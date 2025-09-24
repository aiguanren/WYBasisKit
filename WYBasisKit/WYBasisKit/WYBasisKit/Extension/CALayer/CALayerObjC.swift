//
//  CALayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import UIKit
import QuartzCore

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
    * @param length       每段虚线长度
    * @param spacing      每段虚线间隔
    */
    @objc(wy_drawDashLine:bounds:color:length:spacing:)
    static func wy_drawDashLine(direction: WYDashDirectionObjC, bounds: CGRect, color: UIColor, length: Double = Double(UIDevice.wy_screenWidthObjC(10, pixels: WYBasisKitConfigObjC.defaultScreenPixels)), spacing: Double = Double(UIDevice.wy_screenWidthObjC(5, pixels: WYBasisKitConfigObjC.defaultScreenPixels))) -> CALayer {

        return CALayer.wy_drawDashLine(direction: WYDashDirection(rawValue: direction.rawValue) ?? .leftToRight, bounds: bounds, color: color, length: length, spacing: spacing)
    }
}
