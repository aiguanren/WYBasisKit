//
//  WYEmojiHeaderView+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYEmojiHeaderView {
    func wy_applyHeaderConfiguration() {
        backgroundColor = emojiViewConfig.headerBackgroundColor
        textView.textColor = emojiViewConfig.headerTextColor
        textView.font = emojiViewConfig.headerTextFont
        textView.textAlignment = emojiViewConfig.headerTextAlignment
        textView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(emojiViewConfig.headerTextOffset.x)
            make.right.equalToSuperview().offset(-emojiViewConfig.headerTextOffset.x)
            make.top.equalToSuperview().offset(emojiViewConfig.headerTextOffset.y)
        }
    }
}
