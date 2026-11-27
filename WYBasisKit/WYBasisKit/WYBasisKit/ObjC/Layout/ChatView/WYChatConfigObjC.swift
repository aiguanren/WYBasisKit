//
//  WYChatConfigObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

@objc(WYChatSideLayout)
@objcMembers public class WYChatSideLayoutObjC: NSObject {
    /// 消息昵称对齐方式，nil时按收发侧对齐
    public var nicknameAlignment: NSNumber?
    /// 是否显示头像，默认true
    public var showsAvatar: Bool
    /// 头像距离容器边缘的间距
    public var edgeInset: CGFloat
    /// 头像与内容的间距
    public var contentSpacing: CGFloat
    /// 内容顶部相对头像顶部的偏移
    public var contentTopOffset: CGFloat
    /// 单聊是否显示昵称，默认false
    public var showsSingleNickname: Bool
    /// 群聊是否显示昵称，默认true
    public var showsGroupNickname: Bool

    public override convenience init() { self.init(WYChatSideLayout()) }

    @nonobjc public init(_ value: WYChatSideLayout) {
        self.nicknameAlignment = value.nicknameAlignment.map { NSNumber(value: $0.rawValue) }
        self.showsAvatar = value.showsAvatar
        self.edgeInset = value.edgeInset
        self.contentSpacing = value.contentSpacing
        self.contentTopOffset = value.contentTopOffset
        self.showsSingleNickname = value.showsSingleNickname
        self.showsGroupNickname = value.showsGroupNickname
        super.init()
    }

    @nonobjc public func toValue() -> WYChatSideLayout {
        var value = WYChatSideLayout()
        value.nicknameAlignment = nicknameAlignment.flatMap { NSTextAlignment(rawValue: $0.intValue) }
        value.showsAvatar = showsAvatar
        value.edgeInset = edgeInset
        value.contentSpacing = contentSpacing
        value.contentTopOffset = contentTopOffset
        value.showsSingleNickname = showsSingleNickname
        value.showsGroupNickname = showsGroupNickname
        return value
    }
}

@objc(WYChatBubbleConfig)
@objcMembers public class WYChatBubbleConfigObjC: NSObject {
    /// 自定义气泡箭头图片的显示方式
    public var arrowImageContentMode: UIView.ContentMode
    /// 箭头是否默认对齐头像中心，默认true
    public var alignsArrowWithAvatar: Bool = true
    /// 气泡填充色
    public var fillColor: UIColor
    /// 气泡圆角半径
    public var cornerRadius: CGFloat
    /// 需要圆角的位置
    public var cornersPosition: UIRectCorner
    /// 是否显示箭头，默认true
    public var showsArrow: Bool
    /// 自定义箭头图片，nil时使用气泡箭头
    public var arrowImage: UIImage?
    /// 自定义箭头图片显示尺寸
    public var arrowImageSize: CGSize
    /// 自定义箭头图片偏移
    public var arrowImageOffset: CGPoint
    /// 自定义箭头图片颜色，nil时保留图片颜色
    public var arrowImageTintColor: UIColor?
    /// 箭头尺寸，宽为底边长度，高为突出长度
    public var arrowSize: CGSize
    /// 箭头相对所在边中心的偏移
    public var arrowOffset: CGFloat
    /// 箭头距离圆角的间距
    public var arrowEdgePadding: CGFloat
    /// 箭头尖端圆角半径
    public var arrowTipRadius: CGFloat
    /// 边框色
    public var borderColor: UIColor
    /// 边框宽度
    public var borderWidth: CGFloat
    /// 渐变颜色，空数组时使用填充色
    public var gradientColors: [UIColor]
    /// 渐变方向
    public var gradientDirection: WYGradientDirectionObjC
    /// 阴影颜色，nil时不显示阴影
    public var shadowColor: UIColor?
    /// 阴影偏移
    public var shadowOffset: CGSize
    /// 阴影模糊半径
    public var shadowRadius: CGFloat
    /// 阴影不透明度
    public var shadowOpacity: CGFloat

    public override convenience init() { self.init(WYChatBubbleConfig()) }

    @nonobjc public init(_ value: WYChatBubbleConfig) {
        self.arrowImageContentMode = value.arrowImageContentMode
        self.fillColor = value.fillColor
        self.cornerRadius = value.cornerRadius
        self.cornersPosition = value.cornersPosition
        self.showsArrow = value.showsArrow
        self.arrowImage = value.arrowImage
        self.arrowImageSize = value.arrowImageSize
        self.arrowImageOffset = value.arrowImageOffset
        self.arrowImageTintColor = value.arrowImageTintColor
        self.arrowSize = value.arrowSize
        self.arrowOffset = value.arrowOffset
        self.arrowEdgePadding = value.arrowEdgePadding
        self.arrowTipRadius = value.arrowTipRadius
        self.borderColor = value.borderColor
        self.borderWidth = value.borderWidth
        self.gradientColors = value.gradientColors
        self.gradientDirection = WYGradientDirectionObjC(rawValue: value.gradientDirection.rawValue) ?? .leftToRight
        self.shadowColor = value.shadowColor
        self.shadowOffset = value.shadowOffset
        self.shadowRadius = value.shadowRadius
        self.shadowOpacity = value.shadowOpacity
        alignsArrowWithAvatar = value.alignsArrowWithAvatar
        super.init()
    }

    @nonobjc public func toValue() -> WYChatBubbleConfig {
        var value = WYChatBubbleConfig()
        value.arrowImageContentMode = arrowImageContentMode
        value.fillColor = fillColor
        value.cornerRadius = cornerRadius
        value.cornersPosition = cornersPosition
        value.showsArrow = showsArrow
        value.arrowImage = arrowImage
        value.arrowImageSize = arrowImageSize
        value.arrowImageOffset = arrowImageOffset
        value.arrowImageTintColor = arrowImageTintColor
        value.arrowSize = arrowSize
        value.arrowOffset = arrowOffset
        value.arrowEdgePadding = arrowEdgePadding
        value.arrowTipRadius = arrowTipRadius
        value.borderColor = borderColor
        value.borderWidth = borderWidth
        value.gradientColors = gradientColors
        value.gradientDirection = WYGradientDirection(rawValue: gradientDirection.rawValue) ?? .leftToRight
        value.shadowColor = shadowColor
        value.shadowOffset = shadowOffset
        value.shadowRadius = shadowRadius
        value.shadowOpacity = shadowOpacity
        value.alignsArrowWithAvatar = alignsArrowWithAvatar
        return value
    }
}

@objc(WYChatContentConfig)
@objcMembers public class WYChatContentConfigObjC: NSObject {
    /// 传输状态文字缩小时允许的最小比例，有效范围 0 到 1
    public var transferStatusMinimumScaleFactor: CGFloat
    /// 媒体进度环与下方状态文字的间距
    public var transferOverlayCaptionSpacing: CGFloat
    /// 媒体传输状态文字距封面两侧的间距
    public var transferOverlayCaptionHorizontalInset: CGFloat
    /// 媒体传输状态文字为进度环预留的最小高度
    public var transferOverlayMinimumControlHeight: CGFloat
    /// 媒体传输操作图标的四边留白占按钮边长的比例
    public var transferOverlayIconInsetRatio: CGFloat
    /// 卡片底部传输操作按钮最大宽度
    public var transferInlineControlMaximumWidth: CGFloat
    /// 卡片底部传输操作图标的内边距
    public var transferInlineIconInsets: UIEdgeInsets
    /// 卡片底部传输状态文字最多占按钮以外宽度的比例
    public var transferInlineCaptionMaximumWidthRatio: CGFloat
    /// 传输状态和卡片底部进度条的垂直间距
    public var transferInlineBarSpacing: CGFloat
    /// 传输进度条与同一行状态文字之间的水平间距
    public var transferInlineCaptionSpacing: CGFloat
    /// 卡片底部传输进度区的最小高度
    public var transferInlineMinimumHeight: CGFloat
    /// 卡片底部传输进度区在文字和进度条之外预留的高度
    public var transferInlineVerticalPadding: CGFloat
    /// 合并传输状态与进度文案时的分隔文字
    public var transferStatusSeparator: String
    /// 未通过 actionTitle 覆盖时使用的暂停传输无障碍标签
    public var transferPauseActionTitle: String
    /// 未通过 actionTitle 覆盖时使用的继续传输无障碍标签
    public var transferResumeActionTitle: String
    /// 未通过 actionTitle 覆盖时使用的重试传输无障碍标签
    public var transferRetryActionTitle: String
    /// 内置媒体占位图的显示方式
    public var placeholderContentMode: UIView.ContentMode
    /// 消息气泡额外要求的最小高度，单位点
    public var minimumBubbleHeight: CGFloat
    /// 消息卡片标题文字对齐方式
    public var titleTextAlignment: NSTextAlignment
    /// 消息卡片详情文字对齐方式
    public var detailTextAlignment: NSTextAlignment
    /// 消息卡片底部文字对齐方式
    public var footerTextAlignment: NSTextAlignment
    /// 消息卡片底部文字最大行数，0表示不限
    public var footerNumberOfLines: Int
    /// 卡片和展开媒体预览图的显示方式
    public var previewContentMode: UIView.ContentMode
    /// 卡片缩略图的显示方式
    public var thumbnailContentMode: UIView.ContentMode
    /// 音乐和资金卡片多段详情之间的分隔文字
    public var detailsSeparator: String
    /// 是否显示附件传输控件
    public var transferShowsProgress: Bool
    /// 是否显示附件传输百分比
    public var transferShowsPercentage: Bool
    /// 是否允许从进度控件请求暂停或继续
    public var transferAllowsPause: Bool
    /// 媒体传输控件直径，单位点
    public var transferControlSize: CGFloat
    /// 发出附件的进度颜色
    public var transferSenderColor: UIColor
    /// 接收附件的进度颜色
    public var transferReceiverColor: UIColor
    /// 附件进度轨道颜色
    public var transferTrackColor: UIColor
    /// 媒体传输时封面的遮罩颜色
    public var transferOverlayColor: UIColor
    /// 等待上传图标，nil时使用内置图标
    public var transferUploadImage: UIImage?
    /// 等待下载图标，nil时使用内置图标
    public var transferDownloadImage: UIImage?
    /// 暂停传输图标，nil时使用内置图标
    public var transferPauseImage: UIImage?
    /// 继续传输图标，nil时使用内置图标
    public var transferResumeImage: UIImage?
    /// 重试传输图标，nil时使用内置图标
    public var transferRetryImage: UIImage?
    /// 等待上传的提示文字
    public var transferUploadText: String
    /// 待下载的提示文字
    public var transferDownloadText: String
    /// 暂停传输的提示文字
    public var transferPausedText: String
    /// 没有传输错误详情时的提示文字
    public var transferFailedText: String
    /// 待领取资金卡片背景色，nil时使用普通消息气泡
    public var fundsAvailableBubbleColor: UIColor?
    /// 已处理资金卡片背景色，nil时使用普通消息气泡
    public var fundsInactiveBubbleColor: UIColor?
    /// 待领取资金卡片文字颜色，nil时使用通用卡片配色
    public var fundsAvailableTextColor: UIColor?
    /// 已处理资金卡片文字颜色，nil时使用通用卡片配色
    public var fundsInactiveTextColor: UIColor?
    /// 已收款卡片图标，nil时使用内置勾选图标
    public var fundsReceivedIcon: UIImage?
    /// 发出的转账被接收时的状态文字
    public var fundsSentTransferReceivedText: String
    /// 收到的转账被接收时的状态文字
    public var fundsIncomingTransferReceivedText: String
    /// 转账待收款的状态文字
    public var fundsPendingTransferText: String
    /// 红包卡片底部文案
    public var fundsPacketCaption: String
    /// 转账卡片底部文案
    public var fundsTransferCaption: String
    /// 媒体进度环与卡片进度条的线宽
    public var transferLineWidth: CGFloat
    /// 传输进度环的外半径，负数时沿用 transferControlSize
    public var transferRingRadius: CGFloat
    /// 传输进度条圆角，负数时使用线宽的一半
    public var transferBarCornerRadius: CGFloat
    /// 进度操作图标的模板颜色，nil时使用默认配色
    public var transferControlTintColor: UIColor?
    /// 进度状态文字颜色，nil时使用默认配色
    public var transferStatusTextColor: UIColor?
    /// 进度状态文字字体及字号，nil 时使用 detailFont
    public var transferStatusFont: UIFont?
    /// 附件卡片默认使用媒体进度环，切换为 bottom 可在卡片底部显示进度条
    public var attachmentProgressPlacement: WYChatAttachmentProgressPlacement
    /// 是否将传输操作图标作为模板着色
    public var transferTintsControlImages: Bool
    /// 文件卡片图标是否放在内容尾侧
    public var fileUsesTrailingIcon: Bool
    /// 出站消息显示发送进度前的等待秒数，默认 0.5 秒
    public var transferProgressDelay: TimeInterval
    /// 资金卡片图标着色，nil时使用当前状态的默认颜色
    public var fundsIconTintColor: UIColor?
    /// 资金卡片图标的默认边长，单位点
    public var fundsIconSide: CGFloat
    /// 资金卡片底部说明的透明度
    public var fundsCaptionOpacity: CGFloat
    /// 资金卡片底部文字距气泡实际左边缘的距离，负数时与图标左边缘对齐
    public var fundsCaptionLeftInset: CGFloat
    /// 转账金额未自带符号时使用的货币前缀
    public var fundsAmountPrefix: String
    /// 待领取资金卡片内置图标的默认着色
    public var fundsAvailableIconTintColor: UIColor?
    /// 已处理资金卡片内置图标的默认着色
    public var fundsInactiveIconTintColor: UIColor?
    /// 设置传输进度文案，进度范围为0到1，nil时显示百分比
    public var transferProgressFormatter: ((_ progress: Double) -> String)?
    /// 红包或转账已领取提示
    public var fundsReceivedText: String
    /// 红包或转账已过期提示
    public var fundsExpiredText: String
    /// 红包或转账已退回提示
    public var fundsReturnedText: String
    /// 待领取资金图标默认底色透明度
    public var fundsAvailableIconBackgroundOpacity: CGFloat
    /// 已处理资金图标默认底色透明度
    public var fundsInactiveIconBackgroundOpacity: CGFloat
    /// 资金图标背景圆角占短边的比例
    public var fundsIconCornerRadiusRatio: CGFloat
    /// 网页封面高度占媒体配置高度的比例
    public var webpageCoverHeightRatio: CGFloat
    public var fundsIconBackgroundColor: UIColor?
    /// 消息卡片图标，nil时使用对应消息类型的内置图片
    public var iconImage: UIImage?
    public var iconTintColor: UIColor?
    public var usesDefaultIconTint: Bool
    /// 消息卡片图标的显示尺寸
    public var iconSize: CGSize

    /// 内容内边距
    public var insets: UIEdgeInsets
    /// 内容最大宽度占可用宽度的比例，范围0到1
    public var maximumWidthRatio: CGFloat
    /// 内容最大宽度，0表示由比例决定
    public var maximumWidth: CGFloat
    /// 卡片首选宽度
    public var preferredWidth: CGFloat
    /// 媒体预览尺寸
    public var mediaSize: CGSize
    /// 标题字体
    public var titleFont: UIFont
    /// 标题颜色
    public var titleColor: UIColor
    /// 摘要字体
    public var detailFont: UIFont
    /// 摘要颜色
    public var detailColor: UIColor
    /// 内容之间的间距
    public var spacing: CGFloat
    /// 标题行数，0表示不限
    public var titleNumberOfLines: Int
    /// 摘要行数，0表示不限
    public var detailNumberOfLines: Int
    /// 自定义图片占位图，nil时使用纯色或渐变占位
    public var placeholderImage: UIImage?
    /// 默认图片占位颜色
    public var placeholderColor: UIColor
    /// 默认图片占位圆角半径，0表示直角
    public var placeholderCornerRadius: CGFloat
    /// 默认图片占位渐变颜色
    public var placeholderGradientColors: [UIColor]
    /// 默认图片占位渐变方向
    public var placeholderGradientDirection: WYGradientDirectionObjC
    /// 图片消息在使用默认占位加载网络图片时是否显示动画
    public var showsPlaceholderLoadingIndicator: Bool
    /// 是否显示气泡，默认true
    public var showsBubble: Bool

    public override convenience init() { self.init(WYChatContentConfig()) }

    @nonobjc public init(_ value: WYChatContentConfig) {
        self.transferStatusMinimumScaleFactor = value.transferStatusMinimumScaleFactor
        self.transferOverlayCaptionSpacing = value.transferOverlayCaptionSpacing
        self.transferOverlayCaptionHorizontalInset = value.transferOverlayCaptionHorizontalInset
        self.transferOverlayMinimumControlHeight = value.transferOverlayMinimumControlHeight
        self.transferOverlayIconInsetRatio = value.transferOverlayIconInsetRatio
        self.transferInlineControlMaximumWidth = value.transferInlineControlMaximumWidth
        self.transferInlineIconInsets = value.transferInlineIconInsets
        self.transferInlineCaptionMaximumWidthRatio = value.transferInlineCaptionMaximumWidthRatio
        self.transferInlineBarSpacing = value.transferInlineBarSpacing
        self.transferInlineCaptionSpacing = value.transferInlineCaptionSpacing
        self.transferInlineMinimumHeight = value.transferInlineMinimumHeight
        self.transferInlineVerticalPadding = value.transferInlineVerticalPadding
        self.transferStatusSeparator = value.transferStatusSeparator
        self.transferPauseActionTitle = value.transferPauseActionTitle
        self.transferResumeActionTitle = value.transferResumeActionTitle
        self.transferRetryActionTitle = value.transferRetryActionTitle
        self.placeholderContentMode = value.placeholderContentMode
        self.minimumBubbleHeight = value.minimumBubbleHeight
        self.titleTextAlignment = value.titleTextAlignment
        self.detailTextAlignment = value.detailTextAlignment
        self.footerTextAlignment = value.footerTextAlignment
        self.footerNumberOfLines = value.footerNumberOfLines
        self.previewContentMode = value.previewContentMode
        self.thumbnailContentMode = value.thumbnailContentMode
        self.detailsSeparator = value.detailsSeparator
        self.transferShowsProgress = value.transferShowsProgress
        self.transferShowsPercentage = value.transferShowsPercentage
        self.transferAllowsPause = value.transferAllowsPause
        self.transferControlSize = value.transferControlSize
        self.transferSenderColor = value.transferSenderColor
        self.transferReceiverColor = value.transferReceiverColor
        self.transferTrackColor = value.transferTrackColor
        self.transferOverlayColor = value.transferOverlayColor
        self.transferUploadImage = value.transferUploadImage
        self.transferDownloadImage = value.transferDownloadImage
        self.transferPauseImage = value.transferPauseImage
        self.transferResumeImage = value.transferResumeImage
        self.transferRetryImage = value.transferRetryImage
        self.transferUploadText = value.transferUploadText
        self.transferDownloadText = value.transferDownloadText
        self.transferPausedText = value.transferPausedText
        self.transferFailedText = value.transferFailedText
        self.fundsAvailableBubbleColor = value.fundsAvailableBubbleColor
        self.fundsInactiveBubbleColor = value.fundsInactiveBubbleColor
        self.fundsAvailableTextColor = value.fundsAvailableTextColor
        self.fundsInactiveTextColor = value.fundsInactiveTextColor
        self.fundsReceivedIcon = value.fundsReceivedIcon
        self.fundsSentTransferReceivedText = value.fundsSentTransferReceivedText
        self.fundsIncomingTransferReceivedText = value.fundsIncomingTransferReceivedText
        self.fundsPendingTransferText = value.fundsPendingTransferText
        self.fundsPacketCaption = value.fundsPacketCaption
        self.fundsTransferCaption = value.fundsTransferCaption
        self.transferLineWidth = value.transferLineWidth
        self.transferRingRadius = value.transferRingRadius
        self.transferBarCornerRadius = value.transferBarCornerRadius
        self.transferControlTintColor = value.transferControlTintColor
        self.transferStatusTextColor = value.transferStatusTextColor
        self.transferStatusFont = value.transferStatusFont
        self.attachmentProgressPlacement = value.attachmentProgressPlacement
        self.transferTintsControlImages = value.transferTintsControlImages
        self.fileUsesTrailingIcon = value.fileUsesTrailingIcon
        self.transferProgressDelay = value.transferProgressDelay
        self.fundsIconTintColor = value.fundsIconTintColor
        self.fundsIconSide = value.fundsIconSide
        self.fundsCaptionOpacity = value.fundsCaptionOpacity
        self.fundsCaptionLeftInset = value.fundsCaptionLeftInset
        self.fundsAmountPrefix = value.fundsAmountPrefix
        self.fundsAvailableIconTintColor = value.fundsAvailableIconTintColor
        self.fundsInactiveIconTintColor = value.fundsInactiveIconTintColor
        self.transferProgressFormatter = value.transferProgressFormatter
        self.fundsReceivedText = value.fundsReceivedText
        self.fundsExpiredText = value.fundsExpiredText
        self.fundsReturnedText = value.fundsReturnedText
        self.fundsAvailableIconBackgroundOpacity = value.fundsAvailableIconBackgroundOpacity
        self.fundsInactiveIconBackgroundOpacity = value.fundsInactiveIconBackgroundOpacity
        self.fundsIconCornerRadiusRatio = value.fundsIconCornerRadiusRatio
        self.webpageCoverHeightRatio = value.webpageCoverHeightRatio
        fundsIconBackgroundColor = value.fundsIconBackgroundColor
        self.iconSize = value.iconSize
        self.iconImage = value.iconImage
        iconTintColor = value.iconTintColor
        usesDefaultIconTint = value.usesDefaultIconTint
        self.insets = value.insets
        self.maximumWidthRatio = value.maximumWidthRatio
        self.maximumWidth = value.maximumWidth
        self.preferredWidth = value.preferredWidth
        self.mediaSize = value.mediaSize
        self.titleFont = value.titleFont
        self.titleColor = value.titleColor
        self.detailFont = value.detailFont
        self.detailColor = value.detailColor
        self.spacing = value.spacing
        self.titleNumberOfLines = value.titleNumberOfLines
        self.detailNumberOfLines = value.detailNumberOfLines
        self.placeholderImage = value.placeholderImage
        placeholderColor = value.placeholderColor
        placeholderCornerRadius = value.placeholderCornerRadius
        placeholderGradientColors = value.placeholderGradientColors
        placeholderGradientDirection = WYGradientDirectionObjC(rawValue: value.placeholderGradientDirection.rawValue) ?? .leftToRight
        showsPlaceholderLoadingIndicator = value.showsPlaceholderLoadingIndicator
        self.showsBubble = value.showsBubble
        super.init()
    }

