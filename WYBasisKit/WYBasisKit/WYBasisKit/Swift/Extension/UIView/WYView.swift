//
//  UIView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// 渐变方向
@frozen public enum WYGradientDirection: Int {
    /// 从左到右
    case leftToRight = 0
    /// 从上到下
    case topToBottom
    /// 左上到右下
    case leftToLowRight
    /// 右上到左下
    case rightToLowLeft
}

public extension UIView {

    /// view.width
    var wy_width: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
        get {
            return self.frame.size.width
        }
    }

    /// view.height
    var wy_height: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
        get {
            return self.frame.size.height
        }
    }

    /// view.origin.x
    var wy_left: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
        get {
            return self.frame.origin.x
        }
    }

    /// view.origin.x + view.width
    var wy_right: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue - frame.size.width
            self.frame = frame
        }
        get {
            return self.frame.origin.x + self.frame.size.width
        }
    }

    /// view.origin.y
    var wy_top: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
        get {
            return self.frame.origin.y
        }
    }

    /// view.origin.y + view.height
    var wy_bottom: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue - frame.size.height
            self.frame = frame
        }
        get {
            return self.frame.origin.y + self.frame.size.height
        }
    }

    /// view.center.x
    var wy_centerx: CGFloat {
        set {
            // 防视图带形变时定位不准(frame在形变下取的是包围盒)，直接改center才能命中真实中心点
            var center: CGPoint = self.center
            center.x = newValue
            self.center = center
        }
        get {
            return self.center.x
        }
    }

    /// view.center.y
    var wy_centery: CGFloat {
        set {
            // 防视图带形变时定位不准(frame在形变下取的是包围盒)，直接改center才能命中真实中心点
            var center: CGPoint = self.center
            center.y = newValue
            self.center = center
        }
        get {
            return self.center.y
        }
    }

    /// view.origin
    var wy_origin: CGPoint {
        set {
            var frame: CGRect = self.frame
            frame.origin = newValue
            self.frame = frame
        }
        get {
            return self.frame.origin
        }
    }

    /// view.size
    var wy_size: CGSize {
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
        get {
            return self.frame.size
        }
    }

    /**
     *  获取自定义控件所需要的换行数
     *
     *  @param total     总共有多少个自定义控件
     *
     *  @param perLine   每行显示多少个控件
     *
     */
    static func wy_numberOfLines(total: Int, perLine: Int) -> Int {
        // 防除零崩溃(total或perLine小于等于0时没有行数的意义，直接返回0)
        guard total > 0, perLine > 0 else {
            return 0
        }
        // 整数向上取整即为行数(正好整除时结果不变)
        return total / perLine + (total % perLine == 0 ? 0 : 1)
    }

    /// 移除所有子控件
    func wy_removeAllSubviews() {
        if subviews.isEmpty == false {
            subviews.forEach({$0.removeFromSuperview()})
        }
    }

    /// 移除自身及所有子控件
    func wy_removeFromSuperview() {
        wy_removeAllSubviews()
        removeFromSuperview()
    }

    /**
     *  防止View在短时间内快速重复点击(写在点击事件中才会生效)
     *
     *  @param duration   间隔时间
     *
     */
    func wy_temporarilyDisable(for duration: TimeInterval) {
        self.isUserInteractionEnabled = false
        Task { [weak self] in
            try? await Task.wy_delay(duration, cancelThrows: false, onMain: { [weak self] in
                self?.isUserInteractionEnabled = true
            })
        }
    }

    /// 添加手势点击事件
    @discardableResult
    func wy_addTapGesture(target: Any?, action: Selector?) -> UITapGestureRecognizer {
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: target, action: action)
        isUserInteractionEnabled = true
        addGestureRecognizer(gestureRecognizer)

        return gestureRecognizer
    }

    /// 添加收起键盘的手势
    @discardableResult
    func wy_gestureHidingkeyboard() -> UITapGestureRecognizer {
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(wy_keyboardHide))
        gestureRecognizer.numberOfTapsRequired = 1
        //设置成false表示当前控件响应后会传播到其他控件上，默认为true
        gestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(gestureRecognizer)

        return gestureRecognizer
    }

    @objc private func wy_keyboardHide() {
        endEditing(true)
    }
}

public extension UIView {

