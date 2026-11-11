//
//  WYChatNoticeConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 撤回与重新编辑配置
public struct WYChatNoticeConfig {
    /// 普通消息可请求撤回的时长，单位秒，0表示不限
    public var withdrawalTimeLimit: TimeInterval = 120
    /// 是否提供拍一拍撤回操作，默认true
    public var allowsPatWithdrawal: Bool = true
    /// 拍一拍可请求撤回的时长，单位秒，0表示不限
    public var patWithdrawalTimeLimit: TimeInterval = 120
    /// 是否显示文本消息重新编辑入口，默认true
    public var allowsReedit: Bool = true
    /// 撤回后可重新编辑的时长，单位秒，0表示不限
    public var reeditTimeLimit: TimeInterval = 300
    /// 重新编辑时是否替换当前输入，默认true，false时在当前选区插入
    public var reeditReplacesInput: Bool = true
    /// 重新编辑按钮文字
    public var reeditText: String = WYLocalized("重新编辑", table: WYBasisKitConfig.kitLocalizableTable)
    /// 重新编辑按钮字体
    public var reeditFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
    /// 重新编辑按钮颜色
    public var reeditColor: UIColor = .systemIndigo
    /// 重新编辑按钮高度
    public var reeditHeight: CGFloat = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)
    /// 重新编辑按钮与提示文字的间距
    public var reeditSpacing: CGFloat = UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels)
    /// 普通消息撤回提示，%@替换为发送者名称
    public var withdrawnText: String = WYLocalized("%@撤回了一条消息", table: WYBasisKitConfig.kitLocalizableTable)
    /// 拍一拍撤回提示，空字符串时使用withdrawnText，%@替换为发送者名称
    public var patWithdrawnText: String = ""
    public init() {}
}
