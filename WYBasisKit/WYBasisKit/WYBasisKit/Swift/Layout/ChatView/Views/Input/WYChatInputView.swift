//
//  WYChatInputView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import SnapKit

public struct WYInputBarConfig {
    
    /// 草稿保存键，空字符串时不跨实例保存草稿
    public var draftStorageKey: String = ""

    /// 是否允许长按语音切换按钮直接转写，默认true，需要启用语音识别
    public var enablesVoiceButtonDictation: Bool = true
    /// 长按语音切换按钮开始转写的等待时间，单位秒
    public var voiceButtonLongPressDuration: TimeInterval = 0.35
    /// 文本占位对齐方式，居中且未编辑时支持长按转文字
    public var textPlaceholderAlignment: NSTextAlignment = .left
    /// 是否允许长按居中占位区域转文字，需要启用语音识别
    public var enablesPlaceholderDictation: Bool = true
    /// 是否在键盘展开时显示输入框内的语音识别按钮，需要启用语音识别
    public var enablesKeyboardDictation: Bool = true
    /// 输入框语音识别按钮图片
    public var keyboardDictationImage: UIImage? = UIImage(systemName: "waveform")
    /// 输入框语音识别进行中按钮图片
    public var keyboardDictationStopImage: UIImage? = UIImage(systemName: "stop.circle.fill")
    /// 输入框语音识别按钮尺寸
    public var keyboardDictationSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(26, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(26, WYBasisKitConfig.defaultScreenPixels))
    /// 输入框语音识别按钮内边距
    public var keyboardDictationInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels))
    /// 输入框语音识别按钮颜色
    public var keyboardDictationTintColor: UIColor = .label

    /// 录音按钮长按手势允许手指移动的最大距离
    public var recordViewLongPressMaxOffset: CGFloat = UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels)
    
    /// inputBar弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval = 0.25
    
    /// inputBar背景图
    public var backgroundImage: UIImage? = nil
    
    /// 输入栏背景色，背景图覆盖在此颜色上
    public var backgroundColor: UIColor = .secondarySystemBackground

    /// 文本输入框背景色
    public var textViewBackgroundColor: UIColor = .secondarySystemGroupedBackground

    /// 语音输入框背景色
    public var voiceViewBackgroundColor: UIColor = .secondarySystemGroupedBackground

    /// 语音输入框按压时的背景色
    public var voiceViewHighlightedBackgroundColor: UIColor = .tertiarySystemFill

    /// 输入栏图标颜色
    public var iconTintColor: UIColor = .label

    /// 是否用iconTintColor绘制输入栏图标，默认true
    public var rendersIconsAsTemplate: Bool = true

    /// 是否需要保存上次退出时输入框中的文本
    public var canSaveLastInputText: Bool = true

    /// 是否需要保存上次退出时输入框模式(语音输入还是文本输入)
    public var canSaveLastInputViewStyle: Bool = true
    
    /// 是否允许输入Emoji表情
    public var canInputEmoji: Bool = true

    /// 输入法自带的Emoji表情替换成什么字符(需要canInputEmoji为false才生效)
    public var emojiReplacement: String = ""
    
    /// 自定义表情转换时的正则匹配规则(默认匹配一对不嵌套方括号的[表情名]，不限长度)
    public var emojiPattern: String = "\\[[^\\[\\]]+\\]"
    
    /// 文本切换按钮图片
    public var textBottomImage: UIImage = UIImage(systemName: "keyboard") ?? UIImage.wy_find("WYChatViewTogglekeyboard", inBundle: WYChatSourceBundle)
    
    /// 语音切换按钮图片
    public var voiceButtonImage: UIImage = UIImage.wy_find("WYChatViewVoice", inBundle: WYChatSourceBundle)
    
    /// 表情切换按钮图片
    public var emojiBottomImage: UIImage = UIImage.wy_find("WYChatViewToggleEmoji", inBundle: WYChatSourceBundle)
    
    /// 更多切换按钮图片
    public var moreBottomImage: UIImage = UIImage.wy_find("WYChatViewMore", inBundle: WYChatSourceBundle)
    
    /// 文本输入框背景图
    public var textViewBackgroundImage: UIImage? = nil
    
    /// 语音输入框背景图
    public var voiceViewBackgroundImage: UIImage? = nil
    
    /// 语音输入框按压状态背景图
    public var voiceViewBackgroundImageForHighlighted: UIImage? = nil
    
    /// 语音输入框占位文本
    public var voicePlaceholder: String = WYLocalized("按住 说话", table: WYBasisKitConfig.kitLocalizableTable)

    /// 语音输入框占位文本色值
    public var voicePlaceholderColor: UIColor = .label

    /// 语音框输入占位文本字体、字号
    public var voicePlaceholderFont: UIFont = .boldSystemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    
    /// 键盘类型
    public var chatKeyboardType: UIKeyboardType = .default
    
    /// 键盘右下角按钮类型
    public var chatReturnKeyType: UIReturnKeyType = .default
    
    /// 输入框占位文本
    public var textPlaceholder: String = WYLocalized("请输入消息", table: WYBasisKitConfig.kitLocalizableTable)
    
    /// 输入框占位文本色值
    public var textPlaceholderColor: UIColor = .placeholderText

    /// 输入框占位文本字体、字号
    public var textPlaceholderFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 输入框占位文本距离输入框左侧和顶部的间距
    public var textPlaceholderOffset: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), y: UIDevice.wy_screenWidth(12.5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 输入框内文本偏移量
    public var inputTextEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    
    /// 输入字符长度限制
    public var inputTextLength: Int = Int.max

    /// 输入字符行数限制(0为不限制行数)
    public var inputTextMaximumNumberOfLines: Int = 0

    /// 输入字符的截断方式
    public var textLineBreakMode: NSLineBreakMode = .byTruncatingTail
    
    /// 输入框键盘语言(解决textViewDidChange回调两次的问题)
    public var primaryLanguage: [String] = ["zh-Hans", "zh-Hant"]

    /// 字符输入控件是否允许滑动
    public var textViewIsScrollEnabled: Bool = true

    /// 字符输入控件是否允许弹跳效果
    public var textViewIsBounces: Bool = true

    /// 字符输入控件光标颜色
    public var inputViewCurvesColor: UIColor = .blue

    /// 字符输入控件是否允许弹出用户交互菜单
    public var textViewCanUserInteractionMenu: Bool = true
    
    /// 输入框输入文本色值
    public var textColor: UIColor = .label

    /// 输入框输入文本字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    
    /// 输入框文本行间距
    public var textLineSpacing: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 输入框的最高高度
    public var textViewMaxHeight: CGFloat = UIDevice.wy_screenHeight(120, WYBasisKitConfig.defaultScreenPixels)
    
    /// 语音框的圆角半径
    public var voiceViewCornerRadius: CGFloat = UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels)

    /// 输入框的圆角半径
    public var textViewCornerRadius: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)

    /// 输入框、语音框的边框颜色
    public var textViewBorderColor: UIColor = .gray

    /// 输入框、语音框的边框宽度
    public var textViewBorderWidth: CGFloat = 0

    /// 输入框、语音框的高度
    public var inputViewHeight: CGFloat = UIDevice.wy_screenWidth(42, WYBasisKitConfig.defaultScreenPixels)

    /// 输入框、语音框距离InputBar的间距
    public var inputViewEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(57, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(100, WYBasisKitConfig.defaultScreenPixels))
    
    /// 语音、文本切换按钮的size
    public var voiceTextButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels))
    
    /// 表情、文本切换按钮的size
    public var emojiTextButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels))
    
    /// 更多按钮的size
    public var moreButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels))

    /// 语音、文本切换按钮距离 输入框、语音框 左侧的间距
    public var voiceTextButtonRightOffset: CGFloat = UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels)

    /// 语音、文本切换按钮距离 输入框、语音框 底部的间距
    public var voiceTextButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 表情、文本切换按钮距离 输入框、语音框 右侧的间距
    public var emojiTextButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels)

    /// 表情、文本切换按钮距离 输入框、语音框 底部的间距
    public var emojiTextButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
    /// 更多按钮距离 输入框、语音框 右侧的间距(默认 emojiTextButtonLeftOffset + emojiTextButtonSize.width + emojiTextButtonLeftOffset)
    public var moreButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels) + UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels) + UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels)

    /// 更多按钮距离 输入框、语音框 底部的间距
    public var moreButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
    /// 是否使用独立的发送按钮(开启后当输入框中有字符出现时，会在InputBar的右侧出现一个独立的发送按钮)
    public var showSpecialSendButton: Bool = true
    
    /// 独立发送按钮的Size
    public var specialSendButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(50, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(35, WYBasisKitConfig.defaultScreenPixels))
    
    /// 独立发送按钮左侧距离输入框、语音框右侧的间距
    public var specialSendButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(57, WYBasisKitConfig.defaultScreenPixels)
    
    /// 独立发送按钮右侧距离InputBar右侧的间距(默认 emojiTextButtonLeftOffset)
    public var specialSendButtonRightOffset: CGFloat = UIDevice.wy_screenWidth(13, WYBasisKitConfig.defaultScreenPixels)
    
    /// 独立发送按钮底部距离 输入框、语音框 底部的间距
    public var specialSendButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
    /// 独立发送按钮图片
    public var specialSendButtonImage: UIImage = UIImage.wy_createImage(from: .wy_rgb(64, 118, 246), size: CGSize(width: UIDevice.wy_screenWidth(50, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(35, WYBasisKitConfig.defaultScreenPixels)))
    
    /// 独立发送按钮的圆角半径
    public var specialSendButtonCornerRadius: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 独立发送按钮的边框颜色
    public var specialSendButtonBorderColor: UIColor = .clear

    /// 独立发送按钮的边框宽度
    public var specialSendButtonBorderWidth: CGFloat = 0
    
    /// 独立发送按钮的字体字号
    public var specialSendButtonFont: UIFont = .boldSystemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    
    /// 独立发送按钮的字体颜色
    public var specialSendButtonTextColor: UIColor = .white
    
    /// 独立发送按钮的文本
    public var specialSendButtonText: String = WYLocalized("发送", table: WYBasisKitConfig.kitLocalizableTable)
    
    public init() {}
}

