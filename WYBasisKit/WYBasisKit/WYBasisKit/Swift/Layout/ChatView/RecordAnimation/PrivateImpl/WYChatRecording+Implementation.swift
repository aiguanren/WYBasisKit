//
//  WYChatRecording+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit
import AVFoundation

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
            guard provider.responds(to: #selector(WYChatRecorder.wy_startRecording(_:settings:maximumDuration:progress:completion:))), provider.responds(to: #selector(WYChatRecorder.wy_stopRecording(_:cancel:))) else { wy_captureFinished(nil, duration: 0, error: wy_recordError(WYLocalized("外部录音实现缺少必要方法", table: WYBasisKitConfig.kitLocalizableTable))); return }
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
            state.audioKit = wy_makeAudioKit()
            do { try state.audioKit?.startRecording() }
            catch { wy_captureFinished(nil, duration: 0, error: error as NSError) }
        }
        wy_startRecordingWatchdog()
    }

    private func wy_startRecordingWatchdog() {
        let maximum = wy_captureConfiguration.recordTime.max
        if maximum.isFinite && maximum > 0 && state.requestID != nil {
            state.watchdog = Timer.scheduledTimer(withTimeInterval: maximum, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.state.timedOut = true
                self.stop()
            }
        }
    }

    func wy_stopCapture() {
        guard let identifier = state.requestID, !state.captureStopRequested else { return }
        state.captureStopRequested = true
        if !state.captureStarted { wy_captureFinished(nil, duration: 0, error: nil); return }
        state.duration = max(state.duration, state.startedAt.map { Date().timeIntervalSince($0) } ?? 0)
        state.watchdog?.invalidate()
        state.watchdog = nil
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
        let sound = soundAnimationView
        sound.soundWavesConfigUpdate(status: soundAnimationStatus, config: &sound.soundWavesView.config)
        let power = sound.soundWavesView.makeWaveformLevels(peakPower: peak, averagePower: average)
        sound.soundWavesView.updateMeters(power: power)
        let identifier = state.requestID
        if reportsTime { delegate?.wy_recordingTimeUpdated?(self, currentTime: state.duration, maximumDuration: wy_captureConfiguration.recordTime.max) }
        guard state.requestID == identifier, !state.captureStopRequested else { return }
        delegate?.wy_recordingMeteringUpdated?(self, peakPower: peak, averagePower: average)
    }

    func wy_captureFinished(_ url: URL?, duration: TimeInterval, error: NSError?) {
        guard state.requestID != nil else { return }
        if state.mode == .dictation && soundAnimationStatus == .recording && !state.discard {
            state.automaticallySendsTranscript = wy_captureConfiguration.dictationSendsOnRelease
            soundAnimationStatus = .transfer
        }
        state.requestID = nil
        state.watchdog?.invalidate()
        state.watchdog = nil
        state.liveRecorder = nil
        for view in [state.leftView, state.rightView, state.bottomView, state.soundAnimationView] { view?.alpha = 0 }
        alpha = 0
        let cancelled = state.discard || soundAnimationStatus == .cancel
        let duration = duration.isFinite ? max(0, duration) : 0
        state.duration = duration
        let maximum = wy_captureConfiguration.recordTime.max
        let timedOut = state.timedOut || (maximum.isFinite && maximum > 0 && duration >= maximum)
        let valid = url.map { FileManager.default.fileExists(atPath: $0.path) } == true && duration >= max(0, wy_captureConfiguration.recordTime.min)
        let error = cancelled ? nil : error ?? (valid ? nil : wy_recordError(WYLocalized("录音文件无效或录音时间太短", table: WYBasisKitConfig.kitLocalizableTable)))
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
                    state.editText.text = state.liveText.isEmpty ? wy_captureConfiguration.recognizingText : state.liveText
                    state.editText.isEditable = false
                    state.sendButton.isEnabled = false
                    state.retryButton.isHidden = true
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
                wy_captureFinished(nil, duration: 0, error: wy_recordError(WYLocalized("外部录音实现缺少必要方法", table: WYBasisKitConfig.kitLocalizableTable)))
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
        state.editText.text = state.liveError == nil ? state.liveText : wy_captureConfiguration.recognitionFailureText
        state.editText.isEditable = state.liveError == nil
        state.sendButton.isEnabled = state.liveError == nil && !state.liveText.isEmpty
        state.retryButton.isHidden = state.liveError == nil
        setNeedsLayout()
        wy_sendAutomaticTranscriptIfReady()
    }

    func wy_updateLiveText() {
        let sound = soundAnimationView
        guard wy_captureConfiguration.supportSpeechRecognition, wy_captureConfiguration.speechRecognitionMode == .whileRecording else {
            sound.textView.text = ""
            sound.textView.isHidden = true
            sound.showsLiveText = false
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
        sound.showsLiveText = !sound.textView.isHidden
        sound.textView.accessibilityIdentifier = "WYChatRecording.liveText"
        state.lastLayoutSize = .zero
        setNeedsLayout()
    }

    func wy_recognizeRecording(_ usesLatestConfiguration: Bool = false) {
        wy_cancelTranslation()
        guard let url = state.transcriptionURL else { return }
        state.speech?.cancel()
        wy_showTranscriptPanel()
        state.editText.text = wy_captureConfiguration.recognizingText
        state.editText.isEditable = false
        state.sendButton.isEnabled = false
        state.retryButton.isHidden = true
        let task = WYChatSpeechRecognitionTask(configuration: usesLatestConfiguration ? recordAnimationConfig : wy_captureConfiguration)
        state.speech = task
        task.recognize(url: url) { [weak self, weak task] text, error in
            guard let self, let task, self.state.speech === task else { return }
            self.recognitionResultHandler?(text, error)
            self.state.editText.text = error == nil ? text : self.wy_captureConfiguration.recognitionFailureText
            self.state.editText.isEditable = error == nil
            self.state.sendButton.isEnabled = error == nil && !(text?.isEmpty ?? true)
            self.state.retryButton.isHidden = error == nil
            self.setNeedsLayout()
            self.wy_sendAutomaticTranscriptIfReady()
        }
    }

    func wy_showTranscriptPanel() { wy_configureTranscriptEditor() }

    @objc func wy_editorKeyboardChanged(_ notification: Notification) {
        guard state.editPanel?.isHidden == false else { return }
        setNeedsLayout()
        UIView.animate(withDuration: wy_captureConfiguration.animationDuration) { self.layoutIfNeeded() }
    }

    @objc func wy_recordingWillResignActive() {
        guard state.requestID != nil else { return }
        state.discard = true
        stop()
    }

    @objc func wy_sendTranscript() {
        let text = wy_editorPlainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, state.sendButton.isEnabled else { return }
        let handler = recognizedTextHandler
        wy_cancelTranscript()
        handler?(text)
    }
    func wy_sendAutomaticTranscriptIfReady() {
        guard state.automaticallySendsTranscript else { return }
        if !state.retryButton.isHidden { state.automaticallySendsTranscript = false; return }
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
        wy_cancelTranslation()
        state.editText.inputView = nil
        state.editorEmoji = nil
        state.automaticallySendsTranscript = false
        state.speech?.cancel()
        state.speech = nil
        if state.ownsTranscriptionFile, let url = state.transcriptionURL { try? FileManager.default.removeItem(at: url) }
        state.transcriptionURL = nil
        state.ownsTranscriptionFile = false
        state.editPanel?.isHidden = true
        state.editorBottom?.constant = 0
        state.editText.resignFirstResponder()
        state.captureConfiguration = nil
    }
    func wy_recordError(_ text: String) -> NSError { NSError(domain: String(describing: WYRecordAnimationView.self), code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
}
