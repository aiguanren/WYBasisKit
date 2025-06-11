//
//  WYDecoder.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

public protocol WYDecoder: Decoder {
    
    var topContainer: Any { get }
    
    func decodeNil() -> Bool
    
    func decodeIfPresent(_ type: Bool.Type) throws -> Bool?
    
    func decodeIfPresent(_ type: Int.Type) throws -> Int?
    
    func decodeIfPresent(_ type: UInt.Type) throws -> UInt?
    
    func decodeIfPresent(_ type: CGFloat.Type) throws -> CGFloat?
    
    func decodeIfPresent(_ type: Double.Type) throws -> Double?
    
    func decodeIfPresent(_ type: String.Type) throws -> String?
    
    func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T?
}

// MARK: CleanDecoder Methods
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
    
    /// Returns the given value unboxed from a container.
    func unbox(_ value: Any, as type: Bool.Type) throws -> Bool? {
        guard !(value is NSNull) else { return nil }
        
        if value is String {
            return (NSInteger(value as? String ?? "") ?? 0) > 0
        }
        
        if let number = value as? NSNumber {
            // TODO: Add a flag to coerce non-boolean numbers into Bools?
            if number === kCFBooleanTrue as NSNumber {
                return true
            } else if number === kCFBooleanFalse as NSNumber {
                return false
            }
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let bool = value as? Bool {
             return bool
             */
            
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
            // We are willing to return a Float by losing precision:
            // * If the original value was integral,
            //   * and the integral value was > Float.greatestFiniteMagnitude, we will fail
            //   * and the integral value was <= Float.greatestFiniteMagnitude, we are willing to lose precision past 2^24
            // * If it was a Float, you will get back the precise value
            // * If it was a Double or Decimal, you will get back the nearest approximation if it will fit
            let double = number.doubleValue
            guard abs(double) <= Double(CGFloat.greatestFiniteMagnitude) else {
                return nil
            }
            
            return CGFloat(double)
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let double = value as? Double {
             if abs(double) <= Double(CGFloat.max) {
             return CGFloat(double)
             }
             
             overflow = true
             } else if let int = value as? Int {
             if let cgfloat = CGFloat(exactly: int) {
             return cgfloat
             }
             
             overflow = true
             */
            
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
            // We are always willing to return the number as a Double:
            // * If the original value was integral, it is guaranteed to fit in a Double; we are willing to lose precision past 2^53 if you encoded a UInt64 but requested a Double
            // * If it was a Float or Double, you will get back the precise value
            // * If it was Decimal, you will get back the nearest approximation
            return number.doubleValue
            
            /* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
             } else if let double = value as? Double {
             return double
             } else if let int = value as? Int {
             if let double = Double(exactly: int) {
             return double
             }
             
             overflow = true
             */
            
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
        guard !(value is NSNull) else { return nil }
        
        guard let dict = value as? NSDictionary else { return nil }
        
        var result = [String : Any]()
        let elementType = type.elementType
        for (key, value) in dict {
            let key = key as! String
            self.codingPath.append(WYCodingKey(stringValue: key, intValue: nil))
            defer { self.codingPath.removeLast() }
            
            result[key] = try unbox_(value, as: elementType)
        }
        
        return result as? T
    }
    
    func unbox<T : Decodable>(_ value: Any, as type: T.Type) throws -> T? {
        return try unbox_(value, as: type) as? T
    }
    
    func unbox_(_ value: Any, as type: Decodable.Type) throws -> Any? {
        if type == URL.self || type == NSURL.self {
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

// MARK: - helper
#if arch(i386) || arch(arm)
protocol _JSONStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}
#else
protocol _JSONStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}
#endif

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
