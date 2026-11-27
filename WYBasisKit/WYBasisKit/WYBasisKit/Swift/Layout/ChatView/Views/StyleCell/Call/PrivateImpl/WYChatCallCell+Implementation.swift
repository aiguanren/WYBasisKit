//
//  WYChatCallCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatCallCell {
    func wy_callRender() {
        guard let value = message.content.call else { return }
        let video = value.callStyle == .oneToOneVideo || value.callStyle == .multipleVideos
        wy_showMessageIcon(video ? "WYChatViewVideoCall" : "WYChatViewAudioCall")
        if configuration.notice.outgoingCallIconOnTrailing && message.isSender(userID) { wy_moveThumbnailToTrailing() }
        state.title.text = value.durationOfCall > 0
            ? configuration.notice.callDurationText.replacingOccurrences(of: "{duration}", with: wy_duration(value.durationOfCall))
            : configuration.notice.unconnectedCallText
        state.title.textAlignment = messageContentConfiguration.titleTextAlignment
    }
}
