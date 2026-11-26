//
//  WYChatGradientRecordingView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/16.
//

import UIKit

/// 底部渐变录音提示与声波
final class WYChatGradientRecordingView: UIView {
    let waveform = WYSoundWavesView()
    let hint = UILabel()
    private let glow = CAGradientLayer()
    private let waveformMask = CAGradientLayer()
    private let flow = CALayer()
    private let flowMask = CALayer()
    private let flowLight = CALayer()
    private let pressGlow = CAGradientLayer()
    private var configuration = WYRecordAnimationConfig()
    private var touchPoint: CGPoint?
    private var motionLink: CADisplayLink?
    private var motionStart: CFTimeInterval?
    private var gradientStops: [CGFloat] = []
    private var highlight: (r: CGFloat, g: CGFloat, b: CGFloat) = (r: 1.0, g: 1.0, b: 1.0)
    private var shadow: (r: CGFloat, g: CGFloat, b: CGFloat) = (r: 0.0, g: 0.0, b: 0.0)
    private var observers: [NSObjectProtocol] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        accessibilityIdentifier = "WYChatRecording.gradient"
        glow.type = .radial
        layer.addSublayer(glow)
        flow.mask = flowMask
        flow.isHidden = true
        flowLight.isHidden = true
        layer.addSublayer(flow)
        layer.addSublayer(flowLight)
        pressGlow.type = .radial
        pressGlow.opacity = 0
        layer.addSublayer(pressGlow)
        for name in [UIApplication.didEnterBackgroundNotification, UIApplication.didBecomeActiveNotification, UIAccessibility.reduceMotionStatusDidChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.updateMotion() })
        }
        hint.accessibilityIdentifier = "WYChatRecording.gradientHint"
        addSubview(hint)
        addSubview(waveform)
        waveformMask.startPoint = CGPoint(x: 0, y: 0.5)
        waveformMask.endPoint = CGPoint(x: 1, y: 0.5)
        waveformMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
        waveform.layer.mask = waveformMask
    }

    func refresh(configuration: WYRecordAnimationConfig, cancelled: Bool, mode: WYChatRecordingMode, animated: Bool) {
        self.configuration = configuration
        let color = cancelled ? configuration.gradientCancelColor : configuration.gradientRecordingColor
        let duration = configuration.gradientTransitionDuration.isFinite ? max(0, configuration.gradientTransitionDuration) : 0
        let defaults = WYRecordAnimationConfig()
        let positions = configuration.gradientColorLocations
        let opacities = configuration.gradientColorOpacities
        let valid = Self.validStops(positions: positions, opacities: opacities)
        let gradientOpacities = valid ? opacities : defaults.gradientColorOpacities
        let colors = gradientOpacities.map { color.withAlphaComponent($0).cgColor }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let transition = animated && !UIAccessibility.isReduceMotionEnabled ? duration : 0
        setColors(colors, on: glow, duration: transition)
        glow.locations = (valid ? positions : defaults.gradientColorLocations).map { NSNumber(value: Double($0)) }
        glow.startPoint = configuration.gradientStartPoint.x.isFinite && configuration.gradientStartPoint.y.isFinite ? configuration.gradientStartPoint : defaults.gradientStartPoint
        glow.endPoint = configuration.gradientEndPoint.x.isFinite && configuration.gradientEndPoint.y.isFinite ? configuration.gradientEndPoint : defaults.gradientEndPoint
        backgroundColor = configuration.gradientOverlayColor
        gradientStops = Self.gradientRamp(
            positions: valid ? positions : defaults.gradientColorLocations,
            opacities: gradientOpacities
        )
        highlight = Self.rgb(configuration.gradientMotionHighlightColor.resolvedColor(with: traitCollection), fallback: 1)
        shadow = Self.rgb(configuration.gradientMotionShadowColor.resolvedColor(with: traitCollection), fallback: 0)
        let previousColor = flow.presentation()?.backgroundColor ?? flow.backgroundColor
        let flowColor = color.withAlphaComponent(1).cgColor
        flow.backgroundColor = flowColor
        flow.removeAnimation(forKey: "backgroundColor")
        if transition > 0, let previousColor {
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = previousColor
            animation.toValue = flowColor
            animation.duration = transition
            flow.add(animation, forKey: "backgroundColor")
        }
        let pressColor = configuration.gradientPressColor
        let pressOpacity = opacity(configuration.gradientPressOpacity)
        let pressPositions = configuration.gradientPressLocations
        let pressOpacities = configuration.gradientPressOpacities
        let validPressStops = Self.validStops(positions: pressPositions, opacities: pressOpacities)
        pressGlow.locations = (validPressStops ? pressPositions : defaults.gradientPressLocations).map { NSNumber(value: Double($0)) }
        pressGlow.colors = (validPressStops ? pressOpacities : defaults.gradientPressOpacities).map { pressColor.withAlphaComponent(pressOpacity * $0).cgColor }
        pressGlow.startPoint = Self.finitePoint(configuration.gradientPressStartPoint, fallback: defaults.gradientPressStartPoint)
        pressGlow.endPoint = Self.finitePoint(configuration.gradientPressEndPoint, fallback: defaults.gradientPressEndPoint)
        pressGlow.opacity = configuration.gradientPressEnabled && touchPoint != nil ? 1 : 0
        CATransaction.commit()
        hint.font = configuration.gradientHintFont
        hint.numberOfLines = max(0, configuration.gradientHintNumberOfLines)
        hint.textAlignment = configuration.gradientHintTextAlignment
        hint.textColor = cancelled ? configuration.gradientCancelHintColor : configuration.gradientHintColor
        hint.text = cancelled ? configuration.gradientCancelHint : configuration.gradientRecordingHint.isEmpty ? (mode == .dictation ? configuration.dictationReleaseText : configuration.recordViewTips.onInterior) + configuration.gradientCancelInstruction : configuration.gradientRecordingHint
        waveform.config = configuration.gradientWaveform
        if cancelled { waveform.config.wavesColor = configuration.gradientCancelWaveformColor }
        accessibilityValue = cancelled ? "cancel" : "recording"
        setNeedsLayout()
    }

    func updateTouchPoint(_ point: CGPoint, animated: Bool) {
        guard point.x.isFinite, point.y.isFinite else { return }
        let first = touchPoint == nil
        let duration = configuration.gradientPressFollowingDuration
        let animates = configuration.gradientPressEnabled && duration.isFinite && duration > 0 && !UIAccessibility.isReduceMotionEnabled
        let previous = pressGlow.presentation()?.position ?? pressGlow.position
        touchPoint = point
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pressGlow.position = point
        pressGlow.opacity = configuration.gradientPressEnabled ? 1 : 0
        CATransaction.commit()
        guard animates else {
            pressGlow.removeAllAnimations()
            return
        }
        if animated && !first {
            let movement = CABasicAnimation(keyPath: "position")
            movement.fromValue = NSValue(cgPoint: previous)
            movement.toValue = NSValue(cgPoint: pressGlow.position)
            movement.duration = duration
            movement.timingFunction = CAMediaTimingFunction(name: .easeOut)
            pressGlow.add(movement, forKey: "following")
        } else if first {
            let entrance = CABasicAnimation(keyPath: "transform.scale")
            entrance.fromValue = wy_chatNonnegative(configuration.gradientPressEntranceScale)
            entrance.toValue = 1
            entrance.duration = duration
            pressGlow.add(entrance, forKey: "press")
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            touchPoint = nil
            pressGlow.opacity = 0
            pressGlow.removeAllAnimations()
        }
        updateMotion()
    }

    private func opacity(_ value: CGFloat) -> CGFloat { value.isFinite ? min(1, max(0, value)) : 0 }

    private func setColors(_ colors: [CGColor], on layer: CAGradientLayer, duration: TimeInterval) {
        let previous = layer.presentation()?.colors ?? layer.colors
        layer.colors = colors
        layer.removeAnimation(forKey: "colors")
        guard duration > 0, let previous, previous.count == colors.count else { return }
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = previous
        animation.toValue = colors
        animation.duration = duration
        layer.add(animation, forKey: "colors")
    }

    private static func rgb(_ color: UIColor, fallback: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var red = fallback, green = fallback, blue = fallback
        if !color.getRed(&red, green: &green, blue: &blue, alpha: nil) { return (fallback, fallback, fallback) }
        return (min(1, max(0, red)), min(1, max(0, green)), min(1, max(0, blue)))
    }

    private static func validStops(positions: [CGFloat], opacities: [CGFloat]) -> Bool {
        positions.count >= 2 && positions.count == opacities.count
            && positions.allSatisfy { (0...1).contains($0) }
            && zip(positions, positions.dropFirst()).allSatisfy { $0.0 <= $0.1 }
            && opacities.allSatisfy { (0...1).contains($0) }
    }

    private static func finitePoint(_ point: CGPoint, fallback: CGPoint) -> CGPoint {
        point.x.isFinite && point.y.isFinite ? point : fallback
    }

    private static func gradientRamp(positions: [CGFloat], opacities: [CGFloat]) -> [CGFloat] {
        var stop = 0
        return (0...255).map { index in
            let location = CGFloat(index) / 255
            while stop + 1 < positions.count && positions[stop + 1] <= location { stop += 1 }
            guard location > positions[stop], stop + 1 < positions.count else { return opacities[stop] }
            let fraction = (location - positions[stop]) / (positions[stop + 1] - positions[stop])
            return opacities[stop] + (opacities[stop + 1] - opacities[stop]) * fraction
        }
    }

    private func updateMotion() {
        let config = configuration
        let duration = config.gradientMotionDuration
        let reducedMotion = UIAccessibility.isReduceMotionEnabled
        if reducedMotion { pressGlow.removeAllAnimations() }
        let radialWidth = abs(glow.endPoint.x - glow.startPoint.x)
        let radialHeight = abs(glow.endPoint.y - glow.startPoint.y)
        let active = window != nil && UIApplication.shared.applicationState != .background && !reducedMotion
            && config.gradientMotionEnabled && duration.isFinite && duration > 0
            && glow.bounds.width > 0 && glow.bounds.height > 0
            && radialWidth.isFinite && radialWidth > 0 && radialHeight.isFinite && radialHeight > 0
            && !gradientStops.isEmpty
        if active {
            let framesPerSecond = min(120, max(1, config.gradientMotionFramesPerSecond))
            if let motionLink {
                if motionLink.preferredFramesPerSecond != framesPerSecond { motionLink.preferredFramesPerSecond = framesPerSecond }
                return
            }
            let target = WYChatGradientMotionTarget(view: self)
            let link = CADisplayLink(target: target, selector: #selector(WYChatGradientMotionTarget.tick(_:)))
            link.preferredFramesPerSecond = framesPerSecond
            link.add(to: .main, forMode: .common)
            motionLink = link
        } else {
            motionLink?.invalidate()
            motionLink = nil
            motionStart = nil
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            glow.isHidden = false
            flow.isHidden = true
            flowLight.isHidden = true
            flowMask.contents = nil
            flowLight.contents = nil
            CATransaction.commit()
        }
    }

    fileprivate func drawMotion(at timestamp: CFTimeInterval) {
        let start = motionStart ?? timestamp
        motionStart = start
        let config = configuration
        let time = (timestamp - start) / max(0.12, config.gradientMotionDuration)
        let phase = time.truncatingRemainder(dividingBy: 1)
        if let mask = config.gradientMotionMaskProvider?(phase, glow.bounds.size)?.cgImage {
            wy_setMotionImages(mask: mask, light: nil)
            return
        }
        let width = Int(min(256, max(2, wy_chatNonnegative(config.gradientMotionRenderSize.width))))
        let height = Int(min(256, max(2, wy_chatNonnegative(config.gradientMotionRenderSize.height))))
        let maximumAmplitude = opacity(config.gradientMotionMaximumAmplitudeRatio)
        let xAmplitude = min(maximumAmplitude, opacity(config.gradientMotionAmplitude.width / glow.bounds.width))
        let yAmplitude = min(maximumAmplitude, opacity(config.gradientMotionAmplitude.height / glow.bounds.height))
        let turbulence = min(opacity(config.gradientMotionMaximumTurbulence), opacity(config.gradientMotionScale))
        let highlightOpacity = opacity(config.gradientMotionHighlightOpacity)
        let shadowOpacity = opacity(config.gradientMotionShadowOpacity)
        let origin = glow.startPoint
        let radiusX = abs(glow.endPoint.x - origin.x)
        let radiusY = abs(glow.endPoint.y - origin.y)
        let leftFlare = ShoulderFlare(time: CGFloat(time), rate: 2.55, phase: 0.18, direction: 1)
        let rightFlare = ShoulderFlare(time: CGFloat(time), rate: 2.12, phase: 0.64, direction: -1)
        var maskPixels = [UInt8](repeating: 0, count: width * height * 2)
        var lightPixels = [UInt8](repeating: 0, count: width * height * 4)

        for row in 0..<height {
            let y = CGFloat(row) / CGFloat(height - 1)
            // 根部的摆幅小一些，同一阵起伏先经过底部，再向上延伸。
            let phase = CGFloat(time) + y * 0.62
            let edge = min(1, y * 7, (1 - y) * 3)
            let upper = Self.smoothStep((0.64 - y) / 0.30)
            let sway = (0.76 * sin(4.6 * phase) + 0.24 * sin(7.3 * phase + 0.8)) * (1 - y) * edge
            let mainCenter = 0.5 + xAmplitude * sin(3.1 * phase + 0.5)
            let mainWidth = 0.25 + 0.035 * sin(3.9 * phase)
            let mainHeight = 0.72 + 0.14 * sin(4.4 * phase - 0.7)
            let leftHeight = 0.12 + 0.42 * (0.5 + 0.5 * sin(5.2 * phase + 1.2))
            let rightHeight = 0.1 + 0.44 * (0.5 + 0.5 * sin(4.1 * phase + 3.4))
            for column in 0..<width {
                let x = CGFloat(column) / CGFloat(width - 1)
                let warpedX = x - 1.5 * xAmplitude * sway
                // 宽缓的中央火势与两侧起伏叠在同一片光里，较弱的一侧会融入轮廓。
                let main = mainHeight * Self.roundedPeak(warpedX, center: mainCenter, width: mainWidth)
                let left = leftHeight * Self.roundedPeak(warpedX, center: 0.19 + 0.7 * (mainCenter - 0.5), width: 0.17)
                let right = rightHeight * Self.roundedPeak(warpedX, center: 0.81 + 0.6 * (mainCenter - 0.5), width: 0.18)
                let rise = main + left + right
                let leftSample = leftFlare.sample(x: warpedX, y: y)
                let rightSample = rightFlare.sample(x: warpedX, y: y)
                let front = leftSample.front + rightSample.front - leftSample.front * rightSample.front
                let wake = leftSample.wake + rightSample.wake - leftSample.wake * rightSample.wake
                // 两肩的亮纹掀起局部圆弧，随后从上缘向火焰内部淡去。
                let flare = (front - 0.48 * wake) * upper
                let warpedY = y + yAmplitude * (0.56 * (rise - 0.23) + 1.35 * flare) * edge
                let distance = hypot((warpedX - origin.x) / radiusX, (warpedY - origin.y) / radiusY)
                let stop = min(1, distance) * 255
                let lower = Int(stop)
                let next = min(255, lower + 1)
                let coverage = gradientStops[lower] + (gradientStops[next] - gradientStops[lower]) * (stop - CGFloat(lower))
                let index = row * width + column
                maskPixels[index * 2] = UInt8(255 * min(1, max(0, coverage)))
                maskPixels[index * 2 + 1] = maskPixels[index * 2]

                let light = (0.78 * wake - 0.52 * front) * upper * edge * coverage * (0.72 + turbulence)
                let amount = 255 * min(1, abs(light)) * (light >= 0 ? highlightOpacity : shadowOpacity)
                let color = light >= 0 ? highlight : shadow
                lightPixels[index * 4] = UInt8(amount * color.r)
                lightPixels[index * 4 + 1] = UInt8(amount * color.g)
                lightPixels[index * 4 + 2] = UInt8(amount * color.b)
                lightPixels[index * 4 + 3] = UInt8(amount)
            }
        }

        wy_setMotionImages(
            mask: Self.makeImage(maskPixels, width: width, height: height, space: CGColorSpaceCreateDeviceGray()),
            light: Self.makeImage(lightPixels, width: width, height: height, space: CGColorSpaceCreateDeviceRGB())
        )
    }

    private func wy_setMotionImages(mask: CGImage?, light: CGImage?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        flowMask.contents = mask
        flowLight.contents = light
        glow.isHidden = mask != nil
        flow.isHidden = mask == nil
        flowLight.isHidden = mask == nil || light == nil
        CATransaction.commit()
    }

    private static func roundedPeak(_ x: CGFloat, center: CGFloat, width: CGFloat) -> CGFloat {
        let distance = (x - center) / width
        return exp(-distance * distance)
    }

    private static func smoothStep(_ value: CGFloat) -> CGFloat {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }

    private struct ShoulderFlare {
        let center: CGPoint
        let strength: CGFloat
        let direction: CGFloat

        init(time: CGFloat, rate: CGFloat, phase: CGFloat, direction: CGFloat) {
            let clock = time * rate + phase + 0.16 * sin(5.1 * time + phase * 4)
            let cycle = floor(clock)
            let age = clock - cycle
            let travel = age * (2 - age)
            let offset = direction * (0.22 * travel - 0.31) + 0.05 * sin(time * 5 + phase * 3)
            center = CGPoint(x: 0.5 + offset, y: 0.45 - 0.31 * travel)
            let ignition = WYChatGradientRecordingView.smoothStep(age / 0.19)
            let fade = WYChatGradientRecordingView.smoothStep((0.86 - age) / 0.62)
            strength = ignition * fade * (0.78 + 0.22 * sin(2.38 * cycle + phase * 7))
            self.direction = direction
        }

        func sample(x: CGFloat, y: CGFloat) -> (front: CGFloat, wake: CGFloat) {
            let offset = x - center.x
            let arc = center.y + 0.8 * offset * offset - 0.26 * direction * offset
            let weight = strength * WYChatGradientRecordingView.roundedPeak(x, center: center.x, width: 0.27)
            return (weight * WYChatGradientRecordingView.roundedPeak(y, center: arc, width: 0.12),
                    weight * WYChatGradientRecordingView.roundedPeak(y, center: arc + 0.12, width: 0.15))
        }
    }

    private static func makeImage(_ bytes: [UInt8], width: Int, height: Int, space: CGColorSpace) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        let components = space.numberOfComponents + 1
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: components * 8,
                       bytesPerRow: width * components, space: space,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        func valid(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        let config = configuration
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let height = min(bounds.height, valid(config.gradientHeight))
        glow.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
        flow.frame = glow.frame
        flowMask.frame = flow.bounds
        flowLight.frame = glow.frame
        let pressSize = config.gradientPressSize
        pressGlow.bounds = CGRect(x: 0, y: 0, width: min(bounds.width, valid(pressSize.width)), height: min(bounds.height, valid(pressSize.height)))
        if let touchPoint { pressGlow.position = touchPoint }
        CATransaction.commit()
        let width = min(bounds.width, valid(config.gradientWaveformSize.width))
        let waveHeight = min(bounds.height, valid(config.gradientWaveformSize.height))
        waveform.frame = CGRect(x: (bounds.width - width) / 2, y: max(0, bounds.height - safeAreaInsets.bottom - valid(config.gradientWaveformBottomOffset) - waveHeight), width: width, height: waveHeight)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        waveformMask.frame = waveform.bounds
        let fade = config.gradientWaveformEdgeFade.isFinite ? min(0.5, max(0, config.gradientWaveformEdgeFade)) : 0
        waveformMask.locations = [0, NSNumber(value: Double(fade)), NSNumber(value: Double(1 - fade)), 1]
        CATransaction.commit()
        let insets = config.gradientHintInsets
        let textWidth = max(0, bounds.width - valid(insets.left) - valid(insets.right))
        let textHeight = min(waveform.frame.minY, hint.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height + valid(insets.top) + valid(insets.bottom))
        hint.frame = CGRect(x: valid(insets.left), y: max(0, waveform.frame.minY - valid(config.gradientHintSpacing) - textHeight), width: textWidth, height: textHeight)
        updateMotion()
    }

    deinit {
        motionLink?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}


private final class WYChatGradientMotionTarget: NSObject {
    private weak var view: WYChatGradientRecordingView?

    init(view: WYChatGradientRecordingView) {
        self.view = view
    }

    @objc func tick(_ link: CADisplayLink) {
        view?.drawMotion(at: link.timestamp)
    }
}
