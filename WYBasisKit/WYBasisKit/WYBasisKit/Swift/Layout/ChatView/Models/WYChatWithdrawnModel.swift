//
//  WYChatWithdrawnModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 消息撤回时长最大间隔时间(单位秒)
public var messageWithdrawalInterval: TimeInterval = 120

/// 消息撤回model
public struct WYChatWithdrawnModel {
    
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
    
    /// 初始化方法
    public init(sendTime: String = "",
                withdrawalInterval: TimeInterval = messageWithdrawalInterval,
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
