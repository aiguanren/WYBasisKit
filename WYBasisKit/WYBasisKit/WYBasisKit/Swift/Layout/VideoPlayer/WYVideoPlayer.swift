//
//  WYVideoPlayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import UIKit

/// 点播播放器(画面层直接是 AVPlayerLayer，边下边播经 WYMediaCache，弹幕字幕全屏画中画手势壳全配齐，透出 avPlayer 供宿主做更多系统操作)
public class WYVideoPlayer: UIView {

    /// 播放配置(实例级，外观与开关全量可配)
    public var configuration = WYVideoPlayerConfig() {
        didSet { applyConfiguration() }
    }

    /// 播放代理
    public weak var delegate: WYVideoPlayerDelegate?

    /// 底层系统播放器(想用系统其他能力时直接拿去用)
    public let avPlayer = AVPlayer()

    /// 当前播放素材
    public private(set) var currentAsset: WYVideoPlayerMediaAsset?

    /// 当前播放状态
    public private(set) var state: WYVideoPlayerState = .idle

    /// 是否处于全屏
    public private(set) var isFullscreen = false

    /// 当前倍速(设置即时生效)
    public var rate: Float {
        get { return avPlayer.rate }
        set { avPlayer.rate = abs(newValue) < 0.01 ? 1.0 : newValue }
    }

    /// 是否静音
    public var isMuted: Bool {
        get { return avPlayer.isMuted }
        set {
            avPlayer.isMuted = newValue
            controlShell?.updateMuted(newValue)
        }
    }

    /// 控制壳(替换成自定义壳时先设这个再装载视频，nil 表示不装任何壳)
    public var controlShell: WYVideoPlayerControlShell? {
        didSet { reloadControlShell() }
    }

    /// 内置弹幕视图(配置 showsDanmaku 开启时才有，宿主可直接发弹幕)
    public private(set) var danmakuView: WYDanmakuView?

    /// 当前播放位置，单位为秒
    public var playbackTime: TimeInterval {
        return CMTimeGetSeconds(avPlayer.currentTime())
    }

    /// 视频总时长，单位为秒
    public var duration: TimeInterval {
        guard let duration = avPlayer.currentItem?.duration, CMTIME_IS_VALID(duration), duration.seconds.isFinite else { return 0 }
        return duration.seconds
    }

    /// 播放内核
    let engine: WYVideoPlayerEngine

    /// 手势控制
    let gestureController: WYVideoPlayerGestureController

    /// 字幕解析与轨管理
    let subtitleParser = WYVideoPlayerSubtitleParser()

    /// 截图器
    let snapshotTaker = WYVideoPlayerSnapshotTaker()

    /// 清晰度切换器
    let qualitySwitcher = WYVideoPlayerQualitySwitcher()

    /// 全屏管理
    let fullscreenManager = WYVideoPlayerFullscreenManager()

    /// 画中画管理
    let pipManager = WYVideoPlayerPipManager()

    /// 壳自动隐藏计时
    private var shellAutoHideWorkItem: DispatchWorkItem?

    /// 当前壳在视图树里的引用(换壳时移除用)
    private var shellViewInHierarchy: UIView?

    /// 当前选中的字幕轨下标(-1 关闭)
    private var selectedSubtitleIndex = -1

    override public init(frame: CGRect) {
        engine = WYVideoPlayerEngine(playerHolder: nil)
        gestureController = WYVideoPlayerGestureController(playerHolder: nil)
        super.init(frame: frame)
        engine.bind(player: self)
        gestureController.bind(player: self)
        backgroundColor = .black
        isExclusiveTouch = true
        setupSubtitleHost()
        setupDanmakuIfNeeded()
        setupDefaultShellIfNeeded()
        setupPipIfNeeded()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    /// 画面层直取
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        subtitleParser.relayout()
        controlShell?.shellView.frame = bounds
        danmakuView?.frame = bounds
    }

    deinit {
        engine.unload()
    }

