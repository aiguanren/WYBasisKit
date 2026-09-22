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
@frozen public enum WYAudioFormat: Int, CaseIterable {
    /// AAC 格式（实际保存为 .m4a 容器）
    case aac = 0
    /// WAV 格式（线性 PCM）
    case wav
    /// CAF 格式（Apple 核心音频格式）
    case caf
    /// M4A 格式（MPEG-4 音频）
    case m4a
    /// AIFF 格式（Apple 音频交换文件格式）
    case aiff
    /// MP3 格式（仅播放支持）
    case mp3
    /// FLAC 格式（仅播放支持）
    case flac
    /// AU 格式（仅播放支持）
    case au
    /// AMR 格式（仅播放支持）
    case amr
    /// AC3 格式（仅播放支持）
    case ac3
    /// EAC3 格式（仅播放支持）
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
    
    /// 是否支持直接录制(mp3/flac等系统只有解码器没有编码器，拿它们开录音会抛formatNotSupported)
    public var isRecordable: Bool {
        switch self {
        case .aac, .wav, .caf, .m4a, .aiff:
            return true
        default:
            return false
        }
    }

    /// 是否支持作为格式转换目标(aac/m4a走AAC导出管线，wav/aiff/caf走PCM读写器管线，其余格式系统没有对应编码器，传入convertAudioFormat会回调formatNotSupported)
    public var isConvertible: Bool {
        switch self {
        case .aac, .m4a, .caf, .wav, .aiff:
            return true
        default:
            return false
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
    /// 没有可以播放的音频文件
    case noAudiofilesToPlay
    /// 音频文件未找到
    case fileNotFound
    /// 录音文件保存失败
    case fileSaveFailed
    /// 录音正在进行中
    case recordingInProgress
    /// 录音时长未达到最小值
    case minDurationNotReached
    /// 正在播放音频文件
    case isPlayingAudio
    /// 播放错误
    case playbackError
    /// 没有可以暂停播放的音频
    case noAudioToPause
    /// 没有可以恢复播放的音频任务
    case noAudioResumePlayTasks
    /// 音频下载失败
    case downloadFailed
    /// 无效的远程URL
    case invalidRemoteURL
    /// 没有需要格式转换的文件
    case noFilesRequireConversion
    /// 格式转换失败
    case conversionFailed
    /// 格式转换已取消
    case conversionCancelled
    /// 不支持的录制格式
    case formatNotSupported
    /// 源文件已是目标格式，无需转换
    case sourceAlreadyTargetFormat
    /// 音频会话配置失败
    case sessionConfigurationFailed
    /// 目录创建失败
    case directoryCreationFailed
}

/// 网络下载(音频)文件的远程和本地URL信息
@objcMembers public class WYAudioDownloadInfo: NSObject {
    
    /// 远程URL
    @objc public let remote: URL
    
    /// 本地URL
    @objc public let local: URL
    
    /// 唯一初始化方法
    @objc public init(remote: URL, local: URL) {
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
       - isTimeout: 是否是超时(达到最大录音时长)停止
     */
    @objc(wy_audioRecorderDidStop:isPause:isTimeout:)
    optional func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool)
    
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
       - peakPowers: 当前各通道的归一化峰值幅度数组（0.0 ~ 1.0，0.0 最安静，1.0 最响）；适合直接用于声波动画、音量条等 UI 显示
       - averagePowers: 当前各通道的归一化平均幅度数组（0.0 ~ 1.0）；更平滑，推荐用于语音录制波形动画
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
       - url: 出错的任务相关URL（可选，可能是本地或远程）
       - error: 错误枚举值
       - description: 详细错误描述(可选)
     */
    @objc(wy_audioTaskDidFailed:url:error:description:)
    optional func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?)
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
public final class WYAudioKit: NSObject {
    
    /// 代理对象，用于回调录音、播放、下载、转换等事件
    public weak var delegate: WYAudioKitDelegate?
    
    /// 是否正在录音
    public var isRecording: Bool {
        state.audioRecorder?.isRecording ?? false
    }
    
    /// 是否正在播放
    public var isPlaying: Bool {
        guard let player = state.audioPlayer else { return false }
        return player.rate != 0 && player.timeControlStatus == .playing
    }
    
    /// 录音是否处于暂停状态
    public private(set) var isRecordingPaused: Bool = false
    
    /// 播放是否处于暂停状态
    public internal(set) var isPlaybackPaused: Bool = false
    
    /// 录音最小有效时长（秒），低于此值停止时会自动删除文件，0 表示无限制
    public var minimumRecordDuration: TimeInterval = 0
    
    /// 录音最大允许时长（秒），到达后自动停止录音，0 表示无限制
    public var maximumRecordDuration: TimeInterval = 0
    
    /// 设置音频播放速率 0.5x ~ 2.0x
    public var playbackRate: Float = 1.0 {
        didSet {
            if playbackRate < 0.5 { playbackRate = 0.5 }
            if playbackRate > 2.0 { playbackRate = 2.0 }
            // 播放中才即时生效，暂停时只记住值(暂停中直接设非0的rate会把播放顶起来)，恢复播放时resumePlayback会带上
            if isPlaying {
                state.audioPlayer?.rate = playbackRate
            }
        }
    }
    
    /**
     设置音频质量等级（影响比特率、采样率等，默认中等）
     - Parameter quality: AVAudioQuality 枚举值，会影响默认比特率和采样质量
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
            state.recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件存储的目录类型（修改后会自动创建目录）
    public var downloadsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            state.downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 录音文件存放的子目录名称（nil 表示直接放在根目录）
    public var recordingsSubdirectory: String? = "WYRecordings" {
        didSet {
            if state.recordingDirectoryURL != nil {
                state.recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
            }
        }
    }
    
    /// 下载文件存放的子目录名称（nil 表示直接放在根目录）
    public var downloadsSubdirectory: String? = "WYDownloads" {
        didSet {
            if state.downloadsDirectoryURL != nil {
                state.downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
            }
        }
    }
    
    /// 唯一初始化方法
    public override init() {
        super.init()
        
        setupAudioSession()
        state.recordingDirectoryURL = createDirectory(for: recordingsDirectory, subdirectory: recordingsSubdirectory)
        state.downloadsDirectoryURL = createDirectory(for: downloadsDirectory, subdirectory: downloadsSubdirectory)
        ensureDownloadSession()
        loadDownloadMapping()
    }
    
    /**
     开始录音
     - Parameters:
       - fileName: 自定义文件名（可选，不传则自动生成带时间戳的名字）
       - format: 录音格式（默认 .aac）
     - Throws: WYAudioError（权限、格式、正在录音等异常）
     */
    public func startRecording(fileName: String? = nil, format: WYAudioFormat = .aac) throws {

        // 防误选仅播放格式:mp3/flac等系统没有编码器，硬开录音会在AVAudioRecorder初始化时失败，报的错误还是误导人的"开始录音失败"，这里直接拦下来说清楚
        guard format.isRecordable else {
            wy_handleErrorEvents(error: .formatNotSupported)
            throw WYAudioError.formatNotSupported
        }

        if isRecording {
            wy_handleErrorEvents(error: .recordingInProgress)
            throw WYAudioError.recordingInProgress
        }
        
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .denied:
                wy_handleErrorEvents(error: .permissionDenied)
                throw WYAudioError.permissionDenied
            case .undetermined:
                wy_handleErrorEvents(error: .notDetermined)
                throw WYAudioError.notDetermined
            case .granted:
                // 权限已授予，继续执行录音
                break
            @unknown default:
                break
            }
        }else {
            let permission = AVAudioSession.sharedInstance().recordPermission
            if permission == .denied {
                wy_handleErrorEvents(error: .permissionDenied)
                throw WYAudioError.permissionDenied
            }
            if permission == .undetermined {
                wy_handleErrorEvents(error: .notDetermined)
                throw WYAudioError.notDetermined
            }
        }
        
        let finalFileName: String
        if let name = fileName, !name.isEmpty {
            finalFileName = name
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            finalFileName = "wy_record_\(formatter.string(from: Date()))"
        }
        let ext = format.extensionName
        let fileURL = state.recordingDirectoryURL.appendingPathComponent("\(finalFileName).\(ext)")
        
        var settings = recordSettings
        settings[AVFormatIDKey] = format.audioFormatID
        
        if format == .wav || format == .aiff {
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsNonInterleaved] = false
        } else {
            // 压缩编码统一吃recordQuality(旧版只有caf吃到，aac/m4a时调质量等级完全没反应)
            settings[AVEncoderAudioQualityKey] = recordQuality.rawValue
        }
        
