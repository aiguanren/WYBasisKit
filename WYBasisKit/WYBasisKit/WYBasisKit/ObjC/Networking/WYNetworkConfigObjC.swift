////
////  WYNetworkConfigObjC.swift
////  WYBasisKit
////
////  Created by guanren on 2025/10/7.
////
//
//import Foundation
//import Alamofire
//
///// 网络请求验证方式
//@objc(WYNetworkRequestStyle)
//@frozen public enum WYNetworkRequestStyleObjC: Int {
//    
//    /// HTTP和CAHTTPS(无需额外配置  CAHTTPS：即向正规CA机构购买的HTTPS服务)
//    case httpOrCAHttps = 0
//    /// HTTPS单向验证，客户端验证服务器(自建证书，需要将一个服务端的cer文件放进工程目录，并调用WYNetworkConfig.httpsConfig对应方法配置cer文件名)
//    case httpsSingle
//    /// HTTPS双向验证，客户端和服务端双向验证(自建证书，需要将一个服务端的cer文件与一个带密码的客户端p12文件放进工程目录，并调用WYNetworkConfig.httpsConfig对应方法配置cer、P12文件名与P12文件密码)
//    case httpsBothway
//}
//
///// HTTPS自建证书验证策略
//@objc(WYHttpsVerifyStrategy)
//@frozen public enum WYHttpsVerifyStrategyObjC: Int {
//    
//    /// 证书验证模式，客户端会将服务器返回的证书和本地保存的证书中的 所有内容 全部进行校验，如果正确，才继续执行
//    case pinnedCertificates = 0
//    
//    /// 公钥验证模式，客户端会将服务器返回的证书和本地保存的证书中的 公钥 部分 进行校验，如果正确，才继续执行
//    case publicKeys
//    
//    /// 不进行任何验证,无条件信任证书(不建议使用此选项，如果确实要使用此选项的，最好自己实现验证策略)
//    case directTrust
//}
//
///// HTTPS自建证书相关配置
//@objc(WYHttpsConfig)
//@objcMembers public class WYHttpsConfigObjC: NSObject {
//    
//    /// 自定义验证策略(内部使用)
//    public static var trustManager: ServerTrustManager? {
//        get { return WYHttpsConfig.trustManager }
//        set { WYHttpsConfig.trustManager = newValue }
//    }
//    public var trustManager: ServerTrustManager? = trustManager
//    
//    /// 自定义双向认证sessionDelegate
//    @objc public static var sessionDelegate: SessionDelegate? {
//        get { return WYHttpsConfig.sessionDelegate }
//        set { WYHttpsConfig.sessionDelegate = newValue }
//    }
//    @objc public var sessionDelegate: SessionDelegate? = sessionDelegate
//    
//    /// 配置自建证书HTTPS请求时server.cer文件名
//    @objc public static var serverCer: String {
//        get { return WYHttpsConfig.serverCer }
//        set { WYHttpsConfig.serverCer = newValue }
//    }
//    @objc public var serverCer: String = serverCer
//    
//    /// 配置自建证书HTTPS请求时client.p12文件名
//    @objc public static var clientP12: String {
//        get { return WYHttpsConfig.clientP12 }
//        set { WYHttpsConfig.clientP12 = newValue }
//    }
//    @objc public var clientP12: String = clientP12
//    
//    /// 配置自建证书HTTPS请求时client.p12文件密码
//    @objc public static var clientP12Password: String {
//        get { return WYHttpsConfig.clientP12Password }
//        set { WYHttpsConfig.clientP12Password = newValue }
//    }
//    @objc public var clientP12Password: String = clientP12Password
//    
//    /// 设置验证策略(安全等级)
//    @objc  public static var verifyStrategy: WYHttpsVerifyStrategyObjC {
//        get { return WYHttpsVerifyStrategyObjC(rawValue: WYHttpsConfig.verifyStrategy.rawValue) ?? .pinnedCertificates }
//        set { WYHttpsConfig.verifyStrategy = WYHttpsVerifyStrategy(rawValue: newValue.rawValue) ?? .pinnedCertificates }
//    }
//    @objc  public var verifyStrategy: WYHttpsVerifyStrategyObjC = verifyStrategy
//    
//    /// 是否执行默认验证
//    @objc public static var defaultValidation: Bool {
//        get { return WYHttpsConfig.defaultValidation }
//        set { WYHttpsConfig.defaultValidation = newValue }
//    }
//    @objc public var defaultValidation: Bool = defaultValidation
//    
//    /// 是否验证域名
//    @objc public static var validateDomain: Bool {
//        get { return WYHttpsConfig.validateDomain }
//        set { WYHttpsConfig.validateDomain = newValue }
//    }
//    @objc public var validateDomain: Bool = validateDomain
//    
//    /// 确定是否必须评估此“服务器信任管理器”的所有主机
//    @objc public static var allHostsMustBeEvaluated: Bool {
//        get { return WYHttpsConfig.allHostsMustBeEvaluated }
//        set { WYHttpsConfig.allHostsMustBeEvaluated = newValue }
//    }
//    @objc public var allHostsMustBeEvaluated: Bool = allHostsMustBeEvaluated
//    
//    /// 获取一个默认config
//    @objc public static let `default`: WYHttpsConfigObjC = WYHttpsConfigObjC()
//    
//    @objc public init(sessionDelegate: SessionDelegate? = nil, serverCer: String = serverCer, clientP12: String = clientP12, clientP12Password: String = clientP12Password, verifyStrategy: WYHttpsVerifyStrategyObjC = verifyStrategy, defaultValidation: Bool = defaultValidation, validateDomain: Bool = validateDomain, allHostsMustBeEvaluated: Bool = allHostsMustBeEvaluated) {
//        self.sessionDelegate = sessionDelegate
//        self.serverCer = serverCer
//        self.clientP12 = clientP12
//        self.clientP12Password = clientP12Password
//        self.verifyStrategy = verifyStrategy
//        self.defaultValidation = defaultValidation
//        self.validateDomain = validateDomain
//        self.allHostsMustBeEvaluated = allHostsMustBeEvaluated
//    }
//}
//
///// WYStorageDurableObjC包装类
//@objcMembers public class WYStorageDurableModel: NSObject {
//    
//    /// WYStorageDurableObjC枚举
//    @objc public var storageDurable: WYStorageDurableObjC = .unlimited
//    
//    /// storageDurable对应的间隔时间
//    @objc public var interval: TimeInterval = 0
//    
//    /// 唯一初始化方法
//    @objc public init(storageDurable: WYStorageDurableObjC, interval: TimeInterval = TimeInterval.infinity) {
//        self.storageDurable = storageDurable
//        self.interval = interval
//    }
//}
//
///// 网络请求数据缓存相关配置
//@objc(WYNetworkRequestCache)
//@objcMembers public class WYNetworkRequestCacheObjC: NSObject {
//    
//    /// 缓存数据唯一标识(Key)
//    @objc public static var cacheKey: String {
//        get { return WYNetworkRequestCache.cacheKey }
//        set { WYNetworkRequestCache.cacheKey = newValue }
//    }
//    @objc public var cacheKey: String = cacheKey
//    
//    /// 数据缓存路径
//    @objc public static var cachePath: URL {
//        get { return WYNetworkRequestCache.cachePath }
//        set { WYNetworkRequestCache.cachePath = newValue }
//    }
//    @objc public var cachePath: URL = cachePath
//    
//    /// 数据缓存有效期
//    @objc public static var storageDurable: WYStorageDurableModel {
//        get {
//            let swiftDurable: WYStorageDurable = WYNetworkRequestCache.storageDurable
//            switch swiftDurable {
//            case .minute(let interval):
//                internalStorageDurable.storageDurable = .minute
//                internalStorageDurable.interval = interval
//            case .hour(let interval):
//                internalStorageDurable.storageDurable = .hour
//                internalStorageDurable.interval = interval
//            case .day(let interval):
//                internalStorageDurable.storageDurable = .day
//                internalStorageDurable.interval = interval
//            case .week(let interval):
//                internalStorageDurable.storageDurable = .week
//                internalStorageDurable.interval = interval
//            case .month(let interval):
//                internalStorageDurable.storageDurable = .month
//                internalStorageDurable.interval = interval
//            case .year(let interval):
//                internalStorageDurable.storageDurable = .year
//                internalStorageDurable.interval = interval
//            case .unlimited:
//                internalStorageDurable.storageDurable = .unlimited
//                internalStorageDurable.interval = TimeInterval.infinity
//            }
//            return internalStorageDurable
//        }
//        set {
//            internalStorageDurable = newValue
//            switch internalStorageDurable.storageDurable {
//            case .minute:
//                WYNetworkRequestCache.storageDurable = .minute(internalStorageDurable.interval)
//            case .hour:
//                WYNetworkRequestCache.storageDurable = .hour(internalStorageDurable.interval)
//            case .day:
//                WYNetworkRequestCache.storageDurable = .day(internalStorageDurable.interval)
//            case .week:
//                WYNetworkRequestCache.storageDurable = .week(internalStorageDurable.interval)
//            case .month:
//                WYNetworkRequestCache.storageDurable = .month(internalStorageDurable.interval)
//            case .year:
//                WYNetworkRequestCache.storageDurable = .year(internalStorageDurable.interval)
//            case .unlimited:
//                WYNetworkRequestCache.storageDurable = .unlimited
//            }
//        }
//    }
//    @objc public var storageDurable: WYStorageDurableModel = storageDurable
//    
//    /// 内部使用，帮助storageDurable属性的get方法获取返回值，避免每次初始化WYStorageDurableModel
//    internal static var internalStorageDurable: WYStorageDurableModel = WYStorageDurableModel(storageDurable: .unlimited)
//    
//    @objc public init(cacheKey: String = cacheKey, cachePath: URL = cachePath, storageDurable: WYStorageDurableModel = storageDurable) {
//        self.cacheKey = cacheKey
//        self.cachePath = cachePath
//        self.storageDurable = storageDurable
//    }
//}
//
///// 网络请求相关配置
//@objc(WYNetworkConfig)
//@objcMembers public class WYNetworkConfigObjC: NSObject {
//    
//    /// 网络请求验证方式
//    @objc public static var requestStyle: WYNetworkRequestStyleObjC {
//        get { return WYNetworkRequestStyleObjC(rawValue: WYNetworkConfig.requestStyle.rawValue) ?? .httpOrCAHttps }
//        set { WYNetworkConfig.requestStyle = WYNetworkRequestStyle(rawValue: newValue.rawValue) ?? .httpOrCAHttps }
//    }
//    @objc public var requestStyle: WYNetworkRequestStyleObjC = requestStyle
//    
//    /// HTTPS自建证书相关
//    @objc public static var httpsConfig: WYHttpsConfigObjC {
//        get {
//            let swiftConfig = WYNetworkConfig.httpsConfig
//            
//            internalHttpsConfig.trustManager = swiftConfig.trustManager
//            internalHttpsConfig.sessionDelegate = swiftConfig.sessionDelegate
//            internalHttpsConfig.serverCer = swiftConfig.serverCer
//            internalHttpsConfig.clientP12 = swiftConfig.clientP12
//            internalHttpsConfig.clientP12Password = swiftConfig.clientP12Password
//            internalHttpsConfig.verifyStrategy = WYHttpsVerifyStrategyObjC(rawValue: swiftConfig.verifyStrategy.rawValue) ?? .pinnedCertificates
//            internalHttpsConfig.defaultValidation = swiftConfig.defaultValidation
//            internalHttpsConfig.validateDomain = swiftConfig.validateDomain
//            internalHttpsConfig.allHostsMustBeEvaluated = swiftConfig.allHostsMustBeEvaluated
//            
//            return internalHttpsConfig
//        }
//        set {
//            internalHttpsConfig = newValue
//            
//            WYNetworkConfig.httpsConfig.trustManager = internalHttpsConfig.trustManager
//            WYNetworkConfig.httpsConfig.sessionDelegate = internalHttpsConfig.sessionDelegate
//            WYNetworkConfig.httpsConfig.serverCer = internalHttpsConfig.serverCer
//            WYNetworkConfig.httpsConfig.clientP12 = internalHttpsConfig.clientP12
//            WYNetworkConfig.httpsConfig.clientP12Password = internalHttpsConfig.clientP12Password
//            WYNetworkConfig.httpsConfig.verifyStrategy = WYHttpsVerifyStrategy(rawValue: internalHttpsConfig.verifyStrategy.rawValue) ?? .pinnedCertificates
//            WYNetworkConfig.httpsConfig.defaultValidation = internalHttpsConfig.defaultValidation
//            WYNetworkConfig.httpsConfig.validateDomain = internalHttpsConfig.validateDomain
//            WYNetworkConfig.httpsConfig.allHostsMustBeEvaluated = internalHttpsConfig.allHostsMustBeEvaluated
//        }
//    }
//    @objc public var httpsConfig: WYHttpsConfigObjC = httpsConfig
//    
//    /// 网络请求任务类型
//    @objc public static var taskMethod: WYTaskMethodObjC {
//        get { return WYTaskMethodObjC(rawValue: WYNetworkConfig.taskMethod.rawValue) ?? .parameters }
//        set { WYNetworkConfig.taskMethod = WYTaskMethod(rawValue: newValue.rawValue) ?? .parameters }
//    }
//    @objc public var taskMethod: WYTaskMethodObjC = taskMethod
//    
//    /// 设置网络请求超时时间
//    @objc public static var timeoutInterval: TimeInterval {
//        get { return WYNetworkConfig.timeoutInterval }
//        set { WYNetworkConfig.timeoutInterval = newValue }
//    }
//    @objc public var timeoutInterval: TimeInterval = timeoutInterval
//    
//    /// 配置接口域名
//    @objc public static var domain: String {
//        get { return WYNetworkConfig.domain }
//        set { WYNetworkConfig.domain = newValue }
//    }
//    @objc public var domain: String = domain
//    
//    /// 配置默认请求头
//    @objc public static var header: [String : String]? {
//        get { return WYNetworkConfig.header }
//        set { WYNetworkConfig.header = newValue }
//    }
//    @objc public var header: [String : String]? = header
//    
//    /// 设置url中需要过滤的特殊字符，当url包含有特殊字符时，内部自动将 域名 和 路径 拼接为新的url，避免特殊字符导致的404错误
//    @objc public static var specialCharacters: [String] {
//        get { return WYNetworkConfig.specialCharacters }
//        set { WYNetworkConfig.specialCharacters = newValue }
//    }
//    @objc public var specialCharacters: [String] = specialCharacters
//    
//    /// 返回数据是否需要最原始的返回数据
//    @objc public static var originObject: Bool {
//        get { return WYNetworkConfig.originObject }
//        set { WYNetworkConfig.originObject = newValue }
//    }
//    @objc public var originObject: Bool = originObject
//    
//    /// 网络请求数据缓存相关配置(nil时不进行缓存)
//    @objc public static var requestCache: WYNetworkRequestCacheObjC? {
//        get {
//            if let swiftCache = WYNetworkConfig.requestCache {
//                
//                if internalRequestCache == nil {
//                    internalRequestCache = WYNetworkRequestCacheObjC()
//                }
//                internalRequestCache?.cacheKey = swiftCache.cacheKey
//                internalRequestCache?.cachePath = swiftCache.cachePath
//                
//                let objcStorageDurable: WYStorageDurableModel? = internalRequestCache?.storageDurable
//                
//                let swiftStorageDurable = swiftCache.storageDurable
//                switch swiftStorageDurable {
//                case .minute(let interval):
//                    objcStorageDurable?.storageDurable = .minute
//                    objcStorageDurable?.interval = interval
//                case .hour(let interval):
//                    objcStorageDurable?.storageDurable = .hour
//                    objcStorageDurable?.interval = interval
//                case .day(let interval):
//                    objcStorageDurable?.storageDurable = .day
//                    objcStorageDurable?.interval = interval
//                case .week(let interval):
//                    objcStorageDurable?.storageDurable = .week
//                    objcStorageDurable?.interval = interval
//                case .month(let interval):
//                    objcStorageDurable?.storageDurable = .month
//                    objcStorageDurable?.interval = interval
//                case .year(let interval):
//                    objcStorageDurable?.storageDurable = .year
//                    objcStorageDurable?.interval = interval
//                case .unlimited:
//                    objcStorageDurable?.storageDurable = .unlimited
//                    objcStorageDurable?.interval = TimeInterval.infinity
//                }
//                
//                internalRequestCache?.storageDurable = objcStorageDurable!
//            }
//            return nil
//        }
//        set {
//            internalRequestCache = newValue
//            
//            let swiftInternal: TimeInterval = internalRequestCache?.storageDurable.interval ?? 0
//            
//            switch internalRequestCache?.storageDurable.storageDurable {
//            case .minute:
//                WYNetworkConfig.requestCache?.storageDurable = .minute(swiftInternal)
//            case .hour:
//                WYNetworkConfig.requestCache?.storageDurable = .hour(swiftInternal)
//            case .day:
//                WYNetworkConfig.requestCache?.storageDurable = .day(swiftInternal)
//            case .week:
//                WYNetworkConfig.requestCache?.storageDurable = .week(swiftInternal)
//            case .month:
//                WYNetworkConfig.requestCache?.storageDurable = .month(swiftInternal)
//            case .year:
//                WYNetworkConfig.requestCache?.storageDurable = .year(swiftInternal)
//            case .unlimited:
//                WYNetworkConfig.requestCache?.storageDurable = .unlimited
//            case .none:
//                break
//            }
//        }
//    }
//    @objc public var requestCache: WYNetworkRequestCacheObjC? = requestCache
//
//    /// 下载的文件、资源保存(缓存)路径
//    @objc public static var downloadSavePath: URL {
//        get { return WYNetworkConfig.downloadSavePath }
//        set { WYNetworkConfig.downloadSavePath = newValue }
//    }
//    @objc public var downloadSavePath: URL = downloadSavePath
//    
//    /// 下载是是否自动覆盖同名文件
//    @objc public static var removeSameNameFile: Bool {
//        get { return WYNetworkConfig.removeSameNameFile }
//        set { WYNetworkConfig.removeSameNameFile = newValue }
//    }
//    @objc public var removeSameNameFile: Bool = removeSameNameFile
//    
//    /// 网络请求时队列
//    @objc public static var callbackQueue: DispatchQueue? {
//        get { return WYNetworkConfig.callbackQueue }
//        set { WYNetworkConfig.callbackQueue = newValue }
//    }
//    @objc public var callbackQueue: DispatchQueue? = callbackQueue
//    
//    /// 自定义传入JSON解析时需要映射的Key及其对应的解析字段(仅针对第一层数据映射，第二层级以后的建议在对应的model类中使用Codable原生映射方法),注意，这里key需要使用WYMappingKeyObjC,具体可以查看swift的实现
//    @objc public static var mapper: [NSNumber: String] {
//        get {
//            let swiftDic = WYNetworkConfig.mapper
//            var result: [NSNumber: String] = [:]
//            for (key, value) in swiftDic {
//                result[NSNumber(value: key.rawValue)] = value
//            }
//            return result
//        }
//        set {
//            var swiftDic: [WYMappingKey: String] = [:]
//            for (num, value) in newValue {
//                if let key = WYMappingKey(rawValue: num.intValue) {
//                    swiftDic[key] = value
//                }
//            }
//            WYNetworkConfig.mapper = swiftDic
//        }
//    }
//    @objc public var mapper: [NSNumber: String] = mapper
//    
//    /// 配置服务端自定义的成功code
//    @objc public static var serverRequestSuccessCode: String {
//        get { return WYNetworkConfig.serverRequestSuccessCode }
//        set { WYNetworkConfig.serverRequestSuccessCode = newValue }
//    }
//    @objc public var serverRequestSuccessCode: String = serverRequestSuccessCode
//    
//    /// 配置网络连接失败code
//    @objc public static var networkServerFailCode: String {
//        get { return WYNetworkConfig.networkServerFailCode }
//        set { WYNetworkConfig.networkServerFailCode = newValue }
//    }
//    @objc public var networkServerFailCode: String = networkServerFailCode
//    
//    /// 配置解包失败code
//    @objc public static var unpackServerFailCode: String {
//        get { return WYNetworkConfig.unpackServerFailCode }
//        set { WYNetworkConfig.unpackServerFailCode = newValue }
//    }
//    @objc public var unpackServerFailCode: String = unpackServerFailCode
//    
//    /// Debug模式下是否打印网络请求日志
//    @objc public static var debugModeLog: Bool {
//        get { return WYNetworkConfig.debugModeLog }
//        set { WYNetworkConfig.debugModeLog = newValue }
//    }
//    @objc public var debugModeLog: Bool = debugModeLog
//    
//    /// 获取一个默认config
//    @objc public static let `default`: WYNetworkConfigObjC = WYNetworkConfigObjC()
//    
//    /// 内部使用，帮助httpsConfig属性的get方法获取返回值，避免每次初始化WYHttpsConfigObjC
//    internal static var internalHttpsConfig: WYHttpsConfigObjC = WYHttpsConfigObjC()
//    
//    /// 内部使用，帮助requestCache属性的get方法获取返回值，避免每次初始化WYNetworkRequestCacheObjC
//    internal static var internalRequestCache: WYNetworkRequestCacheObjC?
//    
//    @objc public init(requestStyle: WYNetworkRequestStyleObjC = requestStyle, httpsConfig: WYHttpsConfigObjC = httpsConfig, taskMethod: WYTaskMethodObjC = taskMethod, timeoutInterval: TimeInterval = timeoutInterval, domain: String = domain, header: [String : String]? = nil, specialCharacters: [String] = specialCharacters, originObject: Bool = originObject, requestCache: WYNetworkRequestCacheObjC? = nil, downloadSavePath: URL = downloadSavePath, removeSameNameFile: Bool = removeSameNameFile, callbackQueue: DispatchQueue? = nil, mapper: [NSNumber : String] = mapper, serverRequestSuccessCode: String = serverRequestSuccessCode, networkServerFailCode: String = networkServerFailCode, unpackServerFailCode: String = unpackServerFailCode, debugModeLog: Bool = debugModeLog) {
//        self.requestStyle = requestStyle
//        self.httpsConfig = httpsConfig
//        self.taskMethod = taskMethod
//        self.timeoutInterval = timeoutInterval
//        self.domain = domain
//        self.header = header
//        self.specialCharacters = specialCharacters
//        self.originObject = originObject
//        self.requestCache = requestCache
//        self.downloadSavePath = downloadSavePath
//        self.removeSameNameFile = removeSameNameFile
//        self.callbackQueue = callbackQueue
//        self.mapper = mapper
//        self.serverRequestSuccessCode = serverRequestSuccessCode
//        self.networkServerFailCode = networkServerFailCode
//        self.unpackServerFailCode = unpackServerFailCode
//        self.debugModeLog = debugModeLog
//    }
//}
