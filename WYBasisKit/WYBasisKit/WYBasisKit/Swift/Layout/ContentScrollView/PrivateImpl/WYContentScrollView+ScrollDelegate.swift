//
//  WYContentScrollView+ScrollDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：UIScrollViewDelegate 实现(拖动生命周期/轻扫跨轴判定)与事件转发
extension WYContentScrollView: UIScrollViewDelegate {

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 检查(设置)contentSize与contentOffset
        checkContentSizeAndContentOffset()
        // 如果frame发生变化需要及时更新内容视图的frame
        internalSettingsContentView(isReload: false)
    }

    public override weak var delegate: (any UIScrollViewDelegate)? {
        get {
            return internalDelegate
        }
        set {
            // 防止异常设置（避免死循环）
            guard newValue !== self else { return }
            
            // 如果系统在释放时传入 nil，且没有外部代理，加上super.delegate 目前是 nil，则跳过设置，避免在对象释放过程中再次建立 weak 引用导致闪退
            if newValue == nil && internalDelegate == nil && super.delegate == nil {
                return
            }
            
            internalDelegate = newValue
            // 只有不是 self 时才设置（避免重复）
            if super.delegate !== self {
                super.delegate = self
            }
        }
    }

    /// 点击了内容页面
    @objc func didClickContent() {

        guard let contentDelegate = contentDelegate else { return }

        // 尚未发生任何滑动时点击的是当前展示方向的内容页，用initialDisplayDirection推导展示方向来分发；已滑动过则沿用实际滑动方向
        let clickDirection: WYSlidingDirection = (internalSliderDirection != .unknown) ? internalSliderDirection : initialDisplayDirection

        if (clickDirection == .left) || (clickDirection == .right) {

            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }

            contentDelegate.wy_contentScrollViewDidClick?(self, direction: clickDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
        }else {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }

            contentDelegate.wy_contentScrollViewDidClick?(self, direction: clickDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        // 回调外部
        internalDelegate?.scrollViewWillBeginDragging?(scrollView)

        // 暂停计时器(保留重启标记，松手后自动续播；不能用stopTimer——那会清除标记导致松手后轮播不再恢复)
        pauseTimer()
        // 用户接管：清除程序化动画窗口标记
        isProgrammaticAnimatedScroll = false
        // 重置方向锁定
        isDirectionLocked = false

        // 重置本次拖拽锁定的方向，避免沿用上一次拖拽的方向
        dragLockedDirection = .unknown
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // 回调外部
        internalDelegate?.scrollViewDidScroll?(scrollView)
        
        // 方向锁控制
        let slidingDirection: WYSlidingDirection = handleScrollDirectionLock()
        
        // 判断是否可以滑动
        guard canScroll(slidingDirection) == true else { return }

        if (slidingDirection == .left) || (slidingDirection == .right) {
            if hasInitialCallbackHorizontal == false {
                hasInitialCallbackHorizontal = true
                // 直切/程序化跨轴切换期间不发轴初始补发：两者链路都自带完整will→did，补发会抢在will之前乱序(先did后will再did)；标记照常消费
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }else {
            if hasInitialCallbackVertical == false {
                hasInitialCallbackVertical = true
                // 直切/程序化跨轴切换期间不发轴初始补发：两者链路都自带完整will→did，补发会抢在will之前乱序(先did后will再did)；标记照常消费
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }
        
        if (contentSlidingDirection == .omnidirectional) && (isDirectionLocked == false) && (slidingDirection == internalSliderDirection) {
            // 判轴前的陈旧方向：跳过(否则setter误staging误发willSwitch)
        }else {
            // internalSliderDirection 必须放在canScroll之后设置，否则可能会出现屏幕无法铺满的情况
            internalSliderDirection = slidingDirection
        }
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {

            // 偏移量越过一页宽度时视为已滑过半程，松手可切换
            canSwitchedPage = (abs(contentOffset.x - wy_width) >= wy_width)
            
            if let contentDelegate = contentDelegate,
               horizontalViews?.count == 2,
               let currentHorizontalView = horizontalViews?.first,
               let reserveHorizontalView = horizontalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll?(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
            }
            
        }else {
            
            canSwitchedPage = (abs(contentOffset.y - wy_height) >= wy_height)
            
            if let contentDelegate = contentDelegate,
               verticalViews?.count == 2,
               let currentVerticalView = verticalViews?.first,
               let reserveVerticalView = verticalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll?(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
            }
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // 回调外部
        internalDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        // 仅全向模式处理跨轴轻扫直切
        guard contentSlidingDirection == .omnidirectional else { return }

        // 甩动速度取自pan手势而非委托参数：零行程钳制下contentOffset全程不动，委托回传的velocity恒约为0(实测仅2~3pt/s)，只有手指真实速度才能表达切换意图；符号转换到offset语义(手指上/左滑=offset增=left/up)
        let panVelocity = panGestureRecognizer.velocity(in: self)
        let flickVelocity = CGPoint(x: -panVelocity.x, y: -panVelocity.y)

        // 候选切入方向：仅取速度分量较大的主轴(次轴回退会劫持带斜向分量的同轴翻页手势，表现为同轴滑动被误判成跨轴直切、页面弹跳无法正常切换)；方向符号与handleScrollDirectionLock的delta语义一致(offset增=left/up)
        var candidates: [WYSlidingDirection] = []
        let horizontalVelocity = abs(flickVelocity.x)
        let verticalVelocity = abs(flickVelocity.y)
        func candidate(ofAxisIsHorizontal: Bool) -> WYSlidingDirection? {
            if ofAxisIsHorizontal {
                guard horizontalVelocity > crossAxisFlickVelocityThreshold else { return nil }
                return (flickVelocity.x > 0) ? .left : .right
            }else {
                guard verticalVelocity > crossAxisFlickVelocityThreshold else { return nil }
                return (flickVelocity.y > 0) ? .up : .down
            }
        }
        if let primary = candidate(ofAxisIsHorizontal: horizontalVelocity >= verticalVelocity) {
            candidates.append(primary)
        }
        guard candidates.isEmpty == false else { return }

        // 当前展示轴(方向未知时按置顶View判)：按优先方向判会把垂直展示后的同轴垂直轻扫误判成跨轴直切
        let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)

        // 逐候选判定：跨轴进入(目标轴存在即可，不论数量)、对应方向开关开启、且切入轴速度分量明显占优(1.5倍，斜向轻扫的同轴分量不允许误触发跨轴直切——否则同方向再次轻扫会误切轴导致内容无谓重载)才构成直切；同轴甩动不经此路径，保持原跟手翻页
        for entryDirection in candidates {
            let entryAxisIsHorizontal = (entryDirection == .left) || (entryDirection == .right)
            let entryAxisCount = entryAxisIsHorizontal ? numberOfHorizontalContent : numberOfVerticalContent
            let entryAxisEnabled = entryAxisIsHorizontal ? horizontalSliderEnabled : verticalSliderEnabled
            let entryAxisVelocity = entryAxisIsHorizontal ? horizontalVelocity : verticalVelocity
            let otherAxisVelocity = entryAxisIsHorizontal ? verticalVelocity : horizontalVelocity
            if (entryAxisCount >= 1) && (entryAxisIsHorizontal != displayedAxisIsHorizontal) && entryAxisEnabled && (entryAxisVelocity > otherAxisVelocity * 1.5) {
                // 收回惯性目标到中心页：斜向甩动的同轴分量会带动可拖的展示轴产生松手减速/翻页吸附动画，与直切竞争表现为"切换仍有动画"
                targetContentOffset.pointee = CGPoint(x: wy_width, y: wy_height)
                // 异步发起：待本次拖拽的收尾回调全部走完后再执行直切，避免与拖拽状态互相干扰；呈现样式随crossAxisSwitchStyle
                DispatchQueue.main.async { [weak self] in
                    self?.performCrossAxisSwitch(direction: entryDirection, preservesIndex: true)
                }
                return
            }
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        // 回调外部
        internalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        
        if canRestartedTimer == true {
            startTimer()
        }
        
        // 手指释放，并且没有惯性
        if decelerate == false {
            pauseScroll()
        }
    }

    /// 手指释放且惯性减速结束
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 回调外部
        internalDelegate?.scrollViewDidEndDecelerating?(scrollView)
        pauseScroll()
    }

    /// 代码设置 contentOffset 动画结束
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 回调外部
        internalDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
        pauseScroll()
    }

    /// 告诉系统：我能响应哪些方法
    public override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector)
            || (internalDelegate?.responds(to: aSelector) ?? false)
    }

    /// 将未实现的方法转发给外部 delegate
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if internalDelegate?.responds(to: aSelector) == true {
            return internalDelegate
            
        }
        return super.forwardingTarget(for: aSelector)
    }
}
