//
//  WYChatConfig.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

/// 消息操作
@objc public enum WYChatAction: Int {
    case content, avatar, nickname, retry, copy, quote, forward, delete, withdraw, select, translate, play, pause, mention, takePat, reference, reedit, selectRange, playbackRate, favorite, remind, search, markRead, markUnread, paste
}

/// 头像手势操作
@objc public enum WYChatAvatarAction: Int { case none, profile, mention, takePat }

/// 收发方向的布局配置
public struct WYChatSideLayout {
    /// 是否显示头像，默认true
    public var showsAvatar: Bool = true
    /// 头像距离容器边缘的间距
    public var edgeInset: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
    /// 头像与内容的间距
    public var contentSpacing: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)
    /// 内容顶部相对头像顶部的偏移
    public var contentTopOffset: CGFloat = 0
    /// 单聊是否显示昵称，默认false
    public var showsSingleNickname: Bool = false
    /// 群聊是否显示昵称，默认true
    public var showsGroupNickname: Bool = true
    public init() {}
}

/// 气泡外观配置
public struct WYChatBubbleConfig {
    /// 气泡填充色
    public var fillColor: UIColor = .secondarySystemGroupedBackground
    /// 气泡圆角半径
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
    /// 需要圆角的位置
    public var cornersPosition: UIRectCorner = .allCorners
    /// 是否显示箭头，默认true
    public var showsArrow: Bool = true
    /// 自定义箭头图片，nil时使用气泡箭头
    public var arrowImage: UIImage? = nil
    /// 自定义箭头图片显示尺寸
    public var arrowImageSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels))
    /// 自定义箭头图片偏移
    public var arrowImageOffset: CGPoint = .zero
    /// 自定义箭头图片颜色，nil时保留图片颜色
    public var arrowImageTintColor: UIColor? = nil
    /// 箭头尺寸，宽为底边长度，高为突出长度
    public var arrowSize: CGSize = CGSize(width: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels))
    /// 箭头是否默认对齐头像中心，默认true
    public var alignsArrowWithAvatar: Bool = true
    /// 箭头相对所在边中心的偏移
    public var arrowOffset: CGFloat = 0
    /// 箭头距离圆角的间距
    public var arrowEdgePadding: CGFloat = 0
    /// 箭头尖端圆角半径
    public var arrowTipRadius: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)
    /// 边框色
    public var borderColor: UIColor = .clear
    /// 边框宽度
    public var borderWidth: CGFloat = 0
    /// 渐变颜色，空数组时使用填充色
    public var gradientColors: [UIColor] = []
    /// 渐变方向
    public var gradientDirection: WYGradientDirection = .leftToRight
    /// 阴影颜色，nil时不显示阴影
    public var shadowColor: UIColor? = nil
    /// 阴影偏移
    public var shadowOffset: CGSize = .zero
    /// 阴影模糊半径
    public var shadowRadius: CGFloat = 0
    /// 阴影不透明度
    public var shadowOpacity: CGFloat = 0.5
    public init() {}
}

