//
//  UINavigationController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// 导航栏配置项
public struct WYNavigationBarAppearance {
    
    /// 背景色 (优先级: 背景图 > 背景色)
    public var backgroundColor: UIColor? = .white
    
    /// 背景图 (优先级: 背景图 > 背景色)
    public var backgroundImage: UIImage?
    
    /// 标题字体
    public var titleFont: UIFont = .systemFont(ofSize: 16)
    
    /// 标题颜色
    public var titleColor: UIColor = .black
    
    /// 返回按钮图片
    public var returnButtonImage: UIImage?
    
    /// 返回按钮颜色
    public var returnButtonColor: UIColor = .systemBlue
    
    /// 返回按钮文本
    public var returnButtonTitle: String = ""
    
    /// 是否隐藏底部阴影线
    public var shadowLineHidden: Bool = false
    
    /// 阴影线颜色 (当 shadowHidden = false 时生效)
    public var shadowLineColor: UIColor? = UIColor(white: 0.9, alpha: 1.0)
    
    public init() {}
}

/// 用于全局导航栏配置的类
public class WYNavigationBarConfig {
    
    /// 全局(默认)导航栏样式
    public static var defaultAppearance = WYNavigationBarAppearance()
    
    /// 全局设置导航栏样式
    public static func setGlobalAppearance(_ appearance: WYNavigationBarAppearance) {
        defaultAppearance = appearance
    }
    
    /// 全局隐藏底部阴影线
    public static var globalShadowLineHidden: Bool {
        get { defaultAppearance.shadowLineHidden }
        set { defaultAppearance.shadowLineHidden = newValue }
    }
}

/// 控制器级别设置
public extension UIViewController {
    
    /// 当前控制器导航栏样式
    var wy_navBarAppearance: WYNavigationBarAppearance {
        get {
            // 如果当前控制器有自定义样式，则返回自定义样式
            if let custom = objc_getAssociatedObject(self, &WYAssociatedKeys.customAppearanceKey) as? WYNavigationBarAppearance {
                return custom
            }
            
            // 否则返回全局默认配置
            return WYNavigationBarConfig.defaultAppearance
        }
        set {
            // 存储自定义样式
            objc_setAssociatedObject(self, &WYAssociatedKeys.customAppearanceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            // 立即更新导航栏
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
        var appearance = wy_navBarAppearance
        appearance.backgroundColor = color
        wy_navBarAppearance = appearance
    }
    
    /// 设置导航栏背景图
    func wy_setNavBarBackgroundImage(_ image: UIImage?) {
        var appearance = wy_navBarAppearance
        appearance.backgroundImage = image
        wy_navBarAppearance = appearance
    }
    
    /// 设置导航栏标题样式
    func wy_setNavBarTitle(font: UIFont, color: UIColor) {
        var appearance = wy_navBarAppearance
        appearance.titleFont = font
        appearance.titleColor = color
        wy_navBarAppearance = appearance
    }
    
    /// 设置返回按钮样式
    func wy_setReturnButton(image: UIImage? = nil, color: UIColor? = nil, title: String? = nil) {
        var appearance = wy_navBarAppearance
        if let image = image { appearance.returnButtonImage = image }
        if let color = color { appearance.returnButtonColor = color }
        if let title = title { appearance.returnButtonTitle = title }
        wy_navBarAppearance = appearance
    }
    
    /// 设置阴影线
    func wy_setNavBarShadowLine(hidden: Bool, color: UIColor? = nil) {
        var appearance = wy_navBarAppearance
        appearance.shadowLineHidden = hidden
        if let color = color { appearance.shadowLineColor = color }
        wy_navBarAppearance = appearance
    }
    
    /// 关联对象键
    private struct WYAssociatedKeys {
        static var customAppearanceKey: UInt8 = 0
    }
}

/// 导航栏按钮创建
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

/// 导航控制器实现( 内部)
public extension UINavigationController {
    
    /// 更新指定控制器的导航栏样式
    fileprivate func updateNavigationBarAppearance(for viewController: UIViewController) {
        let appearance = viewController.wy_navBarAppearance
        
        // 创建外观配置
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        // 设置背景
        if let backgroundImage = appearance.backgroundImage {
            navBarAppearance.backgroundImage = backgroundImage
        } else if let backgroundColor = appearance.backgroundColor {
            navBarAppearance.backgroundColor = backgroundColor
        }
        
        // 设置标题
        navBarAppearance.titleTextAttributes = [
            .font: appearance.titleFont,
            .foregroundColor: appearance.titleColor
        ]
        
        // 设置阴影
        if appearance.shadowLineHidden {
            navBarAppearance.shadowColor = .clear
            navBarAppearance.shadowImage = UIImage()
        } else {
            navBarAppearance.shadowColor = appearance.shadowLineColor
            navBarAppearance.shadowImage = nil
        }
        
        // 设置返回按钮
        let backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: appearance.returnButtonColor
        ]
        navBarAppearance.backButtonAppearance = backButtonAppearance
        
        // 应用配置
        navigationBar.standardAppearance = navBarAppearance
        navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationBar.compactAppearance = navBarAppearance
        
        // 单独设置返回按钮
        navigationBar.tintColor = appearance.returnButtonColor
        if let backImage = appearance.returnButtonImage {
            navigationBar.backIndicatorImage = backImage
            navigationBar.backIndicatorTransitionMaskImage = backImage
        }
        
        // 设置返回按钮文本
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: appearance.returnButtonTitle,
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

/// 返回按钮拦截处理(内部)
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

/// 导航控制器代理(内部)
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
