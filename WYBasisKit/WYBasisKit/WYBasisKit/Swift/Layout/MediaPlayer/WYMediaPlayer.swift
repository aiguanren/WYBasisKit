//
//  WYMediaPlayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

#if canImport(IJKPlayerKit)

import IJKPlayerKit

/// 播放器状态回调
@objc @frozen public enum WYMediaPlayerState: Int {
    /// 未知状态
    case unknown = 0
    /// 第一帧渲染完成
    case rendered
    /// 可以播放了
    case ready
    /// 正在播放
    case playing
    /// 缓冲中
    case buffering
    /// 缓冲结束
    case playable
    /// 播放暂停
    case paused
    /// 播放被中断
    case interrupted
    /// 快进
    case seekingForward
    /// 快退
    case seekingBackward
    /// 播放完毕
    case ended
    /// 用户中断播放
    case userExited
    /// 播放出现异常
    case error
    /// 播放地址为空
    case playUrlEmpty
}

@objc public protocol WYMediaPlayerDelegate {

    /// 播放器状态回调
    @objc(wy_mediaPlayerStateDidChanged:state:)
    optional func wy_mediaPlayerStateDidChanged(_ player: WYMediaPlayer, state: WYMediaPlayerState)

    /// 音视频字幕流信息
    @objc(wy_mediaPlayerSubtitleStreamDidChanged:mediaMeta:)
    optional func wy_mediaPlayerSubtitleStreamDidChanged(_ player: WYMediaPlayer, mediaMeta: [AnyHashable: Any])

    /// 播放进度回调(随IJKPlayer的播放时间变化通知触发，播放期间持续回调，做UI刷新请自行节流)
    @objc(wy_mediaPlayerProgressDidChanged:currentTime:duration:playableDuration:)
    optional func wy_mediaPlayerProgressDidChanged(_ player: WYMediaPlayer, currentTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval)

    /**
     *  普通seek完成回调
     *  @param player 播放器组件
     *  @param target 本次seek的目标时间点(单位：s)
     *  @param error seek结果错误码，0表示成功
     */
    @objc(wy_mediaPlayerDidSeekComplete:target:error:)
    optional func wy_mediaPlayerDidSeekComplete(_ player: WYMediaPlayer, target: TimeInterval, error: Int)

    /**
     *  精准seek完成回调(enable-accurate-seek开启时走这里)
     *  @param player 播放器组件
     *  @param currentPosition 精准seek完成后的当前播放位置(单位：s)
     */
    @objc(wy_mediaPlayerDidAccurateSeekComplete:currentPosition:)
    optional func wy_mediaPlayerDidAccurateSeekComplete(_ player: WYMediaPlayer, currentPosition: TimeInterval)

    /**
     *  首帧音频渲染完成回调(听到声音的时刻，早于或晚于首帧视频都属正常)
     *  @param player 播放器组件
     */
    @objc(wy_mediaPlayerFirstAudioFrameRendered:)
    optional func wy_mediaPlayerFirstAudioFrameRendered(_ player: WYMediaPlayer)

    /**
     *  首帧音频解码完成回调(解码完成但未必已渲染)
     *  @param player 播放器组件
     */
    @objc(wy_mediaPlayerFirstAudioFrameDecoded:)
    optional func wy_mediaPlayerFirstAudioFrameDecoded(_ player: WYMediaPlayer)

    /**
     *  首帧视频解码完成回调(解码完成但未必已渲染，渲染完成走wy_mediaPlayerStateDidChanged的rendered)
     *  @param player 播放器组件
     */
    @objc(wy_mediaPlayerFirstVideoFrameDecoded:)
    optional func wy_mediaPlayerFirstVideoFrameDecoded(_ player: WYMediaPlayer)

    /**
     *  seek后首帧视频显示完成回调(拖动进度后画面真正刷新出来的时刻)
     *  @param player 播放器组件
     */
    @objc(wy_mediaPlayerDidSeekFirstVideoFrameDisplayed:)
    optional func wy_mediaPlayerDidSeekFirstVideoFrameDisplayed(_ player: WYMediaPlayer)

    /**
     *  视频原始尺寸就绪回调(prepare后元数据解析完成时触发)
     *  @param player 播放器组件
     *  @param naturalSize 视频原始尺寸(未按显示比例缩放)
     */
    @objc(wy_mediaPlayerNaturalSizeDidChanged:naturalSize:)
    optional func wy_mediaPlayerNaturalSizeDidChanged(_ player: WYMediaPlayer, naturalSize: CGSize)

    /**
     *  视频解码器打开回调(可据此得知当前走硬解还是软解)
     *  @param player 播放器组件
     *  @param decoderName 解码器名称(如"videotoolbox"或软解名)
     */
    @objc(wy_mediaPlayerVideoDecoderOpen:decoderName:)
    optional func wy_mediaPlayerVideoDecoderOpen(_ player: WYMediaPlayer, decoderName: String)

    /**
     *  视频解码器致命错误回调(收到后建议停止播放，否则底层会继续读帧播到结尾；组件会同步置state为error)
     *  @param player 播放器组件
     *  @param errorCode 解码器错误码
     */
    @objc(wy_mediaPlayerVideoDecoderFatal:errorCode:)
    optional func wy_mediaPlayerVideoDecoderFatal(_ player: WYMediaPlayer, errorCode: Int)

    /**
     *  未找到可用解码器回调(源编码格式不被支持时触发，组件会同步置state为error)
     *  @param player 播放器组件
     */
    @objc(wy_mediaPlayerNoCodecFound:)
    optional func wy_mediaPlayerNoCodecFound(_ player: WYMediaPlayer)

    /**
     *  播放器内部警告回调(非致命，如码流异常等)
     *  @param player 播放器组件
     *  @param reason 警告原因码
     */
    @objc(wy_mediaPlayerRecvWarning:reason:)
    optional func wy_mediaPlayerRecvWarning(_ player: WYMediaPlayer, reason: Int)

    /**
     *  ICY电台元数据变化回调(网络电台流的歌名/主持人等信息变化，key见IJK_KEY_ICY_*宏)
     *  @param player 播放器组件
     *  @param meta ICY元数据字典
     */
    @objc(wy_mediaPlayerICYMetaDidChanged:meta:)
    optional func wy_mediaPlayerICYMetaDidChanged(_ player: WYMediaPlayer, meta: [AnyHashable: Any])

    /**
     *  选流失败回调(exchangeSelectedStream/closeCurrentStream操作失败时触发)
     *  @param player 播放器组件
     *  @param streamID 失败的流下标
     *  @param errorCode 失败错误码
     */
    @objc(wy_mediaPlayerSelectingStreamDidFailed:streamID:errorCode:)
    optional func wy_mediaPlayerSelectingStreamDidFailed(_ player: WYMediaPlayer, streamID: Int32, errorCode: Int32)

    /**
     *  缓冲进度变化回调(与wy_mediaPlayerStateDidChanged的buffering状态互补，这里带具体百分比)
     *  @param player 播放器组件
     *  @param bufferingProgress 当前缓冲进度(0~100)
     */
    @objc(wy_mediaPlayerBufferingDidChanged:bufferingProgress:)
    optional func wy_mediaPlayerBufferingDidChanged(_ player: WYMediaPlayer, bufferingProgress: Int)

    /**
     *  AirPlay(无线)投放播放状态变化回调
     *  @param player 播放器组件
     *  @param active 当前是否正通过AirPlay输出
     */
    @objc(wy_mediaPlayerAirPlayActiveDidChanged:active:)
    optional func wy_mediaPlayerAirPlayActiveDidChanged(_ player: WYMediaPlayer, active: Bool)
}

