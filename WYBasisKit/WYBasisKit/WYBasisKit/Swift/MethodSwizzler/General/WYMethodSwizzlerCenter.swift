//
//  WYMethodSwizzlerCenter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/19.
//

import UIKit

/// 拦截决策（用于有返回值的方法）
internal enum WYInterceptResult<Value> {
    /// 继续执行原始交换方法
    case proceed
    /// 直接返回指定的值（可以是 nil），不再调用原始方法
    case result(Value)
}

/**
 移除指定类的指定方法的钩子（包括 before、after 和 intercept）。
 
 - Parameters:
   - anyClass: 目标类。
   - selector: 方法选择器。若传入 `nil`，则移除该类的所有钩子（所有方法）；若指定 `selector`，则只移除该方法的钩子。
 */
internal func wy_removeMethodExchangeHooks(for anyClass: AnyClass, selector: Selector? = nil) {
    
    // 将目标类转换为字符串，用于生成各种键的前缀
    let className = NSStringFromClass(anyClass)
    
    // WYHooksMap 前缀
    let prefix = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: "")
    // WYHitTestInterceptMap 前缀
    let hitTestInterceptPrefix = wy_methodSwizzlerKey(for: .hitTestIntercept, className: className)
    // WYInterceptPopMap 前缀
    let interceptPopPrefix = wy_methodSwizzlerKey(for: .popIntercept, className: className)
    // WYDrawRectInterceptMap 前缀
    let drawRectInterceptPrefix = wy_methodSwizzlerKey(for: .drawRectIntercept, className: className)
    // WYDrawRectCacheMap 前缀
    let drawRectCachePrefix = wy_methodSwizzlerKey(for: .drawRectCache, className: className)
    // WYDrawTextInterceptMap 前缀
    let drawTextInterceptPrefix = wy_methodSwizzlerKey(for: .drawTextIntercept, className: className)
    // WYDrawTextCacheMap 前缀
    let drawTextCachePrefix = wy_methodSwizzlerKey(for: .drawTextCache, className: className)
    // WYTextRectInterceptMap 前缀
    let textRectInterceptPrefix = wy_methodSwizzlerKey(for: .textRectIntercept, className: className)
    // WYTextRectCacheMap 前缀
    let textRectCachePrefix = wy_methodSwizzlerKey(for: .textRectCache, className: className)
    // WYSizeThatFitsInterceptMap 前缀
    let sizeThatFitsInterceptPrefix = wy_methodSwizzlerKey(for: .sizeThatFitsIntercept, className: className)
    // WYIntrinsicContentSizeInterceptMap 前缀
    let intrinsicContentSizeInterceptPrefix = wy_methodSwizzlerKey(for: .intrinsicContentSizeIntercept, className: className)
    // WYLayoutAttributesForElementsInterceptMap 前缀
    let layoutAttributesForElementsInterceptPrefix = wy_methodSwizzlerKey(for: .layoutAttributesForElementsIntercept, className: className)
    // WYLayoutAttributesForItemInterceptMap 前缀
    let layoutAttributesForItemInterceptPrefix = wy_methodSwizzlerKey(for: .layoutAttributesForItemIntercept, className: className)
    // WYLayoutAttributesForSupplementaryViewInterceptMap 前缀
    let layoutAttributesForSupplementaryViewInterceptPrefix = wy_methodSwizzlerKey(for: .layoutAttributesForSupplementaryViewIntercept, className: className)
    // WYCollectionViewContentSizeInterceptMap 前缀
    let collectionViewContentSizeInterceptPrefix = wy_methodSwizzlerKey(for: .collectionViewContentSizeIntercept, className: className)
    // WYShouldInvalidateLayoutInterceptMap 前缀
    let shouldInvalidateLayoutInterceptPrefix = wy_methodSwizzlerKey(for: .shouldInvalidateLayoutIntercept, className: className)
    // WYGestureRecognizerShouldBeginInterceptMap 前缀
    let gestureRecognizerShouldBeginInterceptPrefix = wy_methodSwizzlerKey(for: .gestureRecognizerShouldBeginIntercept, className: className)
    
    // 缓存前缀（用于清除缓存）
    let hookCachePrefix = wy_methodSwizzlerKey(for: .hookCache, className: className, selectorName: "")
    let hitTestCachePrefix = wy_methodSwizzlerKey(for: .hitTestCache, className: className, selectorName: "")
    
    // 加锁，保证线程安全
    WYHooksLock.lock()
    
    if let selector = selector {
        // 指定了 selector：只移除该方法的钩子
        let selName = NSStringFromSelector(selector)
        
        // 清除 before/after 钩子存储
        let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: selName)
        WYHooksMap[key] = nil
        
        // 清除 hitTest 的 intercept 闭包存储
        let hitTestInterceptKey = wy_methodSwizzlerKey(for: .hitTestIntercept, className: className, selectorName: selName)
        WYHitTestInterceptMap[hitTestInterceptKey] = nil
        
        // 清除 popViewController 的 intercept 闭包存储
        let interceptPopKey = wy_methodSwizzlerKey(for: .popIntercept, className: className, selectorName: selName)
        WYInterceptPopMap[interceptPopKey] = nil
        
        // 清除 drawRect 的 intercept 闭包存储和对应的缓存
        let drawRectInterceptKey = wy_methodSwizzlerKey(for: .drawRectIntercept, className: className, selectorName: selName)
        WYDrawRectInterceptMap[drawRectInterceptKey] = nil
        let drawRectCacheKey = wy_methodSwizzlerKey(for: .drawRectCache, className: className, selectorName: selName)
        WYDrawRectCacheMap[drawRectCacheKey] = nil
        
        // 清除 drawText 的 intercept 闭包存储和对应的缓存
        let drawTextInterceptKey = wy_methodSwizzlerKey(for: .drawTextIntercept, className: className, selectorName: selName)
        WYDrawTextInterceptMap[drawTextInterceptKey] = nil
        let drawTextCacheKey = wy_methodSwizzlerKey(for: .drawTextCache, className: className, selectorName: selName)
        WYDrawTextCacheMap[drawTextCacheKey] = nil
        
        // 清除 textRect 的 intercept 闭包存储和对应的缓存
        let textRectInterceptKey = wy_methodSwizzlerKey(for: .textRectIntercept, className: className, selectorName: selName)
        WYTextRectInterceptMap[textRectInterceptKey] = nil
        let textRectCacheKey = wy_methodSwizzlerKey(for: .textRectCache, className: className, selectorName: selName)
        WYTextRectCacheMap[textRectCacheKey] = nil
        
        // 清除 sizeThatFits intercept 闭包存储
        let sizeThatFitsInterceptKey = wy_methodSwizzlerKey(for: .sizeThatFitsIntercept, className: className, selectorName: selName)
        WYSizeThatFitsInterceptMap[sizeThatFitsInterceptKey] = nil
        
        // 清除 intrinsicContentSize intercept 闭包存储
        let intrinsicContentSizeInterceptKey = wy_methodSwizzlerKey(for: .intrinsicContentSizeIntercept, className: className, selectorName: selName)
        WYIntrinsicContentSizeInterceptMap[intrinsicContentSizeInterceptKey] = nil
        
        // 清除 layoutAttributesForElements intercept 闭包存储
        let layoutAttributesForElementsInterceptKey = wy_methodSwizzlerKey(for: .layoutAttributesForElementsIntercept, className: className, selectorName: selName)
        WYLayoutAttributesForElementsInterceptMap[layoutAttributesForElementsInterceptKey] = nil
        
        // 清除 layoutAttributesForItem intercept 闭包存储
        let layoutAttributesForItemInterceptKey = wy_methodSwizzlerKey(for: .layoutAttributesForItemIntercept, className: className, selectorName: selName)
        WYLayoutAttributesForItemInterceptMap[layoutAttributesForItemInterceptKey] = nil
        
        // 清除 layoutAttributesForSupplementaryView intercept 闭包存储
        let layoutAttributesForSupplementaryViewInterceptKey = wy_methodSwizzlerKey(for: .layoutAttributesForSupplementaryViewIntercept, className: className, selectorName: selName)
        WYLayoutAttributesForSupplementaryViewInterceptMap[layoutAttributesForSupplementaryViewInterceptKey] = nil
        
        // 清除 collectionViewContentSize intercept 闭包存储
        let collectionViewContentSizeInterceptKey = wy_methodSwizzlerKey(for: .collectionViewContentSizeIntercept, className: className, selectorName: selName)
        WYCollectionViewContentSizeInterceptMap[collectionViewContentSizeInterceptKey] = nil
        
        // 清除 shouldInvalidateLayout intercept 闭包存储
        let shouldInvalidateLayoutInterceptKey = wy_methodSwizzlerKey(for: .shouldInvalidateLayoutIntercept, className: className, selectorName: selName)
        WYShouldInvalidateLayoutInterceptMap[shouldInvalidateLayoutInterceptKey] = nil
        
        // 清除 gestureRecognizerShouldBegin intercept 闭包存储
        let gestureRecognizerShouldBeginInterceptKey = wy_methodSwizzlerKey(for: .gestureRecognizerShouldBeginIntercept, className: className, selectorName: selName)
        WYGestureRecognizerShouldBeginInterceptMap[gestureRecognizerShouldBeginInterceptKey] = nil
        
        // 清除通用缓存（findHooks 和 findHitTestIntercept 使用）
        let cacheKey = wy_methodSwizzlerKey(for: .hookCache, className: className, selectorName: selName)
        WYHooksCacheMap[cacheKey] = nil
        let hitTestCacheKey = wy_methodSwizzlerKey(for: .hitTestCache, className: className, selectorName: selName)
        WYHitTestCacheMap[hitTestCacheKey] = nil
        
        // 清除由 wy_swizzleMethod 设置的关联对象标记（防止再次交换时被跳过）
        let swizzleKey = wy_methodSwizzlerKey(for: .swizzledMark, className: className, selectorName: selName)
        objc_setAssociatedObject(anyClass, swizzleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 从已调用记录集合中移除该 swizzleKey，以便后续重新注册
        WYExchangedMethodsLock.lock()
        WYExchangedMethodsSet.remove(swizzleKey)
        WYExchangedMethodsLock.unlock()
        
    } else {
        // selector 为 nil，表示移除该类的所有方法钩子
        
        // 清除该类所有方法的 before/after 钩子存储
        let keysToRemove = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            WYHooksMap[key] = nil
        }
        
        // 清除该类所有 hitTest intercept 闭包存储
        let hitTestInterceptKeysToRemove = WYHitTestInterceptMap.keys.filter { $0.hasPrefix(hitTestInterceptPrefix) }
        for key in hitTestInterceptKeysToRemove {
            WYHitTestInterceptMap[key] = nil
        }
        
        // 清除该类所有 popViewController intercept 闭包存储
        let interceptPopKeysToRemove = WYInterceptPopMap.keys.filter { $0.hasPrefix(interceptPopPrefix) }
        for key in interceptPopKeysToRemove {
            WYInterceptPopMap[key] = nil
        }
        
        // 清除该类所有 drawRect intercept 闭包存储和对应的缓存
        let drawRectInterceptKeysToRemove = WYDrawRectInterceptMap.keys.filter { $0.hasPrefix(drawRectInterceptPrefix) }
        for key in drawRectInterceptKeysToRemove {
            WYDrawRectInterceptMap[key] = nil
        }
        let drawRectCacheKeysToRemove = WYDrawRectCacheMap.keys.filter { $0.hasPrefix(drawRectCachePrefix) }
        for key in drawRectCacheKeysToRemove {
            WYDrawRectCacheMap[key] = nil
        }
        
        // 清除该类所有 drawText intercept 闭包存储和对应的缓存
        let drawTextInterceptKeysToRemove = WYDrawTextInterceptMap.keys.filter { $0.hasPrefix(drawTextInterceptPrefix) }
        for key in drawTextInterceptKeysToRemove {
            WYDrawTextInterceptMap[key] = nil
        }
        let drawTextCacheKeysToRemove = WYDrawTextCacheMap.keys.filter { $0.hasPrefix(drawTextCachePrefix) }
        for key in drawTextCacheKeysToRemove {
            WYDrawTextCacheMap[key] = nil
        }
        
        // 清除该类所有 textRect intercept 闭包存储和对应的缓存
        let textRectInterceptKeysToRemove = WYTextRectInterceptMap.keys.filter { $0.hasPrefix(textRectInterceptPrefix) }
        for key in textRectInterceptKeysToRemove {
            WYTextRectInterceptMap[key] = nil
        }
        let textRectCacheKeysToRemove = WYTextRectCacheMap.keys.filter { $0.hasPrefix(textRectCachePrefix) }
        for key in textRectCacheKeysToRemove {
            WYTextRectCacheMap[key] = nil
        }
        
        // 清除该类所有 sizeThatFits intercept 闭包存储
        let sizeThatFitsInterceptKeysToRemove = WYSizeThatFitsInterceptMap.keys.filter { $0.hasPrefix(sizeThatFitsInterceptPrefix) }
        for key in sizeThatFitsInterceptKeysToRemove {
            WYSizeThatFitsInterceptMap[key] = nil
        }
        
        // 清除该类所有 intrinsicContentSize intercept 闭包存储
        let intrinsicContentSizeInterceptKeysToRemove = WYIntrinsicContentSizeInterceptMap.keys.filter { $0.hasPrefix(intrinsicContentSizeInterceptPrefix) }
        for key in intrinsicContentSizeInterceptKeysToRemove {
            WYIntrinsicContentSizeInterceptMap[key] = nil
        }
        
        // 清除该类所有 layoutAttributesForElements intercept 闭包存储
        let layoutAttributesForElementsInterceptKeysToRemove = WYLayoutAttributesForElementsInterceptMap.keys.filter { $0.hasPrefix(layoutAttributesForElementsInterceptPrefix) }
        for key in layoutAttributesForElementsInterceptKeysToRemove {
            WYLayoutAttributesForElementsInterceptMap[key] = nil
        }
        
        // 清除该类所有 layoutAttributesForItem intercept 闭包存储
        let layoutAttributesForItemInterceptKeysToRemove = WYLayoutAttributesForItemInterceptMap.keys.filter { $0.hasPrefix(layoutAttributesForItemInterceptPrefix) }
        for key in layoutAttributesForItemInterceptKeysToRemove {
            WYLayoutAttributesForItemInterceptMap[key] = nil
        }
        
        // 清除该类所有 layoutAttributesForSupplementaryView intercept 闭包存储
        let layoutAttributesForSupplementaryViewInterceptKeysToRemove = WYLayoutAttributesForSupplementaryViewInterceptMap.keys.filter { $0.hasPrefix(layoutAttributesForSupplementaryViewInterceptPrefix) }
        for key in layoutAttributesForSupplementaryViewInterceptKeysToRemove {
            WYLayoutAttributesForSupplementaryViewInterceptMap[key] = nil
        }
        
        // 清除该类所有 collectionViewContentSize intercept 闭包存储
        let collectionViewContentSizeInterceptKeysToRemove = WYCollectionViewContentSizeInterceptMap.keys.filter { $0.hasPrefix(collectionViewContentSizeInterceptPrefix) }
        for key in collectionViewContentSizeInterceptKeysToRemove {
            WYCollectionViewContentSizeInterceptMap[key] = nil
        }
        
        // 清除该类所有 shouldInvalidateLayout intercept 闭包存储
        let shouldInvalidateLayoutInterceptKeysToRemove = WYShouldInvalidateLayoutInterceptMap.keys.filter { $0.hasPrefix(shouldInvalidateLayoutInterceptPrefix) }
        for key in shouldInvalidateLayoutInterceptKeysToRemove {
            WYShouldInvalidateLayoutInterceptMap[key] = nil
        }
        
        // 清除该类所有 gestureRecognizerShouldBegin intercept 闭包存储
        let gestureRecognizerShouldBeginInterceptKeysToRemove = WYGestureRecognizerShouldBeginInterceptMap.keys.filter { $0.hasPrefix(gestureRecognizerShouldBeginInterceptPrefix) }
        for key in gestureRecognizerShouldBeginInterceptKeysToRemove {
            WYGestureRecognizerShouldBeginInterceptMap[key] = nil
        }
        
        // 清除该类所有方法的通用缓存（findHooks 和 findHitTestIntercept 使用）
        let cacheKeysToRemove = WYHooksCacheMap.keys.filter { $0.hasPrefix(hookCachePrefix) }
        for key in cacheKeysToRemove {
            WYHooksCacheMap[key] = nil
        }
        let hitTestCacheKeysToRemove = WYHitTestCacheMap.keys.filter { $0.hasPrefix(hitTestCachePrefix) }
        for key in hitTestCacheKeysToRemove {
            WYHitTestCacheMap[key] = nil
        }
        
        // 清除该类所有方法的关联对象标记并移除集合记录(需要从 WYHooksMap 的 keys 中获取已注册的方法名（key 格式为 "wy_hook_<className>_<selName>"）)
        let allMethodKeys = WYHooksMap.keys.filter { $0.hasPrefix(prefix) }
        for methodKey in allMethodKeys {
            // 从完整 key 中提取 selName：去掉前缀 "wy_hook_<className>_"
            let hookPrefixFull = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: "")
            if let selName = methodKey.replacingOccurrences(of: hookPrefixFull, with: "").split(separator: "_").first {
                let selNameStr = String(selName)
                let swizzleKey = wy_methodSwizzlerKey(for: .swizzledMark, className: className, selectorName: selNameStr)
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

/// 移除所有类、所有方法的钩子
internal func wy_removeAllMethodExchangeHooks() {
    // 加锁，保证线程安全
    WYHooksLock.lock()
    // 清空所有存储字典
    WYHooksMap.removeAll()
    WYHitTestInterceptMap.removeAll()
    WYDrawRectInterceptMap.removeAll()
    WYDrawTextInterceptMap.removeAll()
    WYTextRectInterceptMap.removeAll()
    WYInterceptPopMap.removeAll()
    WYSizeThatFitsInterceptMap.removeAll()
    WYIntrinsicContentSizeInterceptMap.removeAll()
    WYLayoutAttributesForElementsInterceptMap.removeAll()
    WYLayoutAttributesForItemInterceptMap.removeAll()
    WYLayoutAttributesForSupplementaryViewInterceptMap.removeAll()
    WYCollectionViewContentSizeInterceptMap.removeAll()
    WYShouldInvalidateLayoutInterceptMap.removeAll()
    WYGestureRecognizerShouldBeginInterceptMap.removeAll()
    WYHooksCacheMap.removeAll()
    WYHitTestCacheMap.removeAll()
    WYDrawRectCacheMap.removeAll()
    WYDrawTextCacheMap.removeAll()
    WYTextRectCacheMap.removeAll()
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
internal struct WYMethodHooks<Args, Return> {
    /// 方法执行前的回调数组（观察型，无返回值）
    internal var before: [(Any, Selector, Args) -> Void] = []
    /// 方法执行后的回调数组，可修改返回值
    internal var after: [(Any, Selector, Args, Return) -> Return] = []
}

/// 全局钩子存储容器（存储 before/after，值类型为 Any）
internal var WYHooksMap: [String: Any] = [:]

/// 保护钩子容器的线程锁
internal let WYHooksLock = NSLock()

/// 缓存 wy_findHooks 的结果（key: "wy_cache_hook_<className>_<selName>"）
internal var WYHooksCacheMap: [String: Any] = [:]

/// 记录哪些交换函数的 swizzleKey 已经被执行过（用于容错处理）
internal var WYExchangedMethodsSet: Set<String> = []

/// 保护 WYExchangedMethodsSet 的线程锁
internal let WYExchangedMethodsLock = NSLock()

/// Key 类型枚举
internal enum WYMethodSwizzlerKeyStyle {
    
    // 基础存储
    case hook
    case hookCache
    
    // 各类 intercept 存储
    case hitTestIntercept
    case hitTestCache
    case popIntercept
    case drawRectIntercept
    case drawRectCache
    case drawTextIntercept
    case drawTextCache
    case textRectIntercept
    case textRectCache
    case sizeThatFitsIntercept
    case intrinsicContentSizeIntercept
    case layoutAttributesForElementsIntercept
    case layoutAttributesForItemIntercept
    case layoutAttributesForSupplementaryViewIntercept
    case collectionViewContentSizeIntercept
    case shouldInvalidateLayoutIntercept
    case gestureRecognizerShouldBeginIntercept
    
    // 关联对象标记（swizzleKey）
    case swizzledMark
    
    /// 对应的Key前缀
    internal var prefix: String {
        switch self {
        case .hook:                     return "wy_hook_"
        case .hookCache:                return "wy_cache_hook_"
        case .hitTestIntercept:         return "wy_intercept_hitTest_"
        case .hitTestCache:             return "wy_cache_hitTest_"
        case .popIntercept:             return "wy_intercept_popViewController_"
        case .drawRectIntercept:        return "wy_intercept_drawRect_"
        case .drawRectCache:            return "wy_cache_drawRect_"
        case .drawTextIntercept:        return "wy_intercept_drawText_"
        case .drawTextCache:            return "wy_cache_drawText_"
        case .textRectIntercept:        return "wy_intercept_textRect_"
        case .textRectCache:            return "wy_cache_textRect_"
        case .sizeThatFitsIntercept:    return "wy_intercept_sizeThatFits_"
        case .intrinsicContentSizeIntercept: return "wy_intercept_intrinsicContentSize_"
        case .layoutAttributesForElementsIntercept: return "wy_intercept_layoutAttributesForElements_"
        case .layoutAttributesForItemIntercept:     return "wy_intercept_layoutAttributesForItem_"
        case .layoutAttributesForSupplementaryViewIntercept: return "wy_intercept_layoutAttributesForSupplementaryView_"
        case .collectionViewContentSizeIntercept:   return "wy_intercept_collectionViewContentSize_"
        case .shouldInvalidateLayoutIntercept:      return "wy_intercept_shouldInvalidateLayout_"
        case .gestureRecognizerShouldBeginIntercept: return "wy_intercept_gestureRecognizerShouldBegin_"
        case .swizzledMark:             return "wy_"
        }
    }
}

/// 生成统一格式的 Key
internal func wy_methodSwizzlerKey(for style: WYMethodSwizzlerKeyStyle, className: String, selectorName: String = "") -> String {
    let base = "\(style.prefix)\(className)"
    if style == .swizzledMark {
        // swizzledKey 特殊格式：wy_<className>_<selName>_swizzled
        return base + (selectorName.isEmpty ? "" : "_\(selectorName)_swizzled")
    } else {
        return selectorName.isEmpty ? base : base + "_\(selectorName)"
    }
}

/**
 获取指定类的实例方法，若方法不存在则输出错误信息并返回 nil。
 
 - Parameters:
   - targetClass: 目标类
   - selector: 方法选择器
 - Returns: 找到的 Method 对象，如果不存在则返回 nil
 */
internal func wy_getInstanceMethod(_ targetClass: AnyClass, _ selector: Selector) -> Method? {
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
internal func wy_findHooks<Args, Return>(for receiver: AnyObject, selector: Selector) -> WYMethodHooks<Args, Return> {
    // 获取方法名字符串
    let selName = NSStringFromSelector(selector)
    // 从当前对象的类开始向上查找
    var currentClass: AnyClass? = type(of: receiver)
    
    // 遍历继承链（从当前类直到 NSObject）
    while let cls = currentClass, cls != NSObject.self {
        let className = NSStringFromClass(cls)
        // 生成缓存键，格式：wy_cache_hook_<类名>_<方法名>
        let cacheKey = wy_methodSwizzlerKey(for: .hookCache, className: className, selectorName: selName)
        
        // 先尝试从缓存中获取
        WYHooksLock.lock()
        if let cached = WYHooksCacheMap[cacheKey] as? WYMethodHooks<Args, Return> {
            WYHooksLock.unlock()
            return cached
        }
        WYHooksLock.unlock()
        
        // 生成存储键，格式：wy_hook_<类名>_<方法名>
        let key = wy_methodSwizzlerKey(for: .hook, className: className, selectorName: selName)
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
 对指定类的指定方法进行 IMP 替换（仅一次）
 
 - Parameters:
   - targetClass: 目标类
   - selector: 方法选择器
   - newImpBlock: 新的 Block IMP，类型为 @convention(block)
 */
internal func wy_swizzleMethod(
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
    let className = NSStringFromClass(targetClass)
    let selName = NSStringFromSelector(selector)
    let swizzleKey = wy_methodSwizzlerKey(for: .swizzledMark, className: className, selectorName: selName)
    
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
internal func wy_checkAndCleanSwizzleMark(for targetClass: AnyClass, selector: Selector) {
    
    let className = NSStringFromClass(targetClass)
    let selName = NSStringFromSelector(selector)
    let swizzleKey = wy_methodSwizzlerKey(for: .swizzledMark, className: className, selectorName: selName)
    
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
internal func wy_remarkSwizzleKeyCalled(for targetClass: AnyClass, selector: Selector) {
    let className = NSStringFromClass(targetClass)
    let selName = NSStringFromSelector(selector)
    let swizzleKey = wy_methodSwizzlerKey(for: .swizzledMark, className: className, selectorName: selName)
    WYExchangedMethodsLock.lock()
    WYExchangedMethodsSet.insert(swizzleKey)
    WYExchangedMethodsLock.unlock()
}
