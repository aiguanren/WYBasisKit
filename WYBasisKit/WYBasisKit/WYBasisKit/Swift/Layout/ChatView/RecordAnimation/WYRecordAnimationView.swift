//
//  WYRecordAnimationView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/4.
//

import UIKit
import AVFoundation

/// 语音识别错误域
public let WYChatSpeechRecognitionErrorDomain = "WYChatSpeechRecognition"

/// 内置语音识别错误
@objc public enum WYChatSpeechRecognitionErrorCode: Int {
    /// 功能未启用
    case disabled = 1
    /// 文件不存在
    case fileNotFound
    /// 等待超时
    case timedOut
    /// 外部实现未配置
    case missingProvider
    /// 语言不支持
    case unsupportedLanguage
    /// 缺少权限用途说明
    case missingUsageDescription
    /// 未获得识别权限
    case authorizationDenied
    /// 识别服务暂不可用
    case unavailable
    /// 不支持本地识别
    case onDeviceUnavailable
    /// 未识别出文字
    case emptyResult
}

/// 语音识别来源
@objc public enum WYChatSpeechRecognitionSource: Int { case apple, external }

/// 语音识别时机
@objc public enum WYChatSpeechRecognitionMode: Int { case whileRecording, afterRecording }

/// 外部语音识别实现
@objc public protocol WYChatSpeechRecognizer: NSObjectProtocol {
    /**
     开始接收实时音频
     @param requestID 本次任务ID
     @param localeIdentifier 识别语言
     @param requiresOnDevice 是否只允许本地处理
     @param partialResult 当前识别文本，后续结果可以修订此文本
     @param completion 最终文本及错误，只能完成一次
     */
    @objc(wy_startStreamingSpeech:localeIdentifier:requiresOnDevice:partialResult:completion:)
    optional func wy_startStreamingSpeech(_ requestID: String, localeIdentifier: String, requiresOnDevice: Bool, partialResult: @escaping (_ text: String) -> Void, completion: @escaping (_ text: String?, _ error: NSError?) -> Void)
    /**
     追加本次录音的音频
     @param requestID 本次任务ID
     @param buffer PCM音频，不得修改缓冲区内容
     */
    @objc(wy_appendSpeechAudio:buffer:)
    optional func wy_appendSpeechAudio(_ requestID: String, buffer: AVAudioPCMBuffer)
    /**
     结束音频输入并等待最终识别结果
     @param requestID 本次任务ID
     */
    @objc(wy_finishStreamingSpeech:)
    optional func wy_finishStreamingSpeech(_ requestID: String)
    /**
     识别音频文件
     @param requestID 本次任务ID
     @param url 音频文件
     @param localeIdentifier 识别语言
     @param requiresOnDevice 是否只允许本地处理
     @param completion 最终文本及错误，只能完成一次
     */
    @objc(wy_recognizeSpeech:url:localeIdentifier:requiresOnDevice:completion:)
    optional func wy_recognizeSpeech(_ requestID: String, url: URL, localeIdentifier: String, requiresOnDevice: Bool, completion: @escaping (_ text: String?, _ error: NSError?) -> Void)
    /**
     取消任务
     @param requestID 需要取消的任务ID
     */
    @objc(wy_cancelSpeechRecognition:)
    optional func wy_cancelSpeechRecognition(_ requestID: String)
}

