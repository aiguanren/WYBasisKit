//
//  CALayer.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/6/18.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

/// 虚线方向
@frozen public enum WYDashDirection: Int {
    
    /// 从上到下
    case topToBottom = 0
    /// 从左到右
    case leftToRight = 1
}

public extension CALayer {
    
    /**
    * 绘制虚线
    * @param direction    虚线方向
    * @param bounds       虚线bounds
    * @param color        虚线颜色
    * @param length       每段虚线长度
    * @param spacing      每段虚线间隔
    */
    static func drawDashLine(direction: WYDashDirection, bounds: CGRect, color: UIColor, length: Double = Double(UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)), spacing: Double = Double(UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))) -> CALayer {
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.bounds = bounds
        shapeLayer.anchorPoint = CGPoint(x: 0, y: 1)
        shapeLayer.position = bounds.origin
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        
        shapeLayer.lineWidth = direction == .topToBottom ? bounds.size.width : bounds.size.height
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [NSNumber(value: length), NSNumber(value: spacing)]
        
        let path = CGMutablePath()
        switch direction {
        case .leftToRight:
            let margin = bounds.size.height * 1.5
            path.move(to: CGPoint(x: bounds.origin.x, y: bounds.origin.y + margin))
            path.addLine(to: CGPoint(x: bounds.origin.x + bounds.size.width, y: bounds.origin.y + margin))
            break
        case .topToBottom:
            let margin = bounds.size.width * 0.5
            path.move(to: CGPoint(x: bounds.origin.x + margin, y: bounds.origin.y + bounds.size.height))
            path.addLine(to: CGPoint(x: bounds.origin.x + margin, y: (bounds.origin.y * 3) + bounds.size.height))
            break
        }
        shapeLayer.path = path
        
        return shapeLayer
    }
}
