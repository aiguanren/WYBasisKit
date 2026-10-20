//
//  WYMediaCacheObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import AVFoundation
import Foundation
import WYBasisKitSwift

/// 已缓存的一段数据区间(左闭右开，end 减 start 为这段的字节数)
@objc(WYMediaCacheRange)
@objcMembers public class WYMediaCacheRangeObjC: NSObject {

    /// 区间起点的字节偏移(包含在内)
    public let start: Int64

    /// 区间终点的字节偏移(不包含在内)
    public let end: Int64

    public init(start: Int64, end: Int64) {
        self.start = start
        self.end = end
        super.init()
    }

    // 转换WYMediaCacheRange为WYMediaCacheRangeObjC(内部使用)
    static func objc(from range: WYMediaCacheRange) -> WYMediaCacheRangeObjC {
        return WYMediaCacheRangeObjC(start: range.start, end: range.end)
    }
}

/// 缓存状态查询结果
@objc(WYMediaCacheStatus)
@objcMembers public class WYMediaCacheStatusObjC: NSObject {

    /// 媒体文件总大小，单位为字节(还没从服务器取到文件信息时为 0)
    public let contentLength: Int64

    /// 已缓存到本地的字节数
    public let cachedBytes: Int64

    /// 是否已完整缓存整个视频
    public let isFullyCached: Bool

    /// 已缓存的数据区间列表(相邻区间已合并，按起点升序排列)
    public let cachedRanges: [WYMediaCacheRangeObjC]

    public init(contentLength: Int64, cachedBytes: Int64, isFullyCached: Bool, cachedRanges: [WYMediaCacheRangeObjC]) {
        self.contentLength = contentLength
        self.cachedBytes = cachedBytes
        self.isFullyCached = isFullyCached
        self.cachedRanges = cachedRanges
        super.init()
    }

    // 转换WYMediaCacheStatus为WYMediaCacheStatusObjC(内部使用)
    static func objc(from status: WYMediaCacheStatus) -> WYMediaCacheStatusObjC {
        return WYMediaCacheStatusObjC(contentLength: status.contentLength,
                                      cachedBytes: status.cachedBytes,
                                      isFullyCached: status.isFullyCached,
                                      cachedRanges: status.cachedRanges.map { WYMediaCacheRangeObjC.objc(from: $0) })
    }
}

/// 视频边下边播的全局缓存配置(修改后对之后新发起的数据请求与下载任务生效，已在下载中的分块沿用旧值，属性转调全局同一份配置实例)
@objc(WYMediaCacheConfig)
@objcMembers public class WYMediaCacheConfigObjC: NSObject {

    /// 全局默认配置(WYMediaCache 用的就是这份实例，直接改它的属性即可全局生效)
    public static let shared = WYMediaCacheConfigObjC()

    override private init() {
        super.init()
    }

    /// 拦截播放地址使用的自定义URL协议头(播放地址经 WYMediaCache 的 cacheURLForURL 换成这个协议头后，数据请求才会经过缓存层，不要填 http/https 等系统会自己处理的协议头)
    public var scheme: String {
        get { return WYMediaCache.shared.config.scheme }
        set { WYMediaCache.shared.config.scheme = newValue }
    }

    /// 缓存总容量上限，单位为字节(超过后按最久未使用的顺序淘汰闲置条目，0 表示不限制容量)
    public var maxCacheSize: Int64 {
        get { return WYMediaCache.shared.config.maxCacheSize }
        set { WYMediaCache.shared.config.maxCacheSize = newValue }
    }

    /// 单个下载任务一次请求的数据量，单位为字节(按块请求、按块落盘，播放到未缓存区域时一次取回一整块)
    public var downloadChunkSize: Int {
        get { return WYMediaCache.shared.config.downloadChunkSize }
        set { WYMediaCache.shared.config.downloadChunkSize = newValue }
    }

