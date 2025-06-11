//
//  WYCodingKeyedDecodingContainer.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

struct WYCodingKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the decoder we're reading from.
    private let decoder: WYCodableInfo
    
    /// A reference to the container we're reading from.
    private let container: [String: Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: WYCodableInfo, wrapping container: [String: Any]) {
        self.decoder = decoder
        switch decoder.mappingKeys {
        case .useDefaultKeys:
            self.container = container
        case .convertFromSnakeCase:
            // Convert the snake case keys in the container to camel case.
            // If we hit a duplicate key after conversion, then we'll use the first one we saw. Effectively an undefined behavior with JSON dictionaries.
            self.container = Dictionary(container.map {
                dict in (WYCodable.KeyDecodingStrategy._convertFromSnakeCase(dict.key), dict.value)
            }, uniquingKeysWith: { (first, _) in first })
        case .custom(let converter):
            self.container = Dictionary(container.map {
                key, value in (converter(decoder.codingPath + [WYCodingKey(stringValue: key, intValue: nil)]).stringValue, value)
            }, uniquingKeysWith: { (first, _) in first })
        @unknown default:
            self.container = container
        }
        self.codingPath = decoder.codingPath
    }
    
    // MARK: - KeyedDecodingContainerProtocol Methods
    
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }
    
    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }
    
    public func decodeNil(forKey key: Key) -> Bool {
        guard let entry = self.container[key.stringValue] else {
            return true
        }
        return entry is NSNull
    }
    
    @inline(__always)
    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            return Bool.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            return Int.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            return UInt.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode(_ type: CGFloat.Type, forKey key: Key) throws -> CGFloat {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: CGFloat.self) else {
            return CGFloat.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            return Double.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            return try decodeIfKeyNotFound(key)
        }
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            return String.defaultValue
        }
        
        return value
    }
    
    @inline(__always)
    public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = container[key.stringValue] else {
            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }
            return try decoder.decodeAsDefaultValue()
        }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        func decodeObject(from decoder: WYCodableInfo) throws -> T {
            if let value = try decoder.unbox(entry, as: type) { return value }
            
            return try decoder.decodeAsDefaultValue()
        }
        
        /// 若期望解析的类型是字符串类型，则正常解析
        if let _ = String.defaultValue as? T { return try decodeObject(from: decoder) }
        
        /// 若原始值不是有效的 JSON 字符串则正常解析
        guard let string = try decoder.unbox(entry, as: String.self),
              let jsonObject = string.wy_toJSONObjectString()
        else {
            return try decodeObject(from: decoder)
        }
        
        decoder.storage.push(container: jsonObject)
        defer { decoder.storage.popContainer() }
        return try decoder.decode(type)
    }
    
    @inline(__always)
    public func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            return nestedContainer()
        }
        
        guard let dictionary = value as? [String : Any] else {
            return nestedContainer()
        }
        return nestedContainer(wrapping: dictionary)
    }
    
    @inline(__always)
    private func nestedContainer<NestedKey>(
        wrapping dictionary: [String: Any] = [:]
    ) -> KeyedDecodingContainer<NestedKey> {
        let container = WYCodingKeyedDecodingContainer<NestedKey>(
            referencing: decoder,
            wrapping: dictionary
        )
        return KeyedDecodingContainer(container)
    }
    
    @inline(__always)
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: [])
        }
        
        guard let array = value as? [Any] else {
            return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: [])
        }
        
        return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: array)
    }
    
    @inline(__always)
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        let value: Any = self.container[key.stringValue] ?? NSNull()
        return WYCodableInfo(
            referencing: value,
            at: self.decoder.codingPath,
            userInfo: self.decoder.userInfo, mappingKeys: self.decoder.mappingKeys
        )
    }
    
    @inline(__always)
    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: WYCodingKey.super)
    }
    
    @inline(__always)
    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

extension WYCodingKeyedDecodingContainer {
    
    @inline(__always)
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent(_ type: CGFloat.Type, forKey key: K) throws -> CGFloat? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if let value = try decoder.unbox(entry, as: type) { return value }
        
        return nil
    }
    
    @inline(__always)
    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
        guard contains(key), let entry = container[key.stringValue] else { return nil }
        
        decoder.codingPath.append(key)
        defer { decoder.codingPath.removeLast() }
        
        if decodeNil(forKey: key) { return nil }
        
        func decodeObject(from decoder: WYCodableInfo) throws -> T? {
            if let value = try decoder.unbox(entry, as: type) { return value }
            
            return nil
        }
        
        /// 若期望解析的类型是字符串类型，则正常解析
        if let _ = String.defaultValue as? T { return try decodeObject(from: decoder) }
        
        /// 若原始值不是有效的 JSON 字符串则正常解析
        guard let string = try decoder.unbox(entry, as: String.self),
              let jsonObject = string.wy_toJSONObjectString()
        else {
            return try decodeObject(from: decoder)
        }
        return try decoder.unbox(jsonObject, as: type)
    }
}

private extension WYCodable.KeyDecodingStrategy {
    
    static func _convertFromSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }
        
        // Find the first non-underscore character
        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return stringKey
        }
        
        // Find the last non-underscore character
        var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
        while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
            stringKey.formIndex(before: &lastNonUnderscore)
        }
        
        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex
        
        let components = stringKey[keyRange].split(separator: "_")
        let joinedString : String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }
        
        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result : String
        if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
            result = joinedString
        } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
            // Both leading and trailing underscores
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if (!leadingUnderscoreRange.isEmpty) {
            // Just leading
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }
        return result
    }
}

private extension WYCodingKeyedDecodingContainer {
    
    func decodeIfKeyNotFound<T>(_ key: Key) throws -> T where T: Decodable, T: WYCodableDefaultValue {
        return T.defaultValue
    }
}

private extension String {
    
    func wy_toJSONObjectString() -> Any? {
        // 过滤掉非 JSON 格式字符串
        guard hasPrefix("{") || hasPrefix("[") else { return nil }
        
        guard let data = data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return jsonObject
    }
}
