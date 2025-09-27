//
//  UINavigationController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

public extension UINavigationController {
    
    /// 获取一个纯文本UIBarButtonItem
    func wy_navTitleItem(title: String,
                         color: UIColor = .black,
                         target: Any? = nil,
                         selector: Selector? = nil) -> UIBarButtonItem {
        let titleItem = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)
        titleItem.tintColor = color
        return titleItem
    }
    
    /// 获取一个纯图片UIBarButtonItem
    func wy_navImageItem(image: UIImage,
                         color: UIColor = .black,
                         target: Any? = nil,
                         selector: Selector? = nil) -> UIBarButtonItem {
        let imageItem = UIBarButtonItem(image: image, style: .plain, target: target, action: selector)
        imageItem.tintColor = color
        return imageItem
    }
    
    /// 获取一个自定义UIBarButtonItem
    func wy_navCustomItem(itemView: UIView) -> UIBarButtonItem {
        return UIBarButtonItem(customView: itemView)
    }
}

public extension UINavigationController {
    
    // MARK: - 导航栏(全局)配置属性
    
    /// 导航栏背景色 (优先级: 背景图 > 背景色)
    static var wy_navBarBackgroundColor: UIColor? = .white
    
    /// 导航栏背景图 (优先级: 背景图 > 背景色)
    static var wy_navBarBackgroundImage: UIImage?
    
    /// 导航栏标题字体
    static var wy_navBarTitleFont: UIFont = .systemFont(ofSize: 16)
    
    /// 导航栏标题颜色
    static var wy_navBarTitleColor: UIColor = .black
    
    /// 导航栏返回按钮图片
    static var wy_navBarReturnButtonImage: UIImage?
    
    /// 导航栏返回按钮颜色
    static var wy_navBarReturnButtonColor: UIColor = .systemBlue
    
    /// 导航栏返回按钮文本
    static var wy_navBarReturnButtonTitle: String = ""
    
    /// 导航栏是否隐藏底部阴影线
    static var wy_navBarShadowLineHidden: Bool = false
    
    /// 导航栏阴影线颜色 (当 shadowHidden = false 时生效)
    static var wy_navBarShadowLineColor: UIColor? = UIColor(white: 0.9, alpha: 1.0)
    
    // MARK: - 便捷(全局)配置方法
    
    /// 设置全局导航栏样式
    static func wy_setGlobalNavigationBar(
        backgroundColor: UIColor? = nil,
        backgroundImage: UIImage? = nil,
        titleFont: UIFont? = nil,
        titleColor: UIColor? = nil,
        returnButtonImage: UIImage? = nil,
        returnButtonColor: UIColor? = nil,
        returnButtonTitle: String? = nil,
        shadowLineHidden: Bool? = nil,
        shadowLineColor: UIColor? = nil
    ) {
        if let backgroundColor = backgroundColor { wy_navBarBackgroundColor = backgroundColor }
        if let backgroundImage = backgroundImage { wy_navBarBackgroundImage = backgroundImage }
        if let titleFont = titleFont { wy_navBarTitleFont = titleFont }
        if let titleColor = titleColor { wy_navBarTitleColor = titleColor }
        if let returnButtonImage = returnButtonImage { wy_navBarReturnButtonImage = returnButtonImage }
        if let returnButtonColor = returnButtonColor { wy_navBarReturnButtonColor = returnButtonColor }
        if let returnButtonTitle = returnButtonTitle { wy_navBarReturnButtonTitle = returnButtonTitle }
        if let shadowLineHidden = shadowLineHidden { wy_navBarShadowLineHidden = shadowLineHidden }
        if let shadowLineColor = shadowLineColor { wy_navBarShadowLineColor = shadowLineColor }
    }
}

public extension UIViewController {
    
    // MARK: - 控制器级别属性（有自定义值使用自定义值，否则使用全局值）
    
