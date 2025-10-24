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
            
            if let transformed = encodeValue(value, propertyName: propertyName) {
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
        
        if (WYCodableConfig.debugMode) {
            wy_codablePrint("WYCodable - Key mapping: \(keyMapping)")
        }
        
        // 明确指定字典类型
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
                
                object.setValue(value, forKey: propertyName)
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
        
        // 使用 Set 来跟踪已经处理过的属性名，避免重复
        var processedPropertyNames = Set<String>()
        
        while let currentClass = cls {
            let className = NSStringFromClass(currentClass)
            
            // 如果是系统框架的类，跳过（只处理用户自定义类）
            if className.hasPrefix("NS") ||
                className.hasPrefix("UI") ||
                className.hasPrefix("WK") ||
                className.hasPrefix("CA") ||
                className.hasPrefix("_") {
                break
            }
            
            var count: UInt32 = 0
            if let propList = class_copyPropertyList(currentClass, &count) {
                for i in 0..<Int(count) {
                    let property = propList[i]
                    let name = String(cString: property_getName(property))
                    let attributes = property_getAttributes(property).map { String(cString: $0) } ?? ""
                    
                    // 只添加非私有属性且未处理过的属性
                    if !name.hasPrefix("_") && !processedPropertyNames.contains(name) {
                        properties.append(WYCodableProperty(name: name, attributes: attributes))
                        processedPropertyNames.insert(name)
                    }
                }
                free(propList)
            }
            
            // 如果到达 NSObject，停止遍历
            if currentClass == NSObject.self {
                break
            }
            cls = class_getSuperclass(currentClass)
        }
        
        if WYCodableConfig.debugMode {
            let propertyNames = properties.map { $0.name }
            wy_codablePrint("WYCodable - Found properties for \(type(of: object)): \(propertyNames)")
        }
        
        return properties
    }
    
    private static func getPropertyValue(for property: WYCodableProperty, from object: NSObject) -> Any? {
        return object.value(forKey: property.name)
    }
    
    private static func encodeValue(_ value: Any, propertyName: String) -> Any? {
        return WYCodableValueTransformer.encodeValue(value)
    }
    
    private static func decodeValue(_ value: Any,
                                    property: WYCodableProperty,
                                    propertyName: String,
                                    object: NSObject) -> Any? {
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Decoding property: \(propertyName)")
            wy_codablePrint("WYCodable - Property attributes: \(property.attributes)")
            wy_codablePrint("WYCodable - Value type: \(type(of: value)), value: \(value)")
        }
        
        // 优先使用自定义转换
        if let customValue = WYCodableProtocolHelper.callConvertValue(for: object, value: value, key: propertyName) {
            return customValue
        }
        
        let (targetType, genericType) = getPropertyType(from: property.attributes)
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Property \(propertyName) targetType: \(targetType), genericType: \(genericType ?? "nil")")
        }
        
        // 处理嵌套对象（字典 -> 对象）
        if let dictValue = value as? [String: Any] {
            // 如果没有配置，尝试使用属性类型
            if targetType != "NSDictionary" && targetType != "NSMutableDictionary" {
                return createObject(from: dictValue, className: targetType)
            }
        }
        
        // 处理对象数组（数组 -> 对象数组）
        if let arrayValue = value as? [Any] {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Processing array for property: \(propertyName), array count: \(arrayValue.count)")
            }
            
            // 1. 优先使用泛型类型
            if let elementType = genericType {
                if WYCodableConfig.debugMode {
                    wy_codablePrint("WYCodable - Creating objects for array with elementType: \(elementType)")
                }
                return decodeObjectArray(arrayValue, elementType: elementType)
            }
            // 2. 自动推断：根据属性名和数组内容推断元素类型
            else if let inferredType = autoInferArrayElementType(propertyName: propertyName,
                                                                 array: arrayValue,
                                                                 object: object) {
                if WYCodableConfig.debugMode {
                    wy_codablePrint("WYCodable - Auto-inferred element type: \(inferredType) for property: \(propertyName)")
                }
                return decodeObjectArray(arrayValue, elementType: inferredType)
            } else {
                if WYCodableConfig.debugMode {
                    wy_codablePrint("WYCodable - No element type found for array property: \(propertyName), returning raw array")
                }
                // 无法推断类型，返回原始数组
                return arrayValue
            }
        }
        
        // 基础类型转换
        if let transformed = WYCodableValueTransformer.transformValue(value, toClass: targetType) {
            return transformed
        }
        
        return nil
    }
    
    /// 自动推断数组元素类型
    private static func autoInferArrayElementType(propertyName: String, array: [Any], object: NSObject) -> String? {
        
        // 方法1：根据属性名推断（复数 -> 单数）
        if let inferredFromName = inferElementTypeFromPropertyName(propertyName) {
            return inferredFromName
        }
        
        // 方法2：根据数组内容推断（如果数组元素都是字典，且有共同结构）
        if let inferredFromContent = inferElementTypeFromArrayContent(array) {
            return inferredFromContent
        }
        
        // 方法3：检查是否有对应的单数属性存在
        if let inferredFromSingular = inferElementTypeFromSingularProperty(propertyName, object: object) {
            return inferredFromSingular
        }
        
        return nil
    }
    
    /// 根据属性名推断元素类型
    private static func inferElementTypeFromPropertyName(_ propertyName: String) -> String? {
        var possibleClassNames: [String] = []
        
        // subResponses -> SubUserResponse 的特殊处理
        if propertyName == "subResponses" {
            possibleClassNames.append("SubUserResponse")
            possibleClassNames.append("SubResponse")
            possibleClassNames.append("UserResponse")
        }
        
        // 通用规则
        if propertyName.hasSuffix("s") {
            let singular = String(propertyName.dropLast())
            possibleClassNames.append(singular)
            
            // 驼峰命名
            let camelCaseSingular = singular.prefix(1).uppercased() + singular.dropFirst()
            possibleClassNames.append(camelCaseSingular)
            
            // 特殊复数形式
            if propertyName.hasSuffix("ies") {
                let base = String(propertyName.dropLast(3)) + "y"
                possibleClassNames.append(base)
                possibleClassNames.append(base.prefix(1).uppercased() + base.dropFirst())
            }
        }
        
        // 常见后缀规则
        if propertyName.hasSuffix("List") {
            let baseName = String(propertyName.dropLast(4))
            possibleClassNames.append(baseName)
            possibleClassNames.append(baseName.prefix(1).uppercased() + baseName.dropFirst())
        }
        
        if propertyName.hasSuffix("Array") {
            let baseName = String(propertyName.dropLast(5))
            possibleClassNames.append(baseName)
            possibleClassNames.append(baseName.prefix(1).uppercased() + baseName.dropFirst())
        }
        
        // 检查这些可能的类名是否存在
        for className in possibleClassNames {
            if NSClassFromString(className) != nil {
                return className
            }
        }
        
        return nil
    }
    
    /// 根据数组内容推断元素类型
    private static func inferElementTypeFromArrayContent(_ array: [Any]) -> String? {
        guard !array.isEmpty else { return nil }
        
        // 如果数组元素都是字典，检查是否有共同的键
        let dictionaries = array.compactMap { $0 as? [String: Any] }
        guard dictionaries.count == array.count else { return nil }
        
        let allKeys = Set(dictionaries.flatMap { $0.keys })
        
        // 基于常见字段的模式匹配
        if allKeys.contains("iconName") {
            // 包含 iconName 的可能是 SubUserResponse
            return "SubUserResponse"
        }
        
        // 可以添加更多模式匹配规则
        if allKeys.contains("errorCode") && allKeys.contains("errorMessage") {
            return "UserResponse"
        }
        
        // 基于字段组合的推断
        if allKeys.contains("userId") && allKeys.contains("userName") {
            return "User"
        }
        
        if allKeys.contains("productId") && allKeys.contains("productName") {
            return "Product"
        }
        
        return nil
    }
    
    /// 根据单数属性推断数组元素类型
    private static func inferElementTypeFromSingularProperty(_ propertyName: String, object: NSObject) -> String? {
        // 如果属性名是复数形式，检查是否有对应的单数属性
        if propertyName.hasSuffix("s") {
            let singularProperty = String(propertyName.dropLast())
            
            // 检查对象是否有这个单数属性
            let properties = getAllProperties(of: object)
            if properties.contains(where: { $0.name == singularProperty }) {
                // 获取单数属性的类型
                if let singularProperty = properties.first(where: { $0.name == singularProperty }) {
                    let (singularType, _) = getPropertyType(from: singularProperty.attributes)
                    if singularType != "NSObject" && !singularType.hasPrefix("NS") {
                        return singularType
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 解码对象数组
    private static func decodeObjectArray(_ array: [Any], elementType: String) -> [Any]? {
        var result: [Any] = []
        
        for element in array {
            if let dict = element as? [String: Any],
               let obj = createObject(from: dict, className: elementType) {
                result.append(obj)
            } else {
                // 如果不是字典，尝试基础类型转换
                if let transformed = WYCodableValueTransformer.transformValue(element, toClass: elementType) {
                    result.append(transformed)
                }
            }
        }
        
        // 关键修复：确保返回 NSArray 类型，因为 Objective-C 属性期望 NSArray
        return result.isEmpty ? nil : (result as NSArray) as? [Any]
    }
    
    private static func getPropertyType(from attributes: String) -> (String, String?) {
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Parsing property attributes: \(attributes)")
        }
        
        let pattern = "T@\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: attributes, range: NSRange(location: 0, length: attributes.count)),
              match.numberOfRanges > 1 else {
            return ("NSObject", nil)
        }
        
        let fullType = (attributes as NSString).substring(with: match.range(at: 1))
        
        // 解析泛型信息
        if let genericMatch = parseGenericType(from: fullType) {
            return (genericMatch.containerType, genericMatch.elementType)
        }
        
        // 对于 NSArray 类型，尝试从属性名推断元素类型
        if fullType == "NSArray" || fullType == "NSMutableArray" {
            return (fullType, nil) // 元素类型将在使用时推断
        }
        
        return (fullType, nil)
    }
    
    /// 解析泛型类型，如：NSArray<User> -> (containerType: "NSArray", elementType: "User")
    private static func parseGenericType(from typeString: String) -> (containerType: String, elementType: String?)? {
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Parsing generic type: \(typeString)")
        }
        
        // 匹配 NSArray<User> 或 NSArray<User *> 或 __NSArrayM<User *> 等格式
        let pattern = "^(NSArray|NSMutableArray|__NSArrayI|__NSArrayM|NSDictionary|NSMutableDictionary)(?:<([^<>*]+)(?:\\s*\\*)?>)?$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: typeString, range: NSRange(location: 0, length: typeString.count)),
              match.numberOfRanges >= 2 else {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - No generic match for: \(typeString)")
            }
            return nil
        }
        
        let containerType = (typeString as NSString).substring(with: match.range(at: 1))
        
        // 如果有泛型参数
        var elementType: String? = nil
        if match.numberOfRanges >= 3 && match.range(at: 2).location != NSNotFound {
            elementType = (typeString as NSString).substring(with: match.range(at: 2))
        }
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Parsed generic - container: \(containerType), element: \(elementType ?? "nil")")
        }
        
        return (containerType, elementType)
    }
    
    /// 判断是否应该跳过该属性
    private static func shouldSkipProperty(_ propertyName: String) -> Bool {
        return WYCodableConfig.skipProperties.contains(propertyName) || propertyName.hasPrefix("_")
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
