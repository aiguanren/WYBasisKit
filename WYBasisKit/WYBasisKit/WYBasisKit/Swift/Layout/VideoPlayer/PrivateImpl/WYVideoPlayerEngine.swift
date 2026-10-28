//
//  WYVideoPlayerEngine.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// 播放内核(监听播放器与条目状态推进状态机、周期回调进度、处理播完循环与音频打断、前后台续播，只被播放器内部使用)
final class WYVideoPlayerEngine: NSObject {

    /// 所属播放器
    private weak var player: WYVideoPlayer?

    /// 播放控制状态监听(playing、paused、waiting 三态推播放器状态)
    private var timeControlStatusObservation: NSKeyValueObservation?

    /// 条目状态监听(装载结果与失败)
    private var itemStatusObservation: NSKeyValueObservation?

    /// 倍速监听(壳与外部直接改 AVPlayer 倍速时同步壳)
    private var rateObservation: NSKeyValueObservation?

    /// 周期进度监听
    private var timeObserver: Any?

    /// 已应用的进度回调间隔
    private var appliedProgressInterval: TimeInterval?

    /// 通知监听者
    private var notificationObservers: [NSObjectProtocol] = []

    /// 已播完轮数
    private var playedLoopCount = 0

    /// 音频打断前是否在播(打断结束按它决定要不要续)
    private var wasPlayingBeforeInterruption = false

    /// 加载与缓冲超时任务
    private var loadingTimeoutWorkItem: DispatchWorkItem?

    /// 条目 ready 前进来的 seek 请求(条目好了补执行)
    private var pendingSeekTime: TimeInterval?

    /// 条目 ready 前是否要开播
    private var pendingAutoplay: Bool?

    init(playerHolder: WYVideoPlayer?) {
        self.player = playerHolder
        super.init()
    }

    /// 绑定播放器(播放器先建内核再调 super.init 后回绑)
    func bind(player: WYVideoPlayer) {
        self.player = player
        observePlayer()
        registerNotifications()
    }

