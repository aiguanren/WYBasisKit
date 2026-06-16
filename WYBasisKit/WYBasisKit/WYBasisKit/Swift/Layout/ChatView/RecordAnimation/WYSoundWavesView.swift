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
    
    // MARK: - 配置
    private let barCount = 37
    private let idleCount = 16
    
    private let minHeight: CGFloat = 6
    private let maxHeight: CGFloat = 40
    
    private let barWidth: CGFloat = 2.0
    private let barSpacing: CGFloat = 2.0
    
    private let danceDuration: CFTimeInterval = 0.25
    
    // MARK: - 状态
    public enum State {
        case idle
        case dance
        case stop
    }
    
    public var state: State = .idle
    private var currentStatus: WYSoundWavesStatus = .recording
    
    // MARK: - 数据
    private var bars: [Bar] = []
    private var currentPower: CGFloat = 0
    
    private var displayLink: CADisplayLink!
    
    // MARK: - 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        displayLink.invalidate()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        for i in 0..<barCount {
            bars.append(Bar(index: i))
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.add(to: .main, forMode: .common)
    }
    
    // MARK: - 对外接口（兼容你原来的调用）
    public func updateMeters(averagePowers: [Float], status: WYSoundWavesStatus) {
        
        currentStatus = status
        
        // ===== ① 取平均 =====
        let avg = averagePowers.reduce(0, +) / Float(max(1, averagePowers.count))
        
        // ===== ② dB→线性（你外面已经处理，这里直接用）=====
        var power = CGFloat(avg)
        
        // ===== ③ 降噪（关键！）=====
        power = max(0, power - 0.1)
        
        // ===== ④ 放大（关键！）=====
        power = min(1.0, power * 4.0)
        
        // ===== ⑤ 平滑 =====
        currentPower = currentPower * 0.6 + power * 0.4
        
        // ===== ⑥ 状态切换 =====
        if currentPower < 0.03 {
            state = .idle
        } else {
            state = .dance
        }
    }
    
    // MARK: - 动画驱动
    @objc private func tick() {
        
        let now = CACurrentMediaTime()
        
        for bar in bars {
            bar.update(
                time: now,
                state: state,
                power: currentPower
            )
        }
        
        setNeedsDisplay()
    }
    
    // MARK: - 绘制
    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let color: UIColor = {
            switch currentStatus {
            case .recording: return .white
            case .cancel: return UIColor.red
            case .transfer: return UIColor.white.withAlphaComponent(0.8)
            }
        }()
        
        ctx.setFillColor(color.cgColor)
        
        let centerX = rect.midX
        let centerY = rect.midY
        
        let totalWidth =
        CGFloat(barCount) * barWidth +
        CGFloat(barCount - 1) * barSpacing
        
        let startX = centerX - totalWidth / 2
        
        for (i, bar) in bars.enumerated() {
            
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let height = bar.currentHeight
            
            let y = centerY - height / 2
            
            let rect = CGRect(x: x, y: y, width: barWidth, height: height)
            
            let path = UIBezierPath(roundedRect: rect, cornerRadius: barWidth / 2)
            ctx.addPath(path.cgPath)
        }
        
        ctx.fillPath()
    }
}

private class Bar {
    
    let index: Int
    
    private var targetHeight: CGFloat = 6
    private var startTime: CFTimeInterval = 0
    
    var currentHeight: CGFloat = 6
    
    init(index: Int) {
        self.index = index
    }
    
    func update(time: CFTimeInterval, state: WYSoundAnimationView.State, power: CGFloat) {
        
        switch state {
            
        case .idle:
            updateIdle(time: time)
            
        case .dance:
            updateDance(time: time, power: power)
            
        case .stop:
            currentHeight = 6
        }
    }
    
    // MARK: - 静音（水波流动）
    private func updateIdle(time: CFTimeInterval) {
        
        let speed: CGFloat = 2.2          // ⭐️ 速度
        let frequency: CGFloat = 0.5      // ⭐️ 波密度
        let amplitude: CGFloat = 5.0      // ⭐️ 振幅
        let baseHeight: CGFloat = 7.5     // ⭐️ 基础高度
        
        let x = CGFloat(index)
        let center = CGFloat(36) / 2.0    // barCount = 37
        
        let phase = CGFloat(time) * speed
        
        let distance = x - center
        
        let wave: CGFloat
        
        if distance < 0 {
            // ✅ 左边：向左流（相位 +）
            wave = sin(x * frequency + phase)
        } else {
            // ✅ 右边：向右流（相位 -）
            wave = sin(x * frequency - phase)
        }
        
        // ⭐️ 半波整流（变成“团块”）
        let positive = max(0, wave)
        
        // ⭐️ 收紧成水滴感
        let shaped = pow(positive, 2.2)
        
        currentHeight = baseHeight + shaped * amplitude
    }
    
    // MARK: - 有声（微信核心）
    private func updateDance(time: CFTimeInterval, power: CGFloat) {
        
        // 每根柱子独立触发（关键！！！）
        if time > startTime + 0.25 {
            
            startTime = time + Double.random(in: 0...0.08)
            
            let base = power * 30
            
            let center = 18
            let dist = abs(index - center)
            let factor = 1.0 + (1.0 - CGFloat(dist) / 18.0)
            
            targetHeight = max(6, base * factor)
        }
        
        let t = CGFloat((time - startTime) / 0.25)
        
        if t >= 0 && t <= 1 {
            
            // 插值器
            let value = (-2.8 * t * t + 3.8 * t)
            
            currentHeight = max(6, value * targetHeight)
            
        } else {
            currentHeight = 6
        }
    }
}
