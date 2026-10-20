// 
//  WYCodingKeysConverter.swift
//  WYBasisKit
//
//  Created by 官人 on 2024/1/22.
//

import Foundation

/// 自定义 CodingKey(任意字符串或整数都能当编码键用)
public struct WYCodingKey : CodingKey {
    
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

/// 字段路径(从根到当前字段的逐级键名)
public typealias WYCodingPath = [String]

public extension JSONDecoder.KeyDecodingStrategy {
    
    /**
     *  建按字段路径改键名的解码策略
     *
     *  @param container    字段路径到目标键名的映射表
     *
     *  @return 键名转换策略，交给 JSONDecoder.keyDecodingStrategy 使用
     *
     */
    static func mapper(_ container: [WYCodingPath: String]) -> JSONDecoder.KeyDecodingStrategy {
        .custom { WYCodingKeysConverter(container)($0) }
    }
}

/// 按字段路径查映射改键名
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
