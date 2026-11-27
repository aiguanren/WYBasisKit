//
//  WYEmojiFuncAreaView+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYEmojiFuncAreaConfig {

    var showsSendButton: Bool { !removeSendView && sendViewSize.width > 0 && sendViewSize.height > 0 }

    var actionAreaWidth: CGFloat {
        deleteViewLeftOffsetWithArea + deleteViewSize.width + sendViewRightOffset
            + (showsSendButton ? sendViewLeftOffsetWithDeleteView + sendViewSize.width : 0)
    }
}

final class WYEmojiFuncAreaViewPrivateState {
    var sendView: UIButton!
    var deleteView: UIButton!
    var longPressTimer: DispatchSourceTimer?
}

extension WYEmojiFuncAreaView {
    var sendView: UIButton! { state.sendView }
    var deleteView: UIButton! { state.deleteView }

    func wy_createFuncButton(text: String, textColorWithDisabled: UIColor, textColorWithEnable: UIColor, textColorWithHighly: UIColor, backgroundImageWithDisabled: UIImage, backgroundImageWithEnable: UIImage, backgroundImageWithHighly: UIImage, target: Any?, selector: Selector) -> UIButton {

        let button: UIButton = UIButton(type: .custom)
        button.wy_sTitle = text
        button.wy_nTitle = text
        button.wy_hTitle = text
        button.wy_title_sColor = textColorWithDisabled
        button.wy_title_nColor = textColorWithEnable
        button.wy_title_hColor = textColorWithHighly
        button.setBackgroundImage(backgroundImageWithDisabled, for: .selected)
        button.setBackgroundImage(backgroundImageWithEnable, for: .normal)
        button.setBackgroundImage(backgroundImageWithHighly, for: .highlighted)
        button.wy_cornerRadius(emojiViewConfig.funcAreaConfig.deleteViewAndSendViewCornerRadius).wy_showVisual()
        button.addTarget(target, action: selector, for: .touchUpInside)

        return button
    }

    func wy_didLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            cancelLongPressTimer()

            state.longPressTimer = DispatchSource.makeTimerSource()
            let interval = emojiViewConfig.funcAreaConfig.deleteRepeatInterval
            state.longPressTimer?.schedule(deadline: .now(), repeating: interval.isFinite ? max(0.05, interval) : WYEmojiFuncAreaConfig().deleteRepeatInterval)
            state.longPressTimer?.setEventHandler(handler: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.clickDeleteView()
                }
            })
            state.longPressTimer?.resume()
        }

        if (sender.state == .cancelled) || (sender.state == .ended) {
            cancelLongPressTimer()
        }
    }

    func wy_cancelLongPressTimer() {
        state.longPressTimer?.cancel()
        state.longPressTimer = nil
    }
}

extension WYEmojiFuncAreaView {
    func wy_setupFuncArea() {
        addSubview(gradualView)
        gradualView.snp.makeConstraints { make in
            make.top.width.right.equalToSuperview()
            make.height.equalTo(emojiViewConfig.funcAreaConfig.sendViewAndDeleteViewTopOffset)
        }
        gradualView.wy_makeVisual { make in
            let color = emojiViewConfig.backgroundColor
            let opacities = emojiViewConfig.funcAreaConfig.backgroundFadeOpacities.map {
                min(1, wy_chatNonnegative($0))
            }
            let colors = opacities.map { $0 == 1 ? color : color.withAlphaComponent($0) }
            if let first = colors.first {
                make.wy_gradualColors(colors.count == 1 ? [first, first] : colors)
            }
            make.wy_gradientDirection(.topToBottom)
        }

        let contentView: UIView = UIView()
        contentView.backgroundColor = emojiViewConfig.backgroundColor
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(emojiViewConfig.funcAreaConfig.sendViewAndDeleteViewTopOffset)
            make.left.equalTo(gradualView)
        }

        state.sendView = createFuncButton(text: emojiViewConfig.funcAreaConfig.sendViewText, textColorWithDisabled: emojiViewConfig.funcAreaConfig.sendViewTextColorWithDisabled, textColorWithEnable: emojiViewConfig.funcAreaConfig.sendViewTextColorWithEnable, textColorWithHighly: emojiViewConfig.funcAreaConfig.sendViewTextColorWithHighly, backgroundImageWithDisabled: emojiViewConfig.funcAreaConfig.sendViewImageWithDisabled, backgroundImageWithEnable: emojiViewConfig.funcAreaConfig.sendViewImageWithEnable, backgroundImageWithHighly: emojiViewConfig.funcAreaConfig.sendViewImageWithHighly, target: self, selector: #selector(clickSendView))
        state.sendView.wy_titleFont = emojiViewConfig.funcAreaConfig.sendViewFont
        let showsSendButton = emojiViewConfig.funcAreaConfig.showsSendButton
        state.sendView.isHidden = !showsSendButton
        contentView.addSubview(state.sendView)
        state.sendView.snp.makeConstraints { make in
            make.size.equalTo(showsSendButton ? emojiViewConfig.funcAreaConfig.sendViewSize : .zero)
            make.right.equalToSuperview().offset(-emojiViewConfig.funcAreaConfig.sendViewRightOffset)
            make.top.equalToSuperview()
        }

        state.deleteView = createFuncButton(text: emojiViewConfig.funcAreaConfig.deleteViewText, textColorWithDisabled: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithDisabled, textColorWithEnable: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithEnable, textColorWithHighly: emojiViewConfig.funcAreaConfig.deleteViewTextColorWithHighly, backgroundImageWithDisabled: emojiViewConfig.funcAreaConfig.deleteViewImageWithDisabled, backgroundImageWithEnable: emojiViewConfig.funcAreaConfig.deleteViewImageWithEnable, backgroundImageWithHighly: emojiViewConfig.funcAreaConfig.deleteViewImageWithHighly, target: self, selector: #selector(clickDeleteView))
        state.deleteView.wy_titleFont = emojiViewConfig.funcAreaConfig.deleteViewFont
        state.deleteView.accessibilityLabel = emojiViewConfig.funcAreaConfig.deleteViewText.isEmpty
            ? emojiViewConfig.funcAreaConfig.deleteAccessibilityLabel
            : emojiViewConfig.funcAreaConfig.deleteViewText
        if (emojiViewConfig.funcAreaConfig.longPressDelete == true) {
            let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(sender:)))
            let duration = emojiViewConfig.funcAreaConfig.longPressDeleteDuration
            longPress.minimumPressDuration = duration.isFinite ? max(0, duration) : WYEmojiFuncAreaConfig().longPressDeleteDuration
            state.deleteView.addGestureRecognizer(longPress)
        }
        contentView.addSubview(state.deleteView)
        state.deleteView.snp.makeConstraints { make in
            make.size.equalTo(emojiViewConfig.funcAreaConfig.deleteViewSize)
            make.right.equalTo(state.sendView.snp.left).offset(showsSendButton ? -emojiViewConfig.funcAreaConfig.sendViewLeftOffsetWithDeleteView : 0)
            make.top.equalToSuperview()
        }
    }
}
