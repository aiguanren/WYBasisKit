//
//  WYChatMessageModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 消息发送状态
@objc @frozen public enum WYChatMessageSendState: Int {
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
public struct WYChatMessageModel: Equatable {
    
    /// 内容是否正在上传或下载
    public var isTransferring: Bool {
        get { state.isTransferring }
        set { wy_prepareMessageStorage(); state.isTransferring = newValue }
    }
    /// 上传或下载进度，范围0到1
    public var transferProgress: Double {
        get { state.transferProgress }
        set { wy_prepareMessageStorage(); state.transferProgress = newValue }
    }
    /// 上传或下载失败提示，空字符串表示没有错误
    public var transferError: String {
        get { state.transferError }
        set { wy_prepareMessageStorage(); state.transferError = newValue }
    }

    /// 打招呼的消息说明(如果该条消息是打招呼的消息，则会判断这个字段是否为空，不为空的话就会显示提示信息，如：以上是打招呼的内容)
    public var greetingDescription: String {
        get { state.greetingDescription }
        set { wy_prepareMessageStorage(); state.greetingDescription = newValue }
    }
    
    /**
     *  消息已读人数
     *  单聊时  0未读，1已读
     *  群聊时  若已读人数等于群人数则表示全部已读，否则为群内已读人数
     */
    public var readers: String {
        get { state.readers }
        set { wy_prepareMessageStorage(); state.readers = newValue }
    }

    /// 已读回执发送状态
    public var readBackState: WYChatMessageSendState {
        get { state.readBackState }
        set { wy_prepareMessageStorage(); state.readBackState = newValue }
    }

    /// 消息发送状态
    public var sendState: WYChatMessageSendState {
        get { state.sendState }
        set { wy_prepareMessageStorage(); state.sendState = newValue }
    }

    /// 消息ID
    public var messageID: String {
        get { state.messageID }
        set { wy_prepareMessageStorage(); state.messageID = newValue }
    }
    
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String {
        get { state.sessionID }
        set { wy_prepareMessageStorage(); state.sessionID = newValue }
    }
    
    /// 当前客户端时间(依据此字段来计算消息发送时间和当前时间的间距，默认设备本地时间戳)
    public var clientTimestamp: String? {
        get { state.clientTimestamp }
        set { wy_prepareMessageStorage(); state.clientTimestamp = newValue }
    }
    
    /// 上一次显示时间的那一条消息对应的时间(如果是第一条消息，则会出现为空的情况)
    public var lastMessageTimestamp: String {
        get { state.lastMessageTimestamp }
        set { wy_prepareMessageStorage(); state.lastMessageTimestamp = newValue }
    }

    /// 消息发送时间
    public var timestamp: String {
        get { state.timestamp }
        set { wy_prepareMessageStorage(); state.timestamp = newValue }
    }
    
    /**
     *  格式化后的消息发送时间(外部可自定义设置，如果没设置就默认依据timestamp显示)
     *  默认聊天消息时间显示说明
          1、当天的消息，以每5分钟为一个跨度显示时间，具体格式为：HH:mm，如 12:12
          2、昨天的消息，显示格式为：昨天 HH:mm，如 昨天 12:12
          3、消息超过2天、小于1周，显示星期+收发消息的时间，具体格式为：星期几 HH:mm，如    星期日 12:12
          4、消息大于1周且是今年的消息，显示格式为：MMdd HH:mm，如 12月12日 12:12
          5、消息时间不是今年的消息，显示格式为：yyyyMMdd HH:mm，如 2022年12月12日 12:12
     */
    public var timeFormat: String? {
        get { state.timeFormat }
        set { wy_prepareMessageStorage(); state.timeFormat = newValue }
    }

    /// 消息发送者信息
    public var sender: WYChatUserModel {
        get { state.sender }
        set { wy_prepareMessageStorage(); state.sender = newValue }
    }

    /// 消息所属群信息(若为空为单聊，否则为群聊)
    public var group: WYChatGroupModel? {
        get { state.group }
        set { wy_prepareMessageStorage(); state.group = newValue }
    }

    /// 消息内容
    public var content: WYChatMessageContentModel {
        get { state.content }
        set { wy_prepareMessageStorage(); state.content = newValue }
    }
    
    /// 文本中提及的用户及其位置
    public var mentions: [WYChatMention] {
        get { state.mentions }
        set { wy_prepareMessageStorage(); state.mentions = newValue }
    }

    /// 引用消息
    public var reference: WYChatQuoteModel? {
        get { state.reference }
        set { wy_prepareMessageStorage(); state.reference = newValue }
    }
    
    /// model在数组中对应的下标
    public var index: Int {
        get { state.index }
        set { wy_prepareMessageStorage(); state.index = newValue }
    }

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
    public func sharedLastMessageTimestamp(_ datas: [WYChatMessageModel], minimumTimeSpan: TimeInterval = 300) -> String {
        
        var lastMessageTimestamp: String = ""
        
        if datas.isEmpty == false {
            if datas.last?.lastMessageTimestamp.isEmpty ?? true {
                lastMessageTimestamp = datas.last!.timestamp
            }else {
                let rawCurrent = Double(datas.last!.timestamp) ?? 0
                let rawPrevious = Double(datas.last!.lastMessageTimestamp) ?? 0
                let current = rawCurrent > 100_000_000_000 ? rawCurrent / 1000 : rawCurrent
                let previous = rawPrevious > 100_000_000_000 ? rawPrevious / 1000 : rawPrevious
                let lastShowTime = current - previous >= minimumTimeSpan
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
                reference: WYChatQuoteModel? = nil,
                index: Int = 0) {
        state = WYChatMessageStorage(
            greetingDescription: greetingDescription,
            readers: readers,
            readBackState: readBackState,
            sendState: sendState,
            messageID: messageID,
            sessionID: sessionID,
            clientTimestamp: clientTimestamp,
            lastMessageTimestamp: lastMessageTimestamp,
            timestamp: timestamp,
            timeFormat: timeFormat,
            sender: sender,
            group: group,
            content: content,
            reference: reference,
            index: index
        )
    }

    internal var state: WYChatMessageStorage

}
