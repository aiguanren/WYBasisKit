//
//  WYNetworkManager.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Moya
import Network
import Alamofire

/// 网络请求任务类型
@frozen public enum WYTaskMethod: Int {
    
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
@frozen public enum WYFileType: Int {
    
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
@frozen public enum WYMappingKey: Int {
    case message = 0
    case code
    case data
}

/// 网络请求解析对象
public struct WYResponse: Codable {
    
    public var message: String = ""
    public var code: String = ""
    public var data: String = ""
    
    public init(message: String = "", code: String = "", data: String = "") {
        self.message = message
        self.code = code
        self.data = data
    }
}

/// 回调信息
@frozen public enum WYHandler {
    
    /// 进度回调
    case progress(_ progress: WYProgress)
    
    /// 成功回调
    case success(_ success: WYSuccess)
    
    /// 失败回调
    case error(_ error: WYError)
}

/// 进度信息
public struct WYProgress {
    
    /// 完成的进度比 0 - 1
    public var progress: Double = 0
    
    /// 已完成的进度
    public var completedUnit: Int64 = 0
    
    /// 总的进度
    public var totalUnit: Int64 = 0
    
    /// 本地化描述
    public var description: String = ""
    
    public init(progress: Double = 0, completedUnit: Int64 = 0, totalUnit: Int64 = 0, description: String = "") {
        self.progress = progress
        self.completedUnit = completedUnit
        self.totalUnit = totalUnit
        self.description = description
    }
}

/// 成功后的数据信息
public struct WYSuccess {
    
    /// 源数据
    public var origin: String = ""
    
    /// 解包后的数据
    public var parse: String = ""
    
    /// 缓存数据
    public var storage: WYStorageData? = nil
    
    /// 是否是缓存数据
    public var isCache: Bool = false
    
    public init(origin: String = "", parse: String = "", storage: WYStorageData? = nil, isCache: Bool = false) {
        self.origin = origin
        self.parse = parse
        self.storage = storage
        self.isCache = isCache
    }
}

/// 失败后的数据信息
public struct WYError {
    
    /// 错误码
    public var code: String = ""
    
    /// 详细错误描述
    public var describe: String = ""
    
    public init(code: String = "", describe: String = "") {
        self.code = code
        self.describe = describe
    }
}

/// 下载数据信息
public struct WYDownloadModel: Codable {
    
    /// 资源路径
    public var assetPath: String = ""
    
    /// 磁盘路径
    public var diskPath: String = ""
    
    /// 资源名
    public var assetName: String = ""
    
    /// 资源格式
    public var mimeType: String = ""
    
    public init(assetPath: String = "", diskPath: String = "", assetName: String = "", mimeType: String = "") {
        self.assetPath = assetPath
        self.diskPath = diskPath
        self.assetName = assetName
        self.mimeType = mimeType
    }
}

/// 文件数据信息
public struct WYFileModel {
    
    /**
     *  上传的文件的上传后缀(选传项，例如，JPEG图像的MIME类型是image/jpeg，具体参考http://www.iana.org/assignments/media-types/.)
     *  可根据具体的上传文件类型自由设置，默认上传图片时设置为image/jpeg，上传音频时设置为audio/aac，上传视频时设置为video/mp4，上传url时设置为application/octet-stream
     */
    private var _mimeType: String = ""
    public var mimeType: String {
        
        set {
            _mimeType = newValue
        }
        get {
            if _mimeType.isEmpty == true {
                switch fileType {
                case .image:
                    return "image/jpeg"
                case .audio:
                    return  "audio/aac"
                case .video:
                    return  "video/mp4"
                case .urlPath:
                    return  "application/octet-stream"
                }
            }
            return _mimeType
        }
    }
    
    /// 上传的文件的名字(选传项)
    public var fileName: String = ""
    
    /// 上传的文件的文件夹名字(选传项)
    public var folderName: String = "file"
    
    ///上传图片压缩比例(选传项，0~1.0区间，1.0代表无损，默认无损)
    private var _compressionQuality: CGFloat = 1.0
    public var compressionQuality: CGFloat {
        
        set {
            _compressionQuality = (!newValue.isFinite || newValue > 1.0 || newValue <= 0.0) ? 1.0 : newValue
        }
        get {
            return _compressionQuality
        }
    }
    
    /// 上传文件的类型(选传项，默认image)
    public var fileType: WYFileType = .image
    
    /// 上传的图片
    public var image: UIImage? {
        
        willSet {
            
            data = newValue?.jpegData(compressionQuality: compressionQuality)
        }
    }
    
    /// 上传的二进制文件
    public var data: Data?
    
    /// 上传的资源URL路径
    public var fileUrl: String = ""
    
    public init(mimeType: String = "", fileName: String = "", folderName: String = "file", compressionQuality: CGFloat = 1.0, fileType: WYFileType = .image, image: UIImage? = nil, data: Data? = nil, fileUrl: String = "") {
        self._mimeType = mimeType
        self.fileName = fileName
        self.folderName = folderName
        self._compressionQuality = (!compressionQuality.isFinite || compressionQuality > 1.0 || compressionQuality <= 0.0) ? 1.0 : compressionQuality
        self.fileType = fileType
        self.image = image
        self.data = data ?? image?.jpegData(compressionQuality: self._compressionQuality)
        self.fileUrl = fileUrl
    }
}


public struct WYNetworkManager {
    
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
    public static func request(method: HTTPMethod = .post, path: String = "", data: Data? = nil, parameter: [String : Any] = [:], config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none) {
        
        request(method: method, path: path, data: data, config: config, parameter: parameter, files: [], handler: handler)
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
    public static func upload(path: String = "", parameter: [String : Any] = [:], files: [WYFileModel], config: WYNetworkConfig = .default, progress:((_ progress: Double) -> Void)? = .none, handler:((_ result: WYHandler) -> Void)? = .none) {
        
        var taskConfig = config
        taskConfig.taskMethod = .upload
        
        request(method: .post, path: path, data: nil, config: taskConfig, parameter: parameter, files: files) { result in
            if case .progress(let value) = result { progress?(value.progress) }
            handler?(result)
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
    public static func download(path: String = "", parameter: [String : Any]? = nil, assetName: String? = nil, config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none) {
        
        var taskConfig = config
        taskConfig.taskMethod = .download
        
        request(method: .get, path: path, data: nil, config: taskConfig, parameter: parameter ?? [:], files: [], assetName: assetName ?? "", handler: handler)
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
    public static func clearDiskCache(path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
        
        WYStorage.clearMemory(forPath: path, asset: asset, completion: completion)
    }
    
    /// 取消所有网络请求
    public static func cancelAllRequest() {
        WYNetworkRequestRegistry.shared.cancel(url: nil)
    }

    /**
     *  取消指定url的请求
     *
     *  @param domain      域名
     *
     *  @param path        网络请求url路径
     *
     */
    public static func cancelRequest(domain: String = WYNetworkConfig.default.domain, path: String) {
        WYNetworkRequestRegistry.shared.cancel(url: domain + path)
    }
}
