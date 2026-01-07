//
//  UIViewControllerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/27.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// ViewController显示模式
@objc(WYDisplaMode)
@frozen public enum WYDisplaModeObjC: Int {
    
    /// push模式
    case push = 0
    
    /// present模式
    case present
}

@objc public extension UIViewController {
    
    /// 全局设置UIViewController present 跳转模式为全屏
    @objc(wy_globalPresentationFullScreen)
    static func wy_globalPresentationFullScreenObjC() {
        wy_globalPresentationFullScreen()
    }

    /// 获取当前正在显示的控制器
    @objc(wy_currentController)
    static func wy_currentController() -> UIViewController? {
        return wy_currentControllerObjC(windowController: nil)
    }
    
    @objc(wy_currentControllerFromWindowController:)
    static func wy_currentControllerObjC(windowController: UIViewController? = (UIApplication.shared.delegate?.window)??.rootViewController) -> UIViewController? {
        
        var topController: UIViewController? = windowController
        if windowController == nil {
            topController = (UIApplication.shared.delegate?.window)??.rootViewController
        }
        return wy_currentController(windowController: topController)
    }
    
    /// 从导航控制器栈中查找ViewController，没有时返回nil
    @objc(wy_findViewControllerWithClassName:)
    func wy_findViewControllerObjC(className: String) -> UIViewController? {
        return wy_findViewController(className: className)
    }
    
    /// 删除指定的视图控制器
    @objc(wy_deleteViewControllerWithClassName:complete:)
    func wy_deleteViewControllerObjC(className: String, complete:(() -> Void)? = nil) {
        wy_deleteViewController(className: className, complete: complete)
    }
    
    /// 跳转到指定的视图控制器
    @discardableResult
    @objc(wy_showViewControllerWithClassName:parameters:displaMode:animated:)
    func wy_showViewControllerObjC(className: String, parameters: AnyObject? = nil, displaMode: WYDisplaModeObjC = .push, animated: Bool = true) -> UIViewController? {
        wy_showViewController(className: className, parameters: parameters, displaMode: WYDisplaMode(rawValue: displaMode.rawValue) ?? .push, animated: animated)
    }
    
    /// 跳转到指定的视图控制器，此方法可防止循环跳转
    @discardableResult
    @objc(wy_showOnlyViewControllerWithClassName:parameters:displaMode:animated:)
    func wy_showOnlyViewControllerObjC(className: String, parameters: AnyObject? = nil, displaMode: WYDisplaModeObjC = .push, animated: Bool = true) -> UIViewController? {
        wy_showOnlyViewController(className: className, parameters: parameters, displaMode: WYDisplaMode(rawValue: displaMode.rawValue) ?? .push, animated: animated)
    }
    
    /// 返回到指定的视图控制器
    @objc(wy_backToViewControllerWithClassName:animated:)
    func wy_backToViewControllerObjC(className: String, animated: Bool = true) {
        wy_backToViewController(className: className, animated: animated)
    }
    
    /// 跳转到指定的视图控制器(通用)
    @objc(wy_showViewController:parameters:displaMode:animated:)
    func wy_showViewControllerObjC(controller: UIViewController, parameters: AnyObject? = nil, displaMode: WYDisplaModeObjC = .push, animated: Bool = true) {
        wy_showViewController(controller: controller, parameters: parameters, displaMode: WYDisplaMode(rawValue: displaMode.rawValue) ?? .push, animated: animated)
    }
    
    /// 根据字符串获得对应控制器
    @objc(wy_controllerFromClassName:)
    func wy_controllerObjC(from className: String) -> UIViewController? {
        return wy_controller(from: className)
    }
    
    /// 获取viewController跳转模式
    @objc(wy_viewControllerDisplaMode)
    func wy_viewControllerDisplaModeObjC() -> WYDisplaModeObjC {
        return WYDisplaModeObjC(rawValue: wy_viewControllerDisplaMode().rawValue) ?? .push
    }
    
    /// 控制器附加参数
    @objc(wy_parameters)
    var wy_parametersObjC: AnyObject? {
        set(newValue) { wy_parameters = newValue }
        get { return wy_parameters }
    }
}
