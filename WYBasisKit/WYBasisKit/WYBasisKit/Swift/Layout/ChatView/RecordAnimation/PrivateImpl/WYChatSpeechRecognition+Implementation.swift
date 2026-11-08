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
            guard let provider = configuration.speechRecognitionProvider,
                  provider.responds(to: #selector(WYChatSpeechRecognizer.wy_recognizeSpeech(_:url:localeIdentifier:requiresOnDevice:completion:))) else { finish(nil, error: failure(WYLocalized("未配置外部语音识别实现", table: WYBasisKitConfig.kitLocalizableTable), code: .missingProvider)); return }
            provider.wy_recognizeSpeech?(identifier, url: url, localeIdentifier: configuration.speechLocaleIdentifier, requiresOnDevice: configuration.requiresOnDeviceRecognition) { [weak self] text, error in
                DispatchQueue.main.async { self?.finish(text, error: error) }
            }
            return
        }
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
            self.startApple(url)
        }
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
        completed = true
        timeout?.cancel()
        timeout = nil
        recognitionTask = nil
        recognizer = nil
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(value, error ?? ((value?.isEmpty ?? true) ? failure(WYLocalized("没有识别到文字", table: WYBasisKitConfig.kitLocalizableTable), code: .emptyResult) : nil))
    }

    func cancel() {
        guard !cancelled, !completed else { return }
        cancelled = true
        completion = nil
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
