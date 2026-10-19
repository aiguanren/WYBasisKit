//
//  WYMediaCacheDownloadTask.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation

/// 单个视频的一条分块下载任务(从 startOffset 起取一块数据，网络回调由 WYMediaCache 转回所属条目处理)
final class WYMediaCacheDownloadTask: NSObject {

    /// 所属缓存条目(条目由管理器长期持有，这里不强持避免成环)
    weak var item: WYMediaCacheItem?

    /// 本任务从媒体文件的哪个字节偏移开始取
    let startOffset: Int64

    /// 本任务计划取到的字节偏移(不包含在内，取到媒体总长为止)
    var chunkEnd: Int64

    /// 已经收到的字节数(数据落盘与区间登记由所属条目完成)
    var receivedBytes: Int64 = 0

    /// 对应的网络任务(由管理器创建并登记回调路由)
    var sessionTask: URLSessionDataTask?

    /// 是否已主动取消(取消后迟到的数据直接丢弃)
    var isCancelled = false

    init(item: WYMediaCacheItem, startOffset: Int64, chunkSize: Int, contentLength: Int64) {
        self.item = item
        self.startOffset = startOffset
        var end = startOffset + Int64(chunkSize)
        if contentLength > 0 {
            end = min(end, contentLength)
        }
        self.chunkEnd = end
        super.init()
    }
}
