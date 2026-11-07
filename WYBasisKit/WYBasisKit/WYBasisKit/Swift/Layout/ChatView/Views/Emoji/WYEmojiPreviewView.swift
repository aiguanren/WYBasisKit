//
//  WYEmojiPreviewView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/27.
//

import UIKit

public struct WYEmojiPreviewConfig {
    
    /// Emoji表情是否需要支持长按预览详情
    public var show: Bool = true
    
    /// 表情预览控件的背景图
    public var backgroundImage: UIImage = UIImage.wy_find("WYChatEmojiPreview", inBundle: WYChatSourceBundle)
    
    /// 表情预览控件的size
    public var previewSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(120))
    
    /// 表情预览控件内Emoji的size
    public var emojiSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(30), height: UIDevice.wy_screenWidth(30))
    
    /// Emoji距离表情预览控件顶部的间距
    public var emojiTopOffset: CGFloat = UIDevice.wy_screenWidth(16)
    
    /// 表情预览控件内文本控件的字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12))
    
    /// 表情预览控件内文本控件的字体颜色
    public var textColor: UIColor = .wy_rgb(120, 120, 120)
    
    /// 表情预览控件内文本控件顶部距离Emoji控件底部的间距
    public var textTopOffsetWithEmoji: CGFloat = UIDevice.wy_screenWidth(5)

    public init() {}
}

public class WYEmojiPreviewView: UIImageView {

    init(emoji: String) {
        super.init(frame: .zero)
        wy_setupPreview(emoji: emoji)
    }

    @discardableResult
    public static func show(emoji: String, according: UIView) ->WYEmojiPreviewView? {
        return wy_impl_show(emoji: emoji, according: according)
    }

    /// 更新预览浮层的内容和位置(长按拖动切换表情时用，浮层不存在时不动作)
    public static func update(emoji: String, according: UIView) {
        wy_impl_update(emoji: emoji, according: according)
    }

    /// 轻量隐藏或恢复预览浮层(长按拖动滑出表情有效区时隐藏，滑回有效区恢复，不销毁浮层)
    public static func setHidden(_ hidden: Bool) {
        wy_impl_setHidden(hidden)
    }

    public static func dismiss() {
        wy_impl_dismiss()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView: UIView? = super.hitTest(point, with: event)
        wy_dismissPreviewIfNeeded(hitView)
        return hitView
    }
    
    internal let state = WYEmojiPreviewViewPrivateState()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
