//
//  WYRecordAnimationView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/4.
//

import UIKit
import AVFoundation

@objc public protocol WYRecordEventsHandler {
    
    /**
     录音开始
     - Parameters:
     - audioKit: 音频工具实例
     - isResume: 是否是恢复录音
     */
    @objc(wy_audioRecorderDidStart:isResume:)
    optional func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool)
    
    /**
     录音停止
     - Parameters:
     - audioKit: 音频工具实例
     - isPause: 是否是暂停录音
     - isTimeout: 是否是超时(达到最大录音时长)停止
     */
    @objc(wy_audioRecorderDidStop:isPause:isTimeout:)
    optional func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool)
    
    /**
     录音时间更新
     - Parameters:
     - audioKit: 音频工具实例
     - currentTime: 当前录音时间（秒）
     - duration: 总录音时长限制（秒）
     */
    @objc(wy_audioRecorderTimeUpdated:currentTime:duration:)
    optional func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval)
    
    /**
     录音声波数据更新（单通道）
     - Parameters:
       - audioKit: 音频工具实例
       - peakPower: 当前峰值功率（dB），范围 -160.0 到 0.0（0.0 表示最响，-160.0 表示最安静）；适合用于实时响应敏感的声波动画，但可能导致动画跳动剧烈
       - averagePower: 当前平均功率（dB），范围 -160.0 到 0.0；比 peakPower 更平滑，适合语音录制页面的声波动画
     */
    @objc(wy_audioRecorderDidUpdateMetering:peakPower:averagePower:)
    optional func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float)
    
    /**
     音频任务执行失败
     - Parameters:
     - audioKit: 音频工具实例
     - url: 出错的任务相关URL（可选，可能是本地或远程）
     - error: 错误枚举值
     - description: 详细错误描述(可选)
     */
    @objc(wy_audioTaskDidFailed:url:error:description:)
    optional func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?)
}

public class WYRecordAnimationView: UIView {
    
    /// 代理
    public weak var delegate: WYRecordEventsHandler? = nil
    
    /// 声音数据
    public var soundMeters: [CGFloat] = []
    
    /// 创建录音器
    public lazy var audioKit: WYAudioKit? = {
        
        let kit = WYAudioKit()
        kit.delegate = self
        kit.minimumRecordDuration = recordAnimationConfig.recordTime.min
        kit.maximumRecordDuration = recordAnimationConfig.recordTime.max
        
        var setingDictionary: Dictionary = Dictionary<String, Any>()
        // 设置录音格式
        setingDictionary[AVFormatIDKey] = kAudioFormatMPEG4AAC
        // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
        setingDictionary[AVSampleRateKey] = 44100.0
        // 设置通道,这里采用单声道
        setingDictionary[AVNumberOfChannelsKey] = 1
        // 每个采样点位数,分为8、16、24、32
        setingDictionary[AVLinearPCMBitDepthKey] = 8
        // 是否使用浮点数采样
        setingDictionary[AVLinearPCMIsFloatKey] = true
        
        kit.recordSettings = setingDictionary
        
        return kit
    }()
    
    /// 当前录音状态
    public var soundWavesStatus: WYSoundWavesStatus = .recording
    
    public init(alpha: CGFloat = 1.0, delegate: WYRecordEventsHandler? = nil) {
        super.init(frame: .zero)
        backgroundColor = recordAnimationConfig.fillColor.onExternal
        self.alpha = alpha
        self.delegate = delegate
    }
    
    public func addSoundMeter(item: CGFloat) {
        var canSoundMetersCount: Int = 0
        
        switch soundWavesStatus {
        case .recording:
            canSoundMetersCount = recordAnimationConfig.severalSoundWaves.recording
            break
        case .cancel:
            canSoundMetersCount = recordAnimationConfig.severalSoundWaves.cancel
            break
        case .transfer:
            canSoundMetersCount = recordAnimationConfig.severalSoundWaves.transfer
            break
        }
        if soundMeters.count < canSoundMetersCount {
            soundMeters.append(item)
        }else {
            for index: Int in 0 ..< soundMeters.count {
                if index < (canSoundMetersCount - 1) {
                    soundMeters[index] = soundMeters[index + 1]
                }
            }
            // 插入新数据
            soundMeters[canSoundMetersCount - 1] = item
            soundWavesView.animationView.refreshSoundWaves(meters: soundMeters, status: soundWavesStatus)
        }
    }
    
