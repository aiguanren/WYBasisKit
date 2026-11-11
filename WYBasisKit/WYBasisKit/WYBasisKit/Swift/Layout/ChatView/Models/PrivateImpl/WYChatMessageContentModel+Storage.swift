//
//  WYChatMessageContentModel+Storage.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/9.
//

import Foundation

/// 不可变的消息内容
final class WYChatContentValue<Value: Equatable>: Equatable {
    let value: Value

    init(_ value: Value) { self.value = value }

    static func == (lhs: WYChatContentValue, rhs: WYChatContentValue) -> Bool { lhs === rhs || lhs.value == rhs.value }
}

/// 消息体的按需存储
final class WYChatContentStorage: Equatable {
    var text: WYChatContentValue<String>?
    var voice: WYChatContentValue<WYChatVoiceModel>?
    var photo: WYChatContentValue<WYChatPhotoModel>?
    var music: WYChatContentValue<WYChatMusicModel>?
    var video: WYChatContentValue<WYChatVideoModel>?
    var luckyMoney: WYChatContentValue<WYChatLuckyMoneyModel>?
    var transfer: WYChatContentValue<WYChatLuckyMoneyModel>?
    var location: WYChatContentValue<WYChatLocationModel>?
    var takePat: WYChatContentValue<WYChatTakePatModel>?
    var withdrawn: WYChatContentValue<WYChatWithdrawnModel>?
    var call: WYChatContentValue<WYChatCallModel>?
    var webpage: WYChatContentValue<WYChatWebpageModel>?
    var file: WYChatContentValue<WYChatFileModel>?
    var businessCard: WYChatContentValue<WYChatBusinessCardModel>?
    var chatRecords: WYChatContentValue<WYChatRecordsModel>?
    var mediaGroup: WYChatContentValue<WYChatMediaGroupModel>?

    func copy() -> WYChatContentStorage {
        let result = WYChatContentStorage()
        result.text = text
        result.voice = voice
        result.photo = photo
        result.music = music
        result.video = video
        result.luckyMoney = luckyMoney
        result.transfer = transfer
        result.location = location
        result.takePat = takePat
        result.withdrawn = withdrawn
        result.call = call
        result.webpage = webpage
        result.file = file
        result.businessCard = businessCard
        result.chatRecords = chatRecords
        result.mediaGroup = mediaGroup
        return result
    }

    static func == (lhs: WYChatContentStorage, rhs: WYChatContentStorage) -> Bool {
        if lhs === rhs { return true }
        return lhs.text == rhs.text
            && lhs.voice == rhs.voice
            && lhs.photo == rhs.photo
            && lhs.music == rhs.music
            && lhs.video == rhs.video
            && lhs.luckyMoney == rhs.luckyMoney
            && lhs.transfer == rhs.transfer
            && lhs.location == rhs.location
            && lhs.takePat == rhs.takePat
            && lhs.withdrawn == rhs.withdrawn
            && lhs.call == rhs.call
            && lhs.webpage == rhs.webpage
            && lhs.file == rhs.file
            && lhs.businessCard == rhs.businessCard
            && lhs.chatRecords == rhs.chatRecords
            && lhs.mediaGroup == rhs.mediaGroup
    }
}

extension WYChatMessageContentModel {
    mutating func wy_prepareContentStorage() {
        if !isKnownUniquelyReferenced(&state) { state = state.copy() }
    }
}
