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
            _compressionQuality = ((newValue > 1.0) || (newValue <= 0.0)) ? 1.0 : newValue
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
            
            if ((data == nil) && (newValue != nil)) {
                
                data = newValue!.jpegData(compressionQuality: compressionQuality)
            }else {
                fatalError("二进制文件 \(String(describing: data)) 与 图片 \(String(describing: image))只传入其中一项即可")
            }
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
        self._compressionQuality = compressionQuality
        self.fileType = fileType
        self.image = image
        self.data = data
        self.fileUrl = fileUrl
    }
}

/**
 *  利用 NWPathMonitor 进行网络活动监听
 */
public struct WYNetworkStatus {
    
    /// 当前是否连接到网络
    public static var isReachable: Bool {
        return currentPath.status == .satisfied
    }
    
    /// 当前网络是否是无法连接状态(可能是飞行模式、断网或信号太差等原因)
    public static var isNotReachable: Bool {
        return currentPath.status == .unsatisfied
    }
    
    /// 当前网络是否是蜂窝网络(移动数据流量)
    public static var isReachableOnCellular: Bool {
        return currentPath.usesInterfaceType(.cellular)
    }
    
    /// 当前网络是否是 WiFi 网络
    public static var isReachableOnWiFi: Bool {
        return currentPath.usesInterfaceType(.wifi)
    }
    
    /// 当前网络是否是有线网络(例如通过网线或适配器)
    public static var isReachableOnWiredEthernet: Bool {
        return currentPath.usesInterfaceType(.wiredEthernet)
    }
    
    /// 当前网络是否通过 VPN 连接
    public static var isReachableOnVPN: Bool {
#if os(macOS)
        return currentPath.usesInterfaceType(.vpn)
#else
        let vpnPrefixes = ["utun", "ppp", "ipsec"]
        if currentPath.availableInterfaces.contains(where: { iface in
            vpnPrefixes.contains { iface.name.lowercased().hasPrefix($0) }
        }) {
            return true
        }
        return false
#endif
    }
    
    /// 当前网络是否为本地回环接口(通常用于本机内部通信，如 127.0.0.1)
    public static var isLoopback: Bool {
        return currentPath.usesInterfaceType(.loopback)
    }
    
    /// 当前网络是否被系统标记为"昂贵"连接（如蜂窝数据，可能会产生流量费用）
    public static var isExpensive: Bool {
        return currentPath.isExpensive
    }
    
    /// 当前网络是否需要额外步骤才能建立连接（如需要登录认证的网络）
    public static var requiresConnection: Bool {
        return currentPath.status == .requiresConnection
    }
    
    /// 当前网络是否为其他网络(未知类型，无法识别的网络接口，虚拟网络设备、未知硬件通道、Apple 特定测试接口等)
    public static var isReachableOnOther: Bool {
        return currentPath.usesInterfaceType(.other)
    }
    
    /// 当前网络是否支持 IPv4
    public static var supportsIPv4: Bool {
        return currentPath.supportsIPv4
    }
    
    /// 当前网络是否支持 IPv6
    public static var supportsIPv6: Bool {
        return currentPath.supportsIPv6
    }
    
    /// 当前网络状态
    public static var currentNetworkStatus: NWPath.Status {
        return currentPath.status
    }
    
    /// 获取 currentPath（如果还没有监听过，则主动检测一次）
    public static var currentPath: NWPath {
        pathLock.lock()
        defer { pathLock.unlock() }
        
        if let existing = _currentPath {
            return existing
        }
        
        // 如果已经在初始化中，返回临时路径避免重复初始化
        if _isInitializing {
            return createTemporaryPath()
        }
        
        // 标记初始化开始
        _isInitializing = true
        
        // 异步初始化当前路径
        initializeCurrentPathAsync()
        
        // 返回临时路径，避免阻塞调用者
        return createTemporaryPath()
    }
    
