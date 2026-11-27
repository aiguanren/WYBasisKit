//
//  WYChatWebpageCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatWebpageCell {
    func wy_webpageRender() {
        guard let value = message.content.webpage else { return }
        state.title.text = value.title
        state.detail.text = value.remarks
        state.footer.text = value.name
        wy_showImage(value.cover, height: messageContentConfiguration.mediaSize.height * wy_chatNonnegative(messageContentConfiguration.webpageCoverHeightRatio))
    }
}
