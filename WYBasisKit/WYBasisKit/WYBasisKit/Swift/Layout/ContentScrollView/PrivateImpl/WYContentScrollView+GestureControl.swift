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

    /// 当前轮播应推进的方向：单轴模式为模式本身(该轴数量不足2时不轮播，返回nil)，全向模式跟随当前置顶的ContentView所属轴(跨轴直切切换展示轴后，轮播轴随之切换)；展示轴数量不足2同样返回nil——轮播绝不翻非展示轴，否则会把不可见页的回调与下标变动强加给业务
    var carouselDirection: WYContentSlidingDirection? {

        switch contentSlidingDirection {
        case .leftOrRight:
            return (numberOfHorizontalContent >= 2) ? .leftOrRight : nil
        case .topOrBottom:
            return (numberOfVerticalContent >= 2) ? .topOrBottom : nil
        case .omnidirectional:
            guard let currentContentView = upperContentView else { return nil }
            if currentContentView == horizontalViews?.first {
                return (numberOfHorizontalContent >= 2) ? .leftOrRight : nil
            }
            return (numberOfVerticalContent >= 2) ? .topOrBottom : nil
        }
    }

    /// 暂停定时器
    func pauseTimer() {
        if timer != nil {
        }
        timer?.invalidate()
        timer = nil
    }

    /// 轮播计时器随展示轴/数量/开关动态启停：当前展示轴翻不了页(数量不足2/关自动轮播/关无限轮播)时停止并清除计时器(避免定时器每3秒空转一次)，恢复可翻时若此前开启过轮播则自动重启；调用点：checkCarouselStatus(方向/数量/开关变化都会经过)与跨轴直切收尾(展示轴翻转不经方向与数量变化)
    func refreshCarouselTimer() {

        guard (automaticCarousel != false) && (unlimitedCarousel != false) && (carouselDirection != nil) else {
            // 用暂停而非停止：条件恢复(数量改回/开关重开/展示轴翻回)后自动续播，重启标记不能丢
            pauseTimer()
            return
        }

        // 计时器不在跑且开启过轮播才重启：从未startTimer或业务已关轮播则不复活(stopTimer是软停，真正关闭用automaticCarousel=false，与松手重启语义一致)；用户拖动/惯性中不重启，由松手回调负责
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

            // 此模式下只要有一个方向存在内容且允许滑动就放开全局滚动(isScrollEnabled是全局的)，具体方向与单页约束通过handleScrollDirectionLock与canScroll按展示轴动态实现
            isScrollEnabled = horizontalExists || verticalExists
            break
        }

        // 方向/数量/开关任何变化后动态启停轮播计时器(展示轴翻不了页时清除防空转，恢复可翻时自动重启)
        refreshCarouselTimer()
    }

    /// 处理方向锁定并返回当前滑动方向：锁死不可滑动的方向(回退到 lastValidContentOffset)、全向模式下判定并锁定拖拽主方向、边界处钳制 contentOffset 防止越过中心露出背景
    func handleScrollDirectionLock() -> WYSlidingDirection {

        // 方向推导必须读钳制前的原始偏移：程序化动画的位移会被下方轴能力钳制抹回中心，读钳制后偏移则delta恒0判不了轴(轮播停摆)
        let incomingOffset = contentOffset

        // 横向是否允许滑动(非全向：单页/无内容不可滑)
        var horizontalCanScroll = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false

        // 纵向是否允许滑动(非全向：单页/无内容不可滑)
        var verticalCanScroll = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false

        if contentSlidingDirection == .omnidirectional {
            
            // 展示轴判定(方向未知时按置顶View判)：优先方向只是挂载瞬间的展示轴代理，按它判会把垂直展示后的垂直滑动/翻页误判成跨轴而拦死
            let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)
            horizontalCanScroll = false
            verticalCanScroll = false
            if isDirectionLocked {
                let lockedAxisIsHorizontal = (dragLockedDirection == .left) || (dragLockedDirection == .right)
                horizontalCanScroll = lockedAxisIsHorizontal && displayedAxisIsHorizontal && (numberOfHorizontalContent > 1) && horizontalSliderEnabled
                verticalCanScroll = (lockedAxisIsHorizontal == false) && (displayedAxisIsHorizontal == false) && (numberOfVerticalContent > 1) && verticalSliderEnabled
            }
        }

        if isInstantCrossAxisEntry || isProgrammaticAnimatedScroll {
            // 轻扫直切/程序化动画滚动期间：两轴能力临时放开(单轴约束由下方方向锁定逻辑保证)，避免偏移被钳回中心(程序化动画被钳会欠位移导致终点不够整页、切换失败弹回)
            horizontalCanScroll = true
            verticalCanScroll = true
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
        
            // 防抖
            let threshold: CGFloat = 2.0

            // 未锁定时，根据主方向判断一次(判轴依据手指位移而非contentOffset的delta：零行程钳制下delta恒为0，offset判不出跨轴意图；手指上/左滑=offset增=left/up，符号需取反)
            if isDirectionLocked == false {

                let panTranslation = panGestureRecognizer.translation(in: self)
                var translationX = -panTranslation.x
                var translationY = -panTranslation.y
                if isInstantCrossAxisEntry {
                    // 轻扫直切期间没有手势位移，按直切偏移方向判轴定向
                    translationX = deltaX
                    translationY = deltaY
                }else if (isTracking == false) && (isDecelerating == false) {
                    // 纯程序化滚动(定时器轮播/nextContent/lastContent/switchContent)没有手指：pan位移恒为0锁不上轴，判轴前两轴全钳制会把程序化动画掐死在第一帧(表现为切全向后轮播停止；缠斗期间staging仍发willSwitch、失败复位又把页面无动画弹回原页)；此场景回退按偏移位移判轴(与直切同源)。用户路径不受影响：同轴拖动靠手指位移先锁再放行，被钳制的零行程delta≈0不会误锁；同时消除手势结束后残留的陈旧位移被程序化滚动误用导致的时好时坏
                    translationX = deltaX
                    translationY = deltaY
                }
                // 判轴防抖取10pt后按主分量定轴(不要求优势倍数)：优势倍数要求会让接近斜向的同轴手势永远锁不上轴、全程被钳制(表现为同轴前几次滑动弹跳/无法切换)；10pt内两轴全钳制的手感与两轴均单页一致，斜向抖动被吸收在10pt内
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

    /// 轴向判定：方向明确时按方向判水平/垂直；方向未知(挂载后未滑动、程序切换动画重置、重新展示重置)时按置顶ContentView所属轴判(置顶View是展示轴的事实源，优先方向只是挂载瞬间的代理——按优先方向判会把垂直展示后的垂直翻页/进入/轻扫全部误判成跨轴)；置顶View判不出时按优先方向兜底
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

    /// 判断当前方向是否可以继续滚动：处于边界页(第一/最后一页)且关闭无限轮播时，往循环方向(无内容方向)的滑动会被拦截并把 contentOffset 拉回中心页
    /// 程序化修正contentOffset的统一入口(判轴钳制/边界拦截回拉)：赋值会同步重入didScroll，重入链路可能再次发起修正，两个修正目标不一致时互拉成无限互递归栈溢出(实测：关无限轮播+全向+末页回滑触发)——重入闸让重入的修正直接跳过，单层收敛
    func correctContentOffset(_ target: CGPoint) {

        guard (isCorrectingContentOffset == false) && (target != contentOffset) else {
            return
        }

        isCorrectingContentOffset = true
        contentOffset = target
        isCorrectingContentOffset = false
    }

    func canScroll(_ slidingDirection: WYSlidingDirection) -> Bool {

        guard slidingDirection != .unknown else { return false }

        if (contentSlidingDirection == .omnidirectional) && isDirectionLocked {
            let slidingAxisIsHorizontal = (slidingDirection == .left) || (slidingDirection == .right)
            // 展示轴判定(方向未知时按置顶View判)：优先方向只是挂载瞬间的展示轴代理，按它判会把垂直展示后的垂直滑动/翻页误判成跨轴而拦死
            let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)
            if slidingAxisIsHorizontal != displayedAxisIsHorizontal {
                // 跨轴意图的普通拖动一律拦截(零行程且不触发setter，避免拖动中把另一轴View置顶提前换页，任意数量组合与两轴均单页的手感完全一致)；轻扫直切与程序化跨轴切换(nextContent/lastContent/switchContent指定非展示轴)放行——后者是显式指令，被拦会导致动画锁轴后setter不执行、目标轴无willSwitch不预加载、动画到位却提交失败卡在未加载页
                return isInstantCrossAxisEntry || isProgrammaticAnimatedScroll
            }
        }

        if ((slidingDirection == .left) || (slidingDirection == .right)) && (horizontalSliderEnabled == false) {
            return false
        }
        if ((slidingDirection == .up) || (slidingDirection == .down)) && (verticalSliderEnabled == false) {
            return false
        }

        if (slidingDirection == .left) || (slidingDirection == .right) {

            guard contentSlidingDirection != .topOrBottom else { return false }

            // 边界判断只看 currentHorizontalIndex：canScroll 在 setter 之前执行，若依赖 reserveHorizontalIndex(上一次的值)，先反向滑使其变化后边界拦截会失效、导致 reserveView 闪现
            let isFirstPage = (currentHorizontalIndex == 0)

            let isLastPage = (currentHorizontalIndex == (numberOfHorizontalContent - 1))

            // 关闭无限轮播时，边界页往循环方向不允许切换
            if (isFirstPage && (slidingDirection == .right)) || (isLastPage && (slidingDirection == .left)) {
                if (unlimitedCarousel == false) {
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
                if (unlimitedCarousel == false) {
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
