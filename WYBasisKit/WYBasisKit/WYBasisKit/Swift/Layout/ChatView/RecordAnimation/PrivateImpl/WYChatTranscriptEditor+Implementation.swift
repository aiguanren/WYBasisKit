//
//  WYChatTranscriptEditor+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import Speech

/// 转写编辑、语言切换与外部翻译
extension WYRecordAnimationView {
    var wy_editorPlainText: String {
        NSMutableAttributedString(attributedString: state.editText.attributedText ?? NSAttributedString(string: "")).wy_convertEmojiAttributedString(textColor: wy_captureConfiguration.recognitionTextColor, textFont: wy_captureConfiguration.recognitionFont).string
    }

    func wy_configureTranscriptEditor() {
        alpha = 1
        let config = wy_captureConfiguration
        state.editPanel?.removeFromSuperview()
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
        state.editText.textContainerInset = config.recognitionTextInsets
        state.editText.textContainer.lineFragmentPadding = 0
        state.editText.isScrollEnabled = true
        state.editText.accessibilityIdentifier = "WYChatRecording.editor"
        let header = UIStackView(arrangedSubviews: [state.cancelButton, UIView(), state.languageButton, state.translationButton])
        let footer = UIStackView(arrangedSubviews: [state.editorEmojiButton, UIView(), state.retryButton, state.voiceButton, state.sendButton])
        header.alignment = .center
        footer.alignment = .center
        for row in [header, footer] { row.spacing = max(0, config.recognitionControlSpacing) }
        header.heightAnchor.constraint(equalToConstant: max(1, config.recognitionHeaderHeight)).isActive = true
        footer.heightAnchor.constraint(equalToConstant: max(1, config.recognitionControlHeight)).isActive = true
        for button in [state.cancelButton, state.languageButton, state.translationButton] {
            _ = fixed(button.heightAnchor, max(1, config.recognitionHeaderHeight))
            _ = fixed(button.widthAnchor, max(0, button === state.cancelButton ? config.recognitionAccessoryWidth : config.recognitionHeaderButtonWidth))
        }
        _ = fixed(state.editorEmojiButton.widthAnchor, max(0, config.recognitionAccessoryWidth))
        state.editorActionWidths = [state.retryButton, state.voiceButton, state.sendButton].map { button in
            _ = fixed(button.heightAnchor, max(1, config.recognitionControlHeight))
            return fixed(button.widthAnchor, max(0, config.recognitionActionWidth))
        }
        _ = fixed(state.editorEmojiButton.heightAnchor, max(1, config.recognitionControlHeight))
        for button in [state.cancelButton, state.languageButton, state.translationButton, state.editorEmojiButton, state.retryButton, state.voiceButton, state.sendButton] {
            button.removeTarget(nil, action: nil, for: .touchUpInside)
            button.titleLabel?.font = config.recognitionControlFont
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.tintColor = config.recognitionControlColor
            button.setTitleColor(config.recognitionControlColor, for: .normal)
            button.backgroundColor = config.recognitionControlBackgroundColor
            button.layer.cornerRadius = max(0, config.recognitionControlCornerRadius)
        }
        state.cancelButton.setTitle(config.recognitionCloseImage == nil ? config.recognitionCancelText : nil, for: .normal)
        state.cancelButton.setImage(config.recognitionCloseImage, for: .normal)
        state.cancelButton.addTarget(self, action: #selector(wy_cancelTranscript), for: .touchUpInside)
        state.retryButton.setTitle(config.recognitionRetryText, for: .normal)
        state.retryButton.addTarget(self, action: #selector(wy_retryTranscript), for: .touchUpInside)
        state.voiceButton.setTitle(config.recognitionSendVoiceText, for: .normal)
        state.voiceButton.isHidden = state.mode == .dictation || !config.showsOriginalVoiceButton
        state.voiceButton.isEnabled = state.transcriptionURL != nil
        state.voiceButton.accessibilityIdentifier = "WYChatRecording.sendVoice"
        state.voiceButton.addTarget(self, action: #selector(wy_sendOriginalRecording), for: .touchUpInside)
        state.sendButton.setTitle(config.recognitionSendText, for: .normal)
        state.sendButton.accessibilityIdentifier = "WYChatRecording.sendText"
        state.sendButton.addTarget(self, action: #selector(wy_sendTranscript), for: .touchUpInside)
        state.editorEmojiButton.setImage(state.editText.inputView == nil ? config.recognitionEmojiImage : config.recognitionKeyboardImage, for: .normal)
        state.editorEmojiButton.isHidden = !config.showsRecognitionEmojiButton
        state.editorEmojiButton.accessibilityLabel = WYLocalized("表情", table: WYBasisKitConfig.kitLocalizableTable)
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
        state.translationButton.isHidden = !config.enablesTranslation
        state.translationButton.isEnabled = state.translationID == nil
        state.translationButton.setTitle(config.translationText, for: .normal)
        state.translationButton.accessibilityIdentifier = "WYChatRecording.translate"
        let targets = config.translationTargetLanguages.isEmpty ? [config.translationTargetLocaleIdentifier] : config.translationTargetLanguages
        state.translationButton.menu = UIMenu(children: targets.map { identifier in
            UIAction(title: Locale.current.localizedString(forIdentifier: identifier) ?? identifier) { [weak self] _ in self?.wy_translateTranscript(to: identifier) }
        })
        state.translationButton.showsMenuAsPrimaryAction = true
        state.editorStatusLabel.font = config.recognitionControlFont
        state.editorStatusLabel.textColor = config.recognitionTextColor
        state.editorStatusLabel.numberOfLines = 0
        state.editorStatusLabel.isHidden = state.translationID == nil
        let bubble = WYAirBubbleView()
        bubble.fillColor = config.recognitionBackgroundColor
        bubble.cornerRadius = max(0, config.recognitionPanelCornerRadius)
        bubble.arrowSize = config.arrowSizeForMoveUp.transfer
        bubble.arrowTipRadius = config.arrowTipRadiusForMoveUp.transfer
        bubble.arrowDirection = .bottom
        bubble.arrowOffset = max(0, config.soundWavesViewWidth.transfer / 2 - config.moveUpButtonDiameter.onInterior / 2)
        if let image = config.bubbleArrowImage {
            bubble.showsArrow = false
            let view = UIImageView(image: image.withRenderingMode(config.bubbleArrowImageTintColor == nil ? .alwaysOriginal : .alwaysTemplate))
            view.tintColor = config.bubbleArrowImageTintColor
            view.contentMode = .scaleAspectFit
            view.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(view)
            NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: config.arrowSizeForMoveUp.transfer.width), view.heightAnchor.constraint(equalToConstant: config.arrowSizeForMoveUp.transfer.height), view.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: config.bubbleArrowImageOffset.y - 1), view.centerXAnchor.constraint(equalTo: bubble.centerXAnchor, constant: bubble.arrowOffset + config.bubbleArrowImageOffset.x)])
        }
        bubble.translatesAutoresizingMaskIntoConstraints = false
        state.editText.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(state.editText)
        NSLayoutConstraint.activate([state.editText.topAnchor.constraint(equalTo: bubble.topAnchor), state.editText.leadingAnchor.constraint(equalTo: bubble.leadingAnchor), state.editText.trailingAnchor.constraint(equalTo: bubble.trailingAnchor), state.editText.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -max(0, bubble.arrowSize.height))])
        state.editorBubble = bubble
        panel.addArrangedSubview(header)
        panel.addArrangedSubview(state.editorStatusLabel)
        panel.addArrangedSubview(bubble)
        panel.addArrangedSubview(footer)
        panel.setCustomSpacing(max(0, config.recognitionHeaderSpacing), after: header)
        panel.setCustomSpacing(max(0, config.recognitionFooterSpacing), after: bubble)
        for button in [state.cancelButton, state.editorEmojiButton] {
            button.backgroundColor = .clear
            button.tintColor = config.recognitionAccessoryColor
            button.setTitleColor(config.recognitionAccessoryColor, for: .normal)
            button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: max(1, config.recognitionAccessoryImageSize)), forImageIn: .normal)
        }
        state.sendButton.setTitleColor(config.recognitionSendColor, for: .normal)
        state.sendButton.backgroundColor = config.recognitionSendBackgroundColor
        let controls: [(WYChatRecordingEditorControl, UIButton)] = [(.close, state.cancelButton), (.language, state.languageButton), (.translation, state.translationButton), (.emoji, state.editorEmojiButton), (.retry, state.retryButton), (.originalVoice, state.voiceButton), (.send, state.sendButton)]
        for (control, button) in controls { config.recognitionControlAppearance?(control, button) }
        addSubview(panel)
        state.editorBottom = panel.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: -config.recognitionPanelOuterInsets.bottom)
        state.editorHeight = panel.heightAnchor.constraint(equalToConstant: max(1, config.recognitionMinimumHeight))
        NSLayoutConstraint.activate([panel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: config.recognitionPanelOuterInsets.top), panel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: config.recognitionPanelOuterInsets.left), panel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -config.recognitionPanelOuterInsets.right), state.editorBottom!, state.editorHeight!])
        state.editPanel = panel
        setNeedsLayout()
    }

    func wy_layoutTranscriptEditor() {
        guard let panel = state.editPanel, !panel.isHidden, bounds.width > 0 else { return }
        let config = wy_captureConfiguration
        let width = max(1, bounds.width - safeAreaInsets.left - safeAreaInsets.right - config.recognitionPanelOuterInsets.left - config.recognitionPanelOuterInsets.right - config.recognitionPanelInsets.left - config.recognitionPanelInsets.right)
        let actionButtons = [state.retryButton, state.voiceButton, state.sendButton]
        let count = actionButtons.filter { !$0.isHidden }.count
        let accessory = state.editorEmojiButton.isHidden ? 0 : max(0, config.recognitionAccessoryWidth)
        let gaps = CGFloat(max(0, count + (state.editorEmojiButton.isHidden ? 0 : 1))) * max(0, config.recognitionControlSpacing)
        let actionWidth = min(max(0, config.recognitionActionWidth), max(0, width - accessory - gaps) / CGFloat(max(1, count)))
        for constraint in state.editorActionWidths where constraint.constant != actionWidth { constraint.constant = actionWidth }
        let textHeight = state.editText.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height + max(0, config.arrowSizeForMoveUp.transfer.height)
        let statusHeight = state.editorStatusLabel.isHidden ? 0 : state.editorStatusLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height + max(0, config.recognitionControlSpacing)
        let controls = max(1, config.recognitionHeaderHeight) + max(1, config.recognitionControlHeight) + max(0, config.recognitionHeaderSpacing) + max(0, config.recognitionFooterSpacing) + config.recognitionPanelInsets.top + config.recognitionPanelInsets.bottom + statusHeight
        let guideTop = keyboardLayoutGuide.layoutFrame.minY
        let available = max(1, (guideTop > 0 ? guideTop : bounds.height - safeAreaInsets.bottom) - safeAreaInsets.top - config.recognitionPanelOuterInsets.top - config.recognitionPanelOuterInsets.bottom)
        let maximum = min(available, max(1, config.recognitionPanelHeight))
        let height = min(maximum, max(min(maximum, max(1, config.recognitionMinimumHeight)), textHeight + controls))
        if state.editorHeight?.constant != height { state.editorHeight?.constant = height }
        state.editorEmoji?.frame.size.width = width
    }

    func wy_editorTextChanged() {
        wy_cancelTranslation()
        if state.editText.isEditable { state.sendButton.isEnabled = !wy_editorPlainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        setNeedsLayout()
    }

    @objc func wy_toggleEditorEmoji() {
        guard state.editText.isEditable else { return }
        if state.editText.inputView != nil { state.editText.inputView = nil }
        else {
            let emoji = WYChatEmojiView(config: wy_captureConfiguration.recognitionEmoji)
            emoji.frame = CGRect(x: 0, y: 0, width: bounds.width, height: max(1, wy_captureConfiguration.recognitionEmoji.contentHeight))
            emoji.delegate = state.editorDelegate
            state.editorEmoji = emoji
            state.editText.inputView = emoji
        }
        state.editorEmojiButton.setImage(state.editText.inputView == nil ? wy_captureConfiguration.recognitionEmojiImage : wy_captureConfiguration.recognitionKeyboardImage, for: .normal)
        state.editText.becomeFirstResponder()
        state.editText.reloadInputViews()
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

    func wy_translateTranscript(to identifier: String) {
        guard wy_captureConfiguration.enablesTranslation, state.editPanel?.isHidden == false, state.editText.isEditable else { return }
        wy_cancelTranslation()
        let text = wy_editorPlainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let config = wy_captureConfiguration
        guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, config.translationTimeout.isFinite, config.translationTimeout > 0,
              let provider = config.translationProvider,
              provider.responds(to: #selector(WYChatTextTranslator.wy_translateText(_:text:sourceLocaleIdentifier:targetLocaleIdentifier:completion:))) else {
            wy_finishTranslation(nil, error: NSError(domain: Self.translationErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: config.translationFailureText]))
            return
        }
        let request = UUID().uuidString
        state.translationID = request
        state.translationProvider = provider
        state.translationButton.isEnabled = false
        state.editorStatusLabel.text = config.translationWaitingText
        state.editorStatusLabel.isHidden = false
        setNeedsLayout()
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.state.translationID == request else { return }
            self.wy_cancelTranslation()
            self.wy_finishTranslation(nil, error: NSError(domain: Self.translationErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: config.translationFailureText]))
        }
        state.translationTimeoutWork = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + config.translationTimeout, execute: timeout)
        provider.wy_translateText?(request, text: text, sourceLocaleIdentifier: config.translationSourceLocaleIdentifier, targetLocaleIdentifier: identifier, completion: { [weak self] translated, error in
            DispatchQueue.main.async {
                guard let self, self.state.translationID == request else { return }
                self.state.translationID = nil
                self.state.translationProvider = nil
                self.state.translationTimeoutWork?.cancel()
                self.state.translationTimeoutWork = nil
                guard self.wy_editorPlainText.trimmingCharacters(in: .whitespacesAndNewlines) == text else { self.state.translationButton.isEnabled = true; self.state.editorStatusLabel.isHidden = true; return }
                let result = translated?.trimmingCharacters(in: .whitespacesAndNewlines)
                let failure = error ?? ((result?.isEmpty ?? true) ? NSError(domain: Self.translationErrorDomain, code: 3, userInfo: [NSLocalizedDescriptionKey: config.translationFailureText]) : nil)
                self.wy_finishTranslation(result, error: failure)
            }
        })
    }

    func wy_finishTranslation(_ text: String?, error: NSError?) {
        state.translationButton.isEnabled = true
        state.editorStatusLabel.isHidden = error == nil
        state.editorStatusLabel.text = error?.localizedDescription
        if error == nil, let text { state.editText.text = text; state.sendButton.isEnabled = !text.isEmpty }
        setNeedsLayout()
        translationResultHandler?(error == nil ? text : nil, error)
    }

    func wy_cancelTranslation() {
        let identifier = state.translationID
        let provider = state.translationProvider
        state.translationID = nil
        state.translationProvider = nil
        state.translationTimeoutWork?.cancel()
        state.translationTimeoutWork = nil
        state.translationButton.isEnabled = true
        state.editorStatusLabel.isHidden = true
        if let identifier { provider?.wy_cancelTranslation?(identifier) }
    }
}

/// 编辑文本与表情操作转发
final class WYChatTranscriptEditorDelegate: NSObject, UITextViewDelegate, WYChatEmojiViewDelegate {
    weak var owner: WYRecordAnimationView?
    func textViewDidChange(_ textView: UITextView) { owner?.wy_editorTextChanged() }
    func wy_didClickEmojiView(_ emojiView: WYChatEmojiView, indexPath: IndexPath) {
        guard emojiView.dataSource.indices.contains(indexPath.section), emojiView.dataSource[indexPath.section].indices.contains(indexPath.item) else { return }
        owner?.wy_insertEditorEmoji(emojiView.dataSource[indexPath.section][indexPath.item])
    }
    func wy_didClickEmojiSendView(_ sendView: UIButton) { owner?.wy_sendTranscript() }
    func wy_didClickEmojiDeleteView(_ deleteView: UIButton) { owner?.state.editText.deleteBackward(); owner?.wy_editorTextChanged() }
}
