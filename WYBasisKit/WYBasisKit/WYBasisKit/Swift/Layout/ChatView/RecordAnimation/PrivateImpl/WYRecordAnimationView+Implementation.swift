//
//  WYRecordAnimationView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit
import AVFoundation

final class WYRecordAnimationViewPrivateState {
    var requestID: String?
    var discard = false
    var duration: TimeInterval = 0
    var startedAt: Date?
    var speech: WYChatSpeechRecognitionTask?
    var transcriptionURL: URL?
    var ownsTranscriptionFile = false
    var watchdog: Timer?
    var editorHeight: NSLayoutConstraint?
    var editorBottom: NSLayoutConstraint?
    var editPanel: UIStackView?
    let editText = UITextView()
    let sendButton = UIButton(type: .system)
    let retryButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)
    var lastLayoutSize: CGSize = .zero
    var bottomLayer: CAShapeLayer?
    var bottomTitleView: UILabel?
    var bottomView: UIView?
    var soundAnimationView: WYSoundAnimationView?
    var leftView: WYMoveUpTipsView?
    var rightView: WYMoveUpTipsView?
}

extension WYRecordAnimationView {

    func wy_makeAudioKit() -> WYAudioKit? {

        let kit = WYAudioKit()
        kit.delegate = self
        kit.minimumRecordDuration = self.recordAnimationConfig.recordTime.min
        kit.maximumRecordDuration = self.recordAnimationConfig.recordTime.max

        var settingDictionary: Dictionary = Dictionary<String, Any>()
        // 设置录音格式
        settingDictionary[AVFormatIDKey] = kAudioFormatMPEG4AAC
        // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
        settingDictionary[AVSampleRateKey] = 44100.0
        // 设置通道,这里采用单声道
        settingDictionary[AVNumberOfChannelsKey] = 1
        // 每个采样点位数,分为8、16、24、32
        settingDictionary[AVLinearPCMBitDepthKey] = 16
        // 是否使用浮点数采样
        settingDictionary[AVLinearPCMIsFloatKey] = false
        settingDictionary[AVEncoderAudioQualityKey] = AVAudioQuality.high.rawValue

        kit.recordSettings = self.recordAnimationConfig.recordSettings.isEmpty ? settingDictionary : self.recordAnimationConfig.recordSettings

        return kit
    }

