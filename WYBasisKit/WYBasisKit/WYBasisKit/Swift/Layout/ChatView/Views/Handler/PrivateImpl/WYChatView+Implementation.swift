//
//  WYChatView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 聊天界面实例状态
final class WYChatViewPrivateState {
    let backgroundTapDelegate = WYChatBackgroundTapDelegate()
    var mediaBrowser: WYChatMediaBrowserAdapter?
    let mediaViews = NSHashTable<WYChatMediaGroupView>.weakObjects()
    var input: WYChatInputView?
    var emoji: WYChatEmojiView?
    var more: WYChatMoreView?
    var inputDependent: [NSLayoutConstraint] = []
    var inputBottom: NSLayoutConstraint?
    var ready = false
    var preservingHistory = false
    var updatingMediaPage = false
    var keyboardIsPresented = false
    var pendingScrollToBottom = false
    var followsBottom = false
    var tableLayoutWidth: CGFloat = 0
    var readingAnchor: WYChatReadingAnchor?
    var scrollRevision = 0
    var measuredHeights: [WYChatMeasurementKey: WYChatMeasuredHeight] = [:]
    var measuringCells: [WYChatMessageStyle: WYChatBasicCell] = [:]
    var hasUniqueMessageIDs = true
    var inputMentions: [WYChatMention] = []
    var mentionText = ""
    var inputQuote: WYChatQuoteModel?
    var quoteHeight: NSLayoutConstraint?
    var reeditTimer: DispatchWorkItem?
    var reeditRequestID: UUID?
    var pendingMentionEdit: (old: String, range: NSRange, replacement: String)?
    var selectionAnchorID: String?
    var selectionHeight: NSLayoutConstraint?
    var recognizingMessageID: String?
    var speech: WYChatSpeechRecognitionTask?
}

/// 列表空白区域的点击识别
final class WYChatBackgroundTapDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let table = gestureRecognizer.view as? UITableView else { return false }
        return table.indexPathForRow(at: touch.location(in: table)) == nil
    }
}

/// 记录列表布局和主动滚动
final class WYChatMessageTableView: UITableView {
    var layoutHandler: (() -> Void)?
    var geometryHandler: (() -> Void)?
    var manualScrollHandler: (() -> Void)?
    var widthChangeHandler: (() -> Void)?
    private var isPerformingLayout = false
    private var internalScrollDepth = 0

    override var bounds: CGRect {
        willSet {
            if bounds.width > 0 && newValue.width != bounds.width { widthChangeHandler?() }
            else if !isPerformingLayout && internalScrollDepth == 0 && newValue.origin != bounds.origin { manualScrollHandler?() }
        }
    }

    override var contentOffset: CGPoint {
        willSet {
            if !isPerformingLayout && internalScrollDepth == 0 && newValue != contentOffset { manualScrollHandler?() }
        }
    }

    override func layoutSubviews() {
        guard !isPerformingLayout else { super.layoutSubviews(); return }
        isPerformingLayout = true
        super.layoutSubviews()
        layoutHandler?()
        isPerformingLayout = false
    }

    override func rectForRow(at indexPath: IndexPath) -> CGRect {
        guard !isPerformingLayout else { return super.rectForRow(at: indexPath) }
        isPerformingLayout = true
        defer { isPerformingLayout = false }
        _ = super.rectForRow(at: indexPath)
        geometryHandler?()
        return super.rectForRow(at: indexPath)
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        manualScrollHandler?()
        wy_scrollInternally(to: indexPath, at: scrollPosition, animated: animated)
    }

    func wy_setOffsetInternally(_ offset: CGPoint) {
        internalScrollDepth += 1
        contentOffset = offset
        internalScrollDepth -= 1
    }

    func wy_scrollInternally(to indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        internalScrollDepth += 1
        super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        internalScrollDepth -= 1
    }

    func wy_performInternalUpdates(_ updates: () -> Void) {
        internalScrollDepth += 1
        defer { internalScrollDepth -= 1 }
        updates()
    }
}

