//
//  WYChatView+Interactions.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 消息操作与引用
extension WYChatView {
    func wy_sendMessage(_ text: String, messageID: String) -> WYChatMessageModel {
        var model = WYChatMessageModel(messageID: messageID, timestamp: String(Date().timeIntervalSince1970), sender: userInfo, content: WYChatMessageContentModel(text: text))
        model.lastMessageTimestamp = model.sharedLastMessageTimestamp(dataSource, minimumTimeSpan: configuration.basic.messageMinimumTimeSpan)
        model.reference = quotedMessageID.flatMap { messageModelFrom($0)?.content }
        model.sendState = .sending
        model.index = dataSource.count
        if configuration.automaticallyInsertsSentMessages { dataSource.append(model); scrollToLastMessage() }
        quoteMessage(nil)
        messagePreparedHandler?(model)
        return model
    }

    func wy_quoteMessage(_ identifier: String?) {
        quotedMessageID = identifier.flatMap { messageModelFrom($0)?.messageID }
        let message = quotedMessageID.flatMap { messageModelFrom($0) }
        quoteButton.setTitle(message.map { "↪ " + $0.sender.name + ": " + $0.content.wy_summary + "  ×" }, for: .normal)
        quoteButton.isHidden = message == nil
        tableView.contentInset.bottom = message == nil ? 0 : configuration.input.inputViewHeight
    }

    func wy_menu(_ model: WYChatMessageModel) -> UIMenu {
        let actions = configuration.menuActions.filter { action in
            guard configuration.allowsAction?(action, model) ?? true else { return false }
            if action == .copy { return model.content.text != nil || !(model.content.voice?.voiceToText.isEmpty ?? true) }
            if action == .withdraw { return model.isSender(userInfo.id) }
            if action == .translate { return configuration.recording.supportSpeechRecognition && model.content.voice != nil }
            return true
        }
        return UIMenu(children: actions.map { action in
            UIAction(title: configuration.actionTitle?(action) ?? wy_actionTitle(action), attributes: action == .delete ? .destructive : []) { [weak self] _ in self?.wy_performAction(action, messageID: model.messageID) }
        })
    }

    func wy_actionTitle(_ action: WYChatAction) -> String {
        switch action {
        case .copy: return WYLocalized("复制", table: WYBasisKitConfig.kitLocalizableTable)
        case .quote: return WYLocalized("引用", table: WYBasisKitConfig.kitLocalizableTable)
        case .forward: return WYLocalized("转发", table: WYBasisKitConfig.kitLocalizableTable)
        case .delete: return WYLocalized("删除", table: WYBasisKitConfig.kitLocalizableTable)
        case .withdraw: return WYLocalized("撤回", table: WYBasisKitConfig.kitLocalizableTable)
        case .select: return WYLocalized("多选", table: WYBasisKitConfig.kitLocalizableTable)
        case .translate: return WYLocalized("转文字", table: WYBasisKitConfig.kitLocalizableTable)
        case .retry: return WYLocalized("重试", table: WYBasisKitConfig.kitLocalizableTable)
        case .play: return WYLocalized("播放", table: WYBasisKitConfig.kitLocalizableTable)
        case .pause: return WYLocalized("暂停", table: WYBasisKitConfig.kitLocalizableTable)
        default: return WYLocalized("打开", table: WYBasisKitConfig.kitLocalizableTable)
        }
    }

