//
//  WYContentScrollView+GestureControl.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：手势判轴与滚动控制(方向锁定/轴能力钳制/跨轴拦截/轮播计时器启停)
extension WYContentScrollView {
    
    /// 暂停定时器
    func pauseTimer() {
        if timer != nil {
        }
        timer?.invalidate()
        timer = nil
    }
    
    /// 同轴手势翻页冷却判定：该轴设置了最小间隔、且距上次手势翻页还没超过间隔(代码切页和轻扫直切不记录时间、不受冷却限制)
    func isSameAxisGestureCoolingDown(isHorizontal: Bool) -> Bool {

        let interval = isHorizontal ? horizontalMinimumSwitchInterval : verticalMinimumSwitchInterval
        guard interval > 0 else { return false }

        let lastDate = isHorizontal ? lastGestureHorizontalSwitchDate : lastGestureVerticalSwitchDate
        guard let lastDate = lastDate else { return false }

        return Date().timeIntervalSince(lastDate) < interval
    }

    /// 轮播计时器随展示轴/数量/开关动态启停：翻不了页时停掉计时器，恢复可翻且此前开过轮播时自动重启
    func refreshCarouselTimer() {
        
        // 无限翻页前提按展示轴的开关判定(轮播只翻展示轴，无限开关已按轴拆分)
        guard let carouselDirection = carouselDirection else {
            // 用暂停而非停止：条件恢复(数量改回/开关重开/展示轴翻回)后自动续播，重启标记不能丢
            pauseTimer()
            return
        }
        guard (automaticCarousel != false) && ((carouselDirection == .topOrBottom) ? (verticalUnlimitedCarousel != false) : (horizontalUnlimitedCarousel != false)) else {
            // 用暂停而非停止：条件恢复(数量改回/开关重开/展示轴翻回)后自动续播，重启标记不能丢
            pauseTimer()
            return
        }
        
        // 计时器不在跑且此前开启过轮播才重启：从未startTimer过、或业务已把automaticCarousel设为false的，不复活(stopTimer只是暂停性质的停止，彻底关掉要用automaticCarousel=false，和松手后恢复轮播是同一套逻辑)；用户正在拖动/惯性滚动中不重启，交给松手回调处理
        if (timer == nil) && (canRestartedTimer == true) && (isTracking == false) && (isDecelerating == false) {
            startTimer()
        }
    }
    
    /// 检查当前滚动能力（只控制整体是否可滚动，不参与方向控制）
    func checkCarouselStatus() {
        
        switch contentSlidingDirection {
        case .leftOrRight:
            // 横向滑动(单页/无内容不可滑)
            isScrollEnabled = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false
            break
        case .topOrBottom:
            // 纵向滑动(单页/无内容不可滑)
            isScrollEnabled = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false
            break
        case .omnidirectional:
            // 横向轴是否存在内容且允许滑动
            let horizontalExists = (numberOfHorizontalContent >= 1) && horizontalSliderEnabled
            // 纵向轴是否存在内容且允许滑动
            let verticalExists = (numberOfVerticalContent >= 1) && verticalSliderEnabled
            
            // 此模式下只要有一个方向存在内容且允许滑动就放开全局滚动(isScrollEnabled是全局的)，具体方向与单页约束通过handleScrollDirectionLock与canScroll按展示轴动态实现；两轴开关全关时此处为false=手势完全静默(纯展示，跨轴轻扫也不响应，双关的意图是锁死交互)，此时切换方向只能走switchContent等API(显式指令不受手势开关约束，isScrollEnabled只挡触摸、不挡代码赋值)
            isScrollEnabled = horizontalExists || verticalExists
            break
        }
        
        // 方向/数量/开关任何变化后动态启停轮播计时器(展示轴翻不了页时清除防空转，恢复可翻时自动重启)
        refreshCarouselTimer()
    }
    
