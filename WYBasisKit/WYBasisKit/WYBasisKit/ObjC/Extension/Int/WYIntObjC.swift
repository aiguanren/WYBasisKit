//
//  IntObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objcMembers public class IntObjC: NSObject {
    
    /// NSInteger转String
    @objc public static func wy_stringValue(_ value: Int) -> String {
        return value.wy_convertTo(String.self)
    }
    
    /// NSInteger转CGFloat
    @objc public static func wy_floatValue(_ value: Int) -> CGFloat {
        return value.wy_convertTo(CGFloat.self)
    }
    
    /// NSInteger转Double
    @objc public static func wy_doubleValue(_ value: Int) -> Double {
        return value.wy_convertTo(Double.self)
    }
    
    /// NSInteger转NSDecimalNumber
    @objc public static func wy_decimalValue(_ value: Int) -> NSDecimalNumber {
        let string: String = wy_stringValue(value)
        return NSDecimalNumber(string: string)
    }
    
    /**
     *  获取一个随机整数
     *
     *  @param minimum   最小可以是多少
     *
     *  @param maximum   最大可以是多少
     *
     */
    @objc public static func wy_random(minimum: Int = 1, maximum: Int = 99999) -> Int {
        return Int.wy_random(minimum: minimum, maximum: maximum)
    }
}
