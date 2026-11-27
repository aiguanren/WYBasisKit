//
//  WYChatNoticeCells+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 提示与通话消息内容
extension WYChatBasicCell {
    func wy_renderNotice() {
        switch message.content.style() {
        case .withdrawn:
            let template = configuration.notice.wy_withdrawalTemplate(for: message, userID: userID)
            state.title.text = template.replacingOccurrences(of: "%@", with: message.sender.name)
            state.title.isHidden = template.isEmpty
            wy_renderReedit()
        case .takePat:
            guard let value = message.content.takePat else { return }
            if let template = configuration.notice.patText {
                state.title.text = template.replacingOccurrences(of: "{sender}", with: value.striking.name)
                    .replacingOccurrences(of: "{recipient}", with: value.beaten.name)
                    .replacingOccurrences(of: "{note}", with: value.notes)
            } else {
                state.title.text = String(format: WYLocalized("%@拍了拍%@%@", table: WYBasisKitConfig.kitLocalizableTable), value.striking.name, value.beaten.name, value.notes)
            }
            let font = messageContentConfiguration.detailFont
            state.preferredContentWidth = ceil(((state.title.text ?? "") as NSString).size(withAttributes: [.font: font]).width)
        case .fundsReceipt:
            guard let receipt = message.content.fundsReceipt else { return }
            let notice = configuration.notice
            let template: String
            if receipt.isRedPacket { template = receipt.isOriginalSender ? notice.fundsSentPacketReceiptText : notice.fundsIncomingPacketReceiptText }
            else { template = receipt.isOriginalSender ? notice.fundsSentTransferReceiptText : notice.fundsIncomingTransferReceiptText }
            let title = template.replacingOccurrences(of: "{actor}", with: receipt.actorName)
            let style = messageContentConfiguration
            let display = NSMutableAttributedString(string: title, attributes: [.font: style.detailFont, .foregroundColor: style.detailColor])
            let keyword = receipt.isRedPacket ? style.fundsPacketCaption : style.fundsTransferCaption
            let range = (title as NSString).range(of: keyword, options: .backwards)
            if !keyword.isEmpty, range.location != NSNotFound, let accent = notice.fundsReceiptAccentColor {
                display.addAttribute(.foregroundColor, value: accent, range: range)
            }
            state.title.attributedText = display
            if let icon = style.iconImage ?? (receipt.isRedPacket ? notice.fundsPacketReceiptImage : notice.fundsTransferReceiptImage) {
                state.usesThumbnail = true
                let side = wy_chatNonnegative(notice.fundsReceiptIconSide)
                state.thumbnailSize[0].constant = side
                state.thumbnailSize[1].constant = side
                let tint = style.iconTintColor ?? (receipt.isRedPacket ? notice.fundsPacketReceiptTintColor : notice.fundsTransferReceiptTintColor)
                state.thumbnail.tintsImage = tint != nil
                state.thumbnail.tintColor = tint
                state.thumbnail.image = icon.withRenderingMode(tint == nil ? .alwaysOriginal : .alwaysTemplate)
            }
            state.preferredContentWidth = ceil(display.size().width) + (state.usesThumbnail ? state.thumbnailSize[0].constant + state.header.spacing : 0)
        case .call:
            guard let value = message.content.call else { return }
            let video = value.callStyle == .oneToOneVideo || value.callStyle == .multipleVideos
            wy_showMessageIcon(video ? "WYChatViewVideoCall" : "WYChatViewAudioCall")
            if configuration.notice.outgoingCallIconOnTrailing && message.isSender(userID) { wy_moveThumbnailToTrailing() }
            state.title.text = value.durationOfCall > 0
                ? configuration.notice.callDurationText.replacingOccurrences(of: "{duration}", with: wy_duration(value.durationOfCall))
                : configuration.notice.unconnectedCallText
        default: break
        }
        if wy_isNotice {
            state.title.textAlignment = configuration.notice.centeredTextAlignment
            state.title.font = messageContentConfiguration.detailFont
            state.title.textColor = messageContentConfiguration.detailColor
        } else {
            state.title.textAlignment = messageContentConfiguration.titleTextAlignment
        }
    }
}

/// 居中显示红包或转账回执。
public final class WYChatFundsReceiptCell: WYChatBasicCell {
    public override func renderContent() { wy_renderNotice() }
}
