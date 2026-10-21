//
//  WYChatViewDelegateHandler.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import Foundation
import UIKit

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回true)
@objc public protocol WYChatViewEventsHandler {
    
    /// 是否需要内部处理 APP变的活跃了 时的事件
    @objc(wy_canManagerApplicationDidBecomeActiveEvents:)
    optional func wy_canManagerApplicationDidBecomeActiveEvents(_ application: UIApplication) -> Bool
    
    /// 是否需要内部处理 键盘将要弹出 时的事件
    @objc(wy_canManagerKeyboardWillShowEvents:)
    optional func wy_canManagerKeyboardWillShowEvents(_ notification: Notification) -> Bool
    
    /// 是否需要内部处理 键盘将要消失 时的事件
    @objc(wy_canManagerKeyboardWillDismissEvents)
    optional func wy_canManagerKeyboardWillDismissEvents() -> Bool
    
    /// 是否需要内部处理 tableView的滚动事件
    @objc(wy_canManagerScrollViewDidScrollEvents:)
    optional func wy_canManagerScrollViewDidScrollEvents(_ scrollView: UIScrollView) -> Bool
    
    /// 是否需要内部处理chatInput控件内 语音 按钮的长按事件
    @objc(wy_canManagerVoiceRecordEvents:)
    optional func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool
    
    /// 是否需要内部处理chatInput控件内 文本/语音 按钮的点击事件
    @objc(wy_canManagerTextVoiceViewEvents:)
    optional func wy_canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 文本/表情 切换按钮的点击事件
    @objc(wy_canManagerTextEmojiViewEvents:)
    optional func wy_canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 更多 按钮的点击事件
    @objc(wy_canManagerMoreViewEvents:)
    optional func wy_canManagerMoreViewEvents(_ moreView: UIButton) -> Bool
    
    /// 是否需要内部处理chatInput控件内 键盘发送按钮 的点击事件
    @objc(wy_canManagerKeyboardSendEvents:)
    optional func wy_canManagerKeyboardSendEvents(_ text: String) -> Bool
    
    /// 是否需要内部处理Emoji控件内 cell 的点击事件
    @objc(wy_canManagerEmojiViewClickEvents:indexPath:)
    optional func wy_canManagerEmojiViewClickEvents(_ emojiView: WYChatEmojiView, indexPath: IndexPath) -> Bool

    /// 是否需要内部处理Emoji控件内 删除按钮 的点击事件
    @objc(wy_canManagerEmojiDeleteViewClickEvents:)
    optional func wy_canManagerEmojiDeleteViewClickEvents(_ deleteView: UIButton) -> Bool
    
    /// 是否需要内部处理Emoji控件内 发送按钮 的点击事件
    @objc(wy_canManagerEmojiSendViewClickEvents:)
    optional func wy_canManagerEmojiSendViewClickEvents(_ sendView: UIButton) -> Bool
    
    /// 是否需要内部处理More控件内 cell 的点击事件
    @objc(wy_canManagerMoreViewClickEvents:itemIndex:)
    optional func wy_canManagerMoreViewClickEvents(_ moreView: WYChatMoreView, itemIndex: Int) -> Bool
    
    /// 是否需要内部处理tableView代理 cellForRowAt 方法
    @objc(wy_canManagerCellForRowEvents:tableView:indexPath:)
    optional func wy_canManagerCellForRowEvents(_ chatView: WYChatView, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell?
}

@objc public protocol WYChatViewDelegate {
    
    /// APP变的活跃了
    @objc(wy_applicationDidBecomeActive:)
    optional func wy_applicationDidBecomeActive(_ application: UIApplication)
    
    /// 键盘将要弹出
    @objc(wy_keyboardWillShow:)
    optional func wy_keyboardWillShow(_ notification: Notification)
    
    /// 键盘将要消失
    @objc(wy_keyboardWillDismiss)
    optional func wy_keyboardWillDismiss()
    
    /// tableView的滚动事件
    @objc(wy_scrollViewDidScroll:)
    optional func wy_scrollViewDidScroll(_ scrollView: UIScrollView)
    
    /// 点击了 文本/语音 切换按钮
    @objc(wy_didClickTextVoiceView:)
    optional func wy_didClickTextVoiceView(isText: Bool)
    
    /// 点击了 表情/文本 切换按钮
    @objc(wy_didClickEmojiTextView:)
    optional func wy_didClickEmojiTextView(isText: Bool)
    
    /// 点击了 更多 按钮
    @objc(wy_didClickMoreView:)
    optional func wy_didClickMoreView(isText: Bool)
    
    /// 输入框文本发生变化
    @objc(wy_textDidChanged:)
    optional func wy_textDidChanged(text: String)
    
    /// 点击了键盘上的 发送 按钮(参数为消息ID，需要完整消息model时可用chatView的messageModelFrom(_ messageID:)反查)
    @objc(wy_keyboardSendMessage:)
    optional func wy_keyboardSendMessage(messageID: String)
    
    /// 点击了emoji控件内某个item
    @objc(wy_didClickEmojiView:indexPath:)
    optional func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath)
    
    /// 点击了emoji控件内功能区删除按钮
    @objc(wy_didClickEmojiDeleteView:)
    optional func wy_didClickEmojiDeleteView(_ deleteView: UIButton)
    
    /// 点击了emoji控件内功能区发送按钮
    @objc(wy_didClickEmojiSendView:)
    optional func wy_didClickEmojiSendView(_ sendView: UIButton)

    /// 点击了More控件内某个item
    @objc(wy_didClickMoreView:itemIndex:)
    optional func wy_didClickMoreView(_ moreView: WYChatMoreView, itemIndex: Int)
}