    /// 导航栏背景色
    var wy_navBarBackgroundColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customBackgroundColorKey) as? UIColor ?? UINavigationController.wy_navBarBackgroundColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customBackgroundColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏背景图
    var wy_navBarBackgroundImage: UIImage? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customBackgroundImageKey) as? UIImage ?? UINavigationController.wy_navBarBackgroundImage
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customBackgroundImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏标题字体
    var wy_navBarTitleFont: UIFont {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customTitleFontKey) as? UIFont ?? UINavigationController.wy_navBarTitleFont
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customTitleFontKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏标题颜色
    var wy_navBarTitleColor: UIColor {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customTitleColorKey) as? UIColor ?? UINavigationController.wy_navBarTitleColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customTitleColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏返回按钮图片
    var wy_navBarReturnButtonImage: UIImage? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customReturnButtonImageKey) as? UIImage ?? UINavigationController.wy_navBarReturnButtonImage
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customReturnButtonImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏返回按钮颜色
    var wy_navBarReturnButtonColor: UIColor {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customReturnButtonColorKey) as? UIColor ?? UINavigationController.wy_navBarReturnButtonColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customReturnButtonColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏返回按钮文本
    var wy_navBarReturnButtonTitle: String {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customReturnButtonTitleKey) as? String ?? UINavigationController.wy_navBarReturnButtonTitle
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customReturnButtonTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏是否隐藏底部阴影线
    var wy_navBarShadowLineHidden: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customShadowLineHiddenKey) as? Bool ?? UINavigationController.wy_navBarShadowLineHidden
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customShadowLineHiddenKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            updateNavigationBarAppearance()
        }
    }
    
    /// 导航栏阴影线颜色
    var wy_navBarShadowLineColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.customShadowLineColorKey) as? UIColor ?? UINavigationController.wy_navBarShadowLineColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.customShadowLineColorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateNavigationBarAppearance()
        }
    }
    
    /// 更新导航栏样式
    func updateNavigationBarAppearance() {
        navigationController?.updateNavigationBarAppearance(for: self)
    }
    
    // MARK: - 便捷设置方法
    
    /// 设置导航栏背景色
    func wy_setNavBarBackgroundColor(_ color: UIColor?) {
        wy_navBarBackgroundColor = color
    }
    
    /// 设置导航栏背景图
    func wy_setNavBarBackgroundImage(_ image: UIImage?) {
        wy_navBarBackgroundImage = image
    }
    
    /// 设置导航栏标题样式
    func wy_setNavBarTitle(font: UIFont, color: UIColor) {
        wy_navBarTitleFont = font
        wy_navBarTitleColor = color
    }
    
    /// 设置返回按钮样式
    func wy_setReturnButton(image: UIImage? = nil, color: UIColor? = nil, title: String? = nil) {
        if let image = image { wy_navBarReturnButtonImage = image }
        if let color = color { wy_navBarReturnButtonColor = color }
        if let title = title { wy_navBarReturnButtonTitle = title }
    }
    
    /// 设置阴影线
    func wy_setNavBarShadowLine(hidden: Bool, color: UIColor? = nil) {
        wy_navBarShadowLineHidden = hidden
        if let color = color { wy_navBarShadowLineColor = color }
    }
    
    private struct WYAssociatedKeys {
        static var customBackgroundColorKey: UInt8 = 0
        static var customBackgroundImageKey: UInt8 = 0
        static var customTitleFontKey: UInt8 = 0
        static var customTitleColorKey: UInt8 = 0
        static var customReturnButtonImageKey: UInt8 = 0
        static var customReturnButtonColorKey: UInt8 = 0
        static var customReturnButtonTitleKey: UInt8 = 0
        static var customShadowLineHiddenKey: UInt8 = 0
        static var customShadowLineColorKey: UInt8 = 0
    }
}

// MARK: - 返回按钮拦截处理(内部)

extension UINavigationController: @retroactive UIBarPositioningDelegate {}
extension UINavigationController: @retroactive UINavigationBarDelegate, @retroactive UIGestureRecognizerDelegate {
    
