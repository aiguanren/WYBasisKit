//
//  WYChatVoicePlayback+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 语音播放倍速菜单与按钮布局
extension WYChatVoiceCell {
    func wy_setupVoicePlayback() {
        let unread = voiceState.voiceUnreadView
        unread.translatesAutoresizingMaskIntoConstraints = false
        unread.isUserInteractionEnabled = false
        unread.isHidden = true
        unread.accessibilityIdentifier = "WYChatVoice.unread"
        contentView.addSubview(unread)
        voiceState.voiceUnreadSize = [unread.widthAnchor.constraint(equalToConstant: 0), unread.heightAnchor.constraint(equalToConstant: 0)]
        voiceState.voiceUnreadLeading = unread.leadingAnchor.constraint(equalTo: bubblesView.trailingAnchor)
        NSLayoutConstraint.activate(voiceState.voiceUnreadSize + [voiceState.voiceUnreadLeading!, unread.centerYAnchor.constraint(equalTo: bubblesView.centerYAnchor)])
        let button = voiceState.voiceRateButton
        state.header.addArrangedSubview(button)
        voiceState.voiceRateWidth = button.widthAnchor.constraint(equalToConstant: 0)
        voiceState.voiceRateHeight = button.heightAnchor.constraint(equalToConstant: 0)
        for constraint in [voiceState.voiceRateWidth, voiceState.voiceRateHeight] { constraint?.priority = UILayoutPriority(999); constraint?.isActive = true }
        button.isHidden = true
        button.showsMenuAsPrimaryAction = true
    }
    func wy_layoutVoicePlayback(width: CGFloat) {
        guard let voice = message.content.voice else { return }
        let style = messageContentConfiguration
        let ratesWidth = voiceState.voiceRateButton.isHidden ? 0 : (voiceState.voiceRateWidth?.constant ?? 0) + max(0, style.spacing)
        let waveformWidth = state.usesThumbnail ? max(0, configuration.voicePlayback.waveformSize.width) + max(0, style.spacing) : 0
        let titleWidth = ceil(state.title.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width)
        let playback = configuration.voicePlayback
        let minimum = min(width, wy_chatNonnegative(playback.minimumWidth))
        let maximum = min(width, max(minimum, wy_chatNonnegative(style.preferredWidth)))
        let threshold = wy_chatNonnegative(playback.minimumWidthDuration)
        let duration = max(0, wy_chatNonnegative(voice.duration) - threshold)
        let limit = wy_chatNonnegative(configuration.recording.recordTime.max)
        let preferred: CGFloat
        if state.detail.text?.isEmpty == false {
            preferred = maximum
        } else if playback.usesProportionalWidth && limit > threshold {
            let fraction = min(1, duration / (limit - threshold))
            preferred = minimum + (maximum - minimum) * CGFloat(fraction)
        } else {
            preferred = minimum + CGFloat(duration) * wy_chatNonnegative(playback.widthGrowthPerSecond)
        }
        state.preferredWidth?.constant = max(1, min(width, max(preferred, titleWidth + ratesWidth + waveformWidth)))
        let textWidth = max(1, (state.preferredWidth?.constant ?? width) - ratesWidth - waveformWidth)
        let scale = max(1, traitCollection.displayScale)
        for label in [state.title, state.detail, state.footer] { label.preferredMaxLayoutWidth = floor(textWidth * scale) / scale }
    }
    func wy_renderVoicePlayingState(_ voice: WYChatVoiceModel) {
        if voice.isPlaying && (state.thumbnail.animationImages?.count ?? 0) > 1 && !state.isMeasuring {
            if !state.thumbnail.isAnimating { state.thumbnail.startAnimating() }
        } else if state.thumbnail.isAnimating {
            state.thumbnail.stopAnimating()
        }
        let playback = configuration.voicePlayback
        let duration = String(Int(ceil(min(86_400, wy_chatNonnegative(voice.duration))))) + playback.durationSuffix
        if playback.showsPlaybackSymbol { wy_showPlaybackSymbol(voice.isPlaying ? playback.pauseImage : playback.playImage, text: duration) }
        else if state.title.text != duration { state.title.text = duration }
    }

