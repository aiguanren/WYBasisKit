//
//  WYCodableObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

#if canImport(WYBasisKitSwift)
import WYBasisKitSwift

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
        return internal_isClassSupportWYCodableProtocol(modelClass)
    }
    
    /// 将String、Dictionary、Array、Data类型数据解析成传入的Model类型
    @objc public static func decode(_ obj: AnyObject, modelClass: AnyClass) throws -> AnyObject {
        return try internal_decode(obj, modelClass: modelClass)
    }
    
    /// 将传入的model转换成指定类型(convertType限String、Dictionary、Array、Data)
    @objc public static func encode(_ model: AnyObject, convertType: AnyClass) throws -> AnyObject {
        return try internal_encode(model, convertType: convertType)
    }
    
    /// String转Dictionary
    @objc public static func stringToDictionary(_ string: String) throws -> NSDictionary {
        return try internal_stringToDictionary(string)
    }
    
    /// String转Array
    @objc public static func stringToArray(_ string: String) throws -> NSArray {
        return try internal_stringToArray(string)
    }
    
    /// String转Data
    @objc public static func stringToData(_ string: String) throws -> Data {
        return try internal_stringToData(string)
    }
    
    /// Data转String
    @objc public static func dataToString(_ data: Data) throws -> String {
        return try internal_dataToString(data)
    }
    
    /// Data转Dictionary
    @objc public static func dataToDictionary(_ data: Data) throws -> NSDictionary {
        return try internal_dataToDictionary(data)
    }
    
    /// Data转Array
    @objc public static func dataToArray(_ data: Data) throws -> NSArray {
        return try internal_dataToArray(data)
    }
    
    /// Array转String
    @objc public static func arrayToString(_ array: NSArray) throws -> String {
        return try internal_arrayToString(array)
    }
    
    /// Array转Data
    @objc public static func arrayToData(_ array: NSArray) throws -> Data {
        return try internal_arrayToData(array)
    }
    
    /// Dictionary转String
    @objc public static func dictionaryToString(_ dictionary: NSDictionary) throws -> String {
        return try internal_dictionaryToString(dictionary)
    }
    
    /// Dictionary转Data
    @objc public static func dictionaryToData(_ dictionary: NSDictionary) throws -> Data {
        return try internal_dictionaryToData(dictionary)
    }
}

@objc public extension WYCodableObjC {
    
    /// 使用桥接方式将JSON转换为对象（适用于非Codable的NSObject子类）
    @objc func bridgeDecode(_ json: [String: Any], toObject object: NSObject) -> Bool {
        return internal_bridgeDecode(json, toObject: object)
    }
    
    /// 使用桥接方式创建对象
    @objc func bridgeCreateObject(from json: [String: Any], className: String) -> NSObject? {
        return internal_bridgeCreateObject(from: json, className: className)
    }
    
    /// 使用桥接方式将对象转换为JSON
    @objc func bridgeEncode(_ object: NSObject) -> [String: Any] {
        return internal_bridgeEncode(object)
    }
    
    /// 设置键值解码策略(使用默认的键值策略，不进行任何转换)
    @objc func useDefaultKeys() {
        internal_useDefaultKeys()
    }
    
    /// 设置键值解码策略(将蛇形命名法转换为驼峰命名法（例如：first_name -> firstName）)
    @objc func convertFromSnakeCase() {
        internal_convertFromSnakeCase()
    }
    
    /// 设置键值解码策略(使用自定义的键名转换策略)
    @objc func customKeyMapping(_ handler: @escaping ([String]) -> String) {
        internal_customKeyMapping(handler)
    }
}

#endif

/// 自定义Codable协议
@objc public protocol WYCodableProtocol: NSObjectProtocol {

    /// 指定属性名映射，解决关键字段冲突，如：@{@"objectProperty": @"json_key"}
    @objc optional static func wy_objectKeyMapping() -> [String: String]

    /**
     指定嵌套对象或数组元素的模型类型
     @return 属性名与模型类型的对应关系
     */
    @objc(wy_objectClassMapping) optional static func wy_objectClassMapping() -> [String: AnyClass]

    /// Key映射开始回调
    @objc optional func wy_willStartMappingKey()

    /// Key映射完成回调
    @objc optional func wy_didFinishMappingKey()

    /// 自定义类型转换（用于特殊场景处理）
    @objc optional func wy_convertValue(_ value: Any, forKey key: String) -> Any?
}

@objcMembers public class WYCodableConfig: NSObject {

