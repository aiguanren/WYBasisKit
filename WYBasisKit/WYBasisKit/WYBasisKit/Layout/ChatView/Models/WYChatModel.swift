//
//  WYChatModel.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/16.
//

import Foundation

/// 消息撤回时长最大间隔时间(单位秒)
public var messageWithdrawalInterval: TimeInterval = 120

/// 聊天消息类型
@frozen public enum WYChatMessageStyle: String, Codable {
    /// 未知
    case none = "WYChatBasicCell"
    /// 文本
    case text = "WYChatTextCell"
    /// 语音
    case voice = "WYChatVoiceCell"
    /// 照片
    case photo = "WYChatPhotoCell"
    /// 音乐
    case music = "WYChatMusicCell"
    /// 视频
    case video = "WYChatVideoCell"
    /// 红包
    case luckyMoney = "WYChatLuckyMoneyCell"
    /// 转账
    case transfer = "WYChatTransferCell"
    /// 位置
    case location = "WYChatLocationCell"
    /// 拍一拍
    case takePat = "WYChatTakePatCell"
    /// 消息撤回
    case withdrawn = "WYChatWithdrawnCell"
    /// 音视频通话
    case call = "WYChatCallCell"
    /// 网页、小程序
    case webpage = "WYChatWebpageCell"
    /// 文件
    case file = "WYChatFileCell"
    /// 名片
    case businessCard = "WYChatBusinessCardCell"
    /// 聊天记录(合集)
    case chatRecords = "WYChatRecordsCell"
    
    /// 获取所有枚举属性
    public static func members() -> [WYChatMessageStyle] {
        return [.none, .text, .voice, .photo, .music, .video, .luckyMoney, .transfer, .location, .takePat, .withdrawn, .call, .webpage, .file, .businessCard, .chatRecords]
    }
}

/// 红包、转账收款状态
@frozen public enum WYChatFundsState: Int {
    
    /// 待收款
    case unreceived = 0
    
    /// 已收款
    case received
    
    /// 超时退回
    case timeout
    
    /// 用户退回
    case `return`
}

/// 通话类型
@frozen public enum WYChatCallStyle: Int {
    
    /// 一对一语音
    case oneToOneVoice = 0
    
    /// 一对一视屏
    case oneToOneVideo
    
    /// 多人语音
    case multipleVoices
    
    /// 多人视频
    case multipleVideos
}

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

/// 图片、视频等资源文件相关信息
public class WYChatAssetsModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 名字
    public var name: String = ""
    
    /// 网络下载地址
    public var downloadPath: String = ""
    
    /// 本地文件路径
    public var localPath: String = ""
}

/// 语音消息Model
public class WYChatVoiceModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 语音时长
    public var duration: TimeInterval = 0
    
    /// 是否被播放过
    public var played: Bool = false
    
    /// 是否被暂停播放(决定是否可以断点续播)
    public var pause: Bool = false
    
    /// 被暂停播放时的时间戳
    public var pauseWithTimestamp: TimeInterval = 0
    
    /// 当前已播放时长
    public var currentPlayDuration: TimeInterval = 0
    
    /// 语音转换后的文本
    public var voiceToText: String = ""
    
    /// wav格式本地路径
    public var wavPath: String = ""
    
    /// mp3格式本地路径
    public var mp3Path: String = ""
    
    /// amr格式本地路径
    public var amrPath: String = ""
    
    /// caf格式本地路径
    public var cafPath: String = ""
    
    /// aac格式本地路
    public var aacPath: String = ""
}

/// 照片消息Model
public class WYChatPhotoModel: NSObject {
    
    /// 原图
    public var original: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 缩略图
    public var thumbnail: WYChatAssetsModel = WYChatAssetsModel()
}

/// 音乐消息Model
public class WYChatMusicModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 音乐名
    public var name: String = ""
    
    /// 作曲家
    public var composer: String = ""
    
    /// 演唱者
    public var singer: String = ""
    
    /// 音乐时长
    public var duration: TimeInterval = 0
    
    /// 当前已播放时长
    public var playedDuration: TimeInterval = 0
    
    /// 播放地址
    public var playPath: String = ""
    
    /// 封面
    public var cover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModel = WYChatAssetsModel()
}

/// 视频消息Model
public class WYChatVideoModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 封面
    public var cover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 视频
    public var video: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 视频时长
    public var duration: TimeInterval = 0
    
    /// 当前播放时长
    public var playedDuration: TimeInterval = 0
}

