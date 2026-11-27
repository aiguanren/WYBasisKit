//
//  WYChatRecording+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit
import AVFoundation
import SnapKit

/// 使用单调时钟，在手势追踪期间也能更新倒计时并处理录音上限
final class WYChatRecordingCountdown {
    private var timer: Timer?

    func start(maximum: TimeInterval, leadTime: Int, update: @escaping (Int?) -> Void, timeout: @escaping () -> Void) {
        stop()
        guard maximum.isFinite, maximum > 0 else { return }
        let start = ProcessInfo.processInfo.systemUptime

        func tick(_ countdown: WYChatRecordingCountdown) {
            let remaining = maximum - (ProcessInfo.processInfo.systemUptime - start)
            guard remaining > 0 else {
                countdown.stop()
                update(nil)
                timeout()
                return
            }
            let seconds = Int(exactly: ceil(remaining))
            let visible = seconds.map { $0 <= leadTime } ?? false
            let delay = visible ? remaining - (ceil(remaining) - 1) : remaining - Double(max(0, leadTime))
            let timer = Timer(timeInterval: max(0.001, delay), repeats: false) { [weak countdown] _ in
                if let countdown { tick(countdown) }
            }
            countdown.timer = timer
            RunLoop.main.add(timer, forMode: .common)
            update(visible ? seconds : nil)
        }
        tick(self)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit { stop() }
}

final class WYChatRecordingCountdownLabel: UILabel {
    private weak var anchorView: UIView?
    private var bottomConstraint: Constraint?
    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?

    init(identifier: String) {
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
        accessibilityIdentifier = identifier
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(seconds: Int?, configuration: WYChatRecordingCountdownConfig, above anchor: UIView, in container: UIView) {
        guard let seconds, seconds <= configuration.leadTime, !configuration.text.isEmpty else {
            isHidden = true
            return
        }
        font = configuration.font
        textAlignment = configuration.textAlignment
        numberOfLines = max(0, configuration.maximumNumberOfLines)
        textColor = configuration.textColor
        backgroundColor = configuration.backgroundColor
        text = configuration.text.replacingOccurrences(of: "{seconds}", with: String(seconds))
        let offset = configuration.spacing.isFinite ? -configuration.spacing : 0
        let inset = wy_chatNonnegative(configuration.horizontalInset)
        if superview !== container || anchorView !== anchor {
            container.addSubview(self)
            anchorView = anchor
            snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                leadingConstraint = make.leading.greaterThanOrEqualToSuperview().offset(inset).constraint
                trailingConstraint = make.trailing.lessThanOrEqualToSuperview().offset(-inset).constraint
                bottomConstraint = make.bottom.equalTo(anchor.snp.top).offset(offset).constraint
            }
        } else {
            bottomConstraint?.update(offset: offset)
            leadingConstraint?.update(offset: inset)
            trailingConstraint?.update(offset: -inset)
        }
        isHidden = false
    }
}

/// 录音结果与转写编辑流程
extension WYRecordAnimationView {
    var wy_captureConfiguration: WYRecordAnimationConfig { state.captureConfiguration ?? recordAnimationConfig }

