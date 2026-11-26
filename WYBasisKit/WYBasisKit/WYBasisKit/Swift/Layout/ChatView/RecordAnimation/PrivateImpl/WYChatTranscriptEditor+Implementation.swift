//
//  WYChatTranscriptEditor+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import Speech

final class WYChatTranscriptOverlay: UIView {
    weak var owner: WYRecordAnimationView?

    override func layoutSubviews() {
        super.layoutSubviews()
        owner?.wy_layoutTranscriptEditor()
    }
}

/// 按钮区域与图标尺寸独立，保留接入方提供的图片的宽高比。
final class WYChatTranscriptIconButton: UIButton {
    var iconSize: CGFloat = 0

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        guard let image = currentImage, image.size.width > 0, image.size.height > 0, currentTitle?.isEmpty != false else {
            return super.imageRect(forContentRect: contentRect)
        }
        let limit = max(0, min(iconSize, contentRect.width, contentRect.height))
        let scale = limit / max(image.size.width, image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return CGRect(x: contentRect.midX - size.width / 2, y: contentRect.midY - size.height / 2, width: size.width, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard currentImage != nil, currentTitle?.isEmpty != false else { return }
        imageView?.frame = imageRect(forContentRect: contentRect(forBounds: bounds))
    }
}

/// 转写编辑、语言切换与外部翻译
extension WYRecordAnimationView {
    var wy_editorPlainText: String {
        NSMutableAttributedString(attributedString: state.editText.attributedText ?? NSAttributedString(string: "")).wy_convertEmojiAttributedString(textColor: wy_captureConfiguration.recognitionTextColor, textFont: wy_captureConfiguration.recognitionFont).string
    }