    @nonobjc public func toValue() -> WYChatContentConfig {
        var value = WYChatContentConfig()
        value.transferStatusMinimumScaleFactor = transferStatusMinimumScaleFactor
        value.transferOverlayCaptionSpacing = transferOverlayCaptionSpacing
        value.transferOverlayCaptionHorizontalInset = transferOverlayCaptionHorizontalInset
        value.transferOverlayMinimumControlHeight = transferOverlayMinimumControlHeight
        value.transferOverlayIconInsetRatio = transferOverlayIconInsetRatio
        value.transferInlineControlMaximumWidth = transferInlineControlMaximumWidth
        value.transferInlineIconInsets = transferInlineIconInsets
        value.transferInlineCaptionMaximumWidthRatio = transferInlineCaptionMaximumWidthRatio
        value.transferInlineBarSpacing = transferInlineBarSpacing
        value.transferInlineCaptionSpacing = transferInlineCaptionSpacing
        value.transferInlineMinimumHeight = transferInlineMinimumHeight
        value.transferInlineVerticalPadding = transferInlineVerticalPadding
        value.transferStatusSeparator = transferStatusSeparator
        value.transferPauseActionTitle = transferPauseActionTitle
        value.transferResumeActionTitle = transferResumeActionTitle
        value.transferRetryActionTitle = transferRetryActionTitle
        value.placeholderContentMode = placeholderContentMode
        value.minimumBubbleHeight = minimumBubbleHeight
        value.titleTextAlignment = titleTextAlignment
        value.detailTextAlignment = detailTextAlignment
        value.footerTextAlignment = footerTextAlignment
        value.footerNumberOfLines = footerNumberOfLines
        value.previewContentMode = previewContentMode
        value.thumbnailContentMode = thumbnailContentMode
        value.detailsSeparator = detailsSeparator
        value.transferShowsProgress = transferShowsProgress
        value.transferShowsPercentage = transferShowsPercentage
        value.transferAllowsPause = transferAllowsPause
        value.transferControlSize = transferControlSize
        value.transferSenderColor = transferSenderColor
        value.transferReceiverColor = transferReceiverColor
        value.transferTrackColor = transferTrackColor
        value.transferOverlayColor = transferOverlayColor
        value.transferUploadImage = transferUploadImage
        value.transferDownloadImage = transferDownloadImage
        value.transferPauseImage = transferPauseImage
        value.transferResumeImage = transferResumeImage
        value.transferRetryImage = transferRetryImage
        value.transferUploadText = transferUploadText
        value.transferDownloadText = transferDownloadText
        value.transferPausedText = transferPausedText
        value.transferFailedText = transferFailedText
        value.fundsAvailableBubbleColor = fundsAvailableBubbleColor
        value.fundsInactiveBubbleColor = fundsInactiveBubbleColor
        value.fundsAvailableTextColor = fundsAvailableTextColor
        value.fundsInactiveTextColor = fundsInactiveTextColor
        value.fundsReceivedIcon = fundsReceivedIcon
        value.fundsSentTransferReceivedText = fundsSentTransferReceivedText
        value.fundsIncomingTransferReceivedText = fundsIncomingTransferReceivedText
        value.fundsPendingTransferText = fundsPendingTransferText
        value.fundsPacketCaption = fundsPacketCaption
        value.fundsTransferCaption = fundsTransferCaption
        value.transferLineWidth = transferLineWidth
        value.transferRingRadius = transferRingRadius
        value.transferBarCornerRadius = transferBarCornerRadius
        value.transferControlTintColor = transferControlTintColor
        value.transferStatusTextColor = transferStatusTextColor
        value.transferStatusFont = transferStatusFont
        value.attachmentProgressPlacement = attachmentProgressPlacement
        value.transferTintsControlImages = transferTintsControlImages
        value.fileUsesTrailingIcon = fileUsesTrailingIcon
        value.transferProgressDelay = transferProgressDelay
        value.fundsIconTintColor = fundsIconTintColor
        value.fundsIconSide = fundsIconSide
        value.fundsCaptionOpacity = fundsCaptionOpacity
        value.fundsCaptionLeftInset = fundsCaptionLeftInset
        value.fundsAmountPrefix = fundsAmountPrefix
        value.fundsAvailableIconTintColor = fundsAvailableIconTintColor
        value.fundsInactiveIconTintColor = fundsInactiveIconTintColor
        value.transferProgressFormatter = transferProgressFormatter
        value.fundsReceivedText = fundsReceivedText
        value.fundsExpiredText = fundsExpiredText
        value.fundsReturnedText = fundsReturnedText
        value.fundsAvailableIconBackgroundOpacity = fundsAvailableIconBackgroundOpacity
        value.fundsInactiveIconBackgroundOpacity = fundsInactiveIconBackgroundOpacity
        value.fundsIconCornerRadiusRatio = fundsIconCornerRadiusRatio
        value.webpageCoverHeightRatio = webpageCoverHeightRatio
        value.fundsIconBackgroundColor = fundsIconBackgroundColor
        value.iconSize = iconSize
        value.iconImage = iconImage
        value.iconTintColor = iconTintColor
        value.usesDefaultIconTint = usesDefaultIconTint
        value.insets = insets
        value.maximumWidthRatio = maximumWidthRatio
        value.maximumWidth = maximumWidth
        value.preferredWidth = preferredWidth
        value.mediaSize = mediaSize
        value.titleFont = titleFont
        value.titleColor = titleColor
        value.detailFont = detailFont
        value.detailColor = detailColor
        value.spacing = spacing
        value.titleNumberOfLines = titleNumberOfLines
        value.detailNumberOfLines = detailNumberOfLines
        value.placeholderImage = placeholderImage
        value.placeholderColor = placeholderColor
        value.placeholderCornerRadius = placeholderCornerRadius
        value.placeholderGradientColors = placeholderGradientColors
        value.placeholderGradientDirection = WYGradientDirection(rawValue: placeholderGradientDirection.rawValue) ?? .leftToRight
        value.showsPlaceholderLoadingIndicator = showsPlaceholderLoadingIndicator
        value.showsBubble = showsBubble
        return value
    }
}

@objc(WYChatLocationConfig)
@objcMembers public class WYChatLocationConfigObjC: NSObject {
    /// 地图预览未就绪时显示的大头针，nil时仅显示底色
    public var placeholderImage: UIImage?
    public var placeholderIconSize: CGFloat
    public var placeholderBackgroundColor: UIColor
    public var cornerRadius: CGFloat
    public var showsPreviewBelowAddress: Bool

    public override convenience init() { self.init(WYChatLocationConfig()) }

    @nonobjc public init(_ value: WYChatLocationConfig) {
        placeholderImage = value.placeholderImage
        placeholderIconSize = value.placeholderIconSize
        placeholderBackgroundColor = value.placeholderBackgroundColor
        cornerRadius = value.cornerRadius
        showsPreviewBelowAddress = value.showsPreviewBelowAddress
        super.init()
    }

    @nonobjc public func toValue() -> WYChatLocationConfig {
        var value = WYChatLocationConfig()
        value.placeholderImage = placeholderImage
        value.placeholderIconSize = placeholderIconSize
        value.placeholderBackgroundColor = placeholderBackgroundColor
        value.cornerRadius = cornerRadius
        value.showsPreviewBelowAddress = showsPreviewBelowAddress
        return value
    }
}

@objc(WYChatConfig)
@objcMembers public class WYChatConfigObjC: NSObject {
    /// 聊天列表是否由 UIKit 按安全区自动调整内容边距
    public var listInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior
    /// 气泡旁菜单的按钮标题对齐方式
    public var menuItemTitleAlignment: NSTextAlignment
    /// 气泡旁菜单按钮横向内边距，nil 使用 menuInset 的一半
    public var menuItemContentHorizontalInset: NSNumber?
    /// 消息列表的内容内边距
    public var listContentInset: UIEdgeInsets
    /// 消息列表滚动条的内边距
    public var listScrollIndicatorInsets: UIEdgeInsets
    /// 是否显示消息列表的垂直滚动条
    public var listShowsVerticalScrollIndicator: Bool
    /// 消息列表是否允许边缘回弹
    public var listBounces: Bool
    /// 消息列表的系统分隔线样式
    public var listSeparatorStyle: UITableViewCell.SeparatorStyle
    /// 消息列表的分隔线颜色，nil时使用系统颜色
    public var listSeparatorColor: UIColor?
    /// 消息列表分隔线内边距，nil时使用系统值
    public var listSeparatorInset: NSValue?
    /// 滚到底部时预先测量的屏幕高度倍数，0时关闭
    public var bottomPremeasurementViewportCount: CGFloat
    /// 消息上方间距，nil时采用messageSpacing的一半
    public var messageTopSpacing: NSNumber?
    /// 消息下方间距，nil时采用messageSpacing的一半
    public var messageBottomSpacing: NSNumber?
    /// 新消息按钮距列表末端的间距，nil时采用接收侧边距
    public var newMessagesTrailingInset: NSNumber?
    /// 新消息按钮距输入栏的间距，nil时采用messageSpacing
    public var newMessagesBottomSpacing: NSNumber?
    /// 内置线条菜单图标的描边宽度，以24点图标为基准
    public var menuIconStrokeWidth: CGFloat
    /// 未设置menuBorderColor时的边框透明度
    public var menuBorderOpacity: CGFloat
    /// 菜单内容可滚动时是否显示滚动条
    public var menuShowsVerticalScrollIndicator: Bool
    /// 气泡菜单标题最大行数，至少一行
    public var menuItemTitleLineLimit: Int
    /// 新消息按钮圆角，nil时沿用头像圆角
    public var newMessagesButtonCornerRadius: NSNumber?
    /// 自定义菜单圆角，nil时根据菜单边距计算
    public var menuCornerRadius: NSNumber?
    /// 自定义菜单边框宽度，nil时采用一个物理像素
    public var menuBorderWidth: NSNumber?
    /// 自定义菜单图标与文字的间距，nil时采用菜单边距的一半
    public var menuIconSpacing: NSNumber?
    /// 消息气泡菜单长按触发时长，单位秒
    public var menuLongPressDuration: TimeInterval
    /// 阅读历史消息时是否显示新消息按钮
    public var showsNewMessagesButton: Bool
    /// 新消息按钮标题
    public var newMessagesText: String
    /// 新消息按钮底色
    public var newMessagesButtonBackgroundColor: UIColor
    /// 新消息按钮文字颜色，nil时使用系统按钮颜色
    public var newMessagesButtonTextColor: UIColor?
    /// 新消息按钮字体，nil时使用系统按钮字体
    public var newMessagesButtonFont: UIFont?
    /// 消息菜单的面板边距
    public var menuInset: CGFloat
    /// 消息菜单图标边长
    public var menuIconSize: CGFloat
    /// 消息菜单项的最小宽度
    public var menuMinimumItemWidth: CGFloat
    /// 消息菜单项的最小高度
    public var menuMinimumItemHeight: CGFloat
    /// 消息菜单边框颜色，nil时按菜单文字颜色生成
    public var menuBorderColor: UIColor?
    /// 按消息操作提供菜单图标，返回nil时使用内置图标
    public var actionImage: ((_ action: WYChatAction) -> UIImage?)?
    /// 返回引用和合并记录中的消息摘要，返回nil时使用默认摘要
    public var messageSummary: ((_ content: WYChatMessageContentModelObjC) -> String?)?
    /// 设置指定消息类型的内容配置，参数为消息类型和配置
    public var setContentConfiguration: @convention(block) (_ style: WYChatMessageStyle, _ configuration: WYChatContentConfigObjC) -> WYChatConfigObjC {
        { [self] style, config in self.contentOverrides[NSNumber(value: style.rawValue)] = config; return self }
    }

    /// 多选时是否显示内置工具条，默认true
    public var showsSelectionToolbar: Bool = true
    /// 多选取消按钮文本
    public var selectionCancelText: String = ""
    /// 拖动消息列表时的键盘收起方式
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive
    /// 公共布局
    public var basic: WYBasicChatConfigObjC
    /// 发送方布局
    public var sender: WYChatSideLayoutObjC
    /// 接收方布局
    public var receiver: WYChatSideLayoutObjC
    /// 发送方气泡
    public var senderBubble: WYChatBubbleConfigObjC
    /// 接收方气泡
    public var receiverBubble: WYChatBubbleConfigObjC
    /// 文本配置
    public var text: WYTextChatConfigObjC
    /// 通用内容配置
    public var content: WYChatContentConfigObjC
    /// 各类型内容覆盖配置，未提供时使用content
    public var contentOverrides: [NSNumber: WYChatContentConfigObjC]
    /// 是否显示输入栏，默认true
    public var showsInputBar: Bool
    /// 输入栏配置
    public var input: WYInputBarConfigObjC
    /// 表情配置
    public var emoji: WYEmojiViewConfigObjC
    /// 更多面板配置
    public var more: WYMoreViewConfigObjC
    /// 图片和视频展示
    public var media: WYChatMediaConfigObjC
    /// 位置消息展示
    public var location: WYChatLocationConfigObjC
    /// 引用消息与输入预览
    public var quote: WYChatQuoteConfigObjC
    /// 撤回与重新编辑
    public var notice: WYChatNoticeConfigObjC
    /// 合并聊天记录明细
    public var records: WYChatRecordsConfigObjC
    /// 多选操作与转发
    public var selection: WYChatSelectionConfigObjC
    /// 语音播放倍速
    public var voicePlayback: WYChatVoicePlaybackConfigObjC
    /// 录音配置
    public var recording: WYRecordAnimationConfigObjC
    /// 聊天背景色
    public var backgroundColor: UIColor
    /// Cell上下间距
    public var messageSpacing: CGFloat
    /// 昵称与内容的间距
    public var nicknameSpacing: CGFloat
    /// 点击空白是否收起输入面板，默认true
    public var dismissInputOnTap: Bool
    /// 是否启用长按菜单，默认true
    public var enablesMessageMenu: Bool
    /// 长按消息时是否使用系统整行高亮菜单，默认false，菜单在消息旁出现
    public var highlightsEntireCellOnLongPress: Bool
    /// 消息旁菜单与相邻头像的最小水平间距，默认适配后的16点
    public var menuPreviewAvatarSpacing: CGFloat
    /// 消息旁菜单背景色
    public var menuBackgroundColor: UIColor
    /// 消息旁菜单文字颜色
    public var menuTextColor: UIColor
    /// 消息旁菜单危险操作文字颜色
    public var menuDestructiveTextColor: UIColor
    /// 消息旁菜单功能文字的字体与字号
    public var menuItemFont: UIFont
    /// 消息旁菜单每行最多显示的功能数，默认4，空间不足时自动减少
    public var menuMaximumColumns: Int
    /// 默认菜单操作，接入方通过回调执行外部操作
    public var menuActions: [NSNumber]
    /// 允许自动滚动到底部的距离
    public var bottomDistance: CGFloat
    /// 发送后是否自动加入消息列表，默认true
    public var automaticallyInsertsSentMessages: Bool
    /// 未知消息提示
    public var unsupportedMessageText: String
    /// 自定义注册的Cell
    public var customCellClasses: [AnyClass]
    /// 自定义图片加载，参数为资源、目标控件及消息ID
    public var imageLoader: ((_ asset: WYChatAssetsModelObjC, _ imageView: UIImageView, _ messageID: String) -> Void)?
    /// 按消息调整配置，参数为消息及当前界面配置
    public var messageConfiguration: ((_ message: WYChatMessageModelObjC, _ configuration: WYChatConfigObjC) -> WYChatConfigObjC)?
    /// 自定义菜单标题，参数为操作，返回nil时使用默认标题
    public var actionTitle: ((_ action: WYChatAction) -> String?)?
    /// 是否显示某项菜单，参数为操作及消息
    public var allowsAction: ((_ action: WYChatAction, _ message: WYChatMessageModelObjC) -> Bool)?

    public override convenience init() { self.init(WYChatConfig()) }

    @nonobjc public init(_ value: WYChatConfig) {
        self.listInsetAdjustmentBehavior = value.listInsetAdjustmentBehavior
        self.menuItemTitleAlignment = value.menuItemTitleAlignment
        self.menuItemContentHorizontalInset = value.menuItemContentHorizontalInset.map { NSNumber(value: Double($0)) }
        self.listContentInset = value.listContentInset
        self.listScrollIndicatorInsets = value.listScrollIndicatorInsets
        self.listShowsVerticalScrollIndicator = value.listShowsVerticalScrollIndicator
        self.listBounces = value.listBounces
        self.listSeparatorStyle = value.listSeparatorStyle
        self.listSeparatorColor = value.listSeparatorColor
        self.listSeparatorInset = value.listSeparatorInset.map { NSValue(uiEdgeInsets: $0) }
        self.bottomPremeasurementViewportCount = value.bottomPremeasurementViewportCount
        self.messageTopSpacing = value.messageTopSpacing.map { NSNumber(value: Double($0)) }
        self.messageBottomSpacing = value.messageBottomSpacing.map { NSNumber(value: Double($0)) }
        self.newMessagesTrailingInset = value.newMessagesTrailingInset.map { NSNumber(value: Double($0)) }
        self.newMessagesBottomSpacing = value.newMessagesBottomSpacing.map { NSNumber(value: Double($0)) }
        self.menuIconStrokeWidth = value.menuIconStrokeWidth
        self.menuBorderOpacity = value.menuBorderOpacity
        self.menuShowsVerticalScrollIndicator = value.menuShowsVerticalScrollIndicator
        self.menuItemTitleLineLimit = value.menuItemTitleLineLimit
        self.newMessagesButtonCornerRadius = value.newMessagesButtonCornerRadius.map { NSNumber(value: Double($0)) }
        self.menuCornerRadius = value.menuCornerRadius.map { NSNumber(value: Double($0)) }
        self.menuBorderWidth = value.menuBorderWidth.map { NSNumber(value: Double($0)) }
        self.menuIconSpacing = value.menuIconSpacing.map { NSNumber(value: Double($0)) }
        self.menuLongPressDuration = value.menuLongPressDuration
        self.showsNewMessagesButton = value.showsNewMessagesButton
        self.newMessagesText = value.newMessagesText
        self.newMessagesButtonBackgroundColor = value.newMessagesButtonBackgroundColor
        self.newMessagesButtonTextColor = value.newMessagesButtonTextColor
        self.newMessagesButtonFont = value.newMessagesButtonFont
        self.menuInset = value.menuInset
        self.menuIconSize = value.menuIconSize
        self.menuMinimumItemWidth = value.menuMinimumItemWidth
        self.menuMinimumItemHeight = value.menuMinimumItemHeight
        self.menuBorderColor = value.menuBorderColor
        self.actionImage = value.actionImage
        self.messageSummary = value.messageSummary.map { source in { content in source(content.toValue()) } }
        self.basic = WYBasicChatConfigObjC(value.basic)
        self.sender = WYChatSideLayoutObjC(value.sender)
        self.receiver = WYChatSideLayoutObjC(value.receiver)
        self.senderBubble = WYChatBubbleConfigObjC(value.senderBubble)
        self.receiverBubble = WYChatBubbleConfigObjC(value.receiverBubble)
        self.text = WYTextChatConfigObjC(value.text)
        self.content = WYChatContentConfigObjC(value.content)
        self.contentOverrides = Dictionary(uniqueKeysWithValues: value.contentOverrides.map { (NSNumber(value: $0.key.rawValue), WYChatContentConfigObjC($0.value)) })
        self.showsInputBar = value.showsInputBar
        self.input = WYInputBarConfigObjC(value.input)
        self.emoji = WYEmojiViewConfigObjC(value.emoji)
        self.more = WYMoreViewConfigObjC(value.more)
        self.media = WYChatMediaConfigObjC(value.media)
        self.location = WYChatLocationConfigObjC(value.location)
        self.quote = WYChatQuoteConfigObjC(value.quote)
        self.notice = WYChatNoticeConfigObjC(value.notice)
        self.records = WYChatRecordsConfigObjC(value.records)
        self.selection = WYChatSelectionConfigObjC(value.selection)
        self.voicePlayback = WYChatVoicePlaybackConfigObjC(value.voicePlayback)
        self.recording = WYRecordAnimationConfigObjC(value.recording)
        self.backgroundColor = value.backgroundColor
        self.messageSpacing = value.messageSpacing
        self.nicknameSpacing = value.nicknameSpacing
        self.dismissInputOnTap = value.dismissInputOnTap
        self.enablesMessageMenu = value.enablesMessageMenu
        self.highlightsEntireCellOnLongPress = value.highlightsEntireCellOnLongPress
        self.menuPreviewAvatarSpacing = value.menuPreviewAvatarSpacing
        self.menuBackgroundColor = value.menuBackgroundColor
        self.menuTextColor = value.menuTextColor
        self.menuDestructiveTextColor = value.menuDestructiveTextColor
        self.menuItemFont = value.menuItemFont
        self.menuMaximumColumns = value.menuMaximumColumns
        self.menuActions = value.menuActions.map { NSNumber(value: $0.rawValue) }
        self.bottomDistance = value.bottomDistance
        self.automaticallyInsertsSentMessages = value.automaticallyInsertsSentMessages
        self.unsupportedMessageText = value.unsupportedMessageText
        self.customCellClasses = value.customCellClasses
        self.imageLoader = value.imageLoader.map { source in { asset, image, identifier in source(asset.toValue(), image, identifier) } }
        self.messageConfiguration = value.messageConfiguration.map { source in { message, config in WYChatConfigObjC(source(message.toValue(), config.toValue())) } }
        self.actionTitle = value.actionTitle
        self.allowsAction = value.allowsAction.map { source in { action, message in source(action, message.toValue()) } }
        keyboardDismissMode = value.keyboardDismissMode
        showsSelectionToolbar = value.showsSelectionToolbar
        selectionCancelText = value.selectionCancelText
        super.init()
    }

