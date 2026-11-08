//
//  WYChatViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

public extension WYChatView {
    /// 创建聊天界面，参数为当前用户及界面配置
    @objc class var create: @convention(block) (_ userInfo: WYChatUserModelObjC?, _ configuration: WYChatConfigObjC?) -> WYChatView {
        { user, config in WYChatView(userInfo: user?.toValue() ?? WYChatUserModel(), configuration: config?.toValue() ?? WYChatConfig()) }
    }
    /// 界面配置，设置后刷新当前界面
    @objc(configuration) var configurationObjC: WYChatConfigObjC {
        get { WYChatConfigObjC(configuration) }
        set { configuration = newValue.toValue() }
    }
    /// 当前用户信息
    @objc(userInfo) var userInfoObjC: WYChatUserModelObjC {
        get { WYChatUserModelObjC(userInfo) }
        set { userInfo = newValue.toValue() }
    }
    /// 消息数据源
    @objc(dataSource) var dataSourceObjC: [WYChatMessageModelObjC] {
        get { dataSource.map(WYChatMessageModelObjC.init) }
        set { dataSource = newValue.map { $0.toValue() } }
    }
    /// 界面事件代理
    @objc(delegate) var delegateObjC: WYChatViewDelegate? { get { delegate } set { delegate = newValue } }
    /// 事件接管代理
    @objc(eventsHandler) var eventsHandlerObjC: WYChatViewEventsHandler? { get { eventsHandler } set { eventsHandler = newValue } }
    /// 消息操作，参数为聊天界面、操作和消息ID
    @objc(actionHandler) var actionHandlerObjC: ((_ chatView: WYChatView, _ action: WYChatAction, _ messageID: String) -> Void)? { get { actionHandler } set { actionHandler = newValue } }
    /// 多选操作，参数为操作和按消息顺序排列的消息ID
    @objc(selectionActionHandler) var selectionActionHandlerObjC: ((_ action: WYChatAction, _ messageIDs: [String]) -> Void)? { get { selectionActionHandler } set { selectionActionHandler = newValue } }
    /// 多选工具条
    @objc(selectionToolbar) var selectionToolbarObjC: UIStackView { selectionToolbar }
    /// 取消多选按钮
    @objc(selectionCancelButton) var selectionCancelButtonObjC: UIButton { selectionCancelButton }
    /// 多选转发按钮
    @objc(selectionForwardButton) var selectionForwardButtonObjC: UIButton { selectionForwardButton }
    /// 多选删除按钮
    @objc(selectionDeleteButton) var selectionDeleteButtonObjC: UIButton { selectionDeleteButton }
    /// 已组装的待发送消息，参数为消息模型
    @objc(messagePreparedHandler) var messagePreparedHandlerObjC: ((_ message: WYChatMessageModelObjC) -> Void)? {
        get { messagePreparedHandler.map { handler in { message in handler(message.toValue()) } } }
        set { messagePreparedHandler = newValue.map { handler in { message in handler(WYChatMessageModelObjC(message)) } } }
    }
    /// 录音结果，参数为文件URL、时长及错误
    @objc(recordingHandler) var recordingHandlerObjC: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? { get { recordingHandler } set { recordingHandler = newValue } }
    /// 当前引用的消息ID，nil表示没有引用
    @objc(quotedMessageID) var quotedMessageIDObjC: String? { quotedMessageID }
    /// 新消息提示按钮
    @objc(newMessagesButton) var newMessagesButtonObjC: UIButton { newMessagesButton }
    /// 引用输入提示
    @objc(quoteButton) var quoteButtonObjC: UIButton { quoteButton }
    /// 输入栏
    @objc(chatInput) var chatInputObjC: WYChatInputView { chatInput }
    /// 消息列表
    @objc(tableView) var tableViewObjC: UITableView { tableView }
    /// 表情面板
    @objc(emojiView) var emojiViewObjC: WYChatEmojiView? { emojiView }
    /// 更多面板
    @objc(moreView) var moreViewObjC: WYChatMoreView? { moreView }
    /// 是否开启多选
    @objc(isSelectingMessages) var isSelectingMessagesObjC: Bool { get { isSelectingMessages } set { isSelectingMessages = newValue } }
    /// 已选择的消息ID
    @objc(selectedMessageIDs) var selectedMessageIDsObjC: [String] { selectedMessageIDs.sorted() }
    /// 当前输入面板
    @objc(touchStyle) var touchStyleObjC: WYChatTouchStyle { touchStyle }
    /// 最近输入的表情文本
    @objc(recentlyEmojis) var recentlyEmojisObjC: [String] { get { recentlyEmojis } set { recentlyEmojis = newValue } }
    /// 追加消息，参数为消息数组
    @objc(appendMessages) var appendMessagesObjC: @convention(block) (_ messages: [WYChatMessageModelObjC]) -> WYChatView {
        { [self] messages in self.appendMessages(messages.map { $0.toValue() }); return self }
    }
    /// 插入历史消息并保持阅读位置，参数为较早的消息
    @objc(prependMessages) var prependMessagesObjC: @convention(block) (_ messages: [WYChatMessageModelObjC]) -> WYChatView {
        { [self] messages in self.prependMessages(messages.map { $0.toValue() }); return self }
    }
    /// 组装文本消息并按配置加入列表，参数为文本及消息ID
    @objc(sendMessage) var sendMessageObjC: @convention(block) (_ text: String, _ messageID: String) -> WYChatMessageModelObjC {
        { [self] text, identifier in WYChatMessageModelObjC(self.sendMessage(text, messageID: identifier)) }
    }
    /// 查找消息，参数为消息ID
    @objc(messageModelFrom) var messageModelFromObjC: @convention(block) (_ messageID: String) -> WYChatMessageModelObjC? {
        { [self] identifier in self.messageModelFrom(identifier).map(WYChatMessageModelObjC.init) }
    }
    /// 滚动到最后一条消息，参数为是否使用动画
    @objc(scrollToLastMessage) var scrollToLastMessageObjC: @convention(block) (_ animated: Bool) -> WYChatView {
        { [self] animated in self.scrollToLastMessage(animated); return self }
    }
    /// 引用消息，参数为消息ID，nil表示取消引用
    @objc(quoteMessage) var quoteMessageObjC: @convention(block) (_ messageID: String?) -> WYChatView {
        { [self] identifier in self.quoteMessage(identifier); return self }
    }
    /// 收起所有输入面板
    @objc(inputViewResignFirstResponder) var inputViewResignFirstResponderObjC: @convention(block) () -> WYChatView {
        { [self] in self.inputViewResignFirstResponder(); return self }
    }
    /// 停止录音和识别并释放界面持有的异步任务
    @objc(releaseAll) var releaseAllObjC: @convention(block) () -> WYChatView {
        { [self] in self.releaseAll(); return self }
    }
}

#endif
