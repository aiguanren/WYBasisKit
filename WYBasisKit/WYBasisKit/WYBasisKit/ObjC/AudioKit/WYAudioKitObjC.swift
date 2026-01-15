//
//  WYAudioKitObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/5.
//

import Foundation
import AVFoundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/**
 音频文件格式说明：
 
 可直接录制（iOS 原生支持）：
 - aac   ：高效压缩，体积小，音质好；适合音乐、播客、配音；跨平台兼容性好
 - wav   ：无损 PCM，音质最佳，文件较大；适合高音质场景
 - caf   ：Apple 容器，支持多种编码，适合长音频无大小限制
 - m4a   ：基于 MPEG-4 容器，常封装 AAC/ALAC，Apple 生态常用
 - aiff  ：无损 PCM，Apple 早期格式，音质好，体积较大
 
 仅播放支持（无法直接录制）：
 - mp3   ：通用有损编码，兼容性极高，适合跨平台分发
 - flac  ：无损压缩，音质好，安卓友好，iOS 需转码播放
 - au    ：早期 UNIX 音频格式，现较少使用
 - amr   ：人声优化编码，适合通话录音，音质一般
 - ac3   ：杜比数字音频，多声道环绕声，电影电视常用
 - eac3  ：杜比数字增强版，支持更高码率和更多声道
 
 跨平台推荐：
 - 录制给安卓播放：aac / mp3（兼容性较好）
 - 安卓录制给 iOS 播放：mp3 / aac（无需额外解码）
 */
@objc(WYAudioFormat)
@frozen public enum WYAudioFormatObjC: Int {
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
@objc public extension WYAudioKit {
    
    /// 代理对象
    @objc(delegate)
    weak var delegateObjC: WYAudioKitDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /// 音频录音器
    @objc(audioRecorder)
    var audioRecorderObjC: AVAudioRecorder? {
        get { return audioRecorder }
        set { audioRecorder = newValue }
    }
    
    /// 音频播放器
    @objc(audioPlayer)
    var audioPlayerObjC: AVAudioPlayer? {
        get { return audioPlayer }
        set { audioPlayer = newValue }
    }
    
    // MARK: - 公开状态属性
    
    /// 是否正在录音（包括暂停状态）
    @objc(isRecording)
    var isRecordingObjC: Bool {
        return isRecording
    }
    
    /// 是否正在播放（包括暂停状态）
    @objc(isPlaying)
    var isPlayingObjC: Bool {
        return isPlaying
    }
    
    /// 录音是否暂停
    @objc(isRecordingPaused)
    var isRecordingPausedObjC: Bool {
        return isRecordingPaused
    }
    
    /// 播放是否暂停
    @objc(isPlaybackPaused)
    var isPlaybackPausedObjC: Bool {
        return isPlaybackPaused
    }
    
    /// 当前录音文件URL
    @objc(currentRecordFileURL)
    var currentRecordFileURLObjC: URL? {
        return currentRecordFileURL
    }
    
    /// 录音文件存储目录类型（默认临时目录）
    @objc(recordingsDirectory)
    var recordingsDirectoryObjC: WYAudioStorageDirectoryObjC {
        get { return WYAudioStorageDirectoryObjC(rawValue: recordingsDirectory.rawValue) ?? .temporary }
        set { recordingsDirectory = WYAudioStorageDirectory(rawValue: newValue.rawValue) ?? .temporary }
    }
    
    /// 下载文件存储目录类型（默认临时目录）
    @objc(downloadsDirectory)
    var downloadsDirectoryObjC: WYAudioStorageDirectoryObjC {
        get { return WYAudioStorageDirectoryObjC(rawValue: downloadsDirectory.rawValue) ?? .temporary }
        set { downloadsDirectory = WYAudioStorageDirectory(rawValue: newValue.rawValue) ?? .temporary }
    }
    
    /// 录音文件子目录名称（可选）
    @objc(recordingsSubdirectory)
    var recordingsSubdirectoryObjC: String? {
        get { return recordingsSubdirectory }
        set {recordingsSubdirectory = newValue}
    }
    