    @nonobjc public func toValue() -> WYChatConfig {
        var value = WYChatConfig()
        value.listInsetAdjustmentBehavior = listInsetAdjustmentBehavior
        value.menuItemTitleAlignment = menuItemTitleAlignment
        value.menuItemContentHorizontalInset = menuItemContentHorizontalInset.map { CGFloat($0.doubleValue) }
        value.listContentInset = listContentInset
        value.listScrollIndicatorInsets = listScrollIndicatorInsets
        value.listShowsVerticalScrollIndicator = listShowsVerticalScrollIndicator
        value.listBounces = listBounces
        value.listSeparatorStyle = listSeparatorStyle
        value.listSeparatorColor = listSeparatorColor
        value.listSeparatorInset = listSeparatorInset?.uiEdgeInsetsValue
        value.bottomPremeasurementViewportCount = bottomPremeasurementViewportCount
        value.messageTopSpacing = messageTopSpacing.map { CGFloat($0.doubleValue) }
        value.messageBottomSpacing = messageBottomSpacing.map { CGFloat($0.doubleValue) }
        value.newMessagesTrailingInset = newMessagesTrailingInset.map { CGFloat($0.doubleValue) }
        value.newMessagesBottomSpacing = newMessagesBottomSpacing.map { CGFloat($0.doubleValue) }
        value.menuIconStrokeWidth = menuIconStrokeWidth
        value.menuBorderOpacity = menuBorderOpacity
        value.menuShowsVerticalScrollIndicator = menuShowsVerticalScrollIndicator
        value.menuItemTitleLineLimit = menuItemTitleLineLimit
        value.newMessagesButtonCornerRadius = newMessagesButtonCornerRadius.map { CGFloat($0.doubleValue) }
        value.menuCornerRadius = menuCornerRadius.map { CGFloat($0.doubleValue) }
        value.menuBorderWidth = menuBorderWidth.map { CGFloat($0.doubleValue) }
        value.menuIconSpacing = menuIconSpacing.map { CGFloat($0.doubleValue) }
        value.menuLongPressDuration = menuLongPressDuration
        value.showsNewMessagesButton = showsNewMessagesButton
        value.newMessagesText = newMessagesText
        value.newMessagesButtonBackgroundColor = newMessagesButtonBackgroundColor
        value.newMessagesButtonTextColor = newMessagesButtonTextColor
        value.newMessagesButtonFont = newMessagesButtonFont
        value.menuInset = menuInset
        value.menuIconSize = menuIconSize
        value.menuMinimumItemWidth = menuMinimumItemWidth
        value.menuMinimumItemHeight = menuMinimumItemHeight
        value.menuBorderColor = menuBorderColor
        value.actionImage = actionImage
        value.messageSummary = messageSummary.map { source in { content in source(WYChatMessageContentModelObjC(content)) } }
        value.basic = basic.toValue()
        value.sender = sender.toValue()
        value.receiver = receiver.toValue()
        value.senderBubble = senderBubble.toValue()
        value.receiverBubble = receiverBubble.toValue()
        value.text = text.toValue()
        value.content = content.toValue()
        value.contentOverrides = Dictionary(uniqueKeysWithValues: contentOverrides.compactMap { key, value in WYChatMessageStyle(rawValue: key.intValue).map { ($0, value.toValue()) } })
        value.showsInputBar = showsInputBar
        value.input = input.toValue()
        value.emoji = emoji.toValue()
        value.more = more.toValue()
        value.media = media.toValue()
        value.location = location.toValue()
        value.quote = quote.toValue()
        value.notice = notice.toValue()
        value.records = records.toValue()
        value.selection = selection.toValue()
        value.voicePlayback = voicePlayback.toValue()
        value.recording = recording.toValue()
        value.backgroundColor = backgroundColor
        value.messageSpacing = messageSpacing
        value.nicknameSpacing = nicknameSpacing
        value.dismissInputOnTap = dismissInputOnTap
        value.enablesMessageMenu = enablesMessageMenu
        value.highlightsEntireCellOnLongPress = highlightsEntireCellOnLongPress
        value.menuPreviewAvatarSpacing = menuPreviewAvatarSpacing
        value.menuBackgroundColor = menuBackgroundColor
        value.menuTextColor = menuTextColor
        value.menuDestructiveTextColor = menuDestructiveTextColor
        value.menuItemFont = menuItemFont
        value.menuMaximumColumns = menuMaximumColumns
        value.menuActions = menuActions.compactMap { WYChatAction(rawValue: $0.intValue) }
        value.bottomDistance = bottomDistance
        value.automaticallyInsertsSentMessages = automaticallyInsertsSentMessages
        value.unsupportedMessageText = unsupportedMessageText
        value.customCellClasses = customCellClasses
        value.imageLoader = imageLoader.map { source in { asset, image, identifier in source(WYChatAssetsModelObjC(asset), image, identifier) } }
        value.messageConfiguration = messageConfiguration.map { source in { message, config in source(WYChatMessageModelObjC(message), WYChatConfigObjC(config)).toValue() } }
        value.actionTitle = actionTitle
        value.allowsAction = allowsAction.map { source in { action, message in source(action, WYChatMessageModelObjC(message)) } }
        value.keyboardDismissMode = keyboardDismissMode
        value.showsSelectionToolbar = showsSelectionToolbar
        value.selectionCancelText = selectionCancelText
        return value
    }
}

@objc(WYChatRecordingCountdownConfig)
@objcMembers public class WYChatRecordingCountdownConfigObjC: NSObject {
    /// 倒计时文字距容器左右边缘的最小距离
    public var horizontalInset: CGFloat
    /// 倒计时文字对齐方式
    public var textAlignment: NSTextAlignment
    /// 倒计时最大行数，0表示不限
    public var maximumNumberOfLines: Int
    /// 剩余多少秒时开始显示，0 或负值关闭倒计时
    public var leadTime: Int
    /// 提示文案，用 {seconds} 表示剩余秒数
    public var text: String
    public var font: UIFont
    public var textColor: UIColor
    public var backgroundColor: UIColor
    public var spacing: CGFloat

    public override convenience init() { self.init(WYChatRecordingCountdownConfig()) }

    @nonobjc public init(_ value: WYChatRecordingCountdownConfig) {
        horizontalInset = value.horizontalInset
        textAlignment = value.textAlignment
        maximumNumberOfLines = value.maximumNumberOfLines
        leadTime = value.leadTime
        text = value.text
        font = value.font
        textColor = value.textColor
        backgroundColor = value.backgroundColor
        spacing = value.spacing
    }

    @nonobjc public var swiftValue: WYChatRecordingCountdownConfig {
        var value = WYChatRecordingCountdownConfig()
        value.horizontalInset = horizontalInset
        value.textAlignment = textAlignment
        value.maximumNumberOfLines = maximumNumberOfLines
        value.leadTime = leadTime
        value.text = text
        value.font = font
        value.textColor = textColor
        value.backgroundColor = backgroundColor
        value.spacing = spacing
        return value
    }
}

@objc(WYRecordAnimationConfig)
@objcMembers public class WYRecordAnimationConfigObjC: NSObject {
    /// 渐变录音界面录音状态的无障碍值
    public var gradientRecordingAccessibilityValue: String
    /// 渐变录音界面取消状态的无障碍值
    public var gradientCancelAccessibilityValue: String
    /// 录音滑动操作提示的对齐方式
    public var moveUpTipsTextAlignment: NSTextAlignment
    /// 录音滑动操作按钮标题的对齐方式
    public var moveUpButtonTextAlignment: NSTextAlignment
    /// 系统实时识别准备就绪前保留音频的时长，0 表示关闭缓存
    public var speechRecognitionPreflightBufferDuration: TimeInterval
    /// 分区录音底部提示文字的对齐方式
    public var recordingInteriorTitleAlignment: NSTextAlignment
    /// 弧形录音正在录音或取消时提示文字的对齐方式
    public var recordingHintAlignment: NSTextAlignment
    /// 弧形录音进入转写区域时提示文字的对齐方式
    public var recordingTransferHintAlignment: NSTextAlignment
    /// 是否由内置录音器配置并激活音频会话，关闭后由接入方管理
    public var managesRecordingAudioSession: Bool
    /// 内置录音的音频会话类别，可使用 AVAudioSession.Category 的原始值
    public var recordingAudioSessionCategory: String
    /// 内置录音的音频会话模式，可使用 AVAudioSession.Mode 的原始值
    public var recordingAudioSessionMode: String
    /// AVAudioSession.CategoryOptions 的组合原始值，nil 使用当前内置录音器的默认路由
    public var recordingAudioSessionCategoryOptions: NSNumber?
    /// 普通内置录音结束后是否停用音频会话，默认继续保持活跃
    public var deactivatesAudioSessionAfterClassicRecording: Bool
    /// 录音会话停用时是否通知其他音频会话恢复
    public var notifiesOthersWhenDeactivatingRecordingSession: Bool
    /// 实时录音收到音频会话中断通知时是否结束
    public var stopsRecordingOnAudioInterruption: Bool
    /// 实时录音时音频设备断开是否结束录音
    public var stopsRecordingWhenAudioDeviceDisconnects: Bool
    /// 内置录音文件扩展名，nil 按录音编码选取容器
    public var recordingFileExtension: String?
    /// 内置实时录音和识别回放使用的缓冲帧数，有效范围1到65536
    public var audioBufferFrameCount: Int
    /// 内置流动幅度占渐变宽高的最大比例
    public var gradientMotionMaximumAmplitudeRatio: CGFloat
    /// 内置渐变流动的最大扰动强度
    public var gradientMotionMaximumTurbulence: CGFloat
    /// 按下光点渐变的停靠位置
    public var gradientPressLocations: [NSNumber]
    /// 按下光点各停靠位置的相对透明度
    public var gradientPressOpacities: [NSNumber]
    /// 按下光点渐变起点，采用单位坐标
    public var gradientPressStartPoint: CGPoint
    /// 按下光点渐变终点，采用单位坐标
    public var gradientPressEndPoint: CGPoint
    /// 按下光点出现动画的起始缩放比例
    public var gradientPressEntranceScale: CGFloat
    /// 渐变流动动画的目标帧率
    public var gradientMotionFramesPerSecond: Int
    /// 内置渐变流动的采样网格尺寸，每边为2到256
    public var gradientMotionRenderSize: CGSize
    /// 按动画周期进度和显示尺寸生成自定义透明遮罩，返回nil时使用内置流动
    public var gradientMotionMaskProvider: ((_ phase: TimeInterval, _ size: CGSize) -> UIImage?)?
    /// 渐变录音提示文字对齐方式
    public var gradientHintTextAlignment: NSTextAlignment
    /// 渐变录音提示最大行数，0表示不限
    public var gradientHintNumberOfLines: Int
    /// 转写失败提示文字的对齐方式
    public var recognitionFailureTextAlignment: NSTextAlignment
    /// 录音面板进入动画的弹簧阻尼
    public var overlayShowDamping: CGFloat
    /// 录音面板退出动画的弹簧阻尼
    public var overlayHideDamping: CGFloat
    /// 录音面板进出动画的初始弹簧速度
    public var overlaySpringVelocity: CGFloat
    /// 转写编辑器操作标题最小缩放比例
    public var recognitionControlMinimumScaleFactor: CGFloat
    /// 转写气泡箭头与气泡边缘的重叠长度
    public var recognitionBubbleArrowOverlap: CGFloat
    /// 实时录音进度通知的最小间隔，单位秒
    public var recordingProgressInterval: TimeInterval
    /// 录音面板进入动画时长，单位秒
    public var overlayShowDuration: TimeInterval
    /// 录音面板退出动画时长，单位秒
    public var overlayHideDuration: TimeInterval
    /// 录音面板状态变化动画时长，单位秒
    public var overlayStatusAnimationDuration: TimeInterval
    /// 转写编辑器等待键盘布局通知的时长，单位秒
    public var recognitionKeyboardNotificationTimeout: TimeInterval
    /// 转写编辑器的键盘按钮标题及无障碍标签
    public var recognitionKeyboardText: String
    /// 转写编辑器的表情按钮标题及无障碍标签
    public var recognitionEmojiText: String
    /// 追加到默认录音引导后的上滑取消提示
    public var gradientCancelInstruction: String
    /// 外部录音实现缺少必要方法时的错误说明
    public var missingRecorderText: String
    /// 录音时间太短时的错误说明
    public var shortRecordingText: String
    /// 录音文件无效或录音时间太短时的错误说明
    public var invalidRecordingText: String
    /// 语音识别未启用时的错误说明
    public var recognitionDisabledText: String
    /// 录音文件不存在时的错误说明
    public var recordingNotFoundText: String
    /// 语音识别超时时的错误说明
    public var recognitionTimeoutText: String
    /// 未配置外部语音识别实现时的错误说明
    public var recognitionMissingProviderText: String
    /// 不支持当前识别语言时的错误说明
    public var recognitionUnsupportedLanguageText: String
    /// 缺少语音识别权限用途说明时的错误说明
    public var recognitionMissingUsageDescriptionText: String
    /// 没有语音识别权限时的错误说明
    public var recognitionAuthorizationDeniedText: String
    /// 当前语言的语音识别不可用时的错误说明
    public var recognitionUnavailableText: String
    /// 当前设备或语言不支持本地识别时的错误说明
    public var recognitionOnDeviceUnavailableText: String
    /// 没有识别到文字时的错误说明
    public var recognitionEmptyResultText: String
    /// 语音模式「按住 说话」的录音界面，默认分区操作
    public var interactionStyle: WYRecordingInteractionStyle
    /// 渐变录音区域高度
    public var gradientHeight: CGFloat
    /// 渐变录音普通状态主色
    public var gradientRecordingColor: UIColor
    /// 渐变录音取消状态主色
    public var gradientCancelColor: UIColor
    /// 渐变录音区域以外的遮罩颜色
    public var gradientOverlayColor: UIColor
    /// 渐变中心位置，使用0到1的相对坐标
    public var gradientStartPoint: CGPoint
    /// 渐变外边缘位置，使用相对坐标
    public var gradientEndPoint: CGPoint
    /// 渐变颜色位置，升序排列且取值0到1，数量与gradientColorOpacities一致
    public var gradientColorLocations: [NSNumber]
    /// 渐变各位置的不透明度，取值0到1，数量与gradientColorLocations一致
    public var gradientColorOpacities: [NSNumber]
    /// 是否持续播放渐变流动动画，默认true
    public var gradientMotionEnabled: Bool
    /// 渐变流动的时间尺度，单位秒，非正数时停止动画
    public var gradientMotionDuration: TimeInterval
    /// 渐变流动的水平和垂直移动幅度
    public var gradientMotionAmplitude: CGSize
    /// 渐变流动的纹理强度，取值0到0.5
    public var gradientMotionScale: CGFloat
    /// 渐变流动亮部颜色
    public var gradientMotionHighlightColor: UIColor
    /// 渐变流动暗部颜色
    public var gradientMotionShadowColor: UIColor
    /// 渐变流动亮部不透明度，取值0到1
    public var gradientMotionHighlightOpacity: CGFloat
    /// 渐变流动暗部不透明度，取值0到1
    public var gradientMotionShadowOpacity: CGFloat
    /// 是否显示跟随手指的渐变按压效果，默认true
    public var gradientPressEnabled: Bool
    /// 渐变按压光晕的固定尺寸，单位pt
    public var gradientPressSize: CGSize
    /// 渐变按压效果的颜色
    public var gradientPressColor: UIColor
    /// 渐变按压效果的不透明度，取值0到1
    public var gradientPressOpacity: CGFloat
    /// 渐变按压效果跟随手指移动的过渡时长，单位秒，默认为0（直接跟随）
    public var gradientPressFollowingDuration: TimeInterval
    /// 渐变录音声波两端淡出的宽度比例，取值0到0.5
    public var gradientWaveformEdgeFade: CGFloat
    /// 渐变录音声波区域尺寸
    public var gradientWaveformSize: CGSize
    /// 渐变录音声波距离底部安全区的间距
    public var gradientWaveformBottomOffset: CGFloat
    /// 渐变录音提示距离声波顶部的间距
    public var gradientHintSpacing: CGFloat
    /// 渐变录音普通状态提示，空字符串时根据录音用途显示提示
    public var gradientRecordingHint: String
    /// 渐变录音取消状态提示
    public var gradientCancelHint: String
    /// 渐变录音提示字体
    public var gradientHintFont: UIFont
    /// 渐变录音普通状态提示颜色
    public var gradientHintColor: UIColor
    /// 渐变录音取消状态提示颜色
    public var gradientCancelHintColor: UIColor
    /// 渐变录音取消状态声波颜色
    public var gradientCancelWaveformColor: UIColor
    /// 渐变录音提示文字边距
    public var gradientHintInsets: UIEdgeInsets
    /// 渐变录音从长按起点向上滑动进入取消的距离
    public var gradientCancelDistance: CGFloat
    /// 渐变录音状态过渡时长，单位秒
    public var gradientTransitionDuration: TimeInterval
    /// 渐变录音声波动画配置
    public var gradientWaveform: WYSoundWaveConfigObjC

    /// 录音浮层遮罩颜色
    public var overlayBackgroundColor: UIColor
    /// 录音及转写气泡的自定义箭头图片，nil时使用气泡箭头
    public var bubbleArrowImage: UIImage?
    /// 录音及转写气泡的自定义箭头图片颜色，nil时保留图片颜色
    public var bubbleArrowImageTintColor: UIColor?
    /// 录音及转写气泡的自定义箭头图片偏移
    public var bubbleArrowImageOffset: CGPoint
    /// 录音提示距离声波气泡底部的间距
    public var recordingHintSpacing: CGFloat
    /// 直接转写录音时的松手提示
    public var dictationReleaseText: String

