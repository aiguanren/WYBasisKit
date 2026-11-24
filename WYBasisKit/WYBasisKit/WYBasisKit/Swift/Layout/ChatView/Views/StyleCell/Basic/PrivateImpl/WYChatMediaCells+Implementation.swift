//
//  WYChatMediaCells+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 为内置及异步加载的图标应用显式指定的着色。
final class WYChatIconImageView: UIImageView {
    var tintsImage = false

    override var image: UIImage? {
        get { super.image }
        set { super.image = tintsImage ? newValue?.withRenderingMode(.alwaysTemplate) : newValue }
    }
}

/// 视频封面的播放标记和时长。
final class WYChatVideoOverlayView: UIView {
    private let playBackground = UIView()
    private let play = UIImageView()
    private let duration = UILabel()
    private var playSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(playBackground)
        playBackground.addSubview(play)
        addSubview(duration)
        play.contentMode = .scaleAspectFit
        duration.textAlignment = .center
        duration.adjustsFontSizeToFitWidth = true
        duration.accessibilityIdentifier = "WYChatVideo.duration"
        play.accessibilityIdentifier = "WYChatVideo.play"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ config: WYChatMediaConfig, icon: UIImage?, tint: UIColor?, font: UIFont, duration text: String) {
        play.image = tint == nil ? icon : icon?.withRenderingMode(.alwaysTemplate)
        play.tintColor = tint
        playSize = CGSize(width: config.videoPlaySize.width.isFinite ? max(0, config.videoPlaySize.width) : 0,
                          height: config.videoPlaySize.height.isFinite ? max(0, config.videoPlaySize.height) : 0)
        playBackground.isHidden = play.image == nil || playSize.width == 0 || playSize.height == 0
        playBackground.backgroundColor = config.videoOverlayBackgroundColor
        duration.text = text
        duration.font = font
        duration.textColor = config.videoDurationColor
        duration.backgroundColor = config.videoOverlayBackgroundColor
        duration.isHidden = !config.showsVideoDuration
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(width: min(bounds.width, playSize.width), height: min(bounds.height, playSize.height))
        playBackground.frame = CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
        playBackground.layer.cornerRadius = min(size.width, size.height) / 2
        play.frame = playBackground.bounds.insetBy(dx: size.width * 0.18, dy: size.height * 0.18)
        let textSize = duration.intrinsicContentSize
        let inset: CGFloat = 6
        let width = min(max(0, bounds.width - 2 * inset), max(0, textSize.width + 12))
        let height = min(max(0, bounds.height - 2 * inset), max(0, textSize.height + 4))
        let x = effectiveUserInterfaceLayoutDirection == .rightToLeft ? inset : bounds.width - inset - width
        duration.frame = CGRect(x: x, y: bounds.height - inset - height, width: width, height: height)
        duration.layer.cornerRadius = min(6, height / 2)
        duration.clipsToBounds = true
    }
}

/// 媒体消息内容
extension WYChatBasicCell {
    func wy_showThumbnail(_ asset: WYChatAssetsModel) {
        state.usesThumbnail = true
        if message.content.file != nil || message.content.luckyMoney != nil || message.content.transfer != nil {
            let size = messageContentConfiguration.iconSize
            state.thumbnailSize.first?.constant = size.width.isFinite ? max(0, size.width) : 0
            state.thumbnailSize.last?.constant = size.height.isFinite ? max(0, size.height) : 0
        }
        if asset.localPath.isEmpty && asset.downloadPath.isEmpty && asset.name.isEmpty {
            let names: [WYChatMessageStyle: String] = [.file: "WYChatViewFile", .music: "WYChatViewMusic", .businessCard: "WYChatViewContact", .webpage: "WYChatViewLink"]
            if let name = names[message.content.style()] { wy_showMessageIcon(name); return }
        }
        let style = messageContentConfiguration
        let usesNamedIcon = asset.localPath.isEmpty && asset.downloadPath.isEmpty && style.usesDefaultIconTint
        let tint = style.iconTintColor ?? (usesNamedIcon ? WYChatDefaultResources.iconTint(for: asset.name) : nil)
        state.thumbnail.tintsImage = tint != nil
        state.thumbnail.tintColor = tint
        wy_loadImage(asset, into: state.thumbnail)
    }

