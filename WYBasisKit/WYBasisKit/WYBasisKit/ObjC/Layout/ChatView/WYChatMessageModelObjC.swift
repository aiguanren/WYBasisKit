//
//  WYChatMessageModelObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

@objc(WYChatAssetsModel)
@objcMembers public class WYChatAssetsModelObjC: NSObject {
    /// id
    public var id: String
    /// 名字
    public var name: String
    /// 网络下载地址
    public var downloadPath: String
    /// 本地文件路径
    public var localPath: String

    public override convenience init() { self.init(WYChatAssetsModel()) }

    @nonobjc public init(_ value: WYChatAssetsModel) {
        self.id = value.id
        self.name = value.name
        self.downloadPath = value.downloadPath
        self.localPath = value.localPath
        super.init()
    }

    @nonobjc public func toValue() -> WYChatAssetsModel {
        var value = WYChatAssetsModel()
        value.id = id
        value.name = name
        value.downloadPath = downloadPath
        value.localPath = localPath
        return value
    }
}

@objc(WYChatUserModel)
@objcMembers public class WYChatUserModelObjC: NSObject {
    /// 用户id
    public var id: String
    /// 用户名
    public var name: String
    /// 用户昵称
    public var nickname: String
    /// 用户备注
    public var remarks: String
    /// 用户签名
    public var signature: String
    /// 用户所在地区
    public var area: String
    /// 用户聊天列表
    public var listOfSessions: [WYChatSessionModelObjC]
    /// 加入的群
    public var groups: [WYChatGroupModelObjC]
    /// 用户二维码
    public var qrCode: WYChatAssetsModelObjC
    /// 用户头像
    public var avatar: WYChatAssetsModelObjC
    /// 用户头像缩略图
    public var thumbnailAvatar: WYChatAssetsModelObjC
    /// 更多信息
    public var moreInfo: Data?
    /// model在数组中对应的下标
    public var index: Int

    public override convenience init() { self.init(WYChatUserModel()) }

    @nonobjc public init(_ value: WYChatUserModel) {
        self.id = value.id
        self.name = value.name
        self.nickname = value.nickname
        self.remarks = value.remarks
        self.signature = value.signature
        self.area = value.area
        self.listOfSessions = value.listOfSessions.map { WYChatSessionModelObjC($0) }
        self.groups = value.groups.map { WYChatGroupModelObjC($0) }
        self.qrCode = WYChatAssetsModelObjC(value.qrCode)
        self.avatar = WYChatAssetsModelObjC(value.avatar)
        self.thumbnailAvatar = WYChatAssetsModelObjC(value.thumbnailAvatar)
        self.moreInfo = value.moreInfo
        self.index = value.index
        super.init()
    }

    @nonobjc public func toValue() -> WYChatUserModel {
        var value = WYChatUserModel()
        value.id = id
        value.name = name
        value.nickname = nickname
        value.remarks = remarks
        value.signature = signature
        value.area = area
        value.listOfSessions = listOfSessions.map { $0.toValue() }
        value.groups = groups.map { $0.toValue() }
        value.qrCode = qrCode.toValue()
        value.avatar = avatar.toValue()
        value.thumbnailAvatar = thumbnailAvatar.toValue()
        value.moreInfo = moreInfo
        value.index = index
        return value
    }
}

@objc(WYChatGroupModel)
@objcMembers public class WYChatGroupModelObjC: NSObject {
    /// 群ID
    public var id: String
    /// 用户在群内的昵称
    public var nickname: String
    /// 群主信息
    public var ownerInfo: WYChatUserModelObjC
    /// 群名称
    public var name: String
    /// 群头像
    public var avatar: WYChatAssetsModelObjC
    /// 群头像缩略图
    public var thumbnailAvatar: WYChatAssetsModelObjC
    /// 是否开启了消息免打扰
    public var silence: Bool
    /// 群公告
    public var publicity: String
    /// 用户给群设置的备注
    public var remarks: String
    /// 群二维码
    public var qrCode: WYChatAssetsModelObjC
    /// 群管理信息
    public var managers: [WYChatUserModelObjC]
    /// 群成员信息
    public var members: [WYChatUserModelObjC]
    /// model在数组中对应的下标
    public var index: Int

    public override convenience init() { self.init(WYChatGroupModel()) }

