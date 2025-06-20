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
}
