//
//  UINavigationControllerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension UINavigationController {
    
    /// 获取一个纯文本UIBarButtonItem
    @objc(wy_navTitleItemWithTitle:color:target:selector:)
    func wy_navTitleItemObjC(title: String,
                             color: UIColor = .black,
                            target: Any? = nil,
                          selector: Selector? = nil) -> UIBarButtonItem {
        return wy_navTitleItem(title: title, color: color, target: target, selector: selector)
    }
    
    /// 获取一个纯图片UIBarButtonItem
    @objc(wy_navImageItemWithImage:color:target:selector:)
    func wy_navImageItemObjC(image: UIImage,
                             color: UIColor = .black,
                            target: Any? = nil,
                          selector: Selector? = nil) -> UIBarButtonItem {
        return wy_navImageItem(image: image, color: color, target: target, selector: selector)
    }
    
    /// 获取一个自定义UIBarButtonItem
    @objc(wy_navCustomItemWithView:)
    func wy_navCustomItemObjC(itemView: UIView) -> UIBarButtonItem {
        return wy_navCustomItem(itemView: itemView)
    }
}

@objc public extension UINavigationController {
    
    // MARK: - 导航栏(全局)配置属性
    
    /// 导航栏背景色 (优先级: 背景图 > 背景色)
    @objc(wy_navBarBackgroundColor)
    static var wy_navBarBackgroundColorObjC: UIColor? {
        set { wy_navBarBackgroundColor = newValue }
        get { return wy_navBarBackgroundColor }
    }
    
    /// 导航栏背景图 (优先级: 背景图 > 背景色)
    @objc(wy_navBarBackgroundImage)
    static var wy_navBarBackgroundImageObjC: UIImage? {
        set { wy_navBarBackgroundImage = newValue }
        get { return wy_navBarBackgroundImage }
    }
    
    /// 导航栏标题字体
    @objc(wy_navBarTitleFont)
    static var wy_navBarTitleFontObjC: UIFont {
        set { wy_navBarTitleFont = newValue }
        get { return wy_navBarTitleFont }
    }
    
    /// 导航栏标题颜色
    @objc(wy_navBarTitleColor)
    static var wy_navBarTitleColorObjC: UIColor {
        set { wy_navBarTitleColor = newValue }
        get { return wy_navBarTitleColor }
    }
    
    /// 导航栏返回按钮图片
    @objc(wy_navBarReturnButtonImage)
    static var wy_navBarReturnButtonImageObjC: UIImage? {
        set { wy_navBarReturnButtonImage = newValue }
        get { return wy_navBarReturnButtonImage }
    }
    
    /// 导航栏返回按钮颜色
    @objc(wy_navBarReturnButtonColor)
    static var wy_navBarReturnButtonColorObjC: UIColor {
        set { wy_navBarReturnButtonColor = newValue }
        get { return wy_navBarReturnButtonColor }
    }
    
    /// 导航栏返回按钮文本
    @objc(wy_navBarReturnButtonTitle)
    static var wy_navBarReturnButtonTitleObjC: String {
        set { wy_navBarReturnButtonTitle = newValue }
        get { return wy_navBarReturnButtonTitle }
    }
    
    /// 导航栏是否隐藏底部阴影线
    @objc(wy_navBarShadowLineHidden)
    static var wy_navBarShadowLineHiddenObjC: Bool {
        set { wy_navBarShadowLineHidden = newValue }
        get { return wy_navBarShadowLineHidden }
    }
    
    /// 导航栏阴影线颜色 (当 shadowHidden = false 时生效)
    @objc(wy_navBarShadowLineColor)
    static var wy_navBarShadowLineColorObjC: UIColor? {
        set { wy_navBarShadowLineColor = newValue }
        get { return wy_navBarShadowLineColor }
    }
    
    // MARK: - 便捷(全局)配置方法
    
    /// 设置全局导航栏样式
    @objc(wy_setGlobalNavigationBarWithBackgroundColor:backgroundImage:titleFont:titleColor:returnButtonImage:returnButtonColor:returnButtonTitle:shadowLineHidden:shadowLineColor:)
    static func wy_setGlobalNavigationBarObjC(
        backgroundColor: UIColor? = nil,
        backgroundImage: UIImage? = nil,
        titleFont: UIFont? = nil,
        titleColor: UIColor? = nil,
        returnButtonImage: UIImage? = nil,
        returnButtonColor: UIColor? = nil,
        returnButtonTitle: String? = nil,
        shadowLineHidden: Bool = true,
        shadowLineColor: UIColor? = nil
    ) {
        if let backgroundColor = backgroundColor { wy_navBarBackgroundColor = backgroundColor }
        if let backgroundImage = backgroundImage { wy_navBarBackgroundImage = backgroundImage }
        if let titleFont = titleFont { wy_navBarTitleFont = titleFont }
        if let titleColor = titleColor { wy_navBarTitleColor = titleColor }
        if let returnButtonImage = returnButtonImage { wy_navBarReturnButtonImage = returnButtonImage }
        if let returnButtonColor = returnButtonColor { wy_navBarReturnButtonColor = returnButtonColor }
        if let returnButtonTitle = returnButtonTitle { wy_navBarReturnButtonTitle = returnButtonTitle }
        if let shadowLineColor = shadowLineColor { wy_navBarShadowLineColor = shadowLineColor }
        wy_navBarShadowLineHidden = shadowLineHidden
    }
}

