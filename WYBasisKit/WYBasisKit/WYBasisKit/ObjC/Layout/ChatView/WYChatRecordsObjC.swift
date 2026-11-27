//
//  WYChatRecordsObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 合并聊天记录明细外观
@objc(WYChatRecordsConfig)
@objcMembers public class WYChatRecordsConfigObjC: NSObject {
    /// 合并记录详情是否显示输入栏
    public var showsInputBar: Bool
    /// 合并记录详情是否显示导航栏的关闭按钮
    public var showsCloseButton: Bool
    /// 合并记录详情的头像长按操作
    public var avatarLongPressAction: WYChatAvatarAction
    /// 合并记录详情的头像双击操作
    public var avatarDoubleTapAction: WYChatAvatarAction
    /// 合并记录导航标题是否缩小以适应宽度
    public var titleAdjustsFontSizeToFitWidth: Bool
    /// 合并记录详情中排除的菜单操作
    public var excludedMenuActions: [NSNumber]
    /// 合并记录摘要中发送者与消息之间的分隔文字
    public var summarySenderSeparator: String
    /// 合并记录的多条摘要之间的分隔文字
    public var summaryLineSeparator: String
    /// 是否自动展示合并记录明细，默认true
    public var automaticallyPresentsDetail: Bool
    /// 明细是否显示发送者昵称，默认true
    public var showsNicknames: Bool
    /// 明细展示方式
    public var presentationStyle: UIModalPresentationStyle
    /// 导航栏背景色
    public var navigationColor: UIColor
    /// 导航栏标题字体
    public var titleFont: UIFont
    /// 导航栏标题颜色
    public var titleColor: UIColor
    /// 关闭按钮文字
    public var closeText: String
    /// 关闭按钮字体
    public var closeFont: UIFont
    /// 关闭按钮颜色
    public var closeColor: UIColor
    public override convenience init() { self.init(WYChatRecordsConfig()) }
    @nonobjc public init(_ value: WYChatRecordsConfig) {
        self.showsInputBar = value.showsInputBar
        self.showsCloseButton = value.showsCloseButton
        self.avatarLongPressAction = value.avatarLongPressAction
        self.avatarDoubleTapAction = value.avatarDoubleTapAction
        self.titleAdjustsFontSizeToFitWidth = value.titleAdjustsFontSizeToFitWidth
        self.excludedMenuActions = value.excludedMenuActions.map { NSNumber(value: $0.rawValue) }
        self.summarySenderSeparator = value.summarySenderSeparator
        self.summaryLineSeparator = value.summaryLineSeparator
        automaticallyPresentsDetail = value.automaticallyPresentsDetail
        showsNicknames = value.showsNicknames
        presentationStyle = value.presentationStyle
        navigationColor = value.navigationColor
        titleFont = value.titleFont
        titleColor = value.titleColor
        closeText = value.closeText
        closeFont = value.closeFont
        closeColor = value.closeColor
        super.init()
    }
    @nonobjc public func toValue() -> WYChatRecordsConfig {
        var value = WYChatRecordsConfig()
        value.showsInputBar = showsInputBar
        value.showsCloseButton = showsCloseButton
        value.avatarLongPressAction = avatarLongPressAction
        value.avatarDoubleTapAction = avatarDoubleTapAction
        value.titleAdjustsFontSizeToFitWidth = titleAdjustsFontSizeToFitWidth
        value.excludedMenuActions = excludedMenuActions.compactMap { WYChatAction(rawValue: $0.intValue) }
        value.summarySenderSeparator = summarySenderSeparator
        value.summaryLineSeparator = summaryLineSeparator
        value.automaticallyPresentsDetail = automaticallyPresentsDetail
        value.showsNicknames = showsNicknames
        value.presentationStyle = presentationStyle
        value.navigationColor = navigationColor
        value.titleFont = titleFont
        value.titleColor = titleColor
        value.closeText = closeText
        value.closeFont = closeFont
        value.closeColor = closeColor
        return value
    }
}

public extension WYChatView {
    /// 接入方接管合并记录明细，参数为记录快照
    @objc(recordsPreviewHandler) var recordsPreviewHandlerObjC: ((_ records: WYChatRecordsModelObjC) -> Void)? {
        get { recordsPreviewHandler.map { handler in { records in handler(records.toValue()) } } }
        set { recordsPreviewHandler = newValue.map { handler in { records in handler(WYChatRecordsModelObjC(records)) } } }
    }
    /// 打开合并聊天记录明细，参数为合并记录消息ID
    @objc(previewRecords) var previewRecordsObjC: @convention(block) (_ messageID: String) -> WYChatView { { [self] identifier in previewRecords(identifier); return self } }
}

public extension WYChatRecordsViewController {
    /// 创建合并聊天记录明细，参数为原始记录、当前用户和界面配置
    @objc class var create: @convention(block) (_ records: WYChatRecordsModelObjC, _ userInfo: WYChatUserModelObjC?, _ configuration: WYChatConfigObjC?) -> WYChatRecordsViewController {
        { records, user, config in WYChatRecordsViewController(records: records.toValue(), userInfo: user?.toValue() ?? WYChatUserModel(), configuration: config?.toValue() ?? WYChatConfig()) }
    }
    /// 消息列表，沿用聊天界面的展示与媒体预览
    @objc(chatView) var chatViewObjC: WYChatView { chatView }
    /// 明细中的原始记录
    @objc(records) var recordsObjC: WYChatRecordsModelObjC { get { WYChatRecordsModelObjC(records) } set { records = newValue.toValue() } }
    /// 明细外观与消息配置
    @objc(configuration) var configurationObjC: WYChatConfigObjC { get { WYChatConfigObjC(configuration) } set { configuration = newValue.toValue() } }
    /// 关闭明细按钮
    @objc(closeButton) var closeButtonObjC: UIBarButtonItem { closeButton }
}
#endif
