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
    var transcriptBackgroundColorProvider: (() -> UIColor?)?
    var gradientView: WYChatGradientRecordingView?
    var gradientGestureOrigin: CGPoint? { didSet { if let gradientGestureOrigin { gradientView?.updateTouchPoint(gradientGestureOrigin, animated: false) } } }
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
    let countdown = WYChatRecordingCountdown()
    let countdownLabel = WYChatRecordingCountdownLabel(identifier: "WYChatRecording.countdown")
    var countdownSeconds: Int?
    let editorDelegate = WYChatTranscriptEditorDelegate()
    let languageButton = UIButton(type: .system)
    let translationButton = UIButton(type: .system)
    let translationReadButton = UIButton(type: .system)
    let translationLanguageButton = UIButton(type: .system)
    let translationCancelButton = UIButton(type: .system)
    let editorEmojiButton = UIButton(type: .system)
    let editorFailureLabel = UILabel()
    let editorFailureImage = UIImageView()
    var editorFailureView: UIStackView?
    var editorEmoji: WYChatEmojiView?
    var editorEmojiBackground: UIView?
    var editorEmojiTop: NSLayoutConstraint?
    var editorEmojiHeight: NSLayoutConstraint?
    var showsEditorEmoji = false
    var editorInputGuide: UILayoutGuide?
    var editorInputTop: NSLayoutConstraint?
    var editorKeyboardTop: NSLayoutConstraint?
    var editorKeyboardRequest: UUID?
    var editorTranslationRequest: (id: String, target: String)?
    var editorTranslatedLocale: String?
    var editorHeight: NSLayoutConstraint?
    var editorAlignmentConstraints: [NSLayoutConstraint] = []
    var editPanel: UIStackView?
    var editorOverlay: WYChatTranscriptOverlay?
    var editorBubble: WYAirBubbleView?
    var editorHeader: UIStackView?
    var editorFooter: UIStackView?
    var editorHeaderWidths: [NSLayoutConstraint] = []
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
        let gradient = recordAnimationConfig.interactionStyle == .gradient
        guard state.requestID == nil else { return }
        guard mode != .dictation || recordAnimationConfig.supportSpeechRecognition else {
            recognitionResultHandler?(nil, wy_recordError(wy_captureConfiguration.recognitionDisabledText))
            return
        }
        state.mode = mode
        state.animationRevision += 1
        soundAnimationStatus = .recording
        state.gradientGestureOrigin = nil
        if gradient {
            UIView.performWithoutAnimation {
                superview?.layoutIfNeeded()
                layoutIfNeeded()
            }
            for view in [state.leftView, state.rightView, state.bottomView, state.soundAnimationView, state.recordingHint] { view?.isHidden = true }
            let view = state.gradientView ?? WYChatGradientRecordingView()
            state.gradientView = view
            view.frame = bounds
            addSubview(view)
            view.refresh(configuration: recordAnimationConfig, cancelled: false, mode: mode, animated: false)
            UIView.performWithoutAnimation { view.layoutIfNeeded() }
            backgroundColor = .clear
            alpha = 1
            wy_beginCapture()
            return
        }
        state.gradientView?.removeFromSuperview()
        for view in [state.leftView, state.bottomView, state.soundAnimationView, state.recordingHint] { view?.isHidden = false }
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
        UIView.animate(withDuration: wy_chatNonnegative(wy_captureConfiguration.overlayShowDuration),
                       delay: 0,
                       usingSpringWithDamping: min(1, wy_chatNonnegative(wy_captureConfiguration.overlayShowDamping)),
                       initialSpringVelocity: wy_chatNonnegative(wy_captureConfiguration.overlaySpringVelocity),
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
        state.gradientView?.removeFromSuperview()
        if wy_captureConfiguration.interactionStyle == .gradient { wy_stopCapture(); return }
        state.animationRevision += 1
        let revision = state.animationRevision
        UIView.animate(withDuration: wy_chatNonnegative(wy_captureConfiguration.overlayHideDuration),
                       delay: 0,
                       usingSpringWithDamping: min(1, wy_chatNonnegative(wy_captureConfiguration.overlayHideDamping)),
                       initialSpringVelocity: wy_chatNonnegative(wy_captureConfiguration.overlaySpringVelocity),
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

        if wy_captureConfiguration.interactionStyle == .gradient {
            state.gradientView?.updateTouchPoint(touchPoint, animated: true)
            let origin = state.gradientGestureOrigin ?? CGPoint(x: bounds.midX, y: bounds.height - safeAreaInsets.bottom)
            let distance = wy_captureConfiguration.gradientCancelDistance
            let cancelled = origin.y - touchPoint.y >= (distance.isFinite ? max(0, distance) : 0)
            let status: WYSoundAnimationStatus = cancelled ? .cancel : .recording
            guard status != soundAnimationStatus else { return }
            soundAnimationStatus = status
            state.gradientView?.refresh(configuration: wy_captureConfiguration, cancelled: cancelled, mode: state.mode, animated: true)
            if wy_captureConfiguration.vibrationFeedback { UIDevice.wy_vibrate(.light) }
            return
        }
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

        UIView.animate(withDuration: wy_chatNonnegative(wy_captureConfiguration.overlayStatusAnimationDuration)) { [weak self] in
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
        state.gradientView?.removeFromSuperview()
        state.gradientGestureOrigin = nil
        state.animationRevision += 1
        state.discard = true
        if state.requestID != nil { wy_stopCapture() }
        state.speech?.cancel()
        wy_clearRecordingCountdown()
        wy_clearTranscript()
        state.audioKit?.releaseAll()
        state.audioKit = nil
        alpha = 0
    }

    func wy_impl_wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {

        guard !isPause, state.requestID != nil else { return }
        state.timedOut = state.timedOut || isTimeout
        if state.discard {
            try? audioKit.deleteRecordingFile()
            wy_captureFinished(nil, duration: state.duration, error: nil)
            return
        }
        guard let source = audioKit.currentRecordFileURL else {
            wy_captureFinished(nil, duration: state.duration, error: wy_recordError(wy_captureConfiguration.shortRecordingText))
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
        if let gradient = state.gradientView, gradient.superview != nil {
            gradient.frame = bounds
            return
        }
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
            if sound.state.showsLiveText {
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