public let WYChatSourceBundle: WYSourceBundle = WYSourceBundle(bundleName: "WYChatView")

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回true)
@objc public protocol WYChatInputViewEventsHandler {
    
    /// 是否需要内部处理 语音 按钮的长按事件
    @objc(wy_canManagerVoiceRecordEvents:)
    optional func wy_canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool
    
    /// 是否需要内部处理 文本/语音 按钮的点击事件
    @objc(wy_canManagerTextVoiceViewEvents:)
    optional func wy_canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool
    
    /// 是否需要内部处理 文本/表情 切换按钮的点击事件
    @objc(wy_canManagerTextEmojiViewEvents:)
    optional func wy_canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool
    
    /// 是否需要内部处理 更多 按钮的点击事件
    @objc(wy_canManagerMoreViewEvents:)
    optional func wy_canManagerMoreViewEvents(_ moreView: UIButton) -> Bool
    
    /// 是否需要内部处理 textView 的代理事件
    @objc(wy_canManagerTextViewDelegateEvents:placeholderView:)
    optional func wy_canManagerTextViewDelegateEvents(_ textView: WYChatInputTextView, placeholderView: UILabel) -> Bool
}

/// 监听各控件点击事件
@objc public protocol WYChatInputViewDelegate {
    
    /// 点击了 文本/语音 切换按钮
    @objc(wy_didClickTextVoiceView:)
    optional func wy_didClickTextVoiceView(isText: Bool)
    
