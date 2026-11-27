//
//  WYSoundAnimationView+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYSoundAnimationViewPrivateState {
    let customArrowView = UIImageView()
    var showsLiveText = false
    var waveLayout: CGRect?
    var lastScrolledText = ""
    var lastTextBounds = CGRect.zero
    var currentStatus: WYSoundAnimationStatus = .recording
}

extension WYSoundAnimationView {
    func wy_refreshSoundWaves(status: WYSoundAnimationStatus) {
        state.currentStatus = status
        state.waveLayout = nil

        // 声波动画组件Size
        let soundWavesSize: CGSize = soundWavesSize(for: status)

        switch status {
        case .recording:
            cornerRadius = recordAnimationConfig.cornerRadiusForMoveUp.recording
            fillColor = recordAnimationConfig.backgroundColorForMoveUp.recording
            borderColor = recordAnimationConfig.borderColorForMoveUp.recording
            borderWidth = recordAnimationConfig.borderWidthForMoveUp.recording
            arrowSize = recordAnimationConfig.arrowSizeForMoveUp.recording
            arrowTipRadius = recordAnimationConfig.arrowTipRadiusForMoveUp.recording
            arrowOffset = 0

            soundWavesView.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset(0)
                make.centerY.equalToSuperview().offset(0)
                make.size.equalTo(soundWavesSize)
            }
            break
        case .transfer:
            cornerRadius = recordAnimationConfig.cornerRadiusForMoveUp.transfer
            fillColor = recordAnimationConfig.backgroundColorForMoveUp.transfer
            borderColor = recordAnimationConfig.borderColorForMoveUp.transfer
            borderWidth = recordAnimationConfig.borderWidthForMoveUp.transfer
            arrowSize = recordAnimationConfig.arrowSizeForMoveUp.transfer
            arrowTipRadius = recordAnimationConfig.arrowTipRadiusForMoveUp.transfer
            arrowOffset = (recordAnimationConfig.soundWavesViewWidth.transfer - recordAnimationConfig.moveUpButtonDiameter.onInterior - arrowSize.width) / 2

            soundWavesView.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset((recordAnimationConfig.soundWavesViewWidth.transfer / 2) - recordAnimationConfig.soundWavesRightOffsetForAirBubble.x - (soundWavesSize.width / 2))
                make.centerY.equalToSuperview().offset((recordAnimationConfig.soundWavesViewHeight.transfer / 2) - recordAnimationConfig.soundWavesRightOffsetForAirBubble.y - (soundWavesSize.height / 2))
                make.size.equalTo(soundWavesSize)
            }
            break
        case .cancel:
            cornerRadius = recordAnimationConfig.cornerRadiusForMoveUp.cancel
            fillColor = recordAnimationConfig.backgroundColorForMoveUp.cancel
            borderColor = recordAnimationConfig.borderColorForMoveUp.cancel
            borderWidth = recordAnimationConfig.borderWidthForMoveUp.cancel
            arrowSize = recordAnimationConfig.arrowSizeForMoveUp.cancel
            arrowTipRadius = recordAnimationConfig.arrowTipRadiusForMoveUp.cancel
            arrowOffset = 0

