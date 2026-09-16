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
        return (total + perLine - 1) / perLine
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
        Task {
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

        // 防同帧连设多条边重复排队:已有待执行任务时不再排新任务(任务执行时刷新的是当前全部边框层，合并执行和逐个执行最终效果一致)
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
        wy_visualConfig.rectCorner = corner
        return self
    }

    /// 圆角的半径 默认0.0
    @discardableResult
    func wy_cornerRadius(_ radius: CGFloat) -> UIView {
        wy_visualConfig.cornerRadius = radius
        return self
    }

    /// 边框颜色 默认透明
    @discardableResult
    func wy_borderColor(_ color: UIColor) -> UIView {
        wy_visualConfig.borderColor = color
        return self
    }

    /// 边框宽度 默认0.0
    @discardableResult
    func wy_borderWidth(_ width: CGFloat) -> UIView {
        wy_visualConfig.borderWidth = width
        return self
    }

    /// 阴影颜色 默认透明
    @discardableResult
    func wy_shadowColor(_ color: UIColor) -> UIView {
        wy_visualConfig.shadowColor = color
        return self
    }

    /// 阴影偏移度 默认CGSize.zero (width : 为正数时，向右偏移，为负数时，向左偏移，height : 为正数时，向下偏移，为负数时，向上偏移)
    @discardableResult
    func wy_shadowOffset(_ offset: CGSize) -> UIView {
        wy_visualConfig.shadowOffset = offset
        return self
    }

    /// 阴影模糊半径 默认0.0，需要大于0才会有阴影扩散效果(阴影才可见)
    @discardableResult
    func wy_shadowRadius(_ radius: CGFloat) -> UIView {
        wy_visualConfig.shadowRadius = radius
        return self
    }

    /// 阴影透明度，默认0.5，取值范围0~1
    @discardableResult
    func wy_shadowOpacity(_ opacity: CGFloat) -> UIView {
        wy_visualConfig.shadowOpacity = opacity
        return self
    }

    /// 渐变色数组(设置渐变色时不能设置背景色，会有影响)
    @discardableResult
    func wy_gradualColors(_ colors: [UIColor]) -> UIView {
        wy_visualConfig.gradualColors = colors
        return self
    }

    /// 渐变色方向 默认从左到右
    @discardableResult
    func wy_gradientDirection(_ direction: WYGradientDirection) -> UIView {
        wy_visualConfig.gradientDirection = direction
        return self
    }

    /// 设置圆角时，会去获取视图的Bounds属性，如果此时获取不到(布局还没完成bounds为0)，则需要传入该参数，默认为 nil
    @discardableResult
    func wy_viewBounds(_ bounds: CGRect) -> UIView {
        wy_visualConfig.viewBounds = bounds
        return self
    }

    /// 贝塞尔路径 默认nil (有值时，radius属性将失效)
    @discardableResult
    func wy_bezierPath(_ path: UIBezierPath) -> UIView {
        wy_visualConfig.bezierPath = path
        return self
    }

    /// 显示(更新)边框、阴影、圆角、渐变
    @discardableResult
    func wy_showVisual() -> UIView {

        // 防新加进层级的视图裸奔一帧:应用任务要等下一拍才执行，这一拍里新视图会以原始方块外观上屏闪一下(无圆角深色直角块一闪而过)，这里先按当前bounds同步落一遍，尺寸还没就绪也没关系，空路径的mask会把原始背景整体藏住，任务里再按布局结果修正
        let syncVisualFrame = wy_sharedBounds()
        let syncBezierPath = wy_sharedBezierPath()

        // 防动画不同拍:同步落值阶段同样不能带隐式动画，否则调用方处在动画上下文里时会多出一段0.25秒动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // 添加边框、圆角
        wy_addBorderAndRadius(bezierPath: syncBezierPath, visualFrame: syncVisualFrame)
        // 添加渐变
        wy_addGradual(visualFrame: syncVisualFrame)
        // 添加阴影
        wy_addShadow(bezierPath: syncBezierPath, visualFrame: syncVisualFrame)

        CATransaction.commit()

        // 防同帧连点重复排队:已有待执行任务时不再排新任务(任务执行时读的总是最新config，合并执行和逐个执行最终效果一致)
        if objc_getAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // 防和设置frame/约束的执行顺序冲突:延后到下一个主线程任务再取尺寸，允许先调用本方法、之后再补设frame或约束
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                objc_setAssociatedObject(self, &WYAssociatedKeys.pendingVisualApply, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // 强制更新布局以确保获取最新尺寸(整棵视图树只强制这一次，后续各处直接取bounds)
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()

                // 路径和尺寸整轮只算一次，圆角边框、渐变、阴影共用(防一次应用里同一条路径重复构建两遍)
                let visualFrame = self.wy_sharedBounds()
                let bezierPath = self.wy_sharedBezierPath()

                // 防动画不同拍:应用阶段不在动画上下文里，图层改动必须直接落值，否则长动画进行中重新应用时会多出一段0.25秒隐式动画和长动画各走各的(屏显路径跳变)
                CATransaction.begin()
                CATransaction.setDisableActions(true)

                // 添加边框、圆角
                self.wy_addBorderAndRadius(bezierPath: bezierPath, visualFrame: visualFrame)
                // 添加渐变
                self.wy_addGradual(visualFrame: visualFrame)
                // 添加阴影
                self.wy_addShadow(bezierPath: bezierPath, visualFrame: visualFrame)

                CATransaction.commit()

                // 有视觉图层才开启bounds监听，视图尺寸变化时圆角、边框、渐变、阴影自动跟随更新
                if self.wy_hasChainVisuals() {
                    self.wy_startBoundsObserving()
                }else if self.layer.sublayers?.contains(where: { $0.borderInfo != nil }) != true {
                    // 防监听空转:之前有视觉后来全撤干净、又没重新加上时，停掉bounds监听，免得之后每次bounds变化白跑一遍刷新
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
        config.shadowOpacity = 0.0
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

        // 链式视觉图层全部撤掉且没有指定位置边框时，一并停掉bounds监听
        if (layer.sublayers?.contains(where: { $0.borderInfo != nil }) != true) && (wy_hasChainVisuals() == false) {
            wy_stopBoundsObserving()
        }

        return self
    }
}

// 内部实现，链式编程实现部分
private extension UIView {

    func wy_addShadow(bezierPath: UIBezierPath, visualFrame: CGRect) {
        let config = wy_visualConfig

        // 防阴影没开还留痕迹:颜色透明或透明度不大于0时先把旧阴影清干净再返回，顺带防"只传bezierPath不开阴影"的场景白建阴影背景视图
        guard config.shadowOpacity > 0, wy_colorAlpha(config.shadowColor) > 0 else {
            config.shadowBackgroundView?.removeFromSuperview()
            config.shadowBackgroundView = nil
            layer.shadowOpacity = 0
            layer.shadowColor = nil
            layer.shadowPath = nil
            return
        }

        var shadowView = self

        // 同时存在阴影和圆角时，阴影画在独立的背景视图上，避免被圆角mask裁掉
        if (config.cornerRadius > 0) || (config.bezierPath != nil) {

            if superview == nil {
                //WYLogManager.output("添加阴影和圆角时，请先将view加到父视图上")
            }

            // 防每次showVisual都销毁重建阴影背景视图:还在同一个父视图上时直接复用，只有父视图变了才重建
            if let existView = config.shadowBackgroundView, existView.superview === superview {
                shadowView = existView
            }else {
                config.shadowBackgroundView?.removeFromSuperview()

                shadowView = UIView(frame: self.frame)
                shadowView.translatesAutoresizingMaskIntoConstraints = false
                self.superview?.insertSubview(shadowView, belowSubview: self)
                // 用superview?.addConstraints而非NSLayoutConstraint.activate，视图还不在父视图上时整段静默跳过，不报"没有共同祖先"的错误
                self.superview?.addConstraints([
                    NSLayoutConstraint(item: shadowView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0),
                    NSLayoutConstraint(item: shadowView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0),
                    NSLayoutConstraint(item: shadowView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0),
                    NSLayoutConstraint(item: shadowView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0)])

                config.shadowBackgroundView = shadowView
                // 防形变残留错位:视图已带transform时新建的阴影背景视图要先抄一份transform，否则第一帧两层不贴合
                shadowView.transform = self.transform
            }

            // 防双阴影:阴影从挂在自身切到挂在背景视图时，自身layer上的旧阴影(之前无圆角时设的)不清会两层影子叠着
            layer.shadowOpacity = 0
            layer.shadowPath = nil

            // 圆角或自定义路径时阴影路径跟随路径形状(路径由wy_showVisual整轮只算一次传入)
            shadowView.layer.shadowPath = bezierPath.cgPath
        }else {
            // 不需要背景视图时，撤掉旧的
            config.shadowBackgroundView?.removeFromSuperview()
            config.shadowBackgroundView = nil

            // 防每帧按内容轮廓离屏算阴影:无圆角时阴影挂在自身，内容恰好铺满整个矩形(纯背景色或纯渐变、无子视图)的前提下，矩形shadowPath的阴影和轮廓阴影完全一样，用shadowPath换掉轮廓计算的性能开销；内容不铺满矩形(有子视图、半透明、带图片等)时保持轮廓阴影，并清掉残留的旧矩形路径防阴影停在旧尺寸上
            layer.shadowPath = wy_isSolidRectShadowContent() ? UIBezierPath(rect: visualFrame).cgPath : nil
        }

        // 透明度钳到0~1，防传负数或大于1的值给CALayer出现未定义表现
        shadowView.layer.shadowOpacity = Float(min(max(config.shadowOpacity, 0), 1))
        shadowView.layer.shadowRadius = config.shadowRadius
        shadowView.layer.shadowOffset = config.shadowOffset
        shadowView.layer.shadowColor = config.shadowColor.cgColor
    }

    /// 取颜色的透明度(iOS 14及以上直接用CGColor的alpha属性，更早的系统退化取分量表最后一个，RGB、灰度、CMYK色彩空间里最后一位都是alpha，图案色取不到分量时按不透明算)
    func wy_colorAlpha(_ color: UIColor) -> CGFloat {
        if #available(iOS 14.0, *) {
            return color.cgColor.alpha
        }
        return color.cgColor.components?.last ?? 1
    }

    /// 判断自身可见内容是否恰好铺满整个bounds矩形(无子视图、无自定义contents、子图层只有本库加的、背景色或渐变色不透明)
    func wy_isSolidRectShadowContent() -> Bool {
        // 内容铺满矩形时，矩形shadowPath渲染的阴影和内容轮廓阴影完全一样，才能放心用shadowPath换掉每帧离屏算轮廓的开销

        // 有子视图或layer自带内容(如图片)时轮廓形状未知，不能按矩形算
        guard subviews.isEmpty, layer.contents == nil else { return false }

        // 子图层只认本库加的(链式边框、渐变、指定位置边框)，用户自己往layer上加的图层形状未知
        let sublayersAllOurs = layer.sublayers?.allSatisfy { sublayer in
            sublayer.name == WYLayerName.boardLayer || sublayer.name == WYLayerName.gradientLayer || sublayer.borderInfo != nil
        } ?? true
        guard sublayersAllOurs else { return false }

        // 背景色不透明时轮廓就是整个矩形(渐变或边框叠在上面也不改变外轮廓)
        if let backgroundColor = backgroundColor, wy_colorAlpha(backgroundColor) >= 1 {
            return true
        }

        // 背景透明或没设时，渐变色全部不透明同样铺满矩形
        if let gradualColors = wy_visualConfig.gradualColors, gradualColors.count > 1 {
            return gradualColors.allSatisfy { wy_colorAlpha($0) >= 1 }
        }

        return false
    }

    /// 添加圆角和边框(bezierPath/visualFrame由wy_showVisual整轮只算一次后传入，圆角mask、边框、阴影视图共享同一条路径)
    func wy_addBorderAndRadius(bezierPath: UIBezierPath, visualFrame: CGRect) {

        let config = wy_visualConfig

        let hasRadius: Bool = (config.cornerRadius > 0)
        let hasBezierPath: Bool = (config.bezierPath != nil)

        guard hasRadius || hasBezierPath || (config.borderWidth > 0) else {
            // 什么都不需要时撤掉可能存在的旧mask和旧边框
            self.layer.mask = nil
            self.wy_removeLayer(WYLayerName.boardLayer)
            return
        }

        // 圆角或自定义曲线(防重复应用时闪一帧:已有mask原地更新路径，不先移除再重建，图层任何时刻都在场)
        if hasRadius || hasBezierPath {

            let maskLayer: CAShapeLayer
            if let existLayer = self.layer.mask as? CAShapeLayer, existLayer.name == WYLayerName.maskLayer {
                maskLayer = existLayer
            }else {
                maskLayer = CAShapeLayer()
                maskLayer.name = WYLayerName.maskLayer
                self.layer.mask = maskLayer
            }
            maskLayer.frame = visualFrame
            maskLayer.path = bezierPath.cgPath
        }else {
            self.layer.mask = nil
        }

        // 边框(同样原地更新，不满足条件时移除)
        if config.borderWidth > 0 {

            let borderLayer: CAShapeLayer
            if let existLayer = self.layer.sublayers?.first(where: { $0.name == WYLayerName.boardLayer }) as? CAShapeLayer {
                borderLayer = existLayer
            }else {
                borderLayer = CAShapeLayer()
                borderLayer.name = WYLayerName.boardLayer
                borderLayer.fillColor = UIColor.clear.cgColor
                borderLayer.lineCap = .square
                borderLayer.lineJoin = .miter
                // zPosition固定为1让边框渲染在普通子图层(默认0，含wy_addBorder加的指定位置边框)之上，与旧版每次重建后位于最上层的行为一致
                borderLayer.zPosition = 1
                self.layer.addSublayer(borderLayer)
            }
            borderLayer.frame = visualFrame
            borderLayer.path = bezierPath.cgPath
            // 圆角或自定义路径时线宽翻倍，描边外半边被mask裁掉，剩下的一半正好贴着mask边缘内侧(自定义路径和圆角一样有mask，不翻倍边框只剩一半宽度)
            borderLayer.lineWidth = (hasRadius || hasBezierPath) ? (config.borderWidth * 2) : config.borderWidth
            borderLayer.strokeColor = config.borderColor.cgColor
        }else {
            self.wy_removeLayer(WYLayerName.boardLayer)
        }
    }

    /// 添加渐变色(visualFrame由wy_showVisual整轮只算一次后传入)
    func wy_addGradual(visualFrame: CGRect) {

        let config = wy_visualConfig

        // 渐变色数组个数必须大于1才能满足渐变要求
        guard let gradualColors = config.gradualColors, gradualColors.count > 1 else {
            // 不再需要渐变时移除旧渐变图层
            self.wy_removeLayer(WYLayerName.gradientLayer)
            return
        }

        let cgColors: [CGColor] = gradualColors.map { $0.cgColor }

        let startPoint: CGPoint
        let endPoint: CGPoint
        switch config.gradientDirection {
        case .topToBottom:
            startPoint = CGPoint(x: 0.0, y: 0.0)
            endPoint = CGPoint(x: 0.0, y: 1.0)
        case .leftToRight:
            startPoint = CGPoint(x: 0.0, y: 0.0)
            endPoint = CGPoint(x: 1.0, y: 0.0)
        case .leftToLowRight:
            startPoint = CGPoint(x: 0.0, y: 0.0)
            endPoint = CGPoint(x: 1.0, y: 1.0)
        case .rightToLowLeft:
            startPoint = CGPoint(x: 1.0, y: 0.0)
            endPoint = CGPoint(x: 0.0, y: 1.0)
        }

        // 防重复应用时闪一帧:已有渐变层原地更新颜色方向，不先移除再重建也不重新挂载，图层任何时刻都在场、树结构不动
        if let existLayer = self.layer.sublayers?.first(where: { $0.name == WYLayerName.gradientLayer }) as? CAGradientLayer {
            existLayer.frame = visualFrame
            existLayer.colors = cgColors
            existLayer.startPoint = startPoint
            existLayer.endPoint = endPoint
        }else {
            let gradientLayer = CAGradientLayer()
            gradientLayer.name = WYLayerName.gradientLayer
            // zPosition固定为-1让渐变渲染在所有子图层(默认0)之下，与旧版每次重建后位于最底层的行为一致
            gradientLayer.zPosition = -1
            gradientLayer.frame = visualFrame
            gradientLayer.colors = cgColors
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    /// 移除上次添加的layer
    func wy_removeLayer(_ layerKey: String) {

        self.layer.sublayers?.forEach { sublayer in
            if sublayer.name == layerKey {
                sublayer.removeFromSuperlayer()
            }
        }
    }

    func wy_sharedBounds() -> CGRect {

        // 获取在自动布局前的视图大小(布局已在wy_showVisual的任务里强制完成，这里直接取值不再重复强制布局)
        if wy_visualConfig.viewBounds.equalTo(.zero) == false {
            return wy_visualConfig.viewBounds
        }

        return bounds
    }

    func wy_sharedBezierPath() -> UIBezierPath {

        let config = wy_visualConfig

        if let bezierPath = config.bezierPath {
            return bezierPath
        }

        let bounds = wy_sharedBounds()

        // 防负数或超过短边一半的值画出畸形路径:半径和内缩量都钳到0~短边一半(与气泡视图的钳法一致)，布局还没出来尺寸为0时钳出0同样安全
        let maxRadius = min(bounds.width, bounds.height) / 2
        let cornerRadius = min(max(config.cornerRadius, 0), maxRadius)

        // 内缩量为边框宽度的一半(同样钳到0~短边一半，防负边宽或超宽边框把矩形内缩成负值)
        let borderInset = min(max(config.borderWidth / 2.0, 0), maxRadius)

        if cornerRadius > 0 {
            // 防宽边框吃掉圆角:路径不内缩、直接用设置的半径，配合翻倍线宽让描边只画进mask内侧；旧实现把半径减掉半个边框宽，边框越宽可见圆角越小，边框宽到半径2倍时圆角直接变直角
            return UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: config.rectCorner,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
        }

        // 直角时路径内缩半个线宽，让描边外边缘正好贴住视图边缘
        return UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderInset, dy: borderInset),
            byRoundingCorners: config.rectCorner,
            cornerRadii: CGSize(width: 0.0, height: 0.0)
        )
    }

    /// 链式编程的全部视觉配置(整份配置只挂一个关联对象，读写只查一次关联表)
    final class WYVisualConfig {

        var rectCorner: UIRectCorner = .allCorners
        var cornerRadius: CGFloat = 0.0
        var borderColor: UIColor = .clear
        var borderWidth: CGFloat = 0.0
        var shadowColor: UIColor = .clear
        var shadowOffset: CGSize = .zero
        var shadowRadius: CGFloat = 0.0
        var shadowOpacity: CGFloat = 0.5
        var gradualColors: [UIColor]? = nil
        var gradientDirection: WYGradientDirection = .leftToRight
        var viewBounds: CGRect = .zero
        var bezierPath: UIBezierPath? = nil
        /// 承载"阴影+圆角"的背景视图(强引用，随wy_clearVisual一起销毁)
        var shadowBackgroundView: UIView? = nil

        deinit {
            // 防视图销毁后孤儿阴影:阴影背景视图插在父视图上由父视图持有，本体销毁时这里把它从父视图摘掉，否则屏幕上会残留一块没人管的阴影
            shadowBackgroundView?.removeFromSuperview()
        }
    }

    var wy_visualConfig: WYVisualConfig {
        if let config = objc_getAssociatedObject(self, &WYAssociatedKeys.visualConfig) as? WYVisualConfig {
            return config
        }
        let config = WYVisualConfig()
        objc_setAssociatedObject(self, &WYAssociatedKeys.visualConfig, config, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return config
    }

    // 添加指定位置边框实现部分

    /// 内部数据结构
    struct WYBorderInfo {
        let edge: UIRectEdge
        let thickness: CGFloat
    }

    /// 监听layer.bounds/transform变化的观察者(销毁时自动停止观察，不需要手动removeObserver)
    final class WYBoundsObserver {

        var observation: NSKeyValueObservation?

        var transformObservation: NSKeyValueObservation?

        init(view: UIView) {
            observation = view.layer.observe(\.bounds, options: [.new, .old]) { [weak view] _, change in
                // 防后台线程改动layer属性:只处理主线程上的bounds变化，尺寸没变也不重复刷
                guard Thread.isMainThread, let view = view, change.newValue != change.oldValue else { return }
                view.layer.wy_updateBorderFrames()
                view.wy_refreshVisualLayout()
            }
            transformObservation = view.layer.observe(\.transform, options: [.new]) { [weak view] _, _ in
                // 防阴影背景视图不跟形变:位移、旋转、缩放只改transform不动bounds，靠约束定位的阴影背景视图不会跟着动，这里把视图当前的transform抄给它让阴影和本体始终贴在一起(在动画上下文里改transform时，这次赋值也会被UIKit做成同拍动画)
                guard Thread.isMainThread, let view = view else { return }
                view.wy_visualConfig.shadowBackgroundView?.transform = view.transform
            }
        }
    }

    /// 开启bounds/transform监听，让指定位置边框和已应用的链式视觉跟随视图尺寸变化自动更新、阴影背景视图跟随视图形变移动
    func wy_startBoundsObserving() {
        guard objc_getAssociatedObject(self, &WYAssociatedKeys.borderObserver) == nil else { return }
        let observer = WYBoundsObserver(view: self)
        objc_setAssociatedObject(self, &WYAssociatedKeys.borderObserver, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 停止bounds监听(指定位置边框和链式视觉全部移除后调用)
    func wy_stopBoundsObserving() {
        objc_setAssociatedObject(self, &WYAssociatedKeys.borderObserver, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 视觉图层同步过渡用的动画key(每次先移除同key旧动画再加新的，防快速连点时动画叠加)
    static let wy_visualSyncAnimationKey = "WYBasisKit.visualSyncAnimation"

    /// 让视觉图层与view本体同拍过渡(动画上下文里补一份显式动画组再落值，没有动画上下文时禁隐式动画直接落值；frame传nil表示frame不变只更新路径)
    static func wy_syncLayerGeometry(_ layer: CALayer, frame: CGRect?, path: CGPath? = nil, shadowPath: CGPath? = nil) {

        // 防隐式动画在真实渲染里不跟拍:改约束动画时bounds监听里靠CATransaction隐式动画同步这些图层，屏幕上圆角mask不参与过渡(动画中圆角变直角)、边框和渐变瞬间跳到新尺寸压到还没挪完的周边控件，动画结束又恢复正常；这里照搬WYAirBubbleView验证过的做法，动画上下文里给每个图层显式加一份动画组(fromValue取presentation当前屏显值、时长取inheritedAnimationDuration)，让图层和view本体一起平滑过渡
        if UIView.inheritedAnimationDuration > 0 {

            layer.removeAnimation(forKey: wy_visualSyncAnimationKey)

            // 防keyPath字符串写错或日后属性改名没报错:统一用#keyPath让编译器对着属性定义校验，属性改名或删除时直接编译报错(运行期keyPath无效只会静默没动画，排查无从下手)
            var animations: [CAAnimation] = []
            let presentation = layer.presentation()

            if let path = path, let shapeLayer = layer as? CAShapeLayer {
                let pathAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
                pathAnimation.fromValue = (presentation as? CAShapeLayer)?.path ?? shapeLayer.path
                pathAnimation.toValue = path
                animations.append(pathAnimation)
            }

            if let shadowPath = shadowPath {
                let shadowPathAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.shadowPath))
                shadowPathAnimation.fromValue = presentation?.shadowPath ?? layer.shadowPath
                shadowPathAnimation.toValue = shadowPath
                animations.append(shadowPathAnimation)
            }

            if let frame = frame {
                let boundsAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.bounds))
                boundsAnimation.fromValue = presentation?.bounds ?? layer.bounds
                // 防bounds动画值类型不匹配:bounds是CGRect，toValue传CGSize会被桥接成尺寸类型的NSValue，渲染端解不出bounds导致动画中图层尺寸归零(渐变漏底、指定位置边框消失)，必须包成origin为.zero的完整CGRect
                boundsAnimation.toValue = CGRect(origin: .zero, size: frame.size)
                animations.append(boundsAnimation)

                let positionAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.position))
                positionAnimation.fromValue = presentation?.position ?? layer.position
                positionAnimation.toValue = CGPoint(x: frame.midX, y: frame.midY)
                animations.append(positionAnimation)
            }

            if animations.isEmpty == false {
                let group = CAAnimationGroup()
                group.animations = animations
                group.duration = UIView.inheritedAnimationDuration
                // 公共API拿不到当前动画上下文的自定义曲线，UIView.animate默认曲线就是easeInEaseOut，用同名曲线对齐大多数场景
                group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                group.beginTime = 0
                group.isRemovedOnCompletion = true
                group.fillMode = .removed
                layer.add(group, forKey: wy_visualSyncAnimationKey)
            }
        }

        // 模型值直接落位，屏幕上的过渡交给上面的动画组，模型上不能再叠隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if let path = path, let shapeLayer = layer as? CAShapeLayer {
            shapeLayer.path = path
        }
        if let shadowPath = shadowPath {
            layer.shadowPath = shadowPath
        }
        if let frame = frame {
            layer.frame = frame
        }
        CATransaction.commit()
    }

    /// 视图bounds变化后，把已应用的圆角mask、边框、渐变、阴影路径按新尺寸重算(没有视觉图层时直接返回)
    func wy_refreshVisualLayout() {

        // 防普通视图空跑:没有任何链式视觉图层时不往下走(阴影背景视图存在时mask必定存在，不用单独判)
        guard wy_hasChainVisuals(), bounds.width > 0, bounds.height > 0 else {
            return
        }

        // 路径和frame整轮只算一次，mask、边框、阴影共用
        let bezierPath: UIBezierPath = wy_sharedBezierPath()
        let visualFrame: CGRect = wy_sharedBounds()

        if let maskLayer = layer.mask as? CAShapeLayer, maskLayer.name == WYLayerName.maskLayer {
            UIView.wy_syncLayerGeometry(maskLayer, frame: visualFrame, path: bezierPath.cgPath)
        }

        if let borderLayer = layer.sublayers?.first(where: { $0.name == WYLayerName.boardLayer }) as? CAShapeLayer {
            UIView.wy_syncLayerGeometry(borderLayer, frame: visualFrame, path: bezierPath.cgPath)
        }

        if let gradientLayer = layer.sublayers?.first(where: { $0.name == WYLayerName.gradientLayer }) {
            UIView.wy_syncLayerGeometry(gradientLayer, frame: visualFrame)
        }

        // 阴影背景视图的位置由约束自动跟随，这里只按新尺寸重算阴影路径
        let config = wy_visualConfig
        if let shadowBackgroundView = config.shadowBackgroundView, (config.cornerRadius > 0) || (config.bezierPath != nil) {
            UIView.wy_syncLayerGeometry(shadowBackgroundView.layer, frame: nil, shadowPath: bezierPath.cgPath)
        }else if (config.shadowOpacity > 0) && (layer.shadowOpacity > 0) && (layer.shadowPath != nil) {
            // 无圆角场景挂在自身上的矩形shadowPath，bounds变了同步换新尺寸矩形；后来加了子视图等内容导致轮廓不再铺满矩形时，撤掉路径回到轮廓阴影
            if wy_isSolidRectShadowContent() {
                UIView.wy_syncLayerGeometry(layer, frame: nil, shadowPath: UIBezierPath(rect: visualFrame).cgPath)
            }else {
                layer.shadowPath = nil
            }
        }
    }

    /// 判断是否还有链式编程生成的视觉图层(圆角mask、边框、渐变、挂在自身上的矩形阴影路径)
    func wy_hasChainVisuals() -> Bool {
        if layer.mask?.name == WYLayerName.maskLayer { return true }
        if layer.sublayers?.contains(where: { $0.name == WYLayerName.boardLayer || $0.name == WYLayerName.gradientLayer }) == true { return true }
        // 无圆角场景的阴影挂在自身layer的shadowPath上(没有mask也没有子图层)，但它同样要跟随bounds变化刷新，也算链式视觉(颜色透明说明阴影没真开过，不算)
        let config = wy_visualConfig
        return (config.shadowOpacity > 0) && (wy_colorAlpha(config.shadowColor) > 0) && (layer.shadowPath != nil) && (config.shadowBackgroundView == nil)
    }

    private func addBorder(edge: UIRectEdge,
                           color: UIColor,
                           thickness: CGFloat) {
        // 防图层树结构抖动:重复设置同一条边时原地复用旧边框层改颜色厚度，不先移除再新建(拆层加层会触发图层重挂载，cell复用高频换边框场景开销可见)；顺手清掉历史残留的多余同边层，保证同一条边永远只有一层
        let sameEdgeBorders = layer.sublayers?.filter { $0.borderInfo?.edge == edge } ?? []
        if let existBorder = sameEdgeBorders.first {
            existBorder.backgroundColor = color.cgColor
            existBorder.borderInfo = WYBorderInfo(edge: edge, thickness: thickness)
            sameEdgeBorders.dropFirst().forEach { $0.removeFromSuperlayer() }
            return
        }

        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.borderInfo = WYBorderInfo(edge: edge, thickness: thickness)
        layer.addSublayer(border)
    }

    /// 本库创建的图层name标识(mask挂在layer.mask上，其余在layer.sublayers里)，仅用于内部查找识别
    struct WYLayerName {
        static let maskLayer = "WYBasisKit.maskLayer"
        static let boardLayer = "WYBasisKit.boardLayer"
        static let gradientLayer = "WYBasisKit.gradientLayer"
    }

    struct WYAssociatedKeys {
        static var visualConfig: UInt8 = 0
        static var borderObserver: UInt8 = 0
        static var pendingVisualApply: UInt8 = 0
        static var pendingBorderApply: UInt8 = 0
    }
}