/// 红包消息Model
public class WYChatLuckyMoneyModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 大封面
    public var fullCover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 小封面
    public var smailCover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 封面视频
    public var coverVideo: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 金额
    public var amounts: String = ""
    
    /// 红包个数(1为个人红包，否则为多人红包)
    public var numberOfLuckyMoney: NSInteger = 1
    
    /// 已抢红包个数
    public var numberOfRobbed: NSInteger = 0
    
    /// 红包已抢金额
    public var amountsStolen: Double = 0
    
    /// 收款状态
    public var state: WYChatFundsState = .unreceived
    
    /// 备注
    public var remarks: String = ""
    
    /// 说明(xx红包)
    public var notes: String = ""
}

/// 定位消息Model
public class WYChatLocationModel: NSObject {
    
    /// 定位封面
    public var cover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 定位标题
    public var title: String = ""
    
    /// 定位详细地址
    public var address: String = ""
    
    /// 定位经度
    public var longitude: String = ""
    
    /// 定位纬度
    public var latitude: String = ""
}

/// 拍一拍model
public class WYChatTakePatModel: NSObject {
    
    /// 拍人者
    public var striking: WYChatUaerModel = WYChatUaerModel()
    
    /// 被拍者
    public var beaten: WYChatUaerModel = WYChatUaerModel()
    
    /// 被拍者拍一拍设置
    public var notes: String = ""
}

/// 消息撤回model
public class WYChatWithdrawnModel: NSObject {
    
    /// 发送时间
    public var sendTime: String = ""
    
    /// 可撤回时长间隔
    public var withdrawalInterval: TimeInterval = messageWithdrawalInterval
    
    /// 撤回时间
    public var withdrawnTime: String = ""
    
    /// 消息内容
    public var content: Data = Data()
    
    /// 消息类型
    public var messageStyle: WYChatMessageStyle = .none
}

/// 音视频通话model
public class WYChatCallModel: NSObject {
    
    /// 通话时长
    public var durationOfCall: TimeInterval = 0
    
    /// 通话类型
    public var callStyle: WYChatCallStyle = .oneToOneVoice
    
    /// 通话发起者信息
    public var promoter: WYChatUaerModel = WYChatUaerModel()
    
    /// 通话成员信息(一对一通话时只有一个成员)
    public var members: [WYChatUaerModel] = []
}

/// 网页、小程序model
public class WYChatWebpageModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 封面
    public var cover: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 标题
    public var title: String = ""
    
    /// 描述
    public var remarks: String = ""
    
    /// 头像
    public var avatar: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 名称
    public var name: String = ""
    
    /// 内容链接
    public var path: String = ""
}

/// 文件model
public class WYChatFileModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 标题
    public var title: String = ""
    
    /// icon
    public var icon: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 大小(占用内存，如xxkb,xxmb)
    public var size: String = ""
    
    /// 名称
    public var name: String = ""
    
    /// 头像
    public var avatar: WYChatAssetsModel = WYChatAssetsModel()
}

/// 名片model
public class WYChatBusinessCardModel: NSObject {
    
    /// id
    public var id: String = ""
    
    /// 用户信息
    public var userInfo: WYChatUaerModel = WYChatUaerModel()
    
    /// 描述
    public var remarks: String = ""
}

/// 聊天记录(合集)model
public class WYChatRecordsModel: NSObject {
    
    /// 标题(xxx的聊天记录)
    public var title: String = ""
    
    /// 消息合集
    public var messages: [WYChatMessageModel] = []
    
    /// 备注
    public var remarks: String = ""
}

/// 消息体
public class WYChatMeesageContentModel: NSObject {
    
    /// 文本
    public var text: String? = nil
    
    /// 语音
    public var voice: WYChatVoiceModel? = nil
    
    /// 照片
    public var photo: WYChatPhotoModel? = nil
    
    /// 音乐
    public var music: WYChatMusicModel? = nil
    
    /// 视频
    public var video: WYChatVideoModel? = nil
    
    /// 红包
    public var luckyMoney: WYChatLuckyMoneyModel? = nil
    
    /// 转账
    public var transfer: WYChatLuckyMoneyModel? = nil
    
    /// 位置
    public var location: WYChatLocationModel? = nil
    
    /// 拍一拍
    public var takePat: WYChatTakePatModel? = nil
    
    /// 消息撤回
    public var withdrawn: WYChatWithdrawnModel? = nil
    
    /// 音视频通话
    public var call: WYChatCallModel? = nil
    
    /// 网页、小程序
    public var webpage: WYChatWebpageModel? = nil
    
    /// 文件
    public var file: WYChatFileModel? = nil
    