            soundWavesView.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset(0)
                make.centerY.equalToSuperview().offset(0)
                make.size.equalTo(soundWavesSize)
            }
            break
        }

        // 更新声波柱子配置
        soundWavesConfigUpdate(status: status, config: &soundWavesView.config)
    }

    func wy_soundWavesConfigUpdate(status: WYSoundAnimationStatus, config: inout WYSoundWaveConfig) {

        let soundWavesWidth = recordAnimationConfig.soundWavesWidth
        let soundWavesSpace = recordAnimationConfig.soundWavesSpace

        let soundWavesColor: UIColor
        let soundWavesMaxHeight: CGFloat
        let soundWavesMinHeight: CGFloat
        let severalSoundWaves: Int
        switch status {
        case .recording:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.recording
            soundWavesMaxHeight = recordAnimationConfig.soundWavesMaxHeight.recording
            soundWavesMinHeight = recordAnimationConfig.soundWavesMinHeight.recording
            severalSoundWaves = recordAnimationConfig.severalSoundWaves.recording
            break
        case .transfer:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.transfer
            soundWavesMaxHeight = recordAnimationConfig.soundWavesMaxHeight.transfer
            soundWavesMinHeight = recordAnimationConfig.soundWavesMinHeight.transfer
            severalSoundWaves = recordAnimationConfig.severalSoundWaves.transfer
            break
        case .cancel:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.cancel
            soundWavesMaxHeight = recordAnimationConfig.soundWavesMaxHeight.cancel
            soundWavesMinHeight = recordAnimationConfig.soundWavesMinHeight.cancel
            severalSoundWaves = recordAnimationConfig.severalSoundWaves.cancel
            break
        }

        config.wavesColor = soundWavesColor
        config.barWidth = soundWavesWidth
        config.barSpacing = soundWavesSpace
        config.maxBarHeight = soundWavesMaxHeight
        config.minBarHeight = soundWavesMinHeight
        config.numberOfColumns = severalSoundWaves
    }

    func wy_soundWavesSize(for status: WYSoundAnimationStatus) -> CGSize {

        let soundWavesWidth: CGFloat
        let soundWavesHeight: CGFloat

        switch status {
        case .recording:
            soundWavesWidth = ((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.recording)) - recordAnimationConfig.soundWavesSpace
            soundWavesHeight = recordAnimationConfig.soundWavesMaxHeight.recording
            break
        case .transfer:
            soundWavesWidth = ((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.transfer)) - recordAnimationConfig.soundWavesSpace
            soundWavesHeight = recordAnimationConfig.soundWavesMaxHeight.transfer
            break
        case .cancel:
            soundWavesWidth = ((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.cancel)) - recordAnimationConfig.soundWavesSpace
            soundWavesHeight = recordAnimationConfig.soundWavesMaxHeight.cancel
            break
        }
        return CGSize(width: soundWavesWidth, height: soundWavesHeight)

    }
}

