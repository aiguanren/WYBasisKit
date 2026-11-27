//
//  WYChatMusicCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatMusicCell {
    func wy_musicRender() {
        guard let value = message.content.music else { return }
        wy_showThumbnail(value.thumbnailCover.localPath.isEmpty && value.thumbnailCover.downloadPath.isEmpty ? value.cover : value.thumbnailCover, fallbackIcon: "WYChatViewMusic")
        state.title.text = value.name
        state.detail.text = [value.singer, value.composer].filter { !$0.isEmpty }.joined(separator: messageContentConfiguration.detailsSeparator)
        state.footer.text = wy_duration(value.duration)
    }
}
