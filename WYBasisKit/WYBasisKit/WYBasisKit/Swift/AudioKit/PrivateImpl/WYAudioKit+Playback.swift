//
//  WYAudioKit+Playback.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation

/// WYAudioKit 播放内部实现，播放器状态处理、播放资源统一清理、播放结束检测与播放进度更新
extension WYAudioKit {
    
    /// 处理播放器时间控制状态变化
    func handlePlayerStatusChange(_ status: AVPlayer.TimeControlStatus) {
        // 初始化期间不处理任何回调
        if state.isInitializingPlayer { return }
        
        switch status {
        case .playing:
            startDisplayLinkIfNeeded()
        case .paused:
            if !isPlaybackPaused {
                isPlaybackPaused = true
            }
        default:
            break
        }
    }
    
    /// 内部清理播放器资源
    /// - Parameter shouldCallbackStop: 是否回调 .stop 状态
    func cleanupPlayback(shouldCallbackStop: Bool) {
        guard !state.isStoppingPlayback else { return }
        state.isStoppingPlayback = true
        defer { state.isStoppingPlayback = false }
        
        // 清理观察者(流式播放的观察者也要断，旧版漏了它，流式播完停掉后观察者还挂在旧的playerItem上)
        state.playerItemStatusObservation?.invalidate()
        state.playerItemStatusObservation = nil
        state.streamingObservation?.invalidate()
        state.streamingObservation = nil
        
        if let observer = state.playerTimeObserver {
            state.audioPlayer?.removeTimeObserver(observer)
            state.playerTimeObserver = nil
        }
        
        state.playerObservation?.invalidate()
        state.playerObservation = nil
        
        state.audioPlayer?.pause()
        state.audioPlayer?.replaceCurrentItem(with: nil)
        state.audioPlayer = nil
        state.currentPlaybackURL = nil
        isPlaybackPaused = false
        state.isInitializingPlayer = false
        
        if shouldCallbackStop {
            delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .stop)
        }
        stopDisplayLinkIfNeeded()
    }
    
    /// 添加播放结束监听器（通过周期时间观察者检测播放结束）
    func addPlaybackEndObserver() {
        guard let player = state.audioPlayer else { return }
        state.playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                                                  queue: .main) { [weak self] time in
            guard let self = self,
                  let item = player.currentItem,
                  item.duration.isValid,
                  item.duration.seconds > 0 else { return }
            
            let current = time.seconds
            let total = item.duration.seconds
            
            if current >= total - 0.02 {
                self.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .finish)
                self.cleanupPlayback(shouldCallbackStop: false)
            }
        }
    }
    
    /// 更新播放进度
    func updatePlaybackProgress() {
        guard let player = state.audioPlayer, let item = player.currentItem else { return }
        let currentTime = player.currentTime().seconds
        let duration = item.duration.isValid ? item.duration.seconds : 0
        let progress = duration > 0 ? min(currentTime / duration, 1.0) : 0.0
        
        delegate?.wy_audioPlayerTimeUpdated?(audioKit: self,
                                             localUrl: state.currentPlaybackURL ?? URL(fileURLWithPath: ""),
                                             currentTime: currentTime,
                                             duration: duration,
                                             progress: progress)
    }
}