/// 可替换的录音实现
@objc public protocol WYChatRecorder: NSObjectProtocol {
    /**
     开始采集并提供实时音频
     @param requestID 本次采集ID
     @param settings 录音参数
     @param maximumDuration 最长时长，单位秒
     @param audioBuffer 本次录音的PCM音频，不得修改缓冲区内容
     @param progress 时长、峰值和平均音量回调，音量单位为dB
     @param completion 最终文件、时长及错误，取消后不再提交文件
     */
    @objc(wy_startStreamingRecording:settings:maximumDuration:audioBuffer:progress:completion:)
    optional func wy_startStreamingRecording(_ requestID: String, settings: [String: Any], maximumDuration: TimeInterval, audioBuffer: @escaping (_ buffer: AVAudioPCMBuffer) -> Void, progress: @escaping (_ duration: TimeInterval, _ peakPower: Float, _ averagePower: Float) -> Void, completion: @escaping (_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)
    /**
     开始采集
     @param requestID 本次采集ID
     @param settings 录音参数
     @param maximumDuration 最长时长，单位秒
     @param progress 时长、峰值和平均音量回调，音量单位为dB
     @param completion 最终文件、时长及错误，取消后不再提交文件
     */
    @objc(wy_startRecording:settings:maximumDuration:progress:completion:)
    optional func wy_startRecording(_ requestID: String, settings: [String: Any], maximumDuration: TimeInterval, progress: @escaping (_ duration: TimeInterval, _ peakPower: Float, _ averagePower: Float) -> Void, completion: @escaping (_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)
    /**
     停止采集
     @param requestID 需要停止的采集ID
     @param cancel 是否丢弃本次采集
     */
    @objc(wy_stopRecording:cancel:)
    optional func wy_stopRecording(_ requestID: String, cancel: Bool)
}

/// 录音事件
@objc public protocol WYRecordEventsHandler: NSObjectProtocol {
    /**
     即将开始录音
     @param view 录音界面
     */
    @objc(wy_recordingWillStart:)
    optional func wy_recordingWillStart(_ view: WYRecordAnimationView)

    /**
     录音时长更新
     @param view 录音界面
     @param currentTime 已录制的秒数
     @param maximumDuration 最长录音秒数
     */
    @objc(wy_recordingTimeUpdated:currentTime:maximumDuration:)
    optional func wy_recordingTimeUpdated(_ view: WYRecordAnimationView, currentTime: TimeInterval, maximumDuration: TimeInterval)

    /**
     录音音量更新
     @param view 录音界面
     @param peakPower 峰值音量，单位dB，范围-160到0
     @param averagePower 平均音量，单位dB，范围-160到0
     */
    @objc(wy_recordingMeteringUpdated:peakPower:averagePower:)
    optional func wy_recordingMeteringUpdated(_ view: WYRecordAnimationView, peakPower: Float, averagePower: Float)

    /**
     录音结束
     @param view 录音界面
     @param url 录音文件，取消或失败时为nil
     @param duration 已录制的秒数
     @param cancelled 是否已取消
     @param timedOut 是否达到最长录音时长
     @param error 录音错误，成功或取消时为nil
     */
    @objc(wy_recordingDidFinish:url:duration:cancelled:timedOut:error:)
    optional func wy_recordingDidFinish(_ view: WYRecordAnimationView, url: URL?, duration: TimeInterval, cancelled: Bool, timedOut: Bool, error: NSError?)
}

/// 可替换的文本翻译服务
@objc public protocol WYChatTextTranslator: NSObjectProtocol {
    /**
     翻译文本
     @param requestID 本次翻译ID
     @param text 需要翻译的文本
     @param sourceLocaleIdentifier 源语言，nil时自动识别
     @param targetLocaleIdentifier 目标语言
     @param completion 翻译结果及错误
     */
    @objc(wy_translateText:text:sourceLocaleIdentifier:targetLocaleIdentifier:completion:)
    optional func wy_translateText(_ requestID: String, text: String, sourceLocaleIdentifier: String?, targetLocaleIdentifier: String, completion: @escaping (_ text: String?, _ error: NSError?) -> Void)
    /**
     取消翻译
     @param requestID 需要取消的翻译ID
     */
    @objc(wy_cancelTranslation:)
    optional func wy_cancelTranslation(_ requestID: String)
}

/// 录音用途
@objc public enum WYChatRecordingMode: Int {
    /// 发送语音，可滑入转写编辑
    case voice
    /// 直接转写，可滑入编辑
    case dictation
}

public class WYRecordAnimationView: UIView {
    /// 文本翻译错误域，错误码1表示配置无效，2表示超时，3表示空结果
    @objc public static var translationErrorDomain: String { "WYChatTextTranslation" }

    /// 语音识别错误域
    @objc public static var speechRecognitionErrorDomain: String { WYChatSpeechRecognitionErrorDomain }

    /// 当前实例配置
    public var recordAnimationConfig: WYRecordAnimationConfig = WYRecordAnimationConfig()


    /// 代理
    public weak var delegate: WYRecordEventsHandler? = nil
    
    /// 录音文件结果，参数为文件、时长及错误
    public var resultHandler: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? = nil
    /// 转写结果，参数为最终文本及错误
    public var recognitionResultHandler: ((_ text: String?, _ error: NSError?) -> Void)? = nil
    /// 录音中的识别文本，参数为可被后续结果修订的完整文本
    public var recognitionPartialResultHandler: ((_ text: String) -> Void)? = nil
    /// 转写文本确认发送，参数为编辑后的文本
    public var recognizedTextHandler: ((_ text: String) -> Void)? = nil

    /// 当前录音用途
    public var recordingMode: WYChatRecordingMode { state.mode }

    /// 翻译结果，参数为翻译文本和错误
    public var translationResultHandler: ((_ text: String?, _ error: NSError?) -> Void)? = nil
    /// 识别语言切换，参数为语言标识
    public var recognitionLanguageChangedHandler: ((_ localeIdentifier: String) -> Void)? = nil

    /// 当前录音状态
    public var soundAnimationStatus: WYSoundAnimationStatus = .recording
    
    /// 初始化方法
    public init(alpha: CGFloat = 1.0, delegate: WYRecordEventsHandler? = nil, configuration: WYRecordAnimationConfig = WYRecordAnimationConfig()) {
        self.recordAnimationConfig = configuration
        super.init(frame: .zero)
        backgroundColor = recordAnimationConfig.overlayBackgroundColor
        self.alpha = alpha
        self.delegate = delegate
        keyboardLayoutGuide.followsUndockedKeyboard = true
        NotificationCenter.default.addObserver(self, selector: #selector(wy_editorKeyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(wy_recordingWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    /// 开始录音动画
    public func start() {
        wy_impl_start()
    }
    
    /**
     开始指定用途的录音
     @param mode 录音用途，直接转写需要启用语音识别
     */
    public func start(mode: WYChatRecordingMode) { wy_impl_start(mode: mode) }

    /**
     翻译当前编辑文本
     @param localeIdentifier 目标语言
     */
    public func translateRecognizedText(to localeIdentifier: String) { wy_translateTranscript(to: localeIdentifier) }

    /// 取消当前翻译并保留编辑文本
    public func cancelTranslation() { wy_cancelTranslation() }

    /**
     重新识别录音的语言
     @param localeIdentifier 识别语言
     */
    public func changeRecognitionLanguage(to localeIdentifier: String) { wy_changeRecognitionLanguage(to: localeIdentifier) }

    /// 发送转写编辑前的原始录音，文件由调用方保存或清理
    public func sendOriginalRecording() { wy_sendOriginalRecording() }

    /// 结束录音动画
    public func stop() {
        wy_impl_stop()
    }
    
    /// 录音功能区切换操作
    public func switchStatus(_ touchPoint: CGPoint) {
        wy_impl_switchStatus(touchPoint)
    }
    
    /// 刷新子控件视图
    public func refresh(subview: UIView, status: WYSoundAnimationStatus) {
        wy_impl_refresh(subview: subview, status: status)
    }
    
    public func endRecordVoice() {
        wy_impl_endRecordVoice()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        wy_layoutRecordingView()
    }

    internal let state = WYRecordAnimationViewPrivateState()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        endRecordVoice()
    }

}
