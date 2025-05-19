//
//  WYRecordAnimationView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/4.
//

import UIKit
import AVFoundation
import CoreAudio
import CoreAudioTypes
import WYBasisKit

public struct WYRecordAnimationConfig {
    
    /// 声波线宽度
    public var soundWavesWidth: CGFloat = wy_screenWidth(3)
    
    /// 声波线最大高度
    public var soundWavesHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                                recording: wy_screenWidth(40),
                                                cancel: wy_screenWidth(30),
                                                transfer: wy_screenWidth(30))
    
    /// 声波控件最大宽度
    public var soundWavesViewWidth: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                                recording: wy_screenWidth(280),
                                                cancel: wy_screenWidth(130),
                                                transfer: wy_screenWidth(525))
    
    /// 声波控件最大高度
    public var soundWavesViewHeight: (recording: CGFloat,
                                  cancel: CGFloat,
                                  transfer: CGFloat) = (
                                    recording: wy_screenWidth(130),
                                                cancel: wy_screenWidth(90),
                                                transfer: wy_screenWidth(170))
    
    /// 声波线之间的间距
    public var soundWavesSpace: CGFloat = wy_screenWidth(3)
    
    /// 声波显示条数
    public var severalSoundWaves: (recording: NSInteger,
                                   cancel: NSInteger,
                                   transfer: NSInteger) = (recording: 25,
                                                           cancel: 10,
                                                           transfer: 10)
    
    /// 声波线颜色
    public var colorOfSoundWavesOnRecording: (recording: UIColor,
                                              cancel: UIColor,
                                              transfer: UIColor) = (recording: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    cancel: .wy_hex("282828").withAlphaComponent(0.6),
                                                                    transfer: .wy_hex("282828").withAlphaComponent(0.6))
    
    /// 录音时声波动画背景图
    public var backgroundImageForRecording: UIImage = WYRecordAnimationConfig.soundWavesDefaultImage()
    
    /// 取消录音或者转文字时声波动画背景图
    public var backgroundImageForMoveup: (cancel: UIImage,
                                          transfer: UIImage) = (
                                            cancel: WYRecordAnimationConfig.soundWavesDefaultImage(),
                                            transfer: WYRecordAnimationConfig.soundWavesDefaultImage(UIEdgeInsets(top: wy_screenWidth(10), left: wy_screenWidth(10), bottom: wy_screenWidth(20), right: wy_screenWidth(100))))
    
    /// 录音时声波动画背景色
    public var backgroundColorForRecording: UIColor = .wy_rgb(169, 233, 121)
    
    /// 取消录音或者转文字时声波动画背景色
    public var backgroundColorForMoveup: (cancel: UIColor,
                                          transfer: UIColor) = (
                                            cancel: .wy_rgb(231, 94, 88),
                                            transfer: .wy_rgb(169, 233, 121))
    
    /// 取消按钮背景图
    public var cancelRecordViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: wy_screenWidth(100), height: wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: wy_screenWidth(80), height: wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮内部文本和提示文本
    public var cancelRecordViewText: (onInterior: String, tips: String) = (onInterior: "×", tips: "松开 取消")
    
    /// 转文字按钮内部文本和提示文本
    public var transferViewText: (onInterior: String, tips: String) = (onInterior: "文", tips: "转文字")
    
    /// 录音按钮提示文本
    public var recordViewTips: String = "松开 发送"
    
    /// 转文字按钮背景图
    public var transferViewImage: (onInterior: UIImage, onExternal: UIImage) = (onInterior: .wy_createImage(from: .wy_rgb(236, 236, 236), size: CGSize(width: wy_screenWidth(100), height: wy_screenWidth(100))).wy_cuttingRound(), onExternal: .wy_createImage(from: .wy_rgb(57, 57, 57), size: CGSize(width: wy_screenWidth(80), height: wy_screenWidth(80))).wy_cuttingRound())
    
    /// 取消按钮及转文字按钮的提示语字号和色值
    public var tipsInfoForMoveup: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(15)), color: .wy_rgb(163, 163, 163))
    
    /// 录音按钮提示语字体及色值
    public var recordViewTipsInfo: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(15)), color: .wy_rgb(163, 163, 163))
    
    /// 取消录音按钮内部字体、色值
    public var cancelRecordViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(30)), color: .wy_rgb(20, 20, 20))
    
    /// 取消录音按钮外部字体、色值
    public var cancelRecordViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(30)), color: .wy_rgb(156, 156, 156))
    
    /// 转文字按钮内部字体、色值
    public var transferViewTextInfoForInterior: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(30)), color: .wy_rgb(20, 20, 20))
    
    /// 转文字按钮外部字体、色值
    public var transferViewTextInfoForExternal: (font: UIFont, color: UIColor) = (font: .systemFont(ofSize: wy_screenWidth(30)), color: .wy_rgb(156, 156, 156))
    
    /// 取消录音按钮和转文字按钮的偏转角度
    public var moveupViewDeviationAngle: CGFloat = wy_screenWidth(28)
    
    /// 录音按钮背景色
    public var recordViewColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .white)
    
    /// 录音按钮阴影色值
    public var recordViewShadowColor:(onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .wy_rgb(57, 57, 57))
    
    /// 录音按钮图标及图标、size
    public var recordViewImageInfo: (icon: UIImage, size: CGSize) = (icon: UIImage.wy_find("WYChatViewSoundWavesRecord", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate), size: CGSize(width: wy_screenWidth(27.2), height: wy_screenWidth(55)))
    
    /// 录音按钮图标色值
    public var recordViewImageColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .wy_rgb(57, 57, 57), onExternal: .wy_rgb(156, 156, 156))
    
    /// 声波动画滑动区域圆弧的半径
    public var arcRadian: CGFloat = wy_screenWidth(35)
    
    /// 声波动画可滑动区域的高度
    public var areaHeight: CGFloat = wy_screenWidth(150)
    
    /// 整个声波动画组件向下偏移多少(可兼顾齐刘海)
    public var recordViewBottomOffset: CGFloat = wy_tabbarSafetyZone
    
    /// 取消录音或者语音转文字按钮直径
    public var moveupButtonDiameter: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: wy_screenWidth(100), onExternal: wy_screenWidth(80))
    
    /// 取消录音或者语音转文字按钮中心点距离底部圆弧顶点的间距
    public var moveupButtonBottomOffset: CGFloat = wy_screenWidth(65)
    
    /// 取消录音或者语音转文字按钮中心点距离声波动画控件底部的间距
    public var moveupButtonTopOffset: CGFloat = wy_screenWidth(130)
    
    /// 取消录音或者语音转文字按钮中心点距离tip控件底部的间距
    public var moveupButtonCenterOffsetY: (onInterior: CGFloat, onExternal: CGFloat) = (onInterior: wy_screenWidth(55), onExternal: wy_screenWidth(45))
    
    /// 取消录音按钮和转文字按钮中心点X值距离屏幕父控件左侧或者右侧的间距
    public var moveupButtonCenterOffsetX: CGFloat = wy_screenWidth(wy_screenWidth(100))
    
    /// 声波动画操作区边缘颜色
    public var strokeColor: UIColor = .clear
    
    /// 声波动画操作区内部填充色(手指在操作区域内部或者外部)
    public var fillColor: (onInterior: UIColor, onExternal: UIColor) = (onInterior: .white.withAlphaComponent(0.5), onExternal: .black.withAlphaComponent(0.5))
    
    /// 声波动画操作区阴影位置，(0, 0)时四周都有阴影
    public var shadowOffset: CGSize = CGSize(width: -wy_screenWidth(5), height: -wy_screenWidth(5))
    
    /// 声波动画操作区阴影颜色
    public var shadowColor: UIColor = .white
    
    /// 声波动画操作区阴影透明度
    public var shadowOpacity: CGFloat = 0.1
    
    /// 最多可以录制多少秒(最长录音时间)
    public var maxRecordTime: TimeInterval = 60
    
    /// 获取录音默认背景图
    private static func soundWavesDefaultImage(_ capInsets: UIEdgeInsets = UIEdgeInsets(top: wy_screenWidth(10), left: wy_screenWidth(10), bottom: wy_screenWidth(20), right: wy_screenWidth(10))) -> UIImage {
        
        return UIImage.wy_find("WYChatViewDecibel", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
    }
}

