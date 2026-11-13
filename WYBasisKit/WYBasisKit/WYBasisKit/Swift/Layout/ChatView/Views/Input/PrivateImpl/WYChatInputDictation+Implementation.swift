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
    private var observer: NSObjectProtocol?
    private let update: (String) -> Void
    private let completion: (NSError?) -> Void

    init(configuration: WYRecordAnimationConfig, update: @escaping (String) -> Void, completion: @escaping (NSError?) -> Void) {
        self.configuration = configuration
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
    }

    func finish(cancel: Bool) {
        guard active else { return }
        if cancel { active = false; speech?.cancel() }
        if !stopping && captureStarted { stopping = true; recorder?.stop(cancel: cancel); configuration.recorder?.wy_stopRecording?(identifier, cancel: cancel) }
        if cancel { completion(nil) }
    }

    func cancel() { finish(cancel: true) }

    private func complete(text: String?, error: NSError?) {
        guard active else { return }
        if let text, !text.isEmpty { update(text) }
        active = false
        if !stopping && captureStarted { stopping = true; recorder?.stop(cancel: true); configuration.recorder?.wy_stopRecording?(identifier, cancel: true) }
        completion(error)
    }

    private func failure() -> NSError { NSError(domain: String(describing: Self.self), code: 1, userInfo: [NSLocalizedDescriptionKey: WYLocalized("外部录音实现缺少必要方法", table: WYBasisKitConfig.kitLocalizableTable)]) }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        speech?.cancel()
        recorder?.stop(cancel: true)
        if active && captureStarted { configuration.recorder?.wy_stopRecording?(identifier, cancel: true) }
    }
}

/// 占位区域与键盘内语音输入
extension WYChatInputView {
    var wy_showsKeyboardDictation: Bool { window != nil && inputBarConfig.enablesKeyboardDictation && recordAnimationConfig.supportSpeechRecognition && textView.isFirstResponder && !textView.isHidden }
    var wy_dictationReservedWidth: CGFloat { wy_showsKeyboardDictation ? max(0, inputBarConfig.keyboardDictationSize.width) + max(0, inputBarConfig.keyboardDictationInsets.left) + max(0, inputBarConfig.keyboardDictationInsets.right) : 0 }

