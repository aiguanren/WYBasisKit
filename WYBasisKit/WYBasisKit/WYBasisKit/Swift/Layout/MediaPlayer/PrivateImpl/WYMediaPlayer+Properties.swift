//
//  WYMediaPlayer+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit
import AVKit
import CoreImage

#if canImport(IJKPlayerKit)
import IJKPlayerKit
#endif

#if canImport(IJKPlayerKit)

/// WYMediaPlayer 私有实现，私有属性集中管理
extension WYMediaPlayer {

    var pictureInPictureState: WYMediaPlayerPictureInPictureState? {
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.pictureInPictureState) as? WYMediaPlayerPictureInPictureState }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.pictureInPictureState, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 当前已重试失败次数
    var failReplayNumber: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.failReplayNumber, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.failReplayNumber) as? Int ?? 0 }
    }

    /// 本次加载完成后要不要自动播放(play(with:)看shouldAutoplay、prepare(with:)固定为false)
    var loadAutoplayIntent: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadAutoplayIntent) as? Bool ?? true }
    }

    /// 加载代号(每次load加1，延迟执行的失败重试回来时先核对它，发现变了说明期间发起了新加载，放弃本次重试，防止迟到的重试覆盖新加载)
    var loadGeneration: Int {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.loadGeneration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.loadGeneration) as? Int ?? 0 }
    }

    /// 当前实例是否已prepare完成(供play()判断能否立即起播)
    var isPreparedToPlay: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPreparedToPlay) as? Bool ?? false }
    }

    /// 挂起的播放请求(play()在prepare完成前被调用时先记true，等prepare完成回调再补执行，pause()与releaseAll会取消)
    var isPlayPending: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPlayPending, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPlayPending) as? Bool ?? false }
    }

    /// prepare期间收到的暂停请求，prepare完成时内核会自动起播，由完成回调补一次pause把它压住
    var isPausedWhilePreparing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPausedWhilePreparing) as? Bool ?? false }
    }

    /// 本次加载是否已渲染出第一帧(供海报截取判断)
    var hasRenderedFirstFrame: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasRenderedFirstFrame) as? Bool ?? false }
    }

    /// 是否正处于海报(首帧)探测中(预加载不自动播时底层不渲染第一帧、首帧通知也不来，探测即先静音播放，等第一帧画面出来立刻暂停回到准备好状态，全程靠这个标记收尾)
    var isPosterProbing: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isPosterProbing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.isPosterProbing) as? Bool ?? false }
    }

    /// 本次加载是否真正播放过，没真正播过的实例收到.paused只记状态不通知调用方(这类暂停只是初始化或收尾的内部动作，不是用户暂停)
    var hasReallyPlayed: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.hasReallyPlayed) as? Bool ?? false }
    }

    /// 用户设置的音量(0~1)，实际下发音量统一走applyVolume
    var userVolume: Float {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.userVolume, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.userVolume) as? Float ?? 1 }
    }

    /// 当前使用的URL打开转发代理(第一次用到才创建并绑定self，四个闭包全空时不会挂到player上)
    var urlOpenProxy: WYMediaUrlOpenProxy {
        if let proxy = objc_getAssociatedObject(self, &WYAssociatedKeys.urlOpenProxy) as? WYMediaUrlOpenProxy {
            return proxy
        }
        let proxy = WYMediaUrlOpenProxy()
        proxy.target = self
        objc_setAssociatedObject(self, &WYAssociatedKeys.urlOpenProxy, proxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return proxy
    }
    func preparePictureInPictureController() -> AVPictureInPictureController? {
        guard AVPictureInPictureController.isPictureInPictureSupported(), let renderer = ijkPlayer?.view else { return nil }
        if let pictureInPictureState = pictureInPictureState { return pictureInPictureState.controller }
        let state = WYMediaPlayerPictureInPictureState(player: self, renderer: renderer)
        pictureInPictureState = state
        return state.controller
    }
}

/// 私有属性的关联对象键
private struct WYAssociatedKeys {
    static var pictureInPictureState: UInt8 = 0
    static var failReplayNumber: UInt8 = 0
    static var loadAutoplayIntent: UInt8 = 0
    static var loadGeneration: UInt8 = 0
    static var isPreparedToPlay: UInt8 = 0
    static var isPlayPending: UInt8 = 0
    static var isPausedWhilePreparing: UInt8 = 0
    static var hasRenderedFirstFrame: UInt8 = 0
    static var isPosterProbing: UInt8 = 0
    static var hasReallyPlayed: UInt8 = 0
    static var userVolume: UInt8 = 0
    static var urlOpenProxy: UInt8 = 0
}

