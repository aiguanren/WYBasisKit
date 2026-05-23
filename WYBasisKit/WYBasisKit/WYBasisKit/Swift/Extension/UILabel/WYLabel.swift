//
//  UILabel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/23.
//

import Foundation
import UIKit

public extension UILabel {
    
    /// 内边距（上、左、下、右）
    var wy_contentInsets: UIEdgeInsets {
        get {
            if let value = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_contentInsetsKey) as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            UILabel.wy_swizzleOnce
            objc_setAssociatedObject(
                self,
                &WYAssociatedKeys.wy_contentInsetsKey,
                NSValue(uiEdgeInsets: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            /// 刷新尺寸 & 绘制
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
}

private extension UILabel {
    
    /// 用于关联对象（Associated Object）的静态键值结构
    struct WYAssociatedKeys {
        static var wy_contentInsetsKey: UInt8 = 0
    }
    
    /// 利用 static let 保证只执行一次
    static let wy_swizzleOnce: Void = {
        
        // 交换 drawText(in:)（拦截并替换矩形）
        wy_exchangeDrawText(for: UILabel.self, intercept: { currentLabel, originalRect in
            let insets = currentLabel.wy_contentInsets
            guard insets != .zero else { return .proceed }
            return .replace(originalRect.inset(by: insets))
        })
        
        // 交换 intrinsicContentSize（修改返回值）
        wy_exchangeIntrinsicContentSize(for: UILabel.self, after: { currentView, originalResult in
            guard let label = currentView as? UILabel else { return originalResult }
            
            let insets = label.wy_contentInsets
            guard insets != .zero else { return originalResult }
            return CGSize(
                width: insets.left + originalResult.width + insets.right,
                height: insets.top + originalResult.height + insets.bottom
            )
        })
    }()
}
