//
//  WYChatView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/3/30.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import WYBasisKit

/// 自定义聊天UITableViewCell
public var customChatRegisterClasss: [AnyClass] = []

@frozen public enum WYChatTouchStyle {
    case done
    case more
    case emoji
}

public class WYChatView: UIView {
    
    public weak var eventsHandler: WYChatViewEventsHandler? = nil
    public weak var delegate: WYChatViewDelegate? = nil
    
    public lazy var chatInput: WYChatInputView = {
        let inputView = WYChatInputView()
        inputView.eventsHandler = self
        inputView.delegate = self
        addSubview(inputView)
        inputView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        return inputView
    }()
    
    public lazy var tableView: UITableView = {

        let tableView = UITableView.wy_shared(style: .plain, separatorStyle: .none, delegate: self, dataSource: self, superView: self)
        tableView.wy_swipeOrTapCollapseKeyboard(target: self, action: #selector(inputViewResignFirstResponder), slideMode: .none)
        let registerClasss: [AnyClass] = [WYChatBasicCell.self,
                                          WYChatTextCell.self,
                                          WYChatVoiceCell.self,
                                          WYChatPhotoCell.self,
                                          WYChatMusicCell.self,
                                          WYChatVideoCell.self,
                                          WYChatLuckyMoneyCell.self,
                                          WYChatTransferCell.self,
                                          WYChatLocationCell.self,
                                          WYChatTakePatCell.self,
                                          WYChatWithdrawnCell.self,
                                          WYChatCallCell.self,
                                          WYChatWebpageCell.self,
                                          WYChatFileCell.self,
                                          WYChatBusinessCardCell.self,
                                          WYChatRecordsCell.self]
        
        for register: AnyClass in (registerClasss + customChatRegisterClasss) {
            tableView.register(register, forCellReuseIdentifier: (NSStringFromClass(register).components(separatedBy: ".").last ?? ""))
        }
        tableView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(chatInput.snp.top)
        }
        return tableView
    }()
    
