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
            state.title.text = String(format: WYLocalized("%@拍了拍%@%@", table: WYBasisKitConfig.kitLocalizableTable), value.striking.name, value.beaten.name, value.notes)
        case .call:
            guard let value = message.content.call else { return }
            let video = value.callStyle == .oneToOneVideo || value.callStyle == .multipleVideos
            state.title.text = (video ? "▣  " : "☎  ") + (value.durationOfCall > 0 ? wy_duration(value.durationOfCall) : WYLocalized("通话未接通", table: WYBasisKitConfig.kitLocalizableTable))
        default: break
        }
        if wy_isNotice {
            state.title.textAlignment = .center
            state.title.font = messageContentConfiguration.detailFont
            state.title.textColor = messageContentConfiguration.detailColor
        } else {
            state.title.textAlignment = .natural
        }
    }
}
