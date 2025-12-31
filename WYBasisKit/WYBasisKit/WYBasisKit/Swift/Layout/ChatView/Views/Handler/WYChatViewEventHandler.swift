//
//  WYChatViewEventHandler.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import Foundation
import UIKit

extension WYChatView: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let customCell: UITableViewCell = eventsHandler?.canManagerCellForRowEvents?(self, tableView, indexPath) else {
            
            let model: WYChatMessageModel = dataSource[indexPath.row]
            
            let contentCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: model.content.style().rawValue, for: indexPath)
            
            if contentCell is WYChatBasicCell {
                (contentCell as! WYChatBasicCell).userID = userInfo.id
                (contentCell as! WYChatBasicCell).message = model
            }
            return contentCell
        }
        return customCell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension WYChatView: WYChatInputViewDelegate, WYChatInputViewEventsHandler {
    
    public func didClickMoreView(_ isText: Bool) {
        
        delegate?.didClickMoreView?(isText)
        updateMoreViewConstraints(!isText)
    }
    
    public func didClickEmojiTextView(_ isText: Bool) {
        
        if isText {

        }else {
            updateEmojiFuncAreaViewState()
            if recentlyEmojis.isEmpty == false {
                emojiView?.updateRecentlyEmoji(chatInput.sharedEmojiAttributed(string: recentlyEmojis.joined()))
                recentlyEmojis.removeAll()
            }
        }
        updateEmojiViewConstraints(!isText)
        delegate?.didClickEmojiTextView?(isText)
    }
    
    public func didClickTextVoiceView(_ isText: Bool) {
        
        if isText {

        }else {
            updateEmojiViewConstraints(false)
            updateMoreViewConstraints(false)
            emojiView?.isHidden = true
            moreView?.isHidden = true
        }
        delegate?.didClickTextVoiceView?(isText)
    }
    
    public func textDidChanged(_ text: String) {
        chatInput.textView.attributedText = chatInput.sharedEmojiAttributed(string: text)
        updateEmojiFuncAreaViewState()
        scrollToLastMessage()
        delegate?.textDidChanged?(text)
    }
    
    public func didClickKeyboardEvent(_ text: String, silence: Bool) {
        
        if silence == false {
            guard (eventsHandler?.canManagerKeyboardSendEvents?(text) ?? true) else {
                return
            }
        }
        if emojiViewConfig.instantUpdatesRecently == true {
            emojiView?.updateRecentlyEmoji(chatInput.textView.attributedText)
        }else {
            recentlyEmojis.append(text)
        }
        chatInput.textView.text = ""
        updateEmojiFuncAreaViewState()
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        delegate?.keyboardSendMessage?(sendMessage(text))
    }
    
    public func didClickKeyboardEvent(_ text: String) {
        didClickKeyboardEvent(text, silence: false)
    }
    
    @discardableResult
    public func sendMessage(_ text: String) -> WYChatMessageModel  {
        
        /**
         *  消息已读人数
         *  单聊时  0未读，1已读
         *  群聊时  若已读人数等于群人数则表示全部已读，否则为群内已读人数
         */
        let readers: String = "0"
        
        /// 消息发送状态
        let sendState: WYChatMessageSendState = .sending
        
        /// 已读回执发送状态
        let readBackState: WYChatMessageSendState = .notSent
        
        /// 消息发送时间
        let timestamp: String = String.wy_sharedDeviceTimestamp()
        
        /// 消息发送者信息
        let sendor: WYChatUaerModel = userInfo ?? WYChatUaerModel()

        /// 消息内容
        let content: WYChatMeesageContentModel = WYChatMeesageContentModel()
        content.text = text
         
        /// 引用消息
        //let reference: WYChatMeesageContentModel? = nil
        
        let message: WYChatMessageModel = WYChatMessageModel()
        message.readers = readers
        message.readBackState = readBackState
        message.sendState = sendState
        message.timestamp = timestamp
        message.lastMessageTimestamp = message.sharedLastMessageTimestamp(dataSource)
        message.sendor = sendor
        message.content = content
        message.index = dataSource.count
        dataSource.append(message)
        
        return message
    }
    
    public func canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool {
        return eventsHandler?.canManagerVoiceRecordEvents?(longPress) ?? true
    }
    
    public func canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool {
        return eventsHandler?.canManagerTextVoiceViewEvents?(textVoiceView) ?? true
    }
    
    public func canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool {
        return eventsHandler?.canManagerTextEmojiViewEvents?(textEmojiView) ?? true
    }
    
    public func canManagerMoreViewEvents(_ moreView: UIButton) -> Bool {
        return eventsHandler?.canManagerMoreViewEvents?(moreView) ?? true
    }
}

