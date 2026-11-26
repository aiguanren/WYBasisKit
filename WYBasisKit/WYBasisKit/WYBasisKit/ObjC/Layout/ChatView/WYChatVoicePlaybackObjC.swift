//
//  WYChatVoicePlaybackObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

//
//  WYChatVoicePlaybackObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 语音播放倍速外观
@objc(WYChatVoicePlaybackConfig)
@objcMembers public class WYChatVoicePlaybackConfigObjC: NSObject {
    /// 发送方语音时长对齐方式
    public var senderDurationAlignment: NSTextAlignment
    /// 接收方语音时长对齐方式
    public var receiverDurationAlignment: NSTextAlignment
    /// 发送方语音声波是否放在时长之后
    public var showsSenderWaveformOnTrailingSide: Bool
    /// 内联播放图标占时长字体行高的比例
    public var playbackSymbolScale: CGFloat
    /// 内联播放图标与时长之间的分隔文字
    public var playbackSymbolSeparator: String
    /// 未播放标记圆角，nil时采用圆形
    public var unreadCornerRadius: NSNumber?
    /// 自定义语音倍速按钮和菜单的标题
    public var rateTitle: ((_ rate: Float) -> String)?
    /// 语音内容的最小宽度，不含气泡内边距
    public var minimumWidth: CGFloat
    /// 保持最小宽度的语音时长，单位秒
    public var minimumWidthDuration: TimeInterval
    /// 超过minimumWidthDuration后每秒增加的内容宽度
    public var widthGrowthPerSecond: CGFloat
    /// 语音秒数后的文字
    public var durationSuffix: String
    /// 语音秒数字体
    public var durationFont: UIFont
    /// 共用语音播放帧，静止时显示最后一帧
    public var waveformImages: [UIImage]
    /// 是否水平翻转发送方的语音播放帧，默认true
    public var mirrorsSenderWaveform: Bool
    /// 语音播放帧每轮时长，单位秒
    public var waveformDuration: TimeInterval
    /// 语音播放帧的显示尺寸
    public var waveformSize: CGSize
    /// 声波图片颜色，默认label，nil时保留原图颜色
    public var waveformTintColor: UIColor?
    /// 是否显示额外的播放或暂停图标，默认false
    public var showsPlaybackSymbol: Bool
    /// 再次播放时是否从头开始，默认true
    public var restartsOnTap: Bool
    /// 收到的未播放语音提示颜色
    public var unreadColor: UIColor
    /// 收到的未播放语音提示直径
    public var unreadSize: CGFloat
    /// 语音播放或继续播放图标
    public var playImage: UIImage?
    /// 语音播放时的暂停图标
    public var pauseImage: UIImage?
    /// 可选择的语音倍速，忽略非正数、非有限值和重复值
    public var rates: [NSNumber]
    /// 是否显示语音倍速按钮，默认false
    public var showsRateControl: Bool
    /// 是否只在播放时显示倍速按钮，默认true
    public var showsOnlyWhilePlaying: Bool
    /// 语音倍速按钮尺寸
    public var size: CGSize
    /// 语音倍速按钮内边距
    public var insets: UIEdgeInsets
    /// 语音倍速按钮字体
    public var font: UIFont
    /// 语音倍速按钮文字颜色
    public var textColor: UIColor
    /// 语音倍速按钮背景色
    public var backgroundColor: UIColor
    /// 语音倍速按钮圆角
    public var cornerRadius: CGFloat
    public override convenience init() { self.init(WYChatVoicePlaybackConfig()) }
    @nonobjc public init(_ value: WYChatVoicePlaybackConfig) {
        self.senderDurationAlignment = value.senderDurationAlignment
        self.receiverDurationAlignment = value.receiverDurationAlignment
        self.showsSenderWaveformOnTrailingSide = value.showsSenderWaveformOnTrailingSide
        self.playbackSymbolScale = value.playbackSymbolScale
        self.playbackSymbolSeparator = value.playbackSymbolSeparator
        self.unreadCornerRadius = value.unreadCornerRadius.map { NSNumber(value: Double($0)) }
        self.rateTitle = value.rateTitle
        minimumWidth = value.minimumWidth
        minimumWidthDuration = value.minimumWidthDuration
        widthGrowthPerSecond = value.widthGrowthPerSecond
        durationSuffix = value.durationSuffix
        durationFont = value.durationFont
        waveformImages = value.waveformImages
        mirrorsSenderWaveform = value.mirrorsSenderWaveform
        waveformDuration = value.waveformDuration
        waveformSize = value.waveformSize
        waveformTintColor = value.waveformTintColor
        showsPlaybackSymbol = value.showsPlaybackSymbol
        restartsOnTap = value.restartsOnTap
        unreadColor = value.unreadColor
        unreadSize = value.unreadSize
        playImage = value.playImage
        pauseImage = value.pauseImage
        rates = value.rates.map { NSNumber(value: $0) }
        showsRateControl = value.showsRateControl
        showsOnlyWhilePlaying = value.showsOnlyWhilePlaying
        size = value.size
        insets = value.insets
        font = value.font
        textColor = value.textColor
        backgroundColor = value.backgroundColor
        cornerRadius = value.cornerRadius
        super.init()
    }
    @nonobjc public func toValue() -> WYChatVoicePlaybackConfig {
        var value = WYChatVoicePlaybackConfig()
        value.senderDurationAlignment = senderDurationAlignment
        value.receiverDurationAlignment = receiverDurationAlignment
        value.showsSenderWaveformOnTrailingSide = showsSenderWaveformOnTrailingSide
        value.playbackSymbolScale = playbackSymbolScale
        value.playbackSymbolSeparator = playbackSymbolSeparator
        value.unreadCornerRadius = unreadCornerRadius.map { CGFloat($0.doubleValue) }
        value.rateTitle = rateTitle
        value.minimumWidth = minimumWidth
        value.minimumWidthDuration = minimumWidthDuration
        value.widthGrowthPerSecond = widthGrowthPerSecond
        value.durationSuffix = durationSuffix
        value.durationFont = durationFont
        value.waveformImages = waveformImages
        value.mirrorsSenderWaveform = mirrorsSenderWaveform
        value.waveformDuration = waveformDuration
        value.waveformSize = waveformSize
        value.waveformTintColor = waveformTintColor
        value.showsPlaybackSymbol = showsPlaybackSymbol
        value.restartsOnTap = restartsOnTap
        value.unreadColor = unreadColor
        value.unreadSize = unreadSize
        value.playImage = playImage
        value.pauseImage = pauseImage
        value.rates = rates.map { $0.floatValue }
        value.showsRateControl = showsRateControl
        value.showsOnlyWhilePlaying = showsOnlyWhilePlaying
        value.size = size
        value.insets = insets
        value.font = font
        value.textColor = textColor
        value.backgroundColor = backgroundColor
        value.cornerRadius = cornerRadius
        return value
    }
}

public extension WYChatView {
    /// 语音倍速变更，参数为消息ID和倍速，调用方同步更新播放器
    @objc(voicePlaybackRateHandler) var voicePlaybackRateHandlerObjC: ((_ messageID: String, _ rate: Float) -> Void)? { get { voicePlaybackRateHandler } set { voicePlaybackRateHandler = newValue } }
    /// 设置语音消息的播放倍速并通知调用方，参数为倍速和语音消息ID
    @objc(setVoicePlaybackRate) var setVoicePlaybackRateObjC: @convention(block) (_ rate: Float, _ messageID: String) -> Bool { { [self] rate, identifier in setVoicePlaybackRate(rate, messageID: identifier) } }
}

public extension WYChatBasicCell {
    /// 语音倍速请求，参数为消息ID和倍速
    @objc(voicePlaybackRateHandler) var voicePlaybackRateHandlerObjC: ((_ messageID: String, _ rate: Float) -> Void)? { get { voicePlaybackRateHandler } set { voicePlaybackRateHandler = newValue } }
}
#endif
