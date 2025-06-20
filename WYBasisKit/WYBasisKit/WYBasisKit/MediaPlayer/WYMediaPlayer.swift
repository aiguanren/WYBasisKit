//
//  WYMediaPlayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher
import IJKMediaPlayer

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
}

@objc public protocol WYMediaPlayerDelegate {
    
    /// 播放器状态回调
    @objc optional func mediaPlayerDidChangeState(_ player: WYMediaPlayer, _ state: WYMediaPlayerState)
}

public class WYMediaPlayer: UIImageView {
    
    /// 播放器组件
    public var ijkPlayer: IJKFFMoviePlayerController?
    
    /// 当前正在播放的流地址
    public private(set) var mediaUrl: String = ""
    
    /// 播放器配置选项 具体配置可参考 https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h
    public var options: IJKFFOptions?
    
    /// 播放器状态回调代理
    public weak var delegate: WYMediaPlayerDelegate?
    
    /// 循环播放的次数，为0表示无限次循环(点播流有效)
    public var looping: Int64 = 0
    
    /// 播放失败后重试次数，默认2次
    public var failReplay: Int = 2
    
    /// 是否需要自动播放
    public var shouldAutoplay: Bool = true
    
    /// 播放画面显示模式
    public var scalingMode: IJKMPMovieScalingMode = .aspectFill
    
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
    public func play(with url: String, background: Any? = nil, placeholder: UIImage? = nil) {
        
        image = nil
        isUserInteractionEnabled = true
        
        if mediaUrl != url {
            failReplayNumber = 0
        }
        
        release()
        createPlayer(with: url)
        ijkPlayer?.prepareToPlay()
        
        mediaUrl = url
        
        if let imageUrl: URL = background as? URL {
            kf.setImage(with: URL(string: (imageUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")), placeholder: placeholder)
        }
        
        if let imageString: String = background as? String {
            kf.setImage(with: URL(string: (imageString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")), placeholder: placeholder)
        }
        
        if let backgroundImage: UIImage = background as? UIImage {
            image = backgroundImage
        }
    }
    
    /// 是否需要静音
    public func muted(_ mute: Bool) {
        ijkPlayer?.playbackVolume = mute ? 0 : 1
    }
    
    /// 继续播放(仅适用于暂停后恢复播放)
    public func play() {
        ijkPlayer?.play()
    }
    
    /// 暂停播放
    public func pause() {
        ijkPlayer?.pause()
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
        
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackDidFinish, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerPlaybackStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerLoadStateDidChange, object: ijkPlayer)
        NotificationCenter.default.removeObserver(self, name: .IJKMPMoviePlayerFirstVideoFrameRendered, object: ijkPlayer)
        
        ijkPlayer?.shutdown()
        ijkPlayer?.view.removeFromSuperview()
        ijkPlayer = nil
    }
    
    /// 当前已重试失败次数
    private var failReplayNumber: Int = 0
    
    /// 创建播放器组件
    private func createPlayer(with url: String) {
        
        if options == nil {
            options = IJKFFOptions.byDefault()
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
        }
        ijkPlayer = IJKFFMoviePlayerController(contentURL: URL(string: url), with: options)
        ijkPlayer?.shouldAutoplay = shouldAutoplay
        ijkPlayer?.scalingMode = scalingMode
        addSubview((ijkPlayer?.view)!)
        ijkPlayer?.view.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        IJKFFMoviePlayerController.setLogLevel(k_IJK_LOG_ERROR)
        
        // 播流完成回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerDidFinished(notification:)), name: .IJKMPMoviePlayerPlaybackDidFinish, object: ijkPlayer)
        
        // 用户操作行为回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerPlayStateDidChange(notification:)), name: .IJKMPMoviePlayerPlaybackStateDidChange, object: ijkPlayer)
        
        // 直播加载状态回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidChange(notification:)), name: .IJKMPMoviePlayerLoadStateDidChange, object: ijkPlayer)
        
        // 渲染回调
        NotificationCenter.default.addObserver(self, selector: #selector(ijkPlayerLoadStateDidRendered(notification:)), name: .IJKMPMoviePlayerFirstVideoFrameRendered, object: ijkPlayer)
    }
    
    @objc private func ijkPlayerDidFinished(notification: Notification) {
        
        if let reason: IJKMPMovieFinishReason = notification.userInfo?[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? IJKMPMovieFinishReason {
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
        callback(with: .rendered)
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
