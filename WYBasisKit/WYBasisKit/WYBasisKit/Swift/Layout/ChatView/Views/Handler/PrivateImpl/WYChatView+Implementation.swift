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
    var messageMenuOverlay: UIControl?
    var mediaBrowser: WYChatMediaBrowserAdapter?
    let mediaViews = NSHashTable<WYChatMediaGroupView>.weakObjects()
    var input: WYChatInputView?
    var emoji: WYChatEmojiView?
    var more: WYChatMoreView?
    var inputDependent: [NSLayoutConstraint] = []
    var inputBottom: NSLayoutConstraint?
    var inputKeyboardLimit: NSLayoutConstraint?
    var ready = false
    var preservingHistory = false
    var updatingMediaPage = false
    var keyboardIsPresented = false
    var isLayingOutInputSurfaceSwitch = false
    var inputSurfaceAnimation: WYChatInputSurfaceAnimation?
    var pendingScrollToBottom = false
    var followsBottom = false
    var tableLayoutWidth: CGFloat = 0
    var readingAnchor: WYChatReadingAnchor?
    var scrollRevision = 0
    var measuredHeights: [WYChatMeasurementKey: WYChatMeasuredHeight] = [:]
    var measuringCells: [WYChatMessageStyle: WYChatBasicCell] = [:]
    var hasUniqueMessageIDs = true
    var playedEmojiMessages: Set<WYChatEmojiMessageKey> = []
    var inputMentions: [WYChatMention] = []
    var mentionText = ""
    var inputQuote: WYChatQuoteModel?
    var quoteHeight: NSLayoutConstraint?
    var reeditTimer: DispatchWorkItem?
    var reeditRequestID: UUID?
    var pendingMentionEdit: (old: String, range: NSRange, replacement: String)?
    var selectionAnchorID: String?
    var selectionHeight: NSLayoutConstraint?
    let selectionRangeButton = UIButton(type: .system)
    var selectionRangeEdges: (top: NSLayoutConstraint, bottom: NSLayoutConstraint, leading: NSLayoutConstraint, trailing: NSLayoutConstraint)?
    var selectionRangeAnchorRow: Int?
    var selectionRangePrefersEarlier = false
    var selectionRangeScrollOffset: CGFloat?
    var recognizingMessageID: String?
    var speech: WYChatSpeechRecognitionTask?
}

/// 键盘与应用面板交接时，每帧只写入一个输入栏位置。
final class WYChatInputSurfaceAnimation: NSObject {
    let target: CGFloat
    private var link: CADisplayLink?
    private let start = CACurrentMediaTime()
    private let duration: TimeInterval
    private let update: (CGFloat) -> Void
    private let completion: () -> Void

    init(target: CGFloat, duration: TimeInterval, update: @escaping (CGFloat) -> Void, completion: @escaping () -> Void) {
        self.target = target
        self.duration = duration
        self.update = update
        self.completion = completion
        super.init()
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        self.link = link
        link.add(to: .main, forMode: .common)
    }

    func cancel() {
        link?.invalidate()
        link = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let progress = min(1, max(0, (link.targetTimestamp - start) / duration))
        update(CGFloat(progress * progress * (3 - 2 * progress)))
        if progress == 1 {
            cancel()
            completion()
        }
    }
}

