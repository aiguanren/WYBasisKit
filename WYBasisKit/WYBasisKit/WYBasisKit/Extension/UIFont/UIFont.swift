//
//  UIFont.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/24.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

public extension UIFont {
    
    /// 字号比率转换
    class func wy_fontSize(_ ratioValue: CGFloat, _ pixels: WYScreenPixels = WYBasisKitConfig.defaultScreenPixels) -> CGFloat {
        if UIDevice.wy_screenWidthRatio(pixels) > WYBasisKitConfig.fontRatio.max {
            return ratioValue * WYBasisKitConfig.fontRatio.max
        }else if UIDevice.wy_screenWidthRatio(pixels) < WYBasisKitConfig.fontRatio.min {
            return ratioValue * WYBasisKitConfig.fontRatio.min
        }else {
            return ratioValue * UIDevice.wy_screenWidthRatio(pixels)
        }
    }
}
