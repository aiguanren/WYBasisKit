//
//  WYAudioKit.swift
//  WYBasisKit
//
//  Created by guanren on 2025/8/12.
//

import Foundation
import AVFoundation
import Combine
import QuartzCore

/**
 音频文件格式说明：
 
  可直接录制（iOS 原生支持）：
   - aac ：高效压缩，体积小，音质好；适合音乐、播客、配音；跨平台兼容性好
   - wav ：无损 PCM，音质最佳，文件较大；适合高音质场景
   - caf ：Apple 容器，支持多种编码，适合长音频无大小限制
   - m4a ：基于 MPEG-4 容器，常封装 AAC/ALAC，Apple 生态常用
   - aiff：无损 PCM，Apple 早期格式，音质好，体积较大
 
  仅播放支持（无法直接录制）：
   - mp3 ：通用有损编码，兼容性极高，适合跨平台分发
   - flac：无损压缩，音质好，安卓友好，iOS 需转码播放
   - au  ：早期 UNIX 音频格式，现较少使用
   - amr ：人声优化编码，适合通话录音，音质一般
   - ac3 ：杜比数字音频，多声道环绕声，电影电视常用
   - eac3：杜比数字增强版，支持更高码率和更多声道
 
  跨平台推荐：
   - 录制给安卓播放：aac / mp3（兼容性较好）
   - 安卓录制给 iOS 播放：mp3 / aac（无需额外解码）
 */
@frozen public enum WYAudioFormat: Int {
    case aac = 0
    case wav
    case caf
    case m4a
    case aiff
    case mp3
    case flac
    case au
    case amr
    case ac3
    case eac3
    
    /// 获取文件扩展名
    public var stringValue: String {
        switch self {
        case .aac: return "aac"
        case .wav: return "wav"
        case .caf: return "caf"
        case .m4a: return "m4a"
        case .aiff: return "aiff"
        case .mp3: return "mp3"
        case .flac: return "flac"
        case .au: return "au"
        case .amr: return "amr"
        case .ac3: return "ac3"
        case .eac3: return "eac3"
        }
    }
}

/// 音频存储目录类型
@frozen public enum WYAudioStorageDirectory: Int {
    /// 临时目录（系统可能自动清理）
    case temporary = 0
    /// 文档目录（用户数据，iTunes备份）
    case documents
    /// 缓存目录（系统可能清理）
    case caches
}

/// 音频相关错误类型
@objc @frozen public enum WYAudioError: Int {
    /// 录音权限被拒绝
    case permissionDenied = 0
    /// 音频文件未找到
    case fileNotFound
    /// 录音正在进行中
    case recordingInProgress
    /// 播放错误
    case playbackError
    /// 录音文件保存失败
    case fileSaveFailed
    /// 录音时长未达到最小值
    case minDurationNotReached
    /// 录音达到最大时长
    case maxDurationReached
    /// 音频下载失败
    case downloadFailed
    /// 无效的远程URL
    case invalidRemoteURL
    /// 格式转换失败
    case conversionFailed
    /// 格式转换已取消
    case conversionCancelled
    /// 不支持的录制格式
    case formatNotSupported
    /// 内存不足
    case outOfMemory
    /// 音频会话配置失败
    case sessionConfigurationFailed
    /// 目录创建失败
    case directoryCreationFailed
}

/// 音频工具类代理协议
@objc public protocol WYAudioKitDelegate {
    /// 录音开始回调
    @objc optional func audioRecorderDidStart()
    
    /// 录音停止回调
    @objc optional func audioRecorderDidStop()
    
    /**
     录音时间更新
     - Parameters:
     - currentTime: 当前录音时间（秒）
     - duration: 总录音时长限制（秒）
     */
    @objc optional func audioRecorderTimeUpdated(currentTime: TimeInterval, duration: TimeInterval)
    
    /**
     录音出现错误
     - Parameter error: 错误信息
     */
    @objc optional func audioRecorderDidFail(error: WYAudioError)
    
    /// 播放开始回调
    @objc optional func audioPlayerDidStart()
    
    /// 播放暂停回调
    @objc optional func audioPlayerDidPause()
    
    /// 播放恢复回调
    @objc optional func audioPlayerDidResume()
    
    /// 播放停止回调
    @objc optional func audioPlayerDidStop()
    
