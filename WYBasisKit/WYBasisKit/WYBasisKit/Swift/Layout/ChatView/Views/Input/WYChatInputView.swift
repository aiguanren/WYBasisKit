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
    
    /// 录音按钮长按手势允许手指移动的最大距离
    public var recordViewLongPressMaxOffset: CGFloat = UIDevice.wy_screenWidth(100)
    
    /// inputBar弹起或者收回时动画持续时长
    public var animateDuration: TimeInterval = 0.25
    
    /// inputBar背景图
    public var backgroundImage: UIImage = UIImage.wy_createImage(from: .wy_hex("#f6f6f6"))
    
    /// 是否需要保存上次退出时输入框中的文本
    public var canSaveLastInputText: Bool = true

    /// 是否需要保存上次退出时输入框模式(语音输入还是文本输入)
    public var canSaveLastInputViewStyle: Bool = true
    
    /// 是否允许输入Emoji表情
    public var canInputEmoji: Bool = true

    /// 输入法自带的Emoji表情替换成什么字符(需要canInputEmoji为false才生效)
    public var emojiReplacement: String = ""
    
    /// 自定义表情转换时的正则匹配规则
    public var emojiPattern: String = "\\[.{1,3}\\]"
    
    /// 文本切换按钮图片
    public var textButtomImage: UIImage = UIImage.wy_find("WYChatViewTogglekeyboard", inBundle: WYChatSourceBundle)
    
    /// 语音切换按钮图片
    public var voiceButtonImage: UIImage = UIImage.wy_find("WYChatViewVoice", inBundle: WYChatSourceBundle)
    
    /// 表情切换按钮图片
    public var emojiButtomImage: UIImage = UIImage.wy_find("WYChatViewToggleEmoji", inBundle: WYChatSourceBundle)
    
    /// 更多切换按钮图片
    public var moreButtomImage: UIImage = UIImage.wy_find("WYChatViewMore", inBundle: WYChatSourceBundle)
    
    /// 文本输入框背景图
    public var textViewBackgroundImage: UIImage = UIImage.wy_createImage(from: .white)
    
    /// 语音输入框背景图
    public var voiceViewBackgroundImage: UIImage = UIImage.wy_createImage(from: .white)
    
    /// 语音输入框按压状态背景图
    public var voiceViewBackgroundImageForHighlighted: UIImage = UIImage.wy_createImage(from: .white)
    
    /// 语音输入框占位文本
    public var voicePlaceholder: String = "按住 说话"

    /// 语音输入框占位文本色值
    public var voicePlaceholderColor: UIColor = .black

    /// 语音框输入占位文本字体、字号
    public var voicePlaceholderFont: UIFont = .boldSystemFont(ofSize: UIFont.wy_fontSize(15))
    
    /// 键盘类型
    public var chatKeyboardType: UIKeyboardType = .default
    
    /// 键盘右下角按钮类型
    public var chatReturnKeyType: UIReturnKeyType = .default
    
    /// 输入框占位文本
    public var textPlaceholder: String = "请输入消息"
    
    /// 输入框占位文本色值
    public var textPlaceholderColor: UIColor = .lightGray

    /// 输入框占位文本字体、字号
    public var textPlaceholderFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15))

    /// 输入框占位文本距离输入框左侧和顶部的间距
    public var textPlaceholderOffset: CGPoint = CGPoint(x: UIDevice.wy_screenWidth(16), y: UIDevice.wy_screenWidth(12.5))
    
    /// 输入框内文本偏移量
    public var inputTextEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenWidth(13), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(5), right: UIDevice.wy_screenWidth(5))
    
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
    public var textColor: UIColor = .black

    /// 输入框输入文本字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15))
    
    /// 输入框文本行间距
    public var textLineSpacing: CGFloat = UIDevice.wy_screenWidth(5)

    /// 输入框的最高高度
    public var textViewMaxHeight: CGFloat = CGFLOAT_MAX
    
    /// 输入框、语音框的圆角半径
    public var textViewCornerRadius: CGFloat = UIDevice.wy_screenWidth(8)

    /// 输入框、语音框的边框颜色
    public var textViewBorderColor: UIColor = .gray

    /// 输入框、语音框的边框宽度
    public var textViewBorderWidth: CGFloat = 1

    /// 输入框、语音框的高度
    public var inputViewHeight: CGFloat = UIDevice.wy_screenWidth(42)

    /// 输入框、语音框距离InputBar的间距
    public var inputViewEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenWidth(12), left: UIDevice.wy_screenWidth(57), bottom: UIDevice.wy_screenWidth(12), right: UIDevice.wy_screenWidth(100))
    
    /// 语音、文本切换按钮的size
    public var voiceTextButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31), height: UIDevice.wy_screenWidth(31))
    
    /// 表情、文本切换按钮的size
    public var emojiTextButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31), height: UIDevice.wy_screenWidth(31))
    
    /// 更多按钮的size
    public var moreButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(31), height: UIDevice.wy_screenWidth(31))

    /// 语音、文本切换按钮距离 输入框、语音框 左侧的间距
    public var voiceTextButtonRightOffset: CGFloat = UIDevice.wy_screenWidth(13)

    /// 语音、文本切换按钮距离 输入框、语音框 底部的间距
    public var voiceTextButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5)

    /// 表情、文本切换按钮距离 输入框、语音框 右侧的间距
    public var emojiTextButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(13)

    /// 表情、文本切换按钮距离 输入框、语音框 底部的间距
    public var emojiTextButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5)
    
    /// 更多按钮距离 输入框、语音框 右侧的间距(默认 emojiTextButtonLeftOffset + emojiTextButtonSize.width + emojiTextButtonLeftOffset)
    public var moreButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(13) + UIDevice.wy_screenWidth(31) + UIDevice.wy_screenWidth(13)

    /// 更多按钮距离 输入框、语音框 底部的间距
    public var moreButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5)
    
    /// 是否使用独立的发送按钮(开启后当输入框中有字符出现时，会在InputBar的右侧出现一个独立的发送按钮)
    public var showSpecialSendButton: Bool = true
    
    /// 独立发送按钮的Size
    public var specialSendButtonSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(50), height: UIDevice.wy_screenWidth(35))
    
    /// 独立发送按钮左侧距离输入框、语音框右侧的间距
    public var specialSendButtonLeftOffset: CGFloat = UIDevice.wy_screenWidth(57)
    
    /// 独立发送按钮右侧距离InputBar右侧的间距(默认 emojiTextButtonLeftOffset)
    public var specialSendButtonRightOffset: CGFloat = UIDevice.wy_screenWidth(13)
    
    /// 独立发送按钮底部距离 输入框、语音框 底部的间距
    public var specialSendButtonBottomOffset: CGFloat = UIDevice.wy_screenWidth(5)
    
    /// 独立发送按钮图片
    public var specialSendButtonImage: UIImage = UIImage.wy_createImage(from: .wy_rgb(64, 118, 246), size: CGSize(width: UIDevice.wy_screenWidth(50), height: UIDevice.wy_screenWidth(35)))
    
    /// 独立发送按钮的圆角半径
    public var specialSendButtonCornerRadius: CGFloat = UIDevice.wy_screenWidth(5)

    /// 独立发送按钮的边框颜色
    public var specialSendButtonBorderColor: UIColor = .clear

    /// 独立发送按钮的边框宽度
    public var specialSendButtonBorderWidth: CGFloat = 0
    
    /// 独立发送按钮的字体字号
    public var specialSendButtonFont: UIFont = .boldSystemFont(ofSize: UIFont.wy_fontSize(15))
    
    /// 独立发送按钮的字体颜色
    public var specialSendButtonTextColor: UIColor = .white
    
    /// 独立发送按钮的文本
    public var specialSendButtonText: String = "发送"
    
    public init() {}
}

