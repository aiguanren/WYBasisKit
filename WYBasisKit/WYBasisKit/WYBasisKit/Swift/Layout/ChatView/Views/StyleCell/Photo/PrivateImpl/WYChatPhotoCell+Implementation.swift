//
//  WYChatPhotoCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatPhotoCell {
    func wy_photoRender() {
        guard let value = message.content.photo else { return }
        state.title.isHidden = true
        let thumbnail = value.thumbnail
        wy_showImage(thumbnail.localPath.isEmpty && thumbnail.downloadPath.isEmpty && thumbnail.name.isEmpty ? value.original : thumbnail, isPhoto: true)
        state.preferredWidth?.constant = messageContentConfiguration.mediaSize.width
    }
}
