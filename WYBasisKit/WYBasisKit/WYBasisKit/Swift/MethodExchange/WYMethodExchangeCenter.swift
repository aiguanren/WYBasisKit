//
//  WYMethodExchangeCenter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/19.
//

import UIKit

/// HitTest 拦截决策
public enum WYHitTestDecision {
    /// 继续执行原始交换方法
    case proceed
    /// 直接返回指定的值（可以是 nil），不再调用原始方法
    case result(UIView?)
}

/// DrawRect 拦截决策
public enum WYDrawRectDecision {
    /// 继续使用原始矩形
    case proceed
    /// 替换为指定矩形
    case replace(CGRect)
}

/**
 交换 `UINavigationController` 及其子类的 `popViewController(animated:)` 方法。
 
 - Parameters:
   - targetClass: 目标导航控制器类（如 `UINavigationController.self`）。
   - shouldPop: 拦截决策闭包。返回 `true` 则继续执行原始方法；返回 `false` 则直接返回 `nil`，**不再调用原始方法**。参数依次为：当前导航控制器、是否动画。
   - before: 方法执行前回调。参数依次为：当前导航控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前导航控制器、是否动画、被弹出的视图控制器（可能为 `nil`）。无返回值（仅通知）。
 */
public func wy_exchangePopViewController(
    for targetClass: UINavigationController.Type,
    shouldPop: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> Bool)? = nil,
    before: ((_ currentNavigationController: UINavigationController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentNavigationController: UINavigationController, _ animated: Bool, _ poppedViewController: UIViewController?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UINavigationController.popViewController(animated:))
    
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
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 生成存储 shouldPop 拦截闭包的键，格式：wy_shouldPop_<类名>_<方法名>
    let shouldPopKey = "wy_shouldPop_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 将 shouldPop 闭包存入独立字典 WYShouldPopMap
    WYShouldPopMap[shouldPopKey] = shouldPop
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyNav, _, animated in
            // 将 Any 类型转换为 UINavigationController，然后调用用户闭包
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
        
        // 沿继承链向上查找 shouldPop 拦截闭包
        var currentClass: AnyClass? = type(of: receiver)
        var foundShouldPop: ((UINavigationController, Bool) -> Bool)? = nil
        
        // 遍历继承链（从当前类直到 NSObject）
        while let cls = currentClass, cls != NSObject.self {
            
            // 动态生成当前类className
            let className = NSStringFromClass(cls)
            
            // 动态生成当前类对应的 key
            let shouldPopKey = "wy_shouldPop_\(className)_\(NSStringFromSelector(selector))"
            
            // 加锁读取 WYShouldPopMap 中对应 key 的闭包
            WYHooksLock.lock()
            let shouldPop = WYShouldPopMap[shouldPopKey]
            WYHooksLock.unlock()
            
            if shouldPop != nil {
                foundShouldPop = shouldPop  // 找到第一个非空拦截闭包
                break
            }
            currentClass = class_getSuperclass(cls)  // 继续向父类查找
        }
        
        // 如果找到拦截闭包且返回 false，则直接返回 nil，不执行原始方法
        if let shouldPop = foundShouldPop, shouldPop(receiver, animated) == false {
            return nil
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
}

/**
 交换 `UIViewController` 及其子类的 `present(_:animated:completion:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前控制器、被 present 的控制器、是否动画、完成闭包。无返回值。
   - after: 方法执行后回调。参数依次为：当前控制器、被 present 的控制器、是否动画、完成闭包。无返回值（仅通知，不可修改返回值）。
 */
public func wy_exchangeControllerPresent(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ presentController: UIViewController, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ presentController: UIViewController, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.present(_:animated:completion:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, UIViewController, Bool, (() -> Void)?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (UIViewController, Bool, (() -> Void)?)，返回值为 Void
    typealias Args = (UIViewController, Bool, (() -> Void)?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, args in
            // 将 Any 类型转换为 UIViewController，然后调用用户闭包
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, args.0, args.1, args.2)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, args, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, args.0, args.1, args.2)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController, UIViewController, Bool, (() -> Void)?) -> Void = { receiver, viewControllerToPresent, animated, completion in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (viewControllerToPresent, animated, completion)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法（真正的 present 实现）
        originalBlock(receiver, selector, viewControllerToPresent, animated, completion)
        
        // 依次执行所有 after 闭包（不修改返回值）
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewDidLoad()` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数为当前控制器。无返回值。
   - after: 方法执行后回调。参数为当前控制器。无返回值（仅通知）。
 */
public func wy_exchangeViewDidLoad(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController) -> Void)? = nil,
    after: ((_ currentController: UIViewController) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewDidLoad)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：无参数，无返回值
    typealias Args = Void
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, _ in
            guard let vc = anyVC as? UIViewController else { return }
            before(vc)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, _, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController) -> Void = { receiver in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, ())
        }
        
        // 调用原始方法（原始 viewDidLoad 实现）
        originalBlock(receiver, selector)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, (), ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewWillAppear(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前控制器、是否动画。无返回值（仅通知）。
 */
public func wy_exchangeViewWillAppear(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewWillAppear(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, Bool) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 Bool，返回值为 Void
    typealias Args = Bool
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, animated in
            // 将 Any 类型转换为 UIViewController，然后调用用户闭包
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, animated)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, animated, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, animated)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController, Bool) -> Void = { receiver, animated in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        // 调用原始方法（原始 viewWillAppear 实现）
        originalBlock(receiver, selector, animated)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, animated, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewDidAppear(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前控制器、是否动画。无返回值（仅通知）。
 */
public func wy_exchangeViewDidAppear(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewDidAppear(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, Bool) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 Bool，返回值为 Void
    typealias Args = Bool
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, animated in
            // 将 Any 类型转换为 UIViewController，然后调用用户闭包
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, animated)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, animated, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, animated)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController, Bool) -> Void = { receiver, animated in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        // 调用原始方法（原始 viewDidAppear 实现）
        originalBlock(receiver, selector, animated)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, animated, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewWillDisappear(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前控制器、是否动画。无返回值（仅通知）。
 */
public func wy_exchangeViewWillDisappear(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewWillDisappear(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, Bool) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 Bool，返回值为 Void
    typealias Args = Bool
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, animated in
            // 将 Any 类型转换为 UIViewController，然后调用用户闭包
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, animated)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, animated, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, animated)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController, Bool) -> Void = { receiver, animated in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        // 调用原始方法（原始 viewWillDisappear 实现）
        originalBlock(receiver, selector, animated)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, animated, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIViewController` 及其子类的 `viewDidDisappear(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前控制器、是否动画。无返回值。
   - after: 方法执行后回调。参数依次为：当前控制器、是否动画。无返回值（仅通知）。
 */
public func wy_exchangeViewDidDisappear(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil,
    after: ((_ currentController: UIViewController, _ animated: Bool) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewDidDisappear(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIViewController, Selector, Bool) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 Bool，返回值为 Void
    typealias Args = Bool
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyVC, _, animated in
            // 将 Any 类型转换为 UIViewController，然后调用用户闭包
            guard let vc = anyVC as? UIViewController else { return }
            before(vc, animated)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyVC, _, animated, _ in
            guard let vc = anyVC as? UIViewController else { return }
            after(vc, animated)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIViewController, Bool) -> Void = { receiver, animated in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, animated)
        }
        
        // 调用原始方法（原始 viewDidDisappear 实现）
        originalBlock(receiver, selector, animated)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, animated, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewDidScroll(_:)` 方法。
 
 注意：该方法通常由 `UIViewController` 或 `UIView` 实现，因此交换时需要传入具体的类（如 `MyViewController.self`）。
 
 - Parameters:
   - targetClass: 目标代理类（如 `MyViewController.self`）。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewDidScroll(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewDidScroll(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIScrollView，返回值为 Void
    typealias Args = UIScrollView
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, scrollView in
            // 将 Any 类型转换为 NSObject，然后调用用户闭包
            guard let obj = anyObj as? NSObject else { return }
            before(obj, scrollView)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, scrollView, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, scrollView)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView) -> Void = { receiver, scrollView in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, scrollView)
        }
        
        // 调用原始方法（原始 scrollViewDidScroll 实现）
        originalBlock(receiver, selector, scrollView)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, scrollView, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewWillBeginDragging(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewWillBeginDragging(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewWillBeginDragging(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIScrollView，返回值为 Void
    typealias Args = UIScrollView
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, scrollView in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, scrollView)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, scrollView, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, scrollView)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView) -> Void = { receiver, scrollView in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, scrollView)
        }
        originalBlock(receiver, selector, scrollView)
        for after in hooks.after {
            _ = after(receiver, selector, scrollView, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图、速度、目标偏移指针。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图、速度、目标偏移指针。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewWillEndDragging(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewWillEndDragging(_:withVelocity:targetContentOffset:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>)，返回值为 Void
    typealias Args = (UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, args in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, args.0, args.1, args.2)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, args, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, args.0, args.1, args.2)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void = { receiver, scrollView, velocity, targetContentOffset in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (scrollView, velocity, targetContentOffset)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        originalBlock(receiver, selector, scrollView, velocity, targetContentOffset)
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewDidEndDragging(_:willDecelerate:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图、是否减速。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图、是否减速。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewDidEndDragging(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView, _ willDecelerate: Bool) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView, _ willDecelerate: Bool) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewDidEndDragging(_:willDecelerate:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView, Bool) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (UIScrollView, Bool)，返回值为 Void
    typealias Args = (UIScrollView, Bool)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, args in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, args, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, args.0, args.1)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView, Bool) -> Void = { receiver, scrollView, willDecelerate in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (scrollView, willDecelerate)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        originalBlock(receiver, selector, scrollView, willDecelerate)
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewWillBeginDecelerating(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewWillBeginDecelerating(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewWillBeginDecelerating(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIScrollView，返回值为 Void
    typealias Args = UIScrollView
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, scrollView in
            // 将 Any 类型转换为 NSObject，然后调用用户闭包
            guard let obj = anyObj as? NSObject else { return }
            before(obj, scrollView)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, scrollView, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, scrollView)
            return  // 不修改返回值
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView) -> Void = { receiver, scrollView in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, scrollView)
        }
        
        // 调用原始方法（原始 scrollViewWillBeginDecelerating 实现）
        originalBlock(receiver, selector, scrollView)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, scrollView, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewDidEndDecelerating(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewDidEndDecelerating(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewDidEndDecelerating(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIScrollView，返回值为 Void
    typealias Args = UIScrollView
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, scrollView in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, scrollView)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, scrollView, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, scrollView)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView) -> Void = { receiver, scrollView in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, scrollView)
        }
        
        // 调用原始方法（原始 scrollViewDidEndDecelerating 实现）
        originalBlock(receiver, selector, scrollView)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, scrollView, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIScrollViewDelegate` 的对象的 `scrollViewDidZoom(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类（如 `MyViewController.self`）。
   - before: 方法执行前回调。参数依次为：代理对象、滚动视图。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、滚动视图。无返回值（仅通知）。
 */
public func wy_exchangeScrollViewDidZoom(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ scrollView: UIScrollView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIScrollViewDelegate.scrollViewDidZoom(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIScrollView) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIScrollView，返回值为 Void
    typealias Args = UIScrollView
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, scrollView in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, scrollView)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, scrollView, _ in
            guard let obj = anyObj as? NSObject else { return }
            after(obj, scrollView)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIScrollView) -> Void = { receiver, scrollView in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, scrollView)
        }
        
        // 调用原始方法（原始 scrollViewDidZoom 实现）
        originalBlock(receiver, selector, scrollView)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, scrollView, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `NSObject` 及其子类的 `observeValue(forKeyPath:of:change:context:)` 方法。
 
 - Parameters:
   - targetClass: 目标观察者类（如 `NSObject.self`）。
   - before: 方法执行前回调。参数依次为：观察者、键路径、被观察对象、变化字典、上下文指针。无返回值。
   - after: 方法执行后回调。参数依次为：观察者、键路径、被观察对象、变化字典、上下文指针。无返回值（仅通知）。
 */