/// 消息内容外观配置
public struct WYChatContentConfig {
    /// 红包或转账的图标底板颜色，nil时使用随类型和状态变化的配色
    public var fundsIconBackgroundColor: UIColor?
    /// 消息卡片图标，nil时使用对应消息类型的内置图片
    public var iconImage: UIImage? = nil
    /// 卡片图标着色，nil时使用内置类型颜色或原图颜色
    public var iconTintColor: UIColor?
    /// 是否给内置图标应用默认类型颜色
    public var usesDefaultIconTint: Bool = true
    /// 消息卡片图标的显示尺寸
    public var iconSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(28, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels))
    /// 内容内边距
    public var insets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels))
    /// 内容最大宽度占可用宽度的比例，范围0到1
    public var maximumWidthRatio: CGFloat = 0.75
    /// 内容最大宽度，0表示由比例决定
    public var maximumWidth: CGFloat = 0
    /// 卡片首选宽度
    public var preferredWidth: CGFloat = UIDevice.wy_screenWidth(240, WYBasisKitConfig.defaultScreenPixels)
    /// 媒体预览尺寸
    public var mediaSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(180, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(160, WYBasisKitConfig.defaultScreenPixels))
    /// 标题字体
    public var titleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 标题颜色
    public var titleColor: UIColor = .label
    /// 摘要字体
    public var detailFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
    /// 摘要颜色
    public var detailColor: UIColor = .secondaryLabel
    /// 内容之间的间距
    public var spacing: CGFloat = UIDevice.wy_screenHeight(6, WYBasisKitConfig.defaultScreenPixels)
    /// 标题行数，0表示不限
    public var titleNumberOfLines: Int = 2
    /// 摘要行数，0表示不限
    public var detailNumberOfLines: Int = 3
    /// 自定义图片占位图，nil时使用纯色或渐变占位
    public var placeholderImage: UIImage? = nil
    /// 默认图片占位颜色
    public var placeholderColor: UIColor = WYChatDefaultResources.placeholderColor
    /// 默认图片占位圆角半径，0表示直角
    public var placeholderCornerRadius: CGFloat = 0
    /// 默认图片占位渐变颜色，少于两个颜色时使用纯色
    public var placeholderGradientColors: [UIColor] = []
    /// 默认图片占位渐变方向
    public var placeholderGradientDirection: WYGradientDirection = .leftToRight
    /// 图片消息通过内置流程加载网络图片时，是否在默认占位上显示加载动画
    public var showsPlaceholderLoadingIndicator: Bool = true
    /// 是否显示气泡，默认true
    public var showsBubble: Bool = true
    public init() {}
}

/// 位置消息的地图预览外观
public struct WYChatLocationConfig {
    /// 地图预览未就绪时显示的大头针，nil时仅显示底色
    public var placeholderImage: UIImage? = UIImage.wy_findIfPresent("WYChatViewMapPin", inBundle: WYChatSourceBundle)
    /// 大头针最长边的点数，0表示按预览区等比显示
    public var placeholderIconSize: CGFloat = UIDevice.wy_screenWidth(36, WYBasisKitConfig.defaultScreenPixels)
    /// 地图预览的占位底色
    public var placeholderBackgroundColor: UIColor = .tertiarySystemFill
    /// 地图预览的圆角
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)
    /// 地图放在地点和地址下方，关闭时放在上方
    public var showsPreviewBelowAddress: Bool = true
    public init() {}
}

