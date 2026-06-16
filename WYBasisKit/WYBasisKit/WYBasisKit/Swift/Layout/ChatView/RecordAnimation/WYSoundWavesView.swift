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
    
    /// 柱子数量（越多越细腻，但性能略降），建议范围：25 ~ 45（微信≈35+）
    private let barCount = 37
    
    /// 最小高度（所有柱子的“地板高度”），建议范围：4 ~ 8（越小越“贴地”）
    private let minHeight: CGFloat = 6
    
    /// 最大高度（限制爆炸高度），建议范围：30 ~ 60
    private let maxHeight: CGFloat = 40
    
    /// 每根柱子的宽度，建议范围：1.5 ~ 3
    private let barWidth: CGFloat = 2.0
    
    /// 柱子之间间距，建议范围：1 ~ 3
    private let barSpacing: CGFloat = 2.0
    
    /// 有声动画周期（影响“跳动节奏”），建议范围：0.2 ~ 0.35
    private let danceDuration: CFTimeInterval = 0.25
    
    /// 动画状态
    public enum WYSoundAnimationState {
        /// 静音（水波流动）
        case idle
        /// 有声（跳动）
        case dance
        /// 停止
        case stop
    }
    
    /// 当前状态（外部不直接控制，由音量驱动）
    public var state: WYSoundAnimationState = .idle
    
    /// 当前业务状态（录音 / 取消 / 转换）
    private var currentStatus: WYSoundWavesStatus = .recording
    
    /// 所有柱子（动画最小单位）
    private var bars: [WYAudioBarUnit] = []
    
    /// 当前音量（0~1，经过平滑处理）
    private var currentPower: CGFloat = 0
    
    /// 屏幕刷新驱动（60FPS）
    private var displayLink: CADisplayLink!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        /// 释放刷新器（防止内存泄漏）
        displayLink.invalidate()
    }
    
    private func setup() {
        
        /// 透明背景（避免遮挡）
        backgroundColor = .clear
        
        /// 创建所有柱子
        for i in 0..<barCount {
            bars.append(WYAudioBarUnit(index: i))
        }
        
        /// 创建屏幕刷新驱动（类似游戏循环）
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        
        /// 加入主线程（UI必须在主线程）
        displayLink.add(to: .main, forMode: .common)
    }
    
    /// 声波数据更新
    public func updateMeters(averagePowers: [Float], status: WYSoundWavesStatus) {
        
        /// 更新业务状态（影响颜色）
        currentStatus = status
        
        /// 求平均音量,避免空数组崩溃
        let avg = averagePowers.reduce(0, +) / Float(max(1, averagePowers.count))
        
        /// 转 CGFloat（外部已归一化）
        var power = CGFloat(avg)
        
        /// 降噪(去掉底噪),建议范围：0.05 ~ 0.15
        power = max(0, power - 0.1)
        
        /// 放大（灵敏度核心）,控制整体“跳动幅度”,建议范围：2.5 ~ 5
        power = min(1.0, power * 4.0)

        /// 平滑（防抖动）,当前值占60%，新值占40%,越大 → 越稳定但延迟高,建议：0.5 ~ 0.8
        currentPower = currentPower * 0.6 + power * 0.4

        /// 状态切换（核心）,小于阈值 → 静音,建议范围：0.02 ~ 0.05
        if currentPower < 0.03 {
            state = .idle
        } else {
            state = .dance
        }
    }
    
    /// 动画驱动（每帧执行）
    @objc private func tick() {
        
        /// 当前时间（用于动画计算）
        let now = CACurrentMediaTime()
        
        /// 更新每一根柱子
        for bar in bars {
            bar.update(
                time: now,
                state: state,
                power: currentPower
            )
        }
        
        /// 标记重绘（触发 draw）
        setNeedsDisplay()
    }
    
    /// 绘制
    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        /// 设置颜色（根据状态）
        let color: UIColor = {
            switch currentStatus {
            case .recording:
                return .white
            case .cancel:
                return UIColor.red
            case .transfer:
                return UIColor.white.withAlphaComponent(0.8)
            }
        }()
        
        ctx.setFillColor(color.cgColor)
        
        // 计算布局,水平中心
        let centerX = rect.midX
        // 计算布局,垂直中心
        let centerY = rect.midY
        
        // 总宽度 = 所有柱子 + 间距
        let totalWidth =
        CGFloat(barCount) * barWidth +
        CGFloat(barCount - 1) * barSpacing
        
        // 起点X（保证居中）
        let startX = centerX - totalWidth / 2
        
        // 绘制每一根柱子
        for (i, bar) in bars.enumerated() {
            
            // 当前柱子X位置
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            
            // 当前高度（来自动画计算）
            let height = bar.currentHeight
            
            // Y居中（上下对称）
            let y = centerY - height / 2
            
            // 柱子矩形
            let rect = CGRect(
                x: x,
                y: y,
                width: barWidth,
                height: height
            )
            
            // 圆角（做成“胶囊形”）
            let path = UIBezierPath(
                roundedRect: rect,
                cornerRadius: barWidth / 2
            )
            
            ctx.addPath(path.cgPath)
        }
        
        // 一次性填充（性能更好）
        ctx.fillPath()
    }
}

