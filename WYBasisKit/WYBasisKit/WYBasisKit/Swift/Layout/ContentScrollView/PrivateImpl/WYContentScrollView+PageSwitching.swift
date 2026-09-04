//
//  WYContentScrollView+PageSwitching.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：页面切换(切换回调分发/pauseScroll提交/跨轴切换动画编排与直切)
extension WYContentScrollView {
    
    /// 切换内容页回调：isDidSwitch为true=切换完成(didSwitch)、false=即将切换(willSwitch)；direction默认取当前滑动方向
    func switchContentCallback(isDidSwitch: Bool, direction: WYSlidingDirection = .unknown) {
        
        // 优先用调用方显式传入的方向(首次展示场景)，否则用当前滑动方向
        let callbackDirection: WYSlidingDirection = (direction != .unknown) ? direction : internalSliderDirection
        
        guard let contentDelegate = contentDelegate, callbackDirection != .unknown else { return }
        
        if isDidSwitch {
            // didSwitch本身就是"这个轴已经展示了"的通知，收到时顺手把该轴的补发标记设为已发过：如果不设，跨轴切过来后标记还空着，之后某个方向值还没来得及更新的瞬间会把补发误触发，业务平白多收一次didSwitch回调
            if (callbackDirection == .left) || (callbackDirection == .right) {
                hasInitialCallbackHorizontal = true
            }else if (callbackDirection == .up) || (callbackDirection == .down) {
                hasInitialCallbackVertical = true
            }
            contentDelegate.wy_contentScrollViewDidSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }else {
            contentDelegate.wy_contentScrollViewWillSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }
    }
    
    /// 把还在播的代码切页动画瞬间落到终点(防快速连点打断前一动画后无人提交，页面卡在两页中间)
    func completeOngoingProgrammaticSwitch() {
        
        guard isProgrammaticAnimatedScroll else { return }
        
        var completion = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
        if (contentSlidingDirection != .topOrBottom) && (contentOffset.x != wy_width) {
            completion.x = (contentOffset.x > wy_width) ? (2 * wy_width) : 0
        }
        if (contentSlidingDirection != .leftOrRight) && (contentOffset.y != wy_height) {
            completion.y = (contentOffset.y > wy_height) ? (2 * wy_height) : 0
        }
        // 先更新lastValidContentOffset再赋偏移量：赋值会立刻触发didScroll，里面的钳制逻辑会把偏移量拉回lastValidContentOffset记录的位置，顺序反了的话刚赋的终点立刻被旧记录顶回去
        lastValidContentOffset = completion
        setContentOffset(completion, animated: false)
        pauseScroll()
    }
    
