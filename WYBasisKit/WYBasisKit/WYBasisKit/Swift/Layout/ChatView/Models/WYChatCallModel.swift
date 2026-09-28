//
//  WYChatCallModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 通话类型
@frozen public enum WYChatCallStyle: Int {
    
    /// 一对一语音
    case oneToOneVoice = 0
    
    /// 一对一视屏
    case oneToOneVideo
    
    /// 多人语音
    case multipleVoices
    
    /// 多人视频
    case multipleVideos
}

/// 音视频通话model
public struct WYChatCallModel {
    
    /// 通话时长
    public var durationOfCall: TimeInterval
    
    /// 通话类型
    public var callStyle: WYChatCallStyle
    
    /// 通话发起者信息
    public var promoter: WYChatUserModel
    
    /// 通话成员信息(一对一通话时只有一个成员)
    public var members: [WYChatUserModel]
    
    /// 初始化方法
    public init(durationOfCall: TimeInterval = 0,
                callStyle: WYChatCallStyle = .oneToOneVoice,
                promoter: WYChatUserModel = WYChatUserModel(),
                members: [WYChatUserModel] = []) {
        self.durationOfCall = durationOfCall
        self.callStyle = callStyle
        self.promoter = promoter
        self.members = members
    }
}
