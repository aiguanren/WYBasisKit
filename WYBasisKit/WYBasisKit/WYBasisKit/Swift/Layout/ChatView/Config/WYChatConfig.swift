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
    case content, avatar, nickname, retry, copy, quote, forward, delete, withdraw, select, translate, play, pause
}

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
    /// 箭头尺寸，宽为底边长度，高为突出长度
    public var arrowSize: CGSize = CGSize(width: UIDevice.wy_screenHeight(10, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels))
    /// 箭头是否默认对齐头像中心，默认true
    public var alignsArrowWithAvatar: Bool = true
    /// 箭头相对所在边中心的偏移
    public var arrowOffset: CGFloat = 0
    /// 箭头距离圆角的间距
    public var arrowEdgePadding: CGFloat = 0
    /// 箭头尖端圆角半径
    public var arrowTipRadius: CGFloat = 0
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
    /// 图片占位图
    public var placeholderImage: UIImage? = UIImage(systemName: "photo")
    /// 是否显示气泡，默认true
    public var showsBubble: Bool = true
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
    public var senderBubble: WYChatBubbleConfig = { var value = WYChatBubbleConfig(); value.fillColor = .wy_rgb(149, 236, 105); return value }()
    /// 接收方气泡
    public var receiverBubble: WYChatBubbleConfig = WYChatBubbleConfig()
    /// 文本配置
    public var text: WYTextChatConfig = WYTextChatConfig()
    /// 通用内容配置
    public var content: WYChatContentConfig = WYChatContentConfig()
    /// 各类型内容覆盖配置，未提供时使用content
    public var contentOverrides: [WYChatMessageStyle: WYChatContentConfig] = [:]
    /// 输入栏配置
    public var input: WYInputBarConfig = WYInputBarConfig()
    /// 表情配置
    public var emoji: WYEmojiViewConfig = WYEmojiViewConfig()
    /// 更多面板配置
    public var more: WYMoreViewConfig = WYMoreViewConfig()
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
    /// 默认菜单操作，宿主通过回调执行外部操作
    public var menuActions: [WYChatAction] = [.copy, .quote, .forward, .delete, .select, .translate]
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
