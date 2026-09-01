//
//  WYContentScrollView+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有属性集中管理：关联对象存储的状态属性(滑动方向/视图数组/置顶视图/计时器/锁与标记)与派生计算属性(初始展示方向/轮播方向)
extension WYContentScrollView {

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


    /// 当前滑动方向：setter内同步完成reserveView摆位、reserveIndex计算与willSwitch回调
    var internalSliderDirection: WYSlidingDirection {
        set(newValue) {
            
            // 跨轴判定必须用写入前的方向：先写入再读的话previous恒等于newValue(恒判同轴)
            let previousDirection: WYSlidingDirection = objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown

            objc_setAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if ((newValue == .up) || (newValue == .down) && (contentSlidingDirection != .leftOrRight)) {
                
                guard numberOfVerticalContent > 0 else { return }
                
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                
                // 滑动前根据滑动方向的偏移量设置预备显示View的frame(不能简单根据newValue来设置，否则手指不松开上下滑动时无法更新reserveVerticalView.frame，且必须放这里优先处理，否则往左右滑动后可能会出现空白页面)
                // 交互式呈现族拖动期间跳过本摆位：fade/zoom偏移全程钳在中心，下面的摆位分支恒走"另一侧"(y=0屏外)，会逐帧把staging摆在中心的进入页挪出屏；期间进入页的摆位归交互staging所有(slide不豁免：其偏移跟手，本摆位与staging摆位一致，正好承担逐帧跟手摆位的职责)
                if (isInteractiveCrossAxisDrag == false) || (crossAxisSwitchStyle == .slide) {
                    if contentOffset.y > wy_height {
                        reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                    }else {
                        reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                    }
                }
                
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex

                // 跨轴进入判定(方向未知时按置顶View判轴)：必须在下方bringContentToFront之前求值——置顶动作会把目标轴翻上来，之后才判的话.unknown兜底读到的就是刚翻转的目标轴自身，跨轴直切会被误判成"本轴已展示中"的同轴推进(reserve被+1污染+发幽灵will，轻扫直切必现)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)

                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentVerticalView, reserveVerticalView])
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && previousAxisIsHorizontal && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveVerticalIndex = currentVerticalIndex
                }else if newValue == .up {
                    reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                    if (reserveVerticalIndex == 0) && (verticalUnlimitedCarousel == false) {
                        reserveVerticalIndex = currentVerticalIndex
                    }
                }else {
                    reserveVerticalIndex = currentVerticalIndex - 1
                    if (reserveVerticalIndex < 0)  {
                        reserveVerticalIndex = (verticalUnlimitedCarousel == false) ? currentVerticalIndex : (numberOfVerticalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will；冻结期间不发——收尾的方向恢复赋值会走到这里，残留reserve(如无限数量的环绕值)与config比对失效会补出幽灵will(业务无谓重载预备页)，正常staging都在未冻结时发生
                let isPageIndexChanged = (reserveVerticalIndex != currentVerticalIndex)
                if (isFinalizingSwitch == false) && isPageIndexChanged && ((configVerticalReserveIndex != reserveVerticalIndex) || isCrossAxisEntry) {
                    switchContentCallback(isDidSwitch: false)
                }
            }

            if ((newValue == .left) || (newValue == .right) && (contentSlidingDirection != .topOrBottom)) {
                
                guard numberOfHorizontalContent > 0 else { return }
                
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                
                // 滑动前根据滑动方向的偏移量设置预备显示View的frame(不能简单根据newValue来设置，否则手指不松开左右滑动时无法更新reserveHorizontalView.frame，且必须放这里优先处理，否则往上下滑动后可能会出现空白页面)
                // 交互式呈现族拖动期间跳过本摆位(与垂直分支同源)：fade/zoom偏移全程钳在中心，下面的摆位分支恒走"另一侧"(x=0屏外)，会逐帧把staging摆在中心的进入页挪出屏；期间进入页的摆位归交互staging所有(slide不豁免：其偏移跟手，本摆位与staging摆位一致，正好承担逐帧跟手摆位的职责)
                if (isInteractiveCrossAxisDrag == false) || (crossAxisSwitchStyle == .slide) {
                    if contentOffset.x > wy_width {
                        reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                    }else {
                        reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                    }
                }
                
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex

                // 跨轴进入判定(方向未知时按置顶View判轴)：必须在下方bringContentToFront之前求值——置顶动作会把目标轴翻上来，之后才判的话.unknown兜底读到的就是刚翻转的目标轴自身，跨轴直切会被误判成"本轴已展示中"的同轴推进(reserve被+1污染+发幽灵will)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)

                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentHorizontalView, reserveHorizontalView])
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && (previousAxisIsHorizontal == false) && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveHorizontalIndex = currentHorizontalIndex
                }else if newValue == .left {
                    reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                    if (reserveHorizontalIndex == 0) && (horizontalUnlimitedCarousel == false) {
                        reserveHorizontalIndex = currentHorizontalIndex
                    }
                }else {
                    reserveHorizontalIndex = currentHorizontalIndex - 1
                    if (reserveHorizontalIndex < 0)  {
                        reserveHorizontalIndex = (horizontalUnlimitedCarousel == false) ? currentHorizontalIndex : (numberOfHorizontalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will；冻结期间不发——收尾的方向恢复赋值会走到这里，残留reserve(如无限数量的环绕值)与config比对失效会补出幽灵will(业务无谓重载预备页)，正常staging都在未冻结时发生
                let isPageIndexChanged = (reserveHorizontalIndex != currentHorizontalIndex)
                if (isFinalizingSwitch == false) && isPageIndexChanged && ((configHorizontalReserveIndex != reserveHorizontalIndex) || isCrossAxisEntry) {
                    switchContentCallback(isDidSwitch: false)
                }
            }
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown
        }
    }

