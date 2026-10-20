//
//  WYVideoPlayerFullscreenManager.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 全屏管理(把播放器视图从原父视图取出铺满窗口，退出放回原位，跟随设备方向旋转，只被播放器内部使用)
final class WYVideoPlayerFullscreenManager: NSObject {

    /// 全屏前的父视图
    private weak var originalSuperview: UIView?

    /// 全屏前的 frame
    private var originalFrame: CGRect = .zero

    /// 播放器原父视图的 transform(宿主可能给父视图转过方向，记录避免退出后错位)
    private var originalTransform: CGAffineTransform = .identity

    /// 是否正处于全屏
    private(set) var isFullscreen = false

    /**
     *  进入全屏
     *
     *  @param player       播放器
     *  @param animated     是否带转场动画
     *
     */
    func enterFullscreen(player: WYVideoPlayer, animated: Bool) {
        guard isFullscreen == false else { return }
        isFullscreen = true
        originalSuperview = player.superview
        originalFrame = player.frame
        originalTransform = player.superview?.transform ?? .identity
        // 点播全屏取横屏方向，设备不支持横屏时退回竖屏铺满
        let interfaceOrientation = UIInterfaceOrientation.landscapeRight
        let window = WYVideoPlayerFullscreenManager.hostWindow()
        let bounds = window?.bounds ?? UIScreen.main.bounds
        player.removeFromSuperview()
        window?.addSubview(player)
        let rotatedSize = CGSize(width: max(bounds.width, bounds.height), height: min(bounds.width, bounds.height))
        setPlayerOrientation(player, interfaceOrientation: interfaceOrientation)
        player.bounds.origin = .zero
        player.frame = CGRect(origin: .zero, size: rotatedSize)
        if animated {
            player.alpha = 0.2
            UIView.animate(withDuration: 0.25) {
                player.alpha = 1
            }
        }
    }

    /**
     *  退出全屏
     *
     *  @param player       播放器
     *  @param animated     是否带转场动画
     *
     */
    func exitFullscreen(player: WYVideoPlayer, animated: Bool) {
        guard isFullscreen else { return }
        isFullscreen = false
        setPlayerOrientation(player, interfaceOrientation: .portrait)
        player.removeFromSuperview()
        let superview = originalSuperview
        if let superview = superview {
            superview.transform = originalTransform
            player.frame = originalFrame
            superview.addSubview(player)
        }
        originalSuperview = nil
    }

    /// 给播放器设置方向(transform 旋转，不依赖工程声明支持的方向)
    private func setPlayerOrientation(_ player: WYVideoPlayer, interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .landscapeLeft:
            player.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        case .landscapeRight:
            player.transform = CGAffineTransform(rotationAngle: .pi / 2)
        default:
            player.transform = .identity
        }
    }

    /// 找承载全屏的窗口
    private static func hostWindow() -> UIWindow? {
        let sceneWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
        let fallbackWindows = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first }
        return sceneWindows.first ?? fallbackWindows.first
    }
}
