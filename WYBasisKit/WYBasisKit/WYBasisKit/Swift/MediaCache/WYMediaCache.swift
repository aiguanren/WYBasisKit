//
//  WYMediaCache.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation
import Network
import UIKit

/// 缓存过程的报错(播放场景的报错只中断当次数据请求，播放器重新请求数据时会再次尝试，预下载场景的报错经回调抛出)
public enum WYMediaCacheError: Error, LocalizedError {

    /// 播放地址不是 http/https 链接，没法经缓存层取数
    case unsupportedScheme

    /// 服务器不支持从指定位置取数据(没有按 Range 请求返回 206)
    case rangeUnsupported

    /// 服务器没有返回媒体文件总大小，没法建立缓存索引
    case contentLengthUnknown

    /// 网络请求失败，附带失败原因
    case network(String)

    /// 本地缓存文件读写失败，附带失败原因
    case fileIO(String)

    /// 蜂窝流量确认弹窗里用户选择了取消，本次播放或预下载已停止
    case cellularDenied

    /// 报错说明
    public var errorDescription: String? {
        switch self {
        case .unsupportedScheme:
            return "播放地址不是 http/https 链接，没法经缓存层取数"
        case .rangeUnsupported:
            return "服务器不支持从指定位置取数据"
        case .contentLengthUnknown:
            return "服务器没有返回媒体文件总大小，没法建立缓存索引"
        case .network(let message):
            return "网络请求失败，\(message)"
        case .fileIO(let message):
            return "本地缓存文件读写失败，\(message)"
        case .cellularDenied:
            return "用户选择了不使用蜂窝流量，本次播放或预下载已停止"
        }
    }
}

/// 已缓存的一段数据区间(左闭右开，end 减 start 为这段的字节数)
public struct WYMediaCacheRange {

    /// 区间起点的字节偏移(包含在内)
    public let start: Int64

    /// 区间终点的字节偏移(不包含在内)
    public let end: Int64
}

/// 缓存状态查询结果
public struct WYMediaCacheStatus {

    /// 媒体文件总大小，单位为字节(还没从服务器取到文件信息时为 0)
    public let contentLength: Int64

    /// 已缓存到本地的字节数
    public let cachedBytes: Int64

    /// 是否已完整缓存整个视频
    public let isFullyCached: Bool

    /// 已缓存的数据区间列表(相邻区间已合并，按起点升序排列)
    public let cachedRanges: [WYMediaCacheRange]
}

/// 视频边下边播的缓存管理器(把播放地址换成自定义协议头后交给播放器，本地已缓存的数据直接读盘喂给播放器，没缓存的部分向服务器发分块 Range 请求边下边喂)
public class WYMediaCache: NSObject {

    /// 全局单例
    public static let shared = WYMediaCache()

    /// 全局缓存配置(各配置项什么时候生效见 WYMediaCacheConfig 的属性注释)
    public var config: WYMediaCacheConfig = .shared

    /// 当前是否联网(断网时播放数据请求会挂起等待，恢复联网后自动续起)
    public var isNetworkOnline: Bool {
        return perform { self.isOnlineMirror }
    }

    /// 当前是否蜂窝网络(蜂窝或手机热点这类计费网络)
    public var isNetworkCellular: Bool {
        return perform { self.isCellularMirror }
    }

    /// 内部状态串行队列(条目、任务、容量整理都在这条队列上动，也兼作播放器数据请求的回调队列)
    let queue: DispatchQueue

    /// 播放器数据请求转发层
    let resourceLoader: WYMediaCacheResourceLoader

    /// 条目键名到缓存条目的映射
    var items: [String: WYMediaCacheItem] = [:]

    /// 缓存目录当前占用的总字节数(按媒体数据文件的实际大小统计)
    var totalSize: Int64 = 0

    /// 网络任务到下载任务的回调路由
    var sessionTasks: [URLSessionDataTask: WYMediaCacheDownloadTask] = [:]

    /// 分块下载用的网络会话
    var session: URLSession!

    /// 内部队列上镜像的网络在线状态(经 WYNetworkMonitor 别名监听更新)
    var isOnlineMirror = true

