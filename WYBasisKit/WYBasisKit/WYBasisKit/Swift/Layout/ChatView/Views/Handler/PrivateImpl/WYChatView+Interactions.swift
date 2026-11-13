//
//  WYChatView+Interactions.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 消息操作与引用
extension WYChatView {
    func wy_sendRecordedVoice(_ url: URL, duration: TimeInterval, messageID: String) -> WYChatMessageModel? {
        var directory: ObjCBool = false
        guard url.isFileURL, FileManager.default.fileExists(atPath: url.path, isDirectory: &directory), !directory.boolValue, duration.isFinite, duration > 0 else { return nil }
        var voice = WYChatVoiceModel(id: messageID, duration: duration)
        voice.localPath = url.path
        switch url.pathExtension.lowercased() {
        case "wav": voice.wavPath = url.path
        case "mp3": voice.mp3Path = url.path
        case "amr": voice.amrPath = url.path
        case "caf": voice.cafPath = url.path
        case "aac", "m4a": voice.aacPath = url.path
        default: break
        }
        var model = WYChatMessageModel(messageID: messageID, timestamp: String(Date().timeIntervalSince1970), sender: userInfo, content: WYChatMessageContentModel(voice: voice))
        model.lastMessageTimestamp = model.sharedLastMessageTimestamp(dataSource, minimumTimeSpan: configuration.basic.messageMinimumTimeSpan)
        model.reference = state.inputQuote
        model.sendState = .sending
        model.index = dataSource.count
        if configuration.automaticallyInsertsSentMessages { dataSource.append(model); scrollToLastMessage() }
        quoteMessage(nil)
        messagePreparedHandler?(model)
        return model
    }

    func wy_sendMessage(_ text: String, messageID: String) -> WYChatMessageModel {
        var model = WYChatMessageModel(messageID: messageID, timestamp: String(Date().timeIntervalSince1970), sender: userInfo, content: WYChatMessageContentModel(text: text))
        if !state.inputMentions.isEmpty && text == chatInput.sharedEmojiAttributedText(attributed: chatInput.textView.attributedText).string { model.mentions = inputMentions }
        model.lastMessageTimestamp = model.sharedLastMessageTimestamp(dataSource, minimumTimeSpan: configuration.basic.messageMinimumTimeSpan)
        model.reference = state.inputQuote
        model.sendState = .sending
        model.index = dataSource.count
        if configuration.automaticallyInsertsSentMessages { dataSource.append(model); scrollToLastMessage() }
        quoteMessage(nil)
        messagePreparedHandler?(model)
        return model
    }

    func wy_quoteMessage(_ identifier: String?) {
        state.inputQuote = identifier.flatMap { messageModelFrom($0) }.map { WYChatQuoteModel(messageID: $0.messageID, sender: $0.sender, content: $0.content) }
        wy_refreshQuote()
    }

    func wy_menu(_ model: WYChatMessageModel) -> UIMenu {
        if isSelectingMessages {
            guard configuration.selection.allowsRangeSelection, !selectedMessageIDs.isEmpty, configuration.allowsAction?(.selectRange, model) ?? true else { return UIMenu(children: []) }
            return UIMenu(children: [UIAction(title: configuration.selection.rangeTitle) { [weak self] _ in self?.wy_performAction(.selectRange, messageID: model.messageID) }])
        }
        let actions = configuration.menuActions.filter { action in
            guard configuration.allowsAction?(action, model) ?? true else { return false }
            if action == .forward, forwardHandler != nil, configuration.selection.forwardModes.isEmpty { return false }
            if action == .reference { return model.reference != nil }
            if action == .reedit { return canReeditMessage(model.messageID) }
            if model.content.withdrawn != nil { return action == .delete || action == .select }
            if action == .copy { return model.content.text != nil || !(model.content.voice?.voiceToText.isEmpty ?? true) }
            if action == .withdraw { return wy_canWithdraw(model, at: Date()) }
            if action == .translate { return configuration.recording.supportSpeechRecognition && model.content.voice != nil }
            return true
        }
        return UIMenu(children: actions.map { action -> UIMenuElement in
            if action == .forward, forwardHandler != nil { return UIMenu(title: configuration.actionTitle?(.forward) ?? wy_actionTitle(.forward), children: wy_forwardMenu([model.messageID]).children) }
            return UIAction(title: configuration.actionTitle?(action) ?? wy_actionTitle(action), attributes: action == .delete ? .destructive : []) { [weak self] _ in self?.wy_performAction(action, messageID: model.messageID) }
        })
    }

