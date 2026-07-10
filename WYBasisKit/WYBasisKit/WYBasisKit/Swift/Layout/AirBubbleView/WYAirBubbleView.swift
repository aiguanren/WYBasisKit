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
        didSet {
            updateStyle()
            // 只要“可能影响显示”，就刷新 path
            if oldValue <= 0 || borderWidth <= 0 {
                updatePath()
            }
        }
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
    
    /// 渐变色数组(为空则不显示)
    public var gradientColors: [UIColor] = [] {
        didSet {
            updateStyle()
            setNeedsDisplay()
        }
    }

    /// 渐变色方向
    public var gradientDirection: WYGradientDirection = .leftToRight {
        didSet { setNeedsDisplay() }
    }

    /**
     当前气泡的路径（用于外部做 shadow / 命中检测 / 自定义 mask 等）
     规则：
     - Note:
       仅在视图完成 layout（bounds > 0）后才有有效值
       若在初始化或约束未生效前获取，可能为 nil
       也可以在Task { @MainActor 里面获取使用
     */
    public private(set) var bubblePath: CGPath?
    
    /**
     是否启用气泡 path 动画(如果设置了渐变色(既：gradientColors 不为空)时可以不用开启也能支持path动画)
     规则：
     - 开启时：在视图尺寸（frame/bounds/约束）变化过程中，path
       会做同步动画，保证气泡形变平滑
     - 关闭时：path 直接更新，不执行动画（适用于列表滚动等性能敏感场景）
     
     - Note:
       用于避免 CAShapeLayer 隐式动画在尺寸变化时出现的异常（如放大/回弹）
     */
    public var enablePathAnimation: Bool = false

    /// 便捷初始化方法
    public convenience init() {
        self.init(frame: .zero)
    }
    
    /// 指定初始化方法，通过 frame 创建视图
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    /// 从故事板或 XIB 加载时所需的初始化方法
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    /// 用于渲染填充颜色的 CAShapeLayer（包括普通颜色和渐变色的背景层）
    private let fillLayer = CAShapeLayer()

    /// 用于渲染边框的 CAShapeLayer（独立于填充层，以便分别控制颜色和线宽）
    private let borderLayer = CAShapeLayer()
    
    /// 记录当前View的Bounds，用于在 layoutSubviews 中判断尺寸是否真正发生变化，避免重复更新路径
    private var lastBounds: CGRect = .zero
    
    /// 重用的 UIBezierPath 实例，避免频繁创建对象，提高性能
    private let reusablePath = UIBezierPath()

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

    /// 布局子视图时调用，检测 bounds 变化并更新路径
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 只有 bounds 真正改变时才重算路径，避免不必要的性能开销
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        
        // 当视图尺寸变化时重新计算路径
        updatePath()
    }

    /// 更新填充色和边框样式（不涉及路径几何）
    private func updateStyle() {
        
        if gradientColors.isEmpty {
            // 无渐变时使用普通填充色
            fillLayer.fillColor = fillColor.cgColor
        } else {
            // 有渐变时，填充层颜色置为透明，由 draw(_:) 绘制渐变
            fillLayer.fillColor = UIColor.clear.cgColor
        }
        
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        
        // 边框宽度为0时隐藏（避免不必要渲染）
        borderLayer.isHidden = borderWidth <= 0
    }

    /// 更新所有几何路径（气泡主体圆角矩形 + 箭头），并重新赋值给对应图层
    private func updatePath() {
        // 尺寸不足时清空路径，避免绘制异常
        guard bounds.width > 0,
              bounds.height > 0,
              bounds.width > arrowSize.width,
              bounds.height > arrowSize.height else {
            fillLayer.path = nil
            borderLayer.path = nil
            bubblePath = nil
            return
        }

        // 计算除去箭头占位后的气泡主体矩形
        let rect = bubbleRect()

        // 构建统一填充路径（圆角 + 箭头）
        reusablePath.removeAllPoints()
        buildBorderPath(reusablePath, rect: rect)
        
        let newPath = reusablePath.cgPath
        
        if enablePathAnimation {
            // 使用显式动画，避免隐式动画导致的尺寸异常（放大/回弹问题）
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = fillLayer.presentation()?.path ?? fillLayer.path
            animation.toValue = newPath
            animation.duration = CATransaction.animationDuration()
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // 动画key，用于区分不同动画
            let animationKey = "AirBubbleAnimationKey"
            
            // 避免多次 layout 时动画叠加
            fillLayer.removeAnimation(forKey: animationKey)
            borderLayer.removeAnimation(forKey: animationKey)
            
            fillLayer.add(animation, forKey: animationKey)
            borderLayer.add(animation, forKey: animationKey)
        }

        // 仅在路径发生变化时赋值，减少不必要的图层刷新
        if fillLayer.path !== newPath {
            fillLayer.path = newPath
        }

        // 只有在需要边框时才赋值（避免不必要渲染开销）
        borderLayer.path = newPath
        borderLayer.isHidden = (borderWidth <= 0)
        
        // 对外暴露路径（用于 shadow / hitTest / mask 等），同时确保对外暴露的 path 一定是最新
        bubblePath = newPath
        
        setNeedsDisplay()
    }

    /**
     计算气泡主体矩形（扣除箭头占据的区域）
     - Returns: 气泡主体部分的 CGRect，不包含箭头
     */
    private func bubbleRect() -> CGRect {
        var rect = bounds
        guard showsArrow else { return rect }

        // 根据箭头方向，从对应边缩进箭头高度，使主体矩形避开箭头区域
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

        // 右上角圆弧
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

        // 右下角圆弧
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

        // 左下角圆弧
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

        // 左上角圆弧
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
            // 若设置了尖角圆角，则调用专门的方法绘制带圆角的箭头
            addRoundedArrow(path, from: p1, tip: tip, to: p2)
        } else {
            // 否则直接折线连接
            path.addLine(to: tip)
            path.addLine(to: p2)
        }
    }

    /**
     根据当前箭头方向和偏移量，计算箭头的三个关键点（左底点，尖点，右底点）
     - Parameter rect: 气泡主体矩形（不含箭头占位）
     - Returns: 元组 (p1, tip, p2)
     
     安全规则：
     1. 箭头必须避开圆角区域（cornerRadius）
     2. 箭头必须遵守 arrowEdgePadding
     3. 在尺寸不足时自动降级（居中）
     4. 对 safeInset 做 clamp，避免超出可用空间
     5. 对 arrowOffset 做 clamp，防止越界
     */
    private func arrowPoints(rect: CGRect) -> (CGPoint, CGPoint, CGPoint) {
        
        let arrowW = min(arrowSize.width, rect.width)
        let arrowH = min(arrowSize.height, rect.height)

        switch arrowDirection {
            
        case .top, .bottom:
            
            // 期望的安全边距（圆角 & 外部设置）
            let desiredInset = max(cornerRadius, arrowEdgePadding)
            
            // 最大允许 inset（避免超过可用空间）
            let maxInset = max(0, (rect.width - arrowW) / 2)
            
            // clamp 后的安全 inset
            let safeInset = min(desiredInset, maxInset)
            
            let minCenter = rect.minX + safeInset + arrowW / 2
            let maxCenter = rect.maxX - safeInset - arrowW / 2
            
            // 极端情况兜底（宽度不足，直接居中）
            guard minCenter < maxCenter else {
                let centerX = rect.midX
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
            }
            
            // 原始中心点（带偏移）
            let rawCenterX = rect.midX + arrowOffset
            
            // clamp 到安全范围内
            let centerX = min(max(rawCenterX, minCenter), maxCenter)
            
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
            
            let desiredInset = max(cornerRadius, arrowEdgePadding)
            let maxInset = max(0, (rect.height - arrowW) / 2)
            let safeInset = min(desiredInset, maxInset)
            
            let minCenter = rect.minY + safeInset + arrowW / 2
            let maxCenter = rect.maxY - safeInset - arrowW / 2
            
            // 极端情况兜底（高度不足，居中）
            guard minCenter < maxCenter else {
                let centerY = rect.midY
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
            
            let rawCenterY = rect.midY + arrowOffset
            let centerY = min(max(rawCenterY, minCenter), maxCenter)
            
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
    
    /**
     构建带“真实圆角”的箭头（核心算法）
     原理：在尖点两侧截断，然后用二次贝塞尔曲线（或圆弧）连接截断点，形成平滑圆角
     */
    private func addRoundedArrow(_ path: UIBezierPath,
                                 from p1: CGPoint,
                                 tip: CGPoint,
                                 to p2: CGPoint) {
        // 计算从尖点到两个底点的向量
        let v1 = CGPoint(x: p1.x - tip.x, y: p1.y - tip.y)
        let v2 = CGPoint(x: p2.x - tip.x, y: p2.y - tip.y)
        
        // 计算向量长度
        let len1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let len2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        // 若长度为0（点重合），直接连线避免崩溃
        guard len1 > 0, len2 > 0 else {
            path.addLine(to: tip)
            path.addLine(to: p2)
            return
        }
        
        // 归一化方向向量
        let n1 = CGPoint(x: v1.x / len1, y: v1.y / len1)
        let n2 = CGPoint(x: v2.x / len2, y: v2.y / len2)
        
        // 限制最大半径，不能超过边长的一半，以免截断点超过底点
        let maxRadius = min(len1, len2) * 0.9
        let radius = min(arrowTipRadius, maxRadius)
        
        // 计算截断点（从尖点沿两边方向偏移 radius）
        let t1 = CGPoint(x: tip.x + n1.x * radius,
                         y: tip.y + n1.y * radius)
        let t2 = CGPoint(x: tip.x + n2.x * radius,
                         y: tip.y + n2.y * radius)
        
        // 先到截断点1
        path.addLine(to: t1)
        
        // 用二次贝塞尔曲线从截断点1平滑过渡到截断点2，控制点为尖点本身
        path.addQuadCurve(to: t2, controlPoint: tip)
        
        // 最后连到 p2
        path.addLine(to: p2)
    }
    
    /**
     绘制气泡内容，支持渐变填充。当 `gradientColors` 非空时，在此方法中绘制渐变；
     否则由 `fillLayer` 负责普通填充（纯色），此方法不执行任何绘制，以优化性能。
     */
    public override func draw(_ rect: CGRect) {
        // 没有渐变，直接返回（完全避免 CPU 绘制）
        guard !gradientColors.isEmpty,
              let ctx = UIGraphicsGetCurrentContext(),
              let path = bubblePath else {
            return
        }
        
        ctx.saveGState()
        
        // 将当前绘制区域裁剪为气泡形状，使渐变只显示在路径内部
        ctx.addPath(path)
        ctx.clip()
        
        // ===== 绘制渐变 =====
        let colors = gradientColors.map { $0.cgColor } as CFArray
        let space = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: nil) else {
            return
        }
        
        // 根据 gradientDirection 计算起点和终点
        let (start, end) = gradientPoints()
        
        // 绘制线性渐变
        ctx.drawLinearGradient(
            gradient,
            start: start,
            end: end,
            options: []
        )
        
        ctx.restoreGState()
    }
    
    /**
     根据 `gradientDirection` 计算渐变绘制的起点和终点
     - Returns: 一个元组 (startPoint, endPoint)，分别对应渐变的起始和结束位置
     */
    private func gradientPoints() -> (CGPoint, CGPoint) {
        switch gradientDirection {
        case .leftToRight:
            return (
                CGPoint(x: 0, y: bounds.midY),
                CGPoint(x: bounds.maxX, y: bounds.midY)
            )
            
        case .topToBottom:
            return (
                CGPoint(x: bounds.midX, y: 0),
                CGPoint(x: bounds.midX, y: bounds.maxY)
            )
            
        case .leftToLowRight:
            return (
                CGPoint(x: 0, y: 0),
                CGPoint(x: bounds.maxX, y: bounds.maxY)
            )
            
        case .rightToLowLeft:
            return (
                CGPoint(x: bounds.maxX, y: 0),
                CGPoint(x: 0, y: bounds.maxY)
            )
        }
    }
}
