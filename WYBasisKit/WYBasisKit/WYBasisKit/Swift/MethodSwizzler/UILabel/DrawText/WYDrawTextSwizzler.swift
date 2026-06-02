//
//  WYDrawTextSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `UILabel` 及其子类的 `drawText(in:)` 方法。
 
 - Parameters:
   - targetClass: 目标 Label 类（如 `UILabel.self`）。
   - intercept: 拦截决策闭包。返回 `.proceed` 则使用原始矩形；返回 `.result(rect)` 则使用新矩形进行绘制。参数依次为：当前标签、原始矩形。
   - before: 方法执行前观察闭包（仅在原始方法执行前调用）。参数依次为：当前标签、最终使用的矩形。无返回值。
   - after: 方法执行后回调。参数依次为：当前标签、最终使用的矩形。无返回值（仅通知）。
 */
internal func wy_swizzlerDrawText(
    for targetClass: UILabel.Type,
    intercept: ((_ currentLabel: UILabel, _ originalRect: CGRect) -> WYInterceptResult<CGRect>)? = nil,
    before: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil,
    after: ((_ currentLabel: UILabel, _ rect: CGRect) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UILabel.drawText(in:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
    // 检查目标类是否真的实现了该方法，防止传入错误的类
    guard let originalMethod = wy_getInstanceMethod(targetClass, selector) else { return }
    
    // 获取原始方法的 IMP（函数指针）
    let originalIMP = method_getImplementation(originalMethod)
    
    // 定义原始方法的 C 调用约定类型
    typealias OriginalFunc = @convention(c) (UILabel, Selector, CGRect) -> Void
    
    // 将 IMP 转换为可调用的 Swift 闭包 originalBlock
    let originalBlock = unsafeBitCast(originalIMP, to: OriginalFunc.self)
    
    // 定义钩子集合类型，用于存储 before/after 闭包
    typealias Args = CGRect
    typealias Return = Void
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
    
    // 解锁
    WYHooksLock.unlock()
    
    // 生成存储 intercept 闭包的键，格式：wy_intercept_drawText_<类名>_<方法名>
    let interceptKey = wy_methodSwizzlerKey(for: .drawTextIntercept, className: className, selectorName: NSStringFromSelector(selector))
    
    // 加锁，保证对全局字典的修改线程安全
    WYHooksLock.lock()
    
    // 存储 intercept 闭包到全局字典
    WYDrawTextInterceptMap[interceptKey] = intercept
    
    // 解锁
    WYHooksLock.unlock()
    
    // 构造新的方法实现（newBlock），该实现将替换原始方法
    let newBlock: @convention(block) (UILabel, CGRect) -> Void = { receiver, rect in
        // 查找 intercept 决策（沿继承链，使用缓存）
        let foundIntercept = wy_findDrawTextIntercept(for: receiver, selector: selector)
        
        // 如果存在 intercept 闭包，根据决策决定使用的矩形
        var finalRect = rect
        if let intercept = foundIntercept {
            switch intercept(receiver, rect) {
            case .result(let newRect):
                finalRect = newRect
            case .proceed:
                break
            }
        }
        
        // 获取钩子集合（before/after）
        let hooks: Hooks = wy_findHooks(for: receiver, selector: selector)
        
        // 执行所有 before 闭包
        for before in hooks.before {
            before(receiver, selector, finalRect)
        }
        
        // 调用原始方法
        originalBlock(receiver, selector, finalRect)
        
        // 执行所有 after 闭包
        for after in hooks.after {
            _ = after(receiver, selector, finalRect, ())
        }
    }
    
    // 执行真正的 method swizzling：将原始方法的实现替换为 newBlock
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: newBlock)
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}

/**
 沿继承链查找 drawText 的 intercept 闭包
 
 - Parameters:
   - receiver: 当前标签
   - selector: drawText 方法选择器
 - Returns: 找到的第一个 intercept 闭包，若未找到则返回 nil
 */
internal func wy_findDrawTextIntercept(for receiver: UILabel, selector: Selector) -> ((UILabel, CGRect) -> WYInterceptResult<CGRect>)? {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        // 获取当前类的类名字符串
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_drawText_<类名>_<方法名>
        let cacheKey = wy_methodSwizzlerKey(for: .drawTextCache, className: className, selectorName: selName)
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYDrawTextCacheMap[cacheKey] {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_intercept_drawText_<类名>_<方法名>
        let key = wy_methodSwizzlerKey(for: .drawTextIntercept, className: className, selectorName: selName)
        // 加锁读取 intercept 字典
        WYHooksLock.lock()
        let intercept = WYDrawTextInterceptMap[key]
        WYHooksLock.unlock()
        
        if let intercept = intercept {
            // 找到 intercept，存入缓存并返回
            WYHooksLock.lock()
            WYDrawTextCacheMap[cacheKey] = intercept
            WYHooksLock.unlock()
            return intercept
        }
        // 未找到，继续向父类查找
        currentClass = class_getSuperclass(cls)
    }
    // 整个继承链都没有找到任何 intercept 闭包，返回 nil
    return nil
}

/// 独立存储 drawText 的 intercept 闭包
internal var WYDrawTextInterceptMap: [String: (UILabel, CGRect) -> WYInterceptResult<CGRect>] = [:]

/// 缓存 wy_findDrawTextIntercept 的结果
internal var WYDrawTextCacheMap: [String: (UILabel, CGRect) -> WYInterceptResult<CGRect>] = [:]