    /// 处理方向锁定并返回当前滑动方向：锁死不可滑方向、全向判定并锁定拖拽主方向、边界处钳制contentOffset
    func handleScrollDirectionLock() -> WYSlidingDirection {
        
        // 方向推导必须读钳制前的原始偏移：代码切页动画的位移会被下方轴能力钳制回中心，读钳制后的偏移的话变化量一直是0、判不出方向(轮播就卡住不动了)
        let incomingOffset = contentOffset
        
        // 横向是否允许滑动(非全向：单页/无内容不可滑)
        var horizontalCanScroll = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false
        
        // 纵向是否允许滑动(非全向：单页/无内容不可滑)
        var verticalCanScroll = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false
        
        if contentSlidingDirection == .omnidirectional {
            
            // 判断当前展示的是哪个轴：方向还不知道时按最顶上的View判断(优先方向只是刚挂载那会儿的展示轴，拿它判断会把"已经切到垂直轴后的垂直滑动"错当成跨轴滑动而拦死)；跨轴拖动进行中改用开始那一刻记下的原展示轴，因为方向值已经翻成目标轴了，再按它判断会误以为已经切过去了
            let displayedAxisIsHorizontal = isInteractiveCrossAxisDrag ? interactiveCrossOriginalAxisIsHorizontal : axisIsHorizontal(of: internalSliderDirection)
            horizontalCanScroll = false
            verticalCanScroll = false
            if isDirectionLocked {
                let lockedAxisIsHorizontal = (dragLockedDirection == .left) || (dragLockedDirection == .right)
                horizontalCanScroll = lockedAxisIsHorizontal && displayedAxisIsHorizontal && (numberOfHorizontalContent > 1) && horizontalSliderEnabled
                verticalCanScroll = (lockedAxisIsHorizontal == false) && (displayedAxisIsHorizontal == false) && (numberOfVerticalContent > 1) && verticalSliderEnabled
            }
        }
        
        if isInstantCrossAxisEntry || isProgrammaticAnimatedScroll {
            // 轻扫直切/代码切页动画期间：两轴临时放行(单轴数量约束由下方方向锁定逻辑保证)，避免偏移被钳回中心(动画被钳会少吃一段位移，最后停的位置不够一整页、切换失败弹回)
            horizontalCanScroll = true
            verticalCanScroll = true
        }
        
        if (isInteractiveCrossAxisDrag == true) && (crossAxisSwitchStyle == .slide) && isDirectionLocked {
            // slide样式的跨轴拖动：放开锁定轴让偏移跟手滑动(像普通翻页一样)；fade/zoom不开，因为它们靠拖动距离控制渐变/缩放，偏移保持不动
            if (dragLockedDirection == .left) || (dragLockedDirection == .right) {
                horizontalCanScroll = true
            }else {
                verticalCanScroll = true
            }
        }
        
        if isDirectionLocked && (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
            // 同轴翻页冷却：距离上次手势翻页还没超过设定间隔时，新的同轴拖动直接钳住不动、也不发任何回调(和滑动开关关闭同样的体验)；想切轴的拖动和代码切页不受这个限制
            let displayedAxisIsHorizontal = isInteractiveCrossAxisDrag ? interactiveCrossOriginalAxisIsHorizontal : axisIsHorizontal(of: internalSliderDirection)
            let lockedAxisIsHorizontal = (dragLockedDirection == .left) || (dragLockedDirection == .right)
            if (lockedAxisIsHorizontal == displayedAxisIsHorizontal) && isSameAxisGestureCoolingDown(isHorizontal: lockedAxisIsHorizontal) {
                if lockedAxisIsHorizontal {
                    horizontalCanScroll = false
                }else {
                    verticalCanScroll = false
                }
            }
        }

        // 目标偏移量
        var targetOffset = contentOffset
        
        // 禁止横向滑动
        if !horizontalCanScroll {
            targetOffset.x = lastValidContentOffset.x
        }
        
        // 禁止纵向滑动
        if !verticalCanScroll {
            targetOffset.y = lastValidContentOffset.y
        }
        
        // 如果发生变化则修正(经统一入口，防写入互递归)
        correctContentOffset(targetOffset)
        
        // 记录合法偏移量
        lastValidContentOffset = targetOffset
        
        let offsetX = incomingOffset.x
        let offsetY = incomingOffset.y
        
        var slidingDirection: WYSlidingDirection = internalSliderDirection
        
        // 仅在全方向模式下处理
        if contentSlidingDirection == .omnidirectional {
            
            let centerX = wy_width
            let centerY = wy_height
            
            // 相对中心点的偏移
            let deltaX = offsetX - centerX
            let deltaY = offsetY - centerY
            
            // 还没锁定方向时判断一次往哪边滑：依据手指位移而不是偏移量变化，因为被钳制时偏移量全程不动，靠它判不出方向；手指往上/往左滑对应offset增大，所以符号要取反
            if isDirectionLocked == false {
                
                let panTranslation = panGestureRecognizer.translation(in: self)
                var translationX = -panTranslation.x
                var translationY = -panTranslation.y
                if isInstantCrossAxisEntry {
                    // 轻扫直切期间没有手势位移，按直切偏移方向判轴定向
                    translationX = deltaX
                    translationY = deltaY
                }else if (isTracking == false) && (isDecelerating == false) {
                    // 定时器轮播、代码切页这类没有手指的滚动，手势位移永远是0锁不上轴，而锁轴之前两轴都被钳制不动，动画第一帧就被掐死了；这种情况退回来按偏移量的变化判方向(和直切同理)
                    // 用户手指拖动不受影响：手指一动就能锁上轴，被钳制住的零头位移接近0不会误锁；顺带修掉手势结束后残留的旧位移被代码切页误用的时好时坏问题
                    translationX = deltaX
                    translationY = deltaY
                }
                // 判断轴之前先要求手指移动超过10pt，然后按哪个分量大定轴(不要求大多少)：如果要求"必须明显偏向一边"，接近斜着滑的同轴手势就永远判不出方向、全程拖不动；10pt以内两边都不放的手感跟两个轴都只有一页时一致，斜着抖动的部分被这10pt吸收掉
                let lockThreshold: CGFloat = 10.0
                if (abs(translationX) > lockThreshold) || (abs(translationY) > lockThreshold) {
                    if abs(translationX) >= abs(translationY) {
                        // 横向
                        if translationX > 0 {
                            slidingDirection = .left
                        } else {
                            slidingDirection = .right
                        }
                    }else {
                        // 纵向
                        if translationY > 0 {
                            slidingDirection = .up
                        } else {
                            slidingDirection = .down
                        }
                    }
                    // 一旦判断完成，立即锁定并记录本次拖拽方向，用于边界拦截后 internalSliderDirection 未更新时仍能保持方向
                    isDirectionLocked = true
                    dragLockedDirection = slidingDirection
                    // slide/fade/zoom样式下判出想切轴时进入跟手模式：slide像普通翻页一样跟手滑；fade/zoom按拖动距离控制渐变/缩放；松手时拖过半页或甩得够快算切换成功，否则弹回原轴；instant保持原来的原地直切+轻扫切换，不进这个模式
                    // 展示轴用置顶View真相推导(不信internalSliderDirection，上次回弹残留的目标轴方向会把首次跨轴判反)
                    if (crossAxisSwitchStyle != .instant) && (axisIsHorizontal(of: .unknown) != ((slidingDirection == .left) || (slidingDirection == .right))) {
                        beginInteractiveCrossAxisDrag(direction: slidingDirection)
                    }
                }
            } else {
                // 已锁定轴时，按 contentOffset 的物理偏移符号(deltaX/deltaY 的正负)判断轴内方向，避免 dragLockedDirection 与实际偏移方向不一致时 setter 把 reserveView 摆到错误一侧而闪现(如最后一页先右滑锁 .right、再左滑时 deltaX 已>0 却仍按 .right 放行，导致 setter 把 reserveView 摆到右侧闪现)；只有偏移为0(边界拦截后回中心)才沿用 dragLockedDirection 保持方向让 canScroll 持续拦截
                if dragLockedDirection == .left || dragLockedDirection == .right {
                    if deltaX > 0 {
                        slidingDirection = .left
                    } else if deltaX < 0 {
                        slidingDirection = .right
                    } else {
                        slidingDirection = dragLockedDirection
                    }
                } else {
                    if deltaY > 0 {
                        slidingDirection = .up
                    } else if deltaY < 0 {
                        slidingDirection = .down
                    } else {
                        slidingDirection = dragLockedDirection
                    }
                }
            }
            
            // 锁死另一方向（防止出现多方向同时滑动的问题）
            if isDirectionLocked {
                if slidingDirection == .left || slidingDirection == .right {
                    // 锁死 Y
                    if offsetY != centerY {
                        contentOffset.y = centerY
                    }
                    
                } else if slidingDirection == .up || slidingDirection == .down {
                    // 锁死 X
                    if offsetX != centerX {
                        contentOffset.x = centerX
                    }
                }
            }
        }else {
            if (offsetX != 0) && (contentSlidingDirection != .topOrBottom) {
                if offsetX > wy_width {
                    slidingDirection = .left
                }else if offsetX < wy_width {
                    slidingDirection = .right
                }
            }
            
            if (offsetY != 0) && (contentSlidingDirection != .leftOrRight) {
                if offsetY > wy_height {
                    slidingDirection = .up
                }else if offsetY < wy_height {
                    slidingDirection = .down
                }
            }
        }
        
        return slidingDirection
    }
    
