//
//  WYContentScrollView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/4/13.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

@objc public protocol WYContentScrollViewDelegate {

    /**
     *  监听ContentScrollView的偏移量变化事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *  @param offset             当前的偏移量
     *  @param direction          当前的滑动方向
     *  @param currentView        当前正在显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param reserveView        当前预备显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param index              当前滑动的Index
     */
    @objc(wy_contentScrollViewDidScroll:offset:direction:currentView:reserveView:index:)
    optional func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)

    /**
     *  监听ContentScrollView的点击事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *  @param direction          当前的滑动方向
     *  @param currentView        当前正在显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param reserveView        当前预备显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param index              当前点击的Index
     */
    @objc(wy_contentScrollViewDidClick:direction:currentView:reserveView:index:)
    optional func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)

    /**
     *  监听ContentScrollView即将切换页面的事件
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *  @param direction             当前的滑动方向
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    @objc(wy_contentScrollViewWillSwitch:direction:currentHorizontalView:reserveHorizontalView:currentVerticalView:reserveVerticalView:)
    optional func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?)

    /**
     *  监听ContentScrollView页面已经切换完成的事件
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *  @param direction             当前的滑动方向
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    @objc(wy_contentScrollViewDidSwitch:direction:currentHorizontalView:reserveHorizontalView:currentVerticalView:reserveVerticalView:)
    optional func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?)
}

/// 支持的滑动方向
@objc public enum WYContentSlidingDirection: Int {
    /// 左右滑动
    case leftOrRight = 0
    /// 上下滑动
    case topOrBottom
    /// 上下左右滑动
    case omnidirectional
}

public class WYContentScrollView: UIScrollView {
    
    /// 滑动事件代理
    public weak var contentDelegate: WYContentScrollViewDelegate?
    
    /// 水平方向内容页视图数量（Int.max表示无限数量）
    public var numberOfHorizontalContent: Int = Int.max {
        didSet {
            
            // 防数量收缩后残留旧下标：staging会按旧下标±1算出错误reserve误发willSwitch(表现为单页轴也能滑出回调、will/did错位)
            if currentHorizontalIndex > numberOfHorizontalContent - 1 {
                currentHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            if reserveHorizontalIndex > numberOfHorizontalContent - 1 {
                reserveHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            
            // 展示轴翻转(当前轴数量归零回落另一轴)是纯z序切换不经滑动链路、无任何回调，业务不知道页面换了——检测置顶View变化后补发一次didSwitch并同步方向/标记(下标未变按语义只发did)
            let previousUpperContentView = upperContentView
            bringContentToFront()
            if let currentUpperContentView = upperContentView, currentUpperContentView !== previousUpperContentView {
                if (currentUpperContentView == horizontalViews?.first) && (numberOfHorizontalContent >= 1) {
                    internalSliderDirection = .left
                    hasInitialCallbackHorizontal = true
                    switchContentCallback(isDidSwitch: true, direction: .left)
                }else if (currentUpperContentView == verticalViews?.first) && (numberOfVerticalContent >= 1) {
                    internalSliderDirection = .up
                    hasInitialCallbackVertical = true
                    switchContentCallback(isDidSwitch: true, direction: .up)
                }
            }
            // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
            checkCarouselStatus()
        }
    }
    
    /// 垂直方向内容页视图数量（Int.max表示无限数量）
    public var numberOfVerticalContent: Int = Int.max {
        didSet {
            // 防数量收缩后残留旧下标：staging会按旧下标±1算出错误reserve误发willSwitch(表现为单页轴也能滑出回调、will/did错位)
            if currentVerticalIndex > numberOfVerticalContent - 1 {
                currentVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            if reserveVerticalIndex > numberOfVerticalContent - 1 {
                reserveVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            
            // 展示轴翻转(当前轴数量归零回落另一轴)是纯z序切换不经滑动链路、无任何回调，业务不知道页面换了——检测置顶View变化后补发一次didSwitch并同步方向/标记(下标未变按语义只发did)
            let previousUpperContentView = upperContentView
            bringContentToFront()
            if let currentUpperContentView = upperContentView, currentUpperContentView !== previousUpperContentView {
                if (currentUpperContentView == horizontalViews?.first) && (numberOfHorizontalContent >= 1) {
                    internalSliderDirection = .left
                    hasInitialCallbackHorizontal = true
                    switchContentCallback(isDidSwitch: true, direction: .left)
                }else if (currentUpperContentView == verticalViews?.first) && (numberOfVerticalContent >= 1) {
                    internalSliderDirection = .up
                    hasInitialCallbackVertical = true
                    switchContentCallback(isDidSwitch: true, direction: .up)
                }
            }
            // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
            checkCarouselStatus()
        }
    }
    
    /// 支持的滑动方向
    public var contentSlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet {
            bringContentToFront()
            checkContentSizeAndContentOffset()
            // 方向变化会改变 isScrollEnabled 的计算分支，需同步刷新
            checkCarouselStatus()
        }
    }
    
    /// 当前水平方向内容页索引
    public private(set) var currentHorizontalIndex: Int = 0
    
    /// 水平方向储备内容页索引
    public private(set) var reserveHorizontalIndex: Int = 0
    
    /// 当前垂直方向内容页索引
    public private(set) var currentVerticalIndex: Int = 0
    
    /// 垂直方向储备内容页索引
    public private(set) var reserveVerticalIndex: Int = 0
    
    /// 自动轮播时每一页停留时间，默认为3s，最少1s(当设置的值小于1s时，则为默认值)
    public var standingTime: TimeInterval = 3

    /// 轻扫跨轴直切的速度阈值(单位：pt/s，默认500；仅影响全向模式的轻扫跨轴判定，同轴翻页不经过此阈值，值越低越灵敏，越高越保守)
    public var crossAxisFlickVelocityThreshold: CGFloat = 500 {
        didSet {
            let clampedValue = min(max(crossAxisFlickVelocityThreshold, 50), 3000)
            if clampedValue != crossAxisFlickVelocityThreshold {
                // 在自身didSet内赋值不会递归，Swift语言规定，didSet内给本属性赋值时新值直接替换刚设置的值、观察器不会再次触发,导致卡死闪退，这是Swift官方文档定义的行为
                crossAxisFlickVelocityThreshold = clampedValue
            }
        }
    }
    
    /// 水平方向是否支持滑动(仅内容页数量大于1时生效，单页/无内容时该方向不可滑)，默认true
    public var horizontalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }

    /// 垂直方向是否支持滑动(仅内容页数量大于1时生效，单页/无内容时该方向不可滑)，默认true
    public var verticalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 是否需要无限滑动/轮播
    public var unlimitedCarousel: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 是否需要自动轮播/轮播
    public var automaticCarousel: Bool = true
    
    /// 设置需要显示的自定义View(contentSlidingDirection != omnidirectional 时调用)，currentView 为正在显示的View、reserveView 为预备显示的View，两者Size都将等于当前WYContentScrollView的Size
    public func horizontalOrVerticalDisplay(currentView: UIView,
                                            reserveView: UIView) {
        
        guard contentSlidingDirection != .omnidirectional else {
            return
        }

        // 重挂同一组View时保留组件内部当前/预备顺序：调用方自行保管的数组不随翻页交换(顺序滞后)，按其顺序重挂会把持有旧内容的View置顶(表现为切方向后无动画秒回上一页)
        let displayViews: [UIView] = resolveDisplayOrder([currentView, reserveView], existingViews: (contentSlidingDirection == .leftOrRight) ? horizontalViews : verticalViews)

        contentViewInitializationCheck([currentView, reserveView])

        if contentSlidingDirection == .leftOrRight {
            horizontalViews = displayViews
        }

        if contentSlidingDirection == .topOrBottom {
            verticalViews = displayViews
        }
        
        internalSettingsContentView(isReload: true)
    }
    
    /// 设置需要显示的自定义View(contentSlidingDirection == omnidirectional 时调用)，水平/垂直方向各需 current(正在显示)与 reserve(预备显示)两个View，Size都将等于当前WYContentScrollView的Size
    public func omnidirectionalDisplay(currentHorizontalView: UIView,
                                       reserveHorizontalView: UIView,
                                       currentVerticalView: UIView,
                                       reserveVerticalView: UIView) {
        
        if contentSlidingDirection == .omnidirectional {

            // 重挂同一组View时保留组件内部当前/预备顺序(两轴各自判定)：按调用方滞后的顺序重挂会把旧内容View置顶(表现为切方向后无动画秒回上一页)
            let displayHorizontalViews: [UIView] = resolveDisplayOrder([currentHorizontalView, reserveHorizontalView], existingViews: horizontalViews)
            let displayVerticalViews: [UIView] = resolveDisplayOrder([currentVerticalView, reserveVerticalView], existingViews: verticalViews)

            contentViewInitializationCheck([currentHorizontalView, reserveHorizontalView, currentVerticalView, reserveVerticalView])

            horizontalViews = displayHorizontalViews
            verticalViews = displayVerticalViews

            internalSettingsContentView(isReload: true)
        }
    }
    
    /// 当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)
    public var prioritySlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet {
            bringContentToFront()
        }
    }
    
    /// 当前轮播应推进的方向：单轴模式为模式本身(该轴数量不足2时不轮播，返回nil)，全向模式跟随当前置顶的ContentView所属轴(跨轴直切切换展示轴后，轮播轴随之切换)；展示轴数量不足2同样返回nil——轮播绝不翻非展示轴，否则会把不可见页的回调与下标变动强加给业务
    private var carouselDirection: WYContentSlidingDirection? {

        switch contentSlidingDirection {
        case .leftOrRight:
            return (numberOfHorizontalContent >= 2) ? .leftOrRight : nil
        case .topOrBottom:
            return (numberOfVerticalContent >= 2) ? .topOrBottom : nil
        case .omnidirectional:
            guard let currentContentView = upperContentView else { return nil }
            if currentContentView == horizontalViews?.first {
                return (numberOfHorizontalContent >= 2) ? .leftOrRight : nil
            }
            return (numberOfVerticalContent >= 2) ? .topOrBottom : nil
        }
    }

    /// 开启定时器(默认开启，调用该方法会重新开启)
    public func startTimer() {

        // 如果已经开启了，就先关闭计时器
        if timer != nil {
            // 停止计时器
            stopTimer()
        }

        // 未开启轮播或不支持无限循环则跳过
        guard (unlimitedCarousel != false) &&
                (automaticCarousel != false) else {
            return
        }

        // 创建时仅判一次能否开启轮播(单轴数量不足2/全向无置顶View则不开)；运行期轮播方向由timer闭包每次触发实时推导，跨轴直切换展示轴后跟随新轴
        guard (carouselDirection != nil) else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            guard let self = self else { return }
            // 每次触发时重新推导轮播方向：跨轴直切后跟随新的展示轴；推导失败(重挂载等过渡态)跳过本次触发
            guard let direction = self.carouselDirection else { return }
            self.nextContent(direction)
        })
        RunLoop.current.add(timer!, forMode: .common)
        
        canRestartedTimer = true
    }
    
    /// 停止定时器
    public func stopTimer() {
        pauseTimer()
        canRestartedTimer = false
    }

    /// 暂停定时器
    private func pauseTimer() {
        if timer != nil {
        }
        timer?.invalidate()
        timer = nil
    }

    /// 轮播计时器随展示轴/数量/开关动态启停：当前展示轴翻不了页(数量不足2/关自动轮播/关无限轮播)时停止并清除计时器(避免定时器每3秒空转一次)，恢复可翻时若此前开启过轮播则自动重启；调用点：checkCarouselStatus(方向/数量/开关变化都会经过)与跨轴直切收尾(展示轴翻转不经方向与数量变化)
    private func refreshCarouselTimer() {

        guard (automaticCarousel != false) && (unlimitedCarousel != false) && (carouselDirection != nil) else {
            // 用暂停而非停止：条件恢复(数量改回/开关重开/展示轴翻回)后自动续播，重启标记不能丢
            pauseTimer()
            return
        }

        // 计时器不在跑且开启过轮播才重启：从未startTimer或业务已关轮播则不复活(stopTimer是软停，真正关闭用automaticCarousel=false，与松手重启语义一致)；用户拖动/惯性中不重启，由松手回调负责
        if (timer == nil) && (canRestartedTimer == true) && (isTracking == false) && (isDecelerating == false) {
            startTimer()
        }
    }
    
    /// 切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)
    public func nextContent(_ direction: WYContentSlidingDirection) {
        switch direction {
        case .leftOrRight:
            if !((numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false) { return }
        case .topOrBottom:
            if !((numberOfVerticalContent > 1) ? verticalSliderEnabled : false) { return }
        default:
            return
        }

        isDirectionLocked = false
        dragLockedDirection = .unknown
        internalSliderDirection = .unknown
        // 标记程序化动画窗口：动画期间两轴能力放开，防判轴前全钳制抹掉头几帧位移导致终点不够整页
        isProgrammaticAnimatedScroll = true

        switch direction {
        case .leftOrRight:
            guard contentSlidingDirection != .topOrBottom else {
                return
            }
            // 只有在最后一页时才要求无限轮播开启(用于循环回到第一页)，非最后一页无论是否无限轮播都允许切下一页
            if currentHorizontalIndex == (numberOfHorizontalContent - 1) {
                guard unlimitedCarousel else { return }
            }

            // 跨轴程序化切换统一无动画直切(与轻扫直切同观感)：目标轴非当前展示轴时瞬间落位+手动收尾——非动画setContentOffset不会回调DidEndScrollingAnimation；窗口标记已在上方置位，didScroll链路同步完成staging/willSwitch/展示轴翻转/下标推进
            if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                setContentOffset(CGPoint(x: wy_width * 2, y: wy_height), animated: false)
                pauseScroll()
                return
            }

            setContentOffset(CGPoint(x: wy_width*2, y: (contentSlidingDirection == .omnidirectional) ? wy_height : 0), animated: true)

            break
        case .topOrBottom:
            guard contentSlidingDirection != .leftOrRight else {
                return
            }
            
            // 只有在最后一页时才要求无限轮播开启(用于循环回到第一页)，非最后一页无论是否无限轮播都允许切下一页
            if currentVerticalIndex == (numberOfVerticalContent - 1) {
                guard unlimitedCarousel else { return }
            }

            // 跨轴程序化切换统一无动画直切(与轻扫直切同观感)：目标轴非当前展示轴时瞬间落位+手动收尾——非动画setContentOffset不会回调DidEndScrollingAnimation；窗口标记已在上方置位，didScroll链路同步完成staging/willSwitch/展示轴翻转/下标推进
            if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                setContentOffset(CGPoint(x: wy_width, y: wy_height * 2), animated: false)
                pauseScroll()
                return
            }

            setContentOffset(CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: wy_height*2), animated: true)
            break
            
        default:
            break
        }
    }
    
    /// 切换指定方向上一个内容页面(不支持直接传入direction为omnidirectional)
    public func lastContent(_ direction: WYContentSlidingDirection) {
        switch direction {
        case .leftOrRight:
            if !((numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false) { return }
        case .topOrBottom:
            if !((numberOfVerticalContent > 1) ? verticalSliderEnabled : false) { return }
        default:
            return
        }
        
        isDirectionLocked = false
        dragLockedDirection = .unknown
        internalSliderDirection = .unknown
        // 标记程序化动画窗口：动画期间两轴能力放开，防判轴前全钳制抹掉头几帧位移导致终点不够整页
        isProgrammaticAnimatedScroll = true

        switch direction {
        case .leftOrRight:
            guard contentSlidingDirection != .topOrBottom else {
                return
            }

            // 只有在第一页时才要求无限轮播开启(用于循环回到最后一页)，非第一页无论是否无限轮播都允许切上一页
            if currentHorizontalIndex <= 0 {
                guard unlimitedCarousel else { return }
            }

            // 跨轴程序化切换统一无动画直切(与轻扫直切同观感)：目标轴非当前展示轴时瞬间落位+手动收尾——非动画setContentOffset不会回调DidEndScrollingAnimation；窗口标记已在上方置位，didScroll链路同步完成staging/willSwitch/展示轴翻转/下标推进
            if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                setContentOffset(CGPoint(x: 0, y: wy_height), animated: false)
                pauseScroll()
                return
            }

            setContentOffset(CGPoint(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0)), animated: true)

            break
        case .topOrBottom:
            guard contentSlidingDirection != .leftOrRight else {
                return
            }
            
            // 只有在第一页时才要求无限轮播开启(用于循环回到最后一页)，非第一页无论是否无限轮播都允许切上一页，与水平分支对齐
            if currentVerticalIndex <= 0 {
                guard unlimitedCarousel else { return }
            }

            // 跨轴程序化切换统一无动画直切(与轻扫直切同观感)：目标轴非当前展示轴时瞬间落位+手动收尾——非动画setContentOffset不会回调DidEndScrollingAnimation；窗口标记已在上方置位，didScroll链路同步完成staging/willSwitch/展示轴翻转/下标推进
            if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                setContentOffset(CGPoint(x: wy_width, y: 0), animated: false)
                pauseScroll()
                return
            }

            setContentOffset(CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0), animated: true)
            break
            
        default:
            break
        }
    }
    
    /// 切换到指定方向指定下标处(不支持直接传入direction为omnidirectional)，内部通过把 currentXxxIndex 预设为目标下标∓1 再借 lastContent/nextContent 一次滑动到达目标页
    public func switchContent(_ direction: WYContentSlidingDirection, index: inout Int) {
        switch direction {
        case .leftOrRight:
            
            if index < 0 { index = 0 }
            if index > (numberOfHorizontalContent - 1) { index = (numberOfHorizontalContent - 1) }
            
            guard (contentSlidingDirection != .topOrBottom) || (index != currentHorizontalIndex) else {
                return
            }
            
            // 向后跳预设目标+1再lastContent(实际滑到 目标+1-1=目标)，向前跳预设目标-1再nextContent(实际滑到 目标-1+1=目标)；预设值恒不落在边界guard上，切换不会被无限轮播拦截，索引也不会被污染
            if index < currentHorizontalIndex {
                currentHorizontalIndex = (index + 1)
                lastContent(direction)
            }else if index > currentHorizontalIndex {
                currentHorizontalIndex = (index - 1)
                nextContent(direction)
            }else if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                // 同下标但展示轴在另一侧：目标页就是水平轴当前下标，只需翻转展示轴——走直切通道(下标不变、只发didSwitch、无动画)；同轴相等时保持原有no-op
                instantCrossAxisEntry(.left)
            }else {
            }

            break
        case .topOrBottom:
            
            if index < 0 { index = 0 }
            if index > (numberOfVerticalContent - 1) { index = (numberOfVerticalContent - 1) }
            
            guard (contentSlidingDirection != .leftOrRight) || (index != currentVerticalIndex) else {
                return
            }
            
            // 向后跳预设目标+1再lastContent，向前跳预设目标-1再nextContent，预设值恒不落在边界guard上
            if index < currentVerticalIndex {
                currentVerticalIndex = (index + 1)
                lastContent(direction)
            }else if index > currentVerticalIndex {
                currentVerticalIndex = (index - 1)
                nextContent(direction)
            }else if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                // 同下标但展示轴在另一侧：目标页就是垂直轴当前下标，只需翻转展示轴——走直切通道(下标不变、只发didSwitch、无动画)；同轴相等时保持原有no-op
                instantCrossAxisEntry(.up)
            }else {
            }
            break
        default:
            break
        }
    }
    
    /// 便捷初始化方法
    public convenience init() {
        self.init(frame: .zero)
    }
    
    /// 指定初始化方法，通过 frame 创建视图
    public override init(frame: CGRect) {
        super.init(frame: frame)
        internalInitializationSettings()
    }
    
    /// 从故事板或 XIB 加载时所需的初始化方法
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        internalInitializationSettings()
    }
    
    deinit {
        stopTimer()
        WYLogManager.output("WYContentScrollView deinit")
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}

extension WYContentScrollView {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 检查(设置)contentSize与contentOffset
        checkContentSizeAndContentOffset()
        // 如果frame发生变化需要及时更新内容视图的frame
        internalSettingsContentView(isReload: false)
    }
    
    public override weak var delegate: (any UIScrollViewDelegate)? {
        get {
            return internalDelegate
        }
        set {
            // 防止异常设置（避免死循环）
            guard newValue !== self else { return }
            
            // 如果系统在释放时传入 nil，且没有外部代理，加上super.delegate 目前是 nil，则跳过设置，避免在对象释放过程中再次建立 weak 引用导致闪退
            if newValue == nil && internalDelegate == nil && super.delegate == nil {
                return
            }
            
            internalDelegate = newValue
            // 只有不是 self 时才设置（避免重复）
            if super.delegate !== self {
                super.delegate = self
            }
        }
    }
    
    /// 检查各ContentView的superView
    private func contentViewInitializationCheck(_ contentViews: [UIView]) {

        contentViews.forEach { $0.removeFromSuperview() }

        // 统一清理水平与垂直两个方向的 view，避免残留 view 遮挡新方向内容
        horizontalViews?.forEach { $0.removeFromSuperview() }
        horizontalViews = nil
        verticalViews?.forEach { $0.removeFromSuperview() }
        verticalViews = nil
    }

    /// 解析重挂载时应采用的View顺序：传入View组与组件现有View组完全一致(身份级、不看顺序)时保留组件内部的当前/预备顺序(组件每次翻页成功都会交换两View位置，调用方自行保管的数组是滞后的，按其顺序重挂会把旧内容View置顶)；传入新View组时尊重调用方顺序
    private func resolveDisplayOrder(_ incomingViews: [UIView], existingViews: [UIView]?) -> [UIView] {

        guard let existingViews = existingViews,
              (existingViews.count == 2) && (incomingViews.count == 2),
              Set(incomingViews.map(ObjectIdentifier.init)) == Set(existingViews.map(ObjectIdentifier.init)) else {
            return incomingViews
        }

        return existingViews
    }
    
    /// 内部初始化设置
    private func internalInitializationSettings() {
        
        super.delegate = self
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickContent))
        addGestureRecognizer(gestureRecognizer)
        
        // 强制关闭 bounces，边界行为统一由 canScroll/handleScrollDirectionLock 控制，条件开启 bounces 需联动 contentSize/alwaysBounce/isPagingEnabled等，判断点过多会引入一系列其他问题
        bounces = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
    }
    
    /// 内部设置添加ContentView
    private func internalSettingsContentView(isReload: Bool) {

        // 布局前记录内容View是否尚未挂载(以此判断本次是否为首次展示/切换方向后的重新展示)
        let isInitialDisplay: Bool = (horizontalViews?.first?.superview == nil) && (verticalViews?.first?.superview == nil)

        if (contentSlidingDirection == .omnidirectional) {
            if prioritySlidingDirection == .topOrBottom {
                layoutContentSubViews(.leftOrRight, isReload: isReload)
                layoutContentSubViews(.topOrBottom, isReload: isReload)
            }else {
                layoutContentSubViews(.topOrBottom, isReload: isReload)
                layoutContentSubViews(.leftOrRight, isReload: isReload)
            }
        }else {
            layoutContentSubViews(contentSlidingDirection, isReload: isReload)
        }
        
        // 本次确实新挂载了内容View才触发初始didSwitch(只回调当前展示方向，另一方向等首次滑动时补发)
        let didDisplay: Bool = (horizontalViews?.first?.superview != nil) || (verticalViews?.first?.superview != nil)
        if isInitialDisplay && didDisplay {


            internalSliderDirection = .unknown

            // 本次展示(前置)的方向：左右模式与全向(优先非上下)为水平轴，上下模式与全向优先上下为垂直轴
            let isHorizontalFront: Bool = (initialDisplayDirection == .left) || (initialDisplayDirection == .right)
            // 非展示轴重置标记，等首次滑动时在scrollViewDidScroll补发
            if isHorizontalFront {
                hasInitialCallbackVertical = false
            }else {
                hasInitialCallbackHorizontal = false
            }
            // 展示轴只有在尚未回调过时才发初始didSwitch(如左右切全向且优先左右，水平轴一直是展示方向则不再重复回调)
            if isHorizontalFront && !hasInitialCallbackHorizontal {
                hasInitialCallbackHorizontal = true
                switchContentCallback(isDidSwitch: true, direction: initialDisplayDirection)
            }else if !isHorizontalFront && !hasInitialCallbackVertical {
                hasInitialCallbackVertical = true
                switchContentCallback(isDidSwitch: true, direction: initialDisplayDirection)
            }
        }
    }
    
    /// 按方向布局内容视图：currentView 固定位于中心页，reserveView 位于其滑动方向一侧(全向模式下水平/垂直各自的中心重叠，靠 bringContentToFront 决定顶层)
    private func layoutContentSubViews(_ direction: WYContentSlidingDirection, isReload: Bool) {

        if direction == .leftOrRight {

            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }

            // 自身尺寸未变化且非强制重载时跳过布局，避免 layoutSubviews 频繁触发造成浪费
            guard (!CGSizeEqualToSize(frame.size, currentHorizontalView.frame.size)) || (isReload == true) else {
                return
            }
            
            var currentHorizontalViewOffset: CGPoint = .zero
            var reserveHorizontalViewOffset: CGPoint = .zero
            if (contentSlidingDirection == .omnidirectional) {
                currentHorizontalViewOffset = CGPoint(x: wy_width, y: wy_height)
                reserveHorizontalViewOffset = CGPoint(x: 2 * wy_width, y: wy_height)
            }else {
                currentHorizontalViewOffset = CGPoint(x: wy_width, y: 0)
                reserveHorizontalViewOffset = CGPoint(x: 2 * wy_width, y: 0)
            }
            
            let currentHorizontalViewFrame: CGRect = CGRect(x: currentHorizontalViewOffset.x, y: currentHorizontalViewOffset.y, width: wy_width, height: wy_height)
            
            let reserveHorizontalViewFrame: CGRect = CGRect(x: reserveHorizontalViewOffset.x, y: reserveHorizontalViewOffset.y, width: wy_width, height: wy_height)
            
            if !CGRectEqualToRect(currentHorizontalView.frame, currentHorizontalViewFrame) {
                currentHorizontalView.frame = currentHorizontalViewFrame
            }
            
            if !CGRectEqualToRect(reserveHorizontalView.frame, reserveHorizontalViewFrame) {
                reserveHorizontalView.frame = reserveHorizontalViewFrame
            }
            
            if (currentHorizontalView.superview == nil) && (reserveHorizontalView.superview == nil) {
                upperContentView = currentHorizontalView
                addSubview(reserveHorizontalView)
                addSubview(currentHorizontalView)
            }
        }
        
        if direction == .topOrBottom {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            guard (!CGSizeEqualToSize(frame.size, currentVerticalView.frame.size)) || (isReload == true) else {
                return
            }
            
            var currentVerticalViewOffset: CGPoint = .zero
            var reserveVerticalViewOffset: CGPoint = .zero
            if (contentSlidingDirection == .omnidirectional) {
                currentVerticalViewOffset = CGPoint(x: wy_width, y: wy_height)
                reserveVerticalViewOffset = CGPoint(x: wy_width, y: 2 * wy_height)
            }else {
                currentVerticalViewOffset = CGPoint(x: 0, y: wy_height)
                reserveVerticalViewOffset = CGPoint(x: 0, y: 2 * wy_height)
            }
            
            let currentVerticalViewFrame: CGRect = CGRect(x: currentVerticalViewOffset.x, y: currentVerticalViewOffset.y, width: wy_width, height: wy_height)
            
            let reserveVerticalViewFrame: CGRect = CGRect(x: reserveVerticalViewOffset.x, y: reserveVerticalViewOffset.y, width: wy_width, height: wy_height)
            
            if !CGRectEqualToRect(currentVerticalView.frame, currentVerticalViewFrame) {
                currentVerticalView.frame = currentVerticalViewFrame
            }
            
            if !CGRectEqualToRect(reserveVerticalView.frame, reserveVerticalViewFrame) {
                reserveVerticalView.frame = reserveVerticalViewFrame
            }
            
            if (currentVerticalView.superview == nil) && (reserveVerticalView.superview == nil) {
                upperContentView = currentVerticalView
                addSubview(reserveVerticalView)
                addSubview(currentVerticalView)
            }
        }
        // 初始化时同步lastValid：不同步的话紧随其后的handleScrollDirectionLock会用旧方向的合法偏移把新布局的contentOffset锁回去(表现为闪一下又跳回)
        lastValidContentOffset = contentOffset
    }
    
    /// 检查当前滚动能力（只控制整体是否可滚动，不参与方向控制）
    private func checkCarouselStatus() {
        
        switch contentSlidingDirection {
        case .leftOrRight:
            // 横向滑动(单页/无内容不可滑)
            isScrollEnabled = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false
            break
        case .topOrBottom:
            // 纵向滑动(单页/无内容不可滑)
            isScrollEnabled = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false
            break
        case .omnidirectional:
            // 横向轴是否存在内容且允许滑动
            let horizontalExists = (numberOfHorizontalContent >= 1) && horizontalSliderEnabled
            // 纵向轴是否存在内容且允许滑动
            let verticalExists = (numberOfVerticalContent >= 1) && verticalSliderEnabled

            // 此模式下只要有一个方向存在内容且允许滑动就放开全局滚动(isScrollEnabled是全局的)，具体方向与单页约束通过handleScrollDirectionLock与canScroll按展示轴动态实现
            isScrollEnabled = horizontalExists || verticalExists
            break
        }

        // 方向/数量/开关任何变化后动态启停轮播计时器(展示轴翻不了页时清除防空转，恢复可翻时自动重启)
        refreshCarouselTimer()
    }
    
    /// 判断设置展示在顶层的对应方向的View，若contentViews为空则内部自行判断
    private func bringContentToFront(_ contentViews: [UIView]? = nil) {
        
        // 直接将传入的对应的ContentView移到WYContentScrollView的最顶层，且因为currentView和reserveView的frame有可能是一样的，所以需要最后执行bringSubviewToFront(currentView)
        if (contentViews?.count == 2), let currentView = contentViews?.first, let reserveView = contentViews?.last  {
            if upperContentView != currentView {
                bringSubviewToFront(reserveView)
                bringSubviewToFront(currentView)
                upperContentView = currentView
            }
            return
        }else {
            // 根据各方向的显示数量以及支持的滑动方向和全向模式时优先显示的方向来设置显示优先级
            switch contentSlidingDirection {
            case .leftOrRight:
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                if upperContentView != currentHorizontalView {
                    bringSubviewToFront(reserveHorizontalView)
                    bringSubviewToFront(currentHorizontalView)
                    upperContentView = currentHorizontalView
                }
                return
            case .topOrBottom:
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                if upperContentView != currentVerticalView {
                    bringSubviewToFront(reserveVerticalView)
                    bringSubviewToFront(currentVerticalView)
                    upperContentView = currentVerticalView
                }
                return
            case .omnidirectional:
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                if (numberOfHorizontalContent >= 1) && (upperContentView == currentHorizontalView) {
                    // 水平轴正在置顶展示且仍有内容：停留在水平轴，不因数量变化被劫持
                    return
                }
                if (numberOfVerticalContent >= 1) && (upperContentView == currentVerticalView) {
                    // 垂直轴正在置顶展示且仍有内容：停留在垂直轴，不因数量变化被劫持
                    return
                }

                if ((numberOfHorizontalContent > 1) && (numberOfVerticalContent > 1)) || (numberOfHorizontalContent == numberOfVerticalContent) {
                    
                    // 都大于1或者都等于1，则依据优先显示方向来处理
                    if (prioritySlidingDirection == .leftOrRight) && (upperContentView != currentHorizontalView) {
                        bringSubviewToFront(reserveHorizontalView)
                        bringSubviewToFront(currentHorizontalView)
                        upperContentView = currentHorizontalView
                        return
                    }
                    if (prioritySlidingDirection == .topOrBottom) && (upperContentView != currentVerticalView) {
                        bringSubviewToFront(reserveVerticalView)
                        bringSubviewToFront(currentVerticalView)
                        upperContentView = currentVerticalView
                        return
                    }
                }else {
                    // 先按数量决定该显示哪个方向，再判断是否需要切换，每个方向处理完直接 return，杜绝 fall through 到另一方向
                    if numberOfHorizontalContent > numberOfVerticalContent {
                        if upperContentView != currentHorizontalView {
                            bringSubviewToFront(reserveHorizontalView)
                            bringSubviewToFront(currentHorizontalView)
                            upperContentView = currentHorizontalView
                        }
                        return
                    } else {
                        if upperContentView != currentVerticalView {
                            bringSubviewToFront(reserveVerticalView)
                            bringSubviewToFront(currentVerticalView)
                            upperContentView = currentVerticalView
                        }
                        return
                    }
                }
            }
        }
    }
    
    /// 处理方向锁定并返回当前滑动方向：锁死不可滑动的方向(回退到 lastValidContentOffset)、全向模式下判定并锁定拖拽主方向、边界处钳制 contentOffset 防止越过中心露出背景
    private func handleScrollDirectionLock() -> WYSlidingDirection {

        // 方向推导必须读钳制前的原始偏移：程序化动画的位移会被下方轴能力钳制抹回中心，读钳制后偏移则delta恒0判不了轴(轮播停摆)
        let incomingOffset = contentOffset

        // 横向是否允许滑动(非全向：单页/无内容不可滑)
        var horizontalCanScroll = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false

        // 纵向是否允许滑动(非全向：单页/无内容不可滑)
        var verticalCanScroll = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false

        if contentSlidingDirection == .omnidirectional {
            
            // 展示轴判定(方向未知时按置顶View判)：优先方向只是挂载瞬间的展示轴代理，按它判会把垂直展示后的垂直滑动/翻页误判成跨轴而拦死
            let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)
            horizontalCanScroll = false
            verticalCanScroll = false
            if isDirectionLocked {
                let lockedAxisIsHorizontal = (dragLockedDirection == .left) || (dragLockedDirection == .right)
                horizontalCanScroll = lockedAxisIsHorizontal && displayedAxisIsHorizontal && (numberOfHorizontalContent > 1) && horizontalSliderEnabled
                verticalCanScroll = (lockedAxisIsHorizontal == false) && (displayedAxisIsHorizontal == false) && (numberOfVerticalContent > 1) && verticalSliderEnabled
            }
        }

        if isInstantCrossAxisEntry || isProgrammaticAnimatedScroll {
            // 轻扫直切/程序化动画滚动期间：两轴能力临时放开(单轴约束由下方方向锁定逻辑保证)，避免偏移被钳回中心(程序化动画被钳会欠位移导致终点不够整页、切换失败弹回)
            horizontalCanScroll = true
            verticalCanScroll = true
        }
        
        // 目标偏移量
        var targetOffset = contentOffset
        
        // 禁止横向滑动
        if !horizontalCanScroll {
            targetOffset.x = lastValidContentOffset.x
        }
        
        // 禁止纵向滑动
        if !verticalCanScroll {
            targetOffset.y = lastValidContentOffset.y
        }
        
        // 如果发生变化则修正
        if targetOffset != contentOffset {
            contentOffset = targetOffset
        }
        
        // 记录合法偏移量
        lastValidContentOffset = targetOffset
        
        let offsetX = incomingOffset.x
        let offsetY = incomingOffset.y

        var slidingDirection: WYSlidingDirection = internalSliderDirection

        // 仅在全方向模式下处理
        if contentSlidingDirection == .omnidirectional {
            
            let centerX = wy_width
            let centerY = wy_height

            // 相对中心点的偏移
            let deltaX = offsetX - centerX
            let deltaY = offsetY - centerY
        
            // 防抖
            let threshold: CGFloat = 2.0

            // 未锁定时，根据主方向判断一次(判轴依据手指位移而非contentOffset的delta：零行程钳制下delta恒为0，offset判不出跨轴意图；手指上/左滑=offset增=left/up，符号需取反)
            if isDirectionLocked == false {

                let panTranslation = panGestureRecognizer.translation(in: self)
                var translationX = -panTranslation.x
                var translationY = -panTranslation.y
                if isInstantCrossAxisEntry {
                    // 轻扫直切期间没有手势位移，按直切偏移方向判轴定向
                    translationX = deltaX
                    translationY = deltaY
                }else if (isTracking == false) && (isDecelerating == false) {
                    // 纯程序化滚动(定时器轮播/nextContent/lastContent/switchContent)没有手指：pan位移恒为0锁不上轴，判轴前两轴全钳制会把程序化动画掐死在第一帧(表现为切全向后轮播停止；缠斗期间staging仍发willSwitch、失败复位又把页面无动画弹回原页)；此场景回退按偏移位移判轴(与直切同源)。用户路径不受影响：同轴拖动靠手指位移先锁再放行，被钳制的零行程delta≈0不会误锁；同时消除手势结束后残留的陈旧位移被程序化滚动误用导致的时好时坏
                    translationX = deltaX
                    translationY = deltaY
                }
                // 判轴防抖取10pt后按主分量定轴(不要求优势倍数)：优势倍数要求会让接近斜向的同轴手势永远锁不上轴、全程被钳制(表现为同轴前几次滑动弹跳/无法切换)；10pt内两轴全钳制的手感与两轴均单页一致，斜向抖动被吸收在10pt内
                let lockThreshold: CGFloat = 10.0
                if (abs(translationX) > lockThreshold) || (abs(translationY) > lockThreshold) {
                    if abs(translationX) >= abs(translationY) {
                        // 横向
                        if translationX > 0 {
                            slidingDirection = .left
                        } else {
                            slidingDirection = .right
                        }
                    }else {
                        // 纵向
                        if translationY > 0 {
                            slidingDirection = .up
                        } else {
                            slidingDirection = .down
                        }
                    }
                    // 一旦判断完成，立即锁定并记录本次拖拽方向，用于边界拦截后 internalSliderDirection 未更新时仍能保持方向
                    isDirectionLocked = true
                    dragLockedDirection = slidingDirection
                }
            } else {
                // 已锁定轴时，按 contentOffset 的物理偏移符号(deltaX/deltaY 的正负)判断轴内方向，避免 dragLockedDirection 与实际偏移方向不一致时 setter 把 reserveView 摆到错误一侧而闪现(如最后一页先右滑锁 .right、再左滑时 deltaX 已>0 却仍按 .right 放行，导致 setter 把 reserveView 摆到右侧闪现)；只有偏移为0(边界拦截后回中心)才沿用 dragLockedDirection 保持方向让 canScroll 持续拦截
                if dragLockedDirection == .left || dragLockedDirection == .right {
                    if deltaX > 0 {
                        slidingDirection = .left
                    } else if deltaX < 0 {
                        slidingDirection = .right
                    } else {
                        slidingDirection = dragLockedDirection
                    }
                } else {
                    if deltaY > 0 {
                        slidingDirection = .up
                    } else if deltaY < 0 {
                        slidingDirection = .down
                    } else {
                        slidingDirection = dragLockedDirection
                    }
                }
            }
            
            // 锁死另一方向（防止出现多方向同时滑动的问题）
            if isDirectionLocked {
                if slidingDirection == .left || slidingDirection == .right {
                    // 锁死 Y
                    if offsetY != centerY {
                        contentOffset.y = centerY
                    }
                    
                } else if slidingDirection == .up || slidingDirection == .down {
                    // 锁死 X
                    if offsetX != centerX {
                        contentOffset.x = centerX
                    }
                }
            }
        }else {
            if (offsetX != 0) && (contentSlidingDirection != .topOrBottom) {
                if offsetX > wy_width {
                    slidingDirection = .left
                }else if offsetX < wy_width {
                    slidingDirection = .right
                }
            }
            
            if (offsetY != 0) && (contentSlidingDirection != .leftOrRight) {
                if offsetY > wy_height {
                    slidingDirection = .up
                }else if offsetY < wy_height {
                    slidingDirection = .down
                }
            }
        }
        
        return slidingDirection
    }
    
    /// 按滑动方向检查并设置 contentSize 与 contentOffset：currentView 固定停在各方向的中心页；设置 contentOffset 前会先同步 lastValidContentOffset 为同值，避免紧随其触发的 handleScrollDirectionLock 用旧方向的合法偏移把 contentOffset 锁回
    private func checkContentSizeAndContentOffset() {
        switch contentSlidingDirection {
        case .leftOrRight:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: wy_width, y: 0)
                contentOffset = CGPoint(x: wy_width, y: 0)
            }
            break
        case .topOrBottom:
            let targetSize: CGSize = CGSize(width: wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: 0, y: wy_height)
                contentOffset = CGPoint(x: 0, y: wy_height)
            }
            break
        case .omnidirectional:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
                contentOffset = CGPoint(x: wy_width, y: wy_height)
            }
            break
        }
    }
    
    /// 切换内容页回调，isDidSwitch 为 true 表示切换已完成(didSwitch)、false 表示即将切换(willSwitch)；direction 默认取当前滑动方向，首次展示尚未发生滑动时由调用方传入推导出的初始方向
    private func switchContentCallback(isDidSwitch: Bool, direction: WYSlidingDirection = .unknown) {

        // 优先用调用方显式传入的方向(首次展示场景)，否则用当前滑动方向
        let callbackDirection: WYSlidingDirection = (direction != .unknown) ? direction : internalSliderDirection
        
        guard let contentDelegate = contentDelegate, callbackDirection != .unknown else { return }
        
        print("\(isDidSwitch ? "isDidSwitch" : "isWillSwitch"), direction：\(callbackDirection) hIdx=\(currentHorizontalIndex) rhIdx=\(reserveHorizontalIndex) vIdx=\(currentVerticalIndex) rvIdx=\(reserveVerticalIndex)")
        
        if isDidSwitch {
            contentDelegate.wy_contentScrollViewDidSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }else {
            contentDelegate.wy_contentScrollViewWillSwitch?(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }
    }
    
    /// 当前展示形态对应的初始滑动方向：左右模式为.left、上下模式为.up、全向模式按优先方向取(用于首次展示的didSwitch回调，此时尚未发生任何滑动)
    private var initialDisplayDirection: WYSlidingDirection {
        switch contentSlidingDirection {
        case .leftOrRight:
            return .left
        case .topOrBottom:
            return .up
        case .omnidirectional:
            return (prioritySlidingDirection == .topOrBottom) ? .up : .left
        }
    }

    /// 停止滚动并切换contentViews的位置与frame
    func pauseScroll() {


        // 程序化动画已收尾(到达终点或被中断)，清除窗口标记
        isProgrammaticAnimatedScroll = false

        // 清理与回中必须在下方守卫之前无条件执行：直切链路中途失败提前return时若标记残留true，两轴钳制从此失效、一切拖动都会跟手(表现为跨轴变回旧的翻页样式)
        let wasInstantCrossAxisEntry = isInstantCrossAxisEntry

        if isInstantCrossAxisEntry {
            isInstantCrossAxisEntry = false
            lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
            if (canSwitchedPage == false) || (internalSliderDirection == .unknown) {
                contentOffset = CGPoint(x: wy_width, y: wy_height)
                return
            }
        }
        
        // 行程不足的拖动已staging(发过will)但翻页未成立：复位中心页+重置config重新武装willSwitch(失败滑动语义=只will+弹回，下次重新配对)；dir为unknown的程序切换动画分支保持原行为不复活位(防误伤nextContent动画)
        guard (canSwitchedPage == true), (internalSliderDirection != .unknown) else {
            if (canSwitchedPage == false) && (internalSliderDirection != .unknown) && (isInstantCrossAxisEntry == false) {
                let centerOffset = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
                if (contentOffset.x != centerOffset.x) || (contentOffset.y != centerOffset.y) {
                    print("[诊断] 卡中间复位：offset(\(Int(contentOffset.x)),\(Int(contentOffset.y)))→中心 canSwitch=\(canSwitchedPage) dir=\(internalSliderDirection) hIdx=\(currentHorizontalIndex) rhIdx=\(reserveHorizontalIndex)")
                    contentOffset = centerOffset
                    lastValidContentOffset = centerOffset
                }
                configVerticalReserveIndex = currentVerticalIndex
                configHorizontalReserveIndex = currentHorizontalIndex
            }
            return
        }

        isFinalizingSwitch = true
        defer { isFinalizingSwitch = false }

        canSwitchedPage = false

        switch contentSlidingDirection {
        case .leftOrRight:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            contentOffset = CGPoint(x: wy_width, y: 0)

            currentHorizontalIndex = reserveHorizontalIndex
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
            
            // 交换horizontalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
            horizontalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveHorizontalView,currentHorizontalView])
            
            // 下一次方向改变时需要重新设置 reserveHorizontalView
            configHorizontalReserveIndex = nil
            
            switchContentCallback(isDidSwitch: true)
            
            break
        case .topOrBottom:
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            contentOffset = CGPoint(x: 0, y: wy_height)

            currentVerticalIndex = reserveVerticalIndex
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveVerticalView.frame = CGRect(x: 0, y: wy_height, width: wy_width, height: wy_height)
            
            // 交换verticalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
            verticalViews?.swapAt(0, 1)
            
            bringContentToFront([reserveVerticalView, currentVerticalView])
            
            // 下一次方向改变时需要重新设置 reserveVerticalView
            configVerticalReserveIndex = nil
            
            switchContentCallback(isDidSwitch: true)
            
            break
        case.omnidirectional:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            contentOffset = CGPoint(x: wy_width, y: wy_height)
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {

                if wasInstantCrossAxisEntry {
                    // 轻扫直切不翻页不换View：预备View从未staging过目标内容，swap会换到没加载过的View(表现为跨轴来回切内容被重载)
                    bringContentToFront([currentHorizontalView, reserveHorizontalView])
                    configHorizontalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    // 展示轴已翻转：重评轮播(切到可翻轴自动续播、切到单页轴自动停)——直切不触发方向/数量变化，需在此主动刷新
                    refreshCarouselTimer()
                    break
                }

                currentHorizontalIndex = reserveHorizontalIndex

                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换horizontalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
                horizontalViews?.swapAt(0, 1)

                bringContentToFront([reserveHorizontalView, currentHorizontalView])

                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)

            }else {

                if wasInstantCrossAxisEntry {
                    // 轻扫直切不翻页不换View：预备View从未staging过目标内容，swap会换到没加载过的View(表现为跨轴来回切内容被重载)
                    bringContentToFront([currentVerticalView, reserveVerticalView])
                    configVerticalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    // 展示轴已翻转：重评轮播(切到可翻轴自动续播、切到单页轴自动停)——直切不触发方向/数量变化，需在此主动刷新
                    refreshCarouselTimer()
                    break
                }

                currentVerticalIndex = reserveVerticalIndex

                reserveVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换verticalViews数组中两个View的位置——.first恒为新当前页，组件内部数组是"谁是当前页"的唯一事实源(重挂载保序靠它，见resolveDisplayOrder)
                verticalViews?.swapAt(0, 1)

                bringContentToFront([reserveVerticalView, currentVerticalView])

                // 下一次方向改变时需要重新设置 reserveVerticalView
                configVerticalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)
            }
            break
        }
    }
    
    /// 轴向判定：方向明确时按方向判水平/垂直；方向未知(挂载后未滑动、程序切换动画重置、重新展示重置)时按置顶ContentView所属轴判(置顶View是展示轴的事实源，优先方向只是挂载瞬间的代理——按优先方向判会把垂直展示后的垂直翻页/进入/轻扫全部误判成跨轴)；置顶View判不出时按优先方向兜底
    private func axisIsHorizontal(of direction: WYSlidingDirection) -> Bool {

        if (direction == .left) || (direction == .right) {
            return true
        }
        if (direction == .up) || (direction == .down) {
            return false
        }

        if let currentContentView = upperContentView {
            if currentContentView == horizontalViews?.first {
                return true
            }
            if currentContentView == verticalViews?.first {
                return false
            }
        }
        return prioritySlidingDirection != .topOrBottom
    }

    /// 判断当前方向是否可以继续滚动：处于边界页(第一/最后一页)且关闭无限轮播时，往循环方向(无内容方向)的滑动会被拦截并把 contentOffset 拉回中心页
    private func canScroll(_ slidingDirection: WYSlidingDirection) -> Bool {

        guard slidingDirection != .unknown else { return false }

        if (contentSlidingDirection == .omnidirectional) && isDirectionLocked {
            let slidingAxisIsHorizontal = (slidingDirection == .left) || (slidingDirection == .right)
            // 展示轴判定(方向未知时按置顶View判)：优先方向只是挂载瞬间的展示轴代理，按它判会把垂直展示后的垂直滑动/翻页误判成跨轴而拦死
            let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)
            if slidingAxisIsHorizontal != displayedAxisIsHorizontal {
                // 跨轴意图的普通拖动一律拦截(零行程且不触发setter，避免拖动中把另一轴View置顶提前换页，任意数量组合与两轴均单页的手感完全一致)；轻扫直切与程序化跨轴切换(nextContent/lastContent/switchContent指定非展示轴)放行——后者是显式指令，被拦会导致动画锁轴后setter不执行、目标轴无willSwitch不预加载、动画到位却提交失败卡在未加载页
                return isInstantCrossAxisEntry || isProgrammaticAnimatedScroll
            }
        }

        if ((slidingDirection == .left) || (slidingDirection == .right)) && (horizontalSliderEnabled == false) {
            return false
        }
        if ((slidingDirection == .up) || (slidingDirection == .down)) && (verticalSliderEnabled == false) {
            return false
        }

        if (slidingDirection == .left) || (slidingDirection == .right) {

            guard contentSlidingDirection != .topOrBottom else { return false }

            // 边界判断只看 currentHorizontalIndex：canScroll 在 setter 之前执行，若依赖 reserveHorizontalIndex(上一次的值)，先反向滑使其变化后边界拦截会失效、导致 reserveView 闪现
            let isFirstPage = (currentHorizontalIndex == 0)

            let isLastPage = (currentHorizontalIndex == (numberOfHorizontalContent - 1))

            // 关闭无限轮播时，边界页往循环方向不允许切换
            if (isFirstPage && (slidingDirection == .right)) || (isLastPage && (slidingDirection == .left)) {
                if (unlimitedCarousel == false) {
                    let targetOffset: CGPoint = CGPoint(x: wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0))
                    if (!CGPointEqualToPoint(contentOffset, targetOffset)) {
                        contentOffset = targetOffset
                    }
                    return false
                }
            }
            
        }else {
            
            guard contentSlidingDirection != .leftOrRight else { return false }
            
            // 边界判断只看 currentVerticalIndex：canScroll 在 setter 之前执行，若依赖 reserveVerticalIndex(上一次的值)，先反向滑使其变化后边界拦截会失效、导致 reserveView 闪现
            let isFirstPage = (currentVerticalIndex == 0)

            let isLastPage = (currentVerticalIndex == (numberOfVerticalContent - 1))
            
            // 关闭无限轮播时，边界页往循环方向不允许切换
            if (isFirstPage && (slidingDirection == .down)) || (isLastPage && (slidingDirection == .up)) {
                if (unlimitedCarousel == false) {
                    let targetOffset: CGPoint = CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: wy_height)
                    if (!CGPointEqualToPoint(contentOffset, targetOffset)) {
                        contentOffset = targetOffset
                    }
                    return false
                }
            }
        }
        
        return true
    }
    
    /// 点击了内容页面
    @objc func didClickContent() {

        guard let contentDelegate = contentDelegate else { return }

        // 尚未发生任何滑动时点击的是当前展示方向的内容页，用initialDisplayDirection推导展示方向来分发；已滑动过则沿用实际滑动方向
        let clickDirection: WYSlidingDirection = (internalSliderDirection != .unknown) ? internalSliderDirection : initialDisplayDirection

        if (clickDirection == .left) || (clickDirection == .right) {

            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }

            contentDelegate.wy_contentScrollViewDidClick?(self, direction: clickDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
        }else {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }

            contentDelegate.wy_contentScrollViewDidClick?(self, direction: clickDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
        }
    }
    
    /// 当前滑动方向：setter 内同步完成 reserveView 的摆位(按当前偏移量放到滑动方向一侧)、reserveIndex 的计算(含关闭无限轮播时的边界处理)以及 willSwitch 回调的触发
    private var internalSliderDirection: WYSlidingDirection {
        set(newValue) {
            
            // 跨轴判定必须用写入前的方向：先写入再读的话previous恒等于newValue(恒判同轴)
            let previousDirection: WYSlidingDirection = objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown

            objc_setAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if ((newValue == .up) || (newValue == .down) && (contentSlidingDirection != .leftOrRight)) {
                
                guard numberOfVerticalContent > 0 else { return }
                
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                
                // 滑动前根据滑动方向的偏移量设置预备显示View的frame(不能简单根据newValue来设置，否则手指不松开上下滑动时无法更新reserveVerticalView.frame，且必须放这里优先处理，否则往左右滑动后可能会出现空白页面)
                if contentOffset.y > wy_height {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                }else {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                }
                
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentVerticalView, reserveVerticalView])

                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && previousAxisIsHorizontal && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveVerticalIndex = currentVerticalIndex
                }else if newValue == .up {
                    reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                    if (reserveVerticalIndex == 0) && (unlimitedCarousel == false) {
                        reserveVerticalIndex = currentVerticalIndex
                    }
                }else {
                    reserveVerticalIndex = currentVerticalIndex - 1
                    if (reserveVerticalIndex < 0)  {
                        reserveVerticalIndex = (unlimitedCarousel == false) ? currentVerticalIndex : (numberOfVerticalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will
                let isPageIndexChanged = (reserveVerticalIndex != currentVerticalIndex)
                if isPageIndexChanged && ((configVerticalReserveIndex != reserveVerticalIndex) || isCrossAxisEntry) {
                    switchContentCallback(isDidSwitch: false)
                }
            }
            
            if ((newValue == .left) || (newValue == .right) && (contentSlidingDirection != .topOrBottom)) {
                
                guard numberOfHorizontalContent > 0 else { return }
                
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                
                // 滑动前根据滑动方向的偏移量设置预备显示View的frame(不能简单根据newValue来设置，否则手指不松开左右滑动时无法更新reserveHorizontalView.frame，且必须放这里优先处理，否则往上下滑动后可能会出现空白页面)
                if contentOffset.x > wy_width {
                    reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }else {
                    reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }
                
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringContentToFront([currentHorizontalView, reserveHorizontalView])

                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)
                let previousAxisIsHorizontal = axisIsHorizontal(of: previousDirection)
                // 跨轴进入判定(方向未知时按置顶View判轴)：按优先方向判会把垂直进入误判成跨轴、钳住reserve不推进(下标不涨、轮播卡死在未加载的预备页)；程序化跨轴切换(动画窗口内)不按跨轴进入处理——显式调用nextContent/lastContent/switchContent指定非展示轴时期待目标轴下标前进并预加载，"下标保持"语义只属于轻扫直切(用户零成本换轴)
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && (previousAxisIsHorizontal == false) && (isProgrammaticAnimatedScroll == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
                    // 跨轴进入不翻页：reserve钳在current保持下标(跨轴语义=只换展示轴)
                    reserveHorizontalIndex = currentHorizontalIndex
                }else if newValue == .left {
                    reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                    if (reserveHorizontalIndex == 0) && (unlimitedCarousel == false) {
                        reserveHorizontalIndex = currentHorizontalIndex
                    }
                }else {
                    reserveHorizontalIndex = currentHorizontalIndex - 1
                    if (reserveHorizontalIndex < 0)  {
                        reserveHorizontalIndex = (unlimitedCarousel == false) ? currentHorizontalIndex : (numberOfHorizontalContent - 1)
                    }
                }
                
                // 页没变不发will(预备页没换就无需预加载)；跨轴进入时reserve刚被钳制、config比对会失效，需强制补发一次will
                let isPageIndexChanged = (reserveHorizontalIndex != currentHorizontalIndex)
                if isPageIndexChanged && ((configHorizontalReserveIndex != reserveHorizontalIndex) || isCrossAxisEntry) {
                    switchContentCallback(isDidSwitch: false)
                }
            }
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown
        }
    }
    
    /// 当前正在水平方向显示的Views(用户传入的View)
    private var horizontalViews: [UIView]? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.horizontalViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.horizontalViews) as? [UIView]
        }
    }
    
    /// 当前正在垂直方向显示的Views(用户传入的View)
    private var verticalViews: [UIView]? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.verticalViews, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.verticalViews) as? [UIView]
        }
    }
    
    /// 计时器
    private var timer: Timer? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.timer) as? Timer
        }
    }
    
    /// 判断手动拖拽后是否需要启动定时器
    private var canRestartedTimer: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer) as? Bool ?? false
        }
    }
    
    /// 是否已锁定滑动方向（只在一次拖拽中生效，避免contentSlidingDirection == .omnidirectional时滑动后无法锁定方向的问题）
    private var isDirectionLocked: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isDirectionLocked) as? Bool ?? false
        }
    }

    /// 本次拖拽中锁定的滑动方向(仅omnidirectional模式使用)：边界被 canScroll 拦截时 internalSliderDirection 不会更新，靠它保持本次拖拽的方向使拦截持续生效
    private var dragLockedDirection: WYSlidingDirection {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection) as? WYSlidingDirection ?? .unknown }
    }

    /// 是否正处于轻扫跨轴直切中(直切开始前置true、pauseScroll收尾清除；期间handleScrollDirectionLock临时放开两轴能力让直切偏移通过，否则会被轴能力钳回中心)
    private var isInstantCrossAxisEntry: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isInstantCrossAxisEntry) as? Bool ?? false }
    }

    /// 是否正处于切换收尾中(pauseScroll复位中心页会同步重入didScroll→setter，此时previousDirection已翻为目标轴不再判为跨轴，若不拦会按同轴推进逻辑把刚钳制/落定的下标再次±1)
    private var isFinalizingSwitch: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isFinalizingSwitch) as? Bool ?? false }
    }

    /// 是否正处于程序化动画滚动中(nextContent/lastContent的setContentOffset(animated:)期间)：期间两轴能力临时放开，否则判轴前两轴全钳制会抹掉动画头几帧位移、终点欠账够不到整页导致提交失败弹回原页；动画结束或用户接管时清除
    private var isProgrammaticAnimatedScroll: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.isProgrammaticAnimatedScroll, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.isProgrammaticAnimatedScroll) as? Bool ?? false }
    }
    
    /// 上一次合法的偏移量：不可滑方向被锁死时 contentOffset 回退到此值
    private var lastValidContentOffset: CGPoint {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset) as? CGPoint ?? .zero
        }
    }
    
    /// 本次拖拽是否已滑过一页宽度(松手时据此判断要不要执行 pauseScroll 切换)
    private var canSwitchedPage: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canSwitchedPage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.canSwitchedPage) as? Bool ?? false
        }
    }
    
    /// 记录上一次为 reserveHorizontalView 配置的索引，避免重复设置
    private var configHorizontalReserveIndex: Int? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.configHorizontalReserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.configHorizontalReserveIndex) as? Int }
    }
    
    /// 记录上一次为 reserveVerticalView 配置的索引，避免重复设置
    private var configVerticalReserveIndex: Int? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.configVerticalReserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.configVerticalReserveIndex) as? Int }
    }

    /// 水平轴是否已触发过"已展示"didSwitch(初始展示只回调当前展示方向，另一轴第一次被滑到时在scrollViewDidScroll立即补发一次，避免刚进页面两轴内容如双视频同时启动导致声音嘈杂)
    private var hasInitialCallbackHorizontal: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackHorizontal) as? Bool ?? false }
    }

    /// 垂直轴是否已触发过"已展示"didSwitch(初始展示只回调当前展示方向，另一轴第一次被滑到时在scrollViewDidScroll立即补发一次，避免刚进页面两轴内容如双视频同时启动导致声音嘈杂)
    private var hasInitialCallbackVertical: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackVertical, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.hasInitialCallbackVertical) as? Bool ?? false }
    }
    
    /// 外部真实代理（弱引用避免循环引用）
    private weak var internalDelegate: UIScrollViewDelegate? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.internalDelegate, WYWeakBox(newValue as AnyObject?), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.internalDelegate ) as? WYWeakBox)?.value as? UIScrollViewDelegate
        }
    }
    
    /// 当前显示在最上层的ContentView
    private var upperContentView: UIView? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.upperContentView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.upperContentView) as? UIView }
    }
    
    private struct WYAssociatedKeys {
        static var timer: UInt8 = 0
        static var horizontalViews: UInt8 = 0
        static var verticalViews: UInt8 = 0
        static var internalSliderDirection: UInt8 = 0
        static var canRestartedTimer: UInt8 = 0
        static var canSwitchedPage: UInt8 = 0
        static var configHorizontalReserveIndex: UInt8 = 0
        static var configVerticalReserveIndex: UInt8 = 0
        static var internalDelegate: UInt8 = 0
        static var isDirectionLocked: UInt8 = 0
        static var dragLockedDirection: UInt8 = 0
        static var lastValidContentOffset: UInt8 = 0
        static var upperContentView: UInt8 = 0
        static var hasInitialCallbackHorizontal: UInt8 = 0
        static var hasInitialCallbackVertical: UInt8 = 0
        static var isInstantCrossAxisEntry: UInt8 = 0
        static var isFinalizingSwitch: UInt8 = 0
        static var isProgrammaticAnimatedScroll: UInt8 = 0
    }
}

extension WYContentScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        // 回调外部
        internalDelegate?.scrollViewWillBeginDragging?(scrollView)

        // 暂停计时器(保留重启标记，松手后自动续播；不能用stopTimer——那会清除标记导致松手后轮播不再恢复)
        pauseTimer()
        // 用户接管：清除程序化动画窗口标记
        isProgrammaticAnimatedScroll = false
        // 重置方向锁定
        isDirectionLocked = false

        // 重置本次拖拽锁定的方向，避免沿用上一次拖拽的方向
        dragLockedDirection = .unknown
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // 回调外部
        internalDelegate?.scrollViewDidScroll?(scrollView)
        
        // 方向锁控制
        let slidingDirection: WYSlidingDirection = handleScrollDirectionLock()
        
        // 判断是否可以滑动
        guard canScroll(slidingDirection) == true else { return }

        if (slidingDirection == .left) || (slidingDirection == .right) {
            if hasInitialCallbackHorizontal == false {
                hasInitialCallbackHorizontal = true
                // 直切/程序化跨轴切换期间不发轴初始补发：两者链路都自带完整will→did，补发会抢在will之前乱序(先did后will再did)；标记照常消费
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }else {
            if hasInitialCallbackVertical == false {
                hasInitialCallbackVertical = true
                // 直切/程序化跨轴切换期间不发轴初始补发：两者链路都自带完整will→did，补发会抢在will之前乱序(先did后will再did)；标记照常消费
                if (isInstantCrossAxisEntry == false) && (isProgrammaticAnimatedScroll == false) {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }
        
        if (contentSlidingDirection == .omnidirectional) && (isDirectionLocked == false) && (slidingDirection == internalSliderDirection) {
            // 判轴前的陈旧方向：跳过(否则setter误staging误发willSwitch)
        }else {
            // internalSliderDirection 必须放在canScroll之后设置，否则可能会出现屏幕无法铺满的情况
            internalSliderDirection = slidingDirection
        }
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {

            // 偏移量越过一页宽度时视为已滑过半程，松手可切换
            canSwitchedPage = (abs(contentOffset.x - wy_width) >= wy_width)
            
            if let contentDelegate = contentDelegate,
               horizontalViews?.count == 2,
               let currentHorizontalView = horizontalViews?.first,
               let reserveHorizontalView = horizontalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll?(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
            }
            
        }else {
            
            canSwitchedPage = (abs(contentOffset.y - wy_height) >= wy_height)
            
            if let contentDelegate = contentDelegate,
               verticalViews?.count == 2,
               let currentVerticalView = verticalViews?.first,
               let reserveVerticalView = verticalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll?(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
            }
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // 回调外部
        internalDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        // 仅全向模式处理跨轴轻扫直切
        guard contentSlidingDirection == .omnidirectional else { return }

        // 甩动速度取自pan手势而非委托参数：零行程钳制下contentOffset全程不动，委托回传的velocity恒约为0(实测仅2~3pt/s)，只有手指真实速度才能表达切换意图；符号转换到offset语义(手指上/左滑=offset增=left/up)
        let panVelocity = panGestureRecognizer.velocity(in: self)
        let flickVelocity = CGPoint(x: -panVelocity.x, y: -panVelocity.y)

        // 候选切入方向：仅取速度分量较大的主轴(次轴回退会劫持带斜向分量的同轴翻页手势，表现为同轴滑动被误判成跨轴直切、页面弹跳无法正常切换)；方向符号与handleScrollDirectionLock的delta语义一致(offset增=left/up)
        var candidates: [WYSlidingDirection] = []
        let horizontalVelocity = abs(flickVelocity.x)
        let verticalVelocity = abs(flickVelocity.y)
        func candidate(ofAxisIsHorizontal: Bool) -> WYSlidingDirection? {
            if ofAxisIsHorizontal {
                guard horizontalVelocity > crossAxisFlickVelocityThreshold else { return nil }
                return (flickVelocity.x > 0) ? .left : .right
            }else {
                guard verticalVelocity > crossAxisFlickVelocityThreshold else { return nil }
                return (flickVelocity.y > 0) ? .up : .down
            }
        }
        if let primary = candidate(ofAxisIsHorizontal: horizontalVelocity >= verticalVelocity) {
            candidates.append(primary)
        }
        guard candidates.isEmpty == false else { return }

        // 当前展示轴(方向未知时按置顶View判)：按优先方向判会把垂直展示后的同轴垂直轻扫误判成跨轴直切
        let displayedAxisIsHorizontal = axisIsHorizontal(of: internalSliderDirection)

        // 逐候选判定：跨轴进入(目标轴存在即可，不论数量)、对应方向开关开启、且切入轴速度分量明显占优(1.5倍，斜向轻扫的同轴分量不允许误触发跨轴直切——否则同方向再次轻扫会误切轴导致内容无谓重载)才构成直切；同轴甩动不经此路径，保持原跟手翻页
        for entryDirection in candidates {
            let entryAxisIsHorizontal = (entryDirection == .left) || (entryDirection == .right)
            let entryAxisCount = entryAxisIsHorizontal ? numberOfHorizontalContent : numberOfVerticalContent
            let entryAxisEnabled = entryAxisIsHorizontal ? horizontalSliderEnabled : verticalSliderEnabled
            let entryAxisVelocity = entryAxisIsHorizontal ? horizontalVelocity : verticalVelocity
            let otherAxisVelocity = entryAxisIsHorizontal ? verticalVelocity : horizontalVelocity
            if (entryAxisCount >= 1) && (entryAxisIsHorizontal != displayedAxisIsHorizontal) && entryAxisEnabled && (entryAxisVelocity > otherAxisVelocity * 1.5) {
                // 收回惯性目标到中心页：斜向甩动的同轴分量会带动可拖的展示轴产生松手减速/翻页吸附动画，与直切竞争表现为"切换仍有动画"
                targetContentOffset.pointee = CGPoint(x: wy_width, y: wy_height)
                // 异步发起：待本次拖拽的收尾回调全部走完后再执行直切，避免与拖拽状态互相干扰
                DispatchQueue.main.async { [weak self] in
                    self?.instantCrossAxisEntry(entryDirection)
                }
                return
            }
        }
    }

    /// 轻扫跨轴直切：置直切标记后无动画跳到目标轴页(didScroll链路同步触发方向锁定、储备页摆位与willSwitch补发，随后手动pauseScroll完成换页并回调didSwitch；非动画setContentOffset只触发一次didScroll且不会回调scrollViewDidEndScrollingAnimation，收尾必须手动调用)
    private func instantCrossAxisEntry(_ direction: WYSlidingDirection) {

        guard (contentSlidingDirection == .omnidirectional), (isInstantCrossAxisEntry == false) else {
            return
        }

        // 防残留方向锁杀死直切(与nextContent/lastContent同源)：上一轮程序化切换/滑动会把锁留在旧轴上，直切跳变后判轴走"已锁定"分支只看旧轴位移(水平跳变的deltaY=0)会沿用旧方向，错判后再被"锁死另一方向"把跳变偏移钳回中心，直切静默失败——轻扫路径因前置拖动(willBeginDragging清锁)从未暴露，switchContent同下标跨轴直调本方法时才现形
        isDirectionLocked = false
        dragLockedDirection = .unknown

        isInstantCrossAxisEntry = true

        var targetOffset = CGPoint(x: wy_width, y: wy_height)
        if direction == .left {
            targetOffset.x = 2 * wy_width
        }else if direction == .right {
            targetOffset.x = 0
        }else if direction == .up {
            targetOffset.y = 2 * wy_height
        }else {
            targetOffset.y = 0
        }
        setContentOffset(targetOffset, animated: false)
        pauseScroll()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        // 回调外部
        internalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        
        if canRestartedTimer == true {
            startTimer()
        }
        
        // 手指释放，并且没有惯性
        if decelerate == false {
            pauseScroll()
        }
    }
    
    /// 手指释放且惯性减速结束
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 回调外部
        internalDelegate?.scrollViewDidEndDecelerating?(scrollView)
        pauseScroll()
    }
    
    /// 代码设置 contentOffset 动画结束
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // 回调外部
        internalDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
        pauseScroll()
    }
    
    /*************** 未实现的方法自动转发实现 ***************/
    
    /// 告诉系统：我能响应哪些方法
    public override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector)
            || (internalDelegate?.responds(to: aSelector) ?? false)
    }
    
    /// 将未实现的方法转发给外部 delegate
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if internalDelegate?.responds(to: aSelector) == true {
            return internalDelegate
            
        }
        return super.forwardingTarget(for: aSelector)
    }
    /*************** 未实现的方法自动转发实现 ***************/
}

private class WYWeakBox {
    weak var value: AnyObject?
    init(_ value: AnyObject?) {
        self.value = value
    }
}