/// 聊天录音计时器Key
public let recordManagerTimerKey: String = "WYRecordManagerTimerKey"

public class WYRecordAnimationView: UIView {
    
    /// 录音文件保存地址
    public let url: URL = WYStorage.createDirectory(directory: .documentDirectory, subDirectory: "WYChatAudio")
    
    /// 录音时间
    public var recordTime: CGFloat = 0.0
    
    /// 声音数据
    public var soundMeters: [CGFloat] = []
    
    /// 波形更新间隔
    public var updateFequency: CGFloat = 0.05
    
    /// 创建录音器
    public lazy var audioRecorder: AVAudioRecorder? = {
        
        let audioSession: AVAudioSession? = AVAudioSession.sharedInstance()
        try? audioSession?.setCategory(.playAndRecord)
        try? audioSession?.setActive(true)
        
        // 创建录音文件保存路径
        let url: URL = WYStorage.createDirectory(directory: .documentDirectory, subDirectory: "WYChatAudio")
        
        let audioRecorder: AVAudioRecorder? = try? AVAudioRecorder(url: url, settings: sharedAudioSetting())
        // 如果要监控声波则必须设置为true
        audioRecorder?.isMeteringEnabled = true
        
        return audioRecorder
    }()
    
    /// 当前录音状态
    public var soundWavesStatus: WYSoundWavesStatus = .recording
    
