//
//  UIColor.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import SwiftUI

public extension Color {
    
    /// RGB(A) 转换为 Color
    static func wy_rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: Double = 1.0) -> Color {
        return Color(red: red/255.0, green: green/255.0, blue: blue/255.0, opacity: alpha)
    }
    
    /// 十六进制字符串或整数转换为 Color(支持字符串类型或整数类型)
    static func wy_hex(_ value: Any, _ alpha: Double = 1.0) -> Color {
        
        if let hexColor = value as? String {
            
            // 去掉空格并转换为大写
            var colorStr = hexColor.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            // 处理前缀
            if colorStr.hasPrefix("0X") { colorStr.removeFirst(2) }
            if colorStr.hasPrefix("#")  { colorStr.removeFirst(1) }
            
            // 必须是 6 位有效字符
            guard colorStr.count == 6 else { return Color.clear }
            
            // 分割 R/G/B
            let rStr = String(colorStr.prefix(2))
            let gStr = String(colorStr.dropFirst(2).prefix(2))
            let bStr = String(colorStr.dropFirst(4).prefix(2))
            
            // 扫描十六进制数
            var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
            Scanner(string: rStr).scanHexInt64(&r)
            Scanner(string: gStr).scanHexInt64(&g)
            Scanner(string: bStr).scanHexInt64(&b)
            
            return Color(red: Double(r)/255.0, green: Double(g)/255.0, blue: Double(b)/255.0, opacity: alpha)
            
        } else if let hexColor = value as? UInt {
            return Color(
                red: Double((hexColor & 0xFF0000) >> 16) / 255.0,
                green: Double((hexColor & 0x00FF00) >> 8) / 255.0,
                blue: Double(hexColor & 0x0000FF) / 255.0,
                opacity: alpha
            )
        }
        
        return .clear
    }
    
    /// 随机颜色
    static var wy_random: Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1),
            opacity: 1.0
        )
    }
    
    /// 动态颜色
    @available(iOS 14.0, *)
    static func wy_dynamic(_ light: Color, _ dark: Color) -> Color {
        return Color(UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}
