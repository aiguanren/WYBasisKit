//
//  WYChatBasicCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit

/// 双击头像时可以触发拍一拍的对象。
@objc public enum WYChatAvatarDoubleTapPatScope: Int {
    case disabled
    case othersOnly
    case selfOnly
    case everyone
}

/// 消息发送与撤回时间戳的单位。
@objc public enum WYChatTimestampUnit: Int {
    /// 读取时兼容秒和常见的 13 位毫秒时间戳，写入时使用秒。
    case automatic
    case seconds
    case milliseconds
}

/// 通用聊天配置选项
public struct WYBasicChatConfig {
    /// 消息发送时间和撤回时间的单位。
    public var timestampUnit: WYChatTimestampUnit = .automatic

    /// 按消息定制已读标记，返回nil时使用默认已读或未读文本
    public var readMarkFormatter: ((_ message: WYChatMessageModel) -> String?)? = nil
    /// 消息时间的文字对齐方式
    public var timeTextAlignment: NSTextAlignment = .center
    /// 日期与时间之间的分隔文字
    public var dateTimeSeparator: String = " "
    /// 计算气泡最大宽度时是否为发送状态预留空间
    public var reservesSendingStatusSpace: Bool = true
    /// 消息发送中的系统活动指示器样式
    public var loadingIndicatorStyle: UIActivityIndicatorView.Style = .medium
    /// 24小时制消息时间格式
    public var timeFormat: String = "HH:mm"
    /// 12小时制消息时间格式
    public var amPmTimeFormat: String = "a h:mm"
    /// 昨天的消息日期标签
    public var yesterdayText: String = WYLocalized("昨天", table: WYBasisKitConfig.kitLocalizableTable)
    /// 近期消息的星期格式
    public var weekdayFormat: String = "EEEE"
    /// 按星期显示的天数，0时关闭
    public var weekdayDisplayDays: Int = 7
    /// 今年的消息日期模板
    public var currentYearDateTemplate: String = "MMMd"
    /// 其他年份的消息日期模板
    public var previousYearDateTemplate: String = "yyyyMMMd"
    /// 消息显示的最小时间跨度，单位秒
    public var messageMinimumTimeSpan: TimeInterval = 300
    /// 头像尺寸
    public var avatarSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels))
    /// 自定义头像占位图，nil时使用纯色或渐变占位
    public var defaultAvatar: UIImage? = nil
    /// 默认头像占位颜色
    public var avatarPlaceholderColor: UIColor = WYChatDefaultResources.placeholderColor
    /// 默认头像占位圆角半径，负值表示圆形，0表示直角
    public var avatarPlaceholderCornerRadius: CGFloat = -1
    /// 默认头像占位渐变颜色，少于两个颜色时使用纯色
    public var avatarPlaceholderGradientColors: [UIColor] = []
    /// 默认头像占位渐变方向
    public var avatarPlaceholderGradientDirection: WYGradientDirection = .leftToRight
    /// 头像显示方式
    public var avatarContentMode: UIView.ContentMode = .scaleAspectFill
    /// 头像圆角
    public var avatarCornerRadius: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    /// 头像单击操作，默认打开用户信息
    public var avatarTapAction: WYChatAvatarAction = .profile
    /// 头像长按操作，默认提及用户
    public var avatarLongPressAction: WYChatAvatarAction = .mention
    /// 头像双击操作，默认请求拍一拍
    public var avatarDoubleTapAction: WYChatAvatarAction = .takePat
    /// 双击头像的拍一拍对象范围
    public var avatarDoubleTapPatScope: WYChatAvatarDoubleTapPatScope = .everyone
    /// 拍一拍时提供轻触反馈，默认开启
    public var enablesAvatarPatHaptics: Bool = true
    /// 头像长按识别时间，单位秒
    public var avatarLongPressDuration: TimeInterval = 0.35
    /// 拍一拍反馈动画时长，0表示不播放
    public var avatarPatAnimationDuration: TimeInterval = 0.4
    /// 拍一拍反馈的旋转角度序列，单位弧度
    public var avatarPatAnimationAngles: [CGFloat] = [0, -.pi / 36, .pi / 36, -.pi / 72, .pi / 72, 0]
    /// 头像提及时是否自动插入输入框，默认true
    public var automaticallyInsertsMentions: Bool = true
    /// 提及用户的前缀
    public var mentionPrefix: String = "@"
    /// 提及用户后的分隔文本
    public var mentionSuffix: String = " "
    /// 昵称字体
    public var nicknameFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    /// 昵称颜色
    public var nicknameColor: UIColor = .secondaryLabel
    /// 时间字体
    public var timeFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    /// 时间颜色
    public var timeColor: UIColor = .secondaryLabel
    /// 时间与消息间距
    public var timeViewOffset: CGFloat = UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels)
    /// 时间是否显示上午下午标识
    public var showAmPmSymbol: Bool = false
    /// 是否显示发送方已读标识，默认false
    public var showReadMark: Bool = false
    /// 已读标识字体
    public var readMarkFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(10, WYBasisKitConfig.defaultScreenPixels))
    /// 已读标识颜色
    public var readMarkColor: UIColor = .secondaryLabel
    /// 已读文本
    public var readText: String = WYLocalized("已读", table: WYBasisKitConfig.kitLocalizableTable)
    /// 未读文本
    public var unreadText: String = WYLocalized("未读", table: WYBasisKitConfig.kitLocalizableTable)
    /// 发送失败图标
    public var messageSendErrorImage: UIImage? = UIImage.wy_find("WYChatViewSendFailed", inBundle: WYChatSourceBundle)
    /// 等待发送的图标
    public var messagePendingImage: UIImage? = UIImage.wy_find("WYChatViewPending", inBundle: WYChatSourceBundle)
    /// 发送中动画颜色
    public var messageSendingColor: UIColor = .secondaryLabel
    /// 发送失败图标颜色
    public var messageSendErrorColor: UIColor = .systemRed
    /// 等待发送图标颜色
    public var messagePendingColor: UIColor = .secondaryLabel
    /// 发送状态尺寸
    public var messageSendingStateSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels))
    /// 发送状态与内容的间距
    public var messageSendingStateOffset: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
    /// 自定义时间显示，参数为消息，返回显示文本
    public var timeFormatter: ((_ message: WYChatMessageModel) -> String)? = nil
    public init() {}
}

