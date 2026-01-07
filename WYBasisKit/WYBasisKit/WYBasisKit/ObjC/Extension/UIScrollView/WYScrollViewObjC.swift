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

@objc public extension UIScrollView {
    
    /// 是否为用户手指触发的滑动
    @objc(wy_isUserSliding)
    var wy_isUserSlidingObjC: Bool {
        return wy_isUserSliding
    }
    
    /// 当前滑动方向
    @objc(wy_slidingDirection)
    var wy_slidingDirectionObjC: WYSlidingDirectionObjC {
        return WYSlidingDirectionObjC(rawValue: wy_slidingDirection.rawValue) ?? .unknown
    }
}
