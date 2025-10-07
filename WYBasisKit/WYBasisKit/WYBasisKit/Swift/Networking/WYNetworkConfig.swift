//
//  WYNetworkConfig.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/11/23.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import Alamofire

/// 网络请求验证方式
@frozen public enum WYNetworkRequestStyle: Int {
    
    /// HTTP和CAHTTPS(无需额外配置  CAHTTPS：即向正规CA机构购买的HTTPS服务)
    case httpOrCAHttps = 0
    /// HTTPS单向验证，客户端验证服务器(自建证书，需要将一个服务端的cer文件放进工程目录，并调用WYNetworkConfig.httpsConfig对应方法配置cer文件名)
    case httpsSingle
    /// HTTPS双向验证，客户端和服务端双向验证(自建证书，需要将一个服务端的cer文件与一个带密码的客户端p12文件放进工程目录，并调用WYNetworkConfig.httpsConfig对应方法配置cer、P12文件名与P12文件密码)
    case httpsBothway
}

/// HTTPS自建证书验证策略
@frozen public enum WYHttpsVerifyStrategy: Int {
    
    /// 证书验证模式，客户端会将服务器返回的证书和本地保存的证书中的 所有内容 全部进行校验，如果正确，才继续执行
    case pinnedCertificates = 0
    
    /// 公钥验证模式，客户端会将服务器返回的证书和本地保存的证书中的 公钥 部分 进行校验，如果正确，才继续执行
    case publicKeys
    
    /// 不进行任何验证,无条件信任证书(不建议使用此选项，如果确实要使用此选项的，最好自己实现验证策略)
    case directTrust
}

/// HTTPS自建证书相关配置
public struct WYHttpsConfig {
    
    /// 自定义验证策略(内部使用)
    public static var trustManager: ServerTrustManager? = nil
    public var trustManager: ServerTrustManager? = trustManager
    
    /// 自定义双向认证sessionDelegate
    public static var sessionDelegate: SessionDelegate? = nil
    public var sessionDelegate: SessionDelegate? = sessionDelegate
    
    /// 配置自建证书HTTPS请求时server.cer文件名
    public static var serverCer: String = ""
    public var serverCer: String = serverCer
    
    /// 配置自建证书HTTPS请求时client.p12文件名
    public static var clientP12: String = ""
    public var clientP12: String = clientP12
    
    /// 配置自建证书HTTPS请求时client.p12文件密码
    public static var clientP12Password: String = ""
    public var clientP12Password: String = clientP12Password
    
    /// 设置验证策略(安全等级)
    public static var verifyStrategy: WYHttpsVerifyStrategy = .pinnedCertificates
    public var verifyStrategy: WYHttpsVerifyStrategy = verifyStrategy
    
    /// 是否执行默认验证
    public static var defaultValidation: Bool = true
    public var defaultValidation: Bool = defaultValidation
    
    /// 是否验证域名
    public static var validateDomain: Bool = true
    public var validateDomain: Bool = validateDomain
    
    /// 确定是否必须评估此“服务器信任管理器”的所有主机
    public static var allHostsMustBeEvaluated: Bool = true
    public var allHostsMustBeEvaluated: Bool = allHostsMustBeEvaluated
    
    /// 获取一个默认config
    public static let `default`: WYHttpsConfig = WYHttpsConfig()
    
    public init(trustManager: ServerTrustManager? = nil, sessionDelegate: SessionDelegate? = nil, serverCer: String = serverCer, clientP12: String = clientP12, clientP12Password: String = clientP12Password, verifyStrategy: WYHttpsVerifyStrategy = verifyStrategy, defaultValidation: Bool = defaultValidation, validateDomain: Bool = validateDomain, allHostsMustBeEvaluated: Bool = allHostsMustBeEvaluated) {
        self.trustManager = trustManager
        self.sessionDelegate = sessionDelegate
        self.serverCer = serverCer
        self.clientP12 = clientP12
        self.clientP12Password = clientP12Password
        self.verifyStrategy = verifyStrategy
        self.defaultValidation = defaultValidation
        self.validateDomain = validateDomain
        self.allHostsMustBeEvaluated = allHostsMustBeEvaluated
    }
}

/// 网络请求数据缓存相关配置
public struct WYNetworkRequestCache {
    
    /// 缓存数据唯一标识(Key)
    public static var cacheKey: String = ""
    public var cacheKey: String = cacheKey
    
    /// 数据缓存路径
    public static var cachePath: URL = WYStorage.createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/NetworkRequest")
    public var cachePath: URL = cachePath
    
    /// 数据缓存有效期
    public static var storageDurable: WYStorageDurable = .day(1)
    public var storageDurable: WYStorageDurable = storageDurable
    
