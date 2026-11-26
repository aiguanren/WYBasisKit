//
//  WYChatQuoteObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 引用消息的身份与内容快照
@objc(WYChatQuoteModel)
@objcMembers public class WYChatQuoteModelObjC: NSObject {
    /// 被引用的消息ID
    public var messageID: String
    /// 被引用消息的发送者
    public var sender: WYChatUserModelObjC
    /// 被引用的内容快照
    public var content: WYChatMessageContentModelObjC
    public override convenience init() { self.init(WYChatQuoteModel()) }
    @nonobjc public init(_ value: WYChatQuoteModel) { messageID = value.messageID; sender = WYChatUserModelObjC(value.sender); content = WYChatMessageContentModelObjC(value.content); super.init() }
    @nonobjc public func toValue() -> WYChatQuoteModel { WYChatQuoteModel(messageID: messageID, sender: sender.toValue(), content: content.toValue()) }
}

/// 引用预览外观
@objc(WYChatQuoteStyle)
@objcMembers public class WYChatQuoteStyleObjC: NSObject {
    /// 引用关闭按钮的最小触控宽度
    public var closeMinimumTouchWidth: CGFloat
    /// 引用发送者名称最大行数，0表示不限
    public var titleNumberOfLines: Int
    /// 引用摘要的换行或截断方式
    public var textLineBreakMode: NSLineBreakMode
    /// 引用缩略图的显示方式
    public var thumbnailContentMode: UIView.ContentMode
    /// 分行引用的无障碍朗读分隔文字
    public var accessibilitySeparator: String
    /// 关闭引用按钮的无障碍标签
    public var closeAccessibilityLabel: String
    /// 行内引用发送者与摘要之间的分隔文字
    public var inlineSenderSeparator: String
    /// 引用内容内边距
    public var insets: UIEdgeInsets
    /// 发送者与内容的间距
    public var spacing: CGFloat
    /// 缩略图、文本与关闭按钮的间距
    public var itemSpacing: CGFloat
    /// 引用发送者字体
    public var titleFont: UIFont
    /// 引用发送者颜色
    public var titleColor: UIColor
    /// 引用摘要字体
    public var textFont: UIFont
    /// 引用摘要颜色
    public var textColor: UIColor
    /// 引用背景色
    public var backgroundColor: UIColor
    /// 引用圆角
    public var cornerRadius: CGFloat
    /// 引用摘要最大行数，0表示不限
    public var maximumTextLines: Int
    /// 引用最小高度
    public var minimumHeight: CGFloat
    /// 引用最大高度，0表示不限
    public var maximumHeight: CGFloat
    /// 是否显示引用发送者，默认true
    public var showsSender: Bool
    /// 是否将发送者与摘要显示在同一段
    public var showsSenderInline: Bool
    /// 引用内容的前缀
    public var prefix: String
    /// 是否显示引用媒体缩略图，默认true
    public var showsThumbnail: Bool
    /// 引用媒体缩略图尺寸
    public var thumbnailSize: CGSize
    /// 引用媒体缩略图圆角
    public var thumbnailCornerRadius: CGFloat
    /// 引用媒体占位图
    public var thumbnailPlaceholder: UIImage?
    /// 是否显示关闭按钮，默认false
    public var showsCloseButton: Bool
    /// 引用关闭按钮图片
    public var closeImage: UIImage?
    /// 引用关闭按钮颜色
    public var closeColor: UIColor
    /// 引用关闭按钮的图标尺寸
    public var closeSize: CGSize
    public override convenience init() { self.init(WYChatQuoteStyle()) }
    @nonobjc public init(_ value: WYChatQuoteStyle) {
        self.closeMinimumTouchWidth = value.closeMinimumTouchWidth
        self.titleNumberOfLines = value.titleNumberOfLines
        self.textLineBreakMode = value.textLineBreakMode
        self.thumbnailContentMode = value.thumbnailContentMode
        self.accessibilitySeparator = value.accessibilitySeparator
        self.closeAccessibilityLabel = value.closeAccessibilityLabel
        self.inlineSenderSeparator = value.inlineSenderSeparator
        insets = value.insets
        spacing = value.spacing
        itemSpacing = value.itemSpacing
        titleFont = value.titleFont
        titleColor = value.titleColor
        textFont = value.textFont
        textColor = value.textColor
        backgroundColor = value.backgroundColor
        cornerRadius = value.cornerRadius
        maximumTextLines = value.maximumTextLines
        minimumHeight = value.minimumHeight
        maximumHeight = value.maximumHeight
        showsSender = value.showsSender
        showsSenderInline = value.showsSenderInline
        prefix = value.prefix
        showsThumbnail = value.showsThumbnail
        thumbnailSize = value.thumbnailSize
        thumbnailCornerRadius = value.thumbnailCornerRadius
        thumbnailPlaceholder = value.thumbnailPlaceholder
        showsCloseButton = value.showsCloseButton
        closeImage = value.closeImage
        closeColor = value.closeColor
        closeSize = value.closeSize
        super.init()
    }
    @nonobjc public func toValue() -> WYChatQuoteStyle {
        var value = WYChatQuoteStyle()
        value.closeMinimumTouchWidth = closeMinimumTouchWidth
        value.titleNumberOfLines = titleNumberOfLines
        value.textLineBreakMode = textLineBreakMode
        value.thumbnailContentMode = thumbnailContentMode
        value.accessibilitySeparator = accessibilitySeparator
        value.closeAccessibilityLabel = closeAccessibilityLabel
        value.inlineSenderSeparator = inlineSenderSeparator
        value.insets = insets
        value.spacing = spacing
        value.itemSpacing = itemSpacing
        value.titleFont = titleFont
        value.titleColor = titleColor
        value.textFont = textFont
        value.textColor = textColor
        value.backgroundColor = backgroundColor
        value.cornerRadius = cornerRadius
        value.maximumTextLines = maximumTextLines
        value.minimumHeight = minimumHeight
        value.maximumHeight = maximumHeight
        value.showsSender = showsSender
        value.showsSenderInline = showsSenderInline
        value.prefix = prefix
        value.showsThumbnail = showsThumbnail
        value.thumbnailSize = thumbnailSize
        value.thumbnailCornerRadius = thumbnailCornerRadius
        value.thumbnailPlaceholder = thumbnailPlaceholder
        value.showsCloseButton = showsCloseButton
        value.closeImage = closeImage
        value.closeColor = closeColor
        value.closeSize = closeSize
        return value
    }
}