    /// 轴向判定：方向明确按方向判，未知按置顶ContentView所属轴判，判不出按优先方向兜底
    func axisIsHorizontal(of direction: WYSlidingDirection) -> Bool {
        
        if (direction == .left) || (direction == .right) {
            return true
        }
        if (direction == .up) || (direction == .down) {
            return false
        }
        
        if let currentContentView = upperContentView {
            if currentContentView == horizontalViews?.first {
                return true
            }
            if currentContentView == verticalViews?.first {
                return false
            }
        }
        return prioritySlidingDirection != .topOrBottom
    }
    
    /// 所有代码修正偏移量的统一入口：靠"正在修正"标记拦住重入，防止两处修正互相触发、无限递归把栈撑爆
    func correctContentOffset(_ target: CGPoint) {
        
        guard (isCorrectingContentOffset == false) && (target != contentOffset) else {
            return
        }
        
        isCorrectingContentOffset = true
        contentOffset = target
        isCorrectingContentOffset = false
    }
    
    /// 判断该方向这次还能不能继续滑：普通拖动想切轴的直接拦住、冷却期内的拦住、滑动开关关了拦住、关闭无限轮播时边界页往循环方向拦住(边界拦截的同时顺手把偏移量修正回中心页)
    func canScroll(_ slidingDirection: WYSlidingDirection) -> Bool {

        guard slidingDirection != .unknown else { return false }

        if (contentSlidingDirection == .omnidirectional) && isDirectionLocked {
            // 交互式跨轴拖动期间一律放行(拖动切轴是组件识别出的手势，不受目标轴滑动开关的限制；也避免方向翻转后展示轴推导变化误拦)
            if isInteractiveCrossAxisDrag { return true }
            let slidingAxisIsHorizontal = (slidingDirection == .left) || (slidingDirection == .right)
            // 判断当前展示的是哪个轴：方向还不知道时按最顶上的View判断(优先方向只是刚挂载那会儿的展示轴，拿它判断会把"已经切到垂直轴后的垂直滑动"错当成跨轴滑动而拦死)
            let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)
            if slidingAxisIsHorizontal != displayedAxisIsHorizontal {
                // 普通拖动想切轴时一律拦住不放大(拖不动也不触发任何回调)：否则拖动中就会把另一轴的View顶上来提前换页；但轻扫直切和代码调next/last/switchContent切另一轴要放行，因为那是业务明确要求的，拦了会导致动画放完了却提交失败、卡在一个没加载内容的页面上
                return isInstantCrossAxisEntry || isProgrammaticAnimatedScroll || isInteractiveCrossAxisDrag
            }
        }
        
