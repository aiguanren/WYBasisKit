//
//  WYChatWebpageModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 网页、小程序model
public struct WYChatWebpageModel {
    
    /// id
    public var id: String
    
    /// 封面
    public var cover: WYChatAssetsModel
    
    /// 标题
    public var title: String
    
    /// 描述
    public var remarks: String
    
    /// 头像
    public var avatar: WYChatAssetsModel
    
    /// 名称
    public var name: String
    
    /// 内容链接
    public var path: String
    
    /// 初始化方法
    public init(id: String = "",
                cover: WYChatAssetsModel = WYChatAssetsModel(),
                title: String = "",
                remarks: String = "",
                avatar: WYChatAssetsModel = WYChatAssetsModel(),
                name: String = "",
                path: String = "") {
        self.id = id
        self.cover = cover
        self.title = title
        self.remarks = remarks
        self.avatar = avatar
        self.name = name
        self.path = path
    }
}
