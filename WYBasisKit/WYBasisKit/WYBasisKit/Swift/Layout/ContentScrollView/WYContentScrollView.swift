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

/// 跨轴切换(换方向)的呈现样式
@objc public enum WYContentSwitchStyle: Int {
    /// 无动画直切(默认，与手势零行程手感一致)
    case instant = 0
    /// 翻页滑动：当前页滑出、目标页滑入(时长可用crossAxisSwitchDuration配置)
    case slide
    /// 渐变切入：目标页淡入覆盖当前页(时长可用crossAxisSwitchDuration配置)
    case fade
    /// 缩放切入：目标页从crossAxisSwitchZoomScale缩放归位并淡入、当前页同步放大淡出(时长可用crossAxisSwitchDuration配置)
    case zoom
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
    public internal(set) var currentHorizontalIndex: Int = 0
    
    /// 水平方向储备内容页索引
    public internal(set) var reserveHorizontalIndex: Int = 0
    
    /// 当前垂直方向内容页索引
    public internal(set) var currentVerticalIndex: Int = 0
    
    /// 垂直方向储备内容页索引
    public internal(set) var reserveVerticalIndex: Int = 0
    
    /// 自动轮播时每一页停留时间，默认为3s，最少1s(当设置的值小于1s时，则为默认值)；轮播进行中修改会立即生效——计时器以新间隔重建并从修改时刻起算新一轮(运行中的Timer持有的是创建时的旧间隔，不重建不会自己变)
    public var standingTime: TimeInterval = 3 {
        didSet {
            // 间隔只在startTimer创建计时器时读取，运行中修改必须重建才立即生效；用pauseTimer(保留续播标记)而非stopTimer(业务硬停语义)，重建经startTimer自身的门(自动轮播开关/展示轴无限翻页/可轮播方向)重判
            if timer != nil {
                pauseTimer()
                startTimer()
            }
        }
    }

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

    /// 跨轴切换(换方向)的呈现样式，默认.instant；同时作用于API切换(nextContent/lastContent/switchContent的跨轴)与轻扫直切；同轴切换不受影响(始终跟手+吸附/动画翻页)
    public var crossAxisSwitchStyle: WYContentSwitchStyle = .instant

    /// 跨轴切换动画时长(单位：秒，仅.slide/.fade/.zoom生效，.instant无动画不经过此值)，默认0.25s，钳制范围[0.1, 2.0](过短失去动画意义按0.1处理，过长拖沓按2.0处理)；作用于一切组件驱动的跨轴动画——API切换(nextContent/lastContent/switchContent跨轴)、轻扫直切、fade/zoom拖动松手后的补满/归零补间；唯一例外是slide拖动的松手收尾走系统动能减速(时长随释放速度自然变化，见scrollViewWillEndDragging)，不经此值
    public var crossAxisSwitchDuration: TimeInterval = 0.25 {
        didSet {
            let clampedValue = min(max(crossAxisSwitchDuration, 0.1), 2.0)
            if clampedValue != crossAxisSwitchDuration {
                // 在自身didSet内赋值不会递归，Swift语言规定，didSet内给本属性赋值时新值直接替换刚设置的值、观察器不会再次触发，这是Swift官方文档定义的行为
                crossAxisSwitchDuration = clampedValue
            }
        }
    }

    /// 缩放切入(.zoom)的缩放比例，默认1.15：进入页从该值缩放归位、退场页同步放大至该值淡出(对称缩放，值越大幅度越明显)；钳制范围[1.0, 2.0](1.0时无缩放退化为渐变，过大观感夸张)，仅.zoom生效
    public var crossAxisSwitchZoomScale: CGFloat = 1.15 {
        didSet {
            let clampedValue = min(max(crossAxisSwitchZoomScale, 1.0), 2.0)
            if clampedValue != crossAxisSwitchZoomScale {
                // 在自身didSet内赋值不会递归，Swift语言规定，didSet内给本属性赋值时新值直接替换刚设置的值、观察器不会再次触发，这是Swift官方文档定义的行为
                crossAxisSwitchZoomScale = clampedValue
            }
        }
    }
    
