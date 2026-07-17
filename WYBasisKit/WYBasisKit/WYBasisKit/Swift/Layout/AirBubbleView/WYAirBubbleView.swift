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

/// 气泡视图：支持圆角、边框、带三角箭头，箭头可设置方向、尺寸、偏移和圆角等
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
    
    /// 气泡边框的颜色，默认透明
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
    
    /// 渐变色数组（为空则不启用渐变）
    ///
    /// - Note:
    /// 当不为空时：
    /// - 使用 CAGradientLayer + mask 渲染
    /// - fillColor 将被忽略
    /// - 渐变区域完全受气泡路径裁剪
    public var gradientColors: [UIColor] = [] {
        didSet {
            updateStyle()
            updatePath()
        }
    }
    
    /// 渐变色方向
    public var gradientDirection: WYGradientDirection = .leftToRight {
        didSet {
            updateGradientDirection()
            updatePath()
        }
    }
    
    /// 阴影颜色（为 nil 时不显示阴影）
    public var shadowColor: UIColor? = nil {
        didSet {
            updateShadow()
        }
    }
    
    /// 阴影偏移度 默认CGSize.zero (width : 为正数时，向右偏移，为负数时，向左偏移，height : 为正数时，向下偏移，为负数时，向上偏移)
    public var shadowOffset: CGSize = .zero {
        didSet {
            updateShadow()
        }
    }
    
    /// 阴影模糊半径 默认0.0，需要大于0才会有阴影扩散效果(阴影才可见)
    public var shadowRadius: CGFloat = 0.0 {
        didSet {
            updateShadow()
        }
    }
    
    /// 阴影透明度，默认0.5，取值范围0~1
    public var shadowOpacity: CGFloat = 0.5 {
        didSet {
            updateShadow()
        }
    }
    
    /**
     当前气泡的路径（用于外部 hitTest / mask / 动画对齐等）

     - Note:
     仅在视图完成 layout（bounds > 0）后有效
     在初始化或约束未生效前可能为 nil

     - Tip:
     若需要获取稳定路径，建议在布局完成后（如 layoutSubviews / Task @MainActor）访问
     */
    public private(set) var bubblePath: CGPath?
    
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
    
    /// 渐变图层（仅在 gradientColors 非空时启用）
    private let gradientLayer = CAGradientLayer()
    
    /// 专用 mask（不能复用 fillLayer！）
    private let maskLayer = CAShapeLayer()
    
    /// 记录当前View的Bounds，用于在 layoutSubviews 中判断尺寸是否真正发生变化，避免重复更新路径
    private var lastBounds: CGRect = .zero
    
    /// 重用的 UIBezierPath 实例，避免频繁创建对象，提高性能
    private let reusablePath = UIBezierPath()
    
    /// 专用于边框的复用路径（避免重复创建）
    private let borderReusablePath = UIBezierPath()
    
    /// 布局子视图时调用，检测 bounds 变化并更新路径
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 只有 bounds 真正改变时才重算路径，避免不必要的性能开销
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        
        if !gradientColors.isEmpty {
            // 关闭隐式动画，否则有渐变的时候动画会不自然(如动画中圆角不显示)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gradientLayer.frame = bounds
            maskLayer.frame = bounds
            CATransaction.commit()
        }else {
            // 防止之前有残留 frame/动画
            gradientLayer.removeAllAnimations()
            maskLayer.removeAllAnimations()
            // 避免旧 mask 残留
            gradientLayer.mask = nil
        }
        
        // 当视图尺寸变化时重新计算路径
        updatePath()
    }
    
    /// 配置图层属性（背景透明、添加子图层、设置边框样式）
    private func setupLayer() {
        backgroundColor = .clear
        
        layer.addSublayer(borderLayer)
        layer.addSublayer(fillLayer)
        
        // 边框层无需填充（仅描边）
        borderLayer.fillColor = nil
        // 设置为miter才能保证尖角突出部分不被裁剪
        borderLayer.lineJoin = .miter
        borderLayer.lineCap = .round
        
        gradientLayer.isHidden = true
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        updateStyle()
        updateShadow()
    }
    
    /// 更新填充色和边框样式（不涉及路径几何）
    private func updateStyle() {
        
        if gradientColors.isEmpty {
            // 无渐变时使用普通填充色（最高性能路径）
            fillLayer.isHidden = false
            fillLayer.fillColor = fillColor.cgColor
            
            // 移除 gradientLayer
            if gradientLayer.superlayer != nil {
                gradientLayer.removeFromSuperlayer()
            }
            // 清理 mask（避免残留引用）
            gradientLayer.mask = nil
            maskLayer.removeAllAnimations()
            maskLayer.path = nil
        } else {
            // 有渐变时，使用 CAGradientLayer + mask 渲染
            fillLayer.isHidden = true
            
            // gradientLayer只在不存在时插入
            if gradientLayer.superlayer == nil {
                layer.insertSublayer(gradientLayer, above: borderLayer)
            }
            gradientLayer.isHidden = false
            gradientLayer.colors = gradientColors.map { $0.cgColor }
            // 保证尺寸永远正确
            if gradientLayer.frame != bounds {
                gradientLayer.frame = bounds
            }
        }
        
        borderLayer.strokeColor = borderColor.cgColor
        // stroke 是居中绘制边框（内外各一半），而fillLayer 会遮掉内侧一半，所以这里 *2 才能保证视觉宽度正确
        borderLayer.lineWidth = borderWidth * 2
        
        // 边框宽度为0时隐藏（避免不必要渲染）
        borderLayer.isHidden = borderWidth <= 0
    }
    
    /// 更新气泡的完整路径（气泡主体圆角矩形 + 箭头）
    ///
    /// - Responsibilities:
    /// - 构建填充路径（fillLayer / maskLayer）
    /// - 构建边框路径（borderLayer）
    /// - 在 UIView.animate 环境下添加平滑过渡动画
    /// - 同步更新 shadowPath
    /// - 更新对外暴露的 bubblePath
    ///
    /// - Note:
    /// - 该方法是组件的核心渲染入口
    /// - 会根据当前状态（渐变 / 普通填充）自动选择最优渲染路径
    private func updatePath() {
        // 尺寸不足时清空路径，避免绘制异常
        guard bounds.width > 0,
              bounds.height > 0,
              bounds.width > arrowSize.width,
              bounds.height > arrowSize.height else {
            fillLayer.path = nil
            borderLayer.path = nil
            bubblePath = nil
            
            // 同步清空渐变 mask
            if !gradientColors.isEmpty {
                maskLayer.path = nil
            }
            return
        }
        
        // 保证 maskLayer 尺寸正确（避免极端情况下错位
        if !gradientColors.isEmpty, maskLayer.frame != bounds {
            maskLayer.frame = bounds
        }
        
        // 计算除去箭头占位后的气泡主体矩形
        let rect = bubbleRect()
        
        // 构建统一填充路径（圆角 + 箭头）
        reusablePath.removeAllPoints()
        
        // 填充路径：必须包含箭头底边（闭合形状）
        buildBorderPath(reusablePath,
                        rect: rect,
                        includeArrowBaseEdge: true)
        
        let newPath = reusablePath.cgPath
        
        // 渐变图层布局
        if (!gradientColors.isEmpty) && (gradientLayer.mask !== maskLayer) {
            gradientLayer.mask = maskLayer
        }
        
        // 是否正在执行UIView.animate动画
        let isInUIViewAnimation = UIView.inheritedAnimationDuration > 0
        
        if isInUIViewAnimation {
            let animationKey = "AirBubbleAnimationKey"
            
            // 清理旧动画（先移除
            borderLayer.removeAnimation(forKey: animationKey)
            fillLayer.removeAnimation(forKey: animationKey)
            maskLayer.removeAnimation(forKey: animationKey)
            gradientLayer.removeAnimation(forKey: animationKey)
            
            // 添加动画（每个 layer 独立实例)
            if gradientColors.isEmpty {
                fillLayer.add(makeGroup(for: fillLayer, newPath: newPath), forKey: animationKey)
            } else {
                // 渐变模式只需要 maskLayer 动画
                maskLayer.add(makeGroup(for: maskLayer, newPath: newPath), forKey: animationKey)
                gradientLayer.add(makeGroup(for: gradientLayer, newPath: newPath), forKey: animationKey)
            }
            
            // 边框始终需要动画
            borderLayer.add(makeGroup(for: borderLayer, newPath: newPath), forKey: animationKey)
        }
        
        // 禁用隐式动画（防止 layer 属性更新触发额外动画）
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        fillLayer.path = newPath
        
        borderReusablePath.removeAllPoints()
        
        // 边框路径
        buildBorderPath(borderReusablePath,
                        rect: rect,
                        includeArrowBaseEdge: true)
        
        borderLayer.path = borderReusablePath.cgPath
        
        // 渐变模式下同步 mask path
        if !gradientColors.isEmpty {
            maskLayer.path = newPath
        }
        
        CATransaction.commit()
        
        // 对外暴露路径（用于 hitTest / mask 等）
        bubblePath = newPath
        
        // 同步更新阴影路径（保证阴影和气泡完全一致）
        if shadowColor != nil && shadowOpacity > 0 {
            layer.shadowPath = newPath
        }
    }
    
    /// 修改渐变色方向
    private func updateGradientDirection() {
        switch gradientDirection {
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            
        case .leftToLowRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
        case .rightToLowLeft:
            gradientLayer.startPoint = CGPoint(x: 1, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        }
    }
    
    /// 更新阴影（只负责 layer 样式，不参与 path 计算）
    private func updateShadow() {
        
        // 如果没有设置颜色 or opacity 为 0，则关闭阴影（提升性能）
        guard let color = shadowColor, shadowOpacity > 0 else {
            layer.shadowOpacity = 0
            layer.shadowColor = nil
            layer.shadowPath = nil
            return
        }
        
        layer.shadowColor = color.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = Float(min(max(shadowOpacity, 0), 1)) // clamp 0~1
        
        // 使用 shadowPath（性能提升非常大）
        layer.shadowPath = bubblePath
    }
    
    /// 构建动画组（每个 layer 必须使用独立实例）
    ///
    /// - Important:
    /// CAAnimation 在 add 到 layer 时会被 copy，
    /// 若多个 layer 复用同一个实例，可能导致 beginTime 不一致，
    /// 从而产生动画不同步或闪烁问题
    private func makeGroup(for layer: CALayer, newPath: CGPath) -> CAAnimationGroup {
        
        // path 动画
        let pathAnimation = CABasicAnimation(keyPath: "path")
        
        // 根据当前 layer 取各自的 fromValue（保证动画完全同步）
        if let shape = layer as? CAShapeLayer {
            pathAnimation.fromValue = shape.presentation()?.path ?? shape.path
        } else {
            pathAnimation.fromValue = nil
        }
        
        pathAnimation.toValue = newPath
        
        let group = CAAnimationGroup()
        
        if gradientColors.isEmpty {
            // 无渐变：只需要 path 动画
            group.animations = [pathAnimation]
        } else {
            // bounds 动画（gradient 专用)
            let boundsAnimation = CABasicAnimation(keyPath: "bounds")
            boundsAnimation.fromValue = gradientLayer.presentation()?.bounds ?? gradientLayer.bounds
            boundsAnimation.toValue = CGRect(origin: .zero, size: bounds.size)
            
            // position 动画
            let posAnimation = CABasicAnimation(keyPath: "position")
            posAnimation.fromValue = gradientLayer.presentation()?.position ?? gradientLayer.position
            posAnimation.toValue = CGPoint(x: bounds.midX, y: bounds.midY)
            
            group.animations = [pathAnimation, boundsAnimation, posAnimation]
        }
        
        group.duration = UIView.inheritedAnimationDuration
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // 保证时间轴稳定（避免偶发不同步）
        group.beginTime = 0
        group.isRemovedOnCompletion = true
        group.fillMode = .removed
        
        return group
    }
    
    /**
     计算气泡主体矩形（扣除箭头占据的区域）
     - Returns: 气泡主体部分的 CGRect，不包含箭头
     */
    private func bubbleRect() -> CGRect {
        var rect = bounds
        let halfBorder = borderWidth / 2
        rect = rect.insetBy(dx: halfBorder, dy: halfBorder)
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
     完整构建路径（气泡主体 + 箭头）
     
     - Parameters:
     - path: 空的 UIBezierPath，用于接收构建的路径
     - rect: 气泡主体矩形
     - includeArrowBaseEdge:
     是否包含箭头底边：
     - true：用于填充（fillLayer）
     - false：用于边框（borderLayer），避免出现内部边
     */
    private func buildBorderPath(_ path: UIBezierPath,
                                 rect: CGRect,
                                 includeArrowBaseEdge: Bool) {
        
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
        
        // 缓存箭头关键点（避免重复计算）
        let arrow = (showsArrow ? arrowPoints(rect: rect) : nil)
        
        // 从左上角开始
        path.move(to: CGPoint(x: minX + tl, y: minY))
        
        // 上边（TOP)
        if showsArrow && arrowDirection == .top, let (p1, tip, p2) = arrow {
            path.addLine(to: p1)
            addArrowPath(path,
                         from: p1,
                         tip: tip,
                         to: p2,
                         includeBase: includeArrowBaseEdge)
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
        
        // 右边（RIGHT）
        if showsArrow && arrowDirection == .right, let (p1, tip, p2) = arrow {
            path.addLine(to: p1)
            addArrowPath(path,
                         from: p1,
                         tip: tip,
                         to: p2,
                         includeBase: includeArrowBaseEdge)
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
        
        // 下边（BOTTOM）
        if showsArrow && arrowDirection == .bottom, let (p1, tip, p2) = arrow {
            
            // 必须从 p2 开始
            path.addLine(to: p2)
            
            addArrowPath(path,
                         from: p2,   // 反向
                         tip: tip,
                         to: p1,     // 反向
                         includeBase: includeArrowBaseEdge)
            
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
        
        // 左边（LEFT）
        if showsArrow && arrowDirection == .left, let (p1, tip, p2) = arrow {
            
            // 必须从 p2 开始
            path.addLine(to: p2)
            
            addArrowPath(path,
                         from: p2,   // 反向
                         tip: tip,
                         to: p1,     // 反向
                         includeBase: includeArrowBaseEdge)
            
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
    
    /**
     添加箭头路径（支持是否包含“底边”）
     
     说明：
     - includeBase = true：
     用于 fillLayer（填充路径），必须闭合三角形
     
     - includeBase = false：
     用于 borderLayer（边框路径），不绘制底边，
     从而避免“箭头与气泡连接处出现边框”的问题
     
     - Parameters:
     - path: 当前路径
     - p1: 箭头底边左点
     - tip: 箭头尖点
     - p2: 箭头底边右点
     - includeBase: 是否包含底边
     */
    private func addArrowPath(_ path: UIBezierPath,
                              from p1: CGPoint,
                              tip: CGPoint,
                              to p2: CGPoint,
                              includeBase: Bool) {
        
        // 先绘制两条边（p1 → tip → p2）
        if arrowTipRadius > 0 {
            // 若设置了尖角圆角，则绘制圆角箭头
            addRoundedArrow(path, from: p1, tip: tip, to: p2)
        } else {
            // 普通尖角
            path.addLine(to: tip)
            path.addLine(to: p2)
        }
        
        // 仅在需要“完整闭合路径”（填充）时，才补回底边
        if includeBase {
            path.addLine(to: p1)
        }
    }
    
    /**
     根据当前箭头方向和偏移量，计算箭头的三个关键点（底边左点 / 尖点 / 底边右点），用于路径拼接
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
        
        // 对箭头尺寸做像素对齐，避免出现半像素
        let arrowW = pixelAlign(min(arrowSize.width, rect.width))
        let arrowH = pixelAlign(min(arrowSize.height, rect.height))
        
        // 让箭头与气泡主体轻微重叠，彻底消除抗锯齿缝隙
        let overlap = 0.5 / UIApplication.shared.wy_keyWindow.screen.scale
        
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
                let centerX = pixelAlign(rect.midX)
                
                if arrowDirection == .top {
                    return (
                        CGPoint(
                            x: pixelAlign(centerX - arrowW / 2),
                            y: pixelAlign(rect.minY + overlap)
                        ),
                        CGPoint(
                            x: pixelAlign(centerX),
                            y: pixelAlign(rect.minY - arrowH + overlap)
                        ),
                        CGPoint(
                            x: pixelAlign(centerX + arrowW / 2),
                            y: pixelAlign(rect.minY + overlap)
                        )
                    )
                } else {
                    return (
                        CGPoint(
                            x: pixelAlign(centerX - arrowW / 2),
                            y: pixelAlign(rect.maxY - overlap)
                        ),
                        CGPoint(
                            x: pixelAlign(centerX),
                            y: pixelAlign(rect.maxY + arrowH - overlap)
                        ),
                        CGPoint(
                            x: pixelAlign(centerX + arrowW / 2),
                            y: pixelAlign(rect.maxY - overlap)
                        )
                    )
                }
            }
            
            // 原始中心点（带偏移）
            let rawCenterX = rect.midX + arrowOffset
            
            // clamp + 像素对齐
            let centerX = pixelAlign(min(max(rawCenterX, minCenter), maxCenter))
            
            if arrowDirection == .top {
                return (
                    CGPoint(
                        x: pixelAlign(centerX - arrowW / 2),
                        y: pixelAlign(rect.minY + overlap)
                    ),
                    CGPoint(
                        x: pixelAlign(centerX),
                        y: pixelAlign(rect.minY - arrowH + overlap)
                    ),
                    CGPoint(
                        x: pixelAlign(centerX + arrowW / 2),
                        y: pixelAlign(rect.minY + overlap)
                    )
                )
            } else {
                return (
                    CGPoint(
                        x: pixelAlign(centerX - arrowW / 2),
                        y: pixelAlign(rect.maxY - overlap)
                    ),
                    CGPoint(
                        x: pixelAlign(centerX),
                        y: pixelAlign(rect.maxY + arrowH - overlap)
                    ),
                    CGPoint(
                        x: pixelAlign(centerX + arrowW / 2),
                        y: pixelAlign(rect.maxY - overlap)
                    )
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
                let centerY = pixelAlign(rect.midY)
                
                if arrowDirection == .left {
                    return (
                        CGPoint(
                            x: pixelAlign(rect.minX + overlap),
                            y: pixelAlign(centerY - arrowW / 2)
                        ),
                        CGPoint(
                            x: pixelAlign(rect.minX - arrowH + overlap),
                            y: pixelAlign(centerY)
                        ),
                        CGPoint(
                            x: pixelAlign(rect.minX + overlap),
                            y: pixelAlign(centerY + arrowW / 2)
                        )
                    )
                } else {
                    return (
                        CGPoint(
                            x: pixelAlign(rect.maxX - overlap),
                            y: pixelAlign(centerY - arrowW / 2)
                        ),
                        CGPoint(
                            x: pixelAlign(rect.maxX + arrowH - overlap),
                            y: pixelAlign(centerY)
                        ),
                        CGPoint(
                            x: pixelAlign(rect.maxX - overlap),
                            y: pixelAlign(centerY + arrowW / 2)
                        )
                    )
                }
            }
            
            let rawCenterY = rect.midY + arrowOffset
            let centerY = pixelAlign(min(max(rawCenterY, minCenter), maxCenter))
            
            if arrowDirection == .left {
                return (
                    CGPoint(
                        x: pixelAlign(rect.minX + overlap),
                        y: pixelAlign(centerY - arrowW / 2)
                    ),
                    CGPoint(
                        x: pixelAlign(rect.minX - arrowH + overlap),
                        y: pixelAlign(centerY)
                    ),
                    CGPoint(
                        x: pixelAlign(rect.minX + overlap),
                        y: pixelAlign(centerY + arrowW / 2)
                    )
                )
            } else {
                return (
                    CGPoint(
                        x: pixelAlign(rect.maxX - overlap),
                        y: pixelAlign(centerY - arrowW / 2)
                    ),
                    CGPoint(
                        x: pixelAlign(rect.maxX + arrowH - overlap),
                        y: pixelAlign(centerY)
                    ),
                    CGPoint(
                        x: pixelAlign(rect.maxX - overlap),
                        y: pixelAlign(centerY + arrowW / 2)
                    )
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
    
    /// 像素对齐（Pixel Align）
    ///
    /// - Purpose:
    /// 将坐标对齐到设备像素网格，避免出现 0.5pt 导致的模糊或细线缝隙
    private func pixelAlign(_ value: CGFloat) -> CGFloat {
        let scale = UIApplication.shared.wy_keyWindow.screen.scale
        return round(value * scale) / scale
    }
}
