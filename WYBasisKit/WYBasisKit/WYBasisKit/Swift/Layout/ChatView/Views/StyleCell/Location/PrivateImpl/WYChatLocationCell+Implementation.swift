//
//  WYChatLocationCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatLocationCell {
    func wy_locationRender() {
        guard let value = message.content.location else { return }
        state.title.text = value.title.isEmpty ? value.address : value.title
        state.detail.text = state.title.text == value.address ? nil : value.address
        let radius = configuration.location.cornerRadius
        state.image.imageCornerRadius = radius.isFinite ? max(0, radius) : 0
        if configuration.location.showsPreviewBelowAddress, let index = bodyView.arrangedSubviews.firstIndex(of: state.image) {
            bodyView.removeArrangedSubview(state.header)
            bodyView.insertArrangedSubview(state.header, at: index)
        }
        wy_showImage(value.cover, previewPlaceholder: wy_locationPlaceholder)
    }

    func wy_locationPlaceholder() -> UIImage {
        let style = messageContentConfiguration
        let location = configuration.location
        let placeholder: UIImage
        let iconSize = location.placeholderIconSize
        state.image.placeholderContentMode = .scaleAspectFit
        if let custom = style.placeholderImage {
            placeholder = custom
        } else if let pin = location.placeholderImage {
            if let pixels = pin.cgImage, iconSize.isFinite, iconSize > 0 {
                let scale = CGFloat(max(pixels.width, pixels.height)) / iconSize
                placeholder = UIImage(cgImage: pixels, scale: scale, orientation: pin.imageOrientation).withRenderingMode(pin.renderingMode)
                state.image.placeholderContentMode = .center
            } else {
                placeholder = pin
            }
        } else {
            placeholder = UIImage()
        }
        state.image.generatedPlaceholder = placeholder
        state.image.placeholderCornerRadius = state.image.imageCornerRadius
        state.image.placeholderBackgroundColor = location.placeholderBackgroundColor
        return placeholder
    }
}