    func wy_actionTitle(_ action: WYChatAction) -> String {
        switch action {
        case .favorite: return WYLocalized("收藏", table: WYBasisKitConfig.kitLocalizableTable)
        case .remind: return WYLocalized("提醒", table: WYBasisKitConfig.kitLocalizableTable)
        case .search: return WYLocalized("搜索", table: WYBasisKitConfig.kitLocalizableTable)
        case .markRead: return WYLocalized("标记已读", table: WYBasisKitConfig.kitLocalizableTable)
        case .markUnread: return WYLocalized("标记未读", table: WYBasisKitConfig.kitLocalizableTable)
        case .copy: return WYLocalized("复制", table: WYBasisKitConfig.kitLocalizableTable)
        case .selectRange: return configuration.selection.rangeTitle
        case .reference: return WYLocalized("引用", table: WYBasisKitConfig.kitLocalizableTable)
        case .reedit: return configuration.notice.reeditText
        case .quote: return WYLocalized("引用", table: WYBasisKitConfig.kitLocalizableTable)
        case .forward: return WYLocalized("转发", table: WYBasisKitConfig.kitLocalizableTable)
        case .delete: return WYLocalized("删除", table: WYBasisKitConfig.kitLocalizableTable)
        case .withdraw: return WYLocalized("撤回", table: WYBasisKitConfig.kitLocalizableTable)
        case .select: return WYLocalized("多选", table: WYBasisKitConfig.kitLocalizableTable)
        case .translate: return WYLocalized("转文字", table: WYBasisKitConfig.kitLocalizableTable)
        case .retry: return WYLocalized("重试", table: WYBasisKitConfig.kitLocalizableTable)
        case .play: return WYLocalized("播放", table: WYBasisKitConfig.kitLocalizableTable)
        case .pause: return WYLocalized("暂停", table: WYBasisKitConfig.kitLocalizableTable)
        case .mention: return configuration.basic.mentionPrefix
        case .takePat: return WYLocalized("拍一拍", table: WYBasisKitConfig.kitLocalizableTable)
        default: return WYLocalized("打开", table: WYBasisKitConfig.kitLocalizableTable)
        }
    }

    func wy_performAction(_ requested: WYChatAction, messageID: String) {
        guard let model = messageModelFrom(messageID) else { return }
        if requested == .reference, !isSelectingMessages, let reference = model.reference { wy_openReference(reference); return }
        let action: WYChatAction
        if isSelectingMessages && [.content, .avatar, .nickname, .mention, .takePat, .reference].contains(requested) { action = .select }
        else if requested == .content && !model.transferError.isEmpty { action = .retry }
        else if requested == .content, let voice = model.content.voice { action = configuration.recording.supportSpeechRecognition && !voice.recognitionError.isEmpty ? .translate : voice.isPlaying ? .pause : .play }
        else { action = requested }
        guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: action, messageID: messageID) ?? true else { return }
        switch action {
        case .mention: if configuration.basic.automaticallyInsertsMentions { mentionUser(model.sender) }
        case .reedit: _ = reeditMessage(messageID)
        case .copy: UIPasteboard.general.string = model.content.text ?? model.content.voice?.voiceToText
        case .quote: quoteMessage(messageID)
        case .select:
            var selected = selectedMessageIDs
            if selected.contains(messageID) { selected.remove(messageID) } else { selected.insert(messageID) }
            guard wy_setSelectedMessages(dataSource.map(\.messageID).filter { selected.contains($0) }) else { return }
            state.selectionAnchorID = messageID
        case .selectRange:
            guard configuration.allowsAction?(.selectRange, model) ?? true,
                  let first = state.selectionAnchorID ?? dataSource.first(where: { selectedMessageIDs.contains($0.messageID) })?.messageID,
                  wy_selectRange(from: first, through: messageID) else { return }
        case .content:
            if configuration.dismissInputOnTap { inputViewResignFirstResponder() }
            if model.content.chatRecords != nil { wy_previewRecords(messageID) }
            if !wy_mediaItems(model).isEmpty { wy_performMediaAction(.preview, messageID: messageID, index: model.content.mediaGroup?.visibleIndex ?? 0) }
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
        let path = [voice.localPath, voice.aacPath, voice.wavPath, voice.cafPath, voice.mp3Path, voice.amrPath].first { !$0.isEmpty }
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
        state.selectionHeight = selectionToolbar.heightAnchor.constraint(equalToConstant: configuration.selection.height)
        NSLayoutConstraint.activate([selectionToolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor), selectionToolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor), selectionToolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor), state.selectionHeight!])
        wy_updateSelectionUI()
    }

    func wy_updateSelectionUI() {
        guard state.ready else { return }
        let show = isSelectingMessages && configuration.showsSelectionToolbar
        wy_refreshSelectionStyle()
        selectionToolbar.isHidden = !show
        chatInput.isHidden = show || !configuration.showsInputBar
        selectionCancelButton.setTitle(configuration.selectionCancelText, for: .normal)
        selectionForwardButton.setTitle((configuration.actionTitle?(.forward) ?? wy_actionTitle(.forward)) + " (\(selectedMessageIDs.count))", for: .normal)
        selectionDeleteButton.setTitle(configuration.actionTitle?(.delete) ?? wy_actionTitle(.delete), for: .normal)
        selectionForwardButton.isEnabled = !selectedMessageIDs.isEmpty && (forwardHandler == nil || !configuration.selection.forwardModes.isEmpty)
        selectionDeleteButton.isEnabled = !selectedMessageIDs.isEmpty
        wy_refreshInputAnchors()
    }

    @objc func wy_cancelSelection() { isSelectingMessages = false }
    @objc func wy_forwardSelection() { if forwardHandler == nil { wy_selectionAction(.forward) } }
    @objc func wy_deleteSelection() { wy_selectionAction(.delete) }

    func wy_selectionAction(_ action: WYChatAction) {
        let identifiers = dataSource.map { $0.messageID }.filter { selectedMessageIDs.contains($0) }
        guard !identifiers.isEmpty else { return }
        if let selectionActionHandler { selectionActionHandler(action, identifiers) }
        else { for identifier in identifiers { wy_performAction(action, messageID: identifier) } }
        isSelectingMessages = false
    }
}
