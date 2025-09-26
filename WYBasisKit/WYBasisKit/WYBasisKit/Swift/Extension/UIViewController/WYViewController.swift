//
//  UIViewController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// ViewController显示模式
@frozen public enum WYDisplaMode: Int {
    
    /// push模式
    case push = 0
    
    /// present模式
    case present
}

/// 拦截返回按钮的点击和侧滑返回事件
@objc public protocol ViewControllerHandlerProtocol {
    @objc optional func wy_navigationBarWillReturn() -> Bool
}

extension UIViewController: ViewControllerHandlerProtocol {
    open func wy_navigationBarWillReturn() -> Bool {
        return true
    }
}

public extension UIViewController {
    
    /// 全局设置UIViewController present 跳转模式为全屏
    static func wy_globalPresentationFullScreen() {
        let originalSelector = #selector(UIViewController.present(_:animated:completion:))
        let swizzledSelector = #selector(UIViewController.wy_present(_:animated:completion:))
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        // 在进行 Swizzling 的时候,需要用 class_addMethod 先进行判断一下原有类中是否有要替换方法的实现
        let didAddMethod: Bool = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        // 如果 class_addMethod 返回 yes,说明当前类中没有要替换方法的实现,所以需要在父类中查找,这时候就用到 method_getImplemetation 去获取 class_getInstanceMethod 里面的方法实现,然后再进行 class_replaceMethod 来实现 Method Swizzing
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    @objc private func wy_present(_ vc:UIViewController, animated: Bool, completion:(()->())?) {
        vc.modalPresentationStyle = .fullScreen
        wy_present(vc, animated: animated, completion: completion)
    }
    
    
    /// 获取当前正在显示的控制器
    static func wy_currentController(windowController: UIViewController? = (UIApplication.shared.delegate?.window)??.rootViewController) -> UIViewController? {
        
        if let navigationController = windowController as? UINavigationController {
            return wy_currentController(windowController: navigationController.visibleViewController)
            
        }else if let tabBarController = windowController as? UITabBarController {
            return wy_currentController(windowController: tabBarController.selectedViewController)
            
        }else if let presentedController = windowController?.presentedViewController {
            return wy_currentController(windowController: presentedController)
            
        }else {
            return windowController
        }
    }
    
    /// 从导航控制器栈中查找ViewController，没有时返回nil
    func wy_findViewController(className: String) -> UIViewController? {
        
        guard let controller = wy_controller(from: className) else { return nil }
        
        guard self.navigationController?.viewControllers.isEmpty == true else { return nil }
        
        return self.navigationController?.viewControllers.first(where: { $0 == controller })
    }
    
    /// 删除指定的视图控制器
    func wy_deleteViewController(className: String, complete:(() -> Void)? = nil) {
        
        guard let controller = wy_controller(from: className) else { return }
        
        guard self.navigationController?.viewControllers.isEmpty == true else { return }
        
        var controllers: [UIViewController] = self.navigationController!.viewControllers
        
        controllers.removeAll(where: { $0 == controller })
        
        self.navigationController?.viewControllers = controllers
        
        if complete != nil {
            complete!()
        }
    }
    
    /// 跳转到指定的视图控制器
    @discardableResult
    func wy_showViewController(className: String, parameters: AnyObject? = nil, displaMode: WYDisplaMode = .push, animated: Bool = true) -> UIViewController? {

        guard let controller = wy_controller(from: className)  else { return nil}
        
        wy_showViewController(controller: controller, parameters: parameters, displaMode: displaMode, animated: animated)
        
        return controller
    }
    
    /// 跳转到指定的视图控制器，此方法可防止循环跳转
    @discardableResult
    func wy_showOnlyViewController(className: String, parameters: AnyObject? = nil, displaMode: WYDisplaMode = .push, animated: Bool = true) -> UIViewController? {
        
        wy_deleteViewController(className: className)
        
        return wy_showViewController(className: className, parameters: parameters, displaMode: displaMode, animated: animated)
    }
    
    /// 返回到指定的视图控制器
    func wy_backToViewController(className: String, animated: Bool = true) {
        
        let controller = WYProjectInfo.projectName + "." + className
        guard let controllerClass = NSClassFromString(controller) as? UIViewController.Type else {
            
            return
        }
        
        if wy_viewControllerDisplaMode() == .push {
            
            guard self.navigationController?.viewControllers.isEmpty == true else { return }
            
            let showController: UIViewController? = self.navigationController!.viewControllers.first(where: { $0.isKind(of: controllerClass.self) })
            
            guard showController != nil else { return }
            
            self.navigationController?.popToViewController(showController!, animated: animated)
            
        }else {
            
            var presentingController = self.presentingViewController
            
            guard presentingController != nil else { return }
            
            while !(presentingController!.isKind(of: controllerClass.self)) {
                
                presentingController = presentingController?.presentingViewController
            }
            presentingController?.dismiss(animated: animated)
        }
    }
    
    /// 跳转到指定的视图控制器(通用)
    func wy_showViewController(controller: UIViewController, parameters: AnyObject? = nil, displaMode: WYDisplaMode = .push, animated: Bool = true) {
        
        controller.hidesBottomBarWhenPushed = true
        controller.wy_parameters = parameters
        switch displaMode {
        case .push:
            self.navigationController?.pushViewController(controller, animated: animated)
        case .present:
            self.present(controller, animated: animated)
        }
    }
    
    /// 根据字符串获得对应控制器
    func wy_controller(from className: String) -> UIViewController? {
        
        let controller = WYProjectInfo.projectName + "." + className
        
        guard let controllerClass = NSClassFromString(controller) as? UIViewController.Type else {

            WYLogManager.output("找不到 \(className) 这个控制器")
            return nil
        }
        return controllerClass.init()
    }
    
    /// 获取viewController跳转模式
    func wy_viewControllerDisplaMode() -> WYDisplaMode {
        
        let viewcontrollers = self.navigationController?.viewControllers
        var displaMode: WYDisplaMode = .push
        
        if viewcontrollers?.isEmpty == false {
            
            displaMode = (viewcontrollers?.last == self) ? .push : .present
            
        }else {
            
            displaMode = .present
        }
        
        return displaMode;
    }
    
    /// 控制器附加参数
    var wy_parameters: AnyObject? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_parameters, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_parameters) as AnyObject
        }
    }
    
    private struct WYAssociatedKeys {
        static var wy_parameters: UInt8 = 0
    }
}


