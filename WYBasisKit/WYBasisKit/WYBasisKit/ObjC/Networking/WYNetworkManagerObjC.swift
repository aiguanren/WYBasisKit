//
//  WYNetworkManagerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/7.
//

#if canImport(WYBasisKitSwift)
import Foundation
import Alamofire
import WYBasisKitSwift

/// 网络请求类型(对应Alamofire中HTTPMethod)
@objc @frozen public enum WYHTTPMethod: Int {
    /**
     CONNECT 方法
     
     - 用途：建立到服务器的隧道（tunnel），通常用于 HTTPS 代理。
     - 场景：浏览器通过代理服务器访问 HTTPS 网站时先建立隧道。
     - 特点：不是用来获取数据，而是建立连接。
     */
    case connect = 0

    /**
     DELETE 方法
     
     - 用途：删除指定资源。
     - 场景：删除服务器上的某条记录，例如删除用户信息。
     - 特点：请求体通常为空，服务器收到请求后删除资源。
     */
    case delete

    /**
     GET 方法
     
     - 用途：请求获取服务器上的资源。
     - 场景：获取网页内容或 API 数据。
     - 特点：安全、幂等，请求数据通常放在 URL 参数里。
     */
    case get

    /**
     HEAD 方法
     
     - 用途：类似 GET，但只请求响应头，不返回响应体。
     - 场景：检查文件是否存在或获取文件大小、类型等。
     - 特点：比 GET 更轻量。
     */
    case head

    /**
     OPTIONS 方法
     
     - 用途：请求服务器支持的 HTTP 方法，或跨域请求前的预检。
     - 场景：浏览器 AJAX 请求跨域时先发 OPTIONS。
     - 特点：只是询问，不会修改资源。
     */
    case options

    /**
     PATCH 方法
     
     - 用途：对已有资源进行部分修改。
     - 场景：更新用户信息的一部分。
     - 特点：只修改请求体中提供的字段。
     */
    case patch

    /**
     POST 方法
     
     - 用途：提交数据到服务器，通常用于创建新资源或执行操作。
     - 场景：注册用户、提交表单等。
     - 特点：可以包含请求体，不幂等，多次请求可能创建多个资源。
     */
    case post

    /**
     PUT 方法
     
     - 用途：更新整个资源，或创建资源（如果不存在）。
     - 场景：修改用户信息的全部字段。
     - 特点：幂等，多次请求效果相同，用于完整替换资源。
     */
    case put

    /**
     QUERY 方法
     
     - 用途：自定义查询请求（HTTP 标准没有 QUERY 方法）。
     - 场景：可能用于表示查询类请求，逻辑上类似 GET。
     - 特点：视具体实现而定，通常不会修改资源。
     */
    case query

    /**
     TRACE 方法
     
     - 用途：请求服务器返回收到的原始请求，用于调试。
     - 场景：检查请求在代理/服务器链路中是否被修改。
     - 特点：安全风险高，一般生产环境不启用，用途较少。
     */
    case trace
    
    internal func convertToSwift() -> HTTPMethod {
        
        let swiftMethod: HTTPMethod
        switch self {
        case .connect: swiftMethod = .connect
        case .delete: swiftMethod = .delete
        case .get: swiftMethod = .get
        case .head: swiftMethod = .head
        case .options: swiftMethod = .options
        case .patch: swiftMethod = .patch
        case .post: swiftMethod = .post
        case .put: swiftMethod = .put
        case .query: swiftMethod = .query
        case .trace: swiftMethod = .trace
        }
        
        return swiftMethod
    }
}

/// 网络请求任务类型
@objc(WYTaskMethod)
@frozen public enum WYTaskMethodObjC: Int {
    
    /// 数据任务
    case parameters = 0
    /// Data数据任务(对应Postman的raw)
    case data
    /// 上传任务
    case upload
    /// 下载任务
    case download
}

/// 上传类型
@objc(WYFileType)
@frozen public enum WYFileTypeObjC: Int {
    
    /// 上传图片
    case image = 0
    /// 上传音频
    case audio
    /// 上传视频
    case video
    /// URL路径上传
    case urlPath
}

/// 需要映射的Key
@objc(WYMappingKey)
@frozen public enum WYMappingKeyObjC: Int {
    case message = 0
    case code
    case data
}

/// 回调信息
@objc(WYHandler)
@objcMembers public class WYHandlerObjC: NSObject {
    
