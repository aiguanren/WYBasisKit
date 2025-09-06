//
//  UIFontObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import UIKit

@objc public extension UIFont {
    
    /// 字号比率转换
    @objc static func wy_fontSize(with ratioValue: CGFloat) -> CGFloat {
        return wy_fontSize(with: ratioValue, pixels: WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc static func wy_fontSize(with ratioValue: CGFloat, pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIFont.wy_fontSize(ratioValue, WYScreenPixels(width: pixels.width, height: pixels.height))
    }
}
