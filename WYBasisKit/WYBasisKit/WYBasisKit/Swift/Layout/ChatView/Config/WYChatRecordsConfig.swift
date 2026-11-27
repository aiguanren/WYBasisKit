//
//  WYChatRecordsConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并聊天记录明细外观
public struct WYChatRecordsConfig {
    /// 合并记录详情是否显示输入栏
    public var showsInputBar: Bool = false
    /// 合并记录详情是否显示导航栏的关闭按钮
    public var showsCloseButton: Bool = true
    /// 合并记录详情的头像长按操作
    public var avatarLongPressAction: WYChatAvatarAction = .none
    /// 合并记录详情的头像双击操作
    public var avatarDoubleTapAction: WYChatAvatarAction = .none
    /// 合并记录导航标题是否缩小以适应宽度
    public var titleAdjustsFontSizeToFitWidth: Bool = true
    /// 合并记录详情中排除的菜单操作
    public var excludedMenuActions: [WYChatAction] = [.quote, .withdraw, .reedit, .mention, .takePat]
    /// 合并记录摘要中发送者与消息之间的分隔文字
    public var summarySenderSeparator: String = ": "
    /// 合并记录的多条摘要之间的分隔文字
    public var summaryLineSeparator: String = "\n"
    /// 是否自动展示合并记录明细，默认true
    public var automaticallyPresentsDetail = true
    /// 明细是否显示发送者昵称，默认true
    public var showsNicknames = true
    /// 明细展示方式
    public var presentationStyle: UIModalPresentationStyle = .fullScreen
    /// 导航栏背景色
    public var navigationColor: UIColor = .systemBackground
    /// 导航栏标题字体
    public var titleFont = UIFont.systemFont(ofSize: UIFont.wy_fontSize(17, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
    /// 导航栏标题颜色
    public var titleColor: UIColor = .label
    /// 关闭按钮文字
    public var closeText = WYLocalized("关闭", table: WYBasisKitConfig.kitLocalizableTable)
    /// 关闭按钮字体
    public var closeFont = UIFont.systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 关闭按钮颜色
    public var closeColor: UIColor = .systemIndigo
    public init() {}
}
