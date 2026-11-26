//
//  WYChatInputView+Appearance.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 输入方式和按压状态对应的背景色
final class WYChatInputBackgroundButton: UIButton {
    var normalColor: UIColor = .clear { didSet { wy_updateAppearance() } }
    var selectedColor: UIColor = .clear { didSet { wy_updateAppearance() } }
    var highlightedColor: UIColor = .clear { didSet { wy_updateAppearance() } }
    var normalCornerRadius: CGFloat = 0 { didSet { wy_updateAppearance() } }
    var selectedCornerRadius: CGFloat = 0 { didSet { wy_updateAppearance() } }
    override var isSelected: Bool { didSet { wy_updateAppearance() } }
    override var isHighlighted: Bool { didSet { wy_updateAppearance() } }
    override func layoutSubviews() {
        super.layoutSubviews()
        wy_updateAppearance()
    }
    private func wy_updateAppearance() {
        backgroundColor = isHighlighted ? highlightedColor : isSelected ? selectedColor : normalColor
        let value = isSelected ? selectedCornerRadius : normalCornerRadius
        layer.cornerRadius = value.isFinite ? min(max(0, value), min(bounds.width, bounds.height) / 2) : 0
    }
}

/// 输入栏颜色和图标渲染
extension WYChatInputView {
    func wy_applyInputAppearance() {
        let config = inputBarConfig
        backgroundColor = config.backgroundColor
        image = config.backgroundImage
        if let content = textVoiceContentView as? WYChatInputBackgroundButton {
            content.normalCornerRadius = config.voiceViewCornerRadius
            content.selectedCornerRadius = config.textViewCornerRadius
            content.normalColor = config.voiceViewBackgroundColor
            content.selectedColor = config.textViewBackgroundColor
            content.highlightedColor = config.voiceViewHighlightedBackgroundColor
        }
        textVoiceContentView.setBackgroundImage(config.voiceViewBackgroundImage, for: .normal)
        textVoiceContentView.setBackgroundImage(config.textViewBackgroundImage, for: .selected)
        textVoiceContentView.setBackgroundImage(config.voiceViewBackgroundImageForHighlighted, for: .highlighted)
        textVoiceContentView.layer.borderColor = config.textViewBorderColor.resolvedColor(with: traitCollection).cgColor
        func icon(_ value: UIImage) -> UIImage { value.withRenderingMode(config.rendersIconsAsTemplate ? .alwaysTemplate : .alwaysOriginal) }
        for button in [textVoiceView, emojiView, moreView] {
            button.configuration = nil
            button.tintColor = config.iconTintColor
            (button as? WYChatInputIconButton)?.iconContentMode = config.iconContentMode
            for state in [UIControl.State.normal, .selected, .highlighted, [.selected, .highlighted]] {
                button.setBackgroundImage(nil, for: state)
                button.setTitle(nil, for: state)
            }
        }
        textVoiceView.setImage(icon(config.voiceButtonImage), for: .normal)
        textVoiceView.setImage(icon(config.textBottomImage), for: .selected)
        func preparedToggleIcon(_ image: UIImage) -> UIImage {
            guard image.cgImage != nil, image.images == nil else { return icon(image) }
            return icon(image.preparingForDisplay() ?? image)
        }
        let emoji = preparedToggleIcon(config.emojiBottomImage)
        let keyboard = preparedToggleIcon(config.textBottomImage)
        emojiView.setImage(emoji, for: .normal)
        emojiView.setImage(emoji, for: .highlighted)
        emojiView.setImage(keyboard, for: .selected)
        emojiView.setImage(keyboard, for: [.selected, .highlighted])
        moreView.setImage(icon(config.moreBottomImage), for: .normal)
        moreView.setImage(icon(config.moreBottomImage), for: .highlighted)
    }
}

/// 输入切换图标按按钮配置尺寸显示
class WYChatInputIconButton: UIButton {
    var iconContentMode: UIView.ContentMode = .scaleAspectFit { didSet { setNeedsLayout() } }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = bounds
        imageView?.contentMode = iconContentMode
    }
}

/// 表情和键盘的图标与输入面板分别更新，按压及切换状态时立即替换已准备好的图片。
final class WYChatEmojiToggleButton: WYChatInputIconButton {
    override var isSelected: Bool {
        get { super.isSelected }
        set {
            guard newValue != super.isSelected else { return }
            UIView.performWithoutAnimation {
                super.isSelected = newValue
                layoutIfNeeded()
            }
        }
    }

    override var isHighlighted: Bool {
        get { super.isHighlighted }
        set {
            guard newValue != super.isHighlighted else { return }
            UIView.performWithoutAnimation {
                super.isHighlighted = newValue
                layoutIfNeeded()
            }
        }
    }
}