    /// 装载新条目(旧监听全清)
    func load(item: AVPlayerItem) {
        let player = self.player
        itemStatusObservation?.invalidate()
        timeObserver.map { player?.avPlayer.removeTimeObserver($0) }
        timeObserver = nil
        // 换条目前先拆掉播放器级 KVO，替换瞬间的旧状态不再漏进状态机造成假 playing 抖动
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
        rateObservation?.invalidate()
        rateObservation = nil
        playedLoopCount = 0
        pendingAutoplay = nil
        pendingSeekTime = nil
        player?.setState(.preparing)
        player?.readyForDisplayObservation?.invalidate()
        player?.readyForDisplayObservation = nil
        player?.avPlayer.replaceCurrentItem(with: item)
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] (item, _) in
            guard let self = self, let player = self.player else { return }
            DispatchQueue.main.async {
                guard player.avPlayer.currentItem === item else { return }
                switch item.status {
                case .readyToPlay:
                    self.observePlayer()
                    player.setState(.readyToPlay)
                    player.observeReadyForDisplay()
                    player.snapshotTaker.attach(to: item)
                    player.subtitleParser.collectNativeTracks(from: item)
                    player.playbackOptions.applyVideoTracks()
                    player.refreshMediaInfoToShell()
                    player.controlShell?.updateProgress(currentTime: player.playbackTime, duration: player.duration, playableDuration: 0)
                    if let seekTime = self.pendingSeekTime {
                        self.pendingSeekTime = nil
                        player.seek(to: seekTime, accurate: true)
                    }
                    if self.pendingAutoplay ?? player.configuration.shouldAutoplay {
                        player.resume()
                    } else if self.pendingAutoplay == false {
                        player.setState(.paused)
                    }
                case .failed:
                    player.setState(.failed)
                    player.delegate?.wy_videoPlayer?(player, didFailWithError: item.error ?? NSError(domain: "WYVideoPlayer", code: -1))
                default:
                    break
                }
            }
        }
        refreshProgressObservation()
    }

    /// 按配置更新进度回调间隔
    func refreshProgressObservation() {
        guard let player = player else { return }
        let interval = player.configuration.progressCallbackInterval.isFinite && player.configuration.progressCallbackInterval > 0 ? player.configuration.progressCallbackInterval : 1 / Double(UIScreen.main.maximumFramesPerSecond)
        guard timeObserver == nil || appliedProgressInterval != interval else { return }
        if let observer = timeObserver { player.avPlayer.removeTimeObserver(observer) }
        timeObserver = nil
        appliedProgressInterval = interval
        guard player.avPlayer.currentItem != nil else { return }
        timeObserver = player.avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: interval, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.handleProgress(time)
        }
    }

    /// 按播放状态控制等待时限，超时后交给控制壳显示重试
    func handleLoadingState(_ state: WYVideoPlayerState) {
        guard let player = player else { return }
        if state == .playing && !player.isAudioOnly && !player.playerLayer.isReadyForDisplay { return }
        cancelLoadingTimeout()
        guard state == .preparing || state == .readyToPlay || state == .buffering,
              player.configuration.loadingTimeout > 0 else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let player = self.player else { return }
            guard player.state == .preparing || player.state == .readyToPlay || player.state == .buffering || (player.state == .playing && !player.isAudioOnly && !player.playerLayer.isReadyForDisplay) else { return }
            player.avPlayer.replaceCurrentItem(with: nil)
            player.setState(.failed)
            player.delegate?.wy_videoPlayer?(player, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))
        }
        loadingTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + player.configuration.loadingTimeout, execute: workItem)
    }

    /// 取消加载等待任务
    func cancelLoadingTimeout() {
        loadingTimeoutWorkItem?.cancel()
        loadingTimeoutWorkItem = nil
    }

    /// 记住条目就绪后要定位的位置(切清晰度续播用)
    func seekWhenReady(at time: TimeInterval) {
        pendingSeekTime = time
    }

    /// 记住条目就绪后要开播
    func setAutoplayWhenReady(_ shouldPlay: Bool) {
        pendingAutoplay = shouldPlay
    }

    /// 无缝换档收尾(画面层已换到新 AVPlayer 后调)：重绑播放器级监听与新条目装配，不重走装载黑帧路径
    func adoptAVPlayer(item: AVPlayerItem, replacing oldPlayer: AVPlayer) {
        guard let player = player else { return }
        timeControlStatusObservation?.invalidate()
        rateObservation?.invalidate()
        if let observer = timeObserver {
            oldPlayer.removeTimeObserver(observer)
        }
        timeObserver = nil
        itemStatusObservation?.invalidate()
        playedLoopCount = 0
        observePlayer()
        refreshProgressObservation()
        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] (item, _) in
            guard let self = self, let player = self.player, item.status == .failed else { return }
            DispatchQueue.main.async {
                player.setState(.failed)
                player.delegate?.wy_videoPlayer?(player, didFailWithError: item.error ?? NSError(domain: "WYVideoPlayer", code: -1))
            }
        }
        player.snapshotTaker.attach(to: item)
        player.subtitleParser.collectNativeTracks(from: item)
    }

    /// 全部监听拆除(播放器销毁时调)
    func unload() {
        cancelLoadingTimeout()
        timeControlStatusObservation?.invalidate()
        itemStatusObservation?.invalidate()
        rateObservation?.invalidate()
        if let timeObserver = timeObserver, let player = player {
            player.avPlayer.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }

    /// 监听 AVPlayer 播放控制状态
    private func observePlayer() {
        guard let player = player else { return }
        timeControlStatusObservation = player.avPlayer.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (avPlayer, _) in
            guard let self = self, let player = self.player else { return }
            DispatchQueue.main.async {
                guard player.avPlayer === avPlayer else { return }
                switch avPlayer.timeControlStatus {
                case .playing:
                    player.setState(.playing)
                case .waitingToPlayAtSpecifiedRate:
                    // 只在本来就在播时报缓冲，seek 与暂停期间系统也会短暂 waiting
                    if player.state == .playing {
                        player.setState(.buffering)
                    }
                case .paused:
                    if player.state == .playing || player.state == .buffering {
                        player.setState(.paused)
                    }
                @unknown default:
                    break
                }
            }
        }
        rateObservation = player.avPlayer.observe(\.rate, options: [.new]) { [weak self] (avPlayer, _) in
            guard let self = self, let player = self.player else { return }
            DispatchQueue.main.async {
                guard player.avPlayer === avPlayer else { return }
                if avPlayer.rate != 0 { player.preferredPlaybackRate = avPlayer.rate }
                player.controlShell?.updateRate(player.rate)
            }
        }
    }

    /// 注册系统通知
    private func registerNotifications() {
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] (notification) in
            guard let self = self, let player = self.player else { return }
            guard (notification.object as? AVPlayerItem) === player.avPlayer.currentItem else { return }
            self.handlePlayToEnd()
        })
        notificationObservers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] (notification) in
            guard let self = self, let player = self.player else { return }
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? AVAudioSession.InterruptionType.began.rawValue
            if rawType == AVAudioSession.InterruptionType.began.rawValue {
                self.wasPlayingBeforeInterruption = (player.state == .playing)
                player.pause()
            }else if self.wasPlayingBeforeInterruption {
                self.wasPlayingBeforeInterruption = false
                let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume) { player.resume() }
            }
        })
        notificationObservers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (_) in
            guard let self = self, let player = self.player else { return }
            if player.configuration.shouldResumeOnAppActive, self.wasPlayingBeforeResignActive {
                player.resume()
            }
        })
        notificationObservers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] (_) in
            guard let self = self, let player = self.player else { return }
            self.wasPlayingBeforeResignActive = false
            if player.configuration.shouldPauseOnAppResignActive && !player.pipManager.isStartingOrActive && !player.isBackgroundPlaybackEnabled {
                self.wasPlayingBeforeResignActive = player.state == .playing
                player.pause()
            }
        })
    }

    /// 进后台前是否在播
    private var wasPlayingBeforeResignActive = false

    /// 周期进度回调
    private func handleProgress(_ time: CMTime) {
        guard let player = player, player.duration > 0 else { return }
        let currentTime = CMTimeGetSeconds(time)
        let duration = player.duration
        let playable = playableDuration(of: player.avPlayer.currentItem)
        player.delegate?.wy_videoPlayer?(player, currentTime: currentTime, duration: duration, playableDuration: playable)
        player.controlShell?.updateProgress(currentTime: currentTime, duration: duration, playableDuration: playable)
        player.subtitleParser.update(time: currentTime)
    }

    /// 已缓冲可以播到的位置
    private func playableDuration(of item: AVPlayerItem?) -> TimeInterval {
        guard let item = item, let value = item.loadedTimeRanges.first else { return 0 }
        let range = value.timeRangeValue
        return CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
    }

    /// 播完一轮(循环判定)
    private func handlePlayToEnd() {
        guard let player = player else { return }
        playedLoopCount += 1
        player.delegate?.wy_videoPlayer?(player, didPlayToEndWithLoopIndex: playedLoopCount)
        if player.playbackOptions.consumeSleepAtEnd() { return }
        if player.configuration.loopCount == 0 || playedLoopCount < player.configuration.loopCount {
            player.seek(to: 0, accurate: false)
            player.resume()
        }else {
            player.setState(.paused)
        }
    }
}
