//
//  WYViewDidLoadSwizzler.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/29.
//

import UIKit

/**
 交换 `UIViewController` 及其子类的 `viewDidLoad()` 方法。
 
 - Parameters:
   - targetClass: 目标视图控制器类（如 `UIViewController.self`）。
   - before: 方法执行前回调。参数为当前控制器。无返回值。
   - after: 方法执行后回调。参数为当前控制器。无返回值（仅通知）。
 */
internal func wy_swizzlerViewDidLoad(
    for targetClass: UIViewController.Type,
    before: ((_ currentController: UIViewController) -> Void)? = nil,
    after: ((_ currentController: UIViewController) -> Void)? = nil
) {
    // 获取要交换的方法选择器
    let selector = #selector(UIViewController.viewDidLoad)
    
    // 容错处理，清除可能存在的异常标记
    wy_checkAndCleanSwizzleMark(for: targetClass, selector: selector)
    
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
    let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: NSStringFromSelector(selector))
    
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
    
    // 记录当前方法的 swizzleKey 已被调用，供容错函数检查
    wy_remarkSwizzleKeyCalled(for: targetClass, selector: selector)
}
