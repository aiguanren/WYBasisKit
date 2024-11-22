// 
//  WYDecodingStorage.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

struct WYDecodingStorage {
    
    /// The container stack.
    /// Elements may be any one of the JSON types (NSNull, NSNumber, String, Array, [String : Any]).
    private(set) var containers: [Any] = []
    
    // MARK: - Initialization
    
    /// Initializes `self` with no containers.
    init() {}
    
    // MARK: - Modifying the Stack
    
    var count: Int {
        return self.containers.count
    }
    
    var topContainer: Any {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }
    
    mutating func push(container: Any) {
        self.containers.append(container)
    }
    
    mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

final class WYCodableInfo: WYDecoder {
    
    /// The decoder's storage.
    var storage: WYDecodingStorage
    
    /// Options set on the top-level decoder.
    var mappingKeys: JSONDecoder.KeyDecodingStrategy
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initialization
    
    /// Initializes `self` with the given top-level container and options.
    init(referencing container: Any, at codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey : Any], mappingKeys: JSONDecoder.KeyDecodingStrategy) {
        self.storage = WYDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.mappingKeys = mappingKeys
    }
    
    // MARK: - Decoder Methods
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer is NSNull) else {
            let container = WYCodingKeyedDecodingContainer<Key>(
                referencing: self,
                wrapping: [:]
            )
            return KeyedDecodingContainer(container)
        }
        
        guard let topContainer = self.storage.topContainer as? [String : Any] else {
            let container = WYCodingKeyedDecodingContainer<Key>(
                referencing: self,
                wrapping: [:]
            )
            return KeyedDecodingContainer(container)
        }
        
        let container = WYCodingKeyedDecodingContainer<Key>(
            referencing: self,
            wrapping: topContainer
        )
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer is NSNull) else {
            return WYCodableUnkeyedContainer(referencing: self, wrapping: [])
        }
        
        guard let topContainer = self.storage.topContainer as? [Any] else {
            return WYCodableUnkeyedContainer(referencing: self, wrapping: [])
        }
        
        return WYCodableUnkeyedContainer(referencing: self, wrapping: topContainer)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

public protocol WYCaseDefaultable: RawRepresentable {
    
    static var defaultCase: Self { get }
}

public extension WYCaseDefaultable where Self: Decodable, Self.RawValue: Decodable {
    
    init(from decoder: Decoder) throws {
        guard let _decoder = decoder as? WYCodableInfo else {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Self.init(rawValue: rawValue) ?? Self.defaultCase
            return
        }
        
        self = try _decoder.decodeCase(Self.self)
    }
}

private extension WYCodableInfo {
    
    func decodeCase<T>(_ type: T.Type) throws -> T
        where T: WYCaseDefaultable,
        T: Decodable,
        T.RawValue: Decodable
    {
        guard !decodeNil(), !storage.containers.isEmpty, storage.topContainer is T.RawValue else {
            return T.defaultCase
        }
        
        if let number = storage.topContainer as? NSNumber,
            (number === kCFBooleanTrue || number === kCFBooleanFalse) {
            guard let rawValue = number.boolValue as? T.RawValue else {
                return T.defaultCase
            }
            
            return T.init(rawValue: rawValue) ?? T.defaultCase
        }
        
        let rawValue = try decode(T.RawValue.self)
        return T.init(rawValue: rawValue) ?? T.defaultCase
    }
}

extension WYCodableInfo : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    
    public func decodeNil() -> Bool {
        return storage.topContainer is NSNull
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        if let value = try unbox(storage.topContainer, as: Bool.self) { return value }
        return Bool.defaultValue
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        if let value = try unbox(storage.topContainer, as: Int.self) { return value }
        return Int.defaultValue
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        if let value = try unbox(storage.topContainer, as: UInt.self) { return value }
        return UInt.defaultValue
    }
    
    public func decode(_ type: CGFloat.Type) throws -> CGFloat {
        if let value = try unbox(storage.topContainer, as: CGFloat.self) { return value }
        return CGFloat.defaultValue
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        if let value = try unbox(storage.topContainer, as: Double.self) { return value }
        return Double.defaultValue
    }
    
    public func decode(_ type: String.Type) throws -> String {
        if let value = try unbox(storage.topContainer, as: String.self) { return value }
        return String.defaultValue
    }
    
    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        
        if let value = try unbox(storage.topContainer, as: type) { return value }
        return try decodeAsDefaultValue()
    }
}

extension WYCodableInfo {
    
    func decodeAsDefaultValue<T: Decodable>() throws -> T {
        if let array = [] as? T {
            return array
        } else if let string = String.defaultValue as? T {
            return string
        } else if let bool = Bool.defaultValue as? T {
            return bool
        } else if let int = Int.defaultValue as? T {
            return int
        } else if let cgfloat = CGFloat.defaultValue as? T {
            return cgfloat
        } else if let double = Double.defaultValue as? T {
            return double
        } else if let object = try? unbox([:], as: T.self) {
            return object
        }
        
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Key: <\(codingPath)> cannot be decoded as default value."
        )
        throw DecodingError.dataCorrupted(context)
    }
}