    /// 下载文件子目录名称（可选）
    @objc(downloadsSubdirectory)
    var downloadsSubdirectoryObjC: String? {
        get { return downloadsSubdirectory }
        set {downloadsSubdirectory = newValue}
    }
    
    /**
     请求录音权限
     
     - Parameter completion: 权限请求结果回调
     - granted: true 表示已授权，false 表示未授权
     */
    @objc(requestRecordPermission:)
    func requestRecordPermissionObjC(completion: @escaping (Bool) -> Void) {
        requestRecordPermission(completion: completion)
    }
    
    /**
     开始录音
     
     - Parameters:
     - fileName: 自定义文件名（可选，不传则自动生成）
     - format: 音频格式（默认AAC）
     
     - Throws: 可能抛出权限错误或初始化错误
     */
    @objc(startRecordingWithFormat:error:)
    func startRecordingObjC(format: WYAudioFormatObjC = .aac) throws {
        try startRecordingObjC(fileName: nil, format: format)
    }
    @objc(startRecordingWithFileName:format:error:)
    func startRecordingObjC(fileName: String? = nil, format: WYAudioFormatObjC = .aac) throws {
        try startRecording(fileName: fileName, format: WYAudioFormat(rawValue: format.rawValue) ?? .aac)
    }
    
    /// 停止录音
    @objc(stopRecording)
    func stopRecordingObjC() {
        stopRecording()
    }
    
    /// 暂停录音
    @objc(pauseRecording)
    func pauseRecordingObjC() {
        pauseRecording()
    }
    