    /**
     *  指定位置添加边框(仅适合无圆角的UIView添加)
     *
     *  @param edges     要添加的边框的位置
     *
     *  @param color     要添加的边框的颜色
     *
     *  @param thickness 要添加的边框的宽度或高度
     *
     */
    func wy_addBorder(edges: UIRectEdge,
                      color: UIColor,
                      thickness: CGFloat) {
        guard !edges.intersection(.all).isEmpty else { return }
        guard thickness.isFinite, thickness > 0 else {
            wy_removeBorder(edges: edges)
            return
        }
        _ = wy_visualConfig

        if edges.contains(.top) {
            addBorder(edge: .top, color: color, thickness: thickness)
        }
        if edges.contains(.bottom) {
            addBorder(edge: .bottom, color: color, thickness: thickness)
        }
        if edges.contains(.left) {
            addBorder(edge: .left, color: color, thickness: thickness)
        }
        if edges.contains(.right) {
            addBorder(edge: .right, color: color, thickness: thickness)
        }

        // 防重复设置同一条边时边框闪一帧:旧边框在上面已被原地复用并改了厚度，这里立刻用当前bounds把新厚度摆好一起上屏，不等下一个主线程任务，否则旧厚度的frame会多显示一帧
        layer.wy_updateBorderFrames()

        // 开启bounds监听，视图尺寸变化时边框自动跟随更新
        wy_startBoundsObserving()

        // 已有待执行任务时不再排新任务，防止同帧连设多条边重复排队(任务执行时刷新的是当前全部边框层，合并执行和逐个执行最终效果一致)
        if objc_getAssociatedObject(self, &WYAssociatedKeys.pendingBorderApply) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.pendingBorderApply, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                objc_setAssociatedObject(self, &WYAssociatedKeys.pendingBorderApply, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // 强制更新布局以确保获取最新尺寸(整棵视图树只强制这一次，后续直接取bounds)
                self.superview?.layoutIfNeeded()

                self.layer.wy_updateBorderFrames()
            }
        }
    }

    /**
     *  移除指定位置边框
     *
     *  @param edges     要移除的边框的位置
     *
     *  @param thickness 要移除的边框的宽度或高度(传nil时移除所有匹配位置上的边框)
     *
     */
    func wy_removeBorder(edges: UIRectEdge, thickness: CGFloat? = nil) {
        // 防整表重赋sublayers引发图层重挂载:只挑出要移除的边框layer逐个移除
        let bordersToRemove = layer.sublayers?.filter { sublayer in
            guard let info = sublayer.borderInfo else { return false }
            guard edges.contains(info.edge) else { return false }
            if let thickness = thickness {
                return info.thickness == thickness
            }
            return true
        } ?? []
        bordersToRemove.forEach { $0.removeFromSuperlayer() }

        // 边框全部移除且没有链式视觉图层后停掉bounds监听，避免每次bounds变化空跑一遍
        if (layer.sublayers?.contains(where: { $0.borderInfo != nil }) != true) && (wy_hasChainVisuals() == false) {
            wy_stopBoundsObserving()
        }
    }
}

public extension UIView {

    /// 使用链式编程设置圆角、边框、阴影、渐变(调用方式类似SnapKit，也可直接用点语法逐项设置，点语法时需要自己在最后一个设置后面调用wy_showVisual设置才会生效)
    @discardableResult
    func wy_makeVisual(_ visualView: (_ make: UIView) -> Void) -> UIView {
        visualView(self)
        return wy_showVisual()
    }

    /// 圆角的位置， 默认4角圆角
    @discardableResult
    func wy_rectCorner(_ corner: UIRectCorner) -> UIView {
        let config = wy_visualConfig
        if config.rectCorner != corner {
            config.rectCorner = corner
            config.revision &+= 1
        }
        return self
    }

    /// 圆角的半径 默认0.0
    @discardableResult
    func wy_cornerRadius(_ radius: CGFloat) -> UIView {
        let radius = radius.isFinite ? max(radius, 0) : 0
        let config = wy_visualConfig
        if config.cornerRadius != radius {
            config.cornerRadius = radius
            config.revision &+= 1
        }
        return self
    }

    /// 边框颜色 默认透明
    @discardableResult
    func wy_borderColor(_ color: UIColor) -> UIView {
        let config = wy_visualConfig
        if config.borderColor != color {
            config.borderColor = color
            config.revision &+= 1
        }
        return self
    }

    /// 边框宽度 默认0.0
    @discardableResult
    func wy_borderWidth(_ width: CGFloat) -> UIView {
        let width = width.isFinite ? max(width, 0) : 0
        let config = wy_visualConfig
        if config.borderWidth != width {
            config.borderWidth = width
            config.revision &+= 1
        }
        return self
    }

    /// 阴影颜色 默认透明
    @discardableResult
    func wy_shadowColor(_ color: UIColor) -> UIView {
        let config = wy_visualConfig
        if config.shadowColor != color {
            config.shadowColor = color
            config.revision &+= 1
        }
        return self
    }

