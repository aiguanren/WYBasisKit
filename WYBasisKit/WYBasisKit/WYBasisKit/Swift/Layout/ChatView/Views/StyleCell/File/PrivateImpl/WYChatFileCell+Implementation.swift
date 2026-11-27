//
//  WYChatFileCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatFileCell {
    func wy_fileRender() {
        guard let value = message.content.file else { return }
        state.title.text = value.title.isEmpty ? value.name : value.title
        state.detail.text = value.size
        state.footer.text = value.name
        wy_showThumbnail(value.icon, fallbackIcon: "WYChatViewFile", usesIconSize: true)
        if messageContentConfiguration.fileUsesTrailingIcon { wy_moveThumbnailToTrailing() }
    }
}
