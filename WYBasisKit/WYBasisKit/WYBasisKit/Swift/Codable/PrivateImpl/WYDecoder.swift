//
//  WYDecoder.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

/**
 *  解码器协议(在系统 Decoder 之上补充可空解码，取不到值时返回 nil 而不抛错)
 *
 */
public protocol WYDecoder: Decoder {
    
    /// 当前正在解码的栈顶容器
    var topContainer: Any { get }
    
    /**
     *  判断栈顶是否为 null
     *
     */
    func decodeNil() -> Bool
    
    /**
     *  可空解码 Bool，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool?
    
    /**
     *  可空解码 Int，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: Int.Type) throws -> Int?
    
    /**
     *  可空解码 UInt，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: UInt.Type) throws -> UInt?
    
    /**
     *  可空解码 CGFloat，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: CGFloat.Type) throws -> CGFloat?
    
    /**
     *  可空解码 Double，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: Double.Type) throws -> Double?
    
    /**
     *  可空解码 String，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent(_ type: String.Type) throws -> String?
    
    /**
     *  可空解码任意 Decodable 类型，取不到或类型不符时返回 nil
     *
     *  @param type    要解码的类型
     *
     *  @return 解码出的值，取不到时为 nil
     *
     */
    func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T?
}

extension WYCodableInfo {
    
    var topContainer: Any {
        storage.topContainer
    }
    
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent(_ type: CGFloat.Type) throws -> CGFloat? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent(_ type: String.Type) throws -> String? {
        return try unbox(storage.topContainer, as: type)
    }
    
    func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T? {
        return try unbox(storage.topContainer, as: type)
    }
}

extension WYCodableInfo {
    
    /// 把 JSON 值拆成具体类型的值
    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        guard !(value is NSNull) else { return nil }
        
        if value is String {
            return (Int(value as? String ?? "") ?? 0) > 0
        }
        
        if let number = value as? NSNumber {
            if number === kCFBooleanTrue as NSNumber {
                return true
            } else if number === kCFBooleanFalse as NSNumber {
                return false
            }
        }
        
        return nil
    }
    
    func unbox(_ value: Any, as type: Int.Type) throws -> Int? {
        guard !(value is NSNull) else { return nil }
        
        if value is Bool {
            return ((value as? Bool ?? false) == true) ? 1 : 0
        }
        
        guard let number = value as? NSNumber,
              number !== kCFBooleanTrue,
              number !== kCFBooleanFalse else {
            return nil
        }
        
        let int = number.intValue
        guard NSNumber(value: int) == number else {
            return nil
        }
        
        return int
    }
    
    func unbox(_ value: Any, as type: UInt.Type) throws -> UInt? {
        guard !(value is NSNull) else { return nil }
        
        if value is Bool {
            return ((value as? Bool ?? false) == true) ? 1 : 0
        }
        
        guard let number = value as? NSNumber,
              number !== kCFBooleanTrue,
              number !== kCFBooleanFalse else {
            return nil
        }
        
        let uint = number.uintValue
        guard NSNumber(value: uint) == number else {
            return nil
        }
        
        return uint
    }
    
    func unbox(_ value: Any, as type: CGFloat.Type) throws -> CGFloat? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? NSNumber,
           number !== kCFBooleanTrue,
           number !== kCFBooleanFalse {
            /**
             *  允许有损转成 CGFloat，各来源的精度表现如下
             *  - 原值是整数时，超出 CGFloat 最大值会返回 nil，未超出时 2^24 之后的精度会丢
             *  - 原值是 Float 时返回精确值
             *  - 原值是 Double 或 Decimal 时返回能装下的最近似值
             */
            let double = number.doubleValue
            guard abs(double) <= Double(CGFloat.greatestFiniteMagnitude) else {
                return nil
            }
            
            return CGFloat(double)
            
        } else if value is String {
            return CGFloat(NumberFormatter().number(from: value as? String ?? "")?.floatValue ?? 0.0)
        }
        
        return nil
    }
    
    func unbox(_ value: Any, as type: Double.Type) throws -> Double? {
        guard !(value is NSNull) else { return nil }
        
        if let number = value as? NSNumber,
           number !== kCFBooleanTrue,
           number !== kCFBooleanFalse {
            /**
             *  始终允许按 Double 返回，各来源的精度表现如下
             *  - 原值是整数时必能装进 Double，UInt64 编码后按 Double 解码超过 2^53 的精度会丢
             *  - 原值是 Float 或 Double 时返回精确值
             *  - 原值是 Decimal 时返回最近似值
             */
            return number.doubleValue
            
        } else if value is String {
            return NumberFormatter().number(from: value as? String ?? "")?.doubleValue ?? 0.0
        }
        
        return nil
    }
    
    func unbox(_ value: Any, as type: String.Type) throws -> String? {
        guard !(value is NSNull) else { return nil }
        
        if value is String {
            return value as? String
        }
        
        if value is Int {
            let intValue: Int = value as? Int ?? Int.defaultValue
            return String(intValue)
        }
        
        if value is CGFloat {
            
            let floatValue: CGFloat = value as? CGFloat ?? CGFloat.defaultValue
            return String(format: "%f", floatValue)
        }
        
        if value is Double {
            let doubleValue: Double = value as? Double ?? Double.defaultValue
            return String(format: "%f", doubleValue)
        }
        
        if value is Dictionary<String, Any> {
            let dictionaryString: String = try (value as? Dictionary<String, Any>)?.wy_convertToString() ?? String.defaultValue
            return dictionaryString
        }
        
        if value is Array<Any> {
            let arrayString: String = try (value as? Array<Any>)?.wy_convertToString() ?? String.defaultValue
            return arrayString
        }
        
        if value is Data {
            let dataString: String = try (value as? Data)?.wy_convertToString() ?? String.defaultValue
            return dataString
        }
        
        return nil
    }
    
    func unbox(_ value: Any, as type: URL.Type) throws -> URL? {
        guard let string = try unbox(value, as: String.self) else { return nil }
        
        return URL(string: string)
    }
    
    func unbox<T>(_ value: Any, as type: _JSONStringDictionaryDecodableMarker.Type) throws -> T? {
        // 过滤掉 null
        if value is NSNull { return nil }
        
        // 确认是字典
        guard let dict = value as? [String: Any] else { return nil }
        
        var result = [String: Any]()
        let elementType = type.elementType
        
        for (key, val) in dict {
            self.codingPath.append(WYCodingKey(stringValue: key, intValue: nil))
            defer { self.codingPath.removeLast() }
            
            result[key] = try unbox_(val, as: elementType)
        }
        
        return result as? T
    }
    
    func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        return try unbox_(value, as: type) as? T
    }
    
    func unbox_(_ value: Any, as type: Decodable.Type) throws -> Any? {
        if type == URL.self {
            return try unbox(value, as: URL.self)
        } else if let stringKeyedDictType = type as? _JSONStringDictionaryDecodableMarker.Type {
            return try unbox(value, as: stringKeyedDictType)
        } else {
            storage.push(container: value)
            defer { storage.popContainer() }
            return try type.init(from: self)
        }
    }
}

protocol _JSONStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}

extension Dictionary : _JSONStringDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { return Value.self }
}

public protocol WYCodableContainerConvertible {
    func asJSONContainer() -> Any
}

extension Dictionary: WYCodableContainerConvertible where Key == String, Value == Any {
    public func asJSONContainer() -> Any { self }
}

extension Array: WYCodableContainerConvertible where Element == Any {
    public func asJSONContainer() -> Any { self }
}