    /// 录音操作按钮外观，默认弧形条状
    public var actionStyle: WYRecordingActionStyle
    /// 弧形操作按钮尺寸
    public var curvedActionSize: CGSize
    /// 弧形操作按钮圆角
    public var curvedActionCornerRadius: CGFloat
    /// 弧形操作按钮中间向上弯曲的高度，0时为直条
    public var curvedActionBendHeight: CGFloat
    /// 弧形操作按钮文字向屏幕中间的水平偏移
    public var curvedActionTitleOffsetX: CGFloat
    /// 弧形操作按钮倾斜角度，单位弧度
    public var curvedActionTiltAngle: CGFloat
    /// 弧形操作按钮中心相对容器中心的水平距离
    public var curvedActionCenterOffsetX: CGFloat
    /// 弧形操作按钮普通背景色
    public var curvedActionNormalColor: UIColor
    /// 弧形操作按钮选中背景色
    public var curvedActionSelectedColor: UIColor
    /// 是否启用语音识别，默认false
    public var supportSpeechRecognition: Bool
    /// 声波线宽度
    public var soundWavesWidth: CGFloat
    /// 声波线最大高度
    public var soundWavesMaxHeightRecording: CGFloat
    /// 声波线最大高度
    public var soundWavesMaxHeightCancel: CGFloat
    /// 声波线最大高度
    public var soundWavesMaxHeightTransfer: CGFloat
    /// 声波线最小高度
    public var soundWavesMinHeightRecording: CGFloat
    /// 声波线最小高度
    public var soundWavesMinHeightCancel: CGFloat
    /// 声波线最小高度
    public var soundWavesMinHeightTransfer: CGFloat
    /// 声波线之间的间距
    public var soundWavesSpace: CGFloat
    /// 声波显示条数
    public var severalSoundWavesRecording: Int
    /// 声波显示条数
    public var severalSoundWavesCancel: Int
    /// 声波显示条数
    public var severalSoundWavesTransfer: Int
    /// 声波线颜色
    public var colorOfSoundWavesOnRecordingRecording: UIColor
    /// 声波线颜色
    public var colorOfSoundWavesOnRecordingCancel: UIColor
    /// 声波线颜色
    public var colorOfSoundWavesOnRecordingTransfer: UIColor
    /// 录音、取消录音与转文字时气泡控件距离屏幕底部间距
    public var soundWavesViewBottomOffset: CGFloat
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidthRecording: CGFloat
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidthCancel: CGFloat
    /// 录音、取消录音与转文字时气泡控件宽度
    public var soundWavesViewWidthTransfer: CGFloat
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeightRecording: CGFloat
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeightCancel: CGFloat
    /// 录音、取消录音与转文字时气泡控件高度
    public var soundWavesViewHeightTransfer: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡主体圆角半径
    public var cornerRadiusForMoveUpRecording: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡主体圆角半径
    public var cornerRadiusForMoveUpCancel: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡主体圆角半径
    public var cornerRadiusForMoveUpTransfer: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡背景色
    public var backgroundColorForMoveUpRecording: UIColor
    /// 录音、取消录音与转文字时声波动画气泡背景色
    public var backgroundColorForMoveUpCancel: UIColor
    /// 录音、取消录音与转文字时声波动画气泡背景色
    public var backgroundColorForMoveUpTransfer: UIColor
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveUpRecording: UIColor
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveUpCancel: UIColor
    /// 录音、取消录音与转文字时声波动画气泡边框的颜色
    public var borderColorForMoveUpTransfer: UIColor
    /// 录音、取消录音与转文字时声波动画气泡边框宽度
    public var borderWidthForMoveUpRecording: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡边框宽度
    public var borderWidthForMoveUpCancel: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡边框宽度
    public var borderWidthForMoveUpTransfer: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的尺寸（宽度，高度）(宽度是底边长度，高度是尖点到底边的垂直距离)
    public var arrowSizeForMoveUpRecording: CGSize
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的尺寸（宽度，高度）(宽度是底边长度，高度是尖点到底边的垂直距离)
    public var arrowSizeForMoveUpCancel: CGSize
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的尺寸（宽度，高度）(宽度是底边长度，高度是尖点到底边的垂直距离)
    public var arrowSizeForMoveUpTransfer: CGSize
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的圆角半径
    public var arrowTipRadiusForMoveUpRecording: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的圆角半径
    public var arrowTipRadiusForMoveUpCancel: CGFloat
    /// 录音、取消录音与转文字时声波动画气泡三角箭头的圆角半径
    public var arrowTipRadiusForMoveUpTransfer: CGFloat
    /// 转文字及显示实时文本时声波距离气泡右侧与底部的间距
    public var soundWavesRightOffsetForAirBubble: CGPoint
    /// 取消按钮背景图
    public var cancelRecordViewImageOnInterior: UIImage
    /// 取消按钮背景图
    public var cancelRecordViewImageOnExternal: UIImage
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewTextOnInterior: String
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewTextTips: String
    /// 转文字按钮内部文本和提示文本
    public var transferViewTextOnInterior: String
    /// 转文字按钮内部文本和提示文本
    public var transferViewTextTips: String
    /// 录音按钮提示文本
    public var recordViewTipsOnInterior: String
    /// 录音按钮提示文本
    public var recordViewTipsOnExternal: String
    /// 转文字按钮背景图
    public var transferViewImageOnInterior: UIImage
    /// 转文字按钮背景图
    public var transferViewImageOnExternal: UIImage
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveUpFont: UIFont
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveUpColor: UIColor
    /// 录音按钮提示语内部字体及色值
    public var recordViewTipsInfoForInteriorFont: UIFont
    /// 录音按钮提示语内部字体及色值
    public var recordViewTipsInfoForInteriorColor: UIColor
    /// 录音按钮提示语外部字体及色值
    public var recordViewTipsInfoForExternalFont: UIFont
    /// 录音按钮提示语外部字体及色值
    public var recordViewTipsInfoForExternalColor: UIColor
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInteriorFont: UIFont
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInteriorColor: UIColor
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternalFont: UIFont
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternalColor: UIColor
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInteriorFont: UIFont
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInteriorColor: UIColor
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternalFont: UIFont
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternalColor: UIColor
    /// 取消录音按钮和转文字按钮的偏转角度
    public var moveUpViewDeviationAngle: CGFloat
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat
    /// 圆形样式的录音提示距离底部操作区顶部的间距
    public var recordTipViewTopOffset: CGFloat
    /// 取消录音或者语音转文字按钮直径
    public var moveUpButtonDiameterOnInterior: CGFloat
    /// 取消录音或者语音转文字按钮直径
    public var moveUpButtonDiameterOnExternal: CGFloat
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveUpButtonOffsetTop: CGFloat
    /// 取消录音或者语音转文字按钮中心点距离 声波动画控件底部 与 底部圆弧顶点 的间距
    public var moveUpButtonOffsetBottom: CGFloat
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveUpButtonCenterOffsetYOnInterior: CGFloat
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveUpButtonCenterOffsetYOnExternal: CGFloat
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距(如果supportSpeechRecognition为false，则此属性无效，内部会强制水平居中)
    public var moveUpButtonCenterOffsetX: CGFloat
    /// 声波动画操作区切换时是否需要震动反馈
    public var vibrationFeedback: Bool
    /// 声波动画操作区边缘颜色
    public var strokeColor: UIColor
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColorOnInterior: UIColor
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColorOnExternal: UIColor
    /// 声波动画操作区阴影位置，(0, 0)时四周都有阴影
    public var shadowOffset: CGSize
    /// 声波动画操作区阴影颜色
    public var shadowColor: UIColor
    /// 声波动画操作区阴影透明度
    public var shadowOpacity: CGFloat
    /// 最多可以录制多少秒(最短和最长录音时间)
    public var recordTimeMin: TimeInterval
    /// 最多可以录制多少秒(最短和最长录音时间)
    public var recordTimeMax: TimeInterval
    /// 长按发语音的倒计时
    public var voiceCountdown: WYChatRecordingCountdownConfigObjC
    /// 长按直接转写或滑到转文字区域的倒计时
    public var dictationCountdown: WYChatRecordingCountdownConfigObjC
    /// 点击输入框内语音输入按钮的倒计时
    public var keyboardDictationCountdown: WYChatRecordingCountdownConfigObjC
    /// 普通语音录音区是否显示实时文本，默认false，滑入转文字后显示
    public var showsLiveTextWhileRecording: Bool
    /// 实时转写文本距离气泡边缘的间距
    public var liveTextInsets: UIEdgeInsets
    /// 实时转写文本与底部声波的间距
    public var liveTextWaveformSpacing: CGFloat
    /// 直接转写在录音区松手后是否发送文本，默认true，false时进入编辑
    public var dictationSendsOnRelease: Bool
    /// 直接转写的编辑操作文字
    public var dictationEditText: String
    /// 直接转写是否显示声波，默认true
    public var dictationShowsWaveform: Bool
    /// 转写编辑时是否显示发送原语音按钮，默认true
    public var showsOriginalVoiceButton: Bool
    /// 发送原语音按钮文字
    public var recognitionSendVoiceText: String
    /// 语音识别来源，默认使用Apple
    public var speechRecognitionSource: WYChatSpeechRecognitionSource
    /// 语音识别时机，默认边录音边识别
    public var speechRecognitionMode: WYChatSpeechRecognitionMode
    /// 外部语音识别实现
    public var speechRecognitionProvider: WYChatSpeechRecognizer?
    /// 外部录音实现，nil时使用内置采集
    public var recorder: WYChatRecorder?
    /// 识别语言
    public var speechLocaleIdentifier: String
    /// 是否只允许本地识别，默认false
    public var requiresOnDeviceRecognition: Bool
    /// 识别超时，单位秒
    public var speechRecognitionTimeout: TimeInterval
    /// 自定义录音设置，空字典时使用AAC单声道设置
    public var recordSettings: [String: Any]
    /// 录音面板动画时长
    public var animationDuration: TimeInterval
    /// 转写失败提示
    public var recognitionFailureText: String
    public var recognitionFailureImage: UIImage?
    public var recognitionFailureColor: UIColor
    public var recognitionFailureBackgroundColor: UIColor
    public var recognitionPanelAnchorsToBottom: Bool
    public var recognitionPanelShowsArrow: Bool
    public var recognitionCentersFailurePanel: Bool
    public var recognitionAutomaticallyFocusesText: Bool
    public var recognitionSendsOnReturn: Bool
    public var showsRecognitionRetryButton: Bool
    public var recognitionOverlayBackgroundColor: UIColor?
    public var recognitionEditorAppearance: ((_ panel: UIStackView, _ textView: UITextView, _ resultView: WYAirBubbleView, _ failureLabel: UILabel, _ failureIcon: UIImageView) -> Void)?
    public var recognitionDisabledActionOpacity: CGFloat
    public var transcriptTranslationHandler: ((_ editor: WYRecordAnimationView, _ action: WYChatTranscriptTranslationAction, _ requestID: String, _ text: String, _ sourceLocaleIdentifier: String?, _ targetLocaleIdentifier: String) -> Void)?
    public var translationReadAloudText: String
    public var translationChangeLanguageText: String
    public var translationCancelText: String
    public var showsTranslationReadAloudButton: Bool
    public var showsTranslationChangeLanguageButton: Bool
    public var showsTranslationCancelButton: Bool
    /// 转写等待提示
    public var recognizingText: String
    /// 转写确认按钮文字
    public var recognitionSendText: String
    /// 转写重试按钮文字
    public var recognitionRetryText: String
    /// 转写取消按钮文字
    public var recognitionCancelText: String
    /// 转写编辑字体
    public var recognitionFont: UIFont
    /// 转写编辑文字颜色
    public var recognitionTextColor: UIColor
    /// 转写编辑背景色
    public var recognitionBackgroundColor: UIColor
    /// 转写编辑面板高度
    public var recognitionPanelHeight: CGFloat
    /// 转写编辑最小高度
    public var recognitionMinimumHeight: CGFloat
    /// 转写编辑面板外边距，底部相对键盘顶部
    public var recognitionPanelOuterInsets: UIEdgeInsets
    /// 转写编辑面板内边距
    public var recognitionPanelInsets: UIEdgeInsets
    /// 转写编辑面板圆角
    public var recognitionPanelCornerRadius: CGFloat
    /// 转写编辑控件行高度
    public var recognitionControlHeight: CGFloat
    /// 转写编辑控件间距
    public var recognitionControlSpacing: CGFloat
    /// 转写编辑顶部操作行高度
    public var recognitionHeaderHeight: CGFloat
    /// 转写编辑顶部操作行与气泡的间距
    public var recognitionHeaderSpacing: CGFloat
    /// 转写编辑气泡与底部操作行的间距
    public var recognitionFooterSpacing: CGFloat
    /// 转写编辑发送及原语音按钮宽度，空间不足时自动缩小
    public var recognitionActionWidth: CGFloat
    /// 转写编辑语言及翻译按钮宽度
    public var recognitionHeaderButtonWidth: CGFloat
    /// 转写编辑关闭及表情按钮宽度
    public var recognitionAccessoryWidth: CGFloat
    /// 转写编辑关闭及表情图标尺寸
    public var recognitionAccessoryImageSize: CGFloat
    /// 转写编辑关闭及表情按钮颜色
    public var recognitionAccessoryColor: UIColor
    /// 转写编辑发送按钮文字颜色
    public var recognitionSendColor: UIColor
    /// 转写编辑发送按钮背景色
    public var recognitionSendBackgroundColor: UIColor
    /// 自定义转写编辑控件，参数为操作和已应用默认外观的按钮
    public var recognitionControlAppearance: ((_ control: WYChatRecordingEditorControl, _ button: UIButton) -> Void)?
    /// 转写编辑按钮字体
    public var recognitionControlFont: UIFont
    /// 转写编辑按钮颜色
    public var recognitionControlColor: UIColor
    /// 转写编辑按钮背景色
    public var recognitionControlBackgroundColor: UIColor
    /// 转写编辑按钮圆角
    public var recognitionControlCornerRadius: CGFloat
    /// 转写编辑文字内边距
    public var recognitionTextInsets: UIEdgeInsets
    /// 转写编辑文本背景色
    public var recognitionTextBackgroundColor: UIColor
    /// 转写编辑关闭图标，nil时只显示文字
    public var recognitionCloseImage: UIImage?
    /// 转写编辑表情图标
    public var recognitionEmojiImage: UIImage?
    /// 转写编辑键盘图标
    public var recognitionKeyboardImage: UIImage?
    /// 转写编辑是否显示表情按钮，默认true
    public var showsRecognitionEmojiButton: Bool
    /// 转写编辑表情配置
    public var recognitionEmoji: WYEmojiViewConfigObjC
    /// 转写编辑是否显示识别语言按钮，默认false
    public var showsRecognitionLanguageButton: Bool
    /// 识别语言列表，空数组时Apple使用系统支持的语言，外部识别仅显示当前语言
    public var speechRecognitionLanguages: [String]
    /// 识别语言按钮文字
    public var recognitionLanguageText: String
    /// 是否启用外部文本翻译，默认false
    public var enablesTranslation: Bool
    /// 外部文本翻译服务
    public var translationProvider: WYChatTextTranslator?
    /// 翻译源语言，nil时自动识别
    public var translationSourceLocaleIdentifier: String?
    /// 翻译目标语言
    public var translationTargetLocaleIdentifier: String
    /// 翻译目标语言列表，空数组时使用translationTargetLocaleIdentifier
    public var translationTargetLanguages: [String]
    /// 翻译超时，单位秒
    public var translationTimeout: TimeInterval
    /// 翻译失败提示
    public var translationFailureText: String
    /// 翻译等待提示
    public var translationWaitingText: String
    /// 翻译按钮文字
    public var translationText: String
    /// 录音文件保存地址
    public var chatAudioUrl: URL

    public override convenience init() { self.init(WYRecordAnimationConfig()) }

    @nonobjc public init(_ value: WYRecordAnimationConfig) {
        self.gradientRecordingAccessibilityValue = value.gradientRecordingAccessibilityValue
        self.gradientCancelAccessibilityValue = value.gradientCancelAccessibilityValue
        self.moveUpTipsTextAlignment = value.moveUpTipsTextAlignment
        self.moveUpButtonTextAlignment = value.moveUpButtonTextAlignment
        self.speechRecognitionPreflightBufferDuration = value.speechRecognitionPreflightBufferDuration
        self.recordingInteriorTitleAlignment = value.recordingInteriorTitleAlignment
        self.recordingHintAlignment = value.recordingHintAlignment
        self.recordingTransferHintAlignment = value.recordingTransferHintAlignment
        self.managesRecordingAudioSession = value.managesRecordingAudioSession
        self.recordingAudioSessionCategory = value.recordingAudioSessionCategory
        self.recordingAudioSessionMode = value.recordingAudioSessionMode
        self.recordingAudioSessionCategoryOptions = value.recordingAudioSessionCategoryOptions.map { NSNumber(value: $0) }
        self.deactivatesAudioSessionAfterClassicRecording = value.deactivatesAudioSessionAfterClassicRecording
        self.notifiesOthersWhenDeactivatingRecordingSession = value.notifiesOthersWhenDeactivatingRecordingSession
        self.stopsRecordingOnAudioInterruption = value.stopsRecordingOnAudioInterruption
        self.stopsRecordingWhenAudioDeviceDisconnects = value.stopsRecordingWhenAudioDeviceDisconnects
        self.recordingFileExtension = value.recordingFileExtension
        self.audioBufferFrameCount = value.audioBufferFrameCount
        self.gradientMotionMaximumAmplitudeRatio = value.gradientMotionMaximumAmplitudeRatio
        self.gradientMotionMaximumTurbulence = value.gradientMotionMaximumTurbulence
        self.gradientPressLocations = value.gradientPressLocations.map { NSNumber(value: Double($0)) }
        self.gradientPressOpacities = value.gradientPressOpacities.map { NSNumber(value: Double($0)) }
        self.gradientPressStartPoint = value.gradientPressStartPoint
        self.gradientPressEndPoint = value.gradientPressEndPoint
        self.gradientPressEntranceScale = value.gradientPressEntranceScale
        self.gradientMotionFramesPerSecond = value.gradientMotionFramesPerSecond
        self.gradientMotionRenderSize = value.gradientMotionRenderSize
        self.gradientMotionMaskProvider = value.gradientMotionMaskProvider
        self.gradientHintTextAlignment = value.gradientHintTextAlignment
        self.gradientHintNumberOfLines = value.gradientHintNumberOfLines
        self.recognitionFailureTextAlignment = value.recognitionFailureTextAlignment
        self.overlayShowDamping = value.overlayShowDamping
        self.overlayHideDamping = value.overlayHideDamping
        self.overlaySpringVelocity = value.overlaySpringVelocity
        self.recognitionControlMinimumScaleFactor = value.recognitionControlMinimumScaleFactor
        self.recognitionBubbleArrowOverlap = value.recognitionBubbleArrowOverlap
        self.recordingProgressInterval = value.recordingProgressInterval
        self.overlayShowDuration = value.overlayShowDuration
        self.overlayHideDuration = value.overlayHideDuration
        self.overlayStatusAnimationDuration = value.overlayStatusAnimationDuration
        self.recognitionKeyboardNotificationTimeout = value.recognitionKeyboardNotificationTimeout
        self.recognitionKeyboardText = value.recognitionKeyboardText
        self.recognitionEmojiText = value.recognitionEmojiText
        self.gradientCancelInstruction = value.gradientCancelInstruction
        self.missingRecorderText = value.missingRecorderText
        self.shortRecordingText = value.shortRecordingText
        self.invalidRecordingText = value.invalidRecordingText
        self.recognitionDisabledText = value.recognitionDisabledText
        self.recordingNotFoundText = value.recordingNotFoundText
        self.recognitionTimeoutText = value.recognitionTimeoutText
        self.recognitionMissingProviderText = value.recognitionMissingProviderText
        self.recognitionUnsupportedLanguageText = value.recognitionUnsupportedLanguageText
        self.recognitionMissingUsageDescriptionText = value.recognitionMissingUsageDescriptionText
        self.recognitionAuthorizationDeniedText = value.recognitionAuthorizationDeniedText
        self.recognitionUnavailableText = value.recognitionUnavailableText
        self.recognitionOnDeviceUnavailableText = value.recognitionOnDeviceUnavailableText
        self.recognitionEmptyResultText = value.recognitionEmptyResultText
        self.overlayBackgroundColor = value.overlayBackgroundColor
        self.bubbleArrowImage = value.bubbleArrowImage
        self.bubbleArrowImageTintColor = value.bubbleArrowImageTintColor
        self.bubbleArrowImageOffset = value.bubbleArrowImageOffset
        self.recordingHintSpacing = value.recordingHintSpacing
        self.dictationReleaseText = value.dictationReleaseText
        self.gradientRecordingHint = value.gradientRecordingHint
        self.gradientCancelHint = value.gradientCancelHint
        self.gradientWaveformEdgeFade = value.gradientWaveformEdgeFade
        self.gradientColorLocations = value.gradientColorLocations.map { NSNumber(value: Double($0)) }
        self.gradientColorOpacities = value.gradientColorOpacities.map { NSNumber(value: Double($0)) }
        self.gradientMotionEnabled = value.gradientMotionEnabled
        self.gradientMotionDuration = value.gradientMotionDuration
        self.gradientMotionAmplitude = value.gradientMotionAmplitude
        self.gradientMotionScale = value.gradientMotionScale
        self.gradientMotionHighlightColor = value.gradientMotionHighlightColor
        self.gradientMotionShadowColor = value.gradientMotionShadowColor
        self.gradientMotionHighlightOpacity = value.gradientMotionHighlightOpacity
        self.gradientMotionShadowOpacity = value.gradientMotionShadowOpacity
        self.gradientPressEnabled = value.gradientPressEnabled
        self.gradientPressSize = value.gradientPressSize
        self.gradientPressColor = value.gradientPressColor
        self.gradientPressOpacity = value.gradientPressOpacity
        self.gradientPressFollowingDuration = value.gradientPressFollowingDuration
        self.interactionStyle = value.interactionStyle
        self.gradientHeight = value.gradientHeight
        self.gradientRecordingColor = value.gradientRecordingColor
        self.gradientCancelColor = value.gradientCancelColor
        self.gradientOverlayColor = value.gradientOverlayColor
        self.gradientStartPoint = value.gradientStartPoint
        self.gradientEndPoint = value.gradientEndPoint
        self.gradientWaveformSize = value.gradientWaveformSize
        self.gradientWaveformBottomOffset = value.gradientWaveformBottomOffset
        self.gradientHintSpacing = value.gradientHintSpacing
        self.gradientHintFont = value.gradientHintFont
        self.gradientHintColor = value.gradientHintColor
        self.gradientCancelHintColor = value.gradientCancelHintColor
        self.gradientCancelWaveformColor = value.gradientCancelWaveformColor
        self.gradientHintInsets = value.gradientHintInsets
        self.gradientCancelDistance = value.gradientCancelDistance
        self.gradientTransitionDuration = value.gradientTransitionDuration
        self.gradientWaveform = WYSoundWaveConfigObjC().convertToObjC(value.gradientWaveform)
        self.actionStyle = value.actionStyle
        self.curvedActionSize = value.curvedActionSize
        self.curvedActionCornerRadius = value.curvedActionCornerRadius
        self.curvedActionBendHeight = value.curvedActionBendHeight
        self.curvedActionTitleOffsetX = value.curvedActionTitleOffsetX
        self.curvedActionTiltAngle = value.curvedActionTiltAngle
        self.curvedActionCenterOffsetX = value.curvedActionCenterOffsetX
        self.curvedActionNormalColor = value.curvedActionColors.normal
        self.curvedActionSelectedColor = value.curvedActionColors.selected
        self.supportSpeechRecognition = value.supportSpeechRecognition
        self.soundWavesWidth = value.soundWavesWidth
        self.soundWavesMaxHeightRecording = value.soundWavesMaxHeight.recording
        self.soundWavesMaxHeightCancel = value.soundWavesMaxHeight.cancel
        self.soundWavesMaxHeightTransfer = value.soundWavesMaxHeight.transfer
        self.soundWavesMinHeightRecording = value.soundWavesMinHeight.recording
        self.soundWavesMinHeightCancel = value.soundWavesMinHeight.cancel
        self.soundWavesMinHeightTransfer = value.soundWavesMinHeight.transfer
        self.soundWavesSpace = value.soundWavesSpace
        self.severalSoundWavesRecording = value.severalSoundWaves.recording
        self.severalSoundWavesCancel = value.severalSoundWaves.cancel
        self.severalSoundWavesTransfer = value.severalSoundWaves.transfer
        self.colorOfSoundWavesOnRecordingRecording = value.colorOfSoundWavesOnRecording.recording
        self.colorOfSoundWavesOnRecordingCancel = value.colorOfSoundWavesOnRecording.cancel
        self.colorOfSoundWavesOnRecordingTransfer = value.colorOfSoundWavesOnRecording.transfer
        self.soundWavesViewBottomOffset = value.soundWavesViewBottomOffset
        self.soundWavesViewWidthRecording = value.soundWavesViewWidth.recording
        self.soundWavesViewWidthCancel = value.soundWavesViewWidth.cancel
        self.soundWavesViewWidthTransfer = value.soundWavesViewWidth.transfer
        self.soundWavesViewHeightRecording = value.soundWavesViewHeight.recording
        self.soundWavesViewHeightCancel = value.soundWavesViewHeight.cancel
        self.soundWavesViewHeightTransfer = value.soundWavesViewHeight.transfer
        self.cornerRadiusForMoveUpRecording = value.cornerRadiusForMoveUp.recording
        self.cornerRadiusForMoveUpCancel = value.cornerRadiusForMoveUp.cancel
        self.cornerRadiusForMoveUpTransfer = value.cornerRadiusForMoveUp.transfer
        self.backgroundColorForMoveUpRecording = value.backgroundColorForMoveUp.recording
        self.backgroundColorForMoveUpCancel = value.backgroundColorForMoveUp.cancel
        self.backgroundColorForMoveUpTransfer = value.backgroundColorForMoveUp.transfer
        self.borderColorForMoveUpRecording = value.borderColorForMoveUp.recording
        self.borderColorForMoveUpCancel = value.borderColorForMoveUp.cancel
        self.borderColorForMoveUpTransfer = value.borderColorForMoveUp.transfer
        self.borderWidthForMoveUpRecording = value.borderWidthForMoveUp.recording
        self.borderWidthForMoveUpCancel = value.borderWidthForMoveUp.cancel
        self.borderWidthForMoveUpTransfer = value.borderWidthForMoveUp.transfer
        self.arrowSizeForMoveUpRecording = value.arrowSizeForMoveUp.recording
        self.arrowSizeForMoveUpCancel = value.arrowSizeForMoveUp.cancel
        self.arrowSizeForMoveUpTransfer = value.arrowSizeForMoveUp.transfer
        self.arrowTipRadiusForMoveUpRecording = value.arrowTipRadiusForMoveUp.recording
        self.arrowTipRadiusForMoveUpCancel = value.arrowTipRadiusForMoveUp.cancel
        self.arrowTipRadiusForMoveUpTransfer = value.arrowTipRadiusForMoveUp.transfer
        self.soundWavesRightOffsetForAirBubble = value.soundWavesRightOffsetForAirBubble
        self.cancelRecordViewImageOnInterior = value.cancelRecordViewImage.onInterior
        self.cancelRecordViewImageOnExternal = value.cancelRecordViewImage.onExternal
        self.cancelRecordViewTextOnInterior = value.cancelRecordViewText.onInterior
        self.cancelRecordViewTextTips = value.cancelRecordViewText.tips
        self.transferViewTextOnInterior = value.transferViewText.onInterior
        self.transferViewTextTips = value.transferViewText.tips
        self.recordViewTipsOnInterior = value.recordViewTips.onInterior
        self.recordViewTipsOnExternal = value.recordViewTips.onExternal
        self.transferViewImageOnInterior = value.transferViewImage.onInterior
        self.transferViewImageOnExternal = value.transferViewImage.onExternal
        self.tipsInfoForMoveUpFont = value.tipsInfoForMoveUp.font
        self.tipsInfoForMoveUpColor = value.tipsInfoForMoveUp.color
        self.recordViewTipsInfoForInteriorFont = value.recordViewTipsInfoForInterior.font
        self.recordViewTipsInfoForInteriorColor = value.recordViewTipsInfoForInterior.color
        self.recordViewTipsInfoForExternalFont = value.recordViewTipsInfoForExternal.font
        self.recordViewTipsInfoForExternalColor = value.recordViewTipsInfoForExternal.color
        self.cancelRecordViewTextInfoForInteriorFont = value.cancelRecordViewTextInfoForInterior.font
        self.cancelRecordViewTextInfoForInteriorColor = value.cancelRecordViewTextInfoForInterior.color
        self.cancelRecordViewTextInfoForExternalFont = value.cancelRecordViewTextInfoForExternal.font
        self.cancelRecordViewTextInfoForExternalColor = value.cancelRecordViewTextInfoForExternal.color
        self.transferViewTextInfoForInteriorFont = value.transferViewTextInfoForInterior.font
        self.transferViewTextInfoForInteriorColor = value.transferViewTextInfoForInterior.color
        self.transferViewTextInfoForExternalFont = value.transferViewTextInfoForExternal.font
        self.transferViewTextInfoForExternalColor = value.transferViewTextInfoForExternal.color
        self.moveUpViewDeviationAngle = value.moveUpViewDeviationAngle
        self.arcRadian = value.arcRadian
        self.areaHeight = value.areaHeight
        self.recordViewBottomOffset = value.recordViewBottomOffset
        self.recordTipViewTopOffset = value.recordTipViewTopOffset
        self.moveUpButtonDiameterOnInterior = value.moveUpButtonDiameter.onInterior
        self.moveUpButtonDiameterOnExternal = value.moveUpButtonDiameter.onExternal
        self.moveUpButtonOffsetTop = value.moveUpButtonOffset.top
        self.moveUpButtonOffsetBottom = value.moveUpButtonOffset.bottom
        self.moveUpButtonCenterOffsetYOnInterior = value.moveUpButtonCenterOffsetY.onInterior
        self.moveUpButtonCenterOffsetYOnExternal = value.moveUpButtonCenterOffsetY.onExternal
        self.moveUpButtonCenterOffsetX = value.moveUpButtonCenterOffsetX
        self.vibrationFeedback = value.vibrationFeedback
        self.strokeColor = value.strokeColor
        self.fillColorOnInterior = value.fillColor.onInterior
        self.fillColorOnExternal = value.fillColor.onExternal
        self.shadowOffset = value.shadowOffset
        self.shadowColor = value.shadowColor
        self.shadowOpacity = value.shadowOpacity
        self.recordTimeMin = value.recordTime.min
        self.recordTimeMax = value.recordTime.max
        self.voiceCountdown = WYChatRecordingCountdownConfigObjC(value.voiceCountdown)
        self.dictationCountdown = WYChatRecordingCountdownConfigObjC(value.dictationCountdown)
        self.keyboardDictationCountdown = WYChatRecordingCountdownConfigObjC(value.keyboardDictationCountdown)
        self.showsLiveTextWhileRecording = value.showsLiveTextWhileRecording
        self.liveTextInsets = value.liveTextInsets
        self.liveTextWaveformSpacing = value.liveTextWaveformSpacing
        self.dictationSendsOnRelease = value.dictationSendsOnRelease
        self.dictationEditText = value.dictationEditText
        self.dictationShowsWaveform = value.dictationShowsWaveform
        self.showsOriginalVoiceButton = value.showsOriginalVoiceButton
        self.recognitionSendVoiceText = value.recognitionSendVoiceText
        self.speechRecognitionSource = value.speechRecognitionSource
        self.speechRecognitionMode = value.speechRecognitionMode
        self.speechRecognitionProvider = value.speechRecognitionProvider
        self.recorder = value.recorder
        self.speechLocaleIdentifier = value.speechLocaleIdentifier
        self.requiresOnDeviceRecognition = value.requiresOnDeviceRecognition
        self.speechRecognitionTimeout = value.speechRecognitionTimeout
        self.recordSettings = value.recordSettings
        self.animationDuration = value.animationDuration
        self.recognitionFailureText = value.recognitionFailureText
        recognitionFailureImage = value.recognitionFailureImage
        recognitionFailureColor = value.recognitionFailureColor
        recognitionFailureBackgroundColor = value.recognitionFailureBackgroundColor
        recognitionPanelAnchorsToBottom = value.recognitionPanelAnchorsToBottom
        recognitionPanelShowsArrow = value.recognitionPanelShowsArrow
        recognitionCentersFailurePanel = value.recognitionCentersFailurePanel
        recognitionAutomaticallyFocusesText = value.recognitionAutomaticallyFocusesText
        recognitionSendsOnReturn = value.recognitionSendsOnReturn
        showsRecognitionRetryButton = value.showsRecognitionRetryButton
        recognitionOverlayBackgroundColor = value.recognitionOverlayBackgroundColor
        recognitionEditorAppearance = value.recognitionEditorAppearance
        recognitionDisabledActionOpacity = value.recognitionDisabledActionOpacity
        transcriptTranslationHandler = value.transcriptTranslationHandler
        translationReadAloudText = value.translationReadAloudText
        translationChangeLanguageText = value.translationChangeLanguageText
        translationCancelText = value.translationCancelText
        showsTranslationReadAloudButton = value.showsTranslationReadAloudButton
        showsTranslationChangeLanguageButton = value.showsTranslationChangeLanguageButton
        showsTranslationCancelButton = value.showsTranslationCancelButton
        self.recognizingText = value.recognizingText
        self.recognitionSendText = value.recognitionSendText
        self.recognitionRetryText = value.recognitionRetryText
        self.recognitionCancelText = value.recognitionCancelText
        self.recognitionFont = value.recognitionFont
        self.recognitionTextColor = value.recognitionTextColor
        self.recognitionBackgroundColor = value.recognitionBackgroundColor
        self.recognitionPanelHeight = value.recognitionPanelHeight
        self.recognitionMinimumHeight = value.recognitionMinimumHeight
        self.recognitionPanelOuterInsets = value.recognitionPanelOuterInsets
        self.recognitionPanelInsets = value.recognitionPanelInsets
        self.recognitionPanelCornerRadius = value.recognitionPanelCornerRadius
        self.recognitionControlHeight = value.recognitionControlHeight
        self.recognitionControlSpacing = value.recognitionControlSpacing
        self.recognitionHeaderHeight = value.recognitionHeaderHeight
        self.recognitionHeaderSpacing = value.recognitionHeaderSpacing
        self.recognitionFooterSpacing = value.recognitionFooterSpacing
        self.recognitionActionWidth = value.recognitionActionWidth
        self.recognitionHeaderButtonWidth = value.recognitionHeaderButtonWidth
        self.recognitionAccessoryWidth = value.recognitionAccessoryWidth
        self.recognitionAccessoryImageSize = value.recognitionAccessoryImageSize
        self.recognitionAccessoryColor = value.recognitionAccessoryColor
        self.recognitionSendColor = value.recognitionSendColor
        self.recognitionSendBackgroundColor = value.recognitionSendBackgroundColor
        self.recognitionControlAppearance = value.recognitionControlAppearance
        self.recognitionControlFont = value.recognitionControlFont
        self.recognitionControlColor = value.recognitionControlColor
        self.recognitionControlBackgroundColor = value.recognitionControlBackgroundColor
        self.recognitionControlCornerRadius = value.recognitionControlCornerRadius
        self.recognitionTextInsets = value.recognitionTextInsets
        self.recognitionTextBackgroundColor = value.recognitionTextBackgroundColor
        self.recognitionCloseImage = value.recognitionCloseImage
        self.recognitionEmojiImage = value.recognitionEmojiImage
        self.recognitionKeyboardImage = value.recognitionKeyboardImage
        self.showsRecognitionEmojiButton = value.showsRecognitionEmojiButton
        self.recognitionEmoji = WYEmojiViewConfigObjC(value.recognitionEmoji)
        self.showsRecognitionLanguageButton = value.showsRecognitionLanguageButton
        self.speechRecognitionLanguages = value.speechRecognitionLanguages
        self.recognitionLanguageText = value.recognitionLanguageText
        self.enablesTranslation = value.enablesTranslation
        self.translationProvider = value.translationProvider
        self.translationSourceLocaleIdentifier = value.translationSourceLocaleIdentifier
        self.translationTargetLocaleIdentifier = value.translationTargetLocaleIdentifier
        self.translationTargetLanguages = value.translationTargetLanguages
        self.translationTimeout = value.translationTimeout
        self.translationFailureText = value.translationFailureText
        self.translationWaitingText = value.translationWaitingText
        self.translationText = value.translationText
        self.chatAudioUrl = value.chatAudioUrl
        super.init()
    }

