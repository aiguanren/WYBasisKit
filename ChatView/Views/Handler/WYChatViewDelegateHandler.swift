//
//  WYChatViewDelegateHandler.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import Foundation
import UIKit

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回True)
@objc public protocol WYChatViewEventsHandler {
    
    /// 是否需要内部处理 APP变的活跃了 时的事件
    @objc optional func canManagerApplicationDidBecomeActiveEvents(_ application: UIApplication) -> Bool
    
    /// 是否需要内部处理 键盘将要弹出 时的事件
    @objc optional func canManagerKeyboardWillShowEvents(_ notification: Notification) -> Bool
    
    /// 是否需要内部处理 键盘将要消失 时的事件
    @objc optional func canManagerKeyboardWillDismissEvents() -> Bool
    
    /// 是否需要内部处理 tableView的滚动事件
    @objc optional func canManagerScrollViewDidScrollEvents(_ scrollView: UIScrollView) -> Bool
    
    /// 是否需要内部处理chatInput控件内 语音 按钮的长按事件
    @objc optional func canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool
    
    /// 是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件
    @objc optional func canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件
    @objc optional func canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 更多 按钮的点击事件
    @objc optional func canManagerMoreViewEvents(_ moreView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件
    @objc optional func canManagerKeyboardSendEvents(_ text: String) -> Bool
    
    /// 是否需要内部处理Emoji控件内 cell 的点击事件
    @objc optional func canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath) -> Bool
    
    /// 是否需要内部处理 表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调) 的长按事件
    @objc optional func canManagerEmojiLongPressEvents(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, imageView: UIImageView) -> Bool
    
    /// 是否需要内部处理Emoji控件内 删除按钮 的点击事件
    @objc optional func canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool
    
    /// 是否需要内部处理Emoji控件内 发送按钮 的点击事件
    @objc optional func canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool
    
    /// 是否需要内部处理More控件内 cell 的点击事件
    @objc optional func canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, _ itemIndex: NSInteger) -> Bool
    
    /// 是否需要内部处理tableView代理 cellForRowAt 方法
    @objc optional func canManagerCellForRowEvents(_ chatView: WYChatView, _ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell?
}

@objc public protocol WYChatViewDelegate {
    
    /// APP变的活跃了
    @objc optional func applicationDidBecomeActive(_ application: UIApplication)
    
    /// 键盘将要弹出
    @objc optional func keyboardWillShow(_ notification: Notification)
    
    /// 键盘将要消失
    @objc optional func keyboardWillDismiss()
    
    /// tableView的滚动事件
    @objc optional func scrollViewDidScroll(_ scrollView: UIScrollView)
    
    /// 点击了 文本/语音 切换按钮
    @objc optional func didClickTextVoiceView(_ isText: Bool)
    
    /// 点击了 表情/文本 切换按钮
    @objc optional func didClickEmojiTextView(_ isText: Bool)
    
    /// 点击了 更多 按钮
    @objc optional func didClickMoreView(_ isText: Bool)
    
    /// 输入框文本发生变化
    @objc optional func textDidChanged(_ text: String)
    
    /// 点击了键盘上的 发送 按钮
    @objc optional func keyboardSendMessage(_ message: WYChatMessageModel)
    
    /// 点击了emoji控件内某个item
    @objc optional func didClickEmojiView(_ emojiView: WYChatEmojiView, _ indexPath: IndexPath)
    
    /// 点击了emoji控件内功能区删除按钮
    @objc optional func didClickEmojiDeleteView(_ deleteView: UIButton)
    
    /// 点击了emoji控件内功能区发送按钮
    @objc optional func didClickEmojiSendView(_ sendView: UIButton)
    
    /// 长按了表情预览控件(仅限WYEmojiPreviewStyle == other时才会回调)
    @objc optional func emojiItemLongPress(_ gestureRecognizer: UILongPressGestureRecognizer, emoji: String, imageView: UIImageView)
    
    /// 点击了More控件内某个item
    @objc optional func didClickMoreView(_ moreView: WYChatMoreView, _ itemIndex: NSInteger)
}
