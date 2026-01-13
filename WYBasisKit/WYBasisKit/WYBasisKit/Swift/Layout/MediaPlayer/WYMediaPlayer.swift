//
//  WYMediaPlayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

#if canImport(FSPlayer)

import FSPlayer

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
    @objc optional func mediaPlayerDidChangeState(player: WYMediaPlayer, state: WYMediaPlayerState)
    
    /// 音视频字幕流信息
    @objc optional func mediaPlayerDidChangeSubtitleStream(player: WYMediaPlayer, mediaMeta: [AnyHashable: Any])
}

public class WYMediaPlayer: UIImageView {
    
    /// 播放器组件
    public var ijkPlayer: FSPlayer?
    
    /// 当前正在播放的流地址
    public private(set) var mediaUrl: String = ""
    
    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
    public var options: FSOptions?
    
    /// 播放器状态回调代理
    public weak var delegate: WYMediaPlayerDelegate?
    
    /// 循环播放的次数，为0表示无限次循环(点播流有效)
    public var looping: Int64 = 0
    
    /// 播放失败后重试次数，默认2次
    public var failReplay: Int = 2
    
    /// 是否需要自动播放
    public var shouldAutoplay: Bool = true
    
    /// 视频缩放模式
    public var scalingStyle: FSScalingMode = .aspectFit
    
    /// 播放器状态
    public private(set) var state: WYMediaPlayerState = .unknown
    
    /// 当前时间点的缩略图
    public var thumbnailImageAtCurrentTime: UIImage? {
        return ijkPlayer?.thumbnailImageAtCurrentTime()
    }
    
    /**
     * 开始播放
     * @param url 要播放的流地址
     * @param background 视屏背景图(支持UIImage、URL、String)
     * @param placeholder 视屏背景图占位图
     */
    public func play(with url: String, placeholder: UIImage? = nil) {
        
        guard let playUrl = URL(string: url) else {
            callback(with: .playUrlEmpty)
            return
        }
        
        image = nil
        isUserInteractionEnabled = true
        
        if mediaUrl != url {
            failReplayNumber = 0
        }
        
        releaseAll()
        createPlayer(with: playUrl)
        
        // 先隐藏渲染view，因为无法设置其背景色(始终为黑色)等信息，等第一帧渲染完成后再设为false，这样就可以自定义背景色、背景图等信息了
        ijkPlayer?.view.isHidden = true
        
        ijkPlayer?.prepareToPlay()
        
        mediaUrl = url
        
        image = placeholder
    }
    
    /// 音量设置，为0时表示静音
    public func playbackVolume(_ volume: CGFloat) {
        ijkPlayer?.playbackVolume = Float(volume)
    }
    
    /// 继续播放(仅适用于暂停后恢复播放)
    public func play() {
        ijkPlayer?.play()
    }
    
    /// 快进/快退
    public func playbackTime(_ time: TimeInterval) {
        ijkPlayer?.currentPlaybackTime = time
    }
    
