//
//  WYChatBusinessCardCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatBusinessCardCell {
    func wy_businessCardRender() {
        guard let value = message.content.businessCard else { return }
        state.title.text = value.userInfo.name
        state.detail.text = value.remarks
        wy_showThumbnail(value.userInfo.avatar, fallbackIcon: "WYChatViewContact")
    }
}