/// 通用消息Cell
open class WYChatBasicCell: UITableViewCell {
    /// 当前界面配置
    public var configuration: WYChatConfig = WYChatConfig() { didSet { wy_render() } }
    /// 当前用户ID
    public var userID: String = "" { didSet { wy_render() } }
    /// 当前消息
    public var message: WYChatMessageModel = WYChatMessageModel() { didSet { if !state.isUpdating { wy_render() } } }
    /// 消息操作，参数为操作及消息ID
    public var actionHandler: ((_ action: WYChatAction, _ messageID: String) -> Void)? = nil
    /// 媒体组操作，参数为操作、消息ID和媒体下标
    public var mediaActionHandler: ((_ action: WYChatMediaAction, _ messageID: String, _ index: Int) -> Void)? = nil
    /// 媒体组展示视图
    public var mediaContentView: UIView { wy_mediaContentView }

    var wy_mediaContentView: UIView { state.emptyMediaContentView }

    /// 头像控件
    public let avatarView: UIImageView = WYChatAvatarImageView()
    /// 昵称控件
    public let nicknameView: UILabel = UILabel()
    /// 时间控件
    public let timeView: UILabel = UILabel()
    /// 气泡控件
    public let bubblesView: WYAirBubbleView = WYChatBubbleView()
    /// 消息内容容器
    public let bodyView: UIStackView = UIStackView()
    /// 卡片标题控件
    public var titleView: UILabel { state.title }
    /// 卡片摘要控件
    public var detailView: UILabel { state.detail }
    /// 卡片底部说明控件
    public var footerView: UILabel { state.footer }
    /// 媒体预览控件
    public var previewImageView: UIImageView { state.image }
    /// 卡片缩略图控件
    public var thumbnailImageView: UIImageView { state.thumbnail }
    /// 引用内容
    public let referenceView = WYChatQuoteView()
    /// 已读标识
    public let readMarkView: UILabel = UILabel()
    /// 发送失败按钮
    public let loadingView: UIButton = UIButton(type: .custom)
    /// 发送中动画
    public let activityView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    /// 语音倍速请求，参数为消息ID和倍速
    public var voicePlaybackRateHandler: ((_ messageID: String, _ rate: Float) -> Void)?
    /// 当前消息是否已选择
    public var isMessageSelected: Bool = false { didSet { wy_updateSelectionIndicator() } }
    /// 当前消息内容配置
    public var messageContentConfiguration: WYChatContentConfig {
        configuration.contentOverrides[message.content.style()] ?? wy_defaultContentConfiguration
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        wy_setupCell()
    }

    /// 更新消息内容，子类可提供自己的内容视图
    @objc open func renderContent() {
        state.title.text = configuration.unsupportedMessageText
    }

    /**
     更新消息与布局配置
     @param message 消息
     @param configuration 界面配置
     @param userID 当前用户ID
     */
    public func update(message: WYChatMessageModel, configuration: WYChatConfig, userID: String) {
        state.isUpdating = true
        self.configuration = configuration
        self.userID = userID
        self.message = message
        state.isUpdating = false
        wy_render()
    }

    func wy_updateAttachmentProgress(_ message: WYChatMessageModel) { wy_applyAttachmentProgress(message) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        wy_updateLayout()
        contentView.layoutIfNeeded()
        wy_layoutSelectionIndicator()
        wy_layoutAttachmentProgress()
    }

    public override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        wy_updateLayout(width: targetSize.width)
        return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        wy_prepareForReuse()
    }

    var wy_isNotice: Bool { false }
    var wy_hidesContent: Bool { false }
    var wy_bubbleFillColor: UIColor? { nil }
    var wy_noticeBackgroundColor: UIColor? { nil }
    var wy_noticeCornerRadius: CGFloat? { nil }

    var wy_defaultContentConfiguration: WYChatContentConfig { configuration.content }

    func wy_setupContent() {}
    func wy_resetContent() {}
    func wy_layoutContent(width: CGFloat) {}
    func wy_measureContent(_ view: UIView, width: CGFloat) -> CGSize? { nil }
    var wy_transferProgressPresentation: WYChatTransferProgressPresentation { .inline }
    func wy_updatesItemTransferProgress(visible: Bool) -> Bool { false }

    func wy_transferPreviewGeometry() -> (frame: CGRect, cornerRadius: CGFloat) {
        (previewImageView.convert(previewImageView.bounds, to: bubblesView), state.image.imageCornerRadius)
    }


    internal let state = WYChatBasicCellPrivateState()

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