    /// 同一个视频同时进行的下载任务数上限(播放器在不同位置的取数请求各占一个任务，1 表示只顺着一条缺口顺序下载)
    public var maxConcurrentDownloadCount: Int {
        get { return WYMediaCache.shared.config.maxConcurrentDownloadCount }
        set { WYMediaCache.shared.config.maxConcurrentDownloadCount = newValue }
    }

    /// 单个下载任务的请求超时秒数
    public var downloadTimeout: TimeInterval {
        get { return WYMediaCache.shared.config.downloadTimeout }
        set { WYMediaCache.shared.config.downloadTimeout = newValue }
    }

    /// 全部视频同时进行的下载任务总数上限(播放与预下载共用这条限制，0 表示不限制总数，只受单视频上限约束)
    public var maxTotalDownloadTaskCount: Int {
        get { return WYMediaCache.shared.config.maxTotalDownloadTaskCount }
        set { WYMediaCache.shared.config.maxTotalDownloadTaskCount = newValue }
    }

    /// 元数据落盘节流秒数(缓存区间变化后最短隔这么多秒才写一次磁盘，0 表示每次变化立即落盘)
    public var metaDataSaveInterval: TimeInterval {
        get { return WYMediaCache.shared.config.metaDataSaveInterval }
        set { WYMediaCache.shared.config.metaDataSaveInterval = newValue }
    }

    /// 预下载进度回调节流秒数(最短隔这么多秒回调一次进度，0 表示每收到一段数据都回调)
    public var progressNotifyInterval: TimeInterval {
        get { return WYMediaCache.shared.config.progressNotifyInterval }
        set { WYMediaCache.shared.config.progressNotifyInterval = newValue }
    }

    /// 单次喂给播放器的数据量上限，单位为字节(防止超长请求一次性整段读进内存，一般不需要改)
    public var maxRespondLength: Int64 {
        get { return WYMediaCache.shared.config.maxRespondLength }
        set { WYMediaCache.shared.config.maxRespondLength = newValue }
    }

    /// 缓存根目录(默认为沙盒 Caches/WYBasisKit/MediaCache，传入自定义目录时需保证该目录可写，改动只对之后新建的缓存条目生效)
    public var cacheDirectory: URL {
        get { return WYMediaCache.shared.config.cacheDirectory }
        set { WYMediaCache.shared.config.cacheDirectory = newValue }
    }

    /// 蜂窝网络下遇到不小于该大小的视频先弹窗征询用户，单位为字节(0 表示不弹窗，同一视频在一次进入前台到下次进后台之间只征询一次)
    public var cellularConfirmSizeLimit: Int64 {
        get { return WYMediaCache.shared.config.cellularConfirmSizeLimit }
        set { WYMediaCache.shared.config.cellularConfirmSizeLimit = newValue }
    }

    /// 蜂窝确认弹窗标题
    public var cellularConfirmTitle: String {
        get { return WYMediaCache.shared.config.cellularConfirmTitle }
        set { WYMediaCache.shared.config.cellularConfirmTitle = newValue }
    }

    /// 蜂窝确认弹窗内容(格式化时以 %.1fMB 填入视频总大小，改文案时保留这个占位符)
    public var cellularConfirmMessage: String {
        get { return WYMediaCache.shared.config.cellularConfirmMessage }
        set { WYMediaCache.shared.config.cellularConfirmMessage = newValue }
    }

    /// 蜂窝确认弹窗继续按钮文案
    public var cellularConfirmContinueTitle: String {
        get { return WYMediaCache.shared.config.cellularConfirmContinueTitle }
        set { WYMediaCache.shared.config.cellularConfirmContinueTitle = newValue }
    }

    /// 蜂窝确认弹窗取消按钮文案
    public var cellularConfirmCancelTitle: String {
        get { return WYMediaCache.shared.config.cellularConfirmCancelTitle }
        set { WYMediaCache.shared.config.cellularConfirmCancelTitle = newValue }
    }
}

@objc public extension WYMediaCache {

    /// 全局单例
    @objc(shared)
    public static var sharedObjC: WYMediaCache {
        return WYMediaCache.shared
    }

