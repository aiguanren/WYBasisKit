//
//  WYChatTextCell+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 文本消息内容
extension WYChatTextCell {
    func wy_setupText() {
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyView.insertArrangedSubview(textView, at: 0)
        state.title.isHidden = true
        wy_render()
    }

    func wy_renderText() {
        let value = configuration.text
        state.title.isHidden = true
        textView.font = value.textFont
        textView.textColor = value.textColor
        textView.isSelectable = value.isSelectable
        textView.dataDetectorTypes = value.dataDetectorTypes
        textView.textContainer.maximumNumberOfLines = max(0, value.textMaximumNumberOfLines)
        let emoji = configuration.emoji
        let attributed = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: message.content.text ?? "", textColor: value.textColor, textFont: value.textFont, emojiTable: emoji.emojiSource, sourceBundle: emoji.emojiBundle, pattern: configuration.input.emojiPattern, customImageLoader: { name, _ in emoji.staticEmojiImage(name) })
        attributed.wy_lineSpacing(value.textLineSpacing, alignment: .natural)
        textView.attributedText = attributed
    }
}
