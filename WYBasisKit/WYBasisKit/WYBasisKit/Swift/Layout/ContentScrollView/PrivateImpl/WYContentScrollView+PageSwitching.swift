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

    /// 当前展示形态对应的初始滑动方向：左右模式为.left、上下模式为.up、全向模式按优先方向取(用于首次展示的didSwitch回调，此时尚未发生任何滑动)
    var initialDisplayDirection: WYSlidingDirection {
        switch contentSlidingDirection {
        case .leftOrRight:
            return .left
        case .topOrBottom:
            return .up
        case .omnidirectional:
            return (prioritySlidingDirection == .topOrBottom) ? .up : .left
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
                    contentOffset = centerOffset
                    lastValidContentOffset = centerOffset
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

        // 手动补发will(显式传方向，此刻internalSliderDirection还是旧值)
        switchContentCallback(isDidSwitch: false, direction: direction)

        let arrivingIsHorizontal = (direction == .left) || (direction == .right)
        let enteringView = arrivingIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let hiddenView = arrivingIsHorizontal ? horizontalViews?.first : verticalViews?.first

        // 钉住同下标：提交时current=reserve保持不变
        if arrivingIsHorizontal {
            reserveHorizontalIndex = currentHorizontalIndex
        }else {
            reserveVerticalIndex = currentVerticalIndex
        }

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
