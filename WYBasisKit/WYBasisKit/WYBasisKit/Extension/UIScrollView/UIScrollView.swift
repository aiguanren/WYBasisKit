//
//  UIScrollView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/20.
//

import UIKit

/// ScrollView滑动方向
@frozen public enum WYSlidingDirection: Int {
    
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

public extension UIScrollView {
    
    /// 是否为用户手指触发的滑动
    var wy_isUserSliding: Bool {
        return self.isDragging || self.isDecelerating
    }
    
    /// 当前滑动方向
    var wy_slidingDirection: WYSlidingDirection {
        let currentOffset = self.contentOffset
        defer { wy_lastContentOffset = currentOffset }
        
        if currentOffset.y > wy_lastContentOffset.y {
            return .up
        } else if currentOffset.y < wy_lastContentOffset.y {
            return .down
        } else if currentOffset.x > wy_lastContentOffset.x {
            return .left
        } else if currentOffset.x < wy_lastContentOffset.x {
            return .right
        } else {
            return .unknown
        }
    }
}

private extension UIScrollView {
    
    // 保存上一次的偏移量
    private(set) var wy_lastContentOffset: CGPoint {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lastContentOffset) as? CGPoint ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lastContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private struct WYAssociatedKeys {
        static var wy_lastContentOffset: UInt8 = 0
    }
}
