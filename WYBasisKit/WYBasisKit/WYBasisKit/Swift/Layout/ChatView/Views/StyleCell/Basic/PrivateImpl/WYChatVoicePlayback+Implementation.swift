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
        let unread = state.voiceUnreadView
        unread.translatesAutoresizingMaskIntoConstraints = false
        unread.isUserInteractionEnabled = false
        unread.isHidden = true
        unread.accessibilityIdentifier = "WYChatVoice.unread"
        contentView.addSubview(unread)
        state.voiceUnreadSize = [unread.widthAnchor.constraint(equalToConstant: 0), unread.heightAnchor.constraint(equalToConstant: 0)]
        state.voiceUnreadLeading = unread.leadingAnchor.constraint(equalTo: bubblesView.trailingAnchor)
        NSLayoutConstraint.activate(state.voiceUnreadSize + [state.voiceUnreadLeading!, unread.centerYAnchor.constraint(equalTo: bubblesView.centerYAnchor)])
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
        let waveformWidth = state.usesThumbnail ? max(0, configuration.voicePlayback.waveformSize.width) + max(0, style.spacing) : 0
        let titleWidth = ceil(state.title.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width)
        let playback = configuration.voicePlayback
        let duration = voice.duration.isFinite ? max(0, voice.duration) : 0
        let minimum = playback.minimumWidth.isFinite ? max(0, playback.minimumWidth) : 0
        let threshold = playback.minimumWidthDuration.isFinite ? max(0, playback.minimumWidthDuration) : 0
        let growth = playback.widthGrowthPerSecond.isFinite ? max(0, playback.widthGrowthPerSecond) : 0
        let preferred = state.detail.text?.isEmpty == false ? style.preferredWidth : minimum + CGFloat(max(0, duration - threshold)) * growth
        state.preferredWidth?.constant = max(1, min(width, max(preferred, titleWidth + ratesWidth + waveformWidth)))
        let textWidth = max(1, (state.preferredWidth?.constant ?? width) - ratesWidth - waveformWidth)
        let scale = max(1, traitCollection.displayScale)
        for label in [state.title, state.detail, state.footer] { label.preferredMaxLayoutWidth = floor(textWidth * scale) / scale }
    }
    func wy_renderVoicePlayback() {
        let style = configuration.voicePlayback
        let unread = state.voiceUnreadView
        unread.isHidden = message.content.voice == nil || message.isSender(userID) || message.content.voice?.played != false
        let unreadSize = style.unreadSize.isFinite ? max(0, style.unreadSize) : 0
        state.voiceUnreadSize.forEach { $0.constant = unreadSize }
        state.voiceUnreadLeading?.constant = max(0, messageContentConfiguration.spacing)
        unread.backgroundColor = style.unreadColor
        unread.layer.cornerRadius = unreadSize / 2
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
