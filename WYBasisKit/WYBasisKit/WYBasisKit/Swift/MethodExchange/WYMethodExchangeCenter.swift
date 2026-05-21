//
//  WYMethodExchangeCenter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/19.
//

import UIKit

/// 拦截决策
public enum WYInterceptDecision {
    /// 继续执行原始交换方法
    case proceed
    /// 直接返回指定的值（可以是 nil），不再调用原始方法
    case result(UIView?)
}

/**
 移除指定类的指定方法的钩子（包括 before、after 和 intercept）。
 
 - Parameters:
 - anyClass: 目标类。
 - selector: 方法选择器。若传入 `nil`，则移除该类的所有钩子（所有方法）；若指定 `selector`，则只移除该方法的钩子。
 */
public func wy_removeHooks(for anyClass: AnyClass, selector: Selector? = nil) {
    let className = NSStringFromClass(anyClass)
    let prefix = "wy_\(className)_"
    let shouldPopPrefix = "wy_shouldPop_\(className)_"
    WYHooksLock.lock()
    if let selector = selector {
        let selName = NSStringFromSelector(selector)
        let key = prefix + selName
        WYHooksMap[key] = nil
        
        let interceptKey = "wy_intercept_\(className)_\(selName)"
        WYHitTestInterceptMap[interceptKey] = nil
        
        let shouldPopKey = shouldPopPrefix + selName
        WYShouldPopMap[shouldPopKey] = nil
        
        // 清除缓存
        let cacheKey = "\(className)_\(selName)"
        WYHooksCacheMap[cacheKey] = nil
        WYHitTestCacheMap[cacheKey] = nil
    } else {
        let keysToRemove = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            WYHooksMap[key] = nil
        }
        let interceptKeysToRemove = WYHitTestInterceptMap.keys.filter { $0.hasPrefix("wy_intercept_\(className)_") }
        for key in interceptKeysToRemove {
            WYHitTestInterceptMap[key] = nil
        }
        let shouldPopKeysToRemove = WYShouldPopMap.keys.filter { $0.hasPrefix(shouldPopPrefix) }
        for key in shouldPopKeysToRemove {
            WYShouldPopMap[key] = nil
        }
        // 清除该类所有方法缓存
        let cacheKeysToRemove = WYHooksCacheMap.keys.filter { $0.hasPrefix(className + "_") }
        for key in cacheKeysToRemove {
            WYHooksCacheMap[key] = nil
        }
        let hitTestCacheKeysToRemove = WYHitTestCacheMap.keys.filter { $0.hasPrefix(className + "_") }
        for key in hitTestCacheKeysToRemove {
            WYHitTestCacheMap[key] = nil
        }
    }
    WYHooksLock.unlock()
}

/**
 交换 `UINavigationController` 及其子类的 `popViewController(animated:)` 方法。
 
 - Parameters:
 - navigationControllerClass: 目标导航控制器类（如 `UINavigationController.self`）。
 - shouldPop: 拦截决策闭包。返回 `true` 则继续执行原始方法；返回 `false` 则直接返回 `nil`，**不再调用原始方法**。参数依次为：当前导航控制器、是否动画。
 - before: 方法执行前回调。参数依次为：当前导航控制器、是否动画。无返回值。
 - after: 方法执行后回调。参数依次为：当前导航控制器、是否动画、被弹出的视图控制器（可能为 `nil`）。无返回值（仅通知）。
 */
