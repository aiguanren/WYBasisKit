//
//  WYChatViewEventHandler.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit

extension WYChatView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if wy_hidesWithdrawal(at: indexPath) { return .leastNormalMagnitude }
        return wy_cachedHeight(at: indexPath) ?? UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if wy_hidesWithdrawal(at: indexPath) { return .leastNormalMagnitude }
        return wy_cachedHeight(at: indexPath) ?? tableView.estimatedRowHeight
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? WYChatTextCell)?.wy_beginEmojiDisplay(in: self)
        guard dataSource.indices.contains(indexPath.row),
              let cell = cell as? WYChatBasicCell, cell.message.messageID == dataSource[indexPath.row].messageID else { return }
        if cell.wy_isSelectingMessages {
            let selected = selectedMessageIDs.contains(cell.message.messageID)
            if cell.isMessageSelected != selected { cell.isMessageSelected = selected }
        }
        guard configuration.customCellClasses.isEmpty else { return }
        state.measuredHeights[wy_measurementKey(at: indexPath)] = WYChatMeasuredHeight(width: tableView.bounds.width, height: cell.bounds.height)
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? WYChatTextCell)?.wy_endEmojiDisplay()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let custom = eventsHandler?.wy_canManagerCellForRowEvents?(self, tableView: tableView, indexPath: indexPath) { return custom }
        let model = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: model.content.style().cellClass), for: indexPath)
        if let cell = cell as? WYChatBasicCell {
            cell.update(message: model, configuration: configuration.messageConfiguration?(model, configuration) ?? configuration, userID: userInfo.id)
            cell.wy_isSelectingMessages = isSelectingMessages
            cell.isMessageSelected = selectedMessageIDs.contains(model.messageID)
            cell.wy_updateLayout(width: tableView.bounds.width)
            cell.actionHandler = { [weak self] action, identifier in self?.wy_performAction(action, messageID: identifier) }
            cell.voicePlaybackRateHandler = { [weak self] identifier, rate in self?.setVoicePlaybackRate(rate, messageID: identifier) }
            cell.state.progressVisibilityChanged = { [weak self] identifier in
                guard let self, let row = self.dataSource.firstIndex(where: { $0.messageID == identifier }) else { return }
                let path = IndexPath(row: row, section: 0)
                guard self.tableView.cellForRow(at: path) != nil else { return }
                self.state.measuredHeights.removeValue(forKey: .identifier(identifier))
                self.tableView.reconfigureRows(at: [path])
            }
            cell.state.mediaTransferHandler = { [weak self] action, identifier, itemID in
                self?.wy_performMediaTransferAction(action, messageID: identifier, itemID: itemID)
            }
            cell.mediaActionHandler = { [weak self] action, identifier, index in self?.wy_performMediaAction(action, messageID: identifier, index: index) }
            if let mediaCell = cell as? WYChatMediaGroupCell { state.mediaViews.add(mediaCell.mediaView) }
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard dataSource.indices.contains(indexPath.row) else { return }
        tableView.deselectRow(at: indexPath, animated: dataSource[indexPath.row].content.voice == nil)
        guard isSelectingMessages || dataSource[indexPath.row].content.mediaGroup == nil else { return }
        wy_performAction(isSelectingMessages ? .select : .content, messageID: dataSource[indexPath.row].messageID)
    }

    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = wy_messageMenuCell(at: point, in: tableView), wy_usesWholeCellMenu(cell),
              dataSource.indices.contains(indexPath.row) else { return nil }
        let model = dataSource[indexPath.row]
        let menuConfiguration = (cell as? WYChatBasicCell)?.configuration ?? configuration
        return UIContextMenuConfiguration(identifier: model.messageID as NSString, previewProvider: nil) { [weak self] _ in
            self?.wy_menu(model, configuration: menuConfiguration)
        }
    }

    public func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? { nil }

    public func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? { nil }

    public func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        wy_closeMessageMenu()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { wy_cancelAutomaticScroll() }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        state.followsBottom = wy_isNearBottom
        state.readingAnchor = nil
        wy_captureReadingPosition()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for view in state.mediaViews.allObjects { view.updateVisibleImages() }
        wy_updateRangeSelectionScroll(scrollView)
        guard eventsHandler?.wy_canManagerScrollViewDidScrollEvents?(scrollView) ?? true else { return }
        if wy_isNearBottom { newMessagesButton.isHidden = true }
        delegate?.wy_scrollViewDidScroll?(scrollView)
    }
}

