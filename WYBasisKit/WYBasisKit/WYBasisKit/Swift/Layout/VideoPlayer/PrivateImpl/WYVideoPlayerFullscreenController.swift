//
//  WYVideoPlayerFullscreenController.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import UIKit

/// 播放器全屏容器，使用系统横屏布局
final class WYVideoPlayerFullscreenController: UIViewController {

    var onLayout: (() -> Void)?

    var supportedOrientations: UIInterfaceOrientationMask = .landscape

    var onRotationCompleted: (() -> Void)?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { supportedOrientations }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if supportedOrientations == .landscape || supportedOrientations == .landscapeRight { return .landscapeRight }
        if supportedOrientations == .landscapeLeft { return .landscapeLeft }
        return .portrait
    }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            let completion = self?.onRotationCompleted
            self?.onRotationCompleted = nil
            completion?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        onLayout?()
    }
}
