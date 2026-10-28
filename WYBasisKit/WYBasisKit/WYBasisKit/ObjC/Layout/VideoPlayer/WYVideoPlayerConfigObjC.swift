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

    /// 内置弹幕的时钟注入间隔，单位为秒(默认 1/30，值越小弹幕越顺滑，主线程开销越大)
    public var danmakuTickInterval: TimeInterval {
        get { return configuration.danmakuTickInterval }
        set { configuration.danmakuTickInterval = newValue }
    }

    /// 首帧加载或播放缓冲的最长等待时间，单位为秒(默认 15，0 表示不限时)
    public var loadingTimeout: TimeInterval {
        get { return configuration.loadingTimeout }
        set { configuration.loadingTimeout = newValue }
    }

    /// 清晰度或缓存模式切换的最长备流时间，单位为秒(默认 30，失败时保留原流)
    public var qualitySwitchTimeout: TimeInterval {
        get { return configuration.qualitySwitchTimeout }
        set { configuration.qualitySwitchTimeout = newValue }
    }

    /// 无缝切档提交前新流在前方至少要缓冲的秒数(默认 3，越大换档后越稳、提交越慢)
    public var qualitySwitchPrerollSeconds: TimeInterval {
        get { return configuration.qualitySwitchPrerollSeconds }
        set { configuration.qualitySwitchPrerollSeconds = newValue }
    }

    /// 更多面板的功能项目，按数组顺序展示，可删除、改名或追加自定义项目
    public var moreActions: [WYVideoPlayerMoreActionObjC] {
        get {
            return configuration.moreActions.map { action in
                let item = WYVideoPlayerMoreActionObjC(kind: action.kind)
                item.identifier = action.identifier
                item.title = action.title
                item.image = action.image
                item.isEnabled = action.isEnabled
                item.isSelected = action.isSelected
                item.handler = action.handler
                return item
            }
        }
        set { configuration.moreActions = newValue.map { $0.toMoreAction() } }
    }

    /// 自定义控件位置，参数依次为播放器、可用区域、安全区和全屏状态，返回需要覆盖的控件区域
    public var shellLayoutHandler: ((_ player: WYVideoPlayer, _ bounds: CGRect, _ safeAreaInsets: UIEdgeInsets, _ isFullscreen: Bool) -> [NSNumber: NSValue])? {
        get {
            guard let handler = configuration.shellLayoutHandler else { return nil }
            return { player, bounds, insets, fullscreen in
                return Dictionary(uniqueKeysWithValues: handler(player, bounds, insets, fullscreen).map { (NSNumber(value: $0.key.rawValue), NSValue(cgRect: $0.value)) })
            }
        }
        set {
            guard let handler = newValue else { configuration.shellLayoutHandler = nil; return }
            configuration.shellLayoutHandler = { player, bounds, insets, fullscreen in
                var result: [WYVideoPlayerControl: CGRect] = [:]
                for (key, value) in handler(player, bounds, insets, fullscreen) {
                    if let control = WYVideoPlayerControl(rawValue: key.intValue) { result[control] = value.cgRectValue }
                }
                return result
            }
        }
    }

    /// 控件点击回调，参数为控件与播放器，返回true表示已处理，false继续执行内置动作
    public var controlActionHandler: ((_ control: WYVideoPlayerControl, _ player: WYVideoPlayer) -> Bool)? {
        get { return configuration.controlActionHandler }
        set { configuration.controlActionHandler = newValue }
    }

    /// 半屏顶部控件及顺序，flexibleSpace 自动占据剩余空间
    public var shellInlineTopControls: [NSNumber] {
        get { return configuration.shellInlineTopControls.map { NSNumber(value: $0.rawValue) } }
        set { configuration.shellInlineTopControls = newValue.compactMap { WYVideoPlayerControl(rawValue: $0.intValue) } }
    }

    /// 半屏底部控件及顺序
    public var shellInlineBottomControls: [NSNumber] {
        get { return configuration.shellInlineBottomControls.map { NSNumber(value: $0.rawValue) } }
        set { configuration.shellInlineBottomControls = newValue.compactMap { WYVideoPlayerControl(rawValue: $0.intValue) } }
    }

    /// 全屏顶部控件及顺序
    public var shellFullscreenTopControls: [NSNumber] {
        get { return configuration.shellFullscreenTopControls.map { NSNumber(value: $0.rawValue) } }
        set { configuration.shellFullscreenTopControls = newValue.compactMap { WYVideoPlayerControl(rawValue: $0.intValue) } }
    }

    /// 全屏底部控件及顺序，时间和进度条单独显示在操作栏上方
    public var shellFullscreenBottomControls: [NSNumber] {
        get { return configuration.shellFullscreenBottomControls.map { NSNumber(value: $0.rawValue) } }
        set { configuration.shellFullscreenBottomControls = newValue.compactMap { WYVideoPlayerControl(rawValue: $0.intValue) } }
    }

    /// 需要隐藏的控件，隐藏后其余控件自动补位
    public var shellHiddenControls: [NSNumber] {
        get { return configuration.shellHiddenControls.map { NSNumber(value: $0.rawValue) } }
        set { configuration.shellHiddenControls = Set(newValue.compactMap { WYVideoPlayerControl(rawValue: $0.intValue) }) }
    }

    /// 是否显示更多功能按钮(默认 true)
    public var shellShowsMoreButton: Bool {
        get { return configuration.shellShowsMoreButton }
        set { configuration.shellShowsMoreButton = newValue }
    }

    /// 布局中包含画中画按钮时是否显示(默认 true)
    public var shellShowsPictureInPictureButton: Bool {
        get { return configuration.shellShowsPictureInPictureButton }
        set { configuration.shellShowsPictureInPictureButton = newValue }
    }

    /// 半屏是否额外显示倍速、清晰度与字幕入口(默认 false，可从更多面板访问)
    public var shellShowsInlineOptions: Bool {
        get { return configuration.shellShowsInlineOptions }
        set { configuration.shellShowsInlineOptions = newValue }
    }

    /// 没有可选字幕时是否隐藏字幕入口(默认 true)
    public var shellHidesUnavailableSubtitleButton: Bool {
        get { return configuration.shellHidesUnavailableSubtitleButton }
        set { configuration.shellHidesUnavailableSubtitleButton = newValue }
    }

    /// 控制栏标题，空字符串不显示
    public var shellTitle: String {
        get { return configuration.shellTitle }
        set { configuration.shellTitle = newValue }
    }

    /// 控制栏是否使用向画面渐变的背景(默认 true)
    public var shellUsesGradientBackground: Bool {
        get { return configuration.shellUsesGradientBackground }
        set { configuration.shellUsesGradientBackground = newValue }
    }

    /// 文字按钮的最小宽度
    public var shellTextButtonMinimumWidth: CGFloat {
        get { return configuration.shellTextButtonMinimumWidth }
        set { configuration.shellTextButtonMinimumWidth = newValue }
    }

    /// 文字按钮左右留白
    public var shellTextButtonHorizontalPadding: CGFloat {
        get { return configuration.shellTextButtonHorizontalPadding }
        set { configuration.shellTextButtonHorizontalPadding = newValue }
    }

    /// 顶部按钮之间的间距
    public var shellTopButtonSpacing: CGFloat {
        get { return configuration.shellTopButtonSpacing }
        set { configuration.shellTopButtonSpacing = newValue }
    }

    /// 全屏时间行高度
    public var shellFullscreenTimeRowHeight: CGFloat {
        get { return configuration.shellFullscreenTimeRowHeight }
        set { configuration.shellFullscreenTimeRowHeight = newValue }
    }

    /// 全屏进度条触摸区域高度
    public var shellFullscreenProgressRowHeight: CGFloat {
        get { return configuration.shellFullscreenProgressRowHeight }
        set { configuration.shellFullscreenProgressRowHeight = newValue }
    }

    /// 全屏时间文字字号与字重
    public var shellFullscreenTimeFont: UIFont {
        get { return configuration.shellFullscreenTimeFont }
        set { configuration.shellFullscreenTimeFont = newValue }
    }

    /// 更多功能按钮图标，nil 使用系统省略号
    public var moreImage: UIImage? {
        get { return configuration.moreImage }
        set { configuration.moreImage = newValue }
    }

    /// 画中画按钮图标，nil 使用系统画中画图标
    public var pictureInPictureImage: UIImage? {
        get { return configuration.pictureInPictureImage }
        set { configuration.pictureInPictureImage = newValue }
    }

    /// 选项菜单文字的左右边距
    public var menuOptionHorizontalInset: CGFloat {
        get { return configuration.menuOptionHorizontalInset }
        set { configuration.menuOptionHorizontalInset = newValue }
    }

    /// 选项菜单勾选标记尺寸，未选中行保留相同空间
    public var menuCheckmarkSize: CGFloat {
        get { return configuration.menuCheckmarkSize }
        set { configuration.menuCheckmarkSize = newValue }
    }

    /// 选项菜单选中行背景色
    public var menuSelectedBackgroundColor: UIColor {
        get { return configuration.menuSelectedBackgroundColor }
        set { configuration.menuSelectedBackgroundColor = newValue }
    }

    /// 选项菜单文字对齐方式(默认左对齐)
    public var menuTextAlignment: NSTextAlignment {
        get { return configuration.menuTextAlignment }
        set { configuration.menuTextAlignment = newValue }
    }

    /// 定时关闭的可选时长，单位为秒，仅使用大于0的值
    public var sleepTimerOptions: [TimeInterval] {
        get { return configuration.sleepTimerOptions }
        set { configuration.sleepTimerOptions = newValue }
    }

    /// 定时关闭菜单是否提供本视频播完后暂停(默认 true)
    public var showsSleepAtVideoEndOption: Bool {
        get { return configuration.showsSleepAtVideoEndOption }
        set { configuration.showsSleepAtVideoEndOption = newValue }
    }

    /// 更多面板每行项目数(默认 5，空间不足时自动减少)
    public var moreColumnCount: Int {
        get { return configuration.moreColumnCount }
        set { configuration.moreColumnCount = newValue }
    }

    /// 更多面板图标背景的边长
    public var moreIconSize: CGFloat {
        get { return configuration.moreIconSize }
        set { configuration.moreIconSize = newValue }
    }

    /// 更多面板系统图标的字号
    public var moreIconPointSize: CGFloat {
        get { return configuration.moreIconPointSize }
        set { configuration.moreIconPointSize = newValue }
    }

    /// 更多面板每个项目的高度
    public var moreItemHeight: CGFloat {
        get { return configuration.moreItemHeight }
        set { configuration.moreItemHeight = newValue }
    }

    /// 更多面板标题栏高度
    public var moreHeaderHeight: CGFloat {
        get { return configuration.moreHeaderHeight }
        set { configuration.moreHeaderHeight = newValue }
    }

    /// 更多面板内容边距
    public var moreContentInsets: UIEdgeInsets {
        get { return configuration.moreContentInsets }
        set { configuration.moreContentInsets = newValue }
    }

    /// 更多面板圆角
    public var moreCornerRadius: CGFloat {
        get { return configuration.moreCornerRadius }
        set { configuration.moreCornerRadius = newValue }
    }

    /// 全屏时更多面板的宽度
    public var moreFullscreenWidth: CGFloat {
        get { return configuration.moreFullscreenWidth }
        set { configuration.moreFullscreenWidth = newValue }
    }

    /// 更多面板背景色
    public var moreBackgroundColor: UIColor {
        get { return configuration.moreBackgroundColor }
        set { configuration.moreBackgroundColor = newValue }
    }

    /// 更多面板外部遮罩颜色
    public var moreDimmingColor: UIColor {
        get { return configuration.moreDimmingColor }
        set { configuration.moreDimmingColor = newValue }
    }

    /// 更多面板图标背景色
    public var moreIconBackgroundColor: UIColor {
        get { return configuration.moreIconBackgroundColor }
        set { configuration.moreIconBackgroundColor = newValue }
    }

    /// 更多面板选中项目的图标背景色
    public var moreSelectedBackgroundColor: UIColor {
        get { return configuration.moreSelectedBackgroundColor }
        set { configuration.moreSelectedBackgroundColor = newValue }
    }

    /// 更多面板选中项目的图标与文字颜色
    public var moreSelectedColor: UIColor {
        get { return configuration.moreSelectedColor }
        set { configuration.moreSelectedColor = newValue }
    }

    /// 更多面板标题与图标颜色
    public var moreTextColor: UIColor {
        get { return configuration.moreTextColor }
        set { configuration.moreTextColor = newValue }
    }

    /// 更多面板功能名称颜色
    public var moreSecondaryTextColor: UIColor {
        get { return configuration.moreSecondaryTextColor }
        set { configuration.moreSecondaryTextColor = newValue }
    }

    /// 更多面板标题字体
    public var moreTitleFont: UIFont {
        get { return configuration.moreTitleFont }
        set { configuration.moreTitleFont = newValue }
    }

    /// 更多面板功能名称字体
    public var moreItemFont: UIFont {
        get { return configuration.moreItemFont }
        set { configuration.moreItemFont = newValue }
    }

    /// 离线下载是否允许使用蜂窝网络(默认 true)
    public var offlineDownloadAllowsCellularAccess: Bool {
        get { return configuration.offlineDownloadAllowsCellularAccess }
        set { configuration.offlineDownloadAllowsCellularAccess = newValue }
    }

    /// 是否将时间进度单独显示在操作栏上方(默认 false，全屏始终分行显示)
    public var shellPrefersTwoRows: Bool {
        get { return configuration.shellPrefersTwoRows }
        set { configuration.shellPrefersTwoRows = newValue }
    }

    /// 控制栏左右最小边距(与安全区取较大值)
    public var shellHorizontalInset: CGFloat {
        get { return configuration.shellHorizontalInset }
        set { configuration.shellHorizontalInset = newValue }
    }

    /// 时间文字与进度条及播放按钮的间距
    public var shellTimeSpacing: CGFloat {
        get { return configuration.shellTimeSpacing }
        set { configuration.shellTimeSpacing = newValue }
    }

    /// 时间文字最小宽度(实际文字更宽时自动扩展)
    public var shellMinimumTimeWidth: CGFloat {
        get { return configuration.shellMinimumTimeWidth }
        set { configuration.shellMinimumTimeWidth = newValue }
    }

    /// 自动切换两行布局时保留的进度条最小宽度
    public var shellMinimumProgressWidth: CGFloat {
        get { return configuration.shellMinimumProgressWidth }
        set { configuration.shellMinimumProgressWidth = newValue }
    }

    /// 加载指示器背景尺寸
    public var shellLoadingIndicatorSize: CGSize {
        get { return configuration.shellLoadingIndicatorSize }
        set { configuration.shellLoadingIndicatorSize = newValue }
    }

    /// 加载指示器背景圆角
    public var shellLoadingIndicatorCornerRadius: CGFloat {
        get { return configuration.shellLoadingIndicatorCornerRadius }
        set { configuration.shellLoadingIndicatorCornerRadius = newValue }
    }

    /// 加载指示器背景颜色
    public var shellLoadingIndicatorBackgroundColor: UIColor {
        get { return configuration.shellLoadingIndicatorBackgroundColor }
        set { configuration.shellLoadingIndicatorBackgroundColor = newValue }
    }

    /// 加载指示器样式(默认 large)
    public var shellLoadingIndicatorStyle: UIActivityIndicatorView.Style {
        get { return configuration.shellLoadingIndicatorStyle }
        set { configuration.shellLoadingIndicatorStyle = newValue }
    }

    /// 全屏切换是否使用动画(默认 true)
    public var animatesFullscreenTransition: Bool {
        get { return configuration.animatesFullscreenTransition }
        set { configuration.animatesFullscreenTransition = newValue }
    }

    /// 全屏方向切换的最长等待秒数，默认 3，非正数不等待
    public var fullscreenTransitionTimeout: TimeInterval {
        get { return configuration.fullscreenTransitionTimeout }
        set { configuration.fullscreenTransitionTimeout = newValue }
    }

    /// 无需切换屏幕方向时的全屏容器转场样式(默认交叉淡入淡出)
    public var fullscreenTransitionStyle: UIModalTransitionStyle {
        get { return configuration.fullscreenTransitionStyle }
        set { configuration.fullscreenTransitionStyle = newValue }
    }

    /// 横滑一屏对应视频总时长的比例(默认 0.05，最终步长受最小与最大秒数限制)
    public var seekPanDurationRatio: CGFloat {
        get { return configuration.seekPanDurationRatio }
        set { configuration.seekPanDurationRatio = newValue }
    }

    /// 横滑一屏的最小步长，单位为秒(默认 3)
    public var seekPanMinimumSeconds: TimeInterval {
        get { return configuration.seekPanMinimumSeconds }
        set { configuration.seekPanMinimumSeconds = newValue }
    }

    /// 横滑一屏的最大步长，单位为秒(默认 90)
    public var seekPanMaximumSeconds: TimeInterval {
        get { return configuration.seekPanMaximumSeconds }
        set { configuration.seekPanMaximumSeconds = newValue }
    }

    /// 等待系统允许画中画的最长时间，单位为秒(默认 5)
    public var pictureInPictureStartTimeout: TimeInterval {
        get { return configuration.pictureInPictureStartTimeout }
        set { configuration.pictureInPictureStartTimeout = newValue }
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

    /// 横滑快进的灵敏度(按视频时长自动计算步长的倍率，越大越灵敏，默认 1.0)
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

    /// 控制壳顶栏与底栏的高度，单位为pt(默认 44)
    public var shellBarHeight: CGFloat {
        get { return configuration.shellBarHeight }
        set { configuration.shellBarHeight = newValue }
    }

    /// 控制壳底栏功能按钮的边长，单位为pt(默认 34)
    public var shellFunctionButtonSize: CGFloat {
        get { return configuration.shellFunctionButtonSize }
        set { configuration.shellFunctionButtonSize = newValue }
    }

    /// 控制壳中央播放按钮的边长，单位为pt(默认 56)
    public var shellCenterPlayButtonSize: CGFloat {
        get { return configuration.shellCenterPlayButtonSize }
        set { configuration.shellCenterPlayButtonSize = newValue }
    }

    /// 控制壳底栏相邻功能按钮的间距，单位为pt(默认 4)
    public var shellButtonSpacing: CGFloat {
        get { return configuration.shellButtonSpacing }
        set { configuration.shellButtonSpacing = newValue }
    }

    /// 控制壳倍速按钮的文字字号(默认 12)
    public var shellRateButtonFont: UIFont {
        get { return configuration.shellRateButtonFont }
        set { configuration.shellRateButtonFont = newValue }
    }

    /// 控制壳加载指示器的颜色(默认白色)
    public var shellLoadingIndicatorColor: UIColor {
        get { return configuration.shellLoadingIndicatorColor }
        set { configuration.shellLoadingIndicatorColor = newValue }
    }

    /// 控制壳显隐动画时长，单位为秒(默认 0.25)
    public var shellAnimationDuration: TimeInterval {
        get { return configuration.shellAnimationDuration }
        set { configuration.shellAnimationDuration = newValue }
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

    /// 进度条轨道的粗细，单位为pt(默认 3)
    public var progressTrackHeight: CGFloat {
        get { return configuration.progressTrackHeight }
        set { configuration.progressTrackHeight = newValue }
    }

    /// 进度条滑块的边长，单位为pt(默认 14)
    public var progressThumbSize: CGFloat {
        get { return configuration.progressThumbSize }
        set { configuration.progressThumbSize = newValue }
    }

    /// 进度条滑块拖动中的边长，单位为pt(默认 16)
    public var progressThumbDraggingSize: CGFloat {
        get { return configuration.progressThumbDraggingSize }
        set { configuration.progressThumbDraggingSize = newValue }
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

    /// 字幕距播放器左右边缘的距离，单位为pt(默认 12)
    public var subtitleHorizontalInset: CGFloat {
        get { return configuration.subtitleHorizontalInset }
        set { configuration.subtitleHorizontalInset = newValue }
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

    /// 手势提示浮层文字字号(默认 14)
    public var gestureOverlayFont: UIFont {
        get { return configuration.gestureOverlayFont }
        set { configuration.gestureOverlayFont = newValue }
    }

    /// 手势提示浮层圆角半径，单位为pt(默认 6)
    public var gestureOverlayCornerRadius: CGFloat {
        get { return configuration.gestureOverlayCornerRadius }
        set { configuration.gestureOverlayCornerRadius = newValue }
    }

    /// 手势提示浮层尺寸(快进提示、倍速提示、音量亮度指示共用，默认 160x34)
    public var gestureOverlaySize: CGSize {
        get { return configuration.gestureOverlaySize }
        set { configuration.gestureOverlaySize = newValue }
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

    /// 菜单面板圆角半径，单位为pt(默认 8)
    public var menuPanelCornerRadius: CGFloat {
        get { return configuration.menuPanelCornerRadius }
        set { configuration.menuPanelCornerRadius = newValue }
    }

    /// 菜单面板宽度，单位为pt(默认 136)
    public var menuPanelWidth: CGFloat {
        get { return configuration.menuPanelWidth }
        set { configuration.menuPanelWidth = newValue }
    }

    /// 菜单面板行高，单位为pt(默认 40)
    public var menuPanelRowHeight: CGFloat {
        get { return configuration.menuPanelRowHeight }
        set { configuration.menuPanelRowHeight = newValue }
    }

    /// 菜单面板条目文字字号(默认 13)
    public var menuPanelItemFont: UIFont {
        get { return configuration.menuPanelItemFont }
        set { configuration.menuPanelItemFont = newValue }
    }
    /**
     *  创建播放器配置
     *
     */
    public override init() {
        configuration = WYVideoPlayerConfig()
        super.init()
    }

}
#endif
