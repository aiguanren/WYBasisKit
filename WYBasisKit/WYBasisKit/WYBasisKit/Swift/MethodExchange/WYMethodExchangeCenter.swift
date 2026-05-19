//
//  WYMethodExchangeCenter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/19.
//

import UIKit

/**
 移除指定类的指定方法的钩子（before 和 after）。
 
 - Parameters:
   - anyClass: 目标类
   - selector: 方法选择器。若传入 nil，则移除该类的所有钩子（所有方法）；若指定 selector，则只移除该方法的钩子。
 */
public func wy_removeHooks(for anyClass: AnyClass, selector: Selector? = nil) {
    let prefix = "wy_\(String(describing: anyClass))_"
    WYHooksLock.lock()
    if let selector = selector {
        let key = prefix + NSStringFromSelector(selector)
        WYHooksMap[key] = nil
    } else {
        let keysToRemove = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            WYHooksMap[key] = nil
        }
    }
    WYHooksLock.unlock()
}

/**
 present(_:animated:completion:) 方法交换（UIViewController 及其子类）
 
 - Parameters:
   - viewControllerClass: 目标视图控制器类（如 UIViewController.self）
   - before: 方法执行前回调。参数依次为：当前控制器、被 present 的控制器、是否动画、完成闭包。无返回值。
   - after: 方法执行后回调。参数同上，无返回值（仅通知）。
 */
