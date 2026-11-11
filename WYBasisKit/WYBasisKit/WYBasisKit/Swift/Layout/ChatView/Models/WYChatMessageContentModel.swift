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
    
    /// 合并图片和视频
    case mediaGroup

    /// 获取所有枚举属性
    public static func members() -> [WYChatMessageStyle] { Array(allCases) }

    internal var cellClass: AnyClass { registration.type }
    internal var makeCell: () -> WYChatBasicCell { registration.factory }

    private var registration: (type: AnyClass, factory: () -> WYChatBasicCell) {
        switch self {
        case .none: return Self.registration { WYChatBasicCell(style: .default, reuseIdentifier: nil) }
        case .text: return Self.registration { WYChatTextCell(style: .default, reuseIdentifier: nil) }
        case .voice: return Self.registration { WYChatVoiceCell(style: .default, reuseIdentifier: nil) }
        case .photo: return Self.registration { WYChatPhotoCell(style: .default, reuseIdentifier: nil) }
        case .music: return Self.registration { WYChatMusicCell(style: .default, reuseIdentifier: nil) }
        case .video: return Self.registration { WYChatVideoCell(style: .default, reuseIdentifier: nil) }
        case .luckyMoney: return Self.registration { WYChatLuckyMoneyCell(style: .default, reuseIdentifier: nil) }
        case .transfer: return Self.registration { WYChatTransferCell(style: .default, reuseIdentifier: nil) }
        case .location: return Self.registration { WYChatLocationCell(style: .default, reuseIdentifier: nil) }
        case .takePat: return Self.registration { WYChatTakePatCell(style: .default, reuseIdentifier: nil) }
        case .withdrawn: return Self.registration { WYChatWithdrawnCell(style: .default, reuseIdentifier: nil) }
        case .call: return Self.registration { WYChatCallCell(style: .default, reuseIdentifier: nil) }
        case .webpage: return Self.registration { WYChatWebpageCell(style: .default, reuseIdentifier: nil) }
        case .file: return Self.registration { WYChatFileCell(style: .default, reuseIdentifier: nil) }
        case .businessCard: return Self.registration { WYChatBusinessCardCell(style: .default, reuseIdentifier: nil) }
        case .chatRecords: return Self.registration { WYChatRecordsCell(style: .default, reuseIdentifier: nil) }
        case .mediaGroup: return Self.registration { WYChatMediaGroupCell(style: .default, reuseIdentifier: nil) }
        }
    }

    private static func registration<Cell: WYChatBasicCell>(_ factory: @escaping () -> Cell) -> (type: AnyClass, factory: () -> WYChatBasicCell) {
        (Cell.self, { factory() })
    }

}

/// 消息体
public struct WYChatMessageContentModel: Equatable {
    
    /// 文本
    public var text: String? {
        get { state.text?.value }
        set { wy_prepareContentStorage(); state.text = newValue.map(WYChatContentValue.init) }
    }
    
    /// 语音
    public var voice: WYChatVoiceModel? {
        get { state.voice?.value }
        set { wy_prepareContentStorage(); state.voice = newValue.map(WYChatContentValue.init) }
    }
    
    /// 照片
    public var photo: WYChatPhotoModel? {
        get { state.photo?.value }
        set { wy_prepareContentStorage(); state.photo = newValue.map(WYChatContentValue.init) }
    }
    
    /// 音乐
    public var music: WYChatMusicModel? {
        get { state.music?.value }
        set { wy_prepareContentStorage(); state.music = newValue.map(WYChatContentValue.init) }
    }
    
    /// 视频
    public var video: WYChatVideoModel? {
        get { state.video?.value }
        set { wy_prepareContentStorage(); state.video = newValue.map(WYChatContentValue.init) }
    }
    
    /// 红包
    public var luckyMoney: WYChatLuckyMoneyModel? {
        get { state.luckyMoney?.value }
        set { wy_prepareContentStorage(); state.luckyMoney = newValue.map(WYChatContentValue.init) }
    }
    
