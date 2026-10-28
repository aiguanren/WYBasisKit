//
//  WYVideoPlayerQualitySwitcher.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// 清晰度切换器(判档与无缝换档编排，只被播放器内部使用)
final class WYVideoPlayerQualitySwitcher: NSObject {

    /**
     *  判断切档是否需要按本档地址重载
     *
     *  @param asset    播放素材
     *  @param index    目标档下标
     *
     *  @return true 表示需要重载(下标合法且目标档不是 HLS master)，目标档是 HLS master 时交给系统自适应不重载
     *
     */
    func needsReload(asset: WYVideoPlayerMediaAsset, to index: Int) -> Bool {
        guard asset.qualities.indices.contains(index), index != asset.selectedIndex else { return false }
        return asset.qualities[index].isHLSMaster == false
    }

    /// 换档过渡中的新播放器
    private var pendingPlayer: AVPlayer?

    /// 换档过渡中新流挂在画面层底下的临时视频层
    private var pendingLayer: AVPlayerLayer?

    /// 换档过渡条目状态监听
    private var pendingStatusObservation: NSKeyValueObservation?

    /// 换档过渡出帧观察(新流开始出帧时收尾换主)
    private var pendingTickObserver: Any?

    /// 换档过渡完成后交回播放器收尾(参数为新播放器)
    private var pendingCompletion: ((AVPlayer) -> Void)?

    /// 备流失败回调
    private var pendingFailure: ((Error) -> Void)?

    /// 备流超时取消任务
    private var timeoutWorkItem: DispatchWorkItem?

    /// 原播放器，定位时对齐仍在推进的进度
    private weak var sourcePlayer: AVPlayer?

    /// 提交前新流在前方至少要缓冲的秒数
    private var pendingPreroll: TimeInterval = 3

    /// 备流播放倍速
    private var pendingRate: Float = 1