public func wy_exchangeControllerPresent(
    for viewControllerClass: UIViewController.Type,
    before: ((UIViewController, UIViewController, Bool, (() -> Void)?) -> Void)? = nil,
    after: ((UIViewController, UIViewController, Bool, (() -> Void)?) -> Void)? = nil
) {
    let selector = #selector(UIViewController.present(_:animated:completion:))
    let key = "wy_\(String(describing: viewControllerClass))_\(NSStringFromSelector(selector))"
    typealias Args = (UIViewController, Bool, (() -> Void)?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(viewControllerClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 hitTest(_:with:) 方法交换
 
 - Parameters:
   - viewClass: 目标视图类（如 UIView.self）
   - before: 方法执行前回调。参数依次为：当前视图、点击位置、事件。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、点击位置、事件、原始返回值（UIView?）。可返回一个新的 UIView? 来替换原始返回值。
 */
public func wy_exchangeHitTest(
    for viewClass: UIView.Type,
    before: ((UIView, CGPoint, UIEvent?) -> Void)? = nil,
    after: ((UIView, CGPoint, UIEvent?, UIView?) -> UIView?)? = nil
) {
    let selector = #selector(UIView.hitTest(_:with:))
    let key = "wy_\(String(describing: viewClass))_\(NSStringFromSelector(selector))"
    typealias Args = (CGPoint, UIEvent?)
    typealias Return = UIView?
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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

    let newBlock: @convention(block) (UIView, CGPoint, UIEvent?) -> UIView? = { receiver, point, event in
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 layoutSubviews() 方法交换
 
 - Parameters:
   - viewClass: 目标视图类（如 UIView.self）
   - before: 方法执行前回调。参数为当前视图。无返回值。
   - after: 方法执行后回调。参数为当前视图。无返回值（仅通知）。
 */
public func wy_exchangeLayoutSubviews(
    for viewClass: UIView.Type,
    before: ((UIView) -> Void)? = nil,
    after: ((UIView) -> Void)? = nil
) {
    let selector = #selector(UIView.layoutSubviews)
    let key = "wy_\(String(describing: viewClass))_\(NSStringFromSelector(selector))"
    typealias Args = Void
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 sizeThatFits(_:) 方法交换
 
 - Parameters:
   - viewClass: 目标视图类（如 UIView.self）
   - before: 方法执行前回调。参数依次为：当前视图、建议的尺寸。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、建议的尺寸、原始返回值（CGSize）。可返回一个新的 CGSize 来替换原始返回值。
 */
public func wy_exchangeSizeThatFits(
    for viewClass: UIView.Type,
    before: ((UIView, CGSize) -> Void)? = nil,
    after: ((UIView, CGSize, CGSize) -> CGSize)? = nil
) {
    let selector = #selector(UIView.sizeThatFits(_:))
    let key = "wy_\(String(describing: viewClass))_\(NSStringFromSelector(selector))"
    typealias Args = CGSize
    typealias Return = CGSize
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 touchesBegan(_:with:) 方法交换
 
 - Parameters:
   - responderClass: 目标响应者类（如 UIView.self）
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数同上。无返回值（仅通知）。
 */
public func wy_exchangeTouchesBegan(
    for responderClass: UIResponder.Type,
    before: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil,
    after: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesBegan(_:with:))
    let key = "wy_\(String(describing: responderClass))_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 touchesCancelled(_:with:) 方法交换
 
 - Parameters:
   - responderClass: 目标响应者类（如 UIView.self）
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数同上。无返回值（仅通知）。
 */
public func wy_exchangeTouchesCancelled(
    for responderClass: UIResponder.Type,
    before: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil,
    after: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesCancelled(_:with:))
    let key = "wy_\(String(describing: responderClass))_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 touchesEnded(_:with:) 方法交换
 
 - Parameters:
   - responderClass: 目标响应者类（如 UIView.self）
   - before: 方法执行前回调。参数依次为：当前响应者、触摸集合、事件。无返回值。
   - after: 方法执行后回调。参数同上。无返回值（仅通知）。
 */
public func wy_exchangeTouchesEnded(
    for responderClass: UIResponder.Type,
    before: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil,
    after: ((UIResponder, Set<UITouch>, UIEvent?) -> Void)? = nil
) {
    let selector = #selector(UIResponder.touchesEnded(_:with:))
    let key = "wy_\(String(describing: responderClass))_\(NSStringFromSelector(selector))"
    typealias Args = (Set<UITouch>, UIEvent?)
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(responderClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 drawText(in:) 方法交换（UILabel 及其子类）
 
 - Parameters:
   - labelClass: 目标Label类（如 UILabel.self）
   - before: 方法执行前回调。参数依次为：当前标签、绘制区域矩形。无返回值。
   - after: 方法执行后回调。参数同上。无返回值（仅通知）。
 */
public func wy_exchangeDrawText(
    for labelClass: UILabel.Type,
    before: ((UILabel, CGRect) -> Void)? = nil,
    after: ((UILabel, CGRect) -> Void)? = nil
) {
    let selector = #selector(UILabel.drawText(in:))
    let key = "wy_\(String(describing: labelClass))_\(NSStringFromSelector(selector))"
    typealias Args = CGRect
    typealias Return = Void
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(labelClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
 intrinsicContentSize 属性 getter 方法交换（UIView 及其子类）
 
 - Parameters:
   - viewClass: 目标视图类（如 UIView.self）
   - before: 方法执行前回调。参数为当前视图。无返回值。
   - after: 方法执行后回调。参数依次为：当前视图、原始返回值（CGSize）。可返回一个新的 CGSize 来替换原始返回值。
 */
public func wy_exchangeIntrinsicContentSize(
    for viewClass: UIView.Type,
    before: ((UIView) -> Void)? = nil,
    after: ((UIView, CGSize) -> CGSize)? = nil
) {
    let selector = #selector(getter: UIView.intrinsicContentSize)
    let key = "wy_\(String(describing: viewClass))_\(NSStringFromSelector(selector))"
    typealias Args = Void
    typealias Return = CGSize
    typealias Hooks = WYMethodHooks<Args, Return>

    guard let originalMethod = class_getInstanceMethod(viewClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
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
        // 沿继承链向上查找 hooks
        var currentClass: AnyClass? = type(of: receiver)
        var foundHooks: Hooks? = nil
        while let cls = currentClass, cls != NSObject.self {
            let classKey = "wy_\(String(describing: cls))_\(NSStringFromSelector(selector))"
            WYHooksLock.lock()
            let hooks = (WYHooksMap[classKey] as? Hooks)
            WYHooksLock.unlock()
            if hooks != nil {
                foundHooks = hooks
                break
            }
            currentClass = class_getSuperclass(cls)
        }
        
        let hooks = foundHooks ?? Hooks()
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
struct WYMethodHooks<Args, Return> {

    /// 方法执行前的回调数组
    var before: [(Any, Selector, Args) -> Void] = []

    /// 方法执行后的回调数组，可修改返回值
    var after: [(Any, Selector, Args, Return) -> Return] = []
}

/// 全局钩子存储容器（值类型为 Any，实际使用时转型）
private var WYHooksMap: [String: Any] = [:]

/// 保护钩子容器的线程锁
private let WYHooksLock = NSLock()

/**
 对指定类的指定方法进行 IMP 替换（仅一次）
 - Parameters:
   - anyClass: 目标类
   - selector: 方法选择器
   - newImpBlock: 新的 Block IMP，类型为 @convention(block)
 */
func wy_swizzleMethod(
    for anyClass: AnyClass,
    selector: Selector,
    newImpBlock: Any
) {
    let swizzleKey = "wy_\(String(describing: anyClass))_\(NSStringFromSelector(selector))_swizzled"
    objc_sync_enter(anyClass)
    defer { objc_sync_exit(anyClass) }

    // 已交换过则直接返回
    if objc_getAssociatedObject(anyClass, swizzleKey) != nil { return }
    objc_setAssociatedObject(anyClass, swizzleKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    guard let originalMethod = class_getInstanceMethod(anyClass, selector) else {
        assertionFailure("方法不存在: \(NSStringFromSelector(selector))")
        return
    }

    let newIMP = imp_implementationWithBlock(newImpBlock)
    method_setImplementation(originalMethod, newIMP)
}
