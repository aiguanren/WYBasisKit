//
//  WYChatLocationModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/9/28.
//

import Foundation

/// 定位消息Model
public struct WYChatLocationModel {
    
    /// 定位封面
    public var cover: WYChatAssetsModel
    
    /// 定位标题
    public var title: String
    
    /// 定位详细地址
    public var address: String
    
    /// 定位经度
    public var longitude: String
    
    /// 定位纬度
    public var latitude: String
    
    /// 初始化方法
    public init(cover: WYChatAssetsModel = WYChatAssetsModel(),
                title: String = "",
                address: String = "",
                longitude: String = "",
                latitude: String = "") {
        self.cover = cover
        self.title = title
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
    }
}
