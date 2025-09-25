//
//  UIColor.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

public extension UIColor {
    
    /// RGB(A) convert UIColor
    static func wy_rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ aplha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: aplha)
    }
    
    /// hexColor convert UIColor
    static func wy_hex(_ hexColor: String, _ alpha: CGFloat = 1.0) -> UIColor {
        // 去掉空格并转换为大写
        var colorStr = hexColor.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 处理前缀
        if colorStr.hasPrefix("0X") { colorStr.removeFirst(2) }
        if colorStr.hasPrefix("#")  { colorStr.removeFirst(1) }
        
        // 必须是 6 位有效字符
        guard colorStr.count == 6 else { return UIColor.clear }
        
        // 分割 R/G/B
        let rStr = String(colorStr.prefix(2))
        let gStr = String(colorStr.dropFirst(2).prefix(2))
        let bStr = String(colorStr.dropFirst(4).prefix(2))
        
        // 扫描十六进制数
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        Scanner(string: rStr).scanHexInt64(&r)
        Scanner(string: gStr).scanHexInt64(&g)
        Scanner(string: bStr).scanHexInt64(&b)
        
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha)
    }
    
    /// hexColor convert UIColor
    static func wy_hex(_ hexColor: UInt, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat((hexColor & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hexColor & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hexColor & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
    /// randomColor
    static var wy_random: UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
    
    /// 动态颜色
    static func wy_dynamic(_ light: UIColor, _ dark: UIColor) -> UIColor {
        let dynamicColor = UIColor { (trainCollection) -> UIColor in
            if trainCollection.userInterfaceStyle == UIUserInterfaceStyle.light {
                return light
            }else {
                return dark
            }
        }
        return dynamicColor
    }
}
