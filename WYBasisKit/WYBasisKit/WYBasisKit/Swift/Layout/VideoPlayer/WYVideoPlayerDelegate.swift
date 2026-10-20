//
//  WYVideoPlayerDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

/// 播放器状态
@objc public enum WYVideoPlayerState: Int {

    /// 还没有装载任何视频
    case idle = 0

    /// 视频装载中，还没准备好可以播
    case preparing

    /// 已准备好可以播(第一次可播的瞬间回调)
    case readyToPlay

    /// 正在播放
    case playing

    /// 暂停中
    case paused

    /// 播放中遇到缓冲等待(网络跟不上，画面停住等数据)
    case buffering

    /// 定位中
    case seeking

    /// 已停止并释放了资源
    case stopped

    /// 播放失败，错误经代理 wy_videoPlayer(_:didFailWithError:) 抛出
    case failed
}

/// 播放器代理
@objc public protocol WYVideoPlayerDelegate: NSObjectProtocol {

    /**
     *  播放状态变化
     *
     *  @param player       播放器组件
     *  @param state        新状态，失败原因经 wy_videoPlayer(_:didFailWithError:) 单独抛出
     *
     */
    @objc(wy_videoPlayer:stateDidChange:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, stateDidChange state: WYVideoPlayerState)

    /**
     *  播放进度周期回调
     *
     *  @param player           播放器组件
     *  @param currentTime      当前播放位置，单位为秒
     *  @param duration         视频总时长，单位为秒
     *  @param playableDuration 已缓冲可以播到的位置，单位为秒
     *
     */
    @objc(wy_videoPlayer:currentTime:duration:playableDuration:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, currentTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval)

    /**
     *  播放失败
     *
     *  @param player       播放器组件
     *  @param error        失败原因
     *
     */
    @objc(wy_videoPlayer:didFailWithError:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, didFailWithError error: Error)

    /**
     *  播完一轮(设置了循环会每轮回调)
     *
     *  @param player       播放器组件
     *  @param loopIndex    已播完第几轮，从 1 开始
     *
     */
    @objc(wy_videoPlayer:didPlayToEndWithLoopIndex:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, didPlayToEndWithLoopIndex loopIndex: Int)

    /**
     *  定位完成
     *
     *  @param player       播放器组件
     *  @param finished     true 表示定位成功落定
     *
     */
    @objc(wy_videoPlayer:seekDidEndWithFinished:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, seekDidEndWithFinished finished: Bool)

    /**
     *  全屏状态变化
     *
     *  @param player       播放器组件
     *  @param isFullscreen true 表示进入了全屏
     *
     */
    @objc(wy_videoPlayer:fullscreenDidChange:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, fullscreenDidChange isFullscreen: Bool)

    /**
     *  单击画面(默认行为是切换控制壳显隐，实现此回调不影响默认行为)
     *
     *  @param player       播放器组件
     *
     */
    @objc(wy_videoPlayerDidSingleTap:)
    optional func wy_videoPlayerDidSingleTap(_ player: WYVideoPlayer)

    /**
     *  双击画面(默认行为是切换播放暂停，实现此回调不影响默认行为)
     *
     *  @param player       播放器组件
     *
     */
    @objc(wy_videoPlayerDidDoubleTap:)
    optional func wy_videoPlayerDidDoubleTap(_ player: WYVideoPlayer)

    /**
     *  长按临时倍速开始
     *
     *  @param player       播放器组件
     *  @param rate         长按期间使用的倍速
     *
     */
    @objc(wy_videoPlayer:rateLongPressBeganWithRate:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, rateLongPressBeganWithRate rate: Float)

    /**
     *  长按临时倍速结束，回到长按前的倍速
     *
     *  @param player       播放器组件
     *
     */
    @objc(wy_videoPlayerRateLongPressEnded:)
    optional func wy_videoPlayerRateLongPressEnded(_ player: WYVideoPlayer)

    /**
     *  横滑快进快退结束落定
     *
     *  @param player       播放器组件
     *  @param targetTime   落定到的播放位置，单位为秒
     *
     */
    @objc(wy_videoPlayer:seekPanDidEndWithTargetTime:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, seekPanDidEndWithTargetTime targetTime: TimeInterval)

    /**
     *  截图完成
     *
     *  @param player       播放器组件
     *  @param image        截出的当前画面，取不到时为 nil
     *
     */
    @objc(wy_videoPlayer:didTakeSnapshot:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, didTakeSnapshot image: UIImage?)

    /**
     *  清晰度切换完成
     *
     *  @param player       播放器组件
     *  @param qualityIndex 切到第几档，从 0 开始
     *
     */
    @objc(wy_videoPlayer:qualityDidChangeAtIndex:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, qualityDidChangeAtIndex qualityIndex: Int)

    /**
     *  字幕轨切换完成
     *
     *  @param player       播放器组件
     *  @param trackIndex   切到第几条字幕轨，从 0 开始，-1 表示关闭字幕
     *
     */
    @objc(wy_videoPlayer:subtitleDidChangeAtIndex:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, subtitleDidChangeAtIndex trackIndex: Int)

    /**
     *  画中画状态变化
     *
     *  @param player       播放器组件
     *  @param isPlaying    true 表示进入了画中画小窗播放
     *
     */
    @objc(wy_videoPlayer:pipDidChangeWithPlaying:)
    optional func wy_videoPlayer(_ player: WYVideoPlayer, pipDidChangeWithPlaying isPlaying: Bool)
}
