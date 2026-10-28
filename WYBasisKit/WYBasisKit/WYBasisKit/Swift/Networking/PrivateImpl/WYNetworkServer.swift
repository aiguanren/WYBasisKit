//
//  WYNetworkServer.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
import Moya
import Alamofire

struct WYRequest {
    
    /// 请求方式
    var method: HTTPMethod
    /// 网络请求url路径
    var path: String
    /// 参数
    var parameter: [String: Any]
    /// data数据任务时对应的data，非data数据任务传nil即可
    var data: Data?
    /// 要上传的文件
    var files: [WYFileModel]
    /// 请求配置
    var config: WYNetworkConfig = .default
    /// 自定义下载保存的文件名(默认文件名)
    var assetName: String
    
    var downloadStagingURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init(method: HTTPMethod, path: String, data: Data?, parameter: [String : Any], files: [WYFileModel] = [], assetName: String, config: WYNetworkConfig) {
        
        self.method = method
        self.path = path
        self.data = data
        self.parameter = parameter
        self.files = files
        self.assetName = assetName
        self.config = config
    }
}

struct WYTarget: TargetType {
    
    init(request: WYRequest) {
        self.request = request
    }
    
    var request: WYRequest
    
    /// domain/path配错或含非法字符时兜底用的占位地址(拿它发请求必然连接失败，错误经failed回调报给上层而不是闪退)
    static let invalidDomainURL: URL = URL(string: "https://invalid-domain.wybasiskit/")!
    
    var baseURL: URL {
        
        let domain: String = request.config.domain.isEmpty ? request.path : request.config.domain
        
        // 防domain与path都为空直接闪退:返回占位地址，请求会连接失败并经failed回调报错
        guard domain.isEmpty == false else {
            WYNetworkManager.wy_networkPrint("发起网络请求时 request.config.domain + request.path 不能为空")
            return WYTarget.invalidDomainURL
        }
        
        if (request.config.specialCharacters.contains(where: (domain.contains(request.path) ? domain : (request.config.domain + request.path)).contains)) {
            return URL(string: (domain.contains(request.path) ? domain : (request.config.domain + request.path))) ?? WYTarget.invalidDomainURL
        }else {
            return URL(string: domain) ?? WYTarget.invalidDomainURL
        }
    }
    
    var path: String {
        return baseURL.absoluteString.contains(request.path) ? "" : request.path
    }
    
    var method: Moya.Method {
        return request.method
    }
    
    var sampleData: Data {
        return "".data(using: .utf8)!
    }
    
    var task: Task {
        
        switch request.config.taskMethod {
        case .parameters:
            return .requestParameters(parameters: request.parameter, encoding: URLEncoding.default)
        case .data:
            return .requestCompositeData(bodyData: request.data ?? Data(), urlParameters: request.parameter)
        case .upload:
            var multiparts: [Moya.MultipartFormData] = []
            for fileModel in request.files {
                switch fileModel.fileType {
                case .urlPath:
                    let multipart = MultipartFormData(provider: .file(Self.fileURL(for: fileModel.fileUrl)), name: fileModel.folderName, fileName: fileModel.fileName, mimeType: fileModel.mimeType)
                    multiparts.append(multipart)
                default:
                    let multipart = MultipartFormData(provider: .data(fileModel.data ?? Data()), name: fileModel.folderName, fileName: fileModel.fileName, mimeType: fileModel.mimeType)
                    multiparts.append(multipart)
                }
            }
            return .uploadCompositeMultipart(multiparts, urlParameters: request.parameter)
        case .download:
            
            let downloadDestination: DownloadDestination = { temporaryURL, response in
                
                return (request.downloadStagingURL, [])
            }
            return .downloadParameters(parameters: request.parameter, encoding: URLEncoding.default, destination: downloadDestination)
        }
    }
    
    static func fileURL(for path: String) -> URL {
        if let url = URL(string: path), url.isFileURL { return url }
        return URL(fileURLWithPath: path)
    }

    static func downloadURL(for request: WYRequest, response: URLResponse) -> URL {
        let suggested = response.suggestedFilename ?? request.path.components(separatedBy: "?").first ?? ""
        var name = (request.assetName.isEmpty ? suggested : request.assetName) as NSString
        name = name.lastPathComponent as NSString
        if name.length == 0 { name = UUID().uuidString as NSString }
        if name.pathExtension.isEmpty, let mimeType = response.mimeType,
           let extensionName = UTType(mimeType: mimeType)?.preferredFilenameExtension {
            name = (name.appendingPathExtension(extensionName) ?? (name as String)) as NSString
        }
        return request.config.downloadSavePath.appendingPathComponent(name as String)
    }

    var headers: [String : String]? {
        return request.config.header
    }
}

struct WYProviderConfig<target: TargetType> {
    