    func wy_updateVoicePlayingState(_ model: WYChatMessageModel) -> Bool {
        guard let voice = model.content.voice, let previous = message.content.voice else { return false }
        state.isUpdating = true
        message = model
        state.isUpdating = false
        guard voice.isPlaying != previous.isPlaying || voice.played != previous.played || voice.playbackRate != previous.playbackRate else { return false }

        let rateWasHidden = voiceState.voiceRateButton.isHidden
        if voice.isPlaying != previous.isPlaying { wy_renderVoicePlayingState(voice) }
        wy_renderVoicePlayback()
        wy_updateVoiceTitleCompression()
        setNeedsLayout()
        return rateWasHidden != voiceState.voiceRateButton.isHidden || (voice.isPlaying != previous.isPlaying && configuration.voicePlayback.showsPlaybackSymbol)
    }

    func wy_updateVoiceTitleCompression() {
        state.title.setContentCompressionResistancePriority(voiceState.voiceRateButton.isHidden ? .defaultHigh : UILayoutPriority(999), for: .horizontal)
    }

    func wy_showPlaybackSymbol(_ image: UIImage?, text: String) {
        guard let image else { state.title.text = text; return }
        let attachment = NSTextAttachment()
        attachment.image = image.withRenderingMode(.alwaysOriginal)
        let font = messageContentConfiguration.titleFont
        let size = font.lineHeight * wy_chatNonnegative(configuration.voicePlayback.playbackSymbolScale)
        attachment.bounds = CGRect(x: 0, y: font.descender, width: size, height: size)
        let content = NSMutableAttributedString(attachment: attachment)
        content.append(NSAttributedString(string: configuration.voicePlayback.playbackSymbolSeparator + text))
        state.title.attributedText = content
    }

    func wy_renderVoicePlayback() {
        let style = configuration.voicePlayback
        let unread = voiceState.voiceUnreadView
        unread.isHidden = message.content.voice == nil || message.isSender(userID) || message.content.voice?.played != false
        let unreadSize = style.unreadSize.isFinite ? max(0, style.unreadSize) : 0
        voiceState.voiceUnreadSize.forEach { $0.constant = unreadSize }
        voiceState.voiceUnreadLeading?.constant = max(0, messageContentConfiguration.spacing)
        unread.backgroundColor = style.unreadColor
        unread.layer.cornerRadius = min(unreadSize / 2, wy_chatNonnegative(style.unreadCornerRadius ?? unreadSize / 2))
        let button = voiceState.voiceRateButton
        let rates = wy_chatPlaybackRates(style)
        guard let voice = message.content.voice, style.showsRateControl, !rates.isEmpty, !style.showsOnlyWhilePlaying || voice.isPlaying else { button.isHidden = true; button.menu = nil; return }
        button.isHidden = false
        button.accessibilityIdentifier = "WYChatVoice.rate.\(message.messageID)"
        let rate = voice.playbackRate.isFinite && voice.playbackRate > 0 ? voice.playbackRate : rates[0]
        var appearance = UIButton.Configuration.plain()
        var attributes = AttributeContainer()
        attributes.font = style.font
        appearance.attributedTitle = AttributedString(style.rateTitle?(rate) ?? String(format: "%g×", rate), attributes: attributes)
        appearance.baseForegroundColor = style.textColor
        appearance.background.backgroundColor = style.backgroundColor
        appearance.background.cornerRadius = style.cornerRadius.isFinite ? max(0, style.cornerRadius) : 0
        appearance.cornerStyle = .fixed
        appearance.contentInsets = NSDirectionalEdgeInsets(top: style.insets.top, leading: style.insets.left, bottom: style.insets.bottom, trailing: style.insets.right)
        button.configuration = appearance
        voiceState.voiceRateWidth?.constant = style.size.width.isFinite ? max(0, style.size.width) : 0
        voiceState.voiceRateHeight?.constant = style.size.height.isFinite ? max(0, style.size.height) : 0
        let identifier = message.messageID
        button.menu = UIMenu(children: rates.map { value in
            UIAction(title: style.rateTitle?(value) ?? String(format: "%g×", value), state: value == rate ? .on : .off) { [weak self] _ in self?.voicePlaybackRateHandler?(identifier, value) }
        })
    }
}
