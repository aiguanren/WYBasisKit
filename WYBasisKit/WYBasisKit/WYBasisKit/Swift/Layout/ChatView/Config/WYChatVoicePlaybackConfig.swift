//
//  WYChatVoicePlaybackConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 语音播放倍速外观
public struct WYChatVoicePlaybackConfig {
    /// 发送方语音时长对齐方式
    public var senderDurationAlignment: NSTextAlignment = .right
    /// 接收方语音时长对齐方式
    public var receiverDurationAlignment: NSTextAlignment = .left
    /// 发送方语音声波是否放在时长之后
    public var showsSenderWaveformOnTrailingSide: Bool = true
    /// 内联播放图标占时长字体行高的比例
    public var playbackSymbolScale: CGFloat = 1
    /// 内联播放图标与时长之间的分隔文字
    public var playbackSymbolSeparator: String = "  "
    /// 未播放标记圆角，nil时采用圆形
    public var unreadCornerRadius: CGFloat? = nil
    /// 自定义语音倍速按钮和菜单的标题
    public var rateTitle: ((_ rate: Float) -> String)? = nil
    /// 语音内容的最小宽度，不含气泡内边距
    public var minimumWidth: CGFloat = UIDevice.wy_screenWidth(64, WYBasisKitConfig.defaultScreenPixels)
    /// 保持最小宽度的语音时长，单位秒
    public var minimumWidthDuration: TimeInterval = 3
    /// 超过minimumWidthDuration后每秒增加的内容宽度
    public var widthGrowthPerSecond: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
    /// 按最大录音时长分配语音气泡宽度，关闭时使用每秒宽度增量
    public var usesProportionalWidth: Bool = true
    /// 语音秒数后的文字
    public var durationSuffix: String = "″"
    /// 语音秒数字体
    public var durationFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels))
    /// 共用语音播放帧，静止时显示最后一帧
    public var waveformImages: [UIImage] = (1...3).map { UIImage.wy_find("WYChatViewVoiceWave\($0)", inBundle: WYChatSourceBundle) }
    /// 是否水平翻转发送方的语音播放帧，默认true
    public var mirrorsSenderWaveform: Bool = true
    /// 语音播放帧每轮时长，单位秒
    public var waveformDuration: TimeInterval = 0.75
    /// 语音播放帧的显示尺寸
    public var waveformSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(20, WYBasisKitConfig.defaultScreenPixels))
    /// 声波图片颜色，默认label，nil时保留原图颜色
    public var waveformTintColor: UIColor? = .label
    /// 是否显示额外的播放或暂停图标，默认false
    public var showsPlaybackSymbol: Bool = false
    /// 再次播放时是否从头开始，默认true
    public var restartsOnTap: Bool = true
    /// 收到的未播放语音提示颜色
    public var unreadColor: UIColor = .systemRed
    /// 收到的未播放语音提示直径
    public var unreadSize: CGFloat = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
    /// 语音播放或继续播放图标
    public var playImage: UIImage? = UIImage.wy_find("WYChatViewAudioPlay", inBundle: WYChatSourceBundle)
    /// 语音播放时的暂停图标
    public var pauseImage: UIImage? = UIImage.wy_find("WYChatViewAudioSuspend", inBundle: WYChatSourceBundle)
    /// 可选择的语音倍速，忽略非正数、非有限值和重复值
    public var rates: [Float] = [1, 1.25, 1.5, 2]
    /// 是否显示语音倍速按钮，默认false
    public var showsRateControl: Bool = false
    /// 是否只在播放时显示倍速按钮，默认true
    public var showsOnlyWhilePlaying: Bool = true
    /// 语音倍速按钮尺寸
    public var size: CGSize = CGSize(width: UIDevice.wy_screenWidth(54, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels))
    /// 语音倍速按钮内边距
    public var insets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(2, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(2, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels))
    /// 语音倍速按钮字体
    public var font: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
    /// 语音倍速按钮文字颜色
    public var textColor: UIColor = .systemIndigo
    /// 语音倍速按钮背景色
    public var backgroundColor: UIColor = .tertiarySystemFill
    /// 语音倍速按钮圆角
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    public init() {}
}