    /// 开始录音动画
    public func start() {
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
        
        soundMeters.removeAll()
        
        try? audioKit?.startRecording()
    }
    
    /// 结束录音动画
    public func stop() {
        endRecordVoice()
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
            self.refresh(subview: self.soundWavesView, status: .recording)
        }
    }
    
    /// 录音功能区切换操作
    public func switchStatus(_ status: WYSoundWavesStatus) {
        
        guard soundWavesStatus != status else {
            return
        }
        soundWavesStatus = status
        
        UIView.animate(withDuration: 0.18,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: .curveEaseIn) { [weak self] in
            
            guard let self = self else { return }
            
            switch status {
            case .recording:
                self.refresh(subview: self.leftView, status: .recording)
                self.refresh(subview: self.rightView, status: .recording)
                self.refresh(subview: self.bottomView, status: .recording)
                break
            case .cancel:
                self.refresh(subview: self.leftView, status: .cancel)
                self.refresh(subview: self.rightView, status: .cancel)
                self.refresh(subview: self.bottomView, status: .cancel)
                break
            case .transfer:
                self.refresh(subview: self.leftView, status: .transfer)
                self.refresh(subview: self.rightView, status: .transfer)
                self.refresh(subview: self.bottomView, status: .transfer)
                break
            }
        }
        
        UIView.animate(withDuration: 0.36,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: .curveEaseIn) { [weak self] in
            
            guard let self = self else { return }
            
            switch status {
            case .recording:
                self.refresh(subview: self.soundWavesView, status: .recording)
                break
            case .cancel:
                self.refresh(subview: self.soundWavesView, status: .cancel)
                break
            case .transfer:
                self.refresh(subview: self.soundWavesView, status: .transfer)
                break
            }
        }
    }
    
    /// 刷新子控件视图
    public func refresh(subview: UIView, status: WYSoundWavesStatus) {
        
        switch status {
        case .recording:
            if subview == leftView {
                leftView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                    leftView.refresh(tipsState: .cancel, isTouched: false)
                }
            }
            
            if subview == rightView {
                rightView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                    rightView.refresh(tipsState: .transfer, isTouched: false)
                }
            }
            
            if subview == soundWavesView {
                
                soundWavesView.snp.updateConstraints { make in
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.recording)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.recording)
                }
                soundWavesView.refreshSoundWaves(status: .recording)
            }
            
            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onInterior.cgColor
            }
            break
        case .cancel:
            if subview == leftView {
                leftView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onInterior), height: recordAnimationConfig.moveupButtonDiameter.onInterior))
                }
                leftView.refresh(tipsState: .cancel, isTouched: true)
            }
            
            if subview == rightView {
                rightView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                }
                rightView.refresh(tipsState: .transfer, isTouched: false)
            }
            
            if subview == soundWavesView {
                
                soundWavesView.snp.updateConstraints { make in
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.cancel)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.cancel)
                }
                soundWavesView.refreshSoundWaves(status: .cancel)
            }
            
            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onExternal.cgColor
            }
            break
        case .transfer:
            if subview == leftView {
                leftView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(leftView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onExternal)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                }
                leftView.refresh(tipsState: .cancel, isTouched: false)
            }
            
            if subview == rightView {
                rightView.moveuplView.snp.updateConstraints { make in
                    make.centerY.equalTo(rightView.tipsView.snp.bottom).offset(recordAnimationConfig.moveupButtonCenterOffsetY.onInterior)
                    make.width.height.equalTo(CGSize(width: UIDevice.wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onInterior), height: recordAnimationConfig.moveupButtonDiameter.onInterior))
                }
                rightView.refresh(tipsState: .transfer, isTouched: true)
            }
            
            if subview == soundWavesView {
                soundWavesView.snp.updateConstraints { make in
                    make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.transfer)
                    make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.transfer)
                }
                soundWavesView.refreshSoundWaves(status: .transfer)
            }
            
            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onExternal.cgColor
            }
            break
        }
    }
    
    public func endRecordVoice() {
        guard audioKit != nil else {
            return
        }
        audioKit?.releaseAll()
        audioKit = nil
    }
    
    public lazy var bottomLayer: CAShapeLayer = {
        
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
    }()
    
    public lazy var bottomView: UIView = {
        
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
        return bottomView
    }()
    
    public lazy var soundWavesView: WYSoundWavesView = {
        let soundWavesView: WYSoundWavesView = WYSoundWavesView(.recording)
        addSubview(soundWavesView)
        soundWavesView.snp.makeConstraints { make in
            make.center.equalTo(CGPoint(x: frame.size.width / 2, y: frame.size.height - recordAnimationConfig.areaHeight - recordAnimationConfig.moveupButtonOffset.bottom - recordAnimationConfig.moveupButtonOffset.top - (recordAnimationConfig.soundWavesViewHeight.recording / 2)))
            make.width.equalTo(recordAnimationConfig.soundWavesViewWidth.recording)
            make.height.equalTo(recordAnimationConfig.soundWavesViewHeight.recording)
        }
        return soundWavesView
    }()
    
    public lazy var leftView: WYMoveupTipsView = {
        
        let leftView: WYMoveupTipsView = WYMoveupTipsView(tipsState: .cancel)
        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-recordAnimationConfig.moveupButtonCenterOffsetX)
            make.centerY.equalTo(self.snp.bottom).offset(-(recordAnimationConfig.areaHeight + recordAnimationConfig.moveupButtonOffset.bottom))
        }
        return leftView
    }()
    
    public lazy var rightView: WYMoveupTipsView = {
        
        let rightView: WYMoveupTipsView = WYMoveupTipsView(tipsState: .transfer)
        addSubview(rightView)
        rightView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(recordAnimationConfig.moveupButtonCenterOffsetX)
            make.centerY.equalTo(self.snp.bottom).offset(-(recordAnimationConfig.areaHeight + recordAnimationConfig.moveupButtonOffset.bottom))
        }
        return rightView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        endRecordVoice()
        soundMeters.removeAll()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}

