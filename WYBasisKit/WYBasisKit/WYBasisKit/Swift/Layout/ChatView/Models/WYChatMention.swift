//
//  WYChatMention.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import Foundation

/// 文本中提及的用户及其位置
public struct WYChatMention: Equatable {
    /// 被提及的用户
    public var user: WYChatUserModel
    /// 显示的提及文本，包含前缀
    public var text: String
    /// 提及文本在消息中的UTF16范围，不包含分隔文本
    public var range: NSRange

    /**
     创建用户提及
     @param user 被提及的用户
     @param text 显示的提及文本
     @param range 文本在消息中的UTF16范围
     */
    public init(user: WYChatUserModel, text: String, range: NSRange) { self.user = user; self.text = text; self.range = range }
}
