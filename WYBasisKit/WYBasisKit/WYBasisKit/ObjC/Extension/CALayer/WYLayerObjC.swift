//
//  CALayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import UIKit
import QuartzCore
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 虚线方向
@objc(WYDashDirection)
@frozen public enum WYDashDirectionObjC: Int {
    
    /// 从上到下
    case topToBottom = 0
    /// 从左到右
    case leftToRight
}

@objc public extension CALayer {
    
    /**
     * 绘制虚线
     * @param direction    虚线方向
     * @param bounds       虚线bounds
     * @param color        虚线颜色
     * @param length       每段虚线长度（仅当 `isRound` 为 `false` 时有效）
     * @param isRound      是否为圆点虚线（true：圆点，false：普通虚线），为 `true` 时，圆点的直径由 direction 决定(`.topToBottom` 时直径 = bounds.width，`.leftToRight` 时直径 = bounds.height)
     * @param spacing      每段虚线间隔
     */
    @objc(wy_drawDashLine:bounds:color:length:isRound:spacing:)
    static func wy_drawDashLineObjC(direction: WYDashDirectionObjC,
                                    bounds: CGRect,
                                    color: UIColor,
                                    length: Double = Double(UIDevice.wy_screenWidthObjC(10, pixels: WYBasisKitConfigObjC.defaultScreenPixels)),
                                    isRound: Bool = false,
                                    spacing: Double = Double(UIDevice.wy_screenWidthObjC(5, pixels: WYBasisKitConfigObjC.defaultScreenPixels))) -> CALayer {

        return CALayer.wy_drawDashLine(direction: WYDashDirection(rawValue: direction.rawValue) ?? .leftToRight, bounds: bounds, color: color, length: length, isRound: isRound, spacing: spacing)
    }
}
