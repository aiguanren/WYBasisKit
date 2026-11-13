//
//  WYChatInputView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit

let canSaveLastInputTextKey: String = "canSaveLastInputTextKey"

let canSaveLastInputViewStyleKey: String = "canSaveLastInputViewStyleKey"

extension WYChatInputView {

    func wy_makeRecordView() -> WYRecordAnimationView {
        hasCreatedRecordView = true
        let recordView: WYRecordAnimationView = WYRecordAnimationView(alpha: 0, delegate: self, configuration: recordAnimationConfig)
        recordView.resultHandler = { [weak self] url, duration, error in self?.recordingResultHandler?(url, duration, error) }
        recordView.recognizedTextHandler = { [weak self] text in self?.delegate?.wy_didClickKeyboardEvent?(text: text) }
        superview?.addSubview(recordView)
        recordView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(self.recordAnimationConfig.recordViewBottomOffset)
        }
        return recordView
    }

    func wy_makeSpecialSendButton() -> UIButton? {

        guard self.inputBarConfig.showSpecialSendButton == true else {
            return nil
        }

        let specialSendButton: UIButton = UIButton(type: .custom)
        specialSendButton.wy_titleFont = self.inputBarConfig.specialSendButtonFont
        specialSendButton.wy_nTitle = self.inputBarConfig.specialSendButtonText
        specialSendButton.wy_title_nColor = self.inputBarConfig.specialSendButtonTextColor
        specialSendButton.setBackgroundImage(self.inputBarConfig.specialSendButtonImage, for: .normal)
        specialSendButton.layer.cornerRadius = self.inputBarConfig.specialSendButtonCornerRadius
        specialSendButton.layer.borderWidth = self.inputBarConfig.specialSendButtonBorderWidth
        specialSendButton.layer.borderColor = self.inputBarConfig.specialSendButtonBorderColor.cgColor
        specialSendButton.layer.masksToBounds = true
        specialSendButton.accessibilityIdentifier = "WYChatInput.send"
        specialSendButton.addTarget(self, action: #selector(didClickSendView(_:)), for: .touchUpInside)
        addSubview(specialSendButton)
        specialSendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-self.inputBarConfig.specialSendButtonRightOffset)
            make.centerX.equalTo(textVoiceContentView.snp.right).offset(self.inputBarConfig.specialSendButtonLeftOffset + (self.inputBarConfig.specialSendButtonSize.width / 2))
            make.centerY.equalTo(textVoiceContentView.snp.bottom).offset(-(self.inputBarConfig.specialSendButtonBottomOffset + (self.inputBarConfig.specialSendButtonSize.height / 2)))
            make.size.equalTo(CGSize.zero)
        }
        return specialSendButton
    }

    @objc func didClickTextVoiceView(sender: UIButton) {
        wy_stopInputDictation(cancel: true)

        guard (eventsHandler?.wy_canManagerTextVoiceViewEvents?(sender) ?? true) else {
            return
        }

        sender.isSelected = !sender.isSelected
        textVoiceContentView.isSelected = !sender.isSelected
        textView.isHidden = !textVoiceContentView.isSelected
        emojiView.isSelected = false
        moreView.isSelected = false

        if sender.isSelected {
            textView.resignFirstResponder()
            let prepareSpeech: () -> Void = { [weak self] in
                guard let self, self.textVoiceView.isSelected, self.recordAnimationConfig.supportSpeechRecognition, self.recordAnimationConfig.speechRecognitionSource == .apple else { return }
                wy_authorizeSpeechRecognition(showSettingsAlert: false) { _ in }
            }
            if recordAnimationConfig.recorder == nil {
                wy_authorizeMicrophoneAccess(showSettingsAlert: false) { granted in if granted { prepareSpeech() } }
            } else { prepareSpeech() }
        }else {
            textView.becomeFirstResponder()
        }

        updateContentViewHeight()

        delegate?.wy_didClickTextVoiceView?(isText: !sender.isSelected)
        saveLastInputViewStyle()
    }

    @objc func voiceViewLongPressMethod(_ sender: UILongPressGestureRecognizer) {
        guard eventsHandler?.wy_canManagerVoiceRecordEvents?(sender) ?? true, textVoiceView.isSelected else { return }
        switch sender.state {
        case .began:
            let identifier = UUID()
            recordingGestureID = identifier
            let begin: (Bool) -> Void = { [weak self, weak sender] authorized in
                guard let self, let sender, authorized, self.recordingGestureID == identifier, sender.state == .began || sender.state == .changed else { return }
                self.recordView.recordAnimationConfig = self.recordAnimationConfig
                self.recordView.start()
            }
            if recordAnimationConfig.recorder != nil { begin(true) }
            else { wy_authorizeMicrophoneAccess(showSettingsAlert: true) { granted in begin(granted) } }
        case .changed:
            if recordView.state.requestID != nil { recordView.switchStatus(sender.location(in: recordView)) }
        case .ended:
            recordingGestureID = nil
            recordView.stop()
        case .cancelled, .failed:
            recordingGestureID = nil
            recordView.state.discard = true
            recordView.stop()
        default: break
        }
    }

    @objc func voiceButtonDictationLongPress(_ sender: UILongPressGestureRecognizer) {
        let enabled = sender.view === placeholderGate ? inputBarConfig.enablesPlaceholderDictation && inputBarConfig.textPlaceholderAlignment == .center : inputBarConfig.enablesVoiceButtonDictation
        guard enabled, recordAnimationConfig.supportSpeechRecognition,
              eventsHandler?.wy_canManagerVoiceRecordEvents?(sender) ?? true else { return }
        switch sender.state {
        case .began:
            let identifier = UUID()
            recordingGestureID = identifier
            let begin: (Bool) -> Void = { [weak self, weak sender] authorized in
                guard let self, let sender, authorized, self.recordingGestureID == identifier, sender.state == .began || sender.state == .changed else { return }
                self.textView.resignFirstResponder()
                self.recordView.recordAnimationConfig = self.recordAnimationConfig
                self.recordView.start(mode: .dictation)
            }
            if recordAnimationConfig.recorder != nil { begin(true) }
            else { wy_authorizeMicrophoneAccess(showSettingsAlert: true) { begin($0) } }
        case .changed:
            if recordView.state.requestID != nil { recordView.switchStatus(sender.location(in: recordView)) }
        case .ended:
            recordingGestureID = nil
            recordView.stop()
        case .cancelled, .failed:
            recordingGestureID = nil
            recordView.state.discard = true
            recordView.stop()
        default: break
        }
    }

    @objc func didClickMoreView(sender: UIButton) {
        wy_stopInputDictation(cancel: true)

        guard (eventsHandler?.wy_canManagerMoreViewEvents?(sender) ?? true) else {
            return
        }

        sender.isSelected = !sender.isSelected

        textVoiceContentView.isSelected = true
        textView.isHidden = false
        textVoiceView.isSelected = false
        emojiView.isSelected = false

        if sender.isSelected {
            if textView.canResignFirstResponder {
                textView.resignFirstResponder()
            }
        }else {
            if textView.canBecomeFirstResponder {
                textView.becomeFirstResponder()
            }
        }
        updateContentViewHeight()

        delegate?.wy_didClickMoreView?(isText: !sender.isSelected)
        saveLastInputViewStyle()
    }

    @objc func didClickEmojiView(sender: UIButton) {
        wy_stopInputDictation(cancel: true)

        guard (eventsHandler?.wy_canManagerTextEmojiViewEvents?(sender) ?? true) else {
            return
        }

        sender.isSelected = !sender.isSelected

        textVoiceContentView.isSelected = true
        textView.isHidden = false
        textVoiceView.isSelected = false
        moreView.isSelected = false

        if sender.isSelected {
            if textView.canResignFirstResponder {
                textView.resignFirstResponder()
            }
        }else {
            if textView.canBecomeFirstResponder {
                textView.becomeFirstResponder()
            }
        }
        updateContentViewHeight()

        delegate?.wy_didClickEmojiTextView?(isText: !sender.isSelected)
        saveLastInputViewStyle()
    }

    func wy_impl_updateSpecialSendState(hasText: Bool) {

        guard specialSendButton != nil else {
            return
        }

        specialSendButton?.isHidden = false
        UIView.animate(withDuration: 0.25) { [weak self] in

            guard let self = self else {return}

            self.specialSendButton?.snp.updateConstraints { make in
                make.size.equalTo(hasText ? self.inputBarConfig.specialSendButtonSize : CGSize.zero)
            }
            self.specialSendButton?.superview?.layoutIfNeeded()
        }
    }

    func wy_impl_sharedEmojiAttributed(string: String) -> NSAttributedString {

        let attributed: NSMutableAttributedString = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: string, textColor: self.inputBarConfig.textColor, textFont: self.inputBarConfig.textFont, emojiTable: self.emojiViewConfig.emojiSource, sourceBundle: self.emojiViewConfig.emojiBundle, pattern: self.inputBarConfig.emojiPattern, customImageLoader: { emojiName, _ in self.emojiViewConfig.staticEmojiImage(emojiName) })
        attributed.wy_lineSpacing(self.inputBarConfig.textLineSpacing, alignment: .left)

        return attributed
    }

    func wy_impl_sharedEmojiAttributedText(attributed: NSAttributedString) -> NSAttributedString {
        let attributed: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributed).wy_convertEmojiAttributedString(textColor: self.inputBarConfig.textColor, textFont: self.inputBarConfig.textFont)
        attributed.wy_lineSpacing(self.inputBarConfig.textLineSpacing, alignment: .left)
        return attributed
    }

    func saveLastInputViewStyle() {
        guard !inputBarConfig.draftStorageKey.isEmpty else { return }
        UserDefaults.standard.setValue(textView.isHidden, forKey: inputBarConfig.draftStorageKey + canSaveLastInputViewStyleKey)
        UserDefaults.standard.synchronize()
    }

    func updateContentViewHeight() {
        textVoiceContentView.isAccessibilityElement = textView.isHidden
        textVoiceContentView.accessibilityIdentifier = textView.isHidden ? "WYChatInput.record" : nil
        textVoiceContentView.accessibilityElements = textView.isHidden ? nil : [textView]

        let textHeight: CGFloat = textView.attributedText.wy_calculateHeight(controlWidth: textViewInputWidth()) + self.inputBarConfig.inputTextEdgeInsets.top + self.inputBarConfig.inputTextEdgeInsets.bottom

        var contentHeight: CGFloat = [textHeight,
                                      textView.contentSize.height,
                                      self.inputBarConfig.inputViewHeight]
            .max() ?? 0

        if (textVoiceView.isSelected == true) {
            contentHeight = self.inputBarConfig.inputViewHeight
        }

        textVoiceContentView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight > self.inputBarConfig.textViewMaxHeight ? self.inputBarConfig.textViewMaxHeight : contentHeight)
        }

        textView.contentSize = CGSize(width: self.textView.contentSize.width, height: contentHeight)
        updateTextViewOffset()
        wy_updateDictationControls()
    }

    // 获取textView可输入的宽度
    func textViewInputWidth() -> CGFloat {
        let width = textVoiceContentView.bounds.width > 0 ? textVoiceContentView.bounds.width : max(1, bounds.width - inputBarConfig.inputViewEdgeInsets.left - inputBarConfig.inputViewEdgeInsets.right)
        return max(1, width - inputBarConfig.inputTextEdgeInsets.left - inputBarConfig.inputTextEdgeInsets.right - wy_dictationReservedWidth)
    }

    func wy_impl_updateTextViewOffset() {
        if textView.attributedText.string.utf16.count > 0 {
            if textRowGreaterThan(row: 1) {
                textView.contentOffset = CGPoint(x: 0, y: textView.contentSize.height - textView.wy_height)
            }else {
                textView.contentOffset = CGPoint(x: 0, y: 0)
            }
        }
    }

    func checkTextCount() {

        if textView.attributedText.string.utf16.count > self.inputBarConfig.inputTextLength {
            let selectRange = textView.markedTextRange
            if let selectRange = selectRange {
                let position =  textView.position(from: (selectRange.start), offset: 0)
                if (position != nil) {
                    return
                }
            }
            let textContent = textView.attributedText.string
            let textNum = textContent.utf16.count - (textContent.utf16.count - textContent.count)
            if (textNum > self.inputBarConfig.inputTextLength) && (self.inputBarConfig.inputTextLength > 0) {
                textView.attributedText = textView.attributedText.attributedSubstring(from: NSMakeRange(0, (self.inputBarConfig.inputTextLength)))
            }
        }
    }

    /// 当前TextView文本显示的行数是否大于指定的行数
    func textRowGreaterThan(row target: Int, attributedText: NSAttributedString? = nil) -> Bool {

        // 如果0表示不限行数，直接返回false
        guard target > 0 else {
            return false
        }

        // textView可输入文本的宽度
        let textInputWidth: CGFloat = textViewInputWidth()

        let attributedString: NSAttributedString
        if let attributed = attributedText {
            attributedString = attributed
        }else {
            attributedString = textView.attributedText
        }

        // textView文本高度
        let textHeight: CGFloat = attributedString.wy_calculateHeight(controlWidth: textInputWidth)

        // 指定行数文本的高度
        let targetHeight: CGFloat = ceil(((self.inputBarConfig.textFont.lineHeight + self.inputBarConfig.textLineSpacing) * CGFloat(target)) - self.inputBarConfig.textLineSpacing)

        // textView显示行数是否大于 target
        return (textHeight > targetHeight)
    }

    func wy_impl_processingTextViewDidChange(_ textView: UITextView, silence: Bool) {

        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: textView.selectedTextRange?.start ?? textView.beginningOfDocument)

        var emojiText: String = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: self.inputBarConfig.textColor, textFont: self.inputBarConfig.textFont).string

        if self.inputBarConfig.canInputEmoji == false {
            emojiText = emojiText.wy_replaceEmoji(self.inputBarConfig.emojiReplacement)
            textView.text = emojiText
        }

        textView.attributedText = sharedEmojiAttributed(string: emojiText)

        checkTextCount()

        emojiText = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: self.inputBarConfig.textColor, textFont: self.inputBarConfig.textFont).string

        textPlaceholderView.isHidden = !emojiText.isEmpty
        if silence == false {
            delegate?.wy_textDidChanged?(text: emojiText)
        }
        updateContentViewHeight()

        if cursorPosition < textView.attributedText.string.utf16.count {
            let start: UITextPosition = textView.position(from: textView.beginningOfDocument, offset: cursorPosition)!
            let end: UITextPosition = textView.position(from: start, offset: 0)!
            textView.selectedTextRange = textView.textRange(from: start, to: end)
        }

        if !inputBarConfig.draftStorageKey.isEmpty { UserDefaults.standard.setValue(emojiText, forKey: inputBarConfig.draftStorageKey + canSaveLastInputTextKey) }
        UserDefaults.standard.synchronize()

        updateTextViewOffset()
    }

    func wy_impl_textViewDidChange(_ textView: UITextView, silence: Bool) {

        // 以下获取键盘输入模式及判断selectedRange相关目的是为了解决textViewDidChange回调两次的问题

        // 获取键盘输入模式
        let primaryLanguage: String = textView.textInputMode?.primaryLanguage ?? ""

        // 九宫格输入
        if self.inputBarConfig.primaryLanguage.contains(primaryLanguage) {
            // 拼音输入的时候 selectedRange 会有值 输入完成 selectedRange 会等于nil, 所以在输入完再进行相关的逻辑操作
            if textView.markedTextRange == nil {
                processingTextViewDidChange(textView, silence: silence)
            }else {
                // bar上的拼音监听
                textPlaceholderView.isHidden = true
            }
        }else {
            // 英文输入
            processingTextViewDidChange(textView, silence: silence)
        }
        updateSpecialSendState(hasText: textView.attributedText.string.utf16.count > 0)
    }

    func wy_impl_didClickSendView(_ sender: UIButton? = nil) {
        wy_stopInputDictation(cancel: true)
        let emojiText: String = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: self.inputBarConfig.textColor, textFont: self.inputBarConfig.textFont).string

        if emojiText.wy_replace(appointSymbol: "\n", replacement: "").count > 0 {
            delegate?.wy_didClickKeyboardEvent?(text: emojiText)
        }
    }

    @available(iOS, introduced: 10.0, deprecated: 17.0, message: "Use textView(_:primaryActionForTextItem:defaultAction:) instead")
    func wy_impl_textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        handleTextAttachmentSelection(in: textView, range: characterRange)
        return true
    }

    @available(iOS 17.0, *)
    func wy_impl_textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        // 使用 switch 语句处理不同的 content 类型
        switch textItem.content {
        case .textAttachment(_):

            // 处理文本附件
            handleTextAttachmentSelection(in: textView, range: textItem.range)

            return defaultAction

        case .tag(_):
            // 处理标签
            return defaultAction

        case .link(_):
            // 处理链接
            return defaultAction

        @unknown default:
            // 处理未来可能新增的类型
            return defaultAction
        }
    }

    func wy_impl_textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        emojiView.isSelected = false
        moreView.isSelected = false
        return true
    }

    func wy_impl_textViewDidChange(_ textView: UITextView) {
        textViewDidChange(textView, silence: false)
    }

    func wy_impl_textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !isApplyingDictationText { wy_stopInputDictation(cancel: true) }

        if text == "\n" && !inputBarConfig.showSpecialSendButton {
            didClickSendView()
            return false
        }
        if textView.markedTextRange != nil { textEditingHandler?(range, text); return true }
        let current = textView.attributedText.string as NSString
        guard range.location != NSNotFound, range.location >= 0, range.length >= 0, NSMaxRange(range) <= current.length else { return false }
        let candidate = current.replacingCharacters(in: range, with: text)
        let attributed = sharedEmojiAttributed(string: candidate)
        if inputBarConfig.inputTextLength > 0 && attributed.string.count > inputBarConfig.inputTextLength { return false }
        if textRowGreaterThan(row: inputBarConfig.inputTextMaximumNumberOfLines, attributedText: attributed) { return false }
        textEditingHandler?(range, text)
        return true
    }

    // 公共处理逻辑
    func handleTextAttachmentSelection(in textView: UITextView, range: NSRange) {

        if textView.isFirstResponder == false {
            textView.becomeFirstResponder()
        }

        // 安全地获取位置
        guard let start = textView.position(from: textView.beginningOfDocument, offset: range.location) else {
            // 如果无法获取起始位置，直接返回
            return
        }

        guard let end = textView.position(from: start, offset: 0) else {
            // 如果无法获取结束位置，直接返回
            return
        }

        textView.selectedTextRange = textView.textRange(from: start, to: end)
    }
}