    @nonobjc public func toValue() -> WYRecordAnimationConfig {
        var value = WYRecordAnimationConfig()
        value.gradientRecordingAccessibilityValue = gradientRecordingAccessibilityValue
        value.gradientCancelAccessibilityValue = gradientCancelAccessibilityValue
        value.moveUpTipsTextAlignment = moveUpTipsTextAlignment
        value.moveUpButtonTextAlignment = moveUpButtonTextAlignment
        value.speechRecognitionPreflightBufferDuration = speechRecognitionPreflightBufferDuration
        value.recordingInteriorTitleAlignment = recordingInteriorTitleAlignment
        value.recordingHintAlignment = recordingHintAlignment
        value.recordingTransferHintAlignment = recordingTransferHintAlignment
        value.managesRecordingAudioSession = managesRecordingAudioSession
        value.recordingAudioSessionCategory = recordingAudioSessionCategory
        value.recordingAudioSessionMode = recordingAudioSessionMode
        value.recordingAudioSessionCategoryOptions = recordingAudioSessionCategoryOptions?.uintValue
        value.deactivatesAudioSessionAfterClassicRecording = deactivatesAudioSessionAfterClassicRecording
        value.notifiesOthersWhenDeactivatingRecordingSession = notifiesOthersWhenDeactivatingRecordingSession
        value.stopsRecordingOnAudioInterruption = stopsRecordingOnAudioInterruption
        value.stopsRecordingWhenAudioDeviceDisconnects = stopsRecordingWhenAudioDeviceDisconnects
        value.recordingFileExtension = recordingFileExtension
        value.audioBufferFrameCount = audioBufferFrameCount
        value.gradientMotionMaximumAmplitudeRatio = gradientMotionMaximumAmplitudeRatio
        value.gradientMotionMaximumTurbulence = gradientMotionMaximumTurbulence
        value.gradientPressLocations = gradientPressLocations.map { CGFloat($0.doubleValue) }
        value.gradientPressOpacities = gradientPressOpacities.map { CGFloat($0.doubleValue) }
        value.gradientPressStartPoint = gradientPressStartPoint
        value.gradientPressEndPoint = gradientPressEndPoint
        value.gradientPressEntranceScale = gradientPressEntranceScale
        value.gradientMotionFramesPerSecond = gradientMotionFramesPerSecond
        value.gradientMotionRenderSize = gradientMotionRenderSize
        value.gradientMotionMaskProvider = gradientMotionMaskProvider
        value.gradientHintTextAlignment = gradientHintTextAlignment
        value.gradientHintNumberOfLines = gradientHintNumberOfLines
        value.recognitionFailureTextAlignment = recognitionFailureTextAlignment
        value.overlayShowDamping = overlayShowDamping
        value.overlayHideDamping = overlayHideDamping
        value.overlaySpringVelocity = overlaySpringVelocity
        value.recognitionControlMinimumScaleFactor = recognitionControlMinimumScaleFactor
        value.recognitionBubbleArrowOverlap = recognitionBubbleArrowOverlap
        value.recordingProgressInterval = recordingProgressInterval
        value.overlayShowDuration = overlayShowDuration
        value.overlayHideDuration = overlayHideDuration
        value.overlayStatusAnimationDuration = overlayStatusAnimationDuration
        value.recognitionKeyboardNotificationTimeout = recognitionKeyboardNotificationTimeout
        value.recognitionKeyboardText = recognitionKeyboardText
        value.recognitionEmojiText = recognitionEmojiText
        value.gradientCancelInstruction = gradientCancelInstruction
        value.missingRecorderText = missingRecorderText
        value.shortRecordingText = shortRecordingText
        value.invalidRecordingText = invalidRecordingText
        value.recognitionDisabledText = recognitionDisabledText
        value.recordingNotFoundText = recordingNotFoundText
        value.recognitionTimeoutText = recognitionTimeoutText
        value.recognitionMissingProviderText = recognitionMissingProviderText
        value.recognitionUnsupportedLanguageText = recognitionUnsupportedLanguageText
        value.recognitionMissingUsageDescriptionText = recognitionMissingUsageDescriptionText
        value.recognitionAuthorizationDeniedText = recognitionAuthorizationDeniedText
        value.recognitionUnavailableText = recognitionUnavailableText
        value.recognitionOnDeviceUnavailableText = recognitionOnDeviceUnavailableText
        value.recognitionEmptyResultText = recognitionEmptyResultText
        value.overlayBackgroundColor = overlayBackgroundColor
        value.bubbleArrowImage = bubbleArrowImage
        value.bubbleArrowImageTintColor = bubbleArrowImageTintColor
        value.bubbleArrowImageOffset = bubbleArrowImageOffset
        value.recordingHintSpacing = recordingHintSpacing
        value.dictationReleaseText = dictationReleaseText
        value.gradientRecordingHint = gradientRecordingHint
        value.gradientCancelHint = gradientCancelHint
        value.gradientWaveformEdgeFade = gradientWaveformEdgeFade
        value.gradientColorLocations = gradientColorLocations.map { CGFloat($0.doubleValue) }
        value.gradientColorOpacities = gradientColorOpacities.map { CGFloat($0.doubleValue) }
        value.gradientMotionEnabled = gradientMotionEnabled
        value.gradientMotionDuration = gradientMotionDuration
        value.gradientMotionAmplitude = gradientMotionAmplitude
        value.gradientMotionScale = gradientMotionScale
        value.gradientMotionHighlightColor = gradientMotionHighlightColor
        value.gradientMotionShadowColor = gradientMotionShadowColor
        value.gradientMotionHighlightOpacity = gradientMotionHighlightOpacity
        value.gradientMotionShadowOpacity = gradientMotionShadowOpacity
        value.gradientPressEnabled = gradientPressEnabled
        value.gradientPressSize = gradientPressSize
        value.gradientPressColor = gradientPressColor
        value.gradientPressOpacity = gradientPressOpacity
        value.gradientPressFollowingDuration = gradientPressFollowingDuration
        value.interactionStyle = interactionStyle
        value.gradientHeight = gradientHeight
        value.gradientRecordingColor = gradientRecordingColor
        value.gradientCancelColor = gradientCancelColor
        value.gradientOverlayColor = gradientOverlayColor
        value.gradientStartPoint = gradientStartPoint
        value.gradientEndPoint = gradientEndPoint
        value.gradientWaveformSize = gradientWaveformSize
        value.gradientWaveformBottomOffset = gradientWaveformBottomOffset
        value.gradientHintSpacing = gradientHintSpacing
        value.gradientHintFont = gradientHintFont
        value.gradientHintColor = gradientHintColor
        value.gradientCancelHintColor = gradientCancelHintColor
        value.gradientCancelWaveformColor = gradientCancelWaveformColor
        value.gradientHintInsets = gradientHintInsets
        value.gradientCancelDistance = gradientCancelDistance
        value.gradientTransitionDuration = gradientTransitionDuration
        value.gradientWaveform = gradientWaveform.convertToSwift(&value.gradientWaveform)
        value.actionStyle = actionStyle
        value.curvedActionSize = curvedActionSize
        value.curvedActionCornerRadius = curvedActionCornerRadius
        value.curvedActionBendHeight = curvedActionBendHeight
        value.curvedActionTitleOffsetX = curvedActionTitleOffsetX
        value.curvedActionTiltAngle = curvedActionTiltAngle
        value.curvedActionCenterOffsetX = curvedActionCenterOffsetX
        value.curvedActionColors = (curvedActionNormalColor, curvedActionSelectedColor)
        value.supportSpeechRecognition = supportSpeechRecognition
        value.soundWavesWidth = soundWavesWidth
        value.soundWavesMaxHeight.recording = soundWavesMaxHeightRecording
        value.soundWavesMaxHeight.cancel = soundWavesMaxHeightCancel
        value.soundWavesMaxHeight.transfer = soundWavesMaxHeightTransfer
        value.soundWavesMinHeight.recording = soundWavesMinHeightRecording
        value.soundWavesMinHeight.cancel = soundWavesMinHeightCancel
        value.soundWavesMinHeight.transfer = soundWavesMinHeightTransfer
        value.soundWavesSpace = soundWavesSpace
        value.severalSoundWaves.recording = severalSoundWavesRecording
        value.severalSoundWaves.cancel = severalSoundWavesCancel
        value.severalSoundWaves.transfer = severalSoundWavesTransfer
        value.colorOfSoundWavesOnRecording.recording = colorOfSoundWavesOnRecordingRecording
        value.colorOfSoundWavesOnRecording.cancel = colorOfSoundWavesOnRecordingCancel
        value.colorOfSoundWavesOnRecording.transfer = colorOfSoundWavesOnRecordingTransfer
        value.soundWavesViewBottomOffset = soundWavesViewBottomOffset
        value.soundWavesViewWidth.recording = soundWavesViewWidthRecording
        value.soundWavesViewWidth.cancel = soundWavesViewWidthCancel
        value.soundWavesViewWidth.transfer = soundWavesViewWidthTransfer
        value.soundWavesViewHeight.recording = soundWavesViewHeightRecording
        value.soundWavesViewHeight.cancel = soundWavesViewHeightCancel
        value.soundWavesViewHeight.transfer = soundWavesViewHeightTransfer
        value.cornerRadiusForMoveUp.recording = cornerRadiusForMoveUpRecording
        value.cornerRadiusForMoveUp.cancel = cornerRadiusForMoveUpCancel
        value.cornerRadiusForMoveUp.transfer = cornerRadiusForMoveUpTransfer
        value.backgroundColorForMoveUp.recording = backgroundColorForMoveUpRecording
        value.backgroundColorForMoveUp.cancel = backgroundColorForMoveUpCancel
        value.backgroundColorForMoveUp.transfer = backgroundColorForMoveUpTransfer
        value.borderColorForMoveUp.recording = borderColorForMoveUpRecording
        value.borderColorForMoveUp.cancel = borderColorForMoveUpCancel
        value.borderColorForMoveUp.transfer = borderColorForMoveUpTransfer
        value.borderWidthForMoveUp.recording = borderWidthForMoveUpRecording
        value.borderWidthForMoveUp.cancel = borderWidthForMoveUpCancel
        value.borderWidthForMoveUp.transfer = borderWidthForMoveUpTransfer
        value.arrowSizeForMoveUp.recording = arrowSizeForMoveUpRecording
        value.arrowSizeForMoveUp.cancel = arrowSizeForMoveUpCancel
        value.arrowSizeForMoveUp.transfer = arrowSizeForMoveUpTransfer
        value.arrowTipRadiusForMoveUp.recording = arrowTipRadiusForMoveUpRecording
        value.arrowTipRadiusForMoveUp.cancel = arrowTipRadiusForMoveUpCancel
        value.arrowTipRadiusForMoveUp.transfer = arrowTipRadiusForMoveUpTransfer
        value.soundWavesRightOffsetForAirBubble = soundWavesRightOffsetForAirBubble
        value.cancelRecordViewImage.onInterior = cancelRecordViewImageOnInterior
        value.cancelRecordViewImage.onExternal = cancelRecordViewImageOnExternal
        value.cancelRecordViewText.onInterior = cancelRecordViewTextOnInterior
        value.cancelRecordViewText.tips = cancelRecordViewTextTips
        value.transferViewText.onInterior = transferViewTextOnInterior
        value.transferViewText.tips = transferViewTextTips
        value.recordViewTips.onInterior = recordViewTipsOnInterior
        value.recordViewTips.onExternal = recordViewTipsOnExternal
        value.transferViewImage.onInterior = transferViewImageOnInterior
        value.transferViewImage.onExternal = transferViewImageOnExternal
        value.tipsInfoForMoveUp.font = tipsInfoForMoveUpFont
        value.tipsInfoForMoveUp.color = tipsInfoForMoveUpColor
        value.recordViewTipsInfoForInterior.font = recordViewTipsInfoForInteriorFont
        value.recordViewTipsInfoForInterior.color = recordViewTipsInfoForInteriorColor
        value.recordViewTipsInfoForExternal.font = recordViewTipsInfoForExternalFont
        value.recordViewTipsInfoForExternal.color = recordViewTipsInfoForExternalColor
        value.cancelRecordViewTextInfoForInterior.font = cancelRecordViewTextInfoForInteriorFont
        value.cancelRecordViewTextInfoForInterior.color = cancelRecordViewTextInfoForInteriorColor
        value.cancelRecordViewTextInfoForExternal.font = cancelRecordViewTextInfoForExternalFont
        value.cancelRecordViewTextInfoForExternal.color = cancelRecordViewTextInfoForExternalColor
        value.transferViewTextInfoForInterior.font = transferViewTextInfoForInteriorFont
        value.transferViewTextInfoForInterior.color = transferViewTextInfoForInteriorColor
        value.transferViewTextInfoForExternal.font = transferViewTextInfoForExternalFont
        value.transferViewTextInfoForExternal.color = transferViewTextInfoForExternalColor
        value.moveUpViewDeviationAngle = moveUpViewDeviationAngle
        value.arcRadian = arcRadian
        value.areaHeight = areaHeight
        value.recordViewBottomOffset = recordViewBottomOffset
        value.recordTipViewTopOffset = recordTipViewTopOffset
        value.moveUpButtonDiameter.onInterior = moveUpButtonDiameterOnInterior
        value.moveUpButtonDiameter.onExternal = moveUpButtonDiameterOnExternal
        value.moveUpButtonOffset.top = moveUpButtonOffsetTop
        value.moveUpButtonOffset.bottom = moveUpButtonOffsetBottom
        value.moveUpButtonCenterOffsetY.onInterior = moveUpButtonCenterOffsetYOnInterior
        value.moveUpButtonCenterOffsetY.onExternal = moveUpButtonCenterOffsetYOnExternal
        value.moveUpButtonCenterOffsetX = moveUpButtonCenterOffsetX
        value.vibrationFeedback = vibrationFeedback
        value.strokeColor = strokeColor
        value.fillColor.onInterior = fillColorOnInterior
        value.fillColor.onExternal = fillColorOnExternal
        value.shadowOffset = shadowOffset
        value.shadowColor = shadowColor
        value.shadowOpacity = shadowOpacity
        value.recordTime.min = recordTimeMin
        value.recordTime.max = recordTimeMax
        value.voiceCountdown = voiceCountdown.swiftValue
        value.dictationCountdown = dictationCountdown.swiftValue
        value.keyboardDictationCountdown = keyboardDictationCountdown.swiftValue
        value.showsLiveTextWhileRecording = showsLiveTextWhileRecording
        value.liveTextInsets = liveTextInsets
        value.liveTextWaveformSpacing = liveTextWaveformSpacing
        value.dictationSendsOnRelease = dictationSendsOnRelease
        value.dictationEditText = dictationEditText
        value.dictationShowsWaveform = dictationShowsWaveform
        value.showsOriginalVoiceButton = showsOriginalVoiceButton
        value.recognitionSendVoiceText = recognitionSendVoiceText
        value.speechRecognitionSource = speechRecognitionSource
        value.speechRecognitionMode = speechRecognitionMode
        value.speechRecognitionProvider = speechRecognitionProvider
        value.recorder = recorder
        value.speechLocaleIdentifier = speechLocaleIdentifier
        value.requiresOnDeviceRecognition = requiresOnDeviceRecognition
        value.speechRecognitionTimeout = speechRecognitionTimeout
        value.recordSettings = recordSettings
        value.animationDuration = animationDuration
        value.recognitionFailureText = recognitionFailureText
        value.recognitionFailureImage = recognitionFailureImage
        value.recognitionFailureColor = recognitionFailureColor
        value.recognitionFailureBackgroundColor = recognitionFailureBackgroundColor
        value.recognitionPanelAnchorsToBottom = recognitionPanelAnchorsToBottom
        value.recognitionPanelShowsArrow = recognitionPanelShowsArrow
        value.recognitionCentersFailurePanel = recognitionCentersFailurePanel
        value.recognitionAutomaticallyFocusesText = recognitionAutomaticallyFocusesText
        value.recognitionSendsOnReturn = recognitionSendsOnReturn
        value.showsRecognitionRetryButton = showsRecognitionRetryButton
        value.recognitionOverlayBackgroundColor = recognitionOverlayBackgroundColor
        value.recognitionEditorAppearance = recognitionEditorAppearance
        value.recognitionDisabledActionOpacity = recognitionDisabledActionOpacity
        value.transcriptTranslationHandler = transcriptTranslationHandler
        value.translationReadAloudText = translationReadAloudText
        value.translationChangeLanguageText = translationChangeLanguageText
        value.translationCancelText = translationCancelText
        value.showsTranslationReadAloudButton = showsTranslationReadAloudButton
        value.showsTranslationChangeLanguageButton = showsTranslationChangeLanguageButton
        value.showsTranslationCancelButton = showsTranslationCancelButton
        value.recognizingText = recognizingText
        value.recognitionSendText = recognitionSendText
        value.recognitionRetryText = recognitionRetryText
        value.recognitionCancelText = recognitionCancelText
        value.recognitionFont = recognitionFont
        value.recognitionTextColor = recognitionTextColor
        value.recognitionBackgroundColor = recognitionBackgroundColor
        value.recognitionPanelHeight = recognitionPanelHeight
        value.recognitionMinimumHeight = recognitionMinimumHeight
        value.recognitionPanelOuterInsets = recognitionPanelOuterInsets
        value.recognitionPanelInsets = recognitionPanelInsets
        value.recognitionPanelCornerRadius = recognitionPanelCornerRadius
        value.recognitionControlHeight = recognitionControlHeight
        value.recognitionControlSpacing = recognitionControlSpacing
        value.recognitionHeaderHeight = recognitionHeaderHeight
        value.recognitionHeaderSpacing = recognitionHeaderSpacing
        value.recognitionFooterSpacing = recognitionFooterSpacing
        value.recognitionActionWidth = recognitionActionWidth
        value.recognitionHeaderButtonWidth = recognitionHeaderButtonWidth
        value.recognitionAccessoryWidth = recognitionAccessoryWidth
        value.recognitionAccessoryImageSize = recognitionAccessoryImageSize
        value.recognitionAccessoryColor = recognitionAccessoryColor
        value.recognitionSendColor = recognitionSendColor
        value.recognitionSendBackgroundColor = recognitionSendBackgroundColor
        value.recognitionControlAppearance = recognitionControlAppearance
        value.recognitionControlFont = recognitionControlFont
        value.recognitionControlColor = recognitionControlColor
        value.recognitionControlBackgroundColor = recognitionControlBackgroundColor
        value.recognitionControlCornerRadius = recognitionControlCornerRadius
        value.recognitionTextInsets = recognitionTextInsets
        value.recognitionTextBackgroundColor = recognitionTextBackgroundColor
        value.recognitionCloseImage = recognitionCloseImage
        value.recognitionEmojiImage = recognitionEmojiImage
        value.recognitionKeyboardImage = recognitionKeyboardImage
        value.showsRecognitionEmojiButton = showsRecognitionEmojiButton
        value.recognitionEmoji = recognitionEmoji.toValue()
        value.showsRecognitionLanguageButton = showsRecognitionLanguageButton
        value.speechRecognitionLanguages = speechRecognitionLanguages
        value.recognitionLanguageText = recognitionLanguageText
        value.enablesTranslation = enablesTranslation
        value.translationProvider = translationProvider
        value.translationSourceLocaleIdentifier = translationSourceLocaleIdentifier
        value.translationTargetLocaleIdentifier = translationTargetLocaleIdentifier
        value.translationTargetLanguages = translationTargetLanguages
        value.translationTimeout = translationTimeout
        value.translationFailureText = translationFailureText
        value.translationWaitingText = translationWaitingText
        value.translationText = translationText
        value.chatAudioUrl = chatAudioUrl
        return value
    }
}

