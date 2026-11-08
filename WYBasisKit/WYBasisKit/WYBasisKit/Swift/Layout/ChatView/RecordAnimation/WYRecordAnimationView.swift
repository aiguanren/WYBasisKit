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

/// 外部语音识别实现
@objc public protocol WYChatSpeechRecognizer: NSObjectProtocol {
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

@objc public protocol WYRecordEventsHandler {
    
    /**
     录音开始
     @param audioKit 音频工具实例
     @param isResume 是否是恢复录音
     */
    @objc(wy_audioRecorderDidStart:isResume:)
    optional func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool)
    
    /**
     录音停止
     @param audioKit 音频工具实例
     @param isPause 是否是暂停录音
     @param isTimeout 是否是超时(达到最大录音时长)停止
     */
    @objc(wy_audioRecorderDidStop:isPause:isTimeout:)
    optional func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool)
    
    /**
     录音时间更新
     @param audioKit 音频工具实例
     @param currentTime 当前录音时间（秒）
     @param duration 总录音时长限制（秒）
     */
    @objc(wy_audioRecorderTimeUpdated:currentTime:duration:)
    optional func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval)
    
    /**
     录音声波数据更新（单通道）
       @param audioKit 音频工具实例
       @param peakPower 当前峰值功率（dB），范围 -160.0 到 0.0（0.0 表示最响，-160.0 表示最安静），适合用于实时响应敏感的声波动画，但可能导致动画跳动剧烈
       @param averagePower 当前平均功率（dB），范围 -160.0 到 0.0，比 peakPower 更平滑，适合语音录制页面的声波动画
     */
    @objc(wy_audioRecorderDidUpdateMetering:peakPower:averagePower:)
    optional func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float)
    
    /**
     音频任务执行失败
     @param audioKit 音频工具实例
     @param url 出错的任务相关URL（可选，可能是本地或远程）
     @param error 错误枚举值
     @param description 详细错误描述(可选)
     */
    @objc(wy_audioTaskDidFailed:url:error:description:)
    optional func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?)
}

public class WYRecordAnimationView: UIView {
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
    /// 转写文本确认发送，参数为编辑后的文本
    public var recognizedTextHandler: ((_ text: String) -> Void)? = nil

    /// 创建录音器
    public lazy var audioKit: WYAudioKit? = wy_makeAudioKit()
    
    /// 当前录音状态
    public var soundAnimationStatus: WYSoundAnimationStatus = .recording
    
    /// 初始化方法
    public init(alpha: CGFloat = 1.0, delegate: WYRecordEventsHandler? = nil, configuration: WYRecordAnimationConfig = WYRecordAnimationConfig()) {
        self.recordAnimationConfig = configuration
        super.init(frame: .zero)
        backgroundColor = recordAnimationConfig.fillColor.onExternal
        self.alpha = alpha
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(wy_editorKeyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(wy_recordingWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    /// 开始录音动画
    public func start() {
        wy_impl_start()
    }
    
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

extension WYRecordAnimationView: WYAudioKitDelegate {
    
    /**
     录音开始
     @param audioKit 音频工具实例
     @param isResume 是否是恢复录音
     */
    public func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        wy_impl_wy_audioRecorderDidStart(audioKit: audioKit, isResume: isResume)
    }
    
    /**
     录音停止
     @param audioKit 音频工具实例
     @param isPause 是否是暂停录音
     @param isTimeout 是否是超时(达到最大录音时长)停止
     */
    public func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {
        wy_impl_wy_audioRecorderDidStop(audioKit: audioKit, isPause: isPause, isTimeout: isTimeout)
    }
    
    /**
     录音时间更新
     @param audioKit 音频工具实例
     @param currentTime 当前录音时间（秒）
     @param duration 总录音时长限制（秒）
     */
    public func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
        wy_impl_wy_audioRecorderTimeUpdated(audioKit: audioKit, currentTime: currentTime, duration: duration)
    }
    
    /**
     录音声波数据更新（单通道）
     @param audioKit 音频工具实例
     @param peakPower 当前峰值功率（dB），范围 -160.0 到 0.0（0.0 表示最响，-160.0 表示最安静），适合用于实时响应敏感的声波动画，但可能导致动画跳动剧烈
     @param averagePower 当前平均功率（dB），范围 -160.0 到 0.0，比 peakPower 更平滑，适合语音录制页面的声波动画
     */
    public func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) {
        wy_impl_wy_audioRecorderDidUpdateMetering(audioKit: audioKit, peakPower: peakPower, averagePower: averagePower)
    }
    
    /**
     音频任务执行失败
     @param audioKit 音频工具实例
     @param url 出错的任务相关URL（可选，可能是本地或远程）
     @param error 错误枚举值
     @param description 详细错误描述(可选)
     */
    public func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        wy_impl_wy_audioTaskDidFailed(audioKit: audioKit, url: url, error: error, description: description)
    }
}