    /// 停止滚动并切换contentViews的位置与frame
    func pauseScroll() {
        
        // 记下这次翻页是谁发起的：手势提交要记录时间(供同轴翻页冷却判断用)，代码提交不记录(API切页不该挡住用户随后的手势)
        let wasProgrammaticSwitch = isProgrammaticAnimatedScroll

        // 代码切页动画已收尾(到达终点或被中断)，清除窗口标记
        isProgrammaticAnimatedScroll = false
        
        // 清理与回中必须在下方守卫之前无条件执行：直切链路中途失败提前return时若标记残留true，两轴钳制从此失效、一切拖动都会跟手
        let wasInstantCrossAxisEntry = isInstantCrossAxisEntry
        
        if isInstantCrossAxisEntry {
            isInstantCrossAxisEntry = false
            lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
            if (canSwitchedPage == false) || (internalSliderDirection == .unknown) {
                contentOffset = CGPoint(x: wy_width, y: wy_height)
                return
            }
        }
        
        // 拖动距离不够没翻成页但willSwitch已经发出去了：把偏移量弹回中间页，并把记录恢复到可以再发willSwitch的状态(没切成的语义就是只发will然后弹回，下次滑动重新走一遍流程)；方向还是unknown的程序动画不走这个复位，避免误伤nextContent的动画
        guard (canSwitchedPage == true), (internalSliderDirection != .unknown) else {
            if (canSwitchedPage == false) && (internalSliderDirection != .unknown) && (isInstantCrossAxisEntry == false) {
                let centerOffset = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
                if (contentOffset.x != centerOffset.x) || (contentOffset.y != centerOffset.y) {
                    // 必须先更新合法偏移记录、再赋值偏移量：赋值会立刻触发didScroll回调，里面的钳制逻辑会把偏移量拉回记录里的位置；顺序写反了的话，刚赋的中间位置立刻被旧记录顶回原来的位置，页面就卡在半路回不去了
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
        
        // 提交回中前先更新lastValidContentOffset再赋中心偏移：赋值会立刻重入didScroll，若目标轴的滑动开关是关的，判轴钳制会按还带着拖动/动画位移的旧lastValid把刚赋的中心值顶回原位移
        lastValidContentOffset = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
        
        switch contentSlidingDirection {
        case .leftOrRight:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            contentOffset = CGPoint(x: wy_width, y: 0)
            
            currentHorizontalIndex = reserveHorizontalIndex
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
            
            // 交换数组里两个View的位置，让第一个位置永远是当前页：组件内部的数组记录着"谁是当前页"，重新挂载View时靠它保持顺序不乱
            horizontalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveHorizontalView,currentHorizontalView])
            
            // 切换完成后把旧页面挪到屏幕外的预备位置：新页和旧页都停在中间重叠着，如果内容不满铺(比如小图)，旧页会从新页四周露出来(表现为同时看到两页)；挪出去的位置和挂载时预备页的位置一致
            currentHorizontalView.frame = CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height)
            if wasProgrammaticSwitch == false { lastGestureHorizontalSwitchDate = Date() }
            
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
            
            // 交换数组里两个View的位置，让第一个位置永远是当前页：组件内部的数组记录着"谁是当前页"，重新挂载View时靠它保持顺序不乱
            verticalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveVerticalView, currentVerticalView])
            