    func wy_makeBottomLayer() -> CAShapeLayer {

        let bezierPath: UIBezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: self.recordAnimationConfig.arcRadian))
        bezierPath.addQuadCurve(to: CGPoint(x: frame.size.width, y: self.recordAnimationConfig.arcRadian), controlPoint: CGPoint(x: frame.size.width / 2, y: -self.recordAnimationConfig.arcRadian))
        bezierPath.addLine(to: CGPoint(x: frame.size.width, y: self.recordAnimationConfig.areaHeight))
        bezierPath.addLine(to: CGPoint(x: 0, y: self.recordAnimationConfig.areaHeight))

        let bottomLayer: CAShapeLayer = CAShapeLayer()
        bottomLayer.path = bezierPath.cgPath
        bottomLayer.strokeColor = self.recordAnimationConfig.strokeColor.cgColor
        bottomLayer.fillColor = self.recordAnimationConfig.fillColor.onInterior.cgColor
        bottomLayer.shadowOffset = self.recordAnimationConfig.shadowOffset
        bottomLayer.shadowColor = self.recordAnimationConfig.shadowColor.cgColor
        bottomLayer.shadowOpacity = Float(self.recordAnimationConfig.shadowOpacity)

        return bottomLayer
    }

    var bottomLayer: CAShapeLayer {
        if let value = state.bottomLayer { return value }
        let value = wy_makeBottomLayer()
        state.bottomLayer = value
        return value
    }

    func wy_makeBottomTitleView() -> UILabel {

        let label: UILabel = UILabel()
        label.textAlignment = .left
        label.font = self.recordAnimationConfig.recordViewTipsInfoForInterior.font
        label.textColor = self.recordAnimationConfig.recordViewTipsInfoForInterior.color
        label.text = self.recordAnimationConfig.recordViewTips.onInterior

        return label
    }

    var bottomTitleView: UILabel {
        if let value = state.bottomTitleView { return value }
        let value = wy_makeBottomTitleView()
        state.bottomTitleView = value
        return value
    }

    func wy_makeBottomView() -> UIView {

        layoutIfNeeded()

        let bottomView: UIView = UIView()
        bottomView.backgroundColor = .clear
        bottomView.layer.addSublayer(bottomLayer)
        addSubview(bottomView)
        bottomView.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(self.recordAnimationConfig.areaHeight)
            make.height.equalTo(self.recordAnimationConfig.areaHeight)
        })

        bottomView.addSubview(bottomTitleView)
        bottomTitleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(self.recordAnimationConfig.recordTipViewTopOffset)
        }

        // 必须主动调用下这两个View，否则在手指滑动到这两个控件上之前不会显示出来
        leftView.refresh(tipsState: .cancel, isTouched: false)
        rightView.refresh(tipsState: .transfer, isTouched: false)

        return bottomView
    }

    var bottomView: UIView {
        if let value = state.bottomView { return value }
        let value = wy_makeBottomView()
        state.bottomView = value
        return value
    }

    func wy_makeSoundAnimationView() -> WYSoundAnimationView {
        let soundAnimationView: WYSoundAnimationView = WYSoundAnimationView(.recording, configuration: recordAnimationConfig)
        addSubview(soundAnimationView)
        state.lastLayoutSize = .zero
        setNeedsLayout()
        soundAnimationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(-self.recordAnimationConfig.soundWavesViewBottomOffset)
            make.width.equalTo(self.recordAnimationConfig.soundWavesViewWidth.recording)
            make.height.equalTo(self.recordAnimationConfig.soundWavesViewHeight.recording)
        }
        return soundAnimationView
    }

    var soundAnimationView: WYSoundAnimationView {
        if let value = state.soundAnimationView { return value }
        let value = wy_makeSoundAnimationView()
        state.soundAnimationView = value
        return value
    }

    func wy_makeLeftView() -> WYMoveUpTipsView {

        let leftView: WYMoveUpTipsView = WYMoveUpTipsView(tipsState: .cancel, configuration: recordAnimationConfig)
        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            if self.recordAnimationConfig.supportSpeechRecognition {
                make.centerX.equalToSuperview().offset(-self.recordAnimationConfig.moveUpButtonCenterOffsetX)
            }else {
                make.centerX.equalToSuperview()
            }
            make.centerY.equalTo(self.snp.bottom).offset(-(self.recordAnimationConfig.areaHeight + self.recordAnimationConfig.moveUpButtonOffset.bottom))
        }
        return leftView
    }

    var leftView: WYMoveUpTipsView {
        if let value = state.leftView { return value }
        let value = wy_makeLeftView()
        state.leftView = value
        return value
    }

    func wy_makeRightView() -> WYMoveUpTipsView {

        let rightView: WYMoveUpTipsView = WYMoveUpTipsView(tipsState: .transfer, configuration: recordAnimationConfig)
        rightView.isHidden = !self.recordAnimationConfig.supportSpeechRecognition
        addSubview(rightView)
        rightView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(self.recordAnimationConfig.moveUpButtonCenterOffsetX)
            make.centerY.equalTo(self.snp.bottom).offset(-(self.recordAnimationConfig.areaHeight + self.recordAnimationConfig.moveUpButtonOffset.bottom))
        }
        return rightView
    }

    var rightView: WYMoveUpTipsView {
        if let value = state.rightView { return value }
        let value = wy_makeRightView()
        state.rightView = value
        return value
    }

    func wy_impl_start() {
        superview?.layoutIfNeeded()
        layoutIfNeeded()
        UIView.animate(withDuration: 0.18,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseIn) { [weak self] in

            guard let self = self else { return }

            self.alpha = 1.0
            self.bottomView.alpha = 1.0
            self.bottomView.snp.updateConstraints({ make in
                make.bottom.equalToSuperview().offset(0)
            })
        }

        state.lastLayoutSize = .zero
        wy_layoutRecordingView()
        wy_beginCapture()
    }

    func wy_impl_stop() {
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: .curveEaseOut) { [weak self] in

            guard let self = self else { return }

            self.alpha = 0.0
            self.bottomView.alpha = 0.0

        }completion: { [weak self] _ in

            guard let self = self else { return }

            self.bottomView.snp.updateConstraints({ make in
                make.bottom.equalToSuperview().offset(self.recordAnimationConfig.areaHeight)
            })
            self.refresh(subview: self.leftView, status: .recording)
            self.refresh(subview: self.rightView, status: .recording)
            self.refresh(subview: self.bottomView, status: .recording)
            self.refresh(subview: self.soundAnimationView, status: .recording)
        }
        wy_stopCapture()
    }

    func wy_impl_switchStatus(_ touchPoint: CGPoint) {

        let status: WYSoundAnimationStatus
        // 判断触摸点是否在 指定View 上面
        if leftView.frame.contains(touchPoint) {
            status = .cancel
        } else if recordAnimationConfig.supportSpeechRecognition && rightView.frame.contains(touchPoint) {
            status = .transfer
        } else if bottomView.frame.contains(touchPoint) {
            status = .recording
        } else {
            status = .cancel
        }

        guard soundAnimationStatus != status else {
            return
        }
        soundAnimationStatus = status
        state.lastLayoutSize = .zero

        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }

            refresh(subview: leftView, status: status)
            refresh(subview: rightView, status: status)
            refresh(subview: bottomView, status: status)
            refresh(subview: soundAnimationView, status: status)

            // 保障动画正常执行
            layoutIfNeeded()
        }

        if self.recordAnimationConfig.vibrationFeedback {
            // 录音会占用 AVAudioSession，系统默认会屏蔽非必要的触觉反馈，开启此选项可在录音期间保留 Haptic 和系统震动能力。
            try? AVAudioSession.sharedInstance()
                .setAllowHapticsAndSystemSoundsDuringRecording(true)
            UIDevice.wy_vibrate(.light)
        }
    }

    func wy_impl_refresh(subview: UIView, status: WYSoundAnimationStatus) {

        switch status {
        case .recording:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onExternal, height: self.recordAnimationConfig.moveUpButtonDiameter.onExternal))
                    leftView.refresh(tipsState: .cancel, isTouched: false)
                }
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onExternal, height: self.recordAnimationConfig.moveUpButtonDiameter.onExternal))
                    rightView.refresh(tipsState: .transfer, isTouched: false)
                }
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(0)
                    make.width.equalTo(self.recordAnimationConfig.soundWavesViewWidth.recording)
                    make.height.equalTo(self.recordAnimationConfig.soundWavesViewHeight.recording)
                }
                soundAnimationView.refreshSoundWaves(status: .recording)
            }

            if subview == bottomView {
                bottomLayer.fillColor = self.recordAnimationConfig.fillColor.onInterior.cgColor
                bottomTitleView.font = self.recordAnimationConfig.recordViewTipsInfoForInterior.font
                bottomTitleView.textColor = self.recordAnimationConfig.recordViewTipsInfoForInterior.color
                bottomTitleView.text = self.recordAnimationConfig.recordViewTips.onInterior
            }
            break
        case .cancel:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onInterior, height: self.recordAnimationConfig.moveUpButtonDiameter.onInterior))
                }
                leftView.refresh(tipsState: .cancel, isTouched: true)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onExternal, height: self.recordAnimationConfig.moveUpButtonDiameter.onExternal))
                }
                rightView.refresh(tipsState: .transfer, isTouched: false)
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(-self.recordAnimationConfig.moveUpButtonCenterOffsetX - (self.recordAnimationConfig.moveUpButtonDiameter.onInterior / 2) + (self.recordAnimationConfig.soundWavesViewWidth.cancel / 2))
                    make.width.equalTo(self.recordAnimationConfig.soundWavesViewWidth.cancel)
                    make.height.equalTo(self.recordAnimationConfig.soundWavesViewHeight.cancel)
                }
                soundAnimationView.refreshSoundWaves(status: .cancel)
            }

            if subview == bottomView {
                bottomLayer.fillColor = self.recordAnimationConfig.fillColor.onExternal.cgColor
                bottomTitleView.font = self.recordAnimationConfig.recordViewTipsInfoForExternal.font
                bottomTitleView.textColor = self.recordAnimationConfig.recordViewTipsInfoForExternal.color
                bottomTitleView.text = self.recordAnimationConfig.recordViewTips.onExternal
            }
            break
        case .transfer:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onExternal, height: self.recordAnimationConfig.moveUpButtonDiameter.onExternal))
                }
                leftView.refresh(tipsState: .cancel, isTouched: false)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: self.recordAnimationConfig.moveUpButtonDiameter.onInterior, height: self.recordAnimationConfig.moveUpButtonDiameter.onInterior))
                }
                rightView.refresh(tipsState: .transfer, isTouched: true)
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(0)
                    make.width.equalTo(self.recordAnimationConfig.soundWavesViewWidth.transfer)
                    make.height.equalTo(self.recordAnimationConfig.soundWavesViewHeight.transfer)
                }
                soundAnimationView.refreshSoundWaves(status: .transfer)
            }

            if subview == bottomView {
                bottomLayer.fillColor = self.recordAnimationConfig.fillColor.onExternal.cgColor
                bottomTitleView.font = self.recordAnimationConfig.recordViewTipsInfoForExternal.font
                bottomTitleView.textColor = self.recordAnimationConfig.recordViewTipsInfoForExternal.color
                bottomTitleView.text = self.recordAnimationConfig.recordViewTips.onExternal
            }
            break
        }
    }

    func wy_impl_endRecordVoice() {
        guard audioKit != nil else {
            return
        }
        state.discard = true
        if state.requestID != nil { wy_stopCapture() }
        state.speech?.cancel()
        state.watchdog?.invalidate()
        state.watchdog = nil
        wy_clearTranscript()
        audioKit?.releaseAll()
        audioKit = nil
        alpha = 0
    }

    func wy_impl_wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        delegate?.wy_audioRecorderDidStart?(audioKit: audioKit, isResume: isResume)
    }

    func wy_impl_wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {

        delegate?.wy_audioRecorderDidStop?(audioKit: audioKit, isPause: isPause, isTimeout: isTimeout)

        guard !isPause, state.requestID != nil else { return }
        if state.discard {
            try? audioKit.deleteRecordingFile()
            state.requestID = nil
            state.watchdog?.invalidate()
            alpha = 0
            return
        }
        guard let source = audioKit.currentRecordFileURL else {
            wy_captureFinished(nil, duration: state.duration, error: wy_recordError(WYLocalized("录音时间太短", table: WYBasisKitConfig.kitLocalizableTable)))
            return
        }
        do {
            try FileManager.default.createDirectory(at: recordAnimationConfig.chatAudioUrl, withIntermediateDirectories: true)
            let destination = recordAnimationConfig.chatAudioUrl.appendingPathComponent(UUID().uuidString).appendingPathExtension(source.pathExtension)
            try audioKit.saveRecording(destinationUrl: destination)
            try audioKit.deleteRecordingFile(localUrl: source)
            wy_captureFinished(destination, duration: state.duration, error: nil)
        } catch { wy_captureFinished(nil, duration: state.duration, error: error as NSError) }
    }

    func wy_impl_wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
        state.duration = currentTime
        delegate?.wy_audioRecorderTimeUpdated?(audioKit: audioKit, currentTime: currentTime, duration: duration)
    }

    func wy_impl_wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) {

        // 回调给外部
        delegate?.wy_audioRecorderDidUpdateMetering?(audioKit: audioKit, peakPower: peakPower, averagePower: averagePower)

        // 更新声波柱子配置
        soundAnimationView.soundWavesConfigUpdate(status: soundAnimationStatus, config: &soundAnimationView.soundWavesView.config)

        // 生成声波能量值（0~1）
        let power: Float = soundAnimationView.soundWavesView.makeWaveformLevels(peakPower: peakPower, averagePower: averagePower)

        // 传给动画层
        soundAnimationView.soundWavesView.updateMeters(power: power)
    }

    func wy_impl_wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        delegate?.wy_audioTaskDidFailed?(audioKit: audioKit, url: url, error: error, description: description)
        if state.requestID != nil { wy_captureFinished(nil, duration: state.duration, error: wy_recordError(description ?? String(describing: error))) }
    }
}