@objc public extension UIViewController {
    
    // MARK: - 控制器级别属性（有自定义值使用自定义值，否则使用全局值）
    
    /// 导航栏背景色
    @objc(wy_navBarBackgroundColor)
    var wy_navBarBackgroundColorObjC: UIColor? {
        get { return wy_navBarBackgroundColor }
        set { wy_navBarBackgroundColor = newValue }
    }
    
    /// 导航栏背景图
    @objc(wy_navBarBackgroundImage)
    var wy_navBarBackgroundImageObjC: UIImage? {
        get { return wy_navBarBackgroundImage }
        set { wy_navBarBackgroundImage = newValue }
    }
    
    /// 导航栏标题字体
    @objc(wy_navBarTitleFont)
    var wy_navBarTitleFontObjC: UIFont {
        get { return wy_navBarTitleFont }
        set { wy_navBarTitleFont = newValue }
    }
    
    /// 导航栏标题颜色
    @objc(wy_navBarTitleColor)
    var wy_navBarTitleColorObjC: UIColor {
        get { return wy_navBarTitleColor }
        set { wy_navBarTitleColor = newValue }
    }
    
    /// 导航栏返回按钮图片
    @objc(wy_navBarReturnButtonImage)
    var wy_navBarReturnButtonImageObjC: UIImage? {
        get { return wy_navBarReturnButtonImage }
        set { wy_navBarReturnButtonImage = newValue }
    }
    
    /// 导航栏返回按钮颜色
    @objc(wy_navBarReturnButtonColor)
    var wy_navBarReturnButtonColorObjC: UIColor {
        get { return wy_navBarReturnButtonColor }
        set { wy_navBarReturnButtonColor = newValue }
    }
    
    /// 导航栏返回按钮文本
    @objc(wy_navBarReturnButtonTitle)
    var wy_navBarReturnButtonTitleObjC: String {
        get { return wy_navBarReturnButtonTitle }
        set { wy_navBarReturnButtonTitle = newValue }
    }
    
    /// 导航栏是否隐藏底部阴影线
    @objc(wy_navBarShadowLineHidden)
    var wy_navBarShadowLineHiddenObjC: Bool {
        get { return wy_navBarShadowLineHidden }
        set { wy_navBarShadowLineHidden = newValue }
    }
    
    /// 导航栏阴影线颜色
    @objc(wy_navBarShadowLineColor)
    var wy_navBarShadowLineColorObjC: UIColor? {
        get { return wy_navBarShadowLineColor }
        set { wy_navBarShadowLineColor = newValue }
    }
    
    /// 更新导航栏样式
    @objc(updateNavigationBarAppearance)
    func updateNavigationBarAppearanceObjC() {
        updateNavigationBarAppearance()
    }
    
    // MARK: - 便捷设置方法
    
    /// 设置导航栏背景色
    @objc(wy_setNavBarBackgroundColor:)
    func wy_setNavBarBackgroundColorObjC(_ color: UIColor?) {
        wy_setNavBarBackgroundColor(color)
    }
    
    /// 设置导航栏背景图
    @objc(wy_setNavBarBackgroundImage:)
    func wy_setNavBarBackgroundImageObjC(_ image: UIImage?) {
        wy_setNavBarBackgroundImage(image)
    }
    
    /// 设置导航栏标题样式
    @objc(wy_setNavBarTitleWithFont:color:)
    func wy_setNavBarTitleObjC(font: UIFont, color: UIColor) {
        wy_setNavBarTitle(font: font, color: color)
    }
    
    /// 设置返回按钮样式
    @objc(wy_setReturnButtonWithImage:color:title:)
    func wy_setReturnButtonObjC(image: UIImage? = nil, color: UIColor? = nil, title: String? = nil) {
        wy_setReturnButton(image: image, color: color, title: title)
    }
    
    /// 设置阴影线
    @objc(wy_setNavBarShadowLineLidden:color:)
    func wy_setNavBarShadowLineObjC(hidden: Bool, color: UIColor? = nil) {
        wy_setNavBarShadowLine(hidden: hidden, color: color)
    }
}