    /**
     播放进度更新
     - Parameters:
     - currentTime: 当前播放位置（秒）
     - duration: 音频总时长（秒）
     - progress: 播放进度百分比（0.0 - 1.0）
     */
    @objc optional func audioPlayerTimeUpdated(currentTime: TimeInterval, duration: TimeInterval, progress: Double)
    
    /// 播放完成回调
    @objc optional func audioPlayerDidFinishPlaying()
    
    /**
     播放出现错误
     
     - Parameter error: 错误信息
     */
    @objc optional func audioPlayerDidFail(error: WYAudioError)
    
    /**
     网络音频下载进度更新
     
     - Parameter progress: 下载进度百分比（0.0 - 1.0）
     */
    @objc optional func remoteAudioDownloadProgressUpdated(progress: Double)
    
    /**
     格式转换进度更新
     
     - Parameter progress: 转换进度百分比（0.0 - 1.0）
     */
    @objc optional func conversionProgressUpdated(progress: Double)
    
    /**
     格式转换完成
     
     - Parameter url: 转换后的文件URL
     */
    @objc optional func conversionDidComplete(url: URL)
    
    /**
     音频会话配置失败
     
     - Parameter error: 错误信息
     */
    @objc optional func audioSessionConfigurationFailed(error: Error)
    
    /**
     录音声波数据更新
     
     - Parameter peakPower: 当前峰值功率（dB），范围 -160 到 0
     */
    @objc optional func audioRecorderDidUpdateMetering(peakPower: Float)
}

/**
 音频工具类 - 提供录音、播放、文件管理和格式转换功能
 
 主要功能：
 - 录音控制（开始、暂停、恢复、停止）
 - 播放控制（播放、暂停、恢复、停止、进度跳转）
 - 文件管理（获取录音文件、保存、删除）
 - 网络音频播放（支持下载和播放远程音频）
 - 录音参数配置（格式、质量、时长限制）
 - 音频格式转换（支持多种格式互转）
 */
public final class WYAudioKit: NSObject {
    
    /// 代理对象
    public weak var delegate: WYAudioKitDelegate?
    
    /// 音频录音器
    public var audioRecorder: AVAudioRecorder?
    
    /// 音频播放器
    public var audioPlayer: AVAudioPlayer?
    
    /// 是否正在录音（包括暂停状态）
    public var isRecording: Bool {
        return audioRecorder != nil
    }
    
    /// 是否正在播放（包括暂停状态）
    public var isPlaying: Bool {
        return audioPlayer != nil
    }
    
    /// 录音是否暂停
    public private(set) var isRecordingPaused: Bool = false
    
    /// 播放是否暂停
    public private(set) var isPlaybackPaused: Bool = false
    
    /// 当前录音文件URL
    public private(set) var currentRecordFileURL: URL?
    
