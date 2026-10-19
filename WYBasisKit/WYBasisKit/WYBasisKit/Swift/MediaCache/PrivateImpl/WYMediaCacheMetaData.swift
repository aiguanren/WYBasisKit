//
//  WYMediaCacheMetaData.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation

/// 已缓存区间的内存索引(左闭右开区间按起点升序存放，相邻或重叠的区间在插入时自动合并)
struct WYMediaCacheIntervalIndex {

    /// 已合并排序好的区间列表
    private(set) var ranges: [Range<Int64>] = []

    /// 已缓存的字节总数
    var cachedBytes: Int64 {
        return ranges.reduce(0) { $0 + ($1.upperBound - $1.lowerBound) }
    }

    /// 插入一个区间，并把与它相邻或重叠的区间合并成一条
    mutating func insert(_ range: Range<Int64>) {
        guard range.lowerBound < range.upperBound else { return }
        var merged = Range<Int64>(uncheckedBounds: (range.lowerBound, range.upperBound))
        var result: [Range<Int64>] = []
        for existing in ranges {
            // 与合并中的区间既不相邻也不重叠的原样保留，相差 1 字节也算相邻，避免区间列表越攒越多
            if existing.upperBound < merged.lowerBound - 1 || existing.lowerBound > merged.upperBound + 1 {
                result.append(existing)
            }else {
                merged = Range<Int64>(uncheckedBounds: (min(existing.lowerBound, merged.lowerBound), max(existing.upperBound, merged.upperBound)))
            }
        }
        result.append(merged)
        result.sort { $0.lowerBound < $1.lowerBound }
        ranges = result
    }

    /// 找到覆盖指定偏移的已缓存区间(该偏移处已有数据时返回所在区间，否则返回 nil)
    func range(covering offset: Int64) -> Range<Int64>? {
        for range in ranges where range.contains(offset) {
            return range
        }
        return nil
    }

    /// 从指定偏移起找第一个没缓存的字节偏移(从 offset 到 limit 全部已缓存时返回 nil)
    func firstGapStart(after offset: Int64, limit: Int64) -> Int64? {
        var cursor = offset
        for range in ranges {
            if range.lowerBound <= cursor {
                cursor = max(cursor, range.upperBound)
            }else {
                break
            }
        }
        return cursor < limit ? cursor : nil
    }
}

/// 缓存条目的落盘元数据(与媒体数据文件同名存放，记录文件总大小、已缓存区间与最近使用时间)
struct WYMediaCacheMetaData: Codable {

    /// 原始播放地址(仅供排查缓存目录时辨认条目，不参与查找)
    var url: String = ""

    /// 媒体文件总大小，单位为字节(还没从服务器取到文件信息时为 0)
    var contentLength: Int64 = 0

    /// 服务器返回的媒体类型(如 video/mp4)
    var mimeType: String?

    /// 已缓存区间列表，每项为 [区间起点, 区间终点)，终点不包含在内
    var ranges: [[Int64]] = []

    /// 条目创建时间
    var creationDate: Date = Date()

    /// 最近一次使用时间(播放、查询状态、预下载都会刷新，容量超出时按它从旧到新淘汰)
    var lastAccessDate: Date = Date()

    /// 从内存索引生成可落盘的元数据
    static func metaData(url: String, contentLength: Int64, mimeType: String?, index: WYMediaCacheIntervalIndex, creationDate: Date, lastAccessDate: Date) -> WYMediaCacheMetaData {
        var metaData = WYMediaCacheMetaData()
        metaData.url = url
        metaData.contentLength = contentLength
        metaData.mimeType = mimeType
        metaData.ranges = index.ranges.map { [$0.lowerBound, $0.upperBound] }
        metaData.creationDate = creationDate
        metaData.lastAccessDate = lastAccessDate
        return metaData
    }

    /// 生成内存索引
    func intervalIndex() -> WYMediaCacheIntervalIndex {
        var index = WYMediaCacheIntervalIndex()
        for range in ranges where range.count == 2 && range[0] < range[1] {
            index.insert(Range<Int64>(uncheckedBounds: (range[0], range[1])))
        }
        return index
    }
}
