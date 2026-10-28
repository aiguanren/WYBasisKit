//
//  WYSoundWavesView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/10.
//

import UIKit

/// 声波动画参数配置
public struct WYSoundWaveConfig {
    
    /**************** 音频处理参数（影响 dB → 能量转换）****************/
    
    /// dB 下限（默认 -60），越小 → 越“灵敏”（能感知更小声音），建议：-80 ~ -40
    public var minDb: Float = -60
    
    /// 降噪阈值（默认 0.35），越大越不灵敏（小声音不动），越小越灵敏（环境声也会触发），建议：0.15 ~ 0.60
    public var noiseGate: CGFloat = 0.45
    
    /// 放大倍数（默认 2.0），越大动画越“炸”，越小越克制，建议：1.8 ~ 3.5
    public var gain: CGFloat = 2.0
    
    /// 非线性指数（曲线变换），>1：压制小声音，保留大声音（更稳），<1：放大小声音（更灵敏），建议：1.05 ~ 1.3
    public var powerExponent: CGFloat = 1.1
    
    /// 最大振幅限制（默认 0.80），防止高度过高导致“炸裂”，建议：0.65 ~ 0.90
    public var limit: CGFloat = 0.80
    
    /**************** 状态切换参数（带滞回）****************/
    
    /// 进入 dance 状态的高阈值（默认 0.05），当能量高于此值时切换到 dance 状态，建议范围：0.015 ~ 0.08
    public var highThreshold: CGFloat = 0.05
    
    /// 回到 idle 状态的低阈值（默认 0.012），当能量低于此值时切换到 idle 状态，建议范围：0.008 ~ 0.02
    public var lowThreshold: CGFloat = 0.012
    
    /// 低通滤波平滑系数（默认 0.5），值越小越平滑（延迟稍高），值越大越灵敏（更跟手），建议范围：0.3 ~ 0.7
    public var smoothingFactor: CGFloat = 0.5
    
    /// 屏幕刷新帧率（默认 36），人眼几乎无感知，省电约 40%，建议范围：24 ~ 60
    public var preferredFramesPerSecond: Int = 36
    
    /**************** Idle 状态参数（静音时的水波纹流动）****************/
    
    /// Idle 波动速度（默认 6.0），越大波动越快，建议范围：2.0 ~ 15.0
    public var idleSpeed: CGFloat = 6.0
    
    /// Idle 波密度（默认 0.3），越大波越密（脉冲越窄），建议范围：0.2 ~ 1.5
    public var idleFrequency: CGFloat = 0.3
    
    /// Idle 状态下声波柱子波动的基线高度（默认 6.0），与 idleAmplitude 配合使用，实际高度 = idleBaseHeight + 波形值(0~1) * idleAmplitude，例如 idleBaseHeight=6、idleAmplitude=10 时，柱子高度在 6~16 之间波动
    public var idleBaseHeight: CGFloat = 6.0
    
    /// Idle 状态下声波柱子波动的幅度（默认 10.0），与 idleBaseHeight 配合使用，实际高度 = idleBaseHeight + 波形值(0~1) * idleAmplitude，例如 idleBaseHeight=6、idleAmplitude=10 时，柱子高度在 6~16 之间波动，值越大波动越明显，控制静音时的“呼吸感”强度
    public var idleAmplitude: CGFloat = 10.0
    
    /// Idle 非线性压缩指数（默认 2.2），值越大波形越尖锐，建议范围：1.5 ~ 3.0
    public var idleShapingExponent: CGFloat = 2.2
    
    /// Idle 随机扰动幅度（默认 0.08），在正弦波上叠加平滑扰动，让水波更自然，去机械感，建议范围：0.0 ~ 0.15
    public var idleNoiseMagnitude: CGFloat = 0.08
    
    /// Idle 扰动频率（默认 0.5），独立于主波形频率，控制扰动变化的快慢，建议范围：0.2 ~ 1.0
    public var idleNoiseFrequency: CGFloat = 0.5
    
    /// Idle 扰动相位间距（默认 0.618），控制相邻声波柱子扰动相位的间隔（黄金分割比例使分布最均匀），建议范围：0.3 ~ 0.8
    public var idleNoisePhaseSpacing: CGFloat = 0.618
    
    /**************** Dance 状态参数（有声时的跳动）****************/
    
