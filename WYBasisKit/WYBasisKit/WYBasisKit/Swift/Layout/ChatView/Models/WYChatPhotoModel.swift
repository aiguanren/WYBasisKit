//
//  WYChatPhotoModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 照片消息Model
public struct WYChatPhotoModel {
    
    /// 原图
    public var original: WYChatAssetsModel
    
    /// 缩略图
    public var thumbnail: WYChatAssetsModel
    
    /// 初始化方法
    public init(original: WYChatAssetsModel = WYChatAssetsModel(),
                thumbnail: WYChatAssetsModel = WYChatAssetsModel()) {
        self.original = original
        self.thumbnail = thumbnail
    }
}