/// 列表点击与消息菜单长按的协调
final class WYChatBackgroundTapDelegate: NSObject, UIGestureRecognizerDelegate {
    var allowsMessageMenu: ((CGPoint) -> Bool)?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer is UILongPressGestureRecognizer else { return true }
        return allowsMessageMenu?(gestureRecognizer.location(in: gestureRecognizer.view)) ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer is UITapGestureRecognizer else { return true }
        var view = touch.view
        while let target = view, target !== gestureRecognizer.view {
            if target is WYChatQuoteView { return false }
            view = target.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UITapGestureRecognizer && !(otherGestureRecognizer is UILongPressGestureRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UITapGestureRecognizer
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
        NotificationCenter.default.addObserver(self, selector: #selector(wy_finishKeyboardLayout), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
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
        value.quoteLayoutHandler = { [weak self] in self?.wy_layoutQuoteComposer() }
        value.textEditingHandler = { [weak self] range, replacement in self?.wy_recordInputEdit(range: range, replacement: replacement) }
        value.recordingResultHandler = { [weak self] url, duration, error in
            guard let self else { return }
            if error == nil, let url { _ = self.sendVoiceRecording(url, duration: duration) }
            self.recordingHandler?(url, duration, error)
            self.delegate?.wy_recordingFinished?(self, url: url, duration: duration, error: error)
        }
        value.translatesAutoresizingMaskIntoConstraints = false
        addSubview(value)
        state.input = value
        state.inputBottom = value.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        state.inputBottom?.priority = .defaultHigh
        let keyboardLimit = value.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor)
        state.inputKeyboardLimit = keyboardLimit
        NSLayoutConstraint.activate([value.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), value.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), keyboardLimit, state.inputBottom!])
        return value
    }

    func wy_makeTableView() -> UITableView {
        let value = WYChatMessageTableView(frame: .zero, style: .plain)
        value.layoutHandler = { [weak self] in
            guard let self else { return }
            self.wy_restoreReadingPosition()
            self.wy_followBottomLayout()
            self.wy_captureReadingPosition()
            self.wy_updateRangeSelectionButton()
        }
        value.geometryHandler = { [weak self] in self?.wy_restoreReadingPosition(); self?.wy_followBottomLayout() }
        value.widthChangeHandler = { [weak self] in self?.wy_captureReadingPosition() }
        value.manualScrollHandler = { [weak self] in self?.wy_cancelAutomaticScroll() }
        value.delegate = self
        value.dataSource = self
        value.separatorStyle = .none
        let tap = value.wy_swipeOrTapCollapseKeyboard(target: self, action: #selector(wy_tableBackgroundTap(_:)), slideMode: configuration.keyboardDismissMode)
        tap.delegate = state.backgroundTapDelegate
        let menuPress = UILongPressGestureRecognizer(target: self, action: #selector(wy_showMessageMenu(_:)))
        state.backgroundTapDelegate.allowsMessageMenu = { [weak self] point in
            guard let self, let cell = self.wy_messageMenuCell(at: point, in: self.tableView) else { return false }
            return !self.wy_usesWholeCellMenu(cell)
        }
        menuPress.delegate = state.backgroundTapDelegate
        value.addGestureRecognizer(menuPress)
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

    func wy_scheduleEmojiPreparation() {
        guard window != nil, configuration.input.emojiTextButtonSize != .zero,
              configuration.emoji.customImageLoader == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window != nil, self.bounds.width > 0,
                  self.touchStyle != .emoji, self.configuration.emoji.customImageLoader == nil,
                  let emoji = self.emojiView else { return }
            UIView.performWithoutAnimation {
                self.layoutIfNeeded()
                emoji.wy_prepareFirstViewport()
            }
        }
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
        wy_closeMessageMenu()
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
        wy_scheduleEmojiPreparation()
    }

    func wy_refreshInputAnchors() {
        NSLayoutConstraint.deactivate(state.inputDependent)
        let quote = configuration.quote
        let insets = quote.inputOuterInsets
        let input = chatInput
        let previewParent: UIView = quote.inputBelowTextField ? input : self
        if quotePreview.superview !== previewParent { previewParent.addSubview(quotePreview) }
        let selection = isSelectingMessages && configuration.showsSelectionToolbar
        let showsQuote = !selection && configuration.showsInputBar && state.inputQuote != nil
        quotePreview.isHidden = !showsQuote
        let quoteAboveInput = showsQuote && !quote.inputBelowTextField
        let composerTop = quoteAboveInput ? quotePreview.topAnchor : input.topAnchor
        let bottom = selection ? selectionToolbar.topAnchor : !configuration.showsInputBar ? safeAreaLayoutGuide.bottomAnchor : composerTop
        let previewLeft = quote.inputAlignsWithTextField ? input.textVoiceContentView.leftAnchor : safeAreaLayoutGuide.leftAnchor
        let previewRight = quote.inputAlignsWithTextField ? input.textVoiceContentView.rightAnchor : safeAreaLayoutGuide.rightAnchor
        let quoteVertical = quote.inputBelowTextField
            ? quotePreview.topAnchor.constraint(equalTo: input.textVoiceContentView.bottomAnchor, constant: max(0, insets.top))
            : quotePreview.bottomAnchor.constraint(equalTo: input.topAnchor, constant: -max(0, insets.bottom))
        state.inputDependent = [
            tableView.bottomAnchor.constraint(equalTo: bottom, constant: quoteAboveInput ? -max(0, insets.top) : 0),
            quoteVertical,
            quotePreview.leftAnchor.constraint(equalTo: previewLeft, constant: max(0, insets.left)),
            quotePreview.rightAnchor.constraint(equalTo: previewRight, constant: -max(0, insets.right)),
            newMessagesButton.bottomAnchor.constraint(equalTo: composerTop, constant: -configuration.messageSpacing)
        ]
        NSLayoutConstraint.activate(state.inputDependent)
    }

    func wy_reloadMessages(previous: [WYChatMessageModel]) {
        wy_closeMessageMenu()
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
        let switchesFromKeyboard = panel != .done && chatInput.textView.isFirstResponder
        if switchesFromKeyboard || panel == .emoji {
            state.inputSurfaceAnimation?.cancel()
            state.inputSurfaceAnimation = nil
            // 键盘隐藏前先锁定输入栏当前的位置，避免两个布局来源先后改变列表高度。
            let frame = chatInput.layer.presentation()?.frame ?? chatInput.frame
            let offset = frame.maxY - safeAreaLayoutGuide.layoutFrame.maxY
            state.inputBottom?.constant = min(0, offset)
        }
        touchStyle = panel
        chatInput.emojiView.isSelected = panel == .emoji
        chatInput.wy_updateDictationControls()
        if panel != .done { state.inputKeyboardLimit?.isActive = false }
        if panel == .done, dismissKeyboard {
            chatInput.wy_stopInputDictation(cancel: true)
            endEditing(true)
        }
        if panel == .emoji, let emoji = emojiView {
            UIView.performWithoutAnimation {
                self.layoutIfNeeded()
                emoji.wy_refreshRecentlyEmoji()
                if emoji.isHidden {
                    emoji.wy_prepareFirstViewport()
                    let offset = self.chatInput.frame.maxY - self.safeAreaLayoutGuide.layoutFrame.maxY
                    emoji.transform = CGAffineTransform(translationX: 0, y: max(0, emoji.bounds.height + offset))
                    emoji.isHidden = false
                }
            }
        } else {
            state.emoji?.isHidden = true
        }
        if panel == .more { moreView?.isHidden = false } else { state.more?.isHidden = true }
        let height: CGFloat = panel == .emoji ? configuration.emoji.contentHeight : panel == .more ? configuration.more.contentHeight() : 0
        if switchesFromKeyboard {
            let input = chatInput
            layoutIfNeeded()
            input.textView.resignFirstResponder()
            // 键盘退场会同步触发输入框的布局回调。等回调退出后再开始表情面板动画。
            DispatchQueue.main.async { [weak self, weak input] in
                guard let self, let input, self.state.input === input, self.touchStyle == panel else { return }
                self.wy_setInputOffset(height, switchesInputSurface: true)
            }
            return
        }
        if panel != .done || dismissKeyboard {
            wy_setInputOffset(height, switchesInputSurface: panel == .emoji)
        } else if state.inputKeyboardLimit?.isActive == false {
            // 使用外接键盘时，系统可能不会发出键盘位置通知。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self, self.touchStyle == .done, !self.state.keyboardIsPresented else { return }
                self.wy_setInputOffset(0, switchesInputSurface: true)
            }
        }
        if panel != .done { chatInput.textView.resignFirstResponder() }
    }

    func wy_setInputOffset(_ offset: CGFloat, notification: Notification? = nil, switchesInputSurface: Bool = false) {
        let constant = -max(0, offset.isFinite ? offset : 0)
        if switchesInputSurface, state.inputSurfaceAnimation?.target == constant { return }
        state.inputSurfaceAnimation?.cancel()
        state.inputSurfaceAnimation = nil
        let table = tableView
        let pixel = 1 / max(1, traitCollection.displayScale)
        let bottom = max(-table.adjustedContentInset.top, table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height)
        let shouldFollow = switchesInputSurface ? abs(table.contentOffset.y - bottom) <= pixel : wy_isNearBottom
        if !table.isTracking, !table.isDecelerating, state.followsBottom || shouldFollow {
            state.followsBottom = true
            state.readingAnchor = nil
        } else {
            wy_captureReadingPosition()
        }
        if switchesInputSurface {
            wy_animateInputSurfaceSwitch(to: constant)
            return
        }
        let keyboardDuration = (notification?.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        let duration = keyboardDuration ?? configuration.input.animateDuration
        let keyboardCurve = (notification?.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let curve = UIView.AnimationOptions(rawValue: keyboardCurve << 16)
        UIView.animate(withDuration: duration.isFinite ? max(0, duration) : 0, delay: 0, options: [curve, .beginFromCurrentState, .allowUserInteraction]) {
            self.state.inputBottom?.constant = constant
            self.layoutIfNeeded()
        } completion: { [weak self] finished in
            if finished { self?.wy_finishKeyboardLayout() }
        }
    }

    private func wy_animateInputSurfaceSwitch(to target: CGFloat) {
        let start = state.inputBottom?.constant ?? 0
        let duration = configuration.input.animateDuration
        let update: (CGFloat) -> Void = { [weak self] progress in
            guard let self, let messageTable = self.tableView as? WYChatMessageTableView else { return }
            self.state.isLayingOutInputSurfaceSwitch = true
            defer { self.state.isLayingOutInputSurfaceSwitch = false }
            UIView.performWithoutAnimation {
                let offset = start + (target - start) * progress
                self.state.inputBottom?.constant = offset
                self.wy_positionEmojiPanel(inputOffset: offset)
                messageTable.wy_performInternalUpdates {
                    self.layoutIfNeeded()
                    messageTable.layoutIfNeeded()
                    self.wy_followBottomLayout()
                }
            }
        }
        let completion: () -> Void = { [weak self] in
            self?.state.inputSurfaceAnimation = nil
            self?.wy_finishKeyboardLayout()
        }
        chatInput.layer.removeAllAnimations()
        tableView.layer.removeAllAnimations()
        guard duration.isFinite, duration > 0, start != target, !UIAccessibility.isReduceMotionEnabled else {
            update(1)
            completion()
            return
        }
        update(0)
        state.inputSurfaceAnimation = WYChatInputSurfaceAnimation(target: target, duration: duration, update: update, completion: completion)
    }

    private func wy_positionEmojiPanel(inputOffset: CGFloat) {
        guard touchStyle == .emoji, let emoji = state.emoji, !emoji.isHidden else { return }
        emoji.transform = CGAffineTransform(translationX: 0, y: max(0, emoji.bounds.height + inputOffset))
    }

    @objc func wy_finishKeyboardLayout() {
        guard state.inputSurfaceAnimation == nil, touchStyle == .done, let inputBottom = state.inputBottom else { return }
        let keyboardTop = keyboardLayoutGuide.layoutFrame.minY
        let target = safeAreaLayoutGuide.layoutFrame.maxY + inputBottom.constant
        guard abs(keyboardTop - target) <= 1 / max(1, traitCollection.displayScale) else { return }
        state.inputKeyboardLimit?.isActive = true
        inputBottom.constant = 0
    }

    func wy_handleKeyboard(_ notification: Notification) {
        guard chatInput.textView.isFirstResponder,
              touchStyle == .done || (!chatInput.emojiView.isSelected && !chatInput.moreView.isSelected) else { return }
        let switchesInputSurface = state.inputKeyboardLimit?.isActive == false && (state.inputBottom?.constant ?? 0) < 0
        var overlap: CGFloat?
        if let screenFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window {
            let frame = convert(window.convert(screenFrame, from: window.screen.coordinateSpace), from: window)
            let bottom = safeAreaLayoutGuide.layoutFrame.maxY
            overlap = frame.maxY >= bottom && frame.maxX > bounds.minX && frame.minX < bounds.maxX ? max(0, bottom - frame.minY) : 0
        }
        if switchesInputSurface, overlap == 0 { return }
        state.keyboardIsPresented = true
        guard eventsHandler?.wy_canManagerKeyboardWillShowEvents?(notification) ?? true else { return }
        touchStyle = .done
        state.emoji?.isHidden = true
        state.more?.isHidden = true
        if let overlap {
            wy_setInputOffset(overlap, notification: notification, switchesInputSurface: switchesInputSurface)
        }
        delegate?.wy_keyboardWillShow?(notification)
    }

    func wy_handleKeyboardDismiss() {
        guard state.keyboardIsPresented else { return }
        state.keyboardIsPresented = false
        guard eventsHandler?.wy_canManagerKeyboardWillDismissEvents?() ?? true else { return }
        if touchStyle == .done, !chatInput.emojiView.isSelected, !chatInput.moreView.isSelected { wy_setInputOffset(0) }
        delegate?.wy_keyboardWillDismiss?()
    }

    func wy_handleApplicationActive(_ notification: Notification) {
        let application = notification.object as? UIApplication ?? UIApplication.shared
        guard eventsHandler?.wy_canManagerApplicationDidBecomeActiveEvents?(application) ?? true else { return }
        delegate?.wy_applicationDidBecomeActive?(application)
    }

    func wy_releaseAll() {
        state.inputSurfaceAnimation?.cancel()
        state.inputSurfaceAnimation = nil
        wy_closeMessageMenu()
        state.input?.wy_stopInputDictation(cancel: true)
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