    /// 倍速播放
    public func playbackRate(_ rate: CGFloat) {
        ijkPlayer?.playbackRate = Float(rate)
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
    
    /// 关闭字幕(FS_VAL_TYPE__VIDEO, FS_VAL_TYPE__AUDIO, FS_VAL_TYPE__SUBTITLE)
    public func closeCurrentStream(_ streamStyle: String) {
        ijkPlayer?.closeCurrentStream(streamStyle)
    }
    
    /// 播放画面显示模式
    public func scalingStyle(_ style: FSScalingMode) {
        ijkPlayer?.scalingMode = scalingStyle
        self.scalingStyle = style
    }
    
    /// 逐帧播放
    public func stepToNextFrame() {
        ijkPlayer?.stepToNextFrame()
    }
    
    /// 获取缓冲进度
    public func bufferingProgress() -> Int {
        return ijkPlayer?.bufferingProgress ?? 0
    }
    
    /// 获取视频时长
    public func videoDuration() -> TimeInterval {
        return ijkPlayer?.duration ?? 0
    }
    
    /// 设定音频延迟(单位：s)
    public func audioExtraDelay(_ delay: CGFloat) {
        ijkPlayer?.currentAudioExtraDelay = Float(delay)
    }
    
    /// 设定字幕延迟(单位：s)
    public func subtitleExtraDelay(_ delay: CGFloat) {
        ijkPlayer?.currentSubtitleExtraDelay = Float(delay)
    }
    
    /// 获取预加载时长(单位：s)
    public func playableDuration() -> TimeInterval {
        return ijkPlayer?.playableDuration ?? 0
    }
    
    /// 获取下载速度(单位：byte)
    public func downloadSpeed() -> Int64 {
        return ijkPlayer?.currentDownloadSpeed() ?? 0
    }
    
    /// 暂停播放
    public func pause() {
        ijkPlayer?.pause()
    }
    
    /// 截取当前显示画面
    public func currentSnapshot() -> UIImage {
        return ijkPlayer?.view.snapshot() ?? UIImage()
    }
    
    /// 调整字幕样式(支持设置字体，字体颜色，边框颜色，背景颜色等)
    public func subtitlePreference(_ preference: FSSubtitlePreference) {
        ijkPlayer?.subtitlePreference = preference
    }
    
    /// 旋转画面
    public func rotatePreference(_ preference: FSRotatePreference) {
        ijkPlayer?.view.rotatePreference = preference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }
    
    /// 修改画面色彩
    public func colorPreference(_ preference: FSColorConvertPreference) {
        ijkPlayer?.view.colorPreference = preference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }
    
    /// 设置画面比例
    public func darPreference(_ preference: FSDARPreference) {
        ijkPlayer?.view.darPreference = preference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
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
    
    /// 释放播放器组件
    public func releaseAll() {
        
        guard let player = ijkPlayer else {
            return
        }
        player.stop()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerDidFinish, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerPlaybackStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerLoadStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerFirstVideoFrameRendered, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerIsPreparedToPlay, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.FSPlayerSelectedStreamDidChange, object: ijkPlayer)
        
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
    }
    
    /// 当前已重试失败次数
    private var failReplayNumber: Int = 0
    
    /// 创建播放器组件
    private func createPlayer(with playUrl: URL) {
        
        if options == nil {
            options = FSOptions.byDefault()
            
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
            
            // 循环播放的次数，为0表示无限次循环(点播流有效)
            options?.setPlayerOptionIntValue(looping, forKey: "loop")
            
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
            
            // 准备完成后自动开始播放
            options?.setPlayerOptionIntValue(1, forKey: "start-on-prepared")
            
            // 设置跳帧类型，8表示跳过非参考帧（B帧）
            options?.setPlayerOptionIntValue(8, forKey: "skip_frame")
            
            // 每次播放前清除DNS缓存，解决DNS变更问题
            options?.setFormatOptionIntValue(1, forKey: "dns_cache_clear")
        }
        ijkPlayer = FSPlayer(contentURL: playUrl, with: options)
        ijkPlayer?.shouldAutoplay = shouldAutoplay
        ijkPlayer?.view.frame = bounds
        ijkPlayer?.scalingMode = scalingStyle
        ijkPlayer?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview((ijkPlayer?.view)!)
        FSPlayer.setLogLevel(FS_LOG_ERROR)
        
        // 播流完成回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerDidFinished(notification:)), name: NSNotification.Name.FSPlayerDidFinish, object: ijkPlayer)
        
        // 用户操作行为回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerPlayStateDidChange(notification:)), name: NSNotification.Name.FSPlayerPlaybackStateDidChange, object: ijkPlayer)
        
        // 直播加载状态回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidChange(notification:)), name: NSNotification.Name.FSPlayerLoadStateDidChange, object: ijkPlayer)
        
        // 渲染回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidRendered(notification:)), name: NSNotification.Name.FSPlayerFirstVideoFrameRendered, object: ijkPlayer)
        
        // 字幕流(开始)回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerSubtitleStreamPrepared(notification:)), name: NSNotification.Name.FSPlayerIsPreparedToPlay, object: ijkPlayer)
        
        // 字幕流(改变或结束)回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerSubtitleStreamDidChange(notification:)), name: NSNotification.Name.FSPlayerSelectedStreamDidChange, object: ijkPlayer)
    }
    
    @objc private func ijkPlayerDidFinished(notification: Notification) {
        
        if let reason: FSFinishReason = notification.userInfo?[FSPlayerDidFinishReasonUserInfoKey] as? FSFinishReason {
            switch reason {
            case .playbackEnded:
                callback(with: .ended)
            case .playbackError:
                callback(with: .error)
                
                if failReplayNumber < failReplay {
                    failReplayNumber += 1
                    play(with: mediaUrl)
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
        
        switch player.loadState {
        case .playable:
            callback(with: .playable)
        case .playthroughOK:
            callback(with: .ready)
        case .stalled:
            callback(with: .buffering)
        default:
            callback(with: .unknown)
        }
    }
    
    @objc private func ijkPlayerLoadStateDidRendered(notification: Notification) {
        ijkPlayer?.view.isHidden = false
        callback(with: .rendered)
    }
    
    @objc private func ijkPlayerSubtitleStreamPrepared(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.mediaPlayerDidChangeSubtitleStream?(player: self, mediaMeta: player.monitor.mediaMeta)
    }
    
    @objc private func ijkPlayerSubtitleStreamDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.mediaPlayerDidChangeSubtitleStream?(player: self, mediaMeta: player.monitor.mediaMeta)
    }
    
    private func callback(with currentState: WYMediaPlayerState) {
        guard currentState != state else {
            return
        }
        state = currentState
        delegate?.mediaPlayerDidChangeState?(player: self, state: state)
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
