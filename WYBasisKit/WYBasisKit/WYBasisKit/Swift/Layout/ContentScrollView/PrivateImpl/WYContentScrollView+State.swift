//
//  WYContentScrollView+State.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/8/28.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYContentScrollView 私有实现：关联对象存储的内部状态属性(滑动方向/视图数组/计时器/锁与标记)
extension WYContentScrollView {

    /// 当前滑动方向：setter 内同步完成 reserveView 的摆位(按当前偏移量放到滑动方向一侧)、reserveIndex 的计算(含关闭无限轮播时的边界处理)以及 willSwitch 回调的触发
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
                if contentOffset.y > wy_height {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                }else {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                }
                
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentVerticalView, reserveVerticalView])

                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && previousAxisIsHorizontal && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveVerticalIndex = currentVerticalIndex
                }else if newValue == .up {
                    reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                    if (reserveVerticalIndex == 0) && (unlimitedCarousel == false) {
                        reserveVerticalIndex = currentVerticalIndex
                    }
                }else {
                    reserveVerticalIndex = currentVerticalIndex - 1
                    if (reserveVerticalIndex < 0)  {
                        reserveVerticalIndex = (unlimitedCarousel == false) ? currentVerticalIndex : (numberOfVerticalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will
                let isPageIndexChanged = (reserveVerticalIndex != currentVerticalIndex)
                if isPageIndexChanged && ((configVerticalReserveIndex != reserveVerticalIndex) || isCrossAxisEntry) {
                    switchContentCallback(isDidSwitch: false)
                }
            }
            
            if ((newValue == .left) || (newValue == .right) && (contentSlidingDirection != .topOrBottom)) {
                
                guard numberOfHorizontalContent > 0 else { return }
                
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                
                // 滑动前根据滑动方向的偏移量设置预备显示View的frame(不能简单根据newValue来设置，否则手指不松开左右滑动时无法更新reserveHorizontalView.frame，且必须放这里优先处理，否则往上下滑动后可能会出现空白页面)
                if contentOffset.x > wy_width {
                    reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }else {
                    reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }
                
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentHorizontalView, reserveHorizontalView])

                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && (previousAxisIsHorizontal == false) && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveHorizontalIndex = currentHorizontalIndex
                }else if newValue == .left {
                    reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                    if (reserveHorizontalIndex == 0) && (unlimitedCarousel == false) {
                        reserveHorizontalIndex = currentHorizontalIndex
                    }
                }else {
                    reserveHorizontalIndex = currentHorizontalIndex - 1
                    if (reserveHorizontalIndex < 0)  {
                        reserveHorizontalIndex = (unlimitedCarousel == false) ? currentHorizontalIndex : (numberOfHorizontalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will
                let isPageIndexChanged = (reserveHorizontalIndex != currentHorizontalIndex)
                if isPageIndexChanged && ((configHorizontalReserveIndex != reserveHorizontalIndex) || isCrossAxisEntry) {
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

    /// 是否已锁定滑动方向（只在一次拖拽中生效，避免contentSlidingDirection == .omnidirectional时滑动后无法锁定方向的问题）
    var isDirectionLocked: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked) as? Bool ?? false
        }
    }

    /// 本次拖拽中锁定的滑动方向(仅omnidirectional模式使用)：边界被 canScroll 拦截时 internalSliderDirection 不会更新，靠它保持本次拖拽的方向使拦截持续生效
    var dragLockedDirection: WYSlidingDirection {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection) as? WYSlidingDirection ?? .unknown }
    }

    /// 是否正处于轻扫跨轴直切中(直切开始前置true、pauseScroll收尾清除；期间handleScrollDirectionLock临时放开两轴能力让直切偏移通过，否则会被轴能力钳回中心)
    var isInstantCrossAxisEntry: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry) as? Bool ?? false }
    }

    /// 是否正处于切换收尾中(pauseScroll复位中心页会同步重入didScroll→setter，此时previousDirection已翻为目标轴不再判为跨轴，若不拦会按同轴推进逻辑把刚钳制/落定的下标再次±1)
    var isFinalizingSwitch: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch) as? Bool ?? false }
    }

    /// 是否正处于程序化动画滚动中(nextContent/lastContent的setContentOffset(animated:)期间)：期间两轴能力临时放开，否则判轴前两轴全钳制会抹掉动画头几帧位移、终点欠账够不到整页导致提交失败弹回原页；动画结束或用户接管时清除
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

    /// 水平轴是否已触发过"已展示"didSwitch(初始展示只回调当前展示方向，另一轴第一次被滑到时在scrollViewDidScroll立即补发一次，避免刚进页面两轴内容如双视频同时启动导致声音嘈杂)
    var hasInitialCallbackHorizontal: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal) as? Bool ?? false }
    }

    /// 垂直轴是否已触发过"已展示"didSwitch(初始展示只回调当前展示方向，另一轴第一次被滑到时在scrollViewDidScroll立即补发一次，避免刚进页面两轴内容如双视频同时启动导致声音嘈杂)
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

    struct WYAssociatedKeys {
        static var timer: UInt8 = 0
        static var horizontalViews: UInt8 = 0
        static var verticalViews: UInt8 = 0
        static var internalSliderDirection: UInt8 = 0
        static var canRestartedTimer: UInt8 = 0
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