    /// 进度回调
    @objc public var progress: WYProgressObjC?

    /// 成功回调
    @objc public var success: WYSuccessObjC?
    
    /// 失败回调
    @objc public var error: WYErrorObjC?
    
    /// 初始化方法
    public init(progress: WYProgressObjC? = nil, success: WYSuccessObjC? = nil, error: WYErrorObjC? = nil) {
        self.progress = progress
        self.success = success
        self.error = error
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftHandler: WYHandler) -> WYHandlerObjC {
        switch swiftHandler {
        case .progress(let progress):
            return WYHandlerObjC(progress: WYProgressObjC.objc(from: progress))
        case .success(let success):
            return WYHandlerObjC(success: WYSuccessObjC.objc(from: success))
        case .error(let error):
            return WYHandlerObjC(error: WYErrorObjC.objc(from: error))
        }
    }
}

/// 进度信息
@objc(WYProgress)
@objcMembers public class WYProgressObjC: NSObject {
    
    /// 完成的进度比 0 - 1
    @objc public var progress: Double = 0
    
    /// 已完成的进度
    @objc public var completedUnit: Int = 0
    
    /// 总的进度
    @objc public var totalUnit: Int = 0
    
    /// 本地化描述
    @objc public var info: String = ""
    
    @objc public init(progress: Double = 0, completedUnit: Int = 0, totalUnit: Int = 0, info: String = "") {
        self.progress = progress
        self.completedUnit = completedUnit
        self.totalUnit = totalUnit
        self.info = info
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftProgress: WYProgress) -> WYProgressObjC {
        return WYProgressObjC(
            progress: swiftProgress.progress,
            completedUnit: Int(swiftProgress.completedUnit),
            totalUnit: Int(swiftProgress.totalUnit),
            info: swiftProgress.description
        )
    }
}

/// 成功后的数据信息
@objc(WYSuccess)
@objcMembers public class WYSuccessObjC: NSObject {
    
    /// 源数据
    @objc public var origin: String = ""
    
    /// 解包后的数据
    @objc public var parse: String = ""
    
    /// 缓存数据
    @objc public var storage: WYStorageDataObjC? = nil
    
    /// 是否是缓存数据
    @objc public var isCache: Bool = false
    
    @objc public init(origin: String = "", parse: String = "", storage: WYStorageDataObjC? = nil, isCache: Bool = false) {
        self.origin = origin
        self.parse = parse
        self.storage = storage
        self.isCache = isCache
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftSuccess: WYSuccess) -> WYSuccessObjC {
        let storageObjC: WYStorageDataObjC?
        if let swiftStorage = swiftSuccess.storage {
            storageObjC = WYStorageDataObjC.objc(from: swiftStorage)
        } else {
            storageObjC = nil
        }
        
        return WYSuccessObjC(
            origin: swiftSuccess.origin,
            parse: swiftSuccess.parse,
            storage: storageObjC,
            isCache: swiftSuccess.isCache
        )
    }
}

/// 失败后的数据信息
@objc(WYError)
@objcMembers public class WYErrorObjC: NSObject {
    
    /// 错误码
    @objc public var code: String = ""
    
    /// 详细错误描述
    @objc public var describe: String = ""
    
    @objc public init(code: String = "", describe: String = "") {
        self.code = code
        self.describe = describe
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftError: WYError) -> WYErrorObjC {
        return WYErrorObjC(
            code: swiftError.code,
            describe: swiftError.describe
        )
    }
}

/// 下载数据信息
@objc(WYDownloadModel)
@objcMembers public class WYDownloadModelObjC: NSObject, Codable, WYCodableProtocol {
    
    /// 资源路径
    @objc public var assetPath: String = ""
    
    /// 磁盘路径
    @objc public var diskPath: String = ""
    
    /// 资源名
    @objc public var assetName: String = ""
    
    /// 资源格式
    @objc public var mimeType: String = ""
    
    @objc public override init() {}
    @objc public init(assetPath: String, diskPath: String, assetName: String, mimeType: String) {
        self.assetPath = assetPath
        self.diskPath = diskPath
        self.assetName = assetName
        self.mimeType = mimeType
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftDownloadModel: WYDownloadModel) -> WYDownloadModelObjC {
        return WYDownloadModelObjC(
            assetPath: swiftDownloadModel.assetPath,
            diskPath: swiftDownloadModel.diskPath,
            assetName: swiftDownloadModel.assetName,
            mimeType: swiftDownloadModel.mimeType
        )
    }
}