private class WYAudioBarUnit {
    
    /// 当前柱子的索引（用于计算位置 / 波形）
    let index: Int
    
    /// 当前动画的目标高度（用于插值动画）
    private var targetHeight: CGFloat = 6
    
    /// 当前动画开始时间（控制节奏 & 错峰）
    private var startTime: CFTimeInterval = 0
    
    /// 当前真实显示高度（最终绘制用）
    var currentHeight: CGFloat = 6
    
    init(index: Int) {
        self.index = index
    }
    
    /// 主更新入口（每一帧都会调用）
    func update(
        time: CFTimeInterval,                     // 当前时间（系统时间戳）
        state: WYSoundAnimationView.WYSoundAnimationState,        // 当前状态（静音 / 有声）
        power: CGFloat                            // 当前音量（0~1）
    ) {
        switch state {
            
        case .idle:
            // 静音：水波纹流动
            updateIdle(time: time)
            
        case .dance:
            // 有声：微信语音跳动
            updateDance(time: time, power: power)
            
        case .stop:
            // 停止：回到最小高度
            currentHeight = 6
        }
    }
    
    // 静音（水波：从中间向两边扩散）
    private func updateIdle(time: CFTimeInterval) {
        
        /// 波动速度（越大越快）,建议范围：1.5 ~ 3.0
        let speed: CGFloat = 2.2
        
        /// 波密度（越大越密）,建议范围：0.3 ~ 0.8
        let frequency: CGFloat = 0.5
        
        /// 振幅（波动高度）,建议范围：3 ~ 8
        let amplitude: CGFloat = 5.0
        
        /// 基础高度（最低高度）,建议范围：6 ~ 10
        let baseHeight: CGFloat = 7.5
        
        /// 当前柱子位置（转 CGFloat）
        let x = CGFloat(index)
        
        /// 中心点（决定波从哪里扩散）
        let center = CGFloat(36) / 2.0
        
        /// 时间相位（控制动画推进）
        let phase = CGFloat(time) * speed
        
        /// 距离中心的偏移（负：左边，正：右边）
        let distance = x - center
        
        /// 当前波形值
        let wave: CGFloat
        
        if distance < 0 {
            // 左边：向左流动（相位 +）
            wave = sin(x * frequency + phase)
        } else {
            // 右边：向右流动（相位 -）
            wave = sin(x * frequency - phase)
        }
        
        // 半波整流（只保留正值 → 形成“团块”）
        let positive = max(0, wave)
        
        // 非线性压缩（让波更“圆润”）,值越大 → 越尖锐,建议范围：1.5 ~ 3.0
        let shaped = pow(positive, 2.2)
        
        // 最终高度
        currentHeight = baseHeight + shaped * amplitude
    }
    
    // 有声（声波动画）
    private func updateDance(time: CFTimeInterval, power: CGFloat) {
        
        /// 动画周期（每次跳动时长），建议范围：0.18 ~ 0.35
        let duration: CFTimeInterval = 0.25
        
        // 每根柱子“错峰触发”
        if time > startTime + duration {
            
            /// 下一次触发时间（加入随机延迟 → 更自然）,建议范围：0 ~ 0.1
            startTime = time + Double.random(in: 0...0.08)
            
            /// 基础高度（由音量决定）,建议范围：20 ~ 40（乘 power）
            let base = power * 30
            
            /// 中心点
            let center = 18
            
            /// 距离中心距离
            let dist = abs(index - center)
            
            /// 中间更高，两边更低（形成山峰）,越接近中心 → 倍率越高
            let factor = 1.0 + (1.0 - CGFloat(dist) / 18.0)
            
            /// 最终目标高度
            targetHeight = max(6, base * factor)
        }
        
        /// 当前动画进度（0~1）
        let t = CGFloat((time - startTime) / duration)
        
        if t >= 0 && t <= 1 {
            
            /// 二次函数插值（模拟“弹起”）,特点：先快后慢，有“呼吸感”
            let value = (-2.8 * t * t + 3.8 * t)
            
            currentHeight = max(6, value * targetHeight)
            
        } else {
            // 动画结束 → 回到最低
            currentHeight = 6
        }
    }
}