    /// 表情控件
    public lazy var emojiView: WYChatEmojiView? = {
        guard inputBarConfig.emojiTextButtonSize != CGSize.zero else {
            return nil
        }
        let emojiView: WYChatEmojiView = WYChatEmojiView()
        emojiView.eventsHandler = self
        emojiView.delegate = self
        emojiView.isHidden = true
        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(emojiViewConfig.contentHeight)
            make.bottom.equalToSuperview().offset(emojiViewConfig.contentHeight)
        }
        return emojiView
    }()
    
    /// More控件
    public lazy var moreView: WYChatMoreView? = {
        
        guard inputBarConfig.moreButtonSize != CGSize.zero else {
            return nil
        }
        
        let moreView: WYChatMoreView = WYChatMoreView()
        moreView.eventsHandler = self
        moreView.delegate = self
        moreView.isHidden = true
        addSubview(moreView)
        moreView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(moreViewConfig.contentHeight())
            make.bottom.equalToSuperview().offset(moreViewConfig.contentHeight())
        }
        return moreView
    }()
    
    /// 记录最近使用表情数据，用于实现延时更新最近使用表情
    public var recentlyEmojis: [String] = []
    
    /// 当前登录用户的用户信息
    public var userInfo: WYChatUaerModel!
    
    /// tableView数据源
    public var dataSource: [WYChatMessageModel] = [] {
        didSet {
            guard userInfo != nil else {
                wy_print("当前登录用户的用户信息为空")
                return
            }
            tableView.reloadData()
            scrollToLastMessage()
        }
    }
    
    /// 区分当前点击的是哪个控件
    public var touchStyle: WYChatTouchStyle = .done
    
    public init(userInfo: WYChatUaerModel? = nil) {
        super.init(frame: .zero)
        
        self.userInfo = userInfo
        backgroundColor = .wy_hex("#ECECEC")
        self.tableView.backgroundColor = .wy_hex("#ECECEC")
        self.emojiView?.backgroundColor = .clear
        self.moreView?.backgroundColor = .clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDismiss), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    /// 点击空白处收起键盘、表情、更多...
    @objc public func inputViewResignFirstResponder() {
        chatInput.textView.resignFirstResponder()
        chatInput.emojiView.isSelected = false
        chatInput.moreView.isSelected = false
        updateEmojiViewConstraints(false)
        updateMoreViewConstraints(false)
        emojiView?.isHidden = true
        moreView?.isHidden = true
    }
    
    /// tableView滚动到底部
    public func scrollToLastMessage(_ animated: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.dataSource.isEmpty == false {
                self.tableView.scrollToRow(at: IndexPath(row: self.dataSource.count - 1, section: 0), at: .bottom, animated: animated)
            }
        }
    }
    
    @objc public func keyboardWillShowWith(_ notification: Notification, silence: Bool) {
        if silence == false {
            guard (eventsHandler?.canManagerKeyboardWillShowEvents?(notification) ?? true) else {
                return
            }
        }
        
        let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        updateInputViewOffset(offsety: keyboardRect.size.height - wy_tabbarSafetyZone)
        updateEmojiViewConstraints(false)
        updateMoreViewConstraints(false)
    }
    
    @objc public func keyboardWillShow(notification: Notification) {
        keyboardWillShowWith(notification, silence: false)
    }
    
    @objc public func keyboardWillDismissWith(_ silence: Bool) {
        if silence == false {
            guard (eventsHandler?.canManagerKeyboardWillDismissEvents?() ?? true) else {
                return
            }
        }
        
        var offsety: CGFloat = 0
        switch touchStyle {
        case .emoji:
            offsety = chatInput.emojiView.isSelected ? emojiViewConfig.contentHeight : 0
            break
        case .more:
            offsety = chatInput.moreView.isSelected ? moreViewConfig.contentHeight() : 0
            break
        default:
            offsety = 0
            break
        }
        updateInputViewOffset(offsety: offsety)
    }
    
    @objc public func keyboardWillDismiss() {
        keyboardWillDismissWith(false)
    }
    
    public func updateInputViewOffset(offsety: CGFloat) {
        
        chatInput.layer.removeAllAnimations()
        UIView.animate(withDuration: inputBarConfig.animateDuration) { [weak self] in
            if let self = self {
                self.chatInput.snp.updateConstraints({ make in
                    make.bottom.equalToSuperview().offset(-offsety)
                })
                self.chatInput.superview?.layoutIfNeeded()
                self.scrollToLastMessage()
            }
        }completion: { [weak self] _ in
            if let self = self {
                self.chatInput.updateTextViewOffset()
            }
        }
    }
    
    public func updateEmojiViewConstraints(_ isEmoji: Bool) {
        
        if (isEmoji == false) && (emojiView?.isHidden == true) {
            return
        }
        
        updateMoreViewConstraints(false)
        
        moreView?.isHidden = true
        emojiView?.isHidden = false
        
        if chatInput.textView.isFirstResponder == false {
            touchStyle = .emoji
            keyboardWillDismissWith(true)
        }
        
        if inputBarConfig.emojiTextButtonSize != CGSize.zero {
            
            emojiView?.layer.removeAllAnimations()
            
            let emojiOffset: CGFloat = isEmoji ? 0 : emojiViewConfig.contentHeight
            UIView.animate(withDuration: emojiViewConfig.animateDuration) { [weak self] in
                self?.emojiView?.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(emojiOffset)
                }
                self?.emojiView?.superview?.layoutIfNeeded()
            }completion: {[weak self] _ in
                self?.emojiView?.isHidden = !isEmoji
            }
        }
    }
    
    public func updateMoreViewConstraints(_ isMore: Bool) {
        
        if (isMore == false) && (moreView?.isHidden == true) {
            return
        }
        
        updateEmojiViewConstraints(false)
        
        emojiView?.isHidden = true
        moreView?.isHidden = false

        if chatInput.textView.isFirstResponder == false {
            touchStyle = .more
            keyboardWillDismissWith(true)
        }

        if inputBarConfig.moreButtonSize != CGSize.zero {
            
            moreView?.layer.removeAllAnimations()
            
            let moreOffset: CGFloat = isMore ? 0 : moreViewConfig.contentHeight()
            UIView.animate(withDuration: moreViewConfig.animateDuration) { [weak self] in
                self?.moreView?.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(moreOffset)
                }
                self?.moreView?.superview?.layoutIfNeeded()
            }completion: {[weak self] _ in
                self?.moreView?.isHidden = !isMore
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView, silence: Bool) {
        
        if silence == false {
            guard (eventsHandler?.canManagerScrollViewDidScrollEvents?(scrollView) ?? true) else {
                return
            }
        }
        if silence == false {
            delegate?.scrollViewDidScroll?(scrollView)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDidScroll(scrollView, silence: false)
    }
    
    public func updateEmojiFuncAreaViewState() {
        
        let userInteractionEnabled: Bool = (chatInput.textView.attributedText.string.utf16.count > 0)
        emojiView?.funcAreaView?.sendView.isUserInteractionEnabled = userInteractionEnabled
        emojiView?.funcAreaView?.deleteView.isUserInteractionEnabled = userInteractionEnabled
        emojiView?.funcAreaView?.sendView.isSelected = !userInteractionEnabled
        emojiView?.funcAreaView?.deleteView.isSelected = !userInteractionEnabled
    }
    
    /// APP变的活跃了
    @objc public func applicationDidBecomeActive(_ application: UIApplication) {
        
        guard (eventsHandler?.canManagerApplicationDidBecomeActiveEvents?(application) ?? false) == true else {
            return
        }
        
        delegate?.applicationDidBecomeActive?(application)
        tableView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
