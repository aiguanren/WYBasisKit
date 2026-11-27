//
//  WYSoundAnimationView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/6/17.
//

import UIKit

@objc @frozen public enum WYSoundAnimationStatus: Int {
    
    /// 声播正常录制状态
    case recording = 0
    
    /// 语音转文字状态
    case transfer
    
    /// 准备取消状态
    case cancel
}

public class WYSoundAnimationView: WYAirBubbleView {
    let state = WYSoundAnimationViewPrivateState()

    /// 当前实例配置
    public var recordAnimationConfig: WYRecordAnimationConfig = WYRecordAnimationConfig()

    
    /// 声波动画组件
    public lazy var soundWavesView: WYSoundWavesView = {
        let soundWavesView: WYSoundWavesView = WYSoundWavesView()
        addSubview(soundWavesView)
        return soundWavesView
    }()
    
    /// 文本TextView
    public lazy var textView: UITextView = {
        let textView: UITextView = UITextView()
        addSubview(textView)
        return textView
    }()
    
    /// 初始化方法
    public init(_ status: WYSoundAnimationStatus = .recording, configuration: WYRecordAnimationConfig = WYRecordAnimationConfig()) {
        self.recordAnimationConfig = configuration
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        refreshSoundWaves(status: status)
    }
    
    public func refreshSoundWaves(status: WYSoundAnimationStatus) { wy_refreshSoundWaves(status: status) }
    
    /// 根据录制状态获取对应声波配置
    public func soundWavesConfigUpdate(status: WYSoundAnimationStatus, config: inout WYSoundWaveConfig) { wy_soundWavesConfigUpdate(status: status, config: &config) }
    
    /// 获取录音、取消录音、转文字时声波动画的Size
    public func soundWavesSize(for status: WYSoundAnimationStatus) -> CGSize { wy_soundWavesSize(for: status) }
    
    public override func layoutSubviews() {
        wy_layoutSoundBubble()
        super.layoutSubviews()
        wy_layoutTranscriptText()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
