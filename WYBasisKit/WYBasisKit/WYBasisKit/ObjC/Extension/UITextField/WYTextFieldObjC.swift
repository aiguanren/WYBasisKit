//
//  UITextFieldObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc public extension UITextField {
    
    /// 占位文字颜色
    @objc(wy_placeholderColor)
    var wy_placeholderColorObjC: UIColor {
        set(newValue) { wy_placeholderColor = newValue }
        get { return wy_placeholderColor }
    }
    
    /// 占位label
    @objc(wy_placeholderLabel)
    var wy_placeholderLabelObjC: UILabel {
        return wy_placeholderLabel
    }
}