    static func provider(config: WYNetworkConfig) throws -> MoyaProvider<WYTarget> {
        let requestClosure: MoyaProvider<WYTarget>.RequestClosure = { endpoint, done in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = config.timeoutInterval
                done(.success(request))
            } catch {
                done(.failure(.underlying(error, nil)))
            }
        }
        return MoyaProvider<WYTarget>(requestClosure: requestClosure, session: try session(config: config))
    }

    static func session(config: WYNetworkConfig) throws -> Session {
        let configuration = MoyaProvider<WYTarget>.defaultAlamofireSession().sessionConfiguration
        var serverTrustManager: ServerTrustManager? = nil
        var sessionDelegate: SessionDelegate = SessionDelegate()
        
        if config.requestStyle != .httpOrCAHttps {
            
            if let trustManager = config.httpsConfig.trustManager {
                serverTrustManager = trustManager
            } else if config.httpsConfig.verifyStrategy == .directTrust {
                var policies: [String: ServerTrustEvaluating] = [:]
                for domain in domainsFrom(domain: config.domain) { policies[domain] = DisabledTrustEvaluator() }
                serverTrustManager = ServerTrustManager(allHostsMustBeEvaluated: config.httpsConfig.allHostsMustBeEvaluated, evaluators: policies)
            } else {

                if let cerPath = ((Bundle(for: WYBothwayVerifyDelegate.self).path(forResource: config.httpsConfig.serverCer, ofType: "cer")) ?? (Bundle.main.path(forResource: config.httpsConfig.serverCer, ofType: "cer"))) {
                    do {
                        let certificationData = try Data(contentsOf: URL(fileURLWithPath: cerPath)) as CFData
                        guard let certificate = SecCertificateCreateWithData(nil, certificationData) else { throw CocoaError(.fileReadCorruptFile) }
                        do {
                            
                            let domains: [String] = domainsFrom(domain: config.domain)
                            
                            var trustEvaluator: ServerTrustEvaluating = DisabledTrustEvaluator()
                            
                            switch config.httpsConfig.verifyStrategy {
                            case .pinnedCertificates:
                                
                                let certificates: [SecCertificate] = [certificate]
                                
                                trustEvaluator = PinnedCertificatesTrustEvaluator(certificates: certificates, acceptSelfSignedCertificates: true, performDefaultValidation: config.httpsConfig.defaultValidation, validateHost: config.httpsConfig.validateDomain)
                                
                                break
                                
                            case .publicKeys:
                                
                                let certificates: [SecCertificate] = [certificate]
                                
                                let secKeys: [SecKey] = certificates.af.publicKeys
                                
                                trustEvaluator = PublicKeysTrustEvaluator(keys: secKeys, performDefaultValidation: config.httpsConfig.defaultValidation, validateHost: config.httpsConfig.validateDomain)
                                
                                break
                                
                            case .directTrust:
                                
                                trustEvaluator = DisabledTrustEvaluator()
                                
                                break
                            }
                            
                            var policies: [String: ServerTrustEvaluating] = [:]
                            
                            for index in 0..<domains.count {
                                policies[domains[index]] = trustEvaluator
                            }
                            serverTrustManager = ServerTrustManager(allHostsMustBeEvaluated: config.httpsConfig.allHostsMustBeEvaluated, evaluators: policies)
                            
                        }
                    } catch {
                        WYNetworkManager.wy_networkPrint("\(config.httpsConfig.serverCer).cer 这个证书转换为 CFData类型 失败")
                        throw error
                    }
                }else {
                    WYNetworkManager.wy_networkPrint("找不到 \(config.httpsConfig.serverCer).cer 这个证书")
                    throw CocoaError(.fileReadNoSuchFile)
                }
            }
            
            if config.requestStyle == .httpsBothway {
                sessionDelegate = config.httpsConfig.sessionDelegate ?? WYBothwayVerifyDelegate(config: config)
            }
        }
        return Session(configuration: configuration, delegate: sessionDelegate, startRequestsImmediately: false, serverTrustManager: serverTrustManager)
    }
    
    private static func domainsFrom(domain: String) -> [String] {
        
        var domains: [String] = [domain]
        if let url = URL(string: domain)  {
            if let hostName = url.host  {
                
                if domains.contains(hostName) == false {
                    domains.append(hostName)
                }
                
                let subStrings = hostName.components(separatedBy: ".")
                var domainName = ""
                let count = subStrings.count
                if count > 2 {
                    domainName = subStrings[count - 2] + "." + subStrings[count - 1]
                } else if count == 2 {
                    domainName = hostName
                }
                if domains.contains(domainName) == false {
                    domains.append(domainName)
                }
            }
        }else {
            // 防domain格式有误直接闪退:降级沿用原串作evaluators的key，配错时证书校验不通过会走错误回调
            WYNetworkManager.wy_networkPrint("使用HTTPS自建证书进行网络请求时 request.config.domain 传入有误，至少应该包含必要的域名部分")
        }
        return domains
    }
}

