//
//  WYVideoPlayerObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import AVFoundation
import Foundation
import WYBasisKitSwift

/// 一档清晰度
@objc(WYVideoPlayerMediaQuality)
@objcMembers public class WYVideoPlayerMediaQualityObjC: NSObject {

    /// 展示名，如 标清、高清、1080P
    public var name: String = ""

    /// 该档的播放地址
    public var url: URL

    /// 是否 HLS master 播放列表(是则档位切换交给系统自适应，不按本档地址重载)
    public var isHLSMaster: Bool = false

    /**
     *  建一档清晰度
     *
     *  @param name         展示名
     *  @param url          播放地址
     *  @param isHLSMaster  是否 HLS master 播放列表，默认 false
     *
     */
    public init(name: String, url: URL, isHLSMaster: Bool = false) {
        self.name = name
        self.url = url
        self.isHLSMaster = isHLSMaster
        super.init()
    }

    /**
     *  建一档清晰度
     *
     *  @param name         展示名
     *  @param url          播放地址
     *
     *  @return 新建的清晰度档，isHLSMaster 取 false
     *
     */
    @objc(qualityWithName:URL:)
    public static func quality(_ name: String, url: URL) -> WYVideoPlayerMediaQualityObjC {
        return WYVideoPlayerMediaQualityObjC(name: name, url: url)
    }

    /// 转成结构体清晰度档
    public func toQuality() -> WYVideoPlayerMediaQuality {
        return WYVideoPlayerMediaQuality(name: name, url: url, isHLSMaster: isHLSMaster)
    }
}

/// 一部视频的播放素材(带多档清晰度清单，切换时记住进度无缝续播)
@objc(WYVideoPlayerMediaAsset)
@objcMembers public class WYVideoPlayerMediaAssetObjC: NSObject {

    /// 全部可选清晰度，至少一档
    public var qualities: [WYVideoPlayerMediaQualityObjC] = []

    /// 当前选中的档位下标，从 0 开始
    public private(set) var selectedIndex: Int = 0

    /// 当前档
    public var currentQuality: WYVideoPlayerMediaQualityObjC {
        return qualities[selectedIndex]
    }

    /**
     *  建播放素材
     *
     *  @param qualities       清晰度清单，至少一档
     *  @param defaultIndex    初始档位下标，越界时取 0
     *
     */
    public init(qualities: [WYVideoPlayerMediaQualityObjC], defaultIndex: Int = 0) {
        assert(qualities.isEmpty == false, "qualities 至少要有一档")
        self.qualities = qualities
        self.selectedIndex = qualities.indices.contains(defaultIndex) ? defaultIndex : 0
        super.init()
    }

    /**
     *  用单个地址建单档素材
     *
     *  @param url     播放地址
     *
     *  @return 新建的播放素材，展示名取 原画
     *
     */
    @objc(assetWithURL:)
    public static func asset(url: URL) -> WYVideoPlayerMediaAssetObjC {
        let quality = WYVideoPlayerMediaQualityObjC(name: WYLocalized("原画", table: WYBasisKitConfig.kitLocalizableTable), url: url)
        return WYVideoPlayerMediaAssetObjC(qualities: [quality])
    }

    /**
     *  用多档清晰度建素材
     *
     *  @param qualities       清晰度清单，至少一档
     *  @param defaultIndex    初始档位下标，越界时取 0
     *
     *  @return 新建的播放素材
     *
     */
    @objc(assetWithQualities:defaultIndex:)
    public static func asset(qualities: [WYVideoPlayerMediaQualityObjC], defaultIndex: Int) -> WYVideoPlayerMediaAssetObjC {
        return WYVideoPlayerMediaAssetObjC(qualities: qualities, defaultIndex: defaultIndex)
    }

    /// 转成结构体播放素材
    public func toAsset() -> WYVideoPlayerMediaAsset {
        return WYVideoPlayerMediaAsset(qualities: qualities.map { $0.toQuality() }, defaultIndex: selectedIndex)
    }
}

/// 一条可选字幕轨
@objc(WYVideoPlayerSubtitleTrack)
@objcMembers public class WYVideoPlayerSubtitleTrackObjC: NSObject {

