//
//  WYVideoPlayerConfigObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import AVKit
import UIKit
import WYBasisKitSwift

/// 点播播放器的实例级配置(外观给到每个元素、开关给到每个功能，改动后按各条注释说明的生效时机生效，属性转调播放器持有的同一份配置实例)
@objc(WYVideoPlayerConfig)
@objcMembers public class WYVideoPlayerConfigObjC: NSObject {

    /// 底层配置实例
    let configuration: WYVideoPlayerConfig

    init(configuration: WYVideoPlayerConfig) {
        self.configuration = configuration
        super.init()
    }

    /// 装载完成后是否自动开播(默认 true)
    public var shouldAutoplay: Bool {
        get { return configuration.shouldAutoplay }
        set { configuration.shouldAutoplay = newValue }
    }

    /// 循环播放轮数(0 表示无限循环，1 表示只播一遍，默认 1)
    public var loopCount: Int {
        get { return configuration.loopCount }
        set { configuration.loopCount = newValue }
    }

    /// 初始倍速(0.5~2.0，越界取 1.0，默认 1.0)
    public var preferredRate: Float {
        get { return configuration.preferredRate }
        set { configuration.preferredRate = newValue }
    }

    /// 初始是否静音(默认 false)
    public var shouldMuteByDefault: Bool {
        get { return configuration.shouldMuteByDefault }
        set { configuration.shouldMuteByDefault = newValue }
    }

    /// 播放进度回调间隔，单位为秒(默认 0.5)
    public var progressCallbackInterval: TimeInterval {
        get { return configuration.progressCallbackInterval }
        set { configuration.progressCallbackInterval = newValue }
    }

    /// 回前台是否自动续播(进后台按系统行为停住，默认 true)
    public var shouldResumeOnAppActive: Bool {
        get { return configuration.shouldResumeOnAppActive }
        set { configuration.shouldResumeOnAppActive = newValue }
    }

    /// 进后台是否暂停播放(默认 true，画面本就会被系统中断，这里决定回前台是否需要手动续)
    public var shouldPauseOnAppResignActive: Bool {
        get { return configuration.shouldPauseOnAppResignActive }
        set { configuration.shouldPauseOnAppResignActive = newValue }
    }

    /// 是否经 WYMediaCache 边下边播(默认 true，关闭后直连原地址播放)
    public var usesMediaCache: Bool {
        get { return configuration.usesMediaCache }
        set { configuration.usesMediaCache = newValue }
    }

    /// 是否内置弹幕视图(默认 false，开启后播放器自带一个 WYDanmakuView 并随播放时间驱动)
    public var showsDanmaku: Bool {
        get { return configuration.showsDanmaku }
        set { configuration.showsDanmaku = newValue }
    }

    /// 内置弹幕的外观与行为配置(只在内置弹幕开启时生效)
    public var danmakuConfiguration: WYDanmakuConfigurationObjC {
        get { return WYDanmakuConfigurationObjC(configuration: configuration.danmakuConfiguration) }
        set { configuration.danmakuConfiguration = newValue.configuration }
    }

    /// 单击画面是否切换控制壳显隐(默认 true)
    public var allowsTapGesture: Bool {
        get { return configuration.allowsTapGesture }
        set { configuration.allowsTapGesture = newValue }
    }

    /// 双击画面是否切换播放暂停(默认 true)
    public var allowsDoubleTapGesture: Bool {
        get { return configuration.allowsDoubleTapGesture }
        set { configuration.allowsDoubleTapGesture = newValue }
    }

    /// 是否允许横滑快进快退(默认 true)
    public var allowsSeekPanGesture: Bool {
        get { return configuration.allowsSeekPanGesture }
        set { configuration.allowsSeekPanGesture = newValue }
    }

    /// 横滑快进的灵敏度(每 pt 滑动换算的秒数，越大越灵敏，默认 1.0)
    public var seekPanSensitivity: CGFloat {
        get { return configuration.seekPanSensitivity }
        set { configuration.seekPanSensitivity = newValue }
    }

    /// 是否允许长按临时倍速(默认 true)
    public var allowsRateLongPressGesture: Bool {
        get { return configuration.allowsRateLongPressGesture }
        set { configuration.allowsRateLongPressGesture = newValue }
    }

    /// 长按期间的临时倍速(默认 2.0)
    public var longPressRate: Float {
        get { return configuration.longPressRate }
        set { configuration.longPressRate = newValue }
    }

    /// 是否允许画面左侧竖滑调音量、右侧竖滑调亮度(默认 true)
    public var allowsVolumeBrightnessPanGesture: Bool {
        get { return configuration.allowsVolumeBrightnessPanGesture }
        set { configuration.allowsVolumeBrightnessPanGesture = newValue }
    }

    /// 是否允许全屏切换(默认 true)
    public var allowsFullscreenToggle: Bool {
        get { return configuration.allowsFullscreenToggle }
        set { configuration.allowsFullscreenToggle = newValue }
    }

