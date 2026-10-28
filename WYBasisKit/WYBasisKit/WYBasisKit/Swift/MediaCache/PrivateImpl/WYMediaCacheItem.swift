//
//  WYMediaCacheItem.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import CryptoKit
import Foundation
import UniformTypeIdentifiers

/// 播放地址对应的缓存条目(管理着这个地址的本地数据文件、缓存区间索引、播放器的数据请求与分块下载任务，所有方法只在 WYMediaCache 的串行队列上调用)
final class WYMediaCacheItem {

    /// 缓存元数据文件的扩展名(挂在媒体数据文件名后面)
    static let metaDataExtension = "metadata"

    /// 条目键名(域名加路径加查询参数的 MD5，http 与 https 协议头的同一资源共用一份缓存，用作本地文件名前缀)
    static func cacheKey(for url: URL) -> String {
        let identity: String
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            identity = (components.host ?? "").lowercased() + components.path + (components.query ?? "")
        }else {
            identity = url.absoluteString
        }
        let digest = Insecure.MD5.hash(data: Data(identity.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// 持有本条目的缓存管理器
    let cache: WYMediaCache

    /// 原始播放地址
    let originalURL: URL

    /// 条目键名(键名生成规则见 cacheKey(for:))
    let key: String

    /// 媒体数据落盘地址
    let mediaURL: URL

    /// 元数据落盘地址
    let metaDataURL: URL

    /// 已缓存区间索引
    var index = WYMediaCacheIntervalIndex()

    /// 媒体文件总大小，单位为字节(还没从服务器取到文件信息时为 0)
    var contentLength: Int64 = 0

    /// 服务器返回的媒体类型(如 video/mp4)
    var mimeType: String?

    /// 条目创建时间
    var creationDate = Date()

    /// 最近一次使用时间(播放、查询状态、预下载都会刷新，容量超出时按它从旧到新淘汰)
    var lastAccessDate = Date()

    /// 上一次元数据落盘时间(控制落盘频率)
    var lastMetaSaveDate: Date?

    /// 上一次进度回调时间(控制回调频率)
    var lastProgressNotifyDate: Date?

    /// 播放器发来的待满足数据请求
    var loadingRequests: [AVAssetResourceLoadingRequest] = []

    /// 进行中的分块下载任务
    var downloadTasks: [WYMediaCacheDownloadTask] = []

    /// 预下载整个视频的进度与结果回调列表(同一地址重复预下载会并进同一批)
    var fullDownloadHandlers: [(progress: ((_ cachedBytes: Int64, _ contentLength: Int64) -> Void)?, completion: ((_ error: Error?) -> Void)?)] = []

    /// 是否已标记待删除(正在使用中收到删除指令时先标记，闲置后真正清理)
    var pendingRemoval = false

    /// 蜂窝确认弹窗是否已放行过本条目(一次前台周期内只征询一次)
    var cellularAllowed = false

    /// 媒体数据文件读句柄(懒打开，条目清理时关闭)
    var readFileHandle: FileHandle?

    /// 媒体数据文件写句柄(懒打开，条目清理时关闭)
    var writeFileHandle: FileHandle?

    /// 已计入缓存总容量的媒体文件大小(落盘有空洞时以文件实际大小为准)
    var trackedFileSize: Int64 = 0

    init(cache: WYMediaCache, url: URL) {
        self.cache = cache
        self.originalURL = url
        self.key = Self.cacheKey(for: url)
        // 文件扩展名只保留字母数字，地址里没带可用扩展名时按 mp4 处理
        let ext = url.pathExtension.lowercased().filter { $0.isLetter || $0.isNumber }
        let fileName = key + "." + (ext.isEmpty ? "mp4" : String(ext.prefix(8)))
        self.mediaURL = cache.config.cacheDirectory.appendingPathComponent(fileName)
        self.metaDataURL = mediaURL.appendingPathExtension(Self.metaDataExtension)
    }

    /// 是否已完整缓存整个视频
    var isFullyCached: Bool {
        return contentLength > 0 && index.cachedBytes >= contentLength
    }

    /// 是否有播放请求、下载任务或预下载在占用本条目
    var isActive: Bool {
        return loadingRequests.isEmpty == false || downloadTasks.isEmpty == false || fullDownloadHandlers.isEmpty == false
    }

    /// 当前缓存状态
    func cacheStatus() -> WYMediaCacheStatus {
        return WYMediaCacheStatus(contentLength: contentLength,
                                  cachedBytes: index.cachedBytes,
                                  isFullyCached: isFullyCached,
                                  cachedRanges: index.ranges.map { WYMediaCacheRange(start: $0.lowerBound, end: $0.upperBound) })
    }

    /// 登记播放器的数据请求并尝试满足它(数据不齐时等下载回调再继续)
    func add(_ loadingRequest: AVAssetResourceLoadingRequest) {
        touch()
        loadingRequests.append(loadingRequest)
        processRequests()
    }

    /// 播放器取消了数据请求(播放结束、切资源或资源加载器被释放)
    func cancel(_ loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.removeAll { $0 === loadingRequest }
        processRequests()
    }

    /// 预下载整个视频(已完整缓存时直接回调成功)
    func startFullDownload(progress: ((_ cachedBytes: Int64, _ contentLength: Int64) -> Void)?, completion: ((_ error: Error?) -> Void)?) {
        touch()
        if isFullyCached {
            let cachedBytes = index.cachedBytes
            let length = contentLength
            Task { @MainActor in
                progress?(cachedBytes, length)
                completion?(nil)
            }
            return
        }
        fullDownloadHandlers.append((progress, completion))
        let cachedBytes = index.cachedBytes
        let length = contentLength
        Task { @MainActor in progress?(cachedBytes, length) }
        pumpDownloads()
    }

    /// 取消预下载(还在服务播放请求的下载任务不受影响)
    func cancelFullDownload() {
        fullDownloadHandlers.removeAll()
        for task in downloadTasks {
            if task.isCancelled { continue }
            let servesPlayback = loadingRequests.contains { request in
                guard let dataRequest = request.dataRequest else { return false }
                let offset = Int64(dataRequest.currentOffset)
                return offset >= task.startOffset && offset < task.chunkEnd && index.range(covering: offset) == nil
            }
            if servesPlayback == false {
                cache.cancelSessionTask(task)
            }
        }
    }

    /// 处理下载任务收到的响应头(返回 .allow 继续收数据，返回 .cancel 结束任务，地址不可用或服务器不支持断点续传时同步失败相关请求)
    func handleResponse(_ task: WYMediaCacheDownloadTask, response: URLResponse) -> URLSession.ResponseDisposition {
        guard let httpResponse = response as? HTTPURLResponse else {
            task.isCancelled = true
            failUnservedRequests(error: WYMediaCacheError.network("服务器响应不是 HTTP 数据"))
            finishFullDownloads(error: WYMediaCacheError.network("服务器响应不是 HTTP 数据"))
            return .cancel
        }
        if httpResponse.statusCode == 206 {
            if applyContentInfo(length: totalLength(from: httpResponse), mimeType: httpResponse.mimeType) == false {
                task.isCancelled = true
                failUnservedRequests(error: WYMediaCacheError.contentLengthUnknown)
                finishFullDownloads(error: WYMediaCacheError.contentLengthUnknown)
                return .cancel
            }
            if cache.needsCellularConfirm(contentLength: contentLength, item: self) {
                cache.enqueueCellularConfirm(item: self)
                return .cancel
            }
            return .allow
        }
        if httpResponse.statusCode == 200 {
            // 服务器没按 Range 请求返回，从文件头整段给数据，从中间偏移发起的任务没法服务
            if task.startOffset > 0 {
                task.isCancelled = true
                failUnservedRequests(error: WYMediaCacheError.rangeUnsupported)
                finishFullDownloads(error: WYMediaCacheError.rangeUnsupported)
                return .cancel
            }
            let length = httpResponse.expectedContentLength
            if applyContentInfo(length: length > 0 ? length : 0, mimeType: httpResponse.mimeType) == false {
                task.isCancelled = true
                failUnservedRequests(error: WYMediaCacheError.contentLengthUnknown)
                finishFullDownloads(error: WYMediaCacheError.contentLengthUnknown)
                return .cancel
            }
            task.chunkEnd = contentLength
            if cache.needsCellularConfirm(contentLength: contentLength, item: self) {
                cache.enqueueCellularConfirm(item: self)
                return .cancel
            }
            return .allow
        }
        let message = "服务器返回状态码 \(httpResponse.statusCode)"
        task.isCancelled = true
        failUnservedRequests(error: WYMediaCacheError.network(message))
        finishFullDownloads(error: WYMediaCacheError.network(message))
        return .cancel
    }

    /// 处理下载任务收到的数据(落盘、登记区间、按需喂给播放器请求)
    func handleData(_ task: WYMediaCacheDownloadTask, data: Data) {
        guard task.isCancelled == false, data.isEmpty == false else { return }
        let offset = task.startOffset + task.receivedBytes
        let range = Range<Int64>(uncheckedBounds: (offset, offset + Int64(data.count)))
        guard writeData(data, at: offset) else {
            task.isCancelled = true
            failUnservedRequests(error: WYMediaCacheError.fileIO("写入缓存文件失败"))
            finishFullDownloads(error: WYMediaCacheError.fileIO("写入缓存文件失败"))
            cache.cancelSessionTask(task)
            return
        }
        task.receivedBytes += Int64(data.count)
        index.insert(range)
        refreshFileSize()
        if isFullyCached {
            saveMetaData()
        }else {
            saveMetaDataIfNeeded()
        }
        notifyProgressIfNeeded()
        processRequests()
        cache.evictIfNeeded(excluding: key)
    }

    /// 处理下载任务结束(主动取消不算失败，网络失败时失败等不到数据的请求与预下载回调)
    func handleCompletion(_ task: WYMediaCacheDownloadTask, error: Error?) {
        downloadTasks.removeAll { $0 === task }
        if let error = error as NSError?, error.code != NSURLErrorCancelled {
            if Self.isTransientNetworkError(error) {
                // 断网类失败不停掉播放器请求与预下载回调，网络恢复后由管理器统一续起
                checkPendingRemoval()
                return
            }
            failUnservedRequests(error: WYMediaCacheError.network(error.localizedDescription))
            finishFullDownloads(error: WYMediaCacheError.network(error.localizedDescription))
        }else if error == nil && isFullyCached {
            saveMetaData()
            finishFullDownloads(error: nil)
        }
        processRequests()
        checkPendingRemoval()
    }

    /// 标记待删除(条目闲置时由管理器真正清理)
    func markPendingRemoval() {
        pendingRemoval = true
        checkPendingRemoval()
    }

    /// 条目闲置时执行待删除标记
    func checkPendingRemoval() {
        if pendingRemoval && isActive == false {
            cache.deleteItem(self)
        }
    }

    /// 用落盘元数据恢复条目(数据文件丢失或清零时缓存索引一并作废)
    func restore(metaData: WYMediaCacheMetaData, fileSize: Int64) {
        creationDate = metaData.creationDate
        lastAccessDate = metaData.lastAccessDate
        trackedFileSize = fileSize
        if fileSize > 0 {
            contentLength = metaData.contentLength
            mimeType = metaData.mimeType
            index = metaData.intervalIndex()
        }
    }

    /// 刷新最近使用时间(并按元数据落盘节流间隔决定是否落一次盘)
    func touch() {
        lastAccessDate = Date()
        saveMetaDataIfNeeded()
    }

    /// 喂播放器数据(内容信息到手先填，再从缓存区间一段段喂，喂不动的偏移补下载任务后等回调)
    func processRequests() {
        if contentLength > 0 {
            for request in loadingRequests {
                guard let infoRequest = request.contentInformationRequest else { continue }
                infoRequest.contentType = contentType()
                infoRequest.contentLength = contentLength
                infoRequest.isByteRangeAccessSupported = true
            }
        }
        for request in loadingRequests where request.isFinished == false {
            fulfill(request)
        }
        loadingRequests.removeAll { $0.isFinished }
        pumpDownloads()
        checkPendingRemoval()
    }

    /// 收敛下载任务(播放器还缺数据的偏移与预下载缺口各补任务，同时进行的任务数不超过配置上限)
    func pumpDownloads() {
        for request in loadingRequests {
            guard let dataRequest = request.dataRequest, request.isFinished == false else { continue }
            ensureTask(at: Int64(dataRequest.currentOffset))
        }
        if fullDownloadHandlers.isEmpty == false, isFullyCached == false {
            if contentLength > 0 {
                if let gapStart = index.firstGapStart(after: 0, limit: contentLength) {
                    ensureTask(at: gapStart)
                }
            }else {
                // 还没取到文件总大小时先从头取一块，响应会把总大小带回来
                ensureTask(at: 0)
            }
        }
    }

    /// 保存元数据到磁盘(索引有实际内容才写)
    func saveMetaData() {
        guard contentLength > 0 || index.cachedBytes > 0 else { return }
        let metaData = WYMediaCacheMetaData.metaData(url: originalURL.absoluteString,
                                                     contentLength: contentLength,
                                                     mimeType: mimeType,
                                                     index: index,
                                                     creationDate: creationDate,
                                                     lastAccessDate: lastAccessDate)
        if let data = try? JSONEncoder().encode(metaData) {
            try? data.write(to: metaDataURL, options: .atomic)
        }
        lastMetaSaveDate = Date()
    }

    /// 单个播放器请求的喂数循环(从当前偏移起在缓存区间里逐段读盘喂给请求)
    private func fulfill(_ request: AVAssetResourceLoadingRequest) {
        // 播放器探文件类型的请求带一个只要文件头两字节的伴生数据请求，这两字节播放器并不会真用，喂给它反而会让播放器不再发后续数据请求，所以这类请求只填内容信息
        if request.contentInformationRequest != nil {
            if contentLength > 0 {
                request.finishLoading()
            }
            return
        }
        guard let dataRequest = request.dataRequest else { return }
        // 单次 respond 的数据量上限，防止整段视频一次性读进内存
        let maxRespondLength = cache.config.maxRespondLength
        while request.isFinished == false {
            let currentOffset = Int64(dataRequest.currentOffset)
            var targetEnd: Int64
            if dataRequest.requestedLength > 0 {
                targetEnd = Int64(dataRequest.requestedOffset) + Int64(dataRequest.requestedLength)
            }else {
                targetEnd = contentLength > 0 ? contentLength : Int64.max
            }
            if contentLength > 0 {
                targetEnd = min(targetEnd, contentLength)
            }
            if currentOffset >= targetEnd {
                request.finishLoading()
                return
            }
            guard let cachedRange = index.range(covering: currentOffset) else {
                ensureTask(at: currentOffset)
                return
            }
            let readEnd = min(cachedRange.upperBound, targetEnd)
            let readLength = min(readEnd - currentOffset, maxRespondLength)
            guard let data = readData(offset: currentOffset, length: readLength), data.isEmpty == false else {
                request.finishLoading(with: WYMediaCacheError.fileIO("读取缓存文件失败"))
                return
            }
            dataRequest.respond(with: data)
        }
    }

    /// 确保指定偏移有下载任务在途(该偏移已缓存或有任务会带到它时不动)
    private func ensureTask(at offset: Int64) {
        guard index.range(covering: offset) == nil else { return }
        // 断网期间不启动下载任务，等网络恢复后由管理器统一重新收敛
        guard cache.isNetworkOnline else { return }
        guard cache.isBackgrounded == false else { return }
        for task in downloadTasks where offset >= task.startOffset && offset < task.chunkEnd { return }
        guard downloadTasks.count < cache.config.maxConcurrentDownloadCount else { return }
        guard cache.canStartMoreDownloadTasks() else { return }
        let task = WYMediaCacheDownloadTask(item: self,
                                            startOffset: offset,
                                            chunkSize: cache.config.downloadChunkSize,
                                            contentLength: contentLength)
        downloadTasks.append(task)
        cache.startSessionTask(task)
    }

    /// 失败所有等不到数据的请求(当前偏移没缓存也没有别的在途任务会覆盖)
    func failUnservedRequests(error: Error) {
        for request in loadingRequests where request.isFinished == false {
            guard let dataRequest = request.dataRequest else {
                request.finishLoading(with: error)
                continue
            }
            let offset = Int64(dataRequest.currentOffset)
            if index.range(covering: offset) == nil, downloadTasks.contains(where: { $0.isCancelled == false && offset >= $0.startOffset && offset < $0.chunkEnd }) == false {
                request.finishLoading(with: error)
            }
        }
        loadingRequests.removeAll { $0.isFinished }
    }

    /// 结束全部预下载回调并清空回调列表
    func finishFullDownloads(error: Error?) {
        let handlers = fullDownloadHandlers
        fullDownloadHandlers.removeAll()
        guard handlers.isEmpty == false else { return }
        Task { @MainActor in
            for handler in handlers {
                handler.completion?(error)
            }
        }
    }

    /// 距上次落盘超过配置的节流间隔时保存元数据
    private func saveMetaDataIfNeeded() {
        if let lastDate = lastMetaSaveDate, Date().timeIntervalSince(lastDate) < cache.config.metaDataSaveInterval {
            return
        }
        saveMetaData()
    }

    /// 距上次回调超过配置的节流间隔时给预下载回调报进度
    private func notifyProgressIfNeeded() {
        if fullDownloadHandlers.isEmpty { return }
        if let lastDate = lastProgressNotifyDate, Date().timeIntervalSince(lastDate) < cache.config.progressNotifyInterval {
            return
        }
        lastProgressNotifyDate = Date()
        let cachedBytes = index.cachedBytes
        let length = contentLength
        let handlers = fullDownloadHandlers
        Task { @MainActor in
            for handler in handlers {
                handler.progress?(cachedBytes, length)
            }
        }
    }

    /// 是否断网类网络错误(断网、连接中断、DNS 失败、超时这类临时性错误，恢复网络后可自动续传)
    static func isTransientNetworkError(_ error: NSError) -> Bool {
        guard error.domain == NSURLErrorDomain else { return false }
        let transientCodes: Set<Int> = [NSURLErrorNotConnectedToInternet,
                                        NSURLErrorNetworkConnectionLost,
                                        NSURLErrorCannotFindHost,
                                        NSURLErrorCannotConnectToHost,
                                        NSURLErrorDNSLookupFailed,
                                        NSURLErrorTimedOut,
                                        NSURLErrorInternationalRoamingOff,
                                        NSURLErrorDataNotAllowed]
        return transientCodes.contains(error.code)
    }

    /// 记录媒体类型与总大小(总大小以第一次取到的为准，取不到返回 false)
    @discardableResult
    private func applyContentInfo(length: Int64, mimeType: String?) -> Bool {
        if let mimeType = mimeType, self.mimeType == nil {
            self.mimeType = mimeType
        }
        if contentLength == 0 {
            guard length > 0 else { return false }
            contentLength = length
            saveMetaData()
        }
        return true
    }

    /// 从 206 响应的 Content-Range 头里取文件总大小(服务器没给时返回 0)
    private func totalLength(from response: HTTPURLResponse) -> Int64 {
        guard let contentRange = response.value(forHTTPHeaderField: "Content-Range") else { return 0 }
        // 形如 bytes 0-1023/5120，斜杠后的部分是总大小，"*" 表示服务器没给
        guard let totalText = contentRange.split(separator: "/").last else { return 0 }
        return Int64(totalText) ?? 0
    }

    /// 媒体类型对应的系统类型标识(喂给播放器的内容信息用)
    private func contentType() -> String? {
        if let mimeType = mimeType, let type = UTType(mimeType: mimeType) {
            return type.identifier
        }
        let ext = originalURL.pathExtension
        if ext.isEmpty == false, let type = UTType(filenameExtension: ext) {
            return type.identifier
        }
        return UTType.data.identifier
    }

    /// 把收到的数据写到媒体文件的指定偏移
    private func writeData(_ data: Data, at offset: Int64) -> Bool {
        if openWriteHandle() == false { return false }
        guard let handle = writeFileHandle else { return false }
        do {
            try handle.seek(toOffset: UInt64(offset))
            try handle.write(contentsOf: data)
            return true
        }catch {
            return false
        }
    }

    /// 从媒体文件读一段数据
    private func readData(offset: Int64, length: Int64) -> Data? {
        guard length > 0, FileManager.default.fileExists(atPath: mediaURL.path) else { return nil }
        if openReadHandle() == false { return nil }
        guard let handle = readFileHandle else { return nil }
        do {
            try handle.seek(toOffset: UInt64(offset))
            return try handle.read(upToCount: Int(length))
        }catch {
            return nil
        }
    }

    /// 打开媒体文件读句柄(文件必须已存在)
    private func openReadHandle() -> Bool {
        if readFileHandle != nil { return true }
        readFileHandle = try? FileHandle(forReadingFrom: mediaURL)
        return readFileHandle != nil
    }

    /// 打开媒体文件写句柄(文件不存在时先创建空文件)
    private func openWriteHandle() -> Bool {
        if writeFileHandle != nil { return true }
        if FileManager.default.fileExists(atPath: mediaURL.path) == false {
            guard FileManager.default.createFile(atPath: mediaURL.path, contents: nil) else { return false }
        }
        writeFileHandle = try? FileHandle(forWritingTo: mediaURL)
        return writeFileHandle != nil
    }

    /// 同步缓存文件实际大小到缓存总容量
    private func refreshFileSize() {
        let size = Int64(WYStorage.sandboxFileSize(forPath: mediaURL.path))
        cache.totalSize += size - trackedFileSize
        trackedFileSize = size
    }
}