@objc(WYBasicChatConfig)
@objcMembers public class WYBasicChatConfigObjC: NSObject {
    /// 消息发送时间和撤回时间的单位。
    public var timestampUnit: WYChatTimestampUnit
    /// 按消息定制已读标记，返回nil时使用默认已读或未读文本
    public var readMarkFormatter: ((_ message: WYChatMessageModelObjC) -> String?)?
    /// 消息时间的文字对齐方式
    public var timeTextAlignment: NSTextAlignment
    /// 日期与时间之间的分隔文字
    public var dateTimeSeparator: String
    /// 计算气泡最大宽度时是否为发送状态预留空间
    public var reservesSendingStatusSpace: Bool
    /// 消息发送中的系统活动指示器样式
    public var loadingIndicatorStyle: UIActivityIndicatorView.Style
    /// 24小时制消息时间格式
    public var timeFormat: String
    /// 12小时制消息时间格式
    public var amPmTimeFormat: String
    /// 昨天的消息日期标签
    public var yesterdayText: String
    /// 近期消息的星期格式
    public var weekdayFormat: String
    /// 按星期显示的天数，0时关闭
    public var weekdayDisplayDays: Int
    /// 今年的消息日期模板
    public var currentYearDateTemplate: String
    /// 其他年份的消息日期模板
    public var previousYearDateTemplate: String
    /// 等待发送的图标
    public var messagePendingImage: UIImage? = nil
    /// 发送中动画颜色
    public var messageSendingColor: UIColor = .secondaryLabel
    /// 发送失败图标颜色
    public var messageSendErrorColor: UIColor = .systemRed
    /// 等待发送图标颜色
    public var messagePendingColor: UIColor = .secondaryLabel
    /// 消息显示的最小时间跨度，单位秒
    public var messageMinimumTimeSpan: TimeInterval
    /// 头像尺寸
    public var avatarSize: CGSize
    /// 自定义头像占位图，nil时使用纯色或渐变占位
    public var defaultAvatar: UIImage?
    /// 默认头像占位颜色
    public var avatarPlaceholderColor: UIColor
    /// 默认头像占位圆角半径，负值表示圆形，0表示直角
    public var avatarPlaceholderCornerRadius: CGFloat
    /// 默认头像占位渐变颜色
    public var avatarPlaceholderGradientColors: [UIColor]
    /// 默认头像占位渐变方向
    public var avatarPlaceholderGradientDirection: WYGradientDirectionObjC
    /// 头像显示方式
    public var avatarContentMode: UIView.ContentMode
    /// 头像圆角
    public var avatarCornerRadius: CGFloat
    /// 头像单击操作，默认打开用户信息
    public var avatarTapAction: WYChatAvatarAction
    /// 头像长按操作，默认提及用户
    public var avatarLongPressAction: WYChatAvatarAction
    /// 头像双击操作，默认请求拍一拍
    public var avatarDoubleTapAction: WYChatAvatarAction
    /// 双击头像的拍一拍对象范围
    public var avatarDoubleTapPatScope: WYChatAvatarDoubleTapPatScope
    /// 拍一拍时提供轻触反馈，默认开启
    public var enablesAvatarPatHaptics: Bool
    /// 头像长按识别时间，单位秒
    public var avatarLongPressDuration: TimeInterval
    /// 拍一拍反馈动画时长，0表示不播放
    public var avatarPatAnimationDuration: TimeInterval
    /// 拍一拍反馈的旋转角度序列，单位弧度
    public var avatarPatAnimationAngles: [CGFloat]
    /// 头像提及时是否自动插入输入框，默认true
    public var automaticallyInsertsMentions: Bool
    /// 提及用户的前缀
    public var mentionPrefix: String
    /// 提及用户后的分隔文本
    public var mentionSuffix: String
    /// 昵称字体
    public var nicknameFont: UIFont
    /// 昵称颜色
    public var nicknameColor: UIColor
    /// 时间字体
    public var timeFont: UIFont
    /// 时间颜色
    public var timeColor: UIColor
    /// 时间与消息间距
    public var timeViewOffset: CGFloat
    /// 时间是否显示上午下午标识
    public var showAmPmSymbol: Bool
    /// 是否显示发送方已读标识，默认false
    public var showReadMark: Bool
    /// 已读标识字体
    public var readMarkFont: UIFont
    /// 已读标识颜色
    public var readMarkColor: UIColor
    /// 已读文本
    public var readText: String
    /// 未读文本
    public var unreadText: String
    /// 发送失败图标
    public var messageSendErrorImage: UIImage?
    /// 发送状态尺寸
    public var messageSendingStateSize: CGSize
    /// 发送状态与内容的间距
    public var messageSendingStateOffset: CGFloat
    /// 自定义时间显示，参数为消息，返回显示文本
    public var timeFormatter: ((_ message: WYChatMessageModelObjC) -> String)?

    public override convenience init() { self.init(WYBasicChatConfig()) }

    @nonobjc public init(_ value: WYBasicChatConfig) {
        timestampUnit = value.timestampUnit
        self.readMarkFormatter = value.readMarkFormatter.map { source in { message in source(message.toValue()) } }
        self.timeTextAlignment = value.timeTextAlignment
        self.dateTimeSeparator = value.dateTimeSeparator
        self.reservesSendingStatusSpace = value.reservesSendingStatusSpace
        self.loadingIndicatorStyle = value.loadingIndicatorStyle
        self.timeFormat = value.timeFormat
        self.amPmTimeFormat = value.amPmTimeFormat
        self.yesterdayText = value.yesterdayText
        self.weekdayFormat = value.weekdayFormat
        self.weekdayDisplayDays = value.weekdayDisplayDays
        self.currentYearDateTemplate = value.currentYearDateTemplate
        self.previousYearDateTemplate = value.previousYearDateTemplate
        self.messageMinimumTimeSpan = value.messageMinimumTimeSpan
        self.avatarSize = value.avatarSize
        self.defaultAvatar = value.defaultAvatar
        avatarPlaceholderColor = value.avatarPlaceholderColor
        avatarPlaceholderCornerRadius = value.avatarPlaceholderCornerRadius
        avatarPlaceholderGradientColors = value.avatarPlaceholderGradientColors
        avatarPlaceholderGradientDirection = WYGradientDirectionObjC(rawValue: value.avatarPlaceholderGradientDirection.rawValue) ?? .leftToRight
        self.avatarContentMode = value.avatarContentMode
        self.avatarCornerRadius = value.avatarCornerRadius
        avatarTapAction = value.avatarTapAction
        avatarLongPressAction = value.avatarLongPressAction
        avatarDoubleTapAction = value.avatarDoubleTapAction
        avatarDoubleTapPatScope = value.avatarDoubleTapPatScope
        enablesAvatarPatHaptics = value.enablesAvatarPatHaptics
        avatarLongPressDuration = value.avatarLongPressDuration
        avatarPatAnimationDuration = value.avatarPatAnimationDuration
        avatarPatAnimationAngles = value.avatarPatAnimationAngles
        automaticallyInsertsMentions = value.automaticallyInsertsMentions
        mentionPrefix = value.mentionPrefix
        mentionSuffix = value.mentionSuffix
        self.nicknameFont = value.nicknameFont
        self.nicknameColor = value.nicknameColor
        self.timeFont = value.timeFont
        self.timeColor = value.timeColor
        self.timeViewOffset = value.timeViewOffset
        self.showAmPmSymbol = value.showAmPmSymbol
        self.showReadMark = value.showReadMark
        self.readMarkFont = value.readMarkFont
        self.readMarkColor = value.readMarkColor
        self.readText = value.readText
        self.unreadText = value.unreadText
        self.messageSendErrorImage = value.messageSendErrorImage
        self.messageSendingStateSize = value.messageSendingStateSize
        self.messageSendingStateOffset = value.messageSendingStateOffset
        self.timeFormatter = value.timeFormatter.map { source in { message in source(message.toValue()) } }
        messagePendingImage = value.messagePendingImage
        messageSendingColor = value.messageSendingColor
        messageSendErrorColor = value.messageSendErrorColor
        messagePendingColor = value.messagePendingColor
        super.init()
    }

    @nonobjc public func toValue() -> WYBasicChatConfig {
        var value = WYBasicChatConfig()
        value.timestampUnit = timestampUnit
        value.readMarkFormatter = readMarkFormatter.map { source in { message in source(WYChatMessageModelObjC(message)) } }
        value.timeTextAlignment = timeTextAlignment
        value.dateTimeSeparator = dateTimeSeparator
        value.reservesSendingStatusSpace = reservesSendingStatusSpace
        value.loadingIndicatorStyle = loadingIndicatorStyle
        value.timeFormat = timeFormat
        value.amPmTimeFormat = amPmTimeFormat
        value.yesterdayText = yesterdayText
        value.weekdayFormat = weekdayFormat
        value.weekdayDisplayDays = weekdayDisplayDays
        value.currentYearDateTemplate = currentYearDateTemplate
        value.previousYearDateTemplate = previousYearDateTemplate
        value.messageMinimumTimeSpan = messageMinimumTimeSpan
        value.avatarSize = avatarSize
        value.defaultAvatar = defaultAvatar
        value.avatarPlaceholderColor = avatarPlaceholderColor
        value.avatarPlaceholderCornerRadius = avatarPlaceholderCornerRadius
        value.avatarPlaceholderGradientColors = avatarPlaceholderGradientColors
        value.avatarPlaceholderGradientDirection = WYGradientDirection(rawValue: avatarPlaceholderGradientDirection.rawValue) ?? .leftToRight
        value.avatarContentMode = avatarContentMode
        value.avatarCornerRadius = avatarCornerRadius
        value.avatarTapAction = avatarTapAction
        value.avatarLongPressAction = avatarLongPressAction
        value.avatarDoubleTapAction = avatarDoubleTapAction
        value.avatarDoubleTapPatScope = avatarDoubleTapPatScope
        value.enablesAvatarPatHaptics = enablesAvatarPatHaptics
        value.avatarLongPressDuration = avatarLongPressDuration
        value.avatarPatAnimationDuration = avatarPatAnimationDuration
        value.avatarPatAnimationAngles = avatarPatAnimationAngles
        value.automaticallyInsertsMentions = automaticallyInsertsMentions
        value.mentionPrefix = mentionPrefix
        value.mentionSuffix = mentionSuffix
        value.nicknameFont = nicknameFont
        value.nicknameColor = nicknameColor
        value.timeFont = timeFont
        value.timeColor = timeColor
        value.timeViewOffset = timeViewOffset
        value.showAmPmSymbol = showAmPmSymbol
        value.showReadMark = showReadMark
        value.readMarkFont = readMarkFont
        value.readMarkColor = readMarkColor
        value.readText = readText
        value.unreadText = unreadText
        value.messageSendErrorImage = messageSendErrorImage
        value.messageSendingStateSize = messageSendingStateSize
        value.messageSendingStateOffset = messageSendingStateOffset
        value.timeFormatter = timeFormatter.map { source in { message in source(WYChatMessageModelObjC(message)) } }
        value.messagePendingImage = messagePendingImage
        value.messageSendingColor = messageSendingColor
        value.messageSendErrorColor = messageSendErrorColor
        value.messagePendingColor = messagePendingColor
        return value
    }
}

@objc(WYChatTextDetectionStyle)
@objcMembers public class WYChatTextDetectionStyleObjC: NSObject {
    public var color: UIColor
    public var isUnderlined: Bool

    public override convenience init() { self.init(color: .link, isUnderlined: true) }

    public init(color: UIColor, isUnderlined: Bool) {
        self.color = color
        self.isUnderlined = isUnderlined
        super.init()
    }

    @nonobjc convenience init(_ style: WYChatTextDetectionStyle) {
        self.init(color: style.color, isUnderlined: style.isUnderlined)
    }

    @nonobjc var value: WYChatTextDetectionStyle {
        WYChatTextDetectionStyle(color: color, isUnderlined: isUnderlined)
    }
}

@objc(WYTextChatConfig)
@objcMembers public class WYTextChatConfigObjC: NSObject {
    /// 是否允许选择单表情消息的文本
    public var allowsSingleEmojiSelection: Bool
    /// 单表情消息是否优先使用气泡旁菜单
    public var usesBubbleMenuForSingleEmoji: Bool
    /// 消息动图刷新间隔的下限，单位秒
    public var minimumEmojiAnimationFrameInterval: TimeInterval
    /// 动态表情刷新间隔，单位秒，0时关闭动图播放
    public var emojiAnimationFrameInterval: TimeInterval
    /// 文本行数，0表示不限
    public var textMaximumNumberOfLines: Int
    /// 文本字体
    public var textFont: UIFont
    /// 文本颜色
    public var textColor: UIColor
    /// 行间距
    public var textLineSpacing: CGFloat
    /// 是否支持选择文本，默认true
    public var isSelectable: Bool
    /// detectedTextTypes 为 nil 时使用的 UIKit 自动识别类型
    public var dataDetectorTypes: UIDataDetectorTypes
    /// NSNumber 封装 WYChatTextDetectionType。nil 沿用 dataDetectorTypes，空数组关闭识别
    public var detectedTextTypes: [NSNumber]?
    /// 自动识别内容的默认样式
    public var detectedTextStyle: WYChatTextDetectionStyleObjC
    /// 按类型覆盖默认样式，键为 NSNumber 封装的 WYChatTextDetectionType
    public var detectedTextStyles: [NSNumber: WYChatTextDetectionStyleObjC]
    /// 点击显式配置识别出的内容时收到类型、原文和消息模型。需要启用 isSelectable
    public var detectedTextTapHandler: ((_ type: WYChatTextDetectionType, _ text: String, _ message: WYChatMessageModelObjC) -> Void)?
    /// 文本消息内表情的播放方式，默认仅首次展示时播放
    public var emojiPlaybackMode: WYChatEmojiPlaybackMode

    public override convenience init() { self.init(WYTextChatConfig()) }

    @nonobjc public init(_ value: WYTextChatConfig) {
        self.allowsSingleEmojiSelection = value.allowsSingleEmojiSelection
        self.usesBubbleMenuForSingleEmoji = value.usesBubbleMenuForSingleEmoji
        self.minimumEmojiAnimationFrameInterval = value.minimumEmojiAnimationFrameInterval
        self.emojiAnimationFrameInterval = value.emojiAnimationFrameInterval
        self.textMaximumNumberOfLines = value.textMaximumNumberOfLines
        self.textFont = value.textFont
        self.textColor = value.textColor
        self.textLineSpacing = value.textLineSpacing
        self.isSelectable = value.isSelectable
        self.dataDetectorTypes = value.dataDetectorTypes
        self.detectedTextTypes = value.detectedTextTypes?.map { NSNumber(value: $0.rawValue) }
        self.detectedTextStyle = WYChatTextDetectionStyleObjC(value.detectedTextStyle)
        self.detectedTextStyles = Dictionary(uniqueKeysWithValues: value.detectedTextStyles.map {
            (NSNumber(value: $0.key.rawValue), WYChatTextDetectionStyleObjC($0.value))
        })
        if let handler = value.detectedTextTapHandler {
            self.detectedTextTapHandler = { type, text, message in
                MainActor.assumeIsolated { handler(type, text, message.toValue()) }
            }
        }
        self.emojiPlaybackMode = value.emojiPlaybackMode
        super.init()
    }

    @nonobjc public func toValue() -> WYTextChatConfig {
        var value = WYTextChatConfig()
        value.allowsSingleEmojiSelection = allowsSingleEmojiSelection
        value.usesBubbleMenuForSingleEmoji = usesBubbleMenuForSingleEmoji
        value.minimumEmojiAnimationFrameInterval = minimumEmojiAnimationFrameInterval
        value.emojiAnimationFrameInterval = emojiAnimationFrameInterval
        value.textMaximumNumberOfLines = textMaximumNumberOfLines
        value.textFont = textFont
        value.textColor = textColor
        value.textLineSpacing = textLineSpacing
        value.isSelectable = isSelectable
        value.dataDetectorTypes = dataDetectorTypes
        value.detectedTextTypes = detectedTextTypes?.compactMap { WYChatTextDetectionType(rawValue: $0.intValue) }
        value.detectedTextStyle = detectedTextStyle.value
        for (key, style) in detectedTextStyles {
            guard let type = WYChatTextDetectionType(rawValue: key.intValue) else { continue }
            value.detectedTextStyles[type] = style.value
        }
        if let handler = detectedTextTapHandler {
            value.detectedTextTapHandler = { type, text, message in handler(type, text, WYChatMessageModelObjC(message)) }
        }
        value.emojiPlaybackMode = emojiPlaybackMode
        return value
    }
}

@objc(WYInputBarConfig)
@objcMembers public class WYInputBarConfigObjC: NSObject {
    /// 居中占位文案在输入框聚焦后的对齐方式
    public var focusedCenteredPlaceholderAlignment: NSTextAlignment
    /// 按住说话按钮的长按触发时间，单位秒
    public var voiceLongPressDuration: TimeInterval
    /// 输入超过指定行数时滚到末尾，0表示关闭自动滚动
    public var autoScrollAfterLineCount: Int
    /// 输入栏功能图标的显示方式
    public var iconContentMode: UIView.ContentMode
    /// 键盘听写图标的显示方式
    public var dictationIconContentMode: UIView.ContentMode
    /// 输入占位文案是否自动缩小以适应宽度
    public var placeholderAdjustsFontSizeToFitWidth: Bool
    /// 输入光标在文字行高以外增加的高度
    public var caretExtraHeight: CGFloat
    /// 语音按钮的无障碍标签
    public var voiceAccessibilityLabel: String
    /// 表情按钮的无障碍标签
    public var emojiAccessibilityLabel: String
    /// 更多按钮的无障碍标签
    public var moreAccessibilityLabel: String
    /// 结束听写按钮的无障碍标签
    public var dictationDoneAccessibilityLabel: String
    /// 占位区域长按触发时长，单位秒
    public var placeholderLongPressDuration: TimeInterval
    /// 输入栏高度变化动画时长，单位秒
    public var heightAnimationDuration: TimeInterval
    /// 恢复草稿时等待键盘环境稳定的时长，单位秒
    public var draftFocusDelay: TimeInterval
    /// 等待外接键盘布局通知的时长，单位秒
    public var keyboardNotificationTimeout: TimeInterval
    /// 草稿保存键，空字符串时不跨实例保存草稿
    public var draftStorageKey: String = ""
    /// 文本占位对齐方式
    public var textPlaceholderAlignment: NSTextAlignment
    /// 空输入框的长按操作，默认 voice（长按发语音），dictation 需要启用语音识别
    public var placeholderLongPressAction: WYChatInputLongPressAction
    /// 长按空输入框开始录音时的界面样式，默认底部渐变声波
    public var placeholderRecordingInteractionStyle: WYRecordingInteractionStyle
    /// 是否在键盘展开时显示输入框内的语音识别按钮，需要启用语音识别
    public var enablesKeyboardDictation: Bool
    /// 输入框有内容时是否继续显示语音识别按钮，默认 false，识别进行中仍显示完成按钮
    public var showsKeyboardDictationWithText: Bool
    /// 打开表情面板时是否保留输入框内的语音识别按钮
    public var showsKeyboardDictationInEmojiPanel: Bool
    /// 手动修改输入文本时是否关闭正在进行的语音识别，默认true
    public var stopsKeyboardDictationOnTextChange: Bool
    /// 输入框语音识别按钮图片
    public var keyboardDictationImage: UIImage?
    /// 输入框语音识别进行中按钮图片
    public var keyboardDictationStopImage: UIImage?
    /// 输入框语音识别按钮尺寸
    public var keyboardDictationSize: CGSize
    /// 输入框语音识别按钮内边距
    public var keyboardDictationInsets: UIEdgeInsets
    /// 输入框语音识别按钮颜色
    public var keyboardDictationTintColor: UIColor
    /// 录音按钮长按手势允许手指移动的最大距离
    public var recordViewLongPressMaxOffset: CGFloat
    /// inputBar弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval
    /// inputBar背景图
    public var backgroundImage: UIImage?
    /// 输入栏背景色，背景图覆盖在此颜色上
    public var backgroundColor: UIColor