    /// 内部队列上镜像的蜂窝状态
    var isCellularMirror = false

    /// 内部队列上镜像的后台状态(进后台置 true 期间不创建新下载任务，回前台复位后续起)
    var isBackgrounded = false

    /// 待蜂窝确认的条目键名队列(同一时刻只弹一个弹窗)
    var cellularConfirmItems: [String] = []

    /// 是否正在展示蜂窝确认弹窗
    var isShowingCellularConfirm = false

    /// 标记是否正运行在内部串行队列上(公开方法在队列内外分别直接执行与同步等待，防止重入死锁)
    static let queueKey = DispatchSpecificKey<Bool>()

    override init() {
        let queue = DispatchQueue(label: "com.wybasiskit.mediacache")
        queue.setSpecific(key: WYMediaCache.queueKey, value: true)
        self.queue = queue
        let resourceLoader = WYMediaCacheResourceLoader()
        self.resourceLoader = resourceLoader
        super.init()
        resourceLoader.cache = self
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
        isOnlineMirror = WYNetworkMonitor.isReachable
        isCellularMirror = WYNetworkMonitor.isExpensive
        WYNetworkMonitor.listening("WYMediaCache", queue: queue) { [weak self] (path) in
            guard let self = self else { return }
            let isOnline = path.status == .satisfied
            let isCellular = isOnline && path.isExpensive
            if isOnline != self.isOnlineMirror || isCellular != self.isCellularMirror {
                self.isOnlineMirror = isOnline
                self.isCellularMirror = isCellular
                if isOnline {
                    self.resumeAllItems()
                }
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        scanDiskCache()
        evictIfNeeded(excluding: "")
    }

    /**
     *  把播放地址换成本地缓存协议头的地址
     *
     *  @param url         原始播放地址，非 http/https 链接原样返回
     *
     *  @return 换成缓存协议头后的地址，交给 AVURLAsset 使用后数据请求才会经过缓存层
     *
     */
    public func cacheURL(for url: URL) -> URL {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return url }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        components.scheme = config.scheme
        return components.url ?? url
    }

    /// 用播放地址构造一个带缓存拦截的 AVURLAsset(内部换好缓存协议头并挂上数据请求转发层)
    public func asset(with url: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: cacheURL(for: url))
        // V9临时挂主队列
        asset.resourceLoader.setDelegate(resourceLoader, queue: .main)
        return asset
    }

    /// 用播放地址构造一个可直接播放的 AVPlayerItem(内部走 asset(with:)，播放时边下边缓存)
    public func playerItem(with url: URL) -> AVPlayerItem {
        return AVPlayerItem(asset: asset(with: url))
    }

    /**
     *  查询播放地址当前的缓存状态
     *
     *  @param url         原始播放地址
     *
     *  @return 缓存状态，从未缓存过时各项为 0 与空列表
     *
     */
    public func cacheStatus(for url: URL) -> WYMediaCacheStatus {
        return perform {
            let item = self.item(for: url)
            item.touch()
            return item.cacheStatus()
        }
    }

    /**
     *  播放地址是否已完整缓存
     *
     *  @param url         原始播放地址
     *
     *  @return true 表示整个视频已缓存完整，离线可播
     *
     */
    public func isFullyCached(_ url: URL) -> Bool {
        return perform {
            return self.item(for: url).isFullyCached
        }
    }

    /**
     *  取播放地址的本地缓存文件路径
     *
     *  @param url         原始播放地址
     *
     *  @return 已完整缓存时返回缓存文件路径(可用 AVPlayer 直接播放本地文件)，否则返回 nil
     *
     */
    public func cachedFilePath(for url: URL) -> String? {
        return perform {
            let item = self.item(for: url)
            return item.isFullyCached ? item.mediaURL.path : nil
        }
    }

    /// 缓存目录当前占用的总大小，单位为字节
    public func totalCacheSize() -> Int64 {
        return perform {
            return self.totalSize
        }
    }

    /**
     *  删除播放地址对应的缓存
     *
     *  @param url         原始播放地址，条目正在播放或下载中时先标记，闲置后自动清理
     *
     */
    public func removeCache(for url: URL) {
        perform {
            let item = self.item(for: url)
            self.removeItem(item)
        }
    }

