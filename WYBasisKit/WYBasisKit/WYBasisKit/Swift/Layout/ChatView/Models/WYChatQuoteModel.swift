//
//  WYChatQuoteModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import Foundation

/// 引用消息的身份与内容快照
public struct WYChatQuoteModel: Equatable {
    /// 被引用的消息ID
    public var messageID: String
    /// 被引用消息的发送者
    public var sender: WYChatUserModel
    /// 被引用的内容快照
    public var content: WYChatMessageContentModel

    /**
     创建引用消息快照
     @param messageID 被引用的消息ID
     @param sender 被引用消息的发送者
     @param content 被引用的内容快照
     */
    public init(messageID: String = "", sender: WYChatUserModel = WYChatUserModel(), content: WYChatMessageContentModel = WYChatMessageContentModel()) { self.messageID = messageID; self.sender = sender; self.content = content }
}
