//
//  WYChatMediaModel.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 媒体内容类型
@objc public enum WYChatMediaKind: Int { case photo, video }

/// 宿主选择的图片或视频
public struct WYChatMediaItem: Equatable {
    /// 媒体ID
    public var id: String = UUID().uuidString
    /// 媒体类型
    public var kind: WYChatMediaKind = .photo
    /// 图片原图或视频文件
    public var original: WYChatAssetsModel = WYChatAssetsModel()
    /// 列表缩略图或视频封面
    public var thumbnail: WYChatAssetsModel = WYChatAssetsModel()
    /// 原始显示尺寸，零尺寸时使用配置尺寸
    public var size: CGSize = .zero
    /// 视频时长，单位秒
    public var duration: TimeInterval = 0
    public init() {}
}

/// 合并媒体消息
public struct WYChatMediaGroupModel: Equatable {
    /// 媒体列表
    public var items: [WYChatMediaItem] = []
    /// 是否展开为纵向列表，默认false
    public var isExpanded: Bool = false
    /// 叠卡当前显示的媒体下标
    public var visibleIndex: Int = 0
    public init(items: [WYChatMediaItem] = []) { self.items = items }
}

/// 媒体组操作
@objc public enum WYChatMediaAction: Int { case preview, expand, collapse, pageChanged }
