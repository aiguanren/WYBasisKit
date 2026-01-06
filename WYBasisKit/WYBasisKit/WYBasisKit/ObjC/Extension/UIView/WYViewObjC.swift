//
//  UIViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/25.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

/// 渐变方向
@objc(WYGradientDirection)
@frozen public enum WYGradientDirectionObjC: Int {
    
    /// 从左到右
    case leftToRight = 0
    /// 从上到下
    case topToBottom
    /// 左上到右下
    case leftToLowRight
    /// 右上到左下
    case rightToLowLeft
}

@objc public extension UIView {
    
    /** view.width */
    @objc(wy_width)
    var wy_widthObjC: CGFloat {
        set { self.wy_width = newValue }
        get { return self.wy_width }
    }
    
    /** view.height */
    @objc(wy_height)
    var wy_heightObjC: CGFloat {
        set { self.wy_height = newValue }
        get { return self.wy_height }
    }
    
    /** view.origin.x */
    @objc(wy_left)
    var wy_leftObjC: CGFloat {
        set { self.wy_left = newValue }
        get { return self.wy_left }
    }
    
    /** view.origin.x + view.width */
    @objc(wy_right)
    var wy_rightObjC: CGFloat {
        set { self.wy_right = newValue }
        get { return self.wy_right }
    }
    
    /** view.origin.y */
    @objc(wy_top)
    var wy_topObjC: CGFloat {
        set { self.wy_top = newValue }
        get { return self.wy_top }
    }
    
    /** view.origin.y + view.height */
    @objc(wy_bottom)
    var wy_bottomObjC: CGFloat {
        set { self.wy_bottom = newValue }
        get { return self.wy_bottom }
    }
    
    /** view.center.x */
    @objc(wy_centerx)
    var wy_centerxObjC: CGFloat {
        set { self.wy_centerx = newValue }
        get { return self.wy_centerx }
    }
    
    /** view.center.y */
    @objc(wy_centery)
    var wy_centeryObjC: CGFloat {
        set { self.wy_centery = newValue }
        get { return self.wy_centery }
    }
    
    /** view.origin */
    @objc(wy_origin)
    var wy_originObjC: CGPoint {
        set { self.wy_origin = newValue }
        get { return self.wy_origin }
    }
    
    /** view.size */
    @objc(wy_size)
    var wy_sizeObjC: CGSize {
        set { self.wy_size = newValue }
        get { return self.wy_size }
    }
    
    /**
     *  获取自定义控件所需要的换行数
     *
     *  @param total     总共有多少个自定义控件
     *
     *  @param perLine   每行显示多少个控件
     *
     */
    @objc(wy_numberOfLinesWithTotal:perLine:)
    static func wy_numberOfLinesObjC(total: Int, perLine: Int) -> Int {
        return wy_numberOfLines(total: total, perLine: perLine)
    }
    
    /// 移除所有子控件
    @objc(wy_removeAllSubviews)
    func wy_removeAllSubviewsObjC() {
        wy_removeAllSubviews()
    }
    
    /// 移除自身及所有子控件
    @objc(wy_removeFromSuperview)
    func wy_removeFromSuperviewObjC() {
        wy_removeFromSuperview()
    }
    
    /**
     *  防止View在短时间内快速重复点击(写在点击事件中才会生效)
     *
     *  @param duration   间隔时间
     *
     */
    @objc(wy_temporarilyDisableForDuration:)
    func wy_temporarilyDisable(duration: TimeInterval) {
        wy_temporarilyDisable(for: duration)
    }
    
    /// 添加手势点击事件
    @discardableResult
    @objc(wy_addGestureWithTarget:action:)
    func wy_addGestureObjC(target: Any?, action: Selector?) -> UITapGestureRecognizer {
        return wy_addGesture(target: target, action: action)
    }
    
    /// 添加收起键盘的手势
    @discardableResult
    @objc(wy_gestureHidingkeyboard)
    func wy_gestureHidingkeyboardObjC() -> UITapGestureRecognizer {
        return wy_gestureHidingkeyboard()
    }
}

@objc public extension UIView {
    
    /**
     *  指定位置添加边框(仅适合无圆角的UIView添加)
     *
     *  @param edges     要添加的边框的位置
     *
     *  @param color     要添加的边框的颜色
     *
     *  @param thickness 要添加的边框的宽度或高度
     *
     */
    @objc(wy_addBorder:color:thickness:)
    func wy_addBorderObjC(edges: UIRectEdge,
                          color: UIColor,
                      thickness: CGFloat) {
        
        wy_addBorder(edges: edges, color: color, thickness: thickness)
    }
    
