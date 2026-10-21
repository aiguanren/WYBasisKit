//
//  WYAudioKit+Download.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation

/// WYAudioKit 下载内部实现，URLSession 回调处理（重定向/进度/落盘/错误）、批次进度聚合回调、下载映射持久化与旧任务状态清理
extension WYAudioKit {
    
    /// 下载映射在UserDefaults里的存储key，字符串与历史版本保持一致(改了会读不回旧数据)
    static let downloadMappingStorageKey = "WYAudioKitDownloadMapping"
    
    /// 下载映射落盘(本地路径->远程URL，getAllDownloads靠它找回源地址)
    func persistDownloadMapping() {
        UserDefaults.standard.set(state.downloadMapping, forKey: WYAudioKit.downloadMappingStorageKey)
    }
    
    /// 加载持久化的下载映射
    func loadDownloadMapping() {
        if let dict = UserDefaults.standard.dictionary(forKey: WYAudioKit.downloadMappingStorageKey) as? [String: String] {
            state.downloadMapping = dict
        }
    }
    
    /// 清掉某个原始URL残留的旧下载状态(重新下载前调用)，旧任务取消、从旧批次待完成集合移除，防止旧批次永远等不到回调卡在字典里
    func detachOldDownloadState(for originalURL: URL) {
        let oldInfo = state.tasksInfo[originalURL] ?? state.pausedTaskInfo[originalURL]
        
        var oldTask: URLSessionDownloadTask?
        if let activeInfo = state.tasksInfo[originalURL] {
            oldTask = activeInfo.task
            state.tasksInfo.removeValue(forKey: originalURL)
            state.downloadProgresses.removeValue(forKey: activeInfo.currentURL)
        }
        if let pausedInfo = state.pausedTaskInfo[originalURL] {
            oldTask = oldTask ?? pausedInfo.task
            state.pausedTaskInfo.removeValue(forKey: originalURL)
            state.downloadProgresses.removeValue(forKey: pausedInfo.currentURL)
        }
        oldTask?.cancel()
        // 旧任务都清了，排队中的恢复请求一并作废
        state.pendingResumeUrls.remove(originalURL)
        
        // 从旧批次里移除这个URL，批次空了就整个删掉(不补发failed，用户主动重新下载说明不需要旧结果)
        if let batchID = oldInfo?.batchID, var batch = state.downloadGroups[batchID] {
            batch.pendingUrls.remove(originalURL)
            state.downloadGroups[batchID] = batch
            if batch.pendingUrls.isEmpty {
                state.downloadGroups.removeValue(forKey: batchID)
                state.lastNotifiedBatchProgress.removeValue(forKey: batchID)
            }
        }
    }
    
