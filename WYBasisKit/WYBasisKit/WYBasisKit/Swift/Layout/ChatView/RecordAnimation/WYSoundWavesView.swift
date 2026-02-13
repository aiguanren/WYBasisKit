//
//  WYSoundWavesView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/10.
//

import UIKit

@frozen public enum WYSoundWavesStatus: Int {
    
    /// 声播正常录制状态
    case recording = 0
    
    /// 语音转文字状态
    case transfer
    
    /// 准备取消状态
    case cancel
}

public class WYSoundWavesView: UIImageView {
    
    public lazy var animationView: WYSoundAnimationView = {
        let animationView: WYSoundAnimationView = WYSoundAnimationView()
        addSubview(animationView)
        return animationView
    }()
    
    public init(_ status: WYSoundWavesStatus = .recording) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        refreshSoundWaves(status: status)
    }
    
    public func refreshSoundWaves(meters: [CGFloat] = [], status: WYSoundWavesStatus) {
        switch status {
        case .recording:
            image = recordAnimationConfig.backgroundImageForMoveup.recording
            tintColor = recordAnimationConfig.backgroundColorForMoveup.recording
            animationView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.recording)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.recording)
            }
            break
        case .transfer:
            image = recordAnimationConfig.backgroundImageForMoveup.transfer
            tintColor = recordAnimationConfig.backgroundColorForMoveup.transfer
            animationView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.transfer)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.transfer)
            }
            break
        case .cancel:
            image = recordAnimationConfig.backgroundImageForMoveup.cancel
            tintColor = recordAnimationConfig.backgroundColorForMoveup.cancel
            animationView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.cancel)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.cancel)
            }
            break
        }
        animationView.refreshSoundWaves(meters: meters, status: status)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class WYSoundAnimationView: UIView {
    
    private var soundWavesMeters: [CGFloat] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var soundWavesStatus: WYSoundWavesStatus = .recording
    
    public init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    public func refreshSoundWaves(meters: [CGFloat] = [], status: WYSoundWavesStatus) {
        soundWavesStatus = status
        soundWavesMeters = meters
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard soundWavesMeters.isEmpty == false else {
            return
        }
        
        // 该值代表低于 silent 的声音都认为无声音
        var silent: Double = (-recordAnimationConfig.soundWavesHeight.recording)
        
        // 该值代表最高声音为 highVoice
        var highVoice: Double = recordAnimationConfig.soundWavesHeight.recording
        
        /// 声波线颜色
        var colorOfSoundWaves: UIColor = recordAnimationConfig.colorOfSoundWavesOnRecording.recording
        
        switch soundWavesStatus {
        case .transfer:
            silent = (-recordAnimationConfig.soundWavesHeight.transfer)
            highVoice = recordAnimationConfig.soundWavesHeight.transfer
            colorOfSoundWaves = recordAnimationConfig.colorOfSoundWavesOnRecording.transfer
            break
        case .cancel:
            silent = (-recordAnimationConfig.soundWavesHeight.cancel)
            highVoice = recordAnimationConfig.soundWavesHeight.cancel
            colorOfSoundWaves = recordAnimationConfig.colorOfSoundWavesOnRecording.cancel
            break
        default:
            break
        }
        
        let context: CGContext? = UIGraphicsGetCurrentContext()
        context?.setLineCap(.round)
        context?.setLineJoin(.round)
        context?.setStrokeColor(colorOfSoundWaves.cgColor)
        context?.setLineWidth(recordAnimationConfig.soundWavesWidth)
        
        for (index, var soundWaves) in soundWavesMeters.enumerated() {
            soundWaves = max(soundWaves, silent)
            let lineHeight: CGFloat = (highVoice + soundWaves)
            let startX: CGFloat = ((CGFloat(index) * recordAnimationConfig.soundWavesWidth * 2) + recordAnimationConfig.soundWavesSpace)
            let startY: CGFloat = (lineHeight > highVoice) ? 0 : ((highVoice - lineHeight) / 2)
            context?.move(to: CGPoint(x: startX, y: startY))
            context?.addLine(to: CGPoint(x: startX, y: startY + lineHeight))
        }
        context?.strokePath()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