    func wy_performAction(_ requested: WYChatAction, messageID: String) {
        guard let model = messageModelFrom(messageID) else { return }
        let action: WYChatAction
        if requested == .content && isSelectingMessages { action = .select }
        else if requested == .content && !model.transferError.isEmpty { action = .retry }
        else if requested == .content, let voice = model.content.voice { action = configuration.recording.supportSpeechRecognition && !voice.recognitionError.isEmpty ? .translate : voice.isPlaying ? .pause : .play }
        else { action = requested }
        guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: action, messageID: messageID) ?? true else { return }
        switch action {
        case .copy: UIPasteboard.general.string = model.content.text ?? model.content.voice?.voiceToText
        case .quote: quoteMessage(messageID)
        case .select:
            if !isSelectingMessages { isSelectingMessages = true }
            if selectedMessageIDs.contains(messageID) { selectedMessageIDs.remove(messageID) } else { selectedMessageIDs.insert(messageID) }
            wy_updateSelectionUI()
            tableView.reloadData()
        case .content:
            if configuration.dismissInputOnTap { inputViewResignFirstResponder() }
        case .translate: wy_transcribeMessage(model)
        default: break
        }
        actionHandler?(self, action, messageID)
        delegate?.wy_messageAction?(self, action: action, messageID: messageID)
    }

    func wy_cancelMessageRecognition() {
        state.speech?.cancel()
        state.speech = nil
        if let identifier = state.recognizingMessageID,
           let index = dataSource.firstIndex(where: { $0.messageID == identifier }) {
            dataSource[index].content.voice?.isRecognizing = false
        }
        state.recognizingMessageID = nil
    }

    func wy_transcribeMessage(_ model: WYChatMessageModel) {
        guard configuration.recording.supportSpeechRecognition, let voice = model.content.voice else { return }
        wy_cancelMessageRecognition()
        let path = [voice.aacPath, voice.wavPath, voice.cafPath, voice.mp3Path, voice.amrPath].first { !$0.isEmpty }
        guard let path else {
            let error = NSError(domain: WYChatSpeechRecognitionErrorDomain, code: WYChatSpeechRecognitionErrorCode.fileNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: WYLocalized("录音文件不存在", table: WYBasisKitConfig.kitLocalizableTable)])
            if let index = dataSource.firstIndex(where: { $0.messageID == model.messageID }) { dataSource[index].content.voice?.recognitionError = error.localizedDescription }
            delegate?.wy_speechRecognitionFinished?(self, messageID: model.messageID, text: nil, error: error)
            return
        }
        let task = WYChatSpeechRecognitionTask(configuration: configuration.recording)
        state.speech = task
        state.recognizingMessageID = model.messageID
        if let index = dataSource.firstIndex(where: { $0.messageID == model.messageID }) {
            dataSource[index].content.voice?.recognitionError = ""
            dataSource[index].content.voice?.isRecognizing = true
        }
        task.recognize(url: URL(fileURLWithPath: path)) { [weak self, weak task] text, error in
            guard let self, let task, self.state.speech === task else { return }
            if let index = self.dataSource.firstIndex(where: { $0.messageID == model.messageID }) {
                self.dataSource[index].content.voice?.isRecognizing = false
                self.dataSource[index].content.voice?.recognitionError = error == nil ? "" : self.configuration.recording.recognitionFailureText
                if let text, error == nil { self.dataSource[index].content.voice?.voiceToText = text }
            }
            self.state.recognizingMessageID = nil
            self.state.speech = nil
            self.delegate?.wy_speechRecognitionFinished?(self, messageID: model.messageID, text: text, error: error)
        }
    }
}

/// 多选工具条与批量操作
extension WYChatView {
    func wy_setupSelectionToolbar() {
        selectionToolbar.translatesAutoresizingMaskIntoConstraints = false
        selectionToolbar.axis = .horizontal
        selectionToolbar.distribution = .fillEqually
        selectionToolbar.backgroundColor = .secondarySystemBackground
        for button in [selectionCancelButton, selectionForwardButton, selectionDeleteButton] { selectionToolbar.addArrangedSubview(button) }
        selectionCancelButton.accessibilityIdentifier = "WYChatView.selectionCancel"
        selectionForwardButton.accessibilityIdentifier = "WYChatView.selectionForward"
        selectionDeleteButton.accessibilityIdentifier = "WYChatView.selectionDelete"
        selectionCancelButton.addTarget(self, action: #selector(wy_cancelSelection), for: .touchUpInside)
        selectionForwardButton.addTarget(self, action: #selector(wy_forwardSelection), for: .touchUpInside)
        selectionDeleteButton.addTarget(self, action: #selector(wy_deleteSelection), for: .touchUpInside)
        selectionDeleteButton.tintColor = .systemRed
        addSubview(selectionToolbar)
        NSLayoutConstraint.activate([selectionToolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), selectionToolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), selectionToolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor), selectionToolbar.heightAnchor.constraint(equalToConstant: configuration.input.inputViewHeight + configuration.input.inputViewEdgeInsets.top + configuration.input.inputViewEdgeInsets.bottom)])
        wy_updateSelectionUI()
    }

    func wy_updateSelectionUI() {
        guard state.ready else { return }
        if isSelectingMessages { inputViewResignFirstResponder(); quoteMessage(nil) }
        let show = isSelectingMessages && configuration.showsSelectionToolbar
        selectionToolbar.isHidden = !show
        chatInput.isHidden = show
        selectionCancelButton.setTitle(configuration.selectionCancelText, for: .normal)
        selectionForwardButton.setTitle((configuration.actionTitle?(.forward) ?? wy_actionTitle(.forward)) + " (\(selectedMessageIDs.count))", for: .normal)
        selectionDeleteButton.setTitle(configuration.actionTitle?(.delete) ?? wy_actionTitle(.delete), for: .normal)
        selectionForwardButton.isEnabled = !selectedMessageIDs.isEmpty
        selectionDeleteButton.isEnabled = !selectedMessageIDs.isEmpty
    }

    @objc func wy_cancelSelection() { isSelectingMessages = false }
    @objc func wy_forwardSelection() { wy_selectionAction(.forward) }
    @objc func wy_deleteSelection() { wy_selectionAction(.delete) }

    func wy_selectionAction(_ action: WYChatAction) {
        let identifiers = dataSource.map { $0.messageID }.filter { selectedMessageIDs.contains($0) }
        guard !identifiers.isEmpty else { return }
        if let selectionActionHandler { selectionActionHandler(action, identifiers) }
        else { for identifier in identifiers { wy_performAction(action, messageID: identifier) } }
        isSelectingMessages = false
    }
}