    /// Dance 动画周期（默认 0.25），每次跳动时长（秒），建议范围：0.18 ~ 0.35
    public var danceDuration: TimeInterval = 0.25
    
    /// Dance 随机延迟范围（默认 0.08），每根声波柱子错峰触发的最大随机延迟（秒），实际最大延迟会被限制为 danceDuration * 0.5，建议范围：0.0 ~ 0.1
    public var danceRandomDelay: TimeInterval = 0.08
    
    /// Dance 基础高度倍数（默认 50.0），由音量乘以该值得到基础高度，建议范围：30 ~ 60（值越大声波柱子越高，越小声波柱子越低，控制整体跳动幅度）
    public var danceBaseMultiplier: CGFloat = 50.0
    
    /// Dance 插值曲线系数 a（默认 -2.8），控制弹起曲线的陡峭程度，建议范围：-3.5 ~ -2.0
    public var danceCurveA: CGFloat = -2.8
    
    /// Dance 插值曲线系数 b（默认 3.8），控制弹起曲线的缓落程度，建议范围：3.0 ~ 4.5
    public var danceCurveB: CGFloat = 3.8
    
    /**************** 柱子布局参数 ****************/
    
    /// 声波柱子数量（默认 25），越多越细腻，越少越粗犷，建议：10 ~ 40
    public var numberOfColumns: Int = 25
    
    /// 每根声波柱子的宽度（默认 2.0），建议范围：1.5 ~ 3.0
    public var barWidth: CGFloat = 2.0
    
    /// 声波柱子之间间距（默认 1.0），建议范围：1.0 ~ 3.0
    public var barSpacing: CGFloat = 1.0
    
    /// 声波柱子全局最低高度（默认 6.0），所有状态下声波柱子均不得低于此值，包括 stop/idle/dance 状态
    public var minBarHeight: CGFloat = 6.0
    
    /// 声波柱子全局最高高度（默认 20.0），所有状态下声波柱子均不得高于此值，用于防止动画过度炸裂（建议根据视图实际高度调整，一般不超过视图高度的 1/2）
    public var maxBarHeight: CGFloat = 20.0
    
    /// 声波柱子颜色
    public var wavesColor: UIColor = .white
    
    /// 唯一初始化方法
    public init() {}
}

/// 声波动画状态
@frozen public enum WYSoundWavesState: Int {
    /// 静音（水波流动）
    case idle = 0
    /// 有声（跳动）
    case dance
    /// 停止
    case stop
}

public class WYSoundWavesView: UIView {
    
    /// 声波动画配置
    public var config: WYSoundWaveConfig = WYSoundWaveConfig() {
        didSet {
            // 只有影响声波柱子布局的属性变化时才重建（列数、宽度、间距）
            if oldValue.numberOfColumns != config.numberOfColumns ||
               oldValue.barWidth != config.barWidth ||
               oldValue.barSpacing != config.barSpacing {
                reloadBars()
            } else {
                // 其他属性变化（颜色、振幅、阈值等）只需重绘
                setNeedsDisplay()
            }
            
            // 帧率动态更新
            displayLink?.preferredFramesPerSecond = config.preferredFramesPerSecond
        }
    }
    
