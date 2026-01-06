//
//  UIColorObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension UIColor {
    
    /// RGB(A) 转换为 UIColor
    @objc(wy_rgbWithRed:green:blue:)
    static func wy_rgbObjC(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        return wy_rgb(red, green, blue)
    }
    @objc(wy_rgbWithRed:green:blue:aplha:)
    static func wy_rgbObjC(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ aplha: CGFloat = 1.0) -> UIColor {
        return wy_rgb(red, green, blue, aplha)
    }
    
    /// 十六进制字符串或整数转换为UIColor(支持字符串类型或整数类型)
    @objc(wy_hex:)
    static func wy_hexObjC(_ hexColor: Any) -> UIColor {
        return wy_hex(hexColor)
    }
    @objc(wy_hex:alpha:)
    static func wy_hexObjC(_ hexColor: Any, _ alpha: CGFloat = 1.0) -> UIColor {
        return wy_hex(hexColor, alpha)
    }
    
    /// 随机颜色
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
