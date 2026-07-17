//
//  WYAirBubbleView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/7/2.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 三角箭头的指向方向
@objc(WYArrowDirection)
public enum WYArrowDirectionObjC: Int {
    /// 箭头指向顶部（气泡在下方）
    case top = 0
    /// 箭头指向底部（气泡在上方）
    case bottom
    /// 箭头指向左侧（气泡在右侧）
    case left
    /// 箭头指向右侧（气泡在左侧）
    case right
}

/// 气泡视图：支持圆角、边框、带三角箭头，箭头可设置方向、尺寸、偏移和圆角等
@objc public extension WYAirBubbleView {

    /// 气泡主体的圆角半径
    @objc(cornerRadius)
    public var cornerRadiusObjC: CGFloat {
        set { cornerRadius = newValue }
        get { return cornerRadius }
    }

    /// 需要圆角的位置（左上、右上、左下、右下组合），默认全部圆角
    @objc(cornersPosition)
    public var cornersPositionObjC: UIRectCorner {
        set { cornersPosition = newValue }
        get { return cornersPosition }
    }

    /// 气泡的填充颜色，默认系统蓝色
    @objc(fillColor)
    public var fillColorObjC: UIColor {
        set { fillColor = newValue }
        get { return fillColor }
    }

    /// 气泡边框的颜色，默认透明
    @objc(borderColor)
    public var borderColorObjC: UIColor {
        set { borderColor = newValue }
        get { return borderColor }
    }

    /// 气泡边框的宽度，默认0（无边框）
    @objc(borderWidth)
    public var borderWidthObjC: CGFloat {
        set { borderWidth = newValue }
        get { return borderWidth }
    }

    /// 是否显示三角箭头(默认显示)
    @objc(showsArrow)
    public var showsArrowObjC: Bool {
        set { showsArrow = newValue }
        get { return showsArrow }
    }

    /// 三角箭头的方向，默认指向底部（气泡在上方）
    @objc(arrowDirection)
    public var arrowDirectionObjC: WYArrowDirectionObjC {
        set { arrowDirection = WYArrowDirection(rawValue: newValue.rawValue) ?? .top }
        get { return WYArrowDirectionObjC(rawValue: arrowDirection.rawValue) ?? .top }
    }

    /// 三角箭头的尺寸（宽度，高度），宽度是底边长度，高度是尖点到底边的垂直距离
    @objc(arrowSize)
    public var arrowSizeObjC: CGSize {
        set { arrowSize = newValue }
        get { return arrowSize }
    }

    /**
     箭头相对于所在边中心点的偏移量（单位：pt）
     规则：
     - 当方向为 .top 或 .bottom 时，偏移沿 X 轴（正数向右，负数向左）
     - 当方向为 .left 或 .right 时，偏移沿 Y 轴（正数向下，负数向上）
     */
    @objc(arrowOffset)
    public var arrowOffsetObjC: CGFloat {
        set { arrowOffset = newValue }
        get { return arrowOffset }
    }

    /// 箭头距离气泡边缘的最小安全距离，防止箭头贴边导致圆角或边界重叠
    @objc(arrowEdgePadding)
    public var arrowEdgePaddingObjC: CGFloat {
        set { arrowEdgePadding = newValue }
        get { return arrowEdgePadding }
    }

    /// 箭头尖角的圆角半径
    @objc(arrowTipRadius)
    public var arrowTipRadiusObjC: CGFloat {
        set { arrowTipRadius = newValue }
        get { return arrowTipRadius }
    }
    
    /**
     渐变色数组（为空则不启用渐变）
     
     - Note:
     当不为空时：
       - 使用 CAGradientLayer + mask 渲染
       - fillColor 将被忽略
       - 渐变区域完全受气泡路径裁剪
     */
    @objc(gradientColors)
    public var gradientColorsObjC: [UIColor] {
        set { gradientColors = newValue }
        get { return gradientColors }
    }

    /// 渐变色方向
    @objc(gradientDirection)
    public var gradientDirectionObjC: WYGradientDirectionObjC {
        set { gradientDirection = WYGradientDirection(rawValue: newValue.rawValue) ?? .leftToRight }
        get { return WYGradientDirectionObjC(rawValue: gradientDirection.rawValue) ?? .leftToRight }
    }
    
    /// 阴影颜色（为 nil 时不显示阴影）
    @objc(shadowColor)
    public var shadowColorObjC: UIColor? {
        set { shadowColor = newValue }
        get { return shadowColor }
    }
    
    /// 阴影偏移度 默认CGSize.zero (width : 为正数时，向右偏移，为负数时，向左偏移，height : 为正数时，向下偏移，为负数时，向上偏移)
    @objc(shadowOffset)
    public var shadowOffsetObjC: CGSize {
        set { shadowOffset = newValue }
        get { return shadowOffset }
    }
    
    /// 阴影模糊半径 默认0.0，需要大于0才会有阴影扩散效果(阴影才可见)
    @objc(shadowRadius)
    public var shadowRadiusObjC: CGFloat {
        set { shadowRadius = newValue }
        get { return shadowRadius }
    }
    
    /// 阴影透明度，默认0.5，取值范围0~1
    @objc(shadowOpacity)
    public var shadowOpacityObjC: CGFloat {
        set { shadowOpacity = newValue }
        get { return shadowOpacity }
    }
    
    /**
     当前气泡的路径（用于外部 hitTest / mask / 动画对齐等）
     
     - Note:
     仅在视图完成 layout（bounds > 0）后有效
     在初始化或约束未生效前可能为 nil
     
     - Tip:
     若需要获取稳定路径，建议在布局完成后（如 layoutSubviews / Task @MainActor）访问
     */
    @objc(bubblePath)
    public var bubblePathObjC: CGPath? {
        get { return bubblePath }
    }
}
