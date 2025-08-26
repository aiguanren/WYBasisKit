//
//  UITextView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/8/25.
//

import UIKit

public extension UITextView {
    
    /// 占位文本标签
    var wy_placeholderLabel: UILabel {
        return placeholderLabel
    }
    
    /// 字符长度标签
    var wy_charactersLengthLabel: UILabel {
        return charactersLengthLabel
    }
    
    /// 设置字符长度标签的Frame
    var wy_charactersLengthLabelFrame: CGRect {
        get {
            if let frame = objc_getAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableFrameKey) as? CGRect {
                return frame
            }
            // 默认frame
            return CGRect(x: self.frame.origin.x,
                         y: self.frame.maxY,
                         width: self.frame.width,
                         height: 25)
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableFrameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            charactersLengthLabel.frame = newValue
            updateTextContainerInsets()
        }
    }
    
    /// 占位标签原点位置
    var wy_placeholderOrigin: CGPoint {
        get {
            return placeholderLabel.frame.origin
        }
        set {
            placeholderLabel.frame.origin = newValue
            updateTextContainerInsets()
        }
    }
    
    /// 最大显示字符限制
    var wy_maximumLimit: Int {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.maximumLimitKey) as? Int ?? Int.max
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.maximumLimitKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            wy_fixMessyDisplay()
        }
    }
    
    /// 是否允许复制粘贴
    var wy_allowCopyPaste: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.allowCopyPasteKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.allowCopyPasteKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// 是否显示字符长度提示
    var wy_characterLengthPrompt: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.characterLengthPromptKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.characterLengthPromptKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            wy_fixMessyDisplay()
            
            charactersLengthLabel.isHidden = !newValue
            updateTextContainerInsets()
        }
    }
    
    /// 占位文本是否支持换行(默认true)
    var wy_placeholderAllowsNewlines: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderAllowsNewlinesKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderAllowsNewlinesKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            placeholderLabel.numberOfLines = newValue ? 0 : 1
        }
    }
    
    /// 文本发生改变时回调
    func wy_textDidChange(handle: @escaping (String) -> Void) {
        wy_textHandle = handle
        wy_fixMessyDisplay()
    }
    
    /// 处理系统输入法导致的乱码
    func wy_fixMessyDisplay() {
        if wy_maximumLimit <= 0 {
            wy_maximumLimit = Int.max
        }
        wy_addTextChangeNoti()
    }
}

extension UITextView {
    