    public init(alpha: CGFloat = 1.0) {
        super.init(frame: .zero)
        backgroundColor = recordAnimationConfig.fillColor.onExternal
        self.alpha = alpha
    }
    
    public func record() {
        audioRecorder?.record()
        Timer.wy_start(recordManagerTimerKey, Int.max, updateFequency) { [weak self] remainingTime in
            DispatchQueue.main.async {
                self?.audioRecorder?.updateMeters()
                self?.recordTime += (self?.updateFequency ?? 0)
                self?.addSoundMeter(item: CGFloat(self?.audioRecorder?.averagePower(forChannel: 0) ?? 0))
                if (self?.recordTime ?? 0) >= recordAnimationConfig.maxRecordTime {
                    self?.endRecordVoice()
                }
            }
        }
    }
    
    public func addSoundMeter(item: CGFloat) {
        var canSoundMetersCount: NSInteger = 0
        
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
        if soundMeters.count <  canSoundMetersCount {
            soundMeters.append(item)
        }else {
            for index: NSInteger in 0 ..< soundMeters.count {
                if index < (canSoundMetersCount - 1) {
                    soundMeters[index] = soundMeters[index + 1]
                }
            }
            // 插入新数据
            soundMeters[canSoundMetersCount - 1] = item
            soundWavesView.animationView.refreshSoundWaves(meters: soundMeters, status: soundWavesStatus)
        }
    }
    
    public func endRecordVoice() {
        audioRecorder?.stop()
        Timer.wy_cancel(recordManagerTimerKey)
        soundMeters.removeAll()
    }
    
    /// 开始录音动画
    public func start() {
        UIView.animate(withDuration: 0.18,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseIn) { [weak self] in
            self?.alpha = 1.0
            self?.bottomView.alpha = 1.0
            self?.bottomView.snp.updateConstraints({ make in
                make.bottom.equalToSuperview().offset(0)
            })
        }
        
        guard audioRecorder != nil else {
            return
        }
        
        record()
    }
    
