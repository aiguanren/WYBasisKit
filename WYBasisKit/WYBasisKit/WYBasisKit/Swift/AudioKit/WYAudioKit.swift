//
// WYAudioKit.swift
// WYBasisKit
//
// Created by guanren on 2025/8/12.
//

import Foundation
import AVFoundation
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
 - au ：早期 UNIX 音频格式，现较少使用
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
    
    /// 获取对应格式的文件扩展名
    public var extensionName: String {
        switch self {
        case .aac, .m4a:  return "m4a"
        case .wav:        return "wav"
        case .caf:        return "caf"
        case .aiff:       return "aiff"
        case .mp3:        return "mp3"
        case .flac:       return "flac"
        case .au:         return "au"
        case .amr:        return "amr"
        case .ac3:        return "ac3"
        case .eac3:       return "eac3"
        }
    }
    
    /// 对应的 AudioFormatID（用于录音设置）
    var audioFormatID: AudioFormatID {
        switch self {
        case .aac, .m4a:   return kAudioFormatMPEG4AAC
        case .wav, .aiff:  return kAudioFormatLinearPCM
        case .caf:         return kAudioFormatAppleLossless
        default:           return kAudioFormatMPEG4AAC
        }
    }
    
    /// 对应的 AVFileType（用于格式导出/转换）
    var avFileType: AVFileType {
        switch self {
        case .aac, .m4a: return .m4a
        case .wav:       return .wav
        case .caf:       return .caf
        case .aiff:      return .aiff
        default:         return .m4a
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
@objc @frozen public enum WYAudioError: Int, Error {
    /// 开始录音失败
    case startRecordingFailed = 0
    /// 没有正在录制的音频任务
    case noAudioRecordedTasks
    /// 没有需要暂停的音频任务
    case noAudioPauseTasks
    /// 没有需要恢复录制的音频任务
    case noAudioResumeRecordTasks
    /// 删除音频(录音)文件失败
    case deleteAudioFileFailed
    /// 未申请录音权限(权限未确定)
    case notDetermined
    /// 录音权限被拒绝
    case permissionDenied
    /// 音频文件未找到
    case fileNotFound
    /// 录音文件保存失败
    case fileSaveFailed
    /// 录音正在进行中
    case recordingInProgress
    /// 录音时长未达到最小值
    case minDurationNotReached
    /// 录音时长已达到最大值
    case maxDurationReached
    /// 正在播放音频文件
    case isPlayingAudio
    /// 播放错误
    case playbackError
    /// 没有正在播放的音频
    case noPlayedAudio
    /// 没有可以暂停播放的音频
    case noAudioToPause
    /// 没有可以恢复播放的音频任务
    case noAudioResumePlayTasks
    /// 没有可以停止播放的音频任务
    case noAudioStopPlayTasks
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
    /// 音频会话配置失败
    case sessionConfigurationFailed
    /// 目录创建失败
    case directoryCreationFailed
}

/// 音频播放状态
@objc @frozen public enum WYAudioPlayState: Int {
    /// 开始播放
    case start = 0
    /// 暂停播放
    case pause
    /// 恢复播放
    case resume
    /// 停止播放
    case stop
    /// 完成播放
    case finish
}

/// 网络下载(音频)文件的远程和本地URL信息
public class WYAudioDownloadInfo: NSObject {
    
    /// 远程URL
    public let remote: URL
    /// 本地URL
    public let local: URL
    
    /// 唯一初始化方法
    public init(remote: URL, local: URL) {
        self.remote = remote
        self.local = local
    }
}

/// 音频工具类代理协议
@objc public protocol WYAudioKitDelegate {
    
    /**
     录音开始
     - Parameters:
     - audioKit: 音频工具实例
     - isResume: 是否是恢复录音
     */
    @objc(wy_audioRecorderDidStart:isResume:)
    optional func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool)
    
    /**
     录音停止
     - Parameters:
     - audioKit: 音频工具实例
     - isPause: 是否是暂停录音
     */
    @objc(wy_audioRecorderDidStop:isPause:)
    optional func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool)
    
    /**
     录音时间更新
     - Parameters:
     - audioKit: 音频工具实例
     - currentTime: 当前录音时间（秒）
     - duration: 总录音时长限制（秒）
     */
    @objc(wy_audioRecorderTimeUpdated:currentTime:duration:)
    optional func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval)
    
    /**
     录音声波数据更新（单通道）
     - Parameters:
     - audioKit: 音频工具实例
     - peakPower: 当前峰值功率（dB），范围 -160.0 到 0.0（0.0 表示最响，-160.0 表示最安静）；适合用于实时响应敏感的声波动画，但可能导致动画跳动剧烈
     - averagePower: 当前平均功率（dB），范围 -160.0 到 0.0；比 peakPower 更平滑，适合语音录制页面的声波动画
     */
    @objc(wy_audioRecorderDidUpdateMetering:peakPower:averagePower:)
    optional func wy_audioRecorderDidUpdateMetering(audioKit: WYAudioKit, peakPower: Float, averagePower: Float)
    
    /**
     录音声波数据更新（多通道，归一化 0.0 ~ 1.0）
     - Parameters:
     - audioKit: 音频工具实例
     - normalizedPeaks: 当前各通道的归一化峰值幅度数组（0.0 ~ 1.0，0.0 最安静，1.0 最响）；适合直接用于声波动画、音量条等 UI 显示
     - normalizedAverages: 当前各通道的归一化平均幅度数组（0.0 ~ 1.0）；更平滑，推荐用于语音录制波形动画
     */
    @objc(wy_audioRecorderDidUpdateMeterings:peakPowers:averagePowers:)
    optional func wy_audioRecorderDidUpdateMeterings(audioKit: WYAudioKit, peakPowers: [Float], averagePowers: [Float])
    
    /**
     播放状态发生改变
     - Parameters:
     - audioKit: 音频工具实例
     - state: 播放状态
     */
    @objc(wy_audioPlayerStateDidChanged:state:)
    optional func wy_audioPlayerStateDidChanged(audioKit: WYAudioKit, state: WYAudioPlayState)
    
    /**
     播放进度更新
     - Parameters:
     - audioKit: 音频工具实例
     - localUrl: 正在播放的本地音频文件的URL
     - currentTime: 当前播放位置（秒）
     - duration: 音频总时长（秒）
     - progress: 播放进度百分比（0.0 - 1.0）
     */
    @objc(wy_audioPlayerTimeUpdated:localUrl:currentTime:duration:progress:)
    optional func wy_audioPlayerTimeUpdated(audioKit: WYAudioKit, localUrl: URL, currentTime: TimeInterval, duration: TimeInterval, progress: Double)
    
    /**
     网络音频下载进度更新
     - Parameters:
     - audioKit: 音频工具实例
     - remoteUrls: 下载中的URL进度信息(如果数量为1则表示单条音频进度更新，否则为多条并发进度)
     - progress: 下载进度百分比（0.0 - 1.0）
     */
    @objc(wy_remoteAudioDownloadProgressUpdated:remoteUrls:progress:)
    optional func wy_remoteAudioDownloadProgressUpdated(audioKit: WYAudioKit, remoteUrls: [URL], progress: Double)
    
    /**
     网络音频下载成功
     - Parameters:
     - audioKit: 音频工具实例
     - fileInfos: 下载成功的文件信息数组(单条或多条)
     */
    @objc(wy_remoteAudioDownloadSuccess:fileInfo:)
    optional func wy_remoteAudioDownloadSuccess(audioKit: WYAudioKit, fileInfos: [WYAudioDownloadInfo])
    
    /**
     网络音频下载暂停
     - Parameters:
     - audioKit: 音频工具实例
     - remoteUrls: 被暂停的远程 URL 数组（用户传入的原始 URL）
     */
    @objc(wy_remoteAudioDownloadPaused:remoteUrls:)
    optional func wy_remoteAudioDownloadPaused(audioKit: WYAudioKit, remoteUrls: [URL])
    
    /**
     网络音频下载恢复
     - Parameters:
     - audioKit: 音频工具实例
     - remoteUrls: 被恢复的远程 URL 数组（用户传入的原始 URL）
     */
    @objc(wy_remoteAudioDownloadResumed:remoteUrls:)
    optional func wy_remoteAudioDownloadResumed(audioKit: WYAudioKit, remoteUrls: [URL])
    
    /**
     格式转换进度更新
     - Parameters:
     - audioKit: 音频工具实例
     - localUrls: 正在转换的本地URL数组
     - progress: 转换进度百分比（0.0 - 1.0）
     */
    @objc(wy_formatConversionProgressUpdated:localUrls:progress:)
    optional func wy_formatConversionProgressUpdated(audioKit: WYAudioKit, localUrls: [URL], progress: Double)
    
    /**
     格式转换完成
     - Parameters:
     - audioKit: 音频工具实例
     - outputUrls: 转换成功后的输出文件URL数组
     */
    @objc(wy_formatConversionDidCompleted:outputUrls:)
    optional func wy_formatConversionDidCompleted(audioKit: WYAudioKit, outputUrls: [URL])
    
    /**
     音频任务执行失败
     - Parameters:
     - audioKit: 音频工具实例
     - url: 出错的任务相关URL（可能是本地或远程）
     - error: 错误枚举值
     - description: 可选的详细错误描述
     */
    @objc(wy_audioTaskDidFailed:url:error:description:)
    optional func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL, error: WYAudioError, description: String?)
}

