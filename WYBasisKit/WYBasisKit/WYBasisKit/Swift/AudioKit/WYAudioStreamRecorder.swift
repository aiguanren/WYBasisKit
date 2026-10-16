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
 
 与WYAudioKit的差异，WYAudioKit把录音写成m4a等文件、录完再处理，本类从麦克风取到声音就立刻把音频块回调出来，适合边说边识别语音、实时变声这类等不了录完的场景。
 使用方式，start成功后音频块从onAudioChunk持续吐出，不需要了调stop或releaseAll收尾。
 */
public final class WYAudioStreamRecorder: NSObject {

    /// 音频块回调(pcmBuffer为16千赫兹采样、16位整型、单声道的PCM音频块，currentTime为本块结束时已录的秒数；闭包在音频采集线程回调且为Sendable，不要在这里做耗时操作，UI刷新需自行切回主线程)
    public var onAudioChunk: (@Sendable (_ pcmBuffer: AVAudioPCMBuffer, _ currentTime: TimeInterval) -> Void)?

    /// 音量回调(averagePower为当前音频块的响度，范围-160.0到0.0，0.0最响，适合喂声波动画；currentTime为已录秒数；闭包在音频采集线程回调且为Sendable)
    public var onMetering: (@Sendable (_ averagePower: Float, _ currentTime: TimeInterval) -> Void)?

    /// 目标采样率(单位为赫兹，默认16000是实时语音识别的常用规格，必须在start前设置，start后改动无效)
    public var sampleRate: Double = 16000

    /// 是否正在录音
    public private(set) var isRecording: Bool = false

    /**
     开始流式录音(先要已获得麦克风权限，页面侧推荐先用wy_authorizeMicrophoneAccess请求好再调本方法)
     - Throws: WYAudioError(权限被拒绝、未决定、会话配置失败、录音开启失败)
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

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        targetBufferFormat = targetFormat
        totalFramesConverted = 0

        // 单次转换的输出帧容量(输入2048帧按采样率比例换算目标帧数并上取整，加32帧余量防非整数倍采样率被截断)
        let inputFrames: AVAudioFrameCount = 2048
        tapBufferCapacity = AVAudioFrameCount((Double(inputFrames) * targetFormat.sampleRate / inputFormat.sampleRate).rounded(.up)) + 32

        inputNode.installTap(onBus: 0, bufferSize: inputFrames, format: inputFormat) { [weak self] buffer, _ in
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

    /// 停止流式录音(停止后可以再次start，音频块回调随停而止)
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

    /// 录音引擎(装麦克风输入采样的部件)
    private let audioEngine = AVAudioEngine()

    /// 采样格式转换器(把麦克风原始格式转成目标采样率的单声道Int16)
    private var converter: AVAudioConverter?

    /// 目标音频格式(16千赫兹16位单声道Int16)
    private var targetBufferFormat: AVAudioFormat?

    /// 单次转换输出的帧容量
    private var tapBufferCapacity: AVAudioFrameCount = 0

    /// 已转换的目标帧数累计(除以采样率得到已录秒数)
    private var totalFramesConverted: AVAudioFrameCount = 0

    /// 拆掉采样回调并停掉引擎(开启失败与stop共用收尾)
    private func cleanTap() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        converter = nil
        targetBufferFormat = nil
    }

    /// 处理一棒麦克风采到的音频(转成目标格式后回调出去，顺带算响度)
    private func handleTap(buffer: AVAudioPCMBuffer) {
        guard let converter = converter, let targetFormat = targetBufferFormat, isRecording else { return }

        let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: tapBufferCapacity)
        guard let outBuffer = outBuffer else { return }

        // 单发转换闭包只交一次输入缓冲，转换器不会再要更多数据
        var hasFedInput = false
        var conversionError: NSError?
        let status = converter.convert(to: outBuffer, error: &conversionError) { _, inputStatus in
            if hasFedInput {
                inputStatus.pointee = .noDataNow
                return nil
            }
            hasFedInput = true
            inputStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, outBuffer.frameLength > 0 else { return }

        totalFramesConverted += outBuffer.frameLength
        let currentTime = TimeInterval(totalFramesConverted) / targetFormat.sampleRate
        onAudioChunk?(outBuffer, currentTime)

        if let channelData = outBuffer.int16ChannelData?[0] {
            let sampleCount = Int(outBuffer.frameLength)
            var sum: Double = 0
            for index in 0..<sampleCount {
                let sample = Double(channelData[index])
                sum += sample * sample
            }
            // 均方根换算成分贝(除以32768归一到0.0~1.0再乘20，安静时压到-160防log10算出负无穷)
            let rms = (sum / Double(max(sampleCount, 1))).squareRoot() / 32768.0
            let averagePower = rms > 0.00001 ? max(20.0 * log10(rms), -160.0) : -160.0
            onMetering?(Float(averagePower), currentTime)
        }else {
            onMetering?(-160.0, currentTime)
        }
    }

    deinit {
        releaseAll()
    }
}
