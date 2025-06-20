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
    class func wy_rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ aplha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: aplha)
    }

    /// hexColor convert UIColor
    class func wy_hex(_ hexColor: String, _ alpha: CGFloat = 1.0) -> UIColor {
        var colorStr = hexColor.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString
        if colorStr.length < 6 {
            return UIColor.clear
        }
        if colorStr.hasPrefix("0X") || colorStr.hasPrefix("0x") {
            colorStr = colorStr.substring(from: 2) as NSString
        }
        if colorStr.hasPrefix("#") {
            colorStr = colorStr.substring(from: 1) as NSString
        }
        if colorStr.length != 6 {
            return UIColor.clear
        }
        var range = NSRange.init()
        range.location = 0
        range.length = 2
        // red
        let redStr = colorStr.substring(with: range)
        // green
        range.location = 2
        let greenStr = colorStr.substring(with: range)
        // blue
        range.location = 4
        let blueStr = colorStr.substring(with: range)
        var R: UInt64 = 0x0
        var G: UInt64 = 0x0
        var B: UInt64 = 0x0
        Scanner(string: redStr).scanHexInt64(&R)
        Scanner(string: greenStr).scanHexInt64(&G)
        Scanner(string: blueStr).scanHexInt64(&B)
        return UIColor(red: CGFloat(R)/255.0, green: CGFloat(G)/255.0, blue: CGFloat(B)/255.0, alpha: CGFloat(alpha))
    }
    
    /// hexColor convert UIColor
    class func wy_hex(_ hexColor: UInt, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat((hexColor & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hexColor & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hexColor & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }

    /// randomColor
    class var wy_random: UIColor {
        return UIColor(red: CGFloat(arc4random()%256)/255.0, green: CGFloat(arc4random()%256)/255.0, blue: CGFloat(arc4random()%256)/255.0, alpha: 1.0)
    }
    
    /// 动态颜色
    class func wy_dynamic(_ light: UIColor, _ dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            let dynamicColor = UIColor { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == UIUserInterfaceStyle.light {
                    return light
                }else {
                    return dark
                }
            }
            return dynamicColor
            
        } else {
            return light
        }
    }
}