        // 冷却期内连回调也不发：既然钳制已经让这次拖动翻不了页，就不该再发willSwitch让业务白忙一场预加载；代码切页不受此限
        let slidingAxisIsHorizontal = (slidingDirection == .left) || (slidingDirection == .right)
        if (axisIsHorizontal(of: .unknown) == slidingAxisIsHorizontal) && (isProgrammaticAnimatedScroll == false) && (isInstantCrossAxisEntry == false) && isSameAxisGestureCoolingDown(isHorizontal: slidingAxisIsHorizontal) {
            return false
        }

        // 滑动开关只管用户手指：代码切页(nextContent/lastContent/switchContent)和轮播不受它限制，拦了会把这些切换直接弄失败
        if ((slidingDirection == .left) || (slidingDirection == .right)) && (horizontalSliderEnabled == false) && (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
            return false
        }
        if ((slidingDirection == .up) || (slidingDirection == .down)) && (verticalSliderEnabled == false) && (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
            return false
        }
        
        if (slidingDirection == .left) || (slidingDirection == .right) {
            
            guard contentSlidingDirection != .topOrBottom else { return false }
            
            // 边界判断只看 currentHorizontalIndex：canScroll 在 setter 之前执行，若依赖 reserveHorizontalIndex(上一次的值)，先反向滑使其变化后边界拦截会失效、导致 reserveView 闪现
            let isFirstPage = (currentHorizontalIndex == 0)
            
            let isLastPage = (currentHorizontalIndex == (numberOfHorizontalContent - 1))
            
            // 关闭无限轮播时，边界页往循环方向不允许切换
            if (isFirstPage && (slidingDirection == .right)) || (isLastPage && (slidingDirection == .left)) {
                if (horizontalUnlimitedCarousel == false) {
                    let targetOffset: CGPoint = CGPoint(x: wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0))
                    if (!CGPointEqualToPoint(contentOffset, targetOffset)) {
                        // 经统一入口修正(防写入互递归)
                        correctContentOffset(targetOffset)
                    }
                    return false
                }
            }
            
        }else {
            
            guard contentSlidingDirection != .leftOrRight else { return false }
            
            // 边界判断只看 currentVerticalIndex：canScroll 在 setter 之前执行，若依赖 reserveVerticalIndex(上一次的值)，先反向滑使其变化后边界拦截会失效、导致 reserveView 闪现
            let isFirstPage = (currentVerticalIndex == 0)
            
            let isLastPage = (currentVerticalIndex == (numberOfVerticalContent - 1))
            
            // 关闭无限轮播时，边界页往循环方向不允许切换
            if (isFirstPage && (slidingDirection == .down)) || (isLastPage && (slidingDirection == .up)) {
                if (verticalUnlimitedCarousel == false) {
                    let targetOffset: CGPoint = CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: wy_height)
                    if (!CGPointEqualToPoint(contentOffset, targetOffset)) {
                        // 经统一入口修正(防写入互递归)
                        correctContentOffset(targetOffset)
                    }
                    return false
                }
            }
        }
        return true
    }
}
