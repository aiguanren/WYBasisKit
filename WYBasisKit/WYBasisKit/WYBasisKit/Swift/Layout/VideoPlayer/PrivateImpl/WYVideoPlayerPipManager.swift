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

    /// 画中画控制器
    private var pipController: AVPictureInPictureController?

    /// 画中画期间全局持住的播放器(页面销了也不释放)
    private var retainedPlayer: WYVideoPlayer?

    /// 是否可画中画
    var isPictureInPicturePossible: Bool {
        return AVPictureInPictureController.isPictureInPictureSupported() && pipController != nil
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
        guard AVPictureInPictureController.isPictureInPictureSupported(), let controller = AVPictureInPictureController(playerLayer: playerLayer) else { return }
        controller.delegate = self
        pipController = controller
        onStateChange = onChange
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
        guard let pipController = pipController, pipController.isPictureInPicturePossible else {
            onStateChange?(false)
            return
        }
        retainedPlayer = player
        pipController.startPictureInPicture()
    }

    /// 停止画中画(小窗收回，播放器还原到原界面位置)
    func stopPip() {
        pipController?.stopPictureInPicture()
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        onStateChange?(true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // 系统停完画中画画面会自动回到 playerLayer 所在视图，这里只释放持住与回调
        retainedPlayer = nil
        isRestoring = false
        onStateChange?(false)
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
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
