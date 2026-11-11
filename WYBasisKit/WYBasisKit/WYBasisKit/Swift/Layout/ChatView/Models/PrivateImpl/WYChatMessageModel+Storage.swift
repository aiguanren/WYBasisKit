//
//  WYChatMessageModel+Storage.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/9.
//

import Foundation

/// 消息快照的写入隔离
final class WYChatMessageStorage: Equatable {
    var isTransferring: Bool
    var transferProgress: Double
    var transferError: String
    var greetingDescription: String
    var readers: String
    var readBackState: WYChatMessageSendState
    var sendState: WYChatMessageSendState
    var messageID: String
    var sessionID: String
    var clientTimestamp: String?
    var lastMessageTimestamp: String
    var timestamp: String
    var timeFormat: String?
    var sender: WYChatUserModel
    var group: WYChatGroupModel?
    var content: WYChatMessageContentModel
    var reference: WYChatQuoteModel?
    var mentions: [WYChatMention] = []
    var index: Int

    init(
        isTransferring: Bool = false,
        transferProgress: Double = 0,
        transferError: String = "",
        greetingDescription: String,
        readers: String,
        readBackState: WYChatMessageSendState,
        sendState: WYChatMessageSendState,
        messageID: String,
        sessionID: String,
        clientTimestamp: String?,
        lastMessageTimestamp: String,
        timestamp: String,
        timeFormat: String?,
        sender: WYChatUserModel,
        group: WYChatGroupModel?,
        content: WYChatMessageContentModel,
        reference: WYChatQuoteModel?,
        index: Int
    ) {
        self.isTransferring = isTransferring
        self.transferProgress = transferProgress
        self.transferError = transferError
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

    func copy() -> WYChatMessageStorage {
        let value = WYChatMessageStorage(
            isTransferring: isTransferring,
            transferProgress: transferProgress,
            transferError: transferError,
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
        value.mentions = mentions
        return value
    }

    static func == (lhs: WYChatMessageStorage, rhs: WYChatMessageStorage) -> Bool {
        if lhs === rhs { return true }
        return lhs.isTransferring == rhs.isTransferring
            && lhs.transferProgress == rhs.transferProgress
            && lhs.transferError == rhs.transferError
            && lhs.greetingDescription == rhs.greetingDescription
            && lhs.readers == rhs.readers
            && lhs.readBackState == rhs.readBackState
            && lhs.sendState == rhs.sendState
            && lhs.messageID == rhs.messageID
            && lhs.sessionID == rhs.sessionID
            && lhs.clientTimestamp == rhs.clientTimestamp
            && lhs.lastMessageTimestamp == rhs.lastMessageTimestamp
            && lhs.timestamp == rhs.timestamp
            && lhs.timeFormat == rhs.timeFormat
            && lhs.sender == rhs.sender
            && lhs.group == rhs.group
            && lhs.content == rhs.content
            && lhs.mentions == rhs.mentions
            && lhs.reference == rhs.reference
            && lhs.index == rhs.index
    }
}

extension WYChatMessageModel {
    mutating func wy_prepareMessageStorage() {
        if !isKnownUniquelyReferenced(&state) { state = state.copy() }
    }
}
