//
//  WYVideoPlayerPlaybackOptions.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

import AVFoundation
import UIKit

/// 定时关闭、音频模式与离线下载状态
final class WYVideoPlayerPlaybackOptions {

    weak var player: WYVideoPlayer?
    var stateChanged: (() -> Void)?
    private(set) var isAudioOnly = false
    private(set) var isBackgroundPlaybackEnabled = false
    private(set) var sleepDeadline: Date?
    private(set) var sleepsAtVideoEnd = false
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0

    /// 设置音频播放模式
    func setAudioOnly(_ enabled: Bool) {
        guard isAudioOnly != enabled else { return }
        let request = UUID()
        audioOnlyRequest = request
        isAudioOnly = enabled
        if enabled {
            activateAudioSession { [weak self] error in
                guard let self = self, self.audioOnlyRequest == request, let error = error else { return }
                self.setAudioOnly(false)
                self.stateChanged?()
                if let player = self.player { player.delegate?.wy_videoPlayer?(player, didFailWithError: error) }
            }
        }
        applyVideoTracks()
        if let player = player {
            player.engine.handleLoadingState(player.state)
            player.controlShell?.updateState(player.state)
        }
    }

    /// 切换条目后恢复视频轨道状态
    func applyVideoTracks() {
        guard let player = player else { return }
        player.playerLayer.player = isAudioOnly ? nil : player.avPlayer
        guard let item = player.avPlayer.currentItem else { return }
        for track in item.tracks where track.assetTrack?.mediaType == .video { track.isEnabled = !isAudioOnly }
    }

    /// 后台播放需要播放类音频会话
    func setBackgroundPlayback(_ enabled: Bool) {
        guard isBackgroundPlaybackEnabled != enabled else { return }
        let request = UUID()
        backgroundPlaybackRequest = request
        isBackgroundPlaybackEnabled = enabled
        if enabled {
            activateAudioSession { [weak self] error in
                guard let self = self, self.backgroundPlaybackRequest == request, let error = error else { return }
                self.setBackgroundPlayback(false)
                self.stateChanged?()
                if let player = self.player { player.delegate?.wy_videoPlayer?(player, didFailWithError: error) }
            }
        }
    }

    /// 设置关闭时间，nil 取消
    func setSleepTimer(after interval: TimeInterval?, atVideoEnd: Bool = false) {
        sleepWork?.cancel()
        sleepWork = nil
        sleepDeadline = nil
        sleepsAtVideoEnd = atVideoEnd
        guard let interval = interval, interval.isFinite, interval > 0, !atVideoEnd else { return }
        sleepDeadline = Date().addingTimeInterval(interval)
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.sleepDeadline = nil
            self.sleepWork = nil
            self.player?.pause()
        }
        sleepWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: work)
    }

    /// 本集结束优先于循环播放
    func consumeSleepAtEnd() -> Bool {
        guard sleepsAtVideoEnd else { return false }
        setSleepTimer(after: nil)
        player?.pause()
        return true
    }

    /// 下载当前清晰度
    func download(completion: ((_ url: URL?, _ error: Error?) -> Void)?) {
        guard let player = player, let quality = player.currentAsset?.currentQuality else {
            completion?(nil, NSError(domain: "WYVideoPlayer.Download", code: -2))
            return
        }
        cancelDownload()
        isDownloading = true
        downloadProgress = 0
        downloader.onProgress = { [weak self] progress in self?.downloadProgress = progress }
        downloader.onCompletion = { [weak self] url, error in
            self?.isDownloading = false
            if url != nil { self?.downloadProgress = 1 }
            if let self = self, let player = self.player, let error = error {
                player.delegate?.wy_videoPlayer?(player, didFailWithError: error)
            }
            completion?(url, error)
        }
        downloader.start(quality: quality, allowsCellular: player.configuration.offlineDownloadAllowsCellularAccess)
    }

    /// 取消下载
    func cancelDownload() {
        downloader.cancel()
        downloader.onCompletion = nil
        isDownloading = false
    }

    private func activateAudioSession(completion: @escaping (Error?) -> Void) {
        audioSessionCompletions.append(completion)
        guard audioSessionCompletions.count == 1 else { return }
        audioSessionQueue.async { [weak self] in
            let finish: (Error?) -> Void = { error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let completions = self.audioSessionCompletions
                    self.audioSessionCompletions.removeAll()
                    completions.forEach { $0(error) }
                }
            }
            do {
                let session = AVAudioSession.sharedInstance()
                if session.category != .playback || session.mode != .moviePlayback {
                    try session.setCategory(.playback, mode: .moviePlayback)
                }
                if #available(iOS 27.0, *) {
                    session.activate(options: []) { activated, error in
                        finish(activated ? nil : (error ?? NSError(domain: AVFoundationErrorDomain, code: AVError.Code.unknown.rawValue)))
                    }
                }else {
                    try session.setActive(true)
                    finish(nil)
                }
            } catch {
                finish(error)
            }
        }
    }

    private var audioOnlyRequest = UUID()
    private var backgroundPlaybackRequest = UUID()
    private var audioSessionCompletions: [(Error?) -> Void] = []
    private let audioSessionQueue = DispatchQueue(label: "com.wybasiskit.videoPlayer.audioSession", qos: .userInitiated)
    private var sleepWork: DispatchWorkItem?
    private let downloader = WYVideoPlayerOfflineDownload()

    deinit {
        sleepWork?.cancel()
        downloader.cancel()
    }
}