    /// 录音文件存储目录类型（默认临时目录）
    public var recordingsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            _ = createDirectoryIfNeeded(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件存储目录类型（默认临时目录）
    public var downloadsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            _ = createDirectoryIfNeeded(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 录音文件子目录名称（可选）
    public var recordingsSubdirectory: String? = "Recordings" {
        didSet {
            _ = createDirectoryIfNeeded(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件子目录名称（可选）
    public var downloadsSubdirectory: String? = "Downloads" {
        didSet {
            _ = createDirectoryIfNeeded(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 初始化音频工具（唯一初始化方法）
    public override init() {
        super.init()
        setupDefaultSettings()
        setupDisplayLink()
        setupInterruptionHandler()
        setupRouteChangeHandler()
    }
    
    /**
     请求录音权限
     
     - Parameter completion: 权限请求结果回调
     - granted: true 表示已授权，false 表示未授权
     */
    public func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            recordingSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    /**
     开始录音
     
     - Parameters:
     - fileName: 自定义文件名（可选，不传则自动生成）
     - format: 音频格式（默认AAC）
     
     - Throws: 可能抛出权限错误或初始化错误
     */
    public func startRecording(fileName: String? = nil, format: WYAudioFormat = .aac) throws {
        
        // 检查是否正在录音
        guard !isRecording else {
            throw makeError(.recordingInProgress)
        }
        
        // 检查是否正在播放
        guard !isPlaying else {
            throw makeError(.playbackError)
        }
        
        // 确保有录音权限
        if #available(iOS 17.0, *) {
            guard AVAudioApplication.shared.recordPermission == .granted else {
                throw makeError(.permissionDenied)
            }
        } else {
            guard recordingSession.recordPermission == .granted else {
                throw makeError(.permissionDenied)
            }
        }
        
        // 检查格式支持性
        guard ![.mp3, .flac, .au, .amr, .ac3, .eac3].contains(format) else {
            throw makeError(.formatNotSupported)
        }
        
        // 重置状态 - 确保完全清理前一次录音
        resetRecording()
        
        // 重置音频会话
        try resetAudioSession()
        
        // 配置录音会话
        try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建文件路径
        let fileURL = generateFileURL(fileName: fileName, format: format)
        currentRecordFileURL = fileURL
        
        // 合并自定义设置
        var settings = customRecordSettings
        settings[AVFormatIDKey] = formatKey(for: format)
        
        // 创建录音器
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // 使用 record(forDuration:) 控制最大录音时长
            if maxRecordingDuration > 0 {
                audioRecorder?.record(forDuration: maxRecordingDuration)
            } else {
                audioRecorder?.record()
            }
            
            isRecordingPaused = false
            startRecordingProgressUpdates()
            delegate?.audioRecorderDidStart?()
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.apple.OSStatus" && nsError.code == -108 {
                throw makeError(.outOfMemory)
            } else {
                throw error
            }
        }
    }
    
    /// 停止录音
    public func stopRecording() {
        guard let recorder = audioRecorder else { return }
        
        let currentDuration = recorder.currentTime
        recorder.stop()
        
        // 检查最小录音时长
        if minRecordingDuration > 0 && currentDuration < minRecordingDuration {
            try? deleteRecording()
            delegate?.audioRecorderDidFail?(error: .minDurationNotReached)
        } else {
            delegate?.audioRecorderDidStop?()
        }
        
        // 重置录音状态
        resetRecording()
        
        // 异步重置音频会话
        resetAudioSessionAsync()
    }
    
    /// 暂停录音
    public func pauseRecording() {
        guard let recorder = audioRecorder else { return }
        guard recorder.isRecording else { return }
        guard !isRecordingPaused else { return }
        
        recorder.pause()
        isRecordingPaused = true
        stopRecordingProgressUpdates()
        delegate?.audioRecorderDidStop?()
    }
    
    /// 恢复录音
    public func resumeRecording() {
        guard let recorder = audioRecorder else { return }
        guard !recorder.isRecording else { return }
        guard isRecordingPaused else { return }
        
        recorder.record()
        isRecordingPaused = false
        startRecordingProgressUpdates()
        delegate?.audioRecorderDidStart?()
    }
    
    /**
     设置自定义录音参数
     
     - Parameter settings: 录音参数字典
     
     常用键值:
     - AVFormatIDKey: 音频格式
     - AVSampleRateKey: 采样率
     - AVNumberOfChannelsKey: 通道数
     - AVEncoderAudioQualityKey: 编码质量
     - AVEncoderBitRateKey: 比特率
     */
    public func setRecordSettings(_ settings: [String: Any]) {
        settings.forEach { key, value in
            customRecordSettings[key] = value
        }
    }
    
    /**
     设置音频质量
     
     - Parameter quality: 音频质量等级
     */
    public func setAudioQuality(_ quality: AVAudioQuality) {
        customRecordSettings[AVEncoderAudioQualityKey] = quality.rawValue
    }
    
    /**
     设置录音时长限制
     
     - Parameters:
     - min: 最小录音时长（秒），0表示无限制（默认）
     - max: 最大录音时长（秒），0表示无限制（默认）
     */
    public func setRecordingDurations(min: TimeInterval = 0, max: TimeInterval = 0) {
        minRecordingDuration = min
        maxRecordingDuration = max
    }
    
    /**
     保存录音文件到指定位置
     
     - Parameter destinationURL: 目标文件URL
     
     - Throws: 文件操作可能抛出错误
     */
    public func saveRecording(to destinationURL: URL) throws {
        guard let currentRecordFileURL else {
            throw makeError(.fileNotFound)
        }
        try FileManager.default.copyItem(at: currentRecordFileURL, to: destinationURL)
    }
    
    /**
     删除当前录音文件
     
     - Throws: 文件操作可能抛出错误
     */
    public func deleteRecording() throws {
        guard let currentRecordFileURL else {
            throw makeError(.fileNotFound)
        }
        try FileManager.default.removeItem(at: currentRecordFileURL)
        self.currentRecordFileURL = nil
    }
    
    /**
     获取所有录音文件
     
     - Returns: 录音文件URL数组（按创建日期倒序排序）
     */
    public func getAllRecordings() -> [URL] {
        return getAudioFiles(in: recordingsDirectory, subdirectory: recordingsSubdirectory)
    }
    
    /**
     删除指定的录音文件
     
     - Parameter url: 要删除的文件URL
     
     - Throws: 文件操作可能抛出错误
     */
    public func deleteRecording(at url: URL) throws {
        try deleteFile(at: url)
    }
    
    /**
     删除所有录音文件
     
     - Throws: 文件操作可能抛出错误
     */
    public func deleteAllRecordings() throws {
        try deleteAllFiles(in: recordingsDirectory, subdirectory: recordingsSubdirectory)
    }
    
    /**
     播放指定URL的音频文件
     
     支持本地文件路径
     
     - Parameter url: 音频文件URL
     
     - Throws: 播放初始化可能抛出错误
     */
    public func playAudio(at url: URL) throws {
        // 检查是否正在录音
        guard !isRecording else {
            throw makeError(.recordingInProgress)
        }
        
        // 停止所有音频活动
        stopAllAudioActivities()
        
        // 重置音频会话
        try resetAudioSession()
        
        // 配置播放会话
        try recordingSession.setCategory(.playback, mode: .default)
        try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建播放器
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaybackPaused = false
            startPlaybackProgressUpdates()
            delegate?.audioPlayerDidStart?()
            
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.apple.OSStatus" && nsError.code == -108 {
                throw makeError(.outOfMemory)
            } else {
                throw error
            }
        }
    }
    
    /**
     播放当前录音文件
     
     - Throws: 文件未找到错误
     */
    public func playRecordedFile() throws {
        guard !isRecording else {
            throw makeError(.recordingInProgress)
        }
        
        guard let currentRecordFileURL else {
            throw makeError(.fileNotFound)
        }
        
        isRecordingPaused = false
        try playAudio(at: currentRecordFileURL)
    }
    
    /// 暂停播放
    public func pausePlayback() {
        guard let player = audioPlayer else { return }
        guard player.isPlaying else { return }
        guard !isPlaybackPaused else { return }
        
        player.pause()
        isPlaybackPaused = true
        stopPlaybackProgressUpdates()
        delegate?.audioPlayerDidPause?()
    }
    
    /// 恢复播放
    public func resumePlayback() {
        guard let player = audioPlayer else { return }
        guard !player.isPlaying else { return }
        guard isPlaybackPaused else { return }
        
        player.play()
        isPlaybackPaused = false
        startPlaybackProgressUpdates()
        delegate?.audioPlayerDidResume?()
    }
    
    /// 停止播放
    public func stopPlayback() {
        guard isPlaying else { return }
        
        audioPlayer?.stop()
        delegate?.audioPlayerDidStop?()
        
        resetPlayback()
        resetAudioSessionAsync()
    }
    
    /**
     跳转到指定播放位置
     
     - Parameter time: 目标时间（秒）
     */
    public func seekPlayback(to time: TimeInterval) {
        guard let audioPlayer else { return }
        audioPlayer.currentTime = min(max(time, 0), audioPlayer.duration)
        
        let progress = audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
        delegate?.audioPlayerTimeUpdated?(
            currentTime: audioPlayer.currentTime,
            duration: audioPlayer.duration,
            progress: progress
        )
        
        if audioPlayer.isPlaying {
            startPlaybackProgressUpdates()
        }
    }
    
    /**
     播放网络音频文件
     
     此方法会自动下载远程音频文件并播放
     
     - Parameters:
     - remoteURL: 远程音频文件的URL
     - completion: 下载完成后的回调，返回下载结果
     */
    public func playRemoteAudio(from remoteURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !isRecording else {
            completion(.failure(makeError(.recordingInProgress)))
            return
        }
        
        guard ["http", "https"].contains(remoteURL.scheme?.lowercased() ?? "") else {
            completion(.failure(makeError(.invalidRemoteURL)))
            return
        }
        
        stopAllAudioActivities()
        
        downloadRemoteAudio(from: remoteURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let localURL):
                    do {
                        try self?.playAudio(at: localURL)
                        completion(.success(localURL))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /**
     下载远程音频文件
     
     - Parameters:
     - remoteURL: 远程音频文件的URL
     - completion: 下载完成后的回调，返回本地文件路径或错误
     */
    public func downloadRemoteAudio(from remoteURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard ["http", "https"].contains(remoteURL.scheme?.lowercased() ?? "") else {
            completion(.failure(makeError(.invalidRemoteURL)))
            return
        }
        
        cancelDownload()
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.wybasiskit.audio.download.\(UUID().uuidString)")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        
        downloadDelegate = DownloadDelegate(audioKit: self)
        downloadDelegate?.progressHandler = { [weak self] progress in
            DispatchQueue.main.async {
                self?.delegate?.remoteAudioDownloadProgressUpdated?(progress: progress)
            }
        }
        
        downloadDelegate?.completionHandler = { [weak self] result in
            DispatchQueue.main.async {
                completion(result)
                self?.downloadDelegate = nil
                self?.downloadSession = nil
                self?.downloadTask = nil
            }
        }
        
        downloadSession = URLSession(configuration: config, delegate: downloadDelegate, delegateQueue: nil)
        downloadTask = downloadSession?.downloadTask(with: remoteURL)
        downloadTask?.resume()
    }
    
    /// 取消当前下载任务
    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        downloadDelegate?.completionHandler = nil
        downloadDelegate?.progressHandler = nil
        downloadDelegate = nil
    }
    
    /**
     获取所有下载的音频文件
     
     - Returns: 下载文件URL数组（按创建日期倒序排序）
     */
    public func getAllDownloads() -> [URL] {
        return getAudioFiles(in: downloadsDirectory, subdirectory: downloadsSubdirectory)
    }
    
    /**
     删除指定的下载文件
     
     - Parameter url: 要删除的文件URL
     
     - Throws: 文件操作可能抛出错误
     */
    public func deleteDownload(at url: URL) throws {
        try deleteFile(at: url)
    }
    
    /**
     删除所有下载文件
     
     - Throws: 文件操作可能抛出错误
     */
    public func deleteAllDownloads() throws {
        try deleteAllFiles(in: downloadsDirectory, subdirectory: downloadsSubdirectory)
    }
    
    /**
     转换音频文件格式
     
     支持转换为以下格式：.aac, .m4a, .caf, .wav, .aiff
     
     - Parameters:
     - sourceURL: 源文件URL
     - targetFormat: 目标格式
     - completion: 转换完成后的回调
     */
    public func convertAudioFile(sourceURL: URL, targetFormat: WYAudioFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        let supportedFormats: [WYAudioFormat] = [.aac, .m4a, .caf, .wav, .aiff]
        guard supportedFormats.contains(targetFormat) else {
            completion(.failure(makeError(.formatNotSupported)))
            return
        }
        
        let outputURL = generateFileURL(fileName: "converted_\(UUID().uuidString)", format: targetFormat)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        convertUsingExportSession(sourceURL: sourceURL, outputURL: outputURL, targetFormat: targetFormat, completion: completion)
    }
    
    /// 释放所有资源（外部最好主动调用）
    public func releaseAll() {
        stopAllAudioActivities()
        cancelDownload()
        cleanupAudioObjects()
        
        displayLink?.invalidate()
        displayLink = nil
        
        conversionProgressTimer?.invalidate()
        conversionProgressTimer = nil
        
        cancellables.removeAll()
        
        try? recordingSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        currentRecordFileURL = nil
    }
    
    /// 音频会话
    private let recordingSession = AVAudioSession.sharedInstance()
    
    /// 显示链接 - 用于优化进度更新
    private var displayLink: CADisplayLink?
    
    /// 下载会话
    private var downloadSession: URLSession?
    
    /// 下载任务
    private var downloadTask: URLSessionDownloadTask?
    
    /// 下载代理
    private var downloadDelegate: DownloadDelegate?
    
    /// 转换进度计时器
    private var conversionProgressTimer: Timer?
    
    /// 自定义录音设置
    private var customRecordSettings: [String: Any] = [:]
    
    /// 最小录音时长（秒），0表示无限制
    private var minRecordingDuration: TimeInterval = 0
    
    /// 最大录音时长（秒），0表示无限制
    private var maxRecordingDuration: TimeInterval = 0
    
    /// 上次进度更新时间戳
    private var lastProgressUpdateTime: CFTimeInterval = 0
    
    /// 进度更新间隔（秒）
    private let progressUpdateInterval: CFTimeInterval = 0.1
    
    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 设置默认录音配置
    private func setupDefaultSettings() {
        customRecordSettings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
    }
    
    /// 初始化显示链接
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.isPaused = true
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// 设置音频中断处理
    private func setupInterruptionHandler() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAudioSessionInterruption(notification: notification)
            }
            .store(in: &cancellables)
    }
    
    /// 设置音频路由变化处理
    private func setupRouteChangeHandler() {
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.isPlaying && !self.isPlaybackPaused {
                    self.audioPlayer?.play()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 重置音频会话
    private func resetAudioSession() throws {
        do {
            try recordingSession.setActive(false, options: .notifyOthersOnDeactivation)
            try recordingSession.setCategory(.ambient, mode: .default)
        } catch {
            throw makeError(.sessionConfigurationFailed)
        }
    }
    
    /// 异步重置音频会话
    private func resetAudioSessionAsync() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                try self.recordingSession.setActive(false, options: .notifyOthersOnDeactivation)
                try self.recordingSession.setCategory(.ambient, mode: .default)
            } catch {
                self.delegate?.audioSessionConfigurationFailed?(error: error)
            }
        }
    }
    
    /// 处理音频中断
    private func handleAudioSessionInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        switch type {
        case .began:
            if isRecording && !isRecordingPaused {
                pauseRecording()
            }
            if isPlaying && !isPlaybackPaused {
                pausePlayback()
            }
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    if isRecordingPaused {
                        resumeRecording()
                    }
                    if isPlaybackPaused {
                        resumePlayback()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    /// 彻底清理音频相关对象
    private func cleanupAudioObjects() {
        audioRecorder?.delegate = nil
        audioRecorder?.stop()
        audioRecorder = nil
        
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil
        
        isRecordingPaused = false
        isPlaybackPaused = false
        
        stopRecordingProgressUpdates()
        stopPlaybackProgressUpdates()
    }
    
    /// 重置录音状态
    private func resetRecording() {
        cleanupAudioObjects()
        
        if !isRecording && !isPlaying {
            displayLink?.invalidate()
            displayLink = nil
            setupDisplayLink()
        }
    }
    
    /// 重置播放状态
    private func resetPlayback() {
        cleanupAudioObjects()
        
        if !isRecording && !isPlaying {
            displayLink?.invalidate()
            displayLink = nil
            setupDisplayLink()
        }
    }
    
    /// 停止所有音频活动（录音和播放）
    private func stopAllAudioActivities() {
        stopRecording()
        stopPlayback()
    }
    
    /// 启动录音进度更新
    private func startRecordingProgressUpdates() {
        lastProgressUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    /// 停止录音进度更新
    private func stopRecordingProgressUpdates() {
        displayLink?.isPaused = true
    }
    
    /// 启动播放进度更新
    private func startPlaybackProgressUpdates() {
        lastProgressUpdateTime = CACurrentMediaTime()
        displayLink?.isPaused = false
    }
    
    /// 停止播放进度更新
    private func stopPlaybackProgressUpdates() {
        displayLink?.isPaused = true
    }
    
    /// 处理显示链接回调
    @objc private func handleDisplayLink() {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProgressUpdateTime >= progressUpdateInterval else { return }
        
        lastProgressUpdateTime = currentTime
        
        if let recorder = audioRecorder, recorder.isRecording {
            delegate?.audioRecorderTimeUpdated?(
                currentTime: recorder.currentTime,
                duration: maxRecordingDuration
            )
            
            recorder.updateMeters()
            let peakPower = recorder.peakPower(forChannel: 0)
            delegate?.audioRecorderDidUpdateMetering?(peakPower: peakPower)
        }
        
        if let player = audioPlayer, player.isPlaying {
            let progress = player.duration > 0 ? player.currentTime / player.duration : 0
            delegate?.audioPlayerTimeUpdated?(
                currentTime: player.currentTime,
                duration: player.duration,
                progress: progress
            )
        }
    }
    
    /**
     生成录音文件URL
     
     - Parameters:
     - fileName: 自定义文件名（可选）
     - format: 音频格式
     
     - Returns: 完整的文件URL
     */
    private func generateFileURL(fileName: String?, format: WYAudioFormat) -> URL {
        let name = fileName ?? "recording_\(UUID().uuidString)"
        let directory = getDirectoryURL(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        return directory.appendingPathComponent(name).appendingPathExtension(format.stringValue)
    }
    
    /**
     获取音频格式对应的AVFoundation格式ID
     
     - Parameter format: 音频格式枚举
     
     - Returns: 对应的Core Audio格式ID
     */
    private func formatKey(for format: WYAudioFormat) -> Int {
        switch format {
        case .aac, .m4a:
            return Int(kAudioFormatMPEG4AAC)
        case .wav, .aiff:
            return Int(kAudioFormatLinearPCM)
        case .caf:
            return Int(kAudioFormatAppleIMA4)
        default:
            return Int(kAudioFormatMPEG4AAC)
        }
    }
    
    /**
     获取指定目录的URL
     
     - Parameters:
     - directory: 目录类型
     - subdirectory: 子目录名称（可选）
     
     - Returns: 目录URL
     */
    private func getDirectoryURL(for directory: WYAudioStorageDirectory, subdirectory: String?) -> URL {
        let baseURL: URL
        switch directory {
        case .temporary:
            baseURL = FileManager.default.temporaryDirectory
        case .documents:
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        case .caches:
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
        
        if let subdirectory {
            return baseURL.appendingPathComponent(subdirectory)
        }
        return baseURL
    }
    
    /**
     创建目录（如果不存在）
     
     - Parameters:
     - directory: 目录类型
     - subdirectory: 子目录名称（可选）
     
     - Returns: 是否创建成功或已存在
     */
    @discardableResult
    private func createDirectoryIfNeeded(for directory: WYAudioStorageDirectory, subdirectory: String?) -> Bool {
        let url = getDirectoryURL(for: directory, subdirectory: subdirectory)
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if exists && isDirectory.boolValue {
            return true
        }
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            delegate?.audioRecorderDidFail?(error: .directoryCreationFailed)
            return false
        }
    }
    
    /**
     获取指定目录中的音频文件
     
     - Parameters:
     - directory: 目录类型
     - subdirectory: 子目录名称（可选）
     
     - Returns: 音频文件URL数组（按创建日期倒序排序）
     */
    private func getAudioFiles(in directory: WYAudioStorageDirectory, subdirectory: String?) -> [URL] {
        let url = getDirectoryURL(for: directory, subdirectory: subdirectory)
        
        guard createDirectoryIfNeeded(for: directory, subdirectory: subdirectory) else {
            return []
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let audioExtensions = WYAudioFormat.allCases.map { $0.stringValue }
            let audioFiles = files.filter { audioExtensions.contains($0.pathExtension.lowercased()) }
            
            return audioFiles.sorted {
                let date1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1! > date2!
            }
        } catch {
            return []
        }
    }
    
    /**
     删除指定文件
     
     - Parameter url: 文件URL
     
     - Throws: 文件操作可能抛出错误
     */
    private func deleteFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw makeError(.fileNotFound)
        }
        try FileManager.default.removeItem(at: url)
    }
    
    /**
     删除指定目录中的所有文件
     
     - Parameters:
     - directory: 目录类型
     - subdirectory: 子目录名称（可选）
     
     - Throws: 文件操作可能抛出错误
     */
    private func deleteAllFiles(in directory: WYAudioStorageDirectory, subdirectory: String?) throws {
        let url = getDirectoryURL(for: directory, subdirectory: subdirectory)
        
        guard createDirectoryIfNeeded(for: directory, subdirectory: subdirectory) else {
            throw makeError(.directoryCreationFailed)
        }
        
        let files = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        for file in files {
            try FileManager.default.removeItem(at: file)
        }
    }
    
    /**
     使用 AVAssetExportSession 转换音频格式
     
     - Parameters:
     - sourceURL: 源文件URL
     - outputURL: 输出文件URL
     - targetFormat: 目标格式
     - completion: 完成回调
     */
    private func convertUsingExportSession(sourceURL: URL, outputURL: URL, targetFormat: WYAudioFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: sourceURL)
        
        let presetName: String
        switch targetFormat {
        case .aac, .m4a:
            presetName = AVAssetExportPresetAppleM4A
        case .wav, .aiff, .caf:
            presetName = AVAssetExportPresetPassthrough
        default:
            presetName = AVAssetExportPresetPassthrough
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            completion(.failure(makeError(.conversionFailed)))
            return
        }
        
        let outputFileType: AVFileType
        switch targetFormat {
        case .aac, .m4a:
            outputFileType = .m4a
        case .wav:
            outputFileType = .wav
        case .aiff:
            outputFileType = .aiff
        case .caf:
            outputFileType = .caf
        default:
            outputFileType = .m4a
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL
        
        if targetFormat == .wav || targetFormat == .aiff {
            exportSession.audioTimePitchAlgorithm = .varispeed
        }
        
        startConversionProgressMonitoring(for: exportSession)
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                
                self.conversionProgressTimer?.invalidate()
                self.conversionProgressTimer = nil
                
                switch exportSession.status {
                case .completed:
                    completion(.success(outputURL))
                    self.delegate?.conversionDidComplete?(url: outputURL)
                case .failed:
                    completion(.failure(exportSession.error ?? self.makeError(.conversionFailed)))
                case .cancelled:
                    completion(.failure(self.makeError(.conversionCancelled)))
                default:
                    completion(.failure(self.makeError(.conversionFailed)))
                }
            }
        }
    }
    
    /**
     启动转换进度监控
     
     - Parameter session: 转换会话
     */
    private func startConversionProgressMonitoring(for session: AVAssetExportSession) {
        conversionProgressTimer?.invalidate()
        conversionProgressTimer = nil
        
        conversionProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak session] _ in
            guard let self, let session else {
                self?.conversionProgressTimer?.invalidate()
                self?.conversionProgressTimer = nil
                return
            }
            
            let progress = session.progress
            self.delegate?.conversionProgressUpdated?(progress: Double(progress))
            
            if progress >= 1.0 || session.status != .exporting {
                self.conversionProgressTimer?.invalidate()
                self.conversionProgressTimer = nil
            }
        }
    }
    
    /// 创建错误对象
    private func makeError(_ type: WYAudioError) -> NSError {
        NSError(domain: "WYAudioKit", code: type.rawValue, userInfo: nil)
    }
    
    deinit {
        releaseAll()
    }
}

