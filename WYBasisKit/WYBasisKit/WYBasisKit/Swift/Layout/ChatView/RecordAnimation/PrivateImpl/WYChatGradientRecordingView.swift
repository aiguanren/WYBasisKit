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
    private let motionHighlight = CAGradientLayer()
    private let motionShadow = CAGradientLayer()
    private let pressGlow = CAGradientLayer()
    private var configuration = WYRecordAnimationConfig()
    private var touchPoint: CGPoint?
    private var motionSettings: [Double] = []
    private var observers: [NSObjectProtocol] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        accessibilityIdentifier = "WYChatRecording.gradient"
        glow.type = .radial
        layer.addSublayer(glow)
        for effect in [motionHighlight, motionShadow, pressGlow] {
            effect.type = .radial
            effect.startPoint = CGPoint(x: 0.5, y: 0.5)
            effect.endPoint = CGPoint(x: 1, y: 1)
            layer.addSublayer(effect)
        }
        pressGlow.opacity = 0
        for name in [UIApplication.didEnterBackgroundNotification, UIApplication.didBecomeActiveNotification, UIAccessibility.reduceMotionStatusDidChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.updateMotion() })
        }
        hint.numberOfLines = 0
        hint.textAlignment = .center
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
        let valid = positions.count >= 2 && positions.count == opacities.count && positions.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 1 } && zip(positions, positions.dropFirst()).allSatisfy { $0.0 <= $0.1 } && opacities.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 1 }
        let colors = (valid ? opacities : defaults.gradientColorOpacities).map { color.withAlphaComponent($0).cgColor }
        let previous = glow.presentation()?.colors ?? glow.colors
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glow.colors = colors
        glow.locations = (valid ? positions : defaults.gradientColorLocations).map { NSNumber(value: Double($0)) }
        glow.startPoint = configuration.gradientStartPoint.x.isFinite && configuration.gradientStartPoint.y.isFinite ? configuration.gradientStartPoint : defaults.gradientStartPoint
        glow.endPoint = configuration.gradientEndPoint.x.isFinite && configuration.gradientEndPoint.y.isFinite ? configuration.gradientEndPoint : defaults.gradientEndPoint
        CATransaction.commit()
        if animated, let previous, duration > 0 {
            let animation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = previous
            animation.toValue = colors
            animation.duration = duration
            glow.add(animation, forKey: "colors")
        }
        backgroundColor = configuration.gradientOverlayColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let highlight = opacity(configuration.gradientMotionHighlightOpacity)
        let shadow = opacity(configuration.gradientMotionShadowOpacity)
        motionHighlight.colors = [configuration.gradientMotionHighlightColor.withAlphaComponent(highlight).cgColor, configuration.gradientMotionHighlightColor.withAlphaComponent(highlight * 0.6).cgColor, UIColor.clear.cgColor]
        motionShadow.colors = [configuration.gradientMotionShadowColor.withAlphaComponent(shadow).cgColor, UIColor.clear.cgColor]
        let press = opacity(configuration.gradientPressOpacity)
        pressGlow.colors = [configuration.gradientPressColor.withAlphaComponent(0).cgColor, configuration.gradientPressColor.withAlphaComponent(press * 0.2).cgColor, configuration.gradientPressColor.withAlphaComponent(press).cgColor, UIColor.clear.cgColor]
        pressGlow.locations = [0, 0.2, 0.55, 1]
        pressGlow.opacity = configuration.gradientPressEnabled && touchPoint != nil ? 1 : 0
        CATransaction.commit()
        hint.font = configuration.gradientHintFont
        hint.textColor = cancelled ? configuration.gradientCancelHintColor : configuration.gradientHintColor
        hint.text = cancelled ? configuration.gradientCancelHint : configuration.gradientRecordingHint.isEmpty ? (mode == .dictation ? configuration.dictationReleaseText : configuration.recordViewTips.onInterior) + " · ↑ " + WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable) : configuration.gradientRecordingHint
        waveform.config = configuration.gradientWaveform
        if cancelled { waveform.config.wavesColor = configuration.gradientCancelWaveformColor }
        accessibilityValue = cancelled ? "cancel" : "recording"
        setNeedsLayout()
    }

    func updateTouchPoint(_ point: CGPoint, animated: Bool) {
        guard point.x.isFinite, point.y.isFinite else { return }
        let first = touchPoint == nil
        touchPoint = CGPoint(x: min(max(0, point.x), bounds.width), y: min(max(0, point.y), bounds.height))
        let previous = pressGlow.presentation()?.position ?? pressGlow.position
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pressGlow.position = touchPoint!
        pressGlow.opacity = configuration.gradientPressEnabled ? 1 : 0
        CATransaction.commit()
        let duration = configuration.gradientPressFollowingDuration
        guard configuration.gradientPressEnabled, duration.isFinite, duration > 0, !UIAccessibility.isReduceMotionEnabled else { return }
        if animated && !first {
            let movement = CABasicAnimation(keyPath: "position")
            movement.fromValue = NSValue(cgPoint: previous)
            movement.toValue = NSValue(cgPoint: pressGlow.position)
            movement.duration = duration
            movement.timingFunction = CAMediaTimingFunction(name: .easeOut)
            pressGlow.add(movement, forKey: "following")
        } else if first {
            let entrance = CABasicAnimation(keyPath: "transform.scale")
            entrance.fromValue = 0.8
            entrance.toValue = 1
            entrance.duration = duration
            pressGlow.add(entrance, forKey: "press")
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { touchPoint = nil; pressGlow.opacity = 0; pressGlow.removeAllAnimations() }
        updateMotion()
    }

    private func opacity(_ value: CGFloat) -> CGFloat { value.isFinite ? min(1, max(0, value)) : 0 }

    private func updateMotion() {
        let config = configuration
        let duration = config.gradientMotionDuration
        let active = window != nil && UIApplication.shared.applicationState != .background && !UIAccessibility.isReduceMotionEnabled && config.gradientMotionEnabled && duration.isFinite && duration > 0 && bounds.width > 0
        guard active else {
            for effect in [motionHighlight, motionShadow] { effect.removeAllAnimations(); effect.isHidden = true }
            glow.removeAnimation(forKey: "flow")
            motionSettings = []
            return
        }
        let amplitude = config.gradientMotionAmplitude
        let x = amplitude.width.isFinite ? min(bounds.width / 4, max(0, amplitude.width)) : 0
        let y = amplitude.height.isFinite ? min(bounds.height / 4, max(0, amplitude.height)) : 0
        let scale = config.gradientMotionScale.isFinite ? min(0.5, max(0, config.gradientMotionScale)) : 0
        let settings = [duration, Double(x), Double(y), Double(scale), Double(bounds.width), Double(bounds.height), Double(glow.startPoint.x), Double(glow.startPoint.y), Double(glow.endPoint.x), Double(glow.endPoint.y)]
        guard settings != motionSettings else { return }
        motionSettings = settings
        let drift = CGSize(width: x / max(1, bounds.width) * 0.3, height: y / max(1, glow.bounds.height) * 0.3)
        let baseMotion = CAAnimationGroup()
        baseMotion.animations = ["startPoint", "endPoint"].map { key in
            let point = key == "startPoint" ? glow.startPoint : glow.endPoint
            let animation = CABasicAnimation(keyPath: key)
            animation.fromValue = NSValue(cgPoint: CGPoint(x: point.x - drift.width, y: point.y - drift.height))
            animation.toValue = NSValue(cgPoint: CGPoint(x: point.x + drift.width, y: point.y + drift.height))
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            return animation
        }
        baseMotion.duration = duration / 2
        baseMotion.autoreverses = true
        baseMotion.repeatCount = .infinity
        glow.add(baseMotion, forKey: "flow")
        for (index, effect) in [motionHighlight, motionShadow].enumerated() {
            effect.isHidden = false
            let sign: CGFloat = index == 0 ? 1 : -1
            let center = effect.position
            let movement = CAKeyframeAnimation(keyPath: "position")
            movement.values = [CGPoint(x: center.x - x * sign, y: center.y - y), CGPoint(x: center.x + x * sign, y: center.y + y), CGPoint(x: center.x + x * sign * 0.3, y: center.y - y * 0.5), CGPoint(x: center.x - x * sign, y: center.y - y)].map { NSValue(cgPoint: $0) }
            movement.calculationMode = .cubic
            let expansion = CAKeyframeAnimation(keyPath: "transform.scale")
            expansion.values = [1 - scale, 1 + scale, 1 - scale * 0.5, 1 - scale]
            expansion.calculationMode = .cubic
            let brightness = CAKeyframeAnimation(keyPath: "opacity")
            brightness.values = [0.5, 1, 0.65, 0.5]
            brightness.calculationMode = .cubic
            let animation = CAAnimationGroup()
            animation.animations = [movement, expansion, brightness]
            animation.duration = duration * (index == 0 ? 1 : 1.3)
            animation.repeatCount = .infinity
            effect.add(animation, forKey: "flow")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        func valid(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        let config = configuration
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let height = min(bounds.height, valid(config.gradientHeight))
        glow.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
        motionHighlight.frame = CGRect(x: bounds.width * 0.12, y: bounds.height - height * 0.75, width: bounds.width * 0.72, height: height * 0.85)
        motionShadow.frame = CGRect(x: bounds.width * 0.3, y: bounds.height - height * 0.65, width: bounds.width * 0.6, height: height * 0.8)
        pressGlow.bounds = CGRect(origin: .zero, size: CGSize(width: min(bounds.width, valid(config.gradientPressSize.width)), height: min(bounds.height, valid(config.gradientPressSize.height))))
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

    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
