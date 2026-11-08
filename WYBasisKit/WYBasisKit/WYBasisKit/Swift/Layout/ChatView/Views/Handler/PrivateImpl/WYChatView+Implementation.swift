//
//  WYChatView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 聊天界面实例状态
final class WYChatViewPrivateState {
    var input: WYChatInputView?
    var emoji: WYChatEmojiView?
    var more: WYChatMoreView?
    var inputDependent: [NSLayoutConstraint] = []
    var inputBottom: NSLayoutConstraint?
    var ready = false
    var preservingHistory = false
    var recognizingMessageID: String?
    var speech: WYChatSpeechRecognitionTask?
}

extension WYChatView {
    func wy_setupChat() {
        state.ready = true
        _ = tableView
        for button in [newMessagesButton, quoteButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = .secondarySystemBackground
            button.layer.cornerRadius = configuration.basic.avatarCornerRadius
            addSubview(button)
            button.isHidden = true
        }
        quoteButton.accessibilityIdentifier = "WYChatView.quote"
        newMessagesButton.accessibilityIdentifier = "WYChatView.newMessages"
        newMessagesButton.setTitle(WYLocalized("新消息 ↓", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        newMessagesButton.addTarget(self, action: #selector(wy_newMessagesTap), for: .touchUpInside)
        quoteButton.addTarget(self, action: #selector(wy_cancelQuote), for: .touchUpInside)
        NSLayoutConstraint.activate([
            newMessagesButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -configuration.receiver.edgeInset),

            quoteButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            quoteButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            quoteButton.heightAnchor.constraint(equalToConstant: configuration.input.inputViewHeight)
        ])
        wy_refreshInputAnchors()
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
        let value = UITableView(frame: .zero, style: .plain)
        value.delegate = self
        value.dataSource = self
        value.separatorStyle = .none
        value.keyboardDismissMode = configuration.keyboardDismissMode
        let tap = UITapGestureRecognizer(target: self, action: #selector(wy_tableBackgroundTap(_:)))
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
        tableView.reloadData()
    }

    func wy_refreshInputAnchors() {
        NSLayoutConstraint.deactivate(state.inputDependent)
        state.inputDependent = [tableView.bottomAnchor.constraint(equalTo: chatInput.topAnchor), quoteButton.bottomAnchor.constraint(equalTo: chatInput.topAnchor), newMessagesButton.bottomAnchor.constraint(equalTo: chatInput.topAnchor, constant: -configuration.messageSpacing)]
        NSLayoutConstraint.activate(state.inputDependent)
    }

    func wy_reloadMessages() {
        guard state.ready else { return }
        let nearBottom = wy_isNearBottom
        tableView.reloadData()
        guard !state.preservingHistory else { return }
        if nearBottom { wy_scrollToBottom(false) } else { newMessagesButton.isHidden = dataSource.isEmpty }
    }

    var wy_isNearBottom: Bool { tableView.contentSize.height - tableView.contentOffset.y - tableView.bounds.height <= configuration.bottomDistance }

    func wy_scrollToBottom(_ animated: Bool) {
        guard !dataSource.isEmpty else { return }
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: IndexPath(row: dataSource.count - 1, section: 0), at: .bottom, animated: animated)
        newMessagesButton.isHidden = true
    }

    func wy_prependMessages(_ messages: [WYChatMessageModel]) {
        guard !messages.isEmpty else { return }
        tableView.layoutIfNeeded()
        let anchor = tableView.indexPathsForVisibleRows?.min()
        let distance = anchor.map { tableView.rectForRow(at: $0).minY - tableView.contentOffset.y } ?? 0
        state.preservingHistory = true
        dataSource.insert(contentsOf: messages, at: 0)
        if let anchor {
            let updated = IndexPath(row: anchor.row + messages.count, section: anchor.section)
            tableView.scrollToRow(at: updated, at: .top, animated: false)
            tableView.layoutIfNeeded()
            tableView.contentOffset.y = tableView.rectForRow(at: updated).minY - distance
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
        guard eventsHandler?.wy_canManagerKeyboardWillShowEvents?(notification) ?? true,
              chatInput.textView.isFirstResponder else { return }
        touchStyle = .done
        state.emoji?.isHidden = true
        state.more?.isHidden = true
        wy_setInputOffset(0)
        delegate?.wy_keyboardWillShow?(notification)
    }

    func wy_releaseAll() {
        wy_cancelMessageRecognition()
        if state.input?.hasCreatedRecordView == true { state.input?.recordView.endRecordVoice() }
    }
}
