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
    public var userInfo: WYChatUserModel { didSet { state.measuredHeights.removeAll(); tableView.reloadData() } }
    /// 消息数据源
    public var dataSource: [WYChatMessageModel] = [] {
        willSet { if state.ready && !state.updatingMediaPage { tableView.layoutIfNeeded(); wy_captureReadingPosition() } }
        didSet { if !state.updatingMediaPage { wy_reloadMessages(previous: oldValue) } }
    }
    /// 事件接管代理
    public weak var eventsHandler: WYChatViewEventsHandler? = nil
    /// 界面事件代理
    public weak var delegate: WYChatViewDelegate? = nil
    /// 消息操作，参数为聊天界面、操作和消息ID
    public var actionHandler: ((_ chatView: WYChatView, _ action: WYChatAction, _ messageID: String) -> Void)? = nil
    /// 多选操作，参数为操作和按消息顺序排列的消息ID
    public var selectionActionHandler: ((_ action: WYChatAction, _ messageIDs: [String]) -> Void)? = nil
    /// 转发请求，参数为转发形式及按列表顺序排列的原消息快照
    public var forwardHandler: ((_ mode: WYChatForwardMode, _ messages: [WYChatMessageModel]) -> Void)? { didSet { wy_updateSelectionUI() } }
    /// 已组装的待发送消息，参数为消息模型
    public var messagePreparedHandler: ((_ message: WYChatMessageModel) -> Void)? = nil
    /// 请求宿主打开相册，选择结果通过sendMedia交回
    public var openAlbumHandler: (() -> Void)? = nil
    /// 媒体操作，参数为操作、消息ID和媒体下标
    public var mediaActionHandler: ((_ action: WYChatMediaAction, _ messageID: String, _ index: Int) -> Void)? = nil
    /// 宿主接管媒体预览，参数为媒体列表、初始下标和来源视图
    public var mediaPreviewHandler: ((_ items: [WYChatMediaItem], _ index: Int, _ sourceView: UIView?) -> Void)? = nil

    /// 宿主接管合并记录明细，参数为记录快照
    public var recordsPreviewHandler: ((_ records: WYChatRecordsModel) -> Void)?

    /// 语音倍速变更，参数为消息ID和倍速，调用方同步更新播放器
    public var voicePlaybackRateHandler: ((_ messageID: String, _ rate: Float) -> Void)?

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
    /// 取消输入框引用的按钮
    public var quoteButton: UIButton { quotePreview.closeButton }
    /// 输入框引用预览
    public let quotePreview = WYChatQuoteView()
    /// 多选工具条
    public let selectionToolbar: UIStackView = UIStackView()
    /// 取消多选按钮
    public let selectionCancelButton: UIButton = UIButton(type: .system)
    /// 多选转发按钮
    public let selectionForwardButton: UIButton = UIButton(type: .system)
    /// 多选删除按钮
    public let selectionDeleteButton: UIButton = UIButton(type: .system)
    /// 输入框中仍然有效的用户提及
    public var inputMentions: [WYChatMention] { wy_currentInputMentions() }
    /// 当前引用的消息ID，nil表示没有引用
    public internal(set) var quotedMessageID: String? = nil
    /// 已选择的消息ID
    public internal(set) var selectedMessageIDs: Set<String> = []
    /// 是否开启多选
    public var isSelectingMessages: Bool = false { didSet { if isSelectingMessages != oldValue { state.measuredHeights.removeAll() }; if isSelectingMessages && !oldValue { inputViewResignFirstResponder(); quoteMessage(nil) }; if !isSelectingMessages { selectedMessageIDs.removeAll(); state.selectionAnchorID = nil }; wy_updateSelectionUI(); tableView.reloadData() } }
    /// 当前输入面板
    public internal(set) var touchStyle: WYChatTouchStyle = .done

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
     设置多选消息，超出数量上限或包含无效消息ID时保持原选择
     @param messageIDs 消息ID，空数组表示清空选择
     @return 是否已更新选择
     */
    @discardableResult public func selectMessages(_ messageIDs: [String]) -> Bool { wy_setSelectedMessages(messageIDs) }

    /**
     在当前选择中加入连续区间
     @param firstMessageID 区间起点消息ID
     @param lastMessageID 区间终点消息ID
     @return 是否已完整选中区间
     */
    @discardableResult public func selectMessages(from firstMessageID: String, through lastMessageID: String) -> Bool { wy_selectRange(from: firstMessageID, through: lastMessageID) }

    /**
     组装转发消息，不加入当前列表
     @param messageIDs 原消息ID，结果按当前列表顺序排列
     @param mode 逐条或合并转发
     @param title 合并记录标题，nil时使用selection.recordsTitle
     @return 待发送消息，包含无效消息ID时返回空数组
     */
    public func makeForwardMessages(_ messageIDs: [String], mode: WYChatForwardMode, title: String? = nil) -> [WYChatMessageModel] { wy_makeForwardMessages(messageIDs, mode: mode, title: title) }

    /**
     打开合并聊天记录明细
     @param messageID 合并记录消息ID
     */
    public func previewRecords(_ messageID: String) { wy_previewRecords(messageID) }

    /**
     设置语音消息的播放倍速并通知调用方
     @param rate 倍速，必须在voicePlayback.rates内
     @param messageID 语音消息ID
     @return 是否已设置有效倍速
     */
    @discardableResult public func setVoicePlaybackRate(_ rate: Float, messageID: String) -> Bool { wy_setVoicePlaybackRate(rate, messageID: messageID) }

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

    /**
     在输入框当前选区插入用户提及
     @param user 被提及的用户，id不能为空
     @return 是否已完整插入提及文本
     */
    @discardableResult public func mentionUser(_ user: WYChatUserModel) -> Bool { wy_insertMention(user) }

    /**
     查询消息是否可请求撤回
     @param messageID 消息ID
     @param date 判断时刻
     @return 是否满足本地撤回条件
     */
    public func canWithdrawMessage(_ messageID: String, at date: Date = Date()) -> Bool { messageModelFrom(messageID).map { wy_canWithdraw($0, at: date) } ?? false }

    /**
     在宿主确认撤回成功后更新消息及其引用快照
     @param messageID 消息ID
     @param date 撤回时刻
     @param allowsReedit 是否保留自己的文本供重新编辑
     @return 是否已更新消息
     */
    @discardableResult public func markMessageWithdrawn(_ messageID: String, at date: Date = Date(), allowsReedit: Bool = true) -> Bool { wy_markWithdrawn(messageID, at: date, allowsReedit: allowsReedit) }

    /**
     查询撤回文本是否可重新编辑
     @param messageID 消息ID
     @param date 判断时刻
     @return 是否可重新编辑
     */
    public func canReeditMessage(_ messageID: String, at date: Date = Date()) -> Bool { messageModelFrom(messageID).map { wy_chatCanReedit($0, userID: userInfo.id, configuration: configuration.notice, at: date) } ?? false }

    /**
     恢复撤回文本及发送时的引用
     @param messageID 消息ID
     @return 是否已恢复到输入框
     */
    @discardableResult public func reeditMessage(_ messageID: String) -> Bool { wy_reeditMessage(messageID) }

    /// 请求宿主打开相册
    public func requestAlbum() { inputViewResignFirstResponder(); openAlbumHandler?(); delegate?.wy_chatViewDidRequestAlbum?(self) }

    /**
     组装选中的图片和视频并按配置加入列表
     @param items 宿主选择的媒体
     @return 待发送消息
     */
    @discardableResult public func sendMedia(_ items: [WYChatMediaItem]) -> [WYChatMessageModel] { wy_sendMedia(items) }

    /**
     展开或收起媒体组
     @param expanded 是否展开
     @param messageID 媒体组消息ID
     */
    public func setMediaGroupExpanded(_ expanded: Bool, messageID: String) {
        let group = messageModelFrom(messageID)?.content.mediaGroup
        let index = min(max(0, group?.visibleIndex ?? 0), max(0, (group?.items.count ?? 0) - 1))
        wy_performMediaAction(expanded ? .expand : .collapse, messageID: messageID, index: index)
    }

    /**
     打开媒体组中的图片或视频
     @param messageID 消息ID
     @param index 媒体下标
     */
    public func previewMedia(messageID: String, index: Int = 0) { wy_performMediaAction(.preview, messageID: messageID, index: index) }

    /// 停止录音和识别并释放界面持有的异步任务
    public func releaseAll() { wy_releaseAll() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if tableView.bounds.width > 0, tableView.bounds.height > 0, state.tableLayoutWidth != tableView.bounds.width {
            state.tableLayoutWidth = tableView.bounds.width
            wy_prepareBottomMeasurements()
            tableView.reloadData()
        }
        wy_layoutQuoteComposer()
        if state.pendingScrollToBottom { wy_scrollToBottom(false) }
    }

    internal let state = WYChatViewPrivateState()
    internal var inputBarConfig: WYInputBarConfig { configuration.input }
    internal var emojiViewConfig: WYEmojiViewConfig { configuration.emoji }
    internal var moreViewConfig: WYMoreViewConfig { configuration.more }

    @objc func wy_keyboardWillShow(notification: Notification) { wy_handleKeyboard(notification) }
    @objc func wy_keyboardWillDismiss() { wy_handleKeyboardDismiss() }
    @objc func wy_applicationDidBecomeActive(_ notification: Notification) { wy_handleApplicationActive(notification) }
    @objc func wy_tableBackgroundTap(_ gesture: UITapGestureRecognizer) {
        guard configuration.dismissInputOnTap, tableView.indexPathForRow(at: gesture.location(in: tableView)) == nil else { return }
        inputViewResignFirstResponder()
    }
    @objc func wy_newMessagesTap() { scrollToLastMessage(true) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { NotificationCenter.default.removeObserver(self) }
}
