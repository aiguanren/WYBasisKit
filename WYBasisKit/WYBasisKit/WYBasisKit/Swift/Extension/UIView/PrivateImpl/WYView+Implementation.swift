//
//  WYView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit

// 内部实现，链式编程实现部分
extension UIView {

    internal func wy_addShadow(bezierPath: UIBezierPath, visualFrame: CGRect) {
        let config = wy_visualConfig

        // 颜色透明或透明度不大于0时先把旧阴影清干净再返回(同时避免"只传bezierPath不开阴影"的场景空建阴影背景视图)
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
                // 视图已带transform时新建的阴影背景视图要先复制一份transform，防止第一帧两层不贴合
                shadowView.transform = self.transform
            }

            // 阴影从挂在自身切到挂在背景视图时，自身layer上的旧阴影(无圆角时设的)要清掉，防止两层影子叠加
            layer.shadowOpacity = 0
            layer.shadowPath = nil

            // 圆角或自定义路径时阴影路径跟随路径形状(路径由wy_showVisual整轮只算一次传入)
            shadowView.layer.shadowPath = bezierPath.cgPath
        }else {
            // 不需要背景视图时，撤掉旧的
            config.shadowBackgroundView?.removeFromSuperview()
            config.shadowBackgroundView = nil

            // 无圆角时阴影挂在自身，内容恰好铺满整个矩形(纯背景色或纯渐变、无子视图)的前提下矩形shadowPath的阴影与轮廓阴影完全一样，用shadowPath换掉逐帧按内容轮廓离屏计算阴影的开销，内容不铺满矩形(有子视图、半透明、带图片等)时保持轮廓阴影，并清掉残留的旧矩形路径防止阴影停在旧尺寸上
            layer.shadowPath = wy_isSolidRectShadowContent() ? UIBezierPath(rect: visualFrame).cgPath : nil
        }

        // 透明度钳到0~1，防传负数或大于1的值给CALayer出现未定义表现
        shadowView.layer.shadowOpacity = Float(min(max(config.shadowOpacity, 0), 1))
        shadowView.layer.shadowRadius = config.shadowRadius
        shadowView.layer.shadowOffset = config.shadowOffset
        shadowView.layer.shadowColor = config.shadowColor.cgColor
    }

    /// 取颜色的透明度(直接读CGColor的alpha属性，图案色取不到分量时按不透明算)
    fileprivate func wy_colorAlpha(_ color: UIColor) -> CGFloat {
        return color.cgColor.alpha
    }

    /// 判断自身可见内容是否恰好铺满整个bounds矩形(无子视图、无自定义contents、子图层只有本库加的、背景色或渐变色不透明)
    fileprivate func wy_isSolidRectShadowContent() -> Bool {
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
    internal func wy_addBorderAndRadius(bezierPath: UIBezierPath, visualFrame: CGRect) {

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
                // zPosition固定为1让边框渲染在普通子图层(默认0，含wy_addBorder加的指定位置边框)之上
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
    internal func wy_addGradual(visualFrame: CGRect) {

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

        // 已有渐变层原地更新颜色方向，不先移除再重建也不重新挂载，防止重复应用时闪一帧(图层任何时刻都在场、树结构不动)
        if let existLayer = self.layer.sublayers?.first(where: { $0.name == WYLayerName.gradientLayer }) as? CAGradientLayer {
            existLayer.frame = visualFrame
            existLayer.colors = cgColors
            existLayer.startPoint = startPoint
            existLayer.endPoint = endPoint
        }else {
            let gradientLayer = CAGradientLayer()
            gradientLayer.name = WYLayerName.gradientLayer
            // zPosition固定为-1让渐变渲染在所有子图层(默认0)之下
            gradientLayer.zPosition = -1
            gradientLayer.frame = visualFrame
            gradientLayer.colors = cgColors
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    /// 移除上次添加的layer
    internal func wy_removeLayer(_ layerKey: String) {

        self.layer.sublayers?.forEach { sublayer in
            if sublayer.name == layerKey {
                sublayer.removeFromSuperlayer()
            }
        }
    }

    internal func wy_sharedBounds() -> CGRect {

        // 获取在自动布局前的视图大小(布局已在wy_showVisual的任务里强制完成，这里直接取值不再重复强制布局)
        if wy_visualConfig.viewBounds.equalTo(.zero) == false {
            return wy_visualConfig.viewBounds
        }

        return bounds
    }

    internal func wy_sharedBezierPath() -> UIBezierPath {

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
            // 路径不内缩、直接用设置的半径，配合翻倍线宽让描边只画进mask内侧，防止宽边框压缩可见圆角(把半径减掉半个边框宽时，边框越宽可见圆角越小，边框宽到半径2倍时圆角变直角)
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
    internal final class WYVisualConfig {

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
            // 本体销毁时把阴影背景视图从父视图摘掉(它插在父视图上由父视图持有，不摘掉时屏幕上会残留一块失去管理的阴影)
            shadowBackgroundView?.removeFromSuperview()
        }
    }


    // 添加指定位置边框实现部分

    /// 内部数据结构
    internal struct WYBorderInfo {
        let edge: UIRectEdge
        let thickness: CGFloat
    }

    /// 监听layer.bounds/transform变化的观察者(销毁时自动停止观察，不需要手动removeObserver)
    internal final class WYBoundsObserver {

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
                // 位移、旋转、缩放只改transform不动bounds，靠约束定位的阴影背景视图不会跟着动，把视图当前的transform复制给它让阴影和本体始终贴在一起(在动画上下文里改transform时，这次赋值也会被UIKit做成同拍动画)
                guard Thread.isMainThread, let view = view else { return }
                view.wy_visualConfig.shadowBackgroundView?.transform = view.transform
            }
        }
    }


    /// 视觉图层同步过渡用的动画key(每次先移除同key旧动画再加新的，防快速连点时动画叠加)
    fileprivate static let wy_visualSyncAnimationKey = "WYBasisKit.visualSyncAnimation"

    /// 让视觉图层与view本体同拍过渡(动画上下文里补一份显式动画组再落值，没有动画上下文时禁隐式动画直接落值，frame传nil表示frame不变只更新路径)
    fileprivate static func wy_syncLayerGeometry(_ layer: CALayer, frame: CGRect?, path: CGPath? = nil, shadowPath: CGPath? = nil) {

        // 改约束动画时bounds监听里靠CATransaction隐式动画同步这些图层，屏幕上圆角mask不参与过渡(动画中圆角变直角)、边框和渐变瞬间跳到新尺寸压到还没挪完的周边控件，动画结束又恢复正常，动画上下文里给每个图层显式加一份动画组(fromValue取presentation当前屏显值、时长取inheritedAnimationDuration)，让图层和view本体一起平滑过渡
        if UIView.inheritedAnimationDuration > 0 {

            layer.removeAnimation(forKey: wy_visualSyncAnimationKey)

            // 防止keyPath字符串写错或日后属性改名没报错，统一用#keyPath让编译器对着属性定义校验，属性改名或删除时直接编译报错(运行期keyPath无效只会静默没动画)
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
    fileprivate func wy_refreshVisualLayout() {

        // 没有任何链式视觉图层时不往下走(阴影背景视图存在时mask必定存在，不用单独判)
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
            // 无圆角场景挂在自身上的矩形shadowPath，bounds变了同步换新尺寸矩形，内容不再铺满矩形时撤掉路径回到轮廓阴影
            if wy_isSolidRectShadowContent() {
                UIView.wy_syncLayerGeometry(layer, frame: nil, shadowPath: UIBezierPath(rect: visualFrame).cgPath)
            }else {
                layer.shadowPath = nil
            }
        }
    }

    /// 判断是否还有链式编程生成的视觉图层(圆角mask、边框、渐变、挂在自身上的矩形阴影路径)
    internal func wy_hasChainVisuals() -> Bool {
        if layer.mask?.name == WYLayerName.maskLayer { return true }
        if layer.sublayers?.contains(where: { $0.name == WYLayerName.boardLayer || $0.name == WYLayerName.gradientLayer }) == true { return true }
        // 无圆角场景的阴影挂在自身layer的shadowPath上(没有mask也没有子图层)，但它同样要跟随bounds变化刷新，也算链式视觉(颜色透明说明阴影没真开过，不算)
        let config = wy_visualConfig
        return (config.shadowOpacity > 0) && (wy_colorAlpha(config.shadowColor) > 0) && (layer.shadowPath != nil) && (config.shadowBackgroundView == nil)
    }

    internal func addBorder(edge: UIRectEdge,
                           color: UIColor,
                           thickness: CGFloat) {
        // 重复设置同一条边时原地复用旧边框层改颜色厚度，不先移除再新建(拆层加层会触发图层重挂载，cell复用高频换边框场景开销可见，避免图层树结构抖动)，并清掉历史残留的多余同边层，保证同一条边永远只有一层
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
    internal struct WYLayerName {
        static let maskLayer = "WYBasisKit.maskLayer"
        static let boardLayer = "WYBasisKit.boardLayer"
        static let gradientLayer = "WYBasisKit.gradientLayer"
    }


}

extension CALayer {
    fileprivate struct WYBorderAssociatedKeys {
        static var wy_borderInfoKey: UInt8 = 0
    }

    internal var borderInfo: UIView.WYBorderInfo? {
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
    internal func wy_updateBorderFrames() {

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
