//
//  WYAudioDownloader.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation

internal final class WYAudioDownloader: NSObject, URLSessionDownloadDelegate {
    weak var kit: WYAudioKit?
    
    private var session: URLSession?
    private var tasks: [URL: URLSessionDownloadTask] = [:]
    private var progressMap: [URL: Double] = [:]
    private var completions: [URL: ((WYAudioDownloadInfo?, Error?) -> Void)] = [:]
    private let queue = DispatchQueue(label: "com.wy.audio.downloader")
    
    func downloadRemoteAudio(remoteUrls: [URL], success: @escaping ([WYAudioDownloadInfo]) -> Void, failed: @escaping (Error?) -> Void) {
        if session == nil {
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        }
        
        var infos: [WYAudioDownloadInfo] = []
        let group = DispatchGroup()
        
        for url in remoteUrls {
            group.enter()
            let localURL = kit?.fileManager.localURLForRemote(url) ?? FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            let task = session?.downloadTask(with: url)
            tasks[url] = task
            completions[url] = { info, err in
                if let info { infos.append(info) }
                group.leave()
            }
            task?.resume()
        }
        
        group.notify(queue: .main) {
            success(infos)
        }
    }
    
    func pauseDownload(_ remoteUrls: [URL]?) {
        let urls = remoteUrls ?? Array(tasks.keys)
        for u in urls {
            tasks[u]?.suspend()
        }
    }
    
    func resumeDownload(_ remoteUrls: [URL]?) {
        let urls = remoteUrls ?? Array(tasks.keys)
        for u in urls {
            tasks[u]?.resume()
        }
    }
    
    func cancelDownload(_ remoteUrls: [URL]?) {
        let urls = remoteUrls ?? Array(tasks.keys)
        for u in urls {
            tasks[u]?.cancel()
            tasks.removeValue(forKey: u)
        }
    }
    
    // URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let remote = downloadTask.originalRequest?.url else { return }
        let local = kit?.fileManager.localURLForRemote(remote) ?? location
        do {
            try FileManager.default.moveItem(at: location, to: local)
            let info = WYAudioDownloadInfo(remote: remote, local: local)
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_remoteAudioDownloadSuccess?(audioKit: self.kit!, fileInfos: [info])
                self.completions[remote]?(info, nil)
                self.tasks.removeValue(forKey: remote)
            }
        } catch {
            DispatchQueue.main.async {
                self.completions[remote]?(nil, error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let remote = downloadTask.originalRequest?.url else { return }
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        progressMap[remote] = progress
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self.kit!, remoteUrls: [remote], progress: progress)
        }
    }
    
    func releaseResources() {
        cancelDownload(nil)
        session?.invalidateAndCancel()
        session = nil
    }
}