    /// 文本输入框背景色
    public var textViewBackgroundColor: UIColor

    /// 语音输入框背景色
    public var voiceViewBackgroundColor: UIColor

    /// 语音输入框按压时的背景色
    public var voiceViewHighlightedBackgroundColor: UIColor

    /// 输入栏图标颜色
    public var iconTintColor: UIColor

    /// 是否用iconTintColor绘制输入栏图标，默认false
    public var rendersIconsAsTemplate: Bool

    /// 是否需要保存上次退出时输入框中的文本
    public var canSaveLastInputText: Bool
    /// 是否需要保存上次退出时输入框模式(语音输入还是文本输入)
    public var canSaveLastInputViewStyle: Bool
    /// 是否允许输入Emoji表情
    public var canInputEmoji: Bool
    /// 输入法自带的Emoji表情替换成什么字符(需要canInputEmoji为false才生效)
    public var emojiReplacement: String
    /// 自定义表情转换时的正则匹配规则(默认匹配一对不嵌套方括号的[表情名]，不限长度)
    public var emojiPattern: String
    /// 文本切换按钮图片
    public var textBottomImage: UIImage
    /// 语音切换按钮图片
    public var voiceButtonImage: UIImage
    /// 表情切换按钮图片
    public var emojiBottomImage: UIImage
    /// 更多切换按钮图片
    public var moreBottomImage: UIImage
    /// 文本输入框背景图
    public var textViewBackgroundImage: UIImage?
    /// 语音输入框背景图
    public var voiceViewBackgroundImage: UIImage?
    /// 语音输入框按压状态背景图
    public var voiceViewBackgroundImageForHighlighted: UIImage?
    /// 语音输入框占位文本
    public var voicePlaceholder: String
    /// 语音输入框占位文本色值
    public var voicePlaceholderColor: UIColor
    /// 语音框输入占位文本字体、字号
    public var voicePlaceholderFont: UIFont
    /// 键盘类型
    public var chatKeyboardType: UIKeyboardType
    /// 键盘右下角按钮类型
    public var chatReturnKeyType: UIReturnKeyType
    /// 输入框占位文本
    public var textPlaceholder: String
    /// 输入框占位文本色值
    public var textPlaceholderColor: UIColor
    /// 输入框占位文本字体、字号
    public var textPlaceholderFont: UIFont
    /// 输入框占位文本距离输入框左侧和顶部的间距
    public var textPlaceholderOffset: CGPoint
    /// 输入框内文本偏移量
    public var inputTextEdgeInsets: UIEdgeInsets
    /// 输入字符长度限制
    public var inputTextLength: Int
    /// 输入字符行数限制(0为不限制行数)
    public var inputTextMaximumNumberOfLines: Int
    /// 输入字符的截断方式
    public var textLineBreakMode: NSLineBreakMode
    /// 输入框键盘语言(解决textViewDidChange回调两次的问题)
    public var primaryLanguage: [String]
    /// 字符输入控件是否允许滑动
    public var textViewIsScrollEnabled: Bool
    /// 字符输入控件是否允许弹跳效果
    public var textViewIsBounces: Bool
    /// 字符输入控件光标颜色
    public var inputViewCurvesColor: UIColor
    /// 字符输入控件是否允许弹出用户交互菜单
    public var textViewCanUserInteractionMenu: Bool
    /// 输入框输入文本色值
    public var textColor: UIColor
    /// 输入框输入文本字体、字号
    public var textFont: UIFont
    /// 输入框文本行间距
    public var textLineSpacing: CGFloat
    /// 输入框的最高高度
    public var textViewMaxHeight: CGFloat
    /// 语音框的圆角半径
    public var voiceViewCornerRadius: CGFloat

    /// 输入框的圆角半径
    public var textViewCornerRadius: CGFloat
    /// 输入框、语音框的边框颜色
    public var textViewBorderColor: UIColor
    /// 输入框、语音框的边框宽度
    public var textViewBorderWidth: CGFloat
    /// 输入框、语音框的高度
    public var inputViewHeight: CGFloat
    /// 输入框、语音框距离InputBar的间距
    public var inputViewEdgeInsets: UIEdgeInsets
    /// 语音、文本切换按钮的size
    public var voiceTextButtonSize: CGSize
    /// 表情、文本切换按钮的size
    public var emojiTextButtonSize: CGSize
    /// 更多按钮的size
    public var moreButtonSize: CGSize
    /// 语音、文本切换按钮距离 输入框、语音框 左侧的间距
    public var voiceTextButtonRightOffset: CGFloat
    /// 语音、文本切换按钮距离 输入框、语音框 底部的间距
    public var voiceTextButtonBottomOffset: CGFloat
    /// 表情、文本切换按钮距离 输入框、语音框 右侧的间距
    public var emojiTextButtonLeftOffset: CGFloat
    /// 表情、文本切换按钮距离 输入框、语音框 底部的间距
    public var emojiTextButtonBottomOffset: CGFloat
    /// 更多按钮距离 输入框、语音框 右侧的间距(默认 emojiTextButtonLeftOffset + emojiTextButtonSize.width + emojiTextButtonLeftOffset)
    public var moreButtonLeftOffset: CGFloat
    /// 更多按钮距离 输入框、语音框 底部的间距
    public var moreButtonBottomOffset: CGFloat
    /// 是否使用独立的发送按钮(开启后当输入框中有字符出现时，会在InputBar的右侧出现一个独立的发送按钮)
    public var showSpecialSendButton: Bool
    /// 独立发送按钮的Size
    public var specialSendButtonSize: CGSize
    /// 独立发送按钮左侧距离输入框、语音框右侧的间距
    public var specialSendButtonLeftOffset: CGFloat
    /// 独立发送按钮右侧距离InputBar右侧的间距(默认 emojiTextButtonLeftOffset)
    public var specialSendButtonRightOffset: CGFloat
    /// 独立发送按钮底部距离 输入框、语音框 底部的间距
    public var specialSendButtonBottomOffset: CGFloat
    /// 独立发送按钮图片
    public var specialSendButtonImage: UIImage
    /// 独立发送按钮的圆角半径
    public var specialSendButtonCornerRadius: CGFloat
    /// 独立发送按钮的边框颜色
    public var specialSendButtonBorderColor: UIColor
    /// 独立发送按钮的边框宽度
    public var specialSendButtonBorderWidth: CGFloat
    /// 独立发送按钮的字体字号
    public var specialSendButtonFont: UIFont
    /// 独立发送按钮的字体颜色
    public var specialSendButtonTextColor: UIColor
    /// 独立发送按钮的文本
    public var specialSendButtonText: String

    public override convenience init() { self.init(WYInputBarConfig()) }

    @nonobjc public init(_ value: WYInputBarConfig) {
        self.focusedCenteredPlaceholderAlignment = value.focusedCenteredPlaceholderAlignment
        self.voiceLongPressDuration = value.voiceLongPressDuration
        self.autoScrollAfterLineCount = value.autoScrollAfterLineCount
        self.iconContentMode = value.iconContentMode
        self.dictationIconContentMode = value.dictationIconContentMode
        self.placeholderAdjustsFontSizeToFitWidth = value.placeholderAdjustsFontSizeToFitWidth
        self.caretExtraHeight = value.caretExtraHeight
        self.voiceAccessibilityLabel = value.voiceAccessibilityLabel
        self.emojiAccessibilityLabel = value.emojiAccessibilityLabel
        self.moreAccessibilityLabel = value.moreAccessibilityLabel
        self.dictationDoneAccessibilityLabel = value.dictationDoneAccessibilityLabel
        self.placeholderLongPressDuration = value.placeholderLongPressDuration
        self.heightAnimationDuration = value.heightAnimationDuration
        self.draftFocusDelay = value.draftFocusDelay
        self.keyboardNotificationTimeout = value.keyboardNotificationTimeout
        self.textPlaceholderAlignment = value.textPlaceholderAlignment
        self.placeholderLongPressAction = value.placeholderLongPressAction
        self.placeholderRecordingInteractionStyle = value.placeholderRecordingInteractionStyle
        self.enablesKeyboardDictation = value.enablesKeyboardDictation
        self.showsKeyboardDictationWithText = value.showsKeyboardDictationWithText
        self.showsKeyboardDictationInEmojiPanel = value.showsKeyboardDictationInEmojiPanel
        self.stopsKeyboardDictationOnTextChange = value.stopsKeyboardDictationOnTextChange
        self.keyboardDictationImage = value.keyboardDictationImage
        self.keyboardDictationStopImage = value.keyboardDictationStopImage
        self.keyboardDictationSize = value.keyboardDictationSize
        self.keyboardDictationInsets = value.keyboardDictationInsets
        self.keyboardDictationTintColor = value.keyboardDictationTintColor
        self.recordViewLongPressMaxOffset = value.recordViewLongPressMaxOffset
        self.animateDuration = value.animateDuration
        self.backgroundImage = value.backgroundImage
        self.backgroundColor = value.backgroundColor
        self.textViewBackgroundColor = value.textViewBackgroundColor
        self.voiceViewBackgroundColor = value.voiceViewBackgroundColor
        self.voiceViewHighlightedBackgroundColor = value.voiceViewHighlightedBackgroundColor
        self.iconTintColor = value.iconTintColor
        self.rendersIconsAsTemplate = value.rendersIconsAsTemplate

        self.canSaveLastInputText = value.canSaveLastInputText
        self.canSaveLastInputViewStyle = value.canSaveLastInputViewStyle
        self.canInputEmoji = value.canInputEmoji
        self.emojiReplacement = value.emojiReplacement
        self.emojiPattern = value.emojiPattern
        self.textBottomImage = value.textBottomImage
        self.voiceButtonImage = value.voiceButtonImage
        self.emojiBottomImage = value.emojiBottomImage
        self.moreBottomImage = value.moreBottomImage
        self.textViewBackgroundImage = value.textViewBackgroundImage
        self.voiceViewBackgroundImage = value.voiceViewBackgroundImage
        self.voiceViewBackgroundImageForHighlighted = value.voiceViewBackgroundImageForHighlighted
        self.voicePlaceholder = value.voicePlaceholder
        self.voicePlaceholderColor = value.voicePlaceholderColor
        self.voicePlaceholderFont = value.voicePlaceholderFont
        self.chatKeyboardType = value.chatKeyboardType
        self.chatReturnKeyType = value.chatReturnKeyType
        self.textPlaceholder = value.textPlaceholder
        self.textPlaceholderColor = value.textPlaceholderColor
        self.textPlaceholderFont = value.textPlaceholderFont
        self.textPlaceholderOffset = value.textPlaceholderOffset
        self.inputTextEdgeInsets = value.inputTextEdgeInsets
        self.inputTextLength = value.inputTextLength
        self.inputTextMaximumNumberOfLines = value.inputTextMaximumNumberOfLines
        self.textLineBreakMode = value.textLineBreakMode
        self.primaryLanguage = value.primaryLanguage
        self.textViewIsScrollEnabled = value.textViewIsScrollEnabled
        self.textViewIsBounces = value.textViewIsBounces
        self.inputViewCurvesColor = value.inputViewCurvesColor
        self.textViewCanUserInteractionMenu = value.textViewCanUserInteractionMenu
        self.textColor = value.textColor
        self.textFont = value.textFont
        self.textLineSpacing = value.textLineSpacing
        self.textViewMaxHeight = value.textViewMaxHeight
        self.voiceViewCornerRadius = value.voiceViewCornerRadius
        self.textViewCornerRadius = value.textViewCornerRadius
        self.textViewBorderColor = value.textViewBorderColor
        self.textViewBorderWidth = value.textViewBorderWidth
        self.inputViewHeight = value.inputViewHeight
        self.inputViewEdgeInsets = value.inputViewEdgeInsets
        self.voiceTextButtonSize = value.voiceTextButtonSize
        self.emojiTextButtonSize = value.emojiTextButtonSize
        self.moreButtonSize = value.moreButtonSize
        self.voiceTextButtonRightOffset = value.voiceTextButtonRightOffset
        self.voiceTextButtonBottomOffset = value.voiceTextButtonBottomOffset
        self.emojiTextButtonLeftOffset = value.emojiTextButtonLeftOffset
        self.emojiTextButtonBottomOffset = value.emojiTextButtonBottomOffset
        self.moreButtonLeftOffset = value.moreButtonLeftOffset
        self.moreButtonBottomOffset = value.moreButtonBottomOffset
        self.showSpecialSendButton = value.showSpecialSendButton
        self.specialSendButtonSize = value.specialSendButtonSize
        self.specialSendButtonLeftOffset = value.specialSendButtonLeftOffset
        self.specialSendButtonRightOffset = value.specialSendButtonRightOffset
        self.specialSendButtonBottomOffset = value.specialSendButtonBottomOffset
        self.specialSendButtonImage = value.specialSendButtonImage
        self.specialSendButtonCornerRadius = value.specialSendButtonCornerRadius
        self.specialSendButtonBorderColor = value.specialSendButtonBorderColor
        self.specialSendButtonBorderWidth = value.specialSendButtonBorderWidth
        self.specialSendButtonFont = value.specialSendButtonFont
        self.specialSendButtonTextColor = value.specialSendButtonTextColor
        self.specialSendButtonText = value.specialSendButtonText
        self.draftStorageKey = value.draftStorageKey
        super.init()
    }

    @nonobjc public func toValue() -> WYInputBarConfig {
        var value = WYInputBarConfig()
        value.focusedCenteredPlaceholderAlignment = focusedCenteredPlaceholderAlignment
        value.voiceLongPressDuration = voiceLongPressDuration
        value.autoScrollAfterLineCount = autoScrollAfterLineCount
        value.iconContentMode = iconContentMode
        value.dictationIconContentMode = dictationIconContentMode
        value.placeholderAdjustsFontSizeToFitWidth = placeholderAdjustsFontSizeToFitWidth
        value.caretExtraHeight = caretExtraHeight
        value.voiceAccessibilityLabel = voiceAccessibilityLabel
        value.emojiAccessibilityLabel = emojiAccessibilityLabel
        value.moreAccessibilityLabel = moreAccessibilityLabel
        value.dictationDoneAccessibilityLabel = dictationDoneAccessibilityLabel
        value.placeholderLongPressDuration = placeholderLongPressDuration
        value.heightAnimationDuration = heightAnimationDuration
        value.draftFocusDelay = draftFocusDelay
        value.keyboardNotificationTimeout = keyboardNotificationTimeout
        value.textPlaceholderAlignment = textPlaceholderAlignment
        value.placeholderLongPressAction = placeholderLongPressAction
        value.placeholderRecordingInteractionStyle = placeholderRecordingInteractionStyle
        value.enablesKeyboardDictation = enablesKeyboardDictation
        value.showsKeyboardDictationWithText = showsKeyboardDictationWithText
        value.showsKeyboardDictationInEmojiPanel = showsKeyboardDictationInEmojiPanel
        value.stopsKeyboardDictationOnTextChange = stopsKeyboardDictationOnTextChange
        value.keyboardDictationImage = keyboardDictationImage
        value.keyboardDictationStopImage = keyboardDictationStopImage
        value.keyboardDictationSize = keyboardDictationSize
        value.keyboardDictationInsets = keyboardDictationInsets
        value.keyboardDictationTintColor = keyboardDictationTintColor
        value.recordViewLongPressMaxOffset = recordViewLongPressMaxOffset
        value.animateDuration = animateDuration
        value.backgroundImage = backgroundImage
        value.backgroundColor = backgroundColor
        value.textViewBackgroundColor = textViewBackgroundColor
        value.voiceViewBackgroundColor = voiceViewBackgroundColor
        value.voiceViewHighlightedBackgroundColor = voiceViewHighlightedBackgroundColor
        value.iconTintColor = iconTintColor
        value.rendersIconsAsTemplate = rendersIconsAsTemplate

        value.canSaveLastInputText = canSaveLastInputText
        value.canSaveLastInputViewStyle = canSaveLastInputViewStyle
        value.canInputEmoji = canInputEmoji
        value.emojiReplacement = emojiReplacement
        value.emojiPattern = emojiPattern
        value.textBottomImage = textBottomImage
        value.voiceButtonImage = voiceButtonImage
        value.emojiBottomImage = emojiBottomImage
        value.moreBottomImage = moreBottomImage
        value.textViewBackgroundImage = textViewBackgroundImage
        value.voiceViewBackgroundImage = voiceViewBackgroundImage
        value.voiceViewBackgroundImageForHighlighted = voiceViewBackgroundImageForHighlighted
        value.voicePlaceholder = voicePlaceholder
        value.voicePlaceholderColor = voicePlaceholderColor
        value.voicePlaceholderFont = voicePlaceholderFont
        value.chatKeyboardType = chatKeyboardType
        value.chatReturnKeyType = chatReturnKeyType
        value.textPlaceholder = textPlaceholder
        value.textPlaceholderColor = textPlaceholderColor
        value.textPlaceholderFont = textPlaceholderFont
        value.textPlaceholderOffset = textPlaceholderOffset
        value.inputTextEdgeInsets = inputTextEdgeInsets
        value.inputTextLength = inputTextLength
        value.inputTextMaximumNumberOfLines = inputTextMaximumNumberOfLines
        value.textLineBreakMode = textLineBreakMode
        value.primaryLanguage = primaryLanguage
        value.textViewIsScrollEnabled = textViewIsScrollEnabled
        value.textViewIsBounces = textViewIsBounces
        value.inputViewCurvesColor = inputViewCurvesColor
        value.textViewCanUserInteractionMenu = textViewCanUserInteractionMenu
        value.textColor = textColor
        value.textFont = textFont
        value.textLineSpacing = textLineSpacing
        value.textViewMaxHeight = textViewMaxHeight
        value.voiceViewCornerRadius = voiceViewCornerRadius
        value.textViewCornerRadius = textViewCornerRadius
        value.textViewBorderColor = textViewBorderColor
        value.textViewBorderWidth = textViewBorderWidth
        value.inputViewHeight = inputViewHeight
        value.inputViewEdgeInsets = inputViewEdgeInsets
        value.voiceTextButtonSize = voiceTextButtonSize
        value.emojiTextButtonSize = emojiTextButtonSize
        value.moreButtonSize = moreButtonSize
        value.voiceTextButtonRightOffset = voiceTextButtonRightOffset
        value.voiceTextButtonBottomOffset = voiceTextButtonBottomOffset
        value.emojiTextButtonLeftOffset = emojiTextButtonLeftOffset
        value.emojiTextButtonBottomOffset = emojiTextButtonBottomOffset
        value.moreButtonLeftOffset = moreButtonLeftOffset
        value.moreButtonBottomOffset = moreButtonBottomOffset
        value.showSpecialSendButton = showSpecialSendButton
        value.specialSendButtonSize = specialSendButtonSize
        value.specialSendButtonLeftOffset = specialSendButtonLeftOffset
        value.specialSendButtonRightOffset = specialSendButtonRightOffset
        value.specialSendButtonBottomOffset = specialSendButtonBottomOffset
        value.specialSendButtonImage = specialSendButtonImage
        value.specialSendButtonCornerRadius = specialSendButtonCornerRadius
        value.specialSendButtonBorderColor = specialSendButtonBorderColor
        value.specialSendButtonBorderWidth = specialSendButtonBorderWidth
        value.specialSendButtonFont = specialSendButtonFont
        value.specialSendButtonTextColor = specialSendButtonTextColor
        value.specialSendButtonText = specialSendButtonText
        value.draftStorageKey = draftStorageKey
        return value
    }
}

@objc(WYEmojiFuncAreaConfig)
@objcMembers public class WYEmojiFuncAreaConfigObjC: NSObject {
    /// 操作区顶部渐变的各停靠点透明度，空数组隐藏渐变
    public var backgroundFadeOpacities: [NSNumber]
    /// 删除按钮无可见标题时使用的无障碍标签
    public var deleteAccessibilityLabel: String
    /// 是否需要在右下角显示功能区(内含删除按钮和发送按钮)
    public var show: Bool
    /// 设置使用独立的发送按钮(当输入框中有字符出现时，会在InputBar的右侧出现一个独立的发送按钮)时，是否需要继续在功能区显示发送按钮
    public var removeSendView: Bool
    /// 功能区显示后，如果列表最后一行的表情被功能区遮挡，被遮挡的表情是否需要换行显示
    public var wrapLastLineOfEmoji: Bool
    /// 整个功能区高度
    public var areaHeight: CGFloat
    /// 删除按钮是否需要支持长按连续删除输入框内容
    public var longPressDelete: Bool
    /// 连续删除开始前的按住时长
    public var longPressDeleteDuration: TimeInterval
    /// 连续删除的重复间隔
    public var deleteRepeatInterval: TimeInterval
    /// 整个功能区距离emoji控件右侧的间距
    public var areaRightOffset: CGFloat
    /// 整个功能区距离emoji控件底部的间距
    public var areaBottomOffset: CGFloat
    /// 删除按钮左侧距离功能区左侧的间距
    public var deleteViewLeftOffsetWithArea: CGFloat
    /// 发送按钮size
    public var sendViewSize: CGSize
    /// 删除按钮size
    public var deleteViewSize: CGSize
    /// 发送按钮左侧和删除按钮右侧之间的间距
    public var sendViewLeftOffsetWithDeleteView: CGFloat
    /// 发送按钮距离功能区右侧间距
    public var sendViewRightOffset: CGFloat
    /// 发送按钮和删除按钮距离功能区顶部的间距
    public var sendViewAndDeleteViewTopOffset: CGFloat
    /// 删除按钮和发送按钮的圆角半径
    public var deleteViewAndSendViewCornerRadius: CGFloat
    /// 删除按钮不可点击时背景图
    public var deleteViewImageWithDisabled: UIImage
    /// 发送按钮不可点击时背景图
    public var sendViewImageWithDisabled: UIImage
    /// 删除按钮可点击时背景图
    public var deleteViewImageWithEnable: UIImage
    /// 发送按钮可点击时背景图
    public var sendViewImageWithEnable: UIImage
    /// 删除按钮按压状态背景图
    public var deleteViewImageWithHighly: UIImage
    /// 发送按钮按压状态背景图
    public var sendViewImageWithHighly: UIImage
    /// 删除按钮文本
    public var deleteViewText: String
    /// 发送按钮文本
    public var sendViewText: String
    /// 删除按钮字体字号
    public var deleteViewFont: UIFont
    /// 发送按钮字体字号
    public var sendViewFont: UIFont
    /// 删除按钮不可点击时文本颜色
    public var deleteViewTextColorWithDisabled: UIColor
    /// 发送按钮不可点击时文本颜色
    public var sendViewTextColorWithDisabled: UIColor
    /// 删除按钮可点击时文本颜色
    public var deleteViewTextColorWithEnable: UIColor
    /// 发送按钮可点击时文本颜色
    public var sendViewTextColorWithEnable: UIColor
    /// 删除按钮按压状态文本颜色
    public var deleteViewTextColorWithHighly: UIColor
    /// 发送按钮按压状态文本颜色
    public var sendViewTextColorWithHighly: UIColor

    public override convenience init() { self.init(WYEmojiFuncAreaConfig()) }