    @nonobjc public init(_ value: WYChatGroupModel) {
        self.id = value.id
        self.nickname = value.nickname
        self.ownerInfo = WYChatUserModelObjC(value.ownerInfo)
        self.name = value.name
        self.avatar = WYChatAssetsModelObjC(value.avatar)
        self.thumbnailAvatar = WYChatAssetsModelObjC(value.thumbnailAvatar)
        self.silence = value.silence
        self.publicity = value.publicity
        self.remarks = value.remarks
        self.qrCode = WYChatAssetsModelObjC(value.qrCode)
        self.managers = value.managers.map { WYChatUserModelObjC($0) }
        self.members = value.members.map { WYChatUserModelObjC($0) }
        self.index = value.index
        super.init()
    }

    @nonobjc public func toValue() -> WYChatGroupModel {
        var value = WYChatGroupModel()
        value.id = id
        value.nickname = nickname
        value.ownerInfo = ownerInfo.toValue()
        value.name = name
        value.avatar = avatar.toValue()
        value.thumbnailAvatar = thumbnailAvatar.toValue()
        value.silence = silence
        value.publicity = publicity
        value.remarks = remarks
        value.qrCode = qrCode.toValue()
        value.managers = managers.map { $0.toValue() }
        value.members = members.map { $0.toValue() }
        value.index = index
        return value
    }
}

@objc(WYChatSessionModel)
@objcMembers public class WYChatSessionModelObjC: NSObject {
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String
    /// 最后一条消息
    public var lastMessage: WYChatMessageModelObjC?
    /// 未读消息的ID列表
    public var unreadMessages: [String]

    public override convenience init() { self.init(WYChatSessionModel()) }

    @nonobjc public init(_ value: WYChatSessionModel) {
        self.sessionID = value.sessionID
        self.lastMessage = value.lastMessage.map { WYChatMessageModelObjC($0) }
        self.unreadMessages = value.unreadMessages
        super.init()
    }

    @nonobjc public func toValue() -> WYChatSessionModel {
        var value = WYChatSessionModel()
        value.sessionID = sessionID
        value.lastMessage = lastMessage.map { $0.toValue() }
        value.unreadMessages = unreadMessages
        return value
    }
}

@objc(WYChatMessageModel)
@objcMembers public class WYChatMessageModelObjC: NSObject {
    /// 内容是否正在上传或下载
    public var isTransferring: Bool = false

    /// 上传或下载进度，范围0到1
    public var transferProgress: Double = 0

    /// 上传或下载失败提示，空字符串表示没有错误
    public var transferError: String = ""

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
    public var sender: WYChatUserModelObjC
    /// 消息所属群信息(若为空为单聊，否则为群聊)
    public var group: WYChatGroupModelObjC?
    /// 消息内容
    public var content: WYChatMessageContentModelObjC
    /// 文本中提及的用户及其位置
    public var mentions: [WYChatMentionObjC]
    /// 引用消息
    public var reference: WYChatQuoteModelObjC?
    /// model在数组中对应的下标
    public var index: Int

    public override convenience init() { self.init(WYChatMessageModel()) }

    @nonobjc public init(_ value: WYChatMessageModel) {
        self.greetingDescription = value.greetingDescription
        self.readers = value.readers
        self.readBackState = value.readBackState
        self.sendState = value.sendState
        self.messageID = value.messageID
        self.sessionID = value.sessionID
        self.clientTimestamp = value.clientTimestamp
        self.lastMessageTimestamp = value.lastMessageTimestamp
        self.timestamp = value.timestamp
        self.timeFormat = value.timeFormat
        self.sender = WYChatUserModelObjC(value.sender)
        self.group = value.group.map { WYChatGroupModelObjC($0) }
        self.content = WYChatMessageContentModelObjC(value.content)
        self.mentions = value.mentions.map(WYChatMentionObjC.init)
        self.reference = value.reference.map(WYChatQuoteModelObjC.init)
        self.index = value.index
        self.isTransferring = value.isTransferring
        self.transferProgress = value.transferProgress
        self.transferError = value.transferError
        super.init()
    }

    @nonobjc public func toValue() -> WYChatMessageModel {
        var value = WYChatMessageModel()
        value.greetingDescription = greetingDescription
        value.readers = readers
        value.readBackState = readBackState
        value.sendState = sendState
        value.messageID = messageID
        value.sessionID = sessionID
        value.clientTimestamp = clientTimestamp
        value.lastMessageTimestamp = lastMessageTimestamp
        value.timestamp = timestamp
        value.timeFormat = timeFormat
        value.sender = sender.toValue()
        value.group = group.map { $0.toValue() }
        value.content = content.toValue()
        value.mentions = mentions.map { $0.toValue() }
        value.reference = reference.map { $0.toValue() }
        value.index = index
        value.isTransferring = isTransferring
        value.transferProgress = transferProgress
        value.transferError = transferError
        return value
    }
}

#endif