    /// 恢复录音
    @objc(resumeRecording)
    func resumeRecordingObjC() {
        resumeRecording()
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
    @objc(setRecordSettings:)
    func setRecordSettingsObjC(_ settings: [String: Any]) {
        setRecordSettings(settings)
    }
    
    /**
     设置音频质量
     
     - Parameter quality: 音频质量等级
     */
    @objc(setAudioQuality:)
    func setAudioQualityObjC(_ quality: AVAudioQuality) {
        setAudioQuality(quality)
    }
    
    /**
     设置录音时长限制
     
     - Parameters:
     - min: 最小录音时长（秒），0表示无限制（默认）
     - max: 最大录音时长（秒），0表示无限制（默认）
     */
    @objc(setRecordingDurationsMin:max:)
    func setRecordingDurationsObjC(min: TimeInterval = 0, max: TimeInterval = 0) {
        setRecordingDurations(min: min, max: max)
    }
    
    /**
     保存录音文件到指定位置
     
     - Parameter destinationURL: 目标文件URL
     
     - Throws: 文件操作可能抛出错误
     */
    @objc(saveRecordingToDestinationURL:error:)
    func saveRecordingObjC(to destinationURL: URL) throws {
        try saveRecording(to: destinationURL)
    }
    
    /**
     删除当前录音文件
     
     - Throws: 文件操作可能抛出错误
     */
    @objc(deleteRecordingWithError:)
    func deleteRecordingObjC() throws {
        try deleteRecording()
    }
    
    /**
     播放指定URL的音频文件
     
     支持本地文件路径
     
     - Parameter url: 音频文件URL
     
     - Throws: 播放初始化可能抛出错误
     */
    @objc(playAudioWithUrl:error:)
    func playAudioObjC(at url: URL) throws {
        try playAudio(at: url)
    }
    
    /**
     播放当前录音文件
     
     - Throws: 文件未找到错误
     */
    @objc(playRecordedFileWithError:)
    func playRecordedFileObjC() throws {
        try playRecordedFile()
    }
    
    /**
     播放网络音频文件
     
     此方法会自动下载远程音频文件并播放
     
     - Parameters:
     - remoteURL: 远程音频文件的URL
     - completion: 下载完成后的回调，返回下载结果
     */
    @objc(playRemoteAudioFromRemoteURL:completion:)
    func playRemoteAudioObjC(from remoteURL: URL, completion: @escaping (URL?, Error?) -> Void) {
        playRemoteAudio(from: remoteURL) { result in
            switch result {
            case .success(let url):
                completion(url, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    /**
     下载远程音频文件
     
     - Parameters:
     - remoteURL: 远程音频文件的URL
     - completion: 下载完成后的回调，返回本地文件路径或错误
     */
    @objc(downloadRemoteAudioFromRemoteURL:completion:)
    func downloadRemoteAudioObjC(from remoteURL: URL, completion: @escaping (URL?, Error?) -> Void) {
        downloadRemoteAudio(from: remoteURL) { result in
            switch result {
            case .success(let url):
                completion(url, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    /// 取消当前下载任务
    @objc(cancelDownload)
    func cancelDownloadObjC() {
        cancelDownload()
    }
    
    /// 暂停播放
    @objc(pausePlayback)
    func pausePlaybackObjC() {
        pausePlayback()
    }
    
    /// 恢复播放
    @objc(resumePlayback)
    func resumePlaybackObjC() {
        resumePlayback()
    }
    
    /// 停止播放
    @objc(stopPlayback)
    func stopPlaybackObjC() {
        stopPlayback()
    }
    
    /**
     跳转到指定播放位置
     
     - Parameter time: 目标时间（秒）
     */
    @objc(seekPlaybackTo:)
    func seekPlaybackObjC(to time: TimeInterval) {
        seekPlayback(to: time)
    }
    
    /**
     转换音频文件格式
     
     支持转换为以下格式：.aac, .m4a, .caf, .wav, .aiff
     
     - Parameters:
     - sourceURL: 源文件URL
     - targetFormat: 目标格式
     - completion: 转换完成后的回调
     */
    @objc(convertAudioFileWithSourceURL:targetFormat:completion:)
    func convertAudioFileObjC(sourceURL: URL, targetFormat: WYAudioFormatObjC, completion: @escaping (URL?, Error?) -> Void) {
        let swiftFormat = WYAudioFormat(rawValue: targetFormat.rawValue) ?? .aac
        convertAudioFile(sourceURL: sourceURL, targetFormat: swiftFormat) { result in
            switch result {
            case .success(let url):
                completion(url, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // MARK: - 文件管理方法
    
    /**
     获取所有录音文件
     
     - Returns: 录音文件URL数组（按创建日期倒序排序）
     */
    @objc(getAllRecordings)
    func getAllRecordingsObjC() -> [URL] {
        return getAllRecordings()
    }
    
    /**
     获取所有下载的音频文件
     
     - Returns: 下载文件URL数组（按创建日期倒序排序）
     */
    @objc(getAllDownloads)
    func getAllDownloadsObjC() -> [URL] {
        return getAllDownloads()
    }
    
    /**
     删除指定的录音文件
     
     - Parameter url: 要删除的文件URL
     - Throws: 文件操作可能抛出错误
     */
    @objc(deleteRecordingAtUrl:error:)
    func deleteRecordingObjC(at url: URL) throws {
        try deleteRecording(at: url)
    }
    
    /**
     删除所有录音文件
     
     - Throws: 文件操作可能抛出错误
     */
    @objc(deleteAllRecordingsWithError:)
    func deleteAllRecordingsObjC() throws {
        try deleteAllRecordings()
    }
    
    /**
     删除指定的下载文件
     
     - Parameter url: 要删除的文件URL
     - Throws: 文件操作可能抛出错误
     */
    @objc(deleteDownloadAtUrl:error:)
    func deleteDownloadObjC(at url: URL) throws {
        try deleteDownload(at: url)
    }
    
    /**
     删除所有下载文件
     
     - Throws: 文件操作可能抛出错误
     */
    @objc(deleteAllDownloadsWithError:)
    func deleteAllDownloadsObjC() throws {
        try deleteAllDownloads()
    }
    
    /// 释放所有资源(需要外部调用)
    @objc(releaseAll)
    func releaseAllObjC() {
        releaseAll()
    }
}
