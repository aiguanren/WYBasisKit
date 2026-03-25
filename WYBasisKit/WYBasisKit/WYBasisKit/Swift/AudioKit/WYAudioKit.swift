//
// WYAudioKit.swift
// WYBasisKit
//
// Created by guanren on 2025/8/12.
//

import Foundation
import AVFoundation

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
    @objc(wy_audioRecorderDidUpdateMeterings:normalizedPeaks:normalizedAverages:)
    optional func wy_audioRecorderDidUpdateMeterings(audioKit: WYAudioKit, normalizedPeaks: [Float], normalizedAverages: [Float])
    
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

/**
 音频工具类 - 提供高性能、功能完备的录音、播放、下载、转换与文件管理能力
 
 主要功能：
 - 录音控制：开始、暂停、恢复、停止，支持最小/最大时长限制、自定义文件名与格式
 - 播放控制：本地/网络音频播放、暂停、恢复、停止、精确seek跳转，支持倍速调节（0.5x ~ 2.0x）
 - 网络音频处理：并发多文件下载、精准进度回调、暂停/恢复/取消、边下边播（流式播放）
 - 文件管理：录音/下载文件自动目录管理、列表获取（按时间排序）、保存、删除、音频时长读取
 - 录音高级特性：基于 AVAudioEngine 实现，更精确的实时声波采集（支持单通道 dB 值 + 多通道 0~1 归一化波形）
 - 播放高级特性：基于 AVPlayer 优化，支持流式播放、CADisplayLink 平滑进度更新
 - 格式转换：支持多文件并发转换（aac/m4a/caf/wav/aiff 等），可中断
 - 其他优化：线程安全、无 retain cycle、DispatchSourceTimer 定时、微信风格波形算法、资源自动释放
 
 使用建议：
 - 初始化后可直接使用公开属性与方法
 - 强烈推荐设置 delegate 接收实时回调（录音波形、播放进度、下载状态等）
 - 不再使用时主动调用 releaseAll() 释放资源，避免内存泄漏
 - 兼容 iOS 13+，新特性使用 #if available 区分，便于未来维护
 */
public final class WYAudioKit: NSObject {
    
    /// 代理对象，用于回调录音、播放、下载、转换等事件
    public weak var delegate: WYAudioKitDelegate?
    
    /// 当前使用的音频播放器实例
    public private(set) var audioPlayer: AVPlayer?
    
    /// 是否正在录音
    public var isRecording: Bool { recorder.isRecording }
    
    /// 是否正在播放
    public var isPlaying: Bool { player.isPlaying }
    
    /// 录音是否处于暂停状态（内部手动维护）
    public private(set) var isRecordingPaused: Bool = false
    
    /// 播放是否处于暂停状态（内部手动维护）
    public private(set) var isPlaybackPaused: Bool = false
    
    /// 录音最小有效时长（秒），低于此值停止时会自动删除文件，0 表示无限制
    public var minimumRecordDuration: TimeInterval = 0
    
    /// 录音最大允许时长（秒），到达后自动停止录音，0 表示无限制
    public var maximumRecordDuration: TimeInterval = 0
    
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
    public private(set) var currentRecordFileURL: URL?
    
