//
//  UIButtonObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// UIButton图片控件和文本控件显示位置
@objc(WYButtonPosition)
@frozen public enum WYButtonPositionObjC: Int {
    
    /** 图片在左，文字在右，默认 */
    case imageLeftTitleRight = 0
    /** 图片在右，文字在左 */
    case imageRightTitleLeft
    /** 图片在上，文字在下 */
    case imageTopTitleBottom
    /** 图片在下，文字在上 */
    case imageBottomTitleTop
}

@objc public extension UIButton {
    
    /** 按钮默认状态文字 */
    @objc(wy_nTitle)
    var wy_nTitleObjC: String {
        set { wy_nTitle = newValue }
        get { return wy_nTitle }
    }
    
    /** 按钮高亮状态文字 */
    @objc(wy_hTitle)
    var wy_hTitleObjC: String {
        set { wy_hTitle = newValue }
        get { return wy_hTitle }
    }
    
    /** 按钮选中状态文字 */
    @objc(wy_sTitle)
    var wy_sTitleObjC: String {
        set { wy_sTitle = newValue }
        get { return wy_sTitle }
    }
    
    /** 按钮默认状态文字颜色 */
    @objc(wy_title_nColor)
    var wy_title_nColorObjC: UIColor {
        set { wy_title_nColor = newValue }
        get { return wy_title_nColor }
    }
    
    /** 按钮高亮状态文字颜色 */
    @objc(wy_title_hColor)
    var wy_title_hColorObjC: UIColor {
        set { wy_title_hColor = newValue }
        get { return wy_title_hColor }
    }
    
    /** 按钮选中状态文字颜色 */
    @objc(wy_title_sColor)
    var wy_title_sColorObjC: UIColor {
        set { wy_title_sColor = newValue }
        get { return wy_title_sColor }
    }
    
    
    /** 按钮默认状态图片 */
    @objc(wy_nImage)
    var wy_nImageObjC: UIImage {
        set { wy_nImage = newValue }
        get { return wy_nImage }
    }
    
    /** 按钮高亮状态图片 */
    @objc(wy_hImage)
    var wy_hImageObjC: UIImage {
        set { wy_hImage = newValue }
        get { return wy_hImage }
    }
    
    /** 按钮选中状态图片 */
    @objc(wy_sImage)
    var wy_sImageObjC: UIImage {
        set { wy_sImage = newValue }
        get { return wy_sImage }
    }
    
    /** 设置按钮背景色 */
    @objc(wy_backgroundColor:forState:)
    func wy_backgroundColorObjC(_ color: UIColor, forState: UIControl.State) {
        wy_backgroundColor(color, forState: forState)
    }
    
    /** 设置按钮字号 */
    @objc(wy_titleFont)
    var wy_titleFontObjC: UIFont {
        set { wy_titleFont = newValue }
        get { return wy_titleFont }
    }
    
    /** 利用运行时设置UIButton的titleLabel的显示位置 */
    @objc(wy_titleRect)
    var wy_titleRectObjC: CGRect {
        set { wy_titleRect = newValue }
        get { return wy_titleRect ?? .zero }
    }
    
    /** 利用运行时设置UIButton的imageView的显示位置 */
    @objc(wy_imageRect)
    var wy_imageRectObjC: CGRect {
        set { wy_imageRect = newValue }
        get { return wy_imageRect ?? .zero }
    }
    
    /** 设置按钮左对齐 */
    @objc(wy_leftAlignment)
    func wy_leftAlignmentObjC() {
        wy_leftAlignment()
    }
    
    /** 设置按钮中心对齐 */
    @objc(wy_centerAlignment)
    func wy_centerAlignmentObjC() {
        wy_centerAlignment()
    }
    
    /** 设置按钮右对齐 */
    @objc(wy_rightAlignment)
    func wy_rightAlignmentObjC() {
        wy_rightAlignment()
    }
    
    /** 设置按钮上对齐 */
    @objc(wy_topAlignment)
    func wy_topAlignmentObjC() {
        wy_topAlignment()
    }
    
    /** 设置按钮下对齐 */
    @objc(wy_bottomAlignment)
    func wy_bottomAlignmentObjC() {
        wy_bottomAlignment()
    }
    
    /**
     *  利用configuration或EdgeInsets自由设置UIButton的titleLabel和imageView的显示位置
     *  注意：这个方法需要在设置图片和文字之后才可以调用，且button的大小要大于 图片大小+文字大小+spacing
     *  什么都不设置默认为图片在左，文字在右，居中且挨着排列的
     *  @param spacing 图片和文字的间隔
     */
    @objc(wy_adjustPosition:spacing:)
    func wy_adjustObjC(position: WYButtonPositionObjC, spacing: CGFloat = 0) {
        wy_adjust(position: WYButtonPosition(rawValue: position.rawValue) ?? .imageLeftTitleRight, spacing: spacing)
    }
}
