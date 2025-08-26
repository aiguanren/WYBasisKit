//
//  WYCodableObjc.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

@objc public enum WYCodableErrorObjC: Int, Error {
    /// 未知错误
    case unknown
    /// 类型不匹配
    case typeMismatch
    /// Model必须符合Codable协议
    case protocolMismatch
    /// 数据格式错误
    case dataFormatError
}

@objcMembers public class WYCodableObjC: NSObject {
    
    /// WYCodable的实例对象（内部使用）
    private let codable: WYCodable = WYCodable()
    
    // MARK: - 键值解码策略设置
    
    /// 设置键值解码策略(使用默认的键值策略，不进行任何转换)
    public func useDefaultKeys() {
        codable.mappingKeys = .useDefaultKeys
    }
    
    /// 设置键值解码策略(将蛇形命名法转换为驼峰命名法（例如：first_name -> firstName）)
    public func convertFromSnakeCase() {
        codable.mappingKeys = .convertFromSnakeCase
    }
    
    /// 设置键值解码策略(使用自定义的键名转换策略)
    public func customKeyMapping(_ handler: @escaping ([String]) -> String) {
        codable.mappingKeys = .custom { codingKeys in
            // 将 [CodingKey] 转换为 [String]
            let keyStrings = codingKeys.map { $0.stringValue }
            
            // 调用 handler
            let result = handler(keyStrings)
            
            // 将结果转换为 CodingKey
            return WYCodingKey(stringValue: result, intValue: nil)
        }
    }
    
    // MARK: - 解码方法
    
    /// 将String、Dictionary、Array、Data类型数据解析成传入的Model类型
    @objc public func decode(_ obj: AnyObject, modelClass: AnyClass) throws -> AnyObject {
        guard let codableType = modelClass as? NSObject.Type,
              let _ = codableType.init() as? Codable else {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        // 转换为Data
        var data: Data?
        
        if let string = obj as? String {
            data = try? string.wy_convertToData()
        } else if let dictionary = obj as? [String: Any] {
            data = try? JSONSerialization.data(withJSONObject: dictionary)
        } else if let array = obj as? [Any] {
            data = try? JSONSerialization.data(withJSONObject: array)
        } else if let nsData = obj as? Data {
            data = nsData
        }
        
        guard let validData = data else {
            throw WYCodableErrorObjC.typeMismatch
        }
        
        // 判断是数组还是单个对象
        if obj is [Any] {
            // 数组处理
            guard let elementType = modelClass as? Codable.Type else {
                throw WYCodableErrorObjC.protocolMismatch
            }
            
            // 使用运行时方法创建具体类型的数组
            let resultArray = try decodeArray(from: validData, elementType: elementType)
            return resultArray as AnyObject
        } else {
            // 单个对象处理
            guard let modelType = modelClass as? Codable.Type else {
                throw WYCodableErrorObjC.protocolMismatch
            }
            
            let result = try codable.decode(modelType, from: validData)
            guard let objectResult = result as? NSObject else {
                throw WYCodableErrorObjC.typeMismatch
            }
            return objectResult
        }
    }
    
    // MARK: - 编码方法
    
    /// 将传入的model转换成指定类型(convertType限String、Dictionary、Array、Data)
    @objc public func encode(_ model: AnyObject, convertType: AnyClass) throws -> AnyObject {
        guard let codableModel = model as? Codable else {
            throw WYCodableErrorObjC.protocolMismatch
        }
        
        if convertType == NSString.self {
            let result = try codable.encode(String.self, from: codableModel)
            return result as NSString
        } else if convertType == NSDictionary.self {
            let result = try codable.encode([String: Any].self, from: codableModel)
            return result as NSDictionary
        } else if convertType == NSArray.self {
            let result = try codable.encode([Any].self, from: codableModel)
            return result as NSArray
        } else if convertType == NSData.self {
            let result = try codable.encode(Data.self, from: codableModel)
            return result as NSData
        }
        
        throw WYCodableErrorObjC.typeMismatch
    }
    
    // MARK: - 类型转换方法
    
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
    
    // MARK: - 私有方法
    
    /// 解码数组的辅助方法
    private func decodeArray(from data: Data, elementType: Codable.Type) throws -> [Any] {
        // 使用 JSONSerialization 先解析为 [Any]
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw WYCodableErrorObjC.dataFormatError
        }
        
        var resultArray: [Any] = []
        
        for jsonElement in jsonArray {
            // 将每个元素转换为 Data
            let elementData = try JSONSerialization.data(withJSONObject: jsonElement)
            
            // 解码单个元素
            let element = try codable.decode(elementType, from: elementData)
            resultArray.append(element)
        }
        
        return resultArray
    }
}
