//
//  WYGestureRecognizerShouldBeginSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换遵循 `UIGestureRecognizerDelegate` 的对象的 `gestureRecognizerShouldBegin(_:)` 方法。
 
 - Parameters:
   - targetClass: 目标代理类（如 `MyViewController.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(shouldBegin)` 则直接返回该布尔值，**不再调用原始方法**。参数依次为：代理对象、手势识别器。
   - before: 方法执行前回调。参数依次为：代理对象、手势识别器。无返回值。
   - after: 方法执行后回调。参数依次为：代理对象、手势识别器、原始返回值（`Bool`）。可返回一个新的 `Bool` 来替换原始返回值。
 */
internal func wy_swizzlerGestureRecognizerShouldBegin(
    for targetClass: NSObject.Type,
    intercept: ((_ delegate: NSObject, _ gestureRecognizer: UIGestureRecognizer) -> WYInterceptResult<Bool>)? = nil,
    before: ((_ delegate: NSObject, _ gestureRecognizer: UIGestureRecognizer) -> Void)? = nil,
    after: ((_ delegate: NSObject, _ gestureRecognizer: UIGestureRecognizer, _ originalResult: Bool) -> Bool)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (NSObject, Selector, UIGestureRecognizer) -> Bool
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Args = UIGestureRecognizer
    typealias Return = Bool
    typealias Hooks = WYMethodHooks<Args, Return>
    
    // 将目标类转换为字符串，用于生成唯一键
    let className = NSStringFromClass(targetClass)
    
    // 生成存储钩子（before/after）的键，格式：wy_hook_<类名>_<方法名>
    let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: NSStringFromSelector(selector))
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_gestureRecognizerShouldBegin_<类名>_<方法名>
    let interceptKey = wy_methodSwizzlerKey(for: .gestureRecognizerShouldBeginIntercept, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 存储 intercept 闭包到全局字典
    WYGestureRecognizerShouldBeginInterceptMap[interceptKey] = intercept
    
    // 解锁
    WYHooksLock.unlock()
    
    // 加锁，准备操作钩子集合
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
    
    // 解锁
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (NSObject, UIGestureRecognizer) -> Bool = { receiver, gestureRecognizer in
        // 沿继承链查找 intercept 闭包
        var currentClass: AnyClass? = type(of: receiver)
        var foundIntercept: ((NSObject, UIGestureRecognizer) -> WYInterceptResult<Bool>)? = nil
        while let cls = currentClass, cls != NSObject.self {
            let className = NSStringFromClass(cls)
            // 生成 intercept 闭包的键
            let key = wy_methodSwizzlerKey(for: .gestureRecognizerShouldBeginIntercept, className: className, selectorName: NSStringFromSelector(selector))
            WYHooksLock.lock()
            let intercept = WYGestureRecognizerShouldBeginInterceptMap[key]
            WYHooksLock.unlock()
            if intercept != nil {
                foundIntercept = intercept
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        // 如果存在 intercept 闭包，根据决策决定是否直接返回
        if let intercept = foundIntercept {
            switch intercept(receiver, gestureRecognizer) {
            case .result(let value):
                return value
            case .proceed:
                break
            }
        }
        
        // 获取钩子集合（before/after）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, gestureRecognizer)
        }
        
        // 调用原始方法获取原始返回值
        let originalResult = originalBlock(receiver, selector, gestureRecognizer)
        var result = originalResult
        
        // 执行所有 after 闭包，允许修改返回值
        for after in hooks.after {
            result = after(receiver, selector, gestureRecognizer, result)
        }
        return result
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}

/// 独立存储 gestureRecognizerShouldBegin 的 intercept 闭包
internal var WYGestureRecognizerShouldBeginInterceptMap: [String: (NSObject, UIGestureRecognizer) -> WYInterceptResult<Bool>] = [:]
