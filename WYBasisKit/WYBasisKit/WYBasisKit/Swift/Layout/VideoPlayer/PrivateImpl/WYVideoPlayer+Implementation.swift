//
//  WYVideoPlayer+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import AVFoundation
import UIKit

/// 播放器的状态、控制壳与字幕弹幕装配
extension WYVideoPlayer {

    /// 保留当前画面和进度切换播放条目
    func replacePlaybackItem(with replacementAsset: WYVideoPlayerMediaAsset? = nil, qualityIndex: Int? = nil) {
        guard let asset = replacementAsset ?? currentAsset else { return }
        let newItem = buildItem(for: asset.currentQuality.url, isHLS: asset.currentQuality.isHLSMaster)
        let resumeTime = playbackTime
        let switchRate = rate
        // 无缝换档：旧播放器保持播放，新档静音备流真出帧后原子换主重绑，全程两路活视频不出现黑帧
        qualitySwitcher.startTransition(from: avPlayer, item: newItem, resumeTime: resumeTime, rate: switchRate, preroll: configuration.qualitySwitchPrerollSeconds, hostLayer: playerLayer, timeout: configuration.qualitySwitchTimeout, failure: { [weak self] error in
            guard let self = self else { return }
            self.delegate?.wy_videoPlayer?(self, didFailWithError: error)
        }) { [weak self] (newPlayer) in
            guard let self = self else { return }
            let oldPlayer = self.avPlayer
            if let observer = self.danmakuClockObserver {
                oldPlayer.removeTimeObserver(observer)
                self.danmakuClockObserver = nil
            }
            self.currentAsset = asset
            self.avPlayer = newPlayer
            if #available(iOS 16.0, *) { newPlayer.defaultRate = self.preferredPlaybackRate }
            newPlayer.isMuted = oldPlayer.isMuted
            if self.state != .playing && self.state != .buffering {
                newPlayer.pause()
            } else {
                newPlayer.rate = self.preferredPlaybackRate
            }
            // 先静音停旧再换画面层归属，画面层一次切换不再伴随旧流音频与渲染残留
            oldPlayer.pause()
            self.playerLayer.player = newPlayer
            self.engine.adoptAVPlayer(item: newItem, replacing: oldPlayer)
            self.playbackOptions.applyVideoTracks()
            if self.danmakuView != nil {
                self.danmakuClockObserver = newPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: self.configuration.danmakuTickInterval, preferredTimescale: 600), queue: .main) { [weak self] (time) in
                    self?.danmakuView?.play(at: CMTimeGetSeconds(time))
                }
            }
            oldPlayer.pause()
            oldPlayer.replaceCurrentItem(with: nil)
            self.refreshMediaInfoToShell()
            if let qualityIndex = qualityIndex {
                self.delegate?.wy_videoPlayer?(self, qualityDidChangeAtIndex: qualityIndex)
            }
        }
    }

    /// 状态推进(内核与内部操作调用，同步壳与代理)
    func setState(_ newState: WYVideoPlayerState) {
        guard state != newState else { return }
        state = newState
        engine.handleLoadingState(newState)
        controlShell?.updateState(newState)
        delegate?.wy_videoPlayer?(self, stateDidChange: newState)
    }

    /// 按配置构造条目(走不走 WYMediaCache 在这里分叉)
    func buildItem(for url: URL, isHLS: Bool = false) -> AVPlayerItem {
        if let localURL = WYVideoPlayerOfflineDownload.localURL(for: url, isHLS: isHLS) { return AVPlayerItem(url: localURL) }
        if configuration.usesMediaCache && !isHLS && url.pathExtension.lowercased() != "m3u8" {
            return WYMediaCache.shared.playerItem(with: url)
        }
        return AVPlayerItem(url: url)
    }

    /// 将播放默认值变化绑定到实例，保留宿主直接设置倍速和静音的能力
    func bindPlaybackConfiguration() {
        configuration.preferredRateChanged = { [weak self] in
            guard let self = self else { return }
            self.rate = (0.5...2).contains(self.configuration.preferredRate) ? self.configuration.preferredRate : 1
        }
        configuration.shouldMuteByDefaultChanged = { [weak self] in
            guard let self = self else { return }
            self.isMuted = self.configuration.shouldMuteByDefault
        }
    }

    /// 配置变化时重刷外观相关部件
    func applyConfiguration() {
        bindPlaybackConfiguration()
        configuration.appearanceChanged = { [weak self] in
            self?.applyConfiguration()
        }
        configuration.usesMediaCacheChanged = { [weak self] in
            self?.replacePlaybackItem()
        }
        configuration.showsDanmakuChanged = { [weak self] in
            self?.setupDanmakuIfNeeded()
        }
        engine.refreshProgressObservation()
        if state == .preparing || state == .readyToPlay || state == .buffering { engine.handleLoadingState(state) }
        avPlayer.allowsExternalPlayback = configuration.allowsAirPlay
        setupPipIfNeeded()
        subtitleParser.applyConfiguration(configuration)
        setupDanmakuIfNeeded()
        setupDefaultShellIfNeeded()
        controlShell?.updateRate(rate)
        controlShell?.updateMuted(isMuted)
        refreshMediaInfoToShell()
    }

    /// 字幕标签挂载
    func setupSubtitleHost() {
        subtitleParser.attach(to: self)
    }

    /// 观察画面层首帧就绪(装载/换主后调，闪烁定位)
    func observeReadyForDisplay() {
        readyForDisplayObservation?.invalidate()
        let item = avPlayer.currentItem
        readyForDisplayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] (layer, _) in
            DispatchQueue.main.async {
                guard let self = self, layer.isReadyForDisplay, layer.player?.currentItem === item, item?.status == .readyToPlay else { return }
                self.engine.cancelLoadingTimeout()
                self.controlShell?.updateState(self.state)
            }
        }
    }

    /// 按配置装配内置弹幕
    func setupDanmakuIfNeeded() {
        if let danmakuView = danmakuView {
            danmakuView.configuration = configuration.danmakuConfiguration
            if appliedDanmakuTickInterval != configuration.danmakuTickInterval {
                if let observer = danmakuClockObserver { avPlayer.removeTimeObserver(observer) }
                danmakuClockObserver = nil
                appliedDanmakuTickInterval = configuration.danmakuTickInterval
                let interval = configuration.danmakuTickInterval.isFinite && configuration.danmakuTickInterval > 0 ? configuration.danmakuTickInterval : 1 / Double((self.window?.windowScene?.screen ?? UIScreen.main).maximumFramesPerSecond)
                danmakuClockObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: interval, preferredTimescale: 600), queue: .main) { [weak self] time in
                    self?.danmakuView?.play(at: CMTimeGetSeconds(time))
                }
            }
        }
        if configuration.showsDanmaku, danmakuView == nil {
            let danmakuView = WYDanmakuView()
            danmakuView.configuration = configuration.danmakuConfiguration
            addSubview(danmakuView)
            self.danmakuView = danmakuView
            danmakuView.frame = bounds
            // 弹幕时钟注入走独立高频观察，进度回调间隔太粗会让弹幕一跳一跳
            // 建视图当场先对齐一次当前播放时间，堵住"弹幕引擎时间还在 0、首条弹幕从 0 秒起算再被注入拽回"的窗口
            danmakuView.play(at: playbackTime)
            appliedDanmakuTickInterval = configuration.danmakuTickInterval
            let interval = configuration.danmakuTickInterval.isFinite && configuration.danmakuTickInterval > 0 ? configuration.danmakuTickInterval : 1 / Double((self.window?.windowScene?.screen ?? UIScreen.main).maximumFramesPerSecond)
            danmakuClockObserver = avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: interval, preferredTimescale: 600), queue: .main) { [weak self] (time) in
                self?.danmakuView?.play(at: CMTimeGetSeconds(time))
            }
        }else if configuration.showsDanmaku == false, danmakuView != nil {
            if let observer = danmakuClockObserver {
                avPlayer.removeTimeObserver(observer)
                danmakuClockObserver = nil
            }
            danmakuView?.removeFromSuperview()
            self.danmakuView = nil
        }
    }

    /// 没设过壳时按配置装默认壳
    func setupDefaultShellIfNeeded() {
        let showsDefaultShell = configuration.showsDefaultShell
        defer { appliedShowsDefaultShell = showsDefaultShell }
        if !showsDefaultShell {
            if controlShell is WYVideoPlayerDefaultShell { controlShell = nil }
            return
        }
        guard controlShell == nil, appliedShowsDefaultShell != true else { return }
        if showsDefaultShell {
            let shell = WYVideoPlayerDefaultShell()
            controlShell = shell
        }
    }

    /// 重装壳(替换或清空时把旧壳视图摘掉)
    func reloadControlShell() {
        if let oldShellView = shellViewInHierarchy {
            oldShellView.removeFromSuperview()
        }
        shellViewInHierarchy = nil
        if let shell = controlShell {
            shell.shellView.frame = bounds
            addSubview(shell.shellView)
            bringSubviewToFront(shell.shellView)
            shell.attach(to: self)
            shellViewInHierarchy = shell.shellView
        }
    }

    /// 同步视频画面层尺寸
    func layoutPlaybackLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }

    /// 画中画装配
    func setupPipIfNeeded() {
        guard configuration.allowsPictureInPicture else {
            pipManager.disable()
            return
        }
        pipManager.setup(playerLayer: playerLayer) { [weak self] (isActive) in
            guard let self = self else { return }
            if isActive {
                self.pauseShellAutoHide()
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.playerLayer.transform = CATransform3DIdentity
                self.playerLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                self.playerLayer.bounds = CGRect(origin: .zero, size: self.bounds.size)
                CATransaction.commit()
                self.superview?.layoutIfNeeded()
                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.controlShell?.updateFullscreen(self.isFullscreen)
                self.controlShell?.showShell(animated: false)
                self.scheduleShellAutoHide()
            }
            self.delegate?.wy_videoPlayer?(self, pipDidChangeWithPlaying: isActive)
        }
    }

    /// 刷新壳的清晰度与字幕信息
    func refreshMediaInfoToShell() {
        let qualityNames = currentAsset?.qualities.map { $0.name } ?? []
        let qualityIndex = currentAsset?.selectedIndex ?? -1
        controlShell?.updateMediaInfo(qualityNames: qualityNames, selectedQualityIndex: qualityIndex, subtitleNames: subtitleParser.trackNames, selectedSubtitleIndex: selectedSubtitleIndex)
    }

    /// 切换壳显隐(单击默认行为)
    func toggleShellVisibility() {
        guard let shell = controlShell else {
            return
        }
        if shell.isShellVisible {
            shell.hideShell(animated: true)
        }else {
            shell.showShell(animated: true)
        }
        scheduleShellAutoHide()
    }

    /// 重新计时壳自动隐藏
    func scheduleShellAutoHide() {
        pauseShellAutoHide()
        let interval = configuration.shellAutoHideInterval
        guard interval > 0 else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.state == .playing else {
                return
            }
            self.controlShell?.hideShell(animated: true)
        }
        shellAutoHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    /// 暂停壳自动隐藏计时(手势或拖进度期间调)
    func pauseShellAutoHide() {
        shellAutoHideWorkItem?.cancel()
        shellAutoHideWorkItem = nil
    }

    /// 恢复壳自动隐藏计时
    func resumeShellAutoHide() {
        scheduleShellAutoHide()
    }

    /// 手势预览转发给壳
    func showSeekPreview(targetTime: TimeInterval, delta: TimeInterval) {
        controlShell?.showSeekPreview(targetTime: targetTime, delta: delta)
    }

    /// 手势预览转发给壳
    func hideSeekPreview() {
        controlShell?.hideSeekPreview()
    }

    /// 手势提示转发给壳
    func showRatePrompt(rate: Float) {
        controlShell?.showRatePrompt(rate: rate)
    }

    /// 手势提示转发给壳
    func hideRatePrompt() {
        controlShell?.hideRatePrompt()
    }

    /// 手势指示转发给壳
    func showPanIndicator(isVolume: Bool, value: Float) {
        controlShell?.showPanIndicator(isVolume: isVolume, value: value)
    }

    /// 手势指示转发给壳
    func hidePanIndicator() {
        controlShell?.hidePanIndicator()
    }
}
