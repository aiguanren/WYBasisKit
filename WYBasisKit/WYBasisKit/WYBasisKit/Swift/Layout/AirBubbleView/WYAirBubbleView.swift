//
//  WYAirBubbleView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/7/2.
//

import UIKit

/// 三角箭头方向
public enum WYArrowDirection: Int {
    /// 顶部
    case top = 0
    /// 底部
    case bottom
    /// 左侧
    case left
    /// 右侧
    case right
}

public class WYAirBubbleView: UIView {

    /// (气泡)圆角半径
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels) {
        didSet { updatePath() }
    }

    /// (气泡)圆角位置
    public var cornersPosition: UIRectCorner = .allCorners {
        didSet { updatePath() }
    }

    /// (气泡)填充颜色
    public var fillColor: UIColor = .systemBlue {
        didSet { updateStyle() }
    }

    /// (气泡)边框颜色
    public var borderColor: UIColor = .clear {
        didSet { updateStyle() }
    }

    /// (气泡)边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet { updateStyle() }
    }

    /// 是否显示三角箭头
    public var showsArrow: Bool = true {
        didSet { updatePath() }
    }

    /// 三角箭头方向
    public var arrowDirection: WYArrowDirection = .bottom {
        didSet { updatePath() }
    }

    /// 三角箭头尺寸（宽，高）
    public var arrowSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { updatePath() }
    }

    /// 箭头颜色（默认跟随气泡）
    public var arrowColor: UIColor? {
        didSet { updateStyle() }
    }

    /**
     箭头相对(所在边)中心点偏移（pt）
     规则： - top / bottom：X方向偏移
           - left / right：Y方向偏移
     */
    public var arrowOffset: CGFloat = 0 {
        didSet { updatePath() }
    }

    /// 箭头边界安全距离（防止贴边）
    public var arrowEdgePadding: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels) {
        didSet { updatePath() }
    }

    /// 箭头尖角(圆角)半径
    public var arrowTipRadius: CGFloat = 0 {
        didSet { updatePath() }
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        privateCommonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        privateCommonInit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        arrowLayer.frame = bounds
        updatePath()
    }

    /// 私有初始化配置
    func privateCommonInit() {
        layer.addSublayer(shapeLayer)
        layer.addSublayer(arrowLayer)
        
        shapeLayer.contentsScale = UIApplication.shared.wy_keyWindow.screen.scale
        arrowLayer.contentsScale = UIApplication.shared.wy_keyWindow.screen.scale
        
        // 支持 AutoLayout
        translatesAutoresizingMaskIntoConstraints = false
        
        updateStyle()
        // 确保首次布局时绘制
        setNeedsLayout()
    }
    
    /// 气泡绘制Layer（负责渲染圆角矩形）
    let shapeLayer = CAShapeLayer()
    
    /// 箭头绘制Layer（独立于气泡，支持独立颜色）
    let arrowLayer = CAShapeLayer()
    
    /// 更新颜色与边框
    func updateStyle() {
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.lineWidth = borderWidth
        
        // 箭头独立颜色
        arrowLayer.fillColor = (arrowColor ?? fillColor).cgColor
        arrowLayer.strokeColor = borderColor.cgColor
        arrowLayer.lineWidth = borderWidth
    }
    
    /// 构建气泡路径与箭头路径（独立Layer）
    func updatePath() {
        
        let rect = bounds
        
        let arrowW = showsArrow ? arrowSize.width : 0
        let arrowH = showsArrow ? arrowSize.height : 0
        
        var bubbleRect = rect
        
        // 根据箭头方向调整气泡区域
        switch arrowDirection {
        case .bottom:
            bubbleRect.size.height -= arrowH
        case .top:
            bubbleRect.origin.y += arrowH
            bubbleRect.size.height -= arrowH
        case .left:
            bubbleRect.origin.x += arrowH
            bubbleRect.size.width -= arrowH
        case .right:
            bubbleRect.size.width -= arrowH
        }
        
        // ----- 气泡圆角矩形路径 -----
        let bubblePath = UIBezierPath(
            roundedRect: bubbleRect,
            byRoundingCorners: cornersPosition,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        shapeLayer.path = bubblePath.cgPath
        
        // ----- 箭头路径（若显示） -----
        if showsArrow {
            let arrowPath = UIBezierPath()
            
            // 计算箭头底边中心位置（考虑偏移和边界限制）
            var pos: CGFloat
            switch arrowDirection {
            case .top, .bottom:
                pos = bubbleRect.midX + arrowOffset
                // 限制范围，同时考虑箭头宽度的一半和圆角半径，防止底边超出圆角
                let halfW = arrowW / 2
                let minX = bubbleRect.minX + max(arrowEdgePadding, cornerRadius + halfW)
                let maxX = bubbleRect.maxX - max(arrowEdgePadding, cornerRadius + halfW)
                pos = max(minX, min(pos, maxX))
            case .left, .right:
                pos = bubbleRect.midY + arrowOffset
                let halfW = arrowW / 2
                let minY = bubbleRect.minY + max(arrowEdgePadding, cornerRadius + halfW)
                let maxY = bubbleRect.maxY - max(arrowEdgePadding, cornerRadius + halfW)
                pos = max(minY, min(pos, maxY))
            }
            
            // 确定三个顶点
            let p1: CGPoint, tip: CGPoint, p2: CGPoint
            switch arrowDirection {
            case .bottom:
                p1 = CGPoint(x: pos - arrowW/2, y: bubbleRect.maxY)
                tip = CGPoint(x: pos, y: bubbleRect.maxY + arrowH)
                p2 = CGPoint(x: pos + arrowW/2, y: bubbleRect.maxY)
            case .top:
                p1 = CGPoint(x: pos - arrowW/2, y: bubbleRect.minY)
                tip = CGPoint(x: pos, y: bubbleRect.minY - arrowH)
                p2 = CGPoint(x: pos + arrowW/2, y: bubbleRect.minY)
            case .left:
                p1 = CGPoint(x: bubbleRect.minX, y: pos - arrowW/2)
                tip = CGPoint(x: bubbleRect.minX - arrowH, y: pos)
                p2 = CGPoint(x: bubbleRect.minX, y: pos + arrowW/2)
            case .right:
                p1 = CGPoint(x: bubbleRect.maxX, y: pos - arrowW/2)
                tip = CGPoint(x: bubbleRect.maxX + arrowH, y: pos)
                p2 = CGPoint(x: bubbleRect.maxX, y: pos + arrowW/2)
            }
            
            // 构建箭头（支持圆角尖端）
            if arrowTipRadius > 0 {
                // 精确计算切点：从尖点到两边各取长度 d，使圆弧与两条边相切
                let d = arrowTipRadius / tan(.pi / 8) // 22.5° 半角，tan(π/8) ≈ 0.4142
                // 实际 d 不能超过边长的一半（保留安全系数 0.9）
                let maxD = min(
                    hypot(p1.x - tip.x, p1.y - tip.y),
                    hypot(p2.x - tip.x, p2.y - tip.y)
                ) * 0.9
                let useD = min(d, maxD)
                
                // 从尖点向两边延伸 useD
                let vec1 = CGPoint(x: p1.x - tip.x, y: p1.y - tip.y)
                let len1 = hypot(vec1.x, vec1.y)
                let norm1 = len1 > 0 ? CGPoint(x: vec1.x/len1, y: vec1.y/len1) : .zero
                let mid1 = CGPoint(x: tip.x + norm1.x * useD, y: tip.y + norm1.y * useD)
                
                let vec2 = CGPoint(x: p2.x - tip.x, y: p2.y - tip.y)
                let len2 = hypot(vec2.x, vec2.y)
                let norm2 = len2 > 0 ? CGPoint(x: vec2.x/len2, y: vec2.y/len2) : .zero
                let mid2 = CGPoint(x: tip.x + norm2.x * useD, y: tip.y + norm2.y * useD)
                
                arrowPath.move(to: p1)
                arrowPath.addLine(to: mid1)
                arrowPath.addQuadCurve(to: mid2, controlPoint: tip)
                arrowPath.addLine(to: p2)
            } else {
                arrowPath.move(to: p1)
                arrowPath.addLine(to: tip)
                arrowPath.addLine(to: p2)
            }
            arrowPath.close()
            arrowLayer.path = arrowPath.cgPath
            arrowLayer.isHidden = false
        } else {
            arrowLayer.path = nil
            arrowLayer.isHidden = true
        }
    }
}