    /**
     *  实时监听网络状态
     *  - Parameters:
     *    - alias: 监听器别名
     *    - queue: 回调队列，默认为主队列
     *    - handler: 回调 path
     */
    public static func listening(_ alias: String,
                                 queue: DispatchQueue = .main,
                                 handler: @escaping (_ nwpath: NWPath) -> Void) {
        
        // 如果该 alias 已存在且有 path，则立即回调
        if let existingPath = getCurrentPath(for: alias) {
            handler(existingPath)
            return
        }
        
        stopListening(alias)
        
        let monitor = NWPathMonitor()
        
        // 先保存监听器，确保强引用
        saveMonitor(monitor, for: alias)
        
        // 记录上一次的路径状态，用于去重
        var lastPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            // 检查路径是否真正发生变化
            guard hasPathChanged(from: lastPath, to: path) else {
                return
            }
            
            lastPath = path
            
            // 更新路径信息
            updateCurrentPath(path, for: alias)
            
            // 在主线程回调
            queue.async {
                handler(path)
            }
            
            // 安全检查：如果监听器已被移除，则取消
            guard isListening(alias) else {
                monitor.cancel()
                // 延迟清理闭包引用
                cleanupMonitorReferences(for: alias, after: 0.1)
                return
            }
        }
        
        let monitorQueue = DispatchQueue(label: "com.wy.networkstatus.\(alias)")
        monitor.start(queue: monitorQueue)
    }
    
    /**
     *  停止监听
     *  - Parameters:
     *    - alias: 监听器别名，如果为 nil 则停止所有监听器
     */
    public static func stopListening(_ alias: String? = nil) {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        
        if let alias = alias {
            // 停止特定监听器
            if let monitor = listeningObjects[alias] {
                monitor.cancel()
                // 延迟清理闭包引用，防止内存问题
                cleanupMonitorReferences(for: alias, after: 0.1)
            }
            listeningObjects.removeValue(forKey: alias)
            lastPaths.removeValue(forKey: alias) // 清理去重缓存
            currentPaths.removeValue(forKey: alias)
        } else {
            // 停止所有监听器
            listeningObjects.values.forEach { $0.cancel() }
            
            // 延迟清理所有闭包引用
            cleanupAllMonitorReferences(after: 0.1)
            
            listeningObjects.removeAll()
            lastPaths.removeAll() // 清理所有去重缓存
            currentPaths.removeAll()
        }
        
        // 如果没有活跃的监听器，清空当前路径缓存
        if listeningObjects.isEmpty {
            pathLock.lock()
            _currentPath = nil
            pathLock.unlock()
        }
    }
    
    /// 检查指定别名的监听器是否存在
    public static func isListening(_ alias: String) -> Bool {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return listeningObjects[alias] != nil
    }
    
    /// 获取所有活跃的监听器别名
    public static var activeListeners: [String] {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return Array(listeningObjects.keys)
    }
    
    /// 保护 _currentPath 的线程锁
    private static let pathLock = NSLock()
    
    /// 保护监听器相关容器的线程锁
    private static let listenerLock = NSLock()
    
    /// 当前网络路径缓存（线程安全访问）
    private static var _currentPath: NWPath?
    
    /// 是否正在异步初始化当前路径
    private static var _isInitializing: Bool = false
    
    /// 网络监听器容器
    private static var listeningObjects: [String: NWPathMonitor] = [:]
    
    /// 每个 alias 对应的最新 NWPath
    private static var currentPaths: [String: NWPath] = [:]
    
    /// 每个 alias 对应的上一次 NWPath（用于去重）
    private static var lastPaths: [String: NWPath] = [:]
    
    /// 用于一次性路径检测的共享队列（使用 utility QoS 平衡性能和能效）
    private static let detectionQueue = DispatchQueue(label: "com.wy.networkstatus.detection", qos: .utility)
    
    /// 异步初始化当前路径
    private static func initializeCurrentPathAsync() {
        detectionQueue.async {
            let path = getCurrentPathSynchronously()
            
            pathLock.lock()
            _currentPath = path
            _isInitializing = false
            pathLock.unlock()
        }
    }
    
    /// 创建临时路径（用于异步初始化期间）
    private static func createTemporaryPath() -> NWPath {
        // 使用快速同步方式获取临时路径
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var tempPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            tempPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        let tempQueue = DispatchQueue(label: "com.wy.networkstatus.temp")
        monitor.start(queue: tempQueue)
        
        // 短暂等待，避免阻塞
        _ = semaphore.wait(timeout: .now() + 0.1)
        
        return tempPath ?? createFallbackPath()
    }
    
    /// 创建回退路径
    private static func createFallbackPath() -> NWPath {
        let monitor = NWPathMonitor()
        var fallbackPath: NWPath?
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            fallbackPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        _ = semaphore.wait(timeout: .now() + 0.05)
        
        // 如果仍然失败，返回系统默认状态
        return fallbackPath ?? createFinalFallbackPath()
    }
    
    /// 创建最终回退路径
    private static func createFinalFallbackPath() -> NWPath {
        let monitor = NWPathMonitor()
        var finalPath: NWPath?
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            finalPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        _ = semaphore.wait(timeout: .now() + 0.5)
        
        // 最终保障：如果仍然失败，创建新的 monitor 获取路径
        return finalPath ?? NWPathMonitor().currentPath
    }
    
    /// 同步获取当前网络路径
    private static func getCurrentPathSynchronously() -> NWPath {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var detectedPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            detectedPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        // 在共享队列启动监听，避免创建过多队列
        monitor.start(queue: detectionQueue)
        
        // 最多等待 1.0 秒，给系统足够时间检测
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        // 如果检测失败，使用备选方案
        if let path = detectedPath {
            return path
        } else {
            // 创建 unsatisfied 状态的路径
            return createUnsatisfiedPathWithoutRecursion()
        }
    }
    
    /// 创建 unsatisfied 路径
    private static func createUnsatisfiedPathWithoutRecursion() -> NWPath {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var unsatisfiedPath: NWPath?
        
        monitor.pathUpdateHandler = { path in
            unsatisfiedPath = path
            semaphore.signal()
            monitor.cancel()
        }
        
        monitor.start(queue: detectionQueue)
        
        // 短暂等待获取路径
        _ = semaphore.wait(timeout: .now() + 0.3)
        
        // 如果仍然无法获取，使用默认的 unsatisfied 状态
        return unsatisfiedPath ?? createFallbackPath()
    }
    
    /// 延迟清理监听器引用
    private static func cleanupMonitorReferences(for alias: String, after delay: TimeInterval) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            listenerLock.lock()
            // 确保监听器已经被移除后再清理相关引用
            if listeningObjects[alias] == nil {
                lastPaths.removeValue(forKey: alias)
                currentPaths.removeValue(forKey: alias)
            }
            listenerLock.unlock()
        }
    }
    
    /// 延迟清理所有监听器引用
    private static func cleanupAllMonitorReferences(after delay: TimeInterval) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            listenerLock.lock()
            // 清理所有相关引用
            lastPaths.removeAll()
            currentPaths.removeAll()
            listenerLock.unlock()
        }
    }
    
    /// 检查路径是否真正发生变化
    private static func hasPathChanged(from oldPath: NWPath?, to newPath: NWPath) -> Bool {
        guard let oldPath = oldPath else {
            return true // 第一次回调，总是视为变化
        }
        
        // 比较关键属性是否发生变化
        return oldPath.status != newPath.status ||
        oldPath.isExpensive != newPath.isExpensive ||
        oldPath.supportsIPv4 != newPath.supportsIPv4 ||
        oldPath.supportsIPv6 != newPath.supportsIPv6 ||
        oldPath.availableInterfaces.count != newPath.availableInterfaces.count
    }
    
    /// 保存监听器
    private static func saveMonitor(_ monitor: NWPathMonitor, for alias: String) {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        listeningObjects[alias] = monitor
    }
    
    /// 获取指定别名的当前路径
    private static func getCurrentPath(for alias: String) -> NWPath? {
        listenerLock.lock()
        defer { listenerLock.unlock() }
        return currentPaths[alias]
    }
    
    /// 更新路径信息
    private static func updateCurrentPath(_ path: NWPath, for alias: String) {
        // 更新全局当前路径
        pathLock.lock()
        _currentPath = path
        pathLock.unlock()
        
        // 更新别名对应的路径
        listenerLock.lock()
        currentPaths[alias] = path
        listenerLock.unlock()
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
        
        request(method: .post, path: path, data: nil, config: taskConfig, parameter: parameter, files: files, handler: handler)
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
    public static func download(path: String = "", parameter: [String : Any] = [:], assetName: String = "", config: WYNetworkConfig = .default, handler:((_ result: WYHandler) -> Void)? = .none) {
        
        var taskConfig = config
        taskConfig.taskMethod = .download
        
        request(method: .get, path: path, data: nil, config: taskConfig, parameter: parameter, files: [], assetName: assetName, handler: handler)
    }
    
    /**
     *  清除缓存
     *
     *  @param path         要清除的资源的路径
     *
     *  @param asset        为空表示清除传入 path 下所有资源，否则表示清除传入 path 下对应 asset 的指定资源
     *
     *  @param complte      完成后回调，error 为空表示成功，否则为失败
     *
     */
    public static func clearDiskCache(path: String, asset: String = "", completion:((_ error: String?) -> Void)? = .none) {
        
        WYStorage.clearMemory(forPath: path, asset: asset, completion: completion)
    }
    
    /// 取消所有网络请求
    public static func cancelAllRequest() {
        
        Moya.Session.default.session.getAllTasks { (tasks) in
            
            tasks.forEach { (task) in
                
                task.cancel()
            }
        }
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
        
        Moya.Session.default.session.getAllTasks { (tasks) in
            
            tasks.forEach { (task) in
                
                if (task.originalRequest?.url?.absoluteString == (domain + path)) {
                    task.cancel()
                }
            }
        }
    }
}