/// 聊天界面实例配置
public struct WYChatConfig {
    /// 公共布局
    public var basic: WYBasicChatConfig = WYBasicChatConfig()
    /// 发送方布局
    public var sender: WYChatSideLayout = { var value = WYChatSideLayout(); value.showsGroupNickname = false; return value }()
    /// 接收方布局
    public var receiver: WYChatSideLayout = WYChatSideLayout()
    /// 发送方气泡
    public var senderBubble: WYChatBubbleConfig = { var value = WYChatBubbleConfig(); value.fillColor = UIColor { $0.userInterfaceStyle == .dark ? .wy_hex("#33415F") : .wy_hex("#DDE3FF") }; return value }()
    /// 接收方气泡
    public var receiverBubble: WYChatBubbleConfig = WYChatBubbleConfig()
    /// 文本配置
    public var text: WYTextChatConfig = WYTextChatConfig()
    /// 通用内容配置
    public var content: WYChatContentConfig = WYChatContentConfig()
    /// 各类型内容覆盖配置，未提供时使用content
    public var contentOverrides: [WYChatMessageStyle: WYChatContentConfig] = [:]
    /// 是否显示输入栏，默认true
    public var showsInputBar = true
    /// 输入栏配置
    public var input: WYInputBarConfig = WYInputBarConfig()
    /// 表情配置
    public var emoji: WYEmojiViewConfig = WYEmojiViewConfig()
    /// 更多面板配置
    public var more: WYMoreViewConfig = WYMoreViewConfig()
    /// 图片和视频展示
    public var media: WYChatMediaConfig = WYChatMediaConfig()
    /// 位置消息展示
    public var location = WYChatLocationConfig()
    /// 引用消息与输入预览
    public var quote: WYChatQuoteConfig = WYChatQuoteConfig()
    /// 撤回与重新编辑
    public var notice: WYChatNoticeConfig = WYChatNoticeConfig()
    /// 合并聊天记录明细
    public var records = WYChatRecordsConfig()
    /// 多选操作与转发
    public var selection = WYChatSelectionConfig()
    /// 语音播放倍速
    public var voicePlayback = WYChatVoicePlaybackConfig()
    /// 录音配置
    public var recording: WYRecordAnimationConfig = WYRecordAnimationConfig()
    /// 聊天背景色
    public var backgroundColor: UIColor = .systemGroupedBackground
    /// Cell上下间距
    public var messageSpacing: CGFloat = UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels)
    /// 昵称与内容的间距
    public var nicknameSpacing: CGFloat = UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels)
    /// 点击空白是否收起输入面板，默认true
    public var dismissInputOnTap: Bool = true
    /// 拖动消息列表时的键盘收起方式
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive
    /// 是否启用长按菜单，默认true
    public var enablesMessageMenu: Bool = true
    /// 长按消息时是否使用系统整行高亮菜单，默认false，菜单在消息旁出现
    public var highlightsEntireCellOnLongPress: Bool = false
    /// 消息旁菜单与相邻头像的最小水平间距，默认适配后的16点
    public var menuPreviewAvatarSpacing: CGFloat = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)
    /// 消息旁菜单背景色
    public var menuBackgroundColor: UIColor = .wy_hex("#283341")
    /// 消息旁菜单文字颜色
    public var menuTextColor: UIColor = .wy_hex("#F3F6FA")
    /// 消息旁菜单危险操作文字颜色
    public var menuDestructiveTextColor: UIColor = .wy_hex("#FF9A8D")
    /// 消息旁菜单功能文字的字体与字号
    public var menuItemFont: UIFont = .preferredFont(forTextStyle: .subheadline)
    /// 消息旁菜单每行最多显示的功能数，默认4，空间不足时自动减少
    public var menuMaximumColumns: Int = 4
    /// 默认菜单操作，宿主通过回调执行外部操作
    public var menuActions: [WYChatAction] = [.copy, .paste, .quote, .forward, .favorite, .delete, .withdraw, .reedit, .select, .translate]
    /// 多选时是否显示内置工具条，默认true
    public var showsSelectionToolbar: Bool = true
    /// 多选取消按钮文本
    public var selectionCancelText: String = WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable)
    /// 允许自动滚动到底部的距离
    public var bottomDistance: CGFloat = UIDevice.wy_screenHeight(60, WYBasisKitConfig.defaultScreenPixels)
    /// 发送后是否自动加入消息列表，默认true
    public var automaticallyInsertsSentMessages: Bool = true
    /// 未知消息提示
    public var unsupportedMessageText: String = WYLocalized("不支持的消息类型", table: WYBasisKitConfig.kitLocalizableTable)
    /// 自定义注册的Cell
    public var customCellClasses: [AnyClass] = []
    /// 自定义图片加载，参数为资源、目标控件及消息ID
    public var imageLoader: ((_ asset: WYChatAssetsModel, _ imageView: UIImageView, _ messageID: String) -> Void)? = nil
    /// 按消息调整配置，参数为消息及当前界面配置
    public var messageConfiguration: ((_ message: WYChatMessageModel, _ configuration: WYChatConfig) -> WYChatConfig)? = nil
    /// 自定义菜单标题，参数为操作，返回nil时使用默认标题
    public var actionTitle: ((_ action: WYChatAction) -> String?)? = nil
    /// 是否显示某项菜单，参数为操作及消息
    public var allowsAction: ((_ action: WYChatAction, _ message: WYChatMessageModel) -> Bool)? = nil
    public init() {}
}
