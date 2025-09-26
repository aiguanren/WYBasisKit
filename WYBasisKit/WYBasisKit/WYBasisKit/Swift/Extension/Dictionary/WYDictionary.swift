//
//  Dictionary.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import Foundation

public extension Dictionary {
    
    /// 安全取值(找不到返回 nil)
    func wy_value(forKey key: Key) -> Value? {
        return self[key]
    }
    
    /// 安全取值(找不到返回默认值)
    func wy_value(forKey key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        return self[key] ?? defaultValue()
    }
}
