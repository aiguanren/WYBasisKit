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
        state.thumbnail.isHidden = false
        wy_loadImage(asset, into: state.thumbnail)
    }

    func wy_showImage(_ asset: WYChatAssetsModel, height: CGFloat? = nil) {
        state.image.isHidden = false
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
            state.title.text = "▶  " + wy_duration(value.duration)
        case .music:
            guard let value = message.content.music else { return }
            wy_showThumbnail(value.thumbnailCover.localPath.isEmpty && value.thumbnailCover.downloadPath.isEmpty ? value.cover : value.thumbnailCover)
            state.title.text = "♫  " + value.name
            state.detail.text = [value.singer, value.composer].filter { !$0.isEmpty }.joined(separator: " · ")
            state.footer.text = wy_duration(value.duration)
        case .voice:
            guard let value = message.content.voice else { return }
            state.title.text = (value.isPlaying ? "Ⅱ  " : "▶  ") + wy_duration(value.duration) + (value.played ? "" : "  •")
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
