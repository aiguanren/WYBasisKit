//
//  WYSoundWavesView+Animation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import UIKit

/// 声波视图的刷新与动画实现
extension WYSoundWavesView {

    /// 重新加载声波柱子（当列数、宽度、间距变化时调用）
    func reloadBars() {
        bars.removeAll()
        let count = max(1, config.numberOfColumns)
        for i in 0..<count {
            bars.append(WYAudioBarUnit(index: i, config: config))
        }
        setNeedsDisplay()
    }
    
    // 初始化视图
    func setup() {
        backgroundColor = .clear
        
        reloadBars()
        
        displayLink = CADisplayLink(target: WYSoundWavesDisplayLinkTarget(view: self), selector: #selector(WYSoundWavesDisplayLinkTarget.tick(_:)))
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
    @objc func appWillResignActive() {
        displayLink?.isPaused = true
    }
    
    /// App 回到前台 → 恢复动画
    @objc func appDidBecomeActive() {
        displayLink?.isPaused = false
    }

    /// 动画驱动（每帧执行）
    @objc func tick() {
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

}

final class WYAudioBarUnit {
    
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
     
       @param index 柱子的索引位置（从左到右从 0 开始计数），用于计算波形相位和空间分布
       @param config 声波动画配置，控制柱子的高度、动画参数等
     
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
        state: WYSoundWavesState,       // 当前状态（静音 / 有声 / 停止）
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

/// 声波刷新回调的弱引用转发
final class WYSoundWavesDisplayLinkTarget: NSObject {

    private weak var view: WYSoundWavesView?

    init(view: WYSoundWavesView) {
        self.view = view
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let view = view else {
            link.invalidate()
            return
        }
        view.tick()
    }
}
