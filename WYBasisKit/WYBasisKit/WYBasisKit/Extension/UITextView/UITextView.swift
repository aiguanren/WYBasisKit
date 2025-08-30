//
//  UITextView.swift
//  WYBasiskit
//
//  Created by guanren on 2025/8/25.
//

import UIKit

public extension UITextView {
    
    /// 占位文本标签
    var wy_placeholderLabel: UILabel {
        return placeholderLabel
    }
    
    /// 占位文本可以展示几行(默认0，无限换行)
    var wy_placeholderNumberOfLines: Int {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderNumberOfLines) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderNumberOfLines, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            placeholderLabel.numberOfLines = newValue
        }
    }
    
    /// 字符长度标签
    var wy_charactersLengthLabel: UILabel {
        return charactersLengthLabel
    }
    
    /// 是否允许复制粘贴(默认true)
    var wy_allowCopyPaste: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.allowCopyPasteKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.allowCopyPasteKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            
            UITextView.wy_enableAllMonitors()
        }
    }

    /**
     * 实现最大显示字符限制与占位文本标签的显示与隐藏
     * 本方法需要使用者在textViewDidChange等文本发生改变的事件中调用此方法，否则无法处理最大显示字符限制与占位文本标签的显示与隐藏
     */
    func wy_maximumLimit(_ maximumLength: Int) {
        UITextView.wy_enableAllMonitors()
        wy_textDidChangeHandler(maximumLength)
    }
}

// 属性管理
private extension UITextView {
    
    var placeholderLabel: UILabel {
        get {
            if let label = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderLableKey) as? UILabel {
                return label
            }
            let label = UILabel()
            label.numberOfLines = 0
            label.isUserInteractionEnabled = false
            label.font = self.font
            label.textColor = .lightGray
            label.translatesAutoresizingMaskIntoConstraints = false
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderLableKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 初始添加约束
            setupLabelDefaultConstraints()
            
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
            
            let label = UILabel()
            label.textAlignment = .right
            label.isUserInteractionEnabled = false
            label.font = self.font
            label.textColor = .lightGray
            label.backgroundColor = .clear
            label.translatesAutoresizingMaskIntoConstraints = false
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableKey, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 初始添加约束
            setupLabelDefaultConstraints()
            
            return label
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.charactersLengthLableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    struct WYAssociatedKeys {
        // 占位标签相关
        static var placeholderLableKey: UInt8 = 0
        static var placeholderNumberOfLines: UInt8 = 0
        
        // 字符长度标签相关
        static var charactersLengthLableKey: UInt8 = 0
        
        // 添加约束的关联键
        static var placeholderLeadingConstraintKey: UInt8 = 0
        static var placeholderTopConstraintKey: UInt8 = 0
        static var placeholderWidthConstraintKey: UInt8 = 0
        
        static var lengthTrailingAnchorConstraintKey: UInt8 = 0
        static var lengthBottomConstraintKey: UInt8 = 0
        
        static var allowCopyPasteKey: UInt8 = 0
    }
}

// 方法实现
extension UITextView {
    
    open override func updateConstraints() {
        super.updateConstraints()
        updateLabelConstraints()
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
    
    private func setupLabelDefaultConstraints() {
        if (placeholderLabel.superview == nil) {
            insertSubview(placeholderLabel, at: 0)
            
            // 移除现有约束
            if let leadingConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderLeadingConstraintKey) as? NSLayoutConstraint {
                leadingConstraint.isActive = false
            }
            if let topConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderTopConstraintKey) as? NSLayoutConstraint {
                topConstraint.isActive = false
            }
            if let widthConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderWidthConstraintKey) as? NSLayoutConstraint {
                widthConstraint.isActive = false
            }
            
