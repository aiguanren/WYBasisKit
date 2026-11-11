//
//  WYChatSpeechRecognition+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import Foundation
import Speech

/// 单次文件识别任务
final class WYChatSpeechRecognitionTask {
    private let configuration: WYRecordAnimationConfig
    private let identifier = UUID().uuidString
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var resolvedLocale: Locale?
    private var timeout: DispatchWorkItem?
    private var completion: ((_ text: String?, _ error: NSError?) -> Void)?
    private var completed = false
    private var cancelled = false
    private let audioLock = NSLock()
    private var bufferRequest: SFSpeechAudioBufferRecognitionRequest?
    private var pendingBuffers: [AVAudioPCMBuffer] = []
    private var partialResult: ((_ text: String) -> Void)?
    private var streaming = false
    private var inputEnded = false
    private var replayFile: AVAudioFile?

    init(configuration: WYRecordAnimationConfig) { self.configuration = configuration }

    func recognize(url: URL, completion: @escaping (_ text: String?, _ error: NSError?) -> Void) {
        self.completion = completion
        guard configuration.supportSpeechRecognition else { finish(nil, error: failure(WYLocalized("语音识别未启用", table: WYBasisKitConfig.kitLocalizableTable), code: .disabled)); return }
        guard FileManager.default.fileExists(atPath: url.path) else { finish(nil, error: failure(WYLocalized("录音文件不存在", table: WYBasisKitConfig.kitLocalizableTable), code: .fileNotFound)); return }
        let deadline = configuration.speechRecognitionTimeout
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.cancelled, !self.completed else { return }
            self.recognitionTask?.cancel()
            self.configuration.speechRecognitionProvider?.wy_cancelSpeechRecognition?(self.identifier)
            self.finish(nil, error: self.failure(WYLocalized("语音识别超时", table: WYBasisKitConfig.kitLocalizableTable), code: .timedOut))
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (deadline.isFinite && deadline > 0 ? deadline : 30), execute: work)
        if configuration.speechRecognitionSource == .external {
            guard let provider = configuration.speechRecognitionProvider else { finish(nil, error: failure(WYLocalized("未配置外部语音识别实现", table: WYBasisKitConfig.kitLocalizableTable), code: .missingProvider)); return }
            if !provider.responds(to: #selector(WYChatSpeechRecognizer.wy_recognizeSpeech(_:url:localeIdentifier:requiresOnDevice:completion:))) {
                startStreaming(partialResult: { _ in }, completion: completion)
                guard !cancelled, !completed else { return }
                do { replayFile = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false) }
                catch { finish(nil, error: error as NSError); return }
                replayNextBuffer()
                return
            }
            provider.wy_recognizeSpeech?(identifier, url: url, localeIdentifier: configuration.speechLocaleIdentifier, requiresOnDevice: configuration.requiresOnDeviceRecognition) { [weak self] text, error in
                DispatchQueue.main.async { self?.finish(text, error: error) }
            }
            return
        }
        prepareApple { [weak self] in self?.startApple(url) }
    }

    private func replayNextBuffer() {
        guard !cancelled, !completed, let file = replayFile else { return }
        guard file.framePosition < file.length else { replayFile = nil; finishStreaming(); return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 1024) else { finish(nil, error: failure(WYLocalized("录音文件无效或录音时间太短", table: WYBasisKitConfig.kitLocalizableTable), code: .fileNotFound)); return }
        do { try file.read(into: buffer) }
        catch { finish(nil, error: error as NSError); return }
        if buffer.frameLength == 0 {
            replayFile = nil
            finishStreaming()
        } else {
            appendAudio(buffer)
            DispatchQueue.main.async { [weak self] in self?.replayNextBuffer() }
        }
    }

    private func prepareApple(_ start: @escaping () -> Void) {
        let requested = Locale(identifier: configuration.speechLocaleIdentifier)
        let supported = SFSpeechRecognizer.supportedLocales()
        let requestedID = Locale.canonicalIdentifier(from: requested.identifier)
        resolvedLocale = supported.first { Locale.canonicalIdentifier(from: $0.identifier) == requestedID }
            ?? supported.first { locale in
                if #available(iOS 16.0, *) {
                    return locale.language.languageCode == requested.language.languageCode && locale.region == requested.region
                } else {
                    return locale.languageCode == requested.languageCode && locale.regionCode == requested.regionCode
                }
            }
        guard resolvedLocale != nil else { finish(nil, error: failure(WYLocalized("不支持当前识别语言", table: WYBasisKitConfig.kitLocalizableTable), code: .unsupportedLanguage)); return }
        guard Bundle.main.object(forInfoDictionaryKey: speechRecognitionKey) as? String != nil else { finish(nil, error: failure(WYLocalized("缺少语音识别权限用途说明", table: WYBasisKitConfig.kitLocalizableTable), code: .missingUsageDescription)); return }
        wy_authorizeSpeechRecognition(showSettingsAlert: false) { [weak self] granted in
            guard let self, !self.cancelled, self.completion != nil else { return }
            guard granted else { self.finish(nil, error: self.failure(WYLocalized("没有语音识别权限", table: WYBasisKitConfig.kitLocalizableTable), code: .authorizationDenied)); return }
            start()
        }
    }

    func startStreaming(partialResult: @escaping (_ text: String) -> Void, completion: @escaping (_ text: String?, _ error: NSError?) -> Void) {
        self.completion = completion
        self.partialResult = partialResult
        streaming = true
        guard configuration.supportSpeechRecognition else { finish(nil, error: failure(WYLocalized("语音识别未启用", table: WYBasisKitConfig.kitLocalizableTable), code: .disabled)); return }
        if configuration.speechRecognitionSource == .external {
            guard let provider = configuration.speechRecognitionProvider,
                  provider.responds(to: #selector(WYChatSpeechRecognizer.wy_startStreamingSpeech(_:localeIdentifier:requiresOnDevice:partialResult:completion:))),
                  provider.responds(to: #selector(WYChatSpeechRecognizer.wy_appendSpeechAudio(_:buffer:))),
                  provider.responds(to: #selector(WYChatSpeechRecognizer.wy_finishStreamingSpeech(_:))) else {
                finish(nil, error: failure(WYLocalized("未配置外部语音识别实现", table: WYBasisKitConfig.kitLocalizableTable), code: .missingProvider))
                return
            }
            provider.wy_startStreamingSpeech?(identifier, localeIdentifier: configuration.speechLocaleIdentifier, requiresOnDevice: configuration.requiresOnDeviceRecognition, partialResult: { [weak self] text in
                DispatchQueue.main.async { guard let self, !self.completed, !self.cancelled else { return }; self.partialResult?(text) }
            }, completion: { [weak self] text, error in DispatchQueue.main.async { self?.finish(text, error: error) } })
        } else {
            prepareApple { [weak self] in self?.startAppleStreaming() }
        }
    }

    private func startAppleStreaming() {
        guard !cancelled, !completed else { return }
        guard let recognizer = SFSpeechRecognizer(locale: resolvedLocale ?? Locale(identifier: configuration.speechLocaleIdentifier)), recognizer.isAvailable else { finish(nil, error: failure(WYLocalized("当前语言的语音识别不可用", table: WYBasisKitConfig.kitLocalizableTable), code: .unavailable)); return }
        guard !configuration.requiresOnDeviceRecognition || recognizer.supportsOnDeviceRecognition else { finish(nil, error: failure(WYLocalized("当前设备或语言不支持本地识别", table: WYBasisKitConfig.kitLocalizableTable), code: .onDeviceUnavailable)); return }
        self.recognizer = recognizer
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = configuration.requiresOnDeviceRecognition
        request.shouldReportPartialResults = true
        audioLock.lock()
        bufferRequest = request
        for buffer in pendingBuffers { request.append(buffer) }
        pendingBuffers.removeAll()
        if inputEnded { request.endAudio() }
        audioLock.unlock()
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self, !self.cancelled, !self.completed else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.partialResult?(text)
                    if result.isFinal { self.finish(text, error: error as NSError?) }
                    else if let error { self.finish(nil, error: error as NSError) }
                } else if let error { self.finish(nil, error: error as NSError) }
            }
        }
    }

    func appendAudio(_ buffer: AVAudioPCMBuffer) {
        if configuration.speechRecognitionSource == .external {
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.cancelled, !self.completed, !self.inputEnded else { return }
                self.configuration.speechRecognitionProvider?.wy_appendSpeechAudio?(self.identifier, buffer: buffer)
            }
            return
        }
        audioLock.lock()
        defer { audioLock.unlock() }
        guard !cancelled, !completed, !inputEnded else { return }
        if let request = bufferRequest {
            request.append(buffer)
        } else {
            pendingBuffers.append(buffer)
            let maximumFrames = buffer.format.sampleRate * 2
            while pendingBuffers.count > 1 && pendingBuffers.reduce(0, { $0 + Double($1.frameLength) }) > maximumFrames { pendingBuffers.removeFirst() }
        }
    }

    func finishStreaming() {
        guard streaming else { return }
        audioLock.lock()
        guard !cancelled, !completed, !inputEnded else { audioLock.unlock(); return }
        inputEnded = true
        bufferRequest?.endAudio()
        audioLock.unlock()
        if configuration.speechRecognitionSource == .external { configuration.speechRecognitionProvider?.wy_finishStreamingSpeech?(identifier) }
        guard !cancelled, !completed else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.completed, !self.cancelled else { return }
            self.recognitionTask?.cancel()
            if self.configuration.speechRecognitionSource == .external { self.configuration.speechRecognitionProvider?.wy_cancelSpeechRecognition?(self.identifier) }
            self.finish(nil, error: self.failure(WYLocalized("语音识别超时", table: WYBasisKitConfig.kitLocalizableTable), code: .timedOut))
        }
        timeout?.cancel()
        timeout = work
        let limit = configuration.speechRecognitionTimeout
        DispatchQueue.main.asyncAfter(deadline: .now() + (limit.isFinite && limit > 0 ? limit : 30), execute: work)
    }

    private func startApple(_ url: URL) {
        guard let recognizer = SFSpeechRecognizer(locale: resolvedLocale ?? Locale(identifier: configuration.speechLocaleIdentifier)), recognizer.isAvailable else { finish(nil, error: failure(WYLocalized("当前语言的语音识别不可用", table: WYBasisKitConfig.kitLocalizableTable), code: .unavailable)); return }
        if configuration.requiresOnDeviceRecognition && !recognizer.supportsOnDeviceRecognition { finish(nil, error: failure(WYLocalized("当前设备或语言不支持本地识别", table: WYBasisKitConfig.kitLocalizableTable), code: .onDeviceUnavailable)); return }
        self.recognizer = recognizer
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = configuration.requiresOnDeviceRecognition
        request.shouldReportPartialResults = false
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result, result.isFinal { self.finish(result.bestTranscription.formattedString, error: nil) }
                else if let error { self.finish(nil, error: error as NSError) }
            }
        }
    }

    private func finish(_ text: String?, error: NSError?) {
        guard !cancelled, let completion else { return }
        self.completion = nil
        audioLock.lock()
        completed = true
        bufferRequest = nil
        pendingBuffers.removeAll()
        audioLock.unlock()
        partialResult = nil
        replayFile = nil
        timeout?.cancel()
        timeout = nil
        recognitionTask = nil
        recognizer = nil
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(value, error ?? ((value?.isEmpty ?? true) ? failure(WYLocalized("没有识别到文字", table: WYBasisKitConfig.kitLocalizableTable), code: .emptyResult) : nil))
    }

    func cancel() {
        guard !cancelled, !completed else { return }
        audioLock.lock()
        cancelled = true
        bufferRequest = nil
        pendingBuffers.removeAll()
        audioLock.unlock()
        partialResult = nil
        completion = nil
        replayFile = nil
        timeout?.cancel()
        timeout = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizer = nil
        if configuration.speechRecognitionSource == .external { configuration.speechRecognitionProvider?.wy_cancelSpeechRecognition?(identifier) }
    }

    private func failure(_ text: String, code: WYChatSpeechRecognitionErrorCode) -> NSError { NSError(domain: WYChatSpeechRecognitionErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: text]) }
    deinit { cancel() }
}
