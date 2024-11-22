//
//  WYNetworkServer.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

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

let WYTargetProvider = MoyaProvider<WYTarget>.config()

struct WYTarget: TargetType {
    
    init(request: WYRequest) {
        self.request = request
        MoyaProvider<WYTarget>.config = request.config
    }
    
    var request: WYRequest
    
    var baseURL: URL {
        
        let domain: String = request.config.domain.isEmpty ? request.path : request.config.domain
        
        guard domain.isEmpty == false else {
            fatalError("发起网络请求时 request.config.domain + request.path 不能为空")
        }
        
        if (request.config.specialCharacters.contains(where: (domain.contains(request.path) ? domain : (request.config.domain + request.path)).contains)) {
            return URL(string: (domain.contains(request.path) ? domain : (request.config.domain + request.path)))!
        }else {
            return URL(string: domain)!
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
            return .requestCompositeData(bodyData: request.data!, urlParameters: request.parameter)
        case .upload:
            var multiparts: [Moya.MultipartFormData] = []
            for var fileModel in request.files {
                switch fileModel.fileType {
                case .urlPath:
                    if let multipart = try? MultipartFormData(provider: .data(Data(contentsOf: URL(fileURLWithPath: fileModel.fileUrl))), name: fileModel.folderName, fileName: fileModel.fileName, mimeType: fileModel.mimeType) {
                        multiparts.append(multipart)
                    }
                default:
                    let multipart = MultipartFormData(provider: .data(fileModel.data!), name: fileModel.folderName, fileName: fileModel.fileName, mimeType: fileModel.mimeType)
                    multiparts.append(multipart)
                }
            }
            return .uploadCompositeMultipart(multiparts, urlParameters: request.parameter)
        case .download:

            let downloadDestination: DownloadDestination = { temporaryURL, response in
                
                let format: String = ((response.mimeType ?? "").components(separatedBy: "/").count > 1) ? ((response.mimeType ?? "").components(separatedBy: "/").last ?? "") : ""
                let saveName: String = (request.assetName.isEmpty ? (response.suggestedFilename ?? "") : request.assetName) + "." + format
                return (request.config.downloadSavePath.appendingPathComponent(saveName), request.config.removeSameNameFile ? [.removePreviousFile] : [])
            }
            return .downloadParameters(parameters: request.parameter, encoding: URLEncoding.default, destination: downloadDestination)
        }
    }
    
    var headers: [String : String]? {
        return request.config.header
    }
}

extension MoyaProvider {
    
    static var config: WYNetworkConfig {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, configKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, configKey) as? WYNetworkConfig ?? .default
        }
    }
    
    static func config(requestClosure: @escaping Moya.MoyaProvider<WYTarget>.RequestClosure = WYProviderConfig<WYTarget>.requestClosure,
                       session: Moya.Session = WYProviderConfig<WYTarget>.session()) -> MoyaProvider {
        return MoyaProvider(requestClosure: requestClosure, session: session)
    }
    
    static var configKey: UnsafeRawPointer {
        return UnsafeRawPointer(bitPattern: "configKey".hashValue)!
    }
}

struct WYProviderConfig<target: TargetType> {
    
    static func requestClosure(endpoint: Endpoint, done: @escaping MoyaProvider<WYTarget>.RequestResultClosure) {
        do {
            var request: URLRequest = try endpoint.urlRequest()
            request.timeoutInterval = MoyaProvider<WYTarget>.config.timeoutInterval
            done(.success(request))
        } catch {
            return
        }
    }
    
    static func session() -> Session {
        
        let defaultSession = MoyaProvider<WYTarget>.defaultAlamofireSession()
        let configuration = defaultSession.sessionConfiguration
        let config = MoyaProvider<WYTarget>.config
        
        var serverTrustManager: ServerTrustManager? = nil
        var sessionDelegate: SessionDelegate = SessionDelegate()
        
        if config.requestStyle != .httpOrCAHttps {
            
            if let trustManager = config.httpsConfig.trustManager {
                serverTrustManager = trustManager
            }else {
                
                if let cerPath = ((Bundle(for: WYBothwayVerifyDeleagte.self).path(forResource: config.httpsConfig.serverCer, ofType: "cer")) ?? (Bundle.main.path(forResource: config.httpsConfig.serverCer, ofType: "cer"))) {
                    do {
                        let certificationData = try Data(contentsOf: URL(fileURLWithPath: cerPath)) as CFData
                        if let certificate = SecCertificateCreateWithData(nil, certificationData){
                            
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
                    }
                }else {
                    WYNetworkManager.wy_networkPrint("找不到 \(config.httpsConfig.serverCer).cer 这个证书")
                }
            }
            
            if config.requestStyle == .httpsBothway {
                sessionDelegate = config.httpsConfig.sessionDelegate ?? WYBothwayVerifyDeleagte()
            }
        }
        return Session(configuration: configuration, delegate: sessionDelegate, serverTrustManager: serverTrustManager)
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
            fatalError("使用HTTPS自建证书进行网络请求时 request.config.domain 传入有误，至少应该包含必要的域名部分")
        }
        return domains
    }
}

private class WYBothwayVerifyDeleagte: SessionDelegate {
    
    override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodClientCertificate:
            
            let config = MoyaProvider<WYTarget>.config
            
            guard let p12Path = ((Bundle(for: WYBothwayVerifyDeleagte.self).path(forResource: config.httpsConfig.clientP12, ofType: "p12")) ?? (Bundle.main.path(forResource: config.httpsConfig.clientP12, ofType: "p12"))),
                  let p12Data = try? Data(contentsOf: URL(fileURLWithPath: p12Path)) else {
                      completionHandler(.performDefaultHandling, nil)
                      return
                  }
            
            let p12Contents = PKCS12(pkcs12Data: p12Data, password: config.httpsConfig.clientP12Password, clientP12: config.httpsConfig.clientP12)
            guard let identity = p12Contents.identity else {
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
        let keyID: NSData?
        let trust: SecTrust?
        let certChain: [SecTrust]?
        let identity: SecIdentity?
        
        public init(pkcs12Data: Data, password: String, clientP12: String) {
            let importPasswordOption: NSDictionary
            = [kSecImportExportPassphrase as NSString: password]
            var items: CFArray?
            let secError: OSStatus
            = SecPKCS12Import(pkcs12Data as NSData,
                              importPasswordOption, &items)
            guard secError == errSecSuccess else {
                if secError == errSecAuthFailed {
                    WYNetworkManager.wy_networkPrint("\(clientP12).p12 证书密码错误")
                }
                fatalError("尝试导入 \(pkcs12Data) 时出错")
            }
            guard let theItemsCFArray = items else { fatalError() }
            let theItemsNSArray: NSArray = theItemsCFArray as NSArray
            guard let dictArray
                    = theItemsNSArray as? [[String: AnyObject]] else {
                        fatalError()
                    }
            func f<T>(key: CFString) -> T? {
                for dict in dictArray {
                    if let value = dict[key as String] as? T {
                        return value
                    }
                }
                return nil
            }
            self.label = f(key: kSecImportItemLabel)
            self.keyID = f(key: kSecImportItemKeyID)
            self.trust = f(key: kSecImportItemTrust)
            self.certChain = f(key: kSecImportItemCertChain)
            self.identity = f(key: kSecImportItemIdentity)
        }
    }
}