/// 引用消息与输入预览配置
@objc(WYChatQuoteConfig)
@objcMembers public class WYChatQuoteConfigObjC: NSObject {
    /// 输入框引用外观
    public var input: WYChatQuoteStyleObjC
    /// 消息引用外观
    public var message: WYChatQuoteStyleObjC
    /// 输入框引用外边距
    public var inputOuterInsets: UIEdgeInsets
    /// 是否将引用预览放在输入框下方，关闭时显示在输入栏上方
    public var inputBelowTextField: Bool
    /// 是否按文本框宽度对齐引用预览，关闭时按输入栏宽度对齐
    public var inputAlignsWithTextField: Bool
    /// 消息引用与气泡的间距
    public var messageSpacing: CGFloat
    /// 消息引用首选宽度
    public var messageWidth: CGFloat
    /// 是否按内容缩小消息引用宽度，启用时首选宽度作为上限
    public var fitsMessageContent: Bool
    public override convenience init() { self.init(WYChatQuoteConfig()) }
    @nonobjc public init(_ value: WYChatQuoteConfig) {
        input = WYChatQuoteStyleObjC(value.input)
        message = WYChatQuoteStyleObjC(value.message)
        inputOuterInsets = value.inputOuterInsets
        inputBelowTextField = value.inputBelowTextField
        inputAlignsWithTextField = value.inputAlignsWithTextField
        messageSpacing = value.messageSpacing
        messageWidth = value.messageWidth
        fitsMessageContent = value.fitsMessageContent
        super.init()
    }
    @nonobjc public func toValue() -> WYChatQuoteConfig {
        var value = WYChatQuoteConfig()
        value.input = input.toValue()
        value.message = message.toValue()
        value.inputOuterInsets = inputOuterInsets
        value.inputBelowTextField = inputBelowTextField
        value.inputAlignsWithTextField = inputAlignsWithTextField
        value.messageSpacing = messageSpacing
        value.messageWidth = messageWidth
        value.fitsMessageContent = fitsMessageContent
        return value
    }
}