    /// 是否允许画中画(默认 true，系统不支持时自动失效)
    public var allowsPictureInPicture: Bool {
        get { return configuration.allowsPictureInPicture }
        set { configuration.allowsPictureInPicture = newValue }
    }

    /// 是否允许投屏(默认 true，控制壳上显示投屏入口)
    public var allowsAirPlay: Bool {
        get { return configuration.allowsAirPlay }
        set { configuration.allowsAirPlay = newValue }
    }

    /// 倍速可选项(控制壳倍速菜单按这个列表展示，默认 0.5~2.0 六档)
    public var rateOptions: [Float] {
        get { return configuration.rateOptions }
        set { configuration.rateOptions = newValue }
    }

    /// 控制壳无操作自动隐藏的间隔，单位为秒(默认 4，0 表示不自动隐藏)
    public var shellAutoHideInterval: TimeInterval {
        get { return configuration.shellAutoHideInterval }
        set { configuration.shellAutoHideInterval = newValue }
    }

    /// 是否装载默认控制壳(默认 true，关闭后无壳裸播，适合自定义壳或纯画面场景)
    public var showsDefaultShell: Bool {
        get { return configuration.showsDefaultShell }
        set { configuration.showsDefaultShell = newValue }
    }

    /// 控制壳底栏是否显示倍速按钮(默认 true)
    public var shellShowsRateButton: Bool {
        get { return configuration.shellShowsRateButton }
        set { configuration.shellShowsRateButton = newValue }
    }

    /// 控制壳底栏是否显示清晰度按钮(多档素材时按钮才有效，默认 true)
    public var shellShowsQualityButton: Bool {
        get { return configuration.shellShowsQualityButton }
        set { configuration.shellShowsQualityButton = newValue }
    }

    /// 控制壳底栏是否显示字幕按钮(默认 true)
    public var shellShowsSubtitleButton: Bool {
        get { return configuration.shellShowsSubtitleButton }
        set { configuration.shellShowsSubtitleButton = newValue }
    }

    /// 控制壳底栏是否显示弹幕开关按钮(内置弹幕开启时按钮才有动作，默认 true)
    public var shellShowsDanmakuButton: Bool {
        get { return configuration.shellShowsDanmakuButton }
        set { configuration.shellShowsDanmakuButton = newValue }
    }

    /// 控制壳底栏是否显示截图按钮(默认 false)
    public var shellShowsSnapshotButton: Bool {
        get { return configuration.shellShowsSnapshotButton }
        set { configuration.shellShowsSnapshotButton = newValue }
    }

    /// 控制壳底栏是否显示投屏按钮(默认 true)
    public var shellShowsAirPlayButton: Bool {
        get { return configuration.shellShowsAirPlayButton }
        set { configuration.shellShowsAirPlayButton = newValue }
    }

    /// 控制壳底栏是否显示循环按钮(默认 false)
    public var shellShowsLoopButton: Bool {
        get { return configuration.shellShowsLoopButton }
        set { configuration.shellShowsLoopButton = newValue }
    }

    /// 控制壳顶栏背景色(默认黑色六成透明)
    public var shellBarBackgroundColor: UIColor {
        get { return configuration.shellBarBackgroundColor }
        set { configuration.shellBarBackgroundColor = newValue }
    }

    /// 进度条底轨颜色(默认白色三成透明)
    public var progressTrackColor: UIColor {
        get { return configuration.progressTrackColor }
        set { configuration.progressTrackColor = newValue }
    }

    /// 进度条已缓冲段颜色(默认白色五成五透明)
    public var progressBufferColor: UIColor {
        get { return configuration.progressBufferColor }
        set { configuration.progressBufferColor = newValue }
    }

    /// 进度条已播段颜色(默认系统蓝色)
    public var progressPlayColor: UIColor {
        get { return configuration.progressPlayColor }
        set { configuration.progressPlayColor = newValue }
    }

    /// 进度条滑块颜色(默认白色)
    public var progressThumbColor: UIColor {
        get { return configuration.progressThumbColor }
        set { configuration.progressThumbColor = newValue }
    }

    /// 控制壳按钮颜色(默认白色)
    public var shellButtonTintColor: UIColor {
        get { return configuration.shellButtonTintColor }
        set { configuration.shellButtonTintColor = newValue }
    }

    /// 控制壳时间文字字号(默认 12)
    public var shellTimeFont: UIFont {
        get { return configuration.shellTimeFont }
        set { configuration.shellTimeFont = newValue }
    }

    /// 控制壳时间文字颜色(默认白色)
    public var shellTimeColor: UIColor {
        get { return configuration.shellTimeColor }
        set { configuration.shellTimeColor = newValue }
    }

    /// 控制壳顶栏标题字号(默认 15)
    public var shellTitleFont: UIFont {
        get { return configuration.shellTitleFont }
        set { configuration.shellTitleFont = newValue }
    }

    /// 控制壳顶栏标题颜色(默认白色)
    public var shellTitleColor: UIColor {
        get { return configuration.shellTitleColor }
        set { configuration.shellTitleColor = newValue }
    }

