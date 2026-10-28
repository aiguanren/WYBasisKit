//
//  WYCryptor+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation
import CryptoKit

extension WYCryptor {

    /// 任意长度密钥归一成32字节对称密钥(内部统一走SHA256，保证AES拿到的key定长)
    static func normalizedKey(_ key: Data) -> SymmetricKey {
        return SymmetricKey(data: SHA256.hash(data: key))
    }
}