    /// 更新下载进度（按批次聚合）
    func updateDownloadProgressIfNeeded() {
        guard !state.tasksInfo.isEmpty else {
            if !state.lastNotifiedBatchProgress.isEmpty {
                state.lastNotifiedBatchProgress.removeAll()
            }
            return
        }
        // 按批次聚合进度
        var batchProgress: [UUID: (total: Double, count: Int)] = [:]
        for (_, info) in state.tasksInfo {
            let progress = state.downloadProgresses[info.currentURL] ?? info.progress
            batchProgress[info.batchID, default: (0, 0)].total += progress
            batchProgress[info.batchID]?.count += 1
        }
        
        for (batchID, value) in batchProgress {
            let avg = value.total / Double(value.count)
            guard let batch = state.downloadGroups[batchID],
                  // 进度没变化就不回调(刷新器每帧都跑，不拦截时一秒30次内容完全相同的delegate，外部UI无效刷新)
                  abs(avg - (state.lastNotifiedBatchProgress[batchID] ?? -1)) > 0.001 else { continue }
            state.lastNotifiedBatchProgress[batchID] = avg
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                             remoteUrls: batch.remoteUrls,
                                                             progress: avg)
        }
    }
    
    /**
     处理 HTTP 重定向
       @param session URLSession 实例
       @param task 发生重定向的任务
       @param response HTTP 响应
       @param request 新的请求
       @param completionHandler 完成回调
     */
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard let newURL = request.url,
              let originalRemote = (state.tasksInfo.first { $0.value.task === task })?.key ??
                (state.pausedTaskInfo.first { $0.value.task === task })?.key else {
            completionHandler(request)
            return
        }
        
        if originalRemote == newURL {
            completionHandler(request)
            return
        }
        
        // 更新任务信息中的当前URL
        if var info = state.tasksInfo[originalRemote] {
            info.currentURL = newURL
            state.tasksInfo[originalRemote] = info
            // 更新进度映射
            if let progress = state.downloadProgresses[originalRemote] {
                state.downloadProgresses.removeValue(forKey: originalRemote)
                state.downloadProgresses[newURL] = progress
            }
        } else if var info = state.pausedTaskInfo[originalRemote] {
            info.currentURL = newURL
            state.pausedTaskInfo[originalRemote] = info
            // 暂停中的任务也可能有进度映射（如已暂停但未恢复）
            if let progress = state.downloadProgresses[originalRemote] {
                state.downloadProgresses.removeValue(forKey: originalRemote)
                state.downloadProgresses[newURL] = progress
            }
        }
        
        completionHandler(request)
    }
    
    /**
     下载进度更新回调
       @param session URLSession 实例
       @param downloadTask 下载任务
       @param bytesWritten 本次写入的字节数
       @param totalBytesWritten 已写入的总字节数
       @param totalBytesExpectedToWrite 预期总字节数
     */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let originalURL = state.tasksInfo.first(where: { $0.value.task === downloadTask })?.key,
              var info = state.tasksInfo[originalURL] else {
            // 下载进度回调中找不到任务
            return
        }
        // 恢复下载进度防跳回0(恢复的任务系统可能从0重新累计已写字节，首次回调校准一次，已写字节没到基点说明是从0计的，把基点补上)，之后按校准偏移算进度
        if !info.hasCalibratedResumeBytes {
            info.hasCalibratedResumeBytes = true
            info.resumeOffsetBytes = totalBytesWritten < info.resumeBaselineBytes ? info.resumeBaselineBytes : 0
        }
        let progress = totalBytesExpectedToWrite > 0 ? Double(info.resumeOffsetBytes + totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        info.progress = progress
        state.tasksInfo[originalURL] = info
        state.downloadProgresses[info.currentURL] = progress
    }
    
    /**
     下载完成回调（临时文件位置）
       @param session URLSession 实例
       @param downloadTask 下载任务
       @param location 临时文件 URL
     */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let originalURL = state.tasksInfo.first(where: { $0.value.task === downloadTask })?.key,
              let info = state.tasksInfo[originalURL],
              var batch = state.downloadGroups[info.batchID] else {
            // 无法找到对应的任务或批次
            wy_handleErrorEvents(url: nil, error: .downloadFailed)
            return
        }
        
        let fm = FileManager.default
        let destination = state.downloadsDirectoryURL.appendingPathComponent(info.currentURL.lastPathComponent)
        
        do {
            if !fm.fileExists(atPath: destination.deletingLastPathComponent().path) {
                try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            }
            
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            // 系统给的location文件在本回调返回后就会被删，用move一次落盘即可(copy要把整份音频再读写一遍，大文件I/O翻倍)
            try fm.moveItem(at: location, to: destination)
            
            guard fm.fileExists(atPath: destination.path),
                  let attr = try? fm.attributesOfItem(atPath: destination.path),
                  (attr[.size] as? Int64 ?? 0) > 0 else {
                batch.hasFailed = true
                batch.failed(WYAudioError.downloadFailed)
                state.downloadGroups[info.batchID] = batch
                return
            }
            
            let downloadInfo = WYAudioDownloadInfo(remote: info.currentURL, local: destination)
            batch.infosByOriginalURL[originalURL] = downloadInfo
            state.downloadMapping[destination.path] = info.currentURL.absoluteString
            persistDownloadMapping()
            
            batch.pendingUrls.remove(originalURL)
            state.downloadGroups[info.batchID] = batch
            state.downloadProgresses[info.currentURL] = 1.0
            
            // 立即通知完成进度
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                             remoteUrls: batch.remoteUrls,
                                                             progress: 1.0)
            
            if batch.pendingUrls.isEmpty {
                // 按用户传入的remoteUrls顺序回调(文件完成的先后顺序是随机的，直接按完成顺序回调会与传入顺序不一致)
                batch.success(batch.remoteUrls.compactMap { batch.infosByOriginalURL[$0] })
                state.downloadGroups.removeValue(forKey: info.batchID)
                state.lastNotifiedBatchProgress.removeValue(forKey: info.batchID)
            }
        } catch {
            batch.hasFailed = true
            batch.failed(error)
            state.downloadGroups[info.batchID] = batch
        }
        
        // 单个文件完成就移除任务记录(批次里还有别的文件未完成时该记录会一直留着，刷新器也就一直停不下来)
        state.tasksInfo.removeValue(forKey: originalURL)
        state.downloadProgresses.removeValue(forKey: info.currentURL)
        stopDisplayLinkIfNeeded()
    }
    
    /**
     任务完成回调（包含错误）
       @param session URLSession 实例
       @param task 完成的任务
       @param error 发生的错误（如果有）
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let originalURL = state.tasksInfo.first(where: { $0.value.task === task })?.key,
              let info = state.tasksInfo[originalURL],
              var batch = state.downloadGroups[info.batchID] else { return }
        batch.pendingUrls.remove(originalURL)
        if !batch.hasFailed {
            batch.hasFailed = true
            batch.failed(error)
        }
        state.downloadGroups[info.batchID] = batch
        if batch.pendingUrls.isEmpty {
            state.downloadGroups.removeValue(forKey: info.batchID)
            state.lastNotifiedBatchProgress.removeValue(forKey: info.batchID)
        }
        state.tasksInfo.removeValue(forKey: originalURL)
        state.downloadProgresses.removeValue(forKey: info.currentURL)
        stopDisplayLinkIfNeeded()
    }
}

/// URLSession 的弱引用代理(会话会强持有delegate直到invalidate，直接把kit传给它时不调releaseAll就永远释放不了，会话持有它、它只弱持有kit，kit释放时deinit里作废会话，整条引用链一起断开)
final class WYWeakSessionDelegate: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
    
    /// 真正处理回调的kit实例
    weak var kit: WYAudioKit?
    
    /// 唯一初始化方法
    init(kit: WYAudioKit) {
        self.kit = kit
    }
    
    func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {
        guard let kit = kit else {
            // kit已经释放了，重定向只能照原样放行
            completionHandler(request)
            return
        }
        kit.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        kit?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        kit?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        kit?.urlSession(session, task: task, didCompleteWithError: error)
    }
}
