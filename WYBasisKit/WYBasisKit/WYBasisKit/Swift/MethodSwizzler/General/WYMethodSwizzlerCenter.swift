//
//  WYMethodSwizzlerCenter.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/19.
//

import UIKit

/// 拦截决策（用于有返回值的方法）
public enum WYInterceptResult<Value> {
    /// 继续执行原始交换方法
    case proceed
    /// 直接返回指定的值（可以是 nil），不再调用原始方法
    case result(Value)
}

/**
 移除指定类的指定方法的钩子（包括 before、after 和 intercept）。
 
   @param anyClass 目标类。
   @param selector 方法选择器。若传入 `nil` 则移除该类的所有钩子(所有方法)，若指定 `selector` 则只移除该方法的钩子
 */
public func wy_removeMethodExchangeHooks(for anyClass: AnyClass, selector: Selector? = nil) {
    wy_removeMethodExchangeHooksInternal(for: anyClass, selector: selector)
}

/**
 移除所有类、所有方法的钩子
 */
public func wy_removeAllMethodExchangeHooks() {
    wy_removeAllMethodExchangeHooksInternal()
}
