//
//  WYChatVideoModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 视频消息Model
public struct WYChatVideoModel {
    
    /// id
    public var id: String
    
    /// 封面
    public var cover: WYChatAssetsModel
    
    /// 封面缩略图
    public var thumbnailCover: WYChatAssetsModel
    
    /// 视频
    public var video: WYChatAssetsModel
    
    /// 视频时长
    public var duration: TimeInterval
    
    /// 当前播放时长
    public var playedDuration: TimeInterval
    
    /// 初始化方法
    public init(id: String = "",
                cover: WYChatAssetsModel = WYChatAssetsModel(),
                thumbnailCover: WYChatAssetsModel = WYChatAssetsModel(),
                video: WYChatAssetsModel = WYChatAssetsModel(),
                duration: TimeInterval = 0,
                playedDuration: TimeInterval = 0) {
        self.id = id
        self.cover = cover
        self.thumbnailCover = thumbnailCover
        self.video = video
        self.duration = duration
        self.playedDuration = playedDuration
    }
}