extension WYNetworkManager {
    
    /// 网络连接模式与用户操作选项
    private enum NetworkStatus {
        
        /// 未知网络，可能是不安全的连接
        case unknown
        /// 无网络连接
        case notReachable
        /// wifi网络
        case reachableWifi
        /// 蜂窝移动网络
        case reachableCellular
        
        /// 用户未选择
        case userNotSelectedConnect
        /// 用户设置取消连接
        case userCancelConnect
        /// 用户设置继续连接
        case userContinueConnect
    }
    
    private static var networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
    
    private static func request(method: HTTPMethod, path: String, data: Data?, config: WYNetworkConfig = .default, parameter: [String : Any], files: [WYFileModel], assetName: String = "", handler:((_ result: WYHandler) -> Void)?) {
        
        checkNetworkStatus { (statusInfo) in
            
            if (statusInfo.0 == .userCancelConnect) {
                
                handlerFailure(error: WYError(code: config.networkServerFailCode, describe: statusInfo.1), debugModeLog: config.debugModeLog, handler: handler)
                
            }else {
                
                let request = WYRequest(method: method, path: path, data: data, parameter: parameter, files: files, assetName: assetName, config: config)
                
                let target = WYTarget(request: request)
                
                self.request(target: target, config: config, handler: handler)
            }
        }
    }
    
