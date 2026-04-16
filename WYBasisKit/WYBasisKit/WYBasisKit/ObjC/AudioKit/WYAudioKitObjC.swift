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

@objc(WYAudioFormat)
@frozen public enum WYAudioFormatObjC: Int {
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
}

/// 音频存储目录类型
@objc(WYAudioStorageDirectory)
@frozen public enum WYAudioStorageDirectoryObjC: Int {
    /// 临时目录（系统可能自动清理）
    case temporary = 0
    /// 文档目录（用户数据，iTunes备份）
    case documents
    /// 缓存目录（系统可能清理）
    case caches
}

/// 网络下载(音频)文件的远程和本地URL信息
@objc(WYAudioDownloadInfo)
public class WYAudioDownloadInfoObjC: NSObject {
    
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
@objc public extension WYAudioKit {
    
    // MARK: - 公开属性
    
    /// 代理对象，用于回调录音、播放、下载、转换等事件
    @objc(delegate)
    public weak var delegateObjC: WYAudioKitDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /// 是否正在录音
    @objc(isRecording)
    public var isRecordingObjC: Bool {
        return isRecording
    }
    
    /// 是否正在播放
    @objc(isPlaying)
    public var isPlayingObjC: Bool {
        return isPlaying
    }
    
    /// 录音是否处于暂停状态
    @objc(isRecordingPaused)
    public var isRecordingPausedObjC: Bool {
        return isRecordingPaused
    }
    
    /// 播放是否处于暂停状态
    @objc(isPlaybackPaused)
    public var isPlaybackPausedObjC: Bool {
        return isPlaybackPaused
    }
    
    /// 录音最小有效时长（秒），低于此值停止时会自动删除文件，0 表示无限制
    @objc(minimumRecordDuration)
    public var minimumRecordDurationObjC: TimeInterval {
        return minimumRecordDuration
    }
    
    /// 录音最大允许时长（秒），到达后自动停止录音，0 表示无限制
    @objc(maximumRecordDuration)
    public var maximumRecordDurationObjC: TimeInterval {
        return maximumRecordDuration
    }
    
    /// 设置音频播放速率 0.5x ~ 2.0x
    @objc(playbackRate)
    public var playbackRateObjC: Float {
        get { return playbackRate }
        set { playbackRate = newValue }
    }
    
    /**
     设置音频质量等级（影响比特率、采样率等，默认中等）
     - Parameter quality: AVAudioQuality 枚举值，会影响默认比特率和采样质量
     */
    @objc(recordQuality)
    public var recordQualityObjC: AVAudioQuality {
        get { return recordQuality }
        set { recordQuality = newValue }
    }
    
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
    @objc(recordSettings)
    public var recordSettingsObjC: [String: Any] {
        get { return recordSettings }
        set { recordSettings = newValue }
    }
    
    /// 当前正在录制的音频文件本地URL（录音开始后设置，停止后保留直到下次录音）
    @objc(currentRecordFileURL)
    public var currentRecordFileURLObjC: URL? {
        return currentRecordFileURL
    }
    
    /// 录音文件存储的目录类型（修改后会自动创建目录）
    @objc(recordingsDirectory)
    public var recordingsDirectoryObjC: WYAudioStorageDirectoryObjC {
        get { return WYAudioStorageDirectoryObjC(rawValue: recordingsDirectory.rawValue) ?? .temporary }
        set { recordingsDirectory = WYAudioStorageDirectory(rawValue: newValue.rawValue) ?? .temporary }
    }
    
    /// 下载文件存储的目录类型（修改后会自动创建目录）
    @objc(downloadsDirectory)
    public var downloadsDirectoryObjC: WYAudioStorageDirectoryObjC {
        get { return WYAudioStorageDirectoryObjC(rawValue: downloadsDirectory.rawValue) ?? .temporary }
        set { downloadsDirectory = WYAudioStorageDirectory(rawValue: newValue.rawValue) ?? .temporary }
    }
    
    /// 录音文件存放的子目录名称（nil 表示直接放在根目录）
    @objc(recordingsSubdirectory)
    public var recordingsSubdirectoryObjC: String? {
        get { return recordingsSubdirectory }
        set { recordingsSubdirectory = newValue }
    }
    
    /// 下载文件存放的子目录名称（nil 表示直接放在根目录）
    @objc(downloadsSubdirectory)
    public var downloadsSubdirectoryObjC: String? {
        get { return downloadsSubdirectory }
        set { downloadsSubdirectory = newValue }
    }
    
    // MARK: - 录音控制
    