    /// 结束录音动画
    public func stop() {
        endRecordVoice()
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 1,
                       options: .curveEaseOut) { [weak self] in
            self?.alpha = 0.0
            self?.bottomView.alpha = 0.0
        }completion: { [weak self] _ in
            
            guard let self = self else { return }
            
            self.bottomView.snp.updateConstraints({ make in
                make.bottom.equalToSuperview().offset(recordAnimationConfig.areaHeight)
            })
            self.refresh(subview: self.leftView, status: .recording)
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
                self.refresh(subview: self.bottomView, status: .recording)
                break
            case .cancel:
                self.refresh(subview: self.leftView, status: .cancel)
                self.refresh(subview: self.bottomView, status: .cancel)
                break
            case .transfer:
                self.refresh(subview: self.leftView, status: .transfer)
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
                    make.width.height.equalTo(CGSize(width: wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                    leftView.refresh(isDefault: true, isTouched: false)
                }
            }
            
            if subview == soundWavesView {
                
                soundWavesView.snp.updateConstraints { make in
                    make.size.equalTo(CGSize(width: recordAnimationConfig.soundWavesViewWidth.recording, height: recordAnimationConfig.soundWavesViewHeight.recording))
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
                    make.width.height.equalTo(CGSize(width: wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onInterior), height: recordAnimationConfig.moveupButtonDiameter.onInterior))
                }
                leftView.refresh(isDefault: true, isTouched: true)
            }
            
            if subview == soundWavesView {
                
                soundWavesView.snp.updateConstraints { make in
                    make.size.equalTo(CGSize(width: recordAnimationConfig.soundWavesViewWidth.cancel, height: recordAnimationConfig.soundWavesViewHeight.cancel))
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
                    make.width.height.equalTo(CGSize(width: wy_screenWidth(recordAnimationConfig.moveupButtonDiameter.onExternal), height: recordAnimationConfig.moveupButtonDiameter.onExternal))
                }
                leftView.refresh(isDefault: true, isTouched: false)
            }
            
            if subview == soundWavesView {
                soundWavesView.snp.updateConstraints { make in
                    make.size.equalTo(CGSize(width: recordAnimationConfig.soundWavesViewWidth.transfer, height: recordAnimationConfig.soundWavesViewHeight.transfer))
                }
                soundWavesView.refreshSoundWaves(status: .transfer)
            }
            
            if subview == bottomView {
                bottomLayer.fillColor = recordAnimationConfig.fillColor.onExternal.cgColor
            }
            break
        }
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
            make.center.equalTo(CGPoint(x: frame.size.width / 2, y: frame.size.height - recordAnimationConfig.areaHeight - recordAnimationConfig.moveupButtonBottomOffset - recordAnimationConfig.moveupButtonTopOffset - (recordAnimationConfig.soundWavesViewHeight.recording / 2)))
            make.size.equalTo(CGSize(width: recordAnimationConfig.soundWavesViewWidth.recording, height: recordAnimationConfig.soundWavesViewHeight.recording))
        }
        return soundWavesView
    }()
    
    public lazy var leftView: WYMoveupTipsView = {
        
        let leftView: WYMoveupTipsView = WYMoveupTipsView(isDefault: true)
        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-recordAnimationConfig.moveupButtonCenterOffsetX)
            make.centerY.equalTo(self.snp.bottom).offset(-(recordAnimationConfig.areaHeight + recordAnimationConfig.moveupButtonBottomOffset))
        }
        return leftView
    }()
    
    /**
     *  录音文件设置
     *  @return 录音设置
     */
    public func sharedAudioSetting() -> Dictionary<String, Any> {
        
        var dictionary: Dictionary = Dictionary<String, Any>()
        // 设置录音格式
        dictionary[AVFormatIDKey] = kAudioFormatMPEG4AAC
        // 设置录音采样率，8000是电话采样率，对于一般录音已经够了
        dictionary[AVSampleRateKey] = 44100.0
        // 设置通道,这里采用单声道
        dictionary[AVNumberOfChannelsKey] = 1
        // 每个采样点位数,分为8、16、24、32
        dictionary[AVLinearPCMBitDepthKey] = 8
        // 是否使用浮点数采样
        dictionary[AVLinearPCMIsFloatKey] = true
        
        return dictionary
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        endRecordVoice()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
