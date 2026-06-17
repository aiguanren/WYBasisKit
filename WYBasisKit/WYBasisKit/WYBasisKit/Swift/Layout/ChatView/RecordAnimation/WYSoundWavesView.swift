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

/// 声波动画参数配置
public struct WYSoundWaveConfig {
    
    /// dB 下限（默认 -60），越小 → 越“灵敏”（能感知更小声音），建议：-80 ~ -40
    public var minDb: Float = -60
    
    /// 降噪阈值（默认 0.18）,越大越不灵敏（小声音不动），越小越灵敏（环境声也会触发），建议：0.12 ~ 0.30
    public var noiseGate: CGFloat = 0.18
    
    /// 放大倍数（默认 1.6）,越大动画越“炸”，越小越克制，建议：1.2 ~ 2.2
    public var gain: CGFloat = 1.6
    
    /// 非线性指数（曲线变换），>1：压制小声音，保留大声音（更稳），<1：放大小声音（更灵敏），建议：1.05 ~ 1.3
    public var powerExponent: CGFloat = 1.1
    
    /// 最大振幅限制（默认 0.75），防止高度过高导致“炸裂”，建议：0.55 ~ 0.85
    public var limit: CGFloat = 0.75
    
    /// 柱子数量（默认 15），越多越细腻，越少越粗犷，建议：11 ~ 31
    public var numberOfColumns: Int = 15
    
    /// 空间分布形状（默认 1.8），越大越尖（中间高），越小越平（整体更均匀），建议：1.4 ~ 2.4
    public var shapePower: CGFloat = 1.8
    
    /// 静音判定阈值（默认 0.015），当整体能量低于该值时，认为进入“静音状态”，开始触发微动逻辑，值越大越容易进入静音（更频繁触发微动，越小越接近完全静止（只有极小声音才会触发），建议：0.01 ~ 0.03
    public var idleThreshold: CGFloat = 0.015
    
    /// 静音微动幅度（默认 0.01），控制静音状态下随机波动的最大值（“呼吸感”的强弱），值越大静音时波动越明显（更“活跃”，但可能显得假），越小越接近静止（更克制，轻微流动），建议：0.002 ~ 0.015
    public var idleAmplitude: CGFloat = 0.01
    
    /// 唯一初始化方法
    public init(minDb: Float = -60,
                noiseGate: CGFloat = 0.18,
                gain: CGFloat = 1.6,
                powerExponent: CGFloat = 1.1,
                limit: CGFloat = 0.75,
                numberOfColumns: Int = 15,
                shapePower: CGFloat = 1.8,
                idleThreshold: CGFloat = 0.015,
                idleAmplitude: CGFloat = 0.01) {
        
        self.minDb = minDb
        self.noiseGate = noiseGate
        self.gain = gain
        self.powerExponent = powerExponent
        self.limit = limit
        self.numberOfColumns = numberOfColumns
        self.shapePower = shapePower
        self.idleThreshold = idleThreshold
        self.idleAmplitude = idleAmplitude
    }
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
    
    /// 柱子数量（越多越细腻，但性能略降），建议：25 ~ 45
    private let barCount = 37
    
    /// 每根柱子的宽度，建议范围：1.5 ~ 3
    private let barWidth: CGFloat = 2.0
    
    /// 柱子之间间距，建议范围：1 ~ 3
    private let barSpacing: CGFloat = 2.0
    
    /// 动画状态
    public enum State {
        /// 静音（水波流动）
        case idle
        /// 有声（跳动）
        case dance
        /// 停止
        case stop
    }
    
    /// 当前状态（外部不直接控制，由音量驱动）
    public var state: State = .idle
    
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
    
