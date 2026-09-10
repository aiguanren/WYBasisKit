//
//  WYPagingItem+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/10.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingItem 私有属性集中管理，关联对象存储的图文排布参数与内容尺寸约束(供内容构建与选中状态变化时重新测量使用)
extension WYPagingItem {

    // 图文排布模式(创建内容布局与重新测量图文内容大小时使用)
    var contentPosition: WYButtonPosition {
        get {
            let rawValue: WYButtonPosition.RawValue = (objc_getAssociatedObject(self, &WYAssociatedKeys.contentPosition) as? WYButtonPosition.RawValue) ?? WYButtonPosition.imageLeftTitleRight.rawValue
            return WYButtonPosition(rawValue: rawValue) ?? .imageLeftTitleRight
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.contentPosition, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 图文之间的间距(创建内容布局与重新测量图文内容大小时使用)
    var contentDividingOffset: CGFloat {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.contentDividingOffset) as? NSNumber)?.doubleValue ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.contentDividingOffset, NSNumber(value: Double(newValue)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 图标固定尺寸(重新测量图文内容大小时使用)
    var contentImageViewSize: CGSize {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.contentImageViewSize) as? NSValue)?.cgSizeValue ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.contentImageViewSize, NSValue(cgSize: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 图文内容最小宽度约束(选中/未选中字体不同时随状态重算常量，Item宽度精确跟随当前字号)
    var textContentWidthConstraint: NSLayoutConstraint? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.textContentWidthConstraint) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.textContentWidthConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 图文内容最小高度约束(竖向布局用，随选中状态重算常量)
    var textContentHeightConstraint: NSLayoutConstraint? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.textContentHeightConstraint) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.textContentHeightConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    struct WYAssociatedKeys {
        static var contentPosition: UInt8 = 0
        static var contentDividingOffset: UInt8 = 0
        static var contentImageViewSize: UInt8 = 0
        static var textContentWidthConstraint: UInt8 = 0
        static var textContentHeightConstraint: UInt8 = 0
    }
}
