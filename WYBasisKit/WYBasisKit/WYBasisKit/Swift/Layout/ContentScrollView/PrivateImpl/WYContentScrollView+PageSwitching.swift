//
//  WYContentScrollView+PageSwitching.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：页面切换(staging回调/pauseScroll提交/跨轴切换呈现编排与直切)
extension WYContentScrollView {

    /// 切换内容页回调，isDidSwitch 为 true 表示切换已完成(didSwitch)、false 表示即将切换(willSwitch)；direction 默认取当前滑动方向，首次展示尚未发生滑动时由调用方传入推导出的初始方向
    func switchContentCallback(isDidSwitch: Bool, direction: WYSlidingDirection = .unknown) {

        // 优先用调用方显式传入的方向(首次展示场景)，否则用当前滑动方向
        let callbackDirection: WYSlidingDirection = (direction != .unknown) ? direction : internalSliderDirection
        
        guard let contentDelegate = contentDelegate, callbackDirection != .unknown else { return }
        
        print("\(isDidSwitch ? "isDidSwitch" : "isWillSwitch"), direction：\(callbackDirection) hIdx=\(currentHorizontalIndex) rhIdx=\(reserveHorizontalIndex) vIdx=\(currentVerticalIndex) rvIdx=\(reserveVerticalIndex)")
        
        if isDidSwitch {
            contentDelegate.wy_contentScrollViewDidSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }else {
            contentDelegate.wy_contentScrollViewWillSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }
    }

    /// 停止滚动并切换contentViews的位置与frame
    func pauseScroll() {

        // 程序化动画已收尾(到达终点或被中断)，清除窗口标记
        isProgrammaticAnimatedScroll = false

        // 清理与回中必须在下方守卫之前无条件执行：直切链路中途失败提前return时若标记残留true，两轴钳制从此失效、一切拖动都会跟手(表现为跨轴变回旧的翻页样式)
        let wasInstantCrossAxisEntry = isInstantCrossAxisEntry

        if isInstantCrossAxisEntry {
            isInstantCrossAxisEntry = false
            lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
            if (canSwitchedPage == false) || (internalSliderDirection == .unknown) {
                contentOffset = CGPoint(x: wy_width, y: wy_height)
                return
            }
        }
        
        // 行程不足的拖动已staging(发过will)但翻页未成立：复位中心页+重置config重新武装willSwitch(失败滑动语义=只will+弹回，下次重新配对)；dir为unknown的程序切换动画分支保持原行为不复活位(防误伤nextContent动画)
        guard (canSwitchedPage == true), (internalSliderDirection != .unknown) else {
            if (canSwitchedPage == false) && (internalSliderDirection != .unknown) && (isInstantCrossAxisEntry == false) {
                let centerOffset = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
                if (contentOffset.x != centerOffset.x) || (contentOffset.y != centerOffset.y) {
                    print("[诊断] 卡中间复位：offset(\(Int(contentOffset.x)),\(Int(contentOffset.y)))→中心 canSwitch=\(canSwitchedPage) dir=\(internalSliderDirection) hIdx=\(currentHorizontalIndex) rhIdx=\(reserveHorizontalIndex)")
                    // 必须先更新lastValid再赋偏移：赋值会同步重入didScroll，判轴钳制按lastValid把偏移拉回"合法位"——顺序反了回中会被陈旧lastValid当场顶回原位移(表现为页面永久卡在两页之间)
                    lastValidContentOffset = centerOffset
                    contentOffset = centerOffset
                }
                configVerticalReserveIndex = currentVerticalIndex
                configHorizontalReserveIndex = currentHorizontalIndex
            }
            return
        }

        isFinalizingSwitch = true
        defer { isFinalizingSwitch = false }

        canSwitchedPage = false

        switch contentSlidingDirection {
        case .leftOrRight:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            contentOffset = CGPoint(x: wy_width, y: 0)

            currentHorizontalIndex = reserveHorizontalIndex
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
            
            // 交换horizontalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
            horizontalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveHorizontalView,currentHorizontalView])
            
            // 下一次方向改变时需要重新设置 reserveHorizontalView
            configHorizontalReserveIndex = nil
            
