//
//  DictionaryObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import Foundation

@objc public extension NSDictionary {
    
    /// 安全取值(找不到返回 nil)
    @objc func wy_value(forKey key: String) -> Any? {
        return self[key]
    }
    
    /// 安全取值(找不到返回默认值)
    @objc func wy_value(forKey key: String, default defaultValue: Any) -> Any {
        return self[key] ?? defaultValue
    }
}
