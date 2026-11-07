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
        kit.minimumRecordDuration = recordAnimationConfig.recordTime.min
        kit.maximumRecordDuration = recordAnimationConfig.recordTime.max

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

        kit.recordSettings = settingDictionary

        return kit
    }

    func wy_makeBottomLayer() -> CAShapeLayer {

        let bezierPath: UIBezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: recordAnimationConfig.arcRadian))
        bezierPath.addQuadCurve(to: CGPoint(x: frame.size.width, y: recordAnimationConfig.arcRadian), controlPoint: CGPoint(x: frame.size.width / 2, y: -recordAnimationConfig.arcRadian))
        bezierPath.addLine(to: CGPoint(x: frame.size.width, y: recordAnimationConfig.areaHeight))
        bezierPath.addLine(to: CGPoint(x: 0, y: recordAnimationConfig.areaHeight))

        let bottomLayer: CAShapeLayer = CAShapeLayer()
        bottomLayer.path = bezierPath.cgPath
        bottomLayer.strokeColor = recordAnimationConfig.strokeColor.cgColor
        bottomLayer.fillColor = recordAnimationConfig.fillColor.onInterior.cgColor
        bottomLayer.shadowOffset = recordAnimationConfig.shadowOffset
        bottomLayer.shadowColor = recordAnimationConfig.shadowColor.cgColor
        bottomLayer.shadowOpacity = Float(recordAnimationConfig.shadowOpacity)

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
        label.font = recordAnimationConfig.recordViewTipsInfoForInterior.font
        label.textColor = recordAnimationConfig.recordViewTipsInfoForInterior.color
        label.text = recordAnimationConfig.recordViewTips.onInterior

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
            make.bottom.equalToSuperview().offset(recordAnimationConfig.areaHeight)
            make.height.equalTo(recordAnimationConfig.areaHeight)
        })

        bottomView.addSubview(bottomTitleView)
        bottomTitleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(recordAnimationConfig.recordTipViewTopOffset)
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
        let soundAnimationView: WYSoundAnimationView = WYSoundAnimationView(.recording)
        addSubview(soundAnimationView)
        soundAnimationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(-recordAnimationConfig.soundWavesViewBottomOffset)
            make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.recording)
            make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.recording)
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

        let leftView: WYMoveUpTipsView = WYMoveUpTipsView(tipsState: .cancel)
        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            if recordAnimationConfig.supportSpeechRecognition {
                make.centerX.equalToSuperview().offset(-recordAnimationConfig.moveUpButtonCenterOffsetX)
            }else {
                make.centerX.equalToSuperview()
            }
            make.centerY.equalTo(self.snp.bottom).offset(-(recordAnimationConfig.areaHeight + recordAnimationConfig.moveUpButtonOffset.bottom))
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

        let rightView: WYMoveUpTipsView = WYMoveUpTipsView(tipsState: .transfer)
        rightView.isHidden = !recordAnimationConfig.supportSpeechRecognition
        addSubview(rightView)
        rightView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(recordAnimationConfig.moveUpButtonCenterOffsetX)
            make.centerY.equalTo(self.snp.bottom).offset(-(recordAnimationConfig.areaHeight + recordAnimationConfig.moveUpButtonOffset.bottom))
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

        guard audioKit != nil else {
            return
        }

        try? audioKit?.startRecording()
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
                make.bottom.equalToSuperview().offset(recordAnimationConfig.areaHeight)
            })
            self.refresh(subview: self.leftView, status: .recording)
            self.refresh(subview: self.rightView, status: .recording)
            self.refresh(subview: self.bottomView, status: .recording)
            self.refresh(subview: self.soundAnimationView, status: .recording)
        }
    }

    func wy_impl_switchStatus(_ touchPoint: CGPoint) {

        let status: WYSoundAnimationStatus
        // 判断触摸点是否在 指定View 上面
        if leftView.frame.contains(touchPoint) {
            status = .cancel
        } else if rightView.frame.contains(touchPoint) {
            status = .transfer
        } else if bottomView.frame.contains(touchPoint) {
            status = .recording
        } else {
            // 不在任何指定视图上，不做任何处理
            return
        }

        guard soundAnimationStatus != status else {
            return
        }
        soundAnimationStatus = status

        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else { return }

            refresh(subview: leftView, status: status)
            refresh(subview: rightView, status: status)
            refresh(subview: bottomView, status: status)
            refresh(subview: soundAnimationView, status: status)

            // 保障动画正常执行
            layoutIfNeeded()
        }

        if recordAnimationConfig.vibrationFeedback {
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
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onExternal, height: recordAnimationConfig.moveUpButtonDiameter.onExternal))
                    leftView.refresh(tipsState: .cancel, isTouched: false)
                }
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onExternal, height: recordAnimationConfig.moveUpButtonDiameter.onExternal))
                    rightView.refresh(tipsState: .transfer, isTouched: false)
                }
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(0)
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.recording)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.recording)
                }
                soundAnimationView.refreshSoundWaves(status: .recording)
            }

            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onInterior.cgColor
                bottomTitleView.font = recordAnimationConfig.recordViewTipsInfoForInterior.font
                bottomTitleView.textColor = recordAnimationConfig.recordViewTipsInfoForInterior.color
                bottomTitleView.text = recordAnimationConfig.recordViewTips.onInterior
            }
            break
        case .cancel:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onInterior, height: recordAnimationConfig.moveUpButtonDiameter.onInterior))
                }
                leftView.refresh(tipsState: .cancel, isTouched: true)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onExternal, height: recordAnimationConfig.moveUpButtonDiameter.onExternal))
                }
                rightView.refresh(tipsState: .transfer, isTouched: false)
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(-recordAnimationConfig.moveUpButtonCenterOffsetX - (recordAnimationConfig.moveUpButtonDiameter.onInterior / 2) + (recordAnimationConfig.soundWavesViewWidth.cancel / 2))
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.cancel)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.cancel)
                }
                soundAnimationView.refreshSoundWaves(status: .cancel)
            }

            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onExternal.cgColor
                bottomTitleView.font = recordAnimationConfig.recordViewTipsInfoForExternal.font
                bottomTitleView.textColor = recordAnimationConfig.recordViewTipsInfoForExternal.color
                bottomTitleView.text = recordAnimationConfig.recordViewTips.onExternal
            }
            break
        case .transfer:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onExternal, height: recordAnimationConfig.moveUpButtonDiameter.onExternal))
                }
                leftView.refresh(tipsState: .cancel, isTouched: false)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: recordAnimationConfig.moveUpButtonDiameter.onInterior, height: recordAnimationConfig.moveUpButtonDiameter.onInterior))
                }
                rightView.refresh(tipsState: .transfer, isTouched: true)
            }

            if subview == soundAnimationView {
                soundAnimationView.snp.updateConstraints { make in
                    make.centerX.equalToSuperview().offset(0)
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.transfer)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.transfer)
                }
                soundAnimationView.refreshSoundWaves(status: .transfer)
            }

            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onExternal.cgColor
                bottomTitleView.font = recordAnimationConfig.recordViewTipsInfoForExternal.font
                bottomTitleView.textColor = recordAnimationConfig.recordViewTipsInfoForExternal.color
                bottomTitleView.text = recordAnimationConfig.recordViewTips.onExternal
            }
            break
        }
    }

    func wy_impl_endRecordVoice() {
        guard audioKit != nil else {
            return
        }
        audioKit?.releaseAll()
        audioKit = nil
    }

    func wy_impl_wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        delegate?.wy_audioRecorderDidStart?(audioKit: audioKit, isResume: isResume)
    }

    func wy_impl_wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {

        delegate?.wy_audioRecorderDidStop?(audioKit: audioKit, isPause: isPause, isTimeout: isTimeout)

        try? audioKit.saveRecording(destinationUrl: recordAnimationConfig.chatAudioUrl)
    }

    func wy_impl_wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
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
    }
}
