//
//  WYChatSessionModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 聊天model
public struct WYChatSessionModel {
    
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String
    
    /// 最后一条消息
    public var lastMessage: WYChatMessageModel?
    
    /// 未读消息的ID列表
    public var unreadMessages: [String]
    
    /// 初始化方法
    public init(sessionID: String = "",
                lastMessage: WYChatMessageModel? = nil,
                unreadMessages: [String] = []) {
        self.sessionID = sessionID
        self.lastMessage = lastMessage
        self.unreadMessages = unreadMessages
    }
}