public func wy_exchangePopViewController(
    for navigationControllerClass: UINavigationController.Type,
    shouldPop: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> Bool)? = nil,
    before: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentNavigationController: UINavigationController, _ animated: Bool, _ poppedViewController: UIViewController?) -> Void)? = nil
) {
    let selector = #selector(UINavigationController.popViewController(animated:))
    let className = NSStringFromClass(navigationControllerClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = Bool
    typealias Return = UIViewController?
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(navigationControllerClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UINavigationController, Selector, Bool) -> UIViewController?
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 存储 shouldPop 闭包到独立字典（类似 hitTest 的 intercept）
    let shouldPopKey = "wy_shouldPop_\(className)_\(NSStringFromSelector(selector))"
    WYHooksLock.lock()
    WYShouldPopMap[shouldPopKey] = shouldPop
    WYHooksLock.unlock()
    
    // 存储 before/after
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyNav, _, animated in
            guard let nav = anyNav as? UINavigationController else { return }
            before(nav, animated)
        }
    }
    if let after = after {
        hooks.after.append { anyNav, _, animated, poppedVC in
            guard let nav = anyNav as? UINavigationController else { return poppedVC }
            after(nav, animated, poppedVC)
            return poppedVC  // 不修改返回值
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UINavigationController, Bool) -> UIViewController? = { receiver, animated in
        // 查找 shouldPop 拦截
        var currentClass: AnyClass? = type(of: receiver)
        var foundShouldPop: ((UINavigationController, Bool) -> Bool)? = nil
        while let cls = currentClass, cls != NSObject.self {
            let className = NSStringFromClass(cls)
            let key = "wy_shouldPop_\(className)_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let shouldPop = WYShouldPopMap[key]
            WYHooksLock.unlock()
            if shouldPop != nil {
                foundShouldPop = shouldPop
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        // 执行拦截决策
        if let shouldPop = foundShouldPop, shouldPop(receiver, animated) == false {
            return nil
        }
        
        // 查找 before/after 钩子
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        let originalResult = originalBlock(receiver, selector, animated)
        
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, animated, result)
        }
        return result
    }
    
    wy_swizzleMethod(for: navigationControllerClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewWillAppear(_:)` 方法。
 
 - Parameters:
 - viewControllerClass: 目标视图控制器类（如 `UIViewController.self`）。
 - before: 方法执行前回调。参数依次为：当前控制器、是否动画。无返回值。
 - after: 方法执行后回调。参数依次为：当前控制器、是否动画。无返回值（仅通知）。
 */
public func wy_exchangeViewWillAppear(
    for viewControllerClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil
) {
    let selector = #selector(UIViewController.viewWillAppear(_:))
    let className = NSStringFromClass(viewControllerClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = Bool
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewControllerClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, Bool) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyVC, _, animated in
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, animated)
        }
    }
    if let after = after {
        hooks.after.append { anyVC, _, animated, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, animated)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIViewController, Bool) -> Void = { receiver, animated in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        originalBlock(receiver, selector, animated)
        
        for after in hooks.after {
            _ = after(receiver, selector, animated, ())
        }
    }
    
    wy_swizzleMethod(for: viewControllerClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `present(_:animated:completion:)` 方法。
 
 - Parameters:
 - viewControllerClass: 目标视图控制器类（如 `UIViewController.self`）。
 - before: 方法执行前回调。参数依次为：当前控制器、被 present 的控制器、是否动画、完成闭包。无返回值。
 - after: 方法执行后回调。参数依次为：当前控制器、被 present 的控制器、是否动画、完成闭包。无返回值（仅通知，不可修改返回值）。
 */
public func wy_exchangeControllerPresent(
    for viewControllerClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ presentController: UIViewController, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ presentController: UIViewController, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil
) {
    let selector = #selector(UIViewController.present(_:animated:completion:))
    let className = NSStringFromClass(viewControllerClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (UIViewController, Bool, (() -> Void)?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewControllerClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, UIViewController, Bool, (() -> Void)?) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyVC, _, args in
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, args.0, args.1, args.2)
        }
    }
    if let after = after {
        hooks.after.append { anyVC, _, args, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, args.0, args.1, args.2)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIViewController, UIViewController, Bool, (() -> Void)?) -> Void = { receiver, viewControllerToPresent, animated, completion in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (viewControllerToPresent, animated, completion)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        originalBlock(receiver, selector, viewControllerToPresent, animated, completion)
        
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    wy_swizzleMethod(for: viewControllerClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `NSObject` 及其子类的 `observeValue(forKeyPath:of:change:context:)` 方法。
 
 - Parameters:
 - observerClass: 目标观察者类（如 `NSObject.self`）。
 - before: 方法执行前回调。参数依次为：观察者、键路径、被观察对象、变化字典、上下文指针。无返回值。
 - after: 方法执行后回调。参数依次同上。无返回值（仅通知）。
 */
public func wy_exchangeKVOObserve(
    for observerClass: NSObject.Type,
    before: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil,
    after: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil
) {
    let selector = #selector(NSObject.observeValue(forKeyPath:of:change:context:))
    let className = NSStringFromClass(observerClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(observerClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (NSObject, Selector, String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyObs, _, args in
            guard let obs = anyObs as? NSObject else { return }
            before(obs, args.0, args.1, args.2, args.3)
        }
    }
    if let after = after {
        hooks.after.append { anyObs, _, args, _ in
            guard let obs = anyObs as? NSObject else { return }
            after(obs, args.0, args.1, args.2, args.3)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (NSObject, String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?) -> Void = { receiver, keyPath, object, change, context in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (keyPath, object, change, context)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        originalBlock(receiver, selector, keyPath, object, change, context)
        
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    wy_swizzleMethod(for: observerClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `hitTest(_:with:)` 方法。
 
 - Parameters:
 - viewClass: 目标视图类（如 `UIView.self`）。
 - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(view)` 则直接返回该视图（可为 `nil`），**不再调用原始方法**。参数依次为：当前视图、点击位置、事件。
 - before: 方法执行前观察闭包（仅在原始方法执行前调用，不影响流程）。参数依次为：当前视图、点击位置、事件。无返回值。
 - after: 方法执行后回调，可修改原始返回值。参数依次为：当前视图、点击位置、事件、原始返回值（`UIView?`）。返回一个新的 `UIView?` 作为最终结果。
 */
public func wy_exchangeHitTest(
    for viewClass: UIView.Type,
    intercept: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> WYInterceptDecision)? = nil,
    before: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?, _ originalResult: UIView?) -> UIView?)? = nil
) {
    let selector = #selector(UIView.hitTest(_:with:))
    let className = NSStringFromClass(viewClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (CGPoint, UIEvent?)
    typealias Return = UIView?
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGPoint, UIEvent?) -> UIView?
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyView, _, args in
            guard let view = anyView as? UIView else { return }
            before(view, args.0, args.1)
        }
    }
    if let after = after {
        hooks.after.append { anyView, _, args, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, args.0, args.1, original)
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let interceptKey = "wy_intercept_\(className)_\(NSStringFromSelector(selector))"
    WYHooksLock.lock()
    WYHitTestInterceptMap[interceptKey] = intercept
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIView, CGPoint, UIEvent?) -> UIView? = { receiver, point, event in
        // 1. 查找 intercept 决策（使用缓存）
        if let intercept = wy_findHitTestIntercept(for: receiver, selector: selector) {
            switch intercept(receiver, point, event) {
            case .result(let view):
                return view
            case .proceed:
                break
            }
        }
        
        // 2. 查找 before/after 钩子（使用缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (point, event)
        
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        let originalResult = originalBlock(receiver, selector, point, event)
        
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, args, result)
        }
        return result
    }
    
    wy_swizzleMethod(for: viewClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `layoutSubviews()` 方法。
 
 - Parameters:
 - viewClass: 目标视图类（如 `UIView.self`）。
 - before: 方法执行前回调。参数为当前视图。无返回值。
 - after: 方法执行后回调。参数为当前视图。无返回值（仅通知）。
 */
public func wy_exchangeLayoutSubviews(
    for viewClass: UIView.Type,
    before: ((_ currentView: UIView) -> Void)? = nil,
    after: ((_ currentView: UIView) -> Void)? = nil
) {
    let selector = #selector(UIView.layoutSubviews)
    let className = NSStringFromClass(viewClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = Void
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIView, Selector) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyView, _, _ in
            guard let view = anyView as? UIView else { return }
            before(view)
        }
    }
    if let after = after {
        hooks.after.append { anyView, _, _, _ in
            guard let view = anyView as? UIView else { return }
            after(view)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIView) -> Void = { receiver in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, ())
        }
        
        originalBlock(receiver, selector)
        
        for after in hooks.after {
            _ = after(receiver, selector, (), ())
        }
    }
    
    wy_swizzleMethod(for: viewClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `sizeThatFits(_:)` 方法。
 
 - Parameters:
 - viewClass: 目标视图类（如 `UIView.self`）。
 - before: 方法执行前回调。参数依次为：当前视图、建议的尺寸。无返回值。
 - after: 方法执行后回调。参数依次为：当前视图、建议的尺寸、原始返回值（`CGSize`）。可返回一个新的 `CGSize` 来替换原始返回值。
 */
public func wy_exchangeSizeThatFits(
    for viewClass: UIView.Type,
    before: ((_ currentView: UIView, _ size: CGSize) -> Void)? = nil,
    after: ((_ currentView: UIView, _ size: CGSize, _ originalResult: CGSize) -> CGSize)? = nil
) {
    let selector = #selector(UIView.sizeThatFits(_:))
    let className = NSStringFromClass(viewClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = CGSize
    typealias Return = CGSize
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGSize) -> CGSize
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyView, _, size in
            guard let view = anyView as? UIView else { return }
            before(view, size)
        }
    }
    if let after = after {
        hooks.after.append { anyView, _, size, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, size, original)
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIView, CGSize) -> CGSize = { receiver, size in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, size)
        }
        
        let originalResult = originalBlock(receiver, selector, size)
        
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, size, result)
        }
        return result
    }
    
    wy_swizzleMethod(for: viewClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesBegan(_:with:)` 方法。
 
 - Parameters:
 - responderClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
 - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
 - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesBegan(
    for responderClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesBegan(_:with:))
    let className = NSStringFromClass(responderClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        originalBlock(receiver, selector, touches, event)
        
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    wy_swizzleMethod(for: responderClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesCancelled(_:with:)` 方法。
 
 - Parameters:
 - responderClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
 - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
 - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesCancelled(
    for responderClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesCancelled(_:with:))
    let className = NSStringFromClass(responderClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        originalBlock(receiver, selector, touches, event)
        
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    wy_swizzleMethod(for: responderClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesEnded(_:with:)` 方法。
 
 - Parameters:
 - responderClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
 - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
 - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesEnded(
    for responderClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesEnded(_:with:))
    let className = NSStringFromClass(responderClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        originalBlock(receiver, selector, touches, event)
        
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    wy_swizzleMethod(for: responderClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UILabel` 及其子类的 `drawText(in:)` 方法。
 
 - Parameters:
 - labelClass: 目标 Label 类（如 `UILabel.self`）。
 - before: 方法执行前回调。参数依次为：当前标签、绘制区域矩形。无返回值。
 - after: 方法执行后回调。参数依次为：当前标签、绘制区域矩形。无返回值（仅通知）。
 */
public func wy_exchangeDrawText(
    for labelClass: UILabel.Type,
    before: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil,
    after: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil
) {
    let selector = #selector(UILabel.drawText(in:))
    let className = NSStringFromClass(labelClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = CGRect
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(labelClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UILabel, Selector, CGRect) -> Void
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyLabel, _, rect in
            guard let label = anyLabel as? UILabel else { return }
            before(label, rect)
        }
    }
    if let after = after {
        hooks.after.append { anyLabel, _, rect, _ in
            guard let label = anyLabel as? UILabel else { return }
            after(label, rect)
            return
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UILabel, CGRect) -> Void = { receiver, rect in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, rect)
        }
        
        originalBlock(receiver, selector, rect)
        
        for after in hooks.after {
            _ = after(receiver, selector, rect, ())
        }
    }
    
    wy_swizzleMethod(for: labelClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `intrinsicContentSize` 属性的 getter 方法。
 
 - Parameters:
 - viewClass: 目标视图类（如 `UIView.self`）。
 - before: 方法执行前回调。参数为当前视图。无返回值。
 - after: 方法执行后回调。参数依次为：当前视图、原始返回值（`CGSize`）。可返回一个新的 `CGSize` 来替换原始返回值。
 */
public func wy_exchangeIntrinsicContentSize(
    for viewClass: UIView.Type,
    before: ((_ currentView: UIView) -> Void)? = nil,
    after: ((_ currentView: UIView, _ originalResult: CGSize) -> CGSize)? = nil
) {
    let selector = #selector(getter: UIView.intrinsicContentSize)
    let className = NSStringFromClass(viewClass)
    let key = "wy_\(className)_\(NSStringFromSelector(selector))"
    typealias Args = Void
    typealias Return = CGSize
    typealias Hooks = WYMethodHooks<Args, Return>
    
    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    let originalIMP = method_getImplementation(originalMethod)
    typealias OriginalFunc = @convention(c) (UIView, Selector) -> CGSize
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    WYHooksLock.lock()
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    if let before = before {
        hooks.before.append { anyView, _, _ in
            guard let view = anyView as? UIView else { return }
            before(view)
        }
    }
    if let after = after {
        hooks.after.append { anyView, _, _, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, original)
        }
    }
    WYHooksMap[key] = hooks
    WYHooksLock.unlock()
    
    let newBlock: @convention(block) (UIView) -> CGSize = { receiver in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, ())
        }
        
        let originalResult = originalBlock(receiver, selector)
        
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, (), result)
        }
        return result
    }
    
    wy_swizzleMethod(for: viewClass, selector: selector, newImpBlock: newBlock)
}