/// 文件数据信息
@objc(WYFileModel)
@objcMembers public class WYFileModelObjC: NSObject {
    
    /**
     *  上传的文件的上传后缀(选传项，例如，JPEG图像的MIME类型是image/jpeg，具体参考http://www.iana.org/assignments/media-types/.)
     *  可根据具体的上传文件类型自由设置，默认上传图片时设置为image/jpeg，上传音频时设置为audio/aac，上传视频时设置为video/mp4，上传url时设置为application/octet-stream
     */
    private var _mimeType: String = ""
    @objc public var mimeType: String {
        
        set {
            _mimeType = newValue
        }
        get {
            
            if _mimeType.isEmpty == true {
                
                switch fileType {
                case .image:
                    _mimeType = "image/jpeg"
                case .audio:
                    _mimeType =  "audio/aac"
                case .video:
                    _mimeType =  "video/mp4"
                case .urlPath:
                    _mimeType =  "application/octet-stream"
                }
            }
            return _mimeType
        }
    }
    
    /// 上传的文件的名字(选传项)
    @objc public var fileName: String = ""
    
    /// 上传的文件的文件夹名字(选传项)
    @objc public var folderName: String = "file"
    
    ///上传图片压缩比例(选传项，0~1.0区间，1.0代表无损，默认无损)
    private var _compressionQuality: CGFloat = 1.0
    @objc public var compressionQuality: CGFloat {
        
        set {
            _compressionQuality = ((newValue > 1.0) || (newValue <= 0.0)) ? 1.0 : newValue
        }
        get {
            return _compressionQuality
        }
    }
    
    /// 上传文件的类型(选传项，默认image)
    @objc public var fileType: WYFileTypeObjC = .image
    
    /// 上传的图片
    @objc public var image: UIImage? {
        
        willSet {
            
            if ((data == nil) && (newValue != nil)) {
                
                data = newValue!.jpegData(compressionQuality: compressionQuality)
            }else {
                fatalError("二进制文件 \(String(describing: data)) 与 图片 \(String(describing: image))只传入其中一项即可")
            }
        }
    }
    
    /// 上传的二进制文件
    @objc public var data: Data?
    
    /// 上传的资源URL路径
    @objc public var fileUrl: String = ""
    
    @objc public init(mimeType: String = "", fileName: String = "", folderName: String = "file", compressionQuality: CGFloat = 1.0, fileType: WYFileTypeObjC = .image, image: UIImage? = nil, data: Data? = nil, fileUrl: String = "") {
        self._mimeType = mimeType
        self.fileName = fileName
        self.folderName = folderName
        self._compressionQuality = compressionQuality
        self.fileType = fileType
        self.image = image
        self.data = data
        self.fileUrl = fileUrl
    }
    
    /// 转换为ObjC类型
    internal static func objc(from swiftFileModel: WYFileModel) -> WYFileModelObjC {
        
        let fileTypeObjC: WYFileTypeObjC = WYFileTypeObjC(rawValue: swiftFileModel.fileType.rawValue) ?? .image
        
        return WYFileModelObjC(
            mimeType: swiftFileModel.mimeType,
            fileName: swiftFileModel.fileName,
            folderName: swiftFileModel.folderName,
            compressionQuality: swiftFileModel.compressionQuality,
            fileType: fileTypeObjC,
            image: swiftFileModel.image,
            data: swiftFileModel.data,
            fileUrl: swiftFileModel.fileUrl
        )
    }
    
    /// 转换为Swift类型
    internal func convertToSwift() -> WYFileModel {
        
        let fileTypeSwift: WYFileType = WYFileType(rawValue: fileType.rawValue) ?? .image
        
        return WYFileModel(
            mimeType: mimeType,
            fileName: fileName,
            folderName: folderName,
            compressionQuality: compressionQuality,
            fileType: fileTypeSwift,
            image: image,
            data: data,
            fileUrl: fileUrl
        )
    }
}


@objc(WYNetworkManager)
@objcMembers public class WYNetworkManagerObjC: NSObject {
    