    /// 清空全部缓存(正在播放或下载中的条目不受影响，其余全部删除)
    public func clearCache() {
        perform {
            for item in self.items.values {
                self.removeItem(item)
            }
        }
    }

    /**
     *  预下载整个视频到本地缓存
     *
     *  @param url            原始播放地址
     *  @param progress       进度回调，参数依次为已缓存字节数与媒体总字节数，主线程回调
     *  @param completion     结束回调，error 为 nil 表示整个视频已缓存完整，主线程回调
     *
     */
    public func download(url: URL, progress: ((_ cachedBytes: Int64, _ contentLength: Int64) -> Void)?, completion: ((_ error: Error?) -> Void)?) {
        guard checkScheme(url, completion: completion) else { return }
        perform {
            let item = self.item(for: url)
            item.startFullDownload(progress: progress, completion: completion)
        }
    }

    /**
     *  取消预下载
     *
     *  @param url         原始播放地址，只取消没有播放请求在等的下载任务，进度与结束回调不再收到通知
     *
     */
    public func cancelDownload(url: URL) {
        perform {
            self.item(for: url).cancelFullDownload()
        }
    }

    /// 把缓存协议头地址还原成原始播放地址(只认配置里的协议头，还原固定按 https 协议头拼回)
    func originalURL(fromCacheURL url: URL) -> URL? {
        guard let scheme = url.scheme, scheme.lowercased() == config.scheme.lowercased() else { return nil }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = "https"
        return components.url
    }

    /// 登记播放器数据请求到对应条目(在内部队列上调用)
    func addItem(_ loadingRequest: AVAssetResourceLoadingRequest, for url: URL) {
        item(for: url).add(loadingRequest)
    }

    /// 移除播放器数据请求(在内部队列上调用)
    func cancelItemRequest(_ loadingRequest: AVAssetResourceLoadingRequest, for url: URL) {
        item(for: url).cancel(loadingRequest)
    }

    /// 取条目，磁盘上没有时新建空条目
    func item(for url: URL) -> WYMediaCacheItem {
        let key = WYMediaCacheItem.cacheKey(for: url)
        if let item = items[key] {
            return item
        }
        let item = WYMediaCacheItem(cache: self, url: url)
        items[key] = item
        return item
    }

    /// 是否还允许再启动下载任务(全部条目的在途任务总数没超上限，或上限为 0 不限制)
    func canStartMoreDownloadTasks() -> Bool {
        let limit = config.maxTotalDownloadTaskCount
        guard limit > 0 else { return true }
        let totalCount = items.values.reduce(0) { $0 + $1.downloadTasks.count }
        return totalCount < limit
    }

    /// 创建下载任务对应的网络请求并启动
    func startSessionTask(_ task: WYMediaCacheDownloadTask) {
        guard let item = task.item else { return }
        var request = URLRequest(url: item.originalURL)
        request.timeoutInterval = config.downloadTimeout
        request.setValue("bytes=\(task.startOffset)-\(task.chunkEnd - 1)", forHTTPHeaderField: "Range")
        let sessionTask = session.dataTask(with: request)
        task.sessionTask = sessionTask
        sessionTasks[sessionTask] = task
        sessionTask.resume()
    }

    /// 取消下载任务对应的网络请求(任务结束时迟到的回调会自动丢弃)
    func cancelSessionTask(_ task: WYMediaCacheDownloadTask) {
        task.isCancelled = true
        task.sessionTask?.cancel()
    }

    /// 删除条目(条目正在被播放或下载占用时不删，改为标记待删除)
    func removeItem(_ item: WYMediaCacheItem) {
        if item.isActive {
            item.markPendingRemoval()
            return
        }
        deleteItem(item)
    }

    /// 真正清理条目(关句柄、删文件、下账容量、移出条目表，残留的在途任务一并取消并清掉回调路由)
    func deleteItem(_ item: WYMediaCacheItem) {
        for task in item.downloadTasks {
            cancelSessionTask(task)
            if let sessionTask = task.sessionTask {
                sessionTasks.removeValue(forKey: sessionTask)
            }
        }
        item.downloadTasks.removeAll()
        try? item.readFileHandle?.close()
        try? item.writeFileHandle?.close()
        item.readFileHandle = nil
        item.writeFileHandle = nil
        try? FileManager.default.removeItem(at: item.mediaURL)
        try? FileManager.default.removeItem(at: item.metaDataURL)
        totalSize -= item.trackedFileSize
        items.removeValue(forKey: item.key)
    }