    /**
     *  无缝换档过渡
     *
     *  旧播放器保持播放不打断；新清晰度另起一个 AVPlayer 静音备流，条目就绪并定位到续播点后挂临时视频层在画面层底下开播，新流真正出帧后再由回调交回播放器换主重绑，全程两路都是活视频不出现黑帧
     *
     *  @param currentPlayer   当前正在播的旧播放器
     *  @param item            新档条目
     *  @param resumeTime      续播位置，单位为秒
     *  @param rate            原倍速
     *  @param preroll         提交前新流在前方至少要缓冲的秒数
     *  @param hostLayer       播放器画面层(临时视频层挂在它底下)
     *  @param timeout         备流最长等待秒数
     *  @param failure         备流失败回调(主线程，旧流继续播放)
     *  @param completion      新流出帧且缓冲达标后的收尾回调(主线程)
     *
     */
    func startTransition(from currentPlayer: AVPlayer, item: AVPlayerItem, resumeTime: TimeInterval, rate: Float, preroll: TimeInterval, hostLayer: AVPlayerLayer, timeout: TimeInterval, failure: @escaping (Error) -> Void, completion: @escaping (AVPlayer) -> Void) {
        cancelPending()
        pendingPreroll = max(preroll, 0)
        pendingRate = rate
        sourcePlayer = currentPlayer
        pendingFailure = failure
        let timeoutTask = DispatchWorkItem { [weak self] in
            self?.failTransition(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))
        }
        timeoutWorkItem = timeoutTask
        DispatchQueue.main.asyncAfter(deadline: .now() + max(1, timeout), execute: timeoutTask)
        let newPlayer = AVPlayer(playerItem: item)
        if #available(iOS 16.0, *) { newPlayer.defaultRate = rate }
        newPlayer.isMuted = true
        pendingPlayer = newPlayer
        pendingCompletion = completion
        pendingStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] (item, _) in
            DispatchQueue.main.async {
                guard let self = self, self.pendingPlayer === newPlayer else { return }
                if item.status == .failed {
                    self.failTransition(item.error ?? NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotLoadFromNetwork))
                } else if item.status == .readyToPlay {
                    self.prepareNewStream(player: newPlayer, resumeTime: resumeTime, hostLayer: hostLayer)
                }
            }
        }
    }

    /// 取消进行中的换档过渡(旧播放器不受影响继续播)
    func cancelPending() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        pendingFailure = nil
        sourcePlayer = nil
        pendingStatusObservation?.invalidate()
        pendingStatusObservation = nil
        if let observer = pendingTickObserver {
            pendingPlayer?.removeTimeObserver(observer)
            pendingTickObserver = nil
        }
        pendingLayer?.removeFromSuperlayer()
        pendingLayer = nil
        pendingPlayer?.pause()
        pendingPlayer?.replaceCurrentItem(with: nil)
        pendingPlayer = nil
        pendingCompletion = nil
    }

    /// 条目就绪后定位到续播点并挂临时层开播等出帧
    private func prepareNewStream(player: AVPlayer, resumeTime: TimeInterval, hostLayer: AVPlayerLayer) {
        guard pendingPlayer === player, pendingStatusObservation != nil, player.currentItem?.status == .readyToPlay else { return }
        pendingStatusObservation?.invalidate()
        pendingStatusObservation = nil
        let currentTime = sourcePlayer?.currentTime().seconds ?? resumeTime
        let targetTime = currentTime.isFinite ? max(0, currentTime) : max(0, resumeTime)
        player.seek(to: CMTime(seconds: targetTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] (_) in
            DispatchQueue.main.async {
                self?.attachPendingLayer(player: player, hostLayer: hostLayer)
            }
        }
    }

    /// 挂临时视频层开播，等新流出帧后交回收尾
    private func attachPendingLayer(player: AVPlayer, hostLayer: AVPlayerLayer) {
        guard pendingPlayer === player else { return }
        let pendingLayer = AVPlayerLayer(player: player)
        pendingLayer.videoGravity = hostLayer.videoGravity
        pendingLayer.frame = hostLayer.bounds
        hostLayer.insertSublayer(pendingLayer, at: 0)
        self.pendingLayer = pendingLayer
        player.rate = pendingRate
        pendingTickObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 5), queue: .main) { [weak self] (_) in
            guard let self = self, self.pendingPlayer === player, self.pendingLayer?.isReadyForDisplay == true else { return }
            // 出帧之外还要求前方缓冲达标才提交，避免换主后新流缓冲太薄起步顿挫
            let remaining = max(0, (player.currentItem?.duration.seconds ?? 0) - player.currentTime().seconds)
            guard self.bufferAhead(of: player) + 0.1 >= min(self.pendingPreroll, remaining) else { return }
            if self.sourcePlayer?.rate == 0 {
                if let observer = self.pendingTickObserver {
                    player.removeTimeObserver(observer)
                    self.pendingTickObserver = nil
                }
                player.pause()
                let target = self.sourcePlayer?.currentTime() ?? player.currentTime()
                player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                    DispatchQueue.main.async {
                        guard let self = self, self.pendingPlayer === player else { return }
                        if finished { self.finishTransition() }
                        else { self.failTransition(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)) }
                    }
                }
            } else {
                self.finishTransition()
            }
        }
    }

    /// 备流失败后保留旧流并通知调用方
    private func failTransition(_ error: Error) {
        let failure = pendingFailure
        cancelPending()
        failure?(error)
    }

    /// 新流当前播放位置前方的已缓冲秒数
    private func bufferAhead(of player: AVPlayer) -> TimeInterval {
        let current = player.currentTime().seconds
        var maxEnd = current
        for value in player.currentItem?.loadedTimeRanges ?? [] {
            let range = value.timeRangeValue
            let start = CMTimeGetSeconds(range.start)
            let end = CMTimeGetSeconds(range.end)
            if start <= current + 0.5, end > maxEnd {
                maxEnd = end
            }
        }
        return max(0, maxEnd - current)
    }

    /// 新流已出帧且缓冲达标，清过渡态并把新播放器交回播放器
    private func finishTransition() {
        guard let newPlayer = pendingPlayer, let completion = pendingCompletion else { return }
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        pendingFailure = nil
        sourcePlayer = nil
        if let observer = pendingTickObserver {
            newPlayer.removeTimeObserver(observer)
            pendingTickObserver = nil
        }
        pendingLayer?.removeFromSuperlayer()
        pendingLayer = nil
        pendingPlayer = nil
        pendingCompletion = nil
        pendingStatusObservation?.invalidate()
        pendingStatusObservation = nil
        completion(newPlayer)
    }
}
