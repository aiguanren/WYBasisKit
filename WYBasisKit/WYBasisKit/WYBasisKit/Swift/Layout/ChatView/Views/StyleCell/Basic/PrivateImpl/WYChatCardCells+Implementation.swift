//
//  WYChatCardCells+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 卡片消息内容
extension WYChatBasicCell {
    func wy_renderCard() {
        switch message.content.style() {
        case .webpage:
            guard let value = message.content.webpage else { return }
            state.title.text = value.title
            state.detail.text = value.remarks
            state.footer.text = value.name
            wy_showImage(value.cover, height: messageContentConfiguration.mediaSize.height / 2)
        case .file:
            guard let value = message.content.file else { return }
            state.title.text = value.title.isEmpty ? value.name : value.title
            state.detail.text = value.size
            state.footer.text = value.name
            wy_showThumbnail(value.icon)
        case .businessCard:
            guard let value = message.content.businessCard else { return }
            state.title.text = value.userInfo.name
            state.detail.text = value.remarks
            wy_showThumbnail(value.userInfo.avatar)
        case .chatRecords:
            guard let value = message.content.chatRecords else { return }
            state.title.text = value.title
            state.detail.text = value.messages.prefix(max(1, messageContentConfiguration.detailNumberOfLines)).map { $0.sender.name + ": " + $0.content.wy_summary }.joined(separator: "\n")
            state.footer.text = value.remarks
        case .location:
            guard let value = message.content.location else { return }
            state.title.text = value.title
            state.detail.text = value.address
            wy_showImage(value.cover)
        case .luckyMoney, .transfer:
            guard let value = message.content.luckyMoney ?? message.content.transfer else { return }
            state.title.text = value.remarks.isEmpty ? value.amounts : value.remarks
            switch value.state {
            case .unreceived: state.detail.text = value.notes
            case .received: state.detail.text = WYLocalized("已领取", table: WYBasisKitConfig.kitLocalizableTable)
            case .timeout: state.detail.text = WYLocalized("已过期", table: WYBasisKitConfig.kitLocalizableTable)
            case .return: state.detail.text = WYLocalized("已退回", table: WYBasisKitConfig.kitLocalizableTable)
            }
            state.footer.text = value.amounts
            if !value.smallCover.downloadPath.isEmpty || !value.smallCover.localPath.isEmpty { wy_showThumbnail(value.smallCover) }
        default: break
        }
    }
}

extension WYChatMessageContentModel {
    var wy_summary: String {
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
        if takePat != nil { return WYLocalized("拍一拍", table: WYBasisKitConfig.kitLocalizableTable) }
        if call != nil { return WYLocalized("通话记录", table: WYBasisKitConfig.kitLocalizableTable) }
        return WYLocalized("不支持的消息类型", table: WYBasisKitConfig.kitLocalizableTable)
    }
}
