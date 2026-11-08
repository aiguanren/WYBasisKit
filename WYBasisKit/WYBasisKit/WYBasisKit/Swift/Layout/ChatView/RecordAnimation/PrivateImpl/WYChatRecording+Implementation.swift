//
//  WYChatRecording+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 录音结果与转写编辑流程
extension WYRecordAnimationView {
    func wy_beginCapture() {
        guard state.requestID == nil else { return }
        wy_clearTranscript()
        soundAnimationStatus = .recording
        state.discard = false
        state.duration = 0
        state.startedAt = Date()
        let identifier = UUID().uuidString
        state.requestID = identifier
        if let provider = recordAnimationConfig.recorder {
            guard provider.responds(to: #selector(WYChatRecorder.wy_startRecording(_:settings:maximumDuration:progress:completion:))), provider.responds(to: #selector(WYChatRecorder.wy_stopRecording(_:cancel:))) else { wy_captureFinished(nil, duration: 0, error: wy_recordError(WYLocalized("外部录音实现缺少必要方法", table: WYBasisKitConfig.kitLocalizableTable))); return }
            provider.wy_startRecording?(identifier, settings: recordAnimationConfig.recordSettings, maximumDuration: recordAnimationConfig.recordTime.max, progress: { [weak self] duration, peak, average in
                DispatchQueue.main.async {
                    guard let self, self.state.requestID == identifier else { return }
                    self.state.duration = duration
                    let level = self.soundAnimationView.soundWavesView.makeWaveformLevels(peakPower: peak, averagePower: average)
                    self.soundAnimationView.soundWavesView.updateMeters(power: level)
                }
            }, completion: { [weak self] url, duration, error in
                DispatchQueue.main.async {
                    guard let self, self.state.requestID == identifier else { return }
                    self.wy_captureFinished(url, duration: duration, error: error)
                }
            })
        } else {
            audioKit?.delegate = nil
            audioKit?.releaseAll()
            audioKit = wy_makeAudioKit()
            do { try audioKit?.startRecording() }
            catch { wy_captureFinished(nil, duration: 0, error: error as NSError) }
        }
        let maximum = recordAnimationConfig.recordTime.max
        if maximum.isFinite && maximum > 0 && state.requestID != nil {
            state.watchdog = Timer.scheduledTimer(withTimeInterval: maximum, repeats: false) { [weak self] _ in self?.stop() }
        }
    }

    func wy_stopCapture() {
        guard let identifier = state.requestID else { return }
        state.duration = max(state.duration, state.startedAt.map { Date().timeIntervalSince($0) } ?? 0)
        state.watchdog?.invalidate()
        state.watchdog = nil
        if let provider = recordAnimationConfig.recorder {
            provider.wy_stopRecording?(identifier, cancel: state.discard || soundAnimationStatus == .cancel)
            if state.discard || soundAnimationStatus == .cancel { state.requestID = nil }
        } else {
            state.discard = state.discard || soundAnimationStatus == .cancel
            do { try audioKit?.stopRecording() }
            catch { wy_captureFinished(nil, duration: state.duration, error: error as NSError) }
        }
    }

    func wy_captureFinished(_ url: URL?, duration: TimeInterval, error: NSError?) {
        guard state.requestID != nil else { return }
        state.requestID = nil
        state.watchdog?.invalidate()
        state.watchdog = nil
        alpha = 0
        guard !state.discard, soundAnimationStatus != .cancel else { return }
        let duration = duration.isFinite ? max(0, duration) : 0
        if let error { resultHandler?(nil, duration, error); return }
        guard let url, FileManager.default.fileExists(atPath: url.path), duration >= max(0, recordAnimationConfig.recordTime.min) else { resultHandler?(nil, duration, wy_recordError(WYLocalized("录音文件无效或录音时间太短", table: WYBasisKitConfig.kitLocalizableTable))); return }
        if soundAnimationStatus == .transfer && recordAnimationConfig.supportSpeechRecognition {
            state.transcriptionURL = url
            state.ownsTranscriptionFile = recordAnimationConfig.recorder == nil
            wy_recognizeRecording()
        } else { resultHandler?(url, duration, nil) }
    }

    func wy_recognizeRecording() {
        guard let url = state.transcriptionURL else { return }
        state.speech?.cancel()
        wy_showTranscriptPanel()
        state.editText.text = recordAnimationConfig.recognizingText
        state.editText.isEditable = false
        state.sendButton.isEnabled = false
        state.retryButton.isHidden = true
        let task = WYChatSpeechRecognitionTask(configuration: recordAnimationConfig)
        state.speech = task
        task.recognize(url: url) { [weak self, weak task] text, error in
            guard let self, let task, self.state.speech === task else { return }
            self.recognitionResultHandler?(text, error)
            self.state.editText.text = error == nil ? text : self.recordAnimationConfig.recognitionFailureText
            self.state.editText.isEditable = error == nil
            self.state.sendButton.isEnabled = error == nil && !(text?.isEmpty ?? true)
            self.state.retryButton.isHidden = error == nil
        }
    }

    func wy_showTranscriptPanel() {
        alpha = 1
        guard state.editPanel == nil else { state.editPanel?.isHidden = false; return }
        let panel = UIStackView()
        panel.axis = .vertical
        panel.spacing = recordAnimationConfig.recordTipViewTopOffset
        panel.backgroundColor = recordAnimationConfig.recognitionBackgroundColor
        panel.translatesAutoresizingMaskIntoConstraints = false
        state.editText.font = recordAnimationConfig.recognitionFont
        state.editText.textColor = recordAnimationConfig.recognitionTextColor
        panel.addArrangedSubview(state.editText)
        let buttons = UIStackView(arrangedSubviews: [state.cancelButton, state.retryButton, state.sendButton])
        buttons.distribution = .fillEqually
        panel.addArrangedSubview(buttons)
        state.sendButton.setTitle(recordAnimationConfig.recognitionSendText, for: .normal)
        state.retryButton.setTitle(recordAnimationConfig.recognitionRetryText, for: .normal)
        state.cancelButton.setTitle(recordAnimationConfig.recognitionCancelText, for: .normal)
        state.sendButton.addTarget(self, action: #selector(wy_sendTranscript), for: .touchUpInside)
        state.retryButton.addTarget(self, action: #selector(wy_retryTranscript), for: .touchUpInside)
        state.cancelButton.addTarget(self, action: #selector(wy_cancelTranscript), for: .touchUpInside)
        addSubview(panel)
        state.editorBottom = panel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        state.editorHeight = panel.heightAnchor.constraint(equalToConstant: min(max(1, recordAnimationConfig.recognitionPanelHeight), max(1, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom)))
        NSLayoutConstraint.activate([panel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), panel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), state.editorBottom!, state.editorHeight!])
        state.editPanel = panel
    }

    @objc func wy_editorKeyboardChanged(_ notification: Notification) {
        guard state.editText.isFirstResponder, let window,
              let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let local = convert(window.convert(frame, from: nil), from: window)
        let overlap = bounds.intersection(local)
        state.editorBottom?.constant = overlap.isNull ? 0 : -max(0, overlap.height - safeAreaInsets.bottom)
        state.editorHeight?.constant = min(max(1, recordAnimationConfig.recognitionPanelHeight), max(1, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom - abs(state.editorBottom?.constant ?? 0)))
        UIView.animate(withDuration: recordAnimationConfig.animationDuration) { self.layoutIfNeeded() }
    }

    @objc func wy_recordingWillResignActive() {
        guard state.requestID != nil else { return }
        state.discard = true
        stop()
    }

    @objc func wy_sendTranscript() {
        let text = state.editText.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, state.sendButton.isEnabled else { return }
        recognizedTextHandler?(text)
        wy_cancelTranscript()
    }
    @objc func wy_retryTranscript() { wy_recognizeRecording() }
    @objc func wy_cancelTranscript() { state.speech?.cancel(); wy_clearTranscript(); alpha = 0 }
    func wy_clearTranscript() {
        if state.ownsTranscriptionFile, let url = state.transcriptionURL { try? FileManager.default.removeItem(at: url) }
        state.transcriptionURL = nil
        state.ownsTranscriptionFile = false
        state.editPanel?.isHidden = true
        state.editorBottom?.constant = 0
        state.editText.resignFirstResponder()
    }
    func wy_recordError(_ text: String) -> NSError { NSError(domain: String(describing: WYRecordAnimationView.self), code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
}
