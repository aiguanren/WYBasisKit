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
    var mode: WYChatRecordingMode = .voice
    var automaticallySendsTranscript = false
    let voiceButton = UIButton(type: .system)
    var requestID: String?
    var captureConfiguration: WYRecordAnimationConfig?
    var discard = false
    var captureStopRequested = false
    var captureStarted = false
    var animationRevision = 0
    var duration: TimeInterval = 0
    var startedAt: Date?
    var speech: WYChatSpeechRecognitionTask?
    var liveRecorder: WYChatLiveRecorder?
    var audioKit: WYAudioKit?
    let audioDelegate = WYChatAudioRecorderDelegate()
    var timedOut = false
    var liveText = ""
    var liveError: NSError?
    var liveFinished = false
    var liveHeight: CGFloat = 0
    var transcriptionURL: URL?
    var ownsTranscriptionFile = false
    var watchdog: Timer?
    let editorDelegate = WYChatTranscriptEditorDelegate()
    let languageButton = UIButton(type: .system)
    let translationButton = UIButton(type: .system)
    let editorEmojiButton = UIButton(type: .system)
    let editorStatusLabel = UILabel()
    var editorEmoji: WYChatEmojiView?
    var translationID: String?
    var translationProvider: WYChatTextTranslator?
    var translationTimeoutWork: DispatchWorkItem?
    var editorHeight: NSLayoutConstraint?
    var editorBottom: NSLayoutConstraint?
    var editPanel: UIStackView?
    var editorBubble: WYAirBubbleView?
    var editorActionWidths: [NSLayoutConstraint] = []
    var editorControlConstraints: [NSLayoutConstraint] = []
    let editText = UITextView()
    let sendButton = UIButton(type: .system)
    let retryButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)
    var lastLayoutSize: CGSize = .zero
    var bottomLayer: CAShapeLayer?
    var bottomTitleView: UILabel?
    var recordingHint: UILabel?
    var bottomView: UIView?
    var soundAnimationView: WYSoundAnimationView?
    var leftView: WYMoveUpTipsView?
    var rightView: WYMoveUpTipsView?
}

extension WYRecordAnimationView {