            // 切换完成后把旧页面挪到屏幕外的预备位置：新页和旧页都停在中间重叠着，如果内容不满铺(比如小图)，旧页会从新页四周露出来(表现为同时看到两页)；挪出去的位置和挂载时预备页的位置一致
            currentVerticalView.frame = CGRect(x: 0, y: 2 * wy_height, width: wy_width, height: wy_height)
            if wasProgrammaticSwitch == false { lastGestureVerticalSwitchDate = Date() }
            
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
                    // 轻扫直切不翻页不换View：预备页从来没装过目标页的内容，交换会把一个没加载过内容的View当成当前页
                    bringContentToFront([currentHorizontalView, reserveHorizontalView])
                    configHorizontalReserveIndex = nil
                    if wasProgrammaticSwitch == false { lastGestureHorizontalSwitchDate = Date() }
                    switchContentCallback(isDidSwitch: true)
                    // 切轴成功后重新评估轮播(切到能翻页的轴自动继续轮播、切到只有一页的轴自动停)：直切不走方向和数量的变化流程，需要在这里主动刷一次
                    refreshCarouselTimer()
                    // 藏掉离开轴(防不满铺内容从新轴四周透出)
                    syncAxisViewsVisibility()
                    break
                }
                
                currentHorizontalIndex = reserveHorizontalIndex
                
                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                // 交换数组里两个View的位置，让第一个位置永远是当前页：组件内部的数组记录着"谁是当前页"，重新挂载View时靠它保持顺序不乱
                horizontalViews?.swapAt(0, 1)
                
                bringContentToFront([reserveHorizontalView, currentHorizontalView])
                
                // 切换完成后把旧页面挪到屏幕外的预备位置：新页和旧页都停在中间重叠着，如果内容不满铺(比如小图)，旧页会从新页四周露出来(表现为同时看到两页)；挪出去的位置和挂载时预备页的位置一致
                currentHorizontalView.frame = CGRect(x: 2 * wy_width, y: wy_height, width: wy_width, height: wy_height)
                if wasProgrammaticSwitch == false { lastGestureHorizontalSwitchDate = Date() }

                // 跨轴提交后藏掉离开轴(防不满铺内容从新轴四周透出；同轴提交时本调用无变化)
                syncAxisViewsVisibility()
                
                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil
                
                switchContentCallback(isDidSwitch: true)
                
            }else {
                
                if wasInstantCrossAxisEntry {
                    // 轻扫直切不翻页不换View：预备页从来没装过目标页的内容，交换会把一个没加载过内容的View当成当前页
                    bringContentToFront([currentVerticalView, reserveVerticalView])
                    configVerticalReserveIndex = nil
                    if wasProgrammaticSwitch == false { lastGestureVerticalSwitchDate = Date() }
                    switchContentCallback(isDidSwitch: true)
                    // 切轴成功后重新评估轮播(切到能翻页的轴自动继续轮播、切到只有一页的轴自动停)：直切不走方向和数量的变化流程，需要在这里主动刷一次
                    refreshCarouselTimer()
                    // 藏掉离开轴(防不满铺内容从新轴四周透出)
                    syncAxisViewsVisibility()
                    break
                }
                
                currentVerticalIndex = reserveVerticalIndex
                
                reserveVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                // 交换数组里两个View的位置，让第一个位置永远是当前页：组件内部的数组记录着"谁是当前页"，重新挂载View时靠它保持顺序不乱
                verticalViews?.swapAt(0, 1)
                
                bringContentToFront([reserveVerticalView, currentVerticalView])
                
                // 切换完成后把旧页面挪到屏幕外的预备位置：新页和旧页都停在中间重叠着，如果内容不满铺(比如小图)，旧页会从新页四周露出来(表现为同时看到两页)；挪出去的位置和挂载时预备页的位置一致
                currentVerticalView.frame = CGRect(x: wy_width, y: 2 * wy_height, width: wy_width, height: wy_height)
                if wasProgrammaticSwitch == false { lastGestureVerticalSwitchDate = Date() }

                // 跨轴提交后藏掉离开轴(防不满铺内容从新轴四周透出；同轴提交时本调用无变化)
                syncAxisViewsVisibility()
                
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
        
        // 渐变/缩放样式偏移不动：按手指位移换算进度(与判轴同符号约定：手指上/左滑=offset增=正)
        let translation = panGestureRecognizer.translation(in: self)
        if direction == .up { return max(0, min(1, -translation.y / wy_height)) }
        if direction == .down { return max(0, min(1, translation.y / wy_height)) }
        if direction == .left { return max(0, min(1, -translation.x / wy_width)) }
        return max(0, min(1, translation.x / wy_width))
    }
    
    /// 松手判定完成条件：拖过半页或沿完成方向速度达轻扫阈值(回甩不算)
    var isInteractiveCrossCommitReady: Bool {
        
        if interactiveCrossProgress >= 0.5 { return true }
        
        let velocity = panGestureRecognizer.velocity(in: self)
        let axisVelocity = (interactiveCrossDirection == .up) ? -velocity.y
        : (interactiveCrossDirection == .down) ? velocity.y
        : (interactiveCrossDirection == .left) ? -velocity.x
        : velocity.x
        return axisVelocity >= crossAxisFlickVelocityThreshold
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
    
    /// 开始交互式跨轴拖动：预备页按"同下标"语义摆位(补发willSwitch+钉住下标)，slide把进入页摆在进入侧跟手滑，fade/zoom把进入页摆在中心、显示效果随拖动进度变化
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
    
    /// 交互式跨轴拖动期间每帧刷新显示效果(仅fade/zoom，这两种偏移量不动、靠拖动距离控制效果)：进入页透明度随进度变化，zoom还额外带动缩放和退场页的远近感
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
            // 进入页从crossAxisSwitchZoomScale缩放回1.0(与松手后的补齐动画同方向：起于放大值、随进度落回1.0)，退场页反向放大制造推近拉远的纵深感
            let settleScale = crossAxisSwitchZoomScale + (1 - crossAxisSwitchZoomScale) * progress
            enteringView.transform = CGAffineTransform(scaleX: settleScale, y: settleScale)
            let departScale = 1 + (crossAxisSwitchZoomScale - 1) * progress
            departingView?.transform = CGAffineTransform(scaleX: departScale, y: departScale)
            // 防止动画中段露出背景色：退场页的淡出推迟到进度过半之后才开始。两个页面同时半透明时会盖不住底，背景色从缝隙里透出来；进度过半时进入页已经完全不透明地盖在上面，这时底下的页再淡出就看不到了，也露不出背景
            departingView?.alpha = min(1, max(0, 2 - 2 * progress))
        }
    }
    
    /// 松手完成(fade/zoom)：把效果动画播完(进度补满)后经pauseScroll正常提交
    func finishInteractiveCrossAxisDrag() {
        
        // 松手那一刻就把合法偏移记录归位到中心并解除方向锁：真正的收尾在动画完成回调里才执行，那之前记录里存的还是拖动时的偏移，任何想回到中心的赋值都会被钳制逻辑按旧记录顶回去；普通情况这里本来就是中心没有影响，但拖到一半改样式的边缘情况会带着位移走到这里，需要先归位
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
        
        // 统一收尾：把alpha/transform恢复原样、清掉冻结标记，手动把canSwitchedPage置true后经pauseScroll正常提交
        let finalize: () -> Void = { [weak self] in
            // 把四个页面View的alpha/transform全部恢复：摆位时被临时藏起来的目标轴旧当前页(alpha=0)，漏恢复它会透出底下另一轴的内容
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
                // 防止松手后的过渡动画露背景：退场页不参与这段淡出。进度没过半就松手时它还是不透明地垫在下面，如果它和正在渐显的进入页一起做动画，会有短暂两页都是半透明而露出背景；它在进入页下方，收尾时会统一恢复
            }
        }, completion: { (_) in
            finalize()
        })
    }
    
    /// 松手回弹(fade/zoom)：效果动画退回去后恢复原展示轴的层级与页面
    func cancelInteractiveCrossAxisDrag() {
        
        // 松手瞬间先把合法偏移记录归位到中心并解除方向锁：真正的恢复(方向/层级)要等回弹动画播完才执行，这段等待时间里如果记录还停在拖动时的偏移，任何想把页面放回中心的操作都会被钳制逻辑按旧记录顶回原位移(系统减速、落位、复位全部失效，页面永远卡在两页中间)；渐变/缩放样式偏移本来就不动，这里多半是走个过场，防的是拖到一半改样式这种带着位移进来的边缘情况
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
            // 把四个页面View的alpha/transform全部恢复(含摆位时被临时藏起来的目标轴旧当前页，防止透出另一轴内容)
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
            // 回弹恢复原轴后藏掉没切成的目标轴(它的预备页还停在中心，内容不满铺时会透出来)
            self.syncAxisViewsVisibility()
            // 重申一次原轴didSwitch(告诉业务"还停在原页"，和轴初始补发是同一类通知)：切轴前的willSwitch已让业务为切走做了准备(比如暂停当前轴的媒体)，取消后组件无法撤销业务的这些动作，必须重申一次让业务恢复
            self.switchContentCallback(isDidSwitch: true, direction: self.interactiveCrossOriginalAxisIsHorizontal ? .left : .up)
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
    
    /// 交互式跨轴拖动(slide)的减速落地收尾：按落点分流提交或恢复原轴；返回是否接管
    @discardableResult
    func endInteractiveSlideDragIfNeeded() -> Bool {
        
        guard (isInteractiveCrossAxisDrag == true), (crossAxisSwitchStyle == .slide) else { return false }
        
        // 把四个页面View的alpha/transform全部恢复(含摆位时被临时藏起来的目标轴旧当前页，防止透出另一轴内容)
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
            // 回弹：恢复原展示轴方向(拖动期间它已翻成目标轴方向，残留会让下一次拖动的展示轴推导/能力判定判反)与置顶层级，config复位让下次滑动能重新发willSwitch(没切成的语义=只发will然后弹回，下次滑动重新来一遍)
            internalSliderDirection = interactiveCrossOriginalAxisIsHorizontal ? .left : .up
            isInteractiveCrossAxisDrag = false
            isFinalizingSwitch = false
            // 减速落地后马上解除方向锁：残留的锁加上已恢复的原轴方向，会让之后的didScroll被误判成想切轴而钳制拉扯(下一次手势开始时本来也会清，提前清掉免得这个窗口期出干扰)；完成那条分支不能清，提交回中时的钳制还依赖着这个锁放行行程
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
            // 回弹恢复原轴后藏掉没切成的目标轴(它的预备页还停在中心，内容不满铺时会透出来)
            syncAxisViewsVisibility()
            // 重申一次原轴didSwitch(告诉业务"还停在原页"，和轴初始补发是同一类通知)：切轴前的willSwitch已让业务为切走做了准备(比如暂停当前轴的媒体)，取消后组件无法撤销业务的这些动作，必须重申一次让业务恢复
            switchContentCallback(isDidSwitch: true, direction: interactiveCrossOriginalAxisIsHorizontal ? .left : .up)
            return true
        }
    }
    
    /// 静止释放落位：松手时一点速度都没有，系统不会发起减速，按翻页规则补一个落位动画(过半滑向整页那侧、不足一半滑回中心)；返回false表示已经停好无需处理
    @discardableResult
    func settleStationaryReleaseIfNeeded() -> Bool {
        
        // 横竖两个方向各自按"过半取整页"挑最近的目标位置(方向锁保证同时只有一个方向有位移)；单轴模式另一个方向的合法位置固定为0
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
        
        // 动画期间每帧didScroll照常走(方向已锁、预备页已摆好位，落位目标与钳制方向一致不打架)；到位回调scrollViewDidEndScrollingAnimation→pauseScroll按canSwitchedPage提交/复位
        setContentOffset(target, animated: true)
        return true
    }
    
    /// 跨轴切换统一入口：按crossAxisSwitchStyle呈现并收尾
    /// - parameter direction: 目标方向(同时决定.instant/.slide的落位偏移)
    /// - parameter preservesIndex: true为同下标跨轴(下标保持)，false为翻页跨轴(目标轴下标推进/回退)
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
                // 翻页类的跨轴瞬时切换不能带直切标记：直切标记会让收尾走"不换页、下标不落定"的流程，switchContent预设的下标就会残留下来(表现为落在了目标前一页)；不带标记直接跳到目标偏移量再正常提交收尾，代码切页的窗口标记已由nextContent/lastContent设好，didScroll会同步完成预载和下标推进
                setContentOffset(targetOffset, animated: false)
                pauseScroll()
            }
        case .slide:
            var enteringView: UIView?
            var hiddenView: UIView?
            if preservesIndex {
                // 同下标跨轴滑动需要直切标记+重置方向锁(与instantCrossAxisEntry同一套逻辑)：canScroll对跨轴的拦截只放行带直切标记或代码切页动画的滚动，且"下标保持不动"的钳制依赖isCrossAxisEntry这条路径
                isInstantCrossAxisEntry = true
                isDirectionLocked = false
                dragLockedDirection = .unknown
                
                // 摆到进入侧的是预备页(willSwitch已经把目标页的内容装进它了)，同轴的当前页内容是旧的就把它藏起来防止闪现；同下标切换时它跟当前展示页叠在中间同一个位置，必须靠这个临时摆位才能做出"旧页推出去、新页滑进来"的翻页效果
                let staged = stageSameIndexAnimatedArrival(direction: direction, enteringFrame: CGRect(origin: targetOffset, size: CGSize(width: wy_width, height: wy_height)))
                enteringView = staged.entering
                hiddenView = staged.hidden
                // 冻结动画期间setter每帧都会重算下标：首帧之后"上一个方向"已变成目标轴，后续帧会被当成同轴翻页把预备下标±1，同下标语义就坏了(instant只触发一次didScroll没有这个问题)；提交前解除冻结，让pauseScroll正常换位收尾
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
    
    /// 动画样式同下标跨轴共用的预备页摆位：补发willSwitch+把预备下标钉成和当前下标一样+临时藏起旧当前页
    /// - returns: entering=装好目标内容的预备页，hidden=动画结束后需要恢复alpha的同轴当前页
    private func stageSameIndexAnimatedArrival(direction: WYSlidingDirection, enteringFrame: CGRect?) -> (entering: UIView?, hidden: UIView?) {
        
        let arrivingIsHorizontal = (direction == .left) || (direction == .right)
        let enteringView = arrivingIsHorizontal ? horizontalViews?.last : verticalViews?.last
        let hiddenView = arrivingIsHorizontal ? horizontalViews?.first : verticalViews?.first
        
        // 把预备下标钉成和当前下标一样，提交时下标保持不变；必须先钉再发will，因为will里业务是按预备下标装内容的，如果上次拖动失败残留了旧下标(比如从V0上滑到V1一半弹回来了，预备下标还是1)，业务就会装错页(表现为切回来先显示V1再跳回V0)
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
            // 渐变/缩放样式(偏移不动)：进入页摆到中心
            enteringView?.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
        }
        // 解除目标轴隐藏：上一次切走时syncAxisViewsVisibility把它藏了，跨轴摆位时必须让它重新可见(拖动期间原轴的退场页照常展示，由收尾再藏)
        (arrivingIsHorizontal ? horizontalViews : verticalViews)?.forEach { $0.isHidden = false }
        if let enteringView = enteringView {
            bringSubviewToFront(enteringView)
        }
        hiddenView?.alpha = 0
        
        return (enteringView, hiddenView)
    }
    
    /// 渐变/缩放样式的跨轴切换(.fade/.zoom)：偏移量不动、只改alpha/transform，动画结束经pauseScroll正常提交
    func presentationalCrossAxisSwitch(direction: WYSlidingDirection, preservesIndex: Bool) {
        
        // 缩放样式需要同步动画退场页(放大淡出制造纵深感)，必须在setter翻转展示轴之前捕获当前展示页
        let departingIsHorizontal = axisIsHorizontal(of: .unknown)
        let departingView = departingIsHorizontal ? horizontalViews?.first : verticalViews?.first
        
        // 直接赋值触发方向setter：翻页跨轴会推进下标+发willSwitch并把展示轴翻过去；同下标跨轴则保持下标不动(willSwitch由stageSameIndexAnimatedArrival补发，收尾方向也依赖这次赋值)
        internalSliderDirection = direction
        
        let arrivingIsHorizontal = (direction == .left) || (direction == .right)
        var arrivingView: UIView?
        var hiddenView: UIView?
        if preservesIndex {
            let staged = stageSameIndexAnimatedArrival(direction: direction, enteringFrame: nil)
            arrivingView = staged.entering
            hiddenView = staged.hidden
        }else {
            // 翻页跨轴：进入页=预备页(业务已在willSwitch装好目标内容、把它摆在进入侧)，挪回中心置顶呈现
            arrivingView = arrivingIsHorizontal ? horizontalViews?.last : verticalViews?.last
            arrivingView?.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
            if let arrivingView = arrivingView {
                bringSubviewToFront(arrivingView)
            }
            // 解除目标轴隐藏(上一次切走时被syncAxisViewsVisibility藏了)
            (arrivingIsHorizontal ? horizontalViews : verticalViews)?.forEach { $0.isHidden = false }
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
            // 缩放样式：进入页从crossAxisSwitchZoomScale缩放回1.0，退场页同步放大到同一个值再淡出，形成推近拉远的纵深感(进出两边用同一个值控制幅度；初始缩放设得太小会和渐变样式看不出区别)
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
    
    /// 轻扫跨轴直切：置直切标记后无动画跳到目标轴页，手动pauseScroll收尾
    func instantCrossAxisEntry(_ direction: WYSlidingDirection) {
        
        guard (contentSlidingDirection == .omnidirectional), (isInstantCrossAxisEntry == false) else {
            return
        }
        
        // 防止残留的方向锁弄死直切(和nextContent/lastContent同理)：上一轮切换会把锁留在旧轴上，直切跳变过去之后判轴走"已锁定"的分支只看旧轴的位移，沿用旧方向一错判，跳过去的偏移量又被钳回中间，直切就无声无息地失败了，轻扫路径因前置拖动(willBeginDragging清锁)从未暴露，switchContent同下标跨轴直调本方法时才现形
        isDirectionLocked = false
        dragLockedDirection = .unknown
        
        isInstantCrossAxisEntry = true

        // 解除目标轴隐藏(上一次切走时被syncAxisViewsVisibility藏了)
        (((direction == .left) || (direction == .right)) ? horizontalViews : verticalViews)?.forEach { $0.isHidden = false }

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