    /// 展示名，如 中文字幕、关闭
    public var name: String = ""

    /// 字幕来源
    public var type: WYVideoPlayerSubtitleTrackType = .externalSRT

    /// 外挂 SRT 的文件地址(来源是内嵌轨时为 nil)
    public var srtURL: URL?

    /// 外挂 SRT 的文本内容(与 srtURL 二选一，都有时优先地址)
    public var srtText: String?

    /**
     *  建一条外挂 SRT 字幕轨
     *
     *  @param name     展示名
     *  @param srtURL   SRT 文件地址
     *
     */
    public init(name: String, srtURL: URL) {
        self.name = name
        self.type = .externalSRT
        self.srtURL = srtURL
        self.srtText = nil
        super.init()
    }

    /**
     *  建一条内联 SRT 文本字幕轨
     *
     *  @param name     展示名
     *  @param srtText  SRT 格式的文本内容
     *
     */
    public init(name: String, srtText: String) {
        self.name = name
        self.type = .externalSRT
        self.srtURL = nil
        self.srtText = srtText
        super.init()
    }

    /**
     *  建一条外挂 SRT 字幕轨
     *
     *  @param name     展示名
     *  @param srtURL   SRT 文件地址
     *
     *  @return 新建的字幕轨
     *
     */
    @objc(trackWithName:srtURL:)
    public static func track(_ name: String, srtURL: URL) -> WYVideoPlayerSubtitleTrackObjC {
        return WYVideoPlayerSubtitleTrackObjC(name: name, srtURL: srtURL)
    }

    /**
     *  建一条内联 SRT 文本字幕轨
     *
     *  @param name     展示名
     *  @param srtText  SRT 格式的文本内容
     *
     *  @return 新建的字幕轨
     *
     */
    @objc(trackWithName:srtText:)
    public static func track(_ name: String, srtText: String) -> WYVideoPlayerSubtitleTrackObjC {
        return WYVideoPlayerSubtitleTrackObjC(name: name, srtText: srtText)
    }

    /// 转成结构体字幕轨
    public func toTrack() -> WYVideoPlayerSubtitleTrack {
        if let srtURL = srtURL {
            return WYVideoPlayerSubtitleTrack(name: name, srtURL: srtURL)
        }
        return WYVideoPlayerSubtitleTrack(name: name, srtText: srtText ?? "")
    }
}

@objc public extension WYVideoPlayer {

    /// 播放配置(实例级，外观与开关全量可配，属性转调播放器持有的同一份配置实例)
    @objc(configuration)
    var configurationObjC: WYVideoPlayerConfigObjC {
        return WYVideoPlayerConfigObjC(configuration: configuration)
    }

