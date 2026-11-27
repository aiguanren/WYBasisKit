//
//  WYChatVoiceCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatVoiceCellPrivateState {
    let voiceRateButton = UIButton(type: .system)
    let voiceUnreadView = UIView()
    var voiceUnreadSize: [NSLayoutConstraint] = []
    var voiceUnreadLeading: NSLayoutConstraint?
    var voiceRateWidth: NSLayoutConstraint?
    var voiceRateHeight: NSLayoutConstraint?
}

extension WYChatVoiceCell {
    func wy_voiceReset() {
        voiceState.voiceUnreadView.isHidden = true
        voiceState.voiceRateButton.isHidden = true
        voiceState.voiceRateButton.menu = nil
        state.title.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    func wy_voiceMeasure(_ view: UIView, width: CGFloat) -> CGSize? {
        guard view === voiceState.voiceRateButton else { return nil }
        return CGSize(width: voiceState.voiceRateWidth?.constant ?? 0, height: voiceState.voiceRateHeight?.constant ?? 0)
    }

    func wy_voiceRender() {
        guard let value = message.content.voice else { return }
        let playback = configuration.voicePlayback
        state.title.font = playback.durationFont
        let frames = playback.waveformImages.map { image in
            let frame = playback.mirrorsSenderWaveform && message.isSender(userID) ? image.withHorizontallyFlippedOrientation() : image
            return frame.withRenderingMode(playback.waveformTintColor == nil ? .alwaysOriginal : .alwaysTemplate)
        }
        state.thumbnail.tintColor = playback.waveformTintColor ?? messageContentConfiguration.titleColor
        state.usesThumbnail = !frames.isEmpty
        state.thumbnail.image = frames.last
        state.thumbnail.animationImages = frames
        state.thumbnail.animationDuration = playback.waveformDuration.isFinite ? max(0.1, playback.waveformDuration) : 0.75
        state.thumbnailSize.first?.constant = playback.waveformSize.width.isFinite ? max(0, playback.waveformSize.width) : 0
        state.thumbnailSize.last?.constant = playback.waveformSize.height.isFinite ? max(0, playback.waveformSize.height) : 0
        wy_renderVoicePlayingState(value)
        let sender = message.isSender(userID)
        if sender && playback.showsSenderWaveformOnTrailingSide {
            state.header.removeArrangedSubview(state.thumbnail)
            state.header.insertArrangedSubview(state.thumbnail, at: 1)
        }
        state.title.textAlignment = sender ? playback.senderDurationAlignment : playback.receiverDurationAlignment
        state.detail.text = value.isRecognizing ? configuration.recording.recognizingText : value.recognitionError.isEmpty ? value.voiceToText : value.recognitionError
        if !value.isRecognizing && !value.recognitionError.isEmpty { state.detail.textColor = configuration.recording.recognitionFailureColor }
        wy_renderVoicePlayback()
        wy_updateVoiceTitleCompression()
    }
}
