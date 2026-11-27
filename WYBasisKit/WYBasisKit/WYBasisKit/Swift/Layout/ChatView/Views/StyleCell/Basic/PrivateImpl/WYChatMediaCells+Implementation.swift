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

extension WYChatBasicCell {
    func wy_showThumbnail(_ asset: WYChatAssetsModel, fallbackIcon: String? = nil, usesIconSize: Bool = false) {
        state.usesThumbnail = true
        if usesIconSize {
            let size = messageContentConfiguration.iconSize
            state.thumbnailSize.first?.constant = size.width.isFinite ? max(0, size.width) : 0
            state.thumbnailSize.last?.constant = size.height.isFinite ? max(0, size.height) : 0
        }
        if let fallbackIcon, asset.localPath.isEmpty && asset.downloadPath.isEmpty && asset.name.isEmpty {
            wy_showMessageIcon(fallbackIcon)
            return
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

    func wy_showImage(_ asset: WYChatAssetsModel, height: CGFloat? = nil, isPhoto: Bool = false, previewPlaceholder: (() -> UIImage)? = nil) {
        state.usesImage = true
        state.imageHeight?.constant = max(1, height ?? messageContentConfiguration.mediaSize.height)
        wy_loadImage(asset, into: state.image, isPhoto: isPhoto, previewPlaceholder: previewPlaceholder)
    }

    func wy_duration(_ duration: TimeInterval) -> String {
        configuration.media.wy_formattedDuration(duration)
    }
}

extension WYChatMediaConfig {
    func wy_formattedDuration(_ duration: TimeInterval) -> String {
        if let durationFormatter { return durationFormatter(duration) }
        let supported = min(Double(Int64.max / 2), max(0, duration.isFinite ? duration : 0))
        let limit = maximumDefaultFormattedDuration
        let seconds = Int64(limit.isFinite && limit > 0 ? min(limit, supported) : supported)
        return String(format: "%lld:%02lld", seconds / 60, seconds % 60)
    }
}

/// 附件传输条与媒体封面内的传输控件。
final class WYChatAttachmentProgressView: UIView {
    let button = UIButton(type: .system)
    private let caption = UILabel()
    private let barTrack = UIView()
    private let barFill = UIView()
    private let track = CAShapeLayer()
    private let ring = CAShapeLayer()
    private lazy var bubbleMask = CAShapeLayer()
    private var style: WYChatContentConfig?
    private var progress: Double = 0
    private var anchorsBarToBottom = false
    private var overlaysMedia = false
    private var progressColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(barTrack)
        barTrack.addSubview(barFill)
        barTrack.clipsToBounds = true
        for shape in [track, ring] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineCap = .round
            layer.addSublayer(shape)
        }
        addSubview(button)
        addSubview(caption)
        caption.adjustsFontSizeToFitWidth = true
        caption.accessibilityIdentifier = "WYChatTransfer.status"
        button.accessibilityIdentifier = "WYChatTransfer.control"
        button.configuration = .plain()
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func layoutOverBubble(_ bubble: WYAirBubbleView) {
        bubble.layoutIfNeeded()
        frame = bubble.bounds
        layer.cornerRadius = 0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bubbleMask.frame = bounds
        bubbleMask.bounds.origin = bubble.bounds.origin
        bubbleMask.path = bubble.bubblePath
        if layer.mask !== bubbleMask { layer.mask = bubbleMask }
        CATransaction.commit()
    }

    func apply(style: WYChatContentConfig, overlaysMedia: Bool, sender: Bool, progress: Double, text: String, image: UIImage?, actionTitle: String?,
               mediaConfig: WYChatMediaConfig?, anchorsBarToBottom: Bool) {
        self.overlaysMedia = overlaysMedia
        self.anchorsBarToBottom = anchorsBarToBottom
        self.progress = progress
        self.style = style
        progressColor = mediaConfig?.itemTransferRingColor ?? (sender ? style.transferSenderColor : style.transferReceiverColor)
        backgroundColor = overlaysMedia ? style.transferOverlayColor : .clear
        barTrack.isHidden = overlaysMedia
        barTrack.backgroundColor = style.transferTrackColor
        barFill.backgroundColor = progressColor
        track.isHidden = !overlaysMedia
        ring.isHidden = !overlaysMedia
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ring.strokeEnd = CGFloat(progress)
        CATransaction.commit()
        caption.font = style.transferStatusFont ?? style.detailFont
        caption.minimumScaleFactor = min(1, wy_chatNonnegative(style.transferStatusMinimumScaleFactor))
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
        guard let style, !bounds.isEmpty else { return }
        let controlSize = wy_chatNonnegative(style.transferControlSize)
        let lineWidth = wy_chatNonnegative(style.transferLineWidth)
        if overlaysMedia {
            let captionSpacing = wy_chatNonnegative(style.transferOverlayCaptionSpacing)
            let captionInset = min(bounds.width / 2, wy_chatNonnegative(style.transferOverlayCaptionHorizontalInset))
            let captionHeight = caption.isHidden || caption.text?.isEmpty != false ? 0 : caption.font.lineHeight + captionSpacing
            let controlMinimum = wy_chatNonnegative(style.transferOverlayMinimumControlHeight)
            let controlHeight = bounds.height >= captionHeight + controlMinimum ? bounds.height - captionHeight : bounds.height
            let available = min(bounds.width, controlHeight)
            let ringRadius = style.transferRingRadius
            let diameter = ringRadius.isFinite && ringRadius >= 0 ? min(available / 2, ringRadius) * 2 : min(available, controlSize)
            let center = CGPoint(x: bounds.midX, y: min(bounds.midY, controlHeight - max(diameter, min(available, controlSize)) / 2))
            let stroke = min(lineWidth, diameter / 2)
            let radius = max(0, (diameter - stroke) / 2)
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true).cgPath
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            track.lineWidth = stroke
            ring.lineWidth = stroke
            track.path = path
            track.strokeColor = style.transferTrackColor.resolvedColor(with: traitCollection).cgColor
            ring.path = path
            ring.strokeColor = progressColor.resolvedColor(with: traitCollection).cgColor
            CATransaction.commit()
            let buttonSide = min(available, controlSize)
            button.frame = CGRect(x: center.x - buttonSide / 2, y: center.y - buttonSide / 2, width: buttonSide, height: buttonSide)
            let inset = buttonSide * min(0.5, wy_chatNonnegative(style.transferOverlayIconInsetRatio))
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
            let captionTop = max(button.frame.maxY, center.y + diameter / 2) + captionSpacing
            caption.frame = CGRect(x: captionInset, y: captionTop, width: bounds.width - captionInset * 2, height: min(caption.font.lineHeight, max(0, bounds.height - captionTop)))
        } else {
            let buttonWidth = button.isHidden ? 0 : min(wy_chatNonnegative(style.transferInlineControlMaximumWidth), controlSize, bounds.width)
            let thickness = min(bounds.height, lineWidth)
            let statusHeight = anchorsBarToBottom ? max(0, bounds.height - thickness - wy_chatNonnegative(style.transferInlineBarSpacing)) : bounds.height
            button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: statusHeight)
            let insets = style.transferInlineIconInsets
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: wy_chatNonnegative(insets.top), leading: wy_chatNonnegative(insets.left), bottom: wy_chatNonnegative(insets.bottom), trailing: wy_chatNonnegative(insets.right))
            let captionRatio = min(1, wy_chatNonnegative(style.transferInlineCaptionMaximumWidthRatio))
            let labelWidth = min(max(0, bounds.width - buttonWidth) * captionRatio, max(0, caption.intrinsicContentSize.width))
            caption.frame = CGRect(x: bounds.width - labelWidth, y: 0, width: labelWidth, height: statusHeight)
            if anchorsBarToBottom {
                barTrack.frame = CGRect(x: 0, y: bounds.height - thickness, width: bounds.width, height: thickness)
            } else {
                barTrack.frame = CGRect(x: buttonWidth, y: bounds.midY - thickness / 2, width: max(0, caption.frame.minX - buttonWidth - wy_chatNonnegative(style.transferInlineCaptionSpacing)), height: thickness)
            }
            let barRadius = style.transferBarCornerRadius
            let cornerRadius = barRadius.isFinite && barRadius >= 0 ? min(thickness / 2, barRadius) : thickness / 2
            barTrack.layer.cornerRadius = cornerRadius
            barFill.frame = CGRect(x: 0, y: 0, width: barTrack.bounds.width * CGFloat(progress), height: thickness)
            barFill.layer.cornerRadius = min(cornerRadius, barFill.bounds.width / 2)
        }
    }
}

