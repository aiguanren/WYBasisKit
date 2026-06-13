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
    case leftToRight
}

public extension CALayer {
    
    /**
     * 绘制虚线
     * @param direction    虚线方向
     * @param bounds       虚线bounds
     * @param color        虚线颜色
     * @param length       每段虚线长度（仅当 `isRound` 为 `false` 时有效）
     * @param isRound      是否为圆点虚线（true：圆点，false：普通虚线），为 `true` 时，圆点的直径由 direction 决定(`.topToBottom` 时直径 = bounds.width，`.leftToRight` 时直径 = bounds.height)
     * @param spacing      每段虚线间隔
     */
    static func wy_drawDashLine(
        direction: WYDashDirection,
        bounds: CGRect,
        color: UIColor,
        length: Double = Double(UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)),
        isRound: Bool = false,
        spacing: Double = Double(UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels))
    ) -> CALayer {
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        shapeLayer.anchorPoint = CGPoint(x: 0, y: 0)
        shapeLayer.position = bounds.origin
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        
        shapeLayer.lineWidth = direction == .topToBottom ? bounds.size.width : bounds.size.height
        
        // 样式确定
        if isRound {
            shapeLayer.lineCap = .round
            shapeLayer.lineJoin = .round
        } else {
            shapeLayer.lineCap = .butt
            shapeLayer.lineJoin = .miter
        }
        
        if isRound {
            /**
             圆点虚线：
             dash = 0（点）
             gap  = spacing + lineWidth（补偿圆角占用）
             */
            shapeLayer.lineDashPattern = [
                NSNumber(value: 0),
                NSNumber(value: spacing + Double(shapeLayer.lineWidth))
            ]
        } else {
            shapeLayer.lineDashPattern = [
                NSNumber(value: length),
                NSNumber(value: spacing)
            ]
        }
        
        let path = CGMutablePath()
        switch direction {
        case .leftToRight:
            let y = bounds.size.height * 0.5
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.size.width, y: y))
            
        case .topToBottom:
            let x = bounds.size.width * 0.5
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.size.height))
        }
        shapeLayer.path = path
        
        return shapeLayer
    }
}
