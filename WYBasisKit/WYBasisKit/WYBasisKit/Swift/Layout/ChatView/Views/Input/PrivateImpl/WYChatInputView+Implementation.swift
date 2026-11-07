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
        let recordView: WYRecordAnimationView = WYRecordAnimationView(alpha: 1.0, delegate: self)
        superview?.addSubview(recordView)
        recordView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(recordAnimationConfig.recordViewBottomOffset)
        }
        return recordView
    }

    func wy_makeSpecialSendButton() -> UIButton? {

        guard inputBarConfig.showSpecialSendButton == true else {
            return nil
        }

        let specialSendButton: UIButton = UIButton(type: .custom)
        specialSendButton.wy_titleFont = inputBarConfig.specialSendButtonFont
        specialSendButton.wy_nTitle = inputBarConfig.specialSendButtonText
        specialSendButton.wy_title_nColor = inputBarConfig.specialSendButtonTextColor
        specialSendButton.setBackgroundImage(inputBarConfig.specialSendButtonImage, for: .normal)
        specialSendButton.layer.cornerRadius = inputBarConfig.specialSendButtonCornerRadius
        specialSendButton.layer.borderWidth = inputBarConfig.specialSendButtonBorderWidth
        specialSendButton.layer.borderColor = inputBarConfig.specialSendButtonBorderColor.cgColor
        specialSendButton.layer.masksToBounds = true
        specialSendButton.addTarget(self, action: #selector(didClickSendView(_:)), for: .touchUpInside)
        addSubview(specialSendButton)
        specialSendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-inputBarConfig.specialSendButtonRightOffset)
            make.centerX.equalTo(textVoiceContentView.snp.right).offset(inputBarConfig.specialSendButtonLeftOffset + (inputBarConfig.specialSendButtonSize.width / 2))
            make.centerY.equalTo(textVoiceContentView.snp.bottom).offset(-(inputBarConfig.specialSendButtonBottomOffset + (inputBarConfig.specialSendButtonSize.height / 2)))
            make.size.equalTo(CGSize.zero)
        }
        return specialSendButton
    }

    @objc func didClickTextVoiceView(sender: UIButton) {

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
        }else {
            textView.becomeFirstResponder()
        }

        updateContentViewHeight()

        delegate?.wy_didClickTextVoiceView?(isText: !sender.isSelected)
        saveLastInputViewStyle()
    }

    @objc func voiceViewLongPressMethod(_ sender: UILongPressGestureRecognizer) {

        guard ((eventsHandler?.wy_canManagerVoiceRecordEvents?(sender) ?? true) && textVoiceView.isSelected == true) else {
            return
        }
        /// 检查是否拥有麦克风权限
        wy_authorizeMicrophoneAccess(showSettingsAlert: true) { [weak self] authorized in

            guard let self = self else { return }
            guard authorized == true else { return }

            // 用户已授权使用麦克风，开始录音操作
            let point: CGPoint = sender.location(in: self.recordView)
            switch sender.state {
            case .began:
                self.isHidden = true
                self.recordView.start()
                break
            case .changed:
                self.isHidden = true
                // 传入坐标点，在内部切换选中目标
                self.recordView.switchStatus(point)
                break
            default:
                self.isHidden = false
                self.recordView.stop()
                break
            }
        }
    }

    @objc func didClickMoreView(sender: UIButton) {

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
                make.size.equalTo(hasText ? inputBarConfig.specialSendButtonSize : CGSize.zero)
            }
            self.specialSendButton?.superview?.layoutIfNeeded()
        }
    }

    func wy_impl_sharedEmojiAttributed(string: String) -> NSAttributedString {

        let attributed: NSMutableAttributedString = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: string, textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont, emojiTable: emojiViewConfig.emojiSource, sourceBundle: emojiViewConfig.emojiBundle, pattern: inputBarConfig.emojiPattern, customImageLoader: { emojiName, _ in emojiViewConfig.staticEmojiImage(emojiName) })
        attributed.wy_lineSpacing(inputBarConfig.textLineSpacing, alignment: .left)

        return attributed
    }

    func wy_impl_sharedEmojiAttributedText(attributed: NSAttributedString) -> NSAttributedString {
        let attributed: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributed).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont)
        attributed.wy_lineSpacing(inputBarConfig.textLineSpacing, alignment: .left)
        return attributed
    }

    func saveLastInputViewStyle() {
        UserDefaults.standard.setValue(textView.isHidden, forKey: canSaveLastInputViewStyleKey)
        UserDefaults.standard.synchronize()
    }

    func updateContentViewHeight() {

        let textHeight: CGFloat = textView.attributedText.wy_calculateHeight(controlWidth: textViewInputWidth()) + inputBarConfig.inputTextEdgeInsets.top + inputBarConfig.inputTextEdgeInsets.bottom

        var contentHeight: CGFloat = [textHeight,
                                      textView.contentSize.height,
                                      inputBarConfig.inputViewHeight]
            .max() ?? 0

        if (textVoiceView.isSelected == true) {
            contentHeight = inputBarConfig.inputViewHeight
        }

        textVoiceContentView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight > inputBarConfig.textViewMaxHeight ? inputBarConfig.textViewMaxHeight : contentHeight)
        }

        textView.contentSize = CGSize(width: self.textView.contentSize.width, height: contentHeight)
        updateTextViewOffset()
    }

    // 获取textView可输入的宽度
    func textViewInputWidth() -> CGFloat {
        if (inputBarConfig.showSpecialSendButton == true) {
            return ceil(UIDevice.wy_screenWidth - inputBarConfig.inputViewEdgeInsets.left - inputBarConfig.specialSendButtonLeftOffset - inputBarConfig.specialSendButtonRightOffset - inputBarConfig.specialSendButtonSize.width - inputBarConfig.inputTextEdgeInsets.left - inputBarConfig.inputTextEdgeInsets.right - UIDevice.wy_screenWidth(10))
        }else {
            return ceil(UIDevice.wy_screenWidth - inputBarConfig.inputViewEdgeInsets.left - inputBarConfig.inputViewEdgeInsets.right - inputBarConfig.inputTextEdgeInsets.left - inputBarConfig.inputTextEdgeInsets.right - UIDevice.wy_screenWidth(10))
        }
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

        if textView.attributedText.string.utf16.count > inputBarConfig.inputTextLength {
            let selectRange = textView.markedTextRange
            if let selectRange = selectRange {
                let position =  textView.position(from: (selectRange.start), offset: 0)
                if (position != nil) {
                    return
                }
            }
            let textContent = textView.attributedText.string
            let textNum = textContent.utf16.count - (textContent.utf16.count - textContent.count)
            if (textNum > inputBarConfig.inputTextLength) && (inputBarConfig.inputTextLength > 0) {
                textView.attributedText = textView.attributedText.attributedSubstring(from: NSMakeRange(0, (inputBarConfig.inputTextLength)))
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
        let targetHeight: CGFloat = ceil(((inputBarConfig.textFont.lineHeight + inputBarConfig.textLineSpacing) * CGFloat(target)) - inputBarConfig.textLineSpacing)

        // textView显示行数是否大于 target
        return (textHeight > targetHeight)
    }

    func wy_impl_processingTextViewDidChange(_ textView: UITextView, silence: Bool) {

        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: textView.selectedTextRange?.start ?? textView.beginningOfDocument)

        var emojiText: String = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string

        if inputBarConfig.canInputEmoji == false {
            emojiText = emojiText.wy_replaceEmoji(inputBarConfig.emojiReplacement)
            textView.text = emojiText
        }

        textView.attributedText = sharedEmojiAttributed(string: emojiText)

        checkTextCount()

        emojiText = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string

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

        UserDefaults.standard.setValue(emojiText, forKey: canSaveLastInputTextKey)
        UserDefaults.standard.synchronize()

        updateTextViewOffset()
    }

    func wy_impl_textViewDidChange(_ textView: UITextView, silence: Bool) {

        // 以下获取键盘输入模式及判断selectedRange相关目的是为了解决textViewDidChange回调两次的问题

        // 获取键盘输入模式
        let primaryLanguage: String = textView.textInputMode?.primaryLanguage ?? ""

        // 九宫格输入
        if inputBarConfig.primaryLanguage.contains(primaryLanguage) {
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
        let emojiText: String = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string

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

        // 点击换行
        if text == "\n" {

            if inputBarConfig.showSpecialSendButton == true {
                return true
            }else {
                didClickSendView()
                return false
            }
        }

        let textContent = textView.attributedText.string + text
        let textNum = textContent.utf16.count - (textContent.utf16.count - textContent.count)

        if textView.attributedText.string.utf16.count > inputBarConfig.inputTextLength {
            let selectRange = textView.markedTextRange
            if let selectRange = selectRange {
                let position =  textView.position(from: (selectRange.start), offset: 0)
                if (position != nil) {
                    return true
                }
            }
        }

        checkTextCount()

        if (textNum > inputBarConfig.inputTextLength) && (inputBarConfig.inputTextLength > 0) {
            return false
        }

        if textRowGreaterThan(row: inputBarConfig.inputTextMaximumNumberOfLines, attributedText: sharedEmojiAttributed(string: textContent)) {
            return false
        }

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

        isUserInteractionEnabled = true
        backgroundColor = .clear
        image = inputBarConfig.backgroundImage

        textVoiceContentView.setBackgroundImage(inputBarConfig.voiceViewBackgroundImage, for: .normal)
        textVoiceContentView.setBackgroundImage(inputBarConfig.textViewBackgroundImage, for: .selected)
        textVoiceContentView.setBackgroundImage(inputBarConfig.voiceViewBackgroundImageForHighlighted, for: .highlighted)
        textVoiceContentView.wy_nTitle = inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_sTitle = inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_hTitle = inputBarConfig.voicePlaceholder
        textVoiceContentView.wy_titleFont = inputBarConfig.voicePlaceholderFont
        textVoiceContentView.wy_title_nColor = inputBarConfig.voicePlaceholderColor
        textVoiceContentView.wy_title_sColor = .clear
        textVoiceContentView.layer.cornerRadius = inputBarConfig.textViewCornerRadius
        textVoiceContentView.layer.borderWidth = inputBarConfig.textViewBorderWidth
        textVoiceContentView.layer.borderColor = inputBarConfig.textViewBorderColor.cgColor
        textVoiceContentView.layer.masksToBounds = true
        let longPresssGes = UILongPressGestureRecognizer(target: self, action: #selector(voiceViewLongPressMethod(_:)))
        // 指定该手势允许手指移动的最大距离，如果用户手指按下时移动且超过了该距离，则该手势失效
        longPresssGes.allowableMovement = inputBarConfig.recordViewLongPressMaxOffset
        textVoiceContentView.addGestureRecognizer(longPresssGes)
        addSubview(textVoiceContentView)
        textVoiceContentView.snp.makeConstraints { make in
            make.height.equalTo(inputBarConfig.inputViewHeight)
            make.left.equalToSuperview().offset(inputBarConfig.inputViewEdgeInsets.left)
            make.top.equalToSuperview().offset(inputBarConfig.inputViewEdgeInsets.top)
            if (inputBarConfig.showSpecialSendButton == true) {
                make.right.lessThanOrEqualToSuperview().offset(-inputBarConfig.inputViewEdgeInsets.right)
            }else {
                make.right.equalToSuperview().offset(-inputBarConfig.inputViewEdgeInsets.right)
            }
            make.bottom.equalToSuperview().offset(-inputBarConfig.inputViewEdgeInsets.bottom)
        }
        if inputBarConfig.canSaveLastInputViewStyle == true {
            textVoiceContentView.isSelected = !(UserDefaults.standard.value(forKey: canSaveLastInputViewStyleKey) as? Bool ?? false)
        }else {
            textVoiceContentView.isSelected = true
        }

        specialSendButton?.isHidden = inputBarConfig.showSpecialSendButton

        textView.backgroundColor = .clear
        textView.font = inputBarConfig.textFont
        textView.tintColor = inputBarConfig.inputViewCurvesColor
        textView.keyboardType = inputBarConfig.chatKeyboardType
        textView.returnKeyType = inputBarConfig.chatReturnKeyType
        textView.bounces = inputBarConfig.textViewIsBounces
        textView.textContainerInset = inputBarConfig.inputTextEdgeInsets
        textView.textContainer.lineBreakMode = inputBarConfig.textLineBreakMode
        textView.textContainer.maximumNumberOfLines = inputBarConfig.inputTextMaximumNumberOfLines
        textView.isScrollEnabled = inputBarConfig.textViewIsScrollEnabled
        if (eventsHandler?.wy_canManagerTextViewDelegateEvents?(textView, placeholderView: textPlaceholderView) ?? true) == true {
            textView.delegate = self
        }
        textVoiceContentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if inputBarConfig.canSaveLastInputText == true {
            textView.attributedText = sharedEmojiAttributed(string: UserDefaults.standard.value(forKey: canSaveLastInputTextKey) as? String ?? "")
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

        if inputBarConfig.canSaveLastInputViewStyle == true {
            textView.isHidden = UserDefaults.standard.value(forKey: canSaveLastInputViewStyleKey) as? Bool ?? false
        }

        textPlaceholderView.text = inputBarConfig.textPlaceholder
        textPlaceholderView.textColor = inputBarConfig.textPlaceholderColor
        textPlaceholderView.font = inputBarConfig.textPlaceholderFont
        textPlaceholderView.textAlignment = .left
        textPlaceholderView.backgroundColor = .clear
        textPlaceholderView.adjustsFontSizeToFitWidth = true
        textPlaceholderView.isHidden = (textView.attributedText.string.utf16.count > 0)
        textView.addSubview(textPlaceholderView)
        textPlaceholderView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(inputBarConfig.textPlaceholderOffset.x)
            make.top.equalToSuperview().offset(inputBarConfig.textPlaceholderOffset.y)
            make.right.lessThanOrEqualToSuperview().offset(-UIDevice.wy_screenWidth(5))
        }

        textVoiceView.wy_nImage = inputBarConfig.voiceButtonImage
        textVoiceView.wy_sImage = inputBarConfig.textBottomImage
        textVoiceView.wy_sTitle = inputBarConfig.voicePlaceholder
        textVoiceView.wy_title_sColor = inputBarConfig.voicePlaceholderColor
        textVoiceView.wy_titleFont = inputBarConfig.voicePlaceholderFont
        textVoiceView.isSelected = textView.isHidden
        textVoiceView.backgroundColor = .clear
        textVoiceView.addTarget(self, action: #selector(didClickTextVoiceView(sender:)), for: .touchUpInside)
        addSubview(textVoiceView)
        textVoiceView.snp.makeConstraints { make in
            make.size.equalTo(inputBarConfig.voiceTextButtonSize)
            make.right.equalTo(textVoiceContentView.snp.left).offset(-inputBarConfig.voiceTextButtonRightOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-inputBarConfig.voiceTextButtonBottomOffset)
        }

        emojiView.setBackgroundImage(inputBarConfig.emojiBottomImage, for: .normal)
        emojiView.setBackgroundImage(inputBarConfig.textBottomImage, for: .selected)
        emojiView.addTarget(self, action: #selector(didClickEmojiView(sender:)), for: .touchUpInside)
        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.size.equalTo(inputBarConfig.emojiTextButtonSize)
            make.left.equalTo(textVoiceContentView.snp.right).offset(inputBarConfig.emojiTextButtonLeftOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-inputBarConfig.emojiTextButtonBottomOffset)
        }

        moreView.setBackgroundImage(inputBarConfig.moreBottomImage, for: .normal)
        moreView.setBackgroundImage(inputBarConfig.moreBottomImage, for: .highlighted)
        moreView.addTarget(self, action: #selector(didClickMoreView(sender:)), for: .touchUpInside)
        if specialSendButton != nil {
            insertSubview(moreView, belowSubview: specialSendButton!)
        }else {
            addSubview(moreView)
        }

        moreView.snp.makeConstraints { make in
            make.size.equalTo(inputBarConfig.moreButtonSize)
            make.left.equalTo(textVoiceContentView.snp.right).offset(inputBarConfig.moreButtonLeftOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-inputBarConfig.moreButtonBottomOffset)
        }
        updateContentViewHeight()
    }
}