/// 撤回与重新编辑配置
@objc(WYChatNoticeConfig)
@objcMembers public class WYChatNoticeConfigObjC: NSObject {
    /// 发出红包的领取回执，{actor}替换为领取者名称
    public var fundsSentPacketReceiptText: String
    /// 收到红包的领取回执，{actor}替换为发出者名称
    public var fundsIncomingPacketReceiptText: String
    /// 发出转账的接收回执，{actor}替换为接收者名称
    public var fundsSentTransferReceiptText: String
    /// 收到转账的接收回执，{actor}替换为发出者名称
    public var fundsIncomingTransferReceiptText: String
    /// 红包回执图标，nil时隐藏
    public var fundsPacketReceiptImage: UIImage?
    /// 转账回执图标，nil时隐藏
    public var fundsTransferReceiptImage: UIImage?
    /// 回执中红包或转账关键词及模板图标的颜色
    public var fundsReceiptAccentColor: UIColor?
    /// 收款回执背景色，nil时只显示文字与图标
    public var fundsReceiptBackgroundColor: UIColor?
    /// 红包回执图标着色，nil时保留图片原色
    public var fundsPacketReceiptTintColor: UIColor?
    /// 转账回执图标着色，nil时保留图片原色
    public var fundsTransferReceiptTintColor: UIColor?
    /// 资金回执图标的默认边长，单位点
    public var fundsReceiptIconSide: CGFloat
    /// 居中系统提示的文字对齐方式
    public var centeredTextAlignment: NSTextAlignment
    /// 发出的通话记录图标是否放在尾侧
    public var outgoingCallIconOnTrailing: Bool
    /// 通话时长文案，{duration}替换为格式化时长
    public var callDurationText: String
    /// 未接通的通话提示
    public var unconnectedCallText: String
    /// 普通消息可请求撤回的时长，单位秒，0表示不限
    public var withdrawalTimeLimit: TimeInterval
    /// 是否提供拍一拍撤回操作，默认true
    public var allowsPatWithdrawal: Bool
    /// 拍一拍可请求撤回的时长，单位秒，0表示不限
    public var patWithdrawalTimeLimit: TimeInterval
    /// 是否显示文本消息重新编辑入口，默认true
    public var allowsReedit: Bool
    /// 撤回后可重新编辑的时长，单位秒，0表示不限
    public var reeditTimeLimit: TimeInterval
    /// 重新编辑时是否替换当前输入，默认true，false时在当前选区插入
    public var reeditReplacesInput: Bool
    /// 重新编辑按钮文字
    public var reeditText: String
    /// 重新编辑按钮字体
    public var reeditFont: UIFont
    /// 重新编辑按钮颜色
    public var reeditColor: UIColor
    /// 重新编辑按钮高度
    public var reeditHeight: CGFloat
    /// 重新编辑按钮与提示文字的间距
    public var reeditSpacing: CGFloat
    /// 普通消息撤回提示，%@替换为发送者名称
    public var withdrawnText: String
    /// 拍一拍撤回提示，空字符串时使用withdrawnText，%@替换为发送者名称
    public var patWithdrawnText: String
    public var patBackgroundColor: UIColor?
    public var patCornerRadius: CGFloat
    public var patText: String?
    public override convenience init() { self.init(WYChatNoticeConfig()) }
    @nonobjc public init(_ value: WYChatNoticeConfig) {
        self.fundsSentPacketReceiptText = value.fundsSentPacketReceiptText
        self.fundsIncomingPacketReceiptText = value.fundsIncomingPacketReceiptText
        self.fundsSentTransferReceiptText = value.fundsSentTransferReceiptText
        self.fundsIncomingTransferReceiptText = value.fundsIncomingTransferReceiptText
        self.fundsPacketReceiptImage = value.fundsPacketReceiptImage
        self.fundsTransferReceiptImage = value.fundsTransferReceiptImage
        self.fundsReceiptAccentColor = value.fundsReceiptAccentColor
        self.fundsReceiptBackgroundColor = value.fundsReceiptBackgroundColor
        self.fundsPacketReceiptTintColor = value.fundsPacketReceiptTintColor
        self.fundsTransferReceiptTintColor = value.fundsTransferReceiptTintColor
        self.fundsReceiptIconSide = value.fundsReceiptIconSide
        self.centeredTextAlignment = value.centeredTextAlignment
        self.outgoingCallIconOnTrailing = value.outgoingCallIconOnTrailing
        self.callDurationText = value.callDurationText
        self.unconnectedCallText = value.unconnectedCallText
        withdrawalTimeLimit = value.withdrawalTimeLimit
        allowsPatWithdrawal = value.allowsPatWithdrawal
        patWithdrawalTimeLimit = value.patWithdrawalTimeLimit
        allowsReedit = value.allowsReedit
        reeditTimeLimit = value.reeditTimeLimit
        reeditReplacesInput = value.reeditReplacesInput
        reeditText = value.reeditText
        reeditFont = value.reeditFont
        reeditColor = value.reeditColor
        reeditHeight = value.reeditHeight
        reeditSpacing = value.reeditSpacing
        withdrawnText = value.withdrawnText
        patWithdrawnText = value.patWithdrawnText
        patBackgroundColor = value.patBackgroundColor
        patCornerRadius = value.patCornerRadius
        patText = value.patText
        super.init()
    }
    @nonobjc public func toValue() -> WYChatNoticeConfig {
        var value = WYChatNoticeConfig()
        value.fundsSentPacketReceiptText = fundsSentPacketReceiptText
        value.fundsIncomingPacketReceiptText = fundsIncomingPacketReceiptText
        value.fundsSentTransferReceiptText = fundsSentTransferReceiptText
        value.fundsIncomingTransferReceiptText = fundsIncomingTransferReceiptText
        value.fundsPacketReceiptImage = fundsPacketReceiptImage
        value.fundsTransferReceiptImage = fundsTransferReceiptImage
        value.fundsReceiptAccentColor = fundsReceiptAccentColor
        value.fundsReceiptBackgroundColor = fundsReceiptBackgroundColor
        value.fundsPacketReceiptTintColor = fundsPacketReceiptTintColor
        value.fundsTransferReceiptTintColor = fundsTransferReceiptTintColor
        value.fundsReceiptIconSide = fundsReceiptIconSide
        value.centeredTextAlignment = centeredTextAlignment
        value.outgoingCallIconOnTrailing = outgoingCallIconOnTrailing
        value.callDurationText = callDurationText
        value.unconnectedCallText = unconnectedCallText
        value.withdrawalTimeLimit = withdrawalTimeLimit
        value.allowsPatWithdrawal = allowsPatWithdrawal
        value.patWithdrawalTimeLimit = patWithdrawalTimeLimit
        value.allowsReedit = allowsReedit
        value.reeditTimeLimit = reeditTimeLimit
        value.reeditReplacesInput = reeditReplacesInput
        value.reeditText = reeditText
        value.reeditFont = reeditFont
        value.reeditColor = reeditColor
        value.reeditHeight = reeditHeight
        value.reeditSpacing = reeditSpacing
        value.withdrawnText = withdrawnText
        value.patWithdrawnText = patWithdrawnText
        value.patBackgroundColor = patBackgroundColor
        value.patCornerRadius = patCornerRadius
        value.patText = patText
        return value
    }
}

