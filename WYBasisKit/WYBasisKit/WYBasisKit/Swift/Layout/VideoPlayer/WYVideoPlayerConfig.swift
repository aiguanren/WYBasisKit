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
    public var loopCount = 1 {
        didSet { appearanceChanged?() }
    }

    /// 初始倍速(0.5~2.0，越界取 1.0，默认 1.0)
    public var preferredRate: Float = 1.0 {
        didSet { preferredRateChanged?() }
    }

    /// 初始倍速变化回调
    var preferredRateChanged: (() -> Void)?

    /// 初始是否静音(默认 false)
    public var shouldMuteByDefault = false {
        didSet { shouldMuteByDefaultChanged?() }
    }

    /// 默认静音变化回调
    var shouldMuteByDefaultChanged: (() -> Void)?

    /// 播放进度回调间隔，单位为秒(默认 0.5)
    public var progressCallbackInterval: TimeInterval = 0.5 {
        didSet { appearanceChanged?() }
    }

    /// 回前台是否自动续播(进后台按系统行为停住，默认 true)
    public var shouldResumeOnAppActive = true

    /// 进后台是否暂停播放(默认 true，画面本就会被系统中断，这里决定回前台是否需要手动续)
    public var shouldPauseOnAppResignActive = true

    /// 是否经 WYMediaCache 边下边播(默认 true，关闭后直连原地址播放)
    public var usesMediaCache = true {
        didSet {
            if oldValue != usesMediaCache { usesMediaCacheChanged?() }
        }
    }

    /// 缓存开关变化后按当前进度切换播放条目
    var usesMediaCacheChanged: (() -> Void)?

    /// 是否内置弹幕视图(默认 false，开启后播放器自带一个 WYDanmakuView 并随播放时间驱动)
    public var showsDanmaku = false {
        didSet { showsDanmakuChanged?() }
    }

    /// 外观与组件开关变化回调
    var appearanceChanged: (() -> Void)?

    /// 内置弹幕开关变化回调(播放器内部装配与卸装弹幕视图用，改这个属性即时生效)
    var showsDanmakuChanged: (() -> Void)?

    /// 内置弹幕的外观与行为配置(只在内置弹幕开启时生效)
    public var danmakuConfiguration = WYDanmakuConfiguration() {
        didSet { appearanceChanged?() }
    }

    /// 内置弹幕的时钟注入间隔，单位为秒(默认 1/30，值越小弹幕越顺滑，主线程开销越大)
    public var danmakuTickInterval: TimeInterval = 1.0 / 30.0 {
        didSet { appearanceChanged?() }
    }

    /// 首帧加载或播放缓冲的最长等待时间，单位为秒(默认 15，0 表示不限时)
    public var loadingTimeout: TimeInterval = 15 {
        didSet { appearanceChanged?() }
    }

    /// 清晰度或缓存模式切换的最长备流时间，单位为秒(默认 30，失败时保留原流)
    public var qualitySwitchTimeout: TimeInterval = 30

    /// 无缝切档提交前新流在前方至少要缓冲的秒数(默认 3，越大换档后越稳、提交越慢)
    public var qualitySwitchPrerollSeconds: TimeInterval = 3

    /// 更多面板的功能项目，按数组顺序展示，可删除、改名或追加自定义项目
    public var moreActions: [WYVideoPlayerMoreAction] = [WYVideoPlayerMoreActionKind.pictureInPicture, .sleepTimer, .download, .playbackRate, .audioOnly, .backgroundPlayback, .loopPlayback, .quality, .subtitle].map { WYVideoPlayerMoreAction(kind: $0) } {
        didSet { appearanceChanged?() }
    }

    /// 自定义控件位置，参数依次为播放器、可用区域、安全区和全屏状态，返回需要覆盖的控件区域
    public var shellLayoutHandler: ((_ player: WYVideoPlayer, _ bounds: CGRect, _ safeAreaInsets: UIEdgeInsets, _ isFullscreen: Bool) -> [WYVideoPlayerControl: CGRect])? {
        didSet { appearanceChanged?() }
    }

    /// 控件点击回调，参数为控件与播放器，返回true表示已处理，false继续执行内置动作
    public var controlActionHandler: ((_ control: WYVideoPlayerControl, _ player: WYVideoPlayer) -> Bool)?

    /// 半屏顶部控件及顺序，flexibleSpace 自动占据剩余空间
    public var shellInlineTopControls: [WYVideoPlayerControl] = [.flexibleSpace, .airPlay, .more] {
        didSet { appearanceChanged?() }
    }

    /// 半屏底部控件及顺序
    public var shellInlineBottomControls: [WYVideoPlayerControl] = [.playPause, .currentTime, .progress, .duration, .danmaku, .fullscreen] {
        didSet { appearanceChanged?() }
    }

    /// 全屏顶部控件及顺序
    public var shellFullscreenTopControls: [WYVideoPlayerControl] = [.back, .title, .flexibleSpace, .snapshot, .airPlay, .more] {
        didSet { appearanceChanged?() }
    }

    /// 全屏底部控件及顺序，时间和进度条单独显示在操作栏上方
    public var shellFullscreenBottomControls: [WYVideoPlayerControl] = [.playPause, .danmaku, .flexibleSpace, .subtitle, .rate, .quality, .loop, .fullscreen] {
        didSet { appearanceChanged?() }
    }

    /// 需要隐藏的控件，隐藏后其余控件自动补位
    public var shellHiddenControls: Set<WYVideoPlayerControl> = [] {
        didSet { appearanceChanged?() }
    }

    /// 是否显示更多功能按钮(默认 true)
    public var shellShowsMoreButton: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 布局中包含画中画按钮时是否显示(默认 true)
    public var shellShowsPictureInPictureButton: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 半屏是否额外显示倍速、清晰度与字幕入口(默认 false，可从更多面板访问)
    public var shellShowsInlineOptions: Bool = false {
        didSet { appearanceChanged?() }
    }

    /// 没有可选字幕时是否隐藏字幕入口(默认 true)
    public var shellHidesUnavailableSubtitleButton: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 控制栏标题，空字符串不显示
    public var shellTitle: String = "" {
        didSet { appearanceChanged?() }
    }

    /// 控制栏是否使用向画面渐变的背景(默认 true)
    public var shellUsesGradientBackground: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 文字按钮的最小宽度
    public var shellTextButtonMinimumWidth: CGFloat = UIDevice.wy_screenWidth(54, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 文字按钮左右留白
    public var shellTextButtonHorizontalPadding: CGFloat = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 顶部按钮之间的间距
    public var shellTopButtonSpacing: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 全屏时间行高度
    public var shellFullscreenTimeRowHeight: CGFloat = UIDevice.wy_screenHeight(22, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 全屏进度条触摸区域高度
    public var shellFullscreenProgressRowHeight: CGFloat = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 全屏时间文字字号与字重
    public var shellFullscreenTimeFont: UIFont = .monospacedDigitSystemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels), weight: .medium) {
        didSet { appearanceChanged?() }
    }

    /// 更多功能按钮图标，nil 使用系统省略号
    public var moreImage: UIImage? = nil {
        didSet { appearanceChanged?() }
    }

    /// 画中画按钮图标，nil 使用系统画中画图标
    public var pictureInPictureImage: UIImage? = nil {
        didSet { appearanceChanged?() }
    }

    /// 选项菜单文字的左右边距
    public var menuOptionHorizontalInset: CGFloat = UIDevice.wy_screenWidth(18, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 选项菜单勾选标记尺寸，未选中行保留相同空间
    public var menuCheckmarkSize: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 选项菜单选中行背景色
    public var menuSelectedBackgroundColor: UIColor = UIColor(white: 1, alpha: 0.1) {
        didSet { appearanceChanged?() }
    }

    /// 选项菜单文字对齐方式(默认左对齐)
    public var menuTextAlignment: NSTextAlignment = .left {
        didSet { appearanceChanged?() }
    }

    /// 定时关闭的可选时长，单位为秒，仅使用大于0的值
    public var sleepTimerOptions: [TimeInterval] = [15 * 60, 30 * 60, 60 * 60] {
        didSet { appearanceChanged?() }
    }

    /// 定时关闭菜单是否提供本视频播完后暂停(默认 true)
    public var showsSleepAtVideoEndOption: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 更多面板每行项目数(默认 5，空间不足时自动减少)
    public var moreColumnCount: Int = 5 {
        didSet { appearanceChanged?() }
    }

    /// 更多面板图标背景的边长
    public var moreIconSize: CGFloat = UIDevice.wy_screenWidth(52, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板系统图标的字号
    public var moreIconPointSize: CGFloat = UIFont.wy_fontSize(24, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板每个项目的高度
    public var moreItemHeight: CGFloat = UIDevice.wy_screenHeight(100, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板标题栏高度
    public var moreHeaderHeight: CGFloat = UIDevice.wy_screenHeight(56, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板内容边距
    public var moreContentInsets: UIEdgeInsets = UIEdgeInsets(top: UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), left: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels), bottom: UIDevice.wy_screenHeight(16, WYBasisKitConfig.defaultScreenPixels), right: UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板圆角
    public var moreCornerRadius: CGFloat = UIDevice.wy_screenWidth(22, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 全屏时更多面板的宽度
    public var moreFullscreenWidth: CGFloat = UIDevice.wy_screenWidth(360, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板背景色
    public var moreBackgroundColor: UIColor = .systemBackground {
        didSet { appearanceChanged?() }
    }

    /// 更多面板外部遮罩颜色
    public var moreDimmingColor: UIColor = UIColor(white: 0, alpha: 0.5) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板图标背景色
    public var moreIconBackgroundColor: UIColor = .secondarySystemBackground {
        didSet { appearanceChanged?() }
    }

    /// 更多面板选中项目的图标背景色
    public var moreSelectedBackgroundColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.12) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板选中项目的图标与文字颜色
    public var moreSelectedColor: UIColor = .systemBlue {
        didSet { appearanceChanged?() }
    }

    /// 更多面板标题与图标颜色
    public var moreTextColor: UIColor = .label {
        didSet { appearanceChanged?() }
    }

    /// 更多面板功能名称颜色
    public var moreSecondaryTextColor: UIColor = .secondaryLabel {
        didSet { appearanceChanged?() }
    }

    /// 更多面板标题字体
    public var moreTitleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(20, WYBasisKitConfig.defaultScreenPixels), weight: .semibold) {
        didSet { appearanceChanged?() }
    }

    /// 更多面板功能名称字体
    public var moreItemFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 离线下载是否允许使用蜂窝网络(默认 true)
    public var offlineDownloadAllowsCellularAccess: Bool = true {
        didSet { appearanceChanged?() }
    }

    /// 是否将时间进度单独显示在操作栏上方(默认 false，全屏始终分行显示)
    public var shellPrefersTwoRows: Bool = false {
        didSet { appearanceChanged?() }
    }

    /// 控制栏左右最小边距(与安全区取较大值)
    public var shellHorizontalInset: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 时间文字与进度条及播放按钮的间距
    public var shellTimeSpacing: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 时间文字最小宽度(实际文字更宽时自动扩展)
    public var shellMinimumTimeWidth: CGFloat = UIDevice.wy_screenWidth(38, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 自动切换两行布局时保留的进度条最小宽度
    public var shellMinimumProgressWidth: CGFloat = UIDevice.wy_screenWidth(90, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 加载指示器背景尺寸
    public var shellLoadingIndicatorSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(48, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(48, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 加载指示器背景圆角
    public var shellLoadingIndicatorCornerRadius: CGFloat = UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 加载指示器背景颜色
    public var shellLoadingIndicatorBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.45) {
        didSet { appearanceChanged?() }
    }

    /// 加载指示器样式(默认 large)
    public var shellLoadingIndicatorStyle: UIActivityIndicatorView.Style = .large {
        didSet { appearanceChanged?() }
    }

    /// 全屏切换是否使用动画(默认 true)
    public var animatesFullscreenTransition: Bool = true

    /// 全屏方向切换的最长等待秒数，默认 3，非正数不等待
    public var fullscreenTransitionTimeout: TimeInterval = 3

    /// 无需切换屏幕方向时的全屏容器转场样式(默认交叉淡入淡出)
    public var fullscreenTransitionStyle: UIModalTransitionStyle = .crossDissolve

    /// 横滑一屏对应视频总时长的比例(默认 0.05，最终步长受最小与最大秒数限制)
    public var seekPanDurationRatio: CGFloat = 0.05

    /// 横滑一屏的最小步长，单位为秒(默认 3)
    public var seekPanMinimumSeconds: TimeInterval = 3

    /// 横滑一屏的最大步长，单位为秒(默认 90)
    public var seekPanMaximumSeconds: TimeInterval = 90

    /// 等待系统允许画中画的最长时间，单位为秒(默认 5)
    public var pictureInPictureStartTimeout: TimeInterval = 5

    /// 单击画面是否切换控制壳显隐(默认 true)
    public var allowsTapGesture = true

    /// 双击画面是否切换播放暂停(默认 true)
    public var allowsDoubleTapGesture = true

    /// 是否允许横滑快进快退(默认 true)
    public var allowsSeekPanGesture = true

    /// 横滑快进的灵敏度(按视频时长自动计算步长的倍率，越大越灵敏，默认 1.0)
    public var seekPanSensitivity: CGFloat = 1.0

    /// 是否允许长按临时倍速(默认 true)
    public var allowsRateLongPressGesture = true

    /// 长按期间的临时倍速(默认 2.0)
    public var longPressRate: Float = 2.0

    /// 是否允许画面左侧竖滑调音量、右侧竖滑调亮度(默认 true)
    public var allowsVolumeBrightnessPanGesture = true

    /// 是否允许全屏切换(默认 true)
    public var allowsFullscreenToggle = true {
        didSet { appearanceChanged?() }
    }

    /// 是否允许画中画(默认 true，系统不支持时自动失效)
    public var allowsPictureInPicture = true {
        didSet { appearanceChanged?() }
    }

    /// 是否允许投屏(默认 true，控制壳上显示投屏入口)
    public var allowsAirPlay = true {
        didSet { appearanceChanged?() }
    }

    /// 倍速可选项(控制壳倍速菜单按这个列表展示，默认 0.5~2.0 六档)
    public var rateOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    /// 控制壳无操作自动隐藏的间隔，单位为秒(默认 4，0 表示不自动隐藏)
    public var shellAutoHideInterval: TimeInterval = 4 {
        didSet { appearanceChanged?() }
    }

    /// 是否装载默认控制壳(默认 true，关闭后无壳裸播，适合自定义壳或纯画面场景)
    public var showsDefaultShell = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示倍速按钮(默认 true)
    public var shellShowsRateButton = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示清晰度按钮(多档素材时按钮才有效，默认 true)
    public var shellShowsQualityButton = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示字幕按钮(默认 true)
    public var shellShowsSubtitleButton = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示弹幕开关按钮(内置弹幕开启时按钮才有动作，默认 true)
    public var shellShowsDanmakuButton = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示截图按钮(默认 false)
    public var shellShowsSnapshotButton = false {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示投屏按钮(默认 true)
    public var shellShowsAirPlayButton = true {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏是否显示循环按钮(默认 false)
    public var shellShowsLoopButton = false {
        didSet { appearanceChanged?() }
    }

    /// 控制壳顶栏与底栏的高度，单位为pt(默认 44)
    public var shellBarHeight: CGFloat = UIDevice.wy_screenHeight(44, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏功能按钮的边长，单位为pt(默认 34)
    public var shellFunctionButtonSize: CGFloat = UIDevice.wy_screenWidth(34, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳中央播放按钮的边长，单位为pt(默认 56)
    public var shellCenterPlayButtonSize: CGFloat = UIDevice.wy_screenWidth(56, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳底栏相邻功能按钮的间距，单位为pt(默认 4)
    public var shellButtonSpacing: CGFloat = UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳倍速按钮的文字字号(默认 12)
    public var shellRateButtonFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳加载指示器的颜色(默认白色)
    public var shellLoadingIndicatorColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 控制壳显隐动画时长，单位为秒(默认 0.25)
    public var shellAnimationDuration: TimeInterval = 0.25 {
        didSet { appearanceChanged?() }
    }

    /// 控制壳顶栏背景色(默认黑色六成透明)
    public var shellBarBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.6) {
        didSet { appearanceChanged?() }
    }

    /// 进度条底轨颜色(默认白色三成透明)
    public var progressTrackColor: UIColor = UIColor(white: 1, alpha: 0.3) {
        didSet { appearanceChanged?() }
    }

    /// 进度条已缓冲段颜色(默认白色五成五透明)
    public var progressBufferColor: UIColor = UIColor(white: 1, alpha: 0.55) {
        didSet { appearanceChanged?() }
    }

    /// 进度条已播段颜色(默认系统蓝色)
    public var progressPlayColor: UIColor = .systemBlue {
        didSet { appearanceChanged?() }
    }

    /// 进度条滑块颜色(默认白色)
    public var progressThumbColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 进度条轨道的粗细，单位为pt(默认 3)
    public var progressTrackHeight: CGFloat = UIDevice.wy_screenHeight(3, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 进度条滑块的边长，单位为pt(默认 14)
    public var progressThumbSize: CGFloat = UIDevice.wy_screenWidth(14, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 进度条滑块拖动中的边长，单位为pt(默认 16)
    public var progressThumbDraggingSize: CGFloat = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳按钮颜色(默认白色)
    public var shellButtonTintColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 控制壳时间文字字号(默认 12)
    public var shellTimeFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳时间文字颜色(默认白色)
    public var shellTimeColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 控制壳顶栏标题字号(默认 15)
    public var shellTitleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 控制壳顶栏标题颜色(默认白色)
    public var shellTitleColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 字幕文字字号(默认 16)
    public var subtitleFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 字幕文字颜色(默认白色)
    public var subtitleTextColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 字幕文字描边颜色(默认黑色)
    public var subtitleStrokeColor: UIColor = .black {
        didSet { appearanceChanged?() }
    }

    /// 字幕文字描边宽度(负数表示描边同时保留文字填充，默认 -2)
    public var subtitleStrokeWidth: CGFloat = -2 {
        didSet { appearanceChanged?() }
    }

    /// 字幕距播放器左右边缘的距离，单位为pt(默认 12)
    public var subtitleHorizontalInset: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 字幕距播放器底边的距离，单位为pt(默认 12)
    public var subtitleBottomInset: CGFloat = UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 手势提示浮层背景色(默认黑色六成透明)
    public var gestureOverlayBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.6) {
        didSet { appearanceChanged?() }
    }

    /// 手势提示浮层文字颜色(默认白色)
    public var gestureOverlayTextColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 手势提示浮层文字字号(默认 14)
    public var gestureOverlayFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 手势提示浮层圆角半径，单位为pt(默认 6)
    public var gestureOverlayCornerRadius: CGFloat = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 手势提示浮层尺寸(快进提示、倍速提示、音量亮度指示共用，默认 160x34)
    public var gestureOverlaySize: CGSize = CGSize(width: UIDevice.wy_screenWidth(160, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /// 播放按钮图标(nil 用系统 SF Symbol 播放三角)
    public var playImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 暂停按钮图标(nil 用系统 SF Symbol)
    public var pauseImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 返回按钮图标
    public var backImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 进入全屏按钮图标
    public var fullscreenEnterImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 退出全屏按钮图标
    public var fullscreenExitImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 倍速按钮图标
    public var rateImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 清晰度按钮图标
    public var qualityImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 字幕按钮图标
    public var subtitleImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 弹幕开按钮图标
    public var danmakuOnImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 弹幕关按钮图标
    public var danmakuOffImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 截图按钮图标
    public var snapshotImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 投屏按钮图标
    public var airPlayImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 循环按钮图标
    public var loopImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 静音按钮图标
    public var muteImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 有声按钮图标
    public var volumeImage: UIImage? {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板背景色(倍速清晰度字幕选择浮层的底色，默认黑色七成五透明)
    public var menuPanelBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.75) {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板选中项颜色(默认系统蓝色)
    public var menuSelectedColor: UIColor = .systemBlue {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板未选中项颜色(默认白色)
    public var menuNormalColor: UIColor = .white {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板圆角半径，单位为pt(默认 8)
    public var menuPanelCornerRadius: CGFloat = UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板宽度，单位为pt(默认 136)
    public var menuPanelWidth: CGFloat = UIDevice.wy_screenWidth(136, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板行高，单位为pt(默认 40)
    public var menuPanelRowHeight: CGFloat = UIDevice.wy_screenHeight(40, WYBasisKitConfig.defaultScreenPixels) {
        didSet { appearanceChanged?() }
    }

    /// 菜单面板条目文字字号(默认 13)
    public var menuPanelItemFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels)) {
        didSet { appearanceChanged?() }
    }

    /**
     *  创建播放器配置
     *
     */
    public init() {}

}
