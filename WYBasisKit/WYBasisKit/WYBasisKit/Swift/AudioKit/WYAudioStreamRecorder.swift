//
//  WYAudioStreamRecorder.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/16.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation

/**
 流式录音器 - 边录边回调PCM音频块，不落音频文件
 
 与WYAudioKit的差异：WYAudioKit把录音写成m4a等文件、录完再处理，本类从麦克风取到声音就立刻把音频块回调出来，适合边说边识别语音、实时变声这类需要实时音频的场景。
 使用方式：start成功后音频块从onAudioChunk持续回调，不再使用时调stop或releaseAll收尾。
 */
public final class WYAudioStreamRecorder: NSObject {

    /// 音频块回调(pcmBuffer为16千赫兹采样、16位整型、单声道的PCM音频块，currentTime为本块结束时已录的秒数，闭包在音频采集线程回调且为Sendable，避免耗时操作，UI刷新需自行切回主线程)
    public var onAudioChunk: (@Sendable (_ pcmBuffer: AVAudioPCMBuffer, _ currentTime: TimeInterval) -> Void)?

    /// 音量回调(averagePower为当前音频块的响度，范围-160.0到0.0，0.0最响，适合驱动声波动画，currentTime为已录秒数，闭包在音频采集线程回调且为Sendable)
    public var onMetering: (@Sendable (_ averagePower: Float, _ currentTime: TimeInterval) -> Void)?

    /// 目标采样率(单位为赫兹，默认16000是实时语音识别的常用规格，必须在start前设置，start后改动无效)
    public var sampleRate: Double = 16000

    /// 是否正在录音
    public private(set) var isRecording: Bool = false

    /**
     开始流式录音(先要已获得麦克风权限，页面侧推荐先用wy_authorizeMicrophoneAccess请求好再调本方法)
     @throws WYAudioError(权限被拒绝、未决定、会话配置失败、录音开启失败)
     */
    public func start() throws {
        if isRecording { return }

        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .denied:
                throw WYAudioError.permissionDenied
            case .undetermined:
                throw WYAudioError.notDetermined
            case .granted:
                break
            @unknown default:
                break
            }
        }else {
            let permission = AVAudioSession.sharedInstance().recordPermission
            if permission == .denied {
                throw WYAudioError.permissionDenied
            }
            if permission == .undetermined {
                throw WYAudioError.notDetermined
            }
        }

        do {
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 13.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [AVAudioSession.CategoryOptions.allowBluetoothHFP, .defaultToSpeaker, .allowAirPlay])
            }else {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try session.setActive(true)
        }catch {
            throw WYAudioError.sessionConfigurationFailed
        }

        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: sampleRate,
                                               channels: 1,
                                               interleaved: true) else {
            throw WYAudioError.startRecordingFailed
        }

        // 按硬件原生格式装采样回调，拿到Float32后在handleTap里手工重采样转目标格式(AVAudioConverter逐帧单发转换在降采样组合下会输出错乱数据，installTap指定异构格式会抛格式不匹配异常，两条路径均不可用)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        targetBufferFormat = targetFormat
        totalFramesConverted = 0

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.handleTap(buffer: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        }catch {
            cleanTap()
            throw WYAudioError.startRecordingFailed
        }
        isRecording = true
    }

    /// 停止流式录音(停止后可以再次start，停止即不再回调音频块)
    public func stop() {
        guard isRecording else { return }
        isRecording = false
        cleanTap()
    }

    /// 收尾释放(停止录音并释放录音引擎，不再使用时调用)
    public func releaseAll() {
        stop()
        audioEngine.reset()
    }

    /// 录音引擎(采集麦克风输入)
    private let audioEngine = AVAudioEngine()

    /// 目标音频格式(16千赫兹16位单声道Int16)
    private var targetBufferFormat: AVAudioFormat?

    /// 已转换的目标帧数累计(除以采样率得到已录秒数)
    private var totalFramesConverted: AVAudioFrameCount = 0

    /// 拆掉采样回调并停掉引擎(开启失败与stop共用收尾)
    private func cleanTap() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        targetBufferFormat = nil
    }

    /// 处理一块麦克风采到的音频(硬件Float32帧手工重采样转目标采样率的单声道Int16后回调，并计算响度)
    private func handleTap(buffer: AVAudioPCMBuffer) {
        guard let targetFormat = targetBufferFormat, isRecording else { return }
        guard let inputChannel = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }

        let inputRate = buffer.format.sampleRate
        let inputFrames = Int(buffer.frameLength)
        let outputFrames = inputRate == sampleRate ? inputFrames : max(1, Int((Double(inputFrames) * sampleRate / inputRate).rounded()))

        var int16Samples = [Int16](repeating: 0, count: outputFrames)
        if inputRate == sampleRate {
            for index in 0..<outputFrames {
                let clamped = max(-1.0, min(1.0, Double(inputChannel[index])))
                int16Samples[index] = Int16(clamped * 32767.0)
            }
        }else {
            // 线性插值重采样(16千赫兹语音识别带宽8千赫兹以内，插值损失的高频不影响识别)
            let ratio = inputRate / sampleRate
            for index in 0..<outputFrames {
                let position = Double(index) * ratio
                let base = min(Int(position), inputFrames - 1)
                let next = min(base + 1, inputFrames - 1)
                let fraction = position - Double(base)
                let sample = Double(inputChannel[base]) * (1.0 - fraction) + Double(inputChannel[next]) * fraction
                let clamped = max(-1.0, min(1.0, sample))
                int16Samples[index] = Int16(clamped * 32767.0)
            }
        }

        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(outputFrames)) else { return }
        outBuffer.frameLength = AVAudioFrameCount(outputFrames)
        if let destination = outBuffer.int16ChannelData?[0] {
            _ = int16Samples.withUnsafeBufferPointer { pointer in
                memcpy(destination, pointer.baseAddress, outputFrames * 2)
            }
        }

        totalFramesConverted += AVAudioFrameCount(outputFrames)
        let currentTime = TimeInterval(totalFramesConverted) / sampleRate
        onAudioChunk?(outBuffer, currentTime)

        var sum: Double = 0
        for sample in int16Samples {
            sum += Double(sample) * Double(sample)
        }
        // 均方根换算成分贝(除以32768归一到0.0~1.0再乘20，安静时压到-160防止log10算出负无穷)
        let rms = (sum / Double(max(outputFrames, 1))).squareRoot() / 32768.0
        let averagePower = rms > 0.00001 ? max(20.0 * log10(rms), -160.0) : -160.0
        onMetering?(Float(averagePower), currentTime)
    }

    deinit {
        releaseAll()
    }
}
