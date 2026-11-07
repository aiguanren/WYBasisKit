//
//  WYRecordAnimationView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/4.
//

import UIKit
import AVFoundation

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

    /// 代理
    public weak var delegate: WYRecordEventsHandler? = nil
    
    /// 创建录音器
    public lazy var audioKit: WYAudioKit? = wy_makeAudioKit()
    
    /// 当前录音状态
    public var soundAnimationStatus: WYSoundAnimationStatus = .recording
    
    /// 初始化方法
    public init(alpha: CGFloat = 1.0, delegate: WYRecordEventsHandler? = nil) {
        super.init(frame: .zero)
        backgroundColor = recordAnimationConfig.fillColor.onExternal
        self.alpha = alpha
        self.delegate = delegate
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

    internal let state = WYRecordAnimationViewPrivateState()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
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
