//
//  UINavigationController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

public extension UINavigationController {
    
    /// 导航栏背景色
    var wy_backgroundColor: UIColor {
        set(newValue) {
            if newValue == UIColor.clear {
                wy_backgroundImage = UIImage()
                wy_hiddenBottomLine()
                
            }else {
                self.navigationBar.barTintColor = newValue
            }
            if #available(iOS 15.0, *) {
                let appearnce = UINavigationBarAppearance()
                appearnce.configureWithOpaqueBackground()
                appearnce.backgroundColor = wy_backgroundColor
                appearnce.titleTextAttributes = [NSAttributedString.Key.font: wy_titleFont, NSAttributedString.Key.foregroundColor: wy_titleColor]
                UINavigationBar.appearance().standardAppearance = appearnce
                UINavigationBar.appearance().scrollEdgeAppearance = appearnce
            }
        }
        get {
            return self.navigationBar.barTintColor ?? .white
        }
    }
    
    /// 导航栏背景图
    var wy_backgroundImage: UIImage {
        
        set(newValue) {
            self.navigationBar.setBackgroundImage(newValue, for: .default)
        }
        get {
            return self.navigationBar.backgroundImage(for: .default) ?? UIImage.wy_createImage(from: .white)
        }
    }
    
    /// 导航栏标题字体
    var wy_titleFont: UIFont {
        
        set(newValue) {
            
            guard self.navigationBar.titleTextAttributes != nil else {
                
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: newValue, NSAttributedString.Key.foregroundColor: wy_titleColor]
                
                return
            }
            
            var titleTextAttributes = self.navigationBar.titleTextAttributes
            
            titleTextAttributes![NSAttributedString.Key.font] = newValue
            
            self.navigationBar.titleTextAttributes = titleTextAttributes
            
            if #available(iOS 15.0, *) {
                let appearnce = UINavigationBarAppearance()
                appearnce.configureWithOpaqueBackground()
                appearnce.backgroundColor = wy_backgroundColor
                appearnce.titleTextAttributes = [NSAttributedString.Key.font: wy_titleFont, NSAttributedString.Key.foregroundColor: wy_titleColor]
                UINavigationBar.appearance().standardAppearance = appearnce
                UINavigationBar.appearance().scrollEdgeAppearance = appearnce
            }
        }
        get {
            
            let titleTextAttributes = self.navigationBar.titleTextAttributes
            if titleTextAttributes?.keys.contains(NSAttributedString.Key.font) == true {
                
                return titleTextAttributes![NSAttributedString.Key.font] as! UIFont
                
            }else {
                
                return .systemFont(ofSize: wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
            }
        }
    }
    
    /// 导航栏标题颜色
    var wy_titleColor: UIColor {
        
        set(newValue) {
            
            guard self.navigationBar.titleTextAttributes != nil else {
                
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: wy_titleFont, NSAttributedString.Key.foregroundColor: newValue]
                
                return
            }
            
            var titleTextAttributes = self.navigationBar.titleTextAttributes
            
            titleTextAttributes![NSAttributedString.Key.foregroundColor] = newValue
            
            self.navigationBar.titleTextAttributes = titleTextAttributes
            
            if #available(iOS 15.0, *) {
                let appearnce = UINavigationBarAppearance()
                appearnce.configureWithOpaqueBackground()
                appearnce.backgroundColor = wy_backgroundColor
                appearnce.titleTextAttributes = [NSAttributedString.Key.font: wy_titleFont, NSAttributedString.Key.foregroundColor: wy_titleColor]
                UINavigationBar.appearance().standardAppearance = appearnce
                UINavigationBar.appearance().scrollEdgeAppearance = appearnce
            }
        }
        get {
            
            let titleTextAttributes = self.navigationBar.titleTextAttributes
            if titleTextAttributes?.keys.contains(NSAttributedString.Key.foregroundColor) == true {
                
                return titleTextAttributes![NSAttributedString.Key.foregroundColor] as! UIColor
                
            }else {
                
                return .black
            }
        }
    }
    
    /// 返回按钮图片
    var wy_returnButtonImage: UIImage {
        set(newValue) {
            if #available(iOS 15.0, *) {
                self.navigationBar.backIndicatorTransitionMaskImage = newValue
            }
            self.navigationBar.backIndicatorImage = newValue
        }
        get {
            return self.navigationBar.backIndicatorImage ?? UIImage.wy_createImage(from: .white)
        }
    }
    
    /// 返回按钮背景颜色
    var wy_returnButtonColor: UIColor {
        
        set(newValue) {
            self.navigationBar.tintColor = newValue
        }
        get {
            return self.navigationBar.tintColor
        }
    }
    
    /// 返回按钮文本(仅在创建UINavigationController时设置全局样式，如在UITabBarController中初始化子控制器时设置)
    var wy_returnButtonTitle: String {

        set {
            topViewController?.navigationItem.backBarButtonItem?.title = newValue
        }

        get {
            return topViewController?.navigationItem.backBarButtonItem?.title ?? ""
        }
    }
    
    /// 获取一个纯文本UIBarButtonItem
    func wy_navTitleItem(title: String, color: UIColor = .black, target: Any? = nil, selector: Selector? = nil) -> UIBarButtonItem {
        
        let titleItem = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)
        titleItem.tintColor = color
        
        return titleItem
    }
    
    /// 获取一个纯图片UIBarButtonItem
    func wy_navImageItem(image: UIImage, color: UIColor = .black, target: Any? = nil, selector: Selector? = nil) -> UIBarButtonItem {
        
        let imageItem = UIBarButtonItem(image: image, style: .plain, target: target, action: selector)
        imageItem.tintColor = color
            
        return imageItem
    }
    
    /// 获取一个自定义UIBarButtonItem
    func wy_navCustomItem(itemView: UIView) -> UIBarButtonItem {
        
        return UIBarButtonItem(customView: itemView)
    }
    
    /// 隐藏导航栏底部黑线
    func wy_hiddenBottomLine() {
        
        self.navigationBar.shadowImage = UIImage()
    }
    
    /// 显示导航栏底部分割线
    func wy_showBottomLine(color: UIColor?) {
        
        self.navigationBar.shadowImage = nil
        
        if let imageView = wy_sharedBottomLine() {
            
            var frame: CGRect = imageView.frame
            frame.size.height = 1
            imageView.frame = frame
            
            let lineView = imageView.viewWithTag(100) ?? UIView(frame: imageView.bounds)
            lineView.backgroundColor = color
            lineView.tag = 100
            imageView.addSubview(lineView)
        }
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
    
    private struct NavigationControllerRuntimeKey {
        
        static let barReturnButtonDelegate = UnsafeRawPointer(bitPattern: "barReturnButtonDelegate".hashValue)!
    }
}

