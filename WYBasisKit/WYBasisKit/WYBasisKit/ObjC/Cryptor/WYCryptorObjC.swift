//
//  WYCryptor.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/12.
//

#if canImport(WYBasisKitSwift)
import Foundation
import WYBasisKitSwift

/** 通用加解密工具(MD5/SHA/HMAC/AES-GCM/XOR/Base64/Hex/随机数/PBKDF2，全部无状态静态方法，任意模块按需取用) */
@objc(WYCryptor)
@objcMembers public class WYCryptorObjC: NSObject {

    /**
     * 字符串MD5摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 32位小写十六进制摘要串
     */
    @objc public static func md5Hex(_ input: String) -> String {
        return WYCryptor.md5Hex(input)
    }

    /**
     * 数据MD5摘要
     * - Parameter input: 要摘要的数据
     * - Returns: 32位小写十六进制摘要串
     */
    @objc public static func md5HexData(_ input: Data) -> String {
        return WYCryptor.md5Hex(input)
    }

    /**
     * 字符串SHA1摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 40位小写十六进制摘要串
     */
    @objc public static func sha1Hex(_ input: String) -> String {
        return WYCryptor.sha1Hex(input)
    }

    /**
     * 字符串SHA256摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 64位小写十六进制摘要串
     */
    @objc public static func sha256Hex(_ input: String) -> String {
        return WYCryptor.sha256Hex(input)
    }

    /**
     * 字符串SHA512摘要
     * - Parameter input: 要摘要的字符串(按UTF-8取字节)
     * - Returns: 128位小写十六进制摘要串
     */
    @objc public static func sha512Hex(_ input: String) -> String {
        return WYCryptor.sha512Hex(input)
    }

    /**
     * HMAC-SHA256签名
     * - Parameters:
     *   - message: 要签名的内容(按UTF-8取字节)
     *   - key: 签名密钥(按UTF-8取字节)
     * - Returns: 64位小写十六进制签名串
     */
    @objc public static func hmacSHA256Hex(message: String, key: String) -> String {
        return WYCryptor.hmacSHA256Hex(message: message, key: key)
    }

    /**
     * HMAC-SHA1签名
     * - Parameters:
     *   - message: 要签名的内容(按UTF-8取字节)
     *   - key: 签名密钥(按UTF-8取字节)
     * - Returns: 40位小写十六进制签名串
     */
    @objc public static func hmacSHA1Hex(message: String, key: String) -> String {
        return WYCryptor.hmacSHA1Hex(message: message, key: key)
    }

    /**
     * AES-256-GCM加密
     * - Parameters:
     *   - plaintext: 要加密的明文数据
     *   - key: 加密密钥(任意长度，内部先归一成32字节对称密钥)
     * - Returns: 组合密文(12字节随机nonce+密文+16字节认证标签)，解密用aesGCMDecrypt；加密失败返回nil
     */
    @objc public static func aesGCMEncrypt(_ plaintext: Data, key: Data) -> Data? {
        return WYCryptor.aesGCMEncrypt(plaintext, key: key)
    }

    /**
     * AES-256-GCM解密
     * - Parameters:
     *   - combined: aesGCMEncrypt返回的组合密文
     *   - key: 加密时用的同一把密钥
     * - Returns: 解密出的明文数据；密钥不符或数据被篡改时返回nil
     */
    @objc public static func aesGCMDecrypt(_ combined: Data, key: Data) -> Data? {
        return WYCryptor.aesGCMDecrypt(combined, key: key)
    }

    /**
     * AES-256-GCM加密字符串
     * - Parameters:
     *   - plaintext: 要加密的明文字符串(按UTF-8取字节)
     *   - key: 加密密钥(任意长度)
     * - Returns: 组合密文的Base64串，解密用aesGCMDecryptString；加密失败返回nil
     */
    @objc public static func aesGCMEncryptString(_ plaintext: String, key: String) -> String? {
        return WYCryptor.aesGCMEncryptString(plaintext, key: key)
    }

    /**
     * AES-256-GCM解密字符串
     * - Parameters:
     *   - base64Combined: aesGCMEncryptString返回的Base64串
     *   - key: 加密时用的同一把密钥
     * - Returns: 解密出的明文字符串；密钥不符或数据被篡改时返回nil
     */
    @objc public static func aesGCMDecryptString(_ base64Combined: String, key: String) -> String? {
        return WYCryptor.aesGCMDecryptString(base64Combined, key: key)
    }

    /**
     * XOR流处理
     * - Parameters:
     *   - input: 要处理的数据
     *   - key: 循环取字节的密钥
     * - Returns: 与密钥循环异或的结果(加密解密是同一个方法)
     */
    @objc public static func xor(_ input: Data, key: Data) -> Data {
        return WYCryptor.xor(input, key: key)
    }

    /**
     * Base64编码
     * - Parameter input: 要编码的数据
     * - Returns: Base64字符串
     */
    @objc public static func base64Encode(_ input: Data) -> String {
        return WYCryptor.base64Encode(input)
    }

    /**
     * Base64解码
     * - Parameter input: 要解码的Base64字符串
     * - Returns: 解码出的数据；格式非法时返回nil
     */
    @objc public static func base64Decode(_ input: String) -> Data? {
        return WYCryptor.base64Decode(input)
    }

    /**
     * 十六进制编码
     * - Parameter input: 要编码的数据
     * - Returns: 小写十六进制字符串
     */
    @objc public static func hexEncode(_ input: Data) -> String {
        return WYCryptor.hexEncode(input)
    }

    /**
     * 十六进制解码
     * - Parameter input: 要解码的十六进制字符串(大小写都认)
     * - Returns: 解码出的数据；含非十六进制字符时返回nil
     */
    @objc public static func hexDecode(_ input: String) -> Data? {
        return WYCryptor.hexDecode(input)
    }

    /**
     * 安全随机字节
     * - Parameter count: 要生成的字节数
     * - Returns: 系统安全随机源生成的数据(密钥/盐/nonce生成用)
     */
    @objc public static func randomBytes(count: Int) -> Data {
        return WYCryptor.randomBytes(count: count)
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
    @objc public static func pbkdf2(password: String, salt: String, rounds: UInt32, length: Int) -> Data? {
        return WYCryptor.pbkdf2(password: password, salt: salt, rounds: rounds, length: length)
    }
}
#endif
