//
//  CGFloat.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/2/3.
//  Copyright © 2024 官人. All rights reserved.
//

import Foundation

public extension Optional where Wrapped == CGFloat {
    /// 获取非空安全值
    var wy_safe: CGFloat {
        return self ?? 0.0
    }
}

public extension CGFloat {
    
    /// CGFloat转String、Double、Int、Decimal
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {
        
        guard (type == String.self) || (type == Double.self) || (type == Int.self) || (type == Decimal.self)  || (type == CGFloat.self) else {
            fatalError("type只能是String、Double、Int、Decimal中的一种")
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
     *  @param minimum   最小可以是多少
     *
     *  @param maximum   最大可以是多少
     *
     *  @param precision 精度(默认保留2位小数)
     *
     */
    static func wy_randomFloat(minimum: CGFloat = 0.01, maximum: CGFloat = 99999.99, precision: Int = 2) -> CGFloat {
        
        guard minimum < maximum else {
            return maximum
        }
        
        let randomValue = CGFloat.random(in: minimum...maximum)
        
        // 保留 precision 位小数
        let multiplier = pow(10, CGFloat(precision))
        return (randomValue * multiplier).rounded() / multiplier
    }
}
