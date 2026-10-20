//
//  WYVideoPlayerConfig.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 点播播放器的实例级配置(外观给到每个元素、开关给到每个功能，改动后按各条注释说明的生效时机生效)
public class WYVideoPlayerConfig {

    /// 装载完成后是否自动开播(默认 true)
    public var shouldAutoplay = true

    /// 循环播放轮数(0 表示无限循环，1 表示只播一遍，默认 1)
    public var loopCount = 1

    /// 初始倍速(0.5~2.0，越界取 1.0，默认 1.0)
    public var preferredRate: Float = 1.0

    /// 初始是否静音(默认 false)
    public var shouldMuteByDefault = false

    /// 播放进度回调间隔，单位为秒(默认 0.5)
    public var progressCallbackInterval: TimeInterval = 0.5

    /// 回前台是否自动续播(进后台按系统行为停住，默认 true)
    public var shouldResumeOnAppActive = true

    /// 进后台是否暂停播放(默认 true，画面本就会被系统中断，这里决定回前台是否需要手动续)
    public var shouldPauseOnAppResignActive = true

    /// 是否经 WYMediaCache 边下边播(默认 true，关闭后直连原地址播放)
    public var usesMediaCache = true

    /// 是否内置弹幕视图(默认 false，开启后播放器自带一个 WYDanmakuView 并随播放时间驱动)
    public var showsDanmaku = false

    /// 内置弹幕的外观与行为配置(只在内置弹幕开启时生效)
    public var danmakuConfiguration = WYDanmakuConfiguration()

    /// 单击画面是否切换控制壳显隐(默认 true)
    public var allowsTapGesture = true

    /// 双击画面是否切换播放暂停(默认 true)
    public var allowsDoubleTapGesture = true

    /// 是否允许横滑快进快退(默认 true)
    public var allowsSeekPanGesture = true

    /// 横滑快进的灵敏度(每 pt 滑动换算的秒数，越大越灵敏，默认 1.0)
    public var seekPanSensitivity: CGFloat = 1.0

    /// 是否允许长按临时倍速(默认 true)
    public var allowsRateLongPressGesture = true

    /// 长按期间的临时倍速(默认 2.0)
    public var longPressRate: Float = 2.0

    /// 是否允许画面左侧竖滑调音量、右侧竖滑调亮度(默认 true)
    public var allowsVolumeBrightnessPanGesture = true

    /// 是否允许全屏切换(默认 true)
    public var allowsFullscreenToggle = true

    /// 是否允许画中画(默认 true，系统不支持时自动失效)
    public var allowsPictureInPicture = true

    /// 是否允许投屏(默认 true，控制壳上显示投屏入口)
    public var allowsAirPlay = true

    /// 倍速可选项(控制壳倍速菜单按这个列表展示，默认 0.5~2.0 六档)
    public var rateOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    /// 控制壳无操作自动隐藏的间隔，单位为秒(默认 4，0 表示不自动隐藏)
    public var shellAutoHideInterval: TimeInterval = 4

    /// 是否装载默认控制壳(默认 true，关闭后无壳裸播，适合自定义壳或纯画面场景)
    public var showsDefaultShell = true

    /// 控制壳底栏是否显示倍速按钮(默认 true)
    public var shellShowsRateButton = true

    /// 控制壳底栏是否显示清晰度按钮(多档素材时按钮才有效，默认 true)
    public var shellShowsQualityButton = true

    /// 控制壳底栏是否显示字幕按钮(默认 true)
    public var shellShowsSubtitleButton = true

    /// 控制壳底栏是否显示弹幕开关按钮(内置弹幕开启时按钮才有动作，默认 true)
    public var shellShowsDanmakuButton = true

    /// 控制壳底栏是否显示截图按钮(默认 false)
    public var shellShowsSnapshotButton = false

    /// 控制壳底栏是否显示投屏按钮(默认 true)
    public var shellShowsAirPlayButton = true

    /// 控制壳底栏是否显示循环按钮(默认 false)
    public var shellShowsLoopButton = false

    /// 控制壳顶栏背景色(默认黑色六成透明)
    public var shellBarBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.6)

    /// 进度条底轨颜色(默认白色三成透明)
    public var progressTrackColor: UIColor = UIColor(white: 1, alpha: 0.3)

    /// 进度条已缓冲段颜色(默认白色五成五透明)
    public var progressBufferColor: UIColor = UIColor(white: 1, alpha: 0.55)

    /// 进度条已播段颜色(默认系统蓝色)
    public var progressPlayColor: UIColor = .systemBlue

    /// 进度条滑块颜色(默认白色)
    public var progressThumbColor: UIColor = .white

    /// 控制壳按钮颜色(默认白色)
    public var shellButtonTintColor: UIColor = .white

    /// 控制壳时间文字字号(默认 12)
    public var shellTimeFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))

    /// 控制壳时间文字颜色(默认白色)
    public var shellTimeColor: UIColor = .white

    /// 控制壳顶栏标题字号(默认 15)
    public var shellTitleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 控制壳顶栏标题颜色(默认白色)
    public var shellTitleColor: UIColor = .white

    /// 字幕文字字号(默认 16)
    public var subtitleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))

    /// 字幕文字颜色(默认白色)
    public var subtitleTextColor: UIColor = .white

    /// 字幕文字描边颜色(默认黑色)
    public var subtitleStrokeColor: UIColor = .black

    /// 字幕文字描边宽度(负数表示描边同时保留文字填充，默认 -2)
    public var subtitleStrokeWidth: CGFloat = -2

    /// 字幕距播放器底边的距离，单位为pt(默认 12)
    public var subtitleBottomInset: CGFloat = UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels)

    /// 手势提示浮层背景色(默认黑色六成透明)
    public var gestureOverlayBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.6)

    /// 手势提示浮层文字颜色(默认白色)
    public var gestureOverlayTextColor: UIColor = .white

    /// 播放按钮图标(nil 用系统 SF Symbol 播放三角)
    public var playImage: UIImage?

    /// 暂停按钮图标(nil 用系统 SF Symbol)
    public var pauseImage: UIImage?

    /// 返回按钮图标
    public var backImage: UIImage?

    /// 进入全屏按钮图标
    public var fullscreenEnterImage: UIImage?

    /// 退出全屏按钮图标
    public var fullscreenExitImage: UIImage?

    /// 倍速按钮图标
    public var rateImage: UIImage?

    /// 清晰度按钮图标
    public var qualityImage: UIImage?

    /// 字幕按钮图标
    public var subtitleImage: UIImage?

    /// 弹幕开按钮图标
    public var danmakuOnImage: UIImage?

    /// 弹幕关按钮图标
    public var danmakuOffImage: UIImage?

    /// 截图按钮图标
    public var snapshotImage: UIImage?

    /// 投屏按钮图标
    public var airPlayImage: UIImage?

    /// 循环按钮图标
    public var loopImage: UIImage?

    /// 静音按钮图标
    public var muteImage: UIImage?

    /// 有声按钮图标
    public var volumeImage: UIImage?

    /// 菜单面板背景色(倍速清晰度字幕选择浮层的底色，默认黑色七成五透明)
    public var menuPanelBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.75)

    /// 菜单面板选中项颜色(默认系统蓝色)
    public var menuSelectedColor: UIColor = .systemBlue

    /// 菜单面板未选中项颜色(默认白色)
    public var menuNormalColor: UIColor = .white
}