    /// 水平方向是否支持滑动(仅内容页数量大于1时生效，单页/无内容时该方向不可滑)，默认true。语义边界：①纯手势开关——只拦用户手指：本轴同轴拖动零行程不可翻页；跨轴进入(轻扫直切与跨轴API切换)不看目标轴本开关；②轮播不受本开关约束(由automaticCarousel与展示轴的horizontal/verticalUnlimitedCarousel管理，锁手势+自动轮播的Banner场景可用)；③API切换(nextContent/lastContent/switchContent含同轴)是显式指令不受本开关约束；④两轴开关同时关闭时手势完全静默(isScrollEnabled为false，纯展示模式)，切换只能走API
    public var horizontalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }

    /// 垂直方向是否支持滑动(仅内容页数量大于1时生效，单页/无内容时该方向不可滑)，默认true。语义边界：①纯手势开关——只拦用户手指：本轴同轴拖动零行程不可翻页；跨轴进入(轻扫直切与跨轴API切换)不看目标轴本开关；②轮播不受本开关约束(由automaticCarousel与展示轴的horizontal/verticalUnlimitedCarousel管理，锁手势+自动轮播的Banner场景可用)；③API切换(nextContent/lastContent/switchContent含同轴)是显式指令不受本开关约束；④两轴开关同时关闭时手势完全静默(isScrollEnabled为false，纯展示模式)，切换只能走API
    public var verticalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 水平方向是否无限翻页(仅内容页数量大于1时生效)，默认true。管两件事：①本轴环绕语义——手势与API翻到末页/首页时是否环绕到另一端(关闭则本轴有边界，末页再往前翻不动)；②轮播前提——轮播只翻展示轴，展示轴的本开关关闭时轮播自动停(动态启停)，切回环绕轴自动续播；不影响"能到达"与滑动开关(那是horizontalSliderEnabled的职责)
    public var horizontalUnlimitedCarousel: Bool = true {
        didSet { checkCarouselStatus() }
    }

    /// 垂直方向是否无限翻页(仅内容页数量大于1时生效)，默认true。管两件事：①本轴环绕语义——手势与API翻到末页/首页时是否环绕到另一端(关闭则本轴有边界，末页再往前翻不动)；②轮播前提——轮播只翻展示轴，展示轴的本开关关闭时轮播自动停(动态启停)，切回环绕轴自动续播；不影响"能到达"与滑动开关(那是verticalSliderEnabled的职责)
    public var verticalUnlimitedCarousel: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 是否需要自动轮播/轮播
    /// 是否需要自动轮播，默认false(不自动轮播，业务想要自动轮播显式开启；开启后组件会在首次展示时自动开表)；运行中修改会动态启停——关闭立即停表(清计时器)，重新开启且此前表达过开表意图(startTimer成功或尝试过)时自动续播
    public var automaticCarousel: Bool = false {
        didSet { checkCarouselStatus() }
    }
    
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
            // 优先方向变化可能翻转全向模式的置顶轴(展示轴换了人)：轮播轴与滚动能力都随之变化，必须重评(漏掉表现为换优先方向后轮播停摆或不该轮播的轴空转)
            checkCarouselStatus()
        }
    }


    /// 开启定时器(默认开启，调用该方法会重新开启)
    public func startTimer() {

        // 表达开表意图在门禁判定之前：门禁(自动轮播开关/数量/展示轴无限翻页)可能此刻不满足而返回，但意图已记下——后续任一条件经didSet重评时refreshCarouselTimer会自动开表(否则"先开计时器再开自动轮播"顺序下意图丢失，计时器永远起不来)
        canRestartedTimer = true
        // 业务显式开表：解除硬停记录，后续重挂载的自动开表恢复生效
        timerStoppedByBusiness = false

        // 如果已经开启了，就先关闭计时器
        if timer != nil {
            // 停止计时器
            stopTimer()
        }

        // 未开启轮播则跳过
        guard (automaticCarousel != false) else {
            return
        }

        // 创建时仅判一次能否开启轮播(单轴数量不足2/全向无置顶View则不开)；轮播翻的是展示轴，无限翻页前提按展示轴的本开关判定；运行期轮播方向由timer闭包每次触发实时推导，跨轴直切换展示轴后跟随新轴
        guard let carouselDirection = carouselDirection else {
            return
        }
        if ((carouselDirection == .topOrBottom) ? verticalUnlimitedCarousel : horizontalUnlimitedCarousel) == false {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            guard let self = self else { return }
            // 每次触发时重新推导轮播方向：跨轴直切后跟随新的展示轴；推导失败(重挂载等过渡态)跳过本次触发
            guard let direction = self.carouselDirection else { return }
            self.nextContent(direction)
        })
        RunLoop.current.add(timer!, forMode: .common)
    }

    /// 停止定时器(业务语义的停止：清除重启标记，此后松手/条件恢复都不会自动重启，直到业务再次startTimer；拖动暂停等需保留续播的场景请用pauseTimer)
    public func stopTimer() {
        pauseTimer()
        canRestartedTimer = false
        // 记录业务硬停：首次展示的自动开表(见internalSettingsContentView)遇到它必须让位，否则关表后一切换方向重挂载轮播就复活
        timerStoppedByBusiness = true
    }
    
    /// 切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)
    public func nextContent(_ direction: WYContentSlidingDirection) {
        // 快速连点时先瞬时完成上一段仍在飞行的程序化切换(否则新动画会打断旧的：结束回调丢失、偏移冻结在中途无人提交)
        completeOngoingProgrammaticSwitch()

        // 目标轴≠当前展示轴(跨轴)时不受该轴滑动开关与"数量>1"限制——开关管轴内翻页交互不限制到达，跨轴进入目标轴有内容即可；同轴只查数量——滑动开关是纯手势开关(只拦手指拖动/轻扫)，API与轮播(计时器经此进入)都是组件/业务显式驱动不受手势开关约束，否则单关/双关下同轴API被拦死(双关语义"切换只能走API"失去逃生门)、锁手势自动轮播的Banner场景无法实现
        let targetIsHorizontal = (direction == .leftOrRight)
        let isCrossTarget = (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) != targetIsHorizontal)
        switch direction {
        case .leftOrRight:
            if isCrossTarget {
                guard numberOfHorizontalContent > 0 else { return }
            }else if numberOfHorizontalContent <= 1 { return }
        case .topOrBottom:
            if isCrossTarget {
                guard numberOfVerticalContent > 0 else { return }
            }else if numberOfVerticalContent <= 1 { return }
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
                guard horizontalUnlimitedCarousel else { return }
            }

            // 跨轴程序化切换：目标轴非当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页语义推进
            if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                performCrossAxisSwitch(direction: .left, preservesIndex: false)
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
                guard verticalUnlimitedCarousel else { return }
            }

            // 跨轴程序化切换：目标轴非当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页语义推进
            if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                performCrossAxisSwitch(direction: .up, preservesIndex: false)
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
        // 快速连点时先瞬时完成上一段仍在飞行的程序化切换(否则新动画会打断旧的：结束回调丢失、偏移冻结在中途无人提交)
        completeOngoingProgrammaticSwitch()

        // 同轴只查数量、跨轴只查存在——滑动开关是纯手势开关(只拦手指拖动/轻扫)，API与轮播都是组件/业务显式驱动不受手势开关约束(与nextContent同源)
        let targetIsHorizontal = (direction == .leftOrRight)
        let isCrossTarget = (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) != targetIsHorizontal)
        switch direction {
        case .leftOrRight:
            if isCrossTarget {
                guard numberOfHorizontalContent > 0 else { return }
            }else if numberOfHorizontalContent <= 1 { return }
        case .topOrBottom:
            if isCrossTarget {
                guard numberOfVerticalContent > 0 else { return }
            }else if numberOfVerticalContent <= 1 { return }
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
                guard horizontalUnlimitedCarousel else { return }
            }

            // 跨轴程序化切换：目标轴非当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页语义回退
            if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                performCrossAxisSwitch(direction: .right, preservesIndex: false)
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
                guard verticalUnlimitedCarousel else { return }
            }

            // 跨轴程序化切换：目标轴非当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页语义回退
            if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                performCrossAxisSwitch(direction: .down, preservesIndex: false)
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
        // 快速连点时先瞬时完成上一段仍在飞行的程序化切换——必须在本方法的下标预设之前(预设基于当前current下标，在飞切换的提交会改变它)
        completeOngoingProgrammaticSwitch()

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
                // 同下标但展示轴在另一侧：目标页就是水平轴当前下标，只需翻转展示轴(下标不变、只发didSwitch、样式随crossAxisSwitchStyle)；同轴相等时保持原有no-op
                performCrossAxisSwitch(direction: .left, preservesIndex: true)
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
                // 同下标但展示轴在另一侧：目标页就是垂直轴当前下标，只需翻转展示轴(下标不变、只发didSwitch、样式随crossAxisSwitchStyle)；同轴相等时保持原有no-op
                performCrossAxisSwitch(direction: .up, preservesIndex: true)
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
