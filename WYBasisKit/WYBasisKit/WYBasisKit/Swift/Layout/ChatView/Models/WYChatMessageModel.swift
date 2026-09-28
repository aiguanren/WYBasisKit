//
//  WYChatMessageModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 消息发送状态
@frozen public enum WYChatMessageSendState: Int {
    /// 未发送
    case notSent = 0
    /// 发送中
    case sending
    /// 发送成功
    case success
    /// 发送失败
    case failed
}

/// 消息model
public struct WYChatMessageModel {
    
    /// 打招呼的消息说明(如果该条消息是打招呼的消息，则会判断这个字段是否为空，不为空的话就会显示提示信息，如：以上是打招呼的内容)
    public var greetingDescription: String
    
    /**
     *  消息已读人数
     *  单聊时  0未读，1已读
     *  群聊时  若已读人数等于群人数则表示全部已读，否则为群内已读人数
     */
    public var readers: String

    /// 已读回执发送状态
    public var readBackState: WYChatMessageSendState

    /// 消息发送状态
    public var sendState: WYChatMessageSendState

    /// 消息ID
    public var messageID: String
    
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String
    
    /// 当前客户端时间(依据此字段来计算消息发送时间和当前时间的间距，默认设备本地时间戳)
    public var clientTimestamp: String?
    
    /// 上一次显示时间的那一条消息对应的时间(如果是第一条消息，则会出现为空的情况)
    public var lastMessageTimestamp: String

    /// 消息发送时间
    public var timestamp: String
    
    /**
     *  格式化后的消息发送时间(外部可自定义设置，如果没设置就默认依据timestamp显示)
     *  默认聊天消息时间显示说明
          1、当天的消息，以每5分钟为一个跨度显示时间，具体格式为：HH:mm，如 12:12
          2、昨天的消息，显示格式为：昨天 HH:mm，如 昨天 12:12
          3、消息超过2天、小于1周，显示星期+收发消息的时间，具体格式为：星期几 HH:mm，如    星期日 12:12
          4、消息大于1周且是今年的消息，显示格式为：MMdd HH:mm，如 12月12日 12:12
          5、消息时间不是今年的消息，显示格式为：yyyyMMdd HH:mm，如 2022年12月12日 12:12
     */
    public var timeFormat: String?

    /// 消息发送者信息
    public var sender: WYChatUserModel

    /// 消息所属群信息(若为空为单聊，否则为群聊)
    public var group: WYChatGroupModel?

    /// 消息内容
    public var content: WYChatMessageContentModel
    
    /// 引用消息
    public var reference: WYChatMessageContentModel?
    
    /// model在数组中对应的下标
    public var index: Int

    /**
     *  查看某人是否是该条消息的发送者
     *  userID 某人的ID
     */
    public func isSender(_ userID: String) ->Bool {
        return (userID == sender.id)
    }
    
    /**
     *  获取上一次显示时间的那一条消息对应的时间
     *  datas 包含WYChatMessageModel的数组
     */
    public func sharedLastMessageTimestamp(_ datas: [WYChatMessageModel]) -> String {
        
        var lastMessageTimestamp: String = ""
        
        if datas.isEmpty == false {
            if datas.last?.lastMessageTimestamp.isEmpty ?? true {
                lastMessageTimestamp = datas.last!.timestamp
            }else {
                let lastShowTime: Bool = ((NumberFormatter().number(from: datas.last!.timestamp)?.doubleValue ?? 0) - (NumberFormatter().number(from: datas.last!.lastMessageTimestamp)?.doubleValue ?? 0) >= chatTextConfig.basic.messageMinimumTimeSpan)
                if lastShowTime {
                    lastMessageTimestamp = datas.last!.timestamp
                }else {
                    lastMessageTimestamp = datas.last!.lastMessageTimestamp
                }
            }
        }
        return lastMessageTimestamp
    }
    
    /// 初始化方法
    public init(greetingDescription: String = "",
                readers: String = "",
                readBackState: WYChatMessageSendState = .notSent,
                sendState: WYChatMessageSendState = .notSent,
                messageID: String = "",
                sessionID: String = "",
                clientTimestamp: String? = nil,
                lastMessageTimestamp: String = "",
                timestamp: String = "",
                timeFormat: String? = nil,
                sender: WYChatUserModel = WYChatUserModel(),
                group: WYChatGroupModel? = nil,
                content: WYChatMessageContentModel = WYChatMessageContentModel(),
                reference: WYChatMessageContentModel? = nil,
                index: Int = 0) {
        self.greetingDescription = greetingDescription
        self.readers = readers
        self.readBackState = readBackState
        self.sendState = sendState
        self.messageID = messageID
        self.sessionID = sessionID
        self.clientTimestamp = clientTimestamp
        self.lastMessageTimestamp = lastMessageTimestamp
        self.timestamp = timestamp
        self.timeFormat = timeFormat
        self.sender = sender
        self.group = group
        self.content = content
        self.reference = reference
        self.index = index
    }
}
