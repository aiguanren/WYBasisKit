//
//  WYMediaPlayer+LoadCore.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

#if canImport(IJKPlayerKit)

import IJKPlayerKit

/// WYMediaPlayer 私有实现：加载相关(统一下发音量、统一加载入口、创建播放器实例)
extension WYMediaPlayer {
    /// 把背景色换算成0~255的RGB分量设置给渲染视图(纯白/纯黑这类灰度色走白色分量换算；实例还没创建时设置不到，等下次创建实例时会再调一次补上；属性didSet和createPlayer两处都会调用)
    func applyRenderBackgroundColor() {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if renderBackgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            ijkPlayer?.view.setBackgroundColor?(UInt8(red * 255), g: UInt8(green * 255), b: UInt8(blue * 255))
        }else if renderBackgroundColor.getWhite(&red, alpha: &alpha) {
            ijkPlayer?.view.setBackgroundColor?(UInt8(red * 255), g: UInt8(red * 255), b: UInt8(red * 255))
        }
    }

    /// 统一下发实际音量：muted或海报探测期间为0，否则为userVolume(新建实例/变更静音/探测起止都调这里，保证互不覆盖)
    func applyVolume() {
        ijkPlayer?.playbackVolume = (muted || isPosterProbing) ? 0 : userVolume
    }

    /**
     * 加载流地址的统一私有入口
     * @param url 要加载的流地址
     * @param placeholder 视频占位图，加载期间先显示它
     * @param autoplay 本次加载完成后要不要自动播放(play走shouldAutoplay保持兼容，prepare固定为false)
     * @param keepCurrentImage 重试场景传入true以保留已有画面(海报)不清屏
     */
    func load(with url: String, placeholder: UIImage?, autoplay: Bool, keepCurrentImage: Bool = false) {

        // 每次加载重置真播放标记：新实例/换源期间的paused全是内部噪声
        hasReallyPlayed = false
        // 新加载清除准备期暂停意图：本次加载自带起播意图(autoplay参数)，旧的暂停意图若不清除会在prepare完成时压住起播，导致本次加载不起播
        isPausedWhilePreparing = false

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

        // 加载代号+1：延迟1秒才执行的失败重试回来时先核对代号，发现变了说明期间发起了新加载，直接放弃
        loadGeneration &+= 1
        loadAutoplayIntent = autoplay

        releaseAll()

        // 一发起加载就通知业务进入缓冲状态：让业务从头就能挂上loading转圈，到ready/rendered再解除；因为缓冲类的状态通知要等prepare完成才会出现，不提前补这一声，加载全程都没有一个状态能让业务挂loading
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
        // 新实例补发背景色(set发生在加载前时渲染视图还不存在，didSet下发无效)
        applyRenderBackgroundColor()
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
}

#endif
