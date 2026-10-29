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
        if (config.cornerRadius > 0) || (config.bezierPath != nil) || layer.masksToBounds {

            if superview == nil {
                //WYLogManager.output("添加阴影和圆角时，请先将view加到父视图上")
                config.shadowBackgroundView?.removeFromSuperview()
                config.shadowBackgroundView = nil
                layer.shadowOpacity = 0
                layer.shadowPath = nil
                return
            }

            // 防每次showVisual都销毁重建阴影背景视图:还在同一个父视图上时直接复用，只有父视图变了才重建
            if let existView = config.shadowBackgroundView, existView.superview === superview {
                shadowView = existView
            }else {
                config.shadowBackgroundView?.removeFromSuperview()

                shadowView = UIView(frame: self.frame)
                shadowView.translatesAutoresizingMaskIntoConstraints = false
                shadowView.isUserInteractionEnabled = false
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
            var translation = CGAffineTransform(translationX: visualFrame.minX, y: visualFrame.minY)
            shadowView.layer.shadowPath = bezierPath.cgPath.copy(using: &translation)
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
        shadowView.layer.shadowColor = config.shadowColor.resolvedColor(with: traitCollection).cgColor
        wy_syncShadowView()
    }

    /// 取颜色的透明度(直接读CGColor的alpha属性，图案色取不到分量时按不透明算)
    fileprivate func wy_colorAlpha(_ color: UIColor) -> CGFloat {
        return color.resolvedColor(with: traitCollection).cgColor.alpha
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
        let native = config.bezierPath == nil && visualFrame == bounds &&
            (config.cornerRadius > 0 || config.borderWidth > 0 || config.nativeVisual)
        if native {
            if !config.nativeVisual {
                config.savedMasksToBounds = layer.masksToBounds
                config.savedMaskedCorners = layer.maskedCorners
            }
            config.nativeVisual = true
            config.maskLayer?.removeFromSuperlayer()
            config.maskLayer = nil
            layer.mask = nil
            config.borderLayer?.removeFromSuperlayer()
            config.borderLayer = nil
            layer.cornerRadius = min(max(config.cornerRadius, 0), min(bounds.width, bounds.height) / 2)
            var corners: CACornerMask = []
            if config.rectCorner.contains(.topLeft) { corners.insert(.layerMinXMinYCorner) }
            if config.rectCorner.contains(.topRight) { corners.insert(.layerMaxXMinYCorner) }
            if config.rectCorner.contains(.bottomLeft) { corners.insert(.layerMinXMaxYCorner) }
            if config.rectCorner.contains(.bottomRight) { corners.insert(.layerMaxXMaxYCorner) }
            layer.maskedCorners = corners
            layer.masksToBounds = config.cornerRadius > 0 ? true : config.savedMasksToBounds
            layer.borderWidth = max(config.borderWidth, 0)
            layer.borderColor = config.borderColor.resolvedColor(with: traitCollection).cgColor
            return
        }
        let wasNative = config.nativeVisual
        wy_restoreNativeClipping()
        config.nativeVisual = false
        if wasNative {
            layer.cornerRadius = 0
            layer.borderWidth = 0
        }

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
            if let existLayer = config.maskLayer, self.layer.mask === existLayer {
                maskLayer = existLayer
            }else {
                maskLayer = CAShapeLayer()
                maskLayer.name = WYLayerName.maskLayer
                self.layer.mask = maskLayer
                config.maskLayer = maskLayer
            }
            maskLayer.frame = visualFrame
            maskLayer.path = bezierPath.cgPath
        }else {
            self.layer.mask = nil
        }

        // 边框(同样原地更新，不满足条件时移除)
        if config.borderWidth > 0 {

            let borderLayer: CAShapeLayer
            if let existLayer = config.borderLayer, existLayer.superlayer === layer {
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
                config.borderLayer = borderLayer
            }
            borderLayer.frame = visualFrame
            borderLayer.path = bezierPath.cgPath
            // 圆角或自定义路径时线宽翻倍，描边外半边被mask裁掉，剩下的一半正好贴着mask边缘内侧(自定义路径和圆角一样有mask，不翻倍边框只剩一半宽度)
            borderLayer.lineWidth = (hasRadius || hasBezierPath) ? (config.borderWidth * 2) : config.borderWidth
            borderLayer.strokeColor = config.borderColor.resolvedColor(with: traitCollection).cgColor
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

        let cgColors: [CGColor] = gradualColors.map { $0.resolvedColor(with: traitCollection).cgColor }

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
        if let existLayer = config.gradientLayer, existLayer.superlayer === layer {
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
            config.gradientLayer = gradientLayer
        }
    }

    /// 移除上次添加的layer
    internal func wy_removeLayer(_ layerKey: String) {

        self.layer.sublayers?.forEach { sublayer in
            if sublayer.name == layerKey {
                sublayer.removeFromSuperlayer()
            }
        }
        if layerKey == WYLayerName.boardLayer { wy_existingVisualConfig?.borderLayer = nil }
        if layerKey == WYLayerName.gradientLayer { wy_existingVisualConfig?.gradientLayer = nil }
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
        let visualFrame = wy_sharedBounds()
        let customPath = config.bezierPath?.cgPath
        if customPath == nil, visualFrame == bounds,
           config.shadowOpacity <= 0 || wy_colorAlpha(config.shadowColor) <= 0 {
            return config.cachedPath
        }
        if config.pathSize == visualFrame.size,
           config.pathOrigin == (customPath == nil ? .zero : visualFrame.origin),
           config.pathCorner == config.rectCorner,
           config.pathRadius == config.cornerRadius,
           config.pathBorderWidth == config.borderWidth,
           config.pathCustom == customPath {
            return config.cachedPath
        }
        config.pathSize = visualFrame.size
        config.pathOrigin = customPath == nil ? .zero : visualFrame.origin
        config.pathCorner = config.rectCorner
        config.pathRadius = config.cornerRadius
        config.pathBorderWidth = config.borderWidth
        config.pathCustom = customPath
        if let bezierPath = config.bezierPath {
            let path = UIBezierPath(cgPath: bezierPath.cgPath)
            path.apply(CGAffineTransform(translationX: -visualFrame.minX, y: -visualFrame.minY))
            config.cachedPath = path
            return path
        }

        let bounds = CGRect(origin: .zero, size: visualFrame.size)

        // 防负数或超过短边一半的值画出畸形路径:半径和内缩量都钳到0~短边一半(与气泡视图的钳法一致)，布局还没出来尺寸为0时钳出0同样安全
        let maxRadius = min(bounds.width, bounds.height) / 2
        let cornerRadius = min(max(config.cornerRadius, 0), maxRadius)

        // 内缩量为边框宽度的一半(同样钳到0~短边一半，防负边宽或超宽边框把矩形内缩成负值)
        let borderInset = min(max(config.borderWidth / 2.0, 0), maxRadius)

        if cornerRadius > 0 {
            // 路径不内缩、直接用设置的半径，配合翻倍线宽让描边只画进mask内侧，防止宽边框压缩可见圆角(把半径减掉半个边框宽时，边框越宽可见圆角越小，边框宽到半径2倍时圆角变直角)
            config.cachedPath = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: config.rectCorner,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            return config.cachedPath
        }

        // 直角时路径内缩半个线宽，让描边外边缘正好贴住视图边缘
        config.cachedPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderInset, dy: borderInset),
            byRoundingCorners: config.rectCorner,
            cornerRadii: CGSize(width: 0.0, height: 0.0)
        )
        return config.cachedPath
    }

    internal func wy_needsVisualApply() -> Bool {
        let config = wy_visualConfig
        if config.appliedRevision != config.revision || config.appliedFrame != wy_sharedBounds() ||
           config.appliedCustomPath != config.bezierPath?.cgPath ||
           traitCollection.hasDifferentColorAppearance(comparedTo: config.appliedTraits) { return true }
        if let colors = config.gradualColors, colors.count > 1,
           config.gradientLayer?.superlayer !== layer { return true }
        if config.nativeVisual {
            return layer.mask != nil || layer.borderWidth != config.borderWidth ||
                layer.cornerRadius != min(config.cornerRadius, min(bounds.width, bounds.height) / 2)
        }
        if config.cornerRadius > 0 || config.bezierPath != nil {
            if config.maskLayer == nil || layer.mask !== config.maskLayer { return true }
        }
        return config.borderWidth > 0 && config.borderLayer?.superlayer !== layer
    }

    internal func wy_didApplyVisual() {
        let config = wy_visualConfig
        config.appliedRevision = config.revision
        config.appliedFrame = wy_sharedBounds()
        config.appliedCustomPath = config.bezierPath?.cgPath
        config.appliedTraits = traitCollection
        config.isApplying = false
    }

    internal func wy_cancelVisualAnimations() {
        wy_existingVisualConfig?.sampledAnimation = nil
        wy_existingVisualConfig?.sampledGeneration = nil
        layer.wy_visualAnimationRevision &+= 1
        layer.animationKeys()?.filter { $0.hasPrefix(UIView.wy_visualSyncAnimationKey) }.forEach { layer.removeAnimation(forKey: $0) }
    }

    internal func wy_restoreNativeClipping() {
        let config = wy_visualConfig
        guard config.nativeVisual else { return }
        layer.masksToBounds = config.savedMasksToBounds
        layer.maskedCorners = config.savedMaskedCorners
        config.nativeVisual = false
    }

    internal func wy_syncShadowView() {
        guard let config = wy_existingVisualConfig, !config.isSyncingShadow,
              let shadowView = config.shadowBackgroundView else { return }
        config.isSyncingShadow = true
        defer { config.isSyncingShadow = false }
        if shadowView.superview !== superview {
            wy_addShadow(bezierPath: wy_sharedBezierPath(), visualFrame: wy_sharedBounds())
            return
        }
        let geometryChanged = shadowView.bounds != bounds || shadowView.center != center ||
            shadowView.transform != transform || shadowView.layer.opacity != layer.opacity
        if shadowView.bounds != bounds { shadowView.bounds = bounds }
        if shadowView.layer.anchorPoint != layer.anchorPoint { shadowView.layer.anchorPoint = layer.anchorPoint }
        if shadowView.center != center { shadowView.center = center }
        if shadowView.transform != transform { shadowView.transform = transform }
        if shadowView.layer.opacity != layer.opacity { shadowView.alpha = CGFloat(layer.opacity) }
        if shadowView.isHidden != layer.isHidden { shadowView.isHidden = layer.isHidden }
        guard geometryChanged else { return }
        config.shadowRevision &+= 1
        let revision = config.shadowRevision
        Task { @MainActor [weak self, weak shadowView] in
            guard let self = self, let shadowView = shadowView,
                  let config = self.wy_existingVisualConfig, config.shadowRevision == revision,
                  config.shadowBackgroundView === shadowView else { return }
            let properties = [#keyPath(CALayer.bounds), #keyPath(CALayer.position), #keyPath(CALayer.transform), #keyPath(CALayer.opacity)]
            func geometry(_ animation: CAAnimation) -> Bool {
                guard let property = (animation as? CAPropertyAnimation)?.keyPath else { return false }
                return properties.contains { property == $0 || property.hasPrefix($0 + ".") }
            }
            shadowView.layer.animationKeys()?.forEach { key in
                if let animation = shadowView.layer.animation(forKey: key), geometry(animation) {
                    shadowView.layer.removeAnimation(forKey: key)
                }
            }
            self.layer.animationKeys()?.forEach { key in
                guard let original = self.layer.animation(forKey: key), geometry(original),
                      let animation = original.copy() as? CAAnimation else { return }
                if animation.beginTime != 0 {
                    animation.beginTime = shadowView.layer.convertTime(animation.beginTime, from: self.layer)
                }
                shadowView.layer.add(animation, forKey: key)
            }
        }
    }

    fileprivate func wy_refreshShadowContent() {
        guard let config = wy_existingVisualConfig, config.isApplied, !config.isApplying,
              config.cornerRadius == 0, config.bezierPath == nil else { return }
        config.isApplying = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        wy_addShadow(bezierPath: wy_sharedBezierPath(), visualFrame: wy_sharedBounds())
        CATransaction.commit()
        config.isApplying = false
    }

    fileprivate func wy_refreshVisualTraits() {
        guard let config = wy_existingVisualConfig else { return }
        if config.isApplied { wy_showVisual() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.sublayers?.forEach { border in
            guard let info = border.borderInfo else { return }
            border.backgroundColor = info.color.resolvedColor(with: traitCollection).cgColor
        }
        CATransaction.commit()
    }

    fileprivate struct WYVisualBoundsAnimation {
        let bounds: [CGRect]
        let beginTime: CFTimeInterval
        let duration: CFTimeInterval
    }

    fileprivate func wy_compositeBoundsAnimation() -> WYVisualBoundsAnimation? {
        let config = wy_visualConfig
        if config.sampledGeneration == config.animationGeneration { return config.sampledAnimation }
        config.sampledGeneration = config.animationGeneration
        config.sampledAnimation = nil
        let animations = layer.animationKeys()?.compactMap { key -> CABasicAnimation? in
            guard let animation = layer.animation(forKey: key) as? CABasicAnimation,
                  let property = animation.keyPath,
                  property == #keyPath(CALayer.bounds) || property.hasPrefix(#keyPath(CALayer.bounds) + ".") else { return nil }
            return animation
        } ?? []
        guard animations.count > 1, let window = window else { return nil }
        let now = layer.convertTime(CACurrentMediaTime(), from: nil)
        let snapshots = animations.map { animation -> CABasicAnimation in
            let copy = animation.copy() as! CABasicAnimation
            if copy.beginTime == 0 { copy.beginTime = now }
            return copy
        }.sorted { !$0.isAdditive && $1.isAdditive }
        let duration = snapshots.map { animation -> Double in
            guard animation.speed > 0 else { return 0 }
            let cycles = max(Double(animation.repeatCount), 1) * (animation.autoreverses ? 2 : 1)
            return animation.beginTime + (animation.duration * cycles - animation.timeOffset) / Double(animation.speed) - now
        }.max() ?? 0
        let sampleCount = ceil(duration * Double(window.screen.maximumFramesPerSecond))
        guard duration > 0, sampleCount.isFinite, sampleCount < Double(Int.max),
              snapshots.allSatisfy({ $0.repeatCount == 0 && !$0.autoreverses }) else { return nil }
        let count = max(Int(sampleCount), 1)
        let model = layer.bounds
        let values = (0...count).map { index -> CGRect in
            let time = now + duration * Double(index) / Double(count)
            var value = model
            for animation in snapshots {
                let elapsed = (time - animation.beginTime) * Double(animation.speed) + animation.timeOffset
                let cycles = max(Double(animation.repeatCount), 1) * (animation.autoreverses ? 2 : 1)
                if elapsed >= animation.duration * cycles && animation.isAdditive { continue }
                let progress = wy_visualAnimationProgress(animation, elapsed: elapsed)
                let from = animation.fromValue as? NSValue
                let to = animation.toValue as? NSValue
                func interpolate(_ a: CGFloat, _ b: CGFloat) -> CGFloat { return a + (b - a) * CGFloat(progress) }
                if animation.keyPath == #keyPath(CALayer.bounds) {
                    let a = from?.cgRectValue ?? .zero, b = to?.cgRectValue ?? model
                    let result = CGRect(x: interpolate(a.origin.x,b.origin.x), y: interpolate(a.origin.y,b.origin.y), width: interpolate(a.width,b.width), height: interpolate(a.height,b.height))
                    if animation.isAdditive {
                        value.origin.x += result.origin.x; value.origin.y += result.origin.y
                        value.size.width += result.width; value.size.height += result.height
                    }else { value = result }
                }else if animation.keyPath == #keyPath(CALayer.bounds) + ".size" {
                    let a = from?.cgSizeValue ?? .zero, b = to?.cgSizeValue ?? model.size
                    let result = CGSize(width: interpolate(a.width,b.width),height: interpolate(a.height,b.height))
                    if animation.isAdditive { value.size.width += result.width; value.size.height += result.height }
                    else { value.size = result }
                }else if animation.keyPath == #keyPath(CALayer.bounds) + ".origin" {
                    let a = from?.cgPointValue ?? .zero, b = to?.cgPointValue ?? model.origin
                    let result = CGPoint(x: interpolate(a.x,b.x),y: interpolate(a.y,b.y))
                    if animation.isAdditive { value.origin.x += result.x; value.origin.y += result.y }
                    else { value.origin = result }
                }
            }
            return value
        }
        let result = WYVisualBoundsAnimation(bounds: values, beginTime: now, duration: duration)
        config.sampledAnimation = result
        return result
    }

    fileprivate func wy_visualPath(in frame: CGRect) -> CGPath {
        let config = wy_visualConfig
        if let custom = config.bezierPath {
            var translation = CGAffineTransform(translationX: -frame.minX, y: -frame.minY)
            return custom.cgPath.copy(using: &translation) ?? custom.cgPath
        }
        let rect = CGRect(origin: .zero, size: frame.size)
        let limit = min(rect.width, rect.height) / 2
        let radius = min(config.cornerRadius, limit)
        let inset = radius > 0 ? 0 : min(config.borderWidth / 2, limit)
        return UIBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), byRoundingCorners: config.rectCorner, cornerRadii: CGSize(width: radius, height: radius)).cgPath
    }

    /// 链式编程的全部视觉配置(整份配置只挂一个关联对象，读写只查一次关联表)
    internal final class WYVisualConfig {

        @MainActor static var hookedClasses: Set<ObjectIdentifier> = []

        @MainActor static func installHooks(for targetClass: UIView.Type) {
            for viewClass in [UIView.self, targetClass] {
                guard hookedClasses.insert(ObjectIdentifier(viewClass)).inserted else { continue }
                wy_swizzlerVisualLifecycle(for: viewClass)
                wy_swizzlerVisualTraits(for: viewClass)
            }
        }

        var revision: UInt = 0
        var appliedRevision: UInt?
        var appliedFrame: CGRect = .null
        var appliedTraits: UITraitCollection?
        var appliedCustomPath: CGPath?
        var isApplied = false
        var isApplying = false
        var isSyncingShadow = false
        var shadowRevision: UInt = 0
        var animationGeneration: UInt = 0
        fileprivate var sampledGeneration: UInt?
        fileprivate var sampledAnimation: WYVisualBoundsAnimation?
        var nativeVisual = false
        var savedMasksToBounds = false
        var savedMaskedCorners: CACornerMask = []
        var maskLayer: CAShapeLayer?
        var borderLayer: CAShapeLayer?
        var gradientLayer: CAGradientLayer?
        var pathSize: CGSize = CGSize(width: -1, height: -1)
        var pathOrigin: CGPoint = .zero
        var pathCorner: UIRectCorner = []
        var pathRadius: CGFloat = -1
        var pathBorderWidth: CGFloat = -1
        var pathCustom: CGPath?
        var cachedPath = UIBezierPath()

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
        let color: UIColor
    }

    /// 监听layer.bounds/transform变化的观察者(销毁时自动停止观察，不需要手动removeObserver)
    internal final class WYBoundsObserver {

        var observation: NSKeyValueObservation?

        var transformObservation: NSKeyValueObservation?
        var observations: [NSKeyValueObservation] = []

        init(view: UIView) {
            observation = view.layer.observe(\.bounds, options: [.new, .old]) { [weak view] _, change in
                // 防后台线程改动layer属性:只处理主线程上的bounds变化，尺寸没变也不重复刷
                guard Thread.isMainThread, let view = view, change.newValue != change.oldValue,
                      view.wy_existingVisualConfig?.isApplying != true else { return }
                view.wy_visualConfig.animationGeneration &+= 1
                view.wy_syncShadowView()
                view.layer.wy_updateBorderFrames()
                view.wy_refreshVisualLayout()
            }
            enableShadowObserving(view: view)
        }

        func enableShadowObserving(view: UIView) {
            guard observations.isEmpty, let config = view.wy_existingVisualConfig,
                  config.shadowOpacity > 0, view.wy_colorAlpha(config.shadowColor) > 0 else { return }
            transformObservation = view.layer.observe(\.transform, options: [.new]) { [weak view] _, _ in
                // 位移、旋转、缩放只改transform不动bounds，靠约束定位的阴影背景视图不会跟着动，把视图当前的transform复制给它让阴影和本体始终贴在一起(在动画上下文里改transform时，这次赋值也会被UIKit做成同拍动画)
                guard Thread.isMainThread, let view = view else { return }
                view.wy_syncShadowView()
            }
            let sync: (CALayer, NSKeyValueObservedChange<CGPoint>) -> Void = { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_syncShadowView()
            }
            observations.append(view.layer.observe(\.position, options: [.new], changeHandler: sync))
            observations.append(view.layer.observe(\.opacity, options: [.new]) { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_syncShadowView()
            })
            observations.append(view.layer.observe(\.isHidden, options: [.new]) { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_syncShadowView()
            })
            observations.append(view.layer.observe(\.backgroundColor, options: [.new]) { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_refreshShadowContent()
            })
            observations.append(view.layer.observe(\.contents, options: [.new]) { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_refreshShadowContent()
            })
            observations.append(view.layer.observe(\.sublayers, options: [.new]) { [weak view] _, _ in
                guard Thread.isMainThread else { return }
                view?.wy_refreshShadowContent()
            })
        }
    }


    /// 视觉图层同步过渡用的动画key(每次先移除同key旧动画再加新的，防快速连点时动画叠加)
    fileprivate static let wy_visualSyncAnimationKey = "WYBasisKit.visualSyncAnimation"

    /// 让视觉图层与view本体同拍过渡(动画上下文里补一份显式动画组再落值，没有动画上下文时禁隐式动画直接落值，frame传nil表示frame不变只更新路径)
    fileprivate static func wy_syncLayerGeometry(_ layer: CALayer, frame: CGRect?, path: CGPath? = nil, shadowPath: CGPath? = nil, cornerRadius: CGFloat? = nil, source: CALayer? = nil) {
        // 改约束动画时bounds监听里靠CATransaction隐式动画同步这些图层，屏幕上圆角mask不参与过渡(动画中圆角变直角)、边框和渐变瞬间跳到新尺寸压到还没挪完的周边控件，动画结束又恢复正常，动画上下文里给每个图层显式加一份动画组(fromValue取presentation当前屏显值、时长取inheritedAnimationDuration)，让图层和view本体一起平滑过渡
            // 防止keyPath字符串写错或日后属性改名没报错，统一用#keyPath让编译器对着属性定义校验，属性改名或删除时直接编译报错(运行期keyPath无效只会静默没动画)
        let presentation = layer.presentation()
        let fromPath = (presentation as? CAShapeLayer)?.path ?? (layer as? CAShapeLayer)?.path
        let fromShadowPath = presentation?.shadowPath ?? layer.shadowPath
        let fromBounds = presentation?.bounds ?? layer.bounds
        let fromPosition = presentation?.position ?? layer.position
        let fromRadius = presentation?.cornerRadius ?? layer.cornerRadius
        let duration = UIView.inheritedAnimationDuration
        let revision = layer.wy_visualAnimationRevision &+ 1
        layer.wy_visualAnimationRevision = revision
        layer.animationKeys()?.filter { $0.hasPrefix(wy_visualSyncAnimationKey) }.forEach { layer.removeAnimation(forKey: $0) }

        // 模型值直接落位，屏幕上的过渡交给上面的动画组，模型上不能再叠隐式动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if let path = path, let shapeLayer = layer as? CAShapeLayer { shapeLayer.path = path }
        if let shadowPath = shadowPath { layer.shadowPath = shadowPath }
        if let frame = frame { layer.frame = frame }
        if let cornerRadius = cornerRadius { layer.cornerRadius = cornerRadius }
        CATransaction.commit()
        guard duration > 0 else { return }
        Task { @MainActor [weak layer, weak source] in
            guard let layer = layer, layer.wy_visualAnimationRevision == revision else { return }
            if let source = source, let owner = source.delegate as? UIView,
               let data = owner.wy_compositeBoundsAnimation() {
                let config = owner.wy_visualConfig
                let visualFrames = data.bounds.map { config.viewBounds == .zero ? $0 : config.viewBounds }
                @MainActor func keyframes(_ property: String, values: [Any]) {
                    let animation = CAKeyframeAnimation(keyPath: property)
                    animation.values = values
                    animation.duration = data.duration
                    animation.beginTime = layer.convertTime(data.beginTime, from: source)
                    animation.calculationMode = .linear
                    layer.add(animation, forKey: wy_visualSyncAnimationKey + "." + property)
                }
                if path != nil {
                    keyframes(#keyPath(CAShapeLayer.path), values: visualFrames.map { owner.wy_visualPath(in: $0) })
                }
                if shadowPath != nil {
                    keyframes(#keyPath(CALayer.shadowPath), values: visualFrames.map { rect -> CGPath in
                        var translation = CGAffineTransform(translationX: rect.minX, y: rect.minY)
                        let path = owner.wy_visualPath(in: rect)
                        return path.copy(using: &translation) ?? path
                    })
                }
                if frame != nil {
                    let frames: [CGRect]
                    if let info = layer.borderInfo {
                        frames = data.bounds.map { rect in
                            switch info.edge {
                            case .top: return CGRect(x: rect.minX,y: rect.minY,width: rect.width,height: info.thickness)
                            case .bottom: return CGRect(x: rect.minX,y: rect.maxY-info.thickness,width: rect.width,height: info.thickness)
                            case .left: return CGRect(x: rect.minX,y: rect.minY,width: info.thickness,height: rect.height)
                            default: return CGRect(x: rect.maxX-info.thickness,y: rect.minY,width: info.thickness,height: rect.height)
                            }
                        }
                    }else { frames = visualFrames }
                    keyframes(#keyPath(CALayer.bounds), values: frames.map { NSValue(cgRect: CGRect(origin: .zero, size: $0.size)) })
                    keyframes(#keyPath(CALayer.position), values: frames.map { NSValue(cgPoint: CGPoint(x: $0.midX,y: $0.midY)) })
                }
                if cornerRadius != nil {
                    keyframes(#keyPath(CALayer.cornerRadius), values: data.bounds.map { min(config.cornerRadius, min($0.width,$0.height)/2) })
                }
                return
            }
            func template(_ keyPath: String) -> CABasicAnimation? {
                guard let source = source else { return nil }
                func find(_ animation: CAAnimation) -> CABasicAnimation? {
                    if let basic = animation as? CABasicAnimation,
                       let property = basic.keyPath,
                       property == keyPath || property.hasPrefix(keyPath + ".") { return basic }
                    if let group = animation as? CAAnimationGroup {
                        return group.animations?.compactMap { find($0) }.first
                    }
                    return nil
                }
                return source.animationKeys()?.compactMap { key in
                    source.animation(forKey: key).flatMap { find($0) }
                }.first
            }
            @MainActor func animate(_ keyPath: String, from: Any?, to: Any?, matching: String) {
                let original = template(matching) ?? template(#keyPath(CALayer.bounds)) ?? template(#keyPath(CALayer.position))
                let animation = (original?.copy() as? CABasicAnimation) ?? CABasicAnimation()
                animation.keyPath = keyPath
                animation.fromValue = from
                animation.toValue = to
                animation.byValue = nil
                animation.isAdditive = false
                animation.isCumulative = false
                if original == nil {
                    animation.duration = duration
                // 公共API拿不到当前动画上下文的自定义曲线，UIView.animate默认曲线就是easeInEaseOut，用同名曲线对齐大多数场景
                    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                }else if animation.beginTime != 0, let source = source {
                    animation.beginTime = layer.convertTime(animation.beginTime, from: source)
                }
                layer.add(animation, forKey: wy_visualSyncAnimationKey + "." + keyPath)
            }
            if let path = path { animate(#keyPath(CAShapeLayer.path), from: fromPath, to: path, matching: #keyPath(CALayer.bounds)) }
            if let shadowPath = shadowPath { animate(#keyPath(CALayer.shadowPath), from: fromShadowPath, to: shadowPath, matching: #keyPath(CALayer.bounds)) }
            if let frame = frame {
                // 防bounds动画值类型不匹配:bounds是CGRect，toValue传CGSize会被桥接成尺寸类型的NSValue，渲染端解不出bounds导致动画中图层尺寸归零(渐变漏底、指定位置边框消失)，必须包成origin为.zero的完整CGRect
                animate(#keyPath(CALayer.bounds), from: fromBounds, to: CGRect(origin: .zero, size: frame.size), matching: #keyPath(CALayer.bounds))
                animate(#keyPath(CALayer.position), from: fromPosition, to: CGPoint(x: frame.midX, y: frame.midY), matching: #keyPath(CALayer.position))
            }
            if let cornerRadius = cornerRadius { animate(#keyPath(CALayer.cornerRadius), from: fromRadius, to: cornerRadius, matching: #keyPath(CALayer.bounds)) }
        }
    }

    /// 视图bounds变化后，把已应用的圆角mask、边框、渐变、阴影路径按新尺寸重算(没有视觉图层时直接返回)
    fileprivate func wy_refreshVisualLayout() {

        // 没有任何链式视觉图层时不往下走(阴影背景视图存在时mask必定存在，不用单独判)
        guard wy_hasChainVisuals() else {
            return
        }

        // 路径和frame整轮只算一次，mask、边框、阴影共用
        let bezierPath: UIBezierPath = wy_sharedBezierPath()
        let visualFrame: CGRect = wy_sharedBounds()
        let config = wy_visualConfig
        config.appliedFrame = visualFrame
        if config.nativeVisual {
            let radius = min(config.cornerRadius, min(bounds.width, bounds.height) / 2)
            if layer.cornerRadius != radius {
                UIView.wy_syncLayerGeometry(layer, frame: nil, cornerRadius: radius, source: layer)
            }
        }

        if let maskLayer = layer.mask as? CAShapeLayer, maskLayer.name == WYLayerName.maskLayer {
            UIView.wy_syncLayerGeometry(maskLayer, frame: visualFrame, path: bezierPath.cgPath, source: layer)
        }

        if let borderLayer = layer.sublayers?.first(where: { $0.name == WYLayerName.boardLayer }) as? CAShapeLayer {
            UIView.wy_syncLayerGeometry(borderLayer, frame: visualFrame, path: bezierPath.cgPath, source: layer)
        }

        if let gradientLayer = layer.sublayers?.first(where: { $0.name == WYLayerName.gradientLayer }) {
            UIView.wy_syncLayerGeometry(gradientLayer, frame: visualFrame, source: layer)
        }

        // 阴影背景视图的位置由约束自动跟随，这里只按新尺寸重算阴影路径
        if let shadowBackgroundView = config.shadowBackgroundView {
            var translation = CGAffineTransform(translationX: visualFrame.minX, y: visualFrame.minY)
            UIView.wy_syncLayerGeometry(shadowBackgroundView.layer, frame: nil, shadowPath: bezierPath.cgPath.copy(using: &translation), source: layer)
        }else if (config.shadowOpacity > 0) && (layer.shadowOpacity > 0) && (layer.shadowPath != nil) {
            // 无圆角场景挂在自身上的矩形shadowPath，bounds变了同步换新尺寸矩形，内容不再铺满矩形时撤掉路径回到轮廓阴影
            if wy_isSolidRectShadowContent() {
                UIView.wy_syncLayerGeometry(layer, frame: nil, shadowPath: UIBezierPath(rect: visualFrame).cgPath, source: layer)
            }else {
                layer.shadowPath = nil
            }
        }
    }

    /// 判断是否还有链式编程生成的视觉图层(圆角mask、边框、渐变、挂在自身上的矩形阴影路径)
    internal func wy_hasChainVisuals() -> Bool {
        if let config = wy_existingVisualConfig, config.isApplied,
           config.nativeVisual && (config.cornerRadius > 0 || config.borderWidth > 0) { return true }
        if wy_existingVisualConfig?.shadowBackgroundView != nil { return true }
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
            existBorder.backgroundColor = color.resolvedColor(with: traitCollection).cgColor
            existBorder.borderInfo = WYBorderInfo(edge: edge, thickness: thickness, color: color)
            sameEdgeBorders.dropFirst().forEach { $0.removeFromSuperlayer() }
            return
        }

        let border = CALayer()
        border.backgroundColor = color.resolvedColor(with: traitCollection).cgColor
        border.borderInfo = WYBorderInfo(edge: edge, thickness: thickness, color: color)
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
        static var visualAnimationRevision: UInt8 = 0
    }

    fileprivate var wy_visualAnimationRevision: UInt {
        get { return objc_getAssociatedObject(self, &WYBorderAssociatedKeys.visualAnimationRevision) as? UInt ?? 0 }
        set { objc_setAssociatedObject(self, &WYBorderAssociatedKeys.visualAnimationRevision, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: bounds.minX, y: bounds.minY,
                                                                    width: bounds.width, height: info.thickness), source: self)
            case .bottom:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: bounds.minX, y: bounds.maxY - info.thickness,
                                                                    width: bounds.width, height: info.thickness), source: self)
            case .left:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: bounds.minX, y: bounds.minY,
                                                                    width: info.thickness, height: bounds.height), source: self)
            case .right:
                UIView.wy_syncLayerGeometry(sublayer, frame: CGRect(x: bounds.maxX - info.thickness, y: bounds.minY,
                                                                    width: info.thickness, height: bounds.height), source: self)
            default:
                break
            }
        }
    }
}

fileprivate func wy_swizzlerVisualLifecycle(for targetClass: UIView.Type) {
    let selector = #selector(UIView.didMoveToSuperview)
    guard let method = wy_getInstanceMethod(targetClass, selector) else { return }
    let originalIMP = method_getImplementation(method)
    typealias Original = @convention(c) (UIView, Selector) -> Void
    let replacement: @convention(block) (UIView) -> Void = { view in
        let original = unsafeBitCast(wy_originalMethodImplementation(for: targetClass, selector: selector, fallback: originalIMP), to: Original.self)
        original(view, selector)
        guard ObjectIdentifier(type(of: view)) == ObjectIdentifier(targetClass) else { return }
        guard let config = view.wy_existingVisualConfig, config.isApplied, !config.isApplying else { return }
        config.isApplying = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.wy_addShadow(bezierPath: view.wy_sharedBezierPath(), visualFrame: view.wy_sharedBounds())
        CATransaction.commit()
        config.isApplying = false
    }
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: replacement)
}

fileprivate func wy_swizzlerVisualTraits(for targetClass: UIView.Type) {
    let selector = #selector(UIView.traitCollectionDidChange(_:))
    guard let method = wy_getInstanceMethod(targetClass, selector) else { return }
    let originalIMP = method_getImplementation(method)
    typealias Original = @convention(c) (UIView, Selector, UITraitCollection?) -> Void
    let replacement: @convention(block) (UIView, UITraitCollection?) -> Void = { view, previous in
        let original = unsafeBitCast(wy_originalMethodImplementation(for: targetClass, selector: selector, fallback: originalIMP), to: Original.self)
        original(view, selector, previous)
        guard ObjectIdentifier(type(of: view)) == ObjectIdentifier(targetClass) else { return }
        guard view.traitCollection.hasDifferentColorAppearance(comparedTo: previous) else { return }
        view.wy_refreshVisualTraits()
    }
    wy_swizzleMethod(for: targetClass, selector: selector, newImpBlock: replacement)
}

fileprivate func wy_visualAnimationProgress(_ animation: CABasicAnimation, elapsed: Double) -> Double {
    guard animation.duration > 0 else { return 1 }
    let cycles = max(Double(animation.repeatCount), 1) * (animation.autoreverses ? 2 : 1)
    if elapsed <= 0 { return 0 }
    if elapsed >= animation.duration * cycles { return animation.autoreverses ? 0 : 1 }
    var time = elapsed.truncatingRemainder(dividingBy: animation.duration)
    if animation.autoreverses && Int(elapsed / animation.duration) % 2 == 1 { time = animation.duration - time }
    if let spring = animation as? CASpringAnimation {
        let mass = spring.mass, stiffness = spring.stiffness, damping = spring.damping
        let omega = sqrt(stiffness / mass)
        let beta = damping / (2 * mass)
        let velocity = spring.initialVelocity
        if beta < omega {
            let frequency = sqrt(omega * omega - beta * beta)
            return 1 - exp(-beta * time) * (cos(frequency * time) + (beta - velocity) / frequency * sin(frequency * time))
        }
        if beta == omega { return 1 - exp(-omega * time) * (1 + (omega - velocity) * time) }
        let delta = sqrt(beta * beta - omega * omega)
        let first = -beta + delta, second = -beta - delta
        let a = (velocity + second) / (first - second)
        return 1 + a * exp(first * time) + (-1 - a) * exp(second * time)
    }
    let fraction = time / animation.duration
    let function = animation.timingFunction ?? CAMediaTimingFunction(name: .default)
    var first: [Float] = [0,0], second: [Float] = [0,0]
    function.getControlPoint(at: 1, values: &first)
    function.getControlPoint(at: 2, values: &second)
    func cubic(_ value: Double, _ a: Float, _ b: Float) -> Double {
        let inverse = 1 - value
        return 3 * inverse * inverse * value * Double(a) + 3 * inverse * value * value * Double(b) + value * value * value
    }
    var low = 0.0, high = 1.0
    while high - low > Double.ulpOfOne.squareRoot() {
        let middle = (low + high) / 2
        if cubic(middle, first[0], second[0]) < fraction { low = middle }else { high = middle }
    }
    return cubic((low + high) / 2, first[1], second[1])
}
