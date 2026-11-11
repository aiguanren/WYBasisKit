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
        self.fillColor = value.fillColor
        self.cornerRadius = value.cornerRadius
        self.cornersPosition = value.cornersPosition
        self.showsArrow = value.showsArrow
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
        value.fillColor = fillColor
        value.cornerRadius = cornerRadius
        value.cornersPosition = cornersPosition
        value.showsArrow = showsArrow
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
    /// 图片占位图
    public var placeholderImage: UIImage?
    /// 是否显示气泡，默认true
    public var showsBubble: Bool

    public override convenience init() { self.init(WYChatContentConfig()) }

    @nonobjc public init(_ value: WYChatContentConfig) {
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
        self.showsBubble = value.showsBubble
        super.init()
    }

    @nonobjc public func toValue() -> WYChatContentConfig {
        var value = WYChatContentConfig()
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
        value.showsBubble = showsBubble
        return value
    }
}

@objc(WYChatConfig)
@objcMembers public class WYChatConfigObjC: NSObject {
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
    /// 默认菜单操作，宿主通过回调执行外部操作
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

@objc(WYRecordAnimationConfig)
@objcMembers public class WYRecordAnimationConfigObjC: NSObject {
    /// 录音浮层遮罩颜色
    public var overlayBackgroundColor: UIColor
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
    /// 直接转写是否显示声波，默认false
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
        self.overlayBackgroundColor = value.overlayBackgroundColor
        self.recordingHintSpacing = value.recordingHintSpacing
        self.dictationReleaseText = value.dictationReleaseText
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
        value.overlayBackgroundColor = overlayBackgroundColor
        value.recordingHintSpacing = recordingHintSpacing
        value.dictationReleaseText = dictationReleaseText
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
    /// 默认头像
    public var defaultAvatar: UIImage?
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
        self.messageMinimumTimeSpan = value.messageMinimumTimeSpan
        self.avatarSize = value.avatarSize
        self.defaultAvatar = value.defaultAvatar
        self.avatarContentMode = value.avatarContentMode
        self.avatarCornerRadius = value.avatarCornerRadius
        avatarTapAction = value.avatarTapAction
        avatarLongPressAction = value.avatarLongPressAction
        avatarDoubleTapAction = value.avatarDoubleTapAction
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
        value.messageMinimumTimeSpan = messageMinimumTimeSpan
        value.avatarSize = avatarSize
        value.defaultAvatar = defaultAvatar
        value.avatarContentMode = avatarContentMode
        value.avatarCornerRadius = avatarCornerRadius
        value.avatarTapAction = avatarTapAction
        value.avatarLongPressAction = avatarLongPressAction
        value.avatarDoubleTapAction = avatarDoubleTapAction
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

@objc(WYTextChatConfig)
@objcMembers public class WYTextChatConfigObjC: NSObject {
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
    /// 自动识别的链接类型
    public var dataDetectorTypes: UIDataDetectorTypes

    public override convenience init() { self.init(WYTextChatConfig()) }

    @nonobjc public init(_ value: WYTextChatConfig) {
        self.textMaximumNumberOfLines = value.textMaximumNumberOfLines
        self.textFont = value.textFont
        self.textColor = value.textColor
        self.textLineSpacing = value.textLineSpacing
        self.isSelectable = value.isSelectable
        self.dataDetectorTypes = value.dataDetectorTypes
        super.init()
    }

    @nonobjc public func toValue() -> WYTextChatConfig {
        var value = WYTextChatConfig()
        value.textMaximumNumberOfLines = textMaximumNumberOfLines
        value.textFont = textFont
        value.textColor = textColor
        value.textLineSpacing = textLineSpacing
        value.isSelectable = isSelectable
        value.dataDetectorTypes = dataDetectorTypes
        return value
    }
}

@objc(WYInputBarConfig)
@objcMembers public class WYInputBarConfigObjC: NSObject {
    /// 草稿保存键，空字符串时不跨实例保存草稿
    public var draftStorageKey: String = ""
    /// 是否允许长按语音切换按钮直接转写，默认true，需要启用语音识别
    public var enablesVoiceButtonDictation: Bool
    /// 长按语音切换按钮开始转写的等待时间，单位秒
    public var voiceButtonLongPressDuration: TimeInterval
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

    /// 是否用iconTintColor绘制输入栏图标，默认true
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
        self.enablesVoiceButtonDictation = value.enablesVoiceButtonDictation
        self.voiceButtonLongPressDuration = value.voiceButtonLongPressDuration
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
        value.enablesVoiceButtonDictation = enablesVoiceButtonDictation
        value.voiceButtonLongPressDuration = voiceButtonLongPressDuration
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
    /// 自定义Emoji控件弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval
    /// 自定义Emoji控件背景色
    public var backgroundColor: UIColor
    /// 自定义Emoji控件的高度
    public var contentHeight: CGFloat
    /// 自定义Emoji控件内collectionView底部距离Emoji控件底部的偏移量
    public var collectionViewBottomOffset: CGFloat
    /// 自定义Emoji数据源(默认读WYChatView.bundle的WYChatViewEmoji.plist，资源缺失或格式不符时降级为空数组)，示例：["[玫瑰](表情图片名)","[色](表情图片名)","[嘻嘻](表情图片名)"]
    public var emojiSource: [String]
    /// 自定义加载Emoji图片的Bundle
    public var emojiBundle: WYSourceBundleObjC?
    /// 表情资源是否放在同名子文件夹中(如WYChatViewEmoji/微笑/[微笑].png + [微笑].gif)
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
        self.animateDuration = value.animateDuration
        self.backgroundColor = value.backgroundColor
        self.contentHeight = value.contentHeight
        self.collectionViewBottomOffset = value.collectionViewBottomOffset
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
        value.animateDuration = animateDuration
        value.backgroundColor = backgroundColor
        value.contentHeight = contentHeight
        value.collectionViewBottomOffset = collectionViewBottomOffset
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
    /// 图标加载，参数为资源名，返回nil时使用默认资源查找
    public var imageProvider: ((_ name: String) -> UIImage?)? = nil
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
    /// 自定义More控件数据源
    public var moreSource: [[String: String]]
    /// 自定义More控件的Inset
    public var contentInset: UIEdgeInsets
    /// 自定义More控件内imageView的背景色
    public var imageViewBackgroundColor: UIColor
    /// 自定义More控件内imageView的Size
    public var imageViewSize: CGSize
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
        self.imageProvider = value.imageProvider
        super.init()
    }

    @nonobjc public func toValue() -> WYMoreViewConfig {
        var value = WYMoreViewConfig()
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
        value.imageProvider = imageProvider
        return value
    }
}

#endif