    /// 转账
    public var transfer: WYChatLuckyMoneyModel? {
        get { state.transfer?.value }
        set { wy_prepareContentStorage(); state.transfer = newValue.map(WYChatContentValue.init) }
    }
    
    /// 位置
    public var location: WYChatLocationModel? {
        get { state.location?.value }
        set { wy_prepareContentStorage(); state.location = newValue.map(WYChatContentValue.init) }
    }
    
    /// 拍一拍
    public var takePat: WYChatTakePatModel? {
        get { state.takePat?.value }
        set { wy_prepareContentStorage(); state.takePat = newValue.map(WYChatContentValue.init) }
    }
    
    /// 消息撤回
    public var withdrawn: WYChatWithdrawnModel? {
        get { state.withdrawn?.value }
        set { wy_prepareContentStorage(); state.withdrawn = newValue.map(WYChatContentValue.init) }
    }
    
    /// 音视频通话
    public var call: WYChatCallModel? {
        get { state.call?.value }
        set { wy_prepareContentStorage(); state.call = newValue.map(WYChatContentValue.init) }
    }
    
    /// 网页、小程序
    public var webpage: WYChatWebpageModel? {
        get { state.webpage?.value }
        set { wy_prepareContentStorage(); state.webpage = newValue.map(WYChatContentValue.init) }
    }
    
    /// 文件
    public var file: WYChatFileModel? {
        get { state.file?.value }
        set { wy_prepareContentStorage(); state.file = newValue.map(WYChatContentValue.init) }
    }
    
    /// 名片
    public var businessCard: WYChatBusinessCardModel? {
        get { state.businessCard?.value }
        set { wy_prepareContentStorage(); state.businessCard = newValue.map(WYChatContentValue.init) }
    }
    
    /// 聊天记录(合集)
    public var chatRecords: WYChatRecordsModel? {
        get { state.chatRecords?.value }
        set { wy_prepareContentStorage(); state.chatRecords = newValue.map(WYChatContentValue.init) }
    }
    
    /// 合并图片和视频
    public var mediaGroup: WYChatMediaGroupModel? {
        get { state.mediaGroup?.value }
        set { wy_prepareContentStorage(); state.mediaGroup = newValue.map(WYChatContentValue.init) }
    }

    /// 获取消息类型
    public func style() -> WYChatMessageStyle {

        if state.text != nil { return .text }
        if state.voice != nil { return .voice }
        if state.photo != nil { return .photo }
        if state.music != nil { return .music }
        if state.video != nil { return .video }
        if state.luckyMoney != nil { return .luckyMoney }
        if state.transfer != nil { return .transfer }
        if state.location != nil { return .location }
        if state.takePat != nil { return .takePat }
        if state.withdrawn != nil { return .withdrawn }
        if state.call != nil { return .call }
        if state.webpage != nil { return .webpage }
        if state.file != nil { return .file }
        if state.businessCard != nil { return .businessCard }
        if state.chatRecords != nil { return .chatRecords }
        if state.mediaGroup != nil { return .mediaGroup }
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
                chatRecords: WYChatRecordsModel? = nil,
                mediaGroup: WYChatMediaGroupModel? = nil) {
        state.text = text.map(WYChatContentValue.init)
        state.voice = voice.map(WYChatContentValue.init)
        state.photo = photo.map(WYChatContentValue.init)
        state.music = music.map(WYChatContentValue.init)
        state.video = video.map(WYChatContentValue.init)
        state.luckyMoney = luckyMoney.map(WYChatContentValue.init)
        state.transfer = transfer.map(WYChatContentValue.init)
        state.location = location.map(WYChatContentValue.init)
        state.takePat = takePat.map(WYChatContentValue.init)
        state.withdrawn = withdrawn.map(WYChatContentValue.init)
        state.call = call.map(WYChatContentValue.init)
        state.webpage = webpage.map(WYChatContentValue.init)
        state.file = file.map(WYChatContentValue.init)
        state.businessCard = businessCard.map(WYChatContentValue.init)
        state.chatRecords = chatRecords.map(WYChatContentValue.init)
        state.mediaGroup = mediaGroup.map(WYChatContentValue.init)
    }

    internal var state = WYChatContentStorage()

}
