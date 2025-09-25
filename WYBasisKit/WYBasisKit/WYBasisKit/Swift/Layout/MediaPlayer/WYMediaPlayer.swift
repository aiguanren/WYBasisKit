//
//  WYMediaPlayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

#if WYBasisKit_Supports_MediaPlayer_FS

import FSPlayer

/// 播放器状态回调
@objc @frozen public enum WYMediaPlayerState: Int {
    /// 未知状态
    case unknown
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
    @objc optional func mediaPlayerDidChangeState(_ player: WYMediaPlayer, _ state: WYMediaPlayerState)
    
    /// 音视频字幕流信息
    @objc optional func mediaPlayerDidChangeSubtitleStream(_ player: WYMediaPlayer, _ mediaMeta: [AnyHashable: Any])
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
        
        release()
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
    public func playbackTime(_ playbackTime: TimeInterval) {
        ijkPlayer?.currentPlaybackTime = playbackTime
    }
    
    /// 倍速播放
    public func playbackRate(_ playbackRate: CGFloat) {
        ijkPlayer?.playbackRate = Float(playbackRate)
    }
    
    /// 挂载并激活字幕(本地/网络)
    public func loadThenActiveSubtitle(_ url: URL) -> Bool {
        return ijkPlayer?.loadThenActiveSubtitle(url) ?? false
    }
    
    /// 仅挂载不激活字幕(本地/网络)
    public func loadSubtitleOnly(_ url: URL) -> Bool {
        return ijkPlayer?.loadSubtitleOnly(url) ?? false
    }
    
    /// 批量挂载不激活字幕(本地/网络)
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
    public func scalingStyle(_ scalingStyle: FSScalingMode) {
        ijkPlayer?.scalingMode = scalingStyle
        self.scalingStyle = scalingStyle
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
    public func audioExtraDelay(_ audioExtraDelay: CGFloat) {
        ijkPlayer?.currentAudioExtraDelay = Float(audioExtraDelay)
    }
    
    /// 设定字幕延迟(单位：s)
    public func subtitleExtraDelay(_ subtitleExtraDelay: CGFloat) {
        ijkPlayer?.currentSubtitleExtraDelay = Float(subtitleExtraDelay)
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
    public func subtitlePreference(_ subtitlePreference: FSSubtitlePreference) {
        ijkPlayer?.subtitlePreference = subtitlePreference
    }
    
    /// 旋转画面
    public func rotatePreference(_ rotatePreference: FSRotatePreference) {
        ijkPlayer?.view.rotatePreference = rotatePreference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }
    
    /// 修改画面色彩
    public func colorPreference(_ colorPreference: FSColorConvertPreference) {
        ijkPlayer?.view.colorPreference = colorPreference
        if ijkPlayer?.isPlaying() ?? false {
            ijkPlayer?.view.setNeedsRefreshCurrentPic()
        }
    }
    
    /// 设置画面比例
    public func darPreference(_ darPreference: FSDARPreference) {
        ijkPlayer?.view.darPreference = darPreference
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
        release()
    }
    
    /// 释放播放器组件
    public func release() {
        
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
        
        ijkPlayer?.shutdown()
        ijkPlayer?.view.removeFromSuperview()
        ijkPlayer = nil
    }
    
    /// 当前已重试失败次数
    private var failReplayNumber: Int = 0
    
    /// 创建播放器组件
    private func createPlayer(with playUrl: URL) {
        
        if options == nil {
            options = FSOptions.byDefault()
            options?.setPlayerOptionIntValue(1, forKey: "videotoolbox")
            options?.setPlayerOptionIntValue(Int64(29.97), forKey: "r")
            options?.setPlayerOptionIntValue(512, forKey: "vol")
            options?.setPlayerOptionIntValue(48, forKey: "skip_loop_filter")
            options?.setPlayerOptionIntValue(1024 * 5, forKey: "probesize")
            options?.setPlayerOptionIntValue(1, forKey: "packet-buffering")
            options?.setPlayerOptionIntValue(1, forKey: "reconnect")
            options?.setPlayerOptionIntValue(looping, forKey: "loop")
            options?.setPlayerOptionIntValue(1, forKey: "framedrop")
            options?.setPlayerOptionIntValue(30, forKey: "max-fps")
            options?.setPlayerOptionIntValue(0, forKey: "http-detect-range-support")
            options?.setPlayerOptionIntValue(25, forKey: "min-frames")
            options?.setPlayerOptionIntValue(1, forKey: "start-on-prepared")
            options?.setPlayerOptionIntValue(8, forKey: "skip_frame")
            options?.setFormatOptionIntValue(1, forKey: "dns_cache_clear")
            options?.setPlayerOptionIntValue(6, forKey: "video-pictq-size")
            options?.setPlayerOptionIntValue(0, forKey: "enable-cvpixelbufferpool")
            options?.setPlayerOptionIntValue(1, forKey: "videotoolbox_hwaccel")
            options?.setPlayerOptionIntValue(1, forKey: "enable-accurate-seek")
            options?.setPlayerOptionIntValue(1500, forKey: "accurate-seek-timeout")
            
            options?.setFormatOptionIntValue(1, forKey: "seek_flag_keyframe")
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
                    release()
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
        delegate?.mediaPlayerDidChangeSubtitleStream?(self, player.monitor.mediaMeta)
    }
    
    @objc private func ijkPlayerSubtitleStreamDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.mediaPlayerDidChangeSubtitleStream?(self, player.monitor.mediaMeta)
    }
    
    private func callback(with currentState: WYMediaPlayerState) {
        guard currentState != state else {
            return
        }
        state = currentState
        delegate?.mediaPlayerDidChangeState?(self, state)
    }
    
    deinit {
        release()
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