    /// 播放代理
    @objc(delegate)
    var delegateObjC: WYVideoPlayerDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }

    /// 当前播放状态
    @objc(state)
    var stateObjC: WYVideoPlayerState {
        return state
    }

    /// 当前播放素材
    @objc(currentAsset)
    var currentAssetObjC: WYVideoPlayerMediaAssetObjC? {
        guard let asset = currentAsset else { return nil }
        return WYVideoPlayerMediaAssetObjC(qualities: asset.qualities.map { WYVideoPlayerMediaQualityObjC(name: $0.name, url: $0.url, isHLSMaster: $0.isHLSMaster) }, defaultIndex: asset.selectedIndex)
    }

    /// 是否处于全屏
    @objc(isFullscreen)
    var isFullscreenObjC: Bool {
        return isFullscreen
    }

    /// 当前倍速(设置即时生效)
    @objc(rate)
    var rateObjC: Float {
        get { return rate }
        set { rate = newValue }
    }

    /// 是否静音
    @objc(isMuted)
    var isMutedObjC: Bool {
        get { return isMuted }
        set { isMuted = newValue }
    }

    /// 当前播放位置，单位为秒
    @objc(playbackTime)
    var playbackTimeObjC: TimeInterval {
        return playbackTime
    }

    /// 视频总时长，单位为秒
    @objc(duration)
    var durationObjC: TimeInterval {
        return duration
    }

    /// 内嵌字幕轨清单(条目装载完成后可取)
    @objc(subtitleTracks)
    var subtitleTracksObjC: [WYVideoPlayerSubtitleTrackObjC] {
        return subtitleTracks.map { track -> WYVideoPlayerSubtitleTrackObjC in
            let trackObjC = WYVideoPlayerSubtitleTrackObjC(name: track.name, srtText: track.srtText ?? "")
            trackObjC.type = track.type
            trackObjC.srtURL = track.srtURL
            return trackObjC
        }
    }

    /// 内置弹幕视图(配置 showsDanmaku 开启时才有，发弹幕走 sendDanmaku:type:)
    @objc(danmakuView)
    var danmakuViewObjC: UIView? {
        return danmakuView
    }

    /**
     *  播放一个地址(单档清晰度)
     *
     *  @param url     视频地址，按配置决定走不走 WYMediaCache 边下边播
     *
     */
    @objc(playWithURL:)
    func playObjC(with url: URL) {
        play(with: url)
    }

    /**
     *  播放带清晰度清单的素材
     *
     *  @param asset   播放素材，多档时壳上出现清晰度按钮可切换
     *
     */
    @objc(playWithAsset:)
    func playObjC(with asset: WYVideoPlayerMediaAssetObjC) {
        play(with: asset.toAsset())
    }

    /// 暂停
    @objc(pauseVideo)
    func pauseObjC() {
        pause()
    }

    /// 继续播放(按当前倍速)
    @objc(resumeVideo)
    func resumeObjC() {
        resume()
    }

    /**
     *  定位到指定位置
     *
     *  @param time        目标位置，单位为秒
     *  @param accurate    true 精确定位(慢一点)，false 关键帧定位(快)
     *
     */
    @objc(seekToTime:accurate:)
    func seekObjC(to time: TimeInterval, accurate: Bool) {
        seek(to: time, accurate: accurate)
    }

    /// 停止播放并释放条目资源
    @objc(stopVideo)
    func stopObjC() {
        stop()
    }

    /**
     *  切换清晰度档位(记住当前进度无缝续播)
     *
     *  @param index    档位下标，从 0 开始
     *
     */
    @objc(selectQualityAtIndex:)
    func selectQualityObjC(at index: Int) {
        selectQuality(at: index)
    }

    /**
     *  选中字幕轨
     *
     *  @param index    轨下标(内嵌轨加外挂轨的合并顺序，-1 关闭字幕)
     *
     */
    @objc(selectSubtitleAtIndex:)
    func selectSubtitleObjC(at index: Int) {
        selectSubtitle(at: index)
    }

    /// 追加一条外挂 SRT 字幕轨(追加后经 selectSubtitle 选中生效)
    @objc(appendSubtitleTrack:)
    func appendSubtitleTrackObjC(_ track: WYVideoPlayerSubtitleTrackObjC) {
        appendSubtitleTrack(track.toTrack())
    }

    /**
     *  发弹幕到内置弹幕视图(内置弹幕开启时有效)
     *
     *  @param text     弹幕文字
     *  @param type     弹幕类型
     *
     */
    @objc(sendDanmaku:type:)
    func sendDanmakuObjC(_ text: String, type: WYDanmakuType) {
        sendDanmaku(text, type: type)
    }

    /// 开始画中画(系统不支持或画面未就绪时无动作)
    @objc(startPictureInPicture)
    func startPictureInPictureObjC() {
        startPictureInPicture()
    }

    /// 停止画中画
    @objc(stopPictureInPicture)
    func stopPictureInPictureObjC() {
        stopPictureInPicture()
    }

    /// 进入全屏(横屏铺满窗口)
    @objc(enterFullscreen)
    func enterFullscreenObjC() {
        enterFullscreen()
    }

    /// 退出全屏(放回原位置)
    @objc(exitFullscreen)
    func exitFullscreenObjC() {
        exitFullscreen()
    }

    /**
     *  截取当前画面
     *
     *  @param completion  截图回调(主线程)，代理 wy_videoPlayer:didTakeSnapshot: 也会收到
     *
     */
    @objc(snapshotWithCompletion:)
    func snapshotObjC(completion: ((_ image: UIImage?) -> Void)?) {
        snapshot(completion: completion)
    }
}
#endif
