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
    
    func startRecording(fileName: String? = nil, format: WYAudioFormat) throws {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                let session = AVAudioSession.sharedInstance()
                if session.recordPermission == .denied { throw WYAudioError.permissionDenied }
                if session.recordPermission == .undetermined {
                    // 实际项目中可异步请求，此处简化抛出
                    throw WYAudioError.notDetermined
                }
                try session.setCategory(.record, mode: .default)
                try session.setActive(true)
                
                let engine = AVAudioEngine()
                let input = engine.inputNode
                let sampleRate = (self.recordSettings[AVSampleRateKey] as? Double) ?? 44100
                let channels = (self.recordSettings[AVNumberOfChannelsKey] as? Int) ?? 2
                let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: AVAudioChannelCount(channels), interleaved: true)!
                
                let fileName = fileName ?? "record_\(Int(Date().timeIntervalSince1970)).\(format.extensionName)"
                let dirURL = self.kit?.fileManager.recordingsDirectoryURL ?? FileManager.default.temporaryDirectory
                let url = dirURL.appendingPathComponent(fileName)
                let settings: [String: Any] = [
                    AVFormatIDKey: format.audioFormatID,
                    AVSampleRateKey: sampleRate,
                    AVNumberOfChannelsKey: channels,
                    AVEncoderAudioQualityKey: self.recordQuality.rawValue
                ]
                let file = try AVAudioFile(forWriting: url, settings: settings)
                
                self.engine = engine
                self.inputNode = input
                self.audioFile = file
                self.currentRecordFileURL = url
                self.format = format
                self.waveformLevels = []
                self.startTime = Date()
                self.pausedDuration = 0
                
                input.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { buffer, _ in
                    self.processBuffer(buffer)
                }
                engine.connect(input, to: engine.mainMixerNode, format: audioFormat)
                try engine.start()
                
                self.isRecording = true
                self.isPaused = false
                self.startTimer()
                
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioRecorderDidStart?(audioKit: self.kit!, isResume: false)
                }
            } catch {
                throw WYAudioError.startRecordingFailed
            }
        }
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        let ch = Int(buffer.format.channelCount)
        
        // WeChat风格波形算法：分段RMS归一化到0~1
        let segments = 8
        let segSize = frames / segments
        var newLevels: [Float] = []
        for i in 0..<segments {
            var sum: Float = 0
            let start = i * segSize
            let end = min(start + segSize, frames)
            for j in start..<end {
                let sample = abs(data[0][j])
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(end - start))
            let level = min(1.0, max(0.0, rms * 12.0)) // 经验归一化
            newLevels.append(level)
        }
        waveformLevels.append(contentsOf: newLevels)
        
        // 峰值/平均（dB）
        var peak: Float = -160
        var sumSq: Float = 0
        for i in 0..<frames {
            let s = abs(data[0][i])
            if s > peak { peak = s }
            sumSq += s * s
        }
        let rms = sqrt(sumSq / Float(frames))
        let avgPower = 20 * log10(max(rms, 0.00001))
        let peakPower = 20 * log10(max(peak, 0.00001))
        
        if Date().timeIntervalSince(lastWaveformTime) > 0.05 {
            lastWaveformTime = Date()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.kit?.recordingWaveform = self.waveformLevels
                self.kit?.delegate?.wy_audioRecorderDidUpdateWaveform?(audioKit: self.kit!, waveform: self.waveformLevels)
                self.kit?.delegate?.wy_audioRecorderDidUpdateMetering?(audioKit: self.kit!, peakPower: peakPower, averagePower: avgPower)
            }
        }
        
        try? audioFile?.write(from: buffer)
    }
    
    private func startTimer() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(100))
        t.setEventHandler { [weak self] in
            guard let self, let start = self.startTime else { return }
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
    
    func pauseRecording() {
        queue.async { [weak self] in
            guard let self, self.isRecording else { return }
            self.engine?.pause()
            self.isPaused = true
            if let start = self.startTime {
                self.pausedDuration += Date().timeIntervalSince(start)
            }
            self.startTime = nil
            self.timer?.suspend()
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_audioRecorderDidStop?(audioKit: self.kit!, isPause: true)
            }
        }
    }
    
    func resumeRecording() {
        queue.async { [weak self] in
            guard let self, self.isRecording, self.isPaused else { return }
            try? self.engine?.start()
            self.isPaused = false
            self.startTime = Date()
            self.timer?.resume()
            DispatchQueue.main.async {
                self.kit?.delegate?.wy_audioRecorderDidStart?(audioKit: self.kit!, isResume: true)
            }
        }
    }
    
    func stopRecording() {
        queue.async { [weak self] in
            guard let self else { return }
            self.engine?.stop()
            self.inputNode?.removeTap(onBus: 0)
            self.audioFile = nil
            self.engine = nil
            self.inputNode = nil
            self.timer?.cancel()
            self.timer = nil
            self.isRecording = false
            self.isPaused = false
            
            let duration = self.currentRecordFileURL.map { self.kit?.fileManager.getAudioDuration(for: $0) ?? 0 } ?? 0
            if self.minimumRecordDuration > 0 && duration < self.minimumRecordDuration {
                try? FileManager.default.removeItem(at: self.currentRecordFileURL!)
                DispatchQueue.main.async {
                    self.kit?.delegate?.wy_audioTaskDidFailed?(audioKit: self.kit!, url: self.currentRecordFileURL ?? URL(fileURLWithPath: ""), error: .minDurationNotReached, description: nil)
                }
            } else {
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