extension WYChatInputView {

    func wy_setupInputView() {
        isAccessibilityElement = false
        textVoiceContentView.isAccessibilityElement = false
        textPlaceholderView.isAccessibilityElement = false

        isUserInteractionEnabled = true
        textView.accessibilityIdentifier = "WYChatInput.text"
        textVoiceView.accessibilityIdentifier = "WYChatInput.voice"
        emojiView.accessibilityIdentifier = "WYChatInput.emoji"
        moreView.accessibilityIdentifier = "WYChatInput.more"
        textVoiceView.accessibilityLabel = WYLocalized("语音输入", table: WYBasisKitConfig.kitLocalizableTable)
        emojiView.accessibilityLabel = WYLocalized("表情", table: WYBasisKitConfig.kitLocalizableTable)
        moreView.accessibilityLabel = WYLocalized("更多", table: WYBasisKitConfig.kitLocalizableTable)
        backgroundColor = .clear
        image = self.inputBarConfig.backgroundImage

        textVoiceContentView.setBackgroundImage(self.inputBarConfig.voiceViewBackgroundImage, for: .normal)
        textVoiceContentView.setBackgroundImage(self.inputBarConfig.textViewBackgroundImage, for: .selected)
        textVoiceContentView.setBackgroundImage(self.inputBarConfig.voiceViewBackgroundImageForHighlighted, for: .highlighted)
        textVoiceContentView.wy_nTitle = self.inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_sTitle = self.inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_hTitle = self.inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_titleFont = self.inputBarConfig.voicePlaceholderFont
        textVoiceContentView.wy_title_nColor = self.inputBarConfig.voicePlaceholderColor
        textVoiceContentView.wy_title_sColor = .clear
        textVoiceContentView.layer.cornerRadius = self.inputBarConfig.textViewCornerRadius
        textVoiceContentView.layer.borderWidth = self.inputBarConfig.textViewBorderWidth
        textVoiceContentView.layer.borderColor = self.inputBarConfig.textViewBorderColor.cgColor
        textVoiceContentView.layer.masksToBounds = true
        let longPresssGes = UILongPressGestureRecognizer(target: self, action: #selector(voiceViewLongPressMethod(_:)))
        // 指定该手势允许手指移动的最大距离，如果用户手指按下时移动且超过了该距离，则该手势失效
        longPresssGes.allowableMovement = self.inputBarConfig.recordViewLongPressMaxOffset
        textVoiceContentView.addGestureRecognizer(longPresssGes)
        addSubview(textVoiceContentView)
        textVoiceContentView.snp.makeConstraints { make in
            make.height.equalTo(self.inputBarConfig.inputViewHeight)
            make.left.equalToSuperview().offset(self.inputBarConfig.inputViewEdgeInsets.left)
            make.top.equalToSuperview().offset(self.inputBarConfig.inputViewEdgeInsets.top)
            if (self.inputBarConfig.showSpecialSendButton == true) {
                make.right.lessThanOrEqualToSuperview().offset(-self.inputBarConfig.inputViewEdgeInsets.right)
            }else {
                make.right.equalToSuperview().offset(-self.inputBarConfig.inputViewEdgeInsets.right)
            }
            make.bottom.equalToSuperview().offset(-self.inputBarConfig.inputViewEdgeInsets.bottom)
        }
        if self.inputBarConfig.canSaveLastInputViewStyle == true && !self.inputBarConfig.draftStorageKey.isEmpty {
            textVoiceContentView.isSelected = !(UserDefaults.standard.value(forKey: inputBarConfig.draftStorageKey + canSaveLastInputViewStyleKey) as? Bool ?? false)
        }else {
            textVoiceContentView.isSelected = true
        }

        specialSendButton?.isHidden = self.inputBarConfig.showSpecialSendButton

        textView.backgroundColor = .clear
        textView.font = self.inputBarConfig.textFont
        textView.tintColor = self.inputBarConfig.inputViewCurvesColor
        textView.keyboardType = self.inputBarConfig.chatKeyboardType
        textView.returnKeyType = self.inputBarConfig.chatReturnKeyType
        textView.bounces = self.inputBarConfig.textViewIsBounces
        textView.textContainerInset = self.inputBarConfig.inputTextEdgeInsets
        textView.textContainer.lineBreakMode = self.inputBarConfig.textLineBreakMode
        textView.textContainer.maximumNumberOfLines = self.inputBarConfig.inputTextMaximumNumberOfLines
        textView.isScrollEnabled = self.inputBarConfig.textViewIsScrollEnabled
        if (eventsHandler?.wy_canManagerTextViewDelegateEvents?(textView, placeholderView: textPlaceholderView) ?? true) == true {
            textView.delegate = self
        }
        textVoiceContentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if self.inputBarConfig.canSaveLastInputText == true && !self.inputBarConfig.draftStorageKey.isEmpty {
            textView.attributedText = sharedEmojiAttributed(string: UserDefaults.standard.value(forKey: inputBarConfig.draftStorageKey + canSaveLastInputTextKey) as? String ?? "")
            if (textView.attributedText.string.utf16.count > 0) && (textVoiceContentView.isSelected == true) {
                updateSpecialSendState(hasText: true)
                Task {
                    // 需延时调用 becomeFirstResponder()，否则键盘弹出初期 trait 未稳定，会出现暗色 → 浅色的瞬间渲染切换（闪烁问题）
                    try? await Task.wy_delay(0.5) {
                        self.textView.becomeFirstResponder()
                    }
                }
            }
        }

        if self.inputBarConfig.canSaveLastInputViewStyle == true && !self.inputBarConfig.draftStorageKey.isEmpty {
            textView.isHidden = UserDefaults.standard.value(forKey: inputBarConfig.draftStorageKey + canSaveLastInputViewStyleKey) as? Bool ?? false
        }

        textPlaceholderView.text = self.inputBarConfig.textPlaceholder
        textPlaceholderView.textColor = self.inputBarConfig.textPlaceholderColor
        textPlaceholderView.font = self.inputBarConfig.textPlaceholderFont
        textPlaceholderView.textAlignment = .left
        textPlaceholderView.backgroundColor = .clear
        textPlaceholderView.adjustsFontSizeToFitWidth = true
        textPlaceholderView.isHidden = (textView.attributedText.string.utf16.count > 0)
        textView.addSubview(textPlaceholderView)
        wy_setupDictationControls()

        textVoiceView.wy_nImage = self.inputBarConfig.voiceButtonImage
        textVoiceView.wy_sImage = self.inputBarConfig.textBottomImage
        textVoiceView.wy_sTitle = self.inputBarConfig.voicePlaceholder
        textVoiceView.wy_title_sColor = self.inputBarConfig.voicePlaceholderColor
        textVoiceView.wy_titleFont = self.inputBarConfig.voicePlaceholderFont
        textVoiceView.isSelected = textView.isHidden
        textVoiceView.backgroundColor = .clear
        textVoiceView.addTarget(self, action: #selector(didClickTextVoiceView(sender:)), for: .touchUpInside)
        let dictation = UILongPressGestureRecognizer(target: self, action: #selector(voiceButtonDictationLongPress(_:)))
        dictation.minimumPressDuration = max(0, inputBarConfig.voiceButtonLongPressDuration)
        dictation.allowableMovement = inputBarConfig.recordViewLongPressMaxOffset
        textVoiceView.addGestureRecognizer(dictation)
        addSubview(textVoiceView)
        textVoiceView.snp.makeConstraints { make in
            make.size.equalTo(self.inputBarConfig.voiceTextButtonSize)
            make.right.equalTo(textVoiceContentView.snp.left).offset(-self.inputBarConfig.voiceTextButtonRightOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-self.inputBarConfig.voiceTextButtonBottomOffset)
        }

        emojiView.setBackgroundImage(self.inputBarConfig.emojiBottomImage, for: .normal)
        emojiView.setBackgroundImage(self.inputBarConfig.textBottomImage, for: .selected)
        emojiView.addTarget(self, action: #selector(didClickEmojiView(sender:)), for: .touchUpInside)
        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.size.equalTo(self.inputBarConfig.emojiTextButtonSize)
            make.left.equalTo(textVoiceContentView.snp.right).offset(self.inputBarConfig.emojiTextButtonLeftOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-self.inputBarConfig.emojiTextButtonBottomOffset)
        }

        moreView.setBackgroundImage(self.inputBarConfig.moreBottomImage, for: .normal)
        moreView.setBackgroundImage(self.inputBarConfig.moreBottomImage, for: .highlighted)
        moreView.addTarget(self, action: #selector(didClickMoreView(sender:)), for: .touchUpInside)
        if specialSendButton != nil {
            insertSubview(moreView, belowSubview: specialSendButton!)
        }else {
            addSubview(moreView)
        }

        moreView.snp.makeConstraints { make in
            make.size.equalTo(self.inputBarConfig.moreButtonSize)
            make.left.equalTo(textVoiceContentView.snp.right).offset(self.inputBarConfig.moreButtonLeftOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-self.inputBarConfig.moreButtonBottomOffset)
        }
        wy_applyInputAppearance()
        updateContentViewHeight()
    }
}

/// 输入实例配置刷新
extension WYChatInputView {
    func wy_applyInputConfiguration() {
        if !inputBarConfig.enablesKeyboardDictation { wy_stopInputDictation(cancel: true) }
        wy_applyInputAppearance()
        textView.font = inputBarConfig.textFont
        textView.textColor = inputBarConfig.textColor
        textView.keyboardType = inputBarConfig.chatKeyboardType
        textView.returnKeyType = inputBarConfig.chatReturnKeyType
        textView.inputBarConfig = inputBarConfig
        textPlaceholderView.text = inputBarConfig.textPlaceholder
        textPlaceholderView.font = inputBarConfig.textPlaceholderFont
        textPlaceholderView.textColor = inputBarConfig.textPlaceholderColor
        wy_updateDictationControls()
        updateContentViewHeight()
    }
}
