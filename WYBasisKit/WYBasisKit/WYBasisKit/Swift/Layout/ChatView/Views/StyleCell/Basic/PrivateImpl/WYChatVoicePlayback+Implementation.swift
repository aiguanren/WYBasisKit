//
//  WYChatVoicePlayback+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 语音播放倍速菜单与按钮布局
extension WYChatBasicCell {
    func wy_setupVoicePlayback() {
        let button = state.voiceRateButton
        state.header.addArrangedSubview(button)
        state.voiceRateWidth = button.widthAnchor.constraint(equalToConstant: 0)
        state.voiceRateHeight = button.heightAnchor.constraint(equalToConstant: 0)
        for constraint in [state.voiceRateWidth, state.voiceRateHeight] { constraint?.priority = UILayoutPriority(999); constraint?.isActive = true }
        button.isHidden = true
        button.showsMenuAsPrimaryAction = true
    }
    func wy_layoutVoicePlayback(width: CGFloat) {
        guard let voice = message.content.voice else { return }
        let style = messageContentConfiguration
        let ratesWidth = state.voiceRateButton.isHidden ? 0 : (state.voiceRateWidth?.constant ?? 0) + max(0, style.spacing)
        let titleWidth = ceil(state.title.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width)
        let fraction = voice.duration.isFinite ? min(1, max(0, voice.duration / max(1, configuration.recording.recordTime.max))) : 0
        let preferred = state.detail.text?.isEmpty == false ? style.preferredWidth : style.preferredWidth * CGFloat(fraction)
        state.preferredWidth?.constant = max(1, min(width, max(preferred, titleWidth + ratesWidth)))
    }
    func wy_renderVoicePlayback() {
        let style = configuration.voicePlayback
        let button = state.voiceRateButton
        let rates = wy_chatPlaybackRates(style)
        guard let voice = message.content.voice, style.showsRateControl, !rates.isEmpty, !style.showsOnlyWhilePlaying || voice.isPlaying else { button.isHidden = true; button.menu = nil; return }
        button.isHidden = false
        button.accessibilityIdentifier = "WYChatVoice.rate.\(message.messageID)"
        let rate = voice.playbackRate.isFinite && voice.playbackRate > 0 ? voice.playbackRate : rates[0]
        var appearance = UIButton.Configuration.plain()
        var attributes = AttributeContainer()
        attributes.font = style.font
        appearance.attributedTitle = AttributedString(String(format: "%g×", rate), attributes: attributes)
        appearance.baseForegroundColor = style.textColor
        appearance.background.backgroundColor = style.backgroundColor
        appearance.background.cornerRadius = style.cornerRadius.isFinite ? max(0, style.cornerRadius) : 0
        appearance.cornerStyle = .fixed
        appearance.contentInsets = NSDirectionalEdgeInsets(top: style.insets.top, leading: style.insets.left, bottom: style.insets.bottom, trailing: style.insets.right)
        button.configuration = appearance
        state.voiceRateWidth?.constant = style.size.width.isFinite ? max(0, style.size.width) : 0
        state.voiceRateHeight?.constant = style.size.height.isFinite ? max(0, style.size.height) : 0
        let identifier = message.messageID
        button.menu = UIMenu(children: rates.map { value in
            UIAction(title: String(format: "%g×", value), state: value == rate ? .on : .off) { [weak self] _ in self?.voicePlaybackRateHandler?(identifier, value) }
        })
    }
}