    /// 阴影偏移度 默认CGSize.zero (width : 为正数时，向右偏移，为负数时，向左偏移，height : 为正数时，向下偏移，为负数时，向上偏移)
    @discardableResult
    func wy_shadowOffset(_ offset: CGSize) -> UIView {
        let offset = CGSize(width: offset.width.isFinite ? offset.width : 0, height: offset.height.isFinite ? offset.height : 0)
        let config = wy_visualConfig
        if config.shadowOffset != offset {
            config.shadowOffset = offset
            config.revision &+= 1
        }
        return self
    }

    /// 阴影模糊半径 默认0.0，需要大于0才会有阴影扩散效果(阴影才可见)
    @discardableResult
    func wy_shadowRadius(_ radius: CGFloat) -> UIView {
        let radius = radius.isFinite ? max(radius, 0) : 0
        let config = wy_visualConfig
        if config.shadowRadius != radius {
            config.shadowRadius = radius
            config.revision &+= 1
        }
        return self
    }

    /// 阴影透明度，默认0.5，取值范围0~1
    @discardableResult
    func wy_shadowOpacity(_ opacity: CGFloat) -> UIView {
        let opacity = min(max(opacity.isNaN ? 0 : opacity, 0), 1)
        let config = wy_visualConfig
        if config.shadowOpacity != opacity {
            config.shadowOpacity = opacity
            config.revision &+= 1
        }
        return self
    }

    /// 渐变色数组(设置渐变色时不能设置背景色，会有影响)
    @discardableResult
    func wy_gradualColors(_ colors: [UIColor]) -> UIView {
        let config = wy_visualConfig
        if config.gradualColors != colors {
            config.gradualColors = colors
            config.revision &+= 1
        }
        return self
    }

    /// 渐变色方向 默认从左到右
    @discardableResult
    func wy_gradientDirection(_ direction: WYGradientDirection) -> UIView {
        let config = wy_visualConfig
        if config.gradientDirection != direction {
            config.gradientDirection = direction
            config.revision &+= 1
        }
        return self
    }

    /// 设置圆角时，会去获取视图的Bounds属性，如果此时获取不到(布局还没完成bounds为0)，则需要传入该参数，默认为 nil
    @discardableResult
    func wy_viewBounds(_ bounds: CGRect) -> UIView {
        let bounds = bounds.origin.x.isFinite && bounds.origin.y.isFinite && bounds.width.isFinite && bounds.height.isFinite && bounds.width >= 0 && bounds.height >= 0 ? bounds : .zero
        let config = wy_visualConfig
        if config.viewBounds != bounds {
            config.viewBounds = bounds
            config.revision &+= 1
        }
        return self
    }

    /// 贝塞尔路径 默认nil (有值时，radius属性将失效)
    @discardableResult
    func wy_bezierPath(_ path: UIBezierPath) -> UIView {
        let config = wy_visualConfig
        if config.bezierPath != path {
            config.bezierPath = path
            config.revision &+= 1
        }
        return self
    }

