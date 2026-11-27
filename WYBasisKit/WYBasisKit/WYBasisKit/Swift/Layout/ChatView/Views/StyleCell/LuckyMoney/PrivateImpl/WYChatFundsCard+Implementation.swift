//
//  WYChatFundsCard+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 红包和转账共用的卡片内容。
extension WYChatBasicCell {
    func wy_fundsBubbleColor(_ value: WYChatLuckyMoneyModel?) -> UIColor? {
        guard let value else { return nil }
        let style = messageContentConfiguration
        return value.state == .unreceived ? style.fundsAvailableBubbleColor : style.fundsInactiveBubbleColor
    }

    func wy_renderFundsCard(_ value: WYChatLuckyMoneyModel, isPacket: Bool, caption: WYChatFundsCaptionView) {
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
        else { wy_showThumbnail(cover, usesIconSize: true) }
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
        caption.label.text = value.notes.isEmpty ? (isPacket ? style.fundsPacketCaption : style.fundsTransferCaption) : value.notes
        caption.label.textAlignment = style.footerTextAlignment
        caption.label.font = style.detailFont
        caption.label.alpha = min(1, wy_chatNonnegative(style.fundsCaptionOpacity))
        caption.label.textColor = textColor ?? style.detailColor
        caption.isHidden = caption.label.text?.isEmpty ?? true
        let opacity = value.state == .unreceived ? style.fundsAvailableIconBackgroundOpacity : style.fundsInactiveIconBackgroundOpacity
        state.thumbnail.backgroundColor = style.fundsIconBackgroundColor ?? UIColor.white.withAlphaComponent(min(1, wy_chatNonnegative(opacity)))
        state.thumbnail.layer.cornerRadius = min(state.thumbnailSize[0].constant, state.thumbnailSize[1].constant) * min(0.5, wy_chatNonnegative(style.fundsIconCornerRadiusRatio))
    }
}

/// 红包、转账的底部文字与距气泡左侧的距离。
final class WYChatFundsCaptionView: UIView {
    let label = UILabel()
    private lazy var left = label.leftAnchor.constraint(equalTo: leftAnchor)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            left,
            label.rightAnchor.constraint(equalTo: rightAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func install(in cell: WYChatBasicCell) {
        guard let index = cell.bodyView.arrangedSubviews.firstIndex(of: cell.state.inlineProgress) else { return }
        cell.bodyView.insertArrangedSubview(self, at: index)
    }

    func layout(in cell: WYChatBasicCell, width: CGFloat) {
        guard !isHidden else { return }
        let insets = cell.state.bodyInsets
        let bodyLeftInset = cell.bodyView.effectiveUserInterfaceLayoutDirection == .rightToLeft ? -insets[3].constant : insets[1].constant
        let leftInset = cell.messageContentConfiguration.fundsCaptionLeftInset
        let proposed = leftInset.isFinite && leftInset >= 0 ? leftInset - bodyLeftInset : 0
        let captionWidth = min(width, cell.state.preferredWidth?.constant ?? width)
        left.constant = min(captionWidth - 1, proposed)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        label.sizeThatFits(CGSize(width: max(1, size.width - left.constant), height: size.height))
    }
}
