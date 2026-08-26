//
//  WYMediaPlayerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

import UIKit

#if canImport(WYBasisKitSwift) && canImport(IJKPlayerKit)

import IJKPlayerKit
import WYBasisKitSwift

@objc public extension WYMediaPlayer {

    /// 播放器组件
    @objc(ijkPlayer)
    public var ijkPlayerObjC: IJKPlayer? {
        get { return ijkPlayer }
        set { ijkPlayer = newValue }
    }

    /// 当前正在播放的流地址
    @objc(mediaUrl)
    public var mediaUrlObjC: String {
        return mediaUrl
    }

    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
    @objc(options)
    public var optionsObjC: IJKOptions? {
        get { return options }
        set { options = newValue }
    }

    /// 播放器状态回调代理
    @objc(delegate)
    public weak var delegateObjC: WYMediaPlayerDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }

    /// 播放器状态
    @objc(state)
    public var stateObjC: WYMediaPlayerState {
        return state
    }

    /// 进度回调间隔(秒，默认0.5；1.0.8起底层通知默认关闭，不设置则wy_mediaPlayerProgressDidChanged收不到周期回调，0=关闭周期回调仅保留prepared/seek等离散事件)
    @objc(progressCallbackInterval)
    public var progressCallbackIntervalObjC: TimeInterval {
        get { return progressCallbackInterval }
        set { progressCallbackInterval = newValue }
    }

    /// 是否需要在play(with:)加载完成后自动播放(默认true；仅影响play(with:)，prepare(with:)恒不自动播，预加载请直接用prepare)
    @objc(shouldAutoplay)
    public var shouldAutoplayObjC: Bool {
        get { return shouldAutoplay }
        set { shouldAutoplay = newValue }
    }

    /// 播放失败后重试次数，默认2次
    @objc(failReplay)
    public var failReplayObjC: Int {
        get { return failReplay }
        set { failReplay = newValue }
    }

    /// 循环播放次数：0表示无限次循环，1表示仅播放一次(默认)，N>1表示播放N次，负数同0(点播流有效；即ijkplayer的loop选项语义；在下次加载时生效，运行中改用playbackLoop)
    @objc(looping)
    public var loopingObjC: Int64 {
        get { return looping }
        set { looping = newValue }
    }

    /// 协议层循环播放次数，语义与looping一致(0=无限次，1=仅一次，N>1播N次)；与looping的区别是运行中可改、立即生效，looping在下次加载时生效
    @objc(playbackLoop)
    public var playbackLoopObjC: Int {
        get { return playbackLoop }
        set { playbackLoop = newValue }
    }

    /// 加载时是否需要把渲染好的第一帧设置为播放器背景(与shouldAutoplay=false配合可做预加载封面：prepare完成不起播，仅把首帧显示为背景；播放中渲染画面会天然盖住背景，无需额外清理)
    @objc(shouldUseFirstFrameAsPoster)
    public var shouldUseFirstFrameAsPosterObjC: Bool {
        get { return shouldUseFirstFrameAsPoster }
        set { shouldUseFirstFrameAsPoster = newValue }
    }

    /// 是否静音(与playbackVolume相互独立：静音时实际音量为0，关闭静音自动恢复原音量；海报探测的临时静音对外不可见，不会覆盖muted状态)
    @objc(muted)
    public var mutedObjC: Bool {
        get { return muted }
        set { muted = newValue }
    }

    /// 音频PCM采样回调(每次渲染回调一块采样；sampleSize为-1时samples为NULL表示需重置刷新UI，配合自定义波形/频谱UI使用；须在play/prepare前设置，加载后设置对当前实例立即生效；底层block属性经Swift导入为非可选，仅非nil时可下发，置nil只对新加载生效)
    @objc(audioSamplesCallback)
    public var audioSamplesCallbackObjC: ((UnsafeMutablePointer<Int16>?, Int32, Int32, Int32) -> Void)? {
        get { return audioSamplesCallback }
        set { audioSamplesCallback = newValue }
    }

    /// 自定义音频渲染组件(须在play/prepare之前设置；nil=使用内置音频输出，自定义时音量/静音由自定义组件自行处理)
    @objc(audioRendering)
    public var audioRenderingObjC: IJKAudioRenderingProtocol? {
        get { return audioRendering }
        set { audioRendering = newValue }
    }

    /// 视频缩放模式
    @objc(scalingStyle)
    public var scalingStyleObjC: IJKScalingMode {
        get { return scalingStyle }
        set { scalingStyle = newValue }
    }

    /// 自定义视频渲染视图(须在play/prepare之前设置；nil=使用内置Metal渲染视图，组件会自动addSubview并跟随bounds)
    @objc(videoRendering)
    public var videoRenderingObjC: (UIView & IJKVideoRenderingProtocol)? {
        get { return videoRendering }
        set { videoRendering = newValue }
    }

    /// 渲染帧回调代理(实现IJKVideoRenderingDelegate的videoRenderingWillDisplay可在渲染前替换CVPixelBuffer帧数据，做滤镜/水印处理)
    @objc(renderDisplayDelegate)
    public var renderDisplayDelegateObjC: IJKVideoRenderingDelegate? {
        get { return renderDisplayDelegate }
        set { renderDisplayDelegate = newValue }
    }

    /// 渲染视图背景色(红绿蓝各0~255；渲染视图默认黑色，设置可自定义播放器底色)
    @objc(setRenderBackgroundColorWithRed:green:blue:)
    public func setRenderBackgroundColorObjC(red: UInt8, green: UInt8, blue: UInt8) {
        renderBackgroundColor = (red, green, blue)
    }

    /// 高斯模糊背景图(填充无画面或黑边区域，替代默认纯色背景；nil=清除，配合placeholder使用体验更佳)
    @objc(renderBackgroundImage)
    public var renderBackgroundImageObjC: UIImage? {
        get { return renderBackgroundImage }
        set { renderBackgroundImage = newValue }
    }

    /// 高斯模糊迭代次数(默认3，推荐2~4，越大越柔但越耗性能)
    @objc(renderBackgroundBlurIterations)
    public var renderBackgroundBlurIterationsObjC: Int {
        get { return renderBackgroundBlurIterations }
        set { renderBackgroundBlurIterations = newValue }
    }

    /// 单次高斯模糊的sigma模糊半径(默认30，值越大越模糊)
    @objc(renderBackgroundBlurSigma)
    public var renderBackgroundBlurSigmaObjC: Float {
        get { return renderBackgroundBlurSigma }
        set { renderBackgroundBlurSigma = newValue }
    }

    /// 渲染视图缩放因子(默认1.0，配合Metal渲染Retina适配使用)
    @objc(renderScaleFactor)
    public var renderScaleFactorObjC: CGFloat {
        get { return renderScaleFactor }
        set { renderScaleFactor = newValue }
    }

    /// 暂停画面渲染(true=不再渲染新画面与字幕，仅保留叠加层内容；做画面冻结/截图场景使用)
    @objc(preventDisplay)
    public var preventDisplayObjC: Bool {
        get { return preventDisplay }
        set { preventDisplay = newValue }
    }

    /// 是否允许HDR直显(iOS16+；true且设备支持时HDR不做tone-map直接显示，false=一律压回SDR；读取直显支持能力用directDisplayHDRSupportted)
    @objc(allowHDRDirectDisplay)
    public var allowHDRDirectDisplayObjC: Bool {
        get { return allowHDRDirectDisplay }
        set { allowHDRDirectDisplay = newValue }
    }

    /// 当前显示是否支持HDR直显(只读，iOS16+；iOS16以下恒为false，tvOS不支持HDR直显)
    @objc(directDisplayHDRSupportted)
    public var directDisplayHDRSupporttedObjC: Bool {
        return directDisplayHDRSupportted
    }

    /// 反交错开关(0=关闭，1=开启；隔行扫描源如部分电视TS流需开启，作用于当前实例)
    @objc(deinterlace)
    public var deinterlaceObjC: Int {
        get { return deinterlace }
        set { deinterlace = newValue }
    }

    /// 是否允许AirPlay(无线)投放(开启后系统控件的AirPlay路由可将本播放器的画面/声音转投到Apple TV/HomePod等设备)
    @objc(allowsMediaAirPlay)
    public var allowsMediaAirPlayObjC: Bool {
        get { return allowsMediaAirPlay }
        set { allowsMediaAirPlay = newValue }
    }

    /// 是否把AirPlay(无线)投放媒体当弹幕媒体处理(影响AirPlay路由策略)
    @objc(isDanmakuMediaAirPlay)
    public var isDanmakuMediaAirPlayObjC: Bool {
        get { return isDanmakuMediaAirPlay }
        set { isDanmakuMediaAirPlay = newValue }
    }

    /// AirPlay(无线)投放当前是否活跃(只读)
    @objc(airPlayMediaActive)
    public var airPlayMediaActiveObjC: Bool {
        return airPlayMediaActive
    }

    /// 当前播放时间(只读，单位：s；拖动请用playbackTime(_:))
    @objc(currentPlaybackTime)
    public var currentPlaybackTimeObjC: TimeInterval {
        return currentPlaybackTime
    }

    /// 当前倍速(只读；设置请用playbackRate(_:))
    @objc(currentPlaybackRate)
    public var currentPlaybackRateObjC: Float {
        return currentPlaybackRate
    }

    /// 播放调度阶段(只读，比state更细的生命周期：idle→initialized→preparing→prepared→started→paused→completed/stopped/error)
    @objc(playbackSchedule)
    public var playbackScheduleObjC: IJKPlayerPlaybackSchedule {
        return playbackSchedule
    }

    /// 是否处于seek缓冲中(只读，1=正在缓冲)
    @objc(isSeekBuffering)
    public var isSeekBufferingObjC: Int32 {
        return isSeekBuffering
    }

    /// 视频原始尺寸(只读，宽高未缩放，prepare完成前为zero)
    @objc(naturalSize)
    public var naturalSizeObjC: CGSize {
        return naturalSize
    }

    /// 视频元数据自带的Z轴旋转角度(只读，部分手机竖拍视频为90/270)
    @objc(videoZRotateDegrees)
    public var videoZRotateDegreesObjC: Int {
        return videoZRotateDegrees
    }

    /// 当前时间点的缩略图
    @objc(thumbnailImageAtCurrentTime)
    public var thumbnailImageAtCurrentTimeObjC: UIImage? {
        return thumbnailImageAtCurrentTime
    }

    /// 监视器(只读；媒体/视频/音频/字幕元数据、网络耗时、各阶段延迟等，支持KVO观察)
    @objc(monitor)
    public var monitorObjC: IJKMonitor? {
        return monitor
    }

    /// 元数据标称帧率(只读，单位：帧/秒)
    @objc(fpsInMeta)
    public var fpsInMetaObjC: CGFloat {
        return fpsInMeta
    }

    /// 实际输出帧率(只读，单位：帧/秒，反映真实渲染性能)
    @objc(fpsAtOutput)
    public var fpsAtOutputObjC: CGFloat {
        return fpsAtOutput
    }

    /// 音频是否与主时钟同步(只读，1=已同步)
    @objc(isAudioSync)
    public var isAudioSyncObjC: Int32 {
        return isAudioSync
    }

    /// 视频是否与主时钟同步(只读，1=已同步)
    @objc(isVideoSync)
    public var isVideoSyncObjC: Int32 {
        return isVideoSync
    }

    /// 本次加载的总流量统计(只读，单位：byte，含重试流量)
    @objc(numberOfBytesTransferred)
    public var numberOfBytesTransferredObjC: Int64 {
        return numberOfBytesTransferred
    }

    /// 是否显示性能调试HUD(帧率/丢帧/缓存等叠加面板，播放中可随时开关)
    @objc(shouldShowHudView)
    public var shouldShowHudViewObjC: Bool {
        get { return shouldShowHudView }
        set { shouldShowHudView = newValue }
    }

    /// IJK内核日志级别(默认IJK_LOG_SILENT完全静默；内核级全局开关，多实例以最后创建实例的值为准)
    @objc(logLevel)
    public var logLevelObjC: IJKLogLevel {
        get { return logLevel }
        set { logLevel = newValue }
    }

    /// HLS分片打开前回调(可改写urlOpenData.url实现本地缓存/鉴权替换，改完自动标记handled；不改url仅做监控也可用)
    @objc(willOpenSegmentUrl)
    public var willOpenSegmentUrlObjC: ((IJKMediaUrlOpenData) -> Void)? {
        get { return willOpenSegmentUrl }
        set { willOpenSegmentUrl = newValue }
    }

    /// TCP连接打开前回调(可读取/改写目标url，观察连接ip/port需配合DidTcpOpen事件属性)
    @objc(willOpenTcpUrl)
    public var willOpenTcpUrlObjC: ((IJKMediaUrlOpenData) -> Void)? {
        get { return willOpenTcpUrl }
        set { willOpenTcpUrl = newValue }
    }

    /// HTTP请求打开前回调(可改写url/查看重试计数retryCounter，适合加签名或换CDN)
    @objc(willOpenHttpUrl)
    public var willOpenHttpUrlObjC: ((IJKMediaUrlOpenData) -> Void)? {
        get { return willOpenHttpUrl }
        set { willOpenHttpUrl = newValue }
    }

    /// 直播流打开前回调(直播重连前触发，可趁机换源)
    @objc(willOpenLiveUrl)
    public var willOpenLiveUrlObjC: ((IJKMediaUrlOpenData) -> Void)? {
        get { return willOpenLiveUrl }
        set { willOpenLiveUrl = newValue }
    }

    /// 媒体模块单例(空闲计时器控制：后台播放时防止屏幕休眠等，详见IJKMediaModule)
    @objc(mediaModule)
    public static var mediaModuleObjC: IJKMediaModule {
        return mediaModule
    }

    /**
     * 开始播放(加载完成后自动起播，受shouldAutoplay控制，默认true)
     * @param url 要播放的流地址
     * @param placeholder 视屏背景图占位图
     */
    @objc(playWithUrl:)
    public func playObjC(with url: String) {
        playObjC(with: url, placeholder: nil)
    }
    @objc(playWithUrl:placeholder:)
    public func playObjC(with url: String, placeholder: UIImage? = nil) {
        play(with: url, placeholder: placeholder)
    }

    /**
     * 预加载：只加载缓冲、不自动播放不出声(适合预加载预备页)；加载完成若开了shouldUseFirstFrameAsPoster会自动探测首帧作封面，之后调playObjC()即可播放(未prepare完会自动挂起，prepare完成后立即起播并跳过探测)
     * @param url 要加载的流地址
     * @param placeholder 视屏背景图占位图
     */
    @objc(prepareWithUrl:)
    public func prepareObjC(with url: String) {
        prepare(with: url)
    }
    @objc(prepareWithUrl:placeholder:)
    public func prepareObjC(with url: String, placeholder: UIImage? = nil) {
        prepare(with: url, placeholder: placeholder)
    }

    /// 继续播放(仅适用于暂停后恢复播放)
    @objc(play)
    public func playObjC() {
        play()
    }

    /// 暂停播放
    @objc(pause)
    public func pauseObjC() {
        pause()
    }

    /// 快进/快退
    @objc(playbackTime:)
    public func playbackTimeObjC(_ time: TimeInterval) {
        playbackTime(time)
    }

    /// 倍速播放
    @objc(playbackRate:)
    public func playbackRateObjC(_ rate: CGFloat) {
        playbackRate(rate)
    }

    /// 逐帧播放
    @objc(stepToNextFrame)
    public func stepToNextFrameObjC() {
        stepToNextFrame()
    }

    /**
     * 开关精准seek(运行中可切换；开启后seek会解码到目标帧，准确但更耗时)
     * @param open true=开启精准seek，false=关闭
     */
    @objc(enableAccurateSeek:)
    public func enableAccurateSeekObjC(_ open: Bool) {
        enableAccurateSeek(open)
    }

    /**
     * 停止播放(无法再次恢复播放)
     * @param keepLast 是否要保留最后一帧图像
     */
    @objc(stopWithKeepLast:)
    public func stopObjC(_ keepLast: Bool = true) {
        stop(keepLast)
    }

    /// 音量设置，0~1，为0时表示静音(实际下发音量统一走applyVolume：muted或海报探测期间为0)
    @objc(playbackVolume:)
    public func playbackVolumeObjC(_ volume: CGFloat) {
        playbackVolume(volume)
    }

    /**
     * 设置音频声道(单声道源切左右声道，双耳助听/外国语场景常用；类型为IJKPlayerKit的IJKAudioChannel，OC侧直接用IJKAudioChannelStereo等常量)
     * @param channel 目标声道
     */
    @objc(setAudioChannel:)
    public func setAudioChannelObjC(_ channel: IJKAudioChannel) {
        setAudioChannel(channel)
    }

    /// 获取当前音频声道(类型为IJKPlayerKit的IJKAudioChannel，OC侧直接用IJKAudioChannelStereo等常量)
    @objc(audioChannel)
    public func audioChannelObjC() -> IJKAudioChannel {
        return audioChannel()
    }

    /// 设定音频延迟(单位：s)
    @objc(audioExtraDelay:)
    public func audioExtraDelayObjC(_ delay: CGFloat) {
        audioExtraDelay(delay)
    }

    /**
     * 设置退到后台是否暂停播放(默认由系统音频会话决定)
     * @param pause true=后台暂停，false=后台继续播(需后台音频权限配合)
     */
    @objc(setPauseInBackground:)
    public func setPauseInBackgroundObjC(_ pause: Bool) {
        setPauseInBackground(pause)
    }

    /// 挂载并激活字幕(本地/网络)
    @objc(loadThenActiveSubtitleWithUrl:)
    @discardableResult
    public func loadThenActiveSubtitleObjC(_ url: URL) -> Bool {
        return loadThenActiveSubtitle(url)
    }

    /// 仅挂载不激活字幕(本地/网络)
    @objc(loadSubtitleOnlyWithUrl:)
    @discardableResult
    public func loadSubtitleOnlyObjC(_ url: URL) -> Bool {
        return loadSubtitleOnly(url)
    }

    /// 批量挂载不激活字幕(本地/网络)
    @objc(loadSubtitleOnlyWithUrls:)
    @discardableResult
    public func loadSubtitleOnlyObjC(_ urls: [URL]) -> Bool {
        return loadSubtitleOnly(urls)
    }

    /// 激活字幕(没有激活的字幕调用激活，相同路径的字幕重复挂载会失败)
    @objc(exchangeSelectedStreamWithIndex:)
    public func exchangeSelectedStreamObjC(_ streamIndex: Int32) {
        exchangeSelectedStream(streamIndex)
    }

    /// 关闭字幕(IJK_VAL_TYPE__VIDEO, IJK_VAL_TYPE__AUDIO, IJK_VAL_TYPE__SUBTITLE)
    @objc(closeCurrentStreamWithStyle:)
    public func closeCurrentStreamObjC(_ streamStyle: String) {
        closeCurrentStream(streamStyle)
    }

    /// 设定字幕延迟(单位：s)
    @objc(subtitleExtraDelay:)
    public func subtitleExtraDelayObjC(_ delay: CGFloat) {
        subtitleExtraDelay(delay)
    }

    /// 调整字幕样式(支持设置字体，字体颜色，边框颜色，背景颜色等)
    @objc(subtitlePreference:)
    public func subtitlePreferenceObjC(_ preference: IJKSubtitlePreference) {
        subtitlePreference(preference)
    }

    /// 播放画面显示模式
    @objc(scalingStyle:)
    public func scalingStyleObjC(_ style: IJKScalingMode) {
        scalingStyle(style)
    }

    /// 旋转画面
    @objc(rotatePreference:)
    public func rotatePreferenceObjC(_ preference: IJKRotatePreference) {
        rotatePreference(preference)
    }

    /// 修改画面色彩
    @objc(colorPreference:)
    public func colorPreferenceObjC(_ preference: IJKColorConvertPreference) {
        colorPreference(preference)
    }

    /// 设置画面比例
    @objc(darPreference:)
    public func darPreferenceObjC(_ preference: IJKDARPreference) {
        darPreference(preference)
    }

    /**
     * 注册画面刷新回调(暂停状态下修改rotatePreference/colorPreference/darPreference后，渲染器刷新完画面会回调；nil=移除)
     * @param block 刷新完成回调
     */
    @objc(registerRefreshCurrentPicObserver:)
    public func registerRefreshCurrentPicObserverObjC(_ block: (() -> Void)?) {
        registerRefreshCurrentPicObserver(block)
    }

    /// 截取当前显示画面
    @objc(currentSnapshot)
    public func currentSnapshotObjC() -> UIImage {
        return currentSnapshot()
    }

    /**
     * 运行时切换硬/软解码(无需停止播放；硬解花屏或兼容性问题时切软解自救)
     * @param hardware true=切硬件解码(VideoToolbox)，false=切软件解码
     * @return 是否切换成功
     */
    @objc(switchVideoDecoder:)
    @discardableResult
    public func switchVideoDecoderObjC(_ hardware: Bool) -> Bool {
        return switchVideoDecoder(hardware)
    }

    /**
     * 开始快速录制(边播边录，速度优先；建议.mp4/.mov容器)
     * @param filePath 录制文件完整路径
     * @return 0=成功，非0=错误码
     */
    @objc(startFastRecord:)
    @discardableResult
    public func startFastRecordObjC(_ filePath: String) -> Int32 {
        return startFastRecord(filePath)
    }

    /// 停止快速录制并落盘
    @objc(stopFastRecord)
    @discardableResult
    public func stopFastRecordObjC() -> Int32 {
        return stopFastRecord()
    }

    /**
     * 开始精准录制(逐帧完整录制，较慢但无丢帧)
     * @param filePath 录制文件完整路径
     * @return 0=成功，非0=错误码
     */
    @objc(startExactRecord:)
    @discardableResult
    public func startExactRecordObjC(_ filePath: String) -> Int32 {
        return startExactRecord(filePath)
    }

    /// 停止精准录制并落盘
    @objc(stopExactRecord)
    @discardableResult
    public func stopExactRecordObjC() -> Int32 {
        return stopExactRecord()
    }

    /// 当前是否正在播放
    @objc(isPlaying)
    public func isPlayingObjC() -> Bool {
        return isPlaying()
    }

    /// 获取视频时长
    @objc(videoDuration)
    public func videoDurationObjC() -> TimeInterval {
        return videoDuration()
    }

    /// 获取预加载时长(单位：s)
    @objc(playableDuration)
    public func playableDurationObjC() -> TimeInterval {
        return playableDuration()
    }

    /// 获取缓冲进度
    @objc(bufferingProgress)
    public func bufferingProgressObjC() -> Int {
        return bufferingProgress()
    }

    /// 获取下载速度(单位：byte)
    @objc(downloadSpeed)
    public func downloadSpeedObjC() -> Int64 {
        return downloadSpeed()
    }

    /// 丢帧率(0~1，反映硬解/渲染跟不上的程度)
    @objc(dropFrameRate)
    public func dropFrameRateObjC() -> Float {
        return dropFrameRate()
    }

    /// 累计丢帧数
    @objc(dropFrameCount)
    public func dropFrameCountObjC() -> Int {
        return dropFrameCount()
    }

    /// 视频与主时钟的偏差(单位：s，正值=视频落后于主时钟，排查音画不同步用)
    @objc(currentVMDiff)
    public func currentVMDiffObjC() -> Float {
        return currentVMDiff()
    }

    /// 本次加载的总流量统计(单位：byte，与numberOfBytesTransferred同源)
    @objc(trafficStatistic)
    public func trafficStatisticObjC() -> Int64 {
        return trafficStatistic()
    }

    /// 获取HUD全部键值(需shouldShowHudView场景外自行展示时使用)
    @objc(allHudItem)
    public func allHudItemObjC() -> [AnyHashable: Any] {
        return allHudItem()
    }

    /// 设置HUD自定义展示值(追加到HUD面板)
    @objc(setHudValue:forKey:)
    public func setHudValueObjC(_ value: String?, forKey key: String) {
        setHudValue(value, forKey: key)
    }

    /// 获取支持的输入格式扩展名列表(判断文件能否播放时使用)
    @objc(getInputFormatExtensions)
    public func getInputFormatExtensionsObjC() -> [String] {
        return getInputFormatExtensions()
    }

    /// 播放器版本号(如"1.0.8")
    @objc(playerVersion)
    public static func playerVersionObjC() -> String {
        return playerVersion()
    }

    /// 内核FFmpeg版本号(如"n7.1.3-32-g23d663f")
    @objc(ffmpegVersion)
    public static func ffmpegVersionObjC() -> String {
        return ffmpegVersion()
    }

    /// 支持的解码器清单(硬解能力排查用)
    @objc(supportedDecoders)
    public static func supportedDecodersObjC() -> [AnyHashable: Any] {
        return supportedDecoders()
    }

    /// 开关日志上报(true=日志走上报通道)
    @objc(setLogReport:)
    public static func setLogReportObjC(_ preferLogReport: Bool) {
        setLogReport(preferLogReport)
    }

    /// 获取当前日志级别(类型为IJKLogLevel，OC侧直接用IJK_LOG_*宏)
    @objc(getLogLevel)
    public static func getLogLevelObjC() -> IJKLogLevel {
        return getLogLevel()
    }

    /**
     * 重定向日志输出(nil=恢复默认stderr输出；level/tag/msg为级别/标签/内容，业务可接自研日志系统；level为IJKLogLevel，OC侧直接用IJK_LOG_*宏)
     * @param handler 日志处理闭包
     */
    @objc(setLogHandler:)
    public static func setLogHandlerObjC(_ handler: ((IJKLogLevel, String, String) -> Void)?) {
        setLogHandler(handler)
    }

    /// 释放播放器组件
    @objc(releaseAll)
    public func releaseAllObjC() {
        releaseAll()
    }

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}

#endif