public class WYMediaPlayer: UIImageView {

    /// 播放器组件
    public var ijkPlayer: IJKPlayer?

    /// 当前正在播放的流地址
    public private(set) var mediaUrl: String = ""

    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
    public var options: IJKOptions?

    /// 播放器状态回调代理
    public weak var delegate: WYMediaPlayerDelegate?

    /// 播放器状态
    public private(set) var state: WYMediaPlayerState = .unknown

    /// 进度回调间隔(秒，默认0.5；1.0.8起底层通知默认关闭，不设置则wy_mediaPlayerProgressDidChanged收不到周期回调，0=关闭周期回调仅保留prepared/seek等离散事件)
    public var progressCallbackInterval: TimeInterval = 0.5

    /// 是否需要在play(with:)加载完成后自动播放(默认true；仅影响play(with:)，prepare(with:)恒不自动播，预加载请直接用prepare)
    public var shouldAutoplay: Bool = true

    /// 播放失败后重试次数，默认2次
    public var failReplay: Int = 2

    /// 循环播放次数：0表示无限次循环，1表示仅播放一次(默认)，N>1表示播放N次，负数同0(点播流有效；即ijkplayer的loop选项语义；在下次加载时生效，运行中改用playbackLoop)
    public var looping: Int64 = 0

    /// 协议层循环播放次数，语义与looping一致(0=无限次，1=仅一次，N>1播N次)；与looping的区别是运行中可改、立即生效，looping在下次加载时生效
    public var playbackLoop: Int {
        get { return Int(ijkPlayer?.playbackLoop ?? 0) }
        set { ijkPlayer?.playbackLoop = Int32(newValue) }
    }

    /// 加载时是否需要把渲染好的第一帧设置为播放器背景(与shouldAutoplay=false配合可做预加载封面：prepare完成不起播，仅把首帧显示为背景；播放中渲染画面会天然盖住背景，无需额外清理)
    public var shouldUseFirstFrameAsPoster: Bool = false {
        didSet {
            // 首帧已渲染后才打开开关且当前没有背景图时立即补截一次(覆盖"加载前设置"之外的时序)；播放中不截，避免取到非首帧
            if shouldUseFirstFrameAsPoster, hasRenderedFirstFrame, image == nil, state != .playing {
                image = ijkPlayer?.thumbnailImageAtCurrentTime()
            }
        }
    }

    /// 是否静音(与playbackVolume相互独立：静音时实际音量为0，关闭静音自动恢复原音量；海报探测的临时静音对外不可见，不会覆盖muted状态)
    public var muted: Bool = false {
        didSet {
            applyVolume()
        }
    }

    /// 音频PCM采样回调(每次渲染回调一块采样；sampleSize为-1时samples为NULL表示需重置刷新UI，配合自定义波形/频谱UI使用；须在play/prepare前设置，加载后设置对当前实例立即生效；底层block属性经Swift导入为非可选，仅非nil时可下发，置nil只对新加载生效)
    public var audioSamplesCallback: ((UnsafeMutablePointer<Int16>?, Int32, Int32, Int32) -> Void)? {
        didSet {
            if let audioSamplesCallback = audioSamplesCallback {
                ijkPlayer?.audioSamplesCallback = audioSamplesCallback
            }
        }
    }

    /// 自定义音频渲染组件(须在play/prepare之前设置；nil=使用内置音频输出，自定义时音量/静音由自定义组件自行处理)
    public var audioRendering: IJKAudioRenderingProtocol?

    /// 视频缩放模式
    public var scalingStyle: IJKScalingMode = .aspectFit

    /// 自定义视频渲染视图(须在play/prepare之前设置；nil=使用内置Metal渲染视图，组件会自动addSubview并跟随bounds)
    public var videoRendering: (UIView & IJKVideoRenderingProtocol)?

    /// 渲染帧回调代理(实现IJKVideoRenderingDelegate的videoRenderingWillDisplay可在渲染前替换CVPixelBuffer帧数据，做滤镜/水印处理)
    public weak var renderDisplayDelegate: IJKVideoRenderingDelegate? {
        get { return ijkPlayer?.view.displayDelegate }
        set { ijkPlayer?.view.displayDelegate = newValue }
    }

    /// 渲染视图背景色(红绿蓝各0~255；渲染视图默认黑色，设置可自定义播放器底色)
    public var renderBackgroundColor: (red: UInt8, green: UInt8, blue: UInt8) {
        get { return (0, 0, 0) }
        set { ijkPlayer?.view.setBackgroundColor?(newValue.red, g: newValue.green, b: newValue.blue) }
    }