            // 创建新约束
            let leadingConstraint = placeholderLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: textContainerInset.left + 3 // 这里加3是因为设置textContainerInset.left后，看起来会比placeholderLabel的x大一些，所以手动处理下
            )
            let topConstraint = placeholderLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: textContainerInset.top
            )
            let widthConstraint = placeholderLabel.widthAnchor.constraint(
                lessThanOrEqualTo: self.widthAnchor,
                constant: -(textContainerInset.left + textContainerInset.right) // 两边都要减去边距
            )
            
            // 存储约束引用
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderLeadingConstraintKey, leadingConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderTopConstraintKey, topConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &WYAssociatedKeys.placeholderWidthConstraintKey, widthConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 激活约束
            NSLayoutConstraint.activate([leadingConstraint, topConstraint, widthConstraint])
        }
        
        if charactersLengthLabel.superview == nil {
            superview?.addSubview(charactersLengthLabel)
            
            if let trailingConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.lengthTrailingAnchorConstraintKey) as? NSLayoutConstraint {
                trailingConstraint.isActive = false
            }
            if let bottomConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.lengthBottomConstraintKey) as? NSLayoutConstraint {
                bottomConstraint.isActive = false
            }
            
            let trailingConstraint = charactersLengthLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -(textContainerInset.right + 3)
            )
            let bottomConstraint = charactersLengthLabel.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -textContainerInset.bottom
            )
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.lengthTrailingAnchorConstraintKey, trailingConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &WYAssociatedKeys.lengthBottomConstraintKey, bottomConstraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            NSLayoutConstraint.activate([trailingConstraint, bottomConstraint])
        }
    }
    
    private func updateLabelConstraints() {
        // 更新现有约束的constant值
        if let leadingConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderLeadingConstraintKey) as? NSLayoutConstraint {
            leadingConstraint.constant = textContainerInset.left + 3
        }
        if let topConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderTopConstraintKey) as? NSLayoutConstraint {
            topConstraint.constant = textContainerInset.top
        }
        if let widthConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.placeholderWidthConstraintKey) as? NSLayoutConstraint {
            widthConstraint.constant = -(textContainerInset.left + textContainerInset.right)
        }
        
        if let trailingConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.lengthTrailingAnchorConstraintKey) as? NSLayoutConstraint {
            trailingConstraint.constant = -(textContainerInset.right + 3)
        }
        if let bottomConstraint = objc_getAssociatedObject(self, &WYAssociatedKeys.lengthBottomConstraintKey) as? NSLayoutConstraint {
            bottomConstraint.constant = -textContainerInset.bottom
        }
    }
}

// 方法交换，实现文本与textContainerInset变化监听
private extension UITextView {
    
    /// 开启所有监听（文本变化 + textContainerInset 变化）
    static func wy_enableAllMonitors() {
        _ = swizzleTextDidChangeImplementation
        _ = swizzleInsetSetterImplementation
    }
    
    static let swizzleTextDidChangeImplementation: Void = {
        // 交换 setText 方法
        let originalSetText = class_getInstanceMethod(UITextView.self, #selector(setter: UITextView.text))
        let swizzledSetText = class_getInstanceMethod(UITextView.self, #selector(wy_setText(_:)))
        method_exchangeImplementations(originalSetText!, swizzledSetText!)
        
        // 交换文本修改相关方法
        let methodsToSwizzle = [
            #selector(copy(_:)),
            #selector(paste(_:)),
            #selector(cut(_:))
        ]
        
        let swizzledMethods = [
            #selector(wy_copy(_:)),
            #selector(wy_paste(_:)),
            #selector(wy_cut(_:))
        ]
        
        for i in 0..<methodsToSwizzle.count {
            guard let originalMethod = class_getInstanceMethod(UITextView.self, methodsToSwizzle[i]),
                  let swizzledMethod = class_getInstanceMethod(UITextView.self, swizzledMethods[i]) else {
                continue
            }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    static let swizzleInsetSetterImplementation: Void = {
        let originalSelector = #selector(setter: UITextView.textContainerInset)
        let swizzledSelector = #selector(UITextView.wy_setTextContainerInset(_:))
        
        if let originalMethod = class_getInstanceMethod(UITextView.self, originalSelector),
           let swizzledMethod = class_getInstanceMethod(UITextView.self, swizzledSelector) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    // 文本修改方法交换实现
    @objc func wy_setText(_ text: String?) {
        let originalText: String = self.text
        self.wy_setText(text)
    }
    
    @objc func wy_copy(_ sender: Any?) {
        guard wy_allowCopyPaste else {
            // 清空通用剪贴板内容
            UIPasteboard.general.string = ""
            return
        }
        self.wy_copy(sender)
    }
    
    @objc func wy_paste(_ sender: Any?) {
        guard wy_allowCopyPaste else { return }
        self.wy_paste(sender)
    }
    
    @objc func wy_cut(_ sender: Any?) {
        guard wy_allowCopyPaste else {
            // 清空通用剪贴板内容
            UIPasteboard.general.string = ""
            return
        }
        
        self.wy_cut(sender)
    }
    
    /// 统一的变化处理逻辑
    func wy_textDidChangeHandler(_ maximumLength: Int) {
        // 更新 placeholder 显示/隐藏
        placeholderLabel.isHidden = !self.text.isEmpty
        
        // 更新字符长度
        if maximumLength > 0 {
            let currentLength = min(self.text.count, maximumLength)
            charactersLengthLabel.text = "\(currentLength)/\(maximumLength)"
            
            // 超过限制直接截断
            if self.text.count > maximumLength {
                let endIndex = self.text.index(self.text.startIndex, offsetBy: maximumLength)
                self.text = String(self.text[..<endIndex])
                
                // 截断后移动光标到末尾，使用异步确保在系统操作之后执行
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // 确保光标位置正确，移动到文本末尾
                    let newPosition = self.endOfDocument
                    self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
                }
            }
        }
    }
    
    @objc func wy_setTextContainerInset(_ inset: UIEdgeInsets) {
        // 调用原始实现
        self.wy_setTextContainerInset(inset)
        
        // 更新 placeholder / lengthLabel 约束
        updateLabelConstraints()
    }
}