// MARK: - 批量任务辅助结构（内部使用）
private struct DownloadBatch {
    var remoteUrls: [URL]
    let success: ([WYAudioDownloadInfo]) -> Void
    let failed: (Error?) -> Void
    var pendingUrls: Set<URL>
    var infos: [WYAudioDownloadInfo] = []
    var hasFailed: Bool = false
}

private struct ConvertBatch {
    let sourceUrls: [URL]
    let success: ([URL]) -> Void
    let failed: (Error?) -> Void
    var pendingUrls: Set<URL>
    var outputUrls: [URL] = []
    var hasFailed: Bool = false
}

// MARK: - 下载任务信息（内部使用）
private struct DownloadTaskInfo {
    let originalURL: URL
    var currentURL: URL
    let batchID: UUID
    var progress: Double = 0.0
    var task: URLSessionDownloadTask?
    var resumeData: Data?
}

/**
 音频工具类 - 提供高性能、功能完备的录音、播放、下载、转换与文件管理能力
 
 主要功能：
 - 录音控制：开始、暂停、恢复、停止，支持最小/最大时长限制、自定义文件名与格式
 - 播放控制：本地/网络音频播放、暂停、恢复、停止、精确seek跳转，支持倍速调节（0.5x ~ 2.0x）
 - 网络音频处理：并发多文件下载、精准进度回调、暂停/恢复/取消、边下边播（流式播放）
 - 文件管理：录音/下载文件自动目录管理、列表获取（按时间排序）、保存、删除、音频时长读取
 - 播放高级特性：基于 AVPlayer，支持流式播放
 - 格式转换：支持多文件并发转换（aac/m4a/caf/wav/aiff 等），可中断
 
 使用建议：
 - 初始化后可直接使用公开属性与方法
 - 推荐设置 delegate 接收实时回调（录音波形、播放进度、下载状态等）
 - 不再使用时主动调用 releaseAll() 释放资源，避免内存泄漏
 */
