//
//  WYAudioKit+Recording.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation

/// WYAudioKit 录音内部实现，刷新器驱动的录音状态/波形更新与 AVAudioRecorder 系统回调
extension WYAudioKit {
    
    /// 更新录音状态（时间、声波、自动停止）
    func updateRecordingState() {
        guard let recorder = state.audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        
        let currentTime = recorder.currentTime
        delegate?.wy_audioRecorderTimeUpdated?(audioKit: self,
                                               currentTime: currentTime,
                                               duration: maximumRecordDuration)
        
        let peak = recorder.peakPower(forChannel: 0)
        let avg = recorder.averagePower(forChannel: 0)
        delegate?.wy_audioRecorderDidUpdateMetering?(audioKit: self,
                                                     peakPower: peak,
                                                     averagePower: avg)
        
        var normalizedPeaks: [Float] = []
        var normalizedAverages: [Float] = []
        
        for i in 0..<min(state.recordChannelCount, 2) {
            let p = recorder.peakPower(forChannel: i)
            let a = recorder.averagePower(forChannel: i)
            normalizedPeaks.append(normalizePower(p))
            normalizedAverages.append(normalizePower(a))
        }
        
        delegate?.wy_audioRecorderDidUpdateMeterings?(audioKit: self,
                                                      peakPowers: normalizedPeaks,
                                                      averagePowers: normalizedAverages)
        
        if maximumRecordDuration > 0 && currentTime >= maximumRecordDuration {
            try? stopRecording()
        }
    }
    
    /// 将分贝值（dB）归一化到 0.0~1.0 范围
    func normalizePower(_ power: Float) -> Float {
        if power <= -160.0 { return 0.0 }
        if power >= 0.0 { return 1.0 }
        return pow(10.0, power / 20.0)
    }
}

// AVAudioRecorderDelegate 系统回调
extension WYAudioKit: AVAudioRecorderDelegate {
    
    /**
     录音完成回调（系统方法）
     - Parameters:
       - recorder: 录音器实例
       - flag: 是否成功完成
     */
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            // 录音完成但成功标志为 false
            wy_handleErrorEvents(error: .startRecordingFailed)
        }
    }
    
    /**
     录音编码错误回调（系统方法）
     - Parameters:
       - recorder: 录音器实例
       - error: 错误信息
     */
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        wy_handleErrorEvents(error: .startRecordingFailed, description: error?.localizedDescription)
    }
}