    /**
     
     生成声波柱强度数组（0~1）
     
     - Description：将音频 dB（peak / average）转换为 UI 可用数据（含降噪 / 放大 / 限幅 / 分布）
     
     整体处理流程： 1. dB → 线性归一化（0~1）
                 2. 降噪（过滤环境小声音）
                 3. 放大（增强视觉效果）
                 4. 非线性调整（优化手感）
                 5. 限幅（防止爆炸）
                 6. 静音微动（避免完全静止）
                 7. 构造“中间强，两边弱”的空间分布
     
     - Parameters:
       - peakPower: 峰值 dB（-160~0），响应快但抖动大（一般不直接用）
       - averagePower: 平均 dB（-160~0），更稳定（推荐）
       - config: 声波配置（控制灵敏度 / 强度 / 形状等）
     
     - Returns: 每个柱子的强度（0~1）
     */
    public static func makeWaveformLevels(peakPower: Float,
                                          averagePower: Float,
                                          config: WYSoundWaveConfig = WYSoundWaveConfig()) -> [Float] {
        
        // 将 dB（-60 ~ 0）映射到 0 ~ 1，越接近 1 表示声音越大(将音频分贝值（负数）转换成 UI 可用的线性强度（0~1）)
        func normalize(_ power: Float) -> CGFloat {
            
            // 如果低于最小阈值，直接认为是“静音”
            if power < config.minDb { return 0 }
            
            // 将 [minDb ~ 0] 线性映射到 [0 ~ 1]（低于 minDb 直接视为 0，且越接近 0（声音越大））
            return CGFloat((power - config.minDb) / -config.minDb)
        }
        
        // 使用 average（更稳定），peak 虽然灵敏，但会抖；average 更适合做 UI 动画
        let avg = normalize(averagePower)
        
        // 当前能量值(原始能量)
        var p = avg
        
        // 降噪（Noise Gate），过滤掉小声音（环境噪音），config.noiseGate 越大越不敏感（小声音不动），越小越灵敏（环境声音也会动）
        p = max(0, p - config.noiseGate)
        
        // 线性放大（Gain），config.gain越大整体波动越明显（更“炸”），越小整体越克制
        p = p * config.gain
        
        /**
         * 非线性增强（曲线变换），调整“小声音 vs 大声音”的比例关系
         * >1：压制小声音，保留大声音，让动画更稳
         * <1：放大小声音（更灵敏），让动画更灵敏
         */
        p = pow(p, config.powerExponent)
        
        // 最大值限制（防止炸），config.limit越大峰值越高（容易炸），越小越平稳（更克制）
        p = min(config.limit, p)
                
        // 静音微动，静音时给一点随机值，使其有“微弱呼吸感”，越大：静音也会明显动（不推荐），越小：更接近完全静止
        if p < config.idleThreshold {
            let idle = CGFloat.random(in: 0.0...config.idleAmplitude)
            p = max(p, idle)
        }
        
        // 柱子最小保护数量
        let count = max(1, config.numberOfColumns)
        
        // 构造“中间强，两边弱”的分布(将一个“整体能量 p”分配到多个柱子上)
        var powers: [Float] = []
        powers.reserveCapacity(count)
        
        for i in 0..<count {
            
            // 当前柱子到“中心点”的距离，中心柱 distance = 0，两边逐渐变大
            let distance = abs(CGFloat(i) - CGFloat(count - 1) / 2.0)

            // 最大距离（用于归一化）
            let maxDistance = CGFloat(count) / 2.0
            
            // 中心权重，中间为1，两边逐渐衰减到0
            let weight = 1.0 - (distance / maxDistance)
            
            // 形状函数(控制“中间聚集程度”)，config.shapePower越大：越“尖”（更集中在中间），越小：越“平”（更像一整条线）
            let shaped = pow(weight, config.shapePower)
            
            // 最终每一条 bar 的强度(每个柱子的高度来源) = 总能量 * 空间权重
            powers.append(Float(p * shaped))
        }
        
        // 返回所有柱子的强度数组（用于 UI 渲染）
        return powers
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
        state: WYSoundAnimationView.State,        // 当前状态（静音 / 有声）
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