extension WYChatView: WYChatInputViewDelegate, WYChatInputViewEventsHandler {
    public func wy_didClickMoreView(isText: Bool) { wy_setPanel(isText ? .done : .more, dismissKeyboard: !isText); delegate?.wy_didClickMoreView?(isText: isText) }
    public func wy_didClickEmojiTextView(isText: Bool) { wy_setPanel(isText ? .done : .emoji, dismissKeyboard: !isText); delegate?.wy_didClickEmojiTextView?(isText: isText) }
    public func wy_didClickTextVoiceView(isText: Bool) { if !isText { wy_setPanel(.done) }; delegate?.wy_didClickTextVoiceView?(isText: isText) }
    public func wy_textDidChanged(text: String) { wy_updateInputMentions(text: text); updateEmojiFuncAreaViewState(); delegate?.wy_textDidChanged?(text: text) }
    public func wy_didClickKeyboardEvent(text: String) { didClickKeyboardEvent(text, silence: false) }
    public func didClickKeyboardEvent(_ text: String, silence: Bool) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard silence || (eventsHandler?.wy_canManagerKeyboardSendEvents?(text) ?? true) else { return }
        emojiView?.updateRecentlyEmoji(chatInput.textView.attributedText)
        let message = sendMessage(text)
        chatInput.textView.text = ""
        wy_updateInputMentions(text: "")
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        updateEmojiFuncAreaViewState()
        delegate?.wy_keyboardSendMessage?(messageID: message.messageID)
    }
    public func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool { eventsHandler?.wy_canManagerVoiceRecordEvents?(longPress) ?? true }
    public func wy_canManagerTextVoiceViewEvents(_ button: UIButton) -> Bool { eventsHandler?.wy_canManagerTextVoiceViewEvents?(button) ?? true }
    public func wy_canManagerTextEmojiViewEvents(_ button: UIButton) -> Bool { eventsHandler?.wy_canManagerTextEmojiViewEvents?(button) ?? true }
    public func wy_canManagerMoreViewEvents(_ button: UIButton) -> Bool { eventsHandler?.wy_canManagerMoreViewEvents?(button) ?? true }
}

extension WYChatView: WYChatEmojiViewDelegate, WYChatEmojiViewEventsHandler {
    public func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) {
        let emoji = emojiView.dataSource[indexPath.section][indexPath.item]
        chatInput.textView.insertText(emoji)
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        delegate?.wy_didClickEmojiView?(emojiView, indexPath: indexPath)
    }
    public func wy_didClickEmojiSendView(_ button: UIButton) {
        didClickKeyboardEvent(chatInput.sharedEmojiAttributedText(attributed: chatInput.textView.attributedText).string, silence: false)
        delegate?.wy_didClickEmojiSendView?(button)
    }
    public func wy_didClickEmojiDeleteView(_ button: UIButton) { chatInput.textView.deleteBackward(); delegate?.wy_didClickEmojiDeleteView?(button) }
    public func wy_canManagerEmojiViewClickEvents(_ view: WYChatEmojiView, indexPath: IndexPath) -> Bool { eventsHandler?.wy_canManagerEmojiViewClickEvents?(view, indexPath: indexPath) ?? true }
    public func wy_canManagerEmojiDeleteViewClickEvents(_ button: UIButton) -> Bool { eventsHandler?.wy_canManagerEmojiDeleteViewClickEvents?(button) ?? true }
    public func wy_canManagerEmojiSendViewClickEvents(_ button: UIButton) -> Bool { eventsHandler?.wy_canManagerEmojiSendViewClickEvents?(button) ?? true }
    public func updateEmojiFuncAreaViewState() {
        let hasText = !(chatInput.textView.text ?? "").isEmpty
        emojiView?.funcAreaView?.sendView.isUserInteractionEnabled = hasText
        emojiView?.funcAreaView?.deleteView.isUserInteractionEnabled = hasText
        emojiView?.funcAreaView?.sendView.isSelected = !hasText
        emojiView?.funcAreaView?.deleteView.isSelected = !hasText
    }
}

extension WYChatView: WYChatMoreViewDelegate, WYMoreViewEventsHandler {
    public func wy_didClickMoreViewAtIndex(itemIndex: Int) {
        if itemIndex == configuration.media.albumMoreItemIndex && itemIndex >= 0 { requestAlbum() }
        if let moreView { delegate?.wy_didClickMoreView?(moreView, itemIndex: itemIndex) }
    }
    public func wy_canManagerMoreViewClickEvents(_ view: WYChatMoreView, itemIndex: Int) -> Bool { eventsHandler?.wy_canManagerMoreViewClickEvents?(view, itemIndex: itemIndex) ?? true }
}