extension WYRecordAnimationView: WYAudioKitDelegate {
    
    /**
     录音开始
     - Parameters:
     - audioKit: 音频工具实例
     - isResume: 是否是恢复录音
     */
    public func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        delegate?.wy_audioRecorderDidStart?(audioKit: audioKit, isResume: isResume)
    }
    
    /**
     录音停止
     - Parameters:
     - audioKit: 音频工具实例
     - isPause: 是否是暂停录音
     - isTimeout: 是否是超时(达到最大录音时长)停止
     */
    public func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {
        
        delegate?.wy_audioRecorderDidStop?(audioKit: audioKit, isPause: isPause, isTimeout: isTimeout)
        
        try? audioKit.saveRecording(destinationUrl: recordAnimationConfig.chatAudioUrl)
        
        endRecordVoice()
    }
    
    /**
     录音时间更新
     - Parameters:
     - audioKit: 音频工具实例
     - currentTime: 当前录音时间（秒）
     - duration: 总录音时长限制（秒）
     */
    public func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
        delegate?.wy_audioRecorderTimeUpdated?(audioKit: audioKit, currentTime: currentTime, duration: duration)
    }
    
    public func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float) {
        delegate?.wy_audioRecorderDidUpdateMetering?(audioKit: audioKit, peakPower: peakPower, averagePower: averagePower)
        addSoundMeter(item: CGFloat(peakPower))
    }
    
    /**
     音频任务执行失败
     - Parameters:
     - audioKit: 音频工具实例
     - url: 出错的任务相关URL（可选，可能是本地或远程）
     - error: 错误枚举值
     - description: 详细错误描述(可选)
     */
    public func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        delegate?.wy_audioTaskDidFailed?(audioKit: audioKit, url: url, error: error, description: description)
    }
}
