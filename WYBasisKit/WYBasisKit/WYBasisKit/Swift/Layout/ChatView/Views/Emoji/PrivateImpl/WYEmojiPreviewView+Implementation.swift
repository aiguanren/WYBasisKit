//
//  WYEmojiPreviewView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit


final class WYEmojiPreviewViewPrivateState {
    /// 表情图控件(长按拖动切换表情时只更新它的图片)
    let emojiView = UIImageView()
    /// 表情文本控件(长按拖动切换表情时只更新它的文本)
    let textView = UILabel()
}

extension WYEmojiPreviewView {

    var emojiView: UIImageView { return state.emojiView }

    var textView: UILabel { return state.textView }

    /// 更新预览的内容(依次尝试gif、webp、apng动图，都没有时走customImageLoader，最终降级静态图)
    func updateContent(_ emoji: String) {

        let bundle = self.emojiViewConfig.emojiSourceBundle(for: emoji)

        if let gifInfo: WYGifInfo = UIImage.wy_animatedParse(.GIF, name: emoji, inBundle: bundle) {
            emojiView.image = gifInfo.animatedImage

        }else if let webpInfo: WYGifInfo = UIImage.wy_animatedParse(.WebP, name: emoji, inBundle: bundle) {
            emojiView.image = webpInfo.animatedImage

        }else if let apngInfo: WYGifInfo = UIImage.wy_animatedParse(.APNG, name: emoji, inBundle: bundle) {
            emojiView.image = apngInfo.animatedImage

        }else if let customImage: UIImage = self.emojiViewConfig.customImageLoader?(emoji, self.emojiViewConfig.emojiBundle) {
            emojiView.image = customImage

        }else {
            emojiView.image = self.emojiViewConfig.staticEmojiImage(emoji)
        }

        textView.text = WYLocalized(emoji.wy_substring(from: 1, to: emoji.count - 1), table: WYBasisKitConfig.kitLocalizableTable)
    }

}

extension WYEmojiPreviewView {

    func wy_setupPreview(emoji: String) {

        isUserInteractionEnabled = true
        alpha = 0.0
        image = self.emojiViewConfig.previewConfig.backgroundImage

        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(self.emojiViewConfig.previewConfig.emojiSize)
            make.top.equalToSuperview().offset(self.emojiViewConfig.previewConfig.emojiTopOffset)
        }
        updateContent(emoji)

        textView.textColor = self.emojiViewConfig.previewConfig.textColor
        textView.font = self.emojiViewConfig.previewConfig.textFont
        textView.textAlignment = .center
        textView.adjustsFontSizeToFitWidth = true
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
            make.right.equalToSuperview().offset(UIDevice.wy_screenWidth(-5, WYBasisKitConfig.defaultScreenPixels))
            make.top.equalTo(emojiView.snp.bottom).offset(self.emojiViewConfig.previewConfig.textTopOffsetWithEmoji)
        }
    }
}
