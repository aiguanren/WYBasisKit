//
//  Decimal.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/2/3.
//  Copyright © 2024 官人. All rights reserved.
//

import Foundation

public extension Decimal {
    
    /// Decimal转String、CGFloat、Double、NSInteger、Int
    func wy_convertTo<T: Any>(_ type: T.Type) -> T {

        guard (type == String.self) || (type == Double.self) || (type == CGFloat.self) || (type == NSInteger.self) || (type == Int.self) || (type == Decimal.self) else {
            fatalError("type只能是String、CGFloat、Double、NSInteger、Int中的一种")
        }
        
        if type == String.self {
            return "\(self)" as! T
        }
        
        if type == CGFloat.self {
            return CGFloat(truncating: self as NSNumber) as! T
        }
            
        if type == Double.self {
            return Double(truncating: self as NSNumber) as! T
        }
        
        if type == Int.self {
            return Int(Double(truncating: self as NSNumber)) as! T
        }
        
        return self as! T
    }
}