    /**
     开始录音
     - Parameters:
       - fileName: 自定义文件名（可选，不传则自动生成带时间戳的名字）
       - format: 录音格式（默认 .aac）
     - Throws: WYAudioError（权限、格式、正在录音等异常）
     */
    @objc(startRecordingWithFileName:format:error:)
    public func startRecordingObjC(fileName: String? = nil, format: WYAudioFormatObjC = .aac) throws {
        try startRecording(fileName: fileName, format: WYAudioFormat(rawValue: format.rawValue) ?? .aac)
    }
    
    /// 暂停当前录音
    @objc(pauseRecordingWithError:)
    public func pauseRecordingObjC() throws {
        try pauseRecording()
    }
    
    /// 恢复已暂停的录音
    @objc(resumeRecordingWithError:)
    public func resumeRecordingObjC() throws {
        try resumeRecording()
    }
    
    /// 停止录音（会检查最小时长，不满足设置则会自动删除文件）
    @objc(stopRecordingWithError:)
    public func stopRecordingObjC() throws {
        try stopRecording()
    }
    
    // MARK: - 播放控制
    
    /**
     开始播放本地音频文件
     - Parameters:
       - url: 要播放的音频文件URL，为 nil 则播放当前录音文件（currentRecordFileURL）
       - success: 播放成功回调，返回实际播放的 URL
       - failed: 播放失败回调，返回错误相关信息
     */
    @objc(playPlaybackWithUrl:success:failed:)
    public func playPlaybackObjC(url: URL? = nil,
                             success: @escaping (_ playURL: URL) -> Void,
                             failed: @escaping (_ playURL: URL?, _ error: Error?, _ description: String?) -> Void) {
        playPlayback(url: url, success: success, failed: failed)
    }
    
    /// 暂停当前播放
    @objc(pausePlaybackWithError:)
    public func pausePlaybackObjC() throws {
        try pausePlayback()
    }
    
    /// 恢复已暂停的播放
    @objc(resumePlaybackWithError:)
    public func resumePlaybackObjC() throws {
        try resumePlayback()
    }
    
    /// 停止当前播放并重置状态
    @objc(stopPlayback)
    public func stopPlaybackObjC() {
        stopPlayback()
    }
    
    /**
     跳转到指定播放时间点（支持暂停状态下跳转）
     - Parameter time: 目标播放时间（秒），会自动限制在有效范围内
     */
    @objc(seekPlaybackWithTime:)
    public func seekPlaybackObjC(time: TimeInterval) {
        seekPlayback(time: time)
    }
    
    /**
     播放网络音频文件（先下载后播放）
     - Parameters:
       - remoteUrl: 远程音频 URL
       - success: 下载并播放成功回调（返回下载信息）
       - failed: 下载或播放失败回调
     */
    @objc(playRemoteAudioWithRemoteUrl:success:failed:)
    public func playRemoteAudioObjC(remoteUrl: URL,
                                success: @escaping (WYAudioDownloadInfoObjC) -> Void,
                                failed: @escaping (Error?) -> Void) {
        
        playRemoteAudio(remoteUrl: remoteUrl) { info in
            if (success != nil) {
                success(WYAudioDownloadInfoObjC(remote: info.remote, local: info.local))
            }
        } failed: { error in
            if (failed != nil) {
                failed(error)
            }
        }
    }
    
    // MARK: - 下载管理
    
    /**
     下载远程音频文件（支持并发多任务）
     - Parameters:
       - remoteUrls: 要下载的远程 URL 数组
       - success: 下载成功回调（返回下载信息数组）
       - failed: 下载失败回调
     */
    @objc(downloadRemoteAudioWithRemoteUrls:success:failed:)
    public func downloadRemoteAudioObjC(remoteUrls: [URL],
                                    success: @escaping ([WYAudioDownloadInfoObjC]) -> Void,
                                    failed: @escaping (Error?) -> Void) {
        downloadRemoteAudio(remoteUrls: remoteUrls) { infos in
            
            if (success != nil) {
                success(infos.map { WYAudioDownloadInfoObjC(remote: $0.remote, local: $0.local) })
            }
            
        } failed: { error in
            if (failed != nil) {
                failed(error)
            }
        }
    }
    
    /**
     暂停指定的远程下载任务
     - Parameter remoteUrls: 要暂停的 URL 数组，nil 表示暂停所有
     - Parameter success: 每个任务成功暂停时的回调，返回该任务的 URL
     - Parameter failed: 每个任务暂停失败时的回调，返回该任务的 URL 和错误
     */
    @objc(pauseDownloadWithRemoteUrls:success:failed:)
    public func pauseDownloadObjC(_ remoteUrls: [URL]?,
                              success: @escaping (URL) -> Void,
                              failed: @escaping (URL, Error?) -> Void) {
        pauseDownload(remoteUrls, success: success, failed: failed)
    }
    