/// 录音面板随实际容器重排
extension WYRecordAnimationView {
    func wy_layoutRecordingView() {
        guard bounds.width > 0, bounds.height > 0, state.lastLayoutSize != bounds.size else { return }
        state.lastLayoutSize = bounds.size
        let config = recordAnimationConfig
        state.editorHeight?.constant = min(max(1, config.recognitionPanelHeight), max(1, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom - abs(state.editorBottom?.constant ?? 0)))
        let areaHeight = min(bounds.height, max(0, config.areaHeight))
        if let bottom = state.bottomView {
            bottom.snp.updateConstraints { make in make.height.equalTo(areaHeight) }
            let path = UIBezierPath()
            let arc = min(areaHeight, max(0, config.arcRadian))
            path.move(to: CGPoint(x: 0, y: arc))
            path.addQuadCurve(to: CGPoint(x: bounds.width, y: arc), controlPoint: CGPoint(x: bounds.width / 2, y: -arc))
            path.addLine(to: CGPoint(x: bounds.width, y: areaHeight))
            path.addLine(to: CGPoint(x: 0, y: areaHeight))
            path.close()
            state.bottomLayer?.path = path.cgPath
        }
        let diameter = max(config.moveUpButtonDiameter.onInterior, config.moveUpButtonDiameter.onExternal)
        let offset = min(max(0, config.moveUpButtonCenterOffsetX), max(0, (bounds.width - diameter) / 2))
        if let left = state.leftView { left.snp.updateConstraints { make in make.centerX.equalToSuperview().offset(config.supportSpeechRecognition ? -offset : 0) } }
        if let right = state.rightView { right.snp.updateConstraints { make in make.centerX.equalToSuperview().offset(offset) } }
        if let sound = state.soundAnimationView {
            let desiredWidth: CGFloat
            let desiredHeight: CGFloat
            switch soundAnimationStatus {
            case .recording: desiredWidth = config.soundWavesViewWidth.recording; desiredHeight = config.soundWavesViewHeight.recording
            case .cancel: desiredWidth = config.soundWavesViewWidth.cancel; desiredHeight = config.soundWavesViewHeight.cancel
            case .transfer: desiredWidth = config.soundWavesViewWidth.transfer; desiredHeight = config.soundWavesViewHeight.transfer
            }
            let width = min(bounds.width, max(0, desiredWidth))
            let height = min(bounds.height, max(0, desiredHeight))
            sound.snp.updateConstraints { make in
                make.width.equalTo(width)
                make.height.equalTo(height)
                make.bottom.equalToSuperview().offset(-min(max(0, config.soundWavesViewBottomOffset), max(0, bounds.height - height)))
            }
        }
    }
}

