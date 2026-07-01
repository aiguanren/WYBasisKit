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
    
    /// 所有声波柱子（动画最小单位）
    private var bars: [WYAudioBarUnit] = []
    
    /// 当前音量（0~1），所有声波柱子共用此值（经过低通滤波平滑）
    private var currentPower: CGFloat = 0
    
    /// 屏幕刷新驱动（60FPS）
    private var displayLink: CADisplayLink!
    
    /**
     
     生成声波柱能量值（0~1）
     
     - Description：将音频 dB（peak / average）转换为 UI 可用的整体能量值（含降噪 / 放大 / 限幅）
     
     整体处理流程：
        1. dB → 线性归一化（0~1）
        2. 降噪（过滤环境小声音）
        3. 放大（增强视觉效果）
        4. 非线性调整（优化手感）
        5. 限幅（防止爆炸）
     
     - Parameters:
       - peakPower: 峰值 dB（-160~0），响应快但抖动大（一般不直接用）
       - averagePower: 平均 dB（-160~0），更稳定（推荐）
       - config: 声波配置（控制灵敏度 / 强度 等）
     
     - Returns: 整体能量值（0~1），所有声波柱子共用此值
     */
    public static func makeWaveformLevels(peakPower: Float,
                                          averagePower: Float,
                                          config: WYSoundWaveConfig = WYSoundWaveConfig()) -> Float {
        
        // 将 dB（minDb ~ 0）映射到 0 ~ 1，越接近 1 表示声音越大（将音频分贝值（负数）转换成 UI 可用的线性强度（0~1））
        func normalize(_ power: Float) -> CGFloat {
            // 如果低于最小阈值，直接认为是"静音"
            if power < config.minDb { return 0 }
            // 将 [minDb ~ 0] 线性映射到 [0 ~ 1]（低于 minDb 直接视为 0，且越接近 0（声音越大））
            return CGFloat((power - config.minDb) / -config.minDb)
        }
        
        // 使用 average（更稳定），peak 虽然灵敏，但会抖；average 更适合做 UI 动画
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
    
    /// 声波数据更新（由外部每帧调用）
    public func updateMeters(power: Float) {
        
        let newPower = CGFloat(power)
        
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
    
    /// 重新加载声波柱子（当列数、宽度、间距变化时调用）
    public func reloadBars() {
        bars.removeAll()
        let count = max(1, config.numberOfColumns)
        for i in 0..<count {
            bars.append(WYAudioBarUnit(index: i, config: config))
        }
        setNeedsDisplay()
    }
    
    // 初始化视图
    private func setup() {
        backgroundColor = .clear
        
        reloadBars()
        
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.preferredFramesPerSecond = config.preferredFramesPerSecond
        displayLink.add(to: .main, forMode: .common)
        
        // 注册前后台通知，避免 App 切后台时 displayLink 仍在运行（节省 CPU 资源）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /// App 切到后台 → 暂停动画（避免 CPU 空转）
    @objc private func appWillResignActive() {
        displayLink?.isPaused = true
    }
    
    /// App 回到前台 → 恢复动画
    @objc private func appDidBecomeActive() {
        displayLink?.isPaused = false
    }
    
    /// 控制 displayLink 生命周期（View 被移除时暂停，避免 CPU 空转）
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        displayLink.isPaused = (window == nil)
    }
    
    /// 动画驱动（每帧执行）
    @objc private func tick() {
        let now = CACurrentMediaTime()
        // 更新每一根声波柱子的高度
        for bar in bars {
            bar.update(
                time: now,
                state: state,
                power: currentPower
            )
        }
        // 标记重绘，触发 draw 方法
        setNeedsDisplay()
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        // 移除通知监听，避免野指针
        NotificationCenter.default.removeObserver(self)
        // 释放刷新器，防止内存泄漏
        displayLink.invalidate()
    }
}

private class WYAudioBarUnit {
    
    /// 当前声波柱子的索引（用于计算位置 / 波形）
    let index: Int
    
    /// 声波配置
    let config: WYSoundWaveConfig
    
    /// 当前动画的目标高度（用于插值动画）
    var targetHeight: CGFloat
    
    /// 当前动画开始时间（控制节奏 & 错峰）
    var startTime: CFTimeInterval = 0
    
    /// 当前真实显示高度（最终绘制用）
    var currentHeight: CGFloat
    
    /// Idle 状态下的中心点（初始化时缓存，避免重复计算）
    let cachedCenter: CGFloat
    
    /// 用于 idle 平滑扰动的固定相位（基于 index 生成，保证每根声波柱子扰动不同且随时间平滑变化）
    let noisePhase: CGFloat
    
    /// 进入 idle 状态时的时间戳（用于重置脉冲相位，使每次进入 idle 都从中心重新开始扩散）
    var idleStartTime: CFTimeInterval = 0
    
    /**
     初始化声波柱子单元
     
     - Parameters:
       - index: 柱子的索引位置（从左到右从 0 开始计数），用于计算波形相位和空间分布
       - config: 声波动画配置，控制柱子的高度、动画参数等
     
     初始化时会缓存以下内容：
       - 当前柱子的初始高度（使用 config.minBarHeight）
       - idle 状态下的中心点位置，用于水波扩散效果
       - 基于 index 生成的固定扰动相位，保证每根柱子的扰动不同且随时间平滑变化
     */
    init(index: Int, config: WYSoundWaveConfig) {
        self.index = index
        self.config = config
        self.currentHeight = config.minBarHeight
        self.targetHeight = config.minBarHeight
        
        let count = CGFloat(max(1, config.numberOfColumns))
        // 缓存中心点
        self.cachedCenter = (count - 1) / 2.0
        
        // 使用 index 生成 0~2π 之间的固定相位（黄金分割比例使分布最均匀）
        self.noisePhase = CGFloat(index) * config.idleNoisePhaseSpacing * 2.0 * .pi
        
        // 初始化 idle 起始时间
        self.idleStartTime = CACurrentMediaTime()
    }
    
    /// 将高度限制在 [minBarHeight, maxBarHeight] 范围内（防止柱子过高或过低）
    func clampHeight(_ height: CGFloat) -> CGFloat {
        return min(max(height, config.minBarHeight), config.maxBarHeight)
    }
    
    /// 重置 idle 脉冲起始时间（使脉冲从中心重新开始扩散）
    func resetIdleStartTime() {
        idleStartTime = CACurrentMediaTime()
    }
    
    /// 主更新入口（每一帧都会调用）
    func update(
        time: CFTimeInterval,           // 当前时间（系统时间戳）
        state: WYSoundWavesView.State,  // 当前状态（静音 / 有声 / 停止）
        power: CGFloat                  // 当前音量（0~1），所有声波柱子共用
    ) {
        switch state {
        case .idle:
            updateIdle(time: time)
        case .dance:
            updateDance(time: time, power: power)
        case .stop:
            currentHeight = config.minBarHeight
        }
    }
    
    /**
     静音状态：水波从中间向两边扩散流动（脉冲波）
     
     实现原理：
        1. 每个脉冲从中心（index = cachedCenter）开始，以 idleSpeed 速度向两侧移动
        2. 脉冲宽度由 idleFrequency 控制，值越大脉冲越窄，波出现频率越高
        3. 每根柱子的高度由当前波前位置和柱子距离决定，形成先升后降的单峰
        4. 扰动仅在脉冲活跃时叠加，且随脉冲幅度变化，避免静默时跳动
        5. 最终高度 = idleBaseHeight + 脉冲幅值 * idleAmplitude，并限制在 [minBarHeight, maxBarHeight]
     */
    func updateIdle(time: CFTimeInterval) {
        let maxDist = cachedCenter
        guard maxDist > 0 else {
            // 只有一根柱子时，固定为基准高度（可添加微小波动）
            let rawHeight = config.idleBaseHeight + config.idleAmplitude * 0.3
            currentHeight = clampHeight(rawHeight)
            return
        }
        
        // 使用相对时间，保证每次进入 idle 都从中心开始
        let relativeTime = time - idleStartTime
        let pulseWidth = maxDist / (1 + config.idleFrequency * 2)
        let totalPeriod = maxDist + pulseWidth   // 一个完整周期（波前从中心到完全消失）
        let front = fmod(relativeTime * config.idleSpeed, totalPeriod) // 当前波前位置
        
        let dist = abs(CGFloat(index) - cachedCenter)
        let x = front - dist   // 柱子相对于波前的位置（波前在中心时为0）
        
        var shaped: CGFloat = 0
        if x >= 0 && x <= pulseWidth {
            // 正弦半波作为脉冲形状，平滑升起再降下
            shaped = sin((x / pulseWidth) * .pi)
            // 只在脉冲活跃时叠加扰动，且扰动幅度随脉冲幅度变化，避免静默时跳动
            let noise = sin(relativeTime * config.idleNoiseFrequency + noisePhase) * config.idleNoiseMagnitude * shaped
            shaped += noise
            // 非线性压缩，调整脉冲形状（>1 使峰更尖锐，<1 更平缓）
            shaped = pow(shaped, config.idleShapingExponent)
            // 限幅，确保不超出 [0,1]
            shaped = max(0, min(1, shaped))
        }
        // 若 shaped 为 0，则柱子完全静止在 idleBaseHeight，无任何扰动
        
        let rawHeight = config.idleBaseHeight + shaped * config.idleAmplitude
        currentHeight = clampHeight(rawHeight)
    }
    
    /**
     有声状态：离散触发 + 二次曲线动画，保留错落感
     
     实现原理：
        1. 每根柱子独立触发（错峰触发），避免所有柱子同时跳动
        2. 目标高度由当前音量 × danceBaseMultiplier 决定
        3. 用二次曲线插值模拟"弹起"效果
        4. 动画结束后回到最低高度
     */
    func updateDance(time: CFTimeInterval, power: CGFloat) {
        // 每根声波柱子"错峰触发"
        if time > startTime + config.danceDuration {
            // 下一次触发时间（加入随机延迟 → 更自然），实际随机延迟上限限制为 danceDuration * 0.5，确保至少有一半周期用于动画
            let maxDelay = min(config.danceRandomDelay, config.danceDuration * 0.5)
            startTime = time + Double.random(in: 0...maxDelay)
            
            // 基础高度（由统一的功率决定）
            let base = power * config.danceBaseMultiplier
            
            // 最终目标高度 = 基础高度 × 空间倍率（固定为 1.0），然后限制在 [minBarHeight, maxBarHeight] 范围内
            targetHeight = clampHeight(base)
        }
        
        // 当前动画进度（0~1）
        let t = CGFloat((time - startTime) / config.danceDuration)
        
        if t >= 0 && t <= 1 {
            // 二次函数插值（模拟"弹起"）：用二次曲线让柱子先快后慢地弹起
            let value = config.danceCurveA * t * t + config.danceCurveB * t
            let rawHeight = value * targetHeight
            currentHeight = clampHeight(rawHeight)
        } else {
            // 动画结束 → 回到最低
            currentHeight = config.minBarHeight
        }
    }
}