    /**
     恢复指定的远程下载任务
     - Parameter remoteUrls: 要恢复的 URL 数组，nil 表示恢复所有
     */
    @objc(resumeDownloadWithRemoteUrls:)
    public func resumeDownloadObjC(_ remoteUrls: [URL]?) {
        resumeDownload(remoteUrls)
    }
    
    /**
     取消指定的远程下载任务
     - Parameter remoteUrls: 要取消的 URL 数组，nil 表示取消所有
     */
    @objc(cancelDownloadWithRemoteUrls:)
    public func cancelDownloadObjC(_ remoteUrls: [URL]?) {
        cancelDownload(remoteUrls)
    }
    
    // MARK: - 文件管理
    
    /**
     保存当前录音文件到指定位置
     - Parameter destinationUrl: 目标保存路径
     */
    @objc(saveRecordingWithDestinationUrl:error:)
    public func saveRecordingObjC(destinationUrl: URL) throws {
        try saveRecording(destinationUrl: destinationUrl)
    }
    
    /**
     获取所有已保存的录音文件（按创建时间倒序）
     - Returns: 文件 URL 数组
     */
    @objc(getAllRecordingsFiles)
    public func getAllRecordingsFilesObjC() -> [URL] {
        return getAllRecordingsFiles()
    }
    
    /**
     删除录音文件
     - Parameter localUrl: 要删除的具体文件 URL，nil 表示删除所有录音文件
     */
    @objc(deleteRecordingFileWithLocalUrl:error:)
    public func deleteRecordingFileObjC(localUrl: URL? = nil) throws {
        try deleteRecordingFile(localUrl: localUrl)
    }
    
    /**
     获取所有已下载的音频文件信息（按创建时间倒序）
     - Returns: 下载信息数组（remote 通过持久化映射获取，若无则为占位符）
     */
    @objc(getAllDownloads)
    public func getAllDownloadsObjC() -> [WYAudioDownloadInfoObjC] {
        return getAllDownloads().map { WYAudioDownloadInfoObjC(remote: $0.remote, local: $0.local) }
    }
    
    /**
     删除已下载的音频文件
     - Parameter info: 要删除的下载信息，nil 表示删除所有下载文件
     */
    @objc(deleteDownloadFileWithInfo:)
    public func deleteDownloadFileObjC(info: WYAudioDownloadInfo?) {
        if let info = info {
            deleteDownloadFile(info: WYAudioDownloadInfo(remote: info.remote, local: info.local))
        }else {
            deleteDownloadFile(info: nil)
        }
    }
    
    // MARK: - 格式转换
    
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
    @objc(convertAudioFormatWithSourceUrls:target:success:failed:)
    public func convertAudioFormatObjC(sourceUrls: [URL],
                                   target: WYAudioFormatObjC,
                                   success: @escaping ([URL]) -> Void,
                                   failed: @escaping (Error?) -> Void) {
        convertAudioFormat(sourceUrls: sourceUrls, target: WYAudioFormat(rawValue: target.rawValue) ?? .aac, success: success, failed: failed)
    }
    
    /**
     停止格式转换任务
     - Parameter localUrls: 要停止的源文件 URL 数组，nil 表示停止所有正在进行的转换
     */
    @objc(stopAudioFormatConvertWithLocalUrls:)
    public func stopAudioFormatConvertObjC(_ localUrls: [URL]?) {
        stopAudioFormatConvert(localUrls)
    }
    
    // MARK: - 高级功能
    
    /**
     流式播放网络音频（边下载边播放，支持倍速）
     - Parameters:
       - remoteUrl: 远程音频 URL
       - rate: 播放速率（0.5~2.0）
       - success: 播放成功回调，返回远程 URL
       - failed: 播放失败回调
     */
    @objc(playStreamingRemoteAudioWithRemoteUrl:rate:success:failed:)
    public func playStreamingRemoteAudioObjC(remoteUrl: URL, rate: Float = 1.0,
                                         success: @escaping (URL) -> Void,
                                         failed: @escaping (Error?) -> Void) {
        playStreamingRemoteAudio(remoteUrl: remoteUrl, rate: rate, success: success, failed: failed)
    }
    
    /**
     获取音频时长（本地/远程均支持）
     - Parameter url: 音频文件 URL（本地或远程）
     - Returns: 音频时长（秒），远程 URL 同步调用返回 0，建议异步获取
     */
    @objc(getAudioDurationForUrl:)
    public func getAudioDurationObjC(for url: URL) -> TimeInterval {
        getAudioDuration(for: url)
    }
    
    /// 释放所有资源（建议在不再使用时主动调用，避免内存泄漏）
    @objc(releaseAll)
    public func releaseAllObjC() {
        releaseAll()
    }
}