extension WYChatView: WYChatEmojiViewDelegate, WYChatEmojiViewEventsHandler {
    
    public func didClick(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) {
        
        let emoji: String = emojiView.dataSource[indexPath.section][indexPath.item]
        
        let textContent = chatInput.textView.attributedText.string
        let textNum = textContent.utf16.count - (textContent.utf16.count - textContent.count) + 1
        if (textNum > inputBarConfig.inputTextLength) && (inputBarConfig.inputTextLength > 0) {
            return
        }

        // 光标位置
        let cursorPosition = chatInput.textView.offset(from: chatInput.textView.beginningOfDocument, to: chatInput.textView.selectedTextRange?.start ?? chatInput.textView.beginningOfDocument)
        
        chatInput.textView.insertText(emoji)
        // 这里 silence 传True，目的是解决delegate回调两次的问题(insertText 和 textViewDidChange 都会导致回调)
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        
        let start: UITextPosition = chatInput.textView.position(from: chatInput.textView.beginningOfDocument, offset: cursorPosition + (inputBarConfig.emojiPattern.isEmpty ? emoji.utf16.count : 1))!
        let end: UITextPosition = chatInput.textView.position(from: start, offset: 0)!

        chatInput.textView.selectedTextRange = chatInput.textView.textRange(from: start, to: end)
        
        delegate?.didClickEmojiView?(emojiView, indexPath)
    }
    
    public func emojiItemLongPress(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, imageView: UIImageView) {
        delegate?.emojiItemLongPress?(gestureRecognizer, emoji: emoji, imageView: imageView)
    }
    
    public func didClickEmojiSendView(_ sendView: UIButton) {
        let emojiText: String = NSMutableAttributedString(attributedString: chatInput.textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string
        didClickKeyboardEvent(emojiText, silence: true)
        delegate?.didClickEmojiSendView?(sendView)
    }
    
    public func didClickEmojiDeleteView(_ deleteView: UIButton) {
        chatInput.textView.deleteBackward()
        delegate?.didClickEmojiDeleteView?(deleteView)
    }
    
    public func canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) -> Bool {
        return eventsHandler?.canManagerEmojiViewClickEvents?(emojiView, indexPath) ?? true
    }
    
    public func canManagerEmojiLongPressEvents(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, imageView: UIImageView) -> Bool {
        return eventsHandler?.canManagerEmojiLongPressEvents?(gestureRecognizer, emoji: emoji, imageView: imageView) ?? true
    }
    
    public func canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool {
        return eventsHandler?.canManagerEmojiDeleteViewClickEvents?(deleteView) ?? true
    }
    
    public func canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool {
        return eventsHandler?.canManagerEmojiSendViewClickEvents?(sendView) ?? true
    }
}

extension WYChatView: WYChatMoreViewDelegate, WYMoreViewEventsHandler {
    
    public func didClickMoreViewAt(_ itemIndex: Int) {
        guard let moreView = moreView else { return }
        delegate?.didClickMoreView?(moreView, itemIndex)
    }
    
    public func canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, _ itemIndex: Int) -> Bool {
        return eventsHandler?.canManagerMoreViewClickEvents?(moreView, itemIndex) ?? true
    }
}
