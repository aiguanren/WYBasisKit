//
//  WYChatMessageContentModel+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatMessageStyle {
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
        case .fundsReceipt: return Self.registration { WYChatFundsReceiptCell(style: .default, reuseIdentifier: nil) }
        case .mediaGroup: return Self.registration { WYChatMediaGroupCell(style: .default, reuseIdentifier: nil) }
        }
    }

    private static func registration<Cell: WYChatBasicCell>(_ factory: @escaping () -> Cell) -> (type: AnyClass, factory: () -> WYChatBasicCell) {
        (Cell.self, { factory() })
    }
}

extension WYChatMessageContentModel {
    func wy_summary(provider: ((WYChatMessageContentModel) -> String?)?, unsupportedText: String) -> String {
        if let text = provider?(self) { return text }
        if let text { return text }
        if let value = voice { return value.voiceToText.isEmpty ? WYLocalized("[语音]", table: WYBasisKitConfig.kitLocalizableTable) : value.voiceToText }
        if let mediaGroup {
            let photo = WYLocalized("[图片]", table: WYBasisKitConfig.kitLocalizableTable)
            let video = WYLocalized("[视频]", table: WYBasisKitConfig.kitLocalizableTable)
            let title = mediaGroup.items.allSatisfy { $0.kind == .video } ? video : mediaGroup.items.allSatisfy { $0.kind == .photo } ? photo : photo + "/" + video
            return title + " (\(mediaGroup.items.count))"
        }
        if photo != nil { return WYLocalized("[图片]", table: WYBasisKitConfig.kitLocalizableTable) }
        if video != nil { return WYLocalized("[视频]", table: WYBasisKitConfig.kitLocalizableTable) }
        if let music { return music.name }
        if let file { return file.title.isEmpty ? file.name : file.title }
        if let location { return location.title }
        if let webpage { return webpage.title }
        if let businessCard { return businessCard.userInfo.name }
        if let chatRecords { return chatRecords.title }
        if let value = luckyMoney ?? transfer { return value.remarks }
        if withdrawn != nil { return WYLocalized("消息已撤回", table: WYBasisKitConfig.kitLocalizableTable) }
        if fundsReceipt != nil { return WYLocalized("收款回执", table: WYBasisKitConfig.kitLocalizableTable) }
        if takePat != nil { return WYLocalized("拍一拍", table: WYBasisKitConfig.kitLocalizableTable) }
        if call != nil { return WYLocalized("通话记录", table: WYBasisKitConfig.kitLocalizableTable) }
        return unsupportedText
    }
}
