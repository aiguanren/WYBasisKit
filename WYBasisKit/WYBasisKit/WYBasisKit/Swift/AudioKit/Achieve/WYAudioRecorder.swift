//
//  WYAudioRecorder.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation
import AVFoundation

internal final class WYAudioRecorder: NSObject {
    weak var kit: WYAudioKit?
    
    private let queue = DispatchQueue(label: "com.wy.audio.recorder", qos: .userInitiated)
    
    private var engine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var timer: DispatchSourceTimer?
    
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    var isRecording: Bool = false
    var isPaused: Bool = false
    var currentRecordFileURL: URL?
    
    var minimumRecordDuration: TimeInterval = 0
    var maximumRecordDuration: TimeInterval = 0
    var recordQuality: AVAudioQuality = .medium
    var recordSettings: [String: Any] = [:]
    
    private var waveformLevels: [Float] = []
    private var lastWaveformTime = Date()
    private var format: WYAudioFormat = .aac
    
    // MARK: - 开始录音
    func startRecording(fileName: String? = nil, format: WYAudioFormat) throws {
        try queue.sync { [weak self] in
            guard let self = self else { return }
            
            let session = AVAudioSession.sharedInstance()
            if session.recordPermission == .denied { throw WYAudioError.permissionDenied }
            if session.recordPermission == .undetermined { throw WYAudioError.notDetermined }
            
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            // 创建录音文件
            let fileURL = self.createRecordFileURL(fileName: fileName, format: format)
            self.currentRecordFileURL = fileURL
            self.kit?.currentRecordFileURL = fileURL
            self.format = format
            
            // 重置引擎
            self.resetEngine()
            
            self.engine = AVAudioEngine()
            guard let engine = self.engine else { throw WYAudioError.startRecordingFailed }
            
            let inputNode = engine.inputNode
            self.inputNode = inputNode
            
            let inputFormat = inputNode.inputFormat(forBus: 0)
            let settings = self.buildRecordingSettings(from: inputFormat, targetFormat: format)
            
            self.audioFile = try AVAudioFile(forWriting: fileURL, settings: settings)
            
            // 安装 Tap
            self.installTap(on: inputNode, format: inputFormat)
            
            try engine.start()
            
            self.isRecording = true
            self.isPaused = false
            self.startTime = Date()
            self.pausedDuration = 0
            self.waveformLevels.removeAll()
            
            self.startTimer()
            
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_audioRecorderDidStart?(audioKit: self.kit!, isResume: false)
            }
        }
    }
    
    // MARK: - 核心辅助方法
    private func createRecordFileURL(fileName: String?, format: WYAudioFormat) -> URL {
        let name = fileName ?? "Recording_\(Int(Date().timeIntervalSince1970)).\(format.extensionName)"
        return kit?.fileManager.recordingsDirectoryURL.appendingPathComponent(name)
            ?? FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
    
    private func buildRecordingSettings(from inputFormat: AVAudioFormat, targetFormat: WYAudioFormat) -> [String: Any] {
        var settings = kit?.recordSettings ?? [:]
        if settings.isEmpty {
            settings = [
                AVFormatIDKey: targetFormat.audioFormatID,
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: recordQuality.rawValue,
                AVEncoderBitRateKey: 128000
            ]
        }
        return settings
    }
    
    private func installTap(on inputNode: AVAudioInputNode, format: AVAudioFormat) {
        let bufferSize: AVAudioFrameCount = 1024
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] (buffer, _) in
            guard let self = self else { return }
            self.processBuffer(buffer)
        }
    }
    
    private func removeTap() {
        inputNode?.removeTap(onBus: 0)
    }
    
    private func resetEngine() {
        removeTap()
        engine?.stop()
        audioFile = nil
        engine = nil
        inputNode = nil
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        try? audioFile?.write(from: buffer)
        
        // 波形计算（保留你原来的 WeChat 风格）
        guard let data = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        let segments = 8
        let segSize = max(frames / segments, 1)
        var newLevels: [Float] = []
        
        for i in 0..<segments {
            var sum: Float = 0
            let start = i * segSize
            let end = min(start + segSize, frames)
            for j in start..<end {
                let sample = abs(data[0][j])
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(max(end - start, 1)))
            let level = min(1.0, max(0.0, rms * 12.0))
            newLevels.append(level)
        }
        waveformLevels.append(contentsOf: newLevels)
        
        // dB 值
        var peak: Float = -160
        var sumSq: Float = 0
        for i in 0..<frames {
            let s = abs(data[0][i])
            if s > peak { peak = s }
            sumSq += s * s
        }
        let rms = sqrt(sumSq / Float(max(frames, 1)))
        let avgPower = 20 * log10(max(rms, 0.00001))
        let peakPower = 20 * log10(max(peak, 0.00001))
        
        if Date().timeIntervalSince(lastWaveformTime) > 0.05 {
            lastWaveformTime = Date()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.kit?.recordingWaveform = self.waveformLevels
                self.kit?.delegate?.wy_audioRecorderDidUpdateMeterings?(audioKit: self.kit!, normalizedPeaks: self.waveformLevels, normalizedAverages: self.waveformLevels)
                self.kit?.delegate?.wy_audioRecorderDidUpdateMetering?(audioKit: self.kit!, peakPower: peakPower, averagePower: avgPower)
            }
        }
    }
    
    private func startTimer() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(100))
        t.setEventHandler { [weak self] in
            guard let self = self, let start = self.startTime else { return }
            let current = Date().timeIntervalSince(start) + self.pausedDuration
            
            if self.maximumRecordDuration > 0 && current >= self.maximumRecordDuration {
                self.stopRecording()
                return
            }
            
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_audioRecorderTimeUpdated?(audioKit: self.kit!, currentTime: current, duration: self.maximumRecordDuration)
            }
        }
        t.resume()
        timer = t
    }
    
    // MARK: - 暂停
    func pauseRecording() {
        queue.async { [weak self] in
            guard let self = self, self.isRecording else { return }
            
            self.removeTap()
            self.engine?.pause()
            self.isPaused = true
            
            if let start = self.startTime {
                self.pausedDuration += Date().timeIntervalSince(start)
            }
            self.startTime = nil
            self.timer?.suspend()
            
            // 同步文件，让暂停后可以播放
            if let url = self.currentRecordFileURL {
                self.kit?.currentRecordFileURL = url
            }
            
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_audioRecorderDidStop?(audioKit: self.kit!, isPause: true)
            }
        }
    }
    
    // MARK: - 恢复（关键修复）
    func resumeRecording() {
        queue.async { [weak self] in
            guard let self = self, self.isRecording, self.isPaused else { return }
            guard let engine = self.engine, let inputNode = self.inputNode else {
                // 如果引擎已失效，则重新开始（最稳妥）
                try? self.startRecording(format: self.format)
                return
            }
            
            do {
                let inputFormat = inputNode.inputFormat(forBus: 0)
                self.installTap(on: inputNode, format: inputFormat)   // 重新安装
                
                try engine.start()
                
                self.isPaused = false
                self.startTime = Date()
                self.timer?.resume()
                
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioRecorderDidStart?(audioKit: self.kit!, isResume: true)
                }
            } catch {
                print("恢复录音失败: \(error)")
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioTaskDidFailed?(audioKit: self.kit!, url: self.currentRecordFileURL ?? URL(fileURLWithPath: ""), error: .startRecordingFailed, description: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 停止
    func stopRecording() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.removeTap()
            self.engine?.stop()
            self.audioFile = nil
            self.engine = nil
            self.inputNode = nil
            self.timer?.cancel()
            self.timer = nil
            
            self.isRecording = false
            self.isPaused = false
            
            guard let fileURL = self.currentRecordFileURL else { return }
            
            let duration = self.kit?.fileManager.getAudioDuration(for: fileURL) ?? 0
            
            if self.minimumRecordDuration > 0 && duration < self.minimumRecordDuration {
                try? FileManager.default.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioTaskDidFailed?(audioKit: self.kit!, url: fileURL, error: .minDurationNotReached, description: nil)
                }
            } else {
                self.kit?.currentRecordFileURL = fileURL
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioRecorderDidStop?(audioKit: self.kit!, isPause: false)
                }
            }
            
            self.currentRecordFileURL = nil
        }
    }
    
    func releaseResources() {
        stopRecording()
    }
}
