//
//  WYChatTransferCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatTransferCellPrivateState {
    let fundsCaption = WYChatFundsCaptionView()
}

extension WYChatTransferCell {
    func wy_transferRender() {
        guard let value = message.content.transfer else { return }
        wy_renderFundsCard(value, isPacket: false, caption: transferState.fundsCaption)
    }
}

extension WYChatFundsReceiptCell {
    func wy_fundsReceiptRender() {
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
        wy_applyNoticeTextStyle()
    }
}
