//
//  WYChatInputDictation+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/12.
//

import UIKit
import AVFoundation

/// 输入框内的音频采集与识别会话
final class WYChatInputDictationSession {
    private let configuration: WYRecordAnimationConfig
    private let identifier = UUID().uuidString
    private var speech: WYChatSpeechRecognitionTask?
    private var recorder: WYChatLiveRecorder?
    private var active = true
    private var stopping = false
    private var captureStarted = false
    private let countdown = WYChatRecordingCountdown()
    private let countdownUpdate: (Int?, WYChatRecordingCountdownConfig) -> Void
    private var observer: NSObjectProtocol?
    private let update: (String) -> Void
    private let completion: (NSError?) -> Void

    init(configuration: WYRecordAnimationConfig, update: @escaping (String) -> Void, countdownUpdate: @escaping (Int?, WYChatRecordingCountdownConfig) -> Void, completion: @escaping (NSError?) -> Void) {
        self.configuration = configuration
        self.countdownUpdate = countdownUpdate
        self.update = update
        self.completion = completion
    }

    func start() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.finish(cancel: true) }
        let task = WYChatSpeechRecognitionTask(configuration: configuration)
        speech = task
        if configuration.speechRecognitionMode == .whileRecording {
            task.startStreaming(partialResult: { [weak self] text in guard let self, self.active else { return }; self.update(text) }, completion: { [weak self] text, error in self?.complete(text: text, error: error) })
        }
        guard active else { return }
        let ownsFile = configuration.recorder == nil
        let captured: (URL?, TimeInterval, NSError?) -> Void = { [weak self] url, _, error in
            DispatchQueue.main.async {
                guard let self, self.active else { if ownsFile, let url { try? FileManager.default.removeItem(at: url) }; return }
                self.stopping = true
                self.stopCountdown()
                if let error { if ownsFile, let url { try? FileManager.default.removeItem(at: url) }; self.complete(text: nil, error: error); return }
                if self.configuration.speechRecognitionMode == .whileRecording {
                    if ownsFile, let url { try? FileManager.default.removeItem(at: url) }
                    self.speech?.finishStreaming()
                } else if let url {
                    self.speech?.recognize(url: url) { [weak self] text, error in
                        if ownsFile { try? FileManager.default.removeItem(at: url) }
                        self?.complete(text: text, error: error)
                    }
                } else { self.complete(text: nil, error: self.failure()) }
            }
        }
        let progress: (TimeInterval, Float, Float) -> Void = { [weak self] duration, _, _ in
            guard let self, self.active, self.configuration.recordTime.max > 0, duration >= self.configuration.recordTime.max else { return }
            self.finish(cancel: false)
        }
        if let provider = configuration.recorder {
            guard provider.responds(to: #selector(WYChatRecorder.wy_stopRecording(_:cancel:))) else { complete(text: nil, error: failure()); return }
            if configuration.speechRecognitionMode == .whileRecording {
                guard provider.responds(to: #selector(WYChatRecorder.wy_startStreamingRecording(_:settings:maximumDuration:audioBuffer:progress:completion:))) else { complete(text: nil, error: failure()); return }
                captureStarted = true
                provider.wy_startStreamingRecording?(identifier, settings: configuration.recordSettings, maximumDuration: configuration.recordTime.max, audioBuffer: { [weak task] buffer in task?.appendAudio(buffer) }, progress: { duration, peak, average in DispatchQueue.main.async { progress(duration, peak, average) } }, completion: captured)
            } else {
                guard provider.responds(to: #selector(WYChatRecorder.wy_startRecording(_:settings:maximumDuration:progress:completion:))) else { complete(text: nil, error: failure()); return }
                captureStarted = true
                provider.wy_startRecording?(identifier, settings: configuration.recordSettings, maximumDuration: configuration.recordTime.max, progress: { duration, peak, average in DispatchQueue.main.async { progress(duration, peak, average) } }, completion: captured)
            }
        } else {
            let recorder = WYChatLiveRecorder()
            self.recorder = recorder
            captureStarted = true
            let streaming = configuration.speechRecognitionMode == .whileRecording
            recorder.start(configuration: configuration, audio: { [weak task] buffer in if streaming { task?.appendAudio(buffer) } }, progress: progress, completion: captured)
        }
        let appearance = configuration.keyboardDictationCountdown
        countdown.start(maximum: configuration.recordTime.max, leadTime: appearance.leadTime, update: { [weak self] seconds in
            self?.countdownUpdate(seconds, appearance)
        }, timeout: { [weak self] in
            self?.finish(cancel: false)
        })
    }

    private func stopCountdown() {
        countdown.stop()
        countdownUpdate(nil, configuration.keyboardDictationCountdown)
    }

    func finish(cancel: Bool) {
        guard active else { return }
        stopCountdown()
        if cancel { active = false; speech?.cancel() }
        if !stopping && captureStarted { stopping = true; recorder?.stop(cancel: cancel); configuration.recorder?.wy_stopRecording?(identifier, cancel: cancel) }
        if cancel { completion(nil) }
    }

    func cancel() { finish(cancel: true) }

    private func complete(text: String?, error: NSError?) {
        guard active else { return }
        if let text, !text.isEmpty { update(text) }
        active = false
        stopCountdown()
        if !stopping && captureStarted { stopping = true; recorder?.stop(cancel: true); configuration.recorder?.wy_stopRecording?(identifier, cancel: true) }
        completion(error)
    }

    private func failure() -> NSError { NSError(domain: String(describing: Self.self), code: 1, userInfo: [NSLocalizedDescriptionKey: configuration.missingRecorderText]) }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        speech?.cancel()
        recorder?.stop(cancel: true)
        if active && captureStarted { configuration.recorder?.wy_stopRecording?(identifier, cancel: true) }
    }
}