    /// 字幕文字字号(默认 16)
    public var subtitleFont: UIFont {
        get { return configuration.subtitleFont }
        set { configuration.subtitleFont = newValue }
    }

    /// 字幕文字颜色(默认白色)
    public var subtitleTextColor: UIColor {
        get { return configuration.subtitleTextColor }
        set { configuration.subtitleTextColor = newValue }
    }

    /// 字幕文字描边颜色(默认黑色)
    public var subtitleStrokeColor: UIColor {
        get { return configuration.subtitleStrokeColor }
        set { configuration.subtitleStrokeColor = newValue }
    }

    /// 字幕文字描边宽度(负数表示描边同时保留文字填充，默认 -2)
    public var subtitleStrokeWidth: CGFloat {
        get { return configuration.subtitleStrokeWidth }
        set { configuration.subtitleStrokeWidth = newValue }
    }

    /// 字幕距播放器底边的距离，单位为pt(默认 12)
    public var subtitleBottomInset: CGFloat {
        get { return configuration.subtitleBottomInset }
        set { configuration.subtitleBottomInset = newValue }
    }

    /// 手势提示浮层背景色(默认黑色六成透明)
    public var gestureOverlayBackgroundColor: UIColor {
        get { return configuration.gestureOverlayBackgroundColor }
        set { configuration.gestureOverlayBackgroundColor = newValue }
    }

    /// 手势提示浮层文字颜色(默认白色)
    public var gestureOverlayTextColor: UIColor {
        get { return configuration.gestureOverlayTextColor }
        set { configuration.gestureOverlayTextColor = newValue }
    }

    /// 播放按钮图标(nil 用系统 SF Symbol 播放三角)
    public var playImage: UIImage? {
        get { return configuration.playImage }
        set { configuration.playImage = newValue }
    }

    /// 暂停按钮图标(nil 用系统 SF Symbol)
    public var pauseImage: UIImage? {
        get { return configuration.pauseImage }
        set { configuration.pauseImage = newValue }
    }

    /// 返回按钮图标
    public var backImage: UIImage? {
        get { return configuration.backImage }
        set { configuration.backImage = newValue }
    }

    /// 进入全屏按钮图标
    public var fullscreenEnterImage: UIImage? {
        get { return configuration.fullscreenEnterImage }
        set { configuration.fullscreenEnterImage = newValue }
    }

    /// 退出全屏按钮图标
    public var fullscreenExitImage: UIImage? {
        get { return configuration.fullscreenExitImage }
        set { configuration.fullscreenExitImage = newValue }
    }

    /// 倍速按钮图标
    public var rateImage: UIImage? {
        get { return configuration.rateImage }
        set { configuration.rateImage = newValue }
    }

    /// 清晰度按钮图标
    public var qualityImage: UIImage? {
        get { return configuration.qualityImage }
        set { configuration.qualityImage = newValue }
    }

    /// 字幕按钮图标
    public var subtitleImage: UIImage? {
        get { return configuration.subtitleImage }
        set { configuration.subtitleImage = newValue }
    }

    /// 弹幕开按钮图标
    public var danmakuOnImage: UIImage? {
        get { return configuration.danmakuOnImage }
        set { configuration.danmakuOnImage = newValue }
    }

    /// 弹幕关按钮图标
    public var danmakuOffImage: UIImage? {
        get { return configuration.danmakuOffImage }
        set { configuration.danmakuOffImage = newValue }
    }

    /// 截图按钮图标
    public var snapshotImage: UIImage? {
        get { return configuration.snapshotImage }
        set { configuration.snapshotImage = newValue }
    }

    /// 投屏按钮图标
    public var airPlayImage: UIImage? {
        get { return configuration.airPlayImage }
        set { configuration.airPlayImage = newValue }
    }

    /// 循环按钮图标
    public var loopImage: UIImage? {
        get { return configuration.loopImage }
        set { configuration.loopImage = newValue }
    }

    /// 静音按钮图标
    public var muteImage: UIImage? {
        get { return configuration.muteImage }
        set { configuration.muteImage = newValue }
    }

    /// 有声按钮图标
    public var volumeImage: UIImage? {
        get { return configuration.volumeImage }
        set { configuration.volumeImage = newValue }
    }

    /// 菜单面板背景色(倍速清晰度字幕选择浮层的底色，默认黑色七成五透明)
    public var menuPanelBackgroundColor: UIColor {
        get { return configuration.menuPanelBackgroundColor }
        set { configuration.menuPanelBackgroundColor = newValue }
    }

    /// 菜单面板选中项颜色(默认系统蓝色)
    public var menuSelectedColor: UIColor {
        get { return configuration.menuSelectedColor }
        set { configuration.menuSelectedColor = newValue }
    }

    /// 菜单面板未选中项颜色(默认白色)
    public var menuNormalColor: UIColor {
        get { return configuration.menuNormalColor }
        set { configuration.menuNormalColor = newValue }
    }
}
#endif