    func wy_configureTranscriptEditor() {
        alpha = 1
        let config = wy_captureConfiguration.wy_withChatBackground(transcriptBackgroundColorProvider?())
        backgroundColor = config.recognitionOverlayBackgroundColor ?? config.overlayBackgroundColor
        wy_removeEditorEmoji()
        state.editPanel?.removeFromSuperview()
        if let guide = state.editorInputGuide { guide.owningView?.removeLayoutGuide(guide) }
        let container: UIView
        if presentsTranscriptInWindow, let window {
            let overlay = state.editorOverlay ?? WYChatTranscriptOverlay(frame: window.bounds)
            overlay.owner = self
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = backgroundColor
            overlay.accessibilityViewIsModal = true
            overlay.keyboardLayoutGuide.followsUndockedKeyboard = keyboardLayoutGuide.followsUndockedKeyboard
            if overlay.superview !== window { window.addSubview(overlay) }
            state.editorOverlay = overlay
            container = overlay
        } else {
            state.editorOverlay?.removeFromSuperview()
            state.editorOverlay = nil
            container = self
        }
        NSLayoutConstraint.deactivate(state.editorControlConstraints)
        state.editorControlConstraints.removeAll()
        func fixed(_ anchor: NSLayoutDimension, _ value: CGFloat) -> NSLayoutConstraint {
            let constraint = anchor.constraint(equalToConstant: value)
            if constraint.firstAttribute == .width { constraint.priority = UILayoutPriority(999) }
            constraint.isActive = true
            state.editorControlConstraints.append(constraint)
            return constraint
        }
        let panel = UIStackView()
        panel.axis = .vertical
        panel.spacing = max(0, config.recognitionControlSpacing)
        panel.backgroundColor = .clear
        panel.isLayoutMarginsRelativeArrangement = true
        panel.layoutMargins = config.recognitionPanelInsets
        panel.translatesAutoresizingMaskIntoConstraints = false
        state.editorDelegate.owner = self
        state.editText.delegate = state.editorDelegate
        state.editText.font = config.recognitionFont
        state.editText.textColor = config.recognitionTextColor
        state.editText.backgroundColor = config.recognitionTextBackgroundColor
        let textInsets = config.recognitionTextInsets
        state.editText.textContainerInset = UIEdgeInsets(top: 0, left: textInsets.left, bottom: 0, right: textInsets.right)
        state.editText.textContainer.lineFragmentPadding = 0
        state.editText.isScrollEnabled = true
        state.editText.accessibilityIdentifier = "WYChatRecording.editor"
        state.editText.returnKeyType = config.recognitionSendsOnReturn ? .send : .default
        state.editText.enablesReturnKeyAutomatically = config.recognitionSendsOnReturn
        let headerActions = [state.languageButton, state.translationButton, state.translationReadButton, state.translationLanguageButton, state.translationCancelButton]
        let footerActions = [state.retryButton, state.voiceButton, state.sendButton]
        let header = UIStackView(arrangedSubviews: [state.cancelButton, UIView()] + headerActions)
        let footer = UIStackView(arrangedSubviews: [state.editorEmojiButton, UIView(), state.retryButton, state.voiceButton, state.sendButton])
        header.alignment = .center
        footer.alignment = .center
        for row in [header, footer] { row.spacing = max(0, config.recognitionControlSpacing) }
        header.heightAnchor.constraint(equalToConstant: max(1, config.recognitionHeaderHeight)).isActive = true
        footer.heightAnchor.constraint(equalToConstant: max(1, config.recognitionControlHeight)).isActive = true
        _ = fixed(state.cancelButton.heightAnchor, max(1, config.recognitionHeaderHeight))
        _ = fixed(state.cancelButton.widthAnchor, max(0, config.recognitionAccessoryWidth))
        state.editorHeaderWidths = headerActions.map { button in
            _ = fixed(button.heightAnchor, max(1, config.recognitionHeaderHeight))
            return fixed(button.widthAnchor, max(0, config.recognitionHeaderButtonWidth))
        }
        _ = fixed(state.editorEmojiButton.widthAnchor, max(0, config.recognitionAccessoryWidth))
        state.editorActionWidths = footerActions.map { button in
            _ = fixed(button.heightAnchor, max(1, config.recognitionControlHeight))
            return fixed(button.widthAnchor, max(0, config.recognitionActionWidth))
        }
        _ = fixed(state.editorEmojiButton.heightAnchor, max(1, config.recognitionControlHeight))
        for button in [state.cancelButton, state.editorEmojiButton] + headerActions + footerActions {
            button.removeTarget(nil, action: nil, for: .touchUpInside)
            button.titleLabel?.font = config.recognitionControlFont
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = min(1, wy_chatNonnegative(config.recognitionControlMinimumScaleFactor))
            button.tintColor = config.recognitionControlColor
            button.setTitleColor(config.recognitionControlColor, for: .normal)
            button.backgroundColor = config.recognitionControlBackgroundColor
            button.layer.cornerRadius = max(0, config.recognitionControlCornerRadius)
        }
        state.cancelButton.setTitle(config.recognitionCloseImage == nil ? config.recognitionCancelText : nil, for: .normal)
        state.cancelButton.setImage(config.recognitionCloseImage, for: .normal)
        state.cancelButton.accessibilityLabel = config.recognitionCancelText
        state.cancelButton.accessibilityIdentifier = "WYChatRecording.close"
        state.cancelButton.addTarget(self, action: #selector(wy_cancelTranscript), for: .touchUpInside)
        state.retryButton.setTitle(config.recognitionRetryText, for: .normal)
        state.retryButton.accessibilityIdentifier = "WYChatRecording.retry"
        state.retryButton.addTarget(self, action: #selector(wy_retryTranscript), for: .touchUpInside)
        state.voiceButton.setTitle(config.recognitionSendVoiceText, for: .normal)
        state.voiceButton.isHidden = state.mode == .dictation || !config.showsOriginalVoiceButton
        state.voiceButton.isEnabled = state.transcriptionURL != nil
        state.voiceButton.accessibilityIdentifier = "WYChatRecording.sendVoice"
        state.voiceButton.addTarget(self, action: #selector(wy_sendOriginalRecording), for: .touchUpInside)
        state.sendButton.setTitle(config.recognitionSendText, for: .normal)
        state.sendButton.accessibilityIdentifier = "WYChatRecording.sendText"
        state.sendButton.addTarget(self, action: #selector(wy_sendTranscript), for: .touchUpInside)
        wy_updateEditorEmojiButton()
        state.editorEmojiButton.isHidden = !config.showsRecognitionEmojiButton
        state.editorEmojiButton.accessibilityIdentifier = "WYChatRecording.emoji"
        state.editorEmojiButton.addTarget(self, action: #selector(wy_toggleEditorEmoji), for: .touchUpInside)
        state.languageButton.isHidden = !config.showsRecognitionLanguageButton
        state.languageButton.setTitle(config.recognitionLanguageText, for: .normal)
        state.languageButton.accessibilityIdentifier = "WYChatRecording.language"
        let languages = config.speechRecognitionLanguages.isEmpty ? (config.speechRecognitionSource == .apple ? SFSpeechRecognizer.supportedLocales().map(\.identifier).sorted() : [config.speechLocaleIdentifier]) : config.speechRecognitionLanguages
        state.languageButton.menu = UIMenu(children: languages.map { identifier in
            UIAction(title: Locale.current.localizedString(forIdentifier: identifier) ?? identifier, state: identifier == config.speechLocaleIdentifier ? .on : .off) { [weak self] _ in self?.wy_changeRecognitionLanguage(to: identifier) }
        })
        state.languageButton.showsMenuAsPrimaryAction = true
        wy_configureTranslationControls()
        let bubble = WYAirBubbleView()
        bubble.fillColor = config.recognitionBackgroundColor.resolvedColor(with: container.traitCollection)
        bubble.cornerRadius = max(0, config.recognitionPanelCornerRadius)
        bubble.showsArrow = config.recognitionPanelShowsArrow
        bubble.arrowSize = config.recognitionPanelShowsArrow ? config.arrowSizeForMoveUp.transfer : .zero
        bubble.arrowTipRadius = config.arrowTipRadiusForMoveUp.transfer
        bubble.arrowDirection = .bottom
        bubble.arrowOffset = max(0, config.soundWavesViewWidth.transfer / 2 - config.moveUpButtonDiameter.onInterior / 2)
        if config.recognitionPanelShowsArrow, let image = config.bubbleArrowImage {
            bubble.showsArrow = false
            let view = UIImageView(image: image.withRenderingMode(config.bubbleArrowImageTintColor == nil ? .alwaysOriginal : .alwaysTemplate))
            view.tintColor = config.bubbleArrowImageTintColor
            view.contentMode = .scaleAspectFit
            view.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(view)
            NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: config.arrowSizeForMoveUp.transfer.width), view.heightAnchor.constraint(equalToConstant: config.arrowSizeForMoveUp.transfer.height), view.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: config.bubbleArrowImageOffset.y - wy_chatNonnegative(config.recognitionBubbleArrowOverlap)), view.centerXAnchor.constraint(equalTo: bubble.centerXAnchor, constant: bubble.arrowOffset + config.bubbleArrowImageOffset.x)])
        }
        bubble.translatesAutoresizingMaskIntoConstraints = false
        state.editText.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(state.editText)
        NSLayoutConstraint.activate([
            state.editText.topAnchor.constraint(equalTo: bubble.topAnchor, constant: max(0, textInsets.top)),
            state.editText.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            state.editText.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),
            state.editText.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -max(0, bubble.arrowSize.height) - max(0, textInsets.bottom))
        ])
        let leadingSpace = UIView()
        let trailingSpace = UIView()
        let failure = UIStackView(arrangedSubviews: [leadingSpace, state.editorFailureImage, state.editorFailureLabel, trailingSpace])
        failure.translatesAutoresizingMaskIntoConstraints = false
        failure.alignment = .center
        failure.spacing = max(0, config.recognitionControlSpacing)
        failure.isHidden = true
        state.editorFailureImage.contentMode = .scaleAspectFit
        state.editorFailureImage.image = config.recognitionFailureImage
        state.editorFailureImage.tintColor = config.recognitionFailureColor
        let iconSize = config.recognitionAccessoryImageSize.isFinite ? max(0, config.recognitionAccessoryImageSize) : 0
        state.editorFailureImage.isHidden = config.recognitionFailureImage == nil || iconSize == 0
        state.editorFailureLabel.text = config.recognitionFailureText
        state.editorFailureLabel.font = config.recognitionFont
        state.editorFailureLabel.textColor = config.recognitionFailureColor
        state.editorFailureLabel.numberOfLines = 0
        state.editorFailureLabel.textAlignment = config.recognitionFailureTextAlignment
        state.editorFailureLabel.accessibilityIdentifier = "WYChatRecording.failure"
        leadingSpace.widthAnchor.constraint(equalTo: trailingSpace.widthAnchor).isActive = true
        bubble.addSubview(failure)
        let insets = config.recognitionTextInsets
        NSLayoutConstraint.activate([
            failure.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: insets.left),
            failure.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -insets.right),
            failure.centerYAnchor.constraint(equalTo: bubble.centerYAnchor, constant: -max(0, bubble.arrowSize.height) / 2)
        ])
        _ = fixed(state.editorFailureImage.widthAnchor, iconSize)
        _ = fixed(state.editorFailureImage.heightAnchor, iconSize)
        state.editorFailureView = failure
        state.editorBubble = bubble
        panel.addArrangedSubview(header)
        panel.addArrangedSubview(bubble)
        panel.addArrangedSubview(footer)
        panel.setCustomSpacing(max(0, config.recognitionHeaderSpacing), after: header)
        panel.setCustomSpacing(max(0, config.recognitionFooterSpacing), after: bubble)
        for button in [state.cancelButton, state.editorEmojiButton] {
            button.backgroundColor = .clear
            button.tintColor = config.recognitionAccessoryColor
            button.setTitleColor(config.recognitionAccessoryColor, for: .normal)
            button.iconSize = iconSize
            button.imageView?.contentMode = .scaleAspectFit
        }
        state.sendButton.setTitleColor(config.recognitionSendColor, for: .normal)
        state.sendButton.backgroundColor = config.recognitionSendBackgroundColor
        let controls: [(WYChatRecordingEditorControl, UIButton)] = [(.close, state.cancelButton), (.language, state.languageButton), (.translation, state.translationButton), (.emoji, state.editorEmojiButton), (.retry, state.retryButton), (.originalVoice, state.voiceButton), (.send, state.sendButton), (.readTranslation, state.translationReadButton), (.changeTranslationLanguage, state.translationLanguageButton), (.cancelTranslation, state.translationCancelButton)]
        for (control, button) in controls { config.recognitionControlAppearance?(control, button) }
        config.recognitionEditorAppearance?(panel, state.editText, bubble, state.editorFailureLabel, state.editorFailureImage)
        container.addSubview(panel)
        let safeAreaLayoutGuide = container.safeAreaLayoutGuide
        let keyboardLayoutGuide = container.keyboardLayoutGuide
        let input = UILayoutGuide()
        container.addLayoutGuide(input)
        state.editorInputTop = input.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        state.editorKeyboardTop = input.topAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            input.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            input.widthAnchor.constraint(equalToConstant: 0),
            input.heightAnchor.constraint(equalToConstant: 0),
            state.editorKeyboardTop!
        ])
        state.editorInputGuide = input
        let top = config.recognitionPanelOuterInsets.top
        let bottom = -config.recognitionPanelOuterInsets.bottom
        let height = panel.heightAnchor.constraint(equalToConstant: max(1, config.recognitionMinimumHeight))
        height.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: top),
            panel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: config.recognitionPanelOuterInsets.left),
            panel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -config.recognitionPanelOuterInsets.right),
            panel.bottomAnchor.constraint(lessThanOrEqualTo: input.topAnchor, constant: bottom),
            height
        ])
        NSLayoutConstraint.deactivate(state.editorAlignmentConstraints)
        state.editorAlignmentConstraints = [panel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: top), panel.bottomAnchor.constraint(equalTo: input.topAnchor, constant: bottom), panel.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)]
        state.editorAlignmentConstraints.forEach { $0.priority = .defaultHigh }
        state.editorHeight = height
        state.editorHeader = header
        state.editorFooter = footer
        state.editPanel = panel
        panel.accessibilityIdentifier = "WYChatRecording.panel"
        wy_invalidateTranscriptLayout()
    }

    func wy_invalidateTranscriptLayout() {
        (state.editorOverlay as UIView? ?? self).setNeedsLayout()
    }

    func wy_layoutTranscriptEditor() {
        guard let panel = state.editPanel, !panel.isHidden, let container = panel.superview, container.bounds.width > 0 else { return }
        let bounds = container.bounds
        let safeAreaInsets = container.safeAreaInsets
        let keyboardLayoutGuide = container.keyboardLayoutGuide
        let config = wy_captureConfiguration
        if let bubble = state.editorBubble {
            let color = state.editorFailureView?.isHidden == false ? config.recognitionFailureBackgroundColor : config.recognitionBackgroundColor
            let fill = color.resolvedColor(with: container.traitCollection)
            if bubble.fillColor != fill { bubble.fillColor = fill }
        }
        let margins = panel.layoutMargins
        let width = max(1, bounds.width - safeAreaInsets.left - safeAreaInsets.right - config.recognitionPanelOuterInsets.left - config.recognitionPanelOuterInsets.right - margins.left - margins.right)
        func fitActions(_ widths: [NSLayoutConstraint], accessory: UIButton, preferredWidth: CGFloat, spacing: CGFloat) {
            let count = widths.filter { ($0.firstItem as? UIButton)?.isHidden == false }.count
            let accessoryWidth = accessory.isHidden ? 0 : max(0, config.recognitionAccessoryWidth)
            let gaps = CGFloat(count + (accessory.isHidden ? 0 : 1)) * max(0, spacing)
            let buttonWidth = min(max(0, preferredWidth), max(0, width - accessoryWidth - gaps) / CGFloat(max(1, count)))
            for constraint in widths where constraint.constant != buttonWidth { constraint.constant = buttonWidth }
        }
        fitActions(state.editorHeaderWidths, accessory: state.cancelButton, preferredWidth: config.recognitionHeaderButtonWidth, spacing: state.editorHeader?.spacing ?? 0)
        fitActions(state.editorActionWidths, accessory: state.editorEmojiButton, preferredWidth: config.recognitionActionWidth, spacing: state.editorFooter?.spacing ?? 0)
        let contentHeight: CGFloat
        if let failure = state.editorFailureView, !failure.isHidden {
            let insets = config.recognitionTextInsets
            let iconSize = state.editorFailureImage.isHidden ? 0 : max(0, config.recognitionAccessoryImageSize)
            let labelWidth = max(1, width - insets.left - insets.right - iconSize - (iconSize > 0 ? failure.spacing : 0))
            let labelHeight = state.editorFailureLabel.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude)).height
            contentHeight = max(labelHeight, iconSize) + insets.top + insets.bottom
        } else {
            contentHeight = state.editText.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
                + max(0, config.recognitionTextInsets.top) + max(0, config.recognitionTextInsets.bottom)
        }
        let textHeight = contentHeight + max(0, state.editorBubble?.arrowSize.height ?? 0)
        let controls = max(1, config.recognitionHeaderHeight) + max(1, config.recognitionControlHeight) + max(0, config.recognitionHeaderSpacing) + max(0, config.recognitionFooterSpacing) + margins.top + margins.bottom
        let safeBottom = bounds.height - safeAreaInsets.bottom
        let outerInsets = config.recognitionPanelOuterInsets
        let availableHeight = safeBottom - safeAreaInsets.top - outerInsets.top - outerInsets.bottom
        let emojiHeight = min(
            max(0, config.recognitionEmoji.contentHeight),
            max(0, availableHeight - max(config.recognitionMinimumHeight, controls))
        )
        if let constraint = state.editorEmojiHeight, constraint.constant != emojiHeight { constraint.constant = emojiHeight }
        let emojiTop = state.showsEditorEmoji ? -emojiHeight : 0
        if let constraint = state.editorEmojiTop, constraint.constant != emojiTop { constraint.constant = emojiTop }
        if state.showsEditorEmoji { state.editorInputTop?.constant = emojiTop }
        let guideTop = keyboardLayoutGuide.layoutFrame.minY
        let inputTop = state.editorInputTop?.isActive == true
            ? safeBottom + (state.editorInputTop?.constant ?? 0)
            : (guideTop > 0 ? guideTop : safeBottom)
        let available = max(1, inputTop - safeAreaInsets.top - outerInsets.top - outerInsets.bottom)
        let maximum = min(available, max(1, config.recognitionPanelHeight))
        let height = min(maximum, max(min(maximum, max(1, config.recognitionMinimumHeight)), textHeight + controls))
        if state.editorHeight?.constant != height { state.editorHeight?.constant = height }
    }

    func wy_updateTranscriptContent(_ text: String?, isRecognizing: Bool = false, failed: Bool = false) {
        let config = wy_captureConfiguration
        let isFailure = !isRecognizing && (failed || (text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true))
        let canEdit = !isRecognizing && !isFailure
        state.editorTranslationRequest = nil
        state.editorTranslatedLocale = nil
        if !canEdit {
            wy_removeEditorEmoji()
            state.editText.resignFirstResponder()
        }
        state.editText.text = isFailure ? nil : text
        state.editText.isHidden = isFailure
        state.editText.isEditable = canEdit
        state.editText.isSelectable = canEdit
        state.editorFailureView?.isHidden = !isFailure
        state.retryButton.isHidden = !isFailure || !config.showsRecognitionRetryButton
        state.sendButton.isHidden = false
        state.editorEmojiButton.isHidden = !config.showsRecognitionEmojiButton
        state.editorEmojiButton.isEnabled = canEdit
        NSLayoutConstraint.deactivate(state.editorAlignmentConstraints)
        let alignment = isFailure && config.recognitionCentersFailurePanel ? 2 : (config.recognitionPanelAnchorsToBottom ? 1 : 0)
        if state.editorAlignmentConstraints.indices.contains(alignment) { state.editorAlignmentConstraints[alignment].isActive = true }
        wy_updateEditorActions()
        if canEdit, !state.automaticallySendsTranscript, config.recognitionAutomaticallyFocusesText {
            let end = (state.editText.text as NSString?)?.length ?? 0
            state.editText.selectedRange = NSRange(location: end, length: 0)
            state.editText.becomeFirstResponder()
        }
        wy_invalidateTranscriptLayout()
    }

    func wy_editorTextChanged() {
        state.editorTranslationRequest = nil
        wy_updateEditorActions()
        wy_invalidateTranscriptLayout()
    }

    @objc func wy_toggleEditorEmoji() {
        guard state.editText.isEditable else { return }
        if state.showsEditorEmoji {
            if state.editText.isFirstResponder {
                state.editText.resignFirstResponder()
                state.editorKeyboardRequest = nil
            } else {
                state.editText.becomeFirstResponder()
            }
        } else {
            wy_setEditorEmojiVisible(true)
            state.editText.resignFirstResponder()
        }
    }

    func wy_requestEditorKeyboard() {
        guard state.showsEditorEmoji else { return }
        let request = UUID()
        state.editorKeyboardRequest = request
        DispatchQueue.main.asyncAfter(deadline: .now() + wy_chatNonnegative(wy_captureConfiguration.recognitionKeyboardNotificationTimeout)) { [weak self] in
            guard let self, self.state.editorKeyboardRequest == request else { return }
            self.wy_setEditorEmojiVisible(false, keyboardOffset: 0)
        }
    }

    func wy_setEditorEmojiVisible(_ visible: Bool, keyboardOffset: CGFloat = 0, notification: Notification? = nil) {
        guard visible != state.showsEditorEmoji, let panel = state.editPanel, let container = panel.superview else { return }
        let config = wy_captureConfiguration.wy_withChatBackground(transcriptBackgroundColorProvider?()).recognitionEmoji
        if state.editorEmoji == nil {
            let emoji = WYChatEmojiView(config: config)
            let background = UIView()
            background.backgroundColor = config.backgroundColor
            background.isUserInteractionEnabled = false
            background.translatesAutoresizingMaskIntoConstraints = false
            background.alpha = 0
            container.insertSubview(background, belowSubview: panel)
            emoji.delegate = state.editorDelegate
            emoji.translatesAutoresizingMaskIntoConstraints = false
            emoji.alpha = 0
            container.insertSubview(emoji, belowSubview: panel)
            let safeArea = container.safeAreaLayoutGuide
            let top = emoji.topAnchor.constraint(equalTo: safeArea.bottomAnchor)
            let height = emoji.heightAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([
                emoji.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
                emoji.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
                top, height,
                background.topAnchor.constraint(equalTo: emoji.topAnchor),
                background.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                background.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                background.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
            state.editorEmoji = emoji
            state.editorEmojiBackground = background
            state.editorEmojiTop = top
            state.editorEmojiHeight = height
        }
        guard let emoji = state.editorEmoji else { return }
        if visible { emoji.wy_refreshRecentlyEmoji() }
        container.layoutIfNeeded()
        state.editorKeyboardRequest = nil
        state.showsEditorEmoji = visible
        emoji.isHidden = false
        emoji.isUserInteractionEnabled = visible
        emoji.accessibilityElementsHidden = !visible
        if !visible { emoji.state.preview?.dismiss() }
        wy_updateEditorActions()
        let duration = config.animateDuration.isFinite && !UIAccessibility.isReduceMotionEnabled ? max(0, config.animateDuration) : 0
        UIView.transition(with: state.editorEmojiButton, duration: duration, options: [.transitionCrossDissolve, .beginFromCurrentState, .allowUserInteraction]) {
            self.wy_updateEditorEmojiButton()
        }
        let curve = (notification?.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, UIView.AnimationOptions(rawValue: curve << 16)]) {
            self.state.editorKeyboardTop?.isActive = false
            self.state.editorInputTop?.constant = -keyboardOffset
            self.state.editorInputTop?.isActive = true
            self.wy_layoutTranscriptEditor()
            emoji.alpha = visible ? 1 : 0
            self.state.editorEmojiBackground?.alpha = emoji.alpha
            container.layoutIfNeeded()
        } completion: { [weak self, weak emoji] finished in
            guard finished, let self, let emoji, self.state.editorEmoji === emoji else { return }
            emoji.isHidden = !self.state.showsEditorEmoji
            self.wy_finishEditorKeyboardLayout()
        }
    }

    func wy_removeEditorEmoji() {
        state.editorKeyboardRequest = nil
        guard let emoji = state.editorEmoji else { return }
        emoji.state.preview?.dismiss()
        emoji.removeFromSuperview()
        state.editorEmojiBackground?.removeFromSuperview()
        state.editorEmojiBackground = nil
        state.editorEmoji = nil
        state.editorEmojiTop = nil
        state.editorEmojiHeight = nil
        state.showsEditorEmoji = false
        state.editorInputTop?.isActive = false
        state.editorKeyboardTop?.isActive = true
        wy_updateEditorEmojiButton()
    }

    private func wy_updateEditorEmojiButton() {
        let config = wy_captureConfiguration
        let showsKeyboard = state.showsEditorEmoji
        let image = showsKeyboard ? config.recognitionKeyboardImage : config.recognitionEmojiImage
        let label = showsKeyboard ? config.recognitionKeyboardText : config.recognitionEmojiText
        state.editorEmojiButton.setImage(image, for: .normal)
        state.editorEmojiButton.setTitle(image == nil ? label : nil, for: .normal)
        state.editorEmojiButton.accessibilityLabel = label
    }

    func wy_insertEditorEmoji(_ emoji: String) {
        guard state.editText.isEditable else { return }
        let config = wy_captureConfiguration
        let value = NSMutableAttributedString(attributedString: state.editText.attributedText ?? NSAttributedString(string: ""))
        let insertion = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: emoji, textColor: config.recognitionTextColor, textFont: config.recognitionFont, emojiTable: config.recognitionEmoji.emojiSource, sourceBundle: config.recognitionEmoji.emojiBundle, customImageLoader: { name, _ in config.recognitionEmoji.staticEmojiImage(name) })
        let range = state.editText.selectedRange
        guard range.location <= value.length, range.length <= value.length - range.location else { return }
        value.replaceCharacters(in: range, with: insertion)
        state.editText.attributedText = value
        state.editText.selectedRange = NSRange(location: range.location + insertion.length, length: 0)
        wy_editorTextChanged()
    }

    func wy_changeRecognitionLanguage(to identifier: String) {
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, state.transcriptionURL != nil, state.requestID == nil else { return }
        recordAnimationConfig.speechLocaleIdentifier = identifier
        state.captureConfiguration?.speechLocaleIdentifier = identifier
        state.automaticallySendsTranscript = false
        recognitionLanguageChangedHandler?(identifier)
        wy_recognizeRecording(true)
    }

    private func wy_configureTranslationControls() {
        let config = wy_captureConfiguration
        let targets = config.translationTargetLanguages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        state.translationButton.setTitle(config.translationText, for: .normal)
        state.translationButton.accessibilityIdentifier = "WYChatRecording.translate"
        state.translationButton.menu = targets.count > 1 ? wy_translationMenu(.translate, targets: targets) : nil
        state.translationButton.showsMenuAsPrimaryAction = state.translationButton.menu != nil
        if state.translationButton.menu == nil {
            state.translationButton.addTarget(self, action: #selector(wy_didTapTranslate), for: .touchUpInside)
        }
        state.translationReadButton.setTitle(config.translationReadAloudText, for: .normal)
        state.translationReadButton.accessibilityIdentifier = "WYChatRecording.translationRead"
        state.translationReadButton.addTarget(self, action: #selector(wy_didTapReadTranslation), for: .touchUpInside)
        state.translationLanguageButton.setTitle(config.translationChangeLanguageText, for: .normal)
        state.translationLanguageButton.accessibilityIdentifier = "WYChatRecording.translationLanguage"
        state.translationLanguageButton.menu = targets.count > 1 ? wy_translationMenu(.changeLanguage, targets: targets) : nil
        state.translationLanguageButton.showsMenuAsPrimaryAction = state.translationLanguageButton.menu != nil
        if state.translationLanguageButton.menu == nil {
            state.translationLanguageButton.addTarget(self, action: #selector(wy_didTapTranslationLanguage), for: .touchUpInside)
        }
        state.translationCancelButton.setTitle(config.translationCancelText, for: .normal)
        state.translationCancelButton.accessibilityIdentifier = "WYChatRecording.translationCancel"
        state.translationCancelButton.addTarget(self, action: #selector(wy_didTapCancelTranslation), for: .touchUpInside)
    }

    private func wy_translationMenu(_ action: WYChatTranscriptTranslationAction, targets: [String]) -> UIMenu {
        UIMenu(children: targets.map { identifier in
            UIAction(title: Locale.current.localizedString(forIdentifier: identifier) ?? identifier) { [weak self] _ in
                self?.wy_requestTranslation(action, target: identifier)
            }
        })
    }

    func wy_updateEditorActions() {
        let config = wy_captureConfiguration
        let canEdit = state.editText.isEditable
        let hasText = !(state.editText.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let enablesTranslation = canEdit && config.enablesTranslation && config.transcriptTranslationHandler != nil
        let isTranslated = state.editorTranslatedLocale != nil
        state.sendButton.isEnabled = canEdit && hasText
        if let actions = state.editorEmoji?.funcAreaView {
            actions.deleteView.isUserInteractionEnabled = canEdit && state.editText.hasText
            actions.sendView.isUserInteractionEnabled = state.sendButton.isEnabled
            actions.updateFuncAreaStyle()
        }
        let opacity = config.recognitionDisabledActionOpacity.isFinite ? min(1, max(0, config.recognitionDisabledActionOpacity)) : 0.44
        state.sendButton.alpha = state.sendButton.isEnabled ? 1 : opacity
        state.editorEmojiButton.alpha = state.editorEmojiButton.isEnabled ? 1 : opacity
        state.languageButton.isHidden = !canEdit || !config.showsRecognitionLanguageButton || isTranslated
        state.translationButton.isHidden = !enablesTranslation || isTranslated
        state.translationButton.isEnabled = hasText
        state.translationReadButton.isHidden = !enablesTranslation || !isTranslated || !config.showsTranslationReadAloudButton
        state.translationReadButton.isEnabled = hasText
        state.translationLanguageButton.isHidden = !enablesTranslation || !isTranslated || !config.showsTranslationChangeLanguageButton
        state.translationCancelButton.isHidden = !enablesTranslation || !isTranslated || !config.showsTranslationCancelButton
    }

    @objc private func wy_didTapTranslate() {
        let config = wy_captureConfiguration
        translateRecognizedText(to: config.translationTargetLanguages.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? config.translationTargetLocaleIdentifier)
    }

    @objc private func wy_didTapReadTranslation() {
        if let locale = state.editorTranslatedLocale { wy_requestTranslation(.readAloud, target: locale) }
    }

    @objc private func wy_didTapTranslationLanguage() {
        if let locale = state.editorTranslatedLocale { wy_requestTranslation(.changeLanguage, target: locale) }
    }

    @objc private func wy_didTapCancelTranslation() { cancelTranslation() }

    func wy_requestTranslation(_ action: WYChatTranscriptTranslationAction, target: String) {
        let config = wy_captureConfiguration
        guard config.enablesTranslation, let handler = config.transcriptTranslationHandler,
              state.editPanel?.isHidden == false, state.editText.isEditable else { return }
        let locale = target.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = wy_editorPlainText
        guard !locale.isEmpty, action == .cancel || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let requestID = UUID().uuidString
        if action != .readAloud { state.editorTranslationRequest = (requestID, locale) }
        handler(self, action, requestID, text, config.translationSourceLocaleIdentifier, locale)
    }
}

/// 编辑文本与表情操作转发
final class WYChatTranscriptEditorDelegate: NSObject, UITextViewDelegate, WYChatEmojiViewDelegate {
    weak var owner: WYRecordAnimationView?
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        owner?.wy_requestEditorKeyboard()
        return true
    }
    func textViewDidChange(_ textView: UITextView) { owner?.wy_editorTextChanged() }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n", textView.markedTextRange == nil, let owner, owner.wy_captureConfiguration.recognitionSendsOnReturn else { return true }
        owner.wy_sendTranscript()
        return false
    }
    func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) {
        guard emojiView.dataSource.indices.contains(indexPath.section), emojiView.dataSource[indexPath.section].indices.contains(indexPath.item) else { return }
        owner?.wy_insertEditorEmoji(emojiView.dataSource[indexPath.section][indexPath.item])
    }
    func wy_didClickEmojiSendView(_ sendView: UIButton) { owner?.wy_sendTranscript() }
    func wy_didClickEmojiDeleteView(_ deleteView: UIButton) { owner?.state.editText.deleteBackward(); owner?.wy_editorTextChanged() }
}
