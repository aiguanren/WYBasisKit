//
//  WYSoundWavesView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/8/10.
//

import UIKit

/// 声波动画参数配置
@objc(WYSoundWaveConfig)
@objcMembers public class WYSoundWaveConfigObjC: NSObject {
    
    /**************** 音频处理参数（影响 dB → 能量转换）****************/
    
    /// dB 下限（默认 -60），越小 → 越“灵敏”（能感知更小声音），建议：-80 ~ -40
    @objc public var minDb: Float = -60 {
        didSet { notifyChange() }
    }
    
    /// 降噪阈值（默认 0.35），越大越不灵敏（小声音不动），越小越灵敏（环境声也会触发），建议：0.15 ~ 0.60
    @objc public var noiseGate: CGFloat = 0.45 {
        didSet { notifyChange() }
    }
    
    /// 放大倍数（默认 2.0），越大动画越“炸”，越小越克制，建议：1.8 ~ 3.5
    @objc public var gain: CGFloat = 2.0 {
        didSet { notifyChange() }
    }
    
    /// 非线性指数（曲线变换），>1：压制小声音，保留大声音（更稳），<1：放大小声音（更灵敏），建议：1.05 ~ 1.3
    @objc public var powerExponent: CGFloat = 1.1 {
        didSet { notifyChange() }
    }
    
    /// 最大振幅限制（默认 0.80），防止高度过高导致“炸裂”，建议：0.65 ~ 0.90
    @objc public var limit: CGFloat = 0.80 {
        didSet { notifyChange() }
    }
    
    /**************** 状态切换参数（带滞回）****************/
    
    /// 进入 dance 状态的高阈值（默认 0.05），当能量高于此值时切换到 dance 状态，建议范围：0.015 ~ 0.08
    @objc public var highThreshold: CGFloat = 0.05 {
        didSet { notifyChange() }
    }
    
    /// 回到 idle 状态的低阈值（默认 0.012），当能量低于此值时切换到 idle 状态，建议范围：0.008 ~ 0.02
    @objc public var lowThreshold: CGFloat = 0.012 {
        didSet { notifyChange() }
    }
    
    /// 低通滤波平滑系数（默认 0.5），值越小越平滑（延迟稍高），值越大越灵敏（更跟手），建议范围：0.3 ~ 0.7
    @objc public var smoothingFactor: CGFloat = 0.5 {
        didSet { notifyChange() }
    }
    
    /// 屏幕刷新帧率（默认 36），人眼几乎无感知，省电约 40%，建议范围：24 ~ 60
    @objc public var preferredFramesPerSecond: Int = 36 {
        didSet { notifyChange() }
    }
    
    /**************** Idle 状态参数（静音时的水波纹流动）****************/
    
    /// Idle 波动速度（默认 6.0），越大波动越快，建议范围：2.0 ~ 15.0
    @objc public var idleSpeed: CGFloat = 6.0 {
        didSet { notifyChange() }
    }
    
    /// Idle 波密度（默认 0.3），越大波越密（脉冲越窄），建议范围：0.2 ~ 1.5
    @objc public var idleFrequency: CGFloat = 0.3 {
        didSet { notifyChange() }
    }
    
    /// Idle 状态下声波柱子波动的基线高度（默认 6.0），与 idleAmplitude 配合使用，实际高度 = idleBaseHeight + 波形值(0~1) * idleAmplitude，例如 idleBaseHeight=6、idleAmplitude=10 时，柱子高度在 6~16 之间波动
    @objc public var idleBaseHeight: CGFloat = 6.0 {
        didSet { notifyChange() }
    }
    
    /// Idle 状态下声波柱子波动的幅度（默认 10.0），与 idleBaseHeight 配合使用，实际高度 = idleBaseHeight + 波形值(0~1) * idleAmplitude，例如 idleBaseHeight=6、idleAmplitude=10 时，柱子高度在 6~16 之间波动，值越大波动越明显，控制静音时的“呼吸感”强度
    @objc public var idleAmplitude: CGFloat = 10.0 {
        didSet { notifyChange() }
    }
    
    /// Idle 非线性压缩指数（默认 2.2），值越大波形越尖锐，建议范围：1.5 ~ 3.0
    @objc public var idleShapingExponent: CGFloat = 2.2 {
        didSet { notifyChange() }
    }
    
    /// Idle 随机扰动幅度（默认 0.08），在正弦波上叠加平滑扰动，让水波更自然，去机械感，建议范围：0.0 ~ 0.15
    @objc public var idleNoiseMagnitude: CGFloat = 0.08 {
        didSet { notifyChange() }
    }
    
    /// Idle 扰动频率（默认 0.5），独立于主波形频率，控制扰动变化的快慢，建议范围：0.2 ~ 1.0
    @objc public var idleNoiseFrequency: CGFloat = 0.5 {
        didSet { notifyChange() }
    }
    
    /// Idle 扰动相位间距（默认 0.618），控制相邻声波柱子扰动相位的间隔（黄金分割比例使分布最均匀），建议范围：0.3 ~ 0.8
    @objc public var idleNoisePhaseSpacing: CGFloat = 0.618 {
        didSet { notifyChange() }
    }
    
