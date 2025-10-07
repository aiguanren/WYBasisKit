//
//  DoubleObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation

@objcMembers public class DoubleObjC: NSObject {
    
    /// Double转String
    @objc public static func wy_stringValue(_ value: Double) -> String {
        return value.wy_convertTo(String.self)
    }
    
    /// Double转CGFloat
    @objc public static func wy_floatValue(_ value: Double) -> CGFloat {
        return value.wy_convertTo(CGFloat.self)
    }
    
    /// Double转NSInteger
    @objc public static func wy_integerValue(_ value: Double) -> Int {
        return value.wy_convertTo(Int.self)
    }
    
    /// Double转NSDecimalNumber
    @objc public static func wy_decimalValue(_ value: Double) -> NSDecimalNumber {
        let string: String = wy_stringValue(value)
        return NSDecimalNumber(string: string)
    }
    
    /**
     *  获取一个随机浮点数
     *
     *  @param minimum   最小值，默认 0.01
     *
     *  @param maximum   最大值，默认 99999.99
     *
     */
    @objc public static func wy_random(minimum: Double = 0.01, maximum: Double = 99999.99) -> Double {
        return Double.wy_random(minimum: minimum, maximum: maximum)
    }
}
