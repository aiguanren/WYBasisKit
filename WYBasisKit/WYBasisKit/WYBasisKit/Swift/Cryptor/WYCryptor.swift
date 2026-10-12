//
//  WYCryptor.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/12.
//

import Foundation
import CryptoKit
import CommonCrypto

/** 通用加解密工具(MD5/SHA/HMAC/AES-GCM/XOR/Base64/Hex/随机数/PBKDF2，全部无状态静态方法，任意模块按需取用) */
public struct WYCryptor {

    /**
     * 字符串MD5摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 32位小写十六进制摘要串
     */
    public static func md5Hex(_ input: String) -> String {
        return md5Hex(Data(input.utf8))
    }

    /**
     * 数据MD5摘要
     * - Parameter input: 要摘要的数据
     * - Returns: 32位小写十六进制摘要串
     */
    public static func md5Hex(_ input: Data) -> String {
        let digest = Insecure.MD5.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * 字符串SHA1摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 40位小写十六进制摘要串
     */
    public static func sha1Hex(_ input: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * 字符串SHA256摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 64位小写十六进制摘要串
     */
    public static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * 字符串SHA512摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 128位小写十六进制摘要串
     */
    public static func sha512Hex(_ input: String) -> String {
        let digest = SHA512.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * HMAC-SHA256签名
     * - Parameters:
     *   - message: 要签名的内容(按UTF-8取字节)
     *   - key: 签名密钥(按UTF-8取字节)
     * - Returns: 64位小写十六进制签名串
     */
    public static func hmacSHA256Hex(message: String, key: String) -> String {
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: SymmetricKey(data: Data(key.utf8)))
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * HMAC-SHA1签名
     * - Parameters:
     *   - message: 要签名的内容(按UTF-8取字节)
     *   - key: 签名密钥(按UTF-8取字节)
     * - Returns: 40位小写十六进制签名串
     */
    public static func hmacSHA1Hex(message: String, key: String) -> String {
        let mac = HMAC<Insecure.SHA1>.authenticationCode(for: Data(message.utf8), using: SymmetricKey(data: Data(key.utf8)))
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * AES-256-GCM加密
     * - Parameters:
     *   - plaintext: 要加密的明文数据
     *   - key: 加密密钥(任意长度，内部先归一成32字节对称密钥)
     * - Returns: 组合密文(12字节随机nonce+密文+16字节认证标签)，解密用aesGCMDecrypt；加密失败返回nil
     */
    public static func aesGCMEncrypt(_ plaintext: Data, key: Data) -> Data? {
        guard let sealed = try? AES.GCM.seal(plaintext, using: normalizedKey(key)).combined else { return nil }
        return sealed
    }

    /**
     * AES-256-GCM解密
     * - Parameters:
     *   - combined: aesGCMEncrypt返回的组合密文
     *   - key: 加密时用的同一把密钥
     * - Returns: 解密出的明文数据；密钥不符或数据被篡改时返回nil
     */
    public static func aesGCMDecrypt(_ combined: Data, key: Data) -> Data? {
        guard let sealedBox = try? AES.GCM.SealedBox(combined: combined),
              let clear = try? AES.GCM.open(sealedBox, using: normalizedKey(key)) else { return nil }
        return clear
    }

    /**
     * AES-256-GCM加密字符串
     * - Parameters:
     *   - plaintext: 要加密的明文字符串(按UTF-8取字节)
     *   - key: 加密密钥(任意长度)
     * - Returns: 组合密文的Base64串，解密用aesGCMDecryptString；加密失败返回nil
     */
    public static func aesGCMEncryptString(_ plaintext: String, key: String) -> String? {
        guard let combined = aesGCMEncrypt(Data(plaintext.utf8), key: Data(key.utf8)) else { return nil }
        return combined.base64EncodedString()
    }

    /**
     * AES-256-GCM解密字符串
     * - Parameters:
     *   - base64Combined: aesGCMEncryptString返回的Base64串
     *   - key: 加密时用的同一把密钥
     * - Returns: 解密出的明文字符串；密钥不符或数据被篡改时返回nil
     */
    public static func aesGCMDecryptString(_ base64Combined: String, key: String) -> String? {
        guard let combined = Data(base64Encoded: base64Combined),
              let clear = aesGCMDecrypt(combined, key: Data(key.utf8)) else { return nil }
        return String(decoding: clear, as: UTF8.self)
    }

    /**
     * XOR流处理
     * - Parameters:
     *   - input: 要处理的数据
     *   - key: 循环取字节的密钥
     * - Returns: 与密钥循环异或的结果(加密解密是同一个方法)
     */
    public static func xor(_ input: Data, key: Data) -> Data {
        let inputBytes = [UInt8](input)
        let keyBytes = [UInt8](key)
        guard keyBytes.isEmpty == false else { return input }

        var output = [UInt8](repeating: 0, count: inputBytes.count)
        for index in inputBytes.indices {
            output[index] = inputBytes[index] ^ keyBytes[index % keyBytes.count]
        }
        return Data(output)
    }

    /**
     * Base64编码
     * - Parameter input: 要编码的数据
     * - Returns: Base64字符串
     */
    public static func base64Encode(_ input: Data) -> String {
        return input.base64EncodedString()
    }

    /**
     * Base64解码
     * - Parameter input: 要解码的Base64字符串
     * - Returns: 解码出的数据；格式非法时返回nil
     */
    public static func base64Decode(_ input: String) -> Data? {
        return Data(base64Encoded: input)
    }

    /**
     * 十六进制编码
     * - Parameter input: 要编码的数据
     * - Returns: 小写十六进制字符串
     */
    public static func hexEncode(_ input: Data) -> String {
        return input.map { String(format: "%02x", $0) }.joined()
    }

    /**
     * 十六进制解码
     * - Parameter input: 要解码的十六进制字符串(大小写都认)
     * - Returns: 解码出的数据；含非十六进制字符时返回nil
     */
    public static func hexDecode(_ input: String) -> Data? {
        let characters = Array(input.lowercased())
        guard characters.count % 2 == 0 else { return nil }

        let hexDigits: [Character: UInt8] = ["0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7,
                                             "8": 8, "9": 9, "a": 10, "b": 11, "c": 12, "d": 13, "e": 14, "f": 15]
        var output = [UInt8]()
        output.reserveCapacity(characters.count / 2)

        var index = 0
        while index < characters.count {
            guard let high = hexDigits[characters[index]],
                  let low = hexDigits[characters[index + 1]] else { return nil }
            output.append(high << 4 | low)
            index += 2
        }
        return Data(output)
    }

    /**
     * 安全随机字节
     * - Parameter count: 要生成的字节数
     * - Returns: 系统安全随机源生成的数据(密钥/盐/nonce生成用)
     */
    public static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: max(0, count))
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    /**
     * PBKDF2密钥派生
     * - Parameters:
     *   - password: 派生口令(按UTF-8取字节)
     *   - salt: 派生盐(按UTF-8取字节)
     *   - rounds: 迭代次数(默认10000，调大更慢更抗暴力)
     *   - length: 派生输出的字节数(默认32)
     * - Returns: 派生出的密钥数据；参数非法时返回nil
     */
    public static func pbkdf2(password: String, salt: String, rounds: UInt32 = 10000, length: Int = 32) -> Data? {
        guard rounds > 0, length > 0 else { return nil }

        var derived = [UInt8](repeating: 0, count: length)
        let passwordBytes = Array(password.utf8)
        let saltBytes = Array(salt.utf8)
        let status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes, passwordBytes.count,
                                          saltBytes, saltBytes.count,
                                          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds,
                                          &derived, length)
        guard status == kCCSuccess else { return nil }
        return Data(derived)
    }

    /// 任意长度密钥归一成32字节对称密钥(内部统一走SHA256，保证AES拿到的key定长)
    private static func normalizedKey(_ key: Data) -> SymmetricKey {
        return SymmetricKey(data: SHA256.hash(data: key))
    }
}
