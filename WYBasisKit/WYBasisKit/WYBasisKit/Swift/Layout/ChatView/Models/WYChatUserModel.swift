//
//  WYChatUserModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 聊天用户model
public struct WYChatUserModel {
    
    /// 用户id
    public var id: String
    
    /// 用户名
    public var name: String
    
    /// 用户昵称
    public var nickname: String
    
    /// 用户备注
    public var remarks: String
    
    /// 用户签名
    public var signature: String
    
    /// 用户所在地区
    public var area: String
    
    /// 用户聊天列表
    public var listOfSessions: [WYChatSessionModel]
    
    /// 加入的群
    public var groups: [WYChatGroupModel]
    
    /// 用户二维码
    public var qrCode: WYChatAssetsModel
    
    /// 用户头像
    public var avatar: WYChatAssetsModel
    
    /// 用户头像缩略图
    public var thumbnailAvatar: WYChatAssetsModel
    
    /// 更多信息
    public var moreInfo: Data?
    
    /// model在数组中对应的下标
    public var index: Int
    
    /// 初始化方法
    public init(id: String = "",
                name: String = "",
                nickname: String = "",
                remarks: String = "",
                signature: String = "",
                area: String = "",
                listOfSessions: [WYChatSessionModel] = [],
                groups: [WYChatGroupModel] = [],
                qrCode: WYChatAssetsModel = WYChatAssetsModel(),
                avatar: WYChatAssetsModel = WYChatAssetsModel(),
                thumbnailAvatar: WYChatAssetsModel = WYChatAssetsModel(),
                moreInfo: Data? = nil,
                index: Int = 0) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.remarks = remarks
        self.signature = signature
        self.area = area
        self.listOfSessions = listOfSessions
        self.groups = groups
        self.qrCode = qrCode
        self.avatar = avatar
        self.thumbnailAvatar = thumbnailAvatar
        self.moreInfo = moreInfo
        self.index = index
    }
}