    public init(cacheKey: String = cacheKey, cachePath: URL = cachePath, storageDurable: WYStorageDurable = storageDurable) {
        self.cacheKey = cacheKey
        self.cachePath = cachePath
        self.storageDurable = storageDurable
    }
}

/// 网络请求相关配置
public struct WYNetworkConfig {
    
    /// 网络请求验证方式
    public static var requestStyle: WYNetworkRequestStyle = .httpOrCAHttps
    public var requestStyle: WYNetworkRequestStyle = requestStyle
    
    /// HTTPS自建证书相关
    public static var httpsConfig: WYHttpsConfig = .default
    public var httpsConfig: WYHttpsConfig = httpsConfig
    
    /// 网络请求任务类型
    public static var taskMethod: WYTaskMethod = .parameters
    public var taskMethod: WYTaskMethod = taskMethod
    
    /// 设置网络请求超时时间
    public static var timeoutInterval: TimeInterval = 15
    public var timeoutInterval: TimeInterval = timeoutInterval
    
    /// 配置接口域名
    public static var domain: String = ""
    public var domain: String = domain
    
    /// 配置默认请求头
    public static var header: [String : String]? = ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"]
    public var header: [String : String]? = header
    
    /// 设置url中需要过滤的特殊字符，当url包含有特殊字符时，内部自动将 域名 和 路径 拼接为新的url，避免特殊字符导致的404错误
    public static var specialCharacters: [String] = ["?"]
    public var specialCharacters: [String] = specialCharacters
    
    /// 返回数据是否需要最原始的返回数据
    public static var originObject: Bool = false
    public var originObject: Bool = originObject
    
    /// 网络请求数据缓存相关配置(nil时不进行缓存)
    public static var requestCache: WYNetworkRequestCache? = nil
    public var requestCache: WYNetworkRequestCache? = requestCache

    /// 下载的文件、资源保存(缓存)路径
    public static var downloadSavePath: URL = WYStorage.createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Download")
    public var downloadSavePath: URL = downloadSavePath
    
    /// 下载是是否自动覆盖同名文件
    public static var removeSameNameFile: Bool = true
    public var removeSameNameFile: Bool = removeSameNameFile
    
    /// 网络请求时队列
    public static var callbackQueue: DispatchQueue? = .global()
    public var callbackQueue: DispatchQueue? = callbackQueue
    
    /// 自定义传入JSON解析时需要映射的Key及其对应的解析字段(仅针对第一层数据映射，第二层级以后的建议在对应的model类中使用Codable原生映射方法)
    public static var mapper: [WYMappingKey: String] = [:]
    public var mapper: [WYMappingKey: String] = mapper
    
    /// 配置服务端自定义的成功code
    public static var serverRequestSuccessCode: String = "200"
    public var serverRequestSuccessCode: String = serverRequestSuccessCode
    
    /// 配置网络连接失败code
    public static var networkServerFailCode: String = "10002"
    public var networkServerFailCode: String = networkServerFailCode
    
    /// 配置解包失败code
    public static var unpackServerFailCode: String = "10001"
    public var unpackServerFailCode: String = unpackServerFailCode
    
    /// Debug模式下是否打印网络请求日志
    public static var debugModeLog: Bool = true
    public var debugModeLog: Bool = debugModeLog
    
    /// 获取一个默认config
    public static let `default`: WYNetworkConfig = WYNetworkConfig()
    
    public init(requestStyle: WYNetworkRequestStyle = requestStyle, httpsConfig: WYHttpsConfig = httpsConfig, taskMethod: WYTaskMethod = taskMethod, timeoutInterval: TimeInterval = timeoutInterval, domain: String = domain, header: [String : String]? = nil, specialCharacters: [String] = specialCharacters, originObject: Bool = originObject, requestCache: WYNetworkRequestCache? = nil, downloadSavePath: URL = downloadSavePath, removeSameNameFile: Bool = removeSameNameFile, callbackQueue: DispatchQueue? = nil, mapper: [WYMappingKey : String] = mapper, serverRequestSuccessCode: String = serverRequestSuccessCode, networkServerFailCode: String = networkServerFailCode, unpackServerFailCode: String = unpackServerFailCode, debugModeLog: Bool = debugModeLog) {
        self.requestStyle = requestStyle
        self.httpsConfig = httpsConfig
        self.taskMethod = taskMethod
        self.timeoutInterval = timeoutInterval
        self.domain = domain
        self.header = header
        self.specialCharacters = specialCharacters
        self.originObject = originObject
        self.requestCache = requestCache
        self.downloadSavePath = downloadSavePath
        self.removeSameNameFile = removeSameNameFile
        self.callbackQueue = callbackQueue
        self.mapper = mapper
        self.serverRequestSuccessCode = serverRequestSuccessCode
        self.networkServerFailCode = networkServerFailCode
        self.unpackServerFailCode = unpackServerFailCode
        self.debugModeLog = debugModeLog
    }
}