    /// 进后台处理(取消全部在途下载任务并把全部条目元数据落盘，回前台再统一续起)
    @objc func handleEnterBackground() {
        queue.async {
            self.isBackgrounded = true
            for item in self.items.values {
                for task in item.downloadTasks {
                    self.cancelSessionTask(task)
                }
                item.saveMetaData()
            }
        }
    }

    /// 回前台处理(续起全部条目的播放请求与预下载，蜂窝放行状态按一次前台周期重置)
    @objc func handleEnterForeground() {
        queue.async {
            self.isBackgrounded = false
            for item in self.items.values {
                for task in item.downloadTasks {
                    self.cancelSessionTask(task)
                }
                item.cellularAllowed = false
            }
            self.resumeAllItems()
        }
    }

    /// 续起全部条目(补下载任务并重新喂未满足的播放请求)
    func resumeAllItems() {
        for item in items.values {
            item.processRequests()
        }
    }

    /// 是否需要蜂窝确认(配置了阈值且当前蜂窝在线、视频不小于阈值且本条目未放行过)
    func needsCellularConfirm(contentLength: Int64, item: WYMediaCacheItem) -> Bool {
        let limit = config.cellularConfirmSizeLimit
        guard limit > 0, isCellularMirror, isOnlineMirror, contentLength >= limit, item.cellularAllowed == false else { return false }
        return true
    }

    /// 排队弹蜂窝确认弹窗(同一时刻只弹一个，同一视频只记一次)
    func enqueueCellularConfirm(item: WYMediaCacheItem) {
        if cellularConfirmItems.contains(item.key) == false {
            cellularConfirmItems.append(item.key)
        }
        presentNextCellularConfirmIfNeeded()
    }

