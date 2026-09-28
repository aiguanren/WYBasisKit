//
//  WYChatVoiceModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 语音消息Model
public struct WYChatVoiceModel {
    
    /// id
    public var id: String
    
    /// 语音时长
    public var duration: TimeInterval
    
    /// 是否被播放过
    public var played: Bool
    
    /// 是否被暂停播放(决定是否可以断点续播)
    public var pause: Bool
    
    /// 被暂停播放时的时间戳
    public var pauseWithTimestamp: TimeInterval
    
    /// 当前已播放时长
    public var currentPlayDuration: TimeInterval
    
    /// 语音转换后的文本
    public var voiceToText: String
    
    /// wav格式本地路径
    public var wavPath: String
    
    /// mp3格式本地路径
    public var mp3Path: String
    
    /// amr格式本地路径
    public var amrPath: String
    
    /// caf格式本地路径
    public var cafPath: String
    
    /// aac格式本地路
    public var aacPath: String
    
    /// 初始化方法
    public init(id: String = "",
                duration: TimeInterval = 0,
                played: Bool = false,
                pause: Bool = false,
                pauseWithTimestamp: TimeInterval = 0,
                currentPlayDuration: TimeInterval = 0,
                voiceToText: String = "",
                wavPath: String = "",
                mp3Path: String = "",
                amrPath: String = "",
                cafPath: String = "",
                aacPath: String = "") {
        self.id = id
        self.duration = duration
        self.played = played
        self.pause = pause
        self.pauseWithTimestamp = pauseWithTimestamp
        self.currentPlayDuration = currentPlayDuration
        self.voiceToText = voiceToText
        self.wavPath = wavPath
        self.mp3Path = mp3Path
        self.amrPath = amrPath
        self.cafPath = cafPath
        self.aacPath = aacPath
    }
}
