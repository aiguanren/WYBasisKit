//
//  UIFontObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import UIKit

@objc public extension UIFont {
    
    /// 字号比率转换
    @objc(wy_fontSize:)
    static func wy_fontSize(_ ratioValue: CGFloat) -> CGFloat {
        return wy_fontSize(ratioValue, pixels: WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc(wy_fontSize:pixels:)
    static func wy_fontSize(_ ratioValue: CGFloat, pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIFont.wy_fontSize(ratioValue, WYScreenPixels(width: pixels.width, height: pixels.height))
    }
}