    func wy_showMessageIcon(_ name: String) {
        state.usesThumbnail = true
        let size = messageContentConfiguration.iconSize
        state.thumbnailSize.first?.constant = size.width.isFinite ? max(0, size.width) : 0
        state.thumbnailSize.last?.constant = size.height.isFinite ? max(0, size.height) : 0
        let style = messageContentConfiguration
        let tint = style.iconTintColor ?? (style.iconImage == nil && style.usesDefaultIconTint ? WYChatDefaultResources.iconTint(for: name) : nil)
        state.thumbnail.tintsImage = tint != nil
        state.thumbnail.tintColor = tint
        state.thumbnail.image = style.iconImage ?? UIImage.wy_find(name, inBundle: WYChatSourceBundle)
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
        wy_loadImage(asset, into: state.image, isPhoto: message.content.style() == .photo)
    }

    func wy_renderMedia() {
        switch message.content.style() {
        case .photo:
            guard let value = message.content.photo else { return }
            state.title.isHidden = true
            let thumbnail = value.thumbnail
            wy_showImage(thumbnail.localPath.isEmpty && thumbnail.downloadPath.isEmpty && thumbnail.name.isEmpty ? value.original : thumbnail)
            state.preferredWidth?.constant = messageContentConfiguration.mediaSize.width
        case .video:
            guard let value = message.content.video else { return }
            let style = messageContentConfiguration
            let media = configuration.media
            let cover = value.thumbnailCover
            state.title.isHidden = true
            state.preferredContentWidth = style.mediaSize.width.isFinite ? max(1, style.mediaSize.width) : nil
            state.image.imageCornerRadius = media.cornerRadius.isFinite ? max(0, media.cornerRadius) : 0
            wy_showImage(cover.localPath.isEmpty && cover.downloadPath.isEmpty && cover.name.isEmpty ? value.cover : cover)
            if state.isMeasuring { return }
            let overlay = state.videoOverlay ?? WYChatVideoOverlayView(frame: state.image.bounds)
            if overlay.superview == nil {
                overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                state.image.addSubview(overlay)
                state.videoOverlay = overlay
            }
            overlay.isHidden = false
            let tint = style.iconTintColor ?? (media.tintsVideoPlayImage && style.usesDefaultIconTint ? media.videoPlayColor : nil)
            overlay.apply(media, icon: style.iconImage ?? media.videoPlayImage, tint: tint, font: style.detailFont, duration: wy_duration(value.duration))
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
            if !value.isRecognizing && !value.recognitionError.isEmpty { state.detail.textColor = configuration.recording.recognitionFailureColor }
            let style = messageContentConfiguration
            let minimum = playback.minimumWidth.isFinite ? max(0, playback.minimumWidth) : 0
            let minimumDuration = playback.minimumWidthDuration.isFinite ? max(0, playback.minimumWidthDuration) : 0
            let growth = playback.widthGrowthPerSecond.isFinite ? max(0, playback.widthGrowthPerSecond) : 0
            let seconds = value.duration.isFinite ? min(86_400, max(0, value.duration)) : 0
            let transcriptWidth = ((state.detail.text ?? "") as NSString).size(withAttributes: [.font: style.detailFont]).width
            let targetWidth = max(minimum + CGFloat(max(0, seconds - minimumDuration)) * growth, transcriptWidth)
            state.preferredContentWidth = max(minimum, min(style.preferredWidth, targetWidth))
        default: break
        }
    }

    func wy_duration(_ duration: TimeInterval) -> String {
        let seconds = Int(min(86400, max(0, duration.isFinite ? duration : 0)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