    /// 当前是否联网(断网时播放数据请求会挂起等待，恢复联网后自动续起)
    @objc(isNetworkOnline)
    public var isNetworkOnlineObjC: Bool {
        return isNetworkOnline
    }

    /// 当前是否蜂窝网络(蜂窝或手机热点这类计费网络)
    @objc(isNetworkCellular)
    public var isNetworkCellularObjC: Bool {
        return isNetworkCellular
    }

    /**
     *  把播放地址换成本地缓存协议头的地址
     *
     *  @param url         原始播放地址，非 http/https 链接原样返回
     *
     *  @return 换成缓存协议头后的地址，交给 AVURLAsset 使用后数据请求才会经过缓存层
     *
     */
    @objc(cacheURLForURL:)
    public func cacheURLObjC(for url: URL) -> URL {
        return cacheURL(for: url)
    }

    /// 用播放地址构造一个带缓存拦截的 AVURLAsset(内部换好缓存协议头并挂上数据请求转发层)
    @objc(assetWithURL:)
    public func assetObjC(with url: URL) -> AVURLAsset {
        return asset(with: url)
    }

    /// 用播放地址构造一个可直接播放的 AVPlayerItem(内部走 asset(with:)，播放时边下边缓存)
    @objc(playerItemWithURL:)
    public func playerItemObjC(with url: URL) -> AVPlayerItem {
        return playerItem(with: url)
    }

    /**
     *  查询播放地址当前的缓存状态
     *
     *  @param url         原始播放地址
     *
     *  @return 缓存状态，从未缓存过时各项为 0 与空列表
     *
     */
    @objc(cacheStatusForURL:)
    public func cacheStatusObjC(for url: URL) -> WYMediaCacheStatusObjC {
        return WYMediaCacheStatusObjC.objc(from: cacheStatus(for: url))
    }

    /**
     *  播放地址是否已完整缓存
     *
     *  @param url         原始播放地址
     *
     *  @return true 表示整个视频已缓存完整，离线可播
     *
     */
    @objc(isFullyCached:)
    public func isFullyCachedObjC(_ url: URL) -> Bool {
        return isFullyCached(url)
    }

    /**
     *  取播放地址的本地缓存文件路径
     *
     *  @param url         原始播放地址
     *
     *  @return 已完整缓存时返回缓存文件路径(可用 AVPlayer 直接播放本地文件)，否则返回 nil
     *
     */
    @objc(cachedFilePathForURL:)
    public func cachedFilePathObjC(for url: URL) -> String? {
        return cachedFilePath(for: url)
    }

    /// 缓存目录当前占用的总大小，单位为字节
    @objc(totalCacheSize)
    public func totalCacheSizeObjC() -> Int64 {
        return totalCacheSize()
    }

    /**
     *  删除播放地址对应的缓存
     *
     *  @param url         原始播放地址，条目正在播放或下载中时先标记，闲置后自动清理
     *
     */
    @objc(removeCacheForURL:)
    public func removeCacheObjC(for url: URL) {
        removeCache(for: url)
    }

    /// 清空全部缓存(正在播放或下载中的条目不受影响，其余全部删除)
    @objc(clearCache)
    public func clearCacheObjC() {
        clearCache()
    }

    /**
     *  预下载整个视频到本地缓存
     *
     *  @param url            原始播放地址
     *  @param progress       进度回调，参数依次为已缓存字节数与媒体总字节数，主线程回调
     *  @param completion     结束回调，error 为 nil 表示整个视频已缓存完整，主线程回调
     *
     */
    @objc(downloadWithURL:progress:completion:)
    public func downloadObjC(with url: URL, progress: ((_ cachedBytes: Int64, _ contentLength: Int64) -> Void)?, completion: ((_ error: Error?) -> Void)?) {
        download(url: url, progress: progress, completion: completion)
    }

    /**
     *  取消预下载
     *
     *  @param url         原始播放地址，只取消没有播放请求在等的下载任务，进度与结束回调不再收到通知
     *
     */
    @objc(cancelDownloadWithURL:)
    public func cancelDownloadObjC(with url: URL) {
        cancelDownload(url: url)
    }
}
#endif
