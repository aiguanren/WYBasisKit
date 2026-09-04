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
        
        // 暂停计时器但保留"可以重启"的标记，松手后轮播自动继续；不能用stopTimer，因为它会清掉标记，松手后轮播就再也恢复不了了
        pauseTimer()
        // 防御：上一轮交互式跨轴拖动若因异常未收尾，无动画立即复位(正常流程松手会走完成/回弹)
        if isInteractiveCrossAxisDrag {
            isInteractiveCrossAxisDrag = false
            isFinalizingSwitch = false
            interactiveCrossDirection = .unknown
            // 把四个页面View的alpha/transform全部恢复：slide松手后由系统减速接管，用户中途按停不会走减速结束回调，切轴摆位时被临时藏起来的旧当前页若不恢复会一直alpha=0(看不见、且透出底下另一轴的内容)
            [horizontalViews?.first, horizontalViews?.last, verticalViews?.first, verticalViews?.last].forEach { (view) in
                view?.alpha = 1
                view?.transform = .identity
            }
        }
        // 用户接管：清掉代码切页动画的窗口标记
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
            // 初始补发只在手滑的方向就是当前展示轴时才发：朝另一轴滑时那个轴其实还没真正切过来(要等松手提交后才算)，这时补发的didSwitch会让业务提前开播另一个轴的内容，而拖动一松手弹回原轴，就出现画面在原轴、声音在另一轴；真正切过去的流程自带完整的will→did回调，不需要补发。判断条件必须包含"非交互式跨轴拖动中"：拖动切轴的过程中目标轴会被提前翻到最上面，按置顶View判断展示轴会被骗
            if (hasInitialCallbackHorizontal == false) && (isInteractiveCrossAxisDrag == false) && (axisIsHorizontal(of: .unknown) == true) {
                hasInitialCallbackHorizontal = true
                // 直切和代码切页期间不发初始补发：这两种流程自带完整的will→did回调，补发会抢在will前面造成乱序(先收did再收will再收did)；还需要isFinalizingSwitch来拦截，因为pauseScroll开头就把直切标记清了，提交过程重入的didScroll里直切条件已经不成立
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) && (isFinalizingSwitch == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }else {
            // 初始补发只在手滑的方向就是当前展示轴时才发：朝另一轴滑时那个轴其实还没真正切过来(要等松手提交后才算)，这时补发的didSwitch会让业务提前开播另一个轴的内容，而拖动一松手弹回原轴，就出现画面在原轴、声音在另一轴；真正切过去的流程自带完整的will→did回调，不需要补发。判断条件必须包含"非交互式跨轴拖动中"：拖动切轴的过程中目标轴会被提前翻到最上面，按置顶View判断展示轴会被骗
            if (hasInitialCallbackVertical == false) && (isInteractiveCrossAxisDrag == false) && (axisIsHorizontal(of: .unknown) == false) {
                hasInitialCallbackVertical = true
                // 直切和代码切页期间不发初始补发：这两种流程自带完整的will→did回调，补发会抢在will前面造成乱序(先收did再收will再收did)；还需要isFinalizingSwitch来拦截，因为pauseScroll开头就把直切标记清了，提交过程重入的didScroll里直切条件已经不成立
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) && (isFinalizingSwitch == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }
        
        if (contentSlidingDirection == .omnidirectional) && (isDirectionLocked == false) && (slidingDirection == internalSliderDirection) {
            // 判轴前的陈旧方向：跳过(否则setter会误摆预备页、误发willSwitch)
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
        
        // 甩动速度从pan手势取而不是用委托参数：偏移量全程被钳住不动时，委托回传的速度永远是0左右(实测只有2~3pt/s)，只有手指的真实速度才能表达想不想切；符号按"手指往上/往左滑对应offset增大"换算
        let panVelocity = panGestureRecognizer.velocity(in: self)
        let flickVelocity = CGPoint(x: -panVelocity.x, y: -panVelocity.y)
        
        // 交互式跨轴拖动收尾：按进度(≥半页)或速度(达轻扫阈值)决定完成或回弹
        if isInteractiveCrossAxisDrag {
            if crossAxisSwitchStyle == .slide {
                // slide改写惯性目标后交给系统减速：和同轴翻页松手后走同一条减速曲线，自己写固定时长的动画模拟不出这种手感；这里不用crossAxisSwitchDuration(它管的是代码切页/轻扫直切/fade与zoom松手动画这些组件自己驱动的动画)，落地后的收尾见endInteractiveSlideDragIfNeeded
                targetContentOffset.pointee = isInteractiveCrossCommitReady ? interactiveCrossTargetOffset : CGPoint(x: wy_width, y: wy_height)
            }else {
                // 渐变/缩放样式(fade/zoom)收回惯性目标，交给组件自己的动画接管
                targetContentOffset.pointee = CGPoint(x: wy_width, y: wy_height)
                if isInteractiveCrossCommitReady {
                    finishInteractiveCrossAxisDrag()
                }else {
                    cancelInteractiveCrossAxisDrag()
                }
            }
            return
        }
        
        // 候选切入方向：只取甩动速度较大的那个轴(两个轴都认的话，斜着甩同轴翻页时会被误判成切轴)；方向符号与handleScrollDirectionLock的判断规则一致(offset增=left/up)
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
        
        // 当前展示轴(按置顶View事实源判，不用internalSliderDirection)：方向残留会把这个判定骗反(如残留.left时垂直展示下的水平轻扫被判"同轴"而不触发直切)；跨轴轻扫期间方向尚未更新，本就应读展示真相
        let displayedAxisIsHorizontal = axisIsHorizontal(of: .unknown)
        
        // 逐个候选判断：想切到的那个轴只要有内容就行(不管几页)，而且切入方向的速度要明显占优(1.5倍，斜着轻扫时的同轴分量不允许误触发切轴，不然同方向再轻扫一次会误切轴、内容白白重载一遍)；目标轴的滑动开关不拦切轴，开关管的是"在轴内翻页"，不限制"能到达"这个轴(切过去后该轴照样拖不动)；同轴的甩动不走这条路，保持原来的跟手翻页
        for entryDirection in candidates {
            let entryAxisIsHorizontal = (entryDirection == .left) || (entryDirection == .right)
            let entryAxisCount = entryAxisIsHorizontal ? numberOfHorizontalContent : numberOfVerticalContent
            let entryAxisVelocity = entryAxisIsHorizontal ? horizontalVelocity : verticalVelocity
            let otherAxisVelocity = entryAxisIsHorizontal ? verticalVelocity : horizontalVelocity
            if (entryAxisCount >= 1) && (entryAxisIsHorizontal != displayedAxisIsHorizontal) && (entryAxisVelocity > otherAxisVelocity * 1.5) {
                // 收回惯性目标到中心页：斜向甩动的同轴分量会带动可拖的展示轴产生松手减速/翻页吸附动画，与直切竞争
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
        
        // 手指释放且没有惯性：静止松手时系统分页不会发起减速，偏移可能停在两页中间，必须先按翻页规则落到整页位置再收尾(直接pauseScroll会把偏移瞬间硬拉回中心)
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
                // fade/zoom松手弹回原轴：取消动画还在播、标记要等动画播完才清，偏移量本来就被钳在中心不动(拖到一半改样式的边缘情况，取消入口已经同步归位过，这里的复位能安全回到中心)；不走落位动画，被取消的切轴拖动如果位移过了半页，落位会滑向整页那侧造成误切换
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
