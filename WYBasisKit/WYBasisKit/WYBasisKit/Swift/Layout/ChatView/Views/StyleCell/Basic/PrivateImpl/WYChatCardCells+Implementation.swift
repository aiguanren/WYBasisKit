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
            wy_showImage(value.cover, height: messageContentConfiguration.mediaSize.height * wy_chatNonnegative(messageContentConfiguration.webpageCoverHeightRatio))
        case .file:
            guard let value = message.content.file else { return }
            state.title.text = value.title.isEmpty ? value.name : value.title
            state.detail.text = value.size
            state.footer.text = value.name
            wy_showThumbnail(value.icon)
            if messageContentConfiguration.fileUsesTrailingIcon { wy_moveThumbnailToTrailing() }
        case .businessCard:
            guard let value = message.content.businessCard else { return }
            state.title.text = value.userInfo.name
            state.detail.text = value.remarks
            wy_showThumbnail(value.userInfo.avatar)
        case .chatRecords:
            guard let value = message.content.chatRecords else { return }
            wy_showMessageIcon("WYChatViewChatRecords")
            state.title.text = value.title
            state.detail.text = value.messages.prefix(max(1, messageContentConfiguration.detailNumberOfLines)).map {
                let summary = $0.content.wy_summary(provider: configuration.messageSummary, unsupportedText: configuration.unsupportedMessageText)
                return $0.sender.name + configuration.records.summarySenderSeparator + summary
            }.joined(separator: configuration.records.summaryLineSeparator)
            state.footer.text = value.remarks
        case .location:
            guard let value = message.content.location else { return }
            state.title.text = value.title.isEmpty ? value.address : value.title
            state.detail.text = state.title.text == value.address ? nil : value.address
            let radius = configuration.location.cornerRadius
            state.image.imageCornerRadius = radius.isFinite ? max(0, radius) : 0
            if configuration.location.showsPreviewBelowAddress, let index = bodyView.arrangedSubviews.firstIndex(of: state.image) {
                bodyView.removeArrangedSubview(state.header)
                bodyView.insertArrangedSubview(state.header, at: index)
            }
            wy_showImage(value.cover)
        case .luckyMoney, .transfer:
            guard let value = message.content.luckyMoney ?? message.content.transfer else { return }
            let isPacket = message.content.luckyMoney != nil
            let priority = isPacket ? value.remarks : value.amounts
            let secondary = isPacket ? value.amounts : value.remarks
            state.title.text = [priority, secondary, value.notes].first { !$0.isEmpty }
            if !isPacket, let amount = state.title.text, !value.amounts.isEmpty && amount == value.amounts {
                state.title.text = amount.first?.isNumber == true ? messageContentConfiguration.fundsAmountPrefix + amount : amount
            }
            let style = messageContentConfiguration
            if !isPacket && !secondary.isEmpty && secondary != state.title.text { state.detail.text = secondary }
            switch value.state {
            case .unreceived: state.footer.text = isPacket ? nil : style.fundsPendingTransferText
            case .received:
                if isPacket { state.footer.text = style.fundsReceivedText }
                else { state.footer.text = message.isSender(userID) ? style.fundsSentTransferReceivedText : style.fundsIncomingTransferReceivedText }
            case .timeout: state.footer.text = messageContentConfiguration.fundsExpiredText
            case .return: state.footer.text = messageContentConfiguration.fundsReturnedText
            }
            let iconName = isPacket ? "WYChatViewRedPacket" : "WYChatViewTransfer"
            let cover = value.smallCover
            if cover.name.isEmpty && cover.downloadPath.isEmpty && cover.localPath.isEmpty { wy_showMessageIcon(iconName) }
            else { wy_showThumbnail(cover) }
            if value.state == .received && (style.fundsReceivedIcon != nil || (!isPacket && style.iconImage == nil && cover.name.isEmpty && cover.downloadPath.isEmpty && cover.localPath.isEmpty)) {
                state.thumbnail.tintsImage = style.iconTintColor != nil
                state.thumbnail.image = style.fundsReceivedIcon ?? UIImage(systemName: "checkmark.circle")
            }
            let explicitTint = style.fundsIconTintColor ?? style.iconTintColor
            let isBuiltIn = style.iconImage == nil && cover.name.isEmpty && cover.downloadPath.isEmpty && cover.localPath.isEmpty
            let defaultTint = value.state == .unreceived ? style.fundsAvailableIconTintColor : style.fundsInactiveIconTintColor
            let tint = explicitTint ?? (isBuiltIn && style.usesDefaultIconTint ? defaultTint : nil)
            state.thumbnail.tintsImage = tint != nil
            state.thumbnail.tintColor = tint
            if let image = state.thumbnail.image {
                state.thumbnail.image = image.withRenderingMode(tint == nil ? .alwaysOriginal : .alwaysTemplate)
            }
            let iconSide = wy_chatNonnegative(style.fundsIconSide)
            state.thumbnailSize[0].constant = iconSide
            state.thumbnailSize[1].constant = iconSide
            let textColor = value.state == .unreceived ? style.fundsAvailableTextColor : style.fundsInactiveTextColor
            if let textColor {
                state.title.textColor = textColor
                state.detail.textColor = textColor
                state.footer.textColor = textColor
            }
            state.fundsCaption.text = value.notes.isEmpty ? (isPacket ? style.fundsPacketCaption : style.fundsTransferCaption) : value.notes
            state.fundsCaption.textAlignment = style.footerTextAlignment
            state.fundsCaption.font = style.detailFont
            state.fundsCaption.alpha = min(1, wy_chatNonnegative(style.fundsCaptionOpacity))
            state.fundsCaption.textColor = textColor ?? style.detailColor
            state.fundsCaption.isHidden = state.fundsCaption.text?.isEmpty ?? true
            let accent = style.iconTintColor ?? WYChatDefaultResources.iconTint(for: iconName)
            let opacity = value.state == .unreceived ? style.fundsAvailableIconBackgroundOpacity : style.fundsInactiveIconBackgroundOpacity
            state.thumbnail.backgroundColor = style.fundsIconBackgroundColor ?? accent?.withAlphaComponent(min(1, wy_chatNonnegative(opacity)))
            state.thumbnail.layer.cornerRadius = min(state.thumbnailSize[0].constant, state.thumbnailSize[1].constant) * min(0.5, wy_chatNonnegative(style.fundsIconCornerRadiusRatio))
        default: break
        }
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