/// 单个方法的钩子集合（泛型，每个类每个方法独立）
public struct WYMethodHooks<Args, Return> {
    /// 方法执行前的回调数组（观察型，无返回值）
    public var before: [(Any, Selector, Args) -> Void] = []
    /// 方法执行后的回调数组，可修改返回值
    public var after: [(Any, Selector, Args, Return) -> Return] = []
}

/// 独立存储 popViewController 的拦截闭包（返回 Bool，false 表示拦截，不执行原始 pop）
private var WYShouldPopMap: [String: (UINavigationController, Bool) -> Bool] = [:]

/// 全局钩子存储容器（存储 before/after，值类型为 Any）
private var WYHooksMap: [String: Any] = [:]

/// 保护钩子容器的线程锁
private let WYHooksLock = NSLock()

/// 独立存储 hitTest 的 intercept 闭包（返回 WYInterceptDecision）
private var WYHitTestInterceptMap: [String: (UIView, CGPoint, UIEvent?) -> WYInterceptDecision] = [:]

/// 缓存 wy_findHooks 的结果（key: "className_selector"）
private var WYHooksCacheMap: [String: Any] = [:]

/// 缓存 wy_findHitTestIntercept 的结果（key: "className_selector"）
private var WYHitTestCacheMap: [String: (UIView, CGPoint, UIEvent?) -> WYInterceptDecision] = [:]