extension WYChatAttachmentProgressView {
    func showPhase(_ phase: WYChatTransferState, progress rawProgress: Double, error: String, style: WYChatContentConfig, overlaysMedia: Bool, sender: Bool, title: ((WYChatAction) -> String?)?,
                   mediaConfig: WYChatMediaConfig? = nil, anchorsBarToBottom: Bool = false) -> WYChatAction? {
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
            actionTitle = style.transferAllowsPause ? (title?(.pauseTransfer) ?? style.transferPauseActionTitle) : nil
        case .paused:
            text = [style.transferPausedText, percentage].filter { !$0.isEmpty }.joined(separator: style.transferStatusSeparator)
            image = style.transferAllowsPause ? style.transferResumeImage ?? WYChatSourceBundle.image(named: "WYChatTransferResume") : nil
            action = style.transferAllowsPause ? .resumeTransfer : nil
            actionTitle = style.transferAllowsPause ? (title?(.resumeTransfer) ?? style.transferResumeActionTitle) : nil
        case .failed:
            text = error.isEmpty ? style.transferFailedText : error
            image = style.transferRetryImage ?? UIImage(systemName: "arrow.clockwise")
            action = .retry
            actionTitle = title?(.retry) ?? style.transferRetryActionTitle
        case .automatic, .completed:
            return nil
        }
        apply(style: style, overlaysMedia: overlaysMedia, sender: sender, progress: progress, text: text, image: image, actionTitle: actionTitle, mediaConfig: mediaConfig, anchorsBarToBottom: anchorsBarToBottom)
        return action
    }
}

