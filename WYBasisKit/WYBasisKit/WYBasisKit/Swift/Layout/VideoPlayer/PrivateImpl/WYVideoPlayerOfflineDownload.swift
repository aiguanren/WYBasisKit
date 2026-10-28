//
//  WYVideoPlayerOfflineDownload.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

import AVFoundation
import Foundation

/// 视频整段下载与离线地址管理
final class WYVideoPlayerOfflineDownload: NSObject, AVAssetDownloadDelegate, URLSessionDownloadDelegate {

    /// 下载进度与结果
    var onProgress: ((_ progress: Double) -> Void)?
    var onCompletion: ((_ url: URL?, _ error: Error?) -> Void)?

    /// 已下载素材的可播放地址
    static func localURL(for url: URL, isHLS: Bool = false) -> URL? {
        if url.isFileURL { return FileManager.default.fileExists(atPath: url.path) ? url : nil }
        if let path = UserDefaults.standard.dictionary(forKey: storageKey)?[url.absoluteString] as? String,
           let local = path.hasPrefix("sandbox:") ? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(String(path.dropFirst("sandbox:".count))) : URL(string: path),
           FileManager.default.fileExists(atPath: local.path) { return local }
        guard !isHLS, url.pathExtension.lowercased() != "m3u8" else { return nil }
        if let path = WYMediaCache.shared.cachedFilePath(for: url) { return URL(fileURLWithPath: path) }
        return nil
    }

    /// 开始当前素材下载
    func start(quality: WYVideoPlayerMediaQuality, allowsCellular: Bool) {
        cancel()
        sourceURL = quality.url
        if let local = Self.localURL(for: quality.url, isHLS: quality.isHLSMaster) {
            onProgress?(1)
            onCompletion?(local, nil)
            return
        }
        let token = UUID()
        generation = token
        if quality.isHLSMaster || quality.url.pathExtension.lowercased() == "m3u8" {
            preparationTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    let asset = AVURLAsset(url: quality.url, options: [AVURLAssetAllowsCellularAccessKey: allowsCellular])
                    let duration = try await asset.load(.duration)
                    let playable = try await asset.load(.isPlayable)
                    try Task.checkCancellation()
                    guard self.generation == token else { return }
                    guard duration.seconds.isFinite, duration.seconds > 0, playable else {
                        self.onCompletion?(nil, NSError(domain: "WYVideoPlayer.Download", code: -3, userInfo: [NSLocalizedDescriptionKey: WYLocalized("仅支持下载点播视频", table: WYBasisKitConfig.kitLocalizableTable)]))
                        return
                    }
                    let configuration = URLSessionConfiguration.background(withIdentifier: "WYVideoPlayer.download." + UUID().uuidString)
                    configuration.allowsCellularAccess = allowsCellular
                    let session = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: .main)
                    self.session = session
                    let downloadConfiguration = AVAssetDownloadConfiguration(asset: asset, title: quality.name)
                    let task = session.makeAssetDownloadTask(downloadConfiguration: downloadConfiguration)
                    self.task = task
                    self.observation = task.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
                        DispatchQueue.main.async {
                            guard let self = self, self.generation == token else { return }
                            self.onProgress?(max(0, min(1, progress.fractionCompleted)))
                        }
                    }
                    task.resume()
                } catch {
                    guard !Task.isCancelled, self.generation == token else { return }
                    self.onCompletion?(nil, error)
                }
            }
        } else {
            let configuration = URLSessionConfiguration.background(withIdentifier: "WYVideoPlayer.download." + UUID().uuidString)
            configuration.allowsCellularAccess = allowsCellular
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
            self.session = session
            let task = session.downloadTask(with: quality.url)
            self.task = task
            task.resume()
        }
    }

    /// 取消本次下载
    func cancel() {
        generation = UUID()
        preparationTask?.cancel()
        preparationTask = nil
        observation?.invalidate()
        observation = nil
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        sourceURL = nil
        destinationURL = nil
        fileError = nil
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard downloadTask === task else { return }
        onProgress?(totalBytesExpectedToWrite > 0 ? min(1, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) : 0)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard downloadTask === task else { return }
        guard let response = downloadTask.response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            fileError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse)
            return
        }
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("WYVideoPlayerDownloads", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let filename = UUID().uuidString + "." + (sourceURL?.pathExtension.isEmpty == false ? sourceURL!.pathExtension : "mp4")
            let destination = directory.appendingPathComponent(filename)
            try FileManager.default.moveItem(at: location, to: destination)
            destinationURL = destination
        } catch { fileError = error }
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, willDownloadTo location: URL) {
        guard assetDownloadTask === task else { return }
        destinationURL = localLocation(location)
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard assetDownloadTask === task else { return }
        destinationURL = localLocation(location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task === self.task else { return }
        observation?.invalidate()
        observation = nil
        var resultError = error ?? fileError
        if resultError == nil, let destinationURL = destinationURL, let sourceURL = sourceURL {
            var paths = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:]
            let home = NSHomeDirectory() + "/"
            paths[sourceURL.absoluteString] = destinationURL.path.hasPrefix(home) ? "sandbox:" + String(destinationURL.path.dropFirst(home.count)) : destinationURL.absoluteString
            UserDefaults.standard.set(paths, forKey: Self.storageKey)
            onProgress?(1)
        } else if resultError == nil {
            resultError = NSError(domain: "WYVideoPlayer.Download", code: -1)
        }
        let localURL = resultError == nil ? destinationURL : nil
        let completedSession = self.session
        self.task = nil
        self.session = nil
        completedSession?.finishTasksAndInvalidate()
        onCompletion?(localURL, resultError)
    }

    private static let storageKey = "WYVideoPlayer.offlineAssets"
    private var sourceURL: URL?
    private var destinationURL: URL?
    private var fileError: Error?
    private var session: URLSession?
    private var task: URLSessionTask?
    private var observation: NSKeyValueObservation?
    private var generation = UUID()
    private var preparationTask: Task<Void, Never>?

    private func localLocation(_ location: URL) -> URL {
        guard location.baseURL != nil else { return location }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent(location.relativePath)
    }

    deinit {
        observation?.invalidate()
        session?.invalidateAndCancel()
    }
}