    private var wy_addNoti: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.addNotiKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.addNotiKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private var wy_havePlaceholderLable: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.havePlaceholderLableKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.havePlaceholderLableKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private var wy_haveCharactersLengthLable: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.haveCharactersLengthLableKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.haveCharactersLengthLableKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private var wy_lastTextStr: String {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastTextStrKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastTextStrKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    private var wy_textHandle: ((String) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.textHandleKey) as? (String) -> Void
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.textHandleKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    private var placeholderLabel: UILabel {
        get {
            if let label = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderLableKey) as? UILabel {
                return label
            }
            
            let label = UILabel()
            label.frame.origin = CGPoint(x: 5, y: 8)
            label.frame.size.width = self.frame.width - 10
            label.numberOfLines = wy_placeholderAllowsNewlines ? 0 : 1
            label.isUserInteractionEnabled = false
            label.font = self.font
            label.textColor = .lightGray
            
            self.insertSubview(label, at: 0)
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderLableKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_havePlaceholderLable = true
            
            // 更新文本容器边距
            updateTextContainerInsets()
            
            return label
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderLableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var charactersLengthLabel: UILabel {
        get {
            if let label = objc_getAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableKey) as? UILabel {
                return label
            }
            
            let label = UILabel(frame: wy_charactersLengthLabelFrame)
            label.backgroundColor = self.backgroundColor
            label.textAlignment = .right
            label.isUserInteractionEnabled = true
            label.font = self.font
            label.textColor = .lightGray
            label.isHidden = !wy_characterLengthPrompt
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(showTextView))
            label.addGestureRecognizer(tap)
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_haveCharactersLengthLable = true
            
            // 更新文本容器边距
            updateTextContainerInsets()
            
            return label
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 保存原始文本容器边距
    private var originalTextContainerInset: UIEdgeInsets {
        get {
            if let inset = objc_getAssociatedObject(self, &WYAssociatedKeys.textContainerInsetKey) as? UIEdgeInsets {
                return inset
            }
            return self.textContainerInset
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.textContainerInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 更新文本容器边距，确保文本与占位标签对齐且不超过字符长度标签
    private func updateTextContainerInsets() {
        // 保存原始边距
        if originalTextContainerInset == .zero {
            originalTextContainerInset = self.textContainerInset
        }
        
        // 计算新的边距
        var newInset = originalTextContainerInset
        
        // 设置左边距和上边距与占位标签位置一致
        newInset.left = wy_placeholderOrigin.x
        newInset.top = wy_placeholderOrigin.y
        
        // 设置下边距，确保文本底部不超过字符长度标签底部
        if wy_characterLengthPrompt {
            let textViewBottom = self.frame.maxY
            let charactersLabelBottom = charactersLengthLabel.frame.maxY
            
            if charactersLabelBottom > textViewBottom {
                // 字符长度标签在文本视图下方，增加下边距
                newInset.bottom += (charactersLabelBottom - textViewBottom) + 5 // 额外增加5pt间距
            }
        }
        
        // 应用新的边距
        self.textContainerInset = newInset
    }
    
    private static let swizzleTextViewImplementation: Void = {
        let originalSelector = #selector(UITextView.layoutSubviews)
        let swizzledSelector = #selector(UITextView.wy_layoutSubviews)
        
        guard let originalMethod = class_getInstanceMethod(UITextView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITextView.self, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(UITextView.self,
                                          originalSelector,
                                          method_getImplementation(swizzledMethod),
                                          method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(UITextView.self,
                               swizzledSelector,
                               method_getImplementation(originalMethod),
                               method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    @objc private func wy_layoutSubviews() {
        // 调用原始实现
        self.wy_layoutSubviews()
        
        // 更新字符长度标签
        if wy_characterLengthPrompt {
            let currentLength = min(self.text.count, wy_maximumLimit)
            charactersLengthLabel.text = "\(currentLength)/\(wy_maximumLimit)\t"
            charactersLengthLabel.isHidden = false
            
            charactersLengthLabel.layer.borderWidth = self.layer.borderWidth
            charactersLengthLabel.layer.borderColor = self.layer.borderColor
            
            if charactersLengthLabel.superview == nil {
                self.superview?.addSubview(charactersLengthLabel)
            }
            
            // 更新文本容器边距
            updateTextContainerInsets()
        }
    }
    
    private func wy_addTextChangeNoti() {
        if !wy_addNoti {
            // 使用方法交换替代通知
            UITextView.swizzleTextViewImplementation
            wy_addNoti = true
        }
    }
    
    @objc private func wy_textDidChange() {
        wy_characterTruncation()
    }
    
    private func wy_characterTruncation() {
        // 字符截取
        if wy_maximumLimit > 0 {
            if let selectedRange = self.markedTextRange,
               let _ = self.position(from: selectedRange.start, offset: 0) {
                // 有高亮文本，不处理
            } else if self.text.count > wy_maximumLimit {
                let index = self.text.index(self.text.startIndex, offsetBy: wy_maximumLimit)
                self.text = String(self.text[..<index])
            }
        }
        
        // 文本变化回调
        if let handle = wy_textHandle, self.text != wy_lastTextStr {
            handle(self.text)
        }
        wy_lastTextStr = self.text
        
        // 更新占位标签显示
        if wy_havePlaceholderLable {
            placeholderLabel.isHidden = !self.text.isEmpty
        }
        
        // 更新字符长度标签
        if wy_haveCharactersLengthLable {
            let currentLength = min(self.text.count, wy_maximumLimit)
            charactersLengthLabel.text = "\(currentLength)/\(wy_maximumLimit)\t"
        }
    }
    
    @objc private func showTextView() {
        self.becomeFirstResponder()
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 禁止剪切
        if action == #selector(cut(_:)) {
            return wy_allowCopyPaste
        }
        
        // 禁止粘贴
        if action == #selector(paste(_:)) {
            return wy_allowCopyPaste
        }
        
        // 禁止选择
        if action == #selector(select(_:)) {
            return wy_allowCopyPaste
        }
        
        // 禁止全选
        if action == #selector(selectAll(_:)) {
            return wy_allowCopyPaste
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    private static func initializeMethod() {
        // 确保方法交换只执行一次
        _ = swizzleTextViewImplementation
    }
    
    private struct WYAssociatedKeys {
        static var maximumLimitKey: UInt8 = 0
        static var characterLengthPromptKey: UInt8 = 0
        static var allowCopyPasteKey: UInt8 = 0
        static var placeholderAllowsNewlinesKey: UInt8 = 0
        static var addNotiKey: UInt8 = 0
        static var havePlaceholderLableKey: UInt8 = 0
        static var haveCharactersLengthLableKey: UInt8 = 0
        static var lastTextStrKey: UInt8 = 0
        static var textHandleKey: UInt8 = 0
        static var placeholderLableKey: UInt8 = 0
        static var charactersLengthLableKey: UInt8 = 0
        static var charactersLengthLableFrameKey: UInt8 = 0
        static var textContainerInsetKey: UInt8 = 0
    }
}
