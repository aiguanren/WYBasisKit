//
//  WYVideoPlayerPipManager.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVKit
import Foundation
import UIKit

/// 画中画管理(进小窗前持住播放器防止页面销毁把播放器带走，还原时把播放器放回原位，只被播放器内部使用)
final class WYVideoPlayerPipManager: NSObject, AVPictureInPictureControllerDelegate {

    /// 是否允许创建和启动画中画
    private var isEnabled = true

    /// 画中画控制器
    private var pipController: AVPictureInPictureController?

    /// 画中画期间全局持住的播放器(页面销了也不释放)
    private var retainedPlayer: WYVideoPlayer?

    /// 等待系统允许画中画的请求
    private var pendingStart: DispatchWorkItem?

    /// 系统画中画可用状态监听
    private var possibleObservation: NSKeyValueObservation?

    /// 正在启动或已进入画中画
    var isStartingOrActive: Bool { retainedPlayer != nil || isPictureInPictureActive }

    /// 是否可画中画
    var isPictureInPicturePossible: Bool {
        return pipController?.isPictureInPicturePossible == true
    }

    /// 是否正处于画中画播放
    var isPictureInPictureActive: Bool {
        return pipController?.isPictureInPictureActive == true
    }

    /**
     *  装配画中画(画面层就绪后调)
     *
     *  @param playerLayer     播放器的画面层
     *  @param onChange        画中画状态变化回调，参数为是否处于画中画播放
     *
     */
    func setup(playerLayer: AVPlayerLayer, onChange: @escaping (Bool) -> Void) {
        isEnabled = true
        onStateChange = onChange
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        guard let controller = pipController ?? AVPictureInPictureController(playerLayer: playerLayer) else { return }
        controller.delegate = self
        pipController = controller
        onStateChange = onChange
        possibleObservation = controller.observe(\.isPictureInPicturePossible, options: [.new]) { [weak self] controller, _ in
            DispatchQueue.main.async {
                guard let self = self, self.isEnabled, self.pipController === controller, self.pendingStart != nil, controller.isPictureInPicturePossible else { return }
                self.pendingStart?.cancel()
                self.pendingStart = nil
                controller.startPictureInPicture()
            }
        }
    }

    /// 状态变化回调
    private var onStateChange: ((Bool) -> Void)?

    /// 是否正在还原回原界面
    private var isRestoring = false

    /**
     *  开始画中画(不可用时回调 false)
     *
     *  @param player       播放器(期间被全局持住)
     *
     */
    func startPip(player: WYVideoPlayer) {
        guard isEnabled, !isStartingOrActive else { return }
        guard let pipController = pipController else {
            onStateChange?(false)
            player.delegate?.wy_videoPlayer?(player, didFailWithError: NSError(domain: AVKitErrorDomain, code: AVKitError.Code.pictureInPictureStartFailed.rawValue))
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            player.delegate?.wy_videoPlayer?(player, didFailWithError: error)
            return
        }
        retainedPlayer = player
        if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        } else {
            let request = DispatchWorkItem { [weak self, weak player] in
                guard let self = self else { return }
                self.pendingStart = nil
                self.retainedPlayer = nil
                self.onStateChange?(false)
                if let player = player {
                    player.delegate?.wy_videoPlayer?(player, didFailWithError: NSError(domain: AVKitErrorDomain, code: AVKitError.Code.pictureInPictureStartFailed.rawValue))
                }
            }
            pendingStart = request
            DispatchQueue.main.asyncAfter(deadline: .now() + max(1, player.configuration.pictureInPictureStartTimeout), execute: request)
        }
    }

    /// 禁用画中画并取消等待中的启动
    func disable() {
        isEnabled = false
        stopPip()
        possibleObservation?.invalidate()
        possibleObservation = nil
        if !isPictureInPictureActive {
            pipController?.delegate = nil
            pipController = nil
        }
    }

    /// 停止画中画(小窗收回，播放器还原到原界面位置)
    func stopPip() {
        pendingStart?.cancel()
        pendingStart = nil
        if !isPictureInPictureActive { retainedPlayer = nil }
        pipController?.stopPictureInPicture()
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pendingStart?.cancel()
        pendingStart = nil
        onStateChange?(true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        finishPip()
    }

    /// 完成画中画停止后的状态恢复
    func finishPip() {
        pendingStart?.cancel()
        pendingStart = nil
        retainedPlayer = nil
        isRestoring = false
        if !isEnabled {
            pipController?.delegate = nil
            pipController = nil
        }
        onStateChange?(false)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        pendingStart?.cancel()
        pendingStart = nil
        if let player = retainedPlayer {
            player.delegate?.wy_videoPlayer?(player, didFailWithError: error)
        }
        retainedPlayer = nil
        onStateChange?(false)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // 用户点小窗还原按钮，宿主页面可能已销毁，把持住的播放器窗口化展示等宿主接管
        if let player = retainedPlayer {
            isRestoring = true
            if player.superview == nil {
                let window = WYVideoPlayerFullscreenManager.hostWindowForPip()
                window?.addSubview(player)
                player.frame = window?.bounds ?? .zero
            }
        }
        completionHandler(true)
    }
}

extension WYVideoPlayerFullscreenManager {

    /// 画中画还原找窗口(与全屏共用逻辑)
    static func hostWindowForPip() -> UIWindow? {
        let sceneWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
        let fallbackWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first }
        return sceneWindows.first ?? fallbackWindows.first
    }
}
