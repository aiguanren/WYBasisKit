//
//  WYChatWithdrawnModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 消息撤回model
public struct WYChatWithdrawnModel: Equatable {
    
    /// 发送时间
    public var sendTime: String
    
    /// 可撤回时长间隔
    public var withdrawalInterval: TimeInterval
    
    /// 撤回时间
    public var withdrawnTime: String
    
    /// 消息内容
    public var content: Data
    
    /// 消息类型
    public var messageStyle: WYChatMessageStyle
    
    /// 可重新编辑的原始文本，nil表示不提供重新编辑
    public var originalText: String? = nil
    /// 原始引用快照，nil表示发送时没有引用
    public var reference: WYChatQuoteModel? = nil
    /// 原始文本中的用户提及
    public var mentions: [WYChatMention] = []

    /// 初始化方法
    public init(sendTime: String = "",
                withdrawalInterval: TimeInterval = 120,
                withdrawnTime: String = "",
                content: Data = Data(),
                messageStyle: WYChatMessageStyle = .none) {
        self.sendTime = sendTime
        self.withdrawalInterval = withdrawalInterval
        self.withdrawnTime = withdrawnTime
        self.content = content
        self.messageStyle = messageStyle
    }
}
