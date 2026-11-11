//
//  WYChatLiveRecorder+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/9.
//

import AVFoundation

/// 同一路音频采集提供录音文件与实时识别数据
final class WYChatLiveRecorder {
    private static let captureQueue = DispatchQueue(label: "WYChatLiveRecorder", qos: .userInitiated)
    private static weak var activeOwner: WYChatLiveRecorder?
    private let queue = WYChatLiveRecorder.captureQueue
    private var observers: [NSObjectProtocol] = []
    private var maximumFrames: AVAudioFramePosition?
    private var engine: AVAudioEngine?
    private var file: AVAudioFile?
    private var converter: AVAudioConverter?
    private var outputURL: URL?
    private var frames: AVAudioFramePosition = 0
    private var lastProgress: TimeInterval = 0
    private var stopping = false
    private var tapInstalled = false
    private var completion: ((_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void)?
    private var audio: ((_ buffer: AVAudioPCMBuffer) -> Void)?
    private var progress: ((_ duration: TimeInterval, _ peak: Float, _ average: Float) -> Void)?

    func start(configuration: WYRecordAnimationConfig, audio: @escaping (_ buffer: AVAudioPCMBuffer) -> Void, progress: @escaping (_ duration: TimeInterval, _ peak: Float, _ average: Float) -> Void, completion: @escaping (_ url: URL?, _ duration: TimeInterval, _ error: NSError?) -> Void) {
        queue.async { [self] in
            self.audio = audio
            self.progress = progress
            self.completion = completion
            do {
                guard Self.activeOwner == nil else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(AVAudioSession.ErrorCode.isBusy.rawValue)) }
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
                Self.activeOwner = self
                observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: nil) { [weak self] notification in
                    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
                    self?.stop(cancel: false)
                })
                observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: nil) { [weak self] notification in
                    guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
                    self?.stop(cancel: false)
                })
                let engine = AVAudioEngine()
                self.engine = engine
                let input = engine.inputNode
                let format = input.outputFormat(forBus: 0)
                guard format.sampleRate > 0, format.channelCount > 0 else { throw NSError(domain: String(describing: Self.self), code: 1, userInfo: [NSLocalizedDescriptionKey: WYLocalized("录音文件无效或录音时间太短", table: WYBasisKitConfig.kitLocalizableTable)]) }
                var settings = configuration.recordSettings
                if settings[AVFormatIDKey] == nil { settings[AVFormatIDKey] = kAudioFormatMPEG4AAC }
                if settings[AVSampleRateKey] == nil { settings[AVSampleRateKey] = format.sampleRate }
                if settings[AVNumberOfChannelsKey] == nil { settings[AVNumberOfChannelsKey] = 1 }
                let formatID = (settings[AVFormatIDKey] as? NSNumber)?.uint32Value ?? kAudioFormatMPEG4AAC
                let suffix = formatID == kAudioFormatMPEG4AAC ? "m4a" : "caf"
                try FileManager.default.createDirectory(at: configuration.chatAudioUrl, withIntermediateDirectories: true)
                let url = configuration.chatAudioUrl.appendingPathComponent(UUID().uuidString).appendingPathExtension(suffix)
                self.outputURL = url
                let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
                self.file = file
                let maximum = configuration.recordTime.max
                if maximum.isFinite && maximum > 0 {
                    maximumFrames = AVAudioFramePosition(min(Double(Int64.max / 2), ceil(maximum * file.processingFormat.sampleRate)))
                }
                self.converter = AVAudioConverter(from: format, to: file.processingFormat)
                guard self.converter != nil else { throw NSError(domain: String(describing: Self.self), code: 2) }
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                    guard let self, let copy = Self.copy(buffer) else { return }
                    self.queue.async { [self] in self.consume(copy) }
                }
                tapInstalled = true
                engine.prepare()
                try engine.start()
            } catch { finish(cancel: true, error: error as NSError) }
        }
    }

    func stop(cancel: Bool) {
        queue.async { [self] in
            guard !stopping else { return }
            stopping = true
            if tapInstalled { engine?.inputNode.removeTap(onBus: 0); tapInstalled = false }
            engine?.stop()
            queue.async { [self] in finish(cancel: cancel, error: nil) }
        }
    }

    private func consume(_ buffer: AVAudioPCMBuffer) {
        guard let file, let converter, completion != nil else { return }
        let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * file.processingFormat.sampleRate / buffer.format.sampleRate) + 32)
        var supplied = false
        while completion != nil {
            guard let converted = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: capacity) else { return }
            var error: NSError?
            let status = converter.convert(to: converted, error: &error) { _, state in
                guard !supplied else { state.pointee = .noDataNow; return nil }
                supplied = true
                state.pointee = .haveData
                return buffer
            }
            if status == .error { finish(cancel: true, error: error ?? NSError(domain: NSOSStatusErrorDomain, code: -50)); return }
            if converted.frameLength > 0 {
                do { try write(converted, to: file) }
                catch { finish(cancel: true, error: error as NSError); return }
            }
            if let maximumFrames, frames >= maximumFrames { finish(cancel: false, error: nil); return }
            if status != .haveData || converted.frameLength == 0 { return }
        }
    }

    private func write(_ converted: AVAudioPCMBuffer, to file: AVAudioFile) throws {
        if let maximumFrames { converted.frameLength = min(converted.frameLength, AVAudioFrameCount(min(Int64(UInt32.max), max(0, maximumFrames - frames)))) }
        guard converted.frameLength > 0 else { return }
        try file.write(from: converted)
        frames += AVAudioFramePosition(converted.frameLength)
        audio?(converted)
        let duration = Double(frames) / file.processingFormat.sampleRate
        guard duration - lastProgress >= 0.05 else { return }
        lastProgress = duration
        var peak: Float = 0
        var squares: Float = 0
        if let values = converted.floatChannelData?[0] {
            for index in 0..<Int(converted.frameLength) {
                let value = abs(values[index])
                peak = max(peak, value)
                squares += value * value
            }
        }
        let average = sqrt(squares / Float(converted.frameLength))
        let peakDB = max(-160, 20 * log10(max(peak, 0.00000001)))
        let averageDB = max(-160, 20 * log10(max(average, 0.00000001)))
        let progress = progress
        DispatchQueue.main.async { progress?(duration, peakDB, averageDB) }
    }

    private func drainConverter() throws {
        guard let file, let converter else { return }
        while completion != nil {
            if let maximumFrames, frames >= maximumFrames { return }
            guard let output = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 1024) else { return }
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { _, state in state.pointee = .endOfStream; return nil }
            if let error { throw error }
            if status == .error { throw NSError(domain: NSOSStatusErrorDomain, code: -50) }
            if output.frameLength > 0 { try write(output, to: file) }
            if status == .endOfStream || status == .error || output.frameLength == 0 { return }
        }
    }

    private func finish(cancel: Bool, error: NSError?) {
        guard let completion else { return }
        var error = error
        if tapInstalled { engine?.inputNode.removeTap(onBus: 0); tapInstalled = false }
        engine?.stop()
        engine = nil
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        if !cancel && error == nil {
            do { try drainConverter() }
            catch let conversionError { error = conversionError as NSError }
        }
        self.completion = nil
        let duration = file.map { Double(frames) / $0.processingFormat.sampleRate } ?? 0
        file = nil
        converter = nil
        audio = nil
        progress = nil
        let url = outputURL
        outputURL = nil
        let discarded = cancel || error != nil
        if discarded, let url { try? FileManager.default.removeItem(at: url) }
        if Self.activeOwner === self {
            Self.activeOwner = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        DispatchQueue.main.async { completion(discarded ? nil : url, duration, error) }
    }

    private static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else { return nil }
        copy.frameLength = buffer.frameLength
        let source = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: buffer.audioBufferList))
        let target = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for index in source.indices {
            guard let input = source[index].mData, let output = target[index].mData else { continue }
            memcpy(output, input, Int(source[index].mDataByteSize))
        }
        return copy
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        let engine = engine
        let tapped = tapInstalled
        queue.async { if tapped { engine?.inputNode.removeTap(onBus: 0) }; engine?.stop() }
    }
}
