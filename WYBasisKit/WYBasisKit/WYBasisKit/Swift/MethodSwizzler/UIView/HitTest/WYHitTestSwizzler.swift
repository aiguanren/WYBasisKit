//
//  WYHitTestSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `UIView` 及其子类的 `hitTest(_:with:)` 方法。
 
 - Parameters:
   - targetClass: 目标视图类（如 `UIView.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(view)` 则直接返回该视图（可为 `nil`），**不再调用原始方法**。参数依次为：当前视图、点击位置、事件。
   - before: 方法执行前观察闭包（仅在原始方法执行前调用，不影响流程）。参数依次为：当前视图、点击位置、事件。无返回值。
   - after: 方法执行后回调，可修改原始返回值。参数依次为：当前视图、点击位置、事件、原始返回值（`UIView?`）。返回一个新的 `UIView?` 作为最终结果。
 */
internal func wy_swizzlerHitTest(
    for targetClass: UIView.Type,
    intercept: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> WYInterceptResult<UIView?>)? = nil,
    before: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?) -> Void)? = nil,
    after: ((_ currentView: UIView, _ point: CGPoint, _ event: UIEvent?, _ originalResult: UIView?) -> UIView?)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIView.hitTest(_:with:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UIView, Selector, CGPoint, UIEvent?) -> UIView?
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Args = (CGPoint, UIEvent?)
    typealias Return = UIView?
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，准备操作钩子集合
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
    
    // 解锁
    WYHooksLock.unlock()
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_hitTest_<类名>_<方法名>
    let interceptKey = wy_methodSwizzlerKey(for: .hitTestIntercept, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 存储 intercept 闭包到全局字典
    WYHitTestInterceptMap[interceptKey] = intercept
    
    // 解锁
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UIView, CGPoint, UIEvent?) -> UIView? = { receiver, point, event in
        // 查找 intercept 决策（沿继承链）
        var currentClass: AnyClass? = type(of: receiver)
        var foundIntercept: ((UIView, CGPoint, UIEvent?) -> WYInterceptResult<UIView?>)? = nil
        while let cls = currentClass, cls != NSObject.self {
            let className = NSStringFromClass(cls)
            // 生成 intercept 闭包的键
            let key = wy_methodSwizzlerKey(for: .hitTestIntercept, className: className, selectorName: NSStringFromSelector(selector))
            WYHooksLock.lock()
            let intercept = WYHitTestInterceptMap[key]
            WYHooksLock.unlock()
            if intercept != nil {
                foundIntercept = intercept
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        // 如果存在 intercept 闭包，根据决策决定是否直接返回
        if let intercept = foundIntercept {
            switch intercept(receiver, point, event) {
            case .result(let view):
                return view
            case .proceed:
                break
            }
        }
        
        // 获取钩子集合（before/after）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (point, event)
        
        // 执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法获取原始返回值
        let originalResult = originalBlock(receiver, selector, point, event)
        var result = originalResult
        
        // 执行所有 after 闭包，允许修改返回值
        for after in hooks.after {
            result = after(receiver, selector, args, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}

/**
 沿继承链查找 hitTest 的 intercept 闭包
 
 - Parameters:
   - receiver: 当前视图
   - selector: hitTest 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
internal func wy_findHitTestIntercept(for receiver: UIView, selector: Selector) -> ((UIView, CGPoint, UIEvent?) -> WYInterceptResult<UIView?>)? {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        // 获取当前类的类名字符串
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_hitTest_<类名>_<方法名>
        let cacheKey = wy_methodSwizzlerKey(for: .hitTestCache, className: className, selectorName: selName)
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYHitTestCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_intercept_hitTest_<类名>_<方法名>
        let key = wy_methodSwizzlerKey(for: .hitTestIntercept, className: className, selectorName: selName)
        
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

/// 独立存储 hitTest 的 intercept 闭包（返回 WYHitTestDecision）
internal var WYHitTestInterceptMap: [String: (UIView, CGPoint, UIEvent?) -> WYInterceptResult<UIView?>] = [:]

/// 缓存 wy_findHitTestIntercept 的结果（key: "wy_cache_hitTest_<className>_<selName>"）
internal var WYHitTestCacheMap: [String: (UIView, CGPoint, UIEvent?) -> WYInterceptResult<UIView?>] = [:]