/// 占位区域与键盘内语音输入
extension WYChatInputView {
    var wy_showsKeyboardDictation: Bool {
        guard window != nil, inputBarConfig.enablesKeyboardDictation, recordAnimationConfig.supportSpeechRecognition,
              !textView.isHidden,
              inputBarConfig.showsKeyboardDictationWithText || !textView.hasText || state.inputDictation != nil else { return false }
        return textView.isFirstResponder || (inputBarConfig.showsKeyboardDictationInEmojiPanel && emojiView.isSelected)
    }
    var wy_dictationReservedWidth: CGFloat { wy_showsKeyboardDictation ? max(0, inputBarConfig.keyboardDictationSize.width) + max(0, inputBarConfig.keyboardDictationInsets.left) + max(0, inputBarConfig.keyboardDictationInsets.right) : 0 }

    func wy_setupDictationControls() {
        state.placeholderGate.accessibilityIdentifier = "WYChatInput.placeholder"
        state.placeholderGate.addTarget(self, action: #selector(wy_focusTextInput), for: .touchUpInside)
        let press = UILongPressGestureRecognizer(target: self, action: #selector(placeholderRecordingLongPress(_:)))
        press.minimumPressDuration = wy_chatNonnegative(inputBarConfig.placeholderLongPressDuration)
        press.allowableMovement = wy_chatNonnegative(inputBarConfig.recordViewLongPressMaxOffset)
        state.placeholderGate.addGestureRecognizer(press)
        addSubview(state.placeholderGate)
        state.keyboardDictationButton.accessibilityIdentifier = "WYChatInput.dictation"
        state.keyboardDictationButton.addTarget(self, action: #selector(wy_toggleInputDictation), for: .touchUpInside)
        addSubview(state.keyboardDictationButton)
    }

    func wy_updateDictationControls() {
        let config = inputBarConfig
        let centered = config.textPlaceholderAlignment == .center && !textView.isFirstResponder
        textPlaceholderView.textAlignment = centered ? .center : config.textPlaceholderAlignment == .center ? .left : config.textPlaceholderAlignment
        let labelHeight = textPlaceholderView.font.lineHeight
        textPlaceholderView.frame = CGRect(x: config.textPlaceholderOffset.x, y: centered ? max(0, (textView.bounds.height - labelHeight) / 2) : config.textPlaceholderOffset.y, width: max(0, textView.bounds.width - config.textPlaceholderOffset.x * 2 - wy_dictationReservedWidth), height: labelHeight)
        state.placeholderGate.frame = textVoiceContentView.convert(textView.frame, to: self)
        let allowsLongPress = config.placeholderLongPressAction == .voice || config.placeholderLongPressAction == .dictation && recordAnimationConfig.supportSpeechRecognition
        state.placeholderGate.isHidden = !allowsLongPress || textView.isFirstResponder || textView.isHidden || !textView.text.isEmpty
        state.placeholderGate.accessibilityLabel = config.textPlaceholder
        let visible = wy_showsKeyboardDictation
        state.keyboardDictationButton.isHidden = !visible
        state.keyboardDictationButton.isSelected = isInputDictating
        let insets = config.keyboardDictationInsets
        let bounds = textVoiceContentView.bounds
        let top = min(bounds.height, max(0, insets.top))
        let bottom = max(0, insets.bottom)
        let availableHeight = max(0, bounds.height - top - bottom)
        let size = CGSize(width: min(max(0, config.keyboardDictationSize.width), bounds.width), height: min(max(0, config.keyboardDictationSize.height), availableHeight))
        let singleLineHeight = max(config.inputViewHeight, ceil(config.textFont.lineHeight) + config.inputTextEdgeInsets.top + config.inputTextEdgeInsets.bottom)
        let alignmentHeight = min(availableHeight, singleLineHeight - top - bottom)
        let frame = CGRect(x: max(bounds.minX, bounds.maxX - max(0, insets.right) - size.width),
                           y: bounds.minY + top + max(0, alignmentHeight - size.height) / 2,
                           width: size.width, height: size.height)
        state.keyboardDictationButton.frame = textVoiceContentView.convert(frame, to: self)
        state.keyboardDictationButton.tintColor = config.keyboardDictationTintColor
        state.keyboardDictationButton.setImage((isInputDictating ? config.keyboardDictationStopImage : config.keyboardDictationImage)?.withRenderingMode(config.rendersIconsAsTemplate ? .alwaysTemplate : .alwaysOriginal), for: .normal)
        state.keyboardDictationButton.imageView?.contentMode = config.dictationIconContentMode
        state.keyboardDictationButton.accessibilityLabel = isInputDictating ? config.dictationDoneAccessibilityLabel : config.voiceAccessibilityLabel
        var textInsets = config.inputTextEdgeInsets
        textInsets.right += wy_dictationReservedWidth
        if textView.textContainerInset != textInsets { textView.textContainerInset = textInsets }
        bringSubviewToFront(state.placeholderGate)
        bringSubviewToFront(state.keyboardDictationButton)
    }

    @objc func wy_focusTextInput() { textView.becomeFirstResponder(); wy_updateDictationControls() }

    @objc func wy_toggleInputDictation() {
        if isInputDictating { wy_stopInputDictation(cancel: false); return }
        guard wy_showsKeyboardDictation else { return }
        let identifier = UUID()
        state.dictationRequestID = identifier
        wy_updateDictationControls()
        let begin: (Bool) -> Void = { [weak self] granted in
            guard let self, self.state.dictationRequestID == identifier else { return }
            guard granted, self.wy_showsKeyboardDictation else { self.wy_stopInputDictation(cancel: true); return }
            self.textView.unmarkText()
            self.state.dictationRange = self.textView.selectedRange
            self.state.dictationTextSnapshot = self.sharedEmojiAttributedText(attributed: self.textView.attributedText).string
            self.state.dictationRecognizedText = ""
            self.state.dictationCommittedTextCount = 0
            let session = WYChatInputDictationSession(configuration: self.recordAnimationConfig, update: { [weak self] text in
                guard let self, self.state.dictationRequestID == identifier else { return }
                self.wy_applyInputDictation(text)
            }, countdownUpdate: { [weak self] seconds, appearance in
                guard let self, self.state.dictationRequestID == identifier else { return }
                self.state.keyboardDictationCountdownLabel.show(seconds: seconds, configuration: appearance, above: self.textVoiceContentView, in: self)
            }, completion: { [weak self] error in
                guard let self, self.state.dictationRequestID == identifier else { return }
                self.state.dictationRequestID = nil
                self.state.inputDictation = nil
                self.updateContentViewHeight()
                if let error {
                    if let handler = self.inputDictationErrorHandler { handler(error) }
                    else { WYActivity.showInfo(error.localizedDescription, in: self.window) }
                }
            })
            self.state.inputDictation = session
            session.start()
        }
        if recordAnimationConfig.recorder != nil { begin(true) }
        else { wy_authorizeMicrophoneAccess(showSettingsAlert: true) { granted in begin(granted) } }
    }

    func wy_reconcileInputDictationText() {
        guard isInputDictating, !state.isApplyingDictationText else { return }
        let current = sharedEmojiAttributedText(attributed: textView.attributedText).string
        guard current != state.dictationTextSnapshot else { return }
        if inputBarConfig.stopsKeyboardDictationOnTextChange {
            wy_stopInputDictation(cancel: true)
        } else {
            let selection = textView.selectedRange
            let length = textView.attributedText.length
            let location = selection.location == NSNotFound ? length : min(NSMaxRange(selection), length)
            state.dictationRange = NSRange(location: location, length: 0)
            state.dictationCommittedTextCount = state.dictationRecognizedText.count
            state.dictationTextSnapshot = current
        }
    }

    func wy_applyInputDictation(_ text: String) {
        wy_reconcileInputDictationText()
        guard isInputDictating, textView.markedTextRange == nil else { return }
        let replacement = String(text.dropFirst(state.dictationCommittedTextCount))
        let current = NSMutableAttributedString(attributedString: textView.attributedText)
        guard state.dictationRange.location != NSNotFound, NSMaxRange(state.dictationRange) <= current.length else { wy_stopInputDictation(cancel: true); return }
        state.isApplyingDictationText = true
        defer { state.isApplyingDictationText = false }
        guard self.textView(textView, shouldChangeTextIn: state.dictationRange, replacementText: replacement) else { return }
        let inserted = sharedEmojiAttributed(string: replacement)
        current.replaceCharacters(in: state.dictationRange, with: inserted)
        textView.attributedText = current
        state.dictationRange.length = inserted.length
        state.dictationRecognizedText = text
        textView.selectedRange = NSRange(location: NSMaxRange(state.dictationRange), length: 0)
        textViewDidChange(textView)
        state.dictationTextSnapshot = sharedEmojiAttributedText(attributed: textView.attributedText).string
    }

    func wy_stopInputDictation(cancel: Bool) {
        guard isInputDictating else { return }
        if cancel {
            state.keyboardDictationCountdownLabel.isHidden = true
            state.dictationRequestID = nil
            let session = state.inputDictation
            state.inputDictation = nil
            session?.cancel()
        } else if let inputDictation = state.inputDictation { inputDictation.finish(cancel: false) }
        else { state.dictationRequestID = nil }
        wy_updateDictationControls()
    }
}
