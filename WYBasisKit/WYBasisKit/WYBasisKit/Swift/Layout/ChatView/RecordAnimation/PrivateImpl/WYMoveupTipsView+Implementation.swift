//
//  WYMoveupTipsView+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYMoveUpTipsViewPrivateState {
    var actionTipsState: WYMoveUpTipsState = .cancel
}

/// 录音操作按钮样式与状态
extension WYMoveUpTipsView {
    func wy_actionSize(touched: Bool) -> CGSize {
        let config = recordAnimationConfig
        if config.actionStyle == .curved {
            let scale = min(1, max(1, superview?.bounds.width ?? UIDevice.wy_screenWidth) / max(1, UIDevice.wy_screenWidth))
            return CGSize(width: (config.curvedActionSize.width.isFinite ? max(1, config.curvedActionSize.width) : 1) * scale, height: (config.curvedActionSize.height.isFinite ? max(1, config.curvedActionSize.height) : 1) * scale)
        }
        let diameter = max(1, touched ? config.moveUpButtonDiameter.onInterior : config.moveUpButtonDiameter.onExternal)
        return CGSize(width: diameter, height: diameter)
    }

    func wy_refreshAction(tipsState: WYMoveUpTipsState, isTouched: Bool) {
        let config = recordAnimationConfig
        state.actionTipsState = tipsState
        let cancel = tipsState == .cancel
        moveUpView.accessibilityIdentifier = cancel ? "WYChatRecording.cancel" : "WYChatRecording.transcribe"
        let interior = cancel ? config.cancelRecordViewTextInfoForInterior : config.transferViewTextInfoForInterior
        let exterior = cancel ? config.cancelRecordViewTextInfoForExternal : config.transferViewTextInfoForExternal
        moveUpView.isSelected = isTouched
        tipsView.font = config.tipsInfoForMoveUp.font
        tipsView.textColor = config.tipsInfoForMoveUp.color
        tipsView.text = isTouched ? (cancel ? config.cancelRecordViewText.tips : config.transferViewText.tips) : ""
        let title = cancel ? config.cancelRecordViewText.onInterior : config.transferViewText.onInterior
        moveUpView.setTitle(title, for: .normal)
        moveUpView.setTitle(title, for: .selected)
        moveUpView.setTitleColor(exterior.color, for: .normal)
        moveUpView.setTitleColor(interior.color, for: .selected)
        moveUpView.titleLabel?.font = isTouched ? interior.font : exterior.font
        let size = wy_actionSize(touched: isTouched)
        if config.actionStyle == .curved {
            moveUpView.setBackgroundImage(nil, for: .normal)
            moveUpView.setBackgroundImage(nil, for: .selected)
            moveUpView.backgroundColor = isTouched ? config.curvedActionColors.selected : config.curvedActionColors.normal
            moveUpView.layer.cornerRadius = 0
            if moveUpView.layer.mask == nil { moveUpView.layer.mask = CAShapeLayer() }
        } else {
            moveUpView.backgroundColor = .clear
            moveUpView.layer.cornerRadius = 0
            moveUpView.layer.mask = nil
            moveUpView.titleLabel?.transform = .identity
            moveUpView.setBackgroundImage(cancel ? config.cancelRecordViewImage.onExternal : config.transferViewImage.onExternal, for: .normal)
            moveUpView.setBackgroundImage(cancel ? config.cancelRecordViewImage.onInterior : config.transferViewImage.onInterior, for: .selected)
        }
        let angle = config.actionStyle == .curved ? config.curvedActionTiltAngle : config.moveUpViewDeviationAngle
        moveUpView.transform = config.supportSpeechRecognition ? CGAffineTransform(rotationAngle: angle.isFinite ? (cancel ? -angle : angle) : 0) : .identity
        moveUpView.snp.updateConstraints { make in make.size.equalTo(size) }
        tipsView.snp.updateConstraints { make in make.height.equalTo(tipsView.font.lineHeight) }
        moveUpView.setNeedsLayout()
        setNeedsLayout()
    }

