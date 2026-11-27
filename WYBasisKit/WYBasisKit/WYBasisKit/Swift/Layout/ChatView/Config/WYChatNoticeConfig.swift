//
//  WYChatNoticeConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 撤回与重新编辑配置
public struct WYChatNoticeConfig {
    /// 发出红包的领取回执，{actor}替换为领取者名称
    public var fundsSentPacketReceiptText: String = "{actor}领取了你的红包"
    /// 收到红包的领取回执，{actor}替换为发出者名称
    public var fundsIncomingPacketReceiptText: String = "你领取了{actor}的红包"
    /// 发出转账的接收回执，{actor}替换为接收者名称
    public var fundsSentTransferReceiptText: String = "{actor}已接收你的转账"
    /// 收到转账的接收回执，{actor}替换为发出者名称
    public var fundsIncomingTransferReceiptText: String = "你已接收{actor}的转账"
    /// 红包回执图标，nil时隐藏
    public var fundsPacketReceiptImage: UIImage? = UIImage.wy_find("WYChatViewRedPacket", inBundle: WYChatSourceBundle)
    /// 转账回执图标，nil时隐藏
    public var fundsTransferReceiptImage: UIImage? = WYChatSourceBundle.image(named: "WYChatViewTransfer")
    /// 回执中红包或转账关键词及模板图标的颜色
    public var fundsReceiptAccentColor: UIColor? = .systemOrange
    /// 收款回执背景色，nil时只显示文字与图标
    public var fundsReceiptBackgroundColor: UIColor? = nil
    /// 红包回执图标着色，nil时保留图片原色
    public var fundsPacketReceiptTintColor: UIColor? = .systemRed
    /// 转账回执图标着色，nil时保留图片原色
    public var fundsTransferReceiptTintColor: UIColor? = .systemOrange
    /// 资金回执图标的默认边长，单位点
    public var fundsReceiptIconSide: CGFloat = 16
    /// 居中系统提示的文字对齐方式
    public var centeredTextAlignment: NSTextAlignment = .center
    /// 发出的通话记录图标是否放在尾侧
    public var outgoingCallIconOnTrailing: Bool = true
    /// 通话时长文案，{duration}替换为格式化时长
    public var callDurationText: String = "通话时长 {duration}"
    /// 未接通的通话提示
    public var unconnectedCallText: String = WYLocalized("通话未接通", table: WYBasisKitConfig.kitLocalizableTable)
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
    /// 普通消息撤回提示，%@ 替换为发送者名称，空字符串隐藏提示
    public var withdrawnText: String = WYLocalized("%@撤回了一条消息", table: WYBasisKitConfig.kitLocalizableTable)
    /// 发出的普通消息撤回文案，nil 沿用 withdrawnText，空字符串隐藏提示
    public var outgoingWithdrawnText: String? = nil
    /// 拍一拍撤回提示，空字符串沿用对应收发方的普通模板，%@ 替换为发送者名称
    public var patWithdrawnText: String = ""
    /// 拍一拍提示底色，nil时仅显示文字
    public var patBackgroundColor: UIColor? = .tertiarySystemFill
    /// 拍一拍提示圆角
    public var patCornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
    /// 自定义拍一拍文案，支持{sender}、{recipient}和{note}，nil时使用本地化文案
    public var patText: String?
    public init() {}
}

extension WYChatNoticeConfig {
}