/// 声波气泡的安全几何尺寸
extension WYSoundAnimationView {
    func wy_layoutSoundBubble() {
        let radius: CGFloat
        let size: CGSize
        switch currentStatus {
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
        cornerRadius = min(radius.isFinite ? max(0, radius) : 0, allowedRadius)
        showsArrow = visible
        arrowSize = visible ? CGSize(width: base, height: arrowDepth) : .zero
        arrowEdgePadding = 0
        let limit = max(0, edge - cornerRadius * 2 - base)
        arrowOffset = visible ? min(limit, max(-limit, arrowOffset.isFinite ? arrowOffset : 0)) : 0
        let desired = soundWavesSize(for: currentStatus)
        let width = min(max(0, desired.width), max(0, bounds.width - cornerRadius * 2))
        let height = min(max(0, desired.height), max(0, bounds.height - cornerRadius * 2))
        let offsetX = currentStatus == .transfer ? bounds.width / 2 - recordAnimationConfig.soundWavesRightOffsetForAirBubble.x - width / 2 : 0
        let offsetY = currentStatus == .transfer ? bounds.height / 2 - recordAnimationConfig.soundWavesRightOffsetForAirBubble.y - height / 2 : 0
        soundWavesView.snp.updateConstraints { make in
            make.size.equalTo(CGSize(width: width, height: height))
            make.centerX.equalToSuperview().offset(min(max(0, (bounds.width - width) / 2), max(-(bounds.width - width) / 2, offsetX)))
            make.centerY.equalToSuperview().offset(min(max(0, (bounds.height - height) / 2), max(-(bounds.height - height) / 2, offsetY)))
        }
    }
}