        state.recordChannelCount = settings[AVNumberOfChannelsKey] as? Int ?? 2
        
        do {
            state.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            state.audioRecorder?.delegate = self
            state.audioRecorder?.isMeteringEnabled = true
            state.audioRecorder?.prepareToRecord()
            
            guard let recorder = state.audioRecorder, recorder.record() else {
                wy_handleErrorEvents(error: .startRecordingFailed)
                throw WYAudioError.startRecordingFailed
            }
            
            currentRecordFileURL = fileURL
            isRecordingPaused = false
            
            startDisplayLinkIfNeeded()
            
            delegate?.wy_audioRecorderDidStart?(audioKit: self, isResume: false)
        } catch {
            wy_handleErrorEvents(error: .startRecordingFailed)
            throw WYAudioError.startRecordingFailed
        }
    }
    
    /// 暂停当前录音
    public func pauseRecording() throws {
        guard let recorder = state.audioRecorder, recorder.isRecording else {
            wy_handleErrorEvents(error: .noAudioRecordedTasks)
            throw WYAudioError.noAudioRecordedTasks
        }
        recorder.pause()
        isRecordingPaused = true
        // 防暂停期间刷新器空转:暂停后没有要刷的东西，不停的话每秒30帧白烧CPU
        stopDisplayLinkIfNeeded()
        delegate?.wy_audioRecorderDidStop?(audioKit: self, isPause: true, isTimeout: false)
    }
    
    /// 恢复已暂停的录音
    public func resumeRecording() throws {
        guard let recorder = state.audioRecorder, isRecordingPaused else {
            wy_handleErrorEvents(error: .noAudioResumeRecordTasks)
            throw WYAudioError.noAudioResumeRecordTasks
        }
        recorder.record()
        isRecordingPaused = false
        startDisplayLinkIfNeeded()
        delegate?.wy_audioRecorderDidStart?(audioKit: self, isResume: true)
    }
    
    /// 停止录音（会检查最小时长，不满足设置则会自动删除文件）
    public func stopRecording() throws {
        guard let recorder = state.audioRecorder else {
            wy_handleErrorEvents(error: .noAudioRecordedTasks)
            throw WYAudioError.noAudioRecordedTasks
        }
        
        let duration = recorder.currentTime
        recorder.stop()
        isRecordingPaused = false
        state.audioRecorder = nil
        // 防最小时长抛错路径漏停刷新器:这里不停的话，录音太短被删文件后刷新器还在每秒30帧空转
        stopDisplayLinkIfNeeded()
        
        if minimumRecordDuration > 0 && duration < minimumRecordDuration {
            try? deleteRecordingFile(localUrl: currentRecordFileURL)
            currentRecordFileURL = nil
            // 防外部UI停在录音状态:录音确实停了、文件也删了，didStop也要发(只抛错不通知的话，声波动画等录音UI收不到复位信号会一直动)
            delegate?.wy_audioRecorderDidStop?(audioKit: self, isPause: false, isTimeout: false)
            wy_handleErrorEvents(error: .minDurationNotReached)
            throw WYAudioError.minDurationNotReached
        }
        
        let isTimeout: Bool = ((maximumRecordDuration > 0) && (duration >= maximumRecordDuration))
        
        delegate?.wy_audioRecorderDidStop?(audioKit: self, isPause: false, isTimeout: isTimeout)
    }
    
    /**
     开始播放本地音频文件
     - Parameters:
       - url: 要播放的音频文件URL，为 nil 则播放当前录音文件（currentRecordFileURL）
       - success: 播放成功回调，返回实际播放的 URL
       - failed: 播放失败回调，返回错误相关信息
     */
    public func playPlayback(url: URL? = nil,
                             success: @escaping (_ playURL: URL) -> Void,
                             failed: @escaping (_ playURL: URL?, _ error: Error?, _ description: String?) -> Void) {
        
        // 如果未指定 URL 且录音尚未停止（包括暂停状态），则视为没有可播放的录音文件
        if url == nil && state.audioRecorder != nil {
            wy_handleErrorEvents(error: .noAudiofilesToPlay)
            failed(nil, WYAudioError.noAudiofilesToPlay, nil)
            return
        }
        
        let targetURL = url ?? currentRecordFileURL
        guard let playURL = targetURL else {
            wy_handleErrorEvents(url: targetURL, error: .noAudiofilesToPlay)
            failed(targetURL, WYAudioError.noAudiofilesToPlay, nil)
            return
        }
        
        if state.currentPlaybackURL == playURL && isPlaying {
            wy_handleErrorEvents(url: playURL, error: .isPlayingAudio)
            failed(playURL, WYAudioError.isPlayingAudio, nil)
            return
        }
        
        // 防标记被清理覆盖:cleanupPlayback末尾会把isInitializingPlayer归false，标记必须放在stopPlayback之后设才有用
        stopPlayback()
        state.isInitializingPlayer = true
        
        let playerItem = AVPlayerItem(url: playURL)
        state.audioPlayer = AVPlayer(playerItem: playerItem)
        state.currentPlaybackURL = playURL
        state.audioPlayer?.rate = playbackRate
        
        startDisplayLinkIfNeeded()
        
        state.playerObservation = state.audioPlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handlePlayerStatusChange(player.timeControlStatus)
        }
        
        addPlaybackEndObserver()
        
        // 使用属性持有观察者
        var hasStarted = false
        state.playerItemStatusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay && !hasStarted {
                hasStarted = true
                self.state.audioPlayer?.play()
                self.state.isInitializingPlayer = false
                self.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .start)
                success(playURL)
                // 观察完成后可以置 nil
                self.state.playerItemStatusObservation = nil
            } else if item.status == .failed {
                self.wy_handleErrorEvents(url: playURL, error: .playbackError, description: item.error?.localizedDescription)
                failed(playURL, WYAudioError.playbackError, item.error?.localizedDescription)
                self.state.playerItemStatusObservation = nil
                self.state.isInitializingPlayer = false
            }
        }
    }
    
    /// 暂停当前播放
    public func pausePlayback() throws {
        // 允许缓冲中的暂停(旧版要求isPlaying为true，流式播放网络卡顿处于等待缓冲时暂停会直接报错)，只要播放器还在且没暂停过就行
        guard let player = state.audioPlayer, !isPlaybackPaused else {
            wy_handleErrorEvents(error: .noAudioToPause)
            throw WYAudioError.noAudioToPause
        }
        player.pause()
        isPlaybackPaused = true
        delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .pause)
    }
    
    /// 恢复已暂停的播放
    public func resumePlayback() throws {
        guard let player = state.audioPlayer, isPlaybackPaused else {
            wy_handleErrorEvents(error: .noAudioResumePlayTasks)
            throw WYAudioError.noAudioResumePlayTasks
        }
        player.rate = playbackRate
        isPlaybackPaused = false
        delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .resume)
        startDisplayLinkIfNeeded()
    }
    
    /// 停止当前播放并重置状态
    public func stopPlayback() {
        // 如果没有播放器，直接返回，不回调任何状态
        guard state.audioPlayer != nil else { return }
        cleanupPlayback(shouldCallbackStop: true)
    }
    
    /**
     跳转到指定播放时间点（支持暂停状态下跳转，超出总时长会自动夹到末尾并触发完成播放）
     - Parameter time: 目标播放时间（秒），负数按0处理，超过音频总时长会定位到末尾
     */
    public func seekPlayback(time: TimeInterval) {
        guard let player = state.audioPlayer else { return }
        var clampedTime = max(0, time)
        // 只有时长有效且有限才夹上界(条目未就绪时duration是NaN、流式播放是无限时长，这两种不该夹，交给播放器自己定位)
        if let itemDuration = player.currentItem?.duration,
           itemDuration.isValid, itemDuration.seconds.isFinite {
            clampedTime = min(clampedTime, itemDuration.seconds)
        }
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    /**
     播放网络音频文件（先下载后播放）
     - Parameters:
       - remoteUrl: 远程音频 URL
       - success: 下载并播放成功回调（返回下载信息）
       - failed: 下载或播放失败回调
     */
    public func playRemoteAudio(remoteUrl: URL,
                                success: @escaping (WYAudioDownloadInfo) -> Void,
                                failed: @escaping (Error?) -> Void) {
        
        downloadRemoteAudio(remoteUrls: [remoteUrl]) { [weak self] infos in
            guard let self = self, let first = infos.first else {
                failed(WYAudioError.fileNotFound)
                return
            }
            // 下载完成回调在文件同步落盘之后才会走到这里，不需要旧版的0.2秒延时等待
            self.playPlayback(url: first.local,
                              success: { _ in
                success(first)
            },
                              failed: { _, error, _ in
                failed(error)
            })
        } failed: { error in
            failed(error)
        }
    }
    
    /**
     下载远程音频文件（支持并发多任务）
     - Parameters:
       - remoteUrls: 要下载的远程 URL 数组（已在下载中的URL会被跳过，不重新下载）
       - success: 下载成功回调（返回下载信息数组）
       - failed: 下载失败回调
     */
    public func downloadRemoteAudio(remoteUrls: [URL],
                                    success: @escaping ([WYAudioDownloadInfo]) -> Void,
                                    failed: @escaping (Error?) -> Void) {
        guard !remoteUrls.isEmpty else {
            wy_handleErrorEvents(error: .invalidRemoteURL)
            failed(WYAudioError.invalidRemoteURL)
            return
        }
        
        // 防重复下载白费流量:同URL已在下载中就跳过(旧版会取消旧任务从头重下，进度回退)，批次只对新增URL建任务
        let urlsToStart = remoteUrls.filter { state.tasksInfo[$0] == nil }
        if urlsToStart.count < remoteUrls.count {
            let duplicated = remoteUrls.filter { state.tasksInfo[$0] != nil }
            for url in duplicated {
                wy_handleErrorEvents(url: url, error: .downloadFailed, description: WYLocalized("该URL已在下载中，忽略重复请求", table: WYBasisKitConfig.kitLocalizableTable))
            }
            guard !urlsToStart.isEmpty else {
                failed(WYAudioError.downloadFailed)
                return
            }
        }
        
        // 启动 DisplayLink 以更新下载进度
        startDisplayLinkIfNeeded()
        
        let batchID = UUID()
        let batch = WYDownloadBatch(remoteUrls: urlsToStart,
                                    success: success,
                                    failed: failed,
                                    pendingUrls: Set(urlsToStart))
        state.downloadGroups[batchID] = batch
        
        for originalURL in urlsToStart {
            // 清除该URL的所有旧状态（避免残留数据干扰，旧批次摘牌防止它永远等不到回调）
            detachOldDownloadState(for: originalURL)
            
            // 强制重置进度显示
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                             remoteUrls: [originalURL],
                                                             progress: 0.0)
            
            // 创建新任务信息
            var info = WYDownloadTaskInfo(originalURL: originalURL,
                                          currentURL: originalURL,
                                          batchID: batchID,
                                          progress: 0.0)
            let task = ensureDownloadSession().downloadTask(with: originalURL)
            task.resume()
            info.task = task
            state.tasksInfo[originalURL] = info
            state.downloadProgresses[originalURL] = 0.0
        }
    }
    
    /// 查询指定远程URL是否正在下载中（不含已暂停的任务）
    public func isDownloading(_ remoteUrl: URL) -> Bool {
        return state.tasksInfo[remoteUrl] != nil
    }
    
    /**
     暂停指定的远程下载任务
     - Parameter remoteUrls: 要暂停的 URL 数组，nil 表示暂停所有
     - Parameter success: 每个任务成功暂停时的回调，返回该任务的 URL
     - Parameter failed: 每个任务暂停失败时的回调，返回该任务的 URL 和错误
     */
    public func pauseDownload(_ remoteUrls: [URL]?,
                              success: @escaping (URL) -> Void,
                              failed: @escaping (URL, Error?) -> Void) {
        let urls = remoteUrls ?? Array(state.tasksInfo.keys)
        
        for originalURL in urls {
            guard let info = state.tasksInfo[originalURL], let task = info.task else {
                wy_handleErrorEvents(url: originalURL, error: .noAudioPauseTasks)
                failed(originalURL, WYAudioError.noAudioPauseTasks)
                continue
            }
            
            // 将任务从活跃字典移到暂停字典
            state.tasksInfo.removeValue(forKey: originalURL)
            state.pausedTaskInfo[originalURL] = info
            
            task.cancel { [weak self] resumeData in
                guard let self = self else { return }
                guard let data = resumeData else {
                    self.wy_handleErrorEvents(url: originalURL, error: .downloadFailed)
                    failed(originalURL, WYAudioError.downloadFailed)
                    // 恢复任务到活跃字典(拿不到resumeData就当没暂停过，任务挪回活跃侧等错误回调收尾)
                    if let failedInfo = self.state.pausedTaskInfo[originalURL] {
                        self.state.pausedTaskInfo.removeValue(forKey: originalURL)
                        self.state.tasksInfo[originalURL] = failedInfo
                    }
                    // 任务回到活跃侧，排队中的恢复请求作废
                    self.state.pendingResumeUrls.remove(originalURL)
                    return
                }
                guard var pausedInfo = self.state.pausedTaskInfo[originalURL] else {
                    self.wy_handleErrorEvents(url: originalURL, error: .downloadFailed)
                    failed(originalURL, WYAudioError.downloadFailed)
                    return
                }
                pausedInfo.resumeData = data
                pausedInfo.task = nil
                self.state.pausedTaskInfo[originalURL] = pausedInfo
                // 代理回调
                self.delegate?.wy_remoteAudioDownloadPaused?(audioKit: self, remoteUrls: [originalURL])
                // 成功暂停，回调该任务的 URL
                success(originalURL)
                // 防恢复请求石沉大海:暂停期间点过恢复的，resumeData一到手立刻自动续上
                if self.state.pendingResumeUrls.remove(originalURL) != nil {
                    self.resumeDownload([originalURL])
                }
            }
        }
        // 暂停后没有活跃下载了就停刷新器，防止空转
        stopDisplayLinkIfNeeded()
    }
    
    /**
     恢复指定的远程下载任务
     - Parameter remoteUrls: 要恢复的 URL 数组，nil 表示恢复所有
     */
    public func resumeDownload(_ remoteUrls: [URL]?) {
        var resumedUrls: [URL] = []
        let urls = remoteUrls ?? Array(state.pausedTaskInfo.keys)
        
        for originalURL in urls {
            guard var info = state.pausedTaskInfo[originalURL] else {
                // [WYAudioKit] 无法恢复 \(originalURL)：缺少恢复数据或任务信息"
                wy_handleErrorEvents(url: originalURL, error: .downloadFailed)
                continue
            }
            // 防恢复请求石沉大海:暂停的cancel回调还没回来(resumeData未就绪)时点了恢复，先排队，resumeData到手自动续上
            guard let resumeData = info.resumeData else {
                state.pendingResumeUrls.insert(originalURL)
                wy_handleErrorEvents(url: originalURL, error: .downloadFailed, description: WYLocalized("暂停尚未完成，已自动排队，暂停落定后立即恢复", table: WYBasisKitConfig.kitLocalizableTable))
                continue
            }
            
            let task = ensureDownloadSession().downloadTask(withResumeData: resumeData)
            task.resume()
            
            // 恢复任务信息(记下字节基点，恢复后系统可能从0重新累计已写字节，进度回调按基点校准防闪0)
            info.task = task
            info.resumeData = nil
            info.resumeBaselineBytes = Int64(resumeData.count)
            info.hasCalibratedResumeBytes = false
            info.resumeOffsetBytes = 0
            state.tasksInfo[originalURL] = info
            // 确保进度字典中有正确的进度值
            state.downloadProgresses[originalURL] = info.progress
            
            // 清理暂停数据
            state.pausedTaskInfo.removeValue(forKey: originalURL)
            
            resumedUrls.append(originalURL)
        }
        
        if !resumedUrls.isEmpty {
            // 防恢复后收不到进度:暂停时刷新器可能已经停了，不重启的话恢复的下载永远没有进度回调
            startDisplayLinkIfNeeded()
            delegate?.wy_remoteAudioDownloadResumed?(audioKit: self, remoteUrls: resumedUrls)
        }
    }
    
    /**
     取消指定的远程下载任务
     - Parameter remoteUrls: 要取消的 URL 数组，nil 表示取消所有
     */
    public func cancelDownload(_ remoteUrls: [URL]?) {
        let urls = remoteUrls ?? Array(state.tasksInfo.keys) + Array(state.pausedTaskInfo.keys)
        var canceledUrls: [URL] = []
        
        for originalURL in Set(urls) {
            var info: WYDownloadTaskInfo?
            if let activeInfo = state.tasksInfo[originalURL] {
                info = activeInfo
                state.tasksInfo.removeValue(forKey: originalURL)
            } else if let pausedInfo = state.pausedTaskInfo[originalURL] {
                info = pausedInfo
                state.pausedTaskInfo.removeValue(forKey: originalURL)
            }
            
            guard let taskInfo = info else { continue }
            taskInfo.task?.cancel()
            
            // 清理批次(batchID是非可选值，旧版的as UUID?强转纯属多余)
            let batchID = taskInfo.batchID
            if var batch = state.downloadGroups[batchID] {
                batch.pendingUrls.remove(originalURL)
                if !batch.hasFailed {
                    batch.hasFailed = true
                    batch.failed(WYAudioError.downloadFailed)
                }
                state.downloadGroups[batchID] = batch
                if batch.pendingUrls.isEmpty {
                    state.downloadGroups.removeValue(forKey: batchID)
                    state.lastNotifiedBatchProgress.removeValue(forKey: batchID)
                }
            }
            
            // 移除所有相关状态(任务都取消了，排队中的恢复请求一并作废)
            state.downloadProgresses.removeValue(forKey: taskInfo.currentURL)
            state.downloadProgresses.removeValue(forKey: originalURL)
            state.pendingResumeUrls.remove(originalURL)
            
            // 通知进度为0
            delegate?.wy_remoteAudioDownloadProgressUpdated?(audioKit: self,
                                                             remoteUrls: [originalURL],
                                                             progress: 0.0)
            canceledUrls.append(originalURL)
        }
        // 取消后没有活跃下载了就停刷新器，防止空转
        stopDisplayLinkIfNeeded()
    }
    
    /**
     保存当前录音文件到指定位置
     - Parameter destinationUrl: 目标保存路径
     */
    public func saveRecording(destinationUrl: URL) throws {
        guard let source = currentRecordFileURL else {
            wy_handleErrorEvents(error: .fileNotFound)
            throw WYAudioError.fileNotFound
        }
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationUrl.path) {
                try fm.removeItem(at: destinationUrl)
            }
            try fm.copyItem(at: source, to: destinationUrl)
        } catch {
            wy_handleErrorEvents(url: destinationUrl, error: .fileSaveFailed, description: error.localizedDescription)
            throw WYAudioError.fileSaveFailed
        }
    }
    
    /**
     获取所有已保存的录音文件（按创建时间倒序）
     - Returns: 文件 URL 数组
     */
    public func getAllRecordingsFiles() -> [URL] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: state.recordingDirectoryURL,
                                                         includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                                                         options: [.skipsHiddenFiles]) else {
            return []
        }
        // 排除子目录(录音目录下有Converted转换输出文件夹，不滤掉会被当成一条录音文件列出来)
        let files = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }
        return files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /**
     删除录音文件
     - Parameter localUrl: 要删除的具体文件 URL，nil 表示删除所有录音文件
     */
    public func deleteRecordingFile(localUrl: URL? = nil) throws {
        let fm = FileManager.default
        if let url = localUrl {
            do {
                try fm.removeItem(at: url)
            } catch  {
                wy_handleErrorEvents(error: .deleteAudioFileFailed, description: error.localizedDescription)
                throw WYAudioError.deleteAudioFileFailed
            }
            if currentRecordFileURL == url {
                currentRecordFileURL = nil
            }
        } else {
            if let contents = try? fm.contentsOfDirectory(at: state.recordingDirectoryURL, includingPropertiesForKeys: nil) {
                for url in contents {
                    do {
                        try fm.removeItem(at: url)
                    } catch  {
                        wy_handleErrorEvents(error: .deleteAudioFileFailed, description: error.localizedDescription)
                        throw WYAudioError.deleteAudioFileFailed
                    }
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
        guard let contents = try? fm.contentsOfDirectory(at: state.downloadsDirectoryURL,
                                                         includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                                                         options: [.skipsHiddenFiles]) else {
            return []
        }
        // 排除子目录(防御性过滤，保证列出来的都是文件)
        let files = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }
        let sorted = files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        var infos: [WYAudioDownloadInfo] = []
        for url in sorted {
            let remoteString = state.downloadMapping[url.path] ?? "https://placeholder.unknown"
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
            state.downloadMapping.removeValue(forKey: info.local.path)
        } else {
            if let contents = try? fm.contentsOfDirectory(at: state.downloadsDirectoryURL, includingPropertiesForKeys: nil) {
                for url in contents {
                    try? fm.removeItem(at: url)
                    state.downloadMapping.removeValue(forKey: url.path)
                }
            }
        }
        // 两个分支都要把映射落盘，抽成一处(旧版两行重复的UserDefaults写)
        persistDownloadMapping()
    }
    
    /**
     转换音频文件格式（支持多文件并发）
     
     **支持的目标格式**：
     - `.aac，.m4a`：输出为 AAC 编码的 .m4a 文件
     - `.caf`：输出为 Apple CAF 格式
     - `.wav`：输出为 WAV 格式（PCM）
     - `.aiff`：输出为 AIFF 格式（PCM）
     
     **不支持的目标格式**：
     - `.mp3`, `.flac`, `.au`, `.amr`, `.ac3`, `.eac3`
     
     - Parameters:
       - sourceUrls: 源文件 URL 数组
       - target: 目标格式（仅限上述支持列表）
       - success: 转换成功回调，返回输出文件 URL 数组
       - failed: 转换失败回调
     */
    public func convertAudioFormat(sourceUrls: [URL],
                                   target: WYAudioFormat,
                                   success: @escaping ([URL]) -> Void,
                                   failed: @escaping (Error?) -> Void) {
        // 检查源文件数组是否为空
        guard !sourceUrls.isEmpty else {
            wy_handleErrorEvents(error: .noFilesRequireConversion)
            failed(WYAudioError.noFilesRequireConversion)
            return
        }
        
        // 检查目标格式是否支持(可转格式统一以WYAudioFormat.isConvertible为单一来源，不在这里另写一份清单)
        guard target.isConvertible else {
            wy_handleErrorEvents(error: .formatNotSupported)
            failed(WYAudioError.formatNotSupported)
            return
        }
        
        // 防同格式白转:源文件扩展名和目标格式相同就跳过(容器编码都一样，转了也只是原样重封装；aac的扩展名就是m4a，m4a源转aac目标同样算同格式)，批次只装需要转的
        let urlsToConvert = sourceUrls.filter { $0.pathExtension.caseInsensitiveCompare(target.extensionName) != .orderedSame }
        if urlsToConvert.count < sourceUrls.count {
            let skipped = sourceUrls.filter { $0.pathExtension.caseInsensitiveCompare(target.extensionName) == .orderedSame }
            for url in skipped {
                wy_handleErrorEvents(url: url, error: .sourceAlreadyTargetFormat, description: String(format: WYLocalized("源文件已是%@格式，跳过转换", table: WYBasisKitConfig.kitLocalizableTable), target.extensionName.uppercased()))
            }
            guard !urlsToConvert.isEmpty else {
                failed(WYAudioError.sourceAlreadyTargetFormat)
                return
            }
        }

        // 生成批次 ID，用于管理多个文件的转换
        let batchID = UUID()
        let batch = WYConvertBatch(sourceUrls: urlsToConvert,
                                   success: success,
                                   failed: failed,
                                   pendingUrls: Set(urlsToConvert))
        state.convertGroups[batchID] = batch
        
        // 创建转换输出目录（位于录音目录下的 Converted 文件夹）
        let convertDir = state.recordingDirectoryURL.appendingPathComponent("Converted", isDirectory: true)
        let fm = FileManager.default
        if !fm.fileExists(atPath: convertDir.path) {
            try? fm.createDirectory(at: convertDir, withIntermediateDirectories: true)
        }
        
        // aac/m4a走导出会话(AAC编码)，wav/aiff/caf走读写器PCM管线(导出会话给不了PCM输出，旧版直通预设对这三种目标基本全部失败，详见+Convert.swift)
        for sourceURL in urlsToConvert {
            let baseName = sourceURL.deletingPathExtension().lastPathComponent
            let outputFileName = "\(baseName)_\(target.extensionName).\(target.extensionName)"
            let outputURL = convertDir.appendingPathComponent(outputFileName)
            
            // 如果输出文件已存在，先删除
            if fm.fileExists(atPath: outputURL.path) {
                try? fm.removeItem(at: outputURL)
            }
            
            // 同一文件还在转换中就先取消旧任务再开新的(直接覆盖记录的话旧任务就失控了，谁也取消不掉它)
            state.convertTasks.removeValue(forKey: sourceURL)?.cancel()
            
            switch target {
            case .aac, .m4a:
                startExportSessionConvert(batchID: batchID, sourceURL: sourceURL, outputURL: outputURL)
            case .wav, .aiff, .caf:
                startPCMConvert(batchID: batchID, sourceURL: sourceURL, outputURL: outputURL, fileType: target.avFileType)
            default:
                // 前面supportedTargets已经拦掉了不支持的目标，这里防御性兜个错
                handleConvertError(batchID: batchID, sourceURL: sourceURL, error: WYAudioError.formatNotSupported)
            }
        }
        // 启动 DisplayLink 以更新进度
        startDisplayLinkIfNeeded()
    }
    
    /**
     停止格式转换任务
     - Parameter localUrls: 要停止的源文件 URL 数组，nil 表示停止所有正在进行的转换
     */
    public func stopAudioFormatConvert(_ localUrls: [URL]?) {
        let urls = localUrls ?? Array(state.convertTasks.keys)
        for url in urls {
            if let task = state.convertTasks[url] {
                task.cancel()
                state.convertTasks.removeValue(forKey: url)
                state.convertProgresses.removeValue(forKey: url)
            }
            for (batchID, var batch) in state.convertGroups {
                if batch.pendingUrls.contains(url) {
                    batch.pendingUrls.remove(url)
                    if !batch.hasFailed {
                        batch.hasFailed = true
                        batch.failed(WYAudioError.conversionCancelled)
                    }
                    state.convertGroups[batchID] = batch
                    if batch.pendingUrls.isEmpty {
                        state.convertGroups.removeValue(forKey: batchID)
                        state.lastNotifiedConvertProgress.removeValue(forKey: batchID)
                    }
                    break
                }
            }
        }
        stopDisplayLinkIfNeeded()
    }
    
    /**
     流式播放网络音频（边下载边播放，支持倍速）
     - Parameters:
       - remoteUrl: 远程音频 URL
       - rate: 播放速率（0.5~2.0）
       - success: 播放成功回调，返回远程 URL
       - failed: 播放失败回调
     */
    public func playStreamingRemoteAudio(remoteUrl: URL, rate: Float = 1.0,
                                         success: @escaping (URL) -> Void,
                                         failed: @escaping (Error?) -> Void) {
        stopPlayback()
        
        let playerItem = AVPlayerItem(url: remoteUrl)
        state.audioPlayer = AVPlayer(playerItem: playerItem)
        state.currentPlaybackURL = remoteUrl
        
        state.playerObservation = state.audioPlayer?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            self?.handlePlayerStatusChange(player.timeControlStatus)
        }
        
        // 旧版靠延时0.2秒后查一次状态来起播，网络慢超过0.2秒就永远收不到进度回调，改成就绪即处理，起播交给rate非0这个播放指令本身
        var hasStarted = false
        state.streamingObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .failed {
                let error = item.error ?? WYAudioError.playbackError
                self.wy_handleErrorEvents(url: remoteUrl, error: .playbackError, description: error.localizedDescription)
                failed(error)
                self.stopPlayback()
            } else if item.status == .readyToPlay && !hasStarted {
                hasStarted = true
                self.state.audioPlayer?.rate = rate
                self.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self, state: .start)
                success(remoteUrl)
                self.startDisplayLinkIfNeeded()
            }
        }
        
        addPlaybackEndObserver()
    }
    
    /**
     获取音频时长（本地/远程均支持）
     - Parameter url: 音频文件 URL（本地或远程）
     - completion: 时长获取完成回调，参数为音频时长（秒），保证在主线程执行
     */
    public func getAudioDuration(with url: URL, completion: @escaping @MainActor (TimeInterval) -> Void) {
        guard url.isFileURL else {
            // 远程 URL 同步获取不支持，直接回调 0
            Task { @MainActor in
                completion(0)
            }
            return
        }
        
        if #available(iOS 16.0, *) {
            Task {
                let asset = AVURLAsset(url: url)
                let duration: TimeInterval
                do {
                    let loadedDuration = try await asset.load(.duration)
                    // 直播流等场景会拿到无效时长，统一兜成0(旧版iOS16以上分支漏了这层判断)
                    duration = loadedDuration.seconds.isFinite ? loadedDuration.seconds : 0
                } catch {
                    duration = 0
                }
                await MainActor.run {
                    completion(duration)
                }
            }
        } else {
            DispatchQueue.global().async {
                let asset = AVAsset(url: url)
                let duration = asset.duration.seconds
                let validDuration = duration.isFinite ? duration : 0
                Task { @MainActor in
                    completion(validDuration)
                }
            }
        }
    }
    
    /// 释放所有资源（建议在不再使用时主动调用，避免内存泄漏）
    public func releaseAll() {
        state.audioRecorder?.stop()
        state.audioRecorder = nil
        
        // 统一走播放清理，顺带把观察者都断掉(旧版漏了流式播放观察者和播放条目观察者的清理)
        cleanupPlayback(shouldCallbackStop: false)
        
        cancelDownload(nil)
        // 会话作废置nil，再次下载时按需重建(旧版置nil后继续下载会拿到死会话直接崩)
        state.downloadSession?.invalidateAndCancel()
        state.downloadSession = nil
        
        stopAudioFormatConvert(nil)
        
        state.displayLink?.invalidate()
        state.displayLink = nil
        
        isRecordingPaused = false
        isPlaybackPaused = false
        state.downloadProgresses.removeAll()
        state.pendingResumeUrls.removeAll()
        state.convertProgresses.removeAll()
    }
    
    /// 私有状态容器
    let state = WYAudioKitPrivateState()
    
    deinit {
        releaseAll()
    }
}