    private static func request(target: WYTarget, config: WYNetworkConfig, handler:((_ result: WYHandler) -> Void)?) {
        
        if config.requestCache != nil {
            
            if config.requestCache!.cacheKey.count > 0 {
                
                let storageData = WYStorage.takeOut(forKey: config.requestCache!.cacheKey, path: config.requestCache!.cachePath.path)
                
                if (storageData.error == nil) && (handler != nil) && (storageData.userData != nil)  {
                    
                    if (config.originObject == true) {
                        handler!(.success(WYSuccess(origin: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
                    }else {
                        handler!(.success(WYSuccess(parse: String(data: storageData.userData!, encoding: .utf8) ?? "", storage: storageData, isCache: true)))
                    }
                }
                
            }else {
                wy_networkPrint("由于传入的用于缓存的唯一标识 cacheKey 为空，本次请求不会被缓存")
            }
        }
        
        WYTargetProvider.request(target, callbackQueue: config.callbackQueue) { (progressResponse) in
            
            if handler != nil {
                
                handler!(.progress(WYProgress(progress: progressResponse.progress, completedUnit: progressResponse.progressObject?.completedUnitCount ?? 0, totalUnit: progressResponse.progressObject?.totalUnitCount ?? 0, description: progressResponse.progressObject?.description ?? "")))
            }
            
        } completion: { (result) in
            
            switch result {
                
            case .success(let response):
                
                if config.taskMethod == .download {
                    
                    let format: String = ((response.response?.mimeType ?? "").components(separatedBy: "/").count > 1) ? ((response.response?.mimeType ?? "").components(separatedBy: "/").last ?? "") : ""
                    let saveName: String = (target.request.assetName.isEmpty ? (response.response?.suggestedFilename ?? "") : target.request.assetName) + "." + format
                    
                    let saveUrl: URL = config.downloadSavePath.appendingPathComponent(saveName)
                    showDebugModeLog(target: target, response: response, saveUrl: saveUrl)
                    
                    var downloadModel = WYDownloadModel()
                    downloadModel.assetPath = saveUrl.path
                    downloadModel.diskPath = config.downloadSavePath.path
                    downloadModel.assetName = (target.request.assetName.isEmpty ? (response.response?.suggestedFilename ?? "") : target.request.assetName)
                    downloadModel.mimeType = format
                    
                    let codable: WYCodable = WYCodable()
                    let jsonString = try? codable.encode(String.self, from: downloadModel)
                    handlerSuccess(response: WYSuccess(origin: jsonString ?? ""), handler: handler)
                }else {
                    
                    let statusCode = response.statusCode
                    
                    if statusCode != 200 {
                        
                        showDebugModeLog(target: target, response: response)
                        
                        handlerFailure(error: WYError(code: String(statusCode), describe: WYLocalized("状态码异常", table: WYBasisKitConfig.kitLocalizableTable)), isStatusCodeError: true, debugModeLog: config.debugModeLog, handler: handler)
                        
                    }else {
                        
                        var storage: WYStorageData? = nil
                        
                        if config.originObject {
                            
                            if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) {
                                
                                storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: response.data, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
                            }
                            
                            showDebugModeLog(target: target, response: response)
                            
                            handlerSuccess(response: WYSuccess(origin: String(data: response.data, encoding: .utf8) ?? "", storage: storage), handler: handler)
                            
                        }else {
                            do {
                                let codable: WYCodable = WYCodable()
                                if config.mapper.isEmpty == false {
                                    var mappingKeys: [[String]: String] = [[String]: String]()
                                    if let mapperMessage: String = config.mapper[WYMappingKey.message] {
                                        mappingKeys[[mapperMessage]] = "message"
                                    }
                                    
                                    if let mapperCode: String = config.mapper[WYMappingKey.code] {
                                        mappingKeys[[mapperCode]] = "code"
                                    }
                                    
                                    if let mapperData: String = config.mapper[WYMappingKey.data] {
                                        mappingKeys[[mapperData]] = "data"
                                    }
                                    
                                    if mappingKeys.isEmpty == false {
                                        codable.mappingKeys = .mapper(mappingKeys)
                                    }
                                }
                                
                                let responseData = try codable.decode(WYResponse.self, from: response.data)
                                
                                if responseData.code == config.serverRequestSuccessCode {
                                    
                                    if (config.requestCache != nil) && (config.requestCache!.cacheKey.count > 0) && (responseData.data.isEmpty == false) {
                                        
                                        if let storageData: Data = responseData.data.data(using: .utf8) {
                                            
                                            storage = WYStorage.storage(forKey: config.requestCache!.cacheKey, data: storageData, durable: config.requestCache!.storageDurable, path: (config.requestCache?.cachePath)!)
                                        }
                                    }
                                    
                                    showDebugModeLog(target: target, response: response)
                                    
                                    handlerSuccess(response: WYSuccess(parse: responseData.data, storage: storage), handler: handler)
                                    
                                }else {
                                    
                                    showDebugModeLog(target: target, response: response)
                                    
                                    handlerFailure(error: WYError(code: responseData.code, describe: (responseData.message.isEmpty ? WYLocalized("响应数据Code校验失败", table: WYBasisKitConfig.kitLocalizableTable) : responseData.message)), debugModeLog: config.debugModeLog, handler: handler)
                                }
                                
                            } catch  {
                                
                                showDebugModeLog(target: target, response: response)
                                
                                handlerFailure(error: WYError(code: config.unpackServerFailCode, describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                            }
                        }
                        guard let storageError = storage?.error else { return  }
                        wy_networkPrint("数据缓存到本地失败：\(storageError)")
                    }
                }
                break
                
            case .failure(let error):
                
                showDebugModeLog(target: target, response: Response(statusCode: error.errorCode, data: error.localizedDescription.data(using: .utf8) ?? Data()))
                
                handlerFailure(error: WYError(code: String(error.errorCode), describe: error.localizedDescription), debugModeLog: config.debugModeLog, handler: handler)
                
                break
            }
        }
    }
    
    private static func handlerSuccess(response: WYSuccess, handler:((_ success: WYHandler) -> Void)? = .none) {
        
        DispatchQueue.main.async {
            
            if (handler != nil) {
                handler!(.success(response))
            }
        }
    }
    
    private static func handlerFailure(error: WYError, isStatusCodeError: Bool = false, debugModeLog: Bool, function: String = #function, line: Int = #line, handler:((_ error: WYHandler) -> Void)? = .none) {
        
        DispatchQueue.main.async {
            
            if (handler != nil) {
                
                handler!(.error(error))
            }
            
            guard debugModeLog == true else { return }
            
            if isStatusCodeError {
                wy_networkPrint("statusCode: \(error.code)\n statusError:  \(error)", function: function, line: line)
            }else {
                wy_networkPrint("serverCode: \(error.code)\n serverError:  \(error)", function: function, line: line)
            }
        }
    }
    
    private static func showDebugModeLog(target: WYTarget, response: Response, saveUrl: URL? = nil, function: String = #function, line: Int = #line) {
        
        let config = MoyaProvider<WYTarget>.config
        
        guard config.debugModeLog == true else { return }
        
        switch target.request.config.taskMethod {
        case .data:
            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n dataString: \((target.request.data == nil ? "" : (String(data: target.request.data!, encoding: .utf8))) ?? "")\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
            
        case .download:
            wy_networkPrint("下载地址: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 资源保存路径: \(saveUrl?.absoluteString ?? "")", function: function, line: line)
            
        default:
            wy_networkPrint("接口: \(target.baseURL)\(target.path)\n 请求头: \(target.headers ?? [:])\n 参数: \(target.request.parameter))\n 返回数据: \(String(describing: try? response.mapJSON()))", function: function, line: line)
        }
    }
    
    private static func checkNetworkStatus(handler: ((_ status: (NetworkStatus, String)) -> Void)? = .none) {
        
        networkStatus(showStatusAlert: false, openSeting: true, statusHandler: { (status) in
            
            DispatchQueue.main.async {
                
                if ((status == .unknown) || (status == .notReachable)) {
                    
                    if (networkSecurityInfo.0 == .userNotSelectedConnect) {
                        
                        networkStatus(showStatusAlert: true, openSeting: true, actionHandler: { (actionStr, networkStatus) in
                            
                            DispatchQueue.main.async {
                                
                                if (actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((.userContinueConnect, ""))
                                    }
                                    
                                }else if ((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) || (actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable))) {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((networkSecurityInfo.0, networkSecurityInfo.1))
                                    }
                                    
                                }else {
                                    
                                    if (handler != nil) {
                                        
                                        handler!((.userNotSelectedConnect, ""))
                                    }
                                }
                            }
                        })
                        
                    }else {
                        
                        if (handler != nil) {
                            
                            handler!((networkSecurityInfo.0, networkSecurityInfo.1))
                        }
                    }
                    
                }else {
                    
                    networkStatus(showStatusAlert: false, openSeting: true, statusHandler: { (_) in
                        
                        DispatchQueue.main.async {
                            
                            if (handler != nil) {
                                
                                handler!((.userNotSelectedConnect, ""))
                            }
                        }
                    })
                }
            }
        })
    }
    
    private static func networkStatus(showStatusAlert: Bool, openSeting: Bool, statusHandler:((_ status: NetworkStatus) -> Void)? = nil, actionHandler:((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
        
        WYNetworkStatus.listening("WYNetworkManager") { nwpath in
            
            var message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
            var networkStatus = NetworkStatus.unknown
            var actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized(WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
            switch nwpath.status {
            case .requiresConnection:
                message = WYLocalized("未知的网络，可能存在安全隐患，是否继续？", table: WYBasisKitConfig.kitLocalizableTable)
                networkStatus = .unknown
                actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)]
                break
            case .unsatisfied:
                message = WYLocalized("不可用的网络，请确认您的网络环境或网络连接权限已正确设置", table: WYBasisKitConfig.kitLocalizableTable)
                networkStatus = .notReachable
                actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                break
            case .satisfied:
                
                if nwpath.usesInterfaceType(.wifi) {
                    message = WYLocalized("您正在使用Wifi联网", table: WYBasisKitConfig.kitLocalizableTable)
                    networkStatus = .reachableWifi
                    actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                }
                
                if nwpath.usesInterfaceType(.cellular) {
                    message = WYLocalized("您正在使用蜂窝移动网络联网", table: WYBasisKitConfig.kitLocalizableTable)
                    networkStatus = .reachableCellular
                    actions = openSeting ? [WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)] : [WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)]
                }
                break
            @unknown default: break
            }
            
            if (statusHandler != nil) {
                
                statusHandler!(networkStatus)
            }
            
            showNetworkStatusAlert(showStatusAlert: showStatusAlert, status: networkStatus, message: message, actions: actions, actionHandler: actionHandler)
        }
    }
    
