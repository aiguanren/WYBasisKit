//
//  WYObserveValueSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `NSObject` 及其子类的 `observeValue(forKeyPath:of:change:context:)` 方法。
 
 - Parameters:
   - targetClass: 目标观察者类（如 `NSObject.self`）。
   - before: 方法执行前回调。参数依次为：观察者、键路径、被观察对象、变化字典、上下文指针。无返回值。
   - after: 方法执行后回调。参数依次为：观察者、键路径、被观察对象、变化字典、上下文指针。无返回值（仅通知）。
 */
internal func wy_swizzlerKVOObserve(
    for targetClass: NSObject.Type,
    before: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil,
    after: ((_ observer: NSObject, _ keyPath: String?, _ object: Any?, _ change: [NSKeyValueChangeKey : Any]?, _ context: UnsafeMutableRawPointer?) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(NSObject.observeValue(forKeyPath:of:change:context:))
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
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
    let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: NSStringFromSelector(selector))
    
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
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}
