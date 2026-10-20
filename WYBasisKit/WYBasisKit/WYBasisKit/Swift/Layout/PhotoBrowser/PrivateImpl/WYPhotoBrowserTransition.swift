//
//  WYPhotoBrowserTransition.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

import UIKit

/// 浏览器进出页转场动画器(缩放样式从来源视图位置放大进入与缩回退出，取不到来源时降级渐隐)
class WYPhotoBrowserTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    /// 所属浏览器(取当前页内容与来源位置)
    weak var browser: WYPhotoBrowser?

    /// true为进入动画，false为退出动画(transitioningDelegate回调时设置)
    var isPresenting: Bool = true

    /**
     * 动画器初始化
     * - Parameters:
     *   - browser: 所属浏览器
     */
    init(browser: WYPhotoBrowser) {
        self.browser = browser
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.32
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if isPresenting {
            animatePresenting(using: transitionContext, containerView: containerView)
        } else {
            animateDismissing(using: transitionContext, containerView: containerView)
        }
    }

    /// 进入动画(来源视图快照放大到适配位置，背景渐显)
    func animatePresenting(using transitionContext: UIViewControllerContextTransitioning, containerView: UIView) {
        guard let browser = browser, let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(true)
            return
        }
        containerView.addSubview(toView)
        toView.frame = containerView.bounds
        toView.layoutIfNeeded()

        let duration = transitionDuration(using: transitionContext)
        let cell = browser.currentCell
        let contentFrame = cell?.mainContentFrame(in: toView)
        let sourceFrame = browser.sourceFrameForItem(at: browser.internalCurrentIndex)

        guard browser.configuration.transitionStyle == .zoom, let contentFrame = contentFrame, let sourceFrame = sourceFrame, let sourceSnapshot = makeSnapshot(fromFrame: sourceFrame) else {
            toView.alpha = 0
            UIView.animate(withDuration: duration) {
                toView.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(true)
            }
            return
        }

        browser.isTransitioningContent = true
        browser.setCurrentContentHidden(true)
        browser.setChromeHidden(true)
        browser.backgroundView.alpha = 0

        containerView.addSubview(sourceSnapshot)
        sourceSnapshot.frame = sourceFrame
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
            sourceSnapshot.frame = contentFrame
            browser.backgroundView.alpha = 1
        } completion: { _ in
            sourceSnapshot.removeFromSuperview()
            browser.setCurrentContentHidden(false)
            browser.setChromeHidden(false)
            browser.isTransitioningContent = false
            transitionContext.completeTransition(true)
        }
    }

    /// 退出动画(当前内容快照缩回来源位置，无来源时居中缩小渐隐，背景渐隐)
    func animateDismissing(using transitionContext: UIViewControllerContextTransitioning, containerView: UIView) {
        guard let browser = browser, let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(true)
            return
        }
        if fromView.superview !== containerView {
            containerView.addSubview(fromView)
        }

        let duration = transitionDuration(using: transitionContext)
        let contentSnapshot = browser.currentCell?.takeMainContentSnapshot()
        let startFrame = browser.currentCell?.mainContentFrame(in: containerView)
        let sourceFrame = browser.sourceFrameForItem(at: browser.internalCurrentIndex)

        guard browser.configuration.transitionStyle == .zoom, let contentSnapshot = contentSnapshot, let startFrame = startFrame else {
            UIView.animate(withDuration: duration) {
                fromView.alpha = 0
            } completion: { _ in
                transitionContext.completeTransition(true)
            }
            return
        }

        browser.setCurrentContentHidden(true)
        browser.setChromeHidden(true)
        containerView.addSubview(contentSnapshot)
        contentSnapshot.frame = startFrame

        let endFrame: CGRect
        if let sourceFrame = sourceFrame {
            endFrame = sourceFrame
        } else {
            let shrinkScale: CGFloat = 0.6
            let shrunkWidth = startFrame.width * shrinkScale
            let shrunkHeight = startFrame.height * shrinkScale
            endFrame = CGRect(x: containerView.bounds.midX - shrunkWidth / 2, y: containerView.bounds.midY - shrunkHeight / 2, width: shrunkWidth, height: shrunkHeight)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn]) {
            contentSnapshot.frame = endFrame
            contentSnapshot.alpha = sourceFrame == nil ? 0 : 1
            browser.backgroundView.alpha = 0
        } completion: { _ in
            contentSnapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    /**
     * 按屏幕位置取来源视图快照(整窗普通快照裁剪出目标区域，动画时整图随容器形变，不出现局部拉伸条纹)
     * - Parameters:
     *   - frame: 来源的屏幕位置
     * - return: 快照容器(取不到时返回nil，转场降级渐隐)
     */
    func makeSnapshot(fromFrame frame: CGRect) -> UIView? {
        guard let window = browser?.view.window else { return nil }
        guard frame.width > 1, frame.height > 1 else { return nil }
        guard let fullSnapshot = window.snapshotView(afterScreenUpdates: false) else { return nil }
        let container = UIView(frame: frame)
        container.clipsToBounds = true
        container.addSubview(fullSnapshot)
        fullSnapshot.frame = CGRect(x: -frame.minX, y: -frame.minY, width: window.bounds.width, height: window.bounds.height)
        fullSnapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return container
    }
}