    func wy_setupDictationControls() {
        placeholderGate.accessibilityIdentifier = "WYChatInput.placeholder"
        placeholderGate.addTarget(self, action: #selector(wy_focusTextInput), for: .touchUpInside)
        let press = UILongPressGestureRecognizer(target: self, action: #selector(voiceButtonDictationLongPress(_:)))
        press.minimumPressDuration = max(0, inputBarConfig.voiceButtonLongPressDuration)
        press.allowableMovement = inputBarConfig.recordViewLongPressMaxOffset
        placeholderGate.addGestureRecognizer(press)
        addSubview(placeholderGate)
        keyboardDictationButton.accessibilityIdentifier = "WYChatInput.dictation"
        keyboardDictationButton.addTarget(self, action: #selector(wy_toggleInputDictation), for: .touchUpInside)
        keyboardDictationButton.imageView?.contentMode = .scaleAspectFit
        addSubview(keyboardDictationButton)
    }

    func wy_updateDictationControls() {
        let config = inputBarConfig
        let centered = config.textPlaceholderAlignment == .center && !textView.isFirstResponder
        textPlaceholderView.textAlignment = centered ? .center : config.textPlaceholderAlignment == .center ? .left : config.textPlaceholderAlignment
        let labelHeight = textPlaceholderView.font.lineHeight
        textPlaceholderView.frame = CGRect(x: config.textPlaceholderOffset.x, y: centered ? max(0, (textView.bounds.height - labelHeight) / 2) : config.textPlaceholderOffset.y, width: max(0, textView.bounds.width - config.textPlaceholderOffset.x * 2 - wy_dictationReservedWidth), height: labelHeight)
        placeholderGate.frame = textVoiceContentView.convert(textView.frame, to: self)
        placeholderGate.isHidden = !centered || textView.isHidden || !textView.text.isEmpty
        placeholderGate.accessibilityLabel = config.textPlaceholder
        let visible = wy_showsKeyboardDictation
        keyboardDictationButton.isHidden = !visible
        keyboardDictationButton.isSelected = isInputDictating
        let insets = config.keyboardDictationInsets
        let size = CGSize(width: min(max(0, config.keyboardDictationSize.width), textVoiceContentView.bounds.width), height: min(max(0, config.keyboardDictationSize.height), textVoiceContentView.bounds.height))
        keyboardDictationButton.frame = textVoiceContentView.convert(CGRect(x: max(0, textVoiceContentView.bounds.width - max(0, insets.right) - size.width), y: max(0, textVoiceContentView.bounds.height - max(0, insets.bottom) - size.height), width: size.width, height: size.height), to: self)
        keyboardDictationButton.tintColor = config.keyboardDictationTintColor
        keyboardDictationButton.setImage((isInputDictating ? config.keyboardDictationStopImage : config.keyboardDictationImage)?.withRenderingMode(config.rendersIconsAsTemplate ? .alwaysTemplate : .alwaysOriginal), for: .normal)
        keyboardDictationButton.accessibilityLabel = WYLocalized(isInputDictating ? "完成" : "语音输入", table: WYBasisKitConfig.kitLocalizableTable)
        var textInsets = config.inputTextEdgeInsets
        textInsets.right += wy_dictationReservedWidth
        if textView.textContainerInset != textInsets { textView.textContainerInset = textInsets }
        bringSubviewToFront(placeholderGate)
        bringSubviewToFront(keyboardDictationButton)
    }

    @objc func wy_focusTextInput() { textView.becomeFirstResponder(); wy_updateDictationControls() }

    @objc func wy_toggleInputDictation() {
        if isInputDictating { wy_stopInputDictation(cancel: false); return }
        guard wy_showsKeyboardDictation else { return }
        let identifier = UUID()
        dictationRequestID = identifier
        wy_updateDictationControls()
        let begin: (Bool) -> Void = { [weak self] granted in
            guard let self, self.dictationRequestID == identifier else { return }
            guard granted, self.wy_showsKeyboardDictation else { self.wy_stopInputDictation(cancel: true); return }
            self.textView.unmarkText()
            self.dictationRange = self.textView.selectedRange
            let session = WYChatInputDictationSession(configuration: self.recordAnimationConfig, update: { [weak self] text in
                guard let self, self.dictationRequestID == identifier else { return }
                self.wy_applyInputDictation(text)
            }, completion: { [weak self] error in
                guard let self, self.dictationRequestID == identifier else { return }
                self.dictationRequestID = nil
                self.inputDictation = nil
                self.wy_updateDictationControls()
                if let error {
                    if let handler = self.inputDictationErrorHandler { handler(error) }
                    else { WYActivity.showInfo(error.localizedDescription, in: self.window) }
                }
            })
            self.inputDictation = session
            session.start()
        }
        if recordAnimationConfig.recorder != nil { begin(true) }
        else { wy_authorizeMicrophoneAccess(showSettingsAlert: true) { granted in begin(granted) } }
    }

    func wy_applyInputDictation(_ text: String) {
        let current = textView.attributedText.string as NSString
        guard dictationRange.location != NSNotFound, NSMaxRange(dictationRange) <= current.length else { wy_stopInputDictation(cancel: true); return }
        isApplyingDictationText = true
        defer { isApplyingDictationText = false }
        guard self.textView(textView, shouldChangeTextIn: dictationRange, replacementText: text) else { return }
        textView.attributedText = sharedEmojiAttributed(string: current.replacingCharacters(in: dictationRange, with: text))
        dictationRange.length = text.utf16.count
        textView.selectedRange = NSRange(location: NSMaxRange(dictationRange), length: 0)
        textViewDidChange(textView)
    }

    func wy_stopInputDictation(cancel: Bool) {
        guard isInputDictating else { return }
        if cancel {
            dictationRequestID = nil
            let session = inputDictation
            inputDictation = nil
            session?.cancel()
        } else if let inputDictation { inputDictation.finish(cancel: false) }
        else { dictationRequestID = nil }
        wy_updateDictationControls()
    }
}