private let canSaveLastInputTextKey: String = "canSaveLastInputTextKey"
private let canSaveLastInputViewStyleKey: String = "canSaveLastInputViewStyleKey"
public let WYChatSourceBundle: WYSourceBundle = WYSourceBundle(bundleName: "WYChatView")

/// 返回一个Bool值来判定各控件的点击或手势事件是否需要内部处理(默认返回True)
@objc public protocol WYChatInputViewEventsHandler {
    
    /// 是否需要内部处理 语音 按钮的长按事件
    @objc optional func canManagerVoiceRecordEvents(_ longPress: UILongPressGestureRecognizer) -> Bool
    
    /// 是否需要内部处理 文本/语音 按钮的点击事件
    @objc optional func canManagerTextVoiceViewEvents(_ textVoiceView: UIButton) -> Bool
    
    /// 是否需要内部处理 文本/表情 切换按钮的点击事件
    @objc optional func canManagerTextEmojiViewEvents(_ textEmojiView: UIButton) -> Bool
    
    /// 是否需要内部处理 更多 按钮的点击事件
    @objc optional func canManagerMoreViewEvents(_ moreView: UIButton) -> Bool
    
    /// 是否需要内部处理 textView 的代理事件
    @objc(canManagerTextViewDelegateEvents:placeholderView:)
    optional func canManagerTextViewDelegateEvents(_ textView: WYChatInputTextView, _ placeholderView: UILabel) -> Bool
}

