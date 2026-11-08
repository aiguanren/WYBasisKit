//
//  WYChatMessageContentModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 聊天消息类型
@objc @frozen public enum WYChatMessageStyle: Int, Codable, CaseIterable {
    /// 未知
    case none
    /// 文本
    case text
    /// 语音
    case voice
    /// 照片
    case photo
    /// 音乐
    case music
    /// 视频
    case video
    /// 红包
    case luckyMoney
    /// 转账
    case transfer
    /// 位置
    case location
    /// 拍一拍
    case takePat
    /// 消息撤回
    case withdrawn
    /// 音视频通话
    case call
    /// 网页、小程序
    case webpage
    /// 文件
    case file
    /// 名片
    case businessCard
    /// 聊天记录(合集)
    case chatRecords
    
    /// 获取所有枚举属性
    public static func members() -> [WYChatMessageStyle] { Array(allCases) }

    internal var cellClass: AnyClass {
        switch self {
        case .none: return WYChatBasicCell.self
        case .text: return WYChatTextCell.self
        case .voice: return WYChatVoiceCell.self
        case .photo: return WYChatPhotoCell.self
        case .music: return WYChatMusicCell.self
        case .video: return WYChatVideoCell.self
        case .luckyMoney: return WYChatLuckyMoneyCell.self
        case .transfer: return WYChatTransferCell.self
        case .location: return WYChatLocationCell.self
        case .takePat: return WYChatTakePatCell.self
        case .withdrawn: return WYChatWithdrawnCell.self
        case .call: return WYChatCallCell.self
        case .webpage: return WYChatWebpageCell.self
        case .file: return WYChatFileCell.self
        case .businessCard: return WYChatBusinessCardCell.self
        case .chatRecords: return WYChatRecordsCell.self
        }
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

        if text != nil { return .text }
        if voice != nil { return .voice }
        if photo != nil { return .photo }
        if music != nil { return .music }
        if video != nil { return .video }
        if luckyMoney != nil { return .luckyMoney }
        if transfer != nil { return .transfer }
        if location != nil { return .location }
        if takePat != nil { return .takePat }
        if withdrawn != nil { return .withdrawn }
        if call != nil { return .call }
        if webpage != nil { return .webpage }
        if file != nil { return .file }
        if businessCard != nil { return .businessCard }
        if chatRecords != nil { return .chatRecords }
        return .none
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