    /// 日期格式化器（可自定义）
    @objc public static var dateFormatter: DateFormatter = internal_dateFormatter()

    /// Data 在 JSON 中的表示前缀
    @objc public static var dataPrefix: String = "__WYCODABLE_DATA__:"

    /// 是否启用调试模式
    @objc public static var debugMode: Bool = false

    /// 是否忽略未知属性（默认true）
    @objc public static var ignoreUnknownProperties: Bool = true

    /// 自定义需要跳过的属性名（如果设置了，将覆盖默认的系统属性过滤）
    @objc public static var skipProperties: Set<String> = defaultSkipProperties()

    /// 默认过滤属性
    @objc public static func defaultSkipProperties() -> Set<String> {
        return internal_defaultSkipProperties()
    }
}

@objcMembers public class WYCodableBridge: NSObject {

    /// 编码：对象 -> JSON
    @objc public static func jsonFromObject(_ object: NSObject) -> [String: Any] {
        return internal_jsonFromObject(object)
    }

    @objc public static func jsonArrayFromObjects(_ objects: [NSObject]) -> [[String: Any]] {
        return internal_jsonArrayFromObjects(objects)
    }

    @objc public static func updateObject(_ object: NSObject, with json: [String: Any]) -> Bool {
        return internal_updateObject(object, with: json)
    }

    @objc public static func createObject(from json: [String: Any], className: String) -> NSObject? {
        return internal_createObject(from: json, className: className)
    }
}

@objcMembers public class WYCodableValueTransformer: NSObject {

    /// 基础类型转换
    @objc public static func transformValue(_ value: Any, toClass className: String) -> Any? {
        return internal_transformValue(value, toClass: className)
    }

    @objc public static func transformToString(_ value: Any) -> String? {
        return internal_transformToString(value)
    }

    @objc public static func transformToNumber(_ value: Any) -> NSNumber? {
        return internal_transformToNumber(value)
    }

    @objc public static func transformToDouble(_ value: Any) -> Double {
        return internal_transformToDouble(value)
    }

    @objc public static func transformToBool(_ value: Any) -> Bool {
        return internal_transformToBool(value)
    }

    @objc public static func transformToData(_ value: Any) -> Data? {
        return internal_transformToData(value)
    }

    @objc public static func transformToDate(_ value: Any) -> Date? {
        return internal_transformToDate(value)
    }

    @objc public static func transformToArray(_ value: Any) -> [Any]? {
        return internal_transformToArray(value)
    }

    @objc public static func transformToDictionary(_ value: Any) -> [String: Any]? {
        return internal_transformToDictionary(value)
    }

    @objc public static func encodeValue(_ value: Any) -> Any? {
        return internal_encodeValue(value)
    }

    /// 清空编码对象缓存（用于重置状态）
    @objc public static func resetEncodingCache() {
        internal_resetEncodingCache()
    }
}

@objc public extension NSObject {

    @objc func wy_toJSONDictionary() -> [String: Any] {
        return internal_wy_toJSONDictionary()
    }

    @objc func wy_toJSONData() -> Data? {
        return internal_wy_toJSONData()
    }

    @objc func wy_toJSONString() -> String? {
        return internal_wy_toJSONString()
    }

    @objc func wy_updateWithJSONDictionary(_ dict: [String: Any]) -> Bool {
        return internal_wy_updateWithJSONDictionary(dict)
    }

    @objc func wy_updateWithJSONData(_ data: Data) -> Bool {
        return internal_wy_updateWithJSONData(data)
    }

    @objc func wy_updateWithJSONString(_ jsonString: String) -> Bool {
        return internal_wy_updateWithJSONString(jsonString)
    }

    @objc static func wy_objectFromJSONDictionary(_ dict: [String: Any]) -> Self? {
        return internal_wy_objectFromJSONDictionary(dict)
    }

    @objc static func wy_objectFromJSONData(_ data: Data) -> Self? {
        return internal_wy_objectFromJSONData(data)
    }

    @objc static func wy_objectFromJSONString(_ jsonString: String) -> Self? {
        return internal_wy_objectFromJSONString(jsonString)
    }

    @objc static func wy_objectsFromJSONArray(_ array: [[String: Any]]) -> [NSObject] {
        return internal_wy_objectsFromJSONArray(array)
    }
}

/// DEBUG打印日志
public func wy_codablePrint(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
    internal_wy_codablePrint(messages, file: file, function: function, line: line)
}
