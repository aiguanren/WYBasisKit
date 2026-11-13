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
    private func wy_updateAppearance() {
        backgroundColor = isHighlighted ? highlightedColor : isSelected ? selectedColor : normalColor
        let value = isSelected ? selectedCornerRadius : normalCornerRadius
        layer.cornerRadius = value.isFinite ? max(0, value) : 0
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
            button.imageView?.contentMode = .scaleAspectFit
            for state in [UIControl.State.normal, .selected, .highlighted, [.selected, .highlighted]] {
                button.setBackgroundImage(nil, for: state)
                button.setTitle(nil, for: state)
            }
        }
        textVoiceView.setImage(icon(config.voiceButtonImage), for: .normal)
        textVoiceView.setImage(icon(config.textBottomImage), for: .selected)
        emojiView.setImage(icon(config.emojiBottomImage), for: .normal)
        emojiView.setImage(icon(config.textBottomImage), for: .selected)
        moreView.setImage(icon(config.moreBottomImage), for: .normal)
        moreView.setImage(icon(config.moreBottomImage), for: .highlighted)
    }
}
