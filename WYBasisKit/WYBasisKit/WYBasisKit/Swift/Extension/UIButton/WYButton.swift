//
//  UIButton.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// UIButton图片控件和文本控件显示位置
@frozen public enum WYButtonPosition: Int {
    
    /** 图片在左，文字在右，默认 */
    case imageLeftTitleRight = 0
    /** 图片在右，文字在左 */
    case imageRightTitleLeft
    /** 图片在上，文字在下 */
    case imageTopTitleBottom
    /** 图片在下，文字在上 */
    case imageBottomTitleTop
}

public extension UIButton {
    
    /** 按钮默认状态文字 */
    var wy_nTitle: String {
        set {
            setTitle(newValue, for: .normal)
        }
        get {
            return title(for: .normal) ?? ""
        }
    }
    
    /** 按钮高亮状态文字 */
    var wy_hTitle: String {
        set {
            setTitle(newValue, for: .highlighted)
        }
        get {
            return title(for: .highlighted) ?? ""
        }
    }
    
    /** 按钮选中状态文字 */
    var wy_sTitle: String {
        set {
            setTitle(newValue, for: .selected)
        }
        get {
            return title(for: .selected) ?? ""
        }
    }
    
    /** 按钮默认状态文字颜色 */
    var wy_title_nColor: UIColor {
        set {
            setTitleColor(newValue, for: .normal)
        }
        get {
            return titleColor(for: .normal) ?? .clear
        }
    }
    
    /** 按钮高亮状态文字颜色 */
    var wy_title_hColor: UIColor {
        set {
            setTitleColor(newValue, for: .highlighted)
        }
        get {
            return titleColor(for: .highlighted) ?? .clear
        }
    }
    
    /** 按钮选中状态文字颜色 */
    var wy_title_sColor: UIColor {
        set {
            setTitleColor(newValue, for: .selected)
        }
        get {
            return titleColor(for: .selected) ?? .clear
        }
    }
    
    
    /** 按钮默认状态图片 */
    var wy_nImage: UIImage {
        set {
            setImage(newValue, for: .normal)
        }
        get {
            return image(for: .normal) ?? UIKit.UIImage.wy_createImage(from: .clear)
        }
    }
    
    /** 按钮高亮状态图片 */
    var wy_hImage: UIImage {
        set {
            setImage(newValue, for: .highlighted)
        }
        get {
            return image(for: .highlighted) ?? UIKit.UIImage.wy_createImage(from: .clear)
        }
    }
    
    /** 按钮选中状态图片 */
    var wy_sImage: UIImage {
        set {
            setImage(newValue, for: .selected)
        }
        get {
            return image(for: .selected) ?? UIKit.UIImage.wy_createImage(from: .clear)
        }
    }
    
    /** 设置按钮背景色 */
    func wy_backgroundColor(_ color: UIColor, forState: UIControl.State) {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        setBackgroundImage(colorImage, for: forState)
    }
    
    /** 设置按钮字号 */
    var wy_titleFont: UIFont {
        
        set {
            titleLabel?.font = newValue
        }
        
        get {
            return (titleLabel?.font)!
        }
    }
    
