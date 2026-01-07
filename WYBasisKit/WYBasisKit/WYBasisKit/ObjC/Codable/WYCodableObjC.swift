//
//  WYCodableObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc(WYCodableError)
@frozen public enum WYCodableErrorObjC: Int, Error {
    /// 类型不匹配
    case typeMismatch
    /// Model必须符合WYCodableProtocol协议
    case protocolMismatch
    /// 数据格式错误
    case dataFormatError
}

@objc(WYCodable)
@objcMembers public class WYCodableObjC: NSObject {
    
    /// 检查类是否支持 WYCodableProtocol
    @objc public static func isClassSupportWYCodableProtocol(_ modelClass: AnyClass) -> Bool {
        // 检查类是否实现了 WYCodableProtocol 协议
        var currentClass: AnyClass? = modelClass
        while let cls = currentClass {
            // 获取类遵循的所有协议
            var count: UInt32 = 0
            let protocolList = class_copyProtocolList(cls, &count)
            if let protocolList = protocolList {
                for i in 0..<Int(count) {
                    let protocolName = NSStringFromProtocol(protocolList[i])
                    if protocolName.contains("WYCodableProtocol") {
                        free(UnsafeMutableRawPointer(protocolList))
                        return true
                    }
                }
                free(UnsafeMutableRawPointer(protocolList))
            }
            currentClass = class_getSuperclass(cls)
        }
        return false
    }
    
    /// 将String、Dictionary、Array、Data类型数据解析成传入的Model类型
    @objc public static func decode(_ obj: AnyObject, modelClass: AnyClass) throws -> AnyObject {
        
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
    
    /// 将传入的model转换成指定类型(convertType限String、Dictionary、Array、Data)
    @objc public static func encode(_ model: AnyObject, convertType: AnyClass) throws -> AnyObject {
        
        
        guard let object = model as? NSObject else {
            throw WYCodableErrorObjC.typeMismatch
        }
        
        // 检查是否支持 WYCodableProtocol
        let supportsProtocol = (object is WYCodableProtocol)
        
        if WYCodableConfig.debugMode {
            let className = NSStringFromClass(type(of: object))
            wy_codablePrint("WYCodable - Object \(className) supports WYCodableProtocol: \(supportsProtocol)")
        }
        
        // 只支持桥接方式
        if !supportsProtocol {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        // 使用桥接方式编码
        let jsonDict = WYCodableBridge.jsonFromObject(object)
        
        if convertType == NSString.self {
            // 转换为JSON字符串
            guard JSONSerialization.isValidJSONObject(jsonDict),
                  let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []),
                  let jsonString = String(data: data, encoding: .utf8) else {
                throw WYCodableErrorObjC.dataFormatError
            }
            return jsonString as NSString
        }
        else if convertType == NSDictionary.self {
            return jsonDict as NSDictionary
        }
        else if convertType == NSArray.self {
            // 如果是数组，返回包含单个字典的数组
            return [jsonDict] as NSArray
        }
        else if convertType == NSData.self {
            // 转换为Data
            guard JSONSerialization.isValidJSONObject(jsonDict),
                  let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
                throw WYCodableErrorObjC.dataFormatError
            }
            return data as NSData
        }
        
        throw WYCodableErrorObjC.typeMismatch
    }
    
    /// String转Dictionary
    @objc public static func stringToDictionary(_ string: String) throws -> NSDictionary {
        let dictionary = try string.wy_convertToDictionary()
        return dictionary as NSDictionary
    }
    
    /// String转Array
    @objc public static func stringToArray(_ string: String) throws -> NSArray {
        let array = try string.wy_convertToArray()
        return array as NSArray
    }
    
    /// String转Data
    @objc public static func stringToData(_ string: String) throws -> Data {
        let data = try string.wy_convertToData()
        return data as Data
    }
    
    /// Data转String
    @objc public static func dataToString(_ data: Data) throws -> String {
        let string = try data.wy_convertToString()
        return string as String
    }
    
    /// Data转Dictionary
    @objc public static func dataToDictionary(_ data: Data) throws -> NSDictionary {
        let dictionary = try data.wy_convertToDictionary()
        return dictionary as NSDictionary
    }
    
    /// Data转Array
    @objc public static func dataToArray(_ data: Data) throws -> NSArray {
        let array = try data.wy_convertToArray()
        return array as NSArray
    }
    
    /// Array转String
    @objc public static func arrayToString(_ array: NSArray) throws -> String {
        guard let swiftArray = array as? [Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let string = try swiftArray.wy_convertToString()
        return string as String
    }
    
    /// Array转Data
    @objc public static func arrayToData(_ array: NSArray) throws -> Data {
        guard let swiftArray = array as? [Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let data = try swiftArray.wy_convertToData()
        return data as Data
    }
    
    /// Dictionary转String
    @objc public static func dictionaryToString(_ dictionary: NSDictionary) throws -> String {
        guard let swiftDictionary = dictionary as? [String: Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let string = try swiftDictionary.wy_convertToString()
        return string as String
    }
    
    /// Dictionary转Data
    @objc public static func dictionaryToData(_ dictionary: NSDictionary) throws -> Data {
        guard let swiftDictionary = dictionary as? [String: Any] else {
            throw WYCodableErrorObjC.typeMismatch
        }
        let data = try swiftDictionary.wy_convertToData()
        return data as Data
    }
}

// MARK: - 桥接扩展（保持向后兼容）
@objc public extension WYCodableObjC {
    
    /// 使用桥接方式将JSON转换为对象（适用于非Codable的NSObject子类）
    @objc func bridgeDecode(_ json: [String: Any], toObject object: NSObject) -> Bool {
        return WYCodableBridge.updateObject(object, with: json)
    }
    
    /// 使用桥接方式创建对象
    @objc func bridgeCreateObject(from json: [String: Any], className: String) -> NSObject? {
        return WYCodableBridge.createObject(from: json, className: className)
    }
    
    /// 使用桥接方式将对象转换为JSON
    @objc func bridgeEncode(_ object: NSObject) -> [String: Any] {
        return WYCodableBridge.jsonFromObject(object)
    }
    
    /// 设置键值解码策略(使用默认的键值策略，不进行任何转换)
    @objc func useDefaultKeys() {
        // 桥接方案不需要这个配置，保持空实现以保持API兼容性
    }
    
    /// 设置键值解码策略(将蛇形命名法转换为驼峰命名法（例如：first_name -> firstName）)
    @objc func convertFromSnakeCase() {
        // 桥接方案不需要这个配置，保持空实现以保持API兼容性
    }
    
    /// 设置键值解码策略(使用自定义的键名转换策略)
    @objc func customKeyMapping(_ handler: @escaping ([String]) -> String) {
        // 桥接方案不需要这个配置，保持空实现以保持API兼容性
    }
}

private extension WYCodableObjC {
    
    static func decodeJSONObject(_ jsonObject: Any, toClass modelClass: AnyClass, supportsProtocol: Bool) throws -> AnyObject {
        let className = NSStringFromClass(modelClass)
        
        // 只支持桥接方式
        if !supportsProtocol {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        if let jsonArray = jsonObject as? [[String: Any]] {
            // 数组处理
            let resultArray = jsonArray.compactMap { jsonDict in
                return WYCodableBridge.createObject(from: jsonDict, className: className)
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
}
