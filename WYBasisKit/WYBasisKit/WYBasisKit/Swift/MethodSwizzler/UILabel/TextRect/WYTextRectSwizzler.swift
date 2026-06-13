//
//  WYTextRectSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `UILabel` 及其子类的 `textRect(forBounds:limitedToNumberOfLines:)` 方法。
 
 - Parameters:
   - targetClass: 目标 Label 类（如 `UILabel.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则继续执行原始方法；返回 `.result(rect)` 则直接返回该矩形，**不再调用原始方法**。参数依次为：当前标签、建议的边界矩形、最大行数。
   - before: 方法执行前回调。参数依次为：当前标签、建议的边界矩形、最大行数。无返回值。
   - after: 方法执行后回调。参数依次为：当前标签、建议的边界矩形、最大行数、原始返回值（`CGRect`）。可返回一个新的 `CGRect` 来替换原始返回值。
 */
internal func wy_swizzlerTextRect(
    for targetClass: UILabel.Type,
    intercept: ((_ currentLabel: UILabel, _ bounds: CGRect, _ numberOfLines: Int) -> WYInterceptResult<CGRect>)? = nil,
    before: ((_ currentLabel: UILabel, _ bounds: CGRect, _ numberOfLines: Int) -> Void)? = nil,
    after: ((_ currentLabel: UILabel, _ bounds: CGRect, _ numberOfLines: Int, _ originalResult: CGRect) -> CGRect)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UILabel.textRect(forBounds:limitedToNumberOfLines:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UILabel, Selector, CGRect, Int) -> CGRect
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Args = (CGRect, Int)
    typealias Return = CGRect
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
        hooks.before.append { anyLabel, _, args in
            guard let label = anyLabel as? UILabel else { return }
            before(label, args.0, args.1)
        }
    }
    
    // 如果用户提供了 after 闭包，则将其包装后添加到 hooks.after 数组
    if let after = after {
        hooks.after.append { anyLabel, _, args, original in
            guard let label = anyLabel as? UILabel else { return original }
            return after(label, args.0, args.1, original)
        }
    }
    
    // 将更新后的钩子集合写回 WYHooksMap
    WYHooksMap[key] = hooks
    
    // 解锁
    WYHooksLock.unlock()
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_textRect_<类名>_<方法名>
    let interceptKey = wy_methodSwizzlerKey(for: .textRectIntercept, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 存储 intercept 闭包到全局字典
    WYTextRectInterceptMap[interceptKey] = intercept
    
    // 解锁
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UILabel, CGRect, Int) -> CGRect = { receiver, bounds, numberOfLines in
        // 查找 intercept 决策（沿继承链，使用缓存）
        let foundIntercept = wy_findTextRectIntercept(for: receiver, selector: selector)
        
        // 如果存在 intercept 闭包，根据决策决定是否直接返回
        if let intercept = foundIntercept {
            switch intercept(receiver, bounds, numberOfLines) {
            case .result(let value):
                return value
            case .proceed:
                break
            }
        }
        
        // 获取钩子集合（before/after）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        let args = (bounds, numberOfLines)
        
        // 执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, args)
        }
        
        // 调用原始方法获取原始返回值
        let originalResult = originalBlock(receiver, selector, bounds, numberOfLines)
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
 沿继承链查找 textRect 的 intercept 闭包
 
 - Parameters:
   - receiver: 当前标签
   - selector: textRect 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
internal func wy_findTextRectIntercept(for receiver: UILabel, selector: Selector) -> ((UILabel, CGRect, Int) -> WYInterceptResult<CGRect>)? {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        // 获取当前类的类名字符串
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_textRect_<类名>_<方法名>
        let cacheKey = wy_methodSwizzlerKey(for: .textRectCache, className: className, selectorName: selName)
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYTextRectCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_intercept_textRect_<类名>_<方法名>
        let key = wy_methodSwizzlerKey(for: .textRectIntercept, className: className, selectorName: selName)
        
        // 加锁读取 intercept 字典
        WYHooksLock.lock()
        let intercept = WYTextRectInterceptMap[key]
        WYHooksLock.unlock()
        
        if let intercept = intercept {
            // 找到 intercept，存入缓存并返回
            WYHooksLock.lock()
            WYTextRectCacheMap[cacheKey] = intercept
            WYHooksLock.unlock()
            return intercept
        }
        // 未找到，继续向父类查找
        currentClass = class_getSuperclass(cls)
    }
    // 整个继承链都没有找到任何 intercept 闭包，返回 nil
    return nil
}

/// 独立存储 textRect 的 intercept 闭包
internal var WYTextRectInterceptMap: [String: (UILabel, CGRect, Int) -> WYInterceptResult<CGRect>] = [:]

/// 缓存 wy_findTextRectIntercept 的结果
internal var WYTextRectCacheMap: [String: (UILabel, CGRect, Int) -> WYInterceptResult<CGRect>] = [:]
