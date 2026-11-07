//
//  WYEmojiPreviewView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit

private var previewView: WYEmojiPreviewView?

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

        let bundle = emojiViewConfig.emojiSourceBundle(for: emoji)

        if let gifInfo: WYGifInfo = UIImage.wy_animatedParse(.GIF, name: emoji, inBundle: bundle) {
            emojiView.image = gifInfo.animatedImage

        }else if let webpInfo: WYGifInfo = UIImage.wy_animatedParse(.WebP, name: emoji, inBundle: bundle) {
            emojiView.image = webpInfo.animatedImage

        }else if let apngInfo: WYGifInfo = UIImage.wy_animatedParse(.APNG, name: emoji, inBundle: bundle) {
            emojiView.image = apngInfo.animatedImage

        }else if let customImage: UIImage = emojiViewConfig.customImageLoader?(emoji, emojiViewConfig.emojiBundle) {
            emojiView.image = customImage

        }else {
            emojiView.image = emojiViewConfig.staticEmojiImage(emoji)
        }

        textView.text = WYLocalized(emoji.wy_substring(from: 1, to: emoji.count - 1), table: WYBasisKitConfig.kitLocalizableTable)
    }

    static func wy_impl_show(emoji: String, according: UIView) ->WYEmojiPreviewView? {

        releaseAll()

        guard emojiViewConfig.previewConfig.show == true else {
            return nil
        }

        previewView = WYEmojiPreviewView(emoji: emoji)
        UIViewController.wy_currentController()?.view.addSubview(previewView!)
        let offset: CGPoint = previewOffset(according: according, superView: previewView!.superview!)
        previewView?.snp.makeConstraints({ make in
            make.size.equalTo(emojiViewConfig.previewConfig.previewSize)
            make.top.equalToSuperview().offset(offset.y)
            make.left.equalToSuperview().offset(offset.x)
        })

        previewView?.show()

        return previewView
    }

    static func wy_impl_update(emoji: String, according: UIView) {

        guard let existPreview: WYEmojiPreviewView = previewView, let superView: UIView = existPreview.superview else {
            return
        }

        existPreview.updateContent(emoji)

        let offset: CGPoint = previewOffset(according: according, superView: superView)
        existPreview.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(offset.y)
            make.left.equalToSuperview().offset(offset.x)
        }
    }

    static func wy_impl_setHidden(_ hidden: Bool) {
        previewView?.isHidden = hidden
    }

    /// 依据锚定控件计算预览浮层的偏移(浮层显示在锚定控件正上方水平居中)
    static func previewOffset(according: UIView, superView: UIView) -> CGPoint {
        let offset: CGPoint = according.convert(according.frame.origin, to: superView)
        return CGPoint(x: offset.x + (according.wy_width / 2) - (emojiViewConfig.previewConfig.previewSize.width / 2), y: offset.y - emojiViewConfig.previewConfig.previewSize.height)
    }

    func show() {
        UIView.animate(withDuration: 0.25) {
            previewView?.alpha = 1.0
        }
    }

    static func wy_impl_dismiss() {

        guard previewView != nil else {
            return
        }

        UIView.animate(withDuration: 0.25) {
            previewView?.alpha = 0.0
        }completion: { _ in
            releaseAll()
        }
    }

    static func releaseAll() {
        previewView?.wy_removeAllSubviews()
        previewView?.removeFromSuperview()
        previewView = nil
    }
}

extension WYEmojiPreviewView {

    func wy_setupPreview(emoji: String) {

        isUserInteractionEnabled = true
        alpha = 0.0
        image = emojiViewConfig.previewConfig.backgroundImage

        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(emojiViewConfig.previewConfig.emojiSize)
            make.top.equalToSuperview().offset(emojiViewConfig.previewConfig.emojiTopOffset)
        }
        updateContent(emoji)

        textView.textColor = emojiViewConfig.previewConfig.textColor
        textView.font = emojiViewConfig.previewConfig.textFont
        textView.textAlignment = .center
        textView.adjustsFontSizeToFitWidth = true
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(UIDevice.wy_screenWidth(5))
            make.right.equalToSuperview().offset(UIDevice.wy_screenWidth(-5))
            make.top.equalTo(emojiView.snp.bottom).offset(emojiViewConfig.previewConfig.textTopOffsetWithEmoji)
        }
    }
}

extension WYEmojiPreviewView {

    func wy_dismissPreviewIfNeeded(_ hitView: UIView?) {
        if hitView != previewView {
            WYEmojiPreviewView.dismiss()
        }
    }
}
