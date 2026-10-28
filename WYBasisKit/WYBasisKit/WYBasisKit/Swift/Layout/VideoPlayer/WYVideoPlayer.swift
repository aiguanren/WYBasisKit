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
        didSet {
            if configuration !== oldValue {
                oldValue.preferredRateChanged = nil
                oldValue.shouldMuteByDefaultChanged = nil
                oldValue.usesMediaCacheChanged = nil
                oldValue.showsDanmakuChanged = nil
                oldValue.appearanceChanged = nil
                rate = (0.5...2).contains(configuration.preferredRate) ? configuration.preferredRate : 1
                isMuted = configuration.shouldMuteByDefault
            }
            applyConfiguration()
        }
    }

    /// 播放代理
    public weak var delegate: WYVideoPlayerDelegate?

    /// 底层系统播放器(无缝切清晰度时会整体换成新实例，想长期持有时请每次现取或用 KVO 跟踪)
    public internal(set) var avPlayer = AVPlayer()

    /// 当前播放素材
    public internal(set) var currentAsset: WYVideoPlayerMediaAsset?

    /// 当前播放状态
    public internal(set) var state: WYVideoPlayerState = .idle

    /// 是否处于全屏
    public private(set) var isFullscreen = false

    /// 当前是否可以启动画中画
    public var isPictureInPicturePossible: Bool {
        return configuration.allowsPictureInPicture && pipManager.isPictureInPicturePossible
    }

    /// 当前是否正在画中画播放
    public var isPictureInPictureActive: Bool {
        return pipManager.isPictureInPictureActive
    }

    /// 是否只播放音频，默认 false
    public var isAudioOnly: Bool {
        get { return playbackOptions.isAudioOnly }
        set { playbackOptions.setAudioOnly(newValue) }
    }

    /// 是否允许后台继续播放，宿主需声明 audio 后台模式，默认 false
    public var isBackgroundPlaybackEnabled: Bool {
        get { return playbackOptions.isBackgroundPlaybackEnabled }
        set { playbackOptions.setBackgroundPlayback(newValue) }
    }

    /// 定时关闭的剩余秒数，没有倒计时时返回 0
    public var sleepTimerRemaining: TimeInterval {
        return max(0, playbackOptions.sleepDeadline?.timeIntervalSinceNow ?? 0)
    }

    /// 是否将在本集结束时暂停
    public var sleepsAtVideoEnd: Bool { return playbackOptions.sleepsAtVideoEnd }

    /// 是否正在下载当前视频
    public var isDownloading: Bool { return playbackOptions.isDownloading }

    /// 当前下载进度，范围为 0...1
    public var downloadProgress: Double { return playbackOptions.downloadProgress }

    /// 当前清晰度的完整离线地址，尚未下载完成时返回 nil
    public var offlineFileURL: URL? {
        guard let quality = currentAsset?.currentQuality else { return nil }
        return WYVideoPlayerOfflineDownload.localURL(for: quality.url, isHLS: quality.isHLSMaster)
    }

    /// 当前倍速(设置即时生效)
    public var rate: Float {
        get { return preferredPlaybackRate }
        set {
            preferredPlaybackRate = newValue.isFinite && abs(newValue) >= 0.01 ? newValue : 1
            if #available(iOS 16.0, *) {
                avPlayer.defaultRate = preferredPlaybackRate
            }
            if avPlayer.rate != 0 {
                avPlayer.rate = preferredPlaybackRate
            }
            controlShell?.updateRate(preferredPlaybackRate)
        }
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
        didSet {
            guard (oldValue as AnyObject?) !== (controlShell as AnyObject?) else { return }
            oldValue?.detach()
            reloadControlShell()
        }
    }

    /// 内置弹幕视图(配置 showsDanmaku 开启时才有，宿主可直接发弹幕)
    public internal(set) var danmakuView: WYDanmakuView?

    /// 当前播放位置，单位为秒
    public var playbackTime: TimeInterval {
        return CMTimeGetSeconds(avPlayer.currentTime())
    }

    /// 视频总时长，单位为秒
    public var duration: TimeInterval {
        guard let duration = avPlayer.currentItem?.duration, CMTIME_IS_VALID(duration), duration.seconds.isFinite else { return 0 }
        return duration.seconds
    }

    let playbackOptions = WYVideoPlayerPlaybackOptions()

    var preferredPlaybackRate: Float = 1

    /// 上次应用的默认控制壳开关
    var appliedShowsDefaultShell: Bool?

    /// 已应用的弹幕时钟间隔
    var appliedDanmakuTickInterval: TimeInterval?

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

    /// 视频独立画面层
    private let playbackLayer = AVPlayerLayer()

    /// 壳自动隐藏计时
    var shellAutoHideWorkItem: DispatchWorkItem?

    /// 当前壳在视图树里的引用(换壳时移除用)
    var shellViewInHierarchy: UIView?

    /// 当前选中的字幕轨下标(-1 关闭)
    var selectedSubtitleIndex = -1

    override public init(frame: CGRect) {
        engine = WYVideoPlayerEngine(playerHolder: nil)
        gestureController = WYVideoPlayerGestureController(playerHolder: nil)
        super.init(frame: frame)
        playbackOptions.player = self
        engine.bind(player: self)
        gestureController.bind(player: self)
        layer.insertSublayer(playbackLayer, at: 0)
        playerLayer.player = avPlayer
        configuration.showsDanmakuChanged = { [weak self] in
            self?.setupDanmakuIfNeeded()
        }
        configuration.usesMediaCacheChanged = { [weak self] in
            self?.replacePlaybackItem()
        }
        bindPlaybackConfiguration()
        configuration.appearanceChanged = { [weak self] in
            self?.applyConfiguration()
        }
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

    /// 画面层直取
    var playerLayer: AVPlayerLayer {
        return playbackLayer
    }

    /// 画面层就绪观察(首帧到达/丢失，闪烁定位关键信号)
    var readyForDisplayObservation: NSKeyValueObservation?

    override public func layoutSubviews() {
        super.layoutSubviews()
        if contentRotationAngle != 0 {
            layoutRotatedContent()
            return
        }
        if transform != .identity {
            transform = .identity
        }
        layoutPlaybackLayer()
        subtitleParser.relayout()
        controlShell?.shellView.frame = bounds
        danmakuView?.frame = bounds
    }

    /// 全屏内容旋转角(0 表示内容不旋转，由全屏管理器设置)
    var contentRotationAngle: CGFloat = 0

    /// 壳布局用的安全区(全屏旋转下系统不把安全区跟着 transform 转进视图，手动按旋转方向映射窗口安全区，非全屏直接用系统值)
    var shellSafeAreaInsets: UIEdgeInsets {
        if contentRotationAngle != 0, let window = window {
            let raw = window.safeAreaInsets
            if contentRotationAngle > 0 {
                return UIEdgeInsets(top: raw.right, left: raw.top, bottom: raw.left, right: raw.bottom)
            }else {
                return UIEdgeInsets(top: raw.left, left: raw.bottom, bottom: raw.right, right: raw.top)
            }
        }
        return safeAreaInsets
    }

    /// 全屏内容旋转时内容的横屏尺寸
    var contentRotationSize: CGSize = .zero

    /**
     *  全屏内容旋转(播放器本体保持竖屏铺满窗口，视频层、壳、弹幕与字幕按横屏尺寸整体旋转，退出全屏时传 0)
     *
     *  @param angle        旋转角，单位为弧度
     *  @param contentSize  旋转后的内容尺寸(横屏长宽)
     *
     */
    func setContentRotation(_ angle: CGFloat, contentSize: CGSize) {
        contentRotationAngle = angle
        contentRotationSize = contentSize
        setNeedsLayout()
    }

    /// 旋转态的内容布局(播放器自身旋转成横屏居中，视频层随视图旋转，壳弹幕字幕按横屏铺)
    private func layoutRotatedContent() {
        let size = contentRotationSize
        transform = contentRotationAngle == 0 ? .identity : CGAffineTransform(rotationAngle: contentRotationAngle)
        bounds = CGRect(origin: .zero, size: size)
        layoutPlaybackLayer()
        if let hostBounds = superview?.bounds {
            center = CGPoint(x: hostBounds.midX, y: hostBounds.midY)
        }
        for view in [controlShell?.shellView, danmakuView].compactMap({ $0 }) {
            view.transform = .identity
            view.frame = bounds
        }
        let label = subtitleParser.subtitleLabel
        let textSize = label.sizeThatFits(CGSize(width: size.width - 24, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: 12, y: size.height - 12 - max(textSize.height, 1), width: size.width - 24, height: max(textSize.height, 1))
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
        qualitySwitcher.cancelPending()
        playbackOptions.cancelDownload()
        currentAsset = asset
        // 整段重装载从 0 起播，弹幕先归零定位，避免装载后注入把旧时间拽回触发二次清屏
        danmakuView?.seek(to: 0)
        engine.load(item: buildItem(for: asset.currentQuality.url, isHLS: asset.currentQuality.isHLSMaster))
        refreshMediaInfoToShell()
    }

    /// 暂停
    public func pause() {
        engine.setAutoplayWhenReady(false)
        avPlayer.pause()
        if avPlayer.currentItem?.status == .readyToPlay { setState(.paused) }
    }

    /// 继续播放(按当前倍速)
    public func resume() {
        if state == .idle || state == .stopped {
            return
        }
        engine.setAutoplayWhenReady(true)
        guard avPlayer.currentItem?.status == .readyToPlay else { return }
        if #available(iOS 16.0, *) {
            avPlayer.defaultRate = preferredPlaybackRate
            avPlayer.play()
        } else {
            avPlayer.rate = preferredPlaybackRate
        }
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
        guard time.isFinite, avPlayer.currentItem != nil else { return }
        if avPlayer.currentItem?.status == .unknown {
            engine.seekWhenReady(at: time)
            return
        }
        let target = duration > 0 ? min(max(0, time), duration) : max(0, time)
        let item = avPlayer.currentItem
        setState(.seeking)
        let tolerance = accurate ? CMTime.zero : CMTime(seconds: 0.5, preferredTimescale: 600)
        avPlayer.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] finished in
            DispatchQueue.main.async {
                guard let self = self, self.avPlayer.currentItem === item else { return }
                self.setState(self.avPlayer.timeControlStatus == .playing ? .playing : .paused)
                self.delegate?.wy_videoPlayer?(self, seekDidEndWithFinished: finished)
                if finished { self.danmakuView?.seek(to: target) }
            }
        }
    }

    /// 停止播放并释放条目资源
    public func stop() {
        qualitySwitcher.cancelPending()
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
        fullscreenManager.enterFullscreen(player: self, animated: configuration.animatesFullscreenTransition)
        guard isFullscreen != fullscreenManager.isFullscreen else { return }
        isFullscreen = fullscreenManager.isFullscreen
        controlShell?.updateFullscreen(isFullscreen)
        delegate?.wy_videoPlayer?(self, fullscreenDidChange: isFullscreen)
    }

    /// 退出全屏(放回原位置)
    public func exitFullscreen() {
        guard isFullscreen else { return }
        fullscreenManager.exitFullscreen(player: self, animated: configuration.animatesFullscreenTransition)
        guard isFullscreen != fullscreenManager.isFullscreen else { return }
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
        asset.selectQuality(at: index)
        replacePlaybackItem(with: asset, qualityIndex: index)
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

    /**
     *  发弹幕到内置弹幕视图(内置弹幕开启时有效)
     *
     *  @param text     弹幕文字
     *  @param type     弹幕类型，默认滚动
     *  @param avatar   头像图片，默认 nil 不显示(弹幕配置关闭头像显示时传了也不显示)
     *
     */
    public func sendDanmaku(_ text: String, type: WYDanmakuType = .scroll, avatar: UIImage? = nil) {
        danmakuView?.send(text, type: type, avatar: avatar)
    }

    /// 开始画中画(系统不支持或画面未就绪时无动作)
    public func startPictureInPicture() {
        guard configuration.allowsPictureInPicture else {
            return
        }
        if isAudioOnly { isAudioOnly = false }
        pipManager.startPip(player: self)
    }

    /// 停止画中画
    public func stopPictureInPicture() {
        pipManager.stopPip()
    }

    /**
     *  设置定时关闭，计时结束后暂停播放
     *
     *  @param interval 等待秒数，非正数或非有限值取消定时关闭
     */
    public func setSleepTimer(after interval: TimeInterval) {
        playbackOptions.setSleepTimer(after: interval)
    }

    /// 设置本集结束后暂停并取消已有倒计时
    public func sleepAtVideoEnd() {
        playbackOptions.setSleepTimer(after: nil, atVideoEnd: true)
    }

    /**
     *  下载当前清晰度的点播视频供离线播放
     *
     *  @param completion 下载结束回调，参数依次为完整离线地址和错误，主线程回调
     */
    public func downloadCurrentVideo(completion: ((_ url: URL?, _ error: Error?) -> Void)?) {
        playbackOptions.download(completion: completion)
    }

    /// 取消当前视频下载
    public func cancelVideoDownload() {
        playbackOptions.cancelDownload()
    }

    /// 显示可配置的更多播放功能面板
    public func showMoreControls() {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController {
                guard controller.presentedViewController == nil else { return }
                let panel = WYVideoPlayerMoreController(player: self)
                pauseShellAutoHide()
                controller.present(panel, animated: true)
                return
            }
            responder = current.next
        }
    }

    /// 内置弹幕的高频时钟观察(装配弹幕时建立，卸装时移除)
    var danmakuClockObserver: Any?

}
