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

        guard let customCell: UITableViewCell = eventsHandler?.wy_canManagerCellForRowEvents?(self, tableView: tableView, indexPath: indexPath) else {
            
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
    
    public func wy_didClickMoreView(isText: Bool) {
        
        delegate?.wy_didClickMoreView?(isText: isText)
        updateMoreViewConstraints(!isText)
    }
    
    public func wy_didClickEmojiTextView(isText: Bool) {
        
        if isText {

        }else {
            updateEmojiFuncAreaViewState()
            if recentlyEmojis.isEmpty == false {
                emojiView?.updateRecentlyEmoji(chatInput.sharedEmojiAttributed(string: recentlyEmojis.joined()))
                recentlyEmojis.removeAll()
            }
        }
        updateEmojiViewConstraints(!isText)
        delegate?.wy_didClickEmojiTextView?(isText: isText)
    }
    
    public func wy_didClickTextVoiceView(isText: Bool) {
        
        if isText {

        }else {
            updateEmojiViewConstraints(false)
            updateMoreViewConstraints(false)
            emojiView?.isHidden = true
            moreView?.isHidden = true
        }
        delegate?.wy_didClickTextVoiceView?(isText: isText)
    }
    
    public func wy_textDidChanged(text: String) {
        chatInput.textView.attributedText = chatInput.sharedEmojiAttributed(string: text)
        updateEmojiFuncAreaViewState()
        scrollToLastMessage()
        delegate?.wy_textDidChanged?(text: text)
    }
    
    public func didClickKeyboardEvent(_ text: String, silence: Bool) {
        
        if silence == false {
            guard (eventsHandler?.wy_canManagerKeyboardSendEvents?(text) ?? true) else {
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
        delegate?.wy_keyboardSendMessage?(messageID: sendMessage(text).messageID)
    }
    
    public func wy_didClickKeyboardEvent(text: String) {
        didClickKeyboardEvent(text, silence: false)
    }
    
    /**
     *  发送一条文本消息(发送后会加入dataSource)
     *  @param text 消息文本内容
     *  @param messageID 消息ID(外部指定了就用指定的，不指定就默认生成一个唯一ID)
     *  @return 组装好的消息model
     */
    @discardableResult
    public func sendMessage(_ text: String, messageID: String = UUID().uuidString) -> WYChatMessageModel  {
        
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
        let sender: WYChatUserModel = userInfo ?? WYChatUserModel()

        /// 消息内容
        var content: WYChatMessageContentModel = WYChatMessageContentModel()
        content.text = text
         
        /// 引用消息
        //let reference: WYChatMessageContentModel? = nil
        
        var message: WYChatMessageModel = WYChatMessageModel()
        message.messageID = messageID
        message.readers = readers
        message.readBackState = readBackState
        message.sendState = sendState
        message.timestamp = timestamp
        message.lastMessageTimestamp = message.sharedLastMessageTimestamp(dataSource)
        message.sender = sender
        message.content = content
        message.index = dataSource.count
        dataSource.append(message)
        
        return message
    }
    
    public func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool {
        return eventsHandler?.wy_canManagerVoiceRecordEvents?(longPress) ?? true
    }
    
    public func wy_canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool {
        return eventsHandler?.wy_canManagerTextVoiceViewEvents?(textVoiceView) ?? true
    }
    
    public func wy_canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool {
        return eventsHandler?.wy_canManagerTextEmojiViewEvents?(textEmojiView) ?? true
    }
    
    public func wy_canManagerMoreViewEvents(_ moreView: UIButton) -> Bool {
        return eventsHandler?.wy_canManagerMoreViewEvents?(moreView) ?? true
    }
}

extension WYChatView: WYChatEmojiViewDelegate, WYChatEmojiViewEventsHandler {
    
    public func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) {
        
        let emoji: String = emojiView.dataSource[indexPath.section][indexPath.item]
        
        let textContent = chatInput.textView.attributedText.string
        let textNum = textContent.utf16.count - (textContent.utf16.count - textContent.count) + 1
        if (textNum > inputBarConfig.inputTextLength) && (inputBarConfig.inputTextLength > 0) {
            return
        }

        // 光标位置
        let cursorPosition = chatInput.textView.offset(from: chatInput.textView.beginningOfDocument, to: chatInput.textView.selectedTextRange?.start ?? chatInput.textView.beginningOfDocument)
        
        chatInput.textView.insertText(emoji)
        // 这里 silence 传true，目的是解决delegate回调两次的问题(insertText 和 textViewDidChange 都会导致回调)
        chatInput.textViewDidChange(chatInput.textView, silence: true)
        
        let start: UITextPosition = chatInput.textView.position(from: chatInput.textView.beginningOfDocument, offset: cursorPosition + (inputBarConfig.emojiPattern.isEmpty ? emoji.utf16.count : 1))!
        let end: UITextPosition = chatInput.textView.position(from: start, offset: 0)!

        chatInput.textView.selectedTextRange = chatInput.textView.textRange(from: start, to: end)
        
        delegate?.wy_didClickEmojiView?(emojiView, indexPath: indexPath)
    }

    public func wy_didClickEmojiSendView(_ sendView: UIButton) {
        let emojiText: String = NSMutableAttributedString(attributedString: chatInput.textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string
        didClickKeyboardEvent(emojiText, silence: true)
        delegate?.wy_didClickEmojiSendView?(sendView)
    }
    
    public func wy_didClickEmojiDeleteView(_ deleteView: UIButton) {
        chatInput.textView.deleteBackward()
        delegate?.wy_didClickEmojiDeleteView?(deleteView)
    }
    
    public func wy_canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, indexPath: IndexPath) -> Bool {
        return eventsHandler?.wy_canManagerEmojiViewClickEvents?(emojiView, indexPath: indexPath) ?? true
    }

    public func wy_canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool {
        return eventsHandler?.wy_canManagerEmojiDeleteViewClickEvents?(deleteView) ?? true
    }
    
    public func wy_canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool {
        return eventsHandler?.wy_canManagerEmojiSendViewClickEvents?(sendView) ?? true
    }
}

extension WYChatView: WYChatMoreViewDelegate, WYMoreViewEventsHandler {
    
    public func wy_didClickMoreViewAtIndex(itemIndex: Int) {
        guard let moreView = moreView else { return }
        delegate?.wy_didClickMoreView?(moreView, itemIndex: itemIndex)
    }
    
    public func wy_canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, itemIndex: Int) -> Bool {
        return eventsHandler?.wy_canManagerMoreViewClickEvents?(moreView, itemIndex: itemIndex) ?? true
    }
}
