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
        // 防御：上一轮交互式跨轴拖动若因异常未收尾，无动画立即复位(正常流程松手会走完成/回弹)
        if isInteractiveCrossAxisDrag {
            isInteractiveCrossAxisDrag = false
            isFinalizingSwitch = false
            interactiveCrossDirection = .unknown
            // 全量恢复四页呈现属性：slide松手后由系统减速接管，用户中途按停不会走减速结束回调，staging隐藏过的陈旧当前页若不恢复会残留alpha=0(后续翻到该页表现为隐形、透视出另一轴内容)
            [horizontalViews?.first, horizontalViews?.last, verticalViews?.first, verticalViews?.last].forEach { (view) in
                view?.alpha = 1
                view?.transform = .identity
            }
        }
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

        // 交互式跨轴拖动(fade/zoom)：每帧按拖动距离驱动渐变/缩放进度(slide由偏移自然跟手无需驱动)
        updateInteractiveCrossAxisProgress()

        if (slidingDirection == .left) || (slidingDirection == .right) {
            // 轴初始补发只在触摸方向为当前展示轴时进行(含标记消费)：跨轴方向的触摸此刻目标轴并未真正展示(要等提交才翻转)，补发的did会让业务立刻起播目标轴内容——拖动取消时展示轴仍是原轴，表现为"画面停在原轴、声音来自另一轴"的隐形出声；跨轴进入的提交链路自带完整will→did，无需补发。判据必须含isInteractiveCrossAxisDrag==false：交互式跨轴拖动的staging会把目标轴提前置顶，按置顶View判展示轴会被骗过(补发在拖动首帧就触发，表现为切轴动画还没滑到位另一轴的声音已起播)
            if (hasInitialCallbackHorizontal == false) && (isInteractiveCrossAxisDrag == false) && (axisIsHorizontal(of: .unknown) == true) {
                hasInitialCallbackHorizontal = true
                // 直切/程序化跨轴切换期间不发轴初始补发：两者链路都自带完整will→did，补发会抢在will之前乱序(先did后will再did)；标记照常消费
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }else {
            // 轴初始补发只在触摸方向为当前展示轴时进行(含标记消费)：跨轴方向的触摸此刻目标轴并未真正展示(要等提交才翻转)，补发的did会让业务立刻起播目标轴内容——拖动取消时展示轴仍是原轴，表现为"画面停在原轴、声音来自另一轴"的隐形出声；跨轴进入的提交链路自带完整will→did，无需补发。判据必须含isInteractiveCrossAxisDrag==false：交互式跨轴拖动的staging会把目标轴提前置顶，按置顶View判展示轴会被骗过(补发在拖动首帧就触发，表现为切轴动画还没滑到位另一轴的声音已起播)
            if (hasInitialCallbackVertical == false) && (isInteractiveCrossAxisDrag == false) && (axisIsHorizontal(of: .unknown) == false) {
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

        // 交互式跨轴拖动收尾：按进度(≥半页)或速度(达轻扫阈值)决定完成或回弹
        if isInteractiveCrossAxisDrag {
            if crossAxisSwitchStyle == .slide {
                // slide改写惯性目标后交给系统动能减速：与同轴翻页松手完全同源的减速曲线，自绘固定时长补间复刻不了动能手感(表现为收尾动画僵硬突兀)；此处不经crossAxisSwitchDuration(它管程序化切换/轻扫直切/fade与zoom松手补间这些组件驱动的动画)，落地后的收尾见endInteractiveSlideDragIfNeeded
                targetContentOffset.pointee = isInteractiveCrossCommitReady ? interactiveCrossTargetOffset : CGPoint(x: wy_width, y: wy_height)
            }else {
                // 呈现族(fade/zoom)收回惯性目标，由组件自己的补间动画接管
                targetContentOffset.pointee = CGPoint(x: wy_width, y: wy_height)
                if isInteractiveCrossCommitReady {
                    finishInteractiveCrossAxisDrag()
                }else {
                    cancelInteractiveCrossAxisDrag()
                }
            }
            return
        }

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

        // 逐候选判定：跨轴进入(目标轴存在即可，不论数量)且切入轴速度分量明显占优(1.5倍，斜向轻扫的同轴分量不允许误触发跨轴直切——否则同方向再次轻扫会误切轴导致内容无谓重载)才构成直切；目标轴的滑动开关不拦跨轴进入——开关管的是"轴内翻页交互"，不限制"能到达"该轴(进入后该轴零行程不可翻)；同轴甩动不经此路径，保持原跟手翻页
        for entryDirection in candidates {
            let entryAxisIsHorizontal = (entryDirection == .left) || (entryDirection == .right)
            let entryAxisCount = entryAxisIsHorizontal ? numberOfHorizontalContent : numberOfVerticalContent
            let entryAxisVelocity = entryAxisIsHorizontal ? horizontalVelocity : verticalVelocity
            let otherAxisVelocity = entryAxisIsHorizontal ? verticalVelocity : horizontalVelocity
            if (entryAxisCount >= 1) && (entryAxisIsHorizontal != displayedAxisIsHorizontal) && (entryAxisVelocity > otherAxisVelocity * 1.5) {
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
        
        // 手指释放，并且没有惯性：静止释放时系统分页不发起减速，偏移可能停在两页之间，必须按分页语义落位后收尾(直接pauseScroll会把偏移瞬时硬跳回中心，表现为页面卡住后瞬移)
        if decelerate == false {
            // slide交互式拖动的松手改写了惯性目标，无减速停止时同样要落地收尾(减速结束时在scrollViewDidEndDecelerating收)
            if endInteractiveSlideDragIfNeeded() {
                if canSwitchedPage {
                    // 完成落地(停在整页侧)：立即提交
                    pauseScroll()
                }else if (abs(contentOffset.x - ((contentSlidingDirection == .topOrBottom) ? 0 : wy_width)) >= 0.5) || (abs(contentOffset.y - ((contentSlidingDirection == .leftOrRight) ? 0 : wy_height)) >= 0.5) {
                    // 回弹落地但静止停在半途：动画滑回中心页，到位由scrollViewDidEndScrollingAnimation走pauseScroll收尾(回弹恢复已把lastValidContentOffset归位中心，落位方向与钳制一致不打架)
                    let center = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
                    setContentOffset(center, animated: true)
                }else {
                    pauseScroll()
                }
            }else if isInteractiveCrossAxisDrag {
                // 呈现族(fade/zoom)松手回弹：cancel补间在飞行、标记要到补间完成才清，偏移由零行程钳制本应在中心(中途改样式带位移进入的边缘场景，cancel入口已同步归位lastValid并解锁，pauseScroll的复位可安全归中)；不走settle——被取消的跨轴拖动若位移过半页，settle会滑向整页侧误提交
                pauseScroll()
            }else if settleStationaryReleaseIfNeeded() == false {
                // 非交互拖动(同轴/单轴)：按半页阈值落位到整页侧或中心，已无位移则照常收尾
                pauseScroll()
            }
        }
    }

    /// 手指释放且惯性减速结束
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 回调外部
        internalDelegate?.scrollViewDidEndDecelerating?(scrollView)
        // slide交互式拖动经系统减速落地：恢复呈现属性与冻结标记后交由pauseScroll按落点提交/复位
        endInteractiveSlideDragIfNeeded()
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