    /// 名片
    public var businessCard: WYChatBusinessCardModel? = nil
    
    /// 聊天记录(合集)
    public var chatRecords: WYChatRecordsModel? = nil
    
    /// 获取消息类型
    public func style() -> WYChatMessageStyle {

        let index: NSInteger = [nil, text, voice, photo, music, video, luckyMoney, transfer, location, takePat, withdrawn, call, webpage, file, businessCard, chatRecords].firstIndex(where: { $0 != nil }) ?? 0
        return WYChatMessageStyle.members()[index]
    }
}

/// 聊天用户model
public class WYChatUaerModel: NSObject {
    
    /// 用户id
    public var id: String = ""
    
    /// 用户名
    public var name: String = ""
    
    /// 用户昵称
    public var nickname: String = ""
    
    /// 用户备注
    public var remarks: String = ""
    
    /// 用户签名
    public var signature: String = ""
    
    /// 用户所在地区
    public var area: String = ""
    
    /// 用户聊天列表
    public var listOfSessions: [WYChatSessionModel] = []
    
    /// 加入的群
    public var groups: [WYChatGroupModel] = []
    
    /// 用户二维码
    public var qrCode: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 用户头像
    public var avatar: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 用户头像缩略图
    public var thumbnailAvatar: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 更多信息
    public var moreInfo: Data? = nil
    
    /// model在数组中对应的下标
    public var index: NSInteger = 0
}

/// 群聊Model
public class WYChatGroupModel: NSObject {
    
    /// 群ID
    public var id: String = ""
    
    /// 用户在群内的昵称
    public var nickname: String = ""
    
    /// 群主信息
    public var ownerInfo: WYChatUaerModel = WYChatUaerModel()
    
    /// 群名称
    public var name: String = ""
    
    /// 群头像
    public var avatar: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 群头像缩略图
    public var thumbnailAvatar: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 是否开启了消息免打扰(0未开启，1已开启)
    public var silence: String = "0"
    
    /// 群公告
    public var publicity: String = ""
    
    /// 用户给群设置的备注
    public var remarks: String = ""
    
    /// 群二维码
    public var qrCode: WYChatAssetsModel = WYChatAssetsModel()
    
    /// 群管理信息
    public var managers: [WYChatUaerModel] = []
    
    /// 群成员信息
    public var members: [WYChatUaerModel] = []
    
    /// model在数组中对应的下标
    public var index: NSInteger = 0
}

/// 聊天model
public class WYChatSessionModel: NSObject {
    
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String = ""
    
    /// 最后一条消息
    public var lastMessage: WYChatMessageModel?
    
    /// 未读消息的ID列表
    public var unreadMessages: [String] = []
}

/// 消息model
public class WYChatMessageModel: NSObject {
    
    /// 打招呼的消息说明(如果该条消息是打招呼的消息，则会判断这个字段是否为空，不为空的话就会显示提示信息，如：以上是打招呼的内容)
    public var greetingDescription: String = ""
    
    /**
     *  消息已读人数
     *  单聊时  0未读，1已读
     *  群聊时  若已读人数等于群人数则表示全部已读，否则为群内已读人数
     */
    public var readers: String = ""

    /// 已读回执发送状态
    public var readBackState: WYChatMessageSendState = .notSent

    /// 消息发送状态
    public var sendState: WYChatMessageSendState = .notSent

    /// 消息ID
    public var messageID: String = ""
    
    /// 会话ID(用户ID或者群ID)
    public var sessionID: String = ""
    
    /// 当前客户端时间(依据此字段来计算消息发送时间和当前时间的间距，默认设备本地时间戳)
    public var clientTimestamp: String?
    
    /// 上一次显示时间的那一条消息对应的时间(如果是第一条消息，则会出现为空的情况)
    public var lastMessageTimestamp: String = ""

    /// 消息发送时间
    public var timestamp: String = ""
    
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
    public var sendor: WYChatUaerModel = WYChatUaerModel()

    /// 消息所属群信息(若为空为单聊，否则为群聊)
    public var group: WYChatGroupModel? = nil

    /// 消息内容
    public var content: WYChatMeesageContentModel = WYChatMeesageContentModel()
    
    /// 引用消息
    public var reference: WYChatMeesageContentModel? = nil
    
    /// model在数组中对应的下标
    public var index: NSInteger = 0

    /**
     *  查看某人是否是该条消息的发送者
     *  userID 某人的ID
     */
    public func isSender(_ userID: String) ->Bool {
        return (userID == sendor.id)
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
}
