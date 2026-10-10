//
//  WYChatAssetsModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 图片、视频等资源文件相关信息
public struct WYChatAssetsModel {
    
    /// id
    public var id: String
    
    /// 名字
    public var name: String
    
    /// 网络下载地址
    public var downloadPath: String
    
    /// 本地文件路径
    public var localPath: String
    
    /// 初始化方法
    public init(id: String = "",
                name: String = "",
                downloadPath: String = "",
                localPath: String = "") {
        self.id = id
        self.name = name
        self.downloadPath = downloadPath
        self.localPath = localPath
    }
}