extension WYChatView {
    func wy_setupChat() {
        state.ready = true
        _ = tableView
        for button in [newMessagesButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = configuration.basic.avatarCornerRadius
            addSubview(button)
            button.isHidden = true
        }
        quoteButton.accessibilityIdentifier = "WYChatView.quote"
        quotePreview.translatesAutoresizingMaskIntoConstraints = false
        quotePreview.isHidden = true
        quotePreview.accessibilityIdentifier = "WYChatView.quotePreview"
        addSubview(quotePreview)
        state.quoteHeight = quotePreview.heightAnchor.constraint(equalToConstant: 0)
        state.quoteHeight?.isActive = true
        quotePreview.closeHandler = { [weak self] in self?.quoteMessage(nil) }
        quotePreview.tapHandler = { [weak self] in if let quote = self?.state.inputQuote { self?.wy_openReference(quote) } }
        newMessagesButton.accessibilityIdentifier = "WYChatView.newMessages"
        newMessagesButton.setTitle(WYLocalized("新消息 ↓", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        newMessagesButton.addTarget(self, action: #selector(wy_newMessagesTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            newMessagesButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -configuration.receiver.edgeInset)
        ])
        wy_refreshInputAnchors()
        wy_refreshQuote()
        wy_setupSelectionToolbar()
        NotificationCenter.default.addObserver(self, selector: #selector(wy_keyboardWillShow(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(wy_keyboardWillDismiss), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(wy_applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        backgroundColor = configuration.backgroundColor
    }

    func wy_inputView() -> WYChatInputView {
        if let value = state.input { return value }
        let value = WYChatInputView(config: configuration.input)
        value.emojiViewConfig = configuration.emoji
        value.recordAnimationConfig = configuration.recording
        value.delegate = self
        value.eventsHandler = self
        value.textEditingHandler = { [weak self] range, replacement in self?.wy_recordInputEdit(range: range, replacement: replacement) }
        value.recordingResultHandler = { [weak self] url, duration, error in
            guard let self else { return }
            self.recordingHandler?(url, duration, error)
            self.delegate?.wy_recordingFinished?(self, url: url, duration: duration, error: error)
        }
        value.translatesAutoresizingMaskIntoConstraints = false
        addSubview(value)
        state.input = value
        state.inputBottom = value.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([value.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), value.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), state.inputBottom!])
        return value
    }

