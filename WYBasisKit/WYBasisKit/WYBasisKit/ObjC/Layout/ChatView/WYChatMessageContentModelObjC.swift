//
//  WYChatMessageContentModelObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

@objc(WYChatPhotoModel)
@objcMembers public class WYChatPhotoModelObjC: NSObject {
    /// 原图
    public var original: WYChatAssetsModelObjC
    /// 缩略图
    public var thumbnail: WYChatAssetsModelObjC

    public override convenience init() { self.init(WYChatPhotoModel()) }

    @nonobjc public init(_ value: WYChatPhotoModel) {
        self.original = WYChatAssetsModelObjC(value.original)
        self.thumbnail = WYChatAssetsModelObjC(value.thumbnail)
        super.init()
    }

    @nonobjc public func toValue() -> WYChatPhotoModel {
        var value = WYChatPhotoModel()
        value.original = original.toValue()
        value.thumbnail = thumbnail.toValue()
        return value
    }
}

@objc(WYChatLuckyMoneyModel)
@objcMembers public class WYChatLuckyMoneyModelObjC: NSObject {
    /// id
    public var id: String
    /// 大封面
    public var fullCover: WYChatAssetsModelObjC
    /// 小封面
    public var smallCover: WYChatAssetsModelObjC
    /// 封面视频
    public var coverVideo: WYChatAssetsModelObjC
    /// 金额
    public var amounts: String
    /// 红包个数(1为个人红包，否则为多人红包)
    public var numberOfLuckyMoney: Int
    /// 已抢红包个数
    public var numberOfRobbed: Int
    /// 红包已抢金额
    public var amountsStolen: Double
    /// 收款状态
    public var state: WYChatFundsState
    /// 备注
    public var remarks: String
    /// 说明(xx红包)
    public var notes: String

    public override convenience init() { self.init(WYChatLuckyMoneyModel()) }

    @nonobjc public init(_ value: WYChatLuckyMoneyModel) {
        self.id = value.id
        self.fullCover = WYChatAssetsModelObjC(value.fullCover)
        self.smallCover = WYChatAssetsModelObjC(value.smallCover)
        self.coverVideo = WYChatAssetsModelObjC(value.coverVideo)
        self.amounts = value.amounts
        self.numberOfLuckyMoney = value.numberOfLuckyMoney
        self.numberOfRobbed = value.numberOfRobbed
        self.amountsStolen = value.amountsStolen
        self.state = value.state
        self.remarks = value.remarks
        self.notes = value.notes
        super.init()
    }

    @nonobjc public func toValue() -> WYChatLuckyMoneyModel {
        var value = WYChatLuckyMoneyModel()
        value.id = id
        value.fullCover = fullCover.toValue()
        value.smallCover = smallCover.toValue()
        value.coverVideo = coverVideo.toValue()
        value.amounts = amounts
        value.numberOfLuckyMoney = numberOfLuckyMoney
        value.numberOfRobbed = numberOfRobbed
        value.amountsStolen = amountsStolen
        value.state = state
        value.remarks = remarks
        value.notes = notes
        return value
    }
}

@objc(WYChatTakePatModel)
@objcMembers public class WYChatTakePatModelObjC: NSObject {
    /// 拍人者
    public var striking: WYChatUserModelObjC
    /// 被拍者
    public var beaten: WYChatUserModelObjC
    /// 被拍者拍一拍设置
    public var notes: String

    public override convenience init() { self.init(WYChatTakePatModel()) }

    @nonobjc public init(_ value: WYChatTakePatModel) {
        self.striking = WYChatUserModelObjC(value.striking)
        self.beaten = WYChatUserModelObjC(value.beaten)
        self.notes = value.notes
        super.init()
    }

    @nonobjc public func toValue() -> WYChatTakePatModel {
        var value = WYChatTakePatModel()
        value.striking = striking.toValue()
        value.beaten = beaten.toValue()
        value.notes = notes
        return value
    }
}

@objc(WYChatFileModel)
@objcMembers public class WYChatFileModelObjC: NSObject {
    /// id
    public var id: String
    /// 标题
    public var title: String
    /// icon
    public var icon: WYChatAssetsModelObjC
    /// 大小(占用内存，如xxkb,xxmb)
    public var size: String
    /// 名称
    public var name: String
    /// 头像
    public var avatar: WYChatAssetsModelObjC

    public override convenience init() { self.init(WYChatFileModel()) }

    @nonobjc public init(_ value: WYChatFileModel) {
        self.id = value.id
        self.title = value.title
        self.icon = WYChatAssetsModelObjC(value.icon)
        self.size = value.size
        self.name = value.name
        self.avatar = WYChatAssetsModelObjC(value.avatar)
        super.init()
    }

