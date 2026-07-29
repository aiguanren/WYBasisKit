//
//  UIScrollView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// ScrollView滑动方向
@objc(WYSlidingDirection)
@frozen public enum WYSlidingDirectionObjC: Int {
    
    /// 未知方向
    case unknown = 0
    
    /// 向上滑动
    case up
    
    /// 向下滑动
    case down
    
    /// 向左滑动
    case left
    
    /// 向右滑动
    case right
}

/**
 ScrollView 滑动来源
 
 - 注意：纯代码触发的滑动（setContentOffset / scrollRectToVisible 等）
   无法在无额外标记的情况下可靠区分，统一归为 `.none`
 */
@objc(WYSlidingSource)
@frozen public enum WYSlidingSourceObjC: Int {
    
    /// 未滑动 / 无法识别（含代码主动滑动）
    case none = 0
    
    /// 用户手指在拖动
    case user
    
    /// 用户手指离开屏幕后的惯性滑动
    case deceleration
}

@objc public extension UIScrollView {
    
    /**
     手指是否正在拖动
     
     - 手指按下并产生位移时为 `true`
     - 手指释放后进入惯性阶段为 `false`
     */
    @objc(wy_isFingerDragging)
    var wy_isFingerDraggingObjC: Bool {
        return wy_isFingerDragging
    }
    
    /**
     是否为用户触发的滑动
     
     包含：
     1. 手指拖动
     2. 手指释放后的惯性滑动
     
     不包含：
     - setContentOffset
     - scrollToTop
     - 自动轮播等代码触发的滑动
     */
    @objc(wy_isUserSliding)
    var wy_isUserSlidingObjC: Bool {
        return wy_isUserSliding
    }
    
    /**
     当前滑动来源
     
     判断优先级：
     1. 手指拖动 / 跟踪中 → `.user`
     2. 惯性减速中 → `.deceleration`
     3. 其他情况（含代码滑动、完全静止）→ `.none`
     
     若只需要简单判断是否用户滑动，直接使用 `wy_isUserSliding` 即可。
     */
    @objc(wy_slidingSource)
    var wy_slidingSourceObjC: WYSlidingSourceObjC {
        return WYSlidingSourceObjC(rawValue: wy_slidingSource.rawValue) ?? .none
    }
    
    /**
     是否处于回弹（bounce）状态
     
     仅在对应方向 contentSize 大于可视区域时才进行判断，
     避免内容不足时的误判。
     */
    @objc(wy_isReboundState)
    var wy_isReboundStateObjC: Bool {
        return wy_isReboundState
    }
    
    /**
     当前手指滑动方向
     
     通过对比本次与上一次的 contentOffset 计算位移方向。
     方向以手指滑动为准（而非内容移动方向）：
     - deltaX > 0（内容右移）→ 手指左滑 → `.left`
     - deltaX < 0（内容左移）→ 手指右滑 → `.right`
     - deltaY > 0（内容下移）→ 手指上滑 → `.up`
     - deltaY < 0（内容上移）→ 手指下滑 → `.down`
     
     建议在 `scrollViewDidScroll(_:)` 中持续调用以获得实时结果。
     
     - Parameter threshold: 位移阈值，用于过滤轻微抖动，默认 0.5pt
     - Returns: 当前有效滑动方向；首次调用或位移过小时返回上一次有效方向（或 `.unknown`）
     */
//    @objc(wy_slidingDirectionWithThreshold:)
//    func wy_slidingDirectionObjC(threshold: CGFloat = 0.5) -> WYSlidingDirectionObjC {
//        let slidingDirection: WYSlidingDirection = wy_slidingDirection(threshold: threshold)
//        return WYSlidingDirectionObjC(rawValue: slidingDirection.rawValue) ?? .unknown
//    }
    
    @objc(wy_slidingDirectionWithThreshold)
    var wy_slidingDirectionObjC: @convention(block) (CGFloat) -> WYSlidingDirectionObjC {
        return { [weak self] threshold in
            guard let self = self else { return .unknown}
            
            let slidingDirection: WYSlidingDirection = wy_slidingDirection(threshold: threshold)
            return WYSlidingDirectionObjC(rawValue: slidingDirection.rawValue) ?? .unknown
        }
    }
}
