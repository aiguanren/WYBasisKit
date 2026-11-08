//
//  WYChatView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

@objc public enum WYChatTouchStyle: Int { case done, more, emoji }

/// 可配置的聊天界面
public class WYChatView: UIView {
    /// 界面配置，设置后刷新当前界面
    public var configuration: WYChatConfig { didSet { wy_applyConfiguration() } }
    /// 当前用户信息
    public var userInfo: WYChatUserModel { didSet { tableView.reloadData() } }
    /// 消息数据源
    public var dataSource: [WYChatMessageModel] = [] { didSet { wy_reloadMessages() } }
    /// 事件接管代理
    public weak var eventsHandler: WYChatViewEventsHandler? = nil
    /// 界面事件代理
    public weak var delegate: WYChatViewDelegate? = nil
    /// 消息操作，参数为聊天界面、操作和消息ID
    public var actionHandler: ((_ chatView: WYChatView, _ action: WYChatAction, _ messageID: String) -> Void)? = nil
    /// 多选操作，参数为操作和按消息顺序排列的消息ID
    public var selectionActionHandler: ((_ action: WYChatAction, _ messageIDs: [String]) -> Void)? = nil
    /// 已组装的待发送消息，参数为消息模型
    public var messagePreparedHandler: ((_ message: WYChatMessageModel) -> Void)? = nil
    /// 录音结果，参数为文件URL、时长及错误
    public var recordingHandler: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? = nil
    /// 输入栏
    public var chatInput: WYChatInputView { wy_inputView() }
    /// 消息列表
    public lazy var tableView: UITableView = wy_makeTableView()
    /// 表情面板
    public var emojiView: WYChatEmojiView? { wy_emojiView() }
    /// 更多面板
    public var moreView: WYChatMoreView? { wy_moreView() }
    /// 新消息提示按钮
    public let newMessagesButton: UIButton = UIButton(type: .system)
    /// 引用输入提示
    public let quoteButton: UIButton = UIButton(type: .system)
    /// 多选工具条
    public let selectionToolbar: UIStackView = UIStackView()
    /// 取消多选按钮
    public let selectionCancelButton: UIButton = UIButton(type: .system)
    /// 多选转发按钮
    public let selectionForwardButton: UIButton = UIButton(type: .system)
    /// 多选删除按钮
    public let selectionDeleteButton: UIButton = UIButton(type: .system)
    /// 当前引用的消息ID，nil表示没有引用
    public internal(set) var quotedMessageID: String? = nil
    /// 已选择的消息ID
    public internal(set) var selectedMessageIDs: Set<String> = []
    /// 是否开启多选
    public var isSelectingMessages: Bool = false { didSet { if !isSelectingMessages { selectedMessageIDs.removeAll() }; wy_updateSelectionUI(); tableView.reloadData() } }
    /// 当前输入面板
    public internal(set) var touchStyle: WYChatTouchStyle = .done
    /// 最近输入的表情文本
    public var recentlyEmojis: [String] = []

    /**
     创建聊天界面
     @param userInfo 当前用户
     @param configuration 界面配置
     */
    public init(userInfo: WYChatUserModel = WYChatUserModel(), configuration: WYChatConfig = WYChatConfig()) {
        self.userInfo = userInfo
        self.configuration = configuration
        super.init(frame: .zero)
        wy_setupChat()
    }

    /**
     追加消息
     @param messages 要追加的消息
     */
    public func appendMessages(_ messages: [WYChatMessageModel]) { dataSource.append(contentsOf: messages) }

    /**
     插入历史消息并保持阅读位置
     @param messages 较早的消息
     */
    public func prependMessages(_ messages: [WYChatMessageModel]) { wy_prependMessages(messages) }

    /**
     组装文本消息并按配置加入列表
     @param text 文本
     @param messageID 消息ID
     @return 消息模型
     */
    @discardableResult public func sendMessage(_ text: String, messageID: String = UUID().uuidString) -> WYChatMessageModel { wy_sendMessage(text, messageID: messageID) }

    /**
     查找消息
     @param messageID 消息ID
     @return 匹配的消息，未找到返回nil
     */
    public func messageModelFrom(_ messageID: String) -> WYChatMessageModel? { dataSource.first { $0.messageID == messageID } }

    /**
     滚动到最后一条消息
     @param animated 是否使用动画
     */
    public func scrollToLastMessage(_ animated: Bool = false) { wy_scrollToBottom(animated) }

    /// 收起所有输入面板
    @objc(wy_resignInput) public func inputViewResignFirstResponder() { wy_setPanel(.done) }

    /**
     引用消息
     @param messageID 消息ID，nil表示取消引用
     */
    public func quoteMessage(_ messageID: String?) { wy_quoteMessage(messageID) }

    /// 停止录音和识别并释放界面持有的异步任务
    public func releaseAll() { wy_releaseAll() }

    internal let state = WYChatViewPrivateState()
    internal var inputBarConfig: WYInputBarConfig { configuration.input }
    internal var emojiViewConfig: WYEmojiViewConfig { configuration.emoji }
    internal var moreViewConfig: WYMoreViewConfig { configuration.more }

    @objc func wy_keyboardWillShow(notification: Notification) { wy_handleKeyboard(notification) }
    @objc func wy_keyboardWillDismiss() { if touchStyle == .done { wy_setInputOffset(0) } }
    @objc func wy_applicationDidBecomeActive(_ application: UIApplication) { delegate?.wy_applicationDidBecomeActive?(application) }
    @objc func wy_tableBackgroundTap(_ gesture: UITapGestureRecognizer) {
        guard configuration.dismissInputOnTap, tableView.indexPathForRow(at: gesture.location(in: tableView)) == nil else { return }
        inputViewResignFirstResponder()
    }
    @objc func wy_cancelQuote() { quoteMessage(nil) }
    @objc func wy_newMessagesTap() { scrollToLastMessage(true) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { NotificationCenter.default.removeObserver(self) }
}
