//
//  WYMediaPlayer+Notifications.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

#if canImport(IJKPlayerKit)

import IJKPlayerKit

/// WYMediaPlayer 私有实现：状态与通知处理(状态去重后回调业务、底层通知转发成代理回调、URL打开事件中转)
extension WYMediaPlayer {
    /// 状态去重后回调代理(与上次相同的状态不重复通知)
    func callback(with currentState: WYMediaPlayerState) {
        guard currentState != state else {
            return
        }
        // 过滤掉播放器内部自己产生的状态噪声：只静默不通知，不改动state属性(直接读state的业务拿到的还是真实值)
        // ①静音探测起播那一瞬间的playing：探测不是真的在播放
        // ②还没真正播放过时的paused：它只代表初始化或探测收尾或等待播放，和用户主动暂停是同一个状态没法区分，不滤的话业务会误判(预加载时误关loading、真暂停时误转loading)
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

    /// 转发播放进度给代理： currentTime 当前播放位置， duration 总时长， playableDuration 已缓冲可播时长
    @objc func ijkPlayerCurrentPlaybackTimeDidChanged(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerProgressDidChanged?(self, currentTime: player.currentPlaybackTime, duration: player.duration, playableDuration: player.playableDuration)
    }

    @objc func ijkPlayerDidFinished(notification: Notification) {

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

    @objc func ijkPlayerPlayStateDidChange(notification: Notification) {

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

    @objc func ijkPlayerLoadStateDidChange(notification: Notification) {
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

    @objc func ijkPlayerLoadStateDidRendered(notification: Notification) {
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

    @objc func ijkPlayerSubtitleStreamPrepared(notification: Notification) {
        guard let player = ijkPlayer else { return }
        isPreparedToPlay = true
        if isPlayPending {
            isPlayPending = false
            player.play()
        }else if isPausedWhilePreparing {
            // prepare期间业务已暂停：补一次pause压住内核的自动起播(未就绪时的pause拦不住它)，停在就绪暂停态
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

    @objc func ijkPlayerSubtitleStreamDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerSubtitleStreamDidChanged?(self, mediaMeta: player.monitor.mediaMeta)
    }

    /// 普通seek完成：取目标时间与错误码转发
    @objc func ijkPlayerDidSeekComplete(notification: Notification) {
        guard let player = ijkPlayer else { return }
        let target = (notification.userInfo?[IJKPlayerDidSeekCompleteTargetKey] as? NSNumber)?.doubleValue ?? player.currentPlaybackTime
        let error = (notification.userInfo?[IJKPlayerDidSeekCompleteErrorKey] as? NSNumber)?.intValue ?? 0
        delegate?.wy_mediaPlayerDidSeekComplete?(self, target: target, error: error)
    }

    /// 精准seek完成：取完成后的当前位置转发
    @objc func ijkPlayerDidAccurateSeekComplete(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let curPos = (notification.userInfo?[IJKPlayerDidAccurateSeekCompleteCurPos] as? NSNumber)?.doubleValue ?? currentPlaybackTime
        delegate?.wy_mediaPlayerDidAccurateSeekComplete?(self, currentPosition: curPos)
    }

    /// 首帧音频渲染完成
    @objc func ijkPlayerFirstAudioFrameRendered(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstAudioFrameRendered?(self)
    }

    /// 首帧音频解码完成
    @objc func ijkPlayerFirstAudioFrameDecoded(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstAudioFrameDecoded?(self)
    }

    /// 首帧视频解码完成
    @objc func ijkPlayerFirstVideoFrameDecoded(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerFirstVideoFrameDecoded?(self)
    }

    /// seek后首帧视频显示完成
    @objc func ijkPlayerAfterSeekFirstVideoFrameDisplay(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerDidSeekFirstVideoFrameDisplayed?(self)
    }

    /// 视频原始尺寸就绪：转发当前naturalSize
    @objc func ijkPlayerNaturalSizeAvailable(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerNaturalSizeDidChanged?(self, naturalSize: player.naturalSize)
    }

    /// 解码器打开：转发monitor记录的解码器名
    @objc func ijkPlayerVideoDecoderOpen(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerVideoDecoderOpen?(self, decoderName: player.monitor.vdecoder ?? "")
    }

    /// 解码器致命错误：转发错误码并置state为error(收到后建议停止播放)
    @objc func ijkPlayerVideoDecoderFatal(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let errorCode = (notification.userInfo?["code"] as? NSNumber)?.intValue ?? 0
        callback(with: .error)
        delegate?.wy_mediaPlayerVideoDecoderFatal?(self, errorCode: errorCode)
    }

    /// 未找到可用解码器：置state为error并转发
    @objc func ijkPlayerNoCodecFound(notification: Notification) {
        guard ijkPlayer != nil else { return }
        callback(with: .error)
        delegate?.wy_mediaPlayerNoCodecFound?(self)
    }

    /// 播放器内部警告
    @objc func ijkPlayerRecvWarning(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let reason = (notification.userInfo?[IJKPlayerWarningReasonUserInfoKey] as? NSNumber)?.intValue ?? 0
        delegate?.wy_mediaPlayerRecvWarning?(self, reason: reason)
    }

    /// ICY电台元数据变化：原样转发userInfo字典
    @objc func ijkPlayerICYMetaChanged(notification: Notification) {
        guard ijkPlayer != nil else { return }
        delegate?.wy_mediaPlayerICYMetaDidChanged?(self, meta: notification.userInfo ?? [:])
    }

    /// 选流失败：取流下标与错误码转发
    @objc func ijkPlayerSelectingStreamDidFailed(notification: Notification) {
        guard ijkPlayer != nil else { return }
        let streamID = (notification.userInfo?[IJKPlayerSelectingStreamIDUserInfoKey] as? NSNumber)?.int32Value ?? 0
        let errorCode = (notification.userInfo?[IJKPlayerSelectingStreamErrUserInfoKey] as? NSNumber)?.int32Value ?? 0
        delegate?.wy_mediaPlayerSelectingStreamDidFailed?(self, streamID: streamID, errorCode: errorCode)
    }

    /// 缓冲进度变化：转发当前缓冲百分比
    @objc func ijkPlayerBufferingDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerBufferingDidChanged?(self, bufferingProgress: Int(player.bufferingProgress))
    }

    /// AirPlay(无线)投放状态变化
    @objc func ijkPlayerAirPlayActiveDidChange(notification: Notification) {
        guard let player = ijkPlayer else { return }
        delegate?.wy_mediaPlayerAirPlayActiveDidChanged?(self, active: player.airPlayMediaActive)
    }

    /// URL打开事件的统一转发代理：IJKPlayerKit的四个*OpenDelegate属性是强引用，直接挂self会循环引用(self持有player、player又强持有delegate)，所以经这个weak中转对象间接持有
    class WYMediaUrlOpenProxy: NSObject, IJKMediaUrlOpenDelegate {

        /// 弱引用业务播放器，避免player→proxy→player循环
        weak var target: WYMediaPlayer?

        /// IJKPlayerKit要求实现：按event的原始值分发(0x20001=TCP/0x20003=HTTP/0x20005=直播/0x20007=HLS分片；这些值定义在IJKMediaPlayback.h的IJKMediaCtrl_*常量里、是内核对外约定好的不会变，枚举名导入Swift后有歧义所以直接比数字)
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

    /// 按需挂载/摘除四个URL打开代理：四个闭包有一个非空才挂proxy(避免没必要的回调链路)，全空时置nil
    func refreshUrlOpenDelegates() {
        let needsProxy = willOpenSegmentUrl != nil || willOpenTcpUrl != nil || willOpenHttpUrl != nil || willOpenLiveUrl != nil
        ijkPlayer?.segmentOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.tcpOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.httpOpenDelegate = needsProxy ? urlOpenProxy : nil
        ijkPlayer?.liveOpenDelegate = needsProxy ? urlOpenProxy : nil
    }

}

#endif