    /// 弹下一个待确认条目
    func presentNextCellularConfirmIfNeeded() {
        guard isShowingCellularConfirm == false, let itemKey = cellularConfirmItems.first else { return }
        guard let item = items[itemKey] else {
            cellularConfirmItems.removeFirst()
            presentNextCellularConfirmIfNeeded()
            return
        }
        isShowingCellularConfirm = true
        let megaBytes = Double(item.contentLength) / 1024 / 1024
        let title = config.cellularConfirmTitle
        let message = String(format: config.cellularConfirmMessage, megaBytes)
        let continueTitle = config.cellularConfirmContinueTitle
        let cancelTitle = config.cellularConfirmCancelTitle
        Task { @MainActor [weak self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: continueTitle, style: .default, handler: { (_) in
                self?.finishCellularConfirm(itemKey: itemKey, allowed: true)
            }))
            alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: { (_) in
                self?.finishCellularConfirm(itemKey: itemKey, allowed: false)
            }))
            WYMediaCacheAlertPresenter.present(alertController)
        }
    }

    /// 蜂窝确认弹窗选择落定(放行后重新收敛该条目，取消则停掉等数据的请求与预下载回调)
    func finishCellularConfirm(itemKey: String, allowed: Bool) {
        queue.async {
            self.isShowingCellularConfirm = false
            if let index = self.cellularConfirmItems.firstIndex(of: itemKey) {
                self.cellularConfirmItems.remove(at: index)
            }
            if let item = self.items[itemKey] {
                if allowed {
                    item.cellularAllowed = true
                    item.processRequests()
                }else {
                    item.failUnservedRequests(error: WYMediaCacheError.cellularDenied)
                    item.finishFullDownloads(error: WYMediaCacheError.cellularDenied)
                }
            }
            self.presentNextCellularConfirmIfNeeded()
        }
    }

    /// 容量整理(超出上限时按最近使用时间从旧到新淘汰闲置条目，excludingKey 指定的条目正有新数据落盘不参与淘汰)
    func evictIfNeeded(excluding excludingKey: String) {
        let limit = config.maxCacheSize
        guard limit > 0, totalSize > limit else { return }
        while totalSize > limit {
            guard let victim = items.values.filter({ $0.isActive == false && $0.key != excludingKey }).min(by: { $0.lastAccessDate < $1.lastAccessDate }) else { return }
            deleteItem(victim)
        }
    }

    /// 启动时扫描缓存目录恢复历史条目(元数据读不出来、数据文件丢失的组合直接清掉，孤儿数据文件一并清理)
    func scanDiskCache() {
        let directory = config.cacheDirectory
        guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        let metaDataSuffix = "." + WYMediaCacheItem.metaDataExtension
        var mediaFileNames: Set<String> = []
        for fileName in fileNames where fileName.hasSuffix(metaDataSuffix) {
            let mediaFileName = String(fileName.dropLast(metaDataSuffix.count))
            let metaDataURL = directory.appendingPathComponent(fileName)
            let mediaURL = directory.appendingPathComponent(mediaFileName)
            guard let data = try? Data(contentsOf: metaDataURL),
                  let metaData = try? JSONDecoder().decode(WYMediaCacheMetaData.self, from: data),
                  let originalURL = URL(string: metaData.url) else {
                try? FileManager.default.removeItem(at: metaDataURL)
                try? FileManager.default.removeItem(at: mediaURL)
                continue
            }
            let fileSize = Int64(WYStorage.sandboxFileSize(forPath: mediaURL.path))
            guard fileSize > 0 else {
                try? FileManager.default.removeItem(at: metaDataURL)
                try? FileManager.default.removeItem(at: mediaURL)
                continue
            }
            let item = WYMediaCacheItem(cache: self, url: originalURL)
            item.restore(metaData: metaData, fileSize: fileSize)
            items[item.key] = item
            totalSize += fileSize
            mediaFileNames.insert(mediaFileName)
        }
        // 没有元数据配对的数据文件按残留清理，系统隐藏文件不动
        for fileName in fileNames where fileName.hasSuffix(metaDataSuffix) == false && fileName.hasPrefix(".") == false {
            if mediaFileNames.contains(fileName) == false {
                try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
            }
        }
    }

    /// 公开方法的执行壳，内部队列上直接跑，外部线程同步切进队列跑
    private func perform<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: WYMediaCache.queueKey) == true {
            return work()
        }
        return queue.sync(execute: work)
    }

    /// 校验播放地址协议头，不合法时主线程回调报错
    private func checkScheme(_ url: URL, completion: ((_ error: Error?) -> Void)?) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            if let completion = completion {
                Task { @MainActor in completion(WYMediaCacheError.unsupportedScheme) }
            }
            return false
        }
        return true
    }
}

/// 弹窗展示助手(把弹窗呈到当前前台界面的最上层控制器上，只供缓存模块内部使用)
enum WYMediaCacheAlertPresenter {

    /// 呈现弹窗(没有可用界面时静默丢弃，调用方按用户取消处理)
    static func present(_ alertController: UIAlertController) {
        let sceneWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
        let fallbackWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first }
        guard let window = sceneWindows.first ?? fallbackWindows.first, let rootViewController = window.rootViewController else { return }
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        topViewController.present(alertController, animated: true)
    }
}

extension WYMediaCache: URLSessionDataDelegate, URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let task = sessionTasks[dataTask], let item = task.item else {
            completionHandler(.cancel)
            return
        }
        queue.async { [weak self] in
            guard let self = self, self.sessionTasks[dataTask] === task else { return }
            let disposition = item.handleResponse(task, response: response)
            completionHandler(disposition)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let task = sessionTasks[dataTask], let item = task.item else { return }
        queue.async { [weak self] in
            guard let self = self, self.sessionTasks[dataTask] === task else { return }
            item.handleData(task, data: data)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let dataTask = task as? URLSessionDataTask, let downloadTask = sessionTasks[dataTask], let item = downloadTask.item else { return }
        queue.async { [weak self] in
            guard let self = self else { return }
            self.sessionTasks.removeValue(forKey: dataTask)
            item.handleCompletion(downloadTask, error: error)
        }
    }
}