/// 旧播放器的视频帧画中画接入
final class WYMediaPlayerPictureInPictureState: NSObject, IJKVideoRenderingDelegate, AVPictureInPictureSampleBufferPlaybackDelegate {

    private(set) var controller: AVPictureInPictureController?
    var forwardDelegate: IJKVideoRenderingDelegate? {
        get { frameLock.lock(); defer { frameLock.unlock() }; return storedDelegate }
        set { frameLock.lock(); storedDelegate = newValue; frameLock.unlock() }
    }

    init(player: WYMediaPlayer, renderer: UIView & IJKVideoRenderingProtocol) {
        self.player = player
        self.renderer = renderer
        super.init()
        forwardDelegate = renderer.displayDelegate
        renderer.displayDelegate = self
        displayLayer.frame = player.bounds
        player.layer.insertSublayer(displayLayer, at: 0)
        if #available(iOS 27.0, *) {
            sampleReceiverState = WYMediaPlayerSampleBufferReceiver(displayLayer: displayLayer)
        }else {
            var timebase: CMTimebase?
            if CMTimebaseCreateWithSourceClock(allocator: kCFAllocatorDefault, sourceClock: CMClockGetHostTimeClock(), timebaseOut: &timebase) == noErr {
                displayLayer.controlTimebase = timebase
            }
        }
        let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: displayLayer, playbackDelegate: self)
        controller = AVPictureInPictureController(contentSource: source)
        controller?.canStartPictureInPictureAutomaticallyFromInline = false
        for name in [Notification.Name.IJKPlayerDidSeekComplete, .IJKPlayerAccurateSeekComplete, .IJKPlayerDidFinish] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: player.ijkPlayer, queue: .main) { [weak self] _ in self?.completeSkip() })
        }
    }

    func detach() {
        completeSkip()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        controller?.stopPictureInPicture()
        controller?.contentSource = nil
        controller = nil
        if renderer?.displayDelegate === self { renderer?.displayDelegate = forwardDelegate }
        renderer = nil
        frameLock.lock()
        pendingFrame = nil
        frameLock.unlock()
        if #available(iOS 27.0, *), let receiver = sampleReceiverState as? WYMediaPlayerSampleBufferReceiver { receiver.detach() }
        sampleReceiverState = nil
        displayLayer.removeFromSuperlayer()
    }

    func videoRenderingWillDisplay(_ renderer: IJKVideoRenderingProtocol, videoFrame: CVPixelBuffer) -> Unmanaged<CVPixelBuffer>? {
        let replacement: Unmanaged<CVPixelBuffer>?
        if let delegate = forwardDelegate, delegate.responds(to: #selector(IJKVideoRenderingDelegate.videoRenderingWillDisplay(_:videoFrame:))) {
            replacement = delegate.videoRenderingWillDisplay?(renderer, videoFrame: videoFrame)
        }else {
            replacement = Unmanaged.passUnretained(videoFrame)
        }
        guard let frame = replacement?.takeUnretainedValue() else { return nil }
        frameLock.lock()
        pendingFrame = frame
        let schedule = !frameScheduled
        frameScheduled = true
        frameLock.unlock()
        if schedule {
            DispatchQueue.main.async { [weak self] in self?.displayPendingFrame() }
        }
        return replacement
    }

    func videoRenderingDidDisplay(_ renderer: IJKVideoRenderingProtocol, attach: IJKOverlayAttach) {
        forwardDelegate?.videoRenderingDidDisplay?(renderer, attach: attach)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if playing { player?.play() } else { player?.pause() }
        syncPlaybackState()
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        guard let player = player, player.ijkPlayer != nil else { return .invalid }
        let duration = player.videoDuration()
        return CMTimeRange(start: .zero, duration: duration.isFinite && duration > 0 ? CMTime(seconds: duration, preferredTimescale: 600) : .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return player?.isPlaying() != true
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion: @escaping () -> Void) {
        completeSkip()
        guard let player = player, player.isPreparedToPlay, skipInterval.seconds.isFinite else { completion(); return }
        let duration = player.videoDuration()
        guard duration.isFinite, duration > 0 else { completion(); return }
        pendingSkip = completion
        player.playbackTime(min(duration, max(0, player.currentPlaybackTime + skipInterval.seconds)))
    }

    func syncPlaybackState() {
        guard let player = player else { return }
        let position = player.currentPlaybackTime
        guard position.isFinite else { return }
        if #available(iOS 27.0, *), let receiver = sampleReceiverState as? WYMediaPlayerSampleBufferReceiver {
            receiver.synchronizer.setRate(player.isPlaying() ? Float(player.currentPlaybackRate) : 0, time: CMTime(seconds: position, preferredTimescale: 600))
            return
        }
        guard let timebase = displayLayer.controlTimebase else { return }
        CMTimebaseSetTime(timebase, time: CMTime(seconds: position, preferredTimescale: 600))
        CMTimebaseSetRate(timebase, rate: player.isPlaying() ? Float64(player.currentPlaybackRate) : 0)
    }

    private weak var player: WYMediaPlayer?
    private weak var renderer: (UIView & IJKVideoRenderingProtocol)?
    private weak var storedDelegate: IJKVideoRenderingDelegate?
    private let displayLayer = AVSampleBufferDisplayLayer()
    private var sampleReceiverState: AnyObject?
    private let frameLock = NSLock()
    private var pendingFrame: CVPixelBuffer?
    private var frameScheduled = false
    private var lastPosition: TimeInterval = 0
    private let imageContext = CIContext(options: [.cacheIntermediates: false])
    private var pixelPool: CVPixelBufferPool?
    private var pixelSize = CGSize.zero
    private var pixelFormat: OSType = 0
    private var observers: [NSObjectProtocol] = []
    private var pendingSkip: (() -> Void)?

    private func completeSkip() {
        guard let completion = pendingSkip else { return }
        pendingSkip = nil
        syncPlaybackState()
        controller?.invalidatePlaybackState()
        completion()
    }

    private func pictureFrame(from frame: CVPixelBuffer) -> CVPixelBuffer? {
        let format = CVPixelBufferGetPixelFormatType(frame)
        if [kCVPixelFormatType_32BGRA, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange].contains(format), CVPixelBufferGetIOSurface(frame) != nil { return frame }
        let planar = format == kCVPixelFormatType_420YpCbCr8Planar || format == kCVPixelFormatType_420YpCbCr8PlanarFullRange
        let outputFormat = planar ? (format == kCVPixelFormatType_420YpCbCr8PlanarFullRange ? kCVPixelFormatType_420YpCbCr8BiPlanarFullRange : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) : kCVPixelFormatType_32BGRA
        let size = CGSize(width: CVPixelBufferGetWidth(frame), height: CVPixelBufferGetHeight(frame))
        if pixelPool == nil || size != pixelSize || pixelFormat != outputFormat {
            pixelPool = nil
            let attributes: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: outputFormat,
                                             kCVPixelBufferWidthKey as String: Int(size.width),
                                             kCVPixelBufferHeightKey as String: Int(size.height),
                                             kCVPixelBufferIOSurfacePropertiesKey as String: [:],
                                             kCVPixelBufferMetalCompatibilityKey as String: true]
            guard CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pixelPool) == kCVReturnSuccess else { return nil }
            pixelSize = size
            pixelFormat = outputFormat
        }
        guard let pool = pixelPool else { return nil }
        var output: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &output) == kCVReturnSuccess, let output = output else { return nil }
        if planar {
            guard copyPlanarFrame(frame, to: output) else { return nil }
        }else {
            let image = CIImage(cvPixelBuffer: frame)
            guard !image.extent.isEmpty else { return nil }
            imageContext.render(image, to: output)
        }
        CVBufferPropagateAttachments(frame, output)
        return output
    }

    private func copyPlanarFrame(_ frame: CVPixelBuffer, to output: CVPixelBuffer) -> Bool {
        guard CVPixelBufferGetPlaneCount(frame) == 3, CVPixelBufferGetPlaneCount(output) == 2,
              CVPixelBufferLockBaseAddress(frame, .readOnly) == kCVReturnSuccess else { return false }
        defer { CVPixelBufferUnlockBaseAddress(frame, .readOnly) }
        guard CVPixelBufferLockBaseAddress(output, []) == kCVReturnSuccess else { return false }
        defer { CVPixelBufferUnlockBaseAddress(output, []) }
        guard let sourceY = CVPixelBufferGetBaseAddressOfPlane(frame, 0),
              let sourceU = CVPixelBufferGetBaseAddressOfPlane(frame, 1)?.assumingMemoryBound(to: UInt8.self),
              let sourceV = CVPixelBufferGetBaseAddressOfPlane(frame, 2)?.assumingMemoryBound(to: UInt8.self),
              let targetY = CVPixelBufferGetBaseAddressOfPlane(output, 0),
              let targetUV = CVPixelBufferGetBaseAddressOfPlane(output, 1)?.assumingMemoryBound(to: UInt8.self) else { return false }
        let width = min(CVPixelBufferGetWidthOfPlane(frame, 0), CVPixelBufferGetWidthOfPlane(output, 0))
        let height = min(CVPixelBufferGetHeightOfPlane(frame, 0), CVPixelBufferGetHeightOfPlane(output, 0))
        for row in 0..<height {
            memcpy(targetY.advanced(by: row * CVPixelBufferGetBytesPerRowOfPlane(output, 0)), sourceY.advanced(by: row * CVPixelBufferGetBytesPerRowOfPlane(frame, 0)), width)
        }
        let chromaWidth = min(CVPixelBufferGetWidthOfPlane(frame, 1), CVPixelBufferGetWidthOfPlane(frame, 2), CVPixelBufferGetWidthOfPlane(output, 1))
        let chromaHeight = min(CVPixelBufferGetHeightOfPlane(frame, 1), CVPixelBufferGetHeightOfPlane(frame, 2), CVPixelBufferGetHeightOfPlane(output, 1))
        for row in 0..<chromaHeight {
            let u = sourceU.advanced(by: row * CVPixelBufferGetBytesPerRowOfPlane(frame, 1))
            let v = sourceV.advanced(by: row * CVPixelBufferGetBytesPerRowOfPlane(frame, 2))
            let uv = targetUV.advanced(by: row * CVPixelBufferGetBytesPerRowOfPlane(output, 1))
            for column in 0..<chromaWidth { uv[column * 2] = u[column]; uv[column * 2 + 1] = v[column] }
        }
        return true
    }

    private func displayPendingFrame() {
        frameLock.lock()
        let frame = pendingFrame
        pendingFrame = nil
        frameScheduled = false
        frameLock.unlock()
        guard let input = frame, let player = player, renderer != nil, controller != nil, let frame = pictureFrame(from: input) else { return }
        displayLayer.frame = player.bounds
        let position = player.currentPlaybackTime
        guard position.isFinite else { return }
        if abs(position - lastPosition) > 1 {
            if #available(iOS 27.0, *), let receiver = sampleReceiverState as? WYMediaPlayerSampleBufferReceiver { receiver.flush() } else if #available(iOS 17.0, *) { displayLayer.sampleBufferRenderer.flush() } else { displayLayer.flush() }
        }
        lastPosition = position
        syncPlaybackState()
        var description: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: frame, formatDescriptionOut: &description) == noErr, let description = description else { return }
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: CMTime(seconds: position, preferredTimescale: 600), decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: frame, formatDescription: description, sampleTiming: &timing, sampleBufferOut: &sample) == noErr, let sample = sample else { return }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        if #available(iOS 27.0, *), let receiver = sampleReceiverState as? WYMediaPlayerSampleBufferReceiver {
            receiver.enqueue(sample)
        }else if #available(iOS 17.0, *) {
            let renderer = displayLayer.sampleBufferRenderer
            if renderer.status == .failed { renderer.flush() }
            if renderer.isReadyForMoreMediaData { renderer.enqueue(sample) }
        }else {
            if displayLayer.status == .failed { displayLayer.flush() }
            if displayLayer.isReadyForMoreMediaData { displayLayer.enqueue(sample) }
        }
        controller?.invalidatePlaybackState()
    }
}

