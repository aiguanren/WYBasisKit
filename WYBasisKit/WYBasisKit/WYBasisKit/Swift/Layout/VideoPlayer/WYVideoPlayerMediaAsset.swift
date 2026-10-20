//
//  WYVideoPlayerMediaAsset.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation

/// 一档清晰度
public struct WYVideoPlayerMediaQuality {

    /// 展示名，如 标清、高清、1080P
    public let name: String

    /// 该档的播放地址
    public let url: URL

    /// 是否 HLS master 播放列表(是则档位切换交给系统自适应，不按本档地址重载)
    public let isHLSMaster: Bool

    /**
     *  建一档清晰度
     *
     *  @param name         展示名
     *  @param url          播放地址
     *  @param isHLSMaster  是否 HLS master 播放列表，默认 false
     *
     */
    public init(name: String, url: URL, isHLSMaster: Bool = false) {
        self.name = name
        self.url = url
        self.isHLSMaster = isHLSMaster
    }
}

/// 一部视频的播放素材(带多档清晰度清单，切换时记住进度无缝续播)
public struct WYVideoPlayerMediaAsset {

    /// 全部可选清晰度，至少一档
    public let qualities: [WYVideoPlayerMediaQuality]

    /// 当前选中的档位下标，从 0 开始
    public private(set) var selectedIndex: Int

    /**
     *  建播放素材
     *
     *  @param qualities       清晰度清单，至少一档
     *  @param defaultIndex    初始档位下标，越界时取 0
     *
     */
    public init(qualities: [WYVideoPlayerMediaQuality], defaultIndex: Int = 0) {
        assert(qualities.isEmpty == false, "qualities 至少要有一档")
        self.qualities = qualities
        self.selectedIndex = qualities.indices.contains(defaultIndex) ? defaultIndex : 0
    }

    /**
     *  用单个地址建单档素材
     *
     *  @param url     播放地址
     *  @param name    展示名，默认 原画
     *
     */
    public init(url: URL, name: String = WYLocalized("原画", table: WYBasisKitConfig.kitLocalizableTable)) {
        self.init(qualities: [WYVideoPlayerMediaQuality(name: name, url: url)])
    }

    /// 当前档
    public var currentQuality: WYVideoPlayerMediaQuality {
        return qualities[selectedIndex]
    }

    /// 选中指定档(越界忽略，由播放器负责记进度重载)
    public mutating func selectQuality(at index: Int) {
        if qualities.indices.contains(index) {
            selectedIndex = index
        }
    }
}
