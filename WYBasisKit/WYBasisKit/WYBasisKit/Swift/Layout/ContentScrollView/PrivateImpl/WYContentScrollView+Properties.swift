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
            
            // 跨轴判定必须用写入前的方向：先写入再读的话，读出来的"上一个方向"永远是刚写进去的新值，跨轴永远判不出来
            let previousDirection: WYSlidingDirection = objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if ((newValue == .up) || (newValue == .down) && (contentSlidingDirection != .leftOrRight)) {
                
                guard numberOfVerticalContent > 0 else { return }
                
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                
                // 滑动时按偏移量把预备页摆到正确的一侧：不能简单按新方向值来摆，否则手指不松开来回滑时预备页的位置不会跟着更新；这一步必须放在最前面先处理，不然滑完另一个轴再回来可能出现空白页面
                // fade/zoom拖动期间跳过这里的摆位：它们拖动时偏移量全程被钳在中心不动，这里的摆位会把已经摆在中间的进入页一帧一帧地挪到屏幕外去；拖动期间进入页的位置由交互逻辑管理(slide不跳过：它的偏移跟手，这里的摆位和交互摆位恰好一致，正好顺便承担逐帧摆位的活)
                if (isInteractiveCrossAxisDrag == false) || (crossAxisSwitchStyle == .slide) {
                    if contentOffset.y > wy_height {
                        reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                    }else {
                        reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                    }
                }
                
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex
                
                // 判断这次方向变化是不是切轴进来：必须在下面置顶操作之前判断，因为置顶会把目标轴翻到最上面，之后再判断时"按置顶View算展示轴"算出来的就是刚翻上来的目标轴自己，切轴会被误判成"本来就是我在展示"，预备下标被错误加一、还多发一条willSwitch(轻扫直切必现)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentVerticalView, reserveVerticalView])
                // 判断这次方向变化是不是切轴进来(方向还不知道时按置顶View算)：按优先方向算会把切到垂直轴判错、预备下标不推进(下标不涨、轮播卡在一个没加载的页上)；代码切页(动画期间)不按切轴处理，业务明确调next/last/switchContent切另一轴时期待目标轴下标前进并预加载，"下标不动"只属于轻扫直切(用户随手换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && previousAxisIsHorizontal && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：预备下标钳在当前下标保持不动(跨轴切换的意思是只换展示轴、不翻页)
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
                
                // 页码没变就不发will(预备页没换就没有预加载的必要)；切轴进来时因为预备下标刚被钳住、比对会失灵，需要强制发一次；收尾冻结期间不发，因为收尾恢复方向时会路过这里，失灵的比对会补出一条多余的willSwitch让业务白白重载预备页(正常的预加载都发生在未冻结时)
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
                
                // 滑动时按偏移量把预备页摆到正确的一侧：不能简单按新方向值来摆，否则手指不松开来回滑时预备页的位置不会跟着更新；这一步必须放在最前面先处理，不然滑完另一个轴再回来可能出现空白页面
                // fade/zoom拖动期间跳过这里的摆位：它们拖动时偏移量全程被钳在中心不动，这里的摆位会把已经摆在中间的进入页一帧一帧地挪到屏幕外去；拖动期间进入页的位置由交互逻辑管理(slide不跳过：它的偏移跟手，这里的摆位和交互摆位恰好一致，正好顺便承担逐帧摆位的活)
                if (isInteractiveCrossAxisDrag == false) || (crossAxisSwitchStyle == .slide) {
                    if contentOffset.x > wy_width {
                        reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                    }else {
                        reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                    }
                }
                
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex
                
                // 判断这次方向变化是不是切轴进来：必须在下面置顶操作之前判断，因为置顶会把目标轴翻到最上面，之后再判断时"按置顶View算展示轴"算出来的就是刚翻上来的目标轴自己，切轴会被误判成"本来就是我在展示"，预备下标被错误加一、还多发一条willSwitch
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentHorizontalView, reserveHorizontalView])
                // 判断这次方向变化是不是切轴进来(方向还不知道时按置顶View算)：按优先方向算会把切到垂直轴判错、预备下标不推进(下标不涨、轮播卡在一个没加载的页上)；代码切页(动画期间)不按切轴处理，业务明确调next/last/switchContent切另一轴时期待目标轴下标前进并预加载，"下标不动"只属于轻扫直切(用户随手换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && (previousAxisIsHorizontal == false) && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：预备下标钳在当前下标保持不动(跨轴切换的意思是只换展示轴、不翻页)
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
                
                // 页码没变就不发will(预备页没换就没有预加载的必要)；切轴进来时因为预备下标刚被钳住、比对会失灵，需要强制发一次；收尾冻结期间不发，因为收尾恢复方向时会路过这里，失灵的比对会补出一条多余的willSwitch让业务白白重载预备页(正常的预加载都发生在未冻结时)
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
    
    /// 水平轴上次手势翻页提交时间(同轴翻页冷却计时用，代码切页的提交不记录时间)
    var lastGestureHorizontalSwitchDate: Date? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.lastGestureHorizontalSwitchDate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.lastGestureHorizontalSwitchDate) as? Date }
    }

    /// 垂直轴上次手势翻页提交时间(同轴翻页冷却计时用，代码切页的提交不记录时间)
    var lastGestureVerticalSwitchDate: Date? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.lastGestureVerticalSwitchDate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.lastGestureVerticalSwitchDate) as? Date }
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
    
    /// 交互式跨轴拖动的目标方向(决定进入页从哪一侧进来、拖动进度沿哪个方向计算)
    var interactiveCrossDirection: WYSlidingDirection {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.interactiveCrossDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.interactiveCrossDirection) as? WYSlidingDirection ?? .unknown
        }
    }
    
    /// 代码修正偏移量时的"正在修正"标记：拦住重入，防止两处修正互相触发、无限递归把栈撑爆
    var isCorrectingContentOffset: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isCorrectingContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isCorrectingContentOffset) as? Bool ?? false
        }
    }
    
    /// 业务是否主动停止过计时器：置位后首次展示的自动开轮播让位不再自动开，只有再调startTimer才恢复
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
    
    /// 是否正处于轻扫跨轴直切中：期间两轴临时放行，防止直切的偏移被钳回中心
    var isInstantCrossAxisEntry: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry) as? Bool ?? false }
    }
    
    /// 是否正处于切换收尾中：防止收尾过程再进一次方向setter把刚定好的下标又±1
    var isFinalizingSwitch: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch) as? Bool ?? false }
    }
    
    /// 是否正处于代码切页的动画滚动中：期间两轴临时放行，防止动画位移被钳回中心导致停的位置不够整页
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
    
    /// 当前显示在最上层的ContentView
    var upperContentView: UIView? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.upperContentView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.upperContentView) as? UIView }
    }
    struct WYAssociatedKeys {
        static var timer: UInt8 = 0
        static var lastGestureHorizontalSwitchDate: UInt8 = 0
        static var lastGestureVerticalSwitchDate: UInt8 = 0
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