public final class WYAudioKit: NSObject,
                               AVAudioRecorderDelegate,
                               URLSessionDownloadDelegate,
                               URLSessionTaskDelegate {
    
    /// 代理对象，用于回调录音、播放、下载、转换等事件
    public weak var delegate: WYAudioKitDelegate?
    
    /// 是否正在录音
    public var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    /// 是否正在播放
    public var isPlaying: Bool {
        guard let player = audioPlayer else { return false }
        return player.rate != 0 && player.timeControlStatus == .playing
    }
    
    /// 录音是否处于暂停状态
    public private(set) var isRecordingPaused: Bool = false
    
    /// 播放是否处于暂停状态
    public private(set) var isPlaybackPaused: Bool = false
    
    /// 录音最小有效时长（秒），低于此值停止时会自动删除文件，0 表示无限制
    public var minimumRecordDuration: TimeInterval = 0
    
    /// 录音最大允许时长（秒），到达后自动停止录音，0 表示无限制
    public var maximumRecordDuration: TimeInterval = 0
    
    /// 设置音频播放速率 0.5x ~ 2.0x
    public var playbackRate: Float = 1.0 {
        didSet {
            if playbackRate < 0.5 { playbackRate = 0.5 }
            if playbackRate > 2.0 { playbackRate = 2.0 }
            audioPlayer?.rate = playbackRate
        }
    }
    
    /**
     设置音频质量等级（影响比特率、采样率等，默认中等）
     - Parameters:
     - quality: AVAudioQuality 枚举值，会影响默认比特率和采样质量
     */
    public var recordQuality: AVAudioQuality = .medium
    
    /**
     设置自定义录音参数
     - Parameter settings: 录音参数字典，会与默认设置合并（自定义优先）
     常用键值:
     - AVFormatIDKey: 音频格式
     - AVSampleRateKey: 采样率
     - AVNumberOfChannelsKey: 通道数
     - AVEncoderAudioQualityKey: 编码质量
     - AVEncoderBitRateKey: 比特率
     */
    public var recordSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        AVEncoderBitRateKey: 128_000
    ]
    
    /// 当前正在录制的音频文件本地URL（录音开始后设置，停止后保留直到下次录音）
    public internal(set) var currentRecordFileURL: URL?
    
    /// 录音文件存储的目录类型（修改后会自动创建目录）
    public var recordingsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件存储的目录类型（修改后会自动创建目录）
    public var downloadsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 录音文件存放的子目录名称（nil 表示直接放在根目录）
    public var recordingsSubdirectory: String? = "Recordings" {
        didSet {
            if recordingDirectoryURL != nil {
                recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
            }
        }
    }
    
    /// 下载文件存放的子目录名称（nil 表示直接放在根目录）
    public var downloadsSubdirectory: String? = "Downloads" {
        didSet {
            if downloadsDirectoryURL != nil {
                downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
            }
        }
    }
    
    // MARK: - 私有属性
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVPlayer?
    private var displayLink: CADisplayLink?
    private var playerObservation: NSKeyValueObservation?
    private var playerTimeObserver: Any?
    private var currentPlaybackURL: URL?
    private var recordChannelCount: Int = 2
    private var isInitializingPlayer: Bool = false
    
    private var recordingDirectoryURL: URL!
    private var downloadsDirectoryURL: URL!
    
    // 下载管理（重构后）
    private var downloadSession: URLSession!
    private var tasksInfo: [URL: DownloadTaskInfo] = [:]      // 原始URL -> 任务信息（仅活跃任务）
    private var downloadGroups: [UUID: DownloadBatch] = [:]
    private var downloadProgresses: [URL: Double] = [:]       // 当前URL -> 进度（用于展示）
    private var pausedTaskInfo: [URL: DownloadTaskInfo] = [:]  // 暂停的任务信息（原始URL -> 任务信息）
    private var pausedBatchID: [URL: UUID] = [:]               // 原始URL -> batchID
    private var downloadMapping: [String: String] = [:]        // 本地路径 -> 远程URL字符串
    
    // 格式转换相关
    private var convertGroups: [UUID: ConvertBatch] = [:]
    private var convertSessions: [URL: AVAssetExportSession] = [:]
    private var convertProgresses: [URL: Float] = [:]
    
    // 流式播放相关
    private var streamingObservation: NSKeyValueObservation?
    
    /// 唯一初始化方法
    public override init() {
        super.init()
        
        setupAudioSession()
        recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        setupDownloadSession()
        loadDownloadMapping()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 13.0, *) {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker, .allowAirPlay])
            } else {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            }
            try session.setActive(true)
        } catch {
            delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                             url: URL(fileURLWithPath: ""),
                                             error: .sessionConfigurationFailed,
                                             description: "音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    private func setupDownloadSession() {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        downloadSession = URLSession(configuration: config,
                                     delegate: self,
                                     delegateQueue: OperationQueue.main)
    }
    
    private func createDirectory(for type: WYAudioStorageDirectory, subdirectory: String?) -> URL {
        let fileManager = FileManager.default
        var baseURL: URL
        switch type {
        case .temporary:
            baseURL = fileManager.temporaryDirectory
        case .documents:
            baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .caches:
            baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }
        let targetURL = subdirectory.map { baseURL.appendingPathComponent($0) } ?? baseURL
        if !fileManager.fileExists(atPath: targetURL.path) {
            do {
                try fileManager.createDirectory(at: targetURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                                 url: targetURL,
                                                 error: .directoryCreationFailed,
                                                 description: "目录创建失败: \(error.localizedDescription)")
            }
        }
        return targetURL
    }
    
    // MARK: - 录音核心方法
    
    /**
     开始录音
     - Parameters:
     - fileName: 自定义文件名（可选，不传则自动生成带时间戳的名字）
     - format: 录音格式（默认 .aac）
     - Throws: WYAudioError（权限、格式、正在录音等异常）
     */
    public func startRecording(fileName: String? = nil, format: WYAudioFormat = .aac) throws {
        
        if isRecording {
            throw WYAudioError.recordingInProgress
        }
        
        let permission = AVAudioSession.sharedInstance().recordPermission
        if permission == .denied {
            throw WYAudioError.permissionDenied
        }
        if permission == .undetermined {
            throw WYAudioError.notDetermined
        }
        
        let finalFileName: String
        if let name = fileName, !name.isEmpty {
            finalFileName = name
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            finalFileName = "record_\(formatter.string(from: Date()))"
        }
        let ext = format.extensionName
        let fileURL = recordingDirectoryURL.appendingPathComponent("\(finalFileName).\(ext)")
        
        var settings = recordSettings
        settings[AVFormatIDKey] = format.audioFormatID
        
        if format == .wav || format == .aiff {
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsNonInterleaved] = false
        } else if format == .caf {
            settings[AVEncoderAudioQualityKey] = recordQuality.rawValue
        }
        
        recordChannelCount = settings[AVNumberOfChannelsKey] as? Int ?? 2
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            if !audioRecorder!.record() {
                throw WYAudioError.startRecordingFailed
            }
            
            currentRecordFileURL = fileURL
            isRecordingPaused = false
            
            startDisplayLinkIfNeeded()
            
            delegate?.wy_audioRecorderDidStart?(audioKit: self, isResume: false)
        } catch {
            throw WYAudioError.startRecordingFailed
        }
    }
    
    /// 暂停当前录音
    public func pauseRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return
        }
        recorder.pause()
        isRecordingPaused = true
        delegate?.wy_audioRecorderDidStop?(audioKit: self, isPause: true)
    }
    
    /// 恢复已暂停的录音
    public func resumeRecording() {
        guard let recorder = audioRecorder, isRecordingPaused else {
            return
        }
        recorder.record()
        isRecordingPaused = false
        startDisplayLinkIfNeeded()
        delegate?.wy_audioRecorderDidStart?(audioKit: self, isResume: true)
    }
    
    /// 停止录音（会检查最小时长，不满足设置则会自动删除文件）
    public func stopRecording() {
        guard let recorder = audioRecorder else {
            return
        }
        
        let duration = recorder.currentTime
        recorder.stop()
        isRecordingPaused = false
        audioRecorder = nil
        
        delegate?.wy_audioRecorderDidStop?(audioKit: self, isPause: false)
        
        if minimumRecordDuration > 0 && duration < minimumRecordDuration {
            deleteRecordingFile(localUrl: currentRecordFileURL)
            delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                             url: currentRecordFileURL ?? URL(fileURLWithPath: ""),
                                             error: .minDurationNotReached,
                                             description: "录音时长未达到最小值，已自动删除文件")
            currentRecordFileURL = nil
            return
        }
        
        stopDisplayLinkIfNeeded()
    }
    
    // MARK: - 播放核心方法
    
    /**
     开始播放本地音频文件
     - Parameters:
     - url: 要播放的音频文件URL，为 nil 则播放当前录音文件（currentRecordFileURL）
     */
    public func playPlayback(url: URL? = nil) {
        let targetURL = url ?? currentRecordFileURL
        guard let playURL = targetURL else {
            return
        }
        
        if currentPlaybackURL == playURL && isPlaying {
            return
        }
        
        isInitializingPlayer = true
        stopPlayback()
        
        let playerItem = AVPlayerItem(url: playURL)
        audioPlayer = AVPlayer(playerItem: playerItem)
        currentPlaybackURL = playURL
        audioPlayer?.rate = playbackRate
        
        // 确保 DisplayLink 启动以更新进度
        startDisplayLinkIfNeeded()
        
        playerObservation = audioPlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handlePlayerStatusChange(player.timeControlStatus)
        }
        
        addPlaybackEndObserver()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, let player = self.audioPlayer else { return }
            self.isInitializingPlayer = false
            
            if player.currentItem?.status == .readyToPlay {
                player.play()
                self.startDisplayLinkIfNeeded()
            } else {
                let observation = player.currentItem?.observe(\.status, options: [.new]) { item, _ in
                    if item.status == .readyToPlay {
                        player.play()
                        self.startDisplayLinkIfNeeded()
                    } else if item.status == .failed {
                        self.delegate?.wy_audioTaskDidFailed?(audioKit: self, url: playURL, error: .playbackError, description: item.error?.localizedDescription)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    observation?.invalidate()
                }
            }
        }
    }
    
    private func handlePlayerStatusChange(_ status: AVPlayer.TimeControlStatus) {
        if isInitializingPlayer { return }
        
        switch status {
        case .playing:
            isPlaybackPaused = false
            delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .start)
            startDisplayLinkIfNeeded()
        case .paused:
            isPlaybackPaused = true
            delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .pause)
        default:
            break
        }
    }
    
    private func addPlaybackEndObserver() {
        guard let player = audioPlayer else { return }
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                                            queue: .main) { [weak self] time in
            guard let self = self,
                  let item = player.currentItem,
                  item.duration.isValid,
                  item.duration.seconds > 0 else { return }
            
            let current = time.seconds
            let total = item.duration.seconds
            
            if current >= total - 0.02 {
                self.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .finish)
                self.stopPlayback()
            }
        }
    }
    
    /// 暂停当前播放
    public func pausePlayback() {
        guard let player = audioPlayer, isPlaying else { return }
        player.pause()
        isPlaybackPaused = true
        delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .pause)
    }
    
    /// 恢复已暂停的播放
    public func resumePlayback() {
        guard let player = audioPlayer, isPlaybackPaused else { return }
        player.rate = playbackRate
        isPlaybackPaused = false
        delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .resume)
    }
    
    /// 停止当前播放并重置状态
    public func stopPlayback() {
        if let observer = playerTimeObserver {
            audioPlayer?.removeTimeObserver(observer)
            playerTimeObserver = nil
        }
        
        playerObservation?.invalidate()
        playerObservation = nil
        
        audioPlayer?.pause()
        audioPlayer?.replaceCurrentItem(with: nil)
        audioPlayer = nil
        currentPlaybackURL = nil
        isPlaybackPaused = false
        isInitializingPlayer = false
        
        delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .stop)
        stopDisplayLinkIfNeeded()
    }
    
    /**
     跳转到指定播放时间点（支持暂停状态下跳转）
     - Parameters:
     - time: 目标播放时间（秒），会自动限制在有效范围内
     */
    public func seekPlayback(time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let duration = player.currentItem?.duration.seconds ?? 0
        let clampedTime = max(0, min(time, duration))
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    // MARK: - 网络音频处理
    
    /**
     播放网络音频文件（先下载后播放）
     - Parameters:
     - remoteUrl: 远程音频 URL
     - success: 下载并播放成功回调
     - failed: 下载或播放失败回调
     */
    public func playRemoteAudio(remoteUrl: URL,
                                success: @escaping (WYAudioDownloadInfo) -> Void,
                                failed: @escaping (Error?) -> Void) {
        print("🎵 [WYAudioKit] 请求播放远程音频: \(remoteUrl)")
        
        downloadRemoteAudio(remoteUrls: [remoteUrl]) { [weak self] infos in
            guard let first = infos.first else {
                print("❌ [WYAudioKit] 下载成功但 infos 为空")
                failed(WYAudioError.fileNotFound)
                return
            }
            print("✅ [WYAudioKit] 下载成功，准备播放: \(first.local.lastPathComponent)")
            success(first)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard let self = self else { return }
                if FileManager.default.fileExists(atPath: first.local.path) {
                    self.playPlayback(url: first.local)
                } else {
                    let error = WYAudioError.fileNotFound
                    self.delegate?.wy_audioTaskDidFailed?(audioKit: self, url: first.local, error: error, description: "下载文件不存在")
                    failed(error)
                }
            }
        } failed: { error in
            print("❌ [WYAudioKit] 下载失败: \(error?.localizedDescription ?? "未知错误")")
            failed(error)
        }
    }
    
    /**
     下载远程音频文件（支持并发多任务）
     - Parameters:
     - remoteUrls: 要下载的远程 URL 数组
     - success: 下载成功回调（返回下载信息数组）
     - failed: 下载失败回调
     */
    public func downloadRemoteAudio(remoteUrls: [URL],
                                    success: @escaping ([WYAudioDownloadInfo]) -> Void,
                                    failed: @escaping (Error?) -> Void) {
        guard !remoteUrls.isEmpty else {
            failed(nil)
            return
        }
        
        print("🚀 [WYAudioKit] 开始下载 \(remoteUrls.count) 个文件")
        
        // 启动 DisplayLink 以更新下载进度
        startDisplayLinkIfNeeded()
        
        let batchID = UUID()
        var batch = DownloadBatch(remoteUrls: remoteUrls,
                                  success: success,
                                  failed: failed,
                                  pendingUrls: Set(remoteUrls))
        downloadGroups[batchID] = batch
        
        for originalURL in remoteUrls {
            // 清除该URL的所有旧状态（避免残留数据干扰）
            if let oldInfo = tasksInfo[originalURL] {
                oldInfo.task?.cancel()
                tasksInfo.removeValue(forKey: originalURL)
                downloadProgresses.removeValue(forKey: oldInfo.currentURL)
            }
            if let oldPausedInfo = pausedTaskInfo[originalURL] {
                oldPausedInfo.task?.cancel()
                pausedTaskInfo.removeValue(forKey: originalURL)
                downloadProgresses.removeValue(forKey: oldPausedInfo.currentURL)
            }
            // 清除暂停相关数据
            pausedBatchID.removeValue(forKey: originalURL)
            
            // 强制重置进度显示
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                            remoteUrls: [originalURL],
                                                            progress: 0.0)
            
            // 创建新任务信息
            var info = DownloadTaskInfo(originalURL: originalURL,
                                        currentURL: originalURL,
                                        batchID: batchID,
                                        progress: 0.0)
            let task = downloadSession.downloadTask(with: originalURL)
            task.resume()
            info.task = task
            tasksInfo[originalURL] = info
            downloadProgresses[originalURL] = 0.0
            
            print("▶️ [WYAudioKit] 开始下载: \(originalURL)")
        }
    }
    
    /**
     暂停指定的远程下载任务
     - Parameter remoteUrls: 要暂停的 URL 数组，nil 表示暂停所有
     */
    public func pauseDownload(_ remoteUrls: [URL]?) {
        var pausedUrls: [URL] = []
        let urls = remoteUrls ?? Array(tasksInfo.keys)
        
        for originalURL in urls {
            guard let info = tasksInfo[originalURL], let task = info.task else {
                if remoteUrls != nil {
                    print("⚠️ [WYAudioKit] 无法暂停 \(originalURL)：任务不存在或已暂停")
                }
                continue
            }
            
            // 保存 batchID 以便恢复
            pausedBatchID[originalURL] = info.batchID
            // 将任务从活跃字典移到暂停字典
            tasksInfo.removeValue(forKey: originalURL)
            pausedTaskInfo[originalURL] = info
            
            task.cancel { [weak self] resumeData in
                guard let self = self, let data = resumeData else { return }
                guard var pausedInfo = self.pausedTaskInfo[originalURL] else { return }
                pausedInfo.resumeData = data
                pausedInfo.task = nil
                self.pausedTaskInfo[originalURL] = pausedInfo
                pausedUrls.append(originalURL)
                print("⏸️ [WYAudioKit] 暂停下载: \(originalURL)")
            }
        }
        
        if !pausedUrls.isEmpty {
            delegate?.wy_remoteAudioDownloadPaused?(audioKit: self, remoteUrls: pausedUrls)
        }
    }
    
    /**
     恢复指定的远程下载任务
     - Parameter remoteUrls: 要恢复的 URL 数组，nil 表示恢复所有
     */
    public func resumeDownload(_ remoteUrls: [URL]?) {
        var resumedUrls: [URL] = []
        let urls = remoteUrls ?? Array(pausedTaskInfo.keys)
        
        for originalURL in urls {
            guard var info = pausedTaskInfo[originalURL],
                  let resumeData = info.resumeData,
                  let batchID = pausedBatchID[originalURL] else {
                print("⚠️ [WYAudioKit] 无法恢复 \(originalURL)：缺少恢复数据或任务信息")
                continue
            }
            
            let task = downloadSession.downloadTask(withResumeData: resumeData)
            task.resume()
            
            // 恢复任务信息
            info.task = task
            info.resumeData = nil
            tasksInfo[originalURL] = info
            // 确保进度字典中有正确的进度值
            downloadProgresses[originalURL] = info.progress
            
            // 清理暂停数据
            pausedTaskInfo.removeValue(forKey: originalURL)
            pausedBatchID.removeValue(forKey: originalURL)
            
            resumedUrls.append(originalURL)
            print("▶️ [WYAudioKit] 恢复下载: \(originalURL)")
        }
        
        if !resumedUrls.isEmpty {
            delegate?.wy_remoteAudioDownloadResumed?(audioKit: self, remoteUrls: resumedUrls)
        }
    }
    
    /**
     取消指定的远程下载任务
     - Parameter remoteUrls: 要取消的 URL 数组，nil 表示取消所有
     */
    public func cancelDownload(_ remoteUrls: [URL]?) {
        let urls = remoteUrls ?? Array(tasksInfo.keys) + Array(pausedTaskInfo.keys)
        var canceledUrls: [URL] = []
        
        for originalURL in Set(urls) {
            var info: DownloadTaskInfo?
            if let activeInfo = tasksInfo[originalURL] {
                info = activeInfo
                tasksInfo.removeValue(forKey: originalURL)
            } else if let pausedInfo = pausedTaskInfo[originalURL] {
                info = pausedInfo
                pausedTaskInfo.removeValue(forKey: originalURL)
            }
            
            guard let taskInfo = info else { continue }
            taskInfo.task?.cancel()
            
            // 清理批次
            if let batchID = taskInfo.batchID as UUID?,
               var batch = downloadGroups[batchID] {
                batch.pendingUrls.remove(originalURL)
                if !batch.hasFailed {
                    batch.hasFailed = true
                    batch.failed(WYAudioError.downloadFailed)
                }
                downloadGroups[batchID] = batch
                if batch.pendingUrls.isEmpty {
                    downloadGroups.removeValue(forKey: batchID)
                }
            }
            
            // 移除所有相关状态
            downloadProgresses.removeValue(forKey: taskInfo.currentURL)
            downloadProgresses.removeValue(forKey: originalURL)
            pausedBatchID.removeValue(forKey: originalURL)
            
            // 通知进度为0
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                            remoteUrls: [originalURL],
                                                            progress: 0.0)
            canceledUrls.append(originalURL)
            print("❌ [WYAudioKit] 取消下载: \(originalURL)")
        }
    }
    
    // MARK: - URLSessionTaskDelegate (处理重定向)
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {
        guard let newURL = request.url,
              let originalRemote = (tasksInfo.first { $0.value.task === task })?.key ??
                                  (pausedTaskInfo.first { $0.value.task === task })?.key else {
            completionHandler(request)
            return
        }
        
        print("🔁 [WYAudioKit] 重定向: \(originalRemote) -> \(newURL)")
        
        if originalRemote == newURL {
            completionHandler(request)
            return
        }
        
        // 更新任务信息中的当前URL
        if var info = tasksInfo[originalRemote] {
            info.currentURL = newURL
            tasksInfo[originalRemote] = info
            // 更新进度映射
            if let progress = downloadProgresses[originalRemote] {
                downloadProgresses.removeValue(forKey: originalRemote)
                downloadProgresses[newURL] = progress
            }
        } else if var info = pausedTaskInfo[originalRemote] {
            info.currentURL = newURL
            pausedTaskInfo[originalRemote] = info
            // 暂停中的任务也可能有进度映射（如已暂停但未恢复）
            if let progress = downloadProgresses[originalRemote] {
                downloadProgresses.removeValue(forKey: originalRemote)
                downloadProgresses[newURL] = progress
            }
        }
        
        completionHandler(request)
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard let originalURL = tasksInfo.first(where: { $0.value.task === downloadTask })?.key,
              var info = tasksInfo[originalURL] else {
            print("⚠️ [WYAudioKit] 下载进度回调中找不到任务")
            return
        }
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        info.progress = progress
        tasksInfo[originalURL] = info
        downloadProgresses[info.currentURL] = progress
    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        guard let originalURL = tasksInfo.first(where: { $0.value.task === downloadTask })?.key,
              var info = tasksInfo[originalURL],
              var batch = downloadGroups[info.batchID] else {
            print("❌ [WYAudioKit] didFinishDownloadingTo 无法找到对应的任务或批次")
            return
        }
        
        let fm = FileManager.default
        let destination = downloadsDirectoryURL.appendingPathComponent(info.currentURL.lastPathComponent)
        
        do {
            if !fm.fileExists(atPath: destination.deletingLastPathComponent().path) {
                try fm.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            }
            
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            try fm.copyItem(at: location, to: destination)
            
            guard fm.fileExists(atPath: destination.path),
                  let attr = try? fm.attributesOfItem(atPath: destination.path),
                  (attr[.size] as? Int64 ?? 0) > 0 else {
                throw NSError(domain: "WYAudioKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载文件无效或为空"])
            }
            
            let downloadInfo = WYAudioDownloadInfo(remote: info.currentURL, local: destination)
            batch.infos.append(downloadInfo)
            saveDownloadMapping(remote: info.currentURL, local: destination)
            
            batch.pendingUrls.remove(originalURL)
            downloadGroups[info.batchID] = batch
            downloadProgresses[info.currentURL] = 1.0
            info.progress = 1.0
            tasksInfo[originalURL] = info
            
            // 立即通知完成进度
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                            remoteUrls: batch.remoteUrls,
                                                            progress: 1.0)
            print("✅ [WYAudioKit] 下载完成: \(destination.lastPathComponent)")
            
            if batch.pendingUrls.isEmpty {
                print("🎉 [WYAudioKit] 批次下载全部完成，回调 success")
                batch.success(batch.infos)
                downloadGroups.removeValue(forKey: info.batchID)
                tasksInfo.removeValue(forKey: originalURL)
            }
        } catch {
            print("❌ [WYAudioKit] 保存下载文件失败: \(error)")
            batch.hasFailed = true
            batch.failed(error)
            downloadGroups[info.batchID] = batch
        }
        
        // 清理任务引用
        tasksInfo[originalURL]?.task = nil
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error,
           let originalURL = tasksInfo.first(where: { $0.value.task === task })?.key,
           var info = tasksInfo[originalURL],
           var batch = downloadGroups[info.batchID] {
            print("❌ [WYAudioKit] 下载任务失败: \(originalURL) - \(error)")
            batch.pendingUrls.remove(originalURL)
            if !batch.hasFailed {
                batch.hasFailed = true
                batch.failed(error)
            }
            downloadGroups[info.batchID] = batch
            tasksInfo.removeValue(forKey: originalURL)
        }
    }
    
    // MARK: - 文件管理
    
    /**
     保存当前录音文件到指定位置
     - Parameter destinationUrl: 目标保存路径
     */
    public func saveRecording(destinationUrl: URL) {
        guard let source = currentRecordFileURL else { return }
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationUrl.path) {
                try fm.removeItem(at: destinationUrl)
            }
            try fm.copyItem(at: source, to: destinationUrl)
        } catch {
            delegate?.wy_audioTaskDidFailed?(audioKit: self,
                                             url: destinationUrl,
                                             error: .fileSaveFailed,
                                             description: "保存录音文件失败: \(error.localizedDescription)")
        }
    }
    
    /**
     获取所有已保存的录音文件（按创建时间倒序）
     - Returns: 文件 URL 数组
     */
    public func getAllRecordingsFiles() -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: recordingDirectoryURL,
                                                         includingPropertiesForKeys: [.creationDateKey],
                                                         options: [.skipsHiddenFiles]) else {
            return []
        }
        return contents.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /**
     删除录音文件
     - Parameter localUrl: 要删除的具体文件 URL，nil 表示删除所有录音文件
     */
    public func deleteRecordingFile(localUrl: URL? = nil) {
        let fm = FileManager.default
        if let url = localUrl {
            try? fm.removeItem(at: url)
            if currentRecordFileURL == url {
                currentRecordFileURL = nil
            }
        } else {
            if let contents = try? fm.contentsOfDirectory(at: recordingDirectoryURL, includingPropertiesForKeys: nil) {
                for url in contents {
                    try? fm.removeItem(at: url)
                }
            }
            currentRecordFileURL = nil
        }
    }
    
    /**
     获取所有已下载的音频文件信息（按创建时间倒序）
     - Returns: 下载信息数组（remote 通过持久化映射获取，若无则为占位符）
     */
    public func getAllDownloads() -> [WYAudioDownloadInfo] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: downloadsDirectoryURL,
                                                         includingPropertiesForKeys: [.creationDateKey],
                                                         options: [.skipsHiddenFiles]) else {
            return []
        }
        
        let sorted = contents.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        var infos: [WYAudioDownloadInfo] = []
        for url in sorted {
            let remoteString = downloadMapping[url.path] ?? "https://placeholder.unknown"
            let remote = URL(string: remoteString) ?? URL(string: "https://placeholder.unknown")!
            infos.append(WYAudioDownloadInfo(remote: remote, local: url))
        }
        return infos
    }
    
    /**
     删除已下载的音频文件
     - Parameter info: 要删除的下载信息，nil 表示删除所有下载文件
     */
    public func deleteDownloadFile(info: WYAudioDownloadInfo?) {
        let fm = FileManager.default
        if let info = info {
            try? fm.removeItem(at: info.local)
            downloadMapping.removeValue(forKey: info.local.path)
            UserDefaults.standard.set(downloadMapping, forKey: "WYAudioKitDownloadMapping")
        } else {
            if let contents = try? fm.contentsOfDirectory(at: downloadsDirectoryURL, includingPropertiesForKeys: nil) {
                for url in contents {
                    try? fm.removeItem(at: url)
                    downloadMapping.removeValue(forKey: url.path)
                }
            }
            UserDefaults.standard.set(downloadMapping, forKey: "WYAudioKitDownloadMapping")
        }
    }
    
    // MARK: - 格式转换
    
    /**
     转换音频文件格式（支持多文件并发）
     支持转换为：aac, m4a, caf, wav, aiff
     - Parameters:
     - sourceUrls: 源文件 URL 数组
     - target: 目标格式
     - success: 转换成功回调，返回输出文件 URL 数组
     - failed: 转换失败回调
     */
    public func convertAudioFormat(sourceUrls: [URL],
                                   target: WYAudioFormat,
                                   success: @escaping ([URL]) -> Void,
                                   failed: @escaping (Error?) -> Void) {
        guard !sourceUrls.isEmpty else {
            failed(nil)
            return
        }
        
        let supportedTargets: [WYAudioFormat] = [.aac, .m4a, .caf, .wav, .aiff]
        guard supportedTargets.contains(target) else {
            failed(WYAudioError.formatNotSupported)
            return
        }
        
        let batchID = UUID()
        var batch = ConvertBatch(sourceUrls: sourceUrls,
                                 success: success,
                                 failed: failed,
                                 pendingUrls: Set(sourceUrls))
        convertGroups[batchID] = batch
        
        let convertDir = recordingDirectoryURL.appendingPathComponent("Converted", isDirectory: true)
        let fm = FileManager.default
        if !fm.fileExists(atPath: convertDir.path) {
            try? fm.createDirectory(at: convertDir, withIntermediateDirectories: true)
        }
        
        for sourceURL in sourceUrls {
            let baseName = sourceURL.deletingPathExtension().lastPathComponent
            let outputFileName = "\(baseName)_\(target.extensionName).\(target.extensionName)"
            let outputURL = convertDir.appendingPathComponent(outputFileName)
            
            if fm.fileExists(atPath: outputURL.path) {
                try? fm.removeItem(at: outputURL)
            }
            
            let asset = AVAsset(url: sourceURL)
            guard let exportSession = AVAssetExportSession(asset: asset,
                                                            presetName: AVAssetExportPresetMediumQuality) else {
                handleConvertError(batchID: batchID, sourceURL: sourceURL, error: WYAudioError.conversionFailed)
                continue
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = target.avFileType
            exportSession.shouldOptimizeForNetworkUse = false
            
            convertSessions[sourceURL] = exportSession
            convertProgresses[sourceURL] = 0.0
            
            exportSession.exportAsynchronously { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        self.convertProgresses[sourceURL] = 1.0
                        self.convertSessions.removeValue(forKey: sourceURL)
                        
                        if var batch = self.convertGroups[batchID] {
                            batch.pendingUrls.remove(sourceURL)
                            batch.outputUrls.append(outputURL)
                            self.convertGroups[batchID] = batch
                            
                            if batch.pendingUrls.isEmpty {
                                batch.success(batch.outputUrls)
                                self.convertGroups.removeValue(forKey: batchID)
                            }
                        }
                    case .failed, .cancelled:
                        let error = exportSession.error ?? WYAudioError.conversionFailed
                        self.handleConvertError(batchID: batchID, sourceURL: sourceURL, error: error)
                    default:
                        break
                    }
                    self.startDisplayLinkIfNeeded()
                }
            }
        }
        startDisplayLinkIfNeeded()
    }
    
    private func handleConvertError(batchID: UUID, sourceURL: URL, error: Error) {
        guard var batch = convertGroups[batchID] else { return }
        batch.pendingUrls.remove(sourceURL)
        convertSessions.removeValue(forKey: sourceURL)
        convertProgresses.removeValue(forKey: sourceURL)
        if !batch.hasFailed {
            batch.hasFailed = true
            batch.failed(error)
        }
        convertGroups[batchID] = batch
        if batch.pendingUrls.isEmpty {
            convertGroups.removeValue(forKey: batchID)
        }
    }
    
    /**
     停止格式转换任务
     - Parameter localUrls: 要停止的源文件 URL 数组，nil 表示停止所有正在进行的转换
     */
    public func stopAudioFormatConvert(_ localUrls: [URL]?) {
        let urls = localUrls ?? Array(convertSessions.keys)
        for url in urls {
            if let session = convertSessions[url] {
                session.cancelExport()
                convertSessions.removeValue(forKey: url)
                convertProgresses.removeValue(forKey: url)
            }
            for (batchID, var batch) in convertGroups {
                if batch.pendingUrls.contains(url) {
                    batch.pendingUrls.remove(url)
                    if !batch.hasFailed {
                        batch.hasFailed = true
                        batch.failed(WYAudioError.conversionCancelled)
                    }
                    convertGroups[batchID] = batch
                    if batch.pendingUrls.isEmpty {
                        convertGroups.removeValue(forKey: batchID)
                    }
                    break
                }
            }
        }
        stopDisplayLinkIfNeeded()
    }
    
    // MARK: - 流式播放
    
    /// 流式播放网络音频（边下载边播放，支持倍速）
    public func playStreamingRemoteAudio(remoteUrl: URL, rate: Float = 1.0,
                                         success: @escaping (URL) -> Void,
                                         failed: @escaping (Error?) -> Void) {
        stopPlayback()
        
        let playerItem = AVPlayerItem(url: remoteUrl)
        audioPlayer = AVPlayer(playerItem: playerItem)
        currentPlaybackURL = remoteUrl
        audioPlayer?.rate = rate
        
        playerObservation = audioPlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handlePlayerStatusChange(player.timeControlStatus)
        }
        
        streamingObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed {
                let error = item.error ?? WYAudioError.playbackError
                self?.delegate?.wy_audioTaskDidFailed?(audioKit: self!, url: remoteUrl, error: .playbackError, description: error.localizedDescription)
                failed(error)
                self?.stopPlayback()
            } else if item.status == .readyToPlay {
                success(remoteUrl)
            }
        }
        
        addPlaybackEndObserver()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, let player = self.audioPlayer else { return }
            if player.currentItem?.status == .readyToPlay {
                player.play()
                self.startDisplayLinkIfNeeded()
            }
        }
    }
    
    // MARK: - 获取音频时长
    
    /// 获取音频时长（本地/远程均支持）
    public func getAudioDuration(for url: URL) -> TimeInterval {
        if url.isFileURL {
            let asset = AVAsset(url: url)
            let duration = asset.duration.seconds
            return duration.isFinite ? duration : 0
        } else {
            print("[WYAudioKit] 获取远程音频时长需要异步，同步调用返回0")
            return 0
        }
    }
    
    // MARK: - 下载映射持久化
    
    private func saveDownloadMapping(remote: URL, local: URL) {
        downloadMapping[local.path] = remote.absoluteString
        UserDefaults.standard.set(downloadMapping, forKey: "WYAudioKitDownloadMapping")
    }
    
    private func loadDownloadMapping() {
        if let dict = UserDefaults.standard.dictionary(forKey: "WYAudioKitDownloadMapping") as? [String: String] {
            downloadMapping = dict
        }
    }
    
    // MARK: - CADisplayLink 驱动
    
    private func startDisplayLinkIfNeeded() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink))
            displayLink?.add(to: .main, forMode: .common)
        }
    }
    
    private func stopDisplayLinkIfNeeded() {
        if !isRecording && !isPlaying && convertSessions.isEmpty && tasksInfo.isEmpty {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    @objc private func updateDisplayLink() {
        if isRecording {
            updateRecordingState()
        }
        if isPlaying {
            updatePlaybackProgress()
        }
        updateDownloadProgressIfNeeded()
        updateConversionProgressIfNeeded()
    }
    
    private func updateRecordingState() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
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
        
        for i in 0..<min(recordChannelCount, 2) {
            let p = recorder.peakPower(forChannel: i)
            let a = recorder.averagePower(forChannel: i)
            normalizedPeaks.append(normalizePower(p))
            normalizedAverages.append(normalizePower(a))
        }
        
        delegate?.wy_audioRecorderDidUpdateMeterings?(audioKit: self,
                                                      peakPowers: normalizedPeaks,
                                                      averagePowers: normalizedAverages)
        
        if maximumRecordDuration > 0 && currentTime >= maximumRecordDuration {
            stopRecording()
        }
    }
    
    private func normalizePower(_ power: Float) -> Float {
        if power <= -160.0 { return 0.0 }
        if power >= 0.0 { return 1.0 }
        return pow(10.0, power / 20.0)
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer, let item = player.currentItem else { return }
        let currentTime = player.currentTime().seconds
        let duration = item.duration.isValid ? item.duration.seconds : 0
        let progress = duration > 0 ? min(currentTime / duration, 1.0) : 0.0
        
        delegate?.wy_audioPlayerTimeUpdated?(audioKit: self,
                                             localUrl: currentPlaybackURL ?? URL(fileURLWithPath: ""),
                                             currentTime: currentTime,
                                             duration: duration,
                                             progress: progress)
    }
    
    private func updateDownloadProgressIfNeeded() {
        guard !tasksInfo.isEmpty else { return }
        // 按批次聚合进度
        var batchProgress: [UUID: (total: Double, count: Int)] = [:]
        for (_, info) in tasksInfo {
            let progress = downloadProgresses[info.currentURL] ?? info.progress
            batchProgress[info.batchID, default: (0,0)].total += progress
            batchProgress[info.batchID]?.count += 1
        }
        
        for (batchID, value) in batchProgress {
            let avg = value.total / Double(value.count)
            if let batch = downloadGroups[batchID] {
                delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                                remoteUrls: batch.remoteUrls,
                                                                progress: avg)
            }
        }
    }
    
    private func updateConversionProgressIfNeeded() {
        guard !convertSessions.isEmpty else { return }
        for (url, session) in convertSessions {
            let progress = session.progress
            convertProgresses[url] = progress
        }
        for (batchID, batch) in convertGroups {
            let urls = batch.sourceUrls
            guard !urls.isEmpty else { continue }
            var total: Float = 0
            for url in urls {
                total += convertProgresses[url] ?? 0
            }
            let avg = Double(total / Float(urls.count))
            delegate?.wy_formatConversionProgressUpdated?(audioKit: self,
                                                           localUrls: urls,
                                                           progress: avg)
        }
    }
    
    /// 释放所有资源（建议在不再使用时主动调用，避免内存泄漏）
    public func releaseAll() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        if let observer = playerTimeObserver {
            audioPlayer?.removeTimeObserver(observer)
        }
        playerObservation?.invalidate()
        streamingObservation?.invalidate()
        
        audioPlayer?.pause()
        audioPlayer?.replaceCurrentItem(with: nil)
        audioPlayer = nil
        currentPlaybackURL = nil
        playerTimeObserver = nil
        playerObservation = nil
        streamingObservation = nil
        isInitializingPlayer = false
        
        cancelDownload(nil)
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        
        stopAudioFormatConvert(nil)
        
        displayLink?.invalidate()
        displayLink = nil
        
        isRecordingPaused = false
        isPlaybackPaused = false
        downloadProgresses.removeAll()
        convertProgresses.removeAll()
    }
    
    deinit {
        releaseAll()
    }
}
