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
    private var playInsetRatio: CGFloat = 0
    private var durationInset: CGFloat = 0
    private var durationPadding = CGSize.zero
    private var durationCornerRadius: CGFloat = 0
    private var playBackgroundCornerRadius: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(playBackground)
        playBackground.addSubview(play)
        addSubview(duration)
        duration.adjustsFontSizeToFitWidth = true
        duration.accessibilityIdentifier = "WYChatVideo.duration"
        play.accessibilityIdentifier = "WYChatVideo.play"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ config: WYChatMediaConfig, icon: UIImage?, tint: UIColor?, font: UIFont, duration text: String) {
        play.contentMode = config.videoPlayContentMode
        duration.textAlignment = config.videoDurationTextAlignment
        playBackgroundCornerRadius = config.videoPlayBackgroundCornerRadius
        playInsetRatio = min(0.5, wy_chatNonnegative(config.videoPlayIconInsetRatio))
        durationInset = wy_chatNonnegative(config.videoDurationEdgeInset)
        durationPadding = CGSize(width: wy_chatNonnegative(config.videoDurationPadding.width), height: wy_chatNonnegative(config.videoDurationPadding.height))
        durationCornerRadius = wy_chatNonnegative(config.videoDurationCornerRadius)
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

    func setPlaySuppressed(_ suppressed: Bool) {
        playBackground.isHidden = suppressed || play.image == nil || playSize.width == 0 || playSize.height == 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(width: min(bounds.width, playSize.width), height: min(bounds.height, playSize.height))
        playBackground.frame = CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
        let maximumRadius = min(size.width, size.height) / 2
        playBackground.layer.cornerRadius = min(maximumRadius, wy_chatNonnegative(playBackgroundCornerRadius ?? maximumRadius))
        play.frame = playBackground.bounds.insetBy(dx: size.width * playInsetRatio, dy: size.height * playInsetRatio)
        let textSize = duration.intrinsicContentSize
        let inset = durationInset
        let width = min(max(0, bounds.width - 2 * inset), max(0, textSize.width + durationPadding.width))
        let height = min(max(0, bounds.height - 2 * inset), max(0, textSize.height + durationPadding.height))
        let x = effectiveUserInterfaceLayoutDirection == .rightToLeft ? inset : bounds.width - inset - width
        duration.frame = CGRect(x: x, y: bounds.height - inset - height, width: width, height: height)
        duration.layer.cornerRadius = min(durationCornerRadius, height / 2)
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
        let size = font.lineHeight * wy_chatNonnegative(configuration.voicePlayback.playbackSymbolScale)
        attachment.bounds = CGRect(x: 0, y: font.descender, width: size, height: size)
        let content = NSMutableAttributedString(attachment: attachment)
        content.append(NSAttributedString(string: configuration.voicePlayback.playbackSymbolSeparator + text))
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
            state.detail.text = [value.singer, value.composer].filter { !$0.isEmpty }.joined(separator: messageContentConfiguration.detailsSeparator)
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
            let sender = message.isSender(userID)
            if sender && playback.showsSenderWaveformOnTrailingSide {
                state.header.removeArrangedSubview(state.thumbnail)
                state.header.insertArrangedSubview(state.thumbnail, at: 1)
            }
            state.title.textAlignment = sender ? playback.senderDurationAlignment : playback.receiverDurationAlignment
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
        if let formatter = configuration.media.durationFormatter { return formatter(duration) }
        let seconds = Int(min(86400, max(0, duration.isFinite ? duration : 0)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// 附件传输条与媒体封面内的传输控件。
final class WYChatAttachmentProgressView: UIView {
    let button = UIButton(type: .system)
    private let caption = UILabel()
    private let bar = UIProgressView(progressViewStyle: .default)
    private let track = CAShapeLayer()
    private let ring = CAShapeLayer()
    private var controlSize: CGFloat = 42
    private var lineWidth: CGFloat = 2.5
    private var overlaysMedia = false
    private var trackColor: UIColor = .clear
    private var progressColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(bar)
        for shape in [track, ring] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineWidth = 2.5
            shape.lineCap = .round
            layer.addSublayer(shape)
        }
        addSubview(button)
        addSubview(caption)
        caption.adjustsFontSizeToFitWidth = true
        caption.minimumScaleFactor = 0.8
        caption.accessibilityIdentifier = "WYChatTransfer.status"
        button.accessibilityIdentifier = "WYChatTransfer.control"
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(style: WYChatContentConfig, overlaysMedia: Bool, sender: Bool, progress: Double, text: String, image: UIImage?, actionTitle: String?,
               mediaConfig: WYChatMediaConfig?) {
        self.overlaysMedia = overlaysMedia
        controlSize = wy_chatNonnegative(style.transferControlSize)
        lineWidth = wy_chatNonnegative(style.transferLineWidth)
        progressColor = mediaConfig?.itemTransferRingColor ?? (sender ? style.transferSenderColor : style.transferReceiverColor)
        trackColor = style.transferTrackColor
        backgroundColor = overlaysMedia ? style.transferOverlayColor : .clear
        bar.isHidden = overlaysMedia
        bar.progress = Float(progress)
        bar.progressTintColor = progressColor
        bar.trackTintColor = trackColor
        track.isHidden = !overlaysMedia
        ring.isHidden = !overlaysMedia
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ring.strokeEnd = CGFloat(progress)
        CATransaction.commit()
        caption.font = style.detailFont
        caption.textColor = style.transferStatusTextColor ?? (overlaysMedia ? .white : style.detailColor)
        caption.textAlignment = overlaysMedia ? .center : .natural
        caption.text = text
        caption.isHidden = mediaConfig?.showsItemTransferCaption == false
        let symbol = image?.withRenderingMode(style.transferTintsControlImages ? .alwaysTemplate : .alwaysOriginal)
        button.setImage(symbol, for: .normal)
        button.isUserInteractionEnabled = actionTitle != nil
        button.isAccessibilityElement = actionTitle != nil && symbol != nil
        button.accessibilityLabel = actionTitle
        button.accessibilityValue = text
        button.tintColor = style.transferControlTintColor ?? (overlaysMedia ? .white : progressColor)
        button.isHidden = symbol == nil
        setNeedsLayout()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        !button.isHidden && button.isUserInteractionEnabled && button.frame.contains(point)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty else { return }
        if overlaysMedia {
            let diameter = min(controlSize, bounds.width, bounds.height)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let stroke = min(lineWidth, diameter / 2)
            let radius = max(0, (diameter - stroke) / 2)
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true).cgPath
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            track.lineWidth = stroke
            ring.lineWidth = stroke
            track.path = path
            track.strokeColor = trackColor.resolvedColor(with: traitCollection).cgColor
            ring.path = path
            ring.strokeColor = progressColor.resolvedColor(with: traitCollection).cgColor
            CATransaction.commit()
            button.frame = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
            let inset = diameter * 0.29
            button.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
            let captionTop = button.frame.maxY + 4
            caption.frame = CGRect(x: 4, y: captionTop, width: max(0, bounds.width - 8), height: min(caption.font.lineHeight, max(0, bounds.height - captionTop)))
        } else {
            let buttonWidth = button.isHidden ? 0 : min(32, controlSize, bounds.width)
            button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.height)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
            let labelWidth = min(max(0, bounds.width - buttonWidth) * 0.6, max(0, caption.intrinsicContentSize.width))
            caption.frame = CGRect(x: bounds.width - labelWidth, y: 0, width: labelWidth, height: bounds.height)
            let thickness = min(bounds.height, lineWidth)
            bar.frame = CGRect(x: buttonWidth, y: bounds.midY - thickness / 2, width: max(0, caption.frame.minX - buttonWidth - 6), height: thickness)
        }
    }
}

extension WYChatAttachmentProgressView {
    func showPhase(_ phase: WYChatTransferState, progress rawProgress: Double, error: String, style: WYChatContentConfig, overlaysMedia: Bool, sender: Bool, title: ((WYChatAction) -> String?)?,
                   mediaConfig: WYChatMediaConfig? = nil) -> WYChatAction? {
        let progress = rawProgress.isFinite ? min(1, max(0, rawProgress)) : 0
        let percentage = style.transferShowsPercentage ? (style.transferProgressFormatter?(progress) ?? String(format: "%.0f%%", progress * 100)) : ""
        let text: String
        let image: UIImage?
        let action: WYChatAction?
        let actionTitle: String?
        switch phase {
        case .waiting:
            text = sender ? style.transferUploadText : style.transferDownloadText
            image = sender ? style.transferUploadImage ?? WYChatSourceBundle.image(named: "WYChatTransferUpload") : style.transferDownloadImage ?? WYChatSourceBundle.image(named: "WYChatTransferDownload")
            action = .startTransfer
            actionTitle = title?(.startTransfer) ?? text
        case .transferring:
            text = percentage
            image = style.transferAllowsPause ? style.transferPauseImage ?? WYChatSourceBundle.image(named: "WYChatTransferPause") : nil
            action = style.transferAllowsPause ? .pauseTransfer : nil
            actionTitle = style.transferAllowsPause ? (title?(.pauseTransfer) ?? "暂停传输") : nil
        case .paused:
            text = [style.transferPausedText, percentage].filter { !$0.isEmpty }.joined(separator: " · ")
            image = style.transferAllowsPause ? style.transferResumeImage ?? WYChatSourceBundle.image(named: "WYChatTransferResume") : nil
            action = style.transferAllowsPause ? .resumeTransfer : nil
            actionTitle = style.transferAllowsPause ? (title?(.resumeTransfer) ?? "继续传输") : nil
        case .failed:
            text = error.isEmpty ? style.transferFailedText : error
            image = style.transferRetryImage ?? UIImage(systemName: "arrow.clockwise")
            action = .retry
            actionTitle = title?(.retry) ?? "重试"
        case .automatic, .completed:
            return nil
        }
        apply(style: style, overlaysMedia: overlaysMedia, sender: sender, progress: progress, text: text, image: image, actionTitle: actionTitle, mediaConfig: mediaConfig)
        return action
    }
}

extension WYChatBasicCell {
    func wy_renderAttachmentProgress() {
        state.progressReveal?.cancel()
        state.progressReveal = nil
        state.inlineProgress.isHidden = true
        state.mediaProgress.isHidden = true
        state.transferAction = nil
        let style = messageContentConfiguration
        let phase = message.wy_effectiveTransferState
        let sender = message.isSender(userID)
        let sending = sender && message.sendState == .sending && !wy_isNotice
        let startedAt = message.sendStartedAt ?? Date.distantPast
        let remaining = max(0, wy_chatNonnegative(style.transferProgressDelay) - max(0, Date().timeIntervalSince(startedAt)))
        let hasItemProgress = message.content.mediaGroup?.items.contains { $0.transferState != .automatic } ?? false
        if style.transferShowsProgress && remaining > 0 && sending && !state.isMeasuring {
            let task = DispatchWorkItem { [weak self] in
                guard let self else { return }
                let wasHidden = self.state.inlineProgress.isHidden
                self.wy_renderAttachmentProgress()
                if wasHidden && !self.state.inlineProgress.isHidden { self.progressVisibilityChanged?(self.message.messageID) }
            }
            state.progressReveal = task
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: task)
        }
        if style.transferShowsProgress && sending && remaining == 0 && !hasItemProgress && (phase == .automatic || phase == .completed) {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
        state.mediaView.setTransferProgressVisible(!sending || remaining == 0)
        guard style.transferShowsProgress, !hasItemProgress, !wy_isNotice, phase != .automatic, phase != .completed else { return }
        let overlaysMedia = message.content.photo != nil || message.content.video != nil || message.content.mediaGroup != nil
        let view = overlaysMedia ? state.mediaProgress : state.inlineProgress
        let shouldHide = sending && remaining > 0 && phase == .transferring
        view.isHidden = shouldHide
        state.transferAction = view.showPhase(phase, progress: message.transferProgress, error: message.transferError, style: style,
                                              overlaysMedia: overlaysMedia, sender: sender, title: configuration.actionTitle)
        state.inlineProgressHeight?.constant = max(30, style.detailFont.lineHeight + 8)
    }

    func wy_layoutAttachmentProgress() {
        guard !state.mediaProgress.isHidden else { return }
        if let group = message.content.mediaGroup {
            let media = state.mediaView
            var frame = media.convert(media.bounds, to: bubblesView)
            if group.isExpanded { frame.size.height = min(frame.height, media.firstItemCenterY * 2) }
            state.mediaProgress.frame = frame
        } else {
            state.mediaProgress.frame = state.image.convert(state.image.bounds, to: bubblesView)
        }
        state.mediaProgress.layer.cornerRadius = message.content.mediaGroup == nil ? state.image.imageCornerRadius : wy_chatNonnegative(configuration.media.cornerRadius)
    }

    @objc func wy_attachmentProgressTapped() {
        guard let action = state.transferAction else { return }
        actionHandler?(action, message.messageID)
    }
}