    @nonobjc public func toValue() -> WYChatFileModel {
        var value = WYChatFileModel()
        value.id = id
        value.title = title
        value.icon = icon.toValue()
        value.size = size
        value.name = name
        value.avatar = avatar.toValue()
        return value
    }
}

@objc(WYChatVideoModel)
@objcMembers public class WYChatVideoModelObjC: NSObject {
    /// id
    public var id: String
    /// 封面
    public var cover: WYChatAssetsModelObjC
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModelObjC
    /// 视频
    public var video: WYChatAssetsModelObjC
    /// 视频时长
    public var duration: TimeInterval
    /// 当前播放时长
    public var playedDuration: TimeInterval

    public override convenience init() { self.init(WYChatVideoModel()) }

    @nonobjc public init(_ value: WYChatVideoModel) {
        self.id = value.id
        self.cover = WYChatAssetsModelObjC(value.cover)
        self.thumbnailCover = WYChatAssetsModelObjC(value.thumbnailCover)
        self.video = WYChatAssetsModelObjC(value.video)
        self.duration = value.duration
        self.playedDuration = value.playedDuration
        super.init()
    }

    @nonobjc public func toValue() -> WYChatVideoModel {
        var value = WYChatVideoModel()
        value.id = id
        value.cover = cover.toValue()
        value.thumbnailCover = thumbnailCover.toValue()
        value.video = video.toValue()
        value.duration = duration
        value.playedDuration = playedDuration
        return value
    }
}

@objc(WYChatMessageContentModel)
@objcMembers public class WYChatMessageContentModelObjC: NSObject {
    /// 消息内容类型
    public var style: WYChatMessageStyle { toValue().style() }
    /// 文本
    public var text: String?
    /// 语音
    public var voice: WYChatVoiceModelObjC?
    /// 照片
    public var photo: WYChatPhotoModelObjC?
    /// 音乐
    public var music: WYChatMusicModelObjC?
    /// 视频
    public var video: WYChatVideoModelObjC?
    /// 红包
    public var luckyMoney: WYChatLuckyMoneyModelObjC?
    /// 转账
    public var transfer: WYChatLuckyMoneyModelObjC?
    /// 位置
    public var location: WYChatLocationModelObjC?
    /// 拍一拍
    public var takePat: WYChatTakePatModelObjC?
    /// 消息撤回
    public var withdrawn: WYChatWithdrawnModelObjC?
    /// 音视频通话
    public var call: WYChatCallModelObjC?
    /// 网页、小程序
    public var webpage: WYChatWebpageModelObjC?
    /// 文件
    public var file: WYChatFileModelObjC?
    /// 名片
    public var businessCard: WYChatBusinessCardModelObjC?
    /// 聊天记录(合集)
    public var chatRecords: WYChatRecordsModelObjC?

    public override convenience init() { self.init(WYChatMessageContentModel()) }

    @nonobjc public init(_ value: WYChatMessageContentModel) {
        self.text = value.text
        self.voice = value.voice.map { WYChatVoiceModelObjC($0) }
        self.photo = value.photo.map { WYChatPhotoModelObjC($0) }
        self.music = value.music.map { WYChatMusicModelObjC($0) }
        self.video = value.video.map { WYChatVideoModelObjC($0) }
        self.luckyMoney = value.luckyMoney.map { WYChatLuckyMoneyModelObjC($0) }
        self.transfer = value.transfer.map { WYChatLuckyMoneyModelObjC($0) }
        self.location = value.location.map { WYChatLocationModelObjC($0) }
        self.takePat = value.takePat.map { WYChatTakePatModelObjC($0) }
        self.withdrawn = value.withdrawn.map { WYChatWithdrawnModelObjC($0) }
        self.call = value.call.map { WYChatCallModelObjC($0) }
        self.webpage = value.webpage.map { WYChatWebpageModelObjC($0) }
        self.file = value.file.map { WYChatFileModelObjC($0) }
        self.businessCard = value.businessCard.map { WYChatBusinessCardModelObjC($0) }
        self.chatRecords = value.chatRecords.map { WYChatRecordsModelObjC($0) }
        super.init()
    }

    @nonobjc public func toValue() -> WYChatMessageContentModel {
        var value = WYChatMessageContentModel()
        value.text = text
        value.voice = voice.map { $0.toValue() }
        value.photo = photo.map { $0.toValue() }
        value.music = music.map { $0.toValue() }
        value.video = video.map { $0.toValue() }
        value.luckyMoney = luckyMoney.map { $0.toValue() }
        value.transfer = transfer.map { $0.toValue() }
        value.location = location.map { $0.toValue() }
        value.takePat = takePat.map { $0.toValue() }
        value.withdrawn = withdrawn.map { $0.toValue() }
        value.call = call.map { $0.toValue() }
        value.webpage = webpage.map { $0.toValue() }
        value.file = file.map { $0.toValue() }
        value.businessCard = businessCard.map { $0.toValue() }
        value.chatRecords = chatRecords.map { $0.toValue() }
        return value
    }
}

