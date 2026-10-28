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
    
    /**
     *  设置按钮内容的四周边距
     *
     *  @param insets 四周内边距
     */
    func wy_contentInsets(_ insets: UIEdgeInsets) {
        var buttonConfiguration = configuration ?? UIButton.Configuration.borderless()
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
        configuration = buttonConfiguration
    }

    /**
     *  利用configuration或EdgeInsets自由设置UIButton的titleLabel和imageView的显示位置
     *  注意：这个方法需要在设置图片和文字之后才可以调用，且button的大小要大于 图片大小+文字大小+spacing
     *  什么都不设置默认为图片在左，文字在右，居中且挨着排列的
     *  @param spacing 图片和文字的间隔
     */
    func wy_adjust(position: WYButtonPosition, spacing: CGFloat = 0) {
        
        Task { @MainActor in
            
            guard self.bounds.size != .zero else { return }
            
            // wy_layoutEdgeInsets方法 需要在设置图片、文字与约束或者frame之后才可以调用，且button的size最好大于 图片大小+文字大小+spacing
            if self.imageView?.image == nil || self.currentImage == nil || self.currentTitle?.isEmpty == true || self.titleLabel?.text?.isEmpty == true {
                return
            }
            
            let imageSize = self.imageView?.intrinsicContentSize ?? .zero
            let titleSize = self.titleLabel?.intrinsicContentSize ?? .zero
            let spacing = spacing
            
            let totalWidth: CGFloat
            let totalHeight: CGFloat
            
            switch position {
            case .imageLeftTitleRight, .imageRightTitleLeft:
                totalWidth = imageSize.width + spacing + titleSize.width
                totalHeight = max(imageSize.height, titleSize.height)
            case .imageTopTitleBottom, .imageBottomTitleTop:
                totalWidth = max(imageSize.width, titleSize.width)
                totalHeight = imageSize.height + spacing + titleSize.height
            }
            
            // 可用内容区域
            let contentRect = self.bounds
            
            let contentX: CGFloat
            switch self.contentHorizontalAlignment {
            case .left, .leading:
                contentX = contentRect.minX
            case .right, .trailing:
                contentX = contentRect.maxX - totalWidth
            case .fill:
                contentX = contentRect.minX
            default: // center
                contentX = contentRect.minX + (contentRect.width - totalWidth) / 2.0
            }
            
            let contentY: CGFloat
            switch self.contentVerticalAlignment {
            case .top:
                contentY = contentRect.minY
            case .bottom:
                contentY = contentRect.maxY - totalHeight
            case .fill:
                contentY = contentRect.minY
            default: // center
                contentY = contentRect.minY + (contentRect.height - totalHeight) / 2.0
            }
            
            var imageFrame = CGRect.zero
            var titleFrame = CGRect.zero
            
            switch position {
                
            case .imageLeftTitleRight:
                
                imageFrame = CGRect(
                    x: contentX,
                    y: contentY + (totalHeight - imageSize.height) / 2.0,
                    width: imageSize.width,
                    height: imageSize.height
                )
                
                titleFrame = CGRect(
                    x: imageFrame.maxX + spacing,
                    y: contentY + (totalHeight - titleSize.height) / 2.0,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
            case .imageRightTitleLeft:
                
                titleFrame = CGRect(
                    x: contentX,
                    y: contentY + (totalHeight - titleSize.height) / 2.0,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                imageFrame = CGRect(
                    x: titleFrame.maxX + spacing,
                    y: contentY + (totalHeight - imageSize.height) / 2.0,
                    width: imageSize.width,
                    height: imageSize.height
                )
                
            case .imageTopTitleBottom:
                
                imageFrame = CGRect(
                    x: contentX + (totalWidth - imageSize.width) / 2.0,
                    y: contentY,
                    width: imageSize.width,
                    height: imageSize.height
                )
                
                titleFrame = CGRect(
                    x: contentX + (totalWidth - titleSize.width) / 2.0,
                    y: imageFrame.maxY + spacing,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
            case .imageBottomTitleTop:
                
                titleFrame = CGRect(
                    x: contentX + (totalWidth - titleSize.width) / 2.0,
                    y: contentY,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                imageFrame = CGRect(
                    x: contentX + (totalWidth - imageSize.width) / 2.0,
                    y: titleFrame.maxY + spacing,
                    width: imageSize.width,
                    height: imageSize.height
                )
            }
            
            self.wy_imageRect = imageFrame
            self.wy_titleRect = titleFrame
        }
    }
}

public typealias WYIntervalSelector = ((_ button: UIButton) -> Void)
