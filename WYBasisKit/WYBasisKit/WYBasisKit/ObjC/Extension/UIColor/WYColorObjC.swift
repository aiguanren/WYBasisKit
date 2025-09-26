//
//  UIColorObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit

@objc public extension UIColor {
    
    /// RGB(A) convert UIColor
    @objc(wy_rgbWithRed:green:blue:aplha:)
    static func wy_rgbObjC(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ aplha: CGFloat = 1.0) -> UIColor {
        return wy_rgb(red, green, blue, aplha)
    }
    
    /// hexColor convert UIColor
    @objc(wy_hexString:alpha:)
    static func wy_hexObjC(string hexColor: String, _ alpha: CGFloat = 1.0) -> UIColor {
        return wy_hex(string: hexColor, alpha)
    }
    
    /// hexColor convert UIColor
    @objc(wy_hexValue:alpha:)
    static func wy_hexObjC(value hexColor: UInt, _ alpha: CGFloat = 1.0) -> UIColor {
        return wy_hex(value: hexColor, alpha)
    }
    
    /// randomColor
    @objc(wy_random)
    static var wy_randomObjC: UIColor {
        return wy_random
    }
    
    /// 动态颜色
    @objc(wy_dynamicWithLight:dark:)
    static func wy_dynamicObjC(_ light: UIColor, _ dark: UIColor) -> UIColor {
        return wy_dynamic(light, dark)
    }
}
