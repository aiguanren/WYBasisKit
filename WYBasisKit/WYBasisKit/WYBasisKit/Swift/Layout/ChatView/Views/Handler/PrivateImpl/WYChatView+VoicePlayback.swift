//
//  WYChatView+VoicePlayback.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 语音倍速的有效选项与消息更新
func wy_chatPlaybackRates(_ configuration: WYChatVoicePlaybackConfig) -> [Float] {
    var seen = Set<Float>()
    return configuration.rates.filter { $0.isFinite && $0 > 0 && seen.insert($0).inserted }
}

extension WYChatView {
    func wy_setVoicePlaybackRate(_ rate: Float, messageID: String) -> Bool {
        guard rate.isFinite, wy_chatPlaybackRates(configuration.voicePlayback).contains(rate),
              let row = dataSource.firstIndex(where: { $0.messageID == messageID }), let voice = dataSource[row].content.voice else { return false }
        if voice.playbackRate == rate { return true }
        guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: .playbackRate, messageID: messageID) ?? true else { return false }
        dataSource[row].content.voice?.playbackRate = rate
        voicePlaybackRateHandler?(messageID, rate)
        actionHandler?(self, .playbackRate, messageID)
        delegate?.wy_voicePlaybackRateChanged?(self, messageID: messageID, rate: rate)
        delegate?.wy_messageAction?(self, action: .playbackRate, messageID: messageID)
        return true
    }
}
