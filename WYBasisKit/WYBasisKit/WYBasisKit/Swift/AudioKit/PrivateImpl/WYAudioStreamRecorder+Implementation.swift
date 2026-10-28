//
//  WYAudioStreamRecorder+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import Foundation
import AVFoundation

/// 流式录音器的采集状态
final class WYAudioStreamRecorderPrivateState {

    /// 录音引擎(采集麦克风输入)
    let audioEngine = AVAudioEngine()

    /// 目标音频格式(16千赫兹16位单声道Int16)
    var targetBufferFormat: AVAudioFormat?

    /// 已转换的目标帧数累计(除以采样率得到已录秒数)
    var totalFramesConverted: AVAudioFrameCount = 0

}

/// 流式录音器的采样与清理实现
extension WYAudioStreamRecorder {

    /// 拆掉采样回调并停掉引擎(开启失败与stop共用收尾)
    func cleanTap() {
        privateState.audioEngine.inputNode.removeTap(onBus: 0)
        privateState.audioEngine.stop()
        privateState.targetBufferFormat = nil
    }

    /// 处理一块麦克风采到的音频(硬件Float32帧手工重采样转目标采样率的单声道Int16后回调，并计算响度)
    func handleTap(buffer: AVAudioPCMBuffer) {
        guard let targetFormat = privateState.targetBufferFormat, isRecording else { return }
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

        privateState.totalFramesConverted += AVAudioFrameCount(outputFrames)
        let currentTime = TimeInterval(privateState.totalFramesConverted) / sampleRate
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
}