    /// 当前状态（外部不直接控制，由音量驱动）
    public var state: WYSoundWavesState = .idle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    /**
     生成声波柱能量值（0~1）
     
     - Description：将音频 dB（peak / average）转换为 UI 可用的整体能量值（含降噪 / 放大 / 限幅）
     
     整体处理流程：
        1. dB → 线性归一化（0~1）
        2. 降噪（过滤环境小声音）
        3. 放大（增强视觉效果）
        4. 非线性调整（优化手感）
        5. 限幅（防止爆炸）
     
       @param peakPower 峰值 dB（-160~0），响应快但抖动大（一般不直接用）
       @param averagePower 平均 dB（-160~0），更稳定（推荐）
       @param config 声波配置（控制灵敏度 / 强度 等）
     
     @return 整体能量值（0~1），所有声波柱子共用此值
     */
    public func makeWaveformLevels(peakPower: Float,
                                   averagePower: Float) -> Float {
        
        // 将 dB（minDb ~ 0）映射到 0 ~ 1，越接近 1 表示声音越大（将音频分贝值（负数）转换成 UI 可用的线性强度（0~1））
        func normalize(_ power: Float) -> CGFloat {
            // 如果低于最小阈值，直接认为是"静音"
            if power < config.minDb { return 0 }
            // 将 [minDb ~ 0] 线性映射到 [0 ~ 1]（低于 minDb 直接视为 0，且越接近 0（声音越大））
            return CGFloat((power - config.minDb) / -config.minDb)
        }
        
        // 取average不取peak(average更稳定，peak灵敏但抖动大，average更适合驱动UI动画)
        let avg = normalize(averagePower)
        
        // 当前能量值（原始能量）
        var p = avg
        
        // 降噪（Noise Gate），过滤掉小声音（环境噪音），config.noiseGate 越大越不敏感（小声音不动），越小越灵敏（环境声音也会动）
        p = max(0, p - config.noiseGate)
        
        // 线性放大（Gain），config.gain越大整体波动越明显（更"炸"），越小整体越克制
        p = p * config.gain
        
        /**
         * 非线性增强（曲线变换），调整"小声音 vs 大声音"的比例关系
         * >1：压制小声音，保留大声音，让动画更稳
         * <1：放大小声音（更灵敏），让动画更灵敏
         */
        p = pow(p, config.powerExponent)
        
        // 最大值限制（防止炸），config.limit越大峰值越高（容易炸），越小越平稳（更克制）
        p = min(config.limit, p)
        
        // 返回整体能量值（所有声波柱子共用）
        return Float(p)
    }
    
    /// 声波数据更新（由外部每帧调用，power传0~1能量或录音器原始分贝负值均可，负值先走能量管线归一成0~1再进平滑与阈值，否则永远过不了起跳阈值只走待机水波纹）
    public func updateMeters(power: Float) {

        var newPower = CGFloat(power)
        if newPower < 0 {
            newPower = CGFloat(makeWaveformLevels(peakPower: power, averagePower: power))
        }
        
        // 低通滤波（核心优化）：消除音频抖动，让动画更顺滑(current = current + (新值 - 旧值) * 平滑系数)
        currentPower = currentPower + (newPower - currentPower) * config.smoothingFactor
        
        // 状态切换（带滞回，消除临界抖动）
        switch state {
        case .idle:
            // 从 idle 切换到 dance 需要高于高阈值（进入门槛更高，不易误触）
            if currentPower > config.highThreshold {
                state = .dance
            }
        case .dance:
            // 从 dance 切换到 idle 需要低于低阈值（离开门槛更低，不易卡在边缘）
            if currentPower < config.lowThreshold {
                state = .idle
                // 进入 idle 时，重置所有柱子的脉冲起始时间，使脉冲从中心重新开始扩散
                for bar in bars {
                    bar.resetIdleStartTime()
                }
            }
        case .stop:
            break
        }
    }
    
    /// 绘制（使用 CGPath 减少转换开销）
    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setFillColor(config.wavesColor.cgColor)

        let centerX = rect.midX
        let centerY = rect.midY

        let count = bars.count
        let totalWidth = CGFloat(count) * config.barWidth + CGFloat(max(0, count - 1)) * config.barSpacing
        let startX = centerX - totalWidth / 2

        for (i, bar) in bars.enumerated() {
            let x = startX + CGFloat(i) * (config.barWidth + config.barSpacing)
            let height = bar.currentHeight
            let y = centerY - height / 2

            let rect = CGRect(x: x, y: y, width: config.barWidth, height: height)
            // 使用 CGPath 直接创建圆角矩形，避免 UIBezierPath 的中间转换开销
            let path = CGPath(
                roundedRect: rect,
                cornerWidth: config.barWidth / 2,
                cornerHeight: config.barWidth / 2,
                transform: nil
            )
            ctx.addPath(path)
        }

        // 一次性填充所有柱子（批量绘制，性能更好）
        ctx.fillPath()
    }

    /// 控制 displayLink 生命周期（View 被移除时暂停，避免 CPU 空转）
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        displayLink.isPaused = (window == nil)
    }

    /// 所有声波柱子（动画最小单位）
    var bars: [WYAudioBarUnit] = []
    
    /// 当前音量（0~1），所有声波柱子共用此值（经过低通滤波平滑）
    var currentPower: CGFloat = 0
    
    /// 屏幕刷新驱动（60FPS）
    var displayLink: CADisplayLink!
    
    deinit {
        // 移除通知监听，避免野指针
        NotificationCenter.default.removeObserver(self)
        // 释放刷新器，防止内存泄漏
        displayLink.invalidate()
    }
}

