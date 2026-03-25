//
//  WYAudioKitInternal.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation

public extension WYAudioKit {
    /// 录音管理器实例
    public private(set) var recorder: WYAudioRecorder

    /// 播放管理器实例
    public private(set) var player: WYAudioPlayer

    /// 下载管理器实例
    public private(set) var downloader: WYAudioDownloader

    /// 格式转换管理器实例
    public private(set) var converter: WYAudioConverter

    /// 文件与目录管理器实例
    public private(set) var fileManager: WYAudioFileManager
    
    /// 实时录音波形数组（值0.0~1.0）
    public private(set) var recordingWaveform: [Float] = []
}
