//
//  WYVideoPlayerMoreAction.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

import UIKit

/// 播放器控制栏中的控件
@objc public enum WYVideoPlayerControl: Int {
    /// 播放与暂停
    case playPause
    /// 当前播放时间
    case currentTime
    /// 播放进度条
    case progress
    /// 视频总时长
    case duration
    /// 返回
    case back
    /// 标题
    case title
    /// 全屏切换
    case fullscreen
    /// 倍速
    case rate
    /// 清晰度
    case quality
    /// 字幕
    case subtitle
    /// 弹幕开关
    case danmaku
    /// 截图
    case snapshot
    /// 投屏
    case airPlay
    /// 画中画
    case pictureInPicture
    /// 更多功能
    case more
    /// 循环播放
    case loop
    /// 中央播放按钮
    case centerPlay
    /// 自动占据剩余空间的间隔，可重复放置
    case flexibleSpace
}

/// 更多面板中的功能类型
@objc public enum WYVideoPlayerMoreActionKind: Int {
    /// 画中画
    case pictureInPicture
    /// 定时关闭
    case sleepTimer
    /// 下载当前视频
    case download
    /// 倍速
    case playbackRate
    /// 音频播放
    case audioOnly
    /// 后台播放
    case backgroundPlayback
    /// 循环播放
    case loopPlayback
    /// 自定义功能
    case custom
    /// 清晰度
    case quality
    /// 字幕
    case subtitle
}

/// 更多面板中的功能项目
public struct WYVideoPlayerMoreAction {

    /// 功能类型
    public var kind: WYVideoPlayerMoreActionKind

    /// 功能标识，自定义功能可据此区分
    public var identifier: String

    /// 显示名称，nil 使用功能类型的默认名称
    public var title: String?

    /// 功能图标，nil 使用功能类型的默认图标
    public var image: UIImage?

    /// 是否允许点击(默认 true)
    public var isEnabled: Bool

    /// 自定义项目是否显示为选中(默认 false)
    public var isSelected: Bool

    /// 点击回调，参数为播放器，设置后替代该项目的内置动作
    public var handler: ((_ player: WYVideoPlayer) -> Void)?

    /**
     *  创建更多功能项目
     *
     *  @param kind          功能类型
     *  @param identifier    功能标识，自定义项目可传入自己的标识
     *  @param title         显示名称，nil 使用默认名称
     *  @param image         功能图标，nil 使用默认图标
     *  @param isEnabled     是否允许点击
     *  @param isSelected    自定义项目是否显示为选中
     *  @param handler       点击回调，参数为播放器，nil 执行内置动作
     *
     */
    public init(kind: WYVideoPlayerMoreActionKind, identifier: String = "", title: String? = nil, image: UIImage? = nil, isEnabled: Bool = true, isSelected: Bool = false, handler: ((_ player: WYVideoPlayer) -> Void)? = nil) {
        self.kind = kind
        self.identifier = identifier.isEmpty ? String(kind.rawValue) : identifier
        self.title = title
        self.image = image
        self.isEnabled = isEnabled
        self.isSelected = isSelected
        self.handler = handler
    }
}