    private static func showNetworkStatusAlert(showStatusAlert: Bool, status: NetworkStatus, message: String, actions: [String], actionHandler: ((_ action: String, _ status: NetworkStatus) -> Void)? = nil) {
        
        if (showStatusAlert == false) {
            
            networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
            return
        }
        
        UIAlertController.wy_show(message: message, actions: actions) { (actionStr, _) in
            
            DispatchQueue.main.async(execute: {
                
                if (actionHandler != nil) {
                    
                    actionHandler!(actionStr, status)
                }
                
                if actionStr == WYLocalized("去设置", table: WYBasisKitConfig.kitLocalizableTable) {
                    
                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
                    
                    let settingUrl = URL(string: UIApplication.openSettingsURLString)
                    if let url = settingUrl, UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(settingUrl!, options: [:], completionHandler: nil)
                    }
                }else if ((actionStr == WYLocalized("继续连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) {
                    
                    networkSecurityInfo = (NetworkStatus.userContinueConnect, "")
                    
                }else if (((actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .unknown)) || ((actionStr == WYLocalized("知道了", table: WYBasisKitConfig.kitLocalizableTable)) && (status == .notReachable))) {
                    
                    let errorStr = (actionStr == WYLocalized("取消连接", table: WYBasisKitConfig.kitLocalizableTable)) ? WYLocalized("已取消不安全网络连接", table: WYBasisKitConfig.kitLocalizableTable) : WYLocalized("无网络连接，请检查您的网络设置", table: WYBasisKitConfig.kitLocalizableTable)
                    networkSecurityInfo = (NetworkStatus.userCancelConnect, errorStr)
                    
                    cancelAllRequest()
                    
                }else {
                    networkSecurityInfo = (NetworkStatus.userNotSelectedConnect, "")
                }
            })
        }
    }
    
    /// DEBUG打印日志
    public static func wy_networkPrint(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let time = timeFormatter.string(from: Date())
        let message = messages.compactMap { "\($0)" }.joined(separator: " ")
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("\n\(time) ——> \(fileName) ——> \(function) ——> line:\(line)\n\n \(message)\n\n\n")
#endif
    }
}