    /// 计时器
    var timer: Timer? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.timer) as? Timer
        }
    }

    /// 判断手动拖拽后是否需要启动定时器
    var canRestartedTimer: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer) as? Bool ?? false
        }
    }

    /// 是否正处于交互式跨轴拖动中：松手按进度(≥半页)或速度(≥轻扫阈值)决定完成或回弹；instant不进此模式
    var isInteractiveCrossAxisDrag: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isInteractiveCrossAxisDrag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isInteractiveCrossAxisDrag) as? Bool ?? false
        }
    }

    /// 交互式跨轴拖动开始时的原展示轴是否为水平：期间展示轴判定与回弹恢复都以它为准
    var interactiveCrossOriginalAxisIsHorizontal: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.interactiveCrossOriginalAxisIsHorizontal, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.interactiveCrossOriginalAxisIsHorizontal) as? Bool ?? true
        }
    }

    /// 交互式跨轴拖动的目标方向(决定进入侧与进度轴向)
    var interactiveCrossDirection: WYSlidingDirection {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.interactiveCrossDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.interactiveCrossDirection) as? WYSlidingDirection ?? .unknown
        }
    }

    /// 程序化contentOffset修正的重入闸：防修正互拉递归栈溢出
    var isCorrectingContentOffset: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isCorrectingContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isCorrectingContentOffset) as? Bool ?? false
        }
    }

    /// 业务是否显式停止过计时器：置位后自动开表让位，仅再次startTimer才恢复
    var timerStoppedByBusiness: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.timerStoppedByBusiness, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.timerStoppedByBusiness) as? Bool ?? false
        }
    }

    /// 是否已锁定滑动方向（只在一次拖拽中生效，避免contentSlidingDirection == .omnidirectional时滑动后无法锁定方向的问题）
    var isDirectionLocked: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked) as? Bool ?? false
        }
    }

    /// 本次拖拽锁定的滑动方向(仅omnidirectional模式)：边界拦截期间靠它保持方向
    var dragLockedDirection: WYSlidingDirection {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection) as? WYSlidingDirection ?? .unknown }
    }

    /// 是否正处于轻扫跨轴直切中：期间两轴能力临时放开
    var isInstantCrossAxisEntry: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry) as? Bool ?? false }
    }

    /// 是否正处于切换收尾中：防止重入setter把刚落定的下标再次±1
    var isFinalizingSwitch: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch) as? Bool ?? false }
    }

    /// 是否正处于程序化动画滚动中：期间两轴能力临时放开防动画被钳制
    var isProgrammaticAnimatedScroll: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isProgrammaticAnimatedScroll, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isProgrammaticAnimatedScroll) as? Bool ?? false }
    }

    /// 上一次合法的偏移量：不可滑方向被锁死时 contentOffset 回退到此值
    var lastValidContentOffset: CGPoint {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset) as? CGPoint ?? .zero
        }
    }

    /// 本次拖拽是否已滑过一页宽度(松手时据此判断要不要执行 pauseScroll 切换)
    var canSwitchedPage: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canSwitchedPage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.canSwitchedPage) as? Bool ?? false
        }
    }

    /// 记录上一次为 reserveHorizontalView 配置的索引，避免重复设置
    var configHorizontalReserveIndex: Int? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.configHorizontalReserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.configHorizontalReserveIndex) as? Int }
    }

    /// 记录上一次为 reserveVerticalView 配置的索引，避免重复设置
    var configVerticalReserveIndex: Int? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.configVerticalReserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.configVerticalReserveIndex) as? Int }
    }

    /// 水平轴是否已触发过初始didSwitch(初始展示只回调展示方向，另一轴首次滑到时补发)
    var hasInitialCallbackHorizontal: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal) as? Bool ?? false }
    }

    /// 垂直轴是否已触发过初始didSwitch(初始展示只回调展示方向，另一轴首次滑到时补发)
    var hasInitialCallbackVertical: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackVertical, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackVertical) as? Bool ?? false }
    }

    /// 外部真实代理（弱引用避免循环引用）
    weak var internalDelegate: UIScrollViewDelegate? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.internalDelegate, WYWeakBox(newValue as AnyObject?), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.internalDelegate ) as? WYWeakBox)?.value as? UIScrollViewDelegate
        }
    }

    /// 当前轮播应推进的方向：单轴为模式本身，全向跟随置顶轴；数量不足2返回nil
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
    struct WYAssociatedKeys {
        static var timer: UInt8 = 0
        static var horizontalViews: UInt8 = 0
        static var verticalViews: UInt8 = 0
        static var internalSliderDirection: UInt8 = 0
        static var canRestartedTimer: UInt8 = 0
        static var timerStoppedByBusiness: UInt8 = 0
        static var isCorrectingContentOffset: UInt8 = 0
        static var isInteractiveCrossAxisDrag: UInt8 = 0
        static var interactiveCrossDirection: UInt8 = 0
        static var interactiveCrossOriginalAxisIsHorizontal: UInt8 = 0
        static var canSwitchedPage: UInt8 = 0
        static var configHorizontalReserveIndex: UInt8 = 0
        static var configVerticalReserveIndex: UInt8 = 0
        static var internalDelegate: UInt8 = 0
        static var isDirectionLocked: UInt8 = 0
        static var dragLockedDirection: UInt8 = 0
        static var lastValidContentOffset: UInt8 = 0
        static var upperContentView: UInt8 = 0
        static var hasInitialCallbackHorizontal: UInt8 = 0
        static var hasInitialCallbackVertical: UInt8 = 0
        static var isInstantCrossAxisEntry: UInt8 = 0
        static var isFinalizingSwitch: UInt8 = 0
        static var isProgrammaticAnimatedScroll: UInt8 = 0
    }
}

/// 内部代理的弱引用包装(代理不能强持有业务对象)
private class WYWeakBox {
    weak var value: AnyObject?
    init(_ value: AnyObject?) {
        self.value = value
    }
}
