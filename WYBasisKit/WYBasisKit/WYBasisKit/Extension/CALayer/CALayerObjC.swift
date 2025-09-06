//
//  CALayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation
import QuartzCore

/// 虚线方向
@objc @frozen public enum WYDashDirectionObjC: Int {
    
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
    @objc static func wy_drawDashLine(direction: WYDashDirectionObjC, bounds: CGRect, color: UIColor, length: Double = Double(UIDevice.wy_screenWidthObjC(10, WYBasisKitConfigObjC.defaultScreenPixels)), spacing: Double = Double(UIDevice.wy_screenWidthObjC(5, WYBasisKitConfigObjC.defaultScreenPixels))) -> CALayer {

        return CALayer.wy_drawDashLine(direction: WYDashDirection(rawValue: direction.rawValue), bounds: bounds, color: color, length: length, spacing: spacing)
    }
}
