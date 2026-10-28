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
        components.scheme = scheme == "http" ? config.scheme + "-http" : config.scheme
        return components.url ?? url
    }

    /// 用播放地址构造一个带缓存拦截的 AVURLAsset(内部换好缓存协议头并挂上数据请求转发层)
    public func asset(with url: URL) -> AVURLAsset {
        let asset = AVURLAsset(url: cacheURL(for: url))
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

}