public func wy_exchangeKVOObserve(
    for targetClass: NSObject.Type,
    before: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil,
    after: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(NSObject.observeValue(forKeyPath:of:change:context:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?)，返回值为 Void
    typealias Args = (String?, Any?, [NSKeyValueChangeKey : Any]?, UnsafeMutableRawPointer?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObs, _, args in
            guard let obs = anyObs as? NSObject else { return }
            before(obs, args.0, args.1, args.2, args.3)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObs, _, args, _ in
            guard let obs = anyObs as? NSObject else { return }
            after(obs, args.0, args.1, args.2, args.3)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `hitTest(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(view)` 则直接返回该视图（可为 `nil`），**不再调用原始方法**。参数依次为：当前视图、点击位置、事件。
   - before: 方法执行前观察闭包（仅在原始方法执行前调用，不影响流程）。参数依次为：当前视图、点击位置、事件。无返回值。
   - after: 方法执行后回调，可修改原始返回值。参数依次为：当前视图、点击位置、事件、原始返回值（`UIView?`）。返回一个新的 `UIView?` 作为最终结果。
 */
public func wy_exchangeHitTest(
    for targetClass: UIView.Type,
    intercept: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> WYHitTestDecision)? = nil,
    before: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?, _ originalResult: UIView?) -> UIView?)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIView.hitTest(_:with:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGPoint, UIEvent?) -> UIView?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (CGPoint, UIEvent?)，返回值为 UIView?
    typealias Args = (CGPoint, UIEvent?)
    typealias Return = UIView?
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyView, _, args in
            guard let view = anyView as? UIView else { return }
            before(view, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyView, _, args, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, args.0, args.1, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_hitTest_<类名>_<方法名>
    let interceptKey = "wy_intercept_hitTest_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局 intercept 字典的修改线程安全
    WYHooksLock.lock()
    WYHitTestInterceptMap[interceptKey] = intercept
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIView, CGPoint, UIEvent?) -> UIView? = { receiver, point, event in
        // 1. 查找 intercept 决策（使用缓存，沿继承链查找）
        if let intercept = wy_findHitTestIntercept(for: receiver, selector: selector) {
            switch intercept(receiver, point, event) {
            case .result(let view):
                // 如果拦截决策返回 .result(view)，则直接返回该视图，不再执行原始方法
                return view
            case .proceed:
                // 继续执行原始方法
                break
            }
        }
        
        // 2. 查找 before/after 钩子（使用缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (point, event)
        
        // 执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法
        let originalResult = originalBlock(receiver, selector, point, event)
        
        // 执行所有 after 闭包，允许修改返回值
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, args, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `layoutSubviews()` 方法。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - before: 方法执行前回调。参数为当前视图。无返回值。
   - after: 方法执行后回调。参数为当前视图。无返回值（仅通知）。
 */
public func wy_exchangeLayoutSubviews(
    for targetClass: UIView.Type,
    before: ((_ currentView: UIView) -> Void)? = nil,
    after: ((_ currentView: UIView) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIView.layoutSubviews)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：无参数，返回值为 Void
    typealias Args = Void
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyView, _, _ in
            guard let view = anyView as? UIView else { return }
            before(view)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyView, _, _, _ in
            guard let view = anyView as? UIView else { return }
            after(view)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesBegan(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesBegan(
    for targetClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIResponder.touchesBegan(_:with:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (Set<UITouch>, UIEvent?)，返回值为 Void
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesMoved(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesMoved(
    for targetClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIResponder.touchesMoved(_:with:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (Set<UITouch>, UIEvent?)，返回值为 Void
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法（原始 touchesMoved 实现）
        originalBlock(receiver, selector, touches, event)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesCancelled(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesCancelled(
    for targetClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIResponder.touchesCancelled(_:with:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (Set<UITouch>, UIEvent?)，返回值为 Void
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法（原始 touchesCancelled 实现）
        originalBlock(receiver, selector, touches, event)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIResponder` 及其子类的 `touchesEnded(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标响应者类（如 `UIView.self` 或 `UIViewController.self`）。
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数依次为：当前响应者、触摸集合、事件。无返回值（仅通知）。
 */
public func wy_exchangeTouchesEnded(
    for targetClass: UIResponder.Type,
    before: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ responder: UIResponder, _ touches: Set<UITouch>, _ event: UIEvent?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIResponder.touchesEnded(_:with:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIResponder, Selector, Set<UITouch>, UIEvent?) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (Set<UITouch>, UIEvent?)，返回值为 Void
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyResponder, _, args in
            guard let responder = anyResponder as? UIResponder else { return }
            before(responder, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyResponder, _, args, _ in
            guard let responder = anyResponder as? UIResponder else { return }
            after(responder, args.0, args.1)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIResponder, Set<UITouch>, UIEvent?) -> Void = { receiver, touches, event in
        // 查找当前接收者对应的 before/after 钩子集合（自动处理继承链和缓存）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (touches, event)
        
        // 依次执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法（原始 touchesEnded 实现）
        originalBlock(receiver, selector, touches, event)
        
        // 依次执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, args, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `draw(_:)` 方法（即 `drawRect:`）。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - before: 方法执行前回调。参数依次为：当前视图、绘制区域矩形。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、绘制区域矩形。无返回值（仅通知）。
 */
public func wy_exchangeDrawRect(
    for targetClass: UIView.Type,
    before: ((_ currentView: UIView, _ rect: CGRect) -> Void)? = nil,
    after: ((_ currentView: UIView, _ rect: CGRect) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIView.draw(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGRect) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 CGRect，返回值为 Void
    typealias Args = CGRect
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyView, _, rect in
            guard let view = anyView as? UIView else { return }
            before(view, rect)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyView, _, rect, _ in
            guard let view = anyView as? UIView else { return }
            after(view, rect)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIView, CGRect) -> Void = { receiver, rect in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, rect)
        }
        originalBlock(receiver, selector, rect)
        for after in hooks.after {
            _ = after(receiver, selector, rect, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `sizeThatFits(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - before: 方法执行前回调。参数依次为：当前视图、建议的尺寸。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、建议的尺寸、原始返回值（`CGSize`）。可返回一个新的 `CGSize` 来替换原始返回值。
 */
public func wy_exchangeSizeThatFits(
    for targetClass: UIView.Type,
    before: ((_ currentView: UIView, _ size: CGSize) -> Void)? = nil,
    after: ((_ currentView: UIView, _ size: CGSize, _ originalResult: CGSize) -> CGSize)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIView.sizeThatFits(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGSize) -> CGSize
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 CGSize，返回值为 CGSize
    typealias Args = CGSize
    typealias Return = CGSize
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyView, _, size in
            guard let view = anyView as? UIView else { return }
            before(view, size)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyView, _, size, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, size, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UILabel` 及其子类的 `drawText(in:)` 方法。
 
 - Parameters:
   - targetClass: 目标 Label 类（如 `UILabel.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则使用原始矩形；返回 `.replace(rect)` 则使用新矩形进行绘制。参数依次为：当前标签、原始矩形。
   - before: 方法执行前观察闭包（仅在原始方法执行前调用）。参数依次为：当前标签、最终使用的矩形。无返回值。
   - after: 方法执行后回调。参数依次为：当前标签、最终使用的矩形。无返回值（仅通知）。
 */
public func wy_exchangeDrawText(
    for targetClass: UILabel.Type,
    intercept: ((_ currentLabel: UILabel, _ originalRect: CGRect) -> WYDrawRectDecision)? = nil,
    before: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil,
    after: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UILabel.drawText(in:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UILabel, Selector, CGRect) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 CGRect，返回值为 Void
    typealias Args = CGRect
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLabel, _, rect in
            guard let label = anyLabel as? UILabel else { return }
            before(label, rect)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLabel, _, rect, _ in
            guard let label = anyLabel as? UILabel else { return }
            after(label, rect)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 存储 intercept 闭包到独立字典
    let interceptKey = "wy_intercept_drawRect_\(className)_\(NSStringFromSelector(selector))"
    WYHooksLock.lock()
    WYDrawRectInterceptMap[interceptKey] = intercept
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UILabel, CGRect) -> Void = { receiver, rect in
        // 查找 intercept 决策（使用缓存）
        var finalRect = rect
        if let decision = wy_findDrawRectIntercept(for: receiver, selector: selector) {
            switch decision(receiver, rect) {
            case .replace(let newRect):
                finalRect = newRect
            case .proceed:
                break
            }
        }
        
        // 查找当前接收者对应的 before/after 钩子集合
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, finalRect)
        }
        
        // 调用原始方法（使用最终矩形）
        originalBlock(receiver, selector, finalRect)
        
        for after in hooks.after {
            _ = after(receiver, selector, finalRect, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UIView` 及其子类的 `intrinsicContentSize` 属性的 getter 方法。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - before: 方法执行前回调。参数为当前视图。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、原始返回值（`CGSize`）。可返回一个新的 `CGSize` 来替换原始返回值。
 */
public func wy_exchangeIntrinsicContentSize(
    for targetClass: UIView.Type,
    before: ((_ currentView: UIView) -> Void)? = nil,
    after: ((_ currentView: UIView, _ originalResult: CGSize) -> CGSize)? = nil
) {
    // 获取要交换的方法选择器（getter）
    let selector = #selector(getter: UIView.intrinsicContentSize)
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector) -> CGSize
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：无参数，返回值为 CGSize
    typealias Args = Void
    typealias Return = CGSize
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyView, _, _ in
            guard let view = anyView as? UIView else { return }
            before(view)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyView, _, _, original in
            guard let view = anyView as? UIView else { return original }
            return after(view, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `prepare()` 方法。
 
 - Parameters:
   - targetClass: 目标布局类（如 `UICollectionViewFlowLayout.self`）。
   - before: 方法执行前回调。参数为当前布局对象。无返回值。
   - after: 方法执行后回调。参数为当前布局对象。无返回值（仅通知）。
 */
public func wy_exchangeLayoutPrepare(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout) -> Void)? = nil
) {
    // 获取要交换的方法选择器（使用字符串，因为 prepare 方法在 Swift 中可能无法直接使用 #selector）
    let selector = NSSelectorFromString("prepare")
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：无参数，返回值为 Void
    typealias Args = Void
    typealias Return = Void
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, _ in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, _, _ in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            after(layout)
            return
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout) -> Void = { receiver in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, ())
        }
        originalBlock(receiver, selector)
        for after in hooks.after {
            _ = after(receiver, selector, (), ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `layoutAttributesForElements(in:)` 方法。
 
 - Parameters:
   - targetClass: 目标布局类。
   - before: 方法执行前回调。参数依次为：布局对象、矩形区域。无返回值。
   - after: 方法执行后回调。参数依次为：布局对象、矩形区域、原始返回值（`[UICollectionViewLayoutAttributes]?`）。可返回一个新的数组来替换原始返回值。
 */
public func wy_exchangeLayoutAttributesForElements(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout, _ rect: CGRect) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout, _ rect: CGRect, _ originalResult: [UICollectionViewLayoutAttributes]?) -> [UICollectionViewLayoutAttributes]?)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UICollectionViewLayout.layoutAttributesForElements(in:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector, CGRect) -> [UICollectionViewLayoutAttributes]?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 CGRect，返回值为 [UICollectionViewLayoutAttributes]?
    typealias Args = CGRect
    typealias Return = [UICollectionViewLayoutAttributes]?
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, rect in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout, rect)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, rect, original in
            guard let layout = anyLayout as? UICollectionViewLayout else { return original }
            return after(layout, rect, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout, CGRect) -> [UICollectionViewLayoutAttributes]? = { receiver, rect in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, rect)
        }
        let originalResult = originalBlock(receiver, selector, rect)
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, rect, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `layoutAttributesForItem(at:)` 方法。
 
 - Parameters:
   - targetClass: 目标布局类。
   - before: 方法执行前回调。参数依次为：布局对象、索引路径。无返回值。
   - after: 方法执行后回调。参数依次为：布局对象、索引路径、原始返回值（`UICollectionViewLayoutAttributes?`）。可返回一个新的属性对象来替换原始返回值。
 */
public func wy_exchangeLayoutAttributesForItem(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout, _ indexPath: IndexPath) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout, _ indexPath: IndexPath, _ originalResult: UICollectionViewLayoutAttributes?) -> UICollectionViewLayoutAttributes?)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UICollectionViewLayout.layoutAttributesForItem(at:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector, IndexPath) -> UICollectionViewLayoutAttributes?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 IndexPath，返回值为 UICollectionViewLayoutAttributes?
    typealias Args = IndexPath
    typealias Return = UICollectionViewLayoutAttributes?
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, indexPath in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout, indexPath)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, indexPath, original in
            guard let layout = anyLayout as? UICollectionViewLayout else { return original }
            return after(layout, indexPath, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout, IndexPath) -> UICollectionViewLayoutAttributes? = { receiver, indexPath in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, indexPath)
        }
        let originalResult = originalBlock(receiver, selector, indexPath)
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, indexPath, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `layoutAttributesForSupplementaryView(ofKind:at:)` 方法。
 
 - Parameters:
   - targetClass: 目标布局类。
   - before: 方法执行前回调。参数依次为：布局对象、元素类型、索引路径。无返回值。
   - after: 方法执行后回调。参数依次为：布局对象、元素类型、索引路径、原始返回值（`UICollectionViewLayoutAttributes?`）。可返回一个新的属性对象来替换原始返回值。
 */
public func wy_exchangeLayoutAttributesForSupplementaryView(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout, _ elementKind: String, _ indexPath: IndexPath) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout, _ elementKind: String, _ indexPath: IndexPath, _ originalResult: UICollectionViewLayoutAttributes?) -> UICollectionViewLayoutAttributes?)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UICollectionViewLayout.layoutAttributesForSupplementaryView(ofKind:at:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector, String, IndexPath) -> UICollectionViewLayoutAttributes?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 (String, IndexPath)，返回值为 UICollectionViewLayoutAttributes?
    typealias Args = (String, IndexPath)
    typealias Return = UICollectionViewLayoutAttributes?
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, args in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, args, original in
            guard let layout = anyLayout as? UICollectionViewLayout else { return original }
            return after(layout, args.0, args.1, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout, String, IndexPath) -> UICollectionViewLayoutAttributes? = { receiver, elementKind, indexPath in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (elementKind, indexPath)
        for before in hooks.before {
            before(receiver, selector, args)
        }
        let originalResult = originalBlock(receiver, selector, elementKind, indexPath)
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, args, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `collectionViewContentSize` 属性的 getter 方法。
 
 - Parameters:
   - targetClass: 目标布局类。
   - before: 方法执行前回调。参数为当前布局对象。无返回值。
   - after: 方法执行后回调。参数依次为：布局对象、原始返回值（`CGSize`）。可返回一个新的 `CGSize` 来替换原始返回值。
 */
public func wy_exchangeCollectionViewContentSize(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout, _ originalResult: CGSize) -> CGSize)? = nil
) {
    // 获取要交换的方法选择器（getter）
    let selector = #selector(getter: UICollectionViewLayout.collectionViewContentSize)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector) -> CGSize
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：无参数，返回值为 CGSize
    typealias Args = Void
    typealias Return = CGSize
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, _ in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, _, original in
            guard let layout = anyLayout as? UICollectionViewLayout else { return original }
            return after(layout, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout) -> CGSize = { receiver in
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
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换 `UICollectionViewLayout` 及其子类的 `shouldInvalidateLayout(forBoundsChange:)` 方法。
 
 - Parameters:
   - targetClass: 目标布局类。
   - before: 方法执行前回调。参数依次为：布局对象、新边界。无返回值。
   - after: 方法执行后回调。参数依次为：布局对象、新边界、原始返回值（`Bool`）。可返回一个新的 `Bool` 来替换原始返回值。
 */
public func wy_exchangeShouldInvalidateLayout(
    for targetClass: UICollectionViewLayout.Type,
    before: ((_ layout: UICollectionViewLayout, _ newBounds: CGRect) -> Void)? = nil,
    after: ((_ layout: UICollectionViewLayout, _ newBounds: CGRect, _ originalResult: Bool) -> Bool)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UICollectionViewLayout.shouldInvalidateLayout(forBoundsChange:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UICollectionViewLayout, Selector, CGRect) -> Bool
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 CGRect，返回值为 Bool
    typealias Args = CGRect
    typealias Return = Bool
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyLayout, _, newBounds in
            guard let layout = anyLayout as? UICollectionViewLayout else { return }
            before(layout, newBounds)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLayout, _, newBounds, original in
            guard let layout = anyLayout as? UICollectionViewLayout else { return original }
            return after(layout, newBounds, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UICollectionViewLayout, CGRect) -> Bool = { receiver, newBounds in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, newBounds)
        }
        let originalResult = originalBlock(receiver, selector, newBounds)
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, newBounds, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 交换遵循 `UIGestureRecognizerDelegate` 的对象的 `gestureRecognizerShouldBegin(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类（如 `MyViewController.self`）。
   - before: 方法执行前回调。参数依次为：代理对象、手势识别器。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、手势识别器、原始返回值（`Bool`）。可返回一个新的 `Bool` 来替换原始返回值。
 */
public func wy_exchangeGestureRecognizerShouldBegin(
    for targetClass: NSObject.Type,
    before: ((_ delegate: NSObject, _ gestureRecognizer: UIGestureRecognizer) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ gestureRecognizer: UIGestureRecognizer, _ originalResult: Bool) -> Bool)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:))
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIGestureRecognizer) -> Bool
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义泛型参数：方法参数为 UIGestureRecognizer，返回值为 Bool
    typealias Args = UIGestureRecognizer
    typealias Return = Bool
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = "wy_hook_\(className)_\(NSStringFromSelector(selector))"
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 从 WYHooksMap 中取出已有的钩子集合，若不存在则创建空集合
    var hooks = (WYHooksMap[key] as? Hooks) ?? Hooks()
    
    // 如果用户提供了 before 闭包，则将其包装后添加到 hooks.before 数组
    if let before = before {
        hooks.before.append { anyObj, _, gesture in
            guard let obj = anyObj as? NSObject else { return }
            before(obj, gesture)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyObj, _, gesture, original in
            guard let obj = anyObj as? NSObject else { return original }
            return after(obj, gesture, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁，结束对全局字典的修改
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIGestureRecognizer) -> Bool = { receiver, gestureRecognizer in
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        for before in hooks.before {
            before(receiver, selector, gestureRecognizer)
        }
        let originalResult = originalBlock(receiver, selector, gestureRecognizer)
        var result = originalResult
        for after in hooks.after {
            result = after(receiver, selector, gestureRecognizer, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
}

/**
 移除指定类的指定方法的钩子（包括 before、after 和 intercept）。
 
 - Parameters:
   - anyClass: 目标类。
   - selector: 方法选择器。若传入 `nil`，则移除该类的所有钩子（所有方法）；若指定 `selector`，则只移除该方法的钩子。
 */
public func wy_removeMethodExchangeHooks(for anyClass: AnyClass, selector: Selector? = nil) {
    // 将目标类转换为字符串，用于生成各种键的前缀
    let className = NSStringFromClass(anyClass)
    
    // 定义各种存储字典的 key 前缀
    let prefix = "wy_hook_\(className)_"                       // WYHooksMap 前缀
    let shouldPopPrefix = "wy_shouldPop_\(className)_"        // WYShouldPopMap 前缀
    let drawRectInterceptPrefix = "wy_intercept_drawRect_\(className)_" // WYDrawRectInterceptMap 前缀
    let drawRectCachePrefix = "wy_cache_drawRect_\(className)_"         // WYDrawRectCacheMap 前缀
    
    // 加锁，保证线程安全
    WYHooksLock.lock()
    
    if let selector = selector {
        // 指定了 selector：只移除该方法的钩子
        let selName = NSStringFromSelector(selector)
        
        // 1. 清除 before/after 钩子存储
        let key = prefix + selName
        WYHooksMap[key] = nil
        
        // 2. 清除 hitTest 的 intercept 闭包存储
        let hitTestInterceptKey = "wy_intercept_hitTest_\(className)_\(selName)"
        WYHitTestInterceptMap[hitTestInterceptKey] = nil
        
        // 3. 清除 popViewController 的 shouldPop 闭包存储
        let shouldPopKey = shouldPopPrefix + selName
        WYShouldPopMap[shouldPopKey] = nil
        
        // 4. 清除 drawRect 的 intercept 闭包存储和对应的缓存
        let drawRectInterceptKey = drawRectInterceptPrefix + selName
        WYDrawRectInterceptMap[drawRectInterceptKey] = nil
        let drawRectCacheKey = drawRectCachePrefix + selName
        WYDrawRectCacheMap[drawRectCacheKey] = nil
        
        // 5. 清除通用缓存（findHooks 和 findHitTestIntercept 使用）
        let cacheKey = "wy_cache_hook_\(className)_\(selName)"
        WYHooksCacheMap[cacheKey] = nil
        let hitTestCacheKey = "wy_cache_hitTest_\(className)_\(selName)"
        WYHitTestCacheMap[hitTestCacheKey] = nil
        
        // 6. 清除由 wy_swizzleMethod 设置的关联对象标记（防止再次交换时被跳过）
        let swizzleKey = "wy_\(className)_\(selName)_swizzled"
        objc_setAssociatedObject(anyClass, swizzleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 7. 从已调用记录集合中移除该 swizzleKey，以便后续重新注册
        WYExchangedMethodsLock.lock()
        WYExchangedMethodsSet.remove(swizzleKey)
        WYExchangedMethodsLock.unlock()
        
    } else {
        // selector 为 nil，表示移除该类的所有方法钩子
        
        // 1. 清除该类所有方法的 before/after 钩子存储
        let keysToRemove = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            WYHooksMap[key] = nil
        }
        
        // 2. 清除该类所有 hitTest intercept 闭包存储
        let hitTestInterceptKeysToRemove = WYHitTestInterceptMap.keys.filter { $0.hasPrefix("wy_intercept_hitTest_\(className)_") }
        for key in hitTestInterceptKeysToRemove {
            WYHitTestInterceptMap[key] = nil
        }
        
        // 3. 清除该类所有 popViewController 拦截闭包存储
        let shouldPopKeysToRemove = WYShouldPopMap.keys.filter { $0.hasPrefix(shouldPopPrefix) }
        for key in shouldPopKeysToRemove {
            WYShouldPopMap[key] = nil
        }
        
        // 4. 清除该类所有 drawRect intercept 闭包存储和对应的缓存
        let drawRectInterceptKeysToRemove = WYDrawRectInterceptMap.keys.filter { $0.hasPrefix(drawRectInterceptPrefix) }
        for key in drawRectInterceptKeysToRemove {
            WYDrawRectInterceptMap[key] = nil
        }
        let drawRectCacheKeysToRemove = WYDrawRectCacheMap.keys.filter { $0.hasPrefix(drawRectCachePrefix) }
        for key in drawRectCacheKeysToRemove {
            WYDrawRectCacheMap[key] = nil
        }
        
        // 5. 清除该类所有方法的通用缓存（findHooks 和 findHitTestIntercept 使用）
        let cacheKeysToRemove = WYHooksCacheMap.keys.filter { $0.hasPrefix("wy_cache_hook_\(className)_") }
        for key in cacheKeysToRemove {
            WYHooksCacheMap[key] = nil
        }
        let hitTestCacheKeysToRemove = WYHitTestCacheMap.keys.filter { $0.hasPrefix("wy_cache_hitTest_\(className)_") }
        for key in hitTestCacheKeysToRemove {
            WYHitTestCacheMap[key] = nil
        }
        
        // 6. 清除该类所有方法的关联对象标记并移除集合记录
        // 需要从 WYHooksMap 的 keys 中获取已注册的方法名（key 格式为 "wy_hook_<className>_<selName>"）
        let allMethodKeys = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for methodKey in allMethodKeys {
            // 提取 selName：去掉前缀 "wy_hook_<className>_"
            if let selName = methodKey.split(separator: "_", maxSplits: 3, omittingEmptySubsequences: false).last {
                let selNameStr = String(selName)
                let swizzleKey = "wy_\(className)_\(selNameStr)_swizzled"
                // 清除关联对象标记
                objc_setAssociatedObject(anyClass, swizzleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                // 从已调用记录集合中移除
                WYExchangedMethodsLock.lock()
                WYExchangedMethodsSet.remove(swizzleKey)
                WYExchangedMethodsLock.unlock()
            }
        }
    }
    
    // 解锁
    WYHooksLock.unlock()
}

/// 移除所有类、所有方法的钩子（包括 before、after、intercept、shouldPop 及缓存等）
public func wy_removeAllMethodExchangeHooks() {
    // 加锁，保证线程安全
    WYHooksLock.lock()
    // 清空所有存储字典
    WYHooksMap.removeAll()
    WYHitTestInterceptMap.removeAll()
    WYDrawRectInterceptMap.removeAll()
    WYShouldPopMap.removeAll()
    WYHooksCacheMap.removeAll()
    WYHitTestCacheMap.removeAll()
    WYDrawRectCacheMap.removeAll()
    WYHooksLock.unlock()
    
    // 清除所有已记录的关联对象标记，并清空集合
    WYExchangedMethodsLock.lock()
    let allSwizzleKeys = WYExchangedMethodsSet
    WYExchangedMethodsSet.removeAll()
    WYExchangedMethodsLock.unlock()
    
    // 遍历 WYExchangedMethodsSet 中的每个 swizzleKey，解析出类并清除标记
    for swizzleKey in allSwizzleKeys {
        // 提取 className（第一个下划线后的部分）(swizzleKey 格式： "wy_<className>_<selName>_swizzled")
        let parts = swizzleKey.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false)
        if parts.count >= 2 {
            let className = String(parts[1])
            // 通过类名字符串获取类对象
            if let targetClass = NSClassFromString(className) {
                // 清除关联对象标记
                objc_setAssociatedObject(targetClass, swizzleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
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

/// 缓存 wy_findHooks 的结果（key: "wy_cache_hook_<className>_<selName>"）
private var WYHooksCacheMap: [String: Any] = [:]

/// 独立存储 hitTest 的 intercept 闭包（返回 WYHitTestDecision）
private var WYHitTestInterceptMap: [String: (UIView, CGPoint, UIEvent?) -> WYHitTestDecision] = [:]

/// 缓存 wy_findHitTestIntercept 的结果（key: "wy_cache_hitTest_<className>_<selName>"）
private var WYHitTestCacheMap: [String: (UIView, CGPoint, UIEvent?) -> WYHitTestDecision] = [:]

/// 独立存储 drawRect 的 intercept 闭包（返回 WYDrawRectDecision）
private var WYDrawRectInterceptMap: [String: (UILabel, CGRect) -> WYDrawRectDecision] = [:]

/// 缓存 wy_findDrawRectIntercept 的结果（key: "wy_cache_drawRect_<className>_<selName>"）
private var WYDrawRectCacheMap: [String: (UILabel, CGRect) -> WYDrawRectDecision] = [:]

/// 记录哪些交换函数的 swizzleKey 已经被执行过（用于容错处理）
private var WYExchangedMethodsSet: Set<String> = []

/// 保护 WYExchangedMethodsSet 的线程锁
private let WYExchangedMethodsLock = NSLock()

/**
 获取指定类的实例方法，若方法不存在则输出错误信息并返回 nil。
 
 - Parameters:
   - targetClass: 目标类
   - selector: 方法选择器
 - Returns: 找到的 Method 对象，如果不存在则返回 nil
 */
private func wy_getInstanceMethod(_ targetClass: AnyClass, _ selector: Selector) -> Method? {
    guard let method = class_getInstanceMethod(targetClass, selector) else {
        #if DEBUG
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        #else
        wy_print("WYMethodExchangeCenter: 方法不存在 \(NSStringFromSelector(selector))", outputMode: .alwaysConsoleOnly)
        #endif
        return nil
    }
    return method
}

/**
 沿继承链查找指定选择器的钩子集合
 
 - Parameters:
   - receiver: 当前对象
   - selector: 方法选择器
 - Returns: 找到的第一个非空钩子集合，若未找到则返回空集合
 */
private func wy_findHooks<Args, Return>(for receiver: AnyObject, selector: Selector) -> WYMethodHooks<Args, Return> {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_hook_<类名>_<方法名>
        let cacheKey = "wy_cache_hook_\(className)_\(selName)"
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYHooksCacheMap[cacheKey] as? WYMethodHooks<Args, Return> {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_hook_<类名>_<方法名>
        let key = "wy_hook_\(className)_\(selName)"
        WYHooksLock.lock()
        let hooks = WYHooksMap[key] as? WYMethodHooks<Args, Return>
        WYHooksLock.unlock()
        
        if let hooks = hooks {
            // 找到非空钩子，存入缓存并返回
            WYHooksLock.lock()
            WYHooksCacheMap[cacheKey] = hooks
            WYHooksLock.unlock()
            return hooks
        }
        // 未找到，继续向父类查找
        currentClass = class_getSuperclass(cls)
    }
    // 整个继承链都没有找到任何钩子，返回空集合
    return WYMethodHooks<Args, Return>()
}

/**
 沿继承链查找 hitTest 的 intercept 闭包
 
 - Parameters:
   - receiver: 当前视图
   - selector: hitTest 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
private func wy_findHitTestIntercept(for receiver: UIView, selector: Selector) -> ((UIView, CGPoint, UIEvent?) -> WYHitTestDecision)? {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        // 获取当前类的类名字符串
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_hitTest_<类名>_<方法名>
        let cacheKey = "wy_cache_hitTest_\(className)_\(selName)"
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYHitTestCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_intercept_hitTest_<类名>_<方法名>
        let key = "wy_intercept_hitTest_\(className)_\(selName)"
        // 加锁读取 intercept 字典
        WYHooksLock.lock()
        let intercept = WYHitTestInterceptMap[key]
        WYHooksLock.unlock()
        
        if let intercept = intercept {
            // 找到 intercept，存入缓存并返回
            WYHooksLock.lock()
            WYHitTestCacheMap[cacheKey] = intercept
            WYHooksLock.unlock()
            return intercept
        }
        // 未找到，继续向父类查找
        currentClass = class_getSuperclass(cls)
    }
    // 整个继承链都没有找到任何 intercept 闭包，返回 nil
    return nil
}

/**
 沿继承链查找 drawRect 的 intercept 闭包
 
 - Parameters:
   - receiver: 当前视图
   - selector: drawRect 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
private func wy_findDrawRectIntercept(for receiver: UILabel, selector: Selector) -> ((UILabel, CGRect) -> WYDrawRectDecision)? {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链
    while let cls = currentClass, cls != NSObject.self {
        // 获取当前类的类名字符串
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_drawRect_<类名>_<方法名>
        let cacheKey = "wy_cache_drawRect_\(className)_\(selName)"
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYDrawRectCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_intercept_drawRect_<类名>_<方法名>
        let key = "wy_intercept_drawRect_\(className)_\(selName)"
        // 加锁读取 intercept 字典
        WYHooksLock.lock()
        let intercept = WYDrawRectInterceptMap[key]
        WYHooksLock.unlock()
        
        if let intercept = intercept {
            // 找到 intercept，存入缓存并返回
            WYHooksLock.lock()
            WYDrawRectCacheMap[cacheKey] = intercept
            WYHooksLock.unlock()
            return intercept
        }
        // 未找到，继续向父类查找
        currentClass = class_getSuperclass(cls)
    }
    // 整个继承链都没有找到任何 intercept 闭包，返回 nil
    return nil
}

/**
 对指定类的指定方法进行 IMP 替换（仅一次）
 
 - Parameters:
   - targetClass: 目标类
   - selector: 方法选择器
   - newImpBlock: 新的 Block IMP，类型为 @convention(block)
 */
private func wy_swizzleMethod(
    for targetClass: AnyClass,
    selector: Selector,
    newImpBlock: Any
) {
    // 使用对象锁，保证同一个类的方法交换线程安全
    objc_sync_enter(targetClass)
    defer { objc_sync_exit(targetClass) }
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 生成 swizzleKey，用于标记该方法是否已经交换过
    let swizzleKey = "wy_\(NSStringFromClass(targetClass))_\(NSStringFromSelector(selector))_swizzled"
    
    // 检查是否已经交换过
    if objc_getAssociatedObject(targetClass, swizzleKey) != nil { return }
    
    // 标记为已交换
    objc_setAssociatedObject(targetClass, swizzleKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    // 将 newImpBlock 转换为 IMP
    let newIMP = imp_implementationWithBlock(newImpBlock)
    // 替换原始方法的实现
    method_setImplementation(originalMethod, newIMP)
}

/**
 检查并清理异常的方法交换标记
 
 在调用某个交换函数时，如果该函数从未被执行过，
 但对应的关联对象 `swizzleKey` 已经存在（说明被意外提前设置），则强制清除该标记，
 以便后续的 `wy_swizzleMethod` 能够正常执行 IMP 替换。
 
 - Parameters:
   - targetClass: 目标类
   - selector: 方法选择器
 
 - Note: 此函数内部使用 `WYExchangedMethodsSet` 记录已经执行过交换的方法，
         并通过 `WYExchangedMethodsLock` 保证线程安全。
 */
private func wy_checkAndCleanSwizzleMark(for targetClass: AnyClass, selector: Selector) {
    
    let className = NSStringFromClass(targetClass)
    let selName = NSStringFromSelector(selector)
    let swizzleKey = "wy_\(className)_\(selName)_swizzled"
    
    // 判断当前方法是否已经被调用过
    WYExchangedMethodsLock.lock()
    let alreadyCalled = WYExchangedMethodsSet.contains(swizzleKey)
    WYExchangedMethodsLock.unlock()
    
    // 如果未被调用过，但关联对象标记意外存在则清除
    if !alreadyCalled, objc_getAssociatedObject(targetClass, swizzleKey) != nil {
        objc_setAssociatedObject(targetClass, swizzleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// 记录当前方法的 swizzleKey 已被调用，供容错函数检查
private func wy_remarkSwizzleKeyCalled(for targetClass: AnyClass, selector: Selector) {
    let className = NSStringFromClass(targetClass)
    let swizzleKey = "wy_\(className)_\(NSStringFromSelector(selector))_swizzled"
    WYExchangedMethodsLock.lock()
    WYExchangedMethodsSet.insert(swizzleKey)
    WYExchangedMethodsLock.unlock()
}