enum WYChatTransferProgressPresentation {
    case inline
    case attachment
    case preview
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
        let hasItemProgress = wy_updatesItemTransferProgress(visible: !sending || remaining == 0)
        if style.transferShowsProgress && remaining > 0 && sending && !state.isMeasuring {
            let task = DispatchWorkItem { [weak self] in
                guard let self else { return }
                let wasHidden = self.state.inlineProgress.isHidden
                let wasAnimating = self.activityView.isAnimating
                let wasOverlayHidden = self.state.mediaProgress.isHidden
                self.wy_renderAttachmentProgress()
                if wasOverlayHidden != self.state.mediaProgress.isHidden
                    || wasAnimating != self.activityView.isAnimating {
                    self.setNeedsLayout()
                }
                if wasHidden && !self.state.inlineProgress.isHidden { self.state.progressVisibilityChanged?(self.message.messageID) }
            }
            state.progressReveal = task
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: task)
        }
        if style.transferShowsProgress && sending && remaining == 0 && !hasItemProgress && (phase == .automatic || phase == .completed) {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
        guard style.transferShowsProgress, !hasItemProgress, !wy_isNotice, phase != .automatic, phase != .completed else { return }
        let presentation = wy_transferProgressPresentation
        let attachmentCard = presentation == .attachment
        let overlaysMedia = presentation == .preview || attachmentCard && style.attachmentProgressPlacement == .overlay
        let view = overlaysMedia ? state.mediaProgress : state.inlineProgress
        let shouldHide = sending && remaining > 0 && phase == .transferring
        view.isHidden = shouldHide
        let cardHasBottomProgress = attachmentCard && !overlaysMedia
        state.transferAction = view.showPhase(phase, progress: message.transferProgress, error: message.transferError, style: style,
                                              overlaysMedia: overlaysMedia, sender: sender, title: configuration.actionTitle,
                                              anchorsBarToBottom: cardHasBottomProgress)
        let font = style.transferStatusFont ?? style.detailFont
        let barHeight = cardHasBottomProgress ? wy_chatNonnegative(style.transferLineWidth) + 2 : 0
        state.inlineProgressHeight?.constant = max(wy_chatNonnegative(style.transferInlineMinimumHeight), font.lineHeight + wy_chatNonnegative(style.transferInlineVerticalPadding) + barHeight)
    }

    func wy_layoutAttachmentProgress() {
        let progress = state.mediaProgress
        guard !progress.isHidden else { return }
        if wy_transferProgressPresentation == .attachment {
            progress.layoutOverBubble(bubblesView)
            return
        }
        progress.layer.mask = nil
        let geometry = wy_transferPreviewGeometry()
        progress.frame = geometry.frame
        progress.layer.cornerRadius = geometry.cornerRadius
    }

    @objc func wy_attachmentProgressTapped() {
        guard let action = state.transferAction else { return }
        actionHandler?(action, message.messageID)
    }
}

extension WYChatBasicCell {
    func wy_applyAttachmentProgress(_ message: WYChatMessageModel) {
        guard self.message.messageID == message.messageID else { return }
        state.isUpdating = true
        self.message = message
        state.isUpdating = false
        wy_renderAttachmentProgress()
        setNeedsLayout()
    }
}