/// 监听各控件点击事件
@objc public protocol WYChatInputViewDelegate {
    
    /// 点击了 文本/语音 切换按钮
    @objc optional func didClickTextVoiceView(_ isText: Bool)
    
    /// 点击了 表情/文本 切换按钮
    @objc optional func didClickEmojiTextView(_ isText: Bool)
    
    /// 点击了 更多 按钮
    @objc optional func didClickMoreView(_ isText: Bool)
    
    /// 输入框文本发生变化
    @objc optional func textDidChanged(_ text: String)
    
    /// 点击了键盘右下角按钮(例如发送)
    @objc optional func didClickKeyboardEvent(_ text: String)
}

public class WYChatInputView: UIImageView {
    
    public let textVoiceContentView: UIButton = UIButton(type: .custom)
    public let textView: WYChatInputTextView = WYChatInputTextView()
    public let textPlaceholderView = UILabel()
    public let textVoiceView: UIButton = UIButton(type: .custom)
    public let emojiView: UIButton = UIButton(type: .custom)
    public let moreView: UIButton = UIButton(type: .custom)
    public lazy var recordView: WYRecordAnimationView = {
        let recordView: WYRecordAnimationView = WYRecordAnimationView(alpha: 1.0, delegate: self)
        superview?.addSubview(recordView)
        recordView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(recordAnimationConfig.recordViewBottomOffset)
        }
        return recordView
    }()
    
    public lazy var specialSendButton: UIButton? = {
        
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
    }()
    
    public weak var eventsHandler: WYChatInputViewEventsHandler? = nil
    public weak var delegate: WYChatInputViewDelegate? = nil
    
    public init() {
        super.init(frame: .zero)
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
        if (eventsHandler?.canManagerTextViewDelegateEvents?(textView, textPlaceholderView) ?? true) == true {
            textView.delegate = self
        }
        textVoiceContentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if inputBarConfig.canSaveLastInputText == true {
            textView.attributedText = sharedEmojiAttributed(string: UserDefaults.standard.value(forKey: canSaveLastInputTextKey) as? String ?? "")
            if textView.attributedText.string.utf16.count > 0 {
                updateSpecialSendState(hasText: true)
                textView.becomeFirstResponder()
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
        textVoiceView.wy_sImage = inputBarConfig.textButtomImage
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
        
        emojiView.setBackgroundImage(inputBarConfig.emojiButtomImage, for: .normal)
        emojiView.setBackgroundImage(inputBarConfig.textButtomImage, for: .selected)
        emojiView.addTarget(self, action: #selector(didClickEmojiView(sender:)), for: .touchUpInside)
        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.size.equalTo(inputBarConfig.emojiTextButtonSize)
            make.left.equalTo(textVoiceContentView.snp.right).offset(inputBarConfig.emojiTextButtonLeftOffset)
            make.bottom.equalTo(textVoiceContentView).offset(-inputBarConfig.emojiTextButtonBottomOffset)
        }
        
        moreView.setBackgroundImage(inputBarConfig.moreButtomImage, for: .normal)
        moreView.setBackgroundImage(inputBarConfig.moreButtomImage, for: .highlighted)
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
    
    @objc private func didClickTextVoiceView(sender: UIButton) {
        
        guard (eventsHandler?.canManagerTextVoiceViewEvents?(sender) ?? true) else {
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
        
        delegate?.didClickTextVoiceView?(!sender.isSelected)
        saveLastInputViewStyle()
    }
    
    @objc private func voiceViewLongPressMethod(_ sender: UILongPressGestureRecognizer) {
        
        guard ((eventsHandler?.canManagerVoiceRecordEvents?(sender) ?? true) && textVoiceView.isSelected == true) else {
            return
        }
        
        /// 检查是否拥有麦克风权限
        wy_authorizeMicrophoneAccess(showSettingsAlert: true) { [weak self] authorized in
            
            guard let self = self else { return }
            guard authorized == true else { return }
            
            // 用户已授权使用麦克风，开始录音操作
            Task { @MainActor in
                let point: CGPoint = sender.location(in: self.recordView)
                switch sender.state {
                case .began:
                    self.isHidden = true
                    self.recordView.start()
                    break
                case .changed:
                    self.isHidden = true
                    if (point.x < (self.recordView.bounds.size.width / 2)) && (point.y < (self.recordView.bounds.size.height - recordAnimationConfig.areaHeight)) {
                        self.recordView.switchStatus(.cancel)
                        
                    }else if (point.x > (self.recordView.bounds.size.width / 2)) && (point.y < (self.recordView.bounds.size.height - recordAnimationConfig.areaHeight)) {
                        self.recordView.switchStatus(.transfer)
                        
                    }else {
                        self.recordView.switchStatus(.recording)
                    }
                    break
                default:
                    self.isHidden = false
                    self.recordView.stop()
                    break
                }
            }
        }
    }
    
    @objc private func didClickMoreView(sender: UIButton) {
        
        guard (eventsHandler?.canManagerMoreViewEvents?(sender) ?? true) else {
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
        
        delegate?.didClickMoreView?(!sender.isSelected)
        saveLastInputViewStyle()
    }
    
    @objc private func didClickEmojiView(sender: UIButton) {
        
        guard (eventsHandler?.canManagerTextEmojiViewEvents?(sender) ?? true) else {
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
        
        delegate?.didClickEmojiTextView?(!sender.isSelected)
        saveLastInputViewStyle()
    }
    
    public func updateSpecialSendState(hasText: Bool) {
        
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
    
    // 根据传入的表情字符串生成富文本，例如字符串 "哈哈[哈哈]" 会生成 "哈哈😄"
    public func sharedEmojiAttributed(string: String) -> NSAttributedString {
        let attributed: NSMutableAttributedString = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: string, textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont, emojiTable: emojiViewConfig.emojiSource, sourceBundle: emojiViewConfig.emojiBundle, pattern: inputBarConfig.emojiPattern)
        attributed.wy_lineSpacing(inputBarConfig.textLineSpacing, alignment: .left)
        
        return attributed
    }
    
    // 将表情富文本生成对应的富文本字符串，例如表情富文本 "哈哈😄" 会生成 "哈哈[哈哈]"
    public func sharedEmojiAttributedText(attributed: NSAttributedString) -> NSAttributedString {
        let attributed: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributed).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont)
        attributed.wy_lineSpacing(inputBarConfig.textLineSpacing, alignment: .left)
        return attributed
    }
    
    private func saveLastInputViewStyle() {
        UserDefaults.standard.setValue(textView.isHidden, forKey: canSaveLastInputViewStyleKey)
        UserDefaults.standard.synchronize()
    }
    
    private func updateContentViewHeight() {

        var textHeight: CGFloat = 0
        if (inputBarConfig.showSpecialSendButton == true) {
            textHeight = textView.attributedText.wy_calculateHeight(controlWidth: UIDevice.wy_screenWidth - inputBarConfig.inputViewEdgeInsets.left - inputBarConfig.specialSendButtonLeftOffset - inputBarConfig.specialSendButtonRightOffset - inputBarConfig.specialSendButtonSize.width - inputBarConfig.inputTextEdgeInsets.left - inputBarConfig.inputTextEdgeInsets.right - UIDevice.wy_screenWidth(10)) + inputBarConfig.inputTextEdgeInsets.top + inputBarConfig.inputTextEdgeInsets.bottom
        }else {
            textHeight = textView.attributedText.wy_calculateHeight(controlWidth: UIDevice.wy_screenWidth - inputBarConfig.inputViewEdgeInsets.left - inputBarConfig.inputViewEdgeInsets.right - inputBarConfig.inputTextEdgeInsets.left - inputBarConfig.inputTextEdgeInsets.right - UIDevice.wy_screenWidth(10)) + inputBarConfig.inputTextEdgeInsets.top + inputBarConfig.inputTextEdgeInsets.bottom
        }
        
        var contentHeight: CGFloat = [textHeight,textView.contentSize.height,inputBarConfig.inputViewHeight].max()!

        
        if (textVoiceView.isSelected == true) {
            contentHeight = inputBarConfig.inputViewHeight
        }
        
        UIView.animate(withDuration: 0.25) {[weak self] in
            guard let self = self else {return}
            self.textVoiceContentView.snp.updateConstraints { make in
                make.height.equalTo(contentHeight > inputBarConfig.textViewMaxHeight ? inputBarConfig.textViewMaxHeight : contentHeight)
            }
            self.textVoiceContentView.superview?.layoutIfNeeded()
        }completion: {[weak self] _ in
            guard let self = self else {return}
            self.textView.contentSize = CGSize(width: self.textView.contentSize.width, height: contentHeight)
            self.updateTextViewOffset()
        }
    }
    
    func updateTextViewOffset() {
        if textView.attributedText.string.utf16.count > 0 {
            if textView.attributedText.wy_numberOfRows(controlWidth: textView.wy_width) <= 1 {
                textView.contentOffset = CGPoint(x: 0, y: 0)
            }else {
                textView.contentOffset = CGPoint(x: 0, y: textView.contentSize.height - textView.wy_height)
            }
        }
    }
    
    private func checkTextCount() {
        
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
    
    public func processingTextViewDidChange(_ textView: UITextView, silence: Bool) {
        
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
            delegate?.textDidChanged?(emojiText)
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
    
    public func textViewDidChange(_ textView: UITextView, silence: Bool) {
        
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
    
    @objc public func didClickSendView(_ sender: UIButton? = nil) {
        let emojiText: String = NSMutableAttributedString(attributedString: textView.attributedText).wy_convertEmojiAttributedString(textColor: inputBarConfig.textColor, textFont: inputBarConfig.textFont).string
        
        if emojiText.wy_replace(appointSymbol: "\n", replacement: "").count > 0 {
            delegate?.didClickKeyboardEvent?(emojiText)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension WYChatInputView: WYRecordEventsHandler {
    
    /**
     录音开始
     - Parameters:
     - audioKit: 音频工具实例
     - isResume: 是否是恢复录音
     */
    public func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        
    }
    
    /**
     录音停止
     - Parameters:
     - audioKit: 音频工具实例
     - isPause: 是否是暂停录音
     */
    public func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool) {
        
    }
    
    /**
     录音时间更新
     - Parameters:
     - audioKit: 音频工具实例
     - currentTime: 当前录音时间（秒）
     - duration: 总录音时长限制（秒）
     */
    public func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
        
    }
    
    /**
     录音声波数据更新
     - Parameters:
     - audioKit: 音频工具实例
     - peakPower: 当前峰值功率（dB），范围 -160.0 到 0.0（0.0 表示最响，-160.0 表示最安静）；适合用于实时响应敏感的声波动画，但可能导致动画跳动剧烈
     - averagePower: 当前平均功率（dB），范围 -160.0 到 0.0；比 peakPower 更平滑，适合微信式语音录制页面的声波动画
     */
    public func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) {
        
    }
    
    /**
     音频任务执行失败
     - Parameters:
     - audioKit: 音频工具实例
     - url: 出错的任务相关URL（可能是本地或远程）
     - error: 错误枚举值
     - description: 可选的详细错误描述
     */
    public func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        
    }
}

extension WYChatInputView: UITextViewDelegate {
    
    @available(iOS, introduced: 10.0, deprecated: 17.0, message: "Use textView(_:primaryActionForTextItem:defaultAction:) instead")
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        handleTextAttachmentSelection(in: textView, range: characterRange)
        return true
    }
    
    @available(iOS 17.0, *)
    public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
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
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        emojiView.isSelected = false
        moreView.isSelected = false
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        textViewDidChange(textView, silence: false)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
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
        
        return true
    }
    
    // 公共处理逻辑
    private func handleTextAttachmentSelection(in textView: UITextView, range: NSRange) {
        
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

public class WYChatInputTextView: UITextView {
    
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