/// 声波气泡的安全几何尺寸
extension WYSoundAnimationView {
    var wy_liveTextInsets: UIEdgeInsets {
        let value = recordAnimationConfig.liveTextInsets
        func valid(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        return UIEdgeInsets(top: valid(value.top), left: valid(value.left), bottom: valid(value.bottom), right: valid(value.right))
    }

    var wy_liveTextFooterHeight: CGFloat {
        let config = recordAnimationConfig
        let arrow = showsArrow && arrowDirection == .bottom ? arrowSize.height : 0
        guard !soundWavesView.isHidden else { return wy_liveTextInsets.bottom + arrow }
        let offset = config.soundWavesRightOffsetForAirBubble.y
        let spacing = config.liveTextWaveformSpacing
        return arrow + max(wy_liveTextInsets.bottom, (offset.isFinite ? max(0, offset) : 0) + max(0, soundWavesSize(for: state.currentStatus).height) + (spacing.isFinite ? max(0, spacing) : 0))
    }

    func wy_layoutTranscriptText() {
        guard state.showsLiveText else { return }
        let insets = wy_liveTextInsets
        let frame = CGRect(x: insets.left, y: insets.top, width: max(1, bounds.width - insets.left - insets.right), height: max(1, bounds.height - insets.top - wy_liveTextFooterHeight))
        if textView.frame != frame { textView.frame = frame }
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        if !textView.text.isEmpty, state.lastScrolledText != textView.text || state.lastTextBounds != textView.bounds {
            state.lastScrolledText = textView.text
            state.lastTextBounds = textView.bounds
            textView.scrollRangeToVisible(NSRange(location: textView.text.utf16.count - 1, length: 1))
        }
    }

    func wy_layoutSoundBubble() {
        let radius: CGFloat
        let size: CGSize
        switch state.currentStatus {
        case .recording: radius = recordAnimationConfig.cornerRadiusForMoveUp.recording; size = recordAnimationConfig.arrowSizeForMoveUp.recording
        case .cancel: radius = recordAnimationConfig.cornerRadiusForMoveUp.cancel; size = recordAnimationConfig.arrowSizeForMoveUp.cancel
        case .transfer: radius = recordAnimationConfig.cornerRadiusForMoveUp.transfer; size = recordAnimationConfig.arrowSizeForMoveUp.transfer
        }
        let vertical = arrowDirection == .left || arrowDirection == .right
        let edge = max(0, vertical ? bounds.height : bounds.width)
        let depth = max(0, vertical ? bounds.width : bounds.height)
        let base = size.width.isFinite ? max(0, size.width) : 0
        let arrowDepth = size.height.isFinite ? max(0, size.height) : 0
        let visible = edge > base && depth > arrowDepth
        let allowedRadius = max(0, min(edge - (visible ? base : 0), depth - (visible ? arrowDepth : 0)) / 2)
        let actualRadius = min(radius.isFinite ? max(0, radius) : 0, allowedRadius)
        if cornerRadius != actualRadius { cornerRadius = actualRadius }
        if showsArrow != visible { showsArrow = visible }
        let actualArrow = visible ? CGSize(width: base, height: arrowDepth) : .zero
        if arrowSize != actualArrow { arrowSize = actualArrow }
        if arrowEdgePadding != 0 { arrowEdgePadding = 0 }
        let limit = max(0, (edge - cornerRadius * 2 - base) / 2)
        let actualOffset = visible ? min(limit, max(-limit, arrowOffset.isFinite ? arrowOffset : 0)) : 0
        if arrowOffset != actualOffset { arrowOffset = actualOffset }
        if state.customArrowView.superview == nil { addSubview(state.customArrowView) }
        state.customArrowView.image = recordAnimationConfig.bubbleArrowImage?.withRenderingMode(recordAnimationConfig.bubbleArrowImageTintColor == nil ? .alwaysOriginal : .alwaysTemplate)
        state.customArrowView.tintColor = recordAnimationConfig.bubbleArrowImageTintColor
        state.customArrowView.contentMode = .scaleAspectFit
        state.customArrowView.isHidden = state.customArrowView.image == nil
        if !state.customArrowView.isHidden {
            showsArrow = false
            let point = recordAnimationConfig.bubbleArrowImageOffset
            let center = edge / 2 + actualOffset
            let rect: CGRect
            switch arrowDirection {
            case .top: rect = CGRect(x: center - base / 2, y: 1 - arrowDepth, width: base, height: arrowDepth)
            case .bottom: rect = CGRect(x: center - base / 2, y: bounds.height - 1, width: base, height: arrowDepth)
            case .left: rect = CGRect(x: 1 - arrowDepth, y: center - base / 2, width: arrowDepth, height: base)
            case .right: rect = CGRect(x: bounds.width - 1, y: center - base / 2, width: arrowDepth, height: base)
            }
            state.customArrowView.frame = rect.offsetBy(dx: point.x, dy: point.y)
        }
        let desired = soundWavesSize(for: state.currentStatus)
        let width = min(max(0, desired.width), max(0, bounds.width - cornerRadius * 2))
        let height = min(max(0, desired.height), max(0, bounds.height - cornerRadius * 2))
        let trailing = state.showsLiveText || state.currentStatus == .transfer
        let offset = recordAnimationConfig.soundWavesRightOffsetForAirBubble
        let insetX = offset.x.isFinite ? max(0, offset.x) : 0
        let insetY = offset.y.isFinite ? max(0, offset.y) : 0
        let rightArrow = showsArrow && arrowDirection == .right ? arrowSize.height : 0
        let bottomArrow = showsArrow && arrowDirection == .bottom ? arrowSize.height : 0
        let offsetX = trailing ? bounds.width / 2 - rightArrow - insetX - width / 2 : 0
        let offsetY = trailing ? bounds.height / 2 - bottomArrow - insetY - height / 2 : 0
        let layout = CGRect(x: min(max(0, (bounds.width - width) / 2), max(-(bounds.width - width) / 2, offsetX)), y: min(max(0, (bounds.height - height) / 2), max(-(bounds.height - height) / 2, offsetY)), width: width, height: height)
        if state.waveLayout != layout {
            state.waveLayout = layout
            soundWavesView.snp.updateConstraints { make in
                make.size.equalTo(layout.size)
                make.centerX.equalToSuperview().offset(layout.origin.x)
                make.centerY.equalToSuperview().offset(layout.origin.y)
            }
        }
    }
}

/// 内置录音事件转发
final class WYChatAudioRecorderDelegate: NSObject, WYAudioKitDelegate {
    weak var owner: WYRecordAnimationView?

    func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) { owner?.wy_impl_wy_audioRecorderDidStop(audioKit: audioKit, isPause: isPause, isTimeout: isTimeout) }
    func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) { owner?.wy_impl_wy_audioRecorderTimeUpdated(audioKit: audioKit, currentTime: currentTime, duration: duration) }
    func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) { owner?.wy_impl_wy_audioRecorderDidUpdateMetering(audioKit: audioKit, peakPower: peakPower, averagePower: averagePower) }
    func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) { owner?.wy_impl_wy_audioTaskDidFailed(audioKit: audioKit, url: url, error: error, description: description) }
}