    func wy_beginCapture() {
        guard state.requestID == nil else { return }
        wy_clearTranscript()
        state.captureConfiguration = recordAnimationConfig
        soundAnimationStatus = .recording
        wy_updateLiveText()
        state.discard = false
        state.captureStopRequested = false
        state.captureStarted = false
        state.timedOut = false
        state.duration = 0
        state.startedAt = Date()
        let identifier = UUID().uuidString
        state.requestID = identifier
        delegate?.wy_recordingWillStart?(self)
        guard state.requestID == identifier, !state.captureStopRequested else { return }
        state.captureStarted = true
        if wy_captureConfiguration.supportSpeechRecognition && wy_captureConfiguration.speechRecognitionMode == .whileRecording {
            wy_beginLiveCapture(identifier)
            wy_startRecordingWatchdog()
            return
        }
        if let provider = wy_captureConfiguration.recorder {
            guard provider.responds(to: #selector(WYChatRecorder.wy_startRecording(_:settings:maximumDuration:progress:completion:))), provider.responds(to: #selector(WYChatRecorder.wy_stopRecording(_:cancel:))) else { wy_captureFinished(nil, duration: 0, error: wy_recordError(wy_captureConfiguration.missingRecorderText)); return }
            provider.wy_startRecording?(identifier, settings: wy_captureConfiguration.recordSettings, maximumDuration: wy_captureConfiguration.recordTime.max, progress: { [weak self] duration, peak, average in
                DispatchQueue.main.async {
                    guard let self, self.state.requestID == identifier else { return }
                    self.wy_captureProgress(duration, peak: peak, average: average)
                }
            }, completion: { [weak self] url, duration, error in
                DispatchQueue.main.async {
                    guard let self, self.state.requestID == identifier else { return }
                    self.wy_captureFinished(url, duration: duration, error: error)
                }
            })
        } else {
            state.audioKit?.delegate = nil
            state.audioKit?.releaseAll()
            do {
                let recorder = try wy_makeAudioKit()
                state.audioKit = recorder
                try recorder.startRecording(format: wy_captureConfiguration.wy_classicRecordingFormat)
            } catch { wy_captureFinished(nil, duration: 0, error: error as NSError) }
        }
        wy_startRecordingWatchdog()
    }

    private func wy_startRecordingWatchdog() {
        guard let identifier = state.requestID, !state.captureStopRequested else { return }
        let config = wy_captureConfiguration
        let leadTime = state.mode == .dictation ? config.dictationCountdown.leadTime :
            max(config.voiceCountdown.leadTime, config.supportSpeechRecognition ? config.dictationCountdown.leadTime : 0)
        state.countdown.start(maximum: config.recordTime.max, leadTime: leadTime, update: { [weak self] seconds in
            guard let self, self.state.requestID == identifier else { return }
            self.state.countdownSeconds = seconds
            self.wy_updateRecordingCountdown()
        }, timeout: { [weak self] in
            guard let self, self.state.requestID == identifier else { return }
            self.state.timedOut = true
            self.stop()
        })
    }

    func wy_updateRecordingCountdown() {
        let config = wy_captureConfiguration
        let gradient = config.interactionStyle == .gradient
        let anchor: UIView? = gradient ? state.gradientView?.hint : state.soundAnimationView
        guard soundAnimationStatus != .cancel, let seconds = state.countdownSeconds, let anchor, anchor.isDescendant(of: self) else {
            state.countdownLabel.isHidden = true
            return
        }
        let appearance = state.mode == .dictation || soundAnimationStatus == .transfer ? config.dictationCountdown : config.voiceCountdown
        state.countdownLabel.show(seconds: seconds, configuration: appearance, above: anchor, in: self)
    }

    func wy_clearRecordingCountdown() {
        state.countdown.stop()
        state.countdownSeconds = nil
        state.countdownLabel.removeFromSuperview()
    }

    func wy_stopCapture() {
        guard let identifier = state.requestID, !state.captureStopRequested else { return }
        state.captureStopRequested = true
        if !state.captureStarted { wy_captureFinished(nil, duration: 0, error: nil); return }
        state.duration = max(state.duration, state.startedAt.map { Date().timeIntervalSince($0) } ?? 0)
        wy_clearRecordingCountdown()
        if state.discard || soundAnimationStatus == .cancel { state.speech?.cancel() }
        if let recorder = state.liveRecorder {
            recorder.stop(cancel: state.discard || soundAnimationStatus == .cancel)
            return
        }
        if let provider = wy_captureConfiguration.recorder {
            provider.wy_stopRecording?(identifier, cancel: state.discard || soundAnimationStatus == .cancel)
            if state.discard || soundAnimationStatus == .cancel { wy_captureFinished(nil, duration: state.duration, error: nil) }
        } else {
            state.discard = state.discard || soundAnimationStatus == .cancel
            do { try state.audioKit?.stopRecording() }
            catch { wy_captureFinished(nil, duration: state.duration, error: error as NSError) }
        }
    }

    func wy_captureProgress(_ duration: TimeInterval, peak: Float, average: Float, reportsTime: Bool = true) {
        guard state.requestID != nil, !state.captureStopRequested else { return }
        if duration.isFinite { state.duration = max(0, duration) }
        let peak = peak.isFinite ? min(0, max(-160, peak)) : -160
        let average = average.isFinite ? min(0, max(-160, average)) : -160
        if wy_captureConfiguration.interactionStyle == .gradient, let waveform = state.gradientView?.waveform {
            waveform.updateMeters(power: waveform.makeWaveformLevels(peakPower: peak, averagePower: average))
        } else {
            let sound = soundAnimationView
            sound.soundWavesConfigUpdate(status: soundAnimationStatus, config: &sound.soundWavesView.config)
            let power = sound.soundWavesView.makeWaveformLevels(peakPower: peak, averagePower: average)
            sound.soundWavesView.updateMeters(power: power)
        }
        let identifier = state.requestID
        if reportsTime { delegate?.wy_recordingTimeUpdated?(self, currentTime: state.duration, maximumDuration: wy_captureConfiguration.recordTime.max) }
        guard state.requestID == identifier, !state.captureStopRequested else { return }
        delegate?.wy_recordingMeteringUpdated?(self, peakPower: peak, averagePower: average)
    }

    func wy_releaseClassicRecordingSession() {
        guard let options = state.classicSessionDeactivationOptions else { return }
        state.classicSessionDeactivationOptions = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: options)
    }

