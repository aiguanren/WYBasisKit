// 
//  WYCodable.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

open class WYCodable: JSONDecoder {
    
    /// 解析时需要映射的Key(仅针对第一层数据映射，第二层级以后的(第一层也可以)建议在对应的model类中使用Codable原生映射方法)
    open var mappingKeys: KeyDecodingStrategy = .useDefaultKeys
    
    /// 将Data类型数据解析成传入的Model类型
    open override func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let topLevel: Any
        do {
            topLevel = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        } catch {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The given data was not valid JSON.",
                    underlyingError: error
                )
            )
        }
        return try decode(type, from: topLevel)
    }
    
    /// 将Dictionary及Array解析成传入的Model类型
    open func decode<T: Decodable>(_ type: T.Type, from convertible: WYCodableContainerConvertible
    ) throws -> T {
        try decode(type, from: convertible.asJSONContainer())
    }
    
    /// 将传入的model转换成指定类型(convertType限Dictionary、Array、Data、String)
    open func encode<T: Any>(_ convertType: T.Type, from model: Codable) throws -> T {
        let encoder = JSONEncoder()
        if (convertType.self == String.self) || (convertType.self == Data.self) {
            let codableError: WYCodableError = (convertType.self == String.self) ? WYCodableError.modelToStringError : WYCodableError.modelToDataError
            do {
                guard let resultData = try? encoder.encode(model) else {
                    throw codableError
                }
                return (convertType.self == String.self) ? (String(data: resultData, encoding: .utf8) as! T) : (resultData as! T)
            } catch  {
                throw codableError
            }
        }
        
        if (convertType.self == Dictionary<String, Any>.self) || (convertType.self == Array<Any>.self) {
            
            let codableError: WYCodableError = (convertType.self == Dictionary<String, Any>.self) ? WYCodableError.modelToDictionaryError : WYCodableError.modelToArrayError
            do {
                let data = try encoder.encode(model)
                
                guard let result = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
                    throw codableError
                }
                return result as! T
                
            } catch {
                throw codableError
            }
        }
        throw WYCodableError.modelDecodableError
    }
}

public extension String {
    
    /// String转Dictionary
    func wy_convertToDictionary() throws -> Dictionary<String, Any> {
        
        do {
            let data = try wy_convertToData()
            
            guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
                throw WYCodableError.stringToDictionaryError
            }
            return dictionary as! Dictionary<String, Any>
            
        } catch {
            throw WYCodableError.stringToDictionaryError
        }
    }
    
    /// String转Array
    func wy_convertToArray() throws -> Array<Any> {
        
        do {
            let data = try wy_convertToData()
            
            guard let array = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
                throw WYCodableError.stringToArrayError
            }
            return array as! Array<Any>
            
        } catch {
            throw WYCodableError.stringToArrayError
        }
    }
    
    /// String转Data
    func wy_convertToData() throws -> Data {
        
        guard let data = self.data(using: String.Encoding.utf8) else {
            throw WYCodableError.stringToDataError
        }
        return data
    }
}

public extension Data {
    
    /// Data转String
    func wy_convertToString() throws -> String {
        
        guard let string = String(data: self, encoding: .utf8) else {
            throw WYCodableError.dataToStringError
        }
        return string
    }
    
    /// Data转Dictionary
    func wy_convertToDictionary() throws -> Dictionary<String, Any> {
        
        guard let dictionary = try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            throw WYCodableError.dataToDictionaryError
        }
        return dictionary as! Dictionary<String, Any>
    }
    
    /// Data转Array
    func wy_convertToArray() throws -> Array<Any> {
        
        guard let array = try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableContainers) else {
            throw WYCodableError.dataToArrayError
        }
        return array as! Array<Any>
    }
}

public extension Array {
    
    /// Array转String
    func wy_convertToString() throws -> String {
        
        guard JSONSerialization.isValidJSONObject(self) else {
            throw WYCodableError.arrayToStringError
        }

        do {
            let data = try wy_convertToData()
            
            guard let string = String(data: data, encoding: .utf8) else {
                throw WYCodableError.arrayToStringError
            }
            return string
            
        } catch {
            throw WYCodableError.arrayToStringError
        }
    }
    
    /// Array转Data
    func wy_convertToData() throws -> Data {
        
        guard JSONSerialization.isValidJSONObject(self) else {
            throw WYCodableError.arrayToDataError
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            throw WYCodableError.arrayToDataError
        }
        return data
    }
}

public extension Dictionary {
    
    /// Dictionary转String
    func wy_convertToString() throws -> String {
        
        guard JSONSerialization.isValidJSONObject(self) else {
            throw WYCodableError.dictionaryToStringError
        }
        
        do {
            let data = try wy_convertToData()
            
            guard let string = String(data: data, encoding: .utf8) else {
                throw WYCodableError.dictionaryToStringError
            }
            return string
            
        } catch {
            throw WYCodableError.dictionaryToStringError
        }
    }
    
    /// Dictionary转Data
    func wy_convertToData() throws -> Data {
        
        guard JSONSerialization.isValidJSONObject(self) else {
            throw WYCodableError.dictionaryToDataError
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            throw WYCodableError.dictionaryToDataError
        }
        return data
    }
}

private extension WYCodable {
    
    func decode<T : Decodable>(
        _ type: T.Type,
        from container: Any
    ) throws -> T {
        let decoder = WYCodableInfo(referencing: container, userInfo: self.userInfo, mappingKeys: self.mappingKeys)
        
        guard let value = try decoder.unbox(container, as: type) else {
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The given data did not contain a top-level value."
                )
            )
        }
        return value
    }
}
