//
//  WYCodableValueTransformer.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/21.
//

import Foundation

@objcMembers public class WYCodableValueTransformer: NSObject {
    
    /// 基础类型转换
    @objc public static func transformValue(_ value: Any, toClass className: String) -> Any? {
        switch className {
        case "NSString", "String":
            return transformToString(value)
        case "NSNumber", "Int", "NSInteger", "NSUInteger", "UInt":
            return transformToNumber(value)
        case "Double", "CGFloat", "Float":
            return transformToDouble(value)
        case "Bool", "BOOL":
            return transformToBool(value)
        case "NSData", "Data":
            return transformToData(value)
        case "NSDate", "Date":
            return transformToDate(value)
        case "NSArray", "Array":
            return transformToArray(value)
        case "NSDictionary", "Dictionary":
            return transformToDictionary(value)
        default:
            return value
        }
    }
    
    @objc public static func transformToString(_ value: Any) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return "\(value)"
    }
    
    @objc public static func transformToNumber(_ value: Any) -> NSNumber? {
        if let number = value as? NSNumber { return number }
        if let int = value as? Int { return NSNumber(value: int) }
        if let double = value as? Double { return NSNumber(value: double) }
        if let bool = value as? Bool { return NSNumber(value: bool) }
        if let string = value as? String {
            let scanner = Scanner(string: string)
            if scanner.scanDouble(nil) && scanner.isAtEnd {
                return NSNumber(value: Double(string) ?? 0)
            }
        }
        return nil
    }
    
    @objc public static func transformToDouble(_ value: Any) -> Double {
        if let double = value as? Double { return double }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) ?? 0 }
        return 0
    }
    
    @objc public static func transformToBool(_ value: Any) -> Bool {
        if let bool = value as? Bool { return bool }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String {
            let lowercased = string.lowercased()
            return ["true", "1", "yes", "y"].contains(lowercased)
        }
        return false
    }
    
    @objc public static func transformToData(_ value: Any) -> Data? {
        if let data = value as? Data { return data }
        if let string = value as? String {
            if string.hasPrefix(WYCodableConfig.dataPrefix) {
                let b64 = String(string.dropFirst(WYCodableConfig.dataPrefix.count))
                return Data(base64Encoded: b64)
            }
            return string.data(using: .utf8)
        }
        return nil
    }
    
    @objc public static func transformToDate(_ value: Any) -> Date? {
        if let date = value as? Date { return date }
        if let timeInterval = value as? TimeInterval { return Date(timeIntervalSince1970: timeInterval) }
        if let timeInterval = value as? Int { return Date(timeIntervalSince1970: TimeInterval(timeInterval)) }
        if let string = value as? String {
            return WYCodableConfig.dateFormatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
        }
        return nil
    }
    
    @objc public static func transformToArray(_ value: Any) -> [Any]? {
        return value as? [Any]
    }
    
    @objc public static func transformToDictionary(_ value: Any) -> [String: Any]? {
        return value as? [String: Any]
    }
    
    @objc public static func encodeValue(_ value: Any) -> Any? {
        return encodeValue(value, visitedObjects: NSHashTable<NSObject>.weakObjects())
    }
    
    /// 内部递归方法，跟踪已访问的对象以防止循环引用
    private static func encodeValue(_ value: Any, visitedObjects: NSHashTable<NSObject>) -> Any? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let date as Date:
            return WYCodableConfig.dateFormatter.string(from: date)
        case let data as Data:
            return WYCodableConfig.dataPrefix + data.base64EncodedString()
        case let array as [Any]:
            return array.map { encodeValue($0, visitedObjects: visitedObjects) ?? NSNull() }
        case let dictionary as [String: Any]:
            var result: [String: Any] = [:]
            for (key, value) in dictionary {
                result[key] = encodeValue(value, visitedObjects: visitedObjects) ?? NSNull()
            }
            return result
        case let object as NSObject:
            // 检查是否是基础类型，避免不必要的对象处理
            if isFoundationType(object) {
                return object
            }
            
            // 检查循环引用
            if visitedObjects.contains(object) {
                // 检测到循环引用，返回对象的描述或标识符
                return "Circular reference:\(object.hash)"
            }
            
            // 标记为已访问
            visitedObjects.add(object)
            
            // 使用桥接方式编码对象
            let json = WYCodableBridge.jsonFromObject(object)
            
            // 递归处理嵌套对象
            var processedJson: [String: Any] = [:]
            for (key, value) in json {
                processedJson[key] = encodeValue(value, visitedObjects: visitedObjects) ?? NSNull()
            }
            
            // 移除已访问标记（对于树形结构，但保留对循环引用的检测）
            // visitedObjects.remove(object) // 注释掉以保持对同一对象的循环引用检测
            
            return processedJson
        default:
            return "\(value)"
        }
    }
    
    /// 判断是否为 Foundation 基础类型
    private static func isFoundationType(_ object: NSObject) -> Bool {
        // NSString, NSNumber, NSDate, NSData 等基础类型
        if object is NSString || object is NSNumber || object is NSDate || object is NSData || object is CGFloat || object is Int || object is Double || object is UInt64 || object is Int64 {
            return true
        }
        
        // 集合类型
        if object is NSArray || object is NSDictionary || object is NSSet {
            return true
        }
        
        // 其他 Foundation 类型
        let className = NSStringFromClass(type(of: object))
        return className.hasPrefix("NS") || className.hasPrefix("__NSCF")
    }
    
    /// 清空编码对象缓存（用于重置状态）
    @objc public static func resetEncodingCache() {
        encodingObjects.removeAllObjects()
    }
    
    /// 用于检测循环引用的集合
    private static var encodingObjects = NSHashTable<NSObject>.weakObjects()
}
