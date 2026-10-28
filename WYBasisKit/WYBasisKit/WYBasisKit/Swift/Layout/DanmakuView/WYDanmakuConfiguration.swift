//
//  WYDanmakuConfiguration.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 轨道满时的处理方式
@objc public enum WYDanmakuOverflowPolicy: Int {

    /// 直接丢弃发不出去的弹幕
    case discard

    /// 排队等有空轨再发
    case queue
}

/// 弹幕外观与行为配置(改动后对之后新发的弹幕与轨道划分生效)
public class WYDanmakuConfiguration {

    /// 轨道条数(0 表示按显示高度与轨道行高自动计算)
    public var trackCount: Int = 0

    /// 单条轨道的行高，单位为pt
    public var trackHeight: CGFloat = UIDevice.wy_screenHeight(36, WYBasisKitConfig.defaultScreenPixels)

    /// 弹幕显示区占弹幕视图高度的比例(0~1，从顶部往下取，底部型弹幕按比例区内底部对齐)
    public var displayAreaRatio: CGFloat = 1.0

    /// 滚动弹幕横穿一个弹幕区宽度的行程时长，单位为秒(所有滚动弹幕同一速度，先发后发不会追尾)
    public var scrollDuration: TimeInterval = 8

    /// 顶部与底部弹幕的停留时长，单位为秒
    public var fixedDuration: TimeInterval = 5

    /// 弹幕字体(发纯文本与发富文本都会套这个字体，富文本自己带字体的段落除外)
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))

    /// 弹幕文字颜色(富文本自己带颜色的段落除外)
    public var textColor: UIColor = .white

    /// 文字描边颜色(与描边宽度配合让弹幕在浅色画面上也看得清)
    public var textStrokeColor: UIColor = .black

    /// 文字描边宽度，单位为pt(负数表示描边同时保留文字填充，正数表示只描边不填充，绝对值越大边越粗)
    public var textStrokeWidth: CGFloat = -2

    /// 文字阴影颜色(nil 表示不画阴影)
    public var textShadowColor: UIColor?

    /// 文字阴影模糊半径，单位为pt
    public var textShadowBlurRadius: CGFloat = 0

    /// 文字阴影偏移，单位为pt
    public var textShadowOffset: CGSize = .zero

    /// 单条弹幕的背景色(nil 表示不画背景)
    public var itemBackgroundColor: UIColor?

    /// 单条弹幕背景的圆角半径，单位为pt
    public var itemBackgroundCornerRadius: CGFloat = 0

    /// 弹幕文字距条目背景左右边缘的留白，单位为pt
    public var itemHorizontalPadding: CGFloat = 0

    /// 弹幕文字距条目背景上下边缘的留白，单位为pt(条目高按轨道行高减上下留白后在轨道内垂直居中)
    public var itemVerticalPadding: CGFloat = 0

    /// 同轨相邻两条弹幕之间的最小间距，单位为pt(前一条让出这个距离后同轨才允许进新条)
    public var itemSpacing: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)

    /// 轨道行与行之间的纵向间距，单位为pt(轨道条数自适应时按轨道行高加本间距计算)
    public var trackSpacing: CGFloat = 0

    /// 是否显示弹幕头像(发送时传了头像图片且此项为 true 才显示)
    public var showsAvatar = true

    /// 头像边长，单位为pt
    public var avatarSize: CGFloat = UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels)

    /// 头像圆角半径，单位为pt(设为头像边长的一半即圆形头像)
    public var avatarCornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)

    /// 头像与文字的间距，单位为pt
    public var avatarSpacing: CGFloat = UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels)

    /// 轨道满时的处理方式
    public var overflowPolicy: WYDanmakuOverflowPolicy = .queue

    /// 在屏弹幕总条数上限，超过后按轨道满时的处理方式对待(0 表示不限制)
    public var maxVisibleCount: Int = 0
}
