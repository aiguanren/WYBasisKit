//
//  WYScrollView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import UIKit

/// ScrollView 滑动方向
@objc public enum WYSlidingDirection: Int {
    
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
@objc @frozen public enum WYSlidingSource: Int {
    
    /// 未滑动 / 无法识别（含代码主动滑动）
    case none = 0
    
    /// 用户手指在拖动
    case user
    
    /// 用户手指离开屏幕后的惯性滑动
    case deceleration
}

public extension UIScrollView {
    
    /**
     手指是否正在拖动
     
     - 手指按下并产生位移时为 `true`
     - 手指释放后进入惯性阶段为 `false`
     */
    var wy_isFingerDragging: Bool {
        let state = panGestureRecognizer.state
        return (state == .began) || (state == .changed)
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
    var wy_isUserSliding: Bool {
        return wy_isFingerDragging || isDecelerating
    }
    
    /**
     当前滑动来源
     
     判断优先级：
     1. 手指拖动 / 跟踪中 → `.user`
     2. 惯性减速中 → `.deceleration`
     3. 其他情况（含代码滑动、完全静止）→ `.none`
     
     若只需要简单判断是否用户滑动，直接使用 `wy_isUserSliding` 即可。
     */
    var wy_slidingSource: WYSlidingSource {
        // 手指按下或正在拖动
        if wy_isFingerDragging || isTracking {
            return .user
        }
        
        // 惯性滑动阶段
        if isDecelerating {
            return .deceleration
        }
        
        // 静止或代码触发的滑动，统一返回 none
        return .none
    }
    
    /**
     是否处于回弹（bounce）状态
     
     仅在对应方向 contentSize 大于可视区域时才进行判断，
     避免内容不足时的误判。
     */
    var wy_isReboundState: Bool {
        
        // 横向可滑动时才判断
        if contentSize.width > bounds.width {
            
            if contentOffset.x < -contentInset.left {
                return true
            }
            
            let maxOffsetX = contentSize.width - bounds.width + contentInset.right
            if contentOffset.x > maxOffsetX {
                return true
            }
        }
        
        // 纵向可滑动时才判断
        if contentSize.height > bounds.height {
            
            if contentOffset.y < -contentInset.top {
                return true
            }
            
            let maxOffsetY = contentSize.height - bounds.height + contentInset.bottom
            if contentOffset.y > maxOffsetY {
                return true
            }
        }
        
        return false
    }
    
    /**
     *  当前手指滑动方向
     *
     *  通过对比本次与上一次的 contentOffset 计算位移方向，方向以手指滑动为准（而非内容移动方向）：
     *  deltaX > 0（内容右移）→ 手指左滑 → .left；deltaX < 0（内容左移）→ 手指右滑 → .right；
     *  deltaY > 0（内容下移）→ 手指上滑 → .up；deltaY < 0（内容上移）→ 手指下滑 → .down
     *
     *  建议在 scrollViewDidScroll(_:) 中持续调用以获得实时结果
     *
     *  @param threshold 位移阈值，用于过滤轻微抖动，默认 0.5pt
     *  @return 当前有效滑动方向；首次调用、位移过小、非用户滑动(setContentOffset等代码触发的偏移跳变)、回弹期间均返回上一次有效方向(从未产生过有效方向则返回 .unknown)
     */
    func wy_slidingDirection(threshold: CGFloat = 0.5) -> WYSlidingDirection {
        let currentOffset = contentOffset

        // 首次调用时记录当前偏移，避免以 .zero 为基准导致方向瞬间错误
        if !wy_hasRecordedOffset {
            wy_lastContentOffset = currentOffset
            wy_hasRecordedOffset = true
            return .unknown
        }

        let lastOffset = wy_lastContentOffset

        // 无论本次是否产生有效方向，都更新 lastOffset，保证下一帧计算准确
        defer { wy_lastContentOffset = currentOffset }

        let deltaX = currentOffset.x - lastOffset.x
        let deltaY = currentOffset.y - lastOffset.y

        // 位移小于阈值，视为抖动，保持上一次有效方向
        if abs(deltaX) < threshold && abs(deltaY) < threshold {
            return wy_lastValidDirection
        }

        if wy_isUserSliding == false {
            return wy_lastValidDirection
        }
        
        // 回弹期间强制返回上一次有效方向，避免回弹过程中方向频繁翻转
        if wy_isReboundState {
            return wy_lastValidDirection
        }
        
        // 以绝对位移更大的轴作为主方向
        let direction: WYSlidingDirection
        if abs(deltaX) > abs(deltaY) {
            // deltaX > 0 → 内容右移 → 手指左滑
            direction = deltaX > 0 ? .left : .right
        } else {
            // deltaY > 0 → 内容下移 → 手指上滑
            direction = deltaY > 0 ? .up : .down
        }
        
        // 记录本次有效方向，供后续抖动/回弹时使用
        wy_lastValidDirection = direction
        
        return direction
    }
}

private extension UIScrollView {
    
    /// 上一次记录的 contentOffset
    var wy_lastContentOffset: CGPoint {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastContentOffset) as? CGPoint ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 上一次有效的滑动方向
    var wy_lastValidDirection: WYSlidingDirection {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastValidDirection) as? WYSlidingDirection ?? .unknown
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastValidDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否已经记录过初始 offset（用于首次调用保护）
    var wy_hasRecordedOffset: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.hasRecordedOffset) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.hasRecordedOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private struct WYAssociatedKeys {
        static var lastContentOffset: UInt8 = 0
        static var lastValidDirection: UInt8 = 0
        static var hasRecordedOffset: UInt8 = 0
    }
}
