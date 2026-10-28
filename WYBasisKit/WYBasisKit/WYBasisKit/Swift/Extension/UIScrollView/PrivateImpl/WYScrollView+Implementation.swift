//
//  WYScrollView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

extension UIScrollView {

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
