//
//  WYContentScrollView+Layout.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：内容视图布局与挂载(重挂保序/置顶层级/尺寸偏移检查)
extension WYContentScrollView {
    
    /// 把没在展示的那个轴藏起来：全向模式下两个轴的当前页叠在同一个位置(布局就是这样，靠谁在上面决定看到谁)，当页面内容不满铺时(比如aspectFit的小图)，底下那个轴的内容会从四周露出来(表现为同时看到两个轴的内容)；把非展示轴整体设为隐藏就不会露了；挂载时和每次跨轴切换/回弹收尾时调用；单轴模式只有一轴的View，不需要处理
    func syncAxisViewsVisibility() {

        guard contentSlidingDirection == .omnidirectional else { return }

        let displayedIsHorizontal = axisIsHorizontal(of: .unknown)
        horizontalViews?.forEach { $0.isHidden = (displayedIsHorizontal == false) }
        verticalViews?.forEach { $0.isHidden = displayedIsHorizontal }
    }

    /// 挂载前清场：把传入的View连同两轴旧View全部移出父视图，防止残留的旧View挡住新挂上来的内容
    func contentViewInitializationCheck(_ contentViews: [UIView]) {
        
        contentViews.forEach { $0.removeFromSuperview() }
        
        // 统一清理水平与垂直两个方向的 view，避免残留 view 遮挡新方向内容
        horizontalViews?.forEach { $0.removeFromSuperview() }
        horizontalViews = nil
        verticalViews?.forEach { $0.removeFromSuperview() }
        verticalViews = nil
    }
    
    /// 重挂同一组View时保留组件内部当前/预备顺序，传入新View组时尊重调用方顺序
    func resolveDisplayOrder(_ incomingViews: [UIView], existingViews: [UIView]?) -> [UIView] {
        
        guard let existingViews = existingViews,
              (existingViews.count == 2) && (incomingViews.count == 2),
              Set(incomingViews.map(ObjectIdentifier.init)) == Set(existingViews.map(ObjectIdentifier.init)) else {
            return incomingViews
        }
        
        return existingViews
    }
    
