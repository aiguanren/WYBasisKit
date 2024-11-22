// 
//  WYCodingKeysConverter.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

struct WYCodingKey : CodingKey {
    
    public var stringValue: String
    
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
    
    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
    
    static let `super` = WYCodingKey(stringValue: "super")!
}

public typealias WYCodingPath = [String]

public extension JSONDecoder.KeyDecodingStrategy {
    
    static func mapper(_ container: [WYCodingPath: String]) -> JSONDecoder.KeyDecodingStrategy {
        .custom { WYCodingKeysConverter(container)($0) }
    }
}

struct WYCodingKeysConverter {
    let container: [WYCodingPath: String]
    
    init(_ container: [WYCodingPath: String]) {
        self.container = container
    }

    func callAsFunction(_ codingPath: [CodingKey]) -> CodingKey {
        guard !codingPath.isEmpty else { return WYCodingKey.super }
        
        let stringKeys = codingPath.map { $0.stringValue }
        
        guard container.keys.contains(stringKeys) else { return codingPath.last! }
        
        return WYCodingKey(stringValue: container[stringKeys]!, intValue: nil)
    }
}
