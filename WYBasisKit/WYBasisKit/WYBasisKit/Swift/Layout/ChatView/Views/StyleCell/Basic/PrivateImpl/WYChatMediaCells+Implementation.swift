//
//  WYChatMediaCells+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 媒体消息内容
extension WYChatBasicCell {
    func wy_showThumbnail(_ asset: WYChatAssetsModel) {
        state.usesThumbnail = true
        if message.content.file != nil {
            let size = messageContentConfiguration.iconSize
            state.thumbnailSize.first?.constant = size.width.isFinite ? max(0, size.width) : 0
            state.thumbnailSize.last?.constant = size.height.isFinite ? max(0, size.height) : 0
        }
        if asset.localPath.isEmpty && asset.downloadPath.isEmpty && asset.name.isEmpty {
            let names: [WYChatMessageStyle: String] = [.file: "WYChatViewFile", .music: "WYChatViewMusic", .businessCard: "WYChatViewContact", .webpage: "WYChatViewLink"]
            if let name = names[message.content.style()] { wy_showMessageIcon(name); return }
        }
        wy_loadImage(asset, into: state.thumbnail)
    }

    func wy_showMessageIcon(_ name: String) {
        state.usesThumbnail = true
        let size = messageContentConfiguration.iconSize
        state.thumbnailSize.first?.constant = size.width.isFinite ? max(0, size.width) : 0
        state.thumbnailSize.last?.constant = size.height.isFinite ? max(0, size.height) : 0
        state.thumbnail.image = messageContentConfiguration.iconImage ?? UIImage.wy_find(name, inBundle: WYChatSourceBundle)
    }

    func wy_showPlaybackSymbol(_ image: UIImage?, text: String) {
        guard let image else { state.title.text = text; return }
        let attachment = NSTextAttachment()
        attachment.image = image.withRenderingMode(.alwaysOriginal)
        let font = messageContentConfiguration.titleFont
        attachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
        let content = NSMutableAttributedString(attachment: attachment)
        content.append(NSAttributedString(string: "  " + text))
        state.title.attributedText = content
    }

    func wy_showImage(_ asset: WYChatAssetsModel, height: CGFloat? = nil) {
        state.usesImage = true
        state.imageHeight?.constant = max(1, height ?? messageContentConfiguration.mediaSize.height)
        wy_loadImage(asset, into: state.image)
    }

    func wy_renderMedia() {
        switch message.content.style() {
        case .photo:
            guard let value = message.content.photo else { return }
            state.title.isHidden = true
            wy_showImage(value.thumbnail.localPath.isEmpty && value.thumbnail.downloadPath.isEmpty ? value.original : value.thumbnail)
            state.preferredWidth?.constant = messageContentConfiguration.mediaSize.width
        case .video:
            guard let value = message.content.video else { return }
            wy_showImage(value.thumbnailCover.localPath.isEmpty && value.thumbnailCover.downloadPath.isEmpty ? value.cover : value.thumbnailCover)
            wy_showPlaybackSymbol(configuration.media.videoPlayImage, text: wy_duration(value.duration))
        case .music:
            guard let value = message.content.music else { return }
            wy_showThumbnail(value.thumbnailCover.localPath.isEmpty && value.thumbnailCover.downloadPath.isEmpty ? value.cover : value.thumbnailCover)
            state.title.text = value.name
            state.detail.text = [value.singer, value.composer].filter { !$0.isEmpty }.joined(separator: " · ")
            state.footer.text = wy_duration(value.duration)
        case .voice:
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
            if value.isPlaying && frames.count > 1 && !state.isMeasuring { state.thumbnail.startAnimating() }
            let duration = String(Int(ceil(min(86400, max(0, value.duration.isFinite ? value.duration : 0))))) + playback.durationSuffix
            if playback.showsPlaybackSymbol { wy_showPlaybackSymbol(value.isPlaying ? playback.pauseImage : playback.playImage, text: duration) }
            else { state.title.text = duration }
            if message.isSender(userID) {
                state.header.removeArrangedSubview(state.thumbnail)
                state.header.insertArrangedSubview(state.thumbnail, at: 1)
                state.title.textAlignment = .right
            } else { state.title.textAlignment = .left }
            state.detail.text = value.isRecognizing ? configuration.recording.recognizingText : value.recognitionError.isEmpty ? value.voiceToText : value.recognitionError
            let fraction = value.duration.isFinite ? min(1, max(0, value.duration / max(1, configuration.recording.recordTime.max))) : 0
            state.preferredWidth?.constant = max(messageContentConfiguration.titleFont.lineHeight * 3, messageContentConfiguration.preferredWidth * CGFloat(fraction))
        default: break
        }
    }

    func wy_duration(_ duration: TimeInterval) -> String {
        let seconds = Int(min(86400, max(0, duration.isFinite ? duration : 0)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
