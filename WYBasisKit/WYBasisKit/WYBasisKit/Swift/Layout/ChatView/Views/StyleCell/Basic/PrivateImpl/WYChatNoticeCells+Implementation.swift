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
            let isPat = message.content.withdrawn?.messageStyle == .takePat
            let template = isPat && !configuration.notice.patWithdrawnText.isEmpty ? configuration.notice.patWithdrawnText : configuration.notice.withdrawnText
            state.title.text = template.replacingOccurrences(of: "%@", with: message.sender.name)
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
        case .call:
            guard let value = message.content.call else { return }
            let video = value.callStyle == .oneToOneVideo || value.callStyle == .multipleVideos
            wy_showMessageIcon(video ? "WYChatViewVideoCall" : "WYChatViewAudioCall")
            state.title.text = value.durationOfCall > 0 ? wy_duration(value.durationOfCall) : configuration.notice.unconnectedCallText
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