    /// 内部初始化设置
    func internalInitializationSettings() {
        
        super.delegate = self
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickContent))
        addGestureRecognizer(gestureRecognizer)
        
        // 强制关闭 bounces，边界行为统一由 canScroll/handleScrollDirectionLock 控制，条件开启 bounces 需联动 contentSize/alwaysBounce/isPagingEnabled等，判断点过多会引入一系列其他问题
        bounces = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
    }
    
    /// 内部设置添加ContentView
    func internalSettingsContentView(isReload: Bool) {
        
        // 布局前记录内容View是否尚未挂载(以此判断本次是否为首次展示/切换方向后的重新展示)
        let isInitialDisplay: Bool = (horizontalViews?.first?.superview == nil) && (verticalViews?.first?.superview == nil)
        
        if (contentSlidingDirection == .omnidirectional) {
            if prioritySlidingDirection == .topOrBottom {
                layoutContentSubViews(.leftOrRight, isReload: isReload)
                layoutContentSubViews(.topOrBottom, isReload: isReload)
            }else {
                layoutContentSubViews(.topOrBottom, isReload: isReload)
                layoutContentSubViews(.leftOrRight, isReload: isReload)
            }
        }else {
            layoutContentSubViews(contentSlidingDirection, isReload: isReload)
        }
        
        // 本次确实新挂载了内容View才触发初始didSwitch(只回调当前展示方向，另一方向等首次滑动时补发)
        let didDisplay: Bool = (horizontalViews?.first?.superview != nil) || (verticalViews?.first?.superview != nil)
        if isInitialDisplay && didDisplay {
            
            
            internalSliderDirection = .unknown
            
            // 本次展示(前置)的方向：左右模式与全向(优先非上下)为水平轴，上下模式与全向优先上下为垂直轴
            let isHorizontalFront: Bool = (initialDisplayDirection == .left) || (initialDisplayDirection == .right)
            // 非展示轴重置标记，等首次滑动时在scrollViewDidScroll补发
            if isHorizontalFront {
                hasInitialCallbackVertical = false
            }else {
                hasInitialCallbackHorizontal = false
            }
            // 展示轴只有在尚未回调过时才发初始didSwitch(如左右切全向且优先左右，水平轴一直是展示方向则不再重复回调)
            if isHorizontalFront && !hasInitialCallbackHorizontal {
                hasInitialCallbackHorizontal = true
                switchContentCallback(isDidSwitch: true, direction: initialDisplayDirection)
            }else if !isHorizontalFront && !hasInitialCallbackVertical {
                hasInitialCallbackVertical = true
                switchContentCallback(isDidSwitch: true, direction: initialDisplayDirection)
            }
            
            // 第一次显示(包括切换方向重新挂载)时如果开着自动轮播就自动开始轮播：不然"自动轮播"开着却一直不播，名不副实；不想要轮播的业务把automaticCarousel设为false就能挡在这里；业务主动调过stopTimer的话这里不再自动开(尊重业务的停止)，要再显式调startTimer才恢复；之后的启停交给startTimer/stopTimer管理(拖动时暂停、松手继续；展示轴翻不了页时自动停、能翻了自动恢复)
            syncAxisViewsVisibility()

            if (automaticCarousel != false) && (timerStoppedByBusiness == false) {
                // 展示轴的无限翻页前提由startTimer自身的门判定(无限开关已按轴拆分，读展示轴的开关)
                startTimer()
            }
        }
    }
    
    /// 按方向布局内容视图：currentView固定中心页，reserveView位于其滑动方向一侧
    func layoutContentSubViews(_ direction: WYContentSlidingDirection, isReload: Bool) {
        
        if direction == .leftOrRight {
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            // 自身尺寸未变化且非强制重载时跳过布局，避免 layoutSubviews 频繁触发造成浪费
            guard (!CGSizeEqualToSize(frame.size, currentHorizontalView.frame.size)) || (isReload == true) else {
                return
            }
            
            var currentHorizontalViewOffset: CGPoint = .zero
            var reserveHorizontalViewOffset: CGPoint = .zero
            if (contentSlidingDirection == .omnidirectional) {
                currentHorizontalViewOffset = CGPoint(x: wy_width, y: wy_height)
                reserveHorizontalViewOffset = CGPoint(x: 2 * wy_width, y: wy_height)
            }else {
                currentHorizontalViewOffset = CGPoint(x: wy_width, y: 0)
                reserveHorizontalViewOffset = CGPoint(x: 2 * wy_width, y: 0)
            }
            
            let currentHorizontalViewFrame: CGRect = CGRect(x: currentHorizontalViewOffset.x, y: currentHorizontalViewOffset.y, width: wy_width, height: wy_height)
            
            let reserveHorizontalViewFrame: CGRect = CGRect(x: reserveHorizontalViewOffset.x, y: reserveHorizontalViewOffset.y, width: wy_width, height: wy_height)
            
            if !CGRectEqualToRect(currentHorizontalView.frame, currentHorizontalViewFrame) {
                currentHorizontalView.frame = currentHorizontalViewFrame
            }
            
            if !CGRectEqualToRect(reserveHorizontalView.frame, reserveHorizontalViewFrame) {
                reserveHorizontalView.frame = reserveHorizontalViewFrame
            }
            
            if (currentHorizontalView.superview == nil) && (reserveHorizontalView.superview == nil) {
                upperContentView = currentHorizontalView
                addSubview(reserveHorizontalView)
                addSubview(currentHorizontalView)
            }
        }
        
        if direction == .topOrBottom {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            guard (!CGSizeEqualToSize(frame.size, currentVerticalView.frame.size)) || (isReload == true) else {
                return
            }
            
            var currentVerticalViewOffset: CGPoint = .zero
            var reserveVerticalViewOffset: CGPoint = .zero
            if (contentSlidingDirection == .omnidirectional) {
                currentVerticalViewOffset = CGPoint(x: wy_width, y: wy_height)
                reserveVerticalViewOffset = CGPoint(x: wy_width, y: 2 * wy_height)
            }else {
                currentVerticalViewOffset = CGPoint(x: 0, y: wy_height)
                reserveVerticalViewOffset = CGPoint(x: 0, y: 2 * wy_height)
            }
            
            let currentVerticalViewFrame: CGRect = CGRect(x: currentVerticalViewOffset.x, y: currentVerticalViewOffset.y, width: wy_width, height: wy_height)
            
            let reserveVerticalViewFrame: CGRect = CGRect(x: reserveVerticalViewOffset.x, y: reserveVerticalViewOffset.y, width: wy_width, height: wy_height)
            
            if !CGRectEqualToRect(currentVerticalView.frame, currentVerticalViewFrame) {
                currentVerticalView.frame = currentVerticalViewFrame
            }
            
            if !CGRectEqualToRect(reserveVerticalView.frame, reserveVerticalViewFrame) {
                reserveVerticalView.frame = reserveVerticalViewFrame
            }
            
            if (currentVerticalView.superview == nil) && (reserveVerticalView.superview == nil) {
                upperContentView = currentVerticalView
                addSubview(reserveVerticalView)
                addSubview(currentVerticalView)
            }
        }
        // 初始化时同步lastValid：否则紧随其后的handleScrollDirectionLock会用旧方向的合法偏移把新布局的contentOffset锁回去
        lastValidContentOffset = contentOffset
    }
    
    /// 把该方向的View摆到最上层：传了contentViews就直接置顶它俩(第一个当当前页)，没传则按各方向数量/滑动方向/优先方向自行判断该置顶哪个轴
    func bringContentToFront(_ contentViews: [UIView]? = nil) {
        
        // 直接将传入的对应的ContentView移到WYContentScrollView的最顶层，且因为currentView和reserveView的frame有可能是一样的，所以需要最后执行bringSubviewToFront(currentView)
        if (contentViews?.count == 2), let currentView = contentViews?.first, let reserveView = contentViews?.last  {
            // 每次都老老实实执行置顶操作，不要因为"记录里说已经置顶过了"就跳过：有些地方直接调了系统的置顶方法没更新记录，一旦哪次切换被打断，实际的叠放顺序就和记录对不上了；按记录跳过会让错误状态永远留在那里。重复置顶没有副作用也没有开销，以实际的叠放顺序为准最可靠
            bringSubviewToFront(reserveView)
            bringSubviewToFront(currentView)
            upperContentView = currentView
            return
        }else {
            // 根据各方向的显示数量以及支持的滑动方向和全向模式时优先显示的方向来设置显示优先级
            switch contentSlidingDirection {
            case .leftOrRight:
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                if upperContentView != currentHorizontalView {
                    bringSubviewToFront(reserveHorizontalView)
                    bringSubviewToFront(currentHorizontalView)
                    upperContentView = currentHorizontalView
                }
                return
            case .topOrBottom:
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                if upperContentView != currentVerticalView {
                    bringSubviewToFront(reserveVerticalView)
                    bringSubviewToFront(currentVerticalView)
                    upperContentView = currentVerticalView
                }
                return
            case .omnidirectional:
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                if upperContentView == currentHorizontalView {
                    // 水平轴还在展示时数量怎么变都停在原地：改数量不应该把用户正看的页面切走(数量一路减到1都停着，偏偏减到0就被甩到另一个轴，行为不连贯)；归零只是这个轴不能再翻了、轮播自动停，想切轴随时可以，不会困住用户
                    return
                }
                if upperContentView == currentVerticalView {
                    // 垂直轴正在置顶展示：数量怎么变都停在原地不劫持(改数量不该把用户正看的页面切走；归零只是这个轴不能再翻了、轮播自动停，想切轴随时可以，不会困住用户)
                    return
                }
                
                if ((numberOfHorizontalContent > 1) && (numberOfVerticalContent > 1)) || (numberOfHorizontalContent == numberOfVerticalContent) {
                    
                    // 都大于1或者都等于1，则依据优先显示方向来处理
                    if (prioritySlidingDirection == .leftOrRight) && (upperContentView != currentHorizontalView) {
                        bringSubviewToFront(reserveHorizontalView)
                        bringSubviewToFront(currentHorizontalView)
                        upperContentView = currentHorizontalView
                        return
                    }
                    if (prioritySlidingDirection == .topOrBottom) && (upperContentView != currentVerticalView) {
                        bringSubviewToFront(reserveVerticalView)
                        bringSubviewToFront(currentVerticalView)
                        upperContentView = currentVerticalView
                        return
                    }
                }else {
                    // 先按数量决定该显示哪个方向，再判断是否需要切换，每个方向处理完直接 return，杜绝 fall through 到另一方向
                    if numberOfHorizontalContent > numberOfVerticalContent {
                        if upperContentView != currentHorizontalView {
                            bringSubviewToFront(reserveHorizontalView)
                            bringSubviewToFront(currentHorizontalView)
                            upperContentView = currentHorizontalView
                        }
                        return
                    } else {
                        if upperContentView != currentVerticalView {
                            bringSubviewToFront(reserveVerticalView)
                            bringSubviewToFront(currentVerticalView)
                            upperContentView = currentVerticalView
                        }
                        return
                    }
                }
            }
        }
    }
    
    /// 按方向检查并设置contentSize与contentOffset：currentView固定停在各方向的中心页
    func checkContentSizeAndContentOffset() {
        switch contentSlidingDirection {
        case .leftOrRight:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: wy_width, y: 0)
                contentOffset = CGPoint(x: wy_width, y: 0)
            }
            break
        case .topOrBottom:
            let targetSize: CGSize = CGSize(width: wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: 0, y: wy_height)
                contentOffset = CGPoint(x: 0, y: wy_height)
            }
            break
        case .omnidirectional:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
                contentOffset = CGPoint(x: wy_width, y: wy_height)
            }
            break
        }
    }
}
