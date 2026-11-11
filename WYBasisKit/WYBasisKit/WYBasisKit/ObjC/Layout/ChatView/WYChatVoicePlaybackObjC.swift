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
    /// 可选择的语音倍速，忽略非正数、非有限值和重复值
    public var rates: [NSNumber]
    /// 是否显示语音倍速按钮，默认true
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