    func wy_captureFinished(_ url: URL?, duration: TimeInterval, error: NSError?) {
        guard state.requestID != nil else { return }
        wy_releaseClassicRecordingSession()
        if state.mode == .dictation && soundAnimationStatus == .recording && !state.discard {
            state.automaticallySendsTranscript = wy_captureConfiguration.dictationSendsOnRelease
            soundAnimationStatus = .transfer
        }
        state.requestID = nil
        wy_clearRecordingCountdown()
        state.liveRecorder = nil
        for view in [state.leftView, state.rightView, state.bottomView, state.soundAnimationView] { view?.alpha = 0 }
        state.gradientView?.removeFromSuperview()
        alpha = 0
        let cancelled = state.discard || soundAnimationStatus == .cancel
        let duration = duration.isFinite ? max(0, duration) : 0
        state.duration = duration
        let maximum = wy_captureConfiguration.recordTime.max
        let timedOut = state.timedOut || (maximum.isFinite && maximum > 0 && duration >= maximum)
        let valid = url.map { FileManager.default.fileExists(atPath: $0.path) } == true && duration >= max(0, wy_captureConfiguration.recordTime.min)
        let error = cancelled ? nil : error ?? (valid ? nil : wy_recordError(wy_captureConfiguration.invalidRecordingText))
        let delegate = delegate
        defer { delegate?.wy_recordingDidFinish?(self, url: cancelled || error != nil ? nil : url, duration: duration, cancelled: cancelled, timedOut: timedOut, error: error) }
        guard !cancelled else {
            state.speech?.cancel()
            if wy_captureConfiguration.recorder == nil, let url { try? FileManager.default.removeItem(at: url) }
            return
        }
        if let error {
            state.speech?.cancel()
            if wy_captureConfiguration.recorder == nil, let url { try? FileManager.default.removeItem(at: url) }
            resultHandler?(nil, duration, error)
            return
        }
        guard let url else { return }
        if soundAnimationStatus == .transfer && wy_captureConfiguration.supportSpeechRecognition {
            state.transcriptionURL = url
            state.ownsTranscriptionFile = wy_captureConfiguration.recorder == nil
            if wy_captureConfiguration.speechRecognitionMode == .whileRecording {
                wy_showTranscriptPanel()
                if state.liveFinished { wy_completeLiveTranscript() }
                else {
                    wy_updateTranscriptContent(state.liveText.isEmpty ? wy_captureConfiguration.recognizingText : state.liveText, isRecognizing: true)
                    state.speech?.finishStreaming()
                }
            } else { wy_recognizeRecording() }
        } else { state.speech?.cancel(); resultHandler?(url, duration, nil) }
    }