    func wy_containsActionPoint(_ point: CGPoint) -> Bool {
        guard moveUpView.bounds.contains(point) else { return false }
        if let path = (moveUpView.layer.mask as? CAShapeLayer)?.path { return path.contains(point) }
        let bounds = moveUpView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return false }
        let x = (point.x - bounds.midX) / (bounds.width / 2)
        let y = (point.y - bounds.midY) / (bounds.height / 2)
        return x * x + y * y <= 1
    }

    func wy_layoutAction() {
        guard recordAnimationConfig.actionStyle == .curved, let mask = moveUpView.layer.mask as? CAShapeLayer else { return }
        let size = moveUpView.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        let configured = recordAnimationConfig.curvedActionBendHeight
        let configuredWidth = recordAnimationConfig.curvedActionSize.width
        let scale = configuredWidth.isFinite && configuredWidth > 0 ? min(1, size.width / configuredWidth) : 1
        let bend = min(size.height / 2, configured.isFinite ? max(0, configured) * scale : 0)
        let halfBand = (size.height - bend) / 2
        let corner = recordAnimationConfig.curvedActionCornerRadius
        let radius = min(size.width / 2, halfBand, corner.isFinite ? max(0, corner) * scale : 0)
        let path = UIBezierPath()
        var arcCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        var arcRadius: CGFloat = 0
        let limit = max(0, size.width / 2 - radius)
        var lower: CGFloat = 0
        var upper = limit
        if bend > 0 && limit > 0 {
            for _ in 0..<24 {
                let chord = (lower + upper) / 2
                let extent = chord + (halfBand - radius) * 2 * chord * bend / (chord * chord + bend * bend)
                if extent < limit { lower = chord } else { upper = chord }
            }
            let chord = (lower + upper) / 2
            let candidate = (chord * chord + bend * bend) / (2 * bend)
            if chord > bend && candidate > halfBand {
                arcRadius = candidate
                arcCenter.y = halfBand + candidate
                let angle = 2 * atan2(bend, chord)
                let start = -CGFloat.pi / 2 - angle
                let end = -CGFloat.pi / 2 + angle
                func point(_ angle: CGFloat, _ distance: CGFloat) -> CGPoint {
                    CGPoint(x: arcCenter.x + cos(angle) * distance, y: arcCenter.y + sin(angle) * distance)
                }
                func capCenter(_ angle: CGFloat, outer: Bool) -> CGPoint {
                    point(angle, candidate + (outer ? 1 : -1) * (halfBand - radius))
                }
                path.addArc(withCenter: arcCenter, radius: candidate + halfBand, startAngle: start, endAngle: end, clockwise: true)
                if radius > 0 {
                    path.addArc(withCenter: capCenter(end, outer: true), radius: radius, startAngle: end, endAngle: end + .pi / 2, clockwise: true)
                    let inner = capCenter(end, outer: false)
                    path.addLine(to: CGPoint(x: inner.x - sin(end) * radius, y: inner.y + cos(end) * radius))
                    path.addArc(withCenter: inner, radius: radius, startAngle: end + .pi / 2, endAngle: end + .pi, clockwise: true)
                } else { path.addLine(to: point(end, candidate - halfBand)) }
                path.addArc(withCenter: arcCenter, radius: candidate - halfBand, startAngle: end, endAngle: start, clockwise: false)
                if radius > 0 {
                    path.addArc(withCenter: capCenter(start, outer: false), radius: radius, startAngle: start + .pi, endAngle: start + .pi * 1.5, clockwise: true)
                    let outer = capCenter(start, outer: true)
                    path.addLine(to: CGPoint(x: outer.x + sin(start) * radius, y: outer.y - cos(start) * radius))
                    path.addArc(withCenter: outer, radius: radius, startAngle: start + .pi * 1.5, endAngle: start + .pi * 2, clockwise: true)
                } else { path.addLine(to: point(start, candidate + halfBand)) }
                path.close()
            }
        }
        if path.isEmpty { path.append(UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: radius)) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.frame = moveUpView.bounds
        mask.path = path.cgPath
        CATransaction.commit()
        let titleOffset = recordAnimationConfig.curvedActionTitleOffsetX
        let inset = recordAnimationConfig.supportSpeechRecognition && titleOffset.isFinite ? titleOffset * scale : 0
        if let label = moveUpView.titleLabel {
            let targetX = min(size.width - halfBand, max(halfBand, size.width / 2 + (state.actionTipsState == .cancel ? inset : -inset)))
            let dx = targetX - arcCenter.x
            let rise = arcRadius > 0 ? sqrt(max(0, arcRadius * arcRadius - dx * dx)) : 0
            let targetY = arcRadius > 0 ? arcCenter.y - rise : size.height / 2
            let tangent = arcRadius > 0 ? atan2(dx, rise) : 0
            label.transform = CGAffineTransform(a: cos(tangent), b: sin(tangent), c: -sin(tangent), d: cos(tangent), tx: targetX - label.center.x, ty: targetY - label.center.y)
        }
        if let label = moveUpView.titleLabel, let host = superview {
            let rect = label.convert(label.textRect(forBounds: label.bounds, limitedToNumberOfLines: label.numberOfLines), to: host)
            let allowed = host.bounds.insetBy(dx: max(0, inset), dy: 0)
            let shift = rect.minX < allowed.minX ? allowed.minX - rect.minX : rect.maxX > allowed.maxX ? allowed.maxX - rect.maxX : 0
            if shift != 0 {
                let origin = moveUpView.convert(CGPoint.zero, from: host)
                let moved = moveUpView.convert(CGPoint(x: shift, y: 0), from: host)
                var transform = label.transform
                transform.tx += moved.x - origin.x
                transform.ty += moved.y - origin.y
                label.transform = transform
            }
        }
    }
}

/// 录音按钮文字与路径布局
final class WYChatRecordingActionButton: UIButton {
    var layoutHandler: (() -> Void)?
    override func layoutSubviews() {
        titleLabel?.transform = .identity
        super.layoutSubviews()
        layoutHandler?()
    }
}
