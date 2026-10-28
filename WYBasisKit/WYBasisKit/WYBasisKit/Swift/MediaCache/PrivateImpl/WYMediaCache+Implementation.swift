//
//  WYMediaCache+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import AVFoundation
import Foundation
import Network
import UIKit

/// 媒体缓存的请求调度、磁盘管理与下载回调
extension WYMediaCache {

    /// 把缓存协议头地址还原成原始播放地址，保留HTTP或HTTPS协议
    func originalURL(fromCacheURL url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(),
              scheme == config.scheme.lowercased() || scheme == config.scheme.lowercased() + "-http" else { return nil }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.scheme = scheme == config.scheme.lowercased() + "-http" ? "http" : "https"
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
    func perform<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: WYMediaCache.queueKey) == true {
            return work()
        }
        return queue.sync(execute: work)
    }

    /// 校验播放地址协议头，不合法时主线程回调报错
    func checkScheme(_ url: URL, completion: ((_ error: Error?) -> Void)?) -> Bool {
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
