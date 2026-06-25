//
//  WYSoundAnimationView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/6/17.
//

import UIKit

@frozen public enum WYSoundAnimationStatus: Int {
    
    /// 声播正常录制状态
    case recording = 0
    
    /// 语音转文字状态
    case transfer
    
    /// 准备取消状态
    case cancel
}

public class WYSoundAnimationView: UIImageView {
    
    public lazy var soundWavesView: WYSoundWavesView = {
        let soundWavesView: WYSoundWavesView = WYSoundWavesView()
        addSubview(soundWavesView)
        return soundWavesView
    }()
    
    public init(_ status: WYSoundAnimationStatus = .recording) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        refreshSoundWaves(status: status)
    }
    
    public func refreshSoundWaves(status: WYSoundAnimationStatus) {
        
        switch status {
        case .recording:
            image = recordAnimationConfig.backgroundImageForMoveup.recording
            tintColor = recordAnimationConfig.backgroundColorForMoveup.recording
            soundWavesView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.recording)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.recording)
            }
            break
        case .transfer:
            image = recordAnimationConfig.backgroundImageForMoveup.transfer
            tintColor = recordAnimationConfig.backgroundColorForMoveup.transfer
            soundWavesView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.transfer)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.transfer)
            }
            break
        case .cancel:
            image = recordAnimationConfig.backgroundImageForMoveup.cancel
            tintColor = recordAnimationConfig.backgroundColorForMoveup.cancel
            soundWavesView.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(((recordAnimationConfig.soundWavesWidth + recordAnimationConfig.soundWavesSpace) * CGFloat(recordAnimationConfig.severalSoundWaves.cancel)) - recordAnimationConfig.soundWavesSpace)
                make.height.equalTo(recordAnimationConfig.soundWavesHeight.cancel)
            }
            break
        }
        
        // 更新声波柱子配置
        soundWavesConfigUpdate(status: status, config: &soundWavesView.config)
    }
    
    /// 根据录制状态获取对应声波配置
    public func soundWavesConfigUpdate(status: WYSoundAnimationStatus, config: inout WYSoundWaveConfig) {
        
        let soundWavesColor: UIColor
        switch status {
        case .recording:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.recording
            break
        case .transfer:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.transfer
            break
        case .cancel:
            soundWavesColor = recordAnimationConfig.colorOfSoundWavesOnRecording.cancel
            break
        }
        
        config.wavesColor = soundWavesColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
