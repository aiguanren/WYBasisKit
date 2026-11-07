//
//  WYCodableObjC+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

#if canImport(WYBasisKitSwift)
extension WYCodableObjC {

    @nonobjc internal var keyDecodingTransform: (([String]) -> String)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.keyDecodingTransform) as? ([String]) -> String
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.keyDecodingTransform, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private struct WYAssociatedKeys {
        static var keyDecodingTransform: UInt8 = 0
    }

    @nonobjc static func keyFromSnakeCase(_ codingPath: [String]) -> String {
        guard let key = codingPath.last,
              let first = key.firstIndex(where: { $0 != "_" }),
              let last = key.lastIndex(where: { $0 != "_" }) else { return codingPath.last ?? "" }
        let components = key[first...last].split(separator: "_")
        guard components.count > 1 else { return key }
        let converted = components[0].lowercased() + components.dropFirst().map { $0.capitalized }.joined()
        return String(key[..<first]) + converted + String(key[key.index(after: last)...])
    }
    
    static func decodeJSONObject(_ jsonObject: Any, toClass modelClass: AnyClass, supportsProtocol: Bool) throws -> AnyObject {
        let className = NSStringFromClass(modelClass)
        
        // 只支持桥接方式
        if !supportsProtocol {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        if let jsonArray = jsonObject as? [[String: Any]] {
            // 数组处理
            let resultArray = try jsonArray.map { jsonDict in
                guard let object = WYCodableBridge.createObject(from: jsonDict, className: className) else {
                    throw WYCodableErrorObjC.typeMismatch
                }
                return object
            }
            return resultArray as AnyObject
        } else if let jsonDict = jsonObject as? [String: Any] {
            // 单个对象处理
            guard let result = WYCodableBridge.createObject(from: jsonDict, className: className) else {
                throw WYCodableErrorObjC.typeMismatch
            }
            return result
        } else {
            throw WYCodableErrorObjC.dataFormatError
        }
    }

    @nonobjc static func internal_isClassSupportWYCodableProtocol(_ modelClass: AnyClass) -> Bool {
        // 检查类是否实现了 WYCodableProtocol 协议
        return modelClass is WYCodableProtocol.Type
    }

    @nonobjc static func internal_decode(_ obj: AnyObject, modelClass: AnyClass) throws -> AnyObject {

        let className = NSStringFromClass(modelClass)

        // 检查是否支持 WYCodableProtocol
        let supportsProtocol = WYCodableObjC.isClassSupportWYCodableProtocol(modelClass)

        if WYCodableConfig.debugMode {
            wy_codablePrint("WYCodable - Class \(className) supports WYCodableProtocol: \(supportsProtocol)")
        }

        // 处理字符串输入
        if let jsonString = obj as? String {
            guard let data = jsonString.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
                throw WYCodableErrorObjC.dataFormatError
            }
            return try decodeJSONObject(jsonObject, toClass: modelClass, supportsProtocol: supportsProtocol)
        }

        // 处理Data输入
        if let data = obj as? Data {
            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
                throw WYCodableErrorObjC.dataFormatError
            }
            return try decodeJSONObject(jsonObject, toClass: modelClass, supportsProtocol: supportsProtocol)
        }

        // 处理字典/数组输入
        return try decodeJSONObject(obj, toClass: modelClass, supportsProtocol: supportsProtocol)
    }

    @nonobjc static func internal_encode(_ model: AnyObject, convertType: AnyClass) throws -> AnyObject {


        let jsonObject: Any
        if let objects = model as? [NSObject] {
            guard objects.allSatisfy({ $0 is WYCodableProtocol }) else { throw WYCodableErrorObjC.protocolMismatch }
            jsonObject = objects.map { WYCodableBridge.jsonFromObject($0) }
        } else {
            guard let object = model as? NSObject else { throw WYCodableErrorObjC.typeMismatch }
            guard object is WYCodableProtocol else { throw WYCodableErrorObjC.protocolMismatch }
            jsonObject = WYCodableBridge.jsonFromObject(object)
        }
        if convertType == NSDictionary.self {
            guard let dictionary = jsonObject as? [String: Any] else { throw WYCodableErrorObjC.typeMismatch }
            return dictionary as NSDictionary
        }
        if convertType == NSArray.self {
            if let array = jsonObject as? [[String: Any]] { return array as NSArray }
            return [jsonObject] as NSArray
        }
        if convertType == NSString.self || convertType == NSData.self {
            guard JSONSerialization.isValidJSONObject(jsonObject),
                  let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
                throw WYCodableErrorObjC.dataFormatError
            }
            if convertType == NSData.self { return data as NSData }
            guard let string = String(data: data, encoding: .utf8) else { throw WYCodableErrorObjC.dataFormatError }
            return string as NSString
        }

        throw WYCodableErrorObjC.typeMismatch
    }

    @nonobjc static func internal_stringToDictionary(_ string: String) throws -> NSDictionary {
        let dictionary = try string.wy_convertToDictionary()
        return dictionary as NSDictionary
    }

    @nonobjc static func internal_stringToArray(_ string: String) throws -> NSArray {
        let array = try string.wy_convertToArray()
        return array as NSArray
    }

    @nonobjc static func internal_stringToData(_ string: String) throws -> Data {
        let data = try string.wy_convertToData()
        return data as Data
    }

    @nonobjc static func internal_dataToString(_ data: Data) throws -> String {
        let string = try data.wy_convertToString()
        return string as String
    }

    @nonobjc static func internal_dataToDictionary(_ data: Data) throws -> NSDictionary {
        let dictionary = try data.wy_convertToDictionary()
        return dictionary as NSDictionary
    }

    @nonobjc static func internal_dataToArray(_ data: Data) throws -> NSArray {
        let array = try data.wy_convertToArray()
        return array as NSArray
    }

    @nonobjc static func internal_arrayToString(_ array: NSArray) throws -> String {
        guard let swiftArray = array as? [Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let string = try swiftArray.wy_convertToString()
        return string as String
    }

    @nonobjc static func internal_arrayToData(_ array: NSArray) throws -> Data {
        guard let swiftArray = array as? [Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let data = try swiftArray.wy_convertToData()
        return data as Data
    }

    @nonobjc static func internal_dictionaryToString(_ dictionary: NSDictionary) throws -> String {
        guard let swiftDictionary = dictionary as? [String: Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let string = try swiftDictionary.wy_convertToString()
        return string as String
    }

    @nonobjc static func internal_dictionaryToData(_ dictionary: NSDictionary) throws -> Data {
        guard let swiftDictionary = dictionary as? [String: Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let data = try swiftDictionary.wy_convertToData()
        return data as Data
    }

    @nonobjc func internal_bridgeDecode(_ json: [String: Any], toObject object: NSObject) -> Bool {
        return WYCodableBridge.updateObject(object, with: json, keyTransform: keyDecodingTransform)
    }

    @nonobjc func internal_bridgeCreateObject(from json: [String: Any], className: String) -> NSObject? {
        return WYCodableBridge.createObject(from: json, className: className, keyTransform: keyDecodingTransform)
    }

    @nonobjc func internal_bridgeEncode(_ object: NSObject) -> [String: Any] {
        return WYCodableBridge.jsonFromObject(object)
    }

    @nonobjc func internal_useDefaultKeys() {
        keyDecodingTransform = nil
    }

    @nonobjc func internal_convertFromSnakeCase() {
        keyDecodingTransform = Self.keyFromSnakeCase
    }

    @nonobjc func internal_customKeyMapping(_ handler: @escaping ([String]) -> String) {
        keyDecodingTransform = handler
    }
}

#endif