    /**************** Dance 状态参数（有声时的跳动）****************/
    
    /// Dance 动画周期（默认 0.25），每次跳动时长（秒），建议范围：0.18 ~ 0.35
    @objc public var danceDuration: TimeInterval = 0.25 {
        didSet { notifyChange() }
    }
    
    /// Dance 随机延迟范围（默认 0.08），每根声波柱子错峰触发的最大随机延迟（秒），实际最大延迟会被限制为 danceDuration * 0.5，建议范围：0.0 ~ 0.1
    @objc public var danceRandomDelay: TimeInterval = 0.08 {
        didSet { notifyChange() }
    }
    
    /// Dance 基础高度倍数（默认 50.0），由音量乘以该值得到基础高度，建议范围：30 ~ 60（值越大声波柱子越高，越小声波柱子越低，控制整体跳动幅度）
    @objc public var danceBaseMultiplier: CGFloat = 50.0 {
        didSet { notifyChange() }
    }
    
    /// Dance 插值曲线系数 a（默认 -2.8），控制弹起曲线的陡峭程度，建议范围：-3.5 ~ -2.0
    @objc public var danceCurveA: CGFloat = -2.8 {
        didSet { notifyChange() }
    }
    
    /// Dance 插值曲线系数 b（默认 3.8），控制弹起曲线的缓落程度，建议范围：3.0 ~ 4.5
    @objc public var danceCurveB: CGFloat = 3.8 {
        didSet { notifyChange() }
    }
    
    /**************** 柱子布局参数 ****************/
    
    /// 声波柱子数量（默认 25），越多越细腻，越少越粗犷，建议：10 ~ 40
    @objc public var numberOfColumns: Int = 25 {
        didSet { notifyChange() }
    }
    
    /// 每根声波柱子的宽度（默认 2.0），建议范围：1.5 ~ 3.0
    @objc public var barWidth: CGFloat = 2.0 {
        didSet { notifyChange() }
    }
    
    /// 声波柱子之间间距（默认 1.0），建议范围：1.0 ~ 3.0
    @objc public var barSpacing: CGFloat = 1.0 {
        didSet { notifyChange() }
    }
    
    /// 声波柱子全局最低高度（默认 6.0），所有状态下声波柱子均不得低于此值，包括 stop/idle/dance 状态
    @objc public var minBarHeight: CGFloat = 6.0 {
        didSet { notifyChange() }
    }
    
    /// 声波柱子全局最高高度（默认 20.0），所有状态下声波柱子均不得高于此值，用于防止动画过度炸裂（建议根据视图实际高度调整，一般不超过视图高度的 1/2）
    @objc public var maxBarHeight: CGFloat = 20.0 {
        didSet { notifyChange() }
    }
    
    /// 声波柱子颜色
    @objc public var wavesColor: UIColor = .white {
        didSet { notifyChange() }
    }
    
    /// 唯一初始化方法
    @objc public override init() {}

    /// 转换为Swift类型
    internal func convertToSwift(_ swiftConfig: inout WYSoundWaveConfig) -> WYSoundWaveConfig {
        
        swiftConfig.minDb = minDb
        swiftConfig.noiseGate = noiseGate
        swiftConfig.gain = gain
        swiftConfig.powerExponent = powerExponent
        swiftConfig.limit = limit
        swiftConfig.highThreshold = highThreshold
        swiftConfig.lowThreshold = lowThreshold
        swiftConfig.smoothingFactor = smoothingFactor
        swiftConfig.preferredFramesPerSecond = preferredFramesPerSecond
        swiftConfig.idleSpeed = idleSpeed
        swiftConfig.idleFrequency = idleFrequency
        swiftConfig.idleBaseHeight = idleBaseHeight
        swiftConfig.idleAmplitude = idleAmplitude
        swiftConfig.idleShapingExponent = idleShapingExponent
        swiftConfig.idleNoiseMagnitude = idleNoiseMagnitude
        swiftConfig.idleNoiseFrequency = idleNoiseFrequency
        swiftConfig.idleNoisePhaseSpacing = idleNoisePhaseSpacing
        swiftConfig.danceDuration = danceDuration
        swiftConfig.danceRandomDelay = danceRandomDelay
        swiftConfig.danceBaseMultiplier = danceBaseMultiplier
        swiftConfig.danceCurveA = danceCurveA
        swiftConfig.danceCurveB = danceCurveB
        swiftConfig.numberOfColumns = numberOfColumns
        swiftConfig.barWidth = barWidth
        swiftConfig.barSpacing = barSpacing
        swiftConfig.minBarHeight = minBarHeight
        swiftConfig.maxBarHeight = maxBarHeight
        swiftConfig.wavesColor = wavesColor
        
        return swiftConfig
    }
    
