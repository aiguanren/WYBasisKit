//
//  WYCodableBridge.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/21.
//

import Foundation

@objcMembers public class WYCodableBridge: NSObject {
    
    /// 编码：对象 -> JSON
    @objc public static func jsonFromObject(_ object: NSObject) -> [String: Any] {
        // 检查是否实现了协议
        guard object is WYCodableProtocol else {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Object does not conform to WYCodableProtocol: \(type(of: object))")
            }
            return [:]
        }
        
        WYCodableProtocolHelper.callWillStartMapping(for: object)
        defer { WYCodableProtocolHelper.callDidFinishMapping(for: object) }
        
        var result: [String: Any] = [:]
        let keyMapping = WYCodableProtocolHelper.getObjectKeyMapping(for: object)
        let containerMapping = WYCodableProtocolHelper.getObjectClassMapping(for: object)
        
        let properties = getAllProperties(of: object)
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - All properties found: \(properties.map { $0.name })")
        }
        
        for property in properties {
            let propertyName = property.name
            let jsonKey = keyMapping[propertyName] ?? propertyName
            
            // 跳过明确不需要编码的属性
            if shouldSkipProperty(propertyName) {
                continue
            }
            
            guard let value = getPropertyValue(for: property, from: object) else {
                continue
            }
            
            // 调试每个属性的值
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Processing property: \(propertyName) -> \(jsonKey), value: \(value)")
            }
            
            if let transformed = encodeValue(value, propertyName: propertyName, containerMapping: containerMapping) {
                result[jsonKey] = transformed
            }
        }
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Final encoded result: \(result)")
        }
        
        return result
    }
    
    @objc public static func jsonArrayFromObjects(_ objects: [NSObject]) -> [[String: Any]] {
        return objects.compactMap { jsonFromObject($0) }
    }
    
    // MARK: - 解码：JSON -> 对象
    @objc public static func updateObject(_ object: NSObject, with json: [String: Any]) -> Bool {
        // 检查是否实现了协议
        guard object is WYCodableProtocol else {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Object does not conform to WYCodableProtocol: \(type(of: object))")
            }
            return false
        }
        
        WYCodableProtocolHelper.callWillStartMapping(for: object)
        defer { WYCodableProtocolHelper.callDidFinishMapping(for: object) }
        
        let keyMapping = WYCodableProtocolHelper.getObjectKeyMapping(for: object)
        let containerMapping = WYCodableProtocolHelper.getObjectClassMapping(for: object)
        
        // 修复：明确指定字典类型
        let reverseMapping: [String: String] = Dictionary(uniqueKeysWithValues: keyMapping.map { ($1, $0) })
        
        let properties = getAllProperties(of: object)
        let propertyMap = Dictionary(uniqueKeysWithValues: properties.map { ($0.name, $0) })
        
        var success = true
        
        for (jsonKey, jsonValue) in json {
            let propertyName = reverseMapping[jsonKey] ?? jsonKey
            
            guard let property = propertyMap[propertyName] else {
                if !WYCodableConfig.ignoreUnknownProperties {
                    success = false
                    if WYCodableConfig.debugMode {
                        wy_codablePrint("WYCodable - Unknown property: \(propertyName)")
                    }
                }
                continue
            }
            
            if let value = decodeValue(jsonValue,
                                       property: property,
                                       propertyName: propertyName,
                                       object: object) {
                do {
                    try object.setValue(value, forKey: propertyName)
                } catch {
                    if WYCodableConfig.debugMode {
                        wy_codablePrint("WYCodable - Failed to set value for key: \(propertyName), error: \(error)")
                    }
                    success = false
                }
            } else {
                if WYCodableConfig.debugMode {
                    wy_codablePrint("WYCodable - Failed to decode value for key: \(propertyName)")
                }
                success = false
            }
        }
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Update \(success ? "success" : "partial success") for \(type(of: object))")
        }
        
        return success
    }
    
    @objc public static func createObject(from json: [String: Any], className: String) -> NSObject? {
        guard let cls = NSClassFromString(className) as? NSObject.Type else {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Class not found: \(className)")
            }
            return nil
        }
        
        let instance = cls.init()
        let success = updateObject(instance, with: json)
        return success ? instance : nil
    }
    
    // MARK: - 私有方法
    private static func getAllProperties(of object: NSObject) -> [WYCodableProperty] {
        var properties: [WYCodableProperty] = []
        var cls: AnyClass? = type(of: object)
        
        while let currentClass = cls, currentClass != NSObject.self {
            var count: UInt32 = 0
            if let propList = class_copyPropertyList(currentClass, &count) {
                for i in 0..<Int(count) {
                    let property = propList[i]
                    let name = String(cString: property_getName(property))
                    let attributes = property_getAttributes(property).map { String(cString: $0) } ?? ""
                    
                    if !name.hasPrefix("_") {
                        properties.append(WYCodableProperty(name: name, attributes: attributes))
                    }
                }
                free(propList)
            }
            cls = class_getSuperclass(currentClass)
        }
        
        return properties
    }
    
    private static func getPropertyValue(for property: WYCodableProperty, from object: NSObject) -> Any? {
        return object.value(forKey: property.name)
    }
    
    private static func encodeValue(_ value: Any, propertyName: String, containerMapping: [String: String]) -> Any? {
        return WYCodableValueTransformer.encodeValue(value)
    }
    
    private static func decodeValue(_ value: Any,
                                    property: WYCodableProperty,
                                    propertyName: String,
                                    object: NSObject) -> Any? {
        
        // 优先使用自定义转换
        if let customValue = WYCodableProtocolHelper.callConvertValue(for: object, value: value, key: propertyName) {
            return customValue
        }
        
        let (targetType, genericType) = getPropertyType(from: property.attributes)
        
        // 获取容器映射配置
        let containerMapping = WYCodableProtocolHelper.getObjectClassMapping(for: object)
        
        // 处理容器类型
        if let elementType = getElementType(for: propertyName, property: property, object: object) {
            return decodeContainerValue(value, elementType: elementType)
        }
        
        // 基础类型转换
        if let transformed = WYCodableValueTransformer.transformValue(value, toClass: targetType) {
            return transformed
        }
        
        // 嵌套对象处理
        if let dictValue = value as? [String: Any],
           let nestedObject = createObject(from: dictValue, className: targetType) {
            return nestedObject
        }
        
        return nil
    }
    
    /// 获取元素类型（统一处理容器类型识别）
    private static func getElementType(for propertyName: String, property: WYCodableProperty, object: NSObject) -> String? {
        // 1. 优先使用 wy_containerMapping 配置
        let containerMapping = WYCodableProtocolHelper.getObjectClassMapping(for: object)
        if let elementType = containerMapping[propertyName] {
            return elementType
        }
        
        // 2. 如果没有配置，尝试使用泛型信息
        let (_, genericType) = getPropertyType(from: property.attributes)
        return genericType
    }
    
    /// 解码容器值（简化参数）
    private static func decodeContainerValue(_ value: Any, elementType: String) -> Any? {
        if let array = value as? [Any] {
            let result: [Any] = array.compactMap { element in
                if let dict = element as? [String: Any],
                   let obj = createObject(from: dict, className: elementType) {
                    return obj
                }
                return WYCodableValueTransformer.transformValue(element, toClass: elementType)
            }
            return result
        }
        return value
    }
    
    private static func getPropertyType(from attributes: String) -> (String, String?) {
        let pattern = "T@\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: attributes, range: NSRange(location: 0, length: attributes.count)),
              match.numberOfRanges > 1 else {
            
            // 处理基础类型...
            return ("NSObject", nil)  // 这里也要保持一致
        }
        
        let fullType = (attributes as NSString).substring(with: match.range(at: 1))
        
        // 解析泛型信息
        if let genericMatch = parseGenericType(from: fullType) {
            return (genericMatch.containerType, genericMatch.elementType)
        }
        
        return (fullType, nil)
    }
    
    /// 解析泛型类型，如：NSArray<User> -> (containerType: "NSArray", elementType: "User")
    private static func parseGenericType(from typeString: String) -> (containerType: String, elementType: String?)? {
        // 匹配 NSArray<User> 或 NSArray<User *> 格式
        let pattern = "^(NSArray|NSMutableArray|NSDictionary|NSMutableDictionary)(?:<([^<>*]+)(?:\\s*\\*)?>)?$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: typeString, range: NSRange(location: 0, length: typeString.count)),
              match.numberOfRanges >= 2 else {
            return nil
        }
        
        let containerType = (typeString as NSString).substring(with: match.range(at: 1))
        
        // 如果有泛型参数
        if match.numberOfRanges >= 3 && match.range(at: 2).location != NSNotFound {
            let elementType = (typeString as NSString).substring(with: match.range(at: 2))
            return (containerType, elementType)
        }
        
        // 明确指定返回类型为 (String, String?)
        return (containerType, nil)
    }
    
    /// 判断是否应该跳过该属性
    private static func shouldSkipProperty(_ propertyName: String) -> Bool {
        
        let skipProperties: Set<String> = [
            // MARK: - NSObject 核心属性
            "hash",                   // 对象的哈希值
            "superclass",             // 父类信息
            "description",            // 对象描述
            "debugDescription",       // 调试描述
            
            // MARK: - KVC/KVO 相关
            "accessInstanceVariablesDirectly", // 是否直接访问实例变量
            "observationInfo",                 // KVO 观察信息
            
            // MARK: - 消息转发相关
            "methodSignatureForSelector",      // 方法签名
            "forwardInvocation",               // 消息转发
            
            // MARK: - 内存管理相关 (MRC/ARC)
            "retainCount",            // 引用计数 (MRC)
            "retain",                 // 保留对象 (MRC)
            "release",                // 释放对象 (MRC)
            "autorelease",            // 自动释放 (MRC)
            
            // MARK: - 运行时相关
            "zone",                   // 内存区域 (已废弃)
            "isProxy",                // 是否为代理对象
            
            // MARK: - 归档/序列化相关
            "classForKeyedArchiver",           // 归档类
            "replacementObjectForKeyedArchiver", // 归档替换对象
            "classForCoder",                   // 编码类
            "replacementObjectForCoder",       // 编码替换对象
            "secureCodingProtocol"             // 安全编码协议
        ]
        
        return skipProperties.contains(propertyName) || propertyName.hasPrefix("_")
    }
}