    /// 显示(更新)边框、阴影、圆角、渐变
    @discardableResult
    func wy_showVisual() -> UIView {
        let config = wy_visualConfig
        config.isApplied = true
        wy_startBoundsObserving()
        guard wy_needsVisualApply() else {
            wy_syncShadowView()
            return self
        }
        config.isApplying = true

        // 应用任务要等下一拍才执行，这一拍里新视图会以原始方块外观上屏闪一下(无圆角深色直角块一闪而过)，这里先按当前bounds同步落一遍，尺寸还没就绪也没关系，空路径的mask会把原始背景整体藏住，任务里再按布局结果修正
        let syncVisualFrame = wy_sharedBounds()
        let syncBezierPath = wy_sharedBezierPath()

        // 同步落值阶段同样不能带隐式动画，防止动画不同拍(调用方处在动画上下文里时会多出一段0.25秒动画)
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // 添加边框、圆角
        wy_addBorderAndRadius(bezierPath: syncBezierPath, visualFrame: syncVisualFrame)
        // 添加渐变
        wy_addGradual(visualFrame: syncVisualFrame)
        // 添加阴影
        wy_addShadow(bezierPath: syncBezierPath, visualFrame: syncVisualFrame)

        CATransaction.commit()
        wy_didApplyVisual()

        // 已有待执行任务时不再排新任务，防止同帧连点重复排队(任务执行时读的总是最新config，合并执行和逐个执行最终效果一致)
        if objc_getAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // 防和设置frame/约束的执行顺序冲突:延后到下一个主线程任务再取尺寸，允许先调用本方法、之后再补设frame或约束
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                objc_setAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // 强制更新布局以确保获取最新尺寸(整棵视图树只强制这一次，后续各处直接取bounds)
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
                guard self.wy_visualConfig.isApplied, self.wy_needsVisualApply() else { return }
                self.wy_visualConfig.isApplying = true

                // 路径和尺寸整轮只算一次，圆角边框、渐变、阴影共用(防一次应用里同一条路径重复构建两遍)
                let visualFrame = self.wy_sharedBounds()
                let bezierPath = self.wy_sharedBezierPath()

                // 应用阶段不在动画上下文里，图层改动必须直接落值，否则长动画进行中重新应用时会多出一段0.25秒隐式动画与长动画不同拍(屏显路径跳变)
                CATransaction.begin()
                CATransaction.setDisableActions(true)

                // 添加边框、圆角
                self.wy_addBorderAndRadius(bezierPath: bezierPath, visualFrame: visualFrame)
                // 添加渐变
                self.wy_addGradual(visualFrame: visualFrame)
                // 添加阴影
                self.wy_addShadow(bezierPath: bezierPath, visualFrame: visualFrame)

                CATransaction.commit()
                self.wy_didApplyVisual()

                // 有视觉图层才开启bounds监听，视图尺寸变化时圆角、边框、渐变、阴影自动跟随更新
                if self.wy_hasChainVisuals() {
                    self.wy_startBoundsObserving()
                }else if self.layer.sublayers?.contains(where: { $0.borderInfo != nil }) != true {
                    // 视觉全部撤干净且未重新设置时停掉bounds监听(否则之后每次bounds变化都空跑一遍刷新)
                    self.wy_stopBoundsObserving()
                }
            }
        }

        return self
    }

    /// 清除边框、阴影、圆角、渐变
    @discardableResult
    func wy_clearVisual() -> UIView {

        let config = wy_visualConfig
        config.isApplied = false
        config.isApplying = true
        config.revision &+= 1
        wy_restoreNativeClipping()
        wy_cancelVisualAnimations()

        // 阴影
        config.shadowBackgroundView?.removeFromSuperview()

        // 圆角、边框、渐变
        wy_removeLayer(WYLayerName.boardLayer)
        wy_removeLayer(WYLayerName.gradientLayer)

        // 恢复默认设置(防bezierPath残留:不清空的话下次showVisual还会沿用旧路径，radius依旧失效)
        config.rectCorner = .allCorners
        config.cornerRadius = 0.0
        config.borderColor = .clear
        config.borderWidth = 0.0
        config.shadowOpacity = 0.5
        config.shadowRadius = 0.0
        config.shadowOffset = .zero
        config.viewBounds = .zero
        config.shadowColor = .clear
        config.gradualColors = nil
        config.gradientDirection = .leftToRight
        config.bezierPath = nil
        config.shadowBackgroundView = nil

        layer.cornerRadius = 0.0
        layer.borderWidth = 0.0
        layer.borderColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0.0
        layer.shadowPath = nil
        layer.shadowRadius = 0.0
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOffset = .zero
        layer.mask = nil
        config.maskLayer = nil
        config.borderLayer = nil
        config.gradientLayer = nil
        config.nativeVisual = false
        config.isApplying = false

        // 链式视觉图层全部撤掉且没有指定位置边框时，一并停掉bounds监听
        if (layer.sublayers?.contains(where: { $0.borderInfo != nil }) != true) && (wy_hasChainVisuals() == false) {
            wy_stopBoundsObserving()
        }

        return self
    }
}

extension UIView {

    internal var wy_existingVisualConfig: WYVisualConfig? {
        return objc_getAssociatedObject(self, &WYAssociatedKeys.visualConfig) as? WYVisualConfig
    }

    internal var wy_visualConfig: WYVisualConfig {
        if let config = objc_getAssociatedObject(self, &WYAssociatedKeys.visualConfig) as? WYVisualConfig {
            return config
        }
        WYVisualConfig.installHooks(for: type(of: self))
        let config = WYVisualConfig()
        objc_setAssociatedObject(self, &WYAssociatedKeys.visualConfig, config, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return config
    }

    /// 开启bounds/transform监听，让指定位置边框和已应用的链式视觉跟随视图尺寸变化自动更新、阴影背景视图跟随视图形变移动
    internal func wy_startBoundsObserving() {
        if let observer = objc_getAssociatedObject(self, &WYAssociatedKeys.borderObserver) as? WYBoundsObserver {
            observer.enableShadowObserving(view: self)
            return
        }
        let observer = WYBoundsObserver(view: self)
        objc_setAssociatedObject(self, &WYAssociatedKeys.borderObserver, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 停止bounds监听(指定位置边框和链式视觉全部移除后调用)
    internal func wy_stopBoundsObserving() {
        objc_setAssociatedObject(self, &WYAssociatedKeys.borderObserver, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate struct WYAssociatedKeys {
        static var visualConfig: UInt8 = 0
        static var borderObserver: UInt8 = 0
        static var pendingVisualApply: UInt8 = 0
        static var pendingBorderApply: UInt8 = 0
    }
}