    public func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem) {
        // 保存原始的交互式pop手势代理
        objc_setAssociatedObject(self, &WYAssociatedKeys.barReturnButtonDelegate,
                                 self.interactivePopGestureRecognizer?.delegate,
                                 .OBJC_ASSOCIATION_ASSIGN)
        self.interactivePopGestureRecognizer?.delegate = self
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        if self.viewControllers.count < (navigationBar.items?.count)! {
            return true
        }
        
        var shouldPop = true
        let vc: UIViewController = topViewController!
        
        if vc.responds(to: #selector(wy_navigationBarWillReturn)) {
            shouldPop = vc.wy_navigationBarWillReturn()
        }
        
        if shouldPop {
            DispatchQueue.main.async {
                self.popViewController(animated: true)
            }
        } else {
            // 取消 pop 后，复原返回按钮的状态
            for subview in navigationBar.subviews {
                if 0.0 < subview.alpha && subview.alpha < 1.0 {
                    UIView.animate(withDuration: 0.25) {
                        subview.alpha = 1.0
                    }
                }
            }
        }
        return false
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.interactivePopGestureRecognizer {
            let vc: UIViewController = topViewController!
            
            if vc.responds(to: #selector(wy_navigationBarWillReturn)) {
                return vc.wy_navigationBarWillReturn()
            }
            
            if let originDelegate = objc_getAssociatedObject(self, &WYAssociatedKeys.barReturnButtonDelegate) as? UIGestureRecognizerDelegate {
                return originDelegate.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
            }
        }
        
        return true
    }
    
    private struct WYAssociatedKeys {
        static var barReturnButtonDelegate: UInt8 = 0
    }
}

// MARK: - 导航控制器代理(内部)

extension UINavigationController: @retroactive UINavigationControllerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    public func navigationController(_ navigationController: UINavigationController,
                                    willShow viewController: UIViewController,
                                    animated: Bool) {
        updateNavigationBarAppearance(for: viewController)
    }
}

// MARK: - 导航控制器实现(内部)

public extension UINavigationController {
    
    /// 更新指定控制器的导航栏样式
    fileprivate func updateNavigationBarAppearance(for viewController: UIViewController) {
        
        // 创建外观配置
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        // 设置背景
        if let backgroundImage = viewController.wy_navBarBackgroundImage {
            navBarAppearance.backgroundImage = backgroundImage
        } else if let backgroundColor = viewController.wy_navBarBackgroundColor {
            navBarAppearance.backgroundColor = backgroundColor
        }
        
        // 设置标题
        navBarAppearance.titleTextAttributes = [
            .font: viewController.wy_navBarTitleFont,
            .foregroundColor: viewController.wy_navBarTitleColor
        ]
        
        // 设置阴影
        if viewController.wy_navBarShadowLineHidden {
            navBarAppearance.shadowColor = .clear
            navBarAppearance.shadowImage = UIImage()
        } else {
            navBarAppearance.shadowColor = viewController.wy_navBarShadowLineColor
            navBarAppearance.shadowImage = nil
        }
        
        // 设置返回按钮
        let backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: viewController.wy_navBarReturnButtonColor
        ]
        navBarAppearance.backButtonAppearance = backButtonAppearance
        
        // 应用配置
        navigationBar.standardAppearance = navBarAppearance
        navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationBar.compactAppearance = navBarAppearance
        
        // 单独设置返回按钮
        navigationBar.tintColor = viewController.wy_navBarReturnButtonColor
        if let backImage = viewController.wy_navBarReturnButtonImage {
            navigationBar.backIndicatorImage = backImage
            navigationBar.backIndicatorTransitionMaskImage = backImage
        }
        
        // 设置返回按钮文本
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: viewController.wy_navBarReturnButtonTitle,
            style: .plain,
            target: nil,
            action: nil
        )
    }
    
    /// 获取导航栏底部分隔线View
    func wy_sharedBottomLine(findView: UIView? = wy_currentController()?.navigationController?.navigationBar) -> UIImageView? {
        if let view = findView {
            if view.isKind(of: UIImageView.self) && view.bounds.size.height <= 1.0 {
                return view as? UIImageView
            }
            
            for subView in view.subviews {
                let imageView = wy_sharedBottomLine(findView: subView)
                if imageView != nil {
                    return imageView
                }
            }
        }
        return nil
    }
}