private class WYBothwayVerifyDelegate: SessionDelegate, @unchecked Sendable {

    private let config: WYNetworkConfig

    init(config: WYNetworkConfig) {
        self.config = config
        super.init()
    }
    
    override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodClientCertificate:
            
            guard let p12Path = ((Bundle(for: WYBothwayVerifyDelegate.self).path(forResource: config.httpsConfig.clientP12, ofType: "p12")) ?? (Bundle.main.path(forResource: config.httpsConfig.clientP12, ofType: "p12"))),
                  let p12Data = try? Data(contentsOf: URL(fileURLWithPath: p12Path)) else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // 导入失败改为返回nil走performDefaultHandling降级，防止p12配错直接闪退(握手失败会经failed回调把错误报给上层)
            guard let p12Contents = PKCS12(pkcs12Data: p12Data, password: config.httpsConfig.clientP12Password, clientP12: config.httpsConfig.clientP12),
                  let identity = p12Contents.identity else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            let credential = URLCredential(identity: identity,
                                           certificates: nil,
                                           persistence: .none)
            challenge.sender?.use(credential, for: challenge)
            completionHandler(.useCredential, credential)
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private struct PKCS12 {
        let label: String?
        let keyID: Data?
        let trust: SecTrust?
        let certChain: [SecTrust]?
        let identity: SecIdentity?
        
        // 防p12数据或密码有误直接闪退:改为可失败init，失败时打日志返回nil，由调用方降级处理
        public init?(pkcs12Data: Data, password: String, clientP12: String) {
            let importPasswordOption = [kSecImportExportPassphrase: password] as CFDictionary
            var items: CFArray?
            let secError = SecPKCS12Import(pkcs12Data as CFData, importPasswordOption, &items)
            
            guard secError == errSecSuccess else {
                if secError == errSecAuthFailed {
                    WYNetworkManager.wy_networkPrint("\(clientP12).p12 证书密码错误")
                }
                WYNetworkManager.wy_networkPrint("尝试导入证书时出错，错误代码：\(secError)")
                return nil
            }
            
            guard let theItems = items as? [[String: Any]] else {
                WYNetworkManager.wy_networkPrint("无效的 PKCS12 数据")
                return nil
            }
            
            func value<T>(forKey key: CFString) -> T? {
                for dict in theItems {
                    if let value = dict[key as String] as? T {
                        return value
                    }
                }
                return nil
            }
            
            self.label = value(forKey: kSecImportItemLabel)
            self.keyID = value(forKey: kSecImportItemKeyID)
            self.trust = value(forKey: kSecImportItemTrust)
            self.certChain = value(forKey: kSecImportItemCertChain)
            self.identity = value(forKey: kSecImportItemIdentity)
        }
    }
}

/// 正在执行的网络请求记录
final class WYNetworkRequestRegistry {

    static let shared = WYNetworkRequestRegistry()

    func register(provider: MoyaProvider<WYTarget>, url: String, onCancel: @escaping () -> Void) -> UUID {
        let identifier = UUID()
        lock.lock()
        entries[identifier] = Entry(provider: provider, url: url, onCancel: onCancel)
        lock.unlock()
        return identifier
    }

    func isActive(_ identifier: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return entries[identifier].map { !$0.cancelled } ?? false
    }

    func setCancellable(_ cancellable: Cancellable, for identifier: UUID) {
        lock.lock()
        let shouldCancel: Bool
        if var entry = entries[identifier] {
            entry.cancellable = cancellable
            shouldCancel = entry.cancelled
            entries[identifier] = entry
        } else {
            shouldCancel = true
        }
        lock.unlock()
        if shouldCancel { cancellable.cancel() }
    }

    func finish(_ identifier: UUID) -> Bool? {
        lock.lock()
        let entry = entries.removeValue(forKey: identifier)
        lock.unlock()
        return entry?.cancelled
    }

    func cancel(url: String?) {
        var cancellables: [Cancellable] = []
        var completions: [() -> Void] = []
        lock.lock()
        let matching = entries.filter { url == nil || $0.value.url == url }
        for (identifier, var entry) in matching {
            if let cancellable = entry.cancellable {
                entry.cancelled = true
                entries[identifier] = entry
                cancellables.append(cancellable)
            } else {
                entries.removeValue(forKey: identifier)
                completions.append(entry.onCancel)
            }
        }
        lock.unlock()
        cancellables.forEach { $0.cancel() }
        completions.forEach { $0() }
    }

    private let lock = NSLock()
    private var entries: [UUID: Entry] = [:]

    private struct Entry {
        let provider: MoyaProvider<WYTarget>
        let url: String
        let onCancel: () -> Void
        var cancellable: Cancellable?
        var cancelled = false
    }
}
