//
//  FloatingPointObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation

@objcMembers public class FloatingPointObjC: NSObject {
    
    /// 角度转弧度
    public static func wy_degreesToRadian(floatFegrees: CGFloat) -> CGFloat {
        return floatFegrees.wy_degreesToRadian
    }
    
    /// 弧度转角度
    public static func wy_radianToDegrees(floatRadian: CGFloat) -> CGFloat {
        return floatRadian.wy_radianToDegrees
    }
    
    /// 角度转弧度
    public static func wy_degreesToRadian(doubleFegrees: Double) -> Double {
        return doubleFegrees.wy_degreesToRadian
    }
    
    /// 弧度转角度
    public static func wy_radianToDegrees(doubleRadian: Double) -> Double {
        return doubleRadian.wy_radianToDegrees
    }
}
