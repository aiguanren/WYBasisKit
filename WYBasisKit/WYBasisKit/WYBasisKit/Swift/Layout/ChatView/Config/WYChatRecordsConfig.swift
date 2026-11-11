//
//  WYChatRecordsConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并聊天记录明细外观
public struct WYChatRecordsConfig {
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