    private func wy_beginLiveCapture(_ identifier: String) {
        state.liveText = ""
        state.liveError = nil
        state.liveFinished = false
        let task = WYChatSpeechRecognitionTask(configuration: wy_captureConfiguration)
        state.speech = task
        task.startStreaming(partialResult: { [weak self, weak task] text in
            guard let self, let task, self.state.speech === task else { return }
            self.state.liveText = text
            self.recognitionPartialResultHandler?(text)
            self.wy_updateLiveText()
        }, completion: { [weak self, weak task] text, error in
            guard let self, let task, self.state.speech === task else { return }
            if let text, !text.isEmpty { self.state.liveText = text }
            self.state.liveError = error
            self.state.liveFinished = true
            self.recognitionResultHandler?(text, error)
            self.wy_updateLiveText()
            if self.state.transcriptionURL != nil { self.wy_completeLiveTranscript() }
        })
        let progress: (TimeInterval, Float, Float) -> Void = { [weak self] duration, peak, average in
            guard let self, self.state.requestID == identifier else { return }
            self.wy_captureProgress(duration, peak: peak, average: average)
        }
        let completion: (URL?, TimeInterval, NSError?) -> Void = { [weak self] url, duration, error in
            DispatchQueue.main.async {
                guard let self, self.state.requestID == identifier else { return }
                self.wy_captureFinished(url, duration: duration, error: error)
            }
        }
        if let recorder = wy_captureConfiguration.recorder {
            guard recorder.responds(to: #selector(WYChatRecorder.wy_startStreamingRecording(_:settings:maximumDuration:audioBuffer:progress:completion:))), recorder.responds(to: #selector(WYChatRecorder.wy_stopRecording(_:cancel:))) else {
                wy_captureFinished(nil, duration: 0, error: wy_recordError(wy_captureConfiguration.missingRecorderText))
                return
            }
            recorder.wy_startStreamingRecording?(identifier, settings: wy_captureConfiguration.recordSettings, maximumDuration: wy_captureConfiguration.recordTime.max, audioBuffer: { [weak task] buffer in task?.appendAudio(buffer) }, progress: { duration, peak, average in DispatchQueue.main.async { progress(duration, peak, average) } }, completion: completion)
        } else {
            let recorder = WYChatLiveRecorder()
            state.liveRecorder = recorder
            recorder.start(configuration: wy_captureConfiguration, audio: { [weak task] buffer in task?.appendAudio(buffer) }, progress: progress, completion: completion)
        }
        wy_updateLiveText()
    }

    private func wy_completeLiveTranscript() {
        wy_updateTranscriptContent(state.liveText, failed: state.liveError != nil)
        wy_sendAutomaticTranscriptIfReady()
    }

    func wy_updateLiveText() {
        guard wy_captureConfiguration.interactionStyle != .gradient else { return }
        let sound = soundAnimationView
        guard wy_captureConfiguration.supportSpeechRecognition, wy_captureConfiguration.speechRecognitionMode == .whileRecording else {
            sound.textView.text = ""
            sound.textView.isHidden = true
            sound.state.showsLiveText = false
            state.lastLayoutSize = .zero
            setNeedsLayout()
            return
        }
        sound.textView.text = state.liveError == nil ? (state.liveText.isEmpty ? wy_captureConfiguration.recognizingText : state.liveText) : wy_captureConfiguration.recognitionFailureText
        sound.textView.font = wy_captureConfiguration.recognitionFont
        sound.textView.textColor = wy_captureConfiguration.recognitionTextColor
        sound.textView.backgroundColor = .clear
        sound.textView.isEditable = false
        sound.textView.isSelectable = false
        sound.textView.isHidden = soundAnimationStatus == .cancel || (soundAnimationStatus == .recording && state.mode == .voice && !wy_captureConfiguration.showsLiveTextWhileRecording)
        sound.state.showsLiveText = !sound.textView.isHidden
        sound.textView.accessibilityIdentifier = "WYChatRecording.liveText"
        state.lastLayoutSize = .zero
        setNeedsLayout()
    }

    func wy_recognizeRecording(_ usesLatestConfiguration: Bool = false) {
        guard let url = state.transcriptionURL else { return }
        state.speech?.cancel()
        wy_showTranscriptPanel()
        wy_updateTranscriptContent(wy_captureConfiguration.recognizingText, isRecognizing: true)
        let task = WYChatSpeechRecognitionTask(configuration: usesLatestConfiguration ? recordAnimationConfig : wy_captureConfiguration)
        state.speech = task
        task.recognize(url: url) { [weak self, weak task] text, error in
            guard let self, let task, self.state.speech === task else { return }
            self.recognitionResultHandler?(text, error)
            guard self.state.speech === task else { return }
            self.wy_updateTranscriptContent(text, failed: error != nil)
            self.wy_sendAutomaticTranscriptIfReady()
        }
    }

