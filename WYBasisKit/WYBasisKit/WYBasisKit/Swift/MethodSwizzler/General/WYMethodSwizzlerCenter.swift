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

/// 方法交换入口（注册和移除操作应在主线程执行，影响目标类的所有实例）
@objc(WYMethodSwizzler)
public final class WYMethodSwizzler: NSObject {

    /**
     移除指定类的指定方法的钩子（包括 before、after 和 intercept）。

       @param anyClass 目标类。
       @param selector 方法选择器。若传入 `nil` 则移除该类的所有钩子(所有方法)，若指定 `selector` 则只移除该方法的钩子
     */
    @objc public static var removeHooks: @convention(block) (_ anyClass: AnyClass, _ selector: Selector?) -> Void {
        return { anyClass, selector in
            wy_removeMethodExchangeHooks(for: anyClass, selector: selector)
        }
    }

    /**
     移除所有类、所有方法的钩子
     */
    @objc public static var removeAllHooks: @convention(block) () -> Void {
        return { wy_removeAllMethodExchangeHooks() }
    }

    private override init() {
        super.init()
    }
}

/// UIView?类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYViewInterceptResult)
public final class WYViewInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYViewInterceptResult {
        return WYViewInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值（允许nil）
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: UIView?) -> WYViewInterceptResult {
        return { value in WYViewInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<UIView?>

    private init(_ decision: WYInterceptResult<UIView?>) {
        self.decision = decision
        super.init()
    }
}

/// UIViewController?类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYViewControllerInterceptResult)
public final class WYViewControllerInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYViewControllerInterceptResult {
        return WYViewControllerInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值（允许nil）
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: UIViewController?) -> WYViewControllerInterceptResult {
        return { value in WYViewControllerInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<UIViewController?>

    private init(_ decision: WYInterceptResult<UIViewController?>) {
        self.decision = decision
        super.init()
    }
}

/// CGRect类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYRectInterceptResult)
public final class WYRectInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYRectInterceptResult {
        return WYRectInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: CGRect) -> WYRectInterceptResult {
        return { value in WYRectInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<CGRect>

    private init(_ decision: WYInterceptResult<CGRect>) {
        self.decision = decision
        super.init()
    }
}

/// CGSize类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYSizeInterceptResult)
public final class WYSizeInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYSizeInterceptResult {
        return WYSizeInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: CGSize) -> WYSizeInterceptResult {
        return { value in WYSizeInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<CGSize>

    private init(_ decision: WYInterceptResult<CGSize>) {
        self.decision = decision
        super.init()
    }
}

/// Bool类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYBoolInterceptResult)
public final class WYBoolInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYBoolInterceptResult {
        return WYBoolInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: Bool) -> WYBoolInterceptResult {
        return { value in WYBoolInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<Bool>

    private init(_ decision: WYInterceptResult<Bool>) {
        self.decision = decision
        super.init()
    }
}

/// UICollectionViewLayoutAttributes?类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYLayoutAttributesInterceptResult)
public final class WYLayoutAttributesInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYLayoutAttributesInterceptResult {
        return WYLayoutAttributesInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值（允许nil）
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: UICollectionViewLayoutAttributes?) -> WYLayoutAttributesInterceptResult {
        return { value in WYLayoutAttributesInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<UICollectionViewLayoutAttributes?>

    private init(_ decision: WYInterceptResult<UICollectionViewLayoutAttributes?>) {
        self.decision = decision
        super.init()
    }
}

/// [UICollectionViewLayoutAttributes]?类型的拦截决策（proceed继续执行，result指定替换值）
@objc(WYLayoutAttributesArrayInterceptResult)
public final class WYLayoutAttributesArrayInterceptResult: NSObject {

    /// 继续执行原始方法（绘制方法使用原始矩形）
    @objc public static var proceed: WYLayoutAttributesArrayInterceptResult {
        return WYLayoutAttributesArrayInterceptResult(.proceed)
    }

    /**
     指定替换值（绘制方法使用指定矩形，其他方法跳过原方法及before/after）
     @param value 替换值（允许nil）
     @return 拦截决策
     */
    @objc public static var result: @convention(block) (_ value: [UICollectionViewLayoutAttributes]?) -> WYLayoutAttributesArrayInterceptResult {
        return { value in WYLayoutAttributesArrayInterceptResult(.result(value)) }
    }

    internal let decision: WYInterceptResult<[UICollectionViewLayoutAttributes]?>

    private init(_ decision: WYInterceptResult<[UICollectionViewLayoutAttributes]?>) {
        self.decision = decision
        super.init()
    }
}
