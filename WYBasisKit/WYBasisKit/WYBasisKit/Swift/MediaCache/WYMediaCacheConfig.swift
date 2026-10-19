//
//  WYMediaCacheConfig.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation

/// 视频边下边播的全局缓存配置(修改后对之后新发起的数据请求与下载任务生效，已在下载中的分块沿用旧值)
public class WYMediaCacheConfig {

    /// 全局默认配置(WYMediaCache 用的就是这份实例，直接改它的属性即可全局生效)
    public static let shared = WYMediaCacheConfig()

    /// 拦截播放地址使用的自定义URL协议头(播放地址经 WYMediaCache 的 cacheURL(for:) 换成这个协议头后，数据请求才会经过缓存层，不要填 http/https 等系统会自己处理的协议头)
    public var scheme: String = "wy-media"

    /// 缓存总容量上限，单位为字节(超过后按最久未使用的顺序淘汰闲置条目，0 表示不限制容量)
    public var maxCacheSize: Int64 = 512 * 1024 * 1024

    /// 单个下载任务一次请求的数据量，单位为字节(按块请求、按块落盘，播放到未缓存区域时一次取回一整块)
    public var downloadChunkSize: Int = 2 * 1024 * 1024

    /// 同一个视频同时进行的下载任务数上限(播放器在不同位置的取数请求各占一个任务，1 表示只顺着一条缺口顺序下载)
    public var maxConcurrentDownloadCount: Int = 2

    /// 单个下载任务的请求超时秒数
    public var downloadTimeout: TimeInterval = 30

    /// 全部视频同时进行的下载任务总数上限(播放与预下载共用这条限制，0 表示不限制总数，只受单视频上限约束)
    public var maxTotalDownloadTaskCount: Int = 0

    /// 元数据落盘节流秒数(缓存区间变化后最短隔这么多秒才写一次磁盘，0 表示每次变化立即落盘)
    public var metaDataSaveInterval: TimeInterval = 3

    /// 预下载进度回调节流秒数(最短隔这么多秒回调一次进度，0 表示每收到一段数据都回调)
    public var progressNotifyInterval: TimeInterval = 0.2

    /// 单次喂给播放器的数据量上限，单位为字节(防止超长请求一次性整段读进内存，一般不需要改)
    public var maxRespondLength: Int64 = 4 * 1024 * 1024

    /// 缓存根目录(默认为沙盒 Caches/WYBasisKit/MediaCache，传入自定义目录时需保证该目录可写，改动只对之后新建的缓存条目生效)
    public lazy var cacheDirectory: URL = WYStorage.createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/MediaCache")

    /// 蜂窝网络下遇到不小于该大小的视频先弹窗征询用户，单位为字节(0 表示不弹窗，同一视频在一次进入前台到下次进后台之间只征询一次)
    public var cellularConfirmSizeLimit: Int64 = 0

    /// 蜂窝确认弹窗标题
    public var cellularConfirmTitle: String = "正在使用蜂窝网络"

    /// 蜂窝确认弹窗内容(格式化时以 %.1fMB 填入视频总大小，改文案时保留这个占位符)
    public var cellularConfirmMessage: String = "当前视频约 %.1fMB，继续播放或下载将消耗蜂窝流量，是否继续？"

    /// 蜂窝确认弹窗继续按钮文案
    public var cellularConfirmContinueTitle: String = "继续"

    /// 蜂窝确认弹窗取消按钮文案
    public var cellularConfirmCancelTitle: String = "取消"
}