    /// 点击了 表情/文本 切换按钮
    @objc(wy_didClickEmojiTextView:)
    optional func wy_didClickEmojiTextView(isText: Bool)
    
    /// 点击了 更多 按钮
    @objc(wy_didClickMoreView:)
    optional func wy_didClickMoreView(isText: Bool)
    
    /// 输入框文本发生变化
    @objc(wy_textDidChanged:)
    optional func wy_textDidChanged(text: String)
    
    /// 点击了键盘右下角按钮(例如发送)
    @objc(wy_didClickKeyboardEvent:)
    optional func wy_didClickKeyboardEvent(text: String)
}

public class WYChatInputView: UIImageView {

    /// 当前实例配置
    public var inputBarConfig: WYInputBarConfig = WYInputBarConfig()

    
    public let textVoiceContentView: UIButton = WYChatInputBackgroundButton(frame: .zero)
    public let textView: WYChatInputTextView = WYChatInputTextView()
    public let textPlaceholderView = UILabel()
    public let textVoiceView: UIButton = UIButton(type: .custom)
    public let emojiView: UIButton = UIButton(type: .custom)
    public let moreView: UIButton = UIButton(type: .custom)
    /// 表情解析配置
    public var emojiViewConfig: WYEmojiViewConfig = WYEmojiViewConfig()
    /// 录音配置
    public var recordAnimationConfig: WYRecordAnimationConfig = WYRecordAnimationConfig() { didSet { wy_updateDictationControls(); if !recordAnimationConfig.supportSpeechRecognition { wy_stopInputDictation(cancel: true) } } }
    /// 录音结果，参数为文件URL、时长和错误
    public var recordingResultHandler: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)? = nil
    internal var textEditingHandler: ((NSRange, String) -> Void)?
    internal var hasCreatedRecordView = false
    internal var recordingGestureID: UUID? = nil
    internal let placeholderGate = UIButton(type: .custom)
    internal let keyboardDictationButton = UIButton(type: .custom)
    internal var inputDictation: WYChatInputDictationSession?
    internal var dictationRequestID: UUID?
    internal var dictationRange = NSRange(location: 0, length: 0)
    internal var isApplyingDictationText = false
    /// 输入框语音识别错误，参数为错误信息，nil时显示默认提示
    public var inputDictationErrorHandler: ((_ error: NSError) -> Void)?
    /// 输入框是否正在采集或等待语音识别结果
    public var isInputDictating: Bool { dictationRequestID != nil }
    public lazy var recordView: WYRecordAnimationView = wy_makeRecordView()
    
    public lazy var specialSendButton: UIButton? = wy_makeSpecialSendButton()
    
    public weak var eventsHandler: WYChatInputViewEventsHandler? = nil
    public weak var delegate: WYChatInputViewDelegate? = nil
    
    public init(config: WYInputBarConfig = WYInputBarConfig()) {
        self.inputBarConfig = config
        super.init(frame: .zero)
        textView.inputBarConfig = config
        wy_setupInputView()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) { wy_applyInputAppearance() }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        wy_updateDictationControls()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { wy_stopInputDictation(cancel: true) }
    }

    deinit { inputDictation?.cancel() }

    public func updateSpecialSendState(hasText: Bool) {
        wy_impl_updateSpecialSendState(hasText: hasText)
    }
    
    // 根据传入的表情字符串生成富文本，例如字符串 "哈哈[哈哈]" 会生成 "哈哈😄"
    public func sharedEmojiAttributed(string: String) -> NSAttributedString {
        return wy_impl_sharedEmojiAttributed(string: string)
    }
    
    // 将表情富文本生成对应的富文本字符串，例如表情富文本 "哈哈😄" 会生成 "哈哈[哈哈]"
    public func sharedEmojiAttributedText(attributed: NSAttributedString) -> NSAttributedString {
        return wy_impl_sharedEmojiAttributedText(attributed: attributed)
    }

    func updateTextViewOffset() {
        wy_impl_updateTextViewOffset()
    }

    public func processingTextViewDidChange(_ textView: UITextView, silence: Bool) {
        wy_impl_processingTextViewDidChange(textView, silence: silence)
    }
    
    public func textViewDidChange(_ textView: UITextView, silence: Bool) {
        wy_impl_textViewDidChange(textView, silence: silence)
    }
    
    @objc public func didClickSendView(_ sender: UIButton? = nil) {
        wy_impl_didClickSendView(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension WYChatInputView: WYRecordEventsHandler {

}

extension WYChatInputView: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) { wy_updateDictationControls(); updateContentViewHeight() }
    public func textViewDidEndEditing(_ textView: UITextView) { wy_stopInputDictation(cancel: true); wy_updateDictationControls(); updateContentViewHeight() }
    
    @available(iOS, introduced: 10.0, deprecated: 17.0, message: "Use textView(_:primaryActionForTextItem:defaultAction:) instead")
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return wy_impl_textView(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction)
    }
    
    @available(iOS 17.0, *)
    public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        return wy_impl_textView(textView, primaryActionFor: textItem, defaultAction: defaultAction)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return wy_impl_textViewShouldBeginEditing(textView)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        wy_impl_textViewDidChange(textView)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return wy_impl_textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

}

