//
//  WYEmojiViewCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYEmojiViewCellPrivateState {
    let emojiView: UIImageView = UIImageView()
    var emojiString: String = ""
}

extension WYEmojiViewCell {
    /// 表情面板长按预览的锚点。
    var emojiView: UIImageView { state.emojiView }
}