    /// 高斯模糊背景图(填充无画面或黑边区域，替代默认纯色背景；nil=清除，配合placeholder使用体验更佳)
    public var renderBackgroundImage: UIImage? {
        get {
            // #selector引用协议声明形成编译期校验：上游改名/删除该成员时这里直接编译报错，杜绝字符串硬编码的静默失效；KVC键名即getter选择子名
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundImage)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return nil }
            return view.value(forKey: NSStringFromSelector(selector)) as? UIImage
        }
        set {
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundImage)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return }
            view.setValue(newValue, forKey: NSStringFromSelector(selector))
        }
    }

    /// 高斯模糊迭代次数(默认3，推荐2~4，越大越柔但越耗性能)
    public var renderBackgroundBlurIterations: Int {
        get {
            // #selector引用协议声明形成编译期校验：上游改名/删除该成员时这里直接编译报错，杜绝字符串硬编码的静默失效；KVC键名即getter选择子名
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundBlurIterations)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return 3 }
            return (view.value(forKey: NSStringFromSelector(selector)) as? NSNumber)?.intValue ?? 3
        }
        set {
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundBlurIterations)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return }
            view.setValue(NSNumber(value: newValue), forKey: NSStringFromSelector(selector))
        }
    }

    /// 单次高斯模糊的sigma模糊半径(默认30，值越大越模糊)
    public var renderBackgroundBlurSigma: Float {
        get {
            // #selector引用协议声明形成编译期校验：上游改名/删除该成员时这里直接编译报错，杜绝字符串硬编码的静默失效；KVC键名即getter选择子名
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundBlurSigma)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return 30 }
            return (view.value(forKey: NSStringFromSelector(selector)) as? NSNumber)?.floatValue ?? 30
        }
        set {
            let selector = #selector(getter: IJKVideoRenderingProtocol.backgroundBlurSigma)
            guard let view = ijkPlayer?.view, view.responds(to: selector) else { return }
            view.setValue(NSNumber(value: newValue), forKey: NSStringFromSelector(selector))
        }
    }

    /// 渲染视图缩放因子(默认1.0，配合Metal渲染Retina适配使用)
    public var renderScaleFactor: CGFloat {
        get { return ijkPlayer?.view.scaleFactor ?? 1 }
        set { ijkPlayer?.view.scaleFactor = newValue }
    }

    /// 暂停画面渲染(true=不再渲染新画面与字幕，仅保留叠加层内容；做画面冻结/截图场景使用)
    public var preventDisplay: Bool {
        get { return ijkPlayer?.view.preventDisplay ?? false }
        set { ijkPlayer?.view.preventDisplay = newValue }
    }

    /// 是否允许HDR直显(iOS16+；true且设备支持时HDR不做tone-map直接显示，false=一律压回SDR；读取直显支持能力用directDisplayHDRSupportted)
    public var allowHDRDirectDisplay: Bool {
        get {
            if #available(iOS 16.0, *) {
                return ijkPlayer?.view.allowHDRDirectDisplay ?? true
            } else {
                return false
            }
        }
        set {
            if #available(iOS 16.0, *) {
                ijkPlayer?.view.allowHDRDirectDisplay = newValue
            }
        }
    }

    /// 当前显示是否支持HDR直显(只读，iOS16+；iOS16以下恒为false，tvOS不支持HDR直显)
    public var directDisplayHDRSupportted: Bool {
        if #available(iOS 16.0, *) {
            return ijkPlayer?.view.directDisplayHDRSupportted ?? false
        } else {
            return false
        }
    }

    /// 反交错开关(0=关闭，1=开启；隔行扫描源如部分电视TS流需开启，作用于当前实例)
    public var deinterlace: Int {
        get { return Int(ijkPlayer?.deinterlace ?? 0) }
        set { ijkPlayer?.deinterlace = Int32(newValue) }
    }

    /// 是否允许AirPlay(无线)投放(开启后系统控件的AirPlay路由可将本播放器的画面/声音转投到Apple TV/HomePod等设备)
    public var allowsMediaAirPlay: Bool {
        get { return ijkPlayer?.allowsMediaAirPlay ?? false }
        set { ijkPlayer?.allowsMediaAirPlay = newValue }
    }

    /// 是否把AirPlay(无线)投放媒体当弹幕媒体处理(影响AirPlay路由策略)
    public var isDanmakuMediaAirPlay: Bool {
        get { return ijkPlayer?.isDanmakuMediaAirPlay ?? false }
        set { ijkPlayer?.isDanmakuMediaAirPlay = newValue }
    }

    /// AirPlay(无线)投放当前是否活跃(只读)
    public var airPlayMediaActive: Bool {
        return ijkPlayer?.airPlayMediaActive ?? false
    }

    /// 当前播放时间(只读，单位：s；拖动请用playbackTime(_:))
    public var currentPlaybackTime: TimeInterval {
        return ijkPlayer?.currentPlaybackTime ?? 0
    }

    /// 当前倍速(只读；设置请用playbackRate(_:))
    public var currentPlaybackRate: Float {
        return ijkPlayer?.playbackRate ?? 0
    }

    /// 播放调度阶段(只读，比state更细的生命周期：idle→initialized→preparing→prepared→started→paused→completed/stopped/error)
    public var playbackSchedule: IJKPlayerPlaybackSchedule {
        return ijkPlayer?.playbackSchedule ?? .idle
    }

    /// 是否处于seek缓冲中(只读，1=正在缓冲)
    public var isSeekBuffering: Int32 {
        return ijkPlayer?.isSeekBuffering ?? 0
    }

    /// 视频原始尺寸(只读，宽高未缩放，prepare完成前为zero)
    public var naturalSize: CGSize {
        return ijkPlayer?.naturalSize ?? .zero
    }

    /// 视频元数据自带的Z轴旋转角度(只读，部分手机竖拍视频为90/270)
    public var videoZRotateDegrees: Int {
        return Int(ijkPlayer?.videoZRotateDegrees ?? 0)
    }

    /// 当前时间点的缩略图
    public var thumbnailImageAtCurrentTime: UIImage? {
        return ijkPlayer?.thumbnailImageAtCurrentTime()
    }

    /// 监视器(只读；媒体/视频/音频/字幕元数据、网络耗时、各阶段延迟等，支持KVO观察)
    public var monitor: IJKMonitor? {
        return ijkPlayer?.monitor
    }

    /// 元数据标称帧率(只读，单位：帧/秒)
    public var fpsInMeta: CGFloat {
        return ijkPlayer?.fpsInMeta ?? 0
    }

    /// 实际输出帧率(只读，单位：帧/秒，反映真实渲染性能)
    public var fpsAtOutput: CGFloat {
        return ijkPlayer?.fpsAtOutput ?? 0
    }

    /// 音频是否与主时钟同步(只读，1=已同步)
    public var isAudioSync: Int32 {
        return ijkPlayer?.isAudioSync ?? 0
    }

    /// 视频是否与主时钟同步(只读，1=已同步)
    public var isVideoSync: Int32 {
        return ijkPlayer?.isVideoSync ?? 0
    }

    /// 本次加载的总流量统计(只读，单位：byte，含重试流量)
    public var numberOfBytesTransferred: Int64 {
        return ijkPlayer?.numberOfBytesTransferred ?? 0
    }

    /// 是否显示性能调试HUD(帧率/丢帧/缓存等叠加面板，播放中可随时开关)
    public var shouldShowHudView: Bool {
        get { return ijkPlayer?.shouldShowHudView ?? false }
        set { ijkPlayer?.shouldShowHudView = newValue }
    }

    /// IJK内核日志级别(默认IJK_LOG_SILENT完全静默；内核级全局开关，多实例以最后创建实例的值为准)
    public var logLevel: IJKLogLevel = IJK_LOG_SILENT

    /// HLS分片打开前回调(可改写urlOpenData.url实现本地缓存/鉴权替换，改完自动标记handled；不改url仅做监控也可用)
    public var willOpenSegmentUrl: ((IJKMediaUrlOpenData) -> Void)? {
        didSet { refreshUrlOpenDelegates() }
    }

    /// TCP连接打开前回调(可读取/改写目标url，观察连接ip/port需配合DidTcpOpen事件属性)
    public var willOpenTcpUrl: ((IJKMediaUrlOpenData) -> Void)? {
        didSet { refreshUrlOpenDelegates() }
    }

    /// HTTP请求打开前回调(可改写url/查看重试计数retryCounter，适合加签名或换CDN)
    public var willOpenHttpUrl: ((IJKMediaUrlOpenData) -> Void)? {
        didSet { refreshUrlOpenDelegates() }
    }

    /// 直播流打开前回调(直播重连前触发，可趁机换源)
    public var willOpenLiveUrl: ((IJKMediaUrlOpenData) -> Void)? {
        didSet { refreshUrlOpenDelegates() }
    }

    /// 媒体模块单例(空闲计时器控制：后台播放时防止屏幕休眠等，详见IJKMediaModule)
    public static var mediaModule: IJKMediaModule {
        return IJKMediaModule.shared()
    }

    /**
     * 开始播放(加载完成后自动起播，受shouldAutoplay控制，默认true)
     * @param url 要播放的流地址
     * @param placeholder 视屏背景图占位图
     */
    public func play(with url: String, placeholder: UIImage? = nil) {
        load(with: url, placeholder: placeholder, autoplay: shouldAutoplay)
    }

    /**
     * 预加载：只加载缓冲、不自动播放不出声(适合预加载预备页)；加载完成若开了shouldUseFirstFrameAsPoster会自动探测首帧作封面，之后调play()即可播放(未prepare完会自动挂起，prepare完成后立即起播并跳过探测)
     * @param url 要加载的流地址
     * @param placeholder 视屏背景图占位图
     */
    public func prepare(with url: String, placeholder: UIImage? = nil) {
        load(with: url, placeholder: placeholder, autoplay: false)
    }

    /// 开始播放(仅适用于暂停后恢复播放)
    public func play() {
        if isPosterProbing {
            isPosterProbing = false
            applyVolume()
        }
        // prepare未完成时play()调用会被底层直接丢弃(换源重载场景实测)，挂起待prepared回调补执行，保证"最终一定要播"
        if isPreparedToPlay == false {
            isPlayPending = true
            // play意图覆盖prepare期间收到的暂停意图(先pause后play=最终要播)
            isPausedWhilePreparing = false
            return
        }
        ijkPlayer?.play()
    }

    /// 暂停播放
    public func pause() {
        isPlayPending = false
        // prepare未完成时记下暂停意图：start-on-prepared是内核级自动起播(play(with:)默认autoplay烘进选项)，未就绪的pause调用拦不住，prepared回调必须抢先压住(否则play后快速pause、prepare完成瞬间声音在画面外响起)
        if isPreparedToPlay == false {
            isPausedWhilePreparing = true
        }
        ijkPlayer?.pause()
    }

    /// 快进/快退
    public func playbackTime(_ time: TimeInterval) {
        ijkPlayer?.currentPlaybackTime = time
    }

    /// 倍速播放
    public func playbackRate(_ rate: CGFloat) {
        ijkPlayer?.playbackRate = Float(rate)
    }

    /// 逐帧播放
    public func stepToNextFrame() {
        ijkPlayer?.stepToNextFrame()
    }

    /**
     * 开关精准seek(运行中可切换；开启后seek会解码到目标帧，准确但更耗时)
     * @param open true=开启精准seek，false=关闭
     */
    public func enableAccurateSeek(_ open: Bool) {
        ijkPlayer?.enableAccurateSeek(open)
    }

    /**
     * 停止播放(无法再次恢复播放)
     * @param keepLast 是否要保留最后一帧图像
     */
    public func stop(_ keepLast: Bool = true) {

        guard let player = ijkPlayer else {
            return
        }

        if keepLast {
            image = player.thumbnailImageAtCurrentTime()
        }
        options = nil
        releaseAll()
    }

    /// 音量设置，0~1，为0时表示静音(实际下发音量统一走applyVolume：muted或海报探测期间为0)
    public func playbackVolume(_ volume: CGFloat) {
        userVolume = Float(volume)
        applyVolume()
    }

    /**
     * 设置音频声道(单声道源切左右声道，双耳助听/外国语场景常用)
     * @param channel 立体声/仅左声道/仅右声道(IJKAudioChannelStereo等常量)
     */
    public func setAudioChannel(_ channel: IJKAudioChannel) {
        ijkPlayer?.setAudioChannel(channel)
    }

    /// 获取当前音频声道
    public func audioChannel() -> IJKAudioChannel {
        return ijkPlayer?.getAudioChanne() ?? IJKAudioChannelStereo
    }

    /// 设定音频延迟(单位：s)
    public func audioExtraDelay(_ delay: CGFloat) {
        ijkPlayer?.currentAudioExtraDelay = Float(delay)
    }

    /**
     * 设置退到后台是否暂停播放(默认由系统音频会话决定)
     * @param pause true=后台暂停，false=后台继续播(需后台音频权限配合)
     */
    public func setPauseInBackground(_ pause: Bool) {
        ijkPlayer?.setPauseInBackground(pause)
    }

    /// 挂载并激活字幕(本地/网络)
    @discardableResult
    public func loadThenActiveSubtitle(_ url: URL) -> Bool {
        return ijkPlayer?.loadThenActiveSubtitle(url) ?? false
    }

    /// 仅挂载不激活字幕(本地/网络)
    @discardableResult
    public func loadSubtitleOnly(_ url: URL) -> Bool {
        return ijkPlayer?.loadSubtitleOnly(url) ?? false
    }

    /// 批量挂载不激活字幕(本地/网络)
    @discardableResult
    public func loadSubtitleOnly(_ urls: [URL]) -> Bool {
        return ijkPlayer?.loadSubtitlesOnly(urls) ?? false
    }

    /// 激活字幕(没有激活的字幕调用激活，相同路径的字幕重复挂载会失败)
    public func exchangeSelectedStream(_ streamIndex: Int32) {
        ijkPlayer?.exchangeSelectedStream(streamIndex)
    }

    /// 关闭字幕(IJK_VAL_TYPE__VIDEO, IJK_VAL_TYPE__AUDIO, IJK_VAL_TYPE__SUBTITLE)
    public func closeCurrentStream(_ streamStyle: String) {
        ijkPlayer?.closeCurrentStream(streamStyle)
    }

    /// 设定字幕延迟(单位：s)
    public func subtitleExtraDelay(_ delay: CGFloat) {
        ijkPlayer?.currentSubtitleExtraDelay = Float(delay)
    }

    /// 调整字幕样式(支持设置字体，字体颜色，边框颜色，背景颜色等)
    public func subtitlePreference(_ preference: IJKSubtitlePreference) {
        ijkPlayer?.subtitlePreference = preference
    }

    /// 播放画面显示模式
    public func scalingStyle(_ style: IJKScalingMode) {
        ijkPlayer?.scalingMode = scalingStyle
        self.scalingStyle = style
    }

    /// 旋转画面
    public func rotatePreference(_ preference: IJKRotatePreference) {
        let (xDegrees, yDegrees, zDegrees): (Float, Float, Float)
        if preference.type == IJKRotateX {
            (xDegrees, yDegrees, zDegrees) = (preference.degrees, 0, 0)
        }else if preference.type == IJKRotateY {
            (xDegrees, yDegrees, zDegrees) = (0, preference.degrees, 0)
        }else if preference.type == IJKRotateZ {
            (xDegrees, yDegrees, zDegrees) = (0, 0, preference.degrees)
        }else {
            (xDegrees, yDegrees, zDegrees) = (0, 0, 0)
        }
        ijkPlayer?.view.xRotateDegrees = xDegrees
        ijkPlayer?.view.yRotateDegrees = yDegrees
        ijkPlayer?.view.zRotateDegrees = zDegrees
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }

    /// 修改画面色彩
    public func colorPreference(_ preference: IJKColorConvertPreference) {
        ijkPlayer?.view.colorPreference = preference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }

    /// 设置画面比例
    public func darPreference(_ preference: IJKDARPreference) {
        ijkPlayer?.view.darPreference = preference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }

    /**
     * 注册画面刷新回调(暂停状态下修改rotatePreference/colorPreference/darPreference后，渲染器刷新完画面会回调；nil=移除)
     * @param block 刷新完成回调
     */
    public func registerRefreshCurrentPicObserver(_ block: (() -> Void)?) {
        ijkPlayer?.view.registerRefreshCurrentPicObserver?(block)
    }

    /// 截取当前显示画面
    public func currentSnapshot() -> UIImage {
        return ijkPlayer?.view.snapshot() ?? UIImage()
    }

    /**
     * 运行时切换硬/软解码(无需停止播放；硬解花屏或兼容性问题时切软解自救)
     * @param hardware true=切硬件解码(VideoToolbox)，false=切软件解码
     * @return 是否切换成功
     */
    @discardableResult
    public func switchVideoDecoder(_ hardware: Bool) -> Bool {
        return ijkPlayer?.switchVideoDecoder(hardware) ?? false
    }

    /**
     * 开始快速录制(边播边录，速度优先；建议.mp4/.mov容器)
     * @param filePath 录制文件完整路径
     * @return 0=成功，非0=错误码
     */
    @discardableResult
    public func startFastRecord(_ filePath: String) -> Int32 {
        return ijkPlayer?.startFastRecord(filePath) ?? -1
    }

    /// 停止快速录制并落盘
    @discardableResult
    public func stopFastRecord() -> Int32 {
        return ijkPlayer?.stopFastRecord() ?? -1
    }

    /**
     * 开始精准录制(逐帧完整录制，较慢但无丢帧)
     * @param filePath 录制文件完整路径
     * @return 0=成功，非0=错误码
     */
    @discardableResult
    public func startExactRecord(_ filePath: String) -> Int32 {
        return ijkPlayer?.startExactRecord(filePath) ?? -1
    }

    /// 停止精准录制并落盘
    @discardableResult
    public func stopExactRecord() -> Int32 {
        return ijkPlayer?.stopExactRecord() ?? -1
    }

    /// 当前是否正在播放
    public func isPlaying() -> Bool {
        return ijkPlayer?.isPlaying() ?? false
    }

    /// 获取视频时长
    public func videoDuration() -> TimeInterval {
        return ijkPlayer?.duration ?? 0
    }

    /// 获取预加载时长(单位：s)
    public func playableDuration() -> TimeInterval {
        return ijkPlayer?.playableDuration ?? 0
    }

    /// 获取缓冲进度
    public func bufferingProgress() -> Int {
        return Int(ijkPlayer?.bufferingProgress ?? 0)
    }

    /// 获取下载速度(单位：byte)
    public func downloadSpeed() -> Int64 {
        return ijkPlayer?.currentDownloadSpeed() ?? 0
    }

    /// 丢帧率(0~1，反映硬解/渲染跟不上的程度)
    public func dropFrameRate() -> Float {
        return ijkPlayer?.dropFrameRate() ?? 0
    }

    /// 累计丢帧数
    public func dropFrameCount() -> Int {
        return Int(ijkPlayer?.dropFrameCount() ?? 0)
    }

    /// 视频与主时钟的偏差(单位：s，正值=视频落后于主时钟，排查音画不同步用)
    public func currentVMDiff() -> Float {
        return ijkPlayer?.currentVMDiff() ?? 0
    }

    /// 本次加载的总流量统计(单位：byte，与numberOfBytesTransferred同源)
    public func trafficStatistic() -> Int64 {
        return ijkPlayer?.trafficStatistic() ?? 0
    }

    /// 获取HUD全部键值(需shouldShowHudView场景外自行展示时使用)
    public func allHudItem() -> [AnyHashable: Any] {
        return ijkPlayer?.allHudItem() ?? [:]
    }

    /// 设置HUD自定义展示值(追加到HUD面板)
    public func setHudValue(_ value: String?, forKey key: String) {
        ijkPlayer?.setHudValue(value, forKey: key)
    }

    /// 获取支持的输入格式扩展名列表(判断文件能否播放时使用)
    public func getInputFormatExtensions() -> [String] {
        return ijkPlayer?.getInputFormatExtensions() ?? []
    }

    /// 播放器版本号(如"1.0.8")
    public static func playerVersion() -> String {
        return IJKPlayer.playerVersion()
    }

    /// 内核FFmpeg版本号(如"n7.1.3-32-g23d663f")
    public static func ffmpegVersion() -> String {
        return IJKPlayer.ffmpegVersion()
    }

    /// 支持的解码器清单(硬解能力排查用)
    public static func supportedDecoders() -> [AnyHashable: Any] {
        return IJKPlayer.supportedDecoders()
    }

    /// 开关日志上报(true=日志走上报通道)
    public static func setLogReport(_ preferLogReport: Bool) {
        IJKPlayer.setLogReport(preferLogReport)
    }

    /// 获取当前日志级别
    public static func getLogLevel() -> IJKLogLevel {
        return IJKPlayer.getLogLevel()
    }

    /**
     * 重定向日志输出(nil=恢复默认stderr输出；level/tag/msg为级别/标签/内容，业务可接自研日志系统)
     * @param handler 日志处理闭包
     */
    public static func setLogHandler(_ handler: ((IJKLogLevel, String, String) -> Void)?) {
        IJKPlayer.setLogHandler(handler)
    }

    /// 释放播放器组件
    public func releaseAll() {

        guard let player = ijkPlayer else {
            return
        }
        player.stop()

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerDidFinish, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerPlaybackStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerLoadStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerFirstVideoFrameRendered, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerIsPreparedToPlay, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerSelectedStreamDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerCurrentPlaybackTimeDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerDidSeekComplete, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerAccurateSeekComplete, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerFirstAudioFrameRendered, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerFirstAudioFrameDecoded, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerFirstVideoFrameDecoded, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerAfterSeekFirstVideoFrameDisplay, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerNaturalSizeAvailable, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerVideoDecoderOpen, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerVideoDecoderFatal, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerNoCodecFound, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerRecvWarning, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerICYMetaChanged, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(IJKPlayerSelectingStreamDidFailed), object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerBufferingDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKPlayerIsAirPlayVideoActiveDidChange, object: ijkPlayer)

        // 安全地移除视图
        if let playerView = self.ijkPlayer?.view, playerView.superview != nil {
            playerView.removeFromSuperview()
        }

        // 关闭播放器
        ijkPlayer?.shutdown()

        // 最后才置为 nil
        ijkPlayer = nil
        state = .unknown
        mediaUrl = ""
        hasRenderedFirstFrame = false
        isPosterProbing = false
        // 真播放标记随实例复位：新加载从"未真播放"开始，期间一切paused静默
        hasReallyPlayed = false
        isPreparedToPlay = false
        isPlayPending = false
        isPausedWhilePreparing = false
    }

    /// 当前已重试失败次数
    private var failReplayNumber: Int = 0

    /// 本次加载的起播意图(play(with:)走shouldAutoplay、prepare(with:)恒为false；驱动start-on-prepared、实例autoplay、海报探测条件与缓冲上限)
    private var loadAutoplayIntent: Bool = true

    /// 加载代号(每次load推进，供延迟重试校验期间是否又发起了新加载，防止迟到的重试覆盖新加载)
    private var loadGeneration: Int = 0

    /// 当前实例是否已prepare完成(IJKPlayerIsPreparedToPlay回调处置true、releaseAll换实例时重置，供play()判断能否立即起播)
    private var isPreparedToPlay: Bool = false

    /// 挂起的播放意图(play()在prepare完成前被调用时置true，prepare完成回调补执行；pause()与releaseAll会取消)
    private var isPlayPending: Bool = false

    /// prepare期间收到的暂停意图(pause()在未就绪时置true)：play(with:)默认autoplay会把start-on-prepared=1烘进内核，prepare完成瞬间内核自行起播，未就绪时的pause调用拦不住它——记下意图由prepared回调抢先压住(表现为play后快速pause、画面已切走而声音在prepare完成后响起)；play()的挂起会覆盖它，releaseAll复位
    private var isPausedWhilePreparing: Bool = false

    /// 本次加载是否已渲染出第一帧(首帧渲染回调处置true、releaseAll时重置，供开关didSet补截与渲染时截取判断)
    private var hasRenderedFirstFrame: Bool = false

    /// 是否正处于海报(首帧)探测中(预加载不起播时管线不渲染首帧、首帧通知不触发，探测=静音起播直到首帧渲染后立即暂停回预备态，期间靠该标记收尾)
    private var isPosterProbing: Bool = false

    /// 本次加载是否真正播放过(非探测的.playing通知出现过即置位，releaseAll/重新load时复位)：未真播放过的实例一切.paused状态只静默不通知——IJKPlayer在实例初始化(prepare阶段即发)与海报探测收尾都会自发paused，它们与"用户主动暂停"同用.paused无法区分，只有真播放之后的暂停才是业务关心的
    private var hasReallyPlayed: Bool = false

    /// 用户设置的音量(0~1，经playbackVolume(_:)记录；实际下发音量统一走applyVolume：muted或海报探测期间为0)
    private var userVolume: Float = 1

    /// 统一下发实际音量：muted或海报探测期间为0，否则为userVolume(新建实例/变更静音/探测起止都调这里，保证互不覆盖)
    private func applyVolume() {
        ijkPlayer?.playbackVolume = (muted || isPosterProbing) ? 0 : userVolume
    }

    /// 状态去重后回调代理(与上次相同的状态不重复通知)
    private func callback(with currentState: WYMediaPlayerState) {
        guard currentState != state else {
            return
        }
        // 滤除内部状态噪声，只静默通知不改状态属性(读state的业务仍能拿到真实值)：探测起播的瞬时.playing是静音探测并非真播放；未真播放过的.paused只代表"初始化/探测收尾/待播预备"——不滤的话业务无法用.paused区分"预加载待播"与"用户主动暂停"(预加载误关loading或真暂停误转loading)
        if (currentState == .playing) && isPosterProbing {
            state = currentState
        }else if (currentState == .playing) {
            // 非探测的playing=真正开始播放，此后的paused才有资格回调
            hasReallyPlayed = true
            state = currentState
            delegate?.wy_mediaPlayerStateDidChanged?(self, state: state)
        }else if (currentState == .paused) && (hasReallyPlayed == false) {
            state = currentState
        }else {
            state = currentState
            delegate?.wy_mediaPlayerStateDidChanged?(self, state: state)
        }
    }

    /**
     * 加载流地址的统一私有入口
     * @param url 要加载的流地址
     * @param placeholder 视屏背景图占位图
     * @param autoplay 本次加载的起播意图(play走shouldAutoplay保持兼容，prepare恒为false)
     * @param keepCurrentImage 重试场景传入true以保留已有画面(海报)不清屏
     */
    private func load(with url: String, placeholder: UIImage?, autoplay: Bool, keepCurrentImage: Bool = false) {

        // 每次加载重置真播放标记：新实例/换源期间的paused全是内部噪声
        hasReallyPlayed = false

        guard let playUrl = URL(string: url) else {
            callback(with: .playUrlEmpty)
            return
        }

        // 重试场景保留已有画面(海报)不清屏
        if keepCurrentImage == false {
            image = nil
        }
        isUserInteractionEnabled = true

        if mediaUrl != url {
            failReplayNumber = 0
        }

        // 推进加载代号：迟到的延迟重试若发现代号变了，说明期间发起了新加载，直接放弃
        loadGeneration &+= 1
        loadAutoplayIntent = autoplay

        releaseAll()

        // 加载发起即通知缓冲态：业务据此在预加载/换源全程先挂loading，到ready/rendered解除——拉流期间组件没有其他可显示loading的状态通知(unknown/buffering类通知prepared之后才开始)，而历史上的预加载loading其实是被IJKPlayer初始化的内部paused误触发的，内部paused被滤除后若不补这一声，预加载全程无loading
        callback(with: .buffering)

        createPlayer(with: playUrl)

        // 先隐藏渲染view，因为无法设置其背景色(始终为黑色)等信息，等第一帧渲染完成后再设为false，这样就可以自定义背景色、背景图等信息了
        ijkPlayer?.view.isHidden = true

        ijkPlayer?.prepareToPlay()

        mediaUrl = url

        if keepCurrentImage == false {
            image = placeholder
        }
    }

    /// 创建播放器组件
    private func createPlayer(with playUrl: URL) {

        if options == nil {
            options = IJKOptions.byDefault()

            // 直播时可以设置成无限读包
            options?.setPlayerOptionIntValue(1, forKey: "infbuf")

            // 缓冲队列空是否需要加载一些数据后才能播放，0即为有数据就播放
            options?.setPlayerOptionIntValue(1, forKey: "packet-buffering")

            // 视频帧处理不过来的时候丢弃一些帧达到同步的效果
            options?.setPlayerOptionIntValue(1, forKey: "framedrop")

            // 视频帧缓存数量上限
            options?.setPlayerOptionIntValue(6, forKey: "video-pictq-size")

            // 停止预加载的最小（未解码的）帧数
            options?.setPlayerOptionIntValue(25, forKey: "min-frames")

            // 设置 mgeg-ts 视频 seek 时过滤非关键帧，能够解决花屏问题
            options?.setFormatOptionIntValue(1, forKey: "seek_flag_keyframe")

            // 设置探测数据上限，默认是 5000000，但是一些超高码率的视频会探测失败，或者探测信息不全
            options?.setPlayerOptionIntValue(1024 * 5, forKey: "probesize")

            // 开启 cvpixelbufferpool提升性能
            options?.setPlayerOptionIntValue(0, forKey: "enable-cvpixelbufferpool")

            // 使用硬件加速解码视频帧，降低 CPU 消耗
            options?.setPlayerOptionIntValue(1, forKey: "videotoolbox_hwaccel")

            // 开启精准 seek，避免进度回退
            options?.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")

            // 精准 seek 超时时长，单位ms
            options?.setPlayerOptionIntValue(1500, forKey: "accurate-seek-timeout")

            // 启用 VideoToolbox 硬件解码（iOS/macOS）
            options?.setPlayerOptionIntValue(1, forKey: "videotoolbox")

            // 设置视频帧率，29.97对应NTSC制式标准帧率
            options?.setPlayerOptionIntValue(Int64(29.97), forKey: "r")

            // 设置音频音量，512为默认值（512 = 100%）
            options?.setPlayerOptionIntValue(512, forKey: "vol")

            // 设置环路滤波器跳过级别，48表示跳过所有非参考帧的环路滤波
            options?.setPlayerOptionIntValue(48, forKey: "skip_loop_filter")

            // 网络断开时自动重连
            options?.setPlayerOptionIntValue(1, forKey: "reconnect")

            // 设置最大帧率限制，防止帧率过高消耗资源
            options?.setPlayerOptionIntValue(30, forKey: "max-fps")

            // 禁用HTTP range检测，适用于不支持range请求的服务器
            options?.setPlayerOptionIntValue(0, forKey: "http-detect-range-support")

            // 设置跳帧类型，8表示跳过非参考帧（B帧）
            options?.setPlayerOptionIntValue(8, forKey: "skip_frame")

            // 每次播放前清除DNS缓存，解决DNS变更问题
            options?.setFormatOptionIntValue(1, forKey: "dns_cache_clear")
        }

        // 以下选项每次创建实例都按当前值重新写入(options会被复用，写在options==nil块内的项后续修改不生效)
        options?.setPlayerOptionIntValue(looping, forKey: "loop")
        options?.setPlayerOptionIntValue(loadAutoplayIntent ? 1 : 0, forKey: "start-on-prepared")
        // 缓冲上限按加载意图区分：预加载4MB省流量省内存，起播15MB对齐ijk默认
        options?.setPlayerOptionIntValue(loadAutoplayIntent ? 15 * 1024 * 1024 : 4 * 1024 * 1024, forKey: "max-buffer-size")

        options?.currentPlaybackTimeNotificationInterval = progressCallbackInterval

        if let videoRendering = videoRendering {
            ijkPlayer = IJKPlayer(content: playUrl.absoluteString, options: options, videoRendering: videoRendering, audioRendering: audioRendering)
        }else {
            ijkPlayer = IJKPlayer(content: playUrl.absoluteString, options: options)
        }
        if let audioSamplesCallback = audioSamplesCallback {
            ijkPlayer?.audioSamplesCallback = audioSamplesCallback
        }
        refreshUrlOpenDelegates()
        ijkPlayer?.shouldAutoplay = loadAutoplayIntent
        ijkPlayer?.view.frame = bounds
        ijkPlayer?.scalingMode = scalingStyle
        ijkPlayer?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview((ijkPlayer?.view)!)
        applyVolume()
        IJKPlayer.setLogLevel(logLevel)

        // 播流完成回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerDidFinished(notification:)), name: NSNotification.Name.IJKPlayerDidFinish, object: ijkPlayer)

        // 用户操作行为回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerPlayStateDidChange(notification:)), name: NSNotification.Name.IJKPlayerPlaybackStateDidChange, object: ijkPlayer)

        // 直播加载状态回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidChange(notification:)), name: NSNotification.Name.IJKPlayerLoadStateDidChange, object: ijkPlayer)

        // 渲染回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidRendered(notification:)), name: NSNotification.Name.IJKPlayerFirstVideoFrameRendered, object: ijkPlayer)

        // 字幕流(开始)回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerSubtitleStreamPrepared(notification:)), name: NSNotification.Name.IJKPlayerIsPreparedToPlay, object: ijkPlayer)

        // 字幕流(改变或结束)回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerSubtitleStreamDidChange(notification:)), name: NSNotification.Name.IJKPlayerSelectedStreamDidChange, object: ijkPlayer)

        // 播放进度回调(IJKPlayer原生播放时间变化通知，播放期间持续触发)
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerCurrentPlaybackTimeDidChanged(notification:)), name: NSNotification.Name.IJKPlayerCurrentPlaybackTimeDidChange, object: ijkPlayer)

        // 普通seek完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerDidSeekComplete(notification:)), name: NSNotification.Name.IJKPlayerDidSeekComplete, object: ijkPlayer)

        // 精准seek完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerDidAccurateSeekComplete(notification:)), name: NSNotification.Name.IJKPlayerAccurateSeekComplete, object: ijkPlayer)

        // 首帧音频渲染完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerFirstAudioFrameRendered(notification:)), name: NSNotification.Name.IJKPlayerFirstAudioFrameRendered, object: ijkPlayer)

        // 首帧音频解码完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerFirstAudioFrameDecoded(notification:)), name: NSNotification.Name.IJKPlayerFirstAudioFrameDecoded, object: ijkPlayer)

        // 首帧视频解码完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerFirstVideoFrameDecoded(notification:)), name: NSNotification.Name.IJKPlayerFirstVideoFrameDecoded, object: ijkPlayer)

        // seek后首帧视频显示完成
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerAfterSeekFirstVideoFrameDisplay(notification:)), name: NSNotification.Name.IJKPlayerAfterSeekFirstVideoFrameDisplay, object: ijkPlayer)

        // 视频原始尺寸就绪
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerNaturalSizeAvailable(notification:)), name: NSNotification.Name.IJKPlayerNaturalSizeAvailable, object: ijkPlayer)

        // 视频解码器打开(可得知硬解/软解)
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerVideoDecoderOpen(notification:)), name: NSNotification.Name.IJKPlayerVideoDecoderOpen, object: ijkPlayer)

        // 视频解码器致命错误
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerVideoDecoderFatal(notification:)), name: NSNotification.Name.IJKPlayerVideoDecoderFatal, object: ijkPlayer)

        // 未找到可用解码器
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerNoCodecFound(notification:)), name: NSNotification.Name.IJKPlayerNoCodecFound, object: ijkPlayer)

        // 播放器内部警告
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerRecvWarning(notification:)), name: NSNotification.Name.IJKPlayerRecvWarning, object: ijkPlayer)

        // ICY电台元数据变化
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerICYMetaChanged(notification:)), name: NSNotification.Name.IJKPlayerICYMetaChanged, object: ijkPlayer)

        // 选流失败(该常量名不以Notification结尾，Swift导入为String，需包一层NSNotification.Name)
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerSelectingStreamDidFailed(notification:)), name: NSNotification.Name(IJKPlayerSelectingStreamDidFailed), object: ijkPlayer)

        // 缓冲进度变化
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerBufferingDidChange(notification:)), name: NSNotification.Name.IJKPlayerBufferingDidChange, object: ijkPlayer)

        // AirPlay(无线)投放状态变化
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerAirPlayActiveDidChange(notification:)), name: NSNotification.Name.IJKPlayerIsAirPlayVideoActiveDidChange, object: ijkPlayer)
    }

    /// 转发播放进度给代理： currentTime 当前播放位置， duration 总时长， playableDuration 已缓冲可播时长
    @objc private func ijkPlayerCurrentPlaybackTimeDidChanged(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerProgressDidChanged?(self, currentTime: player.currentPlaybackTime, duration: player.duration, playableDuration: player.playableDuration)
    }

    @objc private func ijkPlayerDidFinished(notification: Notification) {

        if let reason: IJKFinishReason = notification.userInfo?[IJKPlayerDidFinishReasonUserInfoKey] as? IJKFinishReason {
            switch reason {
            case .playbackEnded:
                callback(with: .ended)
            case .playbackError:
                callback(with: .error)
                if failReplayNumber < failReplay {
                    failReplayNumber += 1
                    let generation: Int = loadGeneration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self = self, self.loadGeneration == generation, self.mediaUrl.isEmpty == false else { return }
                        self.load(with: self.mediaUrl, placeholder: nil, autoplay: self.loadAutoplayIntent, keepCurrentImage: true)
                    }
                }else {
                    releaseAll()
                }
            case .userExited:
                callback(with: .userExited)
            default:
                break
            }
        }
    }

    @objc private func ijkPlayerPlayStateDidChange(notification: Notification) {

        guard let player = ijkPlayer else { return }

        switch player.playbackState {
        case .playing:
            callback(with: .playing)
        case .paused:
            callback(with: .paused)
        case .interrupted:
            callback(with: .interrupted)
        case .seekingForward:
            callback(with: .seekingForward)
        case .seekingBackward:
            callback(with: .seekingBackward)
        case .stopped:
            callback(with: .ended)
        default:
            break
        }
    }

    @objc private func ijkPlayerLoadStateDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }

        let loadState = player.loadState
        if loadState.contains(.stalled) {
            callback(with: .buffering)
        }else if loadState.contains(.playthroughOK) {
            if state == .playing { return }
            if state == .buffering, player.isPlaying() {
                callback(with: .playing)
            }else {
                callback(with: .ready)
            }
        }else if loadState.contains(.playable) {
            if state == .playing { return }
            callback(with: .playable)
        }else {
            if state == .playing || state == .buffering { return }
            callback(with: .unknown)
        }
    }

    @objc private func ijkPlayerLoadStateDidRendered(notification: Notification) {
        // 首帧就绪取消隐藏并短促淡入，配合海报避免封面到视频的生硬切换
        if let renderView: UIView = ijkPlayer?.view {
            renderView.isHidden = false
            renderView.alpha = 0
            UIView.animate(withDuration: 0.25) {
                renderView.alpha = 1
            }
        }
        hasRenderedFirstFrame = true
        if shouldUseFirstFrameAsPoster {
            image = ijkPlayer?.thumbnailImageAtCurrentTime()
        }
        // 首帧已渲染并截取，立即暂停回预备态并经applyVolume恢复音量(探测期间静音，不会漏出声音)
        if isPosterProbing {
            isPosterProbing = false
            ijkPlayer?.pause()
            applyVolume()
        }
        callback(with: .rendered)
    }

    @objc private func ijkPlayerSubtitleStreamPrepared(notification: Notification) {
        guard let player = ijkPlayer else { return }
        isPreparedToPlay = true
        if isPlayPending {
            isPlayPending = false
            player.play()
        }else if isPausedWhilePreparing {
            // prepare期间业务已暂停：压制内核start-on-prepared的自动起播(pause()在未就绪时拦不住它)，停在就绪待播态
            isPausedWhilePreparing = false
            player.pause()
        }else if loadAutoplayIntent == false, shouldUseFirstFrameAsPoster, hasRenderedFirstFrame == false, isPosterProbing == false {
            if let posterImage: UIImage = player.thumbnailImageAtCurrentTime() {
                image = posterImage
            }else {
                isPosterProbing = true
                // 探测期间静音统一走applyVolume(与muted互锁，不再手动存取恢复音量)
                applyVolume()
                player.play()
            }
        }
        delegate?.wy_mediaPlayerSubtitleStreamDidChanged?(self, mediaMeta: player.monitor.mediaMeta)
    }

    @objc private func ijkPlayerSubtitleStreamDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerSubtitleStreamDidChanged?(self, mediaMeta: player.monitor.mediaMeta)
    }

    /// 普通seek完成：取目标时间与错误码转发
    @objc private func ijkPlayerDidSeekComplete(notification: Notification) {
        guard let player = ijkPlayer else { return }
        let target = (notification.userInfo?[IJKPlayerDidSeekCompleteTargetKey] as? NSNumber)?.doubleValue ?? player.currentPlaybackTime
        let error = (notification.userInfo?[IJKPlayerDidSeekCompleteErrorKey] as? NSNumber)?.intValue ?? 0
        delegate?.wy_mediaPlayerDidSeekComplete?(self, target: target, error: error)
    }

    /// 精准seek完成：取完成后的当前位置转发
    @objc private func ijkPlayerDidAccurateSeekComplete(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let curPos = (notification.userInfo?[IJKPlayerDidAccurateSeekCompleteCurPos] as? NSNumber)?.doubleValue ?? currentPlaybackTime
        delegate?.wy_mediaPlayerDidAccurateSeekComplete?(self, currentPosition: curPos)
    }

    /// 首帧音频渲染完成
    @objc private func ijkPlayerFirstAudioFrameRendered(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstAudioFrameRendered?(self)
    }

    /// 首帧音频解码完成
    @objc private func ijkPlayerFirstAudioFrameDecoded(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstAudioFrameDecoded?(self)
    }

    /// 首帧视频解码完成
    @objc private func ijkPlayerFirstVideoFrameDecoded(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstVideoFrameDecoded?(self)
    }

    /// seek后首帧视频显示完成
    @objc private func ijkPlayerAfterSeekFirstVideoFrameDisplay(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerDidSeekFirstVideoFrameDisplayed?(self)
    }

    /// 视频原始尺寸就绪：转发当前naturalSize
    @objc private func ijkPlayerNaturalSizeAvailable(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerNaturalSizeDidChanged?(self, naturalSize: player.naturalSize)
    }

    /// 解码器打开：转发monitor记录的解码器名
    @objc private func ijkPlayerVideoDecoderOpen(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerVideoDecoderOpen?(self, decoderName: player.monitor.vdecoder ?? "")
    }

    /// 解码器致命错误：转发错误码并置state为error(收到后建议停止播放)
    @objc private func ijkPlayerVideoDecoderFatal(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let errorCode = (notification.userInfo?["code"] as? NSNumber)?.intValue ?? 0
        callback(with: .error)
        delegate?.wy_mediaPlayerVideoDecoderFatal?(self, errorCode: errorCode)
    }

    /// 未找到可用解码器：置state为error并转发
    @objc private func ijkPlayerNoCodecFound(notification: Notification) {
        guard ijkPlayer != nil else { return }
        callback(with: .error)
        delegate?.wy_mediaPlayerNoCodecFound?(self)
    }

    /// 播放器内部警告
    @objc private func ijkPlayerRecvWarning(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let reason = (notification.userInfo?[IJKPlayerWarningReasonUserInfoKey] as? NSNumber)?.intValue ?? 0
        delegate?.wy_mediaPlayerRecvWarning?(self, reason: reason)
    }

    /// ICY电台元数据变化：原样转发userInfo字典
    @objc private func ijkPlayerICYMetaChanged(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerICYMetaDidChanged?(self, meta: notification.userInfo ?? [:])
    }

    /// 选流失败：取流下标与错误码转发
    @objc private func ijkPlayerSelectingStreamDidFailed(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let streamID = (notification.userInfo?[IJKPlayerSelectingStreamIDUserInfoKey] as? NSNumber)?.int32Value ?? 0
        let errorCode = (notification.userInfo?[IJKPlayerSelectingStreamErrUserInfoKey] as? NSNumber)?.int32Value ?? 0
        delegate?.wy_mediaPlayerSelectingStreamDidFailed?(self, streamID: streamID, errorCode: errorCode)
    }

    /// 缓冲进度变化：转发当前缓冲百分比
    @objc private func ijkPlayerBufferingDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerBufferingDidChanged?(self, bufferingProgress: Int(player.bufferingProgress))
    }

    /// AirPlay(无线)投放状态变化
    @objc private func ijkPlayerAirPlayActiveDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerAirPlayActiveDidChanged?(self, active: player.airPlayMediaActive)
    }

    /// URL打开事件统一转发代理：IJKPlayerKit的四个*OpenDelegate声明为retain，直接挂self会循环引用，经此weak代理中转
    private class WYMediaUrlOpenProxy: NSObject, IJKMediaUrlOpenDelegate {

        /// 弱引用业务播放器，避免player→proxy→player循环
        weak var target: WYMediaPlayer?

        /// IJKPlayerKit要求实现：按event原始值分发(0x20001=TCP/0x20003=HTTP/0x20005=直播/0x20007=HLS分片，取值定义于IJKMediaPlayback.h的IJKMediaCtrl_*且属内核ABI不会变更；枚举名Swift导入有歧义故用rawValue)
        func willOpenUrl(_ urlOpenData: IJKMediaUrlOpenData) {
            guard let target = target else { return }
            switch urlOpenData.event.rawValue {
            case 0x20001:
                target.willOpenTcpUrl?(urlOpenData)
            case 0x20003:
                target.willOpenHttpUrl?(urlOpenData)
            case 0x20005:
                target.willOpenLiveUrl?(urlOpenData)
            case 0x20007:
                target.willOpenSegmentUrl?(urlOpenData)
            default:
                break
            }
        }
    }

    /// 当前使用的URL打开转发代理(懒加载，四个闭包全空时不挂到player)
    private lazy var urlOpenProxy: WYMediaUrlOpenProxy = {
        let proxy = WYMediaUrlOpenProxy()
        proxy.target = self
        return proxy
    }()

    /// 按需挂/摘四个URL打开代理：任一闭包非空才挂proxy(避免无谓的回调链路)，全空置nil
    private func refreshUrlOpenDelegates() {
        let needsProxy = willOpenSegmentUrl != nil || willOpenTcpUrl != nil || willOpenHttpUrl != nil || willOpenLiveUrl != nil
        ijkPlayer?.segmentOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.tcpOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.httpOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.liveOpenDelegate = needsProxy ? urlOpenProxy : nil
    }

    deinit {
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
