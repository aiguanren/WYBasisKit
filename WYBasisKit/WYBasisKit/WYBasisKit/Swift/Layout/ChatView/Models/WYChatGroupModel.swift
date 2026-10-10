//
//  WYChatGroupModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 群聊Model
public struct WYChatGroupModel {
    
    /// 群ID
    public var id: String
    
    /// 用户在群内的昵称
    public var nickname: String
    
    /// 群主信息
    public var ownerInfo: WYChatUserModel
    
    /// 群名称
    public var name: String
    
    /// 群头像
    public var avatar: WYChatAssetsModel
    
    /// 群头像缩略图
    public var thumbnailAvatar: WYChatAssetsModel
    
    /// 是否开启了消息免打扰
    public var silence: Bool
    
    /// 群公告
    public var publicity: String
    
    /// 用户给群设置的备注
    public var remarks: String
    
    /// 群二维码
    public var qrCode: WYChatAssetsModel
    
    /// 群管理信息
    public var managers: [WYChatUserModel]
    
    /// 群成员信息
    public var members: [WYChatUserModel]
    
    /// model在数组中对应的下标
    public var index: Int
    
    /// 初始化方法
    public init(id: String = "",
                nickname: String = "",
                ownerInfo: WYChatUserModel = WYChatUserModel(),
                name: String = "",
                avatar: WYChatAssetsModel = WYChatAssetsModel(),
                thumbnailAvatar: WYChatAssetsModel = WYChatAssetsModel(),
                silence: Bool = false,
                publicity: String = "",
                remarks: String = "",
                qrCode: WYChatAssetsModel = WYChatAssetsModel(),
                managers: [WYChatUserModel] = [],
                members: [WYChatUserModel] = [],
                index: Int = 0) {
        self.id = id
        self.nickname = nickname
        self.ownerInfo = ownerInfo
        self.name = name
        self.avatar = avatar
        self.thumbnailAvatar = thumbnailAvatar
        self.silence = silence
        self.publicity = publicity
        self.remarks = remarks
        self.qrCode = qrCode
        self.managers = managers
        self.members = members
        self.index = index
    }
}
