//
//  WYPopViewControllerSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `UINavigationController` 及其子类的 `popViewController(animated:)` 方法。
 
 - Parameters:
   - targetClass: 目标导航控制器类（如 `UINavigationController.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(controller)` 则直接返回该控制器（可为 `nil`），**不再调用原始方法**。参数依次为：当前导航控制器、是否动画。
   - before: 方法执行前回调。参数依次为：当前导航控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前导航控制器、是否动画、被弹出的视图控制器（可能为 `nil`）。无返回值（仅通知）。
 */
internal func wy_swizzlerPopViewController(
    for targetClass: UINavigationController.Type,
    intercept: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> WYInterceptResult<UIViewController?>)? = nil,
    before: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentNavigationController: UINavigationController, _ animated: Bool, _ poppedViewController: UIViewController?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UINavigationController.popViewController(animated:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UINavigationController, Selector, Bool) -> UIViewController?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 Bool，返回值为 UIViewController?
    typealias Args = Bool
    typealias Return = UIViewController?
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: NSStringFromSelector(selector))
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_popViewController_<类名>_<方法名>
    let interceptKey = wy_methodSwizzlerKey(for: .popIntercept, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 存储 intercept 闭包
    WYInterceptPopMap[interceptKey] = intercept
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyNav, _, animated in
            guard let nav = anyNav as? UINavigationController else { return }
            before(nav, animated)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyNav, _, animated, poppedVC in
            guard let nav = anyNav as? UINavigationController else { return poppedVC }
            after(nav, animated, poppedVC)
            return poppedVC  // after 闭包不修改返回值，直接返回原始值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UINavigationController, Bool) -> UIViewController? = { receiver, animated in
        // 沿继承链向上查找 intercept 闭包
        var currentClass: AnyClass? = type(of: receiver)
        var foundIntercept: ((UINavigationController, Bool) -> WYInterceptResult<UIViewController?>)? = nil
        while let cls = currentClass, cls != NSObject.self {
            let className = NSStringFromClass(cls)
            let key = wy_methodSwizzlerKey(for: .popIntercept, className: className, selectorName: NSStringFromSelector(selector))
            WYHooksLock.lock()
            let intercept = WYInterceptPopMap[key]
            WYHooksLock.unlock()
            if intercept != nil {
                foundIntercept = intercept
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        // 执行拦截决策
        if let intercept = foundIntercept {
            switch intercept(receiver, animated) {
            case .result(let value):
                return value
            case .proceed:
                break
            }
        }
        
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        // 调用原始方法（真正的 popViewController 实现）
        let originalResult = originalBlock(receiver, selector, animated)
        
        // 依次执行所有 after 闭包，并允许它们修改返回值
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, animated, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}

/// 独立存储 popViewController 的拦截闭包
internal var WYInterceptPopMap: [String: (UINavigationController, Bool) -> WYInterceptResult<UIViewController?>] = [:]