@objc(WYChatWebpageModel)
@objcMembers public class WYChatWebpageModelObjC: NSObject {
    /// id
    public var id: String
    /// 封面
    public var cover: WYChatAssetsModelObjC
    /// 标题
    public var title: String
    /// 描述
    public var remarks: String
    /// 头像
    public var avatar: WYChatAssetsModelObjC
    /// 名称
    public var name: String
    /// 内容链接
    public var path: String

    public override convenience init() { self.init(WYChatWebpageModel()) }

    @nonobjc public init(_ value: WYChatWebpageModel) {
        self.id = value.id
        self.cover = WYChatAssetsModelObjC(value.cover)
        self.title = value.title
        self.remarks = value.remarks
        self.avatar = WYChatAssetsModelObjC(value.avatar)
        self.name = value.name
        self.path = value.path
        super.init()
    }

    @nonobjc public func toValue() -> WYChatWebpageModel {
        var value = WYChatWebpageModel()
        value.id = id
        value.cover = cover.toValue()
        value.title = title
        value.remarks = remarks
        value.avatar = avatar.toValue()
        value.name = name
        value.path = path
        return value
    }
}

@objc(WYChatLocationModel)
@objcMembers public class WYChatLocationModelObjC: NSObject {
    /// 定位封面
    public var cover: WYChatAssetsModelObjC
    /// 定位标题
    public var title: String
    /// 定位详细地址
    public var address: String
    /// 定位经度
    public var longitude: String
    /// 定位纬度
    public var latitude: String

    public override convenience init() { self.init(WYChatLocationModel()) }

    @nonobjc public init(_ value: WYChatLocationModel) {
        self.cover = WYChatAssetsModelObjC(value.cover)
        self.title = value.title
        self.address = value.address
        self.longitude = value.longitude
        self.latitude = value.latitude
        super.init()
    }

    @nonobjc public func toValue() -> WYChatLocationModel {
        var value = WYChatLocationModel()
        value.cover = cover.toValue()
        value.title = title
        value.address = address
        value.longitude = longitude
        value.latitude = latitude
        return value
    }
}

@objc(WYChatCallModel)
@objcMembers public class WYChatCallModelObjC: NSObject {
    /// 通话时长
    public var durationOfCall: TimeInterval
    /// 通话类型
    public var callStyle: WYChatCallStyle
    /// 通话发起者信息
    public var promoter: WYChatUserModelObjC
    /// 通话成员信息(一对一通话时只有一个成员)
    public var members: [WYChatUserModelObjC]

    public override convenience init() { self.init(WYChatCallModel()) }

    @nonobjc public init(_ value: WYChatCallModel) {
        self.durationOfCall = value.durationOfCall
        self.callStyle = value.callStyle
        self.promoter = WYChatUserModelObjC(value.promoter)
        self.members = value.members.map { WYChatUserModelObjC($0) }
        super.init()
    }

    @nonobjc public func toValue() -> WYChatCallModel {
        var value = WYChatCallModel()
        value.durationOfCall = durationOfCall
        value.callStyle = callStyle
        value.promoter = promoter.toValue()
        value.members = members.map { $0.toValue() }
        return value
    }
}

@objc(WYChatRecordsModel)
@objcMembers public class WYChatRecordsModelObjC: NSObject {
    /// 标题(xxx的聊天记录)
    public var title: String
    /// 消息合集
    public var messages: [WYChatMessageModelObjC]
    /// 备注
    public var remarks: String

    public override convenience init() { self.init(WYChatRecordsModel()) }

    @nonobjc public init(_ value: WYChatRecordsModel) {
        self.title = value.title
        self.messages = value.messages.map { WYChatMessageModelObjC($0) }
        self.remarks = value.remarks
        super.init()
    }

    @nonobjc public func toValue() -> WYChatRecordsModel {
        var value = WYChatRecordsModel()
        value.title = title
        value.messages = messages.map { $0.toValue() }
        value.remarks = remarks
        return value
    }
}

@objc(WYChatBusinessCardModel)
@objcMembers public class WYChatBusinessCardModelObjC: NSObject {
    /// id
    public var id: String
    /// 用户信息
    public var userInfo: WYChatUserModelObjC
    /// 描述
    public var remarks: String

    public override convenience init() { self.init(WYChatBusinessCardModel()) }

    @nonobjc public init(_ value: WYChatBusinessCardModel) {
        self.id = value.id
        self.userInfo = WYChatUserModelObjC(value.userInfo)
        self.remarks = value.remarks
        super.init()
    }

    @nonobjc public func toValue() -> WYChatBusinessCardModel {
        var value = WYChatBusinessCardModel()
        value.id = id
        value.userInfo = userInfo.toValue()
        value.remarks = remarks
        return value
    }
}

