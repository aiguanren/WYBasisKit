//
//  WYContentScrollView+Views.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：内容视图存储与布局(挂载/重挂保序/置顶/尺寸偏移检查)
extension WYContentScrollView {

    /// 检查各ContentView的superView
    func contentViewInitializationCheck(_ contentViews: [UIView]) {

        contentViews.forEach { $0.removeFromSuperview() }

        // 统一清理水平与垂直两个方向的 view，避免残留 view 遮挡新方向内容
        horizontalViews?.forEach { $0.removeFromSuperview() }
        horizontalViews = nil
        verticalViews?.forEach { $0.removeFromSuperview() }
        verticalViews = nil
    }

    /// 解析重挂载时应采用的View顺序：传入View组与组件现有View组完全一致(身份级、不看顺序)时保留组件内部的当前/预备顺序(组件每次翻页成功都会交换两View位置，调用方自行保管的数组是滞后的，按其顺序重挂会把旧内容View置顶)；传入新View组时尊重调用方顺序
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

            // 首次展示(含切换方向重挂载)且开着自动轮播时自动开表：让automaticCarousel默认true的语义名副其实——不自动开表的话"自动轮播开着"却一直不轮播，属性与实际状态割裂；不需要轮播的业务把automaticCarousel设为false即可拦在此处；业务stopTimer过硬停后此自动开表也让位(timerStoppedByBusiness)，只有再次显式startTimer才恢复；此后启停交由startTimer/stopTimer与动态启停管理(拖动暂停松手续播、展示轴不可翻自动停恢复)
            if (automaticCarousel != false) && (unlimitedCarousel != false) && (timerStoppedByBusiness == false) {
                startTimer()
            }
        }
    }

    /// 按方向布局内容视图：currentView 固定位于中心页，reserveView 位于其滑动方向一侧(全向模式下水平/垂直各自的中心重叠，靠 bringContentToFront 决定顶层)
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
        // 初始化时同步lastValid：不同步的话紧随其后的handleScrollDirectionLock会用旧方向的合法偏移把新布局的contentOffset锁回去(表现为闪一下又跳回)
        lastValidContentOffset = contentOffset
    }

    /// 判断设置展示在顶层的对应方向的View，若contentViews为空则内部自行判断
    func bringContentToFront(_ contentViews: [UIView]? = nil) {
        
        // 直接将传入的对应的ContentView移到WYContentScrollView的最顶层，且因为currentView和reserveView的frame有可能是一样的，所以需要最后执行bringSubviewToFront(currentView)
        if (contentViews?.count == 2), let currentView = contentViews?.first, let reserveView = contentViews?.last  {
            if upperContentView != currentView {
                bringSubviewToFront(reserveView)
                bringSubviewToFront(currentView)
                upperContentView = currentView
            }
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
                    // 水平轴正在置顶展示：停留不劫持——数量变化不应移动用户页面(数量一路减到1都停留，唯独归零被甩去另一轴是不连续的怪行为)；归零只是该轴不可翻/轮播自动停，跨轴切到有内容的轴随时可行，不会困住用户
                    return
                }
                if upperContentView == currentVerticalView {
                    // 垂直轴正在置顶展示：停留不劫持，语义同上(含数量归零)
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

    /// 按滑动方向检查并设置 contentSize 与 contentOffset：currentView 固定停在各方向的中心页；设置 contentOffset 前会先同步 lastValidContentOffset 为同值，避免紧随其触发的 handleScrollDirectionLock 用旧方向的合法偏移把 contentOffset 锁回
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

    /// 当前正在水平方向显示的Views(用户传入的View)
    var horizontalViews: [UIView]? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.horizontalViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.horizontalViews) as? [UIView]
        }
    }

    /// 当前正在垂直方向显示的Views(用户传入的View)
    var verticalViews: [UIView]? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.verticalViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.verticalViews) as? [UIView]
        }
    }

    /// 当前显示在最上层的ContentView
    var upperContentView: UIView? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.upperContentView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.upperContentView) as? UIView }
    }
}
