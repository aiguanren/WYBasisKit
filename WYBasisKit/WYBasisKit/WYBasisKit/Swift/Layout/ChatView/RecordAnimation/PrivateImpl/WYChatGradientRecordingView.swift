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
    private var configuration = WYRecordAnimationConfig()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        accessibilityIdentifier = "WYChatRecording.gradient"
        glow.type = .radial
        layer.addSublayer(glow)
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
        hint.font = configuration.gradientHintFont
        hint.textColor = cancelled ? configuration.gradientCancelHintColor : configuration.gradientHintColor
        hint.text = cancelled ? configuration.gradientCancelHint : configuration.gradientRecordingHint.isEmpty ? (mode == .dictation ? configuration.dictationReleaseText : configuration.recordViewTips.onInterior) + " · ↑ " + WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable) : configuration.gradientRecordingHint
        waveform.config = configuration.gradientWaveform
        if cancelled { waveform.config.wavesColor = configuration.gradientCancelWaveformColor }
        accessibilityValue = cancelled ? "cancel" : "recording"
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        func valid(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        let config = configuration
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let height = min(bounds.height, valid(config.gradientHeight))
        glow.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
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
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
