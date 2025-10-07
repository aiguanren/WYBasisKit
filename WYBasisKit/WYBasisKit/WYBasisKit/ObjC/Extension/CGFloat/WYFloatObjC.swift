//
//  CGFloatObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation

@objcMembers public class CGFloatObjC: NSObject {
    
    /// CGFloat转String
    @objc public static func wy_stringValue(_ value: CGFloat) -> String {
        return value.wy_convertTo(String.self)
    }
    
    /// CGFloat转NSInteger
    @objc public static func wy_integerValue(_ value: CGFloat) -> Int {
        return value.wy_convertTo(Int.self)
    }
    
    /// CGFloat转Double
    @objc public static func wy_doubleValue(_ value: CGFloat) -> Double {
        return value.wy_convertTo(Double.self)
    }
    
    /// CGFloat转NSDecimalNumber
    @objc public static func wy_decimalValue(_ value: CGFloat) -> NSDecimalNumber {
        let string: String = wy_stringValue(value)
        return NSDecimalNumber(string: string)
    }
    
    /**
     *  获取一个随机浮点数
     *
     *  @param minimum   最小可以是多少
     *
     *  @param maximum   最大可以是多少
     *
     */
    @objc public static func wy_random(minimum: CGFloat = 0.01, maximum: CGFloat = 99999.99) -> CGFloat {
        return CGFloat.wy_random(minimum: minimum, maximum: maximum)
    }
}
