//
//  FloatingPoint.swift
//  WYBasisKit
//
//  Created by 官人 on 2025/7/12.
//

import Foundation

public extension FloatingPoint {
    
    /// 角度转弧度
    var wy_degreesToRadian: Self {
        return self * .pi / 180
    }
    
    /// 弧度转角度
    var wy_radianToDegrees: Self {
        return self * 180 / .pi
    }
}
