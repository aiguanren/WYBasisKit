//
//  WYAudioKit+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import AVFoundation
import QuartzCore

/// WYAudioKit 私有属性集中管理，所有私有存储属性收进状态容器 WYAudioKitPrivateState，由主类持有一个实例，PrivateImpl 各模块经 state 读写
extension WYAudioKit {
    
    /// 集中存放全部私有存储属性(Swift扩展放不了存储属性，收进容器类统一持有；比关联对象方案快，每次访问就是一次指针解引用，没有装箱开销)
    final class WYAudioKitPrivateState {
        
        /// AVAudioRecorder 实例，用于录音
        var audioRecorder: AVAudioRecorder?
        /// AVPlayer 实例，用于播放音频
        var audioPlayer: AVPlayer?
        /// CADisplayLink 用于定时更新录音波形、播放进度、下载进度等
        var displayLink: CADisplayLink?
        /// 观察 AVPlayer 的时间控制状态变化
        var playerObservation: NSKeyValueObservation?
        /// 用于播放进度更新的时间观察者
        var playerTimeObserver: Any?
        /// 当前正在播放的音频 URL（本地或远程）
        var currentPlaybackURL: URL?
        /// 录音的通道数，用于多通道声波回调
        var recordChannelCount: Int = 2
        /// 标记播放器是否正在初始化中（避免状态回调干扰）
        var isInitializingPlayer: Bool = false
        
        /// 录音文件存储的实际目录 URL
        var recordingDirectoryURL: URL!
        /// 下载文件存储的实际目录 URL
        var downloadsDirectoryURL: URL!
        
        /// 标记是否正在停止播放（防止递归调用）
        var isStoppingPlayback = false
        
        /// 观察 AVPlayerItem 的状态（用于播放准备就绪或失败）
        var playerItemStatusObservation: NSKeyValueObservation?
        
        /// 流式播放的观察者（AVPlayerItem 状态）
        var streamingObservation: NSKeyValueObservation?
        
        /// 下载会话(releaseAll会作废它，之后再次下载时按需重建，防止拿到死会话直接崩)
        var downloadSession: URLSession?
        /// 活跃下载任务信息（原始 URL -> 任务信息）
        var tasksInfo: [URL: WYDownloadTaskInfo] = [:]
        /// 下载批次管理（批次 ID -> 批次信息）
        var downloadGroups: [UUID: WYDownloadBatch] = [:]
        /// 下载进度缓存（当前 URL -> 进度 0.0~1.0）
        var downloadProgresses: [URL: Double] = [:]
        /// 已暂停的下载任务信息（原始 URL -> 任务信息）
        var pausedTaskInfo: [URL: WYDownloadTaskInfo] = [:]
        /// 暂停还没落定就被点了恢复的URL(cancel回调带resumeData回来后自动续上，防止用户的恢复请求石沉大海)
        var pendingResumeUrls: Set<URL> = []
        /// 本地文件路径到远程 URL 的映射（用于 getAllDownloads）
        var downloadMapping: [String: String] = [:]
        /// 上次已回调给外部的各下载批次进度(数值没变就不重复回调，刷新器每帧都跑，不拦的话大部分帧都在白发一摸一样的delegate)
        var lastNotifiedBatchProgress: [UUID: Double] = [:]
        
        /// 转换批次管理（批次 ID -> 批次信息）
        var convertGroups: [UUID: WYConvertBatch] = [:]
        /// 进行中的转换任务句柄（源 URL -> 句柄，导出会话和读写器两种实现统一从这查进度、发取消）
        var convertTasks: [URL: WYConvertTaskHandle] = [:]
        /// 转换进度缓存（源 URL -> 进度 0.0~1.0）
        var convertProgresses: [URL: Float] = [:]
        /// 上次已回调给外部的各转换批次进度(同下载批次，数值没变不重复回调)
        var lastNotifiedConvertProgress: [UUID: Double] = [:]
    }
    
    /// 单个转换任务的操控句柄(导出会话和读写器两种实现统一包装成它，查进度和发取消走同一套)
    final class WYConvertTaskHandle {
        /// 取消当前任务
        let cancel: () -> Void
        /// 读取当前进度(0~1，由具体实现提供)
        let readProgress: () -> Float
        
        /// 唯一初始化方法
        init(cancel: @escaping () -> Void, readProgress: @escaping () -> Float) {
            self.cancel = cancel
            self.readProgress = readProgress
        }
    }
    
    /// 下载批次信息
    struct WYDownloadBatch {
        /// 原始远程 URL 列表
        var remoteUrls: [URL]
        /// 成功回调
        let success: ([WYAudioDownloadInfo]) -> Void
        /// 失败回调
        let failed: (Error?) -> Void
        /// 尚未完成的原始 URL 集合
        var pendingUrls: Set<URL>
        /// 已成功下载的文件信息(按原始URL记录，全部完成时按remoteUrls的顺序取，完成顺序是随机的不能直接给外部)
        var infosByOriginalURL: [URL: WYAudioDownloadInfo] = [:]
        /// 是否已经失败（避免重复回调）
        var hasFailed: Bool = false
    }
    
    /// 转换批次信息
    struct WYConvertBatch {
        /// 源文件 URL 列表
        let sourceUrls: [URL]
        /// 成功回调（输出 URL 数组）
        let success: ([URL]) -> Void
        /// 失败回调
        let failed: (Error?) -> Void
        /// 尚未完成的源 URL 集合
        var pendingUrls: Set<URL>
        /// 转换成功的输出文件(源URL->输出URL，全部完成时按sourceUrls的顺序取，完成顺序是随机的不能直接给外部)
        var outputMap: [URL: URL] = [:]
        /// 是否已经失败
        var hasFailed: Bool = false
    }
    
    /// 下载任务信息
    struct WYDownloadTaskInfo {
        /// 用户传入的原始远程 URL
        let originalURL: URL
        /// 当前实际请求的 URL（可能因重定向而改变）
        var currentURL: URL
        /// 所属批次 ID
        let batchID: UUID
        /// 下载进度（0.0~1.0）
        var progress: Double = 0.0
        /// 下载任务实例
        var task: URLSessionDownloadTask?
        /// 暂停时保存的恢复数据
        var resumeData: Data?
        /// 恢复下载的字节基点(resumeData已有的字节数，恢复后系统可能从0重新累计已写字节，拿它校准防止进度闪0)
        var resumeBaselineBytes: Int64 = 0
        /// 恢复后是否已完成首次校准(首次进度回调时判断系统计数方式，只校准一次)
        var hasCalibratedResumeBytes = false
        /// 校准出的需要补加到已写字节数里的偏移量
        var resumeOffsetBytes: Int64 = 0
    }
    
    /**
     音频任务执行失败回调
     - Parameters:
       - url: 出错的任务相关URL（可选，可能是本地或远程）
       - error: 错误枚举值
       - description: 详细错误描述(可选)
     */
    func wy_handleErrorEvents(url: URL? = nil, error: WYAudioError, description: String? = nil) {
        delegate?.wy_audioTaskDidFailed?(audioKit: self, url: url, error: error, description: description)
    }
}
