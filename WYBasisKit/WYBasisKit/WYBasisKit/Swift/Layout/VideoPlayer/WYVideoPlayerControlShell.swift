//
//  WYVideoPlayerControlShell.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import Foundation
import UIKit

/// 播放器控制壳协议(壳可整体替换，实现本协议的壳交给播放器的 controlShell 属性即可接管全部控制界面)
@objc public protocol WYVideoPlayerControlShell: NSObjectProtocol {

    /// 壳的根视图(播放器会把它加到播放器视图上并铺满)
    var shellView: UIView { get }

    /// 绑定播放器(壳从这里读取播放状态并调用播放器的能力)
    func attach(to player: WYVideoPlayer)

    /// 与播放器解绑(壳被替换或播放器销毁时回调)
    func detach()

    /// 壳是否正在显示
    var isShellVisible: Bool { get }

    /**
     *  显示壳
     *
     *  @param animated    是否带显隐动画
     *
     */
    func showShell(animated: Bool)

    /**
     *  隐藏壳
     *
     *  @param animated    是否带显隐动画
     *
     */
    func hideShell(animated: Bool)

    /**
     *  进度刷新(播放中周期回调，壳自行决定展示节流)
     *
     *  @param currentTime      当前播放位置，单位为秒
     *  @param duration         视频总时长，单位为秒
     *  @param playableDuration 已缓冲可以播到的位置，单位为秒
     *
     */
    func updateProgress(currentTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval)

    /**
     *  播放状态刷新
     *
     *  @param state    新状态
     *
     */
    func updateState(_ state: WYVideoPlayerState)

    /**
     *  倍速刷新
     *
     *  @param rate     当前倍速
     *
     */
    func updateRate(_ rate: Float)

    /**
     *  静音刷新
     *
     *  @param isMuted  是否静音
     *
     */
    func updateMuted(_ isMuted: Bool)

    /**
     *  全屏状态刷新
     *
     *  @param isFullscreen    是否全屏
     *
     */
    func updateFullscreen(_ isFullscreen: Bool)

    /**
     *  清晰度与字幕清单刷新
     *
     *  @param qualityNames            各档清晰度名
     *  @param selectedQualityIndex    当前档下标，从 0 开始
     *  @param subtitleNames           各条字幕轨名，含 关闭 占位
     *  @param selectedSubtitleIndex   当前字幕轨下标，-1 表示关闭
     *
     */
    func updateMediaInfo(qualityNames: [String], selectedQualityIndex: Int, subtitleNames: [String], selectedSubtitleIndex: Int)

    /**
     *  显示横滑快进预览
     *
     *  @param targetTime   松手将定位到的播放位置，单位为秒
     *  @param delta        相对当前播放位置偏移的秒数，负数为回退
     *
     */
    func showSeekPreview(targetTime: TimeInterval, delta: TimeInterval)

    /// 隐藏横滑快进预览
    func hideSeekPreview()

    /**
     *  显示长按临时倍速提示
     *
     *  @param rate     长按期间的倍速
     *
     */
    func showRatePrompt(rate: Float)

    /// 隐藏长按临时倍速提示
    func hideRatePrompt()

    /**
     *  显示竖滑音量亮度指示
     *
     *  @param isVolume     true 表示在调音量，false 表示在调亮度
     *  @param value        当前值 0~1
     *
     */
    func showPanIndicator(isVolume: Bool, value: Float)

    /// 隐藏竖滑音量亮度指示
    func hidePanIndicator()
}