    /// 录音文件存储的目录类型（修改后会自动创建目录）
    public var recordingsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            ensureDirectoryExists(recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件存储的目录类型（修改后会自动创建目录）
    public var downloadsDirectory: WYAudioStorageDirectory = .temporary {
        didSet {
            ensureDirectoryExists(downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 录音文件存放的子目录名称（nil 表示直接放在根目录）
    public var recordingsSubdirectory: String? = "Recordings" {
        didSet {
            ensureDirectoryExists(recordingsDirectory, subdirectory: recordingsSubdirectory)
        }
    }
    
    /// 下载文件存放的子目录名称（nil 表示直接放在根目录）
    public var downloadsSubdirectory: String? = "Downloads" {
        didSet {
            ensureDirectoryExists(downloadsDirectory, subdirectory: downloadsSubdirectory)
        }
    }
    
    /// 播放速率 0.5x ~ 2.0x
    public var playbackRate: Float = 1.0
    
    /// 唯一初始化方法
    public override init() {
        self.recorder = WYAudioRecorder()
        self.player = WYAudioPlayer()
        self.downloader = WYAudioDownloader()
        self.converter = WYAudioConverter()
        self.fileManager = WYAudioFileManager()
        super.init()
        
        recorder.kit = self
        player.kit = self
        downloader.kit = self
        converter.kit = self
        fileManager.kit = self
    }
    
    /**
     开始录音
     - Parameters:
     - fileName: 自定义文件名（可选，不传则自动生成带时间戳的名字）
     - format: 录音格式（默认 .aac）
     - Throws: WYAudioError（权限、格式、正在录音等异常）
     */
    public func startRecording(fileName: String? = nil, format: WYAudioFormat = .aac) throws {
        try recorder.startRecording(fileName: fileName, format: format)
    }
    
    /// 暂停当前录音
    public func pauseRecording() {
        recorder.pauseRecording()
    }
    
    /// 恢复已暂停的录音
    public func resumeRecording() {
        recorder.resumeRecording()
    }
    
    /// 停止录音（会检查最小时长，不满足设置则会删除文件）
    public func stopRecording() {
        recorder.stopRecording()
    }
    
    /**
     开始播放本地音频文件
     - Parameters:
     - url: 要播放的音频文件URL，为 nil 则播放当前录音文件（currentRecordFileURL）
     */
    public func playPlayback(url: URL? = nil) {
        player.playPlayback(url: url)
    }
    
    /// 暂停当前播放
    public func pausePlayback() {
        player.pausePlayback()
    }
    
    /// 恢复已暂停的播放
    public func resumePlayback() {
        player.resumePlayback()
    }
    
    /// 停止当前播放并重置状态
    public func stopPlayback() {
        player.stopPlayback()
    }
    
    /**
     跳转到指定播放时间点（支持暂停状态下跳转）
     - Parameters:
     - time: 目标播放时间（秒），会自动限制在有效范围内
     */
    public func seekPlayback(time: TimeInterval) {
        player.seekPlayback(time: time)
    }
    
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
        downloadRemoteAudio(remoteUrls: [remoteUrl]) { infos in
            guard let first = infos.first else { return }
            self.playPlayback(url: first.local)
            success(first)
        } failed: { error in
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
        downloader.downloadRemoteAudio(remoteUrls: remoteUrls, success: success, failed: failed)
    }
    
    /**
     暂停指定的远程下载任务
     - Parameter remoteUrls: 要暂停的 URL 数组，nil 表示暂停所有
     */
    public func pauseDownload(_ remoteUrls: [URL]?) {
        downloader.pauseDownload(remoteUrls)
    }
    
    /**
     恢复指定的远程下载任务
     - Parameter remoteUrls: 要恢复的 URL 数组，nil 表示恢复所有
     */
    public func resumeDownload(_ remoteUrls: [URL]?) {
        downloader.resumeDownload(remoteUrls)
    }
    
    /**
     取消指定的远程下载任务
     - Parameter remoteUrls: 要取消的 URL 数组，nil 表示取消所有
     */
    public func cancelDownload(_ remoteUrls: [URL]?) {
        downloader.cancelDownload(remoteUrls)
    }
    
    /**
     保存当前录音文件到指定位置
     - Parameter destinationUrl: 目标保存路径
     */
    public func saveRecording(destinationUrl: URL) {
        fileManager.saveRecording(currentRecordFileURL, to: destinationUrl)
    }
    
    /**
     获取所有已保存的录音文件（按创建时间倒序）
     - Returns: 文件 URL 数组
     */
    public func getAllRecordingsFiles() -> [URL] {
        fileManager.getAllRecordingsFiles()
    }
    
    /**
     删除录音文件
     - Parameter localUrl: 要删除的具体文件 URL，nil 表示删除所有录音文件
     */
    public func deleteRecordingFile(localUrl: URL? = nil) {
        fileManager.deleteRecordingFile(localUrl)
    }
    
    /**
     获取所有已下载的音频文件信息（按创建时间倒序）
     - Returns: 下载信息数组（remote 通过持久化映射获取，若无则为占位符）
     */
    public func getAllDownloads() -> [WYAudioDownloadInfo] {
        fileManager.getAllDownloads()
    }
    
    /**
     删除已下载的音频文件
     - Parameter info: 要删除的下载信息，nil 表示删除所有下载文件
     */
    public func deleteDownloadFile(info: WYAudioDownloadInfo?) {
        fileManager.deleteDownloadFile(info)
    }
    
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
        converter.convertAudioFormat(sourceUrls: sourceUrls, target: target, success: success, failed: failed)
    }
    
    /**
     停止格式转换任务
     - Parameter localUrls: 要停止的源文件 URL 数组，nil 表示停止所有正在进行的转换
     */
    public func stopAudioFormatConvert(_ localUrls: [URL]?) {
        converter.stopAudioFormatConvert(localUrls)
    }
    
    /// 新增强大功能：流式播放网络音频（边下载边播放，支持倍速）
    public func playStreamingRemoteAudio(remoteUrl: URL, rate: Float = 1.0,
                                         success: @escaping (URL) -> Void,
                                         failed: @escaping (Error?) -> Void) {
        player.playStreamingRemoteAudio(remoteUrl: remoteUrl, rate: rate, success: success, failed: failed)
    }
    
    /// 新增强大功能：获取音频时长（本地/远程均支持）
    public func getAudioDuration(for url: URL) -> TimeInterval {
        fileManager.getAudioDuration(for: url)
    }
    
    /// 释放所有资源（建议在不再使用时主动调用，避免内存泄漏）
    public func releaseAll() {
        recorder.releaseResources()
        player.releaseResources()
        downloader.releaseResources()
        converter.releaseResources()
        fileManager.releaseResources()
    }
    
    deinit {
        releaseAll()
    }
}