    func wy_makeAudioKit() -> WYAudioKit? {

        let kit = WYAudioKit()
        state.audioDelegate.owner = self
        kit.delegate = state.audioDelegate
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

    func wy_impl_start(mode: WYChatRecordingMode = .voice) {
        guard state.requestID == nil else { return }
        guard mode != .dictation || recordAnimationConfig.supportSpeechRecognition else {
            recognitionResultHandler?(nil, wy_recordError(WYLocalized("语音识别未启用", table: WYBasisKitConfig.kitLocalizableTable)))
            return
        }
        state.mode = mode
        state.animationRevision += 1
        soundAnimationStatus = .recording
        rightView.isHidden = !recordAnimationConfig.supportSpeechRecognition
        leftView.recordAnimationConfig = recordAnimationConfig
        rightView.recordAnimationConfig = recordAnimationConfig
        if mode == .dictation { rightView.recordAnimationConfig.transferViewText.onInterior = recordAnimationConfig.dictationEditText }
        soundAnimationView.soundWavesView.isHidden = mode == .dictation && !recordAnimationConfig.dictationShowsWaveform
        soundAnimationView.recordAnimationConfig = recordAnimationConfig
        backgroundColor = recordAnimationConfig.overlayBackgroundColor
        for view in [leftView, rightView, bottomView, soundAnimationView] {
            view.layer.removeAllAnimations()
            view.alpha = 1
            refresh(subview: view, status: .recording)
        }
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
        guard state.requestID != nil, !state.captureStopRequested else { return }
        if state.mode == .dictation && soundAnimationStatus != .cancel && !state.discard {
            state.automaticallySendsTranscript = soundAnimationStatus == .recording && wy_captureConfiguration.dictationSendsOnRelease
            soundAnimationStatus = .transfer
        }
        state.animationRevision += 1
        let revision = state.animationRevision
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            for view in [self.leftView, self.rightView, self.bottomView, self.soundAnimationView] { view.alpha = 0 }
        } completion: { [weak self] _ in
            guard let self, self.state.animationRevision == revision else { return }
            self.bottomView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(self.recordAnimationConfig.areaHeight)
            }
        }
        wy_stopCapture()
    }

    func wy_impl_switchStatus(_ touchPoint: CGPoint) {

        let status: WYSoundAnimationStatus
        // 判断触摸点是否在 指定View 上面
        if leftView.wy_containsActionPoint(leftView.moveUpView.convert(touchPoint, from: self)) {
            status = .cancel
        } else if recordAnimationConfig.supportSpeechRecognition && rightView.wy_containsActionPoint(rightView.moveUpView.convert(touchPoint, from: self)) {
            status = .transfer
        } else if bottomLayer.path?.contains(bottomView.convert(touchPoint, from: self)) ?? bottomView.frame.contains(touchPoint) {
            status = .recording
        } else {
            status = .recording
        }

        guard soundAnimationStatus != status else {
            return
        }
        soundAnimationStatus = status
        wy_updateLiveText()
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
        state.lastLayoutSize = .zero
        setNeedsLayout()

        switch status {
        case .recording:
            if subview == leftView {
                leftView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.size.equalTo(leftView.wy_actionSize(touched: false))
                    leftView.refresh(tipsState: .cancel, isTouched: false)
                }
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.size.equalTo((subview as? WYMoveUpTipsView)?.wy_actionSize(touched: false) ?? .zero)
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
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(self.recordAnimationConfig.actionStyle == .curved ? self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal : self.recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.size.equalTo((subview as? WYMoveUpTipsView)?.wy_actionSize(touched: true) ?? .zero)
                }
                leftView.refresh(tipsState: .cancel, isTouched: true)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal)
                    make.size.equalTo((subview as? WYMoveUpTipsView)?.wy_actionSize(touched: false) ?? .zero)
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
                    make.size.equalTo((subview as? WYMoveUpTipsView)?.wy_actionSize(touched: false) ?? .zero)
                }
                leftView.refresh(tipsState: .cancel, isTouched: false)
            }

            if subview == rightView {
                rightView.moveUpView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(self.recordAnimationConfig.actionStyle == .curved ? self.recordAnimationConfig.moveUpButtonCenterOffsetY.onExternal : self.recordAnimationConfig.moveUpButtonCenterOffsetY.onInterior)
                    make.size.equalTo((subview as? WYMoveUpTipsView)?.wy_actionSize(touched: true) ?? .zero)
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
        state.animationRevision += 1
        state.discard = true
        if state.requestID != nil { wy_stopCapture() }
        state.speech?.cancel()
        state.watchdog?.invalidate()
        state.watchdog = nil
        wy_clearTranscript()
        state.audioKit?.releaseAll()
        state.audioKit = nil
        alpha = 0
    }

    func wy_impl_wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {

        guard !isPause, state.requestID != nil else { return }
        state.timedOut = isTimeout
        if state.discard {
            try? audioKit.deleteRecordingFile()
            wy_captureFinished(nil, duration: state.duration, error: nil)
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
        guard state.requestID != nil, currentTime.isFinite else { return }
        state.duration = max(0, currentTime)
        delegate?.wy_recordingTimeUpdated?(self, currentTime: state.duration, maximumDuration: recordAnimationConfig.recordTime.max)
    }

    func wy_impl_wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) {
        wy_captureProgress(state.duration, peak: peakPower, average: averagePower, reportsTime: false)
    }

    func wy_impl_wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        if state.requestID != nil { wy_captureFinished(nil, duration: state.duration, error: wy_recordError(description ?? String(describing: error))) }
    }
}