    func wy_showTranscriptPanel() { wy_configureTranscriptEditor() }

    @objc func wy_editorKeyboardChanged(_ notification: Notification) {
        guard let panel = state.editPanel, !panel.isHidden, let container = panel.superview else { return }
        var keyboardOffset: CGFloat?
        if state.editText.isFirstResponder,
           let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = container.window {
            let localFrame = container.convert(window.convert(frame, from: window.screen.coordinateSpace), from: window)
            let overlap = container.bounds.intersection(localFrame)
            if !overlap.isEmpty {
                keyboardOffset = max(0, container.safeAreaLayoutGuide.layoutFrame.maxY - overlap.minY)
            }
        }
        if state.showsEditorEmoji {
            if state.editorKeyboardRequest != nil, let keyboardOffset, keyboardOffset > 0 {
                wy_setEditorEmojiVisible(false, keyboardOffset: keyboardOffset, notification: notification)
            }
            return
        }
        wy_invalidateTranscriptLayout()
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? wy_captureConfiguration.animationDuration
        let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        UIView.animate(withDuration: max(0, duration), delay: 0, options: [UIView.AnimationOptions(rawValue: curve << 16), .beginFromCurrentState, .allowUserInteraction]) {
            if self.state.editorInputTop?.isActive == true {
                self.state.editorInputTop?.constant = -(keyboardOffset ?? 0)
            }
            container.layoutIfNeeded()
        }
    }

    @objc func wy_finishEditorKeyboardLayout() {
        guard !state.showsEditorEmoji, let inputTop = state.editorInputTop, inputTop.isActive,
              let container = state.editPanel?.superview else { return }
        let target = container.safeAreaLayoutGuide.layoutFrame.maxY + inputTop.constant
        guard abs(container.keyboardLayoutGuide.layoutFrame.minY - target) <= 1 / max(1, container.traitCollection.displayScale) else { return }
        inputTop.isActive = false
        state.editorKeyboardTop?.isActive = true
    }

    @objc func wy_recordingWillResignActive() {
        guard state.requestID != nil else { return }
        state.discard = true
        stop()
    }

    @objc func wy_sendTranscript() {
        let text = wy_editorPlainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, state.sendButton.isEnabled else { return }
        state.editorEmoji?.updateRecentlyEmoji(state.editText.attributedText)
        let handler = recognizedTextHandler
        wy_cancelTranscript()
        handler?(text)
    }
    func wy_sendAutomaticTranscriptIfReady() {
        guard state.automaticallySendsTranscript else { return }
        if state.editorFailureView?.isHidden == false { state.automaticallySendsTranscript = false; return }
        if state.sendButton.isEnabled { state.automaticallySendsTranscript = false; wy_sendTranscript() }
    }

    @objc func wy_sendOriginalRecording() {
        guard state.mode == .voice, let url = state.transcriptionURL, FileManager.default.fileExists(atPath: url.path) else { return }
        let duration = state.duration
        state.ownsTranscriptionFile = false
        wy_cancelTranscript()
        resultHandler?(url, duration, nil)
    }

    @objc func wy_retryTranscript() { wy_recognizeRecording(true) }
    @objc func wy_cancelTranscript() { state.speech?.cancel(); wy_clearTranscript(); alpha = 0 }
    func wy_clearTranscript() {
        state.editorTranslationRequest = nil
        state.editorTranslatedLocale = nil
        wy_removeEditorEmoji()
        state.automaticallySendsTranscript = false
        state.speech?.cancel()
        state.speech = nil
        if state.ownsTranscriptionFile, let url = state.transcriptionURL { try? FileManager.default.removeItem(at: url) }
        state.transcriptionURL = nil
        state.ownsTranscriptionFile = false
        state.editPanel?.isHidden = true
        state.editText.resignFirstResponder()
        state.editorOverlay?.removeFromSuperview()
        state.editorOverlay = nil
        state.captureConfiguration = nil
    }
    func wy_recordError(_ text: String) -> NSError { NSError(domain: String(describing: WYRecordAnimationView.self), code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
}