extension UINavigationController: UINavigationBarDelegate, UIGestureRecognizerDelegate {
    
    public func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem) {
        
        objc_setAssociatedObject(self, NavigationControllerRuntimeKey.barReturnButtonDelegate, self.interactivePopGestureRecognizer?.delegate, .OBJC_ASSOCIATION_ASSIGN)
        self.interactivePopGestureRecognizer?.delegate = self
        
        /// 全局设置返回按钮文本
        topViewController?.navigationItem.backBarButtonItem = UIBarButtonItem(title: wy_returnButtonTitle, style: .plain, target: nil, action: nil)
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

        if shouldPop == true {

            DispatchQueue.main.async {

                self.popViewController(animated: true)
            }

        }else {

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
        
        if (gestureRecognizer == self.interactivePopGestureRecognizer) {
            
            let vc: UIViewController = topViewController!
            
            if vc.responds(to: #selector(wy_navigationBarWillReturn)) {
                
                return vc.wy_navigationBarWillReturn()
            }
            
            let originDelegate: UIGestureRecognizerDelegate = objc_getAssociatedObject(self, NavigationControllerRuntimeKey.barReturnButtonDelegate)! as! UIGestureRecognizerDelegate
            
            return originDelegate.gestureRecognizerShouldBegin!(gestureRecognizer)
        }
        
        return true
    }
}