    /**
     *  播放一个地址(单档清晰度)
     *
     *  @param url     视频地址，按配置决定走不走 WYMediaCache 边下边播
     *
     */
    public func play(with url: URL) {
        play(with: WYVideoPlayerMediaAsset(url: url))
    }

    /**
     *  播放带清晰度清单的素材
     *
     *  @param asset   播放素材，多档时壳上出现清晰度按钮可切换
     *
     */
    public func play(with asset: WYVideoPlayerMediaAsset) {
        currentAsset = asset
        engine.load(item: buildItem(for: asset.currentQuality.url))
        refreshMediaInfoToShell()
    }

    /// 暂停
    public func pause() {
        avPlayer.pause()
    }

    /// 继续播放(按当前倍速)
    public func resume() {
        if state == .idle || state == .stopped {
            return
        }
        avPlayer.play()
        scheduleShellAutoHide()
    }

    /**
     *  定位到指定位置
     *
     *  @param time        目标位置，单位为秒
     *  @param accurate    true 精确定位(慢一点)，false 关键帧定位(快)
     *
     */
    public func seek(to time: TimeInterval, accurate: Bool) {
        setState(.seeking)
        let tolerance = accurate ? CMTime.zero : CMTime(seconds: 0.5, preferredTimescale: 600)
        avPlayer.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] (_) in
            guard let self = self else { return }
            self.setState(self.avPlayer.timeControlStatus == .playing ? .playing : .paused)
            self.delegate?.wy_videoPlayer?(self, seekDidEndWithFinished: true)
            self.danmakuView?.seek(to: time)
        }
    }

    /// 停止播放并释放条目资源
    public func stop() {
        avPlayer.replaceCurrentItem(with: nil)
        currentAsset = nil
        setState(.stopped)
        danmakuView?.clear()
    }

    /**
     *  截取当前画面
     *
     *  @param completion  截图回调(主线程)，代理 wy_videoPlayer(_:didTakeSnapshot:) 也会收到
     *
     */
    public func snapshot(completion: ((_ image: UIImage?) -> Void)?) {
        guard let item = avPlayer.currentItem else {
            completion?(nil)
            return
        }
        snapshotTaker.takeSnapshot(from: item, at: avPlayer.currentTime()) { [weak self] (image) in
            guard let self = self else { return }
            self.delegate?.wy_videoPlayer?(self, didTakeSnapshot: image)
            completion?(image)
        }
    }

    /// 进入全屏(横屏铺满窗口)
    public func enterFullscreen() {
        guard configuration.allowsFullscreenToggle, isFullscreen == false else { return }
        fullscreenManager.enterFullscreen(player: self, animated: true)
        isFullscreen = fullscreenManager.isFullscreen
        controlShell?.updateFullscreen(isFullscreen)
        delegate?.wy_videoPlayer?(self, fullscreenDidChange: isFullscreen)
    }

    /// 退出全屏(放回原位置)
    public func exitFullscreen() {
        guard isFullscreen else { return }
        fullscreenManager.exitFullscreen(player: self, animated: true)
        isFullscreen = fullscreenManager.isFullscreen
        controlShell?.updateFullscreen(isFullscreen)
        delegate?.wy_videoPlayer?(self, fullscreenDidChange: isFullscreen)
    }

    /**
     *  切换清晰度档位(记住当前进度无缝续播)
     *
     *  @param index    档位下标，从 0 开始
     *
     */
    public func selectQuality(at index: Int) {
        guard var asset = currentAsset, qualitySwitcher.needsReload(asset: asset, to: index) else { return }
        let wasPlaying = (state == .playing || state == .buffering)
        let resumeTime = playbackTime
        asset.selectQuality(at: index)
        currentAsset = asset
        engine.seekWhenReady(at: resumeTime)
        if wasPlaying {
            engine.setAutoplayWhenReady()
        }
        engine.load(item: buildItem(for: asset.qualities[index].url))
        refreshMediaInfoToShell()
        delegate?.wy_videoPlayer?(self, qualityDidChangeAtIndex: index)
    }

    /**
     *  选中字幕轨
     *
     *  @param index    轨下标(内嵌轨加外挂轨的合并顺序，-1 关闭字幕)
     *
     */
    public func selectSubtitle(at index: Int) {
        selectedSubtitleIndex = index
        subtitleParser.selectTrack(at: index, item: avPlayer.currentItem)
        refreshMediaInfoToShell()
        delegate?.wy_videoPlayer?(self, subtitleDidChangeAtIndex: index)
    }

    /// 追加一条外挂 SRT 字幕轨(追加后经 selectSubtitle 选中生效)
    public func appendSubtitleTrack(_ track: WYVideoPlayerSubtitleTrack) {
        subtitleParser.appendExternalTrack(track)
        refreshMediaInfoToShell()
    }

    /// 内嵌字幕轨清单(条目装载完成后可取)
    public var subtitleTracks: [WYVideoPlayerSubtitleTrack] {
        return subtitleParser.tracks
    }

    /// 发弹幕到内置弹幕视图(内置弹幕开启时有效)
    public func sendDanmaku(_ text: String, type: WYDanmakuType = .scroll) {
        danmakuView?.send(text, type: type)
    }

    /// 开始画中画(系统不支持或画面未就绪时无动作)
    public func startPictureInPicture() {
        guard configuration.allowsPictureInPicture else { return }
        pipManager.startPip(player: self)
    }

    /// 停止画中画
    public func stopPictureInPicture() {
        pipManager.stopPip()
    }

    /// 状态推进(内核与内部操作调用，同步壳与代理)
    func setState(_ newState: WYVideoPlayerState) {
        guard state != newState else { return }
        state = newState
        controlShell?.updateState(newState)
        delegate?.wy_videoPlayer?(self, stateDidChange: newState)
    }

    /// 按配置构造条目(走不走 WYMediaCache 在这里分叉)
    private func buildItem(for url: URL) -> AVPlayerItem {
        if configuration.usesMediaCache {
            return WYMediaCache.shared.playerItem(with: url)
        }
        return AVPlayerItem(url: url)
    }

    /// 配置变化时重刷外观相关部件
    private func applyConfiguration() {
        subtitleParser.applyConfiguration(configuration)
        setupDanmakuIfNeeded()
        setupDefaultShellIfNeeded()
        controlShell?.updateRate(rate)
        controlShell?.updateMuted(isMuted)
        refreshMediaInfoToShell()
    }

    /// 字幕标签挂载
    private func setupSubtitleHost() {
        subtitleParser.attach(to: self)
    }

    /// 按配置装配内置弹幕
    private func setupDanmakuIfNeeded() {
        if configuration.showsDanmaku, danmakuView == nil {
            let danmakuView = WYDanmakuView()
            danmakuView.configuration = configuration.danmakuConfiguration
            addSubview(danmakuView)
            self.danmakuView = danmakuView
            danmakuView.frame = bounds
        }else if configuration.showsDanmaku == false, danmakuView != nil {
            danmakuView?.removeFromSuperview()
            self.danmakuView = nil
        }
    }

    /// 没设过壳时按配置装默认壳
    private func setupDefaultShellIfNeeded() {
        guard controlShell == nil else { return }
        if configuration.showsDefaultShell {
            let shell = WYVideoPlayerDefaultShell()
            controlShell = shell
        }
    }

    /// 重装壳(替换或清空时把旧壳视图摘掉)
    private func reloadControlShell() {
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

    /// 画中画装配
    private func setupPipIfNeeded() {
        guard configuration.allowsPictureInPicture else { return }
        pipManager.setup(playerLayer: playerLayer) { [weak self] (isActive) in
            guard let self = self else { return }
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
        guard let shell = controlShell else { return }
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
            guard let self = self, self.state == .playing else { return }
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
