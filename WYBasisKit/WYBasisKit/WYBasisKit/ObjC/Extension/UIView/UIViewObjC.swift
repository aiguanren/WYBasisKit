//
//  UIViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/25.
//

import Foundation

/// 渐变方向
@objc(WYGradientDirection)
@frozen public enum WYGradientDirectionObjC: Int {
    
    /// 从上到下
    case topToBottom = 0
    /// 从左到右
    case leftToRight = 1
    /// 左上到右下
    case leftToLowRight = 2
    /// 右上到左下
    case rightToLowLeft = 3
}
