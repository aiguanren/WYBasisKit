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
        let visitedObjects = NSHashTable<NSObject>(options: [.weakMemory, .objectPointerPersonality])
        visitedObjects.add(object)
        return jsonFromObject(object, visitedObjects: visitedObjects)
    }

    @nonobjc static func jsonFromObject(_ object: NSObject, visitedObjects: NSHashTable<NSObject>) -> [String: Any] {
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
            
            if let transformed = WYCodableValueTransformer.encodeValue(value, visitedObjects: visitedObjects) {
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
    
    @objc public static func updateObject(_ object: NSObject, with json: [String: Any]) -> Bool {
        return updateObject(object, with: json, keyTransform: nil)
    }

    @nonobjc static func updateObject(_ object: NSObject,
                                     with json: [String: Any],
                                     keyTransform: (([String]) -> String)?,
                                     codingPath: [String] = []) -> Bool {
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
        let reverseMapping = Dictionary(grouping: keyMapping.keys.sorted(), by: { keyMapping[$0]! })
        
        let properties = getAllProperties(of: object)
        let propertyMap = Dictionary(uniqueKeysWithValues: properties.map { ($0.name, $0) })
        
        var success = true
        
        for (jsonKey, jsonValue) in json {
            let keyPath = codingPath + [jsonKey]
            let propertyNames: [String]
            if let mappedNames = reverseMapping[jsonKey] {
                propertyNames = mappedNames
            } else {
                let decodedKey = keyTransform?(keyPath) ?? jsonKey
                propertyNames = reverseMapping[decodedKey] ?? [decodedKey]
            }
            for propertyName in propertyNames {
                if shouldSkipProperty(propertyName) { continue }
                guard let property = propertyMap[propertyName] else {
                    if !WYCodableConfig.ignoreUnknownProperties {
                        success = false
                        if WYCodableConfig.debugMode {
                            wy_codablePrint("WYCodable - Unknown property: \(propertyName)")
                        }
                    }
                    continue
                }
                let attributes = property.attributes.components(separatedBy: ",")
                if attributes.contains("R") { continue }
                if jsonValue is NSNull {
                    if property.attributes.hasPrefix("T@") { object.setValue(nil, forKey: propertyName) }
                    continue
                }
                if let value = decodeValue(jsonValue,
                                           property: property,
                                           propertyName: propertyName,
                                           object: object,
                                           keyTransform: keyTransform,
                                           codingPath: keyPath) {
                    let (targetType, _) = getPropertyType(from: property.attributes)
                    if property.attributes.hasPrefix("T@"), let targetClass = NSClassFromString(targetType) {
                        guard let transformed = WYCodableValueTransformer.transformValue(value, toClass: targetType) as? NSObject,
                              transformed.isKind(of: targetClass) else {
                            success = false
                            continue
                        }
                        object.setValue(transformed, forKey: propertyName)
                    } else {
                        guard let transformed = decodeScalarValue(value, attributes: property.attributes) else {
                            success = false
                            continue
                        }
                        object.setValue(transformed, forKey: propertyName)
                    }
                } else {
                    if WYCodableConfig.debugMode {
                        wy_codablePrint("WYCodable - Failed to decode value for key: \(propertyName)")
                    }
                    success = false
                }
            }
        }

        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Update \(success ? "success" : "partial success") for \(type(of: object))")
        }
        
        return success
    }
    
    @objc public static func createObject(from json: [String: Any], className: String) -> NSObject? {
        return createObject(from: json, className: className, keyTransform: nil)
    }

    @nonobjc static func createObject(from json: [String: Any],
                                     className: String,
                                     keyTransform: (([String]) -> String)?,
                                     codingPath: [String] = []) -> NSObject? {
        guard let cls = NSClassFromString(className) as? NSObject.Type else {
            if WYCodableConfig.debugMode {
                wy_codablePrint("WYCodable - Class not found: \(className)")
            }
            return nil
        }
        
        let instance = cls.init()
        let success = updateObject(instance, with: json, keyTransform: keyTransform, codingPath: codingPath)
        return success ? instance : nil
    }
    
    private static func getAllProperties(of object: NSObject) -> [WYCodableProperty] {
        var properties: [WYCodableProperty] = []
        var cls: AnyClass? = type(of: object)
        
        // 使用 Set 来跟踪已经处理过的属性名，避免重复
        var processedPropertyNames = Set<String>()
        
        while let currentClass = cls {
            // 如果是系统框架的类，跳过（只处理用户自定义类）
            if currentClass == NSObject.self || Bundle(for: currentClass) == Bundle(for: NSObject.self) {
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
    
    private static func decodeValue(_ value: Any,
                                    property: WYCodableProperty,
                                    propertyName: String,
                                    object: NSObject,
                                    keyTransform: (([String]) -> String)?,
                                    codingPath: [String]) -> Any? {
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Decoding property: \(propertyName)")
            wy_codablePrint("WYCodable - Property attributes: \(property.attributes)")
            wy_codablePrint("WYCodable - Value type: \(type(of: value)), value: \(value)")
        }
        
        // 优先使用自定义转换
        if let customValue = WYCodableProtocolHelper.callConvertValue(for: object, value: value, key: propertyName) {
            return customValue
        }
        
        if !property.attributes.hasPrefix("T@") {
            return decodeScalarValue(value, attributes: property.attributes)
        }

        let (targetType, genericType) = getPropertyType(from: property.attributes)
        if let modelClass = WYCodableProtocolHelper.getObjectClassMapping(for: object)[propertyName] {
            let className = NSStringFromClass(modelClass)
            if let dictionary = value as? [String: Any] { return createObject(from: dictionary, className: className, keyTransform: keyTransform, codingPath: codingPath) }
            if let array = value as? [Any] { return decodeObjectArray(array, elementType: className, keyTransform: keyTransform, codingPath: codingPath) }
        }
        
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Property \(propertyName) targetType: \(targetType), genericType: \(genericType ?? "nil")")
        }
        
        // 处理嵌套对象（字典 -> 对象）
        if let dictValue = value as? [String: Any] {
            // 如果没有配置，尝试使用属性类型
            if targetType != "NSDictionary" && targetType != "NSMutableDictionary" && targetType != "NSObject" {
                return createObject(from: dictValue, className: targetType, keyTransform: keyTransform, codingPath: codingPath)
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
                return decodeObjectArray(arrayValue, elementType: elementType, keyTransform: keyTransform, codingPath: codingPath)
            }
            // 2. 自动推断：根据属性名和数组内容推断元素类型
            else if let inferredType = autoInferArrayElementType(propertyName: propertyName,
                                                                 array: arrayValue,
                                                                 object: object) {
                if WYCodableConfig.debugMode {
                    wy_codablePrint("WYCodable - Auto-inferred element type: \(inferredType) for property: \(propertyName)")
                }
                return decodeObjectArray(arrayValue, elementType: inferredType, keyTransform: keyTransform, codingPath: codingPath)
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
    
    private static func decodeScalarValue(_ value: Any, attributes: String) -> Any? {
        let encoding = attributes.components(separatedBy: ",").first ?? ""
        let bounds: (NSNumber, NSNumber)
        switch encoding {
        case "Tc": bounds = (NSNumber(value: Int8.min), NSNumber(value: Int8.max))
        case "TC": bounds = (NSNumber(value: UInt8.min), NSNumber(value: UInt8.max))
        case "Ts": bounds = (NSNumber(value: Int16.min), NSNumber(value: Int16.max))
        case "TS": bounds = (NSNumber(value: UInt16.min), NSNumber(value: UInt16.max))
        case "Ti": bounds = (NSNumber(value: Int32.min), NSNumber(value: Int32.max))
        case "TI": bounds = (NSNumber(value: UInt32.min), NSNumber(value: UInt32.max))
        case "Tl": bounds = (NSNumber(value: CLong.min), NSNumber(value: CLong.max))
        case "TL": bounds = (NSNumber(value: CUnsignedLong.min), NSNumber(value: CUnsignedLong.max))
        case "Tq": bounds = (NSNumber(value: Int64.min), NSNumber(value: Int64.max))
        case "TQ": bounds = (NSNumber(value: UInt64.min), NSNumber(value: UInt64.max))
        case "Tf", "Td":
            guard let number = WYCodableValueTransformer.transformToNumber(value), number.doubleValue.isFinite else { return nil }
            if encoding == "Tf", !Float(number.doubleValue).isFinite { return nil }
            return number
        case "TB":
            if let string = value as? String {
                switch string.lowercased() {
                case "true", "yes", "y", "1": return NSNumber(value: true)
                case "false", "no", "n", "0": return NSNumber(value: false)
                default: return nil
                }
            }
            guard let number = value as? NSNumber, number == NSNumber(value: false) || number == NSNumber(value: true) else { return nil }
            return number
        default: return value
        }
        let number: NSNumber
        if let string = value as? String, let integer = Int64(string) {
            number = NSNumber(value: integer)
        } else if let string = value as? String, let integer = UInt64(string) {
            number = NSNumber(value: integer)
        } else if let transformed = WYCodableValueTransformer.transformToNumber(value) {
            number = transformed
        } else {
            return nil
        }
        guard number.doubleValue.isFinite else { return nil }
        let locale = Locale(identifier: "en_US_POSIX")
        guard var decimal = Decimal(string: number.stringValue, locale: locale),
              let minimum = Decimal(string: bounds.0.stringValue, locale: locale),
              let maximum = Decimal(string: bounds.1.stringValue, locale: locale) else { return nil }
        var integer = Decimal()
        NSDecimalRound(&integer, &decimal, 0, .down)
        guard decimal == integer, decimal >= minimum, decimal <= maximum else { return nil }
        return number
    }

    /// 自动推断数组元素类型
    private static func autoInferArrayElementType(propertyName: String, array: [Any], object: NSObject) -> String? {
        
        // 方法1：根据属性名推断（复数 -> 单数）
        if let inferredFromName = inferElementTypeFromPropertyName(propertyName) {
            return inferredFromName
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
    private static func decodeObjectArray(_ array: [Any],
                                          elementType: String,
                                          keyTransform: (([String]) -> String)?,
                                          codingPath: [String]) -> [Any]? {
        var result: [Any] = []
        
        for (index, element) in array.enumerated() {
            if let dictionary = element as? [String: Any] {
                guard let object = createObject(from: dictionary, className: elementType, keyTransform: keyTransform, codingPath: codingPath + ["Index \(index)"]) else { return nil }
                result.append(object)
            } else {
                guard let objectClass = NSClassFromString(elementType),
                      let transformed = WYCodableValueTransformer.transformValue(element, toClass: elementType) as? NSObject,
                      transformed.isKind(of: objectClass) else { return nil }
                result.append(transformed)
            }
        }
        return result
    }

    private static func getPropertyType(from attributes: String) -> (String, String?) {
        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Parsing property attributes: \(attributes)")
        }
        
        let pattern = "T@\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: attributes, range: NSRange(location: 0, length: (attributes as NSString).length)),
              match.numberOfRanges > 1 else {
            let encoding = attributes.components(separatedBy: ",").first ?? ""
            switch encoding {
            case "Tc", "TC", "Ts", "TS", "Ti", "TI", "Tl", "TL", "Tq", "TQ": return ("NSNumber", nil)
            case "Tf", "Td": return ("Double", nil)
            case "TB": return ("Bool", nil)
            default: return ("NSObject", nil)
            }
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

@objc public extension NSObject {
    
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
