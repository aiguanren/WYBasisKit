// 
//  WYCodableUnkeyedContainer.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

struct WYCodableUnkeyedContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    
    /// A reference to the decoder we're reading from.
    private let decoder: WYCodableInfo
    
    /// A reference to the container we're reading from.
    private let container: [Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int
    
    // MARK: - Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: WYCodableInfo, wrapping container: [Any]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }
    
    // MARK: - UnkeyedDecodingContainer Methods
    
    public var count: Int? {
        return self.container.count
    }
    
    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }
    
    public mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                Any?.self,
                DecodingError.Context(
                    codingPath: self.decoder.codingPath + [WYCodingKey(index: self.currentIndex)],
                    debugDescription: "Unkeyed container is at end."
                )
            )
        }
        
        if self.container[self.currentIndex] is NSNull {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> Bool {
        self.currentIndex += 1
        return Bool.defaultValue
    }
    
    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> Int {
        self.currentIndex += 1
        return Int.defaultValue
    }
    
    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> UInt {
        self.currentIndex += 1
        return UInt.defaultValue
    }
    
    public mutating func decode(_ type: CGFloat.Type) throws -> CGFloat {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: CGFloat.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> CGFloat {
        self.currentIndex += 1
        return CGFloat.defaultValue
    }
    
    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> Double {
        self.currentIndex += 1
        return Double.defaultValue
    }
    
    public mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            return try decode(isAtEnd: true)
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            return try decode()
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    private mutating func decode(isAtEnd: Bool = false) throws -> String {
        self.currentIndex += 1
        return String.defaultValue
    }
    
    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(
                    codingPath: self.decoder.codingPath + [WYCodingKey(index: self.currentIndex)],
                    debugDescription: "Unkeyed container is at end."
                )
            )
        }
        
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(
                type,
                DecodingError.Context(
                    codingPath: self.decoder.codingPath + [WYCodingKey(index: self.currentIndex)],
                    debugDescription: "Expected \(type) but found null instead."
                )
            )
        }
        
        self.currentIndex += 1
        return decoded
    }
    
    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<NestedKey>.self,
                DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."
                )
            )
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            self.currentIndex += 1
            return nestedContainer()
        }
        
        guard let dictionary = value as? [String : Any] else {
            self.currentIndex += 1
            return nestedContainer()
        }
        
        self.currentIndex += 1
        return nestedContainer(wrapping: dictionary)
    }
    
    private func nestedContainer<NestedKey>(wrapping dictionary: [String: Any] = [:]) -> KeyedDecodingContainer<NestedKey> {
        let container = WYCodingKeyedDecodingContainer<NestedKey>(
            referencing: self.decoder,
            wrapping: dictionary
        )
        return KeyedDecodingContainer(container)
    }
    
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."
                )
            )
        }
        
        let value = self.container[self.currentIndex]
        guard !(value is NSNull) else {
            self.currentIndex += 1
            return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: [])
        }
        
        guard let array = value as? [Any] else {
            self.currentIndex += 1
            return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: [])
        }
        
        self.currentIndex += 1
        return WYCodableUnkeyedContainer(referencing: self.decoder, wrapping: array)
    }
    
    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(WYCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(
                Decoder.self,
                DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."
                )
            )
        }
        
        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return WYCodableInfo(
            referencing: value,
            at: self.decoder.codingPath,
            userInfo: self.decoder.userInfo, mappingKeys: self.decoder.mappingKeys
        )
    }
}
