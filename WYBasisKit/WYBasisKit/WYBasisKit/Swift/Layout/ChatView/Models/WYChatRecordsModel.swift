//
//  WYChatRecordsModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 聊天记录(合集)model
public struct WYChatRecordsModel {
    
    /// 标题(xxx的聊天记录)
    public var title: String
    
    /// 消息合集
    public var messages: [WYChatMessageModel]
    
    /// 备注
    public var remarks: String

    /// 初始化方法
    public init(title: String = "",
                messages: [WYChatMessageModel] = [],
                remarks: String = "") {
        self.title = title
        self.messages = messages
        self.remarks = remarks
    }
}