/// 视频帧接收与播放时钟
@available(iOS 27.0, *)
private final class WYMediaPlayerSampleBufferReceiver {

    let synchronizer = AVSampleBufferRenderSynchronizer()

    init(displayLayer: AVSampleBufferDisplayLayer) {
        synchronizer.delaysRateChangeUntilHasSufficientMediaData = false
        receiver = synchronizer.sampleBufferReceiver(adding: displayLayer.sampleBufferRenderer)
    }

    func enqueue(_ sample: CMSampleBuffer) {
        guard let receiver = receiver else { return }
        let ready = CMReadySampleBuffer<CMSampleBuffer.DynamicContent>(CMReadySampleBuffer<CVReadOnlyPixelBuffer>(unsafeWithPixelBuffer: sample))
        switch receiver.enqueueImmediately(ready) {
        case .cancelledDueToFlushRequiredToResume:
            receiver.flush()
            _ = receiver.enqueueImmediately(ready)
        default: break
        }
    }

    func flush() { receiver?.flush() }

    func detach() {
        guard let receiver = receiver else { return }
        self.receiver = nil
        receiver.flush()
        let synchronizer = synchronizer
        Task { @MainActor in _ = await synchronizer.removeReceiver(receiver, at: .invalid) }
    }

    private var receiver: AVSampleBufferVideoRenderer.Receiver?
}

#endif
