//
//  WYAirBubbleView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/7/2.
//

import UIKit

/// 三角箭头的指向方向
public enum WYArrowDirection: Int {
    /// 箭头指向顶部（气泡在下方）
    case top = 0
    /// 箭头指向底部（气泡在上方）
    case bottom
    /// 箭头指向左侧（气泡在右侧）
    case left
    /// 箭头指向右侧（气泡在左侧）
    case right
}

/// 自定义气泡视图，支持圆角、边框、带三角箭头，箭头可设置方向、尺寸、偏移和圆角等
public class WYAirBubbleView: UIView {

    /// 气泡主体的圆角半径
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels) {
        didSet { updatePath() }
    }

    /// 需要圆角的位置（左上、右上、左下、右下组合），默认全部圆角
    public var cornersPosition: UIRectCorner = .allCorners {
        didSet { updatePath() }
    }

    /// 气泡的填充颜色，默认系统蓝色
    public var fillColor: UIColor = .systemBlue {
        didSet { updateStyle() }
    }

    /// 气泡边框的颜色，默认透明（无边框）
    public var borderColor: UIColor = .clear {
        didSet { updateStyle() }
    }

    /// 气泡边框的宽度，默认0（无边框）
    public var borderWidth: CGFloat = 0 {
        didSet { updateStyle() }
    }

    /// 是否显示三角箭头(默认显示)
    public var showsArrow: Bool = true {
        didSet { updatePath() }
    }

    /// 三角箭头的方向，默认指向底部（气泡在上方）
    public var arrowDirection: WYArrowDirection = .bottom {
        didSet { updatePath() }
    }

    /// 三角箭头的尺寸（宽度，高度），宽度是底边长度，高度是尖点到底边的垂直距离
    public var arrowSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { updatePath() }
    }

    /**
     箭头相对于所在边中心点的偏移量（单位：pt）
     规则：
     - 当方向为 .top 或 .bottom 时，偏移沿 X 轴（正数向右，负数向左）
     - 当方向为 .left 或 .right 时，偏移沿 Y 轴（正数向下，负数向上）
     */
    public var arrowOffset: CGFloat = 0 {
        didSet { updatePath() }
    }

    /// 箭头距离气泡边缘的最小安全距离，防止箭头贴边导致圆角或边界重叠
    public var arrowEdgePadding: CGFloat = 0 {
        didSet { updatePath() }
    }

    /// 箭头尖角的圆角半径
    public var arrowTipRadius: CGFloat = 0 {
        didSet { updatePath() }
    }
    
    /**
     是否启用气泡 path 动画
     规则：
     - 开启时：在视图尺寸（frame/bounds/约束）变化过程中，path
       会做同步动画，保证气泡形变平滑
     - 关闭时：path 直接更新，不执行动画（适用于列表滚动等性能敏感场景）
     
     - Note:
       用于避免 CAShapeLayer 隐式动画在尺寸变化时出现的异常（如放大/回弹）
     */
    public var enablePathAnimation: Bool = false

    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    /// 用于渲染填充颜色的 CAShapeLayer
    private let fillLayer = CAShapeLayer()

    /// 用于渲染边框的 CAShapeLayer（独立于填充层，以便分别控制颜色和线宽）
    private let borderLayer = CAShapeLayer()
    
    /// 记录当前View的Bounds，实现只在“尺寸变化时”才更新
    private var lastBounds: CGRect = .zero

    /// 配置图层属性（背景透明、添加子图层、设置边框样式）
    private func setupLayer() {
        backgroundColor = .clear

        layer.addSublayer(fillLayer)
        layer.addSublayer(borderLayer)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineJoin = .round
        borderLayer.lineCap = .round

        updateStyle()
    }

    /// 布局
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        
        // 当视图尺寸变化时重新计算路径
        updatePath()
    }

    /// 更新填充色和边框样式（不涉及路径几何）
    private func updateStyle() {
        fillLayer.fillColor = fillColor.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        
        // 边框宽度为0时隐藏（避免不必要渲染）
        borderLayer.isHidden = borderWidth <= 0
    }

    /// 更新所有几何路径（气泡主体圆角矩形 + 箭头），并重新赋值给对应图层
    private func updatePath() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        // 计算除去箭头占位后的气泡主体矩形
        let rect = bubbleRect()

        // 构建统一填充路径（圆角 + 箭头）
        let path = UIBezierPath()
        buildBorderPath(path, rect: rect)
        
        let newPath = path.cgPath
        
        if enablePathAnimation {
            
            // 使用显式动画，避免隐式动画导致的尺寸异常（放大/回弹问题）
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = fillLayer.presentation()?.path ?? fillLayer.path
            animation.toValue = newPath
            animation.duration = CATransaction.animationDuration()
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // 动画key
            let animationKey = "AirBubbleAnimationKey"
            
            // 避免多次 layout 时动画叠加
            fillLayer.removeAnimation(forKey: animationKey)
            borderLayer.removeAnimation(forKey: animationKey)
            
            fillLayer.add(animation, forKey: animationKey)
            borderLayer.add(animation, forKey: animationKey)
        }

        fillLayer.path = newPath
        borderLayer.path = newPath
    }

    /**
     计算气泡主体矩形（扣除箭头占据的区域）
     - Returns: 气泡主体部分的 CGRect，不包含箭头
     */
    private func bubbleRect() -> CGRect {
        var rect = bounds
        guard showsArrow else { return rect }

        switch arrowDirection {
        case .top:
            rect.origin.y += arrowSize.height
            rect.size.height -= arrowSize.height
        case .bottom:
            rect.size.height -= arrowSize.height
        case .left:
            rect.origin.x += arrowSize.height
            rect.size.width -= arrowSize.height
        case .right:
            rect.size.width -= arrowSize.height
        }
        return rect
    }

    /**
     将箭头路径追加到填充路径中（闭合路径）
     - Parameters:
       - path: 已包含气泡主体的路径
       - rect: 气泡主体矩形
     */
    private func appendArrowFill(to path: UIBezierPath, rect: CGRect) {
        let (p1, tip, p2) = arrowPoints(rect: rect)
        path.move(to: p1)
        
        if arrowTipRadius > 0 {
            addRoundedArrow(path, from: p1, tip: tip, to: p2)
        } else {
            path.addLine(to: tip)
            path.addLine(to: p2)
        }
        
        path.close()
    }

    /**
     完整构建边框路径，包含气泡主体的圆角矩形边界以及箭头轮廓，确保边框连续且闭合
     - Parameters:
       - path: 空的 UIBezierPath，用于接收构建的路径
       - rect: 气泡主体矩形
     */
    private func buildBorderPath(_ path: UIBezierPath, rect: CGRect) {
        
        let maxRadius = min(rect.width, rect.height) / 2
        let r = min(cornerRadius, maxRadius)
        
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        // 根据 cornersPosition 计算每个角的半径
        let tl = cornersPosition.contains(.topLeft) ? r : 0
        let tr = cornersPosition.contains(.topRight) ? r : 0
        let bl = cornersPosition.contains(.bottomLeft) ? r : 0
        let br = cornersPosition.contains(.bottomRight) ? r : 0

        // 从左上角开始
        path.move(to: CGPoint(x: minX + tl, y: minY))

        // ----- 上边（TOP）-----
        if showsArrow && arrowDirection == .top {
            let (p1, tip, p2) = arrowPoints(rect: rect)
            path.addLine(to: p1)
            addArrowBorder(path, from: p1, tip: tip, to: p2)
            path.addLine(to: CGPoint(x: maxX - tr, y: minY))
        } else {
            path.addLine(to: CGPoint(x: maxX - tr, y: minY))
        }

        // 右上角
        if tr > 0 {
            path.addArc(
                withCenter: CGPoint(x: maxX - tr, y: minY + tr),
                radius: tr,
                startAngle: -.pi/2,
                endAngle: 0,
                clockwise: true
            )
        }

        // ----- 右边（RIGHT）-----
        if showsArrow && arrowDirection == .right {
            let (p1, tip, p2) = arrowPoints(rect: rect)
            path.addLine(to: p1)
            addArrowBorder(path, from: p1, tip: tip, to: p2)
            path.addLine(to: CGPoint(x: maxX, y: maxY - br))
        } else {
            path.addLine(to: CGPoint(x: maxX, y: maxY - br))
        }

        // 右下角
        if br > 0 {
            path.addArc(
                withCenter: CGPoint(x: maxX - br, y: maxY - br),
                radius: br,
                startAngle: 0,
                endAngle: .pi/2,
                clockwise: true
            )
        }

        // ----- 下边（BOTTOM）-----
        if showsArrow && arrowDirection == .bottom {
            let (p1, tip, p2) = arrowPoints(rect: rect)
            path.addLine(to: p2)
            addArrowBorder(path, from: p2, tip: tip, to: p1)
            path.addLine(to: CGPoint(x: minX + bl, y: maxY))
        } else {
            path.addLine(to: CGPoint(x: minX + bl, y: maxY))
        }

        // 左下角
        if bl > 0 {
            path.addArc(
                withCenter: CGPoint(x: minX + bl, y: maxY - bl),
                radius: bl,
                startAngle: .pi/2,
                endAngle: .pi,
                clockwise: true
            )
        }

        // ----- 左边（LEFT）-----
        if showsArrow && arrowDirection == .left {
            let (p1, tip, p2) = arrowPoints(rect: rect)
            path.addLine(to: p2)
            addArrowBorder(path, from: p2, tip: tip, to: p1)
            path.addLine(to: CGPoint(x: minX, y: minY + tl))
        } else {
            path.addLine(to: CGPoint(x: minX, y: minY + tl))
        }

        // 左上角
        if tl > 0 {
            path.addArc(
                withCenter: CGPoint(x: minX + tl, y: minY + tl),
                radius: tl,
                startAngle: .pi,
                endAngle: -.pi/2,
                clockwise: true
            )
        }

        path.close()
    }

    /// 添加箭头边框的两条边（从 p1 到 尖点tip 再到 p2），支持尖角圆角
    private func addArrowBorder(_ path: UIBezierPath,
                               from p1: CGPoint,
                               tip: CGPoint,
                               to p2: CGPoint) {
        if arrowTipRadius > 0 {
            addRoundedArrow(path, from: p1, tip: tip, to: p2)
        } else {
            path.addLine(to: tip)
            path.addLine(to: p2)
        }
    }

    /**
     根据当前箭头方向和偏移量，计算箭头的三个关键点（左底点，尖点，右底点）
     - Parameter rect: 气泡主体矩形（不含箭头占位）
     - Returns: 元组 (p1, tip, p2)
     */
    private func arrowPoints(rect: CGRect) -> (CGPoint, CGPoint, CGPoint) {
        let arrowW = arrowSize.width
        let arrowH = arrowSize.height

        switch arrowDirection {
        case .top, .bottom:
            // 水平方向箭头，需考虑圆角和安全边距，防止箭头盖过圆角
            let safeInset = max(cornerRadius, arrowEdgePadding)
            let minX = rect.minX + safeInset + arrowW / 2
            let maxX = rect.maxX - safeInset - arrowW / 2

            // 中心点偏移，并限制在安全范围内
            let rawCenterX = rect.midX + arrowOffset
            let centerX = min(max(rawCenterX, minX), maxX)

            if arrowDirection == .top {
                return (
                    CGPoint(x: centerX - arrowW / 2, y: rect.minY),
                    CGPoint(x: centerX, y: rect.minY - arrowH),
                    CGPoint(x: centerX + arrowW / 2, y: rect.minY)
                )
            } else {
                return (
                    CGPoint(x: centerX - arrowW / 2, y: rect.maxY),
                    CGPoint(x: centerX, y: rect.maxY + arrowH),
                    CGPoint(x: centerX + arrowW / 2, y: rect.maxY)
                )
            }

        case .left, .right:
            // 垂直方向箭头
            let safeInset = max(cornerRadius, arrowEdgePadding)
            let minY = rect.minY + safeInset + arrowW / 2
            let maxY = rect.maxY - safeInset - arrowW / 2

            let rawCenterY = rect.midY + arrowOffset
            let centerY = min(max(rawCenterY, minY), maxY)

            if arrowDirection == .left {
                return (
                    CGPoint(x: rect.minX, y: centerY - arrowW / 2),
                    CGPoint(x: rect.minX - arrowH, y: centerY),
                    CGPoint(x: rect.minX, y: centerY + arrowW / 2)
                )
            } else {
                return (
                    CGPoint(x: rect.maxX, y: centerY - arrowW / 2),
                    CGPoint(x: rect.maxX + arrowH, y: centerY),
                    CGPoint(x: rect.maxX, y: centerY + arrowW / 2)
                )
            }
        }
    }
    
    /// 构建带“真实圆角”的箭头（核心算法）(原理：在尖点两侧截断，然后用圆弧连接)
    private func addRoundedArrow(_ path: UIBezierPath,
                                 from p1: CGPoint,
                                 tip: CGPoint,
                                 to p2: CGPoint) {
        // 向量
        let v1 = CGPoint(x: p1.x - tip.x, y: p1.y - tip.y)
        let v2 = CGPoint(x: p2.x - tip.x, y: p2.y - tip.y)
        
        // 长度
        let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard len1 > 0, len2 > 0 else {
            path.addLine(to: tip)
            path.addLine(to: p2)
            return
        }
        
        // 归一化
        let n1 = CGPoint(x: v1.x / len1, y: v1.y / len1)
        let n2 = CGPoint(x: v2.x / len2, y: v2.y / len2)
        
        // 限制最大半径
        let maxRadius = min(len1, len2) * 0.9
        let radius = min(arrowTipRadius, maxRadius)
        
        // 截断点
        let t1 = CGPoint(x: tip.x + n1.x * radius,
                         y: tip.y + n1.y * radius)
        
        let t2 = CGPoint(x: tip.x + n2.x * radius,
                         y: tip.y + n2.y * radius)
        
        // 先到截断点1
        path.addLine(to: t1)
        
        // 再画圆弧到截断点2（用二次曲线近似）
        path.addQuadCurve(to: t2, controlPoint: tip)
        
        // 最后连到 p2
        path.addLine(to: p2)
    }
}