private extension CALayer {
    struct WYBorderAssociatedKeys {
        static var wy_borderInfoKey: UInt8 = 0
    }

    var borderInfo: UIView.WYBorderInfo? {
        get {
            return objc_getAssociatedObject(
                self, &WYBorderAssociatedKeys.wy_borderInfoKey
            ) as? UIView.WYBorderInfo
        }
        set {
            objc_setAssociatedObject(
                self, &WYBorderAssociatedKeys.wy_borderInfoKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 按edge把每个边框layer的frame刷新到当前bounds上
    func wy_updateBorderFrames() {

        // 布局还没完成时跳过，等bounds有值后由监听自动重刷
        guard bounds.width > 0, bounds.height > 0 else { return }

        sublayers?.forEach { sublayer in
            guard let info = sublayer.borderInfo else { return }

            switch info.edge {
            case .top:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: 0, y: 0,
                                                                    width: bounds.width, height: info.thickness))
            case .bottom:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: 0, y: bounds.height - info.thickness,
                                                                    width: bounds.width, height: info.thickness))
            case .left:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: 0, y: 0,
                                                                    width: info.thickness, height: bounds.height))
            case .right:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: bounds.width - info.thickness, y: 0,
                                                                    width: info.thickness, height: bounds.height))
            default:
                break
            }
        }
    }
}
