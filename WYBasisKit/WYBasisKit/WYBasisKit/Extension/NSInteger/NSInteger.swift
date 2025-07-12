//
//  NSInteger.swift
//  WYBasisKit
//
//  Created by 官人 on 2025/7/12.
//

import Foundation

public extension NSInteger {
    
    /// NSInteger转String、CGFloat、Double、Int、Decimal
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {

        guard (type == String.self) || (type == Double.self) || (type == CGFloat.self) || (type == NSInteger.self) || (type == Decimal.self)  || (type == Int.self) else {
            fatalError("type只能是String、CGFloat、Double、Int、Decimal中的一种")
        }
        
        if type == String.self {
            return "\(self)" as! T
        }
        
        if type == CGFloat.self {
            return CGFloat(self) as! T
        }
            
        if type == Double.self {
            return Double(self) as! T
        }
        
        if type == Decimal.self {
            return "\(self)".wy_convertTo(Decimal.self) as! T
        }
        
        if type == Int.self {
            return Int(self) as! T
        }
        
        return self as! T
    }
    
    /**
     *  获取一个随机整数
     *
     *  @param minimux   最小可以是多少
     *
     *  @param maximum   最大可以是多少
     *
     */
    static func wy_random(minimux: NSInteger = 1, maximum: NSInteger = 99999) -> NSInteger {
        
        guard minimux < maximum else {
            return maximum
        }
        return minimux + (NSInteger(arc4random()) % (maximum - minimux))
    }
}
