//
//  DecimalObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import Foundation
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension NSDecimalNumber {
    
    /// NSDecimalNumber转String
    @objc func wy_stringValue() -> String {
        return (self as Decimal).wy_convertTo(String.self)
    }
    
    /// NSDecimalNumber转CGFloat
    @objc func wy_floatValue() -> CGFloat {
        return (self as Decimal).wy_convertTo(CGFloat.self)
    }
    
    /// NSDecimalNumber转Double
    @objc func wy_doubleValue() -> Double {
        return (self as Decimal).wy_convertTo(Double.self)
    }
    
    /// NSDecimalNumber转NSInteger
    @objc func wy_intValue() -> Int {
        return (self as Decimal).wy_convertTo(Int.self)
    }
}
