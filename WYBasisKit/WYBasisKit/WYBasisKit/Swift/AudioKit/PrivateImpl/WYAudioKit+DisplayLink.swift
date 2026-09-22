//
//  WYAudioKit+DisplayLink.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import QuartzCore

/// WYAudioKit 刷新器管理，CADisplayLink 的创建/停止与每帧分发（录音波形、播放/下载/转换进度都由它驱动）
extension WYAudioKit {
    
    /// 启动 CADisplayLink（用于实时更新 UI）
    func startDisplayLinkIfNeeded() {
        guard state.displayLink == nil else { return }
        // 防kit被丢弃后泄漏:displayLink会强持有target，直接传self的话录音/播放期间kit永远释放不了(deinit永远走不到)，用弱代理隔断持有链，kit释放时deinit里先把displayLink停掉，断开后不会再触发
        let proxy = WYWeakProxy()
        proxy.target = self
        state.displayLink = CADisplayLink(target: proxy, selector: #selector(updateDisplayLink))
        // 音频进度和波形30帧人眼完全够用(60帧纯烧一倍CPU)，柱状波形动画由WYSoundWavesView自己的36帧刷新器负责
        state.displayLink?.preferredFramesPerSecond = 30
        state.displayLink?.add(to: .main, forMode: .common)
    }
    
    /// 停止 CADisplayLink（当没有任何活动任务时）
    func stopDisplayLinkIfNeeded() {
        // 录音暂停期间不需要刷任何东西，按"录音器还在且没处于暂停"判断录音是否活跃(AVAudioRecorder暂停后isRecording的值不可靠，不能只看它)
        let recordingActive = state.audioRecorder != nil && !isRecordingPaused
        if !recordingActive && !isPlaying && state.convertTasks.isEmpty && state.tasksInfo.isEmpty {
            state.displayLink?.invalidate()
            state.displayLink = nil
        }
    }
    
    /// DisplayLink 回调，统一更新录音、播放、下载、转换的进度与波形
    @objc func updateDisplayLink() {
        if isRecording {
            updateRecordingState()
        }
        if isPlaying {
            updatePlaybackProgress()
        }
        updateDownloadProgressIfNeeded()
        updateConversionProgressIfNeeded()
    }
}

/// CADisplayLink 弱引用代理（displayLink 强持有它，它只弱持有真正的目标）
private final class WYWeakProxy: NSObject {
    
    /// 真正接收刷新回调的对象
    weak var target: NSObject?
    
    /// 告诉系统这个代理能不能响应某个方法（目标没了就当作不能响应）
    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
    
    /// 把系统调用的方法转发给真正的目标对象
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