@objc(WYChatMusicModel)
@objcMembers public class WYChatMusicModelObjC: NSObject {
    /// id
    public var id: String
    /// 音乐名
    public var name: String
    /// 作曲家
    public var composer: String
    /// 演唱者
    public var singer: String
    /// 音乐时长
    public var duration: TimeInterval
    /// 当前已播放时长
    public var playedDuration: TimeInterval
    /// 播放地址
    public var playPath: String
    /// 封面
    public var cover: WYChatAssetsModelObjC
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModelObjC

    public override convenience init() { self.init(WYChatMusicModel()) }

    @nonobjc public init(_ value: WYChatMusicModel) {
        self.id = value.id
        self.name = value.name
        self.composer = value.composer
        self.singer = value.singer
        self.duration = value.duration
        self.playedDuration = value.playedDuration
        self.playPath = value.playPath
        self.cover = WYChatAssetsModelObjC(value.cover)
        self.thumbnailCover = WYChatAssetsModelObjC(value.thumbnailCover)
        super.init()
    }

    @nonobjc public func toValue() -> WYChatMusicModel {
        var value = WYChatMusicModel()
        value.id = id
        value.name = name
        value.composer = composer
        value.singer = singer
        value.duration = duration
        value.playedDuration = playedDuration
        value.playPath = playPath
        value.cover = cover.toValue()
        value.thumbnailCover = thumbnailCover.toValue()
        return value
    }
}

@objc(WYChatVoiceModel)
@objcMembers public class WYChatVoiceModelObjC: NSObject {
    /// 是否正在识别语音
    public var isRecognizing: Bool = false
    /// 语音识别错误提示
    public var recognitionError: String = ""
    /// 是否正在播放，由调用方更新
    public var isPlaying: Bool = false

    /// id
    public var id: String
    /// 语音时长
    public var duration: TimeInterval
    /// 是否被播放过
    public var played: Bool
    /// 是否被暂停播放(决定是否可以断点续播)
    public var pause: Bool
    /// 被暂停播放时的时间戳
    public var pauseWithTimestamp: TimeInterval
    /// 当前已播放时长
    public var currentPlayDuration: TimeInterval
    /// 语音转换后的文本
    public var voiceToText: String
    /// wav格式本地路径
    public var wavPath: String
    /// mp3格式本地路径
    public var mp3Path: String
    /// amr格式本地路径
    public var amrPath: String
    /// caf格式本地路径
    public var cafPath: String
    /// aac格式本地路
    public var aacPath: String

    public override convenience init() { self.init(WYChatVoiceModel()) }

    @nonobjc public init(_ value: WYChatVoiceModel) {
        self.id = value.id
        self.duration = value.duration
        self.played = value.played
        self.pause = value.pause
        self.pauseWithTimestamp = value.pauseWithTimestamp
        self.currentPlayDuration = value.currentPlayDuration
        self.voiceToText = value.voiceToText
        self.wavPath = value.wavPath
        self.mp3Path = value.mp3Path
        self.amrPath = value.amrPath
        self.cafPath = value.cafPath
        self.aacPath = value.aacPath
        self.isPlaying = value.isPlaying
        isRecognizing = value.isRecognizing
        recognitionError = value.recognitionError
        super.init()
    }

    @nonobjc public func toValue() -> WYChatVoiceModel {
        var value = WYChatVoiceModel()
        value.id = id
        value.duration = duration
        value.played = played
        value.pause = pause
        value.pauseWithTimestamp = pauseWithTimestamp
        value.currentPlayDuration = currentPlayDuration
        value.voiceToText = voiceToText
        value.wavPath = wavPath
        value.mp3Path = mp3Path
        value.amrPath = amrPath
        value.cafPath = cafPath
        value.aacPath = aacPath
        value.isPlaying = isPlaying
        value.isRecognizing = isRecognizing
        value.recognitionError = recognitionError
        return value
    }
}

@objc(WYChatWithdrawnModel)
@objcMembers public class WYChatWithdrawnModelObjC: NSObject {
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

    public override convenience init() { self.init(WYChatWithdrawnModel()) }

    @nonobjc public init(_ value: WYChatWithdrawnModel) {
        self.sendTime = value.sendTime
        self.withdrawalInterval = value.withdrawalInterval
        self.withdrawnTime = value.withdrawnTime
        self.content = value.content
        self.messageStyle = value.messageStyle
        super.init()
    }

    @nonobjc public func toValue() -> WYChatWithdrawnModel {
        var value = WYChatWithdrawnModel()
        value.sendTime = sendTime
        value.withdrawalInterval = withdrawalInterval
        value.withdrawnTime = withdrawnTime
        value.content = content
        value.messageStyle = messageStyle
        return value
    }
}

#endif