    /**
     *  移除指定位置边框
     *
     *  @param edges     要移除的边框的位置
     *
     *  @param thickness 要移除的边框的宽度或高度
     *
     */
    @objc(wy_removeBorder:)
    func wy_removeBorderObjC(edges: UIRectEdge) {
        wy_removeBorder(edges: edges)
    }
    @objc(wy_removeBorder:thickness:)
    func wy_removeBorderObjC(edges: UIRectEdge, thickness: CGFloat) {
        wy_removeBorder(edges: edges, thickness: thickness)
    }
}

public extension UIView {
    
    /// 使用链式编程设置圆角、边框、阴影、渐变(调用方式类似SnapKit， 也可直接.语法调用，点语法时需要自己在最后一个设置后面调用wy_showVisual后设置才会生效)
    @discardableResult
    @objc(wy_makeVisual:)
    func wy_makeVisualObjC(_ visualView: (_ make: UIView) -> Void) -> UIView {
        return wy_makeVisual(visualView)
    }
    
    /// 圆角的位置， 默认4角圆角
    @objc(wy_rectCorner)
    var wy_rectCornerObjC: @convention(block) (UIRectCorner) -> UIView {
        return { corner in
            return self.wy_rectCorner(corner)
        }
    }
    
    /// 圆角的半径 默认0.0
    @objc(wy_cornerRadius)
    var wy_cornerRadiusObjC: @convention(block) (CGFloat) -> UIView {
        return { radius in
            return self.wy_cornerRadius(radius)
        }
    }
    
    /// 边框颜色 默认透明
    @objc(wy_borderColor)
    var wy_borderColorObjC: @convention(block) (UIColor) -> UIView {
        return { color in
            return self.wy_borderColor(color)
        }
    }
    
    /// 边框宽度 默认0.0
    @objc(wy_borderWidth)
    var wy_borderWidthObjC: @convention(block) (CGFloat) -> UIView {
        return { width in
            return self.wy_borderWidth(width)
        }
    }
    
    /// 阴影颜色 默认透明
    @objc(wy_shadowColor)
    var wy_shadowColorObjC: @convention(block) (UIColor) -> UIView {
        return { color in
            return self.wy_shadowColor(color)
        }
    }
    
    /// 阴影偏移度 默认CGSize.zero (width : 为正数时，向右偏移，为负数时，向左偏移，height : 为正数时，向下偏移，为负数时，向上偏移)
    @objc(wy_shadowOffset)
    var wy_shadowOffsetObjC: @convention(block) (CGSize) -> UIView {
        return { offset in
            return self.wy_shadowOffset(offset)
        }
    }
    
    /// 阴影半径 默认0.0
    @objc(wy_shadowRadius)
    var wy_shadowRadiusObjC: @convention(block) (CGFloat) -> UIView {
        return { redius in
            return self.wy_shadowRadius(redius)
        }
    }
    
    /// 阴影模糊度，默认0.5，取值范围0~1
    @objc(wy_shadowOpacity)
    var wy_shadowOpacityObjC: @convention(block) (CGFloat) -> UIView {
        return { opacity in
            return self.wy_shadowOpacity(opacity)
        }
    }
    
    /// 渐变色数组(设置渐变色时不能设置背景色，会有影响)
    @objc(wy_gradualColors)
    var wy_gradualColorsObjC: @convention(block) ([UIColor]) -> UIView {
        return { colors in
            return self.wy_gradualColors(colors)
        }
    }
    
    /// 渐变色方向 默认从左到右
    @objc(wy_gradientDirection)
    var wy_gradientDirectionObjC: @convention(block) (WYGradientDirectionObjC) -> UIView {
        return { direction in
            return self.wy_gradientDirection(WYGradientDirection(rawValue: direction.rawValue) ?? .leftToRight)
        }
    }
    
    /// 设置圆角时，会去获取视图的Bounds属性，如果此时获取不到，则需要传入该参数，默认为 nil，如果传入该参数，会设置视图的frame为bounds
    @objc(wy_viewBounds)
    var wy_viewBoundsObjC: @convention(block) (CGRect) -> UIView {
        return { bounds in
            return self.wy_viewBounds(bounds)
        }
    }
    
    /// 贝塞尔路径 默认nil (有值时，radius属性将失效)
    @objc(wy_bezierPath)
    var wy_bezierPathObjC: @convention(block) (UIBezierPath) -> UIView {
        return { path in
            return self.wy_bezierPath(path)
        }
    }
    
    /// 显示(更新)边框、阴影、圆角、渐变
    @objc(wy_showVisual)
    var wy_showVisualObjC: @convention(block) () -> UIView {
        return {
            return self.wy_showVisual()
        }
    }
    
    /// 清除边框、阴影、圆角、渐变
    @objc(wy_clearVisual)
    var wy_clearVisualObjC: @convention(block) () -> UIView {
        return {
            return self.wy_clearVisual()
        }
    }
}
