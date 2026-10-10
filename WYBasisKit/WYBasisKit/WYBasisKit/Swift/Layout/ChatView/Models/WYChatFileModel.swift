//
//  WYChatFileModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 文件model
public struct WYChatFileModel {
    
    /// id
    public var id: String
    
    /// 标题
    public var title: String
    
    /// icon
    public var icon: WYChatAssetsModel
    
    /// 大小(占用内存，如xxkb,xxmb)
    public var size: String
    
    /// 名称
    public var name: String
    
    /// 头像
    public var avatar: WYChatAssetsModel
    
    /// 初始化方法
    public init(id: String = "",
                title: String = "",
                icon: WYChatAssetsModel = WYChatAssetsModel(),
                size: String = "",
                name: String = "",
                avatar: WYChatAssetsModel = WYChatAssetsModel()) {
        self.id = id
        self.title = title
        self.icon = icon
        self.size = size
        self.name = name
        self.avatar = avatar
    }
}