    /// 转换为ObjC类型
    internal func convertToObjC(_ swiftConfig: WYSoundWaveConfig) -> WYSoundWaveConfigObjC {
        
        canSilentUpdating = true
        defer { canSilentUpdating = false }
        
        minDb = swiftConfig.minDb
        noiseGate = swiftConfig.noiseGate
        gain = swiftConfig.gain
        powerExponent = swiftConfig.powerExponent
        limit = swiftConfig.limit
        highThreshold = swiftConfig.highThreshold
        lowThreshold = swiftConfig.lowThreshold
        smoothingFactor = swiftConfig.smoothingFactor
        preferredFramesPerSecond = swiftConfig.preferredFramesPerSecond
        idleSpeed = swiftConfig.idleSpeed
        idleFrequency = swiftConfig.idleFrequency
        idleBaseHeight = swiftConfig.idleBaseHeight
        idleAmplitude = swiftConfig.idleAmplitude
        idleShapingExponent = swiftConfig.idleShapingExponent
        idleNoiseMagnitude = swiftConfig.idleNoiseMagnitude
        idleNoiseFrequency = swiftConfig.idleNoiseFrequency
        idleNoisePhaseSpacing = swiftConfig.idleNoisePhaseSpacing
        danceDuration = swiftConfig.danceDuration
        danceRandomDelay = swiftConfig.danceRandomDelay
        danceBaseMultiplier = swiftConfig.danceBaseMultiplier
        danceCurveA = swiftConfig.danceCurveA
        danceCurveB = swiftConfig.danceCurveB
        numberOfColumns = swiftConfig.numberOfColumns
        barWidth = swiftConfig.barWidth
        barSpacing = swiftConfig.barSpacing
        minBarHeight = swiftConfig.minBarHeight
        maxBarHeight = swiftConfig.maxBarHeight
        wavesColor = swiftConfig.wavesColor
        
        return self
    }
}

/// 声波动画状态
@objc(WYSoundWavesState)
@frozen public enum WYSoundWavesStateObjC: Int {
    /// 静音（水波流动）
    case idle = 0
    /// 有声（跳动）
    case dance
    /// 停止
    case stop
}

@objc public extension WYSoundWavesView {
    
    /// 声波动画配置
    @objc(config)
    var configObjC: WYSoundWaveConfigObjC {
        set {
            intervalObjCConfig = newValue
            config = newValue.convertToSwift(&config)
            bindObjCConfig(newValue)
        }
        get { return intervalObjCConfig }
    }
    
    /// 当前状态（外部不直接控制，由音量驱动）
    @objc(state)
    var stateObjC: WYSoundWavesStateObjC {
        set {
            state = WYSoundWavesState(rawValue: newValue.rawValue) ?? .idle
        }
        get {
            return WYSoundWavesStateObjC(rawValue: state.rawValue) ?? .idle
        }
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
     
     - Parameters:
       - peakPower: 峰值 dB（-160~0），响应快但抖动大（一般不直接用）
       - averagePower: 平均 dB（-160~0），更稳定（推荐）
       - config: 声波配置（控制灵敏度 / 强度 等）
     
     - Returns: 整体能量值（0~1），所有声波柱子共用此值
     */
    @objc(makeWaveformLevelsPeakPower:averagePower:)
    func makeWaveformLevelsObjC(peakPower: Float,
                                averagePower: Float) -> Float {
        
        return makeWaveformLevels(peakPower: peakPower, averagePower: averagePower)
    }
    
    /// 声波数据更新（由外部每帧调用）
    @objc(updateMetersWithPower:)
    func updateMetersObjC(power: Float) {
        updateMeters(power: power)
    }
}

private typealias OnChangeHandler = () -> Void
private extension WYSoundWaveConfigObjC {
    
    var onChangeHandler: OnChangeHandler? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.intervalOnChange, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.intervalOnChange) as? OnChangeHandler
        }
    }
    
    var canSilentUpdating: Bool {
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.canSilentUpdating) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canSilentUpdating, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func notifyChange() {
        if canSilentUpdating == false {
            onChangeHandler?()
        }
    }
    
    struct WYAssociatedKeys {
        static var intervalOnChange: UInt8 = 0
        static var canSilentUpdating: UInt8 = 0
    }
}

private extension WYSoundWavesView {
    
    var intervalObjCConfig: WYSoundWaveConfigObjC {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.intervalObjCConfig, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let obj = objc_getAssociatedObject(self, &WYAssociatedKeys.intervalObjCConfig) as? WYSoundWaveConfigObjC {
                return obj
            }
            
            let obj = WYSoundWaveConfigObjC()
            // 绑定
            bindObjCConfig(obj)
            // 存回去
            objc_setAssociatedObject(self, &WYAssociatedKeys.intervalObjCConfig, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            return obj
        }
    }
    
    func bindObjCConfig(_ obj: WYSoundWaveConfigObjC) {
        obj.onChangeHandler = { [weak self, weak obj] in
            guard let self = self, let obj = obj else { return }
            _ = obj.convertToSwift(&self.config)
        }
    }
    
    struct WYAssociatedKeys {
        static var intervalObjCConfig: UInt8 = 0
    }
}