    /** 利用运行时设置UIButton的titleLabel的显示位置 */
    var wy_titleRect: CGRect? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_titleRect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UIButton.swizzleLayoutSubviews()
            setNeedsLayout()
        }
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_titleRect) as? CGRect
        }
    }
    
    /** 利用运行时设置UIButton的imageView的显示位置 */
    var wy_imageRect: CGRect? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_imageRect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UIButton.swizzleLayoutSubviews()
            setNeedsLayout()
        }
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_imageRect) as? CGRect
        }
    }
    
    /** 设置按钮左对齐 */
    func wy_leftAlignment() {
        contentHorizontalAlignment = .left
    }
    
    /** 设置按钮中心对齐 */
    func wy_centerAlignment() {
        contentHorizontalAlignment = .center
    }
    
    /** 设置按钮右对齐 */
    func wy_rightAlignment() {
        contentHorizontalAlignment = .right
    }
    
    /** 设置按钮上对齐 */
    func wy_topAlignment() {
        contentVerticalAlignment = .top
    }
    
    /** 设置按钮下对齐 */
    func wy_bottomAlignment() {
        contentVerticalAlignment = .bottom
    }
    
    /**
     *  利用configuration或EdgeInsets自由设置UIButton的titleLabel和imageView的显示位置
     *  注意：这个方法需要在设置图片和文字之后才可以调用，且button的大小要大于 图片大小+文字大小+spacing
     *  什么都不设置默认为图片在左，文字在右，居中且挨着排列的
     *  @param spacing 图片和文字的间隔
     */
    func wy_adjust(position: WYButtonPosition, spacing: CGFloat = 0) {
        
        DispatchQueue.main.async {
            
            if self.imageView?.image == nil || self.currentImage == nil || self.currentTitle?.isEmpty == true || self.titleLabel?.text?.isEmpty == true {
                
                //wy_print("wy_layouEdgeInsets方法 需要在设置图片、文字与约束或者frame之后才可以调用，且button的size最好大于 图片大小+文字大小+spacing")
                return
            }
            self.superview?.layoutIfNeeded()
            
            if #available(iOS 15.0, *) {
                
                var configuration: UIButton.Configuration = self.configuration ?? .plain()
                
                switch position {
                    
                case .imageRightTitleLeft:
                    configuration.imagePlacement = .trailing
                    break
                    
                case .imageLeftTitleRight:
                    configuration.imagePlacement = .leading
                    break
                    
                case .imageTopTitleBottom:
                    configuration.imagePlacement = .top
                    break
                    
                case .imageBottomTitleTop:
                    configuration.imagePlacement = .bottom
                    break
                }
                configuration.imagePadding = spacing
                self.configuration = configuration
                self.setNeedsUpdateConfiguration()
                
            }else {
                
                let imageWidth: CGFloat = (self.imageView?.frame.size.width) ?? 0
                let imageHeight: CGFloat = (self.imageView?.frame.size.height) ?? 0
                let labelWidth: CGFloat = CGFloat(self.titleLabel?.intrinsicContentSize.width ?? 0)
                let labelHeight: CGFloat = CGFloat(self.titleLabel?.intrinsicContentSize.height ?? 0)
                
                switch position {

                case .imageRightTitleLeft:
                    
                    self.imageEdgeInsets = UIEdgeInsets(top:0, left:labelWidth+spacing/2.0, bottom: 0, right: -labelWidth-spacing/2.0)
                    self.titleEdgeInsets =  UIEdgeInsets(top:0, left:-imageWidth-spacing/2.0, bottom: 0, right:imageWidth+spacing/2.0)
                    break
                    
                case .imageLeftTitleRight:
                    
                    self.titleEdgeInsets = UIEdgeInsets(top:0, left:spacing/2.0, bottom: 0, right: -spacing/2.0)
                    self.imageEdgeInsets = UIEdgeInsets(top:0, left:-spacing/2.0, bottom: 0, right:spacing/2.0)
                    break
                    
                case .imageTopTitleBottom:
                    
                    self.imageEdgeInsets = UIEdgeInsets(top: -labelHeight - spacing/2.0, left: 0, bottom: 0, right:  -labelWidth)
                    self.titleEdgeInsets =  UIEdgeInsets(top:0, left: -imageWidth, bottom: -imageHeight-spacing/2.0, right: 0)
                    break
                    
                case .imageBottomTitleTop:
                    
                    self.imageEdgeInsets = UIEdgeInsets(top:0, left:0, bottom: -labelHeight-spacing/2.0, right: -labelWidth)
                    self.titleEdgeInsets =  UIEdgeInsets(top:-imageHeight-spacing/2.0, left:-imageWidth, bottom: 0, right: 0)
                    break
                }
            }
            // 强制刷新布局
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }
    }
}

public typealias IntervalSelector = ((UIButton)->Void)
private extension UIButton {
    
    private var intervalSelector: IntervalSelector? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.intervalSelector, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.intervalSelector) as? IntervalSelector
        }
    }
    
    private var selectorInterval: TimeInterval {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.selectorInterval, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.selectorInterval) as? TimeInterval ?? 0
        }
    }
    
    @objc private func buttonDelayHandler(_ button: UIButton) {
        intervalSelector?(button)
        isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + selectorInterval) { [weak self] in
            DispatchQueue.main.async {
                self?.isUserInteractionEnabled = true
            }
        }
    }
    
    /***** 利用运行时自由设置UIButton的titleLabel和imageView的显示位置 *****/
    static func swizzleLayoutSubviews() {
        _ = self.swizzleLayoutSubviewsOnce
    }
    
    // 方法交换
    private static let swizzleLayoutSubviewsOnce: Void = {
        let cls = UIButton.self
        let original = #selector(UIButton.layoutSubviews)
        let swizzled = #selector(UIButton._custom_layoutSubviews)

        if let originalMethod = class_getInstanceMethod(cls, original),
           let swizzledMethod = class_getInstanceMethod(cls, swizzled) {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()

    // 替换 layoutSubviews
    @objc private func _custom_layoutSubviews() {
        self._custom_layoutSubviews() // 调用原始 layoutSubviews

        // 强制 layout 前先 sizeToFit 避免 size 0
        self.titleLabel?.sizeToFit()
        self.imageView?.sizeToFit()

        if let imageView = self.imageView {
            if let frame = self.wy_imageRect {
                imageView.frame = frame
            }
        }

        if let titleLabel = self.titleLabel {
            if let frame = self.wy_titleRect {
                titleLabel.frame = frame
            }
        }
    }
    /***** 利用运行时自由设置UIButton的titleLabel和imageView的显示位置 *****/
    
    struct WYAssociatedKeys {
        static var intervalSelector: UInt8 = 0
        static var selectorInterval: UInt8 = 0
        static var positionKey: UInt8 = 0
        static var spacingKey: UInt8 = 0
        static var imageViewSizeKey: UInt8 = 0
        static var titleLabelSizeKey: UInt8 = 0
        static var wy_imageRect: UInt8 = 0
        static var wy_titleRect: UInt8 = 0
    }
}
