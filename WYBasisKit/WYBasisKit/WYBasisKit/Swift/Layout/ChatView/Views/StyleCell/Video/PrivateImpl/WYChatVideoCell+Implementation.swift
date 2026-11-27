//
//  WYChatVideoCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatVideoCellPrivateState {
    var videoOverlay: WYChatVideoOverlayView?
}

extension WYChatVideoCell {
    func wy_videoRender() {
        guard let value = message.content.video else { return }
        let style = messageContentConfiguration
        let media = configuration.media
        let cover = value.thumbnailCover
        state.title.isHidden = true
        state.preferredContentWidth = style.mediaSize.width.isFinite ? max(1, style.mediaSize.width) : nil
        state.image.imageCornerRadius = media.cornerRadius.isFinite ? max(0, media.cornerRadius) : 0
        wy_showImage(cover.localPath.isEmpty && cover.downloadPath.isEmpty && cover.name.isEmpty ? value.cover : cover)
        if state.isMeasuring { return }
        let overlay = videoState.videoOverlay ?? WYChatVideoOverlayView(frame: state.image.bounds)
        if overlay.superview == nil {
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            state.image.addSubview(overlay)
            videoState.videoOverlay = overlay
        }
        overlay.isHidden = false
        let tint = style.iconTintColor ?? (media.tintsVideoPlayImage && style.usesDefaultIconTint ? media.videoPlayColor : nil)
        overlay.apply(media, icon: style.iconImage ?? media.videoPlayImage, tint: tint, font: style.detailFont, duration: wy_duration(value.duration))
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
