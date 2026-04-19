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
    
    public func refreshSoundWaves(averagePowers: [Float] = [], status: WYSoundWavesStatus) {
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
        animationView.updateMeters(averagePowers: averagePowers, status: status)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class WYSoundAnimationView: UIView {
    
    private struct Config {
        static let minBarHeight: CGFloat = 4.2
        static let maxBarHeightRatio: CGFloat = 0.93
        static let cornerRadius: CGFloat = 1.0
        
        static let colorRecording: UIColor = .white
        static let colorCancel: UIColor = UIColor(red: 1.0, green: 0.23, blue: 0.21, alpha: 1.0)
        static let colorTransfer: UIColor = .white.withAlphaComponent(0.9)
    }
    
    private var targetRatios: [CGFloat] = []
    private var currentRatios: [CGFloat] = []
    private var currentStatus: WYSoundWavesStatus = .recording
    private var displayLink: CADisplayLink?
    private var silenceDecay: CGFloat = 1.0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        currentRatios = Array(repeating: 0.12, count: 30)
        startDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func tick() {
        var needsDraw = false
        for i in 0..<currentRatios.count {
            let target = targetRatios.count > i ? targetRatios[i] : 0.12
            let diff = target - currentRatios[i]
            let speed = diff > 0 ? 0.60 : 0.17 * silenceDecay
            if abs(diff) > 0.004 {
                currentRatios[i] += diff * speed
                needsDraw = true
            }
        }
        if needsDraw { setNeedsDisplay() }
    }
    
    public func updateMeters(averagePowers: [Float], status: WYSoundWavesStatus) {
        currentStatus = status
        
        let barCount = max(27, recordAnimationConfig.severalSoundWaves.recording)
        var rawValues = averagePowers.prefix(barCount).map { CGFloat($0) }
        while rawValues.count < barCount {
            rawValues.append(rawValues.last ?? 0.06)
        }
        
        targetRatios = rawValues.enumerated().map { index, value in
            let center = CGFloat(barCount - 1) / 2.0
            let dist = abs(CGFloat(index) - center) / (center + 0.3)
            
            let amplified = pow(value, 0.46) * 2.75
            
            var ratio: CGFloat
            
            if value < 0.14 && status == .recording {
                // ==================== 静音模式：干净的中间扩散 ====================
                let breath = sin(CACurrentMediaTime() * 5.8 + CGFloat(index) * 0.7) * 0.065 + 0.14
                ratio = breath * (1.0 - dist * 0.85)   // 只在中间明显，向两边快速衰减
            } else {
                // ==================== 有声音模式：多段独立波峰 ====================
                let wave1 = sin(CGFloat(index) * 0.9) * 0.4 + 0.85      // 主波峰
                let wave2 = sin(CGFloat(index) * 1.65) * 0.25 + 0.65    // 次要叠加波
                ratio = amplified * (wave1 * 0.75 + wave2 * 0.25)
                
                // 中间增强
                let centerBoost = pow(max(0.0, 1.0 - dist * 0.55), 2.25)
                ratio *= centerBoost * 1.78
            }
            
            return max(0.10, min(1.0, ratio))
        }
        
        let avg = targetRatios.reduce(0, +) / CGFloat(targetRatios.count)
        silenceDecay = avg < 0.22 ? 0.58 : 1.0
        
        if status == .cancel {
            targetRatios = targetRatios.map { $0 * 0.55 }
        }
    }
    
    public override func draw(_ rect: CGRect) {
        guard rect.height > 20, !currentRatios.isEmpty else { return }
        
        let context = UIGraphicsGetCurrentContext()!
        let barColor: UIColor = {
            switch currentStatus {
            case .recording: return Config.colorRecording
            case .cancel:    return Config.colorCancel
            case .transfer:  return Config.colorTransfer
            }
        }()
        context.setFillColor(barColor.cgColor)
        
        let maxH = rect.height * Config.maxBarHeightRatio
        let w = recordAnimationConfig.soundWavesWidth
        let s = recordAnimationConfig.soundWavesSpace
        let totalW = CGFloat(currentRatios.count) * w + CGFloat(currentRatios.count - 1) * s
        let startX = (rect.width - totalW) / 2.0
        
        for (i, ratio) in currentRatios.enumerated() {
            let h = Config.minBarHeight + ratio * (maxH - Config.minBarHeight)
            let x = startX + CGFloat(i) * (w + s)
            let y = (rect.height - h) / 2.0
            
            let barRect = CGRect(x: x, y: y, width: w, height: h)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: Config.cornerRadius)
            context.addPath(path.cgPath)
        }
        context.fillPath()
    }
}