public extension WYChatQuoteView {
    /// 引用快照，nil时隐藏预览
    @objc(quote) var quoteObjC: WYChatQuoteModelObjC? { get { quote.map(WYChatQuoteModelObjC.init) } set { quote = newValue?.toValue() } }
    /// 引用外观
    @objc(style) var styleObjC: WYChatQuoteStyleObjC { get { WYChatQuoteStyleObjC(style) } set { style = newValue.toValue() } }
    /// 引用发送者控件
    @objc(titleView) var titleViewObjC: UILabel { titleView }
    /// 引用摘要控件
    @objc(textView) var textViewObjC: UILabel { textView }
    /// 引用缩略图控件
    @objc(thumbnailView) var thumbnailViewObjC: UIImageView { thumbnailView }
    /// 引用关闭控件
    @objc(closeButton) var closeButtonObjC: UIButton { closeButton }
    /// 点击引用内容
    @objc(tapHandler) var tapHandlerObjC: (() -> Void)? { get { tapHandler } set { tapHandler = newValue } }
    /// 关闭引用
    @objc(closeHandler) var closeHandlerObjC: (() -> Void)? { get { closeHandler } set { closeHandler = newValue } }
    /// 自定义图片加载，参数为资源、目标控件及被引用消息ID
    @objc(imageLoader) var imageLoaderObjC: ((_ asset: WYChatAssetsModelObjC, _ imageView: UIImageView, _ messageID: String) -> Void)? {
        get { imageLoader.map { handler in { asset, view, identifier in handler(asset.toValue(), view, identifier) } } }
        set { imageLoader = newValue.map { handler in { asset, view, identifier in handler(WYChatAssetsModelObjC(asset), view, identifier) } } }
    }
    /// 更新引用内容与外观，参数为引用快照、引用外观及图片加载回调
    @objc(update) var updateObjC: @convention(block) (_ quote: WYChatQuoteModelObjC?, _ style: WYChatQuoteStyleObjC, _ imageLoader: ((_ asset: WYChatAssetsModelObjC, _ imageView: UIImageView, _ messageID: String) -> Void)?) -> WYChatQuoteView {
        { [self] quote, style, bridge in
            let loader: ((_ asset: WYChatAssetsModel, _ imageView: UIImageView, _ messageID: String) -> Void)? = bridge.map { handler in { asset, view, identifier in handler(WYChatAssetsModelObjC(asset), view, identifier) } }
            update(quote: quote?.toValue(), style: style.toValue(), imageLoader: loader)
            return self
        }
    }
}

#endif
