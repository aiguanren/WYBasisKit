//
//  WYChatMusicModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 音乐消息Model
public struct WYChatMusicModel {
    
    /// id
    public var id: String = ""
    
    /// 音乐名
    public var name: String = ""
    
    /// 作曲家
    public var composer: String = ""
    
    /// 演唱者
    public var singer: String = ""
    
    /// 音乐时长
    public var duration: TimeInterval = 0
    
    /// 当前已播放时长
    public var playedDuration: TimeInterval = 0
    
    /// 播放地址
    public var playPath: String = ""
    
    /// 封面
    public var cover: WYChatAssetsModel
    
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModel
    
    /// 初始化方法
    public init(id: String = "",
                name: String = "",
                composer: String = "",
                singer: String = "",
                duration: TimeInterval = 0,
                playedDuration: TimeInterval = 0,
                playPath: String = "",
                cover: WYChatAssetsModel = WYChatAssetsModel(),
                thumbnailCover: WYChatAssetsModel = WYChatAssetsModel()) {
        self.id = id
        self.name = name
        self.composer = composer
        self.singer = singer
        self.duration = duration
        self.playedDuration = playedDuration
        self.playPath = playPath
        self.cover = cover
        self.thumbnailCover = thumbnailCover
    }
}
