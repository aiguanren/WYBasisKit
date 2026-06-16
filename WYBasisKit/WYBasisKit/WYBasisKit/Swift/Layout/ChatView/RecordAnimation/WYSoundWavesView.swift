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
        static let minBarHeight: CGFloat = 3.0
        static let maxBarHeightRatio: CGFloat = 0.72
        static let cornerRadius: CGFloat = 1.0
        
        static let colorRecording: UIColor = .white
        static let colorCancel: UIColor = UIColor(red: 1.0, green: 0.23, blue: 0.21, alpha: 1.0)
        static let colorTransfer: UIColor = UIColor.white.withAlphaComponent(0.9)
        
        static let barWidth: CGFloat = 2.0
        static let barSpacing: CGFloat = 2.0
        static let barCount: Int = 30
    }
    
    private var targetRatios: [CGFloat] = []
    private var currentRatios: [CGFloat] = []
    private var currentStatus: WYSoundWavesStatus = .recording
    private var displayLink: CADisplayLink?
    
    private var lastPower: CGFloat = 0
    private var fakePeak: CGFloat = 0
    private var smoothedPower: CGFloat = 0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        currentRatios = Array(repeating: 0.12, count: Config.barCount)
        targetRatios = currentRatios
        
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
            let target = targetRatios[i]
            let diff = target - currentRatios[i]
            
            let speed: CGFloat = abs(diff) > 0.1 ? 0.25 : 0.12
            currentRatios[i] += diff * speed
            
            if abs(diff) > 0.002 {
                needsDraw = true
            }
        }
        
        if needsDraw {
            setNeedsDisplay()
        }
    }
    
    public func updateMeters(averagePowers: [Float], status: WYSoundWavesStatus) {
        
        currentStatus = status
        
        let barCount = Config.barCount
        
        // ===== 1️⃣ 输入 =====
        let avg = averagePowers.reduce(0, +) / Float(max(1, averagePowers.count))
        var power = CGFloat(avg)
        
        // ===== 2️⃣ 降噪（降低门槛！！）=====
        let noiseGate: CGFloat = 0.12   // ❗原来太高了
        power = max(0, power - noiseGate)
        
        // ===== 3️⃣ 放大（让说话明显）=====
        power = power * 4.0             // ❗关键：必须大
        power = min(1.0, power)
        
        // ===== 4️⃣ 平滑 =====
        smoothedPower = smoothedPower * 0.6 + power * 0.4
        
        let center = CGFloat(barCount - 1) / 2.0
        
        let time = CACurrentMediaTime()

        targetRatios = (0..<barCount).map { i in
            
            let dist = abs(CGFloat(i) - center) / center
            var value: CGFloat
            
            if smoothedPower < 0.02 {
                // ===== ✅ 静音：流动水波 =====
                let wave = sin(CGFloat(i) * 0.5 + time * 2.5)
                value = 0.11 + wave * 0.025
                
            } else {
                // ===== ✅ 有声：连续波形 =====
                
                let base = smoothedPower * 0.8
                
                let wave = sin(CGFloat(i) * 0.4 + time * 6.0)
                
                let centerBoost = 1.0 + (1 - dist) * 0.8
                
                value = base * centerBoost + wave * 0.12 * smoothedPower
            }
            
            return max(0.08, min(1.0, value))
        }
        
        if status == .cancel {
            targetRatios = targetRatios.map { $0 * 0.5 }
        }
    }
    
    public override func draw(_ rect: CGRect) {
        guard rect.height > 10 else { return }
        guard !currentRatios.isEmpty else { return }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let barColor: UIColor = {
            switch currentStatus {
            case .recording: return Config.colorRecording
            case .cancel: return Config.colorCancel
            case .transfer: return Config.colorTransfer
            }
        }()
        
        context.setFillColor(barColor.cgColor)
        
        let maxHeight = rect.height * Config.maxBarHeightRatio
        
        let totalWidth =
            CGFloat(Config.barCount) * Config.barWidth +
            CGFloat(Config.barCount - 1) * Config.barSpacing
        
        let startX = (rect.width - totalWidth) / 2.0
        
        for (i, ratio) in currentRatios.enumerated() {
            let height = Config.minBarHeight + ratio * (maxHeight - Config.minBarHeight)
            
            let x = startX + CGFloat(i) * (Config.barWidth + Config.barSpacing)
            let y = (rect.height - height) / 2.0
            
            let rect = CGRect(x: x, y: y, width: Config.barWidth, height: height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: Config.cornerRadius)
            
            context.addPath(path.cgPath)
        }
        
        context.fillPath()
    }
}