// MARK: - AVAudioRecorderDelegate
extension WYAudioKit: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let duration = recorder.currentTime
        
        if flag {
            if minRecordingDuration > 0 && duration < minRecordingDuration {
                try? deleteRecording()
                delegate?.audioRecorderDidFail?(error: .minDurationNotReached)
                return
            }
            
            if maxRecordingDuration > 0 && duration >= maxRecordingDuration {
                delegate?.audioRecorderDidFail?(error: .maxDurationReached)
            } else {
                delegate?.audioRecorderDidStop?()
            }
        } else {
            delegate?.audioRecorderDidFail?(error: .fileSaveFailed)
        }
        
        resetAudioSessionAsync()
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        delegate?.audioRecorderDidFail?(error: .fileSaveFailed)
    }
}

// MARK: - AVAudioPlayerDelegate
extension WYAudioKit: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            delegate?.audioPlayerDidFinishPlaying?()
        } else {
            delegate?.audioPlayerDidFail?(error: .playbackError)
        }
        resetPlayback()
        resetAudioSessionAsync()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        delegate?.audioPlayerDidFail?(error: .playbackError)
        resetPlayback()
        resetAudioSessionAsync()
    }
}

// MARK: - WYAudioFormat 扩展
extension WYAudioFormat: CaseIterable {
    public static var allCases: [WYAudioFormat] {
        return [.aac, .wav, .caf, .m4a, .aiff, .mp3, .flac, .au, .amr, .ac3, .eac3]
    }
}

