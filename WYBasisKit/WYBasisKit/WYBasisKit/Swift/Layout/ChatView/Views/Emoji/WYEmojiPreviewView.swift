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
    public var previewSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(120, WYBasisKitConfig.defaultScreenPixels))
    
    /// 表情预览控件内Emoji的size
    public var emojiSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(30, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(30, WYBasisKitConfig.defaultScreenPixels))
    
    /// Emoji距离表情预览控件顶部的间距
    public var emojiTopOffset: CGFloat = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)
    
    /// 表情预览控件内文本控件的字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
    
    /// 表情预览控件内文本控件的字体颜色
    public var textColor: UIColor = .wy_rgb(120, 120, 120)
    
    /// 表情预览控件内文本控件顶部距离Emoji控件底部的间距
    public var textTopOffsetWithEmoji: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    public init() {}
}

public class WYEmojiPreviewView: UIImageView {

    /// 当前实例配置
    public var emojiViewConfig: WYEmojiViewConfig = WYEmojiViewConfig()


    init(config: WYEmojiViewConfig = WYEmojiViewConfig(), emoji: String) {
        self.emojiViewConfig = config
        super.init(frame: .zero)
        wy_setupPreview(emoji: emoji)
    }

    /// 更新内容和锚定位置
    public func update(emoji: String, according: UIView) {
        updateContent(emoji)
        guard let parent = superview else { return }
        let rect = according.convert(according.bounds, to: parent)
        let size = emojiViewConfig.previewConfig.previewSize
        frame = CGRect(x: min(max(0, rect.midX - size.width / 2), max(0, parent.bounds.width - size.width)), y: max(0, rect.minY - size.height), width: size.width, height: size.height)
    }

    /// 关闭预览
    public func dismiss() { removeFromSuperview() }

    internal let state = WYEmojiPreviewViewPrivateState()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
