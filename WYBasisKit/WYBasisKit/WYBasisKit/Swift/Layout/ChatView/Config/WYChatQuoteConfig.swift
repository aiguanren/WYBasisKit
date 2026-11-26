//
//  WYChatQuoteConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 引用预览外观
public struct WYChatQuoteStyle {
    /// 引用关闭按钮的最小触控宽度
    public var closeMinimumTouchWidth: CGFloat = 44
    /// 引用发送者名称最大行数，0表示不限
    public var titleNumberOfLines: Int = 1
    /// 引用摘要的换行或截断方式
    public var textLineBreakMode: NSLineBreakMode = .byTruncatingTail
    /// 引用缩略图的显示方式
    public var thumbnailContentMode: UIView.ContentMode = .scaleAspectFill
    /// 分行引用的无障碍朗读分隔文字
    public var accessibilitySeparator: String = "，"
    /// 关闭引用按钮的无障碍标签
    public var closeAccessibilityLabel: String = WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable)
    /// 行内引用发送者与摘要之间的分隔文字
    public var inlineSenderSeparator: String = "： "
    /// 引用内容内边距
    public var insets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
    /// 发送者与内容的间距
    public var spacing: CGFloat = UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels)
    /// 缩略图、文本与关闭按钮的间距
    public var itemSpacing: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
    /// 引用发送者字体
    public var titleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    /// 引用发送者颜色
    public var titleColor: UIColor = .secondaryLabel
    /// 引用摘要字体
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
    /// 引用摘要颜色
    public var textColor: UIColor = .label
    /// 引用背景色
    public var backgroundColor: UIColor = .secondarySystemBackground
    /// 引用圆角
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
    /// 引用摘要最大行数，0表示不限
    public var maximumTextLines: Int = 2
    /// 引用最小高度
    public var minimumHeight: CGFloat = UIDevice.wy_screenHeight(42, WYBasisKitConfig.defaultScreenPixels)
    /// 引用最大高度，0表示不限
    public var maximumHeight: CGFloat = UIDevice.wy_screenHeight(120, WYBasisKitConfig.defaultScreenPixels)
    /// 是否显示引用发送者，默认true
    public var showsSender: Bool = true
    /// 是否将发送者与摘要显示在同一段
    public var showsSenderInline: Bool = false
    /// 引用内容的前缀
    public var prefix: String = "↪ "
    /// 是否显示引用媒体缩略图，默认true
    public var showsThumbnail: Bool = true
    /// 引用媒体缩略图尺寸
    public var thumbnailSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(36, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(36, WYBasisKitConfig.defaultScreenPixels))
    /// 引用媒体缩略图圆角
    public var thumbnailCornerRadius: CGFloat = UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels)
    /// 引用媒体占位图
    public var thumbnailPlaceholder: UIImage? = WYChatDefaultResources.solidPlaceholder
    /// 是否显示关闭按钮，默认false
    public var showsCloseButton: Bool = false
    /// 引用关闭按钮图片
    public var closeImage: UIImage? = UIImage.wy_find("WYChatViewQuoteDelete", inBundle: WYChatSourceBundle)
    /// 引用关闭按钮颜色
    public var closeColor: UIColor = .tertiaryLabel
    /// 引用关闭按钮的图标尺寸
    public var closeSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels))
    public init() {}
}

/// 引用消息与输入预览配置
public struct WYChatQuoteConfig {
    /// 输入框引用外观
    public var input: WYChatQuoteStyle = {
        var value = WYChatQuoteStyle()
        value.showsSenderInline = true
        value.showsCloseButton = true
        value.prefix = ""
        value.backgroundColor = .quaternarySystemFill
        value.textColor = .secondaryLabel
        value.minimumHeight = UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels)
        value.insets.top = UIDevice.wy_screenHeight(5, WYBasisKitConfig.defaultScreenPixels)
        value.insets.bottom = value.insets.top
        value.closeSize = CGSize(width: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels))
        return value
    }()
    /// 消息引用外观
    public var message: WYChatQuoteStyle = {
        var value = WYChatQuoteStyle()
        value.showsSenderInline = true
        value.prefix = ""
        value.backgroundColor = .tertiarySystemFill
        value.textColor = .secondaryLabel
        value.minimumHeight = UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels)
        value.insets.top = UIDevice.wy_screenHeight(5, WYBasisKitConfig.defaultScreenPixels)
        value.insets.bottom = value.insets.top
        value.thumbnailSize = CGSize(width: UIDevice.wy_screenWidth(28, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(28, WYBasisKitConfig.defaultScreenPixels))
        return value
    }()
    /// 输入框引用外边距
    public var inputOuterInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels), left: 0, bottom: 0, right: 0)
    /// 是否将引用预览放在输入框下方，关闭时显示在输入栏上方
    public var inputBelowTextField: Bool = true
    /// 是否按文本框宽度对齐引用预览，关闭时按输入栏宽度对齐
    public var inputAlignsWithTextField: Bool = true
    /// 消息引用与气泡的间距
    public var messageSpacing: CGFloat = UIDevice.wy_screenHeight(6, WYBasisKitConfig.defaultScreenPixels)
    /// 消息引用首选宽度
    public var messageWidth: CGFloat = UIDevice.wy_screenWidth(220, WYBasisKitConfig.defaultScreenPixels)
    /// 是否按内容缩小消息引用宽度，启用时首选宽度作为上限
    public var fitsMessageContent: Bool = true
    public init() {}
}
