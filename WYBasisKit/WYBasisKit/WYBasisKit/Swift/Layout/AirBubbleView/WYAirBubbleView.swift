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
    
    /**
     渐变色数组（为空则不启用渐变）
     
     - Note:
     当不为空时：
       - 使用 CAGradientLayer + mask 渲染
       - fillColor 将被忽略
       - 渐变区域完全受气泡路径裁剪
     */
    public var gradientColors: [UIColor] = [] {
        didSet {
            // 渐变色数组小于两个，直接走 fillColor 流程
            guard gradientColors.count > 1 else {
                
                if let color = gradientColors.first {
                    fillColor = color
                }
                
                // 不管是否为空，都必须调用一次updateStyle，否则渐变色不会被清除
                updateStyle()
                
                return
            }
            
            updateStyle()
            updatePath()
        }
    }
    
    /// 渐变色方向
    public var gradientDirection: WYGradientDirection = .leftToRight {
        didSet {
            guard gradientColors.count > 1 else { return }
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
    public internal(set) var bubblePath: CGPath?
    
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

    /// 布局子视图时调用，检测 bounds 变化并更新路径
    public override func layoutSubviews() {
        super.layoutSubviews()

        // 只有 bounds 真正改变时才重算路径，避免不必要的性能开销
        guard bounds != lastBounds else { return }
        lastBounds = bounds

        // 安全尺寸检查
        checkMinimumSize()

        if gradientColors.count > 1 {
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

    /// 用于渲染填充颜色的 CAShapeLayer（包括普通颜色和渐变色的背景层）
    let fillLayer = CAShapeLayer()
    
    /// 用于渲染边框的 CAShapeLayer（独立于填充层，以便分别控制颜色和线宽）
    let borderLayer = CAShapeLayer()
    
    /// 渐变图层（仅在 gradientColors 非空时启用）
    let gradientLayer = CAGradientLayer()
    
    /// 专用 mask（不能复用 fillLayer！）
    let maskLayer = CAShapeLayer()
    
    /// 记录当前View的Bounds，用于在 layoutSubviews 中判断尺寸是否真正发生变化，避免重复更新路径
    var lastBounds: CGRect = .zero
    
    /// 重用的 UIBezierPath 实例，避免频繁创建对象，提高性能
    let reusablePath = UIBezierPath()
    
    /// 专用于边框的复用路径（避免重复创建）
    let borderReusablePath = UIBezierPath()

}