            switchContentCallback(isDidSwitch: true)
            
            break
        case .topOrBottom:
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            contentOffset = CGPoint(x: 0, y: wy_height)

            currentVerticalIndex = reserveVerticalIndex
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveVerticalView.frame = CGRect(x: 0, y: wy_height, width: wy_width, height: wy_height)
            
            // 交换verticalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
            verticalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveVerticalView, currentVerticalView])
            
            // 下一次方向改变时需要重新设置 reserveVerticalView
            configVerticalReserveIndex = nil
            
            switchContentCallback(isDidSwitch: true)
            
            break
        case.omnidirectional:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            contentOffset = CGPoint(x: wy_width, y: wy_height)
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {

                if wasInstantCrossAxisEntry {
                    // 轻扫直切不翻页不换View：预备View从未staging过目标内容，swap会换到没加载过的View(表现为跨轴来回切内容被重载)
                    bringContentToFront([currentHorizontalView, reserveHorizontalView])
                    configHorizontalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    // 展示轴已翻转：重评轮播(切到可翻轴自动续播、切到单页轴自动停)——直切不触发方向/数量变化，需在此主动刷新
                    refreshCarouselTimer()
                    break
                }

                currentHorizontalIndex = reserveHorizontalIndex

                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换horizontalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
                horizontalViews?.swapAt(0, 1)

                bringContentToFront([reserveHorizontalView, currentHorizontalView])

                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)

            }else {

                if wasInstantCrossAxisEntry {
                    // 轻扫直切不翻页不换View：预备View从未staging过目标内容，swap会换到没加载过的View(表现为跨轴来回切内容被重载)
                    bringContentToFront([currentVerticalView, reserveVerticalView])
                    configVerticalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    // 展示轴已翻转：重评轮播(切到可翻轴自动续播、切到单页轴自动停)——直切不触发方向/数量变化，需在此主动刷新
                    refreshCarouselTimer()
                    break
                }

                currentVerticalIndex = reserveVerticalIndex

                reserveVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换verticalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
                verticalViews?.swapAt(0, 1)

                bringContentToFront([reserveVerticalView, currentVerticalView])

                // 下一次方向改变时需要重新设置 reserveVerticalView
                configVerticalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)
            }
            break
        }
    }

    /// 交互式跨轴拖动的进度(0~1)：slide按偏移行程、fade/zoom按手指位移映射，方向符号与判轴一致(手指上/左滑=正进度)
    var interactiveCrossProgress: CGFloat {

        let direction = interactiveCrossDirection
        guard direction != .unknown else { return 0 }

        if crossAxisSwitchStyle == .slide {
            // slide偏移跟手：行程即进度
            if direction == .up { return max(0, (contentOffset.y - wy_height) / wy_height) }
            if direction == .down { return max(0, (wy_height - contentOffset.y) / wy_height) }
            if direction == .left { return max(0, (contentOffset.x - wy_width) / wy_width) }
            return max(0, (wy_width - contentOffset.x) / wy_width)
        }

        // 呈现族偏移不动：按手指位移映射进度(与判轴同符号约定：手指上/左滑=offset增=正)
        let translation = panGestureRecognizer.translation(in: self)
        if direction == .up { return max(0, min(1, -translation.y / wy_height)) }
        if direction == .down { return max(0, min(1, translation.y / wy_height)) }
        if direction == .left { return max(0, min(1, -translation.x / wy_width)) }
        return max(0, min(1, translation.x / wy_width))
    }

    /// 松手判定的完成条件：拖过半页或轴向速度达轻扫阈值(轻甩也算成)；阈值取1/2与同轴分页的过半确认语义对齐(原1/3更激进，与同轴直觉不一致)
    var isInteractiveCrossCommitReady: Bool {

        if interactiveCrossProgress >= 0.5 { return true }

        let velocity = panGestureRecognizer.velocity(in: self)
        let axisVelocity = (interactiveCrossDirection == .up) ? -velocity.y
            : (interactiveCrossDirection == .down) ? velocity.y
            : (interactiveCrossDirection == .left) ? -velocity.x
            : velocity.x
        return abs(axisVelocity) >= crossAxisFlickVelocityThreshold
    }

    /// 交互式跨轴拖动的目标侧偏移(与performCrossAxisSwitch同映射)
    var interactiveCrossTargetOffset: CGPoint {
        var target = CGPoint(x: wy_width, y: wy_height)
        if interactiveCrossDirection == .left { target.x = 2 * wy_width }
        else if interactiveCrossDirection == .right { target.x = 0 }
        else if interactiveCrossDirection == .up { target.y = 2 * wy_height }
        else if interactiveCrossDirection == .down { target.y = 0 }
        return target
    }

    /// 开始交互式跨轴拖动(判轴锁到跨轴意图时调用)：staging复用动画样式的同下标通道(补发will预载+预备页为进入页+钉住下标+隐藏陈旧当前页)，slide把进入页摆到进入侧随偏移跟手，fade/zoom摆中心由进度驱动；冻结setter下标计算防每帧重入推进(与au轮同源)
    func beginInteractiveCrossAxisDrag(direction: WYSlidingDirection) {

        isInteractiveCrossAxisDrag = true
        interactiveCrossDirection = direction
        // 记录原展示轴(置顶View真相)：能力判定与回弹恢复都以此为准
        interactiveCrossOriginalAxisIsHorizontal = axisIsHorizontal(of: .unknown)

        let enteringFrame = (crossAxisSwitchStyle == .slide)
            ? CGRect(origin: interactiveCrossTargetOffset, size: CGSize(width: wy_width, height: wy_height))
            : nil
        let staged = stageSameIndexAnimatedArrival(direction: direction, enteringFrame: enteringFrame)
        _ = staged.entering
        _ = staged.hidden

        isFinalizingSwitch = true
    }

    /// 交互式跨轴拖动每帧驱动(仅fade/zoom，偏移不动由拖动距离驱动呈现)：进入页alpha随进度、zoom另带缩放与退场页纵深感
    func updateInteractiveCrossAxisProgress() {

        guard (isInteractiveCrossAxisDrag == true),
              (crossAxisSwitchStyle == .fade) || (crossAxisSwitchStyle == .zoom) else { return }

        let progress = interactiveCrossProgress
        let enteringIsHorizontal = (interactiveCrossDirection == .left) || (interactiveCrossDirection == .right)
        let enteringView = enteringIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let departingView = enteringIsHorizontal ? verticalViews?.first : horizontalViews?.first
        guard let enteringView = enteringView else { return }

        enteringView.alpha = progress
        if crossAxisSwitchStyle == .zoom {
            // 进入页从crossAxisSwitchZoomScale缩放归位(与非交互呈现族同向：起于放大值、随进度落回1.0)，退场页反向放大制造推近拉远的纵深感
            let settleScale = crossAxisSwitchZoomScale + (1 - crossAxisSwitchZoomScale) * progress
            enteringView.transform = CGAffineTransform(scaleX: settleScale, y: settleScale)
            let departScale = 1 + (crossAxisSwitchZoomScale - 1) * progress
            departingView?.transform = CGAffineTransform(scaleX: departScale, y: departScale)
            // 防中段露背景色：退场页的淡出推迟到后半程——两层同时半透明时叠加覆盖不足，背景会从空隙透出(进入页盖在上方，进度过半时它已完全不透明，垫底页此后淡出不可见也不露背景)
            departingView?.alpha = min(1, max(0, 2 - 2 * progress))
        }
    }

    /// 松手完成(呈现族fade/zoom)：把过渡动画补到全量后正常提交(进入页呈现补满+手动置位canSwitchedPage)，下标经pauseScroll正常落定(同下标语义)；slide不走此路径——松手改写惯性目标交给系统减速(与同轴翻页同源手感)，落地收尾见endInteractiveSlideDragIfNeeded
    func finishInteractiveCrossAxisDrag() {

        // 松手瞬间同步归位钳制基准并解除方向锁：补间完成前(动画窗口内)一切回中写入都会被"按陈旧lastValid(拖动位移)钳回"顶回原位移；呈现族本就零行程此处置多为空操作，但拖动途中切换样式的边缘场景会带着位移进入本路径(表现为页面卡在两页之间)，提交的回中由pauseScroll完成
        lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
        isDirectionLocked = false
        dragLockedDirection = .unknown

        let direction = interactiveCrossDirection
        let enteringIsHorizontal = (direction == .left) || (direction == .right)
        let enteringView = enteringIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let departingView = enteringIsHorizontal ? verticalViews?.first : horizontalViews?.first
        let style = crossAxisSwitchStyle
        let duration = crossAxisSwitchDuration
        let zoomScale = crossAxisSwitchZoomScale

        // 统一收尾：恢复呈现属性与冻结标记，手动置位canSwitchedPage后经pauseScroll正常提交
        let finalize: () -> Void = { [weak self] in
            // 全量恢复四个页面View的呈现属性：staging隐藏过目标轴的陈旧当前页(alpha=0)，漏恢复它会透视出底下另一轴的内容(表现为后续正常翻页"H显示V的内容")
            [self?.horizontalViews?.first, self?.horizontalViews?.last, self?.verticalViews?.first, self?.verticalViews?.last].forEach { (view) in
                view?.alpha = 1
                view?.transform = .identity
            }
            guard let self = self else { return }
            self.isInteractiveCrossAxisDrag = false
            self.isFinalizingSwitch = false
            self.canSwitchedPage = true
            self.pauseScroll()
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            enteringView?.alpha = 1
            if style == .zoom {
                enteringView?.transform = .identity
                departingView?.transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                // 防完成补间露背景：退场页不参与完成动画的淡出——进度过半前松手时它还是不透明垫底，与正在渐显的进入页同时补间会短暂两层皆半透明；它垫在进入页下方，finalize会统一恢复其呈现属性
            }
        }, completion: { (_) in
            finalize()
        })
    }

    /// 松手回弹(呈现族fade/zoom)：过渡动画归零后恢复原展示轴的层级与页面，config复位重新武装willSwitch(失败语义=只will+回弹，下次重新配对)；slide不走此路径——回弹由系统减速到中心完成，落地收尾见endInteractiveSlideDragIfNeeded
    func cancelInteractiveCrossAxisDrag() {

        // 松手瞬间同步归位钳制基准并解除方向锁：真实清场(恢复方向/层级)在补间完成回调里异步执行，窗口内方向锁+陈旧lastValid(拖动位移)会让判轴钳制把一切回中写入顶回原位移(系统减速/settle/复位全部失效，页面永久卡在两页之间)；呈现族本就零行程此处置多为空操作，防的是拖动途中切换样式带位移进入本路径的边缘场景
        lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
        isDirectionLocked = false
        dragLockedDirection = .unknown

        let direction = interactiveCrossDirection
        let enteringIsHorizontal = (direction == .left) || (direction == .right)
        let enteringView = enteringIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let departingView = enteringIsHorizontal ? verticalViews?.first : horizontalViews?.first
        let style = crossAxisSwitchStyle
        let duration = crossAxisSwitchDuration
        let zoomScale = crossAxisSwitchZoomScale

        let restore: () -> Void = { [weak self] in
            // 全量恢复四个页面View的呈现属性(含staging隐藏的目标轴陈旧当前页，防透视另一轴内容)
            [self?.horizontalViews?.first, self?.horizontalViews?.last, self?.verticalViews?.first, self?.verticalViews?.last].forEach { (view) in
                view?.alpha = 1
                view?.transform = .identity
            }
            guard let self = self else { return }
            // 方向恢复为原展示轴方向：拖动期间它已翻成目标轴方向，残留会让下一次拖动的展示轴推导/能力判定判反(跳转错乱的根源之一)
            self.internalSliderDirection = self.interactiveCrossOriginalAxisIsHorizontal ? .left : .up
            self.isInteractiveCrossAxisDrag = false
            self.isFinalizingSwitch = false
            // 恢复原展示轴置顶(拖动期间setter的bringContentToFront已把目标轴置顶)与合法偏移基准
            let originalViews = enteringIsHorizontal ? self.verticalViews : self.horizontalViews
            if let originalCurrent = originalViews?.first, let originalReserve = originalViews?.last {
                self.bringContentToFront([originalCurrent, originalReserve])
            }
            if enteringIsHorizontal {
                self.reserveHorizontalIndex = self.currentHorizontalIndex
                self.configHorizontalReserveIndex = self.currentHorizontalIndex
            }else {
                self.reserveVerticalIndex = self.currentVerticalIndex
                self.configVerticalReserveIndex = self.currentVerticalIndex
            }
            self.lastValidContentOffset = CGPoint(x: self.wy_width, y: self.wy_height)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            enteringView?.alpha = 0
            if style == .zoom {
                enteringView?.transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                departingView?.transform = .identity
                departingView?.alpha = 1
            }
        }, completion: { (_) in
            restore()
        })
    }

    /// 交互式跨轴拖动(slide)的系统减速落地收尾：slide松手只改写惯性目标(完成=目标侧整页/回弹=中心)，飞行动画由系统动能减速完成(与同轴翻页松手同源)，本方法在减速结束/无减速停止时恢复呈现属性与冻结标记并按落点分流——已越整页(canSwitchedPage成立)交由调用方紧随的pauseScroll正常提交(换位+didSwitch)，未越则恢复原展示轴方向与层级(config复位重新武装willSwitch)；返回是否接管了slide交互收尾(调用方据此决定后续落位处理)
    @discardableResult
    func endInteractiveSlideDragIfNeeded() -> Bool {

        guard (isInteractiveCrossAxisDrag == true), (crossAxisSwitchStyle == .slide) else { return false }

        // 全量恢复四个页面View的呈现属性(含staging隐藏的目标轴陈旧当前页，防透视另一轴内容)
        [horizontalViews?.first, horizontalViews?.last, verticalViews?.first, verticalViews?.last].forEach { (view) in
            view?.alpha = 1
            view?.transform = .identity
        }

        let enteringIsHorizontal = (interactiveCrossDirection == .left) || (interactiveCrossDirection == .right)

        if canSwitchedPage {
            // 完成：系统减速会精确停在改写的惯性目标上(整页侧)，方向保持目标轴，提交交给调用方紧随的pauseScroll(下标经同下标语义落定)
            isInteractiveCrossAxisDrag = false
            isFinalizingSwitch = false
            return true
        }else {
            // 回弹：恢复原展示轴方向(拖动期间它已翻成目标轴方向，残留会让下一次拖动的展示轴推导/能力判定判反)与置顶层级，config复位重新武装willSwitch(失败语义=只will+回弹，下次重新配对)
            internalSliderDirection = interactiveCrossOriginalAxisIsHorizontal ? .left : .up
            isInteractiveCrossAxisDrag = false
            isFinalizingSwitch = false
            // 落地即解除方向锁：残留的跨轴锁+已恢复的原轴方向会让后续didScroll被判成跨轴意图而钳制拉扯(下一次手势本也会清，提前清掉窗口期干扰)；完成分支不清——提交回中的重入钳制仍依赖锁定轴放行行程
            isDirectionLocked = false
            dragLockedDirection = .unknown
            let originalViews = enteringIsHorizontal ? verticalViews : horizontalViews
            if let originalCurrent = originalViews?.first, let originalReserve = originalViews?.last {
                bringContentToFront([originalCurrent, originalReserve])
            }
            if enteringIsHorizontal {
                reserveHorizontalIndex = currentHorizontalIndex
                configHorizontalReserveIndex = currentHorizontalIndex
            }else {
                reserveVerticalIndex = currentVerticalIndex
                configVerticalReserveIndex = currentVerticalIndex
            }
            lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
            return true
        }
    }

    /// 静止释放落位：零速度释放时系统分页不发起减速(decelerate=false)，偏移停在两页之间，原路径会瞬时硬跳回中心(表现为页面卡住后瞬移)——此处按同轴分页语义补一段系统落位动画：位移过半页滑向整页侧(到位由scrollViewDidEndScrollingAnimation走pauseScroll正常提交)，不足半页滑回中心页；用setContentOffset(animated:)而非UIView.animate，系统的落位动画可被新触摸原生打断；返回false表示无需接管(已在页边界，落位无意义)
    @discardableResult
    func settleStationaryReleaseIfNeeded() -> Bool {

        // 各维独立按半页阈值取最近整页(轴锁保证只有一维有位移)；单轴模式另一维的合法位置恒为0
        var target = CGPoint(x: wy_width, y: wy_height)
        if contentSlidingDirection == .leftOrRight {
            target.y = 0
        }else if contentSlidingDirection == .topOrBottom {
            target.x = 0
        }

        if contentSlidingDirection != .topOrBottom {
            let deltaX = contentOffset.x - wy_width
            if abs(deltaX) >= (wy_width / 2) {
                target.x = (deltaX > 0) ? (2 * wy_width) : 0
            }
        }
        if contentSlidingDirection != .leftOrRight {
            let deltaY = contentOffset.y - wy_height
            if abs(deltaY) >= (wy_height / 2) {
                target.y = (deltaY > 0) ? (2 * wy_height) : 0
            }
        }

        if (abs(target.x - contentOffset.x) < 0.5) && (abs(target.y - contentOffset.y) < 0.5) {
            return false
        }

        // 动画期间每帧didScroll照常走(方向已锁、预备页staging就位，settle目标与钳制方向一致不打架)；到位回调scrollViewDidEndScrollingAnimation→pauseScroll按canSwitchedPage提交/复位
        setContentOffset(target, animated: true)
        return true
    }

    /// 跨轴切换统一入口：按crossAxisSwitchStyle呈现并收尾——.instant走instantCrossAxisEntry(无动画跳变+手动收尾)；.slide以UIView.animate驱动偏移滑动(每帧didScroll照常走判轴/staging链路，时长可控——系统setContentOffset动画时长固定不可调)；.fade/.zoom为呈现族(偏移不动、状态机全程静默，见presentationalCrossAxisSwitch)
    /// - parameter direction: 目标方向(同时决定.instant/.slide的落位偏移)
    /// - parameter preservesIndex: true为同下标跨轴(下标保持，用于轻扫直切与switchContent同下标跨轴；instant只发didSwitch，动画样式补发willSwitch后正常提交换位)；false为翻页跨轴(目标轴下标推进/回退、will→did成对，用于nextContent/lastContent/switchContent跨轴翻页)
    func performCrossAxisSwitch(direction: WYSlidingDirection, preservesIndex: Bool) {

        var targetOffset = CGPoint(x: wy_width, y: wy_height)
        if direction == .left {
            targetOffset.x = 2 * wy_width
        }else if direction == .right {
            targetOffset.x = 0
        }else if direction == .up {
            targetOffset.y = 2 * wy_height
        }else {
            targetOffset.y = 0
        }

        switch crossAxisSwitchStyle {
        case .instant:
            if preservesIndex {
                instantCrossAxisEntry(direction)
            }else {
                // 翻页跨轴的瞬时切换不能带直切标记：直切标记会让pauseScroll走直切收尾(不换位不落标)，switchContent预设的下标(target-1)就会残留在current上(表现为落在目标-1处)——直接跳到目标偏移后pauseScroll正常提交；程序化窗口标记已由nextContent/lastContent置位，didScroll同步完成staging/willSwitch/下标推进
                setContentOffset(targetOffset, animated: false)
                pauseScroll()
            }
        case .slide:
            var enteringView: UIView?
            var hiddenView: UIView?
            if preservesIndex {
                // 同下标跨轴滑动需要直切标记+锁重置(与instantCrossAxisEntry同源)：canScroll跨轴拦截只对直切标记/程序化窗口放行，且下标保持的钳制依赖isCrossAxisEntry路径
                isInstantCrossAxisEntry = true
                isDirectionLocked = false
                dragLockedDirection = .unknown

                // 进入侧摆位的是预备页(willSwitch已把目标页内容装进它)，同轴当前页内容陈旧需隐藏防闪现；同下标与当前展示页在中心重叠，偏移滑动只能靠这个临时摆位呈现"当前展示页推出+目标页滑入"的翻页观感
                let staged = stageSameIndexAnimatedArrival(direction: direction, enteringFrame: CGRect(origin: targetOffset, size: CGSize(width: wy_width, height: wy_height)))
                enteringView = staged.entering
                hiddenView = staged.hidden
                // 冻结动画期间每帧重入setter的下标计算：首帧后previous已翻为目标轴，后续帧会被按同轴推进把reserve±1，同下标语义被破坏(instant只触发一次didScroll无此问题)；提交前清除，让pauseScroll正常换位收尾
                isFinalizingSwitch = true
            }
            UIView.animate(withDuration: crossAxisSwitchDuration, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: { [weak self] in
                self?.contentOffset = targetOffset
            }, completion: { [weak self] (finished) in
                // 复位临时摆位/隐藏/冻结标记(与收尾同runloop无中间帧)；用户接管时同样必须复位，残留状态会污染后续拖动与提交
                enteringView?.frame = CGRect(x: self?.wy_width ?? 0, y: self?.wy_height ?? 0, width: self?.wy_width ?? 0, height: self?.wy_height ?? 0)
                hiddenView?.alpha = 1
                guard let self = self else { return }
                self.isInstantCrossAxisEntry = false
                self.isFinalizingSwitch = false
                // 用户已接管拖动/惯性时交由松手流程收尾，此处收尾会在拖动中提前提交换页
                guard (self.isTracking == false) && (self.isDecelerating == false) else { return }
                self.pauseScroll()
            })
        case .fade, .zoom:
            presentationalCrossAxisSwitch(direction: direction, preservesIndex: preservesIndex)
        }
    }

    /// 动画样式同下标跨轴的共用staging：手动补发willSwitch(setter的跨轴钳制按"页没变不发will"吞掉了它，但动画期间目标内容必须就位，instant的原子语义不适用)——业务会把目标页内容装进预备页，动画的进入页就是预备页，完成后经正常提交换位成当前页(下标未变但View换了，承载业务刚装的内容)；同时显式钉住reserve下标等于current(动画期间isFinalizingSwitch会冻结setter的下标计算，不钉住则沿用残留值提交后下标漂移)；并隐藏同轴当前页(内容陈旧，动画期间透出会闪现旧页)
    /// - returns: entering=装好目标内容的预备页(已摆位置顶)，hidden=动画后需恢复alpha的同轴当前页
    private func stageSameIndexAnimatedArrival(direction: WYSlidingDirection, enteringFrame: CGRect?) -> (entering: UIView?, hidden: UIView?) {

        let arrivingIsHorizontal = (direction == .left) || (direction == .right)
        let enteringView = arrivingIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let hiddenView = arrivingIsHorizontal ? horizontalViews?.first : verticalViews?.first

        // 钉住同下标：提交时current=reserve保持不变；必须在补发will之前钉——will里业务按reserveIndex给预备页装内容，上次失败拖动staging残留的reserve(如V0上滑V1半程回弹后仍是1)会让业务装错页(表现为跨轴切回该轴时先显示陈旧页、提交后才被didSwitch按currentIndex纠正)
        if arrivingIsHorizontal {
            reserveHorizontalIndex = currentHorizontalIndex
        }else {
            reserveVerticalIndex = currentVerticalIndex
        }

        // 手动补发will(显式传方向，此刻internalSliderDirection还是旧值)
        switchContentCallback(isDidSwitch: false, direction: direction)

        if let enteringFrame = enteringFrame {
            enteringView?.frame = enteringFrame
        }else {
            // 呈现族(渐变/缩放)偏移不动：进入页摆到中心
            enteringView?.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
        }
        if let enteringView = enteringView {
            bringSubviewToFront(enteringView)
        }
        hiddenView?.alpha = 0

        return (enteringView, hiddenView)
    }

    /// 呈现族跨轴切换(.fade渐变/.zoom缩放)：偏移不动，只动alpha/transform——进入页与退场页本就在中心位重叠，无需偏移参与；动画期间didScroll静默(无判轴/钳制/中断竞争)，动画结束恢复呈现属性并经pauseScroll正常提交
    func presentationalCrossAxisSwitch(direction: WYSlidingDirection, preservesIndex: Bool) {

        // 缩放样式需要同步动画退场页(放大淡出制造纵深感)，必须在setter翻转展示轴之前捕获当前展示页
        let departingIsHorizontal = axisIsHorizontal(of: .unknown)
        let departingView = departingIsHorizontal ? horizontalViews?.first : verticalViews?.first

        // 直接赋值触发setter：翻页跨轴推进下标+发will并翻转展示轴；同下标跨轴钳制保持(其will由stageSameIndexAnimatedArrival补发，收尾方向也依赖此赋值)
        internalSliderDirection = direction

        let arrivingIsHorizontal = (direction == .left) || (direction == .right)
        var arrivingView: UIView?
        var hiddenView: UIView?
        if preservesIndex {
            let staged = stageSameIndexAnimatedArrival(direction: direction, enteringFrame: nil)
            arrivingView = staged.entering
            hiddenView = staged.hidden
        }else {
            // 翻页跨轴：进入页=预备页(业务已在willSwitch装好目标内容，staging把它摆在一侧)，挪回中心置顶呈现
            arrivingView = arrivingIsHorizontal ? horizontalViews?.last : verticalViews?.last
            arrivingView?.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
            if let arrivingView = arrivingView {
                bringSubviewToFront(arrivingView)
            }
        }
        guard let arriving = arrivingView else { return }

        let duration = crossAxisSwitchDuration
        let style = crossAxisSwitchStyle

        // 收尾(两样式共用)：恢复全部呈现属性(退场页/隐藏页随后会被换位复用，残留会污染后续展示)，再置位canSwitchedPage走pauseScroll正常提交(下标落定+换位+didSwitch，同下标与翻页统一走此路径)
        let finalize: (Bool) -> Void = { [weak self] (finished) in
            arriving.alpha = 1
            arriving.transform = .identity
            departingView?.alpha = 1
            departingView?.transform = .identity
            departingView?.isHidden = false
            hiddenView?.alpha = 1
            guard let self = self else { return }
            self.canSwitchedPage = true
            self.pauseScroll()
        }

        let isZoom = (style == .zoom)
        let zoomScale = crossAxisSwitchZoomScale
        arriving.alpha = 0
        if isZoom {
            // 缩放样式：进入页从crossAxisSwitchZoomScale缩放归位，退场页同步放大至同值淡出，形成推近拉远的纵深感(对称缩放一个旋钮控制幅度；初始缩放过小与渐变难以分辨)
            arriving.transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
            departingView?.transform = .identity
            departingView?.alpha = 1
        }
        // 不开allowUserInteraction：换方向是低频操作，原子完成比可中断更干净(滑动族才有中断语义)
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            arriving.alpha = 1
            if isZoom {
                arriving.transform = .identity
                departingView?.transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                departingView?.alpha = 0
            }
        }, completion: { (finished) in
            finalize(finished)
        })
    }

    /// 轻扫跨轴直切：置直切标记后无动画跳到目标轴页(didScroll链路同步触发方向锁定、储备页摆位与willSwitch补发，随后手动pauseScroll完成换页并回调didSwitch；非动画setContentOffset只触发一次didScroll且不会回调scrollViewDidEndScrollingAnimation，收尾必须手动调用)
    func instantCrossAxisEntry(_ direction: WYSlidingDirection) {

        guard (contentSlidingDirection == .omnidirectional), (isInstantCrossAxisEntry == false) else {
            return
        }

        // 防残留方向锁杀死直切(与nextContent/lastContent同源)：上一轮程序化切换/滑动会把锁留在旧轴上，直切跳变后判轴走"已锁定"分支只看旧轴位移(水平跳变的deltaY=0)会沿用旧方向，错判后再被"锁死另一方向"把跳变偏移钳回中心，直切静默失败——轻扫路径因前置拖动(willBeginDragging清锁)从未暴露，switchContent同下标跨轴直调本方法时才现形
        isDirectionLocked = false
        dragLockedDirection = .unknown

        isInstantCrossAxisEntry = true

        var targetOffset = CGPoint(x: wy_width, y: wy_height)
        if direction == .left {
            targetOffset.x = 2 * wy_width
        }else if direction == .right {
            targetOffset.x = 0
        }else if direction == .up {
            targetOffset.y = 2 * wy_height
        }else {
            targetOffset.y = 0
        }
        setContentOffset(targetOffset, animated: false)
        pauseScroll()
    }
}
