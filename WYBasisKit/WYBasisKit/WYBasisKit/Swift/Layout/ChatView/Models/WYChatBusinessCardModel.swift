//
//  WYChatBusinessCardModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 名片model
public struct WYChatBusinessCardModel {
    
    /// id
    public var id: String
    
    /// 用户信息
    public var userInfo: WYChatUserModel
    
    /// 描述
    public var remarks: String
    
    /// 初始化方法
    public init(id: String = "",
                userInfo: WYChatUserModel = WYChatUserModel(),
                remarks: String = "") {
        self.id = id
        self.userInfo = userInfo
        self.remarks = remarks
    }
}