    @nonobjc public init(_ value: WYEmojiFuncAreaConfig) {
        self.backgroundFadeOpacities = value.backgroundFadeOpacities.map { NSNumber(value: Double($0)) }
        self.deleteAccessibilityLabel = value.deleteAccessibilityLabel
        self.show = value.show
        self.removeSendView = value.removeSendView
        self.wrapLastLineOfEmoji = value.wrapLastLineOfEmoji
        self.areaHeight = value.areaHeight
        self.longPressDelete = value.longPressDelete
        longPressDeleteDuration = value.longPressDeleteDuration
        deleteRepeatInterval = value.deleteRepeatInterval
        self.areaRightOffset = value.areaRightOffset
        self.areaBottomOffset = value.areaBottomOffset
        self.deleteViewLeftOffsetWithArea = value.deleteViewLeftOffsetWithArea
        self.sendViewSize = value.sendViewSize
        self.deleteViewSize = value.deleteViewSize
        self.sendViewLeftOffsetWithDeleteView = value.sendViewLeftOffsetWithDeleteView
        self.sendViewRightOffset = value.sendViewRightOffset
        self.sendViewAndDeleteViewTopOffset = value.sendViewAndDeleteViewTopOffset
        self.deleteViewAndSendViewCornerRadius = value.deleteViewAndSendViewCornerRadius
        self.deleteViewImageWithDisabled = value.deleteViewImageWithDisabled
        self.sendViewImageWithDisabled = value.sendViewImageWithDisabled
        self.deleteViewImageWithEnable = value.deleteViewImageWithEnable
        self.sendViewImageWithEnable = value.sendViewImageWithEnable
        self.deleteViewImageWithHighly = value.deleteViewImageWithHighly
        self.sendViewImageWithHighly = value.sendViewImageWithHighly
        self.deleteViewText = value.deleteViewText
        self.sendViewText = value.sendViewText
        self.deleteViewFont = value.deleteViewFont
        self.sendViewFont = value.sendViewFont
        self.deleteViewTextColorWithDisabled = value.deleteViewTextColorWithDisabled
        self.sendViewTextColorWithDisabled = value.sendViewTextColorWithDisabled
        self.deleteViewTextColorWithEnable = value.deleteViewTextColorWithEnable
        self.sendViewTextColorWithEnable = value.sendViewTextColorWithEnable
        self.deleteViewTextColorWithHighly = value.deleteViewTextColorWithHighly
        self.sendViewTextColorWithHighly = value.sendViewTextColorWithHighly
        super.init()
    }

    @nonobjc public func toValue() -> WYEmojiFuncAreaConfig {
        var value = WYEmojiFuncAreaConfig()
        value.backgroundFadeOpacities = backgroundFadeOpacities.map { CGFloat($0.doubleValue) }
        value.deleteAccessibilityLabel = deleteAccessibilityLabel
        value.show = show
        value.removeSendView = removeSendView
        value.wrapLastLineOfEmoji = wrapLastLineOfEmoji
        value.areaHeight = areaHeight
        value.longPressDelete = longPressDelete
        value.longPressDeleteDuration = longPressDeleteDuration
        value.deleteRepeatInterval = deleteRepeatInterval
        value.areaRightOffset = areaRightOffset
        value.areaBottomOffset = areaBottomOffset
        value.deleteViewLeftOffsetWithArea = deleteViewLeftOffsetWithArea
        value.sendViewSize = sendViewSize
        value.deleteViewSize = deleteViewSize
        value.sendViewLeftOffsetWithDeleteView = sendViewLeftOffsetWithDeleteView
        value.sendViewRightOffset = sendViewRightOffset
        value.sendViewAndDeleteViewTopOffset = sendViewAndDeleteViewTopOffset
        value.deleteViewAndSendViewCornerRadius = deleteViewAndSendViewCornerRadius
        value.deleteViewImageWithDisabled = deleteViewImageWithDisabled
        value.sendViewImageWithDisabled = sendViewImageWithDisabled
        value.deleteViewImageWithEnable = deleteViewImageWithEnable
        value.sendViewImageWithEnable = sendViewImageWithEnable
        value.deleteViewImageWithHighly = deleteViewImageWithHighly
        value.sendViewImageWithHighly = sendViewImageWithHighly
        value.deleteViewText = deleteViewText
        value.sendViewText = sendViewText
        value.deleteViewFont = deleteViewFont
        value.sendViewFont = sendViewFont
        value.deleteViewTextColorWithDisabled = deleteViewTextColorWithDisabled
        value.sendViewTextColorWithDisabled = sendViewTextColorWithDisabled
        value.deleteViewTextColorWithEnable = deleteViewTextColorWithEnable
        value.sendViewTextColorWithEnable = sendViewTextColorWithEnable
        value.deleteViewTextColorWithHighly = deleteViewTextColorWithHighly
        value.sendViewTextColorWithHighly = sendViewTextColorWithHighly
        return value
    }
}

@objc(WYEmojiViewConfig)
@objcMembers public class WYEmojiViewConfigObjC: NSObject {
    /// 表情单帧缓存数量，0 或负数关闭单帧缓存
    public var staticFrameCacheCountLimit: Int
    /// 表情动图缓存数量，0 或负数关闭动图缓存
    public var animationCacheCountLimit: Int
    /// 表情动图缓存像素数据预算，单位字节，0 表示不限
    public var animationCacheByteLimit: Int
    /// 表情分区标题对齐方式
    public var headerTextAlignment: NSTextAlignment
    /// 没有最近使用分区时是否仍显示全部表情标题
    public var showsAllHeaderWithoutRecent: Bool
    /// 表情动图未提供有效帧时长时采用的默认秒数
    public var defaultAnimationFrameDelay: TimeInterval
    /// 是否显示垂直滚动条
    public var showsVerticalScrollIndicator: Bool
    /// 是否显示水平滚动条
    public var showsHorizontalScrollIndicator: Bool
    /// 自定义Emoji控件弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval
    /// 自定义Emoji控件背景色
    public var backgroundColor: UIColor
    /// 自定义Emoji控件的高度
    public var contentHeight: CGFloat
    /// 自定义Emoji控件内collectionView底部距离Emoji控件底部的偏移量
    public var collectionViewBottomOffset: CGFloat
    /// 表情列表顶部与面板顶部的间距，包含第一个分区标题之前的留白
    public var collectionViewTopOffset: CGFloat
    /// 自定义Emoji数据源(默认读WYChatView.bundle的WYChatViewEmoji.plist，资源缺失或格式不符时降级为空数组)，示例：["[玫瑰](表情图片名)","[色](表情图片名)","[嘻嘻](表情图片名)"]
    public var emojiSource: [String]
    /// 自定义加载Emoji图片的Bundle
    public var emojiBundle: WYSourceBundleObjC?
    /// 表情资源是否放在同名子文件夹中(如Emojis/微笑/[微笑].png + [微笑].gif)
    public var emojiFolders: Bool
    /// 自定义表情图片加载器(传入表情名和bundle返回UIImage，返回nil时走内部加载链)，适合接入Lottie等内部不支持的格式
    public var customImageLoader: ((_ emojiName: String, _ bundle: WYSourceBundleObjC?) -> UIImage)?
    /// 静态图不存在时从动图取哪一帧当静态图(默认末帧)
    public var staticFramePosition: WYEmojiStaticFramePosition
    /// 自定义Emoji控件是否需要显示最近使用的表情
    public var showRecently: Bool
    /// 最近使用表情是否需要点击发送后就立即更新
    public var instantUpdatesRecently: Bool
    /// 自定义Emoji控件最近使用的表情显示几个(表情默认显示7列，这里就默认设置7个)
    public var recentlyCount: Int
    /// 最近使用表情的保存键，可按账号分别设置
    public var recentlyStorageKey: String
    /// 自定义Emoji控件最近使用表情Header文本(设置后会显示一个Header, 仅限scrollDirection == .vertical时生效)
    public var recentlyHeaderText: String
    /// 自定义Emoji控件所有表情Header文本(设置后会显示一个Header，仅限scrollDirection == .vertical时生效)
    public var totalHeaderText: String
    /// 自定义Emoji控件Header文本字体、字号
    public var headerTextFont: UIFont
    /// 自定义Emoji控件Header文本字体颜色
    public var headerTextColor: UIColor
    /// 自定义Emoji控件HeaderView背景色
    public var headerBackgroundColor: UIColor
    /// 自定义Emoji控件HeaderView高度
    public var headerHeight: CGFloat
    /// 自定义Emoji控件HeaderView中TextView的偏移量
    public var headerTextOffset: CGPoint
    /// 自定义Emoji控件每行显示几个表情
    public var minimumLineCount: Int
    /// 自定义Emoji控件单元格的Size
    public var itemSize: CGSize
    /// 自定义Emoji控件全部表情的sectionInset
    public var sectionInset: UIEdgeInsets
    /// 自定义Emoji控件最近使用分区的sectionInset
    public var recentlySectionInset: UIEdgeInsets
    /// 自定义Emoji控件的行间距
    public var minimumLineSpacing: CGFloat
    /// 自定义Emoji控件右下角功能区配置
    public var funcAreaConfig: WYEmojiFuncAreaConfigObjC
    /// Emoji表情长按预览控件配置
    public var previewConfig: WYEmojiPreviewConfigObjC

    public override convenience init() { self.init(WYEmojiViewConfig()) }

    @nonobjc public init(_ value: WYEmojiViewConfig) {
        self.staticFrameCacheCountLimit = value.staticFrameCacheCountLimit
        self.animationCacheCountLimit = value.animationCacheCountLimit
        self.animationCacheByteLimit = value.animationCacheByteLimit
        self.headerTextAlignment = value.headerTextAlignment
        self.showsAllHeaderWithoutRecent = value.showsAllHeaderWithoutRecent
        self.defaultAnimationFrameDelay = value.defaultAnimationFrameDelay
        self.showsVerticalScrollIndicator = value.showsVerticalScrollIndicator
        self.showsHorizontalScrollIndicator = value.showsHorizontalScrollIndicator
        self.animateDuration = value.animateDuration
        self.backgroundColor = value.backgroundColor
        self.contentHeight = value.contentHeight
        self.collectionViewBottomOffset = value.collectionViewBottomOffset
        self.collectionViewTopOffset = value.collectionViewTopOffset
        self.emojiSource = value.emojiSource
        self.emojiBundle = value.emojiBundle.map { WYSourceBundleObjC(targetClass: $0.targetClass, bundleName: $0.bundleName, subdirectory: $0.subdirectory) }
        self.emojiFolders = value.emojiFolders
        self.customImageLoader = value.customImageLoader.map { source in { name, bundle in source(name, bundle.map { WYSourceBundle(targetClass: $0.targetClass, bundleName: $0.bundleName, subdirectory: $0.subdirectory) }) } }
        self.staticFramePosition = value.staticFramePosition
        self.showRecently = value.showRecently
        self.instantUpdatesRecently = value.instantUpdatesRecently
        self.recentlyCount = value.recentlyCount
        self.recentlyStorageKey = value.recentlyStorageKey
        self.recentlyHeaderText = value.recentlyHeaderText
        self.totalHeaderText = value.totalHeaderText
        self.headerTextFont = value.headerTextFont
        self.headerTextColor = value.headerTextColor
        self.headerBackgroundColor = value.headerBackgroundColor
        self.headerHeight = value.headerHeight
        self.headerTextOffset = value.headerTextOffset
        self.minimumLineCount = value.minimumLineCount
        self.itemSize = value.itemSize
        self.sectionInset = value.sectionInset
        self.recentlySectionInset = value.recentlySectionInset
        self.minimumLineSpacing = value.minimumLineSpacing
        self.funcAreaConfig = WYEmojiFuncAreaConfigObjC(value.funcAreaConfig)
        self.previewConfig = WYEmojiPreviewConfigObjC(value.previewConfig)
        super.init()
    }

    @nonobjc public func toValue() -> WYEmojiViewConfig {
        var value = WYEmojiViewConfig()
        value.staticFrameCacheCountLimit = staticFrameCacheCountLimit
        value.animationCacheCountLimit = animationCacheCountLimit
        value.animationCacheByteLimit = animationCacheByteLimit
        value.headerTextAlignment = headerTextAlignment
        value.showsAllHeaderWithoutRecent = showsAllHeaderWithoutRecent
        value.defaultAnimationFrameDelay = defaultAnimationFrameDelay
        value.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        value.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        value.animateDuration = animateDuration
        value.backgroundColor = backgroundColor
        value.contentHeight = contentHeight
        value.collectionViewBottomOffset = collectionViewBottomOffset
        value.collectionViewTopOffset = collectionViewTopOffset
        value.emojiSource = emojiSource
        value.emojiBundle = emojiBundle.map { WYSourceBundle(targetClass: $0.targetClass, bundleName: $0.bundleName, subdirectory: $0.subdirectory) }
        value.emojiFolders = emojiFolders
        value.customImageLoader = customImageLoader.map { source in { name, bundle in source(name, bundle.map { WYSourceBundleObjC(targetClass: $0.targetClass, bundleName: $0.bundleName, subdirectory: $0.subdirectory) }) } }
        value.staticFramePosition = staticFramePosition
        value.showRecently = showRecently
        value.instantUpdatesRecently = instantUpdatesRecently
        value.recentlyCount = recentlyCount
        value.recentlyStorageKey = recentlyStorageKey
        value.recentlyHeaderText = recentlyHeaderText
        value.totalHeaderText = totalHeaderText
        value.headerTextFont = headerTextFont
        value.headerTextColor = headerTextColor
        value.headerBackgroundColor = headerBackgroundColor
        value.headerHeight = headerHeight
        value.headerTextOffset = headerTextOffset
        value.minimumLineCount = minimumLineCount
        value.itemSize = itemSize
        value.sectionInset = sectionInset
        value.recentlySectionInset = recentlySectionInset
        value.minimumLineSpacing = minimumLineSpacing
        value.funcAreaConfig = funcAreaConfig.toValue()
        value.previewConfig = previewConfig.toValue()
        return value
    }
}

@objc(WYEmojiPreviewConfig)
@objcMembers public class WYEmojiPreviewConfigObjC: NSObject {
    /// 表情预览标题对齐方式
    public var textAlignment: NSTextAlignment
    /// 提供表情预览标题，返回nil时使用本地化表情名
    public var textProvider: ((_ emoji: String) -> String?)?
    /// Emoji表情是否需要支持长按预览详情
    public var show: Bool
    /// 表情预览长按识别时间，单位秒
    public var minimumPressDuration: TimeInterval
    /// 表情长按识别前允许的移动距离
    public var allowableMovement: CGFloat
    /// 表情预览文字左右内边距
    public var textHorizontalInset: CGFloat
    /// 表情预览控件的背景图
    public var backgroundImage: UIImage
    /// 表情预览控件的size
    public var previewSize: CGSize
    /// 表情预览控件内Emoji的size
    public var emojiSize: CGSize
    /// Emoji距离表情预览控件顶部的间距
    public var emojiTopOffset: CGFloat
    /// 表情预览控件内文本控件的字体、字号
    public var textFont: UIFont
    /// 表情预览控件内文本控件的字体颜色
    public var textColor: UIColor
    /// 表情预览控件内文本控件顶部距离Emoji控件底部的间距
    public var textTopOffsetWithEmoji: CGFloat

    public override convenience init() { self.init(WYEmojiPreviewConfig()) }

    @nonobjc public init(_ value: WYEmojiPreviewConfig) {
        self.textAlignment = value.textAlignment
        self.textProvider = value.textProvider
        self.show = value.show
        self.minimumPressDuration = value.minimumPressDuration
        self.allowableMovement = value.allowableMovement
        self.textHorizontalInset = value.textHorizontalInset

        self.backgroundImage = value.backgroundImage
        self.previewSize = value.previewSize
        self.emojiSize = value.emojiSize
        self.emojiTopOffset = value.emojiTopOffset
        self.textFont = value.textFont
        self.textColor = value.textColor
        self.textTopOffsetWithEmoji = value.textTopOffsetWithEmoji
        super.init()
    }

    @nonobjc public func toValue() -> WYEmojiPreviewConfig {
        var value = WYEmojiPreviewConfig()
        value.textAlignment = textAlignment
        value.textProvider = textProvider
        value.show = show
        value.minimumPressDuration = minimumPressDuration
        value.allowableMovement = allowableMovement
        value.textHorizontalInset = textHorizontalInset

        value.backgroundImage = backgroundImage
        value.previewSize = previewSize
        value.emojiSize = emojiSize
        value.emojiTopOffset = emojiTopOffset
        value.textFont = textFont
        value.textColor = textColor
        value.textTopOffsetWithEmoji = textTopOffsetWithEmoji
        return value
    }
}

@objc(WYMoreViewConfig)
@objcMembers public class WYMoreViewConfigObjC: NSObject {
    /// 更多面板图标的显示方式
    public var iconContentMode: UIView.ContentMode
    /// 更多面板标题对齐方式
    public var textAlignment: NSTextAlignment
    /// 更多面板标题是否自动缩小以适应按钮宽度
    public var titleAdjustsFontSizeToFitWidth: Bool
    /// 更多面板分页指示器的背景色
    public var pageControlBackgroundColor: UIColor
    /// 是否显示垂直滚动条
    public var showsVerticalScrollIndicator: Bool
    /// 是否显示水平滚动条
    public var showsHorizontalScrollIndicator: Bool
    /// 自定义More控件弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval
    /// 自定义More控件背景色
    public var backgroundColor: UIColor
    /// 自定义More控件滚动方向
    public var scrollDirection: UICollectionView.ScrollDirection
    /// 一页就可以显示所有item的时候，是否显示分页指示器(翻页模式开启时才显示分页指示器)
    public var pageControlHideForSingle: Bool
    /// 是否需要显示分页指示器
    public var showPageControl: Bool
    /// 分页指示器是否允许用户点击(翻页模式开启时才显示分页指示器)
    public var pageControlUserInteractionEnabled: Bool
    /// 自定义More控件是否需要翻页模式
    public var isPagingEnabled: Bool
    /// 更多面板的数据源，数组决定显示顺序，每项包含一个标题及其图片
    public var moreSource: [[String: UIImage]]
    /// 自定义More控件的Inset
    public var contentInset: UIEdgeInsets
    /// 自定义More控件内imageView的背景色
    public var imageViewBackgroundColor: UIColor
    /// 自定义More控件内imageView的Size
    public var imageViewSize: CGSize
    /// 更多面板图标的显示尺寸
    public var iconSize: CGSize
    /// 按菜单标题覆盖图标着色
    public var iconTintColors: [String: UIColor]
    /// 自定义More控件内imageView的圆角半径
    public var imageViewCornerRadius: CGFloat
    /// 自定义More控件内imageView的背景色
    public var imageBackgroundColor: UIColor
    /// 自定义More控件内文本控件的字体、字号
    public var textViewFont: UIFont
    /// 自定义More控件内文本控件的色值
    public var textColor: UIColor
    /// 自定义More控件内文本控件顶部距离图片控件底部的间距
    public var textTopOffset: CGFloat
    /// 自定义More控件内一行显示几个item
    public var itemMaxCountWithLine: Int
    /// scrollDirection == vertical时 自定义More控件内每页可以显示几列
    public var itemMaxCountWithColumn: Int
    /// 自定义More控件内一页最多显示几行
    public var itemMaxLineWithPage: Int
    /// 自定义More控件是否需要按照 itemMaxLineWithPage 来显示高度，false的话高度会自动计算
    public var maxHeightForever: Bool
    /// 自定义More控件内item的行间距
    public var minimumLineSpacing: CGFloat
    /// 分页控件原点位置
    public var pageControlPosition: NSValue?

    public override convenience init() { self.init(WYMoreViewConfig()) }

    @nonobjc public init(_ value: WYMoreViewConfig) {
        self.iconContentMode = value.iconContentMode
        self.textAlignment = value.textAlignment
        self.titleAdjustsFontSizeToFitWidth = value.titleAdjustsFontSizeToFitWidth
        self.pageControlBackgroundColor = value.pageControlBackgroundColor
        self.showsVerticalScrollIndicator = value.showsVerticalScrollIndicator
        self.showsHorizontalScrollIndicator = value.showsHorizontalScrollIndicator
        self.animateDuration = value.animateDuration
        self.backgroundColor = value.backgroundColor
        self.scrollDirection = value.scrollDirection
        self.pageControlHideForSingle = value.pageControlHideForSingle
        self.showPageControl = value.showPageControl
        self.pageControlUserInteractionEnabled = value.pageControlUserInteractionEnabled
        self.isPagingEnabled = value.isPagingEnabled
        self.moreSource = value.moreSource
        self.contentInset = value.contentInset
        self.imageViewBackgroundColor = value.imageViewBackgroundColor
        self.imageViewSize = value.imageViewSize
        self.iconSize = value.iconSize
        iconTintColors = value.iconTintColors
        self.imageViewCornerRadius = value.imageViewCornerRadius
        self.imageBackgroundColor = value.imageBackgroundColor
        self.textViewFont = value.textViewFont
        self.textColor = value.textColor
        self.textTopOffset = value.textTopOffset
        self.itemMaxCountWithLine = value.itemMaxCountWithLine
        self.itemMaxCountWithColumn = value.itemMaxCountWithColumn
        self.itemMaxLineWithPage = value.itemMaxLineWithPage
        self.maxHeightForever = value.maxHeightForever
        self.minimumLineSpacing = value.minimumLineSpacing
        self.pageControlPosition = value.pageControlPosition.map { NSValue(cgPoint: $0) }
        super.init()
    }

    @nonobjc public func toValue() -> WYMoreViewConfig {
        var value = WYMoreViewConfig()
        value.iconContentMode = iconContentMode
        value.textAlignment = textAlignment
        value.titleAdjustsFontSizeToFitWidth = titleAdjustsFontSizeToFitWidth
        value.pageControlBackgroundColor = pageControlBackgroundColor
        value.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        value.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        value.animateDuration = animateDuration
        value.backgroundColor = backgroundColor
        value.scrollDirection = scrollDirection
        value.pageControlHideForSingle = pageControlHideForSingle
        value.showPageControl = showPageControl
        value.pageControlUserInteractionEnabled = pageControlUserInteractionEnabled
        value.isPagingEnabled = isPagingEnabled
        value.moreSource = moreSource
        value.contentInset = contentInset
        value.imageViewBackgroundColor = imageViewBackgroundColor
        value.imageViewSize = imageViewSize
        value.iconSize = iconSize
        value.iconTintColors = iconTintColors
        value.imageViewCornerRadius = imageViewCornerRadius
        value.imageBackgroundColor = imageBackgroundColor
        value.textViewFont = textViewFont
        value.textColor = textColor
        value.textTopOffset = textTopOffset
        value.itemMaxCountWithLine = itemMaxCountWithLine
        value.itemMaxCountWithColumn = itemMaxCountWithColumn
        value.itemMaxLineWithPage = itemMaxLineWithPage
        value.maxHeightForever = maxHeightForever
        value.minimumLineSpacing = minimumLineSpacing
        value.pageControlPosition = pageControlPosition?.cgPointValue
        return value
    }
}

#endif