// MARK: - OC友好扩展
@objc public extension NSObject {
    
    // MARK: - 编码方法
    @objc func wy_toJSONDictionary() -> [String: Any] {
        return WYCodableBridge.jsonFromObject(self)
    }
    
    @objc func wy_toJSONData() -> Data? {
        let dict = wy_toJSONDictionary()
        guard JSONSerialization.isValidJSONObject(dict) else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
    @objc func wy_toJSONString() -> String? {
        guard let data = wy_toJSONData() else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - 解码方法
    @objc func wy_updateWithJSONDictionary(_ dict: [String: Any]) -> Bool {
        return WYCodableBridge.updateObject(self, with: dict)
    }
    
    @objc func wy_updateWithJSONData(_ data: Data) -> Bool {
        guard let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            return false
        }
        return wy_updateWithJSONDictionary(dict)
    }
    
    @objc func wy_updateWithJSONString(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        return wy_updateWithJSONData(data)
    }
    
    // MARK: - 类方法
    @objc static func wy_objectFromJSONDictionary(_ dict: [String: Any]) -> Self? {
        return WYCodableBridge.createObject(from: dict, className: NSStringFromClass(self)) as? Self
    }
    
    @objc static func wy_objectFromJSONData(_ data: Data) -> Self? {
        guard let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            return nil
        }
        return wy_objectFromJSONDictionary(dict)
    }
    
    @objc static func wy_objectFromJSONString(_ jsonString: String) -> Self? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return wy_objectFromJSONData(data)
    }
    
    @objc static func wy_objectsFromJSONArray(_ array: [[String: Any]]) -> [NSObject] {
        return array.compactMap { wy_objectFromJSONDictionary($0) }
    }
}
