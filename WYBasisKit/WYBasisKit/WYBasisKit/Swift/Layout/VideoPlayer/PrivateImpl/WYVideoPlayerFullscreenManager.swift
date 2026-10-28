//
//  WYVideoPlayerFullscreenManager.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

final class WYVideoPlayerFullscreenManager: NSObject {

    private(set) var isFullscreen = false

    private weak var originalSuperview: UIView?
    private var originalFrame: CGRect = .zero
    private var originalIndex = 0
    private var originalTranslatesAutoresizingMask = true
    private var originalAutoresizingMask: UIView.AutoresizingMask = []
    private var originalOrientation: UIInterfaceOrientationMask = .portrait
    private var originalInterfaceOrientation: UIInterfaceOrientation = .portrait
    private var savedConstraints: [NSLayoutConstraint] = []
    private var isTransitioning = false
    private var exitRequested = false
    private var transitionTimeoutTask: DispatchWorkItem?
    private var transitionCover: UIView?
    private var fullscreenController: WYVideoPlayerFullscreenController?

    func enterFullscreen(player: WYVideoPlayer, animated: Bool) {
        guard !isFullscreen, !isTransitioning, let parent = player.superview,
              let window = player.window, var presenter = window.rootViewController else { return }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        guard !presenter.isBeingDismissed, !presenter.isBeingPresented else { return }
        originalSuperview = parent
        originalFrame = player.frame
        originalIndex = parent.subviews.firstIndex(of: player) ?? 0
        originalTranslatesAutoresizingMask = player.translatesAutoresizingMaskIntoConstraints
        originalAutoresizingMask = player.autoresizingMask
        originalOrientation = UIDevice.wy_setInterfaceOrientation
        originalInterfaceOrientation = window.windowScene?.interfaceOrientation ?? .portrait
        var ancestor: UIView? = parent
        while let view = ancestor {
            savedConstraints += view.constraints.filter {
                ($0.firstItem as? UIView) === player || ($0.secondItem as? UIView) === player
            }
            ancestor = view.superview
        }
        savedConstraints += player.constraints.filter {
            ($0.firstItem as? UIView) === player &&
            ($0.secondItem == nil || ($0.secondItem as? UIView) === player)
        }
        transitionCover = player.snapshotView(afterScreenUpdates: false) ?? UIView(frame: player.frame)
        if let cover = transitionCover {
            cover.frame = player.frame
            cover.autoresizingMask = originalAutoresizingMask
            parent.insertSubview(cover, aboveSubview: player)
        }
        isTransitioning = true
        NSLayoutConstraint.deactivate(savedConstraints)
        let controller = WYVideoPlayerFullscreenController()
        controller.supportedOrientations = UIInterfaceOrientationMask(rawValue: 1 << originalInterfaceOrientation.rawValue)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = player.configuration.fullscreenTransitionStyle
        controller.loadViewIfNeeded()
        player.removeFromSuperview()
        player.setContentRotation(0, contentSize: controller.view.bounds.size)
        player.transform = .identity
        player.translatesAutoresizingMaskIntoConstraints = true
        player.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.addSubview(player)
        player.frame = controller.view.bounds
        controller.onLayout = { [weak player, weak controller] in
            guard let player = player, let controller = controller else { return }
            UIView.performWithoutAnimation {
                player.frame = controller.view.bounds
                player.setNeedsLayout()
                player.layoutIfNeeded()
            }
        }
        fullscreenController = controller
        isFullscreen = true
        presenter.present(controller, animated: animated && originalInterfaceOrientation.isLandscape) { [self, player, controller] in
            controller.supportedOrientations = .landscape
            let finish = { [weak self, weak player, weak controller] in
                guard let self = self, let player = player, let controller = controller,
                      self.fullscreenController === controller, self.isFullscreen else { return }
                controller.onRotationCompleted = nil
                self.cancelTransitionTimeout()
                self.isTransitioning = false
                if self.exitRequested {
                    self.exitRequested = false
                    player.exitFullscreen()
                }
            }
            controller.onRotationCompleted = finish
            scheduleTransitionTimeout(player: player, controller: controller, completion: finish)
            let target: UIInterfaceOrientationMask = originalInterfaceOrientation == .landscapeLeft ? .landscapeLeft : .landscapeRight
            UIDevice.wy_setInterfaceOrientation = target
            if controller.view.bounds.width > controller.view.bounds.height {
                finish()
            }
        }
    }

    func exitFullscreen(player: WYVideoPlayer, animated: Bool) {
        guard isFullscreen, let controller = fullscreenController else { return }
        if isTransitioning {
            exitRequested = true
            return
        }
        exitRequested = false
        isTransitioning = true
        isFullscreen = false
        let target = UIInterfaceOrientationMask(rawValue: 1 << originalInterfaceOrientation.rawValue)
        let needsRotation = controller.view.window?.windowScene?.interfaceOrientation != originalInterfaceOrientation
        var restoreStarted = false
        let restore = { [self] in
            guard !restoreStarted else { return }
            restoreStarted = true
            cancelTransitionTimeout()
            controller.onRotationCompleted = nil
            controller.dismiss(animated: animated && !needsRotation) {
                controller.onLayout = nil
                UIView.performWithoutAnimation {
                    player.removeFromSuperview()
                    player.transform = .identity
                    player.translatesAutoresizingMaskIntoConstraints = self.originalTranslatesAutoresizingMask
                    player.autoresizingMask = self.originalAutoresizingMask
                    if let parent = self.originalSuperview {
                        parent.insertSubview(player, at: min(self.originalIndex, parent.subviews.count))
                        if let cover = self.transitionCover, cover.superview === parent {
                            player.frame = cover.frame
                        } else {
                            player.frame = self.originalFrame
                        }
                        NSLayoutConstraint.activate(self.savedConstraints)
                        parent.layoutIfNeeded()
                    }
                    self.transitionCover?.removeFromSuperview()
                    self.transitionCover = nil
                    self.savedConstraints.removeAll()
                    self.originalSuperview = nil
                    self.fullscreenController = nil
                    if UIDevice.wy_setInterfaceOrientation != self.originalOrientation {
                        UIDevice.wy_setInterfaceOrientation = self.originalOrientation
                    }
                }
                self.isTransitioning = false
            }
        }
        controller.supportedOrientations = target
        controller.onRotationCompleted = restore
        scheduleTransitionTimeout(player: player, controller: controller, completion: restore)
        UIDevice.wy_setInterfaceOrientation = target
        let orientation = controller.view.window?.windowScene?.interfaceOrientation
        let alreadyRestored = orientation.map { target.contains(UIInterfaceOrientationMask(rawValue: 1 << $0.rawValue)) } ?? true
        if alreadyRestored {
            controller.onRotationCompleted = nil
            restore()
        }
    }

    private func scheduleTransitionTimeout(player: WYVideoPlayer, controller: WYVideoPlayerFullscreenController, completion: @escaping () -> Void) {
        cancelTransitionTimeout()
        let interval = player.configuration.fullscreenTransitionTimeout
        let task = DispatchWorkItem { [weak self, weak controller] in
            guard let self = self, let controller = controller,
                  self.fullscreenController === controller, self.isTransitioning else { return }
            completion()
        }
        transitionTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + (interval.isFinite ? max(0, interval) : 0), execute: task)
    }

    private func cancelTransitionTimeout() {
        transitionTimeoutTask?.cancel()
        transitionTimeoutTask = nil
    }
}