/**
 沿继承链查找指定选择器的钩子集合
 
 - Parameters:
 - receiver: 当前对象
 - selector: 方法选择器
 - Returns: 找到的第一个非空钩子集合，若未找到则返回空集合
 */
private func wy_findHooks<Args, Return>(for receiver: AnyObject, selector: Selector) -> WYMethodHooks<Args, Return> {
    let selName = NSStringFromSelector(selector)
    var currentClass: AnyClass? = type(of: receiver)
    // 先尝试从缓存中获取
    while let cls = currentClass, cls != NSObject.self {
        let className = NSStringFromClass(cls)
        let cacheKey = "\(className)_\(selName)"
        WYHooksLock.lock()
        if let cached = WYHooksCacheMap[cacheKey] as? WYMethodHooks<Args, Return> {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        let key = "wy_\(className)_\(selName)"
        WYHooksLock.lock()
        let hooks = WYHooksMap[key] as? WYMethodHooks<Args, Return>
        WYHooksLock.unlock()
        if let hooks = hooks {
            // 存入缓存
            WYHooksLock.lock()
            WYHooksCacheMap[cacheKey] = hooks
            WYHooksLock.unlock()
            return hooks
        }
        currentClass = class_getSuperclass(cls)
    }
    let empty = WYMethodHooks<Args, Return>()
    // 缓存空结果，避免重复查找
    let className = NSStringFromClass(type(of: receiver))
    let cacheKey = "\(className)_\(selName)"
    WYHooksLock.lock()
    WYHooksCacheMap[cacheKey] = empty
    WYHooksLock.unlock()
    return empty
}

/**
 沿继承链查找 hitTest 的 intercept 闭包
 
 - Parameters:
 - receiver: 当前视图
 - selector: hitTest 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
private func wy_findHitTestIntercept(for receiver: UIView, selector: Selector) -> ((UIView, CGPoint, UIEvent?) -> WYInterceptDecision)? {
    let selName = NSStringFromSelector(selector)
    var currentClass: AnyClass? = type(of: receiver)
    while let cls = currentClass, cls != NSObject.self {
        let className = NSStringFromClass(cls)
        let cacheKey = "\(className)_\(selName)"
        WYHooksLock.lock()
        if let cached = WYHitTestCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        let key = "wy_intercept_\(className)_\(selName)"
        WYHooksLock.lock()
        let intercept = WYHitTestInterceptMap[key]
        WYHooksLock.unlock()
        if let intercept = intercept {
            WYHooksLock.lock()
            WYHitTestCacheMap[cacheKey] = intercept
            WYHooksLock.unlock()
            return intercept
        }
        currentClass = class_getSuperclass(cls)
    }
    return nil
}

/**
 对指定类的指定方法进行 IMP 替换（仅一次）
 - Parameters:
 - anyClass: 目标类
 - selector: 方法选择器
 - newImpBlock: 新的 Block IMP，类型为 @convention(block)
 */
private func wy_swizzleMethod(
    for anyClass: AnyClass,
    selector: Selector,
    newImpBlock: Any
) {
    let swizzleKey = "wy_\(NSStringFromClass(anyClass))_\(NSStringFromSelector(selector))_swizzled"
    objc_sync_enter(anyClass)
    defer { objc_sync_exit(anyClass) }
    
    if objc_getAssociatedObject(anyClass, swizzleKey) != nil { return }
    objc_setAssociatedObject(anyClass, swizzleKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    guard let originalMethod = class_getInstanceMethod(anyClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return
    }
    
    let newIMP = imp_implementationWithBlock(newImpBlock)
    method_setImplementation(originalMethod, newIMP)
}
