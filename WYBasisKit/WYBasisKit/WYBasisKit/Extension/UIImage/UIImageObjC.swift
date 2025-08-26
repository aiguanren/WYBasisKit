//
//  UIImageObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

/// 动图格式类型
@objc public enum WYAnimatedImageStyleObjC: Int {
    
    /// 普通 GIF 图片
    case GIF = 0
    
    /// APNG 图片
    case APNG
}

/// Gif图片解析结果
@objcMembers public class WYGifInfoObjC: NSObject {
    
    /// 解析后得到的图片数组
    @objc public var animationImages: [UIImage]? = nil
    
    /// 轮询时长
    @objc public var animationDuration: CGFloat = 0.0
    
    /// 可以直接显示的动图
    @objc public var animatedImage: UIImage? = nil
    
    @objc public init(animationImages: [UIImage]? = nil, animationDuration: CGFloat, animatedImage: UIImage? = nil) {
        self.animationImages = animationImages
        self.animationDuration = animationDuration
        self.animatedImage = animatedImage
    }
}