// MARK: - DownloadDelegate
private extension WYAudioKit {
    class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        weak var audioKit: WYAudioKit?
        
        var progressHandler: ((Double) -> Void)?
        var completionHandler: ((Result<URL, Error>) -> Void)?
        
        init(audioKit: WYAudioKit) {
            self.audioKit = audioKit
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            guard totalBytesExpectedToWrite > 0 else { return }
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler?(progress)
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            guard let completion = completionHandler else { return }
            
            do {
                let originalURL = downloadTask.originalRequest?.url
                let directory = audioKit?.getDirectoryURL(for: audioKit?.downloadsDirectory ?? .temporary, subdirectory: audioKit?.downloadsSubdirectory) ?? FileManager.default.temporaryDirectory
                _ = audioKit?.createDirectoryIfNeeded(for: audioKit?.downloadsDirectory ?? .temporary, subdirectory: audioKit?.downloadsSubdirectory)
                
                let destinationURL = directory.appendingPathComponent(originalURL?.lastPathComponent ?? "audio_\(UUID().uuidString)")
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: location, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
            
            completionHandler = nil
            progressHandler = nil
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let completion = completionHandler else { return }
            
            if let error {
                if (error as NSError).code == NSURLErrorCancelled {
                    completion(.failure(NSError(domain: "WYAudioKit", code: WYAudioError.conversionCancelled.rawValue, userInfo: nil)))
                } else {
                    completion(.failure(error))
                }
            }
            
            completionHandler = nil
            progressHandler = nil
        }
    }
}
