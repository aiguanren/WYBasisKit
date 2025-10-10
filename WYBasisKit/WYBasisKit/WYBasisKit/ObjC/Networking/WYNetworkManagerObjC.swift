////
////  WYNetworkManagerObjC.swift
////  WYBasisKit
////
////  Created by guanren on 2025/10/7.
////
//
//import Foundation
//
///// 网络请求任务类型
//@objc(WYTaskMethod)
//@frozen public enum WYTaskMethodObjC: Int {
//    
//    /// 数据任务
//    case parameters = 0
//    /// Data数据任务(对应Postman的raw)
//    case data
//    /// 上传任务
//    case upload
//    /// 下载任务
//    case download
//}
//
///// 上传类型
//@objc(WYFileType)
//@frozen public enum WYFileTypeObjC: Int {
//    
//    /// 上传图片
//    case image = 0
//    /// 上传音频
//    case audio
//    /// 上传视频
//    case video
//    /// URL路径上传
//    case urlPath
//}
//
///// 需要映射的Key
//@objc(WYMappingKey)
//@frozen public enum WYMappingKeyObjC: Int {
//    case message = 0
//    case code
//    case data
//}
//
///// 进度信息
//@objc(WYProgress)
//@objcMembers public class WYProgressObjC: NSObject {
//    
//    /// 完成的进度比 0 - 1
//    @objc public var progress: Double = 0
//    
//    /// 已完成的进度
//    @objc public var completedUnit: Int = 0
//    
//    /// 总的进度
//    @objc public var totalUnit: Int = 0
//    
//    /// 本地化描述
//    @objc public var info: String = ""
//    
//    @objc public init(progress: Double = 0, completedUnit: Int = 0, totalUnit: Int = 0, info: String = "") {
//        self.progress = progress
//        self.completedUnit = completedUnit
//        self.totalUnit = totalUnit
//        self.info = info
//    }
//}
//
///// 成功后的数据信息
//@objc(WYSuccess)
//@objcMembers public class WYSuccessObjC: NSObject {
//    
//    /// 源数据
//    @objc public var origin: String = ""
//    
//    /// 解包后的数据
//    @objc public var parse: String = ""
//    
//    /// 缓存数据
//    @objc public var storage: WYStorageDataObjC? = nil
//    
//    /// 是否是缓存数据
//    @objc public var isCache: Bool = false
//    
//    @objc public init(origin: String = "", parse: String = "", storage: WYStorageDataObjC? = nil, isCache: Bool = false) {
//        self.origin = origin
//        self.parse = parse
//        self.storage = storage
//        self.isCache = isCache
//    }
//}
//
///// 失败后的数据信息
//@objc(WYError)
//@objcMembers public class WYErrorObjC: NSObject {
//    
//    /// 错误码
//    @objc public var code: String = ""
//    
//    /// 详细错误描述
//    @objc public var describe: String = ""
//    
//    @objc public init(code: String = "", describe: String = "") {
//        self.code = code
//        self.describe = describe
//    }
//}
//
///// 下载数据信息
//@objc(WYDownloadModel)
//@objcMembers public class WYDownloadModelObjC: NSObject, Codable {
//    
//    /// 资源路径
//    @objc public var assetPath: String = ""
//    
//    /// 磁盘路径
//    @objc public var diskPath: String = ""
//    
//    /// 资源名
//    @objc public var assetName: String = ""
//    
//    /// 资源格式
//    @objc public var mimeType: String = ""
//    
//    @objc public init(assetPath: String = "", diskPath: String = "", assetName: String = "", mimeType: String = "") {
//        self.assetPath = assetPath
//        self.diskPath = diskPath
//        self.assetName = assetName
//        self.mimeType = mimeType
//    }
//}
//
///// 文件数据信息
//@objc(WYFileModel)
//@objcMembers public class WYFileModelObjC: NSObject {
//    
//    /**
//     *  上传的文件的上传后缀(选传项，例如，JPEG图像的MIME类型是image/jpeg，具体参考http://www.iana.org/assignments/media-types/.)
//     *  可根据具体的上传文件类型自由设置，默认上传图片时设置为image/jpeg，上传音频时设置为audio/aac，上传视频时设置为video/mp4，上传url时设置为application/octet-stream
//     */
//    private var _mimeType: String = ""
//    @objc public var mimeType: String {
//        
//        set {
//            _mimeType = newValue
//        }
//        get {
//            
//            if _mimeType.isEmpty == true {
//                
//                switch fileType {
//                case .image:
//                    _mimeType = "image/jpeg"
//                case .audio:
//                    _mimeType =  "audio/aac"
//                case .video:
//                    _mimeType =  "video/mp4"
//                case .urlPath:
//                    _mimeType =  "application/octet-stream"
//                }
//            }
//            return _mimeType
//        }
//    }
//    
//    /// 上传的文件的名字(选传项)
//    @objc public var fileName: String = ""
//    
//    /// 上传的文件的文件夹名字(选传项)
//    @objc public var folderName: String = "file"
//    
//    ///上传图片压缩比例(选传项，0~1.0区间，1.0代表无损，默认无损)
//    private var _compressionQuality: CGFloat = 1.0
//    @objc public var compressionQuality: CGFloat {
//        
//        set {
//            _compressionQuality = ((newValue > 1.0) || (newValue <= 0.0)) ? 1.0 : newValue
//        }
//        get {
//            return _compressionQuality
//        }
//    }
//    
//    /// 上传文件的类型(选传项，默认image)
//    @objc public var fileType: WYFileTypeObjC = .image
//    
//    /// 上传的图片
//    @objc public var image: UIImage? {
//        
//        willSet {
//            
//            if ((data == nil) && (newValue != nil)) {
//                
//                data = newValue!.jpegData(compressionQuality: compressionQuality)
//            }else {
//                fatalError("二进制文件 \(String(describing: data)) 与 图片 \(String(describing: image))只传入其中一项即可")
//            }
//        }
//    }
//    
//    /// 上传的二进制文件
//    @objc public var data: Data?
//    
//    /// 上传的资源URL路径
//    @objc public var fileUrl: String = ""
//    
//    @objc public init(mimeType: String = "", fileName: String = "", folderName: String = "file", compressionQuality: CGFloat = 1.0, fileType: WYFileTypeObjC = .image, image: UIImage? = nil, data: Data? = nil, fileUrl: String = "") {
//        self._mimeType = mimeType
//        self.fileName = fileName
//        self.folderName = folderName
//        self._compressionQuality = compressionQuality
//        self.fileType = fileType
//        self.image = image
//        self.data = data
//        self.fileUrl = fileUrl
//    }
//}
//
///**
// *  利用 Alamofire 进行网络活动监听
// *  iOS12开始 也可以通过系统 NWPathMonitor 实现监听，参考：https://www.cnblogs.com/breezemist/p/13602730.html
// */
//@objc(WYNetworkStatus)
//@objcMembers public class WYNetworkStatusObjC: NSObject {
//    
//    /**
//     *  当前是否连接到网络
//     */
//    @objc public static let isReachable: Bool = NetworkReachabilityManager.default?.isReachable ?? false
//    
//    /**
//     *  当前网络是否是蜂窝网络(移动数据流量)
//     */
//    @objc public static let isReachableOnCellular: Bool = NetworkReachabilityManager.default?.isReachableOnCellular ?? false
//    
//    /**
//     *  当前网络是否是WIFI网络
//     */
//    @objc public static let isReachableOnEthernetOrWiFi: Bool = NetworkReachabilityManager.default?.isReachableOnEthernetOrWiFi ?? false
//    
//    /**
//     *  当前网络状态
//     */
//    @objc public static let currentNetworkStatus: NetworkReachabilityManager.NetworkReachabilityStatus = NetworkReachabilityManager.default?.status ?? .notReachable
//    
//    /**
//     *  实时监听网络状态(不需要监听时需要手动调用 stopListening 方法结束监听状态)
//     *  alias 监听器对象别名，可根据别名获取到监听器对象
//     */
//    @objc public static func listening(_ alias: String, handler: @escaping (_ status: NetworkReachabilityManager.NetworkReachabilityStatus) -> Void?) {
//        
//        stopListening(alias)
//        if let reachabilityManager = NetworkReachabilityManager() {
//            listeningObjects[alias] = reachabilityManager
//            reachabilityManager.startListening(onUpdatePerforming: { status in
//                handler(status)
//            })
//        }else {
//            WYNetworkManager.wy_networkPrint("创建别名为 \(alias) 的网络监听器失败")
//        }
//    }
//    
//    /**
//     *  结束实时监听网络状态
//     *  alias 监听器别名，根据别名找到指定的监听器对象，停止实时监听
//     *  total 是否需要所有监听器对象都停止监听
//     */
//    @objc public static func stopListening(_ alias: String, total: Bool = false) {
//        guard total == true else {
//            if listeningObjects.keys.contains(alias) {
//                listeningObjects[alias]?.stopListening()
//                listeningObjects.removeValue(forKey: alias)
//                listeningObjects[alias] = nil
//            }
//            return
//        }
//        
//        for alias: String in listeningObjects.keys {
//            listeningObjects[alias]?.stopListening()
//            listeningObjects.removeValue(forKey: alias)
//            listeningObjects[alias] = nil
//        }
//    }
//    
//    /**
//     *  网络监听器容器
//     */
//    @objc public private(set) static var listeningObjects: [String: NetworkReachabilityManager] = [:]
//}
//
//public struct WYNetworkManager {
//    
//    /**
//     *  发起一个网络请求
//     *
//     *  @param method       网络请求类型
//     *
//     *  @param path         网络请求url路径
//     *
//     *  @param data         data数据任务时对应的data，非data数据任务传nil即可
//     *
//     *  @param parameter    参数
//     *
//     *  @param config       请求配置
//     *
//     *  @param progress     进度回调
//     *
//     *  @param success      成功回调
//     *
//     *  @param failure      失败回调
//     *
//     */
//    public static func request(method: HTTPMethod = .post, path: String = "", data: Data? = nil, parameter: [String : Any] = [:], config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none) {
//        
//        request(method: method, path: path, data: data, config: config, parameter: parameter, files: [], handler: handler)
//    }
//    
//    /**
//     *  发起一个上传请求
//     *
//     *  @param path         网络请求url路径
//     *
//     *  @param parameter    参数
//     *
//     *  @param files        要上传的文件
//     *
//     *  @param config       请求配置
//     *
//     *  @param progress     进度回调
//     *
//     *  @param success      成功回调
//     *
//     *  @param failure      失败回调
//     *
//     */
//    public static func upload(path: String = "", parameter: [String : Any] = [:], files: [WYFileModel], config: WYNetworkConfig = .default, progress:((_ progress: Double) -> Void)? = .none, handler:((_ result: WYHandler) -> Void)? = .none) {
//        
//        var taskConfig = config
//        taskConfig.taskMethod = .upload
//        
//        request(method: .post, path: path, data: nil, config: taskConfig, parameter: parameter, files: files, handler: handler)
//    }
//    
//    /**
//     *  发起一个下载请求
//     *
//     *  @param path         网络请求url路径
//     *
//     *  @param parameter    参数
//     *
//     *  @param assetName    自定义要保存的资源文件的名字，不传则使用默认名
//     *
//     *  @param config       请求配置
//     *
//     *  @param progress     进度回调
//     *
//     *  @param success      成功回调
//     *
//     *  @param failure      失败回调
//     *
//     */
//    public static func download(path: String = "", parameter: [String : Any] = [:], assetName: String = "", config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none) {
//        
//        var taskConfig = config
//        taskConfig.taskMethod = .download
//        
//        request(method: .get, path: path, data: nil, config: taskConfig, parameter: parameter, files: [], assetName: assetName, handler: handler)
//    }
//    
//    /**
//     *  清除缓存
//     *
//     *  @param path         要清除的资源的路径
//     *
//     *  @param asset        为空表示清除传入 path 下所有资源，否则表示清除传入 path 下对应 asset 的指定资源
//     *
//     *  @param complte      完成后回调，error 为空表示成功，否则为失败
//     *
//     */
//    public static func clearDiskCache(path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
//        
//        WYStorage.clearMemory(forPath: path, asset: asset, completion: completion)
//    }
//    
//    /// 取消所有网络请求
//    public static func cancelAllRequest() {
//        
//        Moya.Session.default.session.getAllTasks { (tasks) in
//            
//            tasks.forEach { (task) in
//                
//                task.cancel()
//            }
//        }
//    }
//    
//    /**
//     *  取消指定url的请求
//     *
//     *  @param domain      域名
//     *
//     *  @param path        网络请求url路径
//     *
//     */
//    public static func cancelRequest(domain: String = WYNetworkConfig.default.domain, path: String) {
//        
//        Moya.Session.default.session.getAllTasks { (tasks) in
//            
//            tasks.forEach { (task) in
//                
//                if (task.originalRequest?.url?.absoluteString == (domain + path)) {
//                    task.cancel()
//                }
//            }
//        }
//    }
//}
//
//extension WYNetworkManager {
//    
//    /// 网络连接模式与用户操作选项
//    private enum NetworkStatus {
//        
//        /// 未知网络，可能是不安全的连接
//        case unknown
//        /// 无网络连接
//        case notReachable
//        /// wifi网络
//        case reachableWifi
//        /// 蜂窝移动网络
//        case reachableCellular
//        
//        /// 用户未选择
//        case userNotSelectedConnect
//        /// 用户设置取消连接
//        case userCancelConnect
//        /// 用户设置继续连接
//        case userContinueConnect
//    }
//    
//    private static var networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
//    
//    private static func request(method: HTTPMethod, path: String, data: Data?, config: WYNetworkConfig = .default, parameter: [String : Any], files: [WYFileModel], assetName: String = "", handler:((_ result: WYHandler) -> Void)?) {
//        
//        checkNetworkStatus { (statusInfo) in
//            
//            if (statusInfo.0 == .userCancelConnect) {
//                
//                handlerFailure(error: WYError(code: config.networkServerFailCode, describe: statusInfo.1), debugModeLog: config.debugModeLog, handler: handler)
//                
//            }else {
//                
//                let request = WYRequest(method: method, path: path, data: data, parameter: parameter, files: files, assetName: assetName, config: config)
//                
//                let target = WYTarget(request: request)
//                
//                self.request(target: target, config: config, handler: handler)
//            }
//        }
//    }
//    
//    private static func request(target: WYTarget, config: WYNetworkConfig, handler:((_ result: WYHandler) -> Void)?) {
//        
//        if config.requestCache != nil {
//            
//            if config.requestCache!.cacheKey.count > 0 {
//                
//                let storageData = WYStorage.takeOut(forKey: config.requestCache!.cacheKey, path: config.requestCache!.cachePath.path)
//                
//                if (storageData.error == nil) && (handler != nil) && (storageData.userData != nil)  {
//                    
//                    if (config.originObject == true) {
//                        handler!(.success(WYSuccess(origin: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
//                    }else {
//                        handler!(.success(WYSuccess(parse: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
//                    }
//                }
//                
//            }else {
//                wy_networkPrint("由于传入的用于缓存的唯一标识 cacheKey 为空，本次请求不会被缓存")
//            }
//        }
//        
//        WYTargetProvider.request(target, callbackQueue: config.callbackQueue) { (progressResponse) in
//            
//            if handler != nil {
//                
//                handler!(.progress(WYProgress(progress: progressResponse.progress, completedUnit: progressResponse.progressObject?.completedUnitCount ?? 0, totalUnit: progressResponse.progressObject?.totalUnitCount ?? 0, description: progressResponse.progressObject?.description ?? "")))
//            }
//            
//        } completion: { (result) in
//            
//            switch result {
//                
//            case .success(let response):
//                
//                if config.taskMethod == .download {
//                    
//                    let format: String = ((response.response?.mimeType ?? "").components(separatedBy: "/").count > 1) ? ((response.response?.mimeType ?? "").components(separatedBy: "/").last ?? "") : ""
//                    let saveName: String = (target.request.assetName.isEmpty ? (response.response?.suggestedFilename ?? "") : target.request.assetName) + "." + format
//                    
//                    let saveUrl: URL = config.downloadSavePath.appendingPathComponent(saveName)
//                    showDebugModeLog(target: target, response: response, saveUrl: saveUrl)
//                    
//                    var downloadModel = WYDownloadModel()
//                    downloadModel.assetPath = saveUrl.path
//                    downloadModel.diskPath = config.downloadSavePath.path
//                    downloadModel.assetName = (target.request.assetName.isEmpty ? (response.response?.suggestedFilename ?? "") : target.request.assetName)
//                    downloadModel.mimeType = format
//                    
//                    let codable: WYCodable = WYCodable()
//                    let jsonString = try? codable.encode(String.self, from: downloadModel)
//                    handlerSuccess(response: WYSuccess(origin: jsonString ?? ""), handler: handler)
//                }else {
//                    
//                    let statusCode = response.statusCode
//                    
//                    if statusCode != 200 {
//                        
//                        showDebugModeLog(target: target, response: response)
//                        
//                        handlerFailure(error: WYError(code: String(statusCode), describe: WYLocalized("状态码异常", table: WYBasisKitConfig.kitLocalizableTable)), isStatusCodeError: true, debugModeLog: config.debugModeLog, handler: handler)
//                        
//                    }else {
//                        
//                        var storage: WYStorageData? = nil
//                        
//                        if config.originObject {
//                            
//                            if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) {
//                                
//                                storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: response.data, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
//                            }
//                            
//                            showDebugModeLog(target: target, response: response)
//                            
//                            handlerSuccess(response: WYSuccess(origin: String(data: response.data, encoding: .utf8) ?? "", storage: storage), handler: handler)
//                            
//                        }else {
//                            do {
//                                let codable: WYCodable = WYCodable()
//                                if config.mapper.isEmpty == false {
//                                    var mappingKeys: [[String]: String] = [[String]: String]()
//                                    if let mapperMessage: String = config.mapper[WYMappingKey.message] {
//                                        mappingKeys[[mapperMessage]] = "message"
//                                    }
//
//                                    if let mapperCode: String = config.mapper[WYMappingKey.code] {
//                                        mappingKeys[[mapperCode]] = "code"
//                                    }
//
//                                    if let mapperData: String = config.mapper[WYMappingKey.data] {
//                                        mappingKeys[[mapperData]] = "data"
//                                    }
//
//                                    if mappingKeys.isEmpty == false {
//                                        codable.mappingKeys = .mapper(mappingKeys)
//                                    }
//                                }
//                                
//                                let responseData = try codable.decode(WYResponse.self, from: response.data)
//                                
//                                if responseData.code == config.serverRequestSuccessCode {
//                                    
//                                    if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) && (responseData.data.isEmpty == false) {
//                                        
//                                        if let storageData: Data = responseData.data.data(using: .utf8) {
//                                            
//                                            storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: storageData, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
//                                        }
//                                    }
//                                    
//                                    showDebugModeLog(target: target, response: response)
//                                    
//                                    handlerSuccess(response: WYSuccess(parse: responseData.data, storage: storage), handler: handler)
//                                    
//                                }else {
//                                    
//                                    showDebugModeLog(target: target, response: response)
//                                    
//                                    handlerFailure(error: WYError(code: responseData.code, describe: (responseData.message.isEmpty ? WYLocalized("响应数据Code校验失败", table: WYBasisKitConfig.kitLocalizableTable) : responseData.message)), debugModeLog: config.debugModeLog, handler: handler)
//                                }
//                                
//                            } catch  {
//                                
//                                showDebugModeLog(target: target, response: response)
//                                
//                                handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
//                            }
//                        }
//                        guard let storageError = storage?.error else { return  }
//                        wy_networkPrint("数据缓存到本地失败：\(storageError)")
//                    }
//                }
//                break
//                
//            case .failure(let error):
//                
//                showDebugModeLog(target: target, response: Response(statusCode: error.errorCode, data: error.localizedDescription.data(using: .utf8) ?? Data()))
//                
//                handlerFailure(error: WYError(code: String(error.errorCode), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
//                
//                break
//            }
//        }
//    }
//    
//    private static func handlerSuccess(response: WYSuccess, handler:((_ success: WYHandler) -> Void)? = .none) {
//        
//        DispatchQueue.main.async {
//            
//            if (handler != nil) {
//                handler!(.success(response))
//            }
//        }
//    }
//    
//    private static func handlerFailure(error: WYError, isStatusCodeError: Bool = false, debugModeLog: Bool, function: String = #function, line: Int = #line, handler:((_ error: WYHandler) -> Void)? = .none) {
//        
//        DispatchQueue.main.async {
//            
//            if (handler != nil) {
//                
//                handler!(.error(error))
//            }
//            
//            guard debugModeLog == true else { return }
//            
//            if isStatusCodeError {
//                wy_networkPrint("statusCode: \(error.code)\n statusError:  \(error)", function: function, line: line)
//            }else {
//                wy_networkPrint("serverCode: \(error.code)\n serverError:  \(error)", function: function, line: line)
//            }
//        }
//    }
//    
//    private static func showDebugModeLog(target: WYTarget, response: Response, saveUrl: URL? = nil, function: String = #function, line: Int = #line) {
//        
//        let config = MoyaProvider<WYTarget>.config
//        
//        guard config.debugModeLog == true else { return }
//        
//        switch target.request.config.taskMethod {
//        case .data:
//            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n dataString: \((target.request.data == nil ? "" : (String(data: target.request.data!, encoding: .utf8))) ?? "")\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
//            
//        case .download:
//            wy_networkPrint("下载地址: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 资源保存路径: \(saveUrl?.absoluteString ?? "")", function: function, line: line)
//            
//        default:
//            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
//        }
//    }
//    
//    private static func checkNetworkStatus(handler: ((_ status: (NetworkStatus, String)) -> Void)? = .none) {
//        
//        networkStatus(showStatusAlert: false, openSeting: true, statusHandler: { (status) in
//            
//            DispatchQueue.main.async {
//                
//                if ((status == .unknown) || (status == .notReachable)) {
//                    
//                    if (networkSecurityInfo.0 == .userNotSelectedConnect) {
//                        
//                        networkStatus(showStatusAlert: true, openSeting: true, actionHandler: { (actionStr, networkStatus) in
//                            
//                            DispatchQueue.main.async {
//                                
//                                if (actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) {
//                                    
//                                    if (handler != nil) {
//                                        
//                                        handler!((.userContinueConnect, ""))
//                                    }
//                                    
//                                }else if ((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) || (actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable))) {
//                                    
//                                    if (handler != nil) {
//                                        
//                                        handler!((networkSecurityInfo.0, networkSecurityInfo.1))
//                                    }
//                                    
//                                }else {
//                                    
//                                    if (handler != nil) {
//                                        
//                                        handler!((.userNotSelectedConnect, ""))
//                                    }
//                                }
//                            }
//                        })
//                        
//                    }else {
//                        
//                        if (handler != nil) {
//                            
//                            handler!((networkSecurityInfo.0, networkSecurityInfo.1))
//                        }
//                    }
//                    
//                }else {
//                    
//                    networkStatus(showStatusAlert: false, openSeting: true, statusHandler: { (_) in
//                        
//                        DispatchQueue.main.async {
//                            
//                            if (handler != nil) {
//                                
//                                handler!((.userNotSelectedConnect, ""))
//                            }
//                        }
//                    })
//                }
//            }
//        })
//    }
//    
//    private static func networkStatus(showStatusAlert: Bool, openSeting: Bool, statusHandler:((_ status: NetworkStatus) -> Void)? = nil, actionHandler:((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
//        
//        let manager = NetworkReachabilityManager()
//        manager?.startListening(onQueue: .main, onUpdatePerforming: { (status) in
//            
//            var message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
//            var networkStatus = NetworkStatus.unknown
//            var actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized(WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
//            switch status {
//                
//            case .unknown:
//                message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
//                networkStatus = .unknown
//                actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
//                break
//            case .notReachable:
//                message = WYLocalized("不可用的网络，请确认您的网络环境或网络连接权限已正确设置", table: WYBasisKitConfig.kitLocalizableTable)
//                networkStatus = .notReachable
//                actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
//                break
//            case .reachable:
//                if manager!.isReachableOnCellular {
//                    
//                    message = WYLocalized("您正在使用蜂窝移动网络联网", table: WYBasisKitConfig.kitLocalizableTable)
//                    networkStatus = .reachableCellular
//                    actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
//                }else {
//                    
//                    message = WYLocalized("您正在使用Wifi联网", table: WYBasisKitConfig.kitLocalizableTable)
//                    networkStatus = .reachableWifi
//                    actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
//                }
//                break
//            }
//            
//            if (statusHandler != nil) {
//                
//                statusHandler!(networkStatus)
//            }
//            
//            showNetworkStatusAlert(showStatusAlert: showStatusAlert, status: networkStatus, message: message, actions: actions, actionHandler: actionHandler)
//            manager?.stopListening()
//        })
//    }
//    
//    private static func showNetworkStatusAlert(showStatusAlert: Bool, status: NetworkStatus, message: String, actions: [String], actionHandler: ((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
//        
//        if (showStatusAlert == false) {
//            
//            networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
//            return
//        }
//        
//        UIAlertController.wy_show(message: message, actions: actions) { (actionStr, _) in
//            
//            DispatchQueue.main.async(execute: {
//                
//                if (actionHandler != nil) {
//                    
//                    actionHandler!(actionStr, status)
//                }
//                
//                if actionStr == WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable) {
//                    
//                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
//                    
//                    let settingUrl = URL(string: UIApplication.openSettingsURLString)
//                    if let url = settingUrl, UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(settingUrl!, options: [:], completionHandler: nil)
//                    }
//                }else if ((actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) {
//                    
//                    networkSecurityInfo = (NetworkStatus.userContinueConnect, "")
//                    
//                }else if (((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) || ((actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .notReachable))) {
//                    
//                    let errorStr = (actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) ? WYLocalized("已取消不安全网络连接", table: WYBasisKitConfig.kitLocalizableTable) : WYLocalized("无网络连接，请检查您的网络设置", table: WYBasisKitConfig.kitLocalizableTable)
//                    networkSecurityInfo = (NetworkStatus.userCancelConnect, errorStr)
//                    
//                    cancelAllRequest()
//                    
//                }else {
//                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
//                }
//            })
//        }
//    }
//    
//    /// DEBUG打印日志
//    public static func wy_networkPrint(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
//        #if DEBUG
//        let timeFormatter = DateFormatter()
//        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
//        let time = timeFormatter.string(from: Date())
//        let message = messages.compactMap { "\($0)" }.joined(separator: " ")
//        let fileName = URL(fileURLWithPath: file).lastPathComponent
//        print("\n\(time) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n \(message)\n\n\n")
//        #endif
//    }
//}
