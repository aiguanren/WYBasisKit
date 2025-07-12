//
//  CGFloat.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/2/3.
//  Copyright © 2024 官人. All rights reserved.
//

import Foundation

public extension CGFloat {
    
    /// CGFloat转String、Double、Int、NSInteger、Decimal
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {
        
        guard (type == String.self) || (type == Double.self) || (type == Int.self) || (type == NSInteger.self) || (type == Decimal.self)  || (type == CGFloat.self) else {
            fatalError("type只能是String、Double、Int、NSInteger、Decimal中的一种")
        }
        
        if type == String.self {
            return "\(self)" as! T
        }
        
        if type == Double.self {
            return Double(self) as! T
        }
        
        if type == Int.self {
            return Int(self) as! T
        }
        
        if type == Decimal.self {
            return "\(self)".wy_convertTo(Decimal.self) as! T
        }
        
        return self as! T
    }
    
    /**
     *  获取一个随机浮点数
     *
     *  @param minimux   最小可以是多少
     *
     *  @param maximum   最大可以是多少
     *
     *  @param precision 精度(默认保留2位小数)
     *
     */
    static func wy_randomFloat(minimux: CGFloat = 0.01, maximum: CGFloat = 99999.99, precision: NSInteger = 2) -> CGFloat {
        
        guard minimux < maximum else {
            return maximum
        }
        
        let range = Swift.abs(minimux - maximum)
        let base = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let rawValue = base * range + Swift.min(minimux, maximum)
        let format = "%.\(precision)f"
        return CGFloat(Double(String(format: format, rawValue)) ?? 0)
    }
}
