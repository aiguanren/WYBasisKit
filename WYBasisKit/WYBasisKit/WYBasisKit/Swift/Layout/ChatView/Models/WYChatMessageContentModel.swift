//
//  WYChatMessageContentModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

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

/// 消息体
public struct WYChatMessageContentModel {
    
    /// 文本
    public var text: String?
    
    /// 语音
    public var voice: WYChatVoiceModel?
    
    /// 照片
    public var photo: WYChatPhotoModel?
    
    /// 音乐
    public var music: WYChatMusicModel?
    
    /// 视频
    public var video: WYChatVideoModel?
    
    /// 红包
    public var luckyMoney: WYChatLuckyMoneyModel?
    
    /// 转账
    public var transfer: WYChatLuckyMoneyModel?
    
    /// 位置
    public var location: WYChatLocationModel?
    
    /// 拍一拍
    public var takePat: WYChatTakePatModel?
    
    /// 消息撤回
    public var withdrawn: WYChatWithdrawnModel?
    
    /// 音视频通话
    public var call: WYChatCallModel?
    
    /// 网页、小程序
    public var webpage: WYChatWebpageModel?
    
    /// 文件
    public var file: WYChatFileModel?
    
    /// 名片
    public var businessCard: WYChatBusinessCardModel?
    
    /// 聊天记录(合集)
    public var chatRecords: WYChatRecordsModel?
    
    /// 获取消息类型
    public func style() -> WYChatMessageStyle {

        let index: Int = [nil, text, voice, photo, music, video, luckyMoney, transfer, location, takePat, withdrawn, call, webpage, file, businessCard, chatRecords].firstIndex(where: { $0 != nil }) ?? 0
        return WYChatMessageStyle.members()[index]
    }
    
    /// 初始化方法
    public init(text: String? = nil,
                voice: WYChatVoiceModel? = nil,
                photo: WYChatPhotoModel? = nil,
                music: WYChatMusicModel? = nil,
                video: WYChatVideoModel? = nil,
                luckyMoney: WYChatLuckyMoneyModel? = nil,
                transfer: WYChatLuckyMoneyModel? = nil,
                location: WYChatLocationModel? = nil,
                takePat: WYChatTakePatModel? = nil,
                withdrawn: WYChatWithdrawnModel? = nil,
                call: WYChatCallModel? = nil,
                webpage: WYChatWebpageModel? = nil,
                file: WYChatFileModel? = nil,
                businessCard: WYChatBusinessCardModel? = nil,
                chatRecords: WYChatRecordsModel? = nil) {
        self.text = text
        self.voice = voice
        self.photo = photo
        self.music = music
        self.video = video
        self.luckyMoney = luckyMoney
        self.transfer = transfer
        self.location = location
        self.takePat = takePat
        self.withdrawn = withdrawn
        self.call = call
        self.webpage = webpage
        self.file = file
        self.businessCard = businessCard
        self.chatRecords = chatRecords
    }
}