public class WYChatInputTextView: UITextView {

    /// 当前实例配置
    public var inputBarConfig: WYInputBarConfig = WYInputBarConfig()

    
    override public  func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if (action == #selector(UIResponderStandardEditActions.cut(_:))) || (action == #selector(UIResponderStandardEditActions.copy(_:))) || (action == #selector(UIResponderStandardEditActions.paste(_:))) || (action == #selector(UIResponderStandardEditActions.select(_:))) ||
            (action == #selector(UIResponderStandardEditActions.selectAll(_:))) {
            return inputBarConfig.textViewCanUserInteractionMenu
        }else {
            return false
        }
    }
    
    // 重写复制方法兼容富文本
    public override func copy(_ sender: Any?) {
        // 获取用户选择的富文本
        let subEmojiText = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: selectedRange)).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string
        // 复制到粘贴板上
        UIPasteboard.general.string = subEmojiText
    }
    
    // 重写粘贴方法兼容富文本
    public override func paste(_ sender: Any?) {
        
        // 获取光标所在的位置并在对应位置插入复制的文本
        if let string = UIPasteboard.general.string {
            // 光标位置
            _ = offset(from: beginningOfDocument, to: selectedTextRange?.start ?? beginningOfDocument)
            // 调用 insertText 方法后内部会触发 textViewDidChange 方法，在该方法内已实现纯文本转富文本操作
            insertText(string)
        }
    }
    
    // 重定义光标
    override public  func caretRect(for position: UITextPosition) -> CGRect {
        var originalRect = super.caretRect(for: position)
        // 设置光标高度
        originalRect.size.height = inputBarConfig.textFont.lineHeight + 2
        return originalRect
    }
}