    func wy_makeTableView() -> UITableView {
        let value = WYChatMessageTableView(frame: .zero, style: .plain)
        value.layoutHandler = { [weak self] in self?.wy_restoreReadingPosition(); self?.wy_followBottomLayout(); self?.wy_captureReadingPosition() }
        value.geometryHandler = { [weak self] in self?.wy_restoreReadingPosition(); self?.wy_followBottomLayout() }
        value.widthChangeHandler = { [weak self] in self?.wy_captureReadingPosition() }
        value.manualScrollHandler = { [weak self] in self?.wy_cancelAutomaticScroll() }
        value.delegate = self
        value.dataSource = self
        value.separatorStyle = .none
        value.keyboardDismissMode = configuration.keyboardDismissMode
        let tap = UITapGestureRecognizer(target: self, action: #selector(wy_tableBackgroundTap(_:)))
        tap.delegate = state.backgroundTapDelegate
        tap.cancelsTouchesInView = false
        value.addGestureRecognizer(tap)
        value.backgroundColor = configuration.backgroundColor
        value.rowHeight = UITableView.automaticDimension
        value.estimatedRowHeight = configuration.basic.avatarSize.height + configuration.messageSpacing
        value.contentInsetAdjustmentBehavior = .never
        value.translatesAutoresizingMaskIntoConstraints = false
        addSubview(value)
        NSLayoutConstraint.activate([value.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor), value.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), value.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)])
        let types = WYChatMessageStyle.allCases.map { $0.cellClass }
        for type in types + configuration.customCellClasses { value.register(type, forCellReuseIdentifier: String(describing: type)) }
        return value
    }

    func wy_emojiView() -> WYChatEmojiView? {
        guard configuration.input.emojiTextButtonSize != .zero else { return nil }
        if let value = state.emoji { return value }
        let value = WYChatEmojiView(config: configuration.emoji)
        value.delegate = self
        value.eventsHandler = self
        wy_installPanel(value, height: configuration.emoji.contentHeight)
        state.emoji = value
        return value
    }

    func wy_moreView() -> WYChatMoreView? {
        guard configuration.input.moreButtonSize != .zero else { return nil }
        if let value = state.more { return value }
        let value = WYChatMoreView(config: configuration.more)
        value.delegate = self
        value.eventsHandler = self
        wy_installPanel(value, height: configuration.more.contentHeight())
        state.more = value
        return value
    }

    func wy_installPanel(_ value: UIView, height: CGFloat) {
        value.translatesAutoresizingMaskIntoConstraints = false
        value.isHidden = true
        addSubview(value)
        NSLayoutConstraint.activate([value.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), value.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), value.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor), value.heightAnchor.constraint(equalToConstant: max(0, height))])
    }

    func wy_applyConfiguration() {
        guard state.ready else { return }
        state.measuredHeights.removeAll()
        let text = chatInput.textView.attributedText
        inputViewResignFirstResponder()
        wy_cancelMessageRecognition()
        if state.input?.hasCreatedRecordView == true {
            state.input?.recordView.endRecordVoice()
            state.input?.recordView.removeFromSuperview()
        }
        NSLayoutConstraint.deactivate(state.inputDependent)
        state.input?.removeFromSuperview()
        state.input = nil
        chatInput.textView.attributedText = text
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        wy_refreshInputAnchors()
        state.emoji?.removeFromSuperview()
        state.more?.removeFromSuperview()
        state.emoji = nil
        state.more = nil
        backgroundColor = configuration.backgroundColor
        tableView.backgroundColor = configuration.backgroundColor
        tableView.keyboardDismissMode = configuration.keyboardDismissMode
        for type in configuration.customCellClasses { tableView.register(type, forCellReuseIdentifier: String(describing: type)) }
        wy_updateSelectionUI()
        wy_refreshQuote()
        wy_scheduleReeditExpiration()
        tableView.reloadData()
    }

    func wy_refreshInputAnchors() {
        NSLayoutConstraint.deactivate(state.inputDependent)
        let insets = configuration.quote.inputOuterInsets
        let selection = isSelectingMessages && configuration.showsSelectionToolbar
        let bottom = selection ? selectionToolbar.topAnchor : !configuration.showsInputBar ? safeAreaLayoutGuide.bottomAnchor : state.inputQuote == nil ? chatInput.topAnchor : quotePreview.topAnchor
        state.inputDependent = [tableView.bottomAnchor.constraint(equalTo: bottom, constant: selection || !configuration.showsInputBar || state.inputQuote == nil ? 0 : -max(0, insets.top)), quotePreview.bottomAnchor.constraint(equalTo: chatInput.topAnchor, constant: -max(0, insets.bottom)), quotePreview.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: max(0, insets.left)), quotePreview.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -max(0, insets.right)), newMessagesButton.bottomAnchor.constraint(equalTo: chatInput.topAnchor, constant: -configuration.messageSpacing)]
        NSLayoutConstraint.activate(state.inputDependent)
    }

    func wy_reloadMessages(previous: [WYChatMessageModel]) {
        guard state.ready else { return }
        UIView.performWithoutAnimation {
            if let table = tableView as? WYChatMessageTableView { table.wy_performInternalUpdates { wy_reloadMessageRows(previous: previous) } }
            else { wy_reloadMessageRows(previous: previous) }
        }
    }

    private func wy_reloadMessageRows(previous: [WYChatMessageModel]) {
        state.followsBottom = false
        state.scrollRevision += 1
        wy_scheduleReeditExpiration()
        let nearBottom = wy_isNearBottom
        if var anchor = state.readingAnchor, previous.indices.contains(anchor.row),
           let row = dataSource.firstIndex(where: { $0.messageID == previous[anchor.row].messageID }) {
            anchor.row = row
            state.readingAnchor = anchor
        } else { state.readingAnchor = nil }
        let oldIDs = previous.map(\.messageID)
        let newIDs = dataSource.map(\.messageID)
        let currentIDs = Set(newIDs)
        selectedMessageIDs.formIntersection(currentIDs)
        if let anchor = state.selectionAnchorID, !currentIDs.contains(anchor) { state.selectionAnchorID = nil }
        state.hasUniqueMessageIDs = currentIDs.count == newIDs.count
        if state.preservingHistory {
            if Set(oldIDs).count != oldIDs.count || !state.hasUniqueMessageIDs { state.measuredHeights.removeAll() }
            else {
                let oldPositions = Dictionary(uniqueKeysWithValues: oldIDs.enumerated().map { ($0.element, $0.offset) })
                for model in dataSource {
                    if let old = oldPositions[model.messageID], previous[old] != model { state.measuredHeights.removeValue(forKey: .identifier(model.messageID)) }
                }
            }
            tableView.reloadData()
        } else if previous.isEmpty || dataSource.isEmpty || tableView.bounds.width <= 0 || Set(oldIDs).count != oldIDs.count || !state.hasUniqueMessageIDs || !oldIDs.contains(where: { currentIDs.contains($0) }) {
            state.measuredHeights.removeAll()
            if nearBottom && !state.preservingHistory { wy_prepareBottomMeasurements() }
            tableView.reloadData()
        } else {
            let changes = newIDs.difference(from: oldIDs)
            let oldPositions = Dictionary(uniqueKeysWithValues: oldIDs.enumerated().map { ($0.element, $0.offset) })
            let updated = dataSource.indices.filter { index in
                guard let old = oldPositions[dataSource[index].messageID] else { return false }
                return previous[old] != dataSource[index]
            }.map { IndexPath(row: $0, section: 0) }
            let replaced = updated.filter { index in
                guard let old = oldPositions[dataSource[index.row].messageID] else { return false }
                return previous[old].content.style() != dataSource[index.row].content.style()
            }
            let visible = Set(tableView.indexPathsForVisibleRows ?? [])
            let reconfigured = updated.filter { !replaced.contains($0) && (visible.contains($0) || state.measuredHeights[.identifier(dataSource[$0.row].messageID)] != nil) }
            for path in updated { state.measuredHeights.removeValue(forKey: .identifier(dataSource[path.row].messageID)) }
            for id in oldIDs where !currentIDs.contains(id) { state.measuredHeights.removeValue(forKey: .identifier(id)) }
            if nearBottom && !state.preservingHistory { wy_prepareBottomMeasurements() }
            if changes.isEmpty {
                if !replaced.isEmpty { tableView.reloadRows(at: replaced, with: .none) }
                if !reconfigured.isEmpty { tableView.reconfigureRows(at: reconfigured) }
            } else {
                let removed = changes.compactMap { change -> IndexPath? in
                    if case let .remove(index, _, _) = change { return IndexPath(row: index, section: 0) }
                    return nil
                }
                let inserted = changes.compactMap { change -> IndexPath? in
                    if case let .insert(index, _, _) = change { return IndexPath(row: index, section: 0) }
                    return nil
                }
                tableView.performBatchUpdates({
                    if !removed.isEmpty { tableView.deleteRows(at: removed, with: .none) }
                    if !inserted.isEmpty { tableView.insertRows(at: inserted, with: .none) }
                }, completion: { [weak self] _ in
                    guard let self else { return }
                    self.wy_restoreReadingPosition()
                    self.wy_followBottomLayout()
                })
                if !replaced.isEmpty { tableView.reloadRows(at: replaced, with: .none) }
                if !reconfigured.isEmpty { tableView.reconfigureRows(at: reconfigured) }
            }
        }
        wy_updateSelectionUI()
        guard !state.preservingHistory else { return }
        if nearBottom { wy_scrollToBottom(false) } else { newMessagesButton.isHidden = dataSource.isEmpty }
    }

    var wy_isNearBottom: Bool { tableView.contentSize.height - tableView.contentOffset.y - tableView.bounds.height <= configuration.bottomDistance }

    func wy_scrollToBottom(_ animated: Bool) {
        state.readingAnchor = nil
        guard !dataSource.isEmpty else { state.pendingScrollToBottom = false; return }
        guard window != nil, tableView.bounds.width > 0, tableView.bounds.height > 0 else {
            state.pendingScrollToBottom = true
            return
        }
        state.pendingScrollToBottom = false
        state.followsBottom = !animated
        state.scrollRevision += 1
        let revision = state.scrollRevision
        let last = IndexPath(row: dataSource.count - 1, section: 0)
        wy_prepareBottomMeasurements()
        tableView.layoutIfNeeded()
        (tableView as? WYChatMessageTableView)?.wy_scrollInternally(to: last, at: .bottom, animated: animated)
        if !animated {
            let settle: () -> Void = { [weak self] in
                guard let self, self.state.scrollRevision == revision, self.dataSource.indices.contains(last.row), self.window != nil else { return }
                self.layoutIfNeeded()
                self.tableView.layoutIfNeeded()
                (self.tableView as? WYChatMessageTableView)?.wy_scrollInternally(to: last, at: .bottom, animated: false)
            }
            DispatchQueue.main.async(execute: settle)

        }
        newMessagesButton.isHidden = true
    }

    func wy_prependMessages(_ messages: [WYChatMessageModel]) {
        guard !messages.isEmpty else { return }
        tableView.layoutIfNeeded()
        let anchor = tableView.indexPathsForVisibleRows?.min()
        var reading = anchor.map { wy_readingAnchor(at: $0) }
        let distance = reading?.distance ?? 0
        state.preservingHistory = true
        state.readingAnchor = reading
        dataSource.insert(contentsOf: messages, at: 0)
        if let anchor {
            let updated = IndexPath(row: anchor.row + messages.count, section: anchor.section)
            if let table = tableView as? WYChatMessageTableView { table.wy_scrollInternally(to: updated, at: .top, animated: false) }
            else { tableView.scrollToRow(at: updated, at: .top, animated: false) }
            tableView.layoutIfNeeded()
            reading?.row = updated.row
            state.readingAnchor = reading
            (tableView as? WYChatMessageTableView)?.wy_setOffsetInternally(CGPoint(x: tableView.contentOffset.x, y: tableView.rectForRow(at: updated).minY - distance))
            wy_restoreReadingPosition()
        }
        state.preservingHistory = false
    }

    func wy_setPanel(_ panel: WYChatTouchStyle, dismissKeyboard: Bool = true) {
        touchStyle = panel
        if panel != .done { chatInput.textView.resignFirstResponder() } else if dismissKeyboard { endEditing(true) }
        emojiView?.isHidden = panel != .emoji
        moreView?.isHidden = panel != .more
        let height: CGFloat = panel == .emoji ? configuration.emoji.contentHeight : panel == .more ? configuration.more.contentHeight() : 0
        wy_setInputOffset(height)
    }

    func wy_setInputOffset(_ offset: CGFloat) {
        let nearBottom = wy_isNearBottom
        state.inputBottom?.constant = -max(0, offset.isFinite ? offset : 0)
        UIView.animate(withDuration: max(0, configuration.input.animateDuration)) { self.layoutIfNeeded() }
        if nearBottom { scrollToLastMessage() }
    }

    func wy_handleKeyboard(_ notification: Notification) {
        guard chatInput.textView.isFirstResponder else { return }
        state.keyboardIsPresented = true
        guard eventsHandler?.wy_canManagerKeyboardWillShowEvents?(notification) ?? true else { return }
        touchStyle = .done
        state.emoji?.isHidden = true
        state.more?.isHidden = true
        wy_setInputOffset(0)
        delegate?.wy_keyboardWillShow?(notification)
    }

    func wy_handleKeyboardDismiss() {
        guard state.keyboardIsPresented else { return }
        state.keyboardIsPresented = false
        guard eventsHandler?.wy_canManagerKeyboardWillDismissEvents?() ?? true else { return }
        if touchStyle == .done { wy_setInputOffset(0) }
        delegate?.wy_keyboardWillDismiss?()
    }

    func wy_handleApplicationActive(_ notification: Notification) {
        let application = notification.object as? UIApplication ?? UIApplication.shared
        guard eventsHandler?.wy_canManagerApplicationDidBecomeActiveEvents?(application) ?? true else { return }
        delegate?.wy_applicationDidBecomeActive?(application)
    }

    func wy_releaseAll() {
        state.mediaBrowser?.dispose()
        state.mediaBrowser = nil
        state.mediaViews.removeAllObjects()
        state.reeditTimer?.cancel()
        state.reeditTimer = nil
        state.reeditRequestID = nil
        state.scrollRevision += 1
        state.pendingScrollToBottom = false
        state.followsBottom = false
        wy_cancelMessageRecognition()
        if state.input?.hasCreatedRecordView == true { state.input?.recordView.endRecordVoice() }
    }
}
