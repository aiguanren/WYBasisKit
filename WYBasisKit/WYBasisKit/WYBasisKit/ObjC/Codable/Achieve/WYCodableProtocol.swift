//
//  WYCodableProtocol.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/21.
//

import Foundation

/// 自定义Codable协议
@objc public protocol WYCodableProtocol: NSObjectProtocol {
    
    /// 指定属性名映射，解决关键字段冲突，如：@{@"objectProperty": @"json_key"}
    @objc optional static func wy_objectKeyMapping() -> [String: String]
    
    /// Key映射开始回调
    @objc optional func wy_willStartMappingKey()
    
    /// Key映射完成回调
    @objc optional func wy_didFinishMappingKey()
    
    /// 自定义类型转换（用于特殊场景处理）
    @objc optional func wy_convertValue(_ value: Any, forKey key: String) -> Any?
}

internal class WYCodableProtocolHelper {
    
    /// 安全调用 wy_objectKeyMapping
    static func getObjectKeyMapping(for object: NSObject) -> [String: String] {
        guard let codable = object as? WYCodableProtocol else { return [:] }
        return (type(of: codable).wy_objectKeyMapping?() ?? [:])
    }
    
    /// 安全调用 wy_willStartMapping
    static func callWillStartMapping(for object: NSObject) {
        guard let codable = object as? WYCodableProtocol else { return }
        codable.wy_willStartMappingKey?()
    }
    
    /// 安全调用 wy_didFinishMapping
    static func callDidFinishMapping(for object: NSObject) {
        guard let codable = object as? WYCodableProtocol else { return }
        codable.wy_didFinishMappingKey?()
    }
    
    /// 安全调用 wy_convertValue
    static func callConvertValue(for object: NSObject, value: Any, key: String) -> Any? {
        guard let codable = object as? WYCodableProtocol else { return nil }
        return codable.wy_convertValue?(value, forKey: key)
    }
}

/// 属性包装器
internal struct WYCodableProperty {
    let name: String
    let attributes: String
}