    /**
     *  发起一个网络请求
     *
     *  @param method       网络请求类型
     *
     *  @param path         网络请求url路径
     *
     *  @param data         data数据任务时对应的data，非data数据任务传nil即可
     *
     *  @param parameter    参数
     *
     *  @param config       请求配置
     *
     *  @param progress     进度回调
     *
     *  @param success      成功回调
     *
     *  @param failure      失败回调
     *
     */
    @objc public static func request(method: WYHTTPMethod = .post, path: String = "", parameter: [String : Any]? = nil, config: WYNetworkConfigObjC? = .defaultConfig, handler:((_ result: WYHandlerObjC) -> Void)? = .none) {
        request(method: method, path: path, data: nil, parameter: parameter ?? [:], config: config, handler: handler)
    }
    @objc public static func request(method: WYHTTPMethod = .post, path: String = "", data: Data? = nil, parameter: [String : Any] = [:], config: WYNetworkConfigObjC? = .defaultConfig, handler:((_ result: WYHandlerObjC) -> Void)? = .none) {
        
        let swiftConfig: WYNetworkConfig = (config == nil) ? .default : config!.convertToSwift()
        
        WYNetworkManager.request(method: method.convertToSwift(), path: path, data: data, parameter: parameter, config: swiftConfig) { result in
            if (handler != nil) {
                handler!(WYHandlerObjC.objc(from: result))
            }
        }
    }
    
    /**
     *  发起一个上传请求
     *
     *  @param path         网络请求url路径
     *
     *  @param parameter    参数
     *
     *  @param files        要上传的文件
     *
     *  @param config       请求配置
     *
     *  @param progress     进度回调
     *
     *  @param success      成功回调
     *
     *  @param failure      失败回调
     *
     */
    @objc public static func upload(path: String = "", parameter: [String : Any] = [:], files: [WYFileModelObjC], config: WYNetworkConfigObjC? = .defaultConfig, progress:((_ progress: Double) -> Void)? = .none, handler:((_ result: WYHandlerObjC) -> Void)? = .none) {
        
        let swiftConfig: WYNetworkConfig = (config == nil) ? .default : config!.convertToSwift()
        
        var taskConfig = swiftConfig
        taskConfig.taskMethod = .upload
        
        
        // 转换文件模型数组
        let swiftFiles = files.map { $0.convertToSwift() }
        
        WYNetworkManager.upload(path: path, parameter: parameter, files: swiftFiles, config: taskConfig, progress: progress) { result in
            if (handler != nil) {
                handler!(WYHandlerObjC.objc(from: result))
            }
        }
    }
    
    /**
     *  发起一个下载请求
     *
     *  @param path         网络请求url路径
     *
     *  @param parameter    参数
     *
     *  @param assetName    自定义要保存的资源文件的名字，不传则使用默认名
     *
     *  @param config       请求配置
     *
     *  @param progress     进度回调
     *
     *  @param success      成功回调
     *
     *  @param failure      失败回调
     *
     */
    @objc public static func download(path: String = "", parameter: [String : Any]? = nil, assetName: String? = nil, config: WYNetworkConfigObjC? = .defaultConfig, handler:((_ result: WYHandlerObjC) -> Void)? = .none) {
        
        let swiftConfig: WYNetworkConfig = (config == nil) ? .default : config!.convertToSwift()
        
        var taskConfig = swiftConfig
        taskConfig.taskMethod = .download
        
        WYNetworkManager.download(path: path, parameter: parameter, assetName: assetName, config: taskConfig) { result in
            if (handler != nil) {
                handler!(WYHandlerObjC.objc(from: result))
            }
        }
    }
    
    /**
     *  清除缓存
     *
     *  @param path         要清除的资源的路径
     *
     *  @param asset        为空表示清除传入 path 下所有资源，否则表示清除传入 path 下对应 asset 的指定资源
     *
     *  @param completion      完成后回调，error 为空表示成功，否则为失败
     *
     */
    @objc public static func clearDiskCache(path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
        WYNetworkManager.clearDiskCache(path: path, asset: asset, completion: completion)
    }
    
    /// 取消所有网络请求
    @objc public static func cancelAllRequest() {
        WYNetworkManager.cancelAllRequest()
    }
    
    /**
     *  取消指定url的请求
     *
     *  @param domain      域名
     *
     *  @param path        网络请求url路径
     *
     */
    @objc public static func cancelRequest(domain: String? = WYNetworkConfig.default.domain, path: String) {
        let requestDomain: String = domain ?? WYNetworkConfig.default.domain
        WYNetworkManager.cancelRequest(domain: requestDomain, path: path)
    }
}
#endif
