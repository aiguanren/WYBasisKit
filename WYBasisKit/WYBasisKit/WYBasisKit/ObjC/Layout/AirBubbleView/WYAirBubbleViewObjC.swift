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

/// 三角箭头方向
@objc(WYArrowDirection)
public enum WYArrowDirectionObjC: Int {
    /// 顶部
    case top = 0
    /// 底部
    case bottom
    /// 左侧
    case left
    /// 右侧
    case right
}

@objc public extension WYAirBubbleView {

    /// (气泡)圆角半径
    @objc(cornerRadius)
    public var cornerRadiusObjC: CGFloat {
        set { cornerRadius = newValue }
        get { return cornerRadius }
    }

    /// (气泡)圆角位置
    @objc(cornersPosition)
    public var cornersPositionObjC: UIRectCorner {
        set { cornersPosition = newValue }
        get { return cornersPosition }
    }

    /// (气泡)填充颜色
    @objc(fillColor)
    public var fillColorObjC: UIColor {
        set { fillColor = newValue }
        get { return fillColor }
    }

    /// (气泡)边框颜色
    @objc(borderColor)
    public var borderColorObjC: UIColor {
        set { borderColor = newValue }
        get { return borderColor }
    }

    /// (气泡)边框宽度
    @objc(borderWidth)
    public var borderWidthObjC: CGFloat {
        set { borderWidth = newValue }
        get { return borderWidth }
    }

    /// 是否显示三角箭头
    @objc(showsArrow)
    public var showsArrowObjC: Bool {
        set { showsArrow = newValue }
        get { return showsArrow }
    }

    /// 三角箭头方向
    @objc(arrowDirection)
    public var arrowDirectionObjC: WYArrowDirectionObjC {
        set { arrowDirection = WYArrowDirection(rawValue: newValue.rawValue) ?? .top }
        get { return WYArrowDirectionObjC(rawValue: arrowDirection.rawValue) ?? .top }
    }

    /// 三角箭头尺寸（宽，高）
    @objc(arrowSize)
    public var arrowSizeObjC: CGSize {
        set { arrowSize = newValue }
        get { return arrowSize }
    }

    /// 箭头颜色（默认跟随气泡）
    @objc(arrowColor)
    public var arrowColorObjC: UIColor? {
        set { arrowColor = newValue }
        get { return arrowColor }
    }

    /**
     箭头相对(所在边)中心点偏移（pt）
     规则： - top / bottom：X方向偏移
           - left / right：Y方向偏移
     */
    @objc(arrowOffset)
    public var arrowOffsetObjC: CGFloat {
        set { arrowOffset = newValue }
        get { return arrowOffset }
    }

    /// 箭头边界安全距离（防止贴边）
    @objc(arrowEdgePadding)
    public var arrowEdgePaddingObjC: CGFloat {
        set { arrowEdgePadding = newValue }
        get { return arrowEdgePadding }
    }

    /// 箭头尖角(圆角)半径
    @objc(arrowTipRadius)
    public var arrowTipRadiusObjC: CGFloat {
        set { arrowTipRadius = newValue }
        get { return arrowTipRadius }
    }
}
