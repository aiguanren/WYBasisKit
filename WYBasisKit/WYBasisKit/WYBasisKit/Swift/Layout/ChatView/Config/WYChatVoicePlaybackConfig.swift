//
//  WYChatVoicePlaybackConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 语音播放倍速外观
public struct WYChatVoicePlaybackConfig {
    /// 可选择的语音倍速，忽略非正数、非有限值和重复值
    public var rates: [Float] = [1, 1.25, 1.5, 2]
    /// 是否显示语音倍速按钮，默认true
    public var showsRateControl: Bool = true
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