/// 录音面板随实际容器重排
extension WYRecordAnimationView {
    func wy_layoutRecordingHint() {
        guard let sound = state.soundAnimationView else { return }
        let config = recordAnimationConfig
        let curved = config.actionStyle == .curved
        state.bottomTitleView?.isHidden = curved
        state.leftView?.tipsView.isHidden = curved
        state.rightView?.tipsView.isHidden = curved
        let label: UILabel
        if let existing = state.recordingHint { label = existing }
        else {
            label = UILabel()
            label.numberOfLines = 0
            label.accessibilityIdentifier = "WYChatRecording.hint"
            addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.trailing.equalTo(sound)
                make.top.equalTo(sound.snp.bottom).offset(config.recordingHintSpacing.isFinite ? max(0, config.recordingHintSpacing) : 0)
            }
            state.recordingHint = label
        }
        label.isHidden = !curved || state.editPanel?.isHidden == false
        label.font = config.tipsInfoForMoveUp.font
        label.textColor = config.tipsInfoForMoveUp.color
        label.textAlignment = soundAnimationStatus == .transfer ? .right : .center
        let text: String
        switch soundAnimationStatus {
        case .recording: text = state.mode == .dictation ? config.dictationReleaseText : config.recordViewTips.onInterior
        case .cancel: text = config.cancelRecordViewText.tips
        case .transfer: text = config.transferViewText.tips
        }
        if label.text != text { label.text = text }
        label.snp.updateConstraints { make in make.top.equalTo(sound.snp.bottom).offset(config.recordingHintSpacing.isFinite ? max(0, config.recordingHintSpacing) : 0) }
    }

    func wy_layoutRecordingView() {
        wy_layoutTranscriptEditor()
        wy_layoutRecordingHint()
        guard bounds.width > 0, bounds.height > 0, state.lastLayoutSize != bounds.size else { return }
        state.lastLayoutSize = bounds.size
        let config = recordAnimationConfig
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
        let windowScale = min(1, bounds.width / max(1, UIDevice.wy_screenWidth))
        let desiredOffset = config.actionStyle == .curved ? config.curvedActionCenterOffsetX * windowScale : config.moveUpButtonCenterOffsetX
        if config.actionStyle == .curved {
            for view in [state.leftView, state.rightView].compactMap({ $0 }) { view.moveUpView.snp.updateConstraints { make in make.size.equalTo(view.wy_actionSize(touched: view.moveUpView.isSelected)) } }
        }
        let offset = min(max(0, desiredOffset), max(0, config.actionStyle == .curved ? bounds.width / 2 : (bounds.width - diameter) / 2))
        if let left = state.leftView { left.snp.updateConstraints { make in make.centerX.equalToSuperview().offset(config.supportSpeechRecognition ? -offset : 0) } }
        if let right = state.rightView {
            right.isHidden = !config.supportSpeechRecognition
            right.snp.updateConstraints { make in make.centerX.equalToSuperview().offset(offset) }
        }
        if let sound = state.soundAnimationView {
            let desiredWidth: CGFloat
            var desiredHeight: CGFloat
            switch soundAnimationStatus {
            case .recording: desiredWidth = state.mode == .dictation ? config.soundWavesViewWidth.transfer : config.soundWavesViewWidth.recording; desiredHeight = config.soundWavesViewHeight.recording
            case .cancel: desiredWidth = config.soundWavesViewWidth.cancel; desiredHeight = config.soundWavesViewHeight.cancel
            case .transfer: desiredWidth = config.soundWavesViewWidth.transfer; desiredHeight = config.soundWavesViewHeight.transfer
            }
            let width = min(bounds.width, max(0, desiredWidth))
            if sound.showsLiveText {
                let insets = sound.wy_liveTextInsets
                let textHeight = sound.textView.sizeThatFits(CGSize(width: max(1, width - insets.left - insets.right), height: .greatestFiniteMagnitude)).height
                desiredHeight = max(desiredHeight, min(config.recognitionPanelHeight, textHeight + insets.top + sound.wy_liveTextFooterHeight))
            }
            let minimumBottom = max(0, config.areaHeight) + max(0, config.moveUpButtonOffset.bottom) + max(0, config.moveUpButtonOffset.top)
            let desiredBottom = max(config.soundWavesViewBottomOffset.isFinite ? max(0, config.soundWavesViewBottomOffset) : 0, minimumBottom.isFinite ? minimumBottom : 0)
            let bottom = min(desiredBottom, max(0, bounds.height - safeAreaInsets.top - max(0, config.recognitionPanelOuterInsets.top) - 1))
            let height = min(max(1, bounds.height - safeAreaInsets.top - max(0, config.recognitionPanelOuterInsets.top) - bottom), max(0, desiredHeight))
            let desiredCenter = soundAnimationStatus == .cancel ? (config.supportSpeechRecognition ? -offset : 0) - config.moveUpButtonDiameter.onInterior / 2 + width / 2 : 0
            let center = min(max(0, (bounds.width - width) / 2), max(-(bounds.width - width) / 2, desiredCenter))
            sound.snp.updateConstraints { make in
                make.centerX.equalToSuperview().offset(center)
                make.width.equalTo(width)
                make.height.equalTo(height)
                make.bottom.equalToSuperview().offset(-bottom)
            }
        }
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
        return arrow + max(wy_liveTextInsets.bottom, (offset.isFinite ? max(0, offset) : 0) + max(0, soundWavesSize(for: currentStatus).height) + (spacing.isFinite ? max(0, spacing) : 0))
    }

    func wy_layoutTranscriptText() {
        guard showsLiveText else { return }
        let insets = wy_liveTextInsets
        let frame = CGRect(x: insets.left, y: insets.top, width: max(1, bounds.width - insets.left - insets.right), height: max(1, bounds.height - insets.top - wy_liveTextFooterHeight))
        if textView.frame != frame { textView.frame = frame }
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        if !textView.text.isEmpty, lastScrolledText != textView.text || lastTextBounds != textView.bounds {
            lastScrolledText = textView.text
            lastTextBounds = textView.bounds
            textView.scrollRangeToVisible(NSRange(location: textView.text.utf16.count - 1, length: 1))
        }
    }

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
        let actualRadius = min(radius.isFinite ? max(0, radius) : 0, allowedRadius)
        if cornerRadius != actualRadius { cornerRadius = actualRadius }
        if showsArrow != visible { showsArrow = visible }
        let actualArrow = visible ? CGSize(width: base, height: arrowDepth) : .zero
        if arrowSize != actualArrow { arrowSize = actualArrow }
        if arrowEdgePadding != 0 { arrowEdgePadding = 0 }
        let limit = max(0, (edge - cornerRadius * 2 - base) / 2)
        let actualOffset = visible ? min(limit, max(-limit, arrowOffset.isFinite ? arrowOffset : 0)) : 0
        if arrowOffset != actualOffset { arrowOffset = actualOffset }
        if customArrowView.superview == nil { addSubview(customArrowView) }
        customArrowView.image = recordAnimationConfig.bubbleArrowImage?.withRenderingMode(recordAnimationConfig.bubbleArrowImageTintColor == nil ? .alwaysOriginal : .alwaysTemplate)
        customArrowView.tintColor = recordAnimationConfig.bubbleArrowImageTintColor
        customArrowView.contentMode = .scaleAspectFit
        customArrowView.isHidden = customArrowView.image == nil
        if !customArrowView.isHidden {
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
            customArrowView.frame = rect.offsetBy(dx: point.x, dy: point.y)
        }
        let desired = soundWavesSize(for: currentStatus)
        let width = min(max(0, desired.width), max(0, bounds.width - cornerRadius * 2))
        let height = min(max(0, desired.height), max(0, bounds.height - cornerRadius * 2))
        let trailing = showsLiveText || currentStatus == .transfer
        let offset = recordAnimationConfig.soundWavesRightOffsetForAirBubble
        let insetX = offset.x.isFinite ? max(0, offset.x) : 0
        let insetY = offset.y.isFinite ? max(0, offset.y) : 0
        let rightArrow = showsArrow && arrowDirection == .right ? arrowSize.height : 0
        let bottomArrow = showsArrow && arrowDirection == .bottom ? arrowSize.height : 0
        let offsetX = trailing ? bounds.width / 2 - rightArrow - insetX - width / 2 : 0
        let offsetY = trailing ? bounds.height / 2 - bottomArrow - insetY - height / 2 : 0
        let layout = CGRect(x: min(max(0, (bounds.width - width) / 2), max(-(bounds.width - width) / 2, offsetX)), y: min(max(0, (bounds.height - height) / 2), max(-(bounds.height - height) / 2, offsetY)), width: width, height: height)
        if waveLayout != layout {
            waveLayout = layout
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

/// 录音按钮文字与路径布局
final class WYChatRecordingActionButton: UIButton {
    var layoutHandler: (() -> Void)?
    override func layoutSubviews() {
        titleLabel?.transform = .identity
        super.layoutSubviews()
        layoutHandler?()
    }
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
        actionTipsState = tipsState
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
            let targetX = min(size.width - halfBand, max(halfBand, size.width / 2 + (actionTipsState == .cancel ? inset : -inset)))
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
