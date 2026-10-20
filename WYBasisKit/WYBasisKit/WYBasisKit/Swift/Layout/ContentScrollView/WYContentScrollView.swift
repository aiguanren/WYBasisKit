//
//  WYContentScrollView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/4/13.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

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
    /// 无动画直接切换(默认，与轻扫跨轴的瞬间直切手感一致)
    case instant = 0
    /// 翻页滑动，当前页滑出、目标页滑入(时长可用crossAxisSwitchDuration配置)
    case slide
    /// 渐变切入，目标页淡入覆盖当前页(时长可用crossAxisSwitchDuration配置)
    case fade
    /// 缩放切入，目标页从crossAxisSwitchZoomScale缩放归位并淡入、当前页同步放大淡出(时长可用crossAxisSwitchDuration配置)
    case zoom
}

@objc public protocol WYContentScrollViewDelegate {
    
    /**
     *  监听ContentScrollView的偏移量变化事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *  @param offset             当前的偏移量
     *  @param direction          当前的滑动方向
     *  @param currentView        当前正在显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param reserveView        当前预备显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param index              当前页的下标
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
     *  @param index              当前点击页的下标
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

public class WYContentScrollView: UIScrollView {
    
    /// 滑动事件代理
    public weak var contentDelegate: WYContentScrollViewDelegate?
    
    /// 水平方向内容页视图数量（Int.max表示无限数量）
    public var numberOfHorizontalContent: Int = Int.max {
        didSet {
            
            // 数量收缩时钳制残留旧下标(下标超出数量后方向setter会按旧下标±1算出错误的预备下标、误发willSwitch)
            if currentHorizontalIndex > numberOfHorizontalContent - 1 {
                currentHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            if reserveHorizontalIndex > numberOfHorizontalContent - 1 {
                reserveHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            
            // 数量变化正常不会切走用户正看的轴(见bringContentToFront)，但挂载、恢复等过渡场景下置顶View仍可能变化，这种变化只调整叠放顺序、不走正常翻页流程、不产生回调，检测到置顶View变化时补发一次didSwitch通知调用方
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
            // 展示轴翻转后隐藏没内容的那个轴，防止不满铺的内容透出来
            syncAxisViewsVisibility()
            // 数量变化后同步刷新isScrollEnabled等滚动状态
            checkCarouselStatus()
        }
    }
    
    /// 垂直方向内容页视图数量（Int.max表示无限数量）
    public var numberOfVerticalContent: Int = Int.max {
        didSet {
            // 数量收缩时钳制残留旧下标(下标超出数量后方向setter会按旧下标±1算出错误的预备下标、误发willSwitch)
            if currentVerticalIndex > numberOfVerticalContent - 1 {
                currentVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            if reserveVerticalIndex > numberOfVerticalContent - 1 {
                reserveVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            
            // 数量变化正常不会切走用户正看的轴(见bringContentToFront)，但挂载、恢复等过渡场景下置顶View仍可能变化，这种变化只调整叠放顺序、不走正常翻页流程、不产生回调，检测到置顶View变化时补发一次didSwitch通知调用方
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
            // 展示轴翻转后隐藏没内容的那个轴，防止不满铺的内容透出来
            syncAxisViewsVisibility()
            // 数量变化后同步刷新isScrollEnabled等滚动状态
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

    /// 当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)
    public var prioritySlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet {
            bringContentToFront()
            // 优先方向变化可能翻转全向模式的置顶轴，轮播方向与滚动可用状态随之改变，需要重新计算
            checkCarouselStatus()
        }
    }

    /// 当前正在展示的滑动方向(返回值只会有.leftOrRight/.topOrBottom两种类型)
    public var displayingSlidingDirection: WYContentSlidingDirection {
        // 全向模式按置顶View所在轴推导(与组件内部展示轴判定同源，挂载前置顶View未定时按优先方向兜底)，单轴模式只挂载一轴，展示方向就是模式本身
        guard contentSlidingDirection == .omnidirectional else {
            return contentSlidingDirection
        }
        return axisIsHorizontal(of: .unknown) ? .leftOrRight : .topOrBottom
    }

    /// 当前正在水平方向显示的Views(用户传入的View)
    public internal(set) var horizontalViews: [UIView]?
    
    /// 当前正在垂直方向显示的Views(用户传入的View)
    public internal(set) var verticalViews: [UIView]?
    
    /// 当前水平方向内容页索引
    public internal(set) var currentHorizontalIndex: Int = 0
    
    /// 水平方向储备内容页索引
    public internal(set) var reserveHorizontalIndex: Int = 0
    
    /// 当前垂直方向内容页索引
    public internal(set) var currentVerticalIndex: Int = 0
    
    /// 垂直方向储备内容页索引
    public internal(set) var reserveVerticalIndex: Int = 0
    
    /// 自动轮播时每一页停留时间，默认3s(设置的值小于1s时按3s处理，修改后立即生效)
    public var standingTime: TimeInterval = 3 {
        didSet {
            // 间隔只在startTimer创建计时器时读取，运行中修改必须重建才立即生效
            if timer != nil {
                pauseTimer()
                startTimer()
            }
        }
    }
    
    /// 轻扫跨轴直切的速度阈值(单位为pt/s，默认500，范围限制50 - 3000，仅影响全向模式的轻扫跨轴判定，同轴翻页不经过此阈值，值越低越灵敏，越高越保守)
    public var crossAxisFlickVelocityThreshold: CGFloat = 500 {
        didSet {
            let clampedValue = min(max(crossAxisFlickVelocityThreshold, 50), 3000)
            if clampedValue != crossAxisFlickVelocityThreshold {
                // 在自身didSet里回写钳制值不会再触发观察器(Swift规定的特殊行为，不会递归)
                crossAxisFlickVelocityThreshold = clampedValue
            }
        }
    }
    
    /// 跨轴切换(换方向)的呈现样式，默认.instant，作用于跨轴API切换与轻扫直切，同轴切换不受影响
    public var crossAxisSwitchStyle: WYContentSwitchStyle = .instant
    
    /// 跨轴切换动画时长(单位为秒)，默认0.25s，钳制范围[0.1, 2.0]，仅.slide/.fade/.zoom生效
    public var crossAxisSwitchDuration: TimeInterval = 0.25 {
        didSet {
            let clampedValue = min(max(crossAxisSwitchDuration, 0.1), 2.0)
            if clampedValue != crossAxisSwitchDuration {
                // 在自身didSet里回写钳制值不会再触发观察器(Swift规定的特殊行为，不会递归)
                crossAxisSwitchDuration = clampedValue
            }
        }
    }
    
    /// 缩放切入(.zoom)的缩放比例，默认1.15，钳制范围[1.0, 2.0]，仅.zoom生效
    public var crossAxisSwitchZoomScale: CGFloat = 1.15 {
        didSet {
            let clampedValue = min(max(crossAxisSwitchZoomScale, 1.0), 2.0)
            if clampedValue != crossAxisSwitchZoomScale {
                // 在自身didSet里回写钳制值不会再触发观察器(Swift规定的特殊行为，不会递归)
                crossAxisSwitchZoomScale = clampedValue
            }
        }
    }
    
    /// 水平方向是否支持滑动(仅内容页数量大于1时生效，仅拦截手势不影响API切换与轮播，默认true)
    public var horizontalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 垂直方向是否支持滑动(仅内容页数量大于1时生效，仅拦截手势不影响API切换与轮播，默认true)
    public var verticalSliderEnabled: Bool = true {
        didSet { checkCarouselStatus() }
    }

    /// 水平方向同轴翻页的最小时间间隔(单位为秒，默认0不限制，负数按0处理)，手势翻页落定后间隔内的新同轴拖动无效，跨轴切换与API切换不受影响
    public var horizontalMinimumSwitchInterval: TimeInterval = 0 {
        didSet {
            if horizontalMinimumSwitchInterval < 0 {
                // 在自身didSet里回写不会再触发观察器(Swift规定的特殊行为，不会递归)
                horizontalMinimumSwitchInterval = 0
            }
        }
    }

    /// 垂直方向同轴翻页的最小时间间隔(单位为秒，默认0不限制，负数按0处理)，手势翻页落定后间隔内的新同轴拖动无效，跨轴切换与API切换不受影响
    public var verticalMinimumSwitchInterval: TimeInterval = 0 {
        didSet {
            if verticalMinimumSwitchInterval < 0 {
                // 在自身didSet里回写不会再触发观察器(Swift规定的特殊行为，不会递归)
                verticalMinimumSwitchInterval = 0
            }
        }
    }
    
    /// 水平方向是否无限翻页(末页/首页环绕到另一端，默认true，展示轴关闭本开关时轮播随之停止)
    public var horizontalUnlimitedCarousel: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 垂直方向是否无限翻页(末页/首页环绕到另一端，默认true，展示轴关闭本开关时轮播随之停止)
    public var verticalUnlimitedCarousel: Bool = true {
        didSet { checkCarouselStatus() }
    }
    
    /// 是否需要自动轮播(默认false，开启后首次展示时自动开始，运行中修改即时生效)
    public var automaticCarousel: Bool = false {
        didSet { checkCarouselStatus() }
    }
    
    public override weak var delegate: (any UIScrollViewDelegate)? {
        get {
            return internalDelegate
        }
        set {
            // 防止异常设置（避免死循环）
            guard newValue !== self else { return }
            
            // 系统在释放对象时可能传nil进来，此时若外部代理和super.delegate也都是nil，就跳过赋值，防止对象释放过程中重新建立weak引用导致闪退
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
    /**
     *  设置需要显示的自定义View(contentSlidingDirection != omnidirectional 时调用)，两个View的Size都将等于当前WYContentScrollView的Size
     *  @param currentView  正在显示的View
     *  @param reserveView  预备显示的View
     */
    public func horizontalOrVerticalDisplay(currentView: UIView,
                                            reserveView: UIView) {
        
        guard contentSlidingDirection != .omnidirectional else {
            return
        }
        
        // 重挂同一组View时保留组件内部当前/预备顺序，调用方自行保管的数组不随翻页交换(顺序滞后)，按其顺序重挂会把持有旧内容的View置顶
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
    
    /**
     *  设置需要显示的自定义View(contentSlidingDirection == omnidirectional 时调用)，四个View的Size都将等于当前WYContentScrollView的Size
     *  @param currentHorizontalView   水平方向正在显示的View
     *  @param reserveHorizontalView   水平方向预备显示的View
     *  @param currentVerticalView     垂直方向正在显示的View
     *  @param reserveVerticalView     垂直方向预备显示的View
     */
    public func omnidirectionalDisplay(currentHorizontalView: UIView,
                                       reserveHorizontalView: UIView,
                                       currentVerticalView: UIView,
                                       reserveVerticalView: UIView) {
        
        if contentSlidingDirection == .omnidirectional {
            
            // 重挂同一组View时保留组件内部当前/预备顺序(两轴各自判定)，按调用方滞后的顺序重挂会把旧内容View置顶
            let displayHorizontalViews: [UIView] = resolveDisplayOrder([currentHorizontalView, reserveHorizontalView], existingViews: horizontalViews)
            let displayVerticalViews: [UIView] = resolveDisplayOrder([currentVerticalView, reserveVerticalView], existingViews: verticalViews)
            
            contentViewInitializationCheck([currentHorizontalView, reserveHorizontalView, currentVerticalView, reserveVerticalView])
            
            horizontalViews = displayHorizontalViews
            verticalViews = displayVerticalViews
            
            internalSettingsContentView(isReload: true)
        }
    }
    
    /**
     *  刷新当前WYContentScrollView展示的内容View(适合cell/header/footer等重用场景或刷新场景)
     *  @return true表示已按当前持有的View完成刷新，false表示当前条件不满足没有执行(还没挂载过内容View，需先调用display方法传入View完成首次挂载)
     */
    @discardableResult
    public func reload() -> Bool {
        
        // 按当前模式检查应挂载的轴是否就绪(全向模式要两轴就绪、单轴模式只要本轴就绪)，未挂载过则无从重挂，返回false交由外部走首次挂载
        var hasMountedViews: Bool = false
        switch contentSlidingDirection {
        case .leftOrRight:
            hasMountedViews = (horizontalViews?.count == 2)
        case .topOrBottom:
            hasMountedViews = (verticalViews?.count == 2)
        case .omnidirectional:
            hasMountedViews = (horizontalViews?.count == 2) && (verticalViews?.count == 2)
        }
        guard hasMountedViews else {
            return false
        }
        
        // 重挂前先把还在播的代码切页动画瞬间落到终点(否则动画的落定处理发生在重挂之后，按旧状态换页会把刚挂好的页面又换掉)
        completeOngoingProgrammaticSwitch()
        
        // 重挂前记下展示轴与该轴已发过初始回调的标记，重挂直接把原展示轴布局到置顶(不先落回优先轴再二次切换，避免页面闪一下另一轴)
        let displayedAxisWasHorizontal = axisIsHorizontal(of: .unknown)
        let displayedAxisHadCallback = displayedAxisWasHorizontal ? hasInitialCallbackHorizontal : hasInitialCallbackVertical
        
        // 只摘View不丢数组引用，走完整重挂流程(前置轴传原展示轴，两轴下标不受挂载影响)
        horizontalViews?.forEach { $0.removeFromSuperview() }
        verticalViews?.forEach { $0.removeFromSuperview() }
        
        internalSettingsContentView(isReload: true, frontAxisIsHorizontal: displayedAxisWasHorizontal)
        
        // 挂载流程的初始didSwitch有"已回调过就跳过"的去重，展示轴之前回调过时这里补发一条，保证调用方每次刷新都收到通知
        if displayedAxisHadCallback {
            switchContentCallback(isDidSwitch: true, direction: displayedAxisWasHorizontal ? .left : .up)
        }
        
        return true
    }
    
    /// 开启自动轮播计时器(调用该方法会重新开启)
    public func startTimer() {
        
        // 先记录调用方的开轮播意图再做条件检查(条件不满足时此处直接返回，意图已记录，任一条件变化时会自动开启计时器)
        canRestartedTimer = true
        // 调用方主动开计时器，清除主动停止的记录，重新挂载View时自动开计时器的逻辑恢复生效
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
        
        // 创建时仅判一次能否开启轮播(单轴数量不足2/全向无置顶View则不开)，轮播翻的是展示轴，无限翻页前提按展示轴的本开关判定，运行期轮播方向由timer闭包每次触发实时推导，跨轴直切换展示轴后跟随新轴
        guard let carouselDirection = carouselDirection else {
            return
        }
        if ((carouselDirection == .topOrBottom) ? verticalUnlimitedCarousel : horizontalUnlimitedCarousel) == false {
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            guard let self = self else { return }
            // 每次触发时重新推导轮播方向，跨轴直切后跟随新的展示轴，推导失败(重挂载等过渡态)跳过本次触发
            guard let direction = self.carouselDirection else { return }
            self.nextContent(direction)
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    /// 停止自动轮播计时器
    public func stopTimer() {
        pauseTimer()
        canRestartedTimer = false
        // 记录调用方主动停止过计时器，首次展示时的自动开轮播(见internalSettingsContentView)检测到该标记就不再自动开，避免切换方向重新挂载View后轮播自行恢复
        timerStoppedByBusiness = true
    }
    
    /// 切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)
    public func nextContent(_ direction: WYContentSlidingDirection) {
        // 快速连点时先把上一段还在播的代码切页动画瞬间落到终点(否则新动画会打断旧的，结束回调丢失、偏移停在半路无人落定，页面卡在两页之间)
        completeOngoingProgrammaticSwitch()
        
        // 跨轴时只要求目标轴有内容(不看滑动开关与"数量>1")，同轴翻页只检查数量，滑动开关仅拦截手势、不限制API切换与轮播
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
        // 标记正处于代码切页的动画中，动画期间两轴都放行，防止还没判出方向时位移全被钳回中心、前几帧位移丢失，最后停的位置不够一整页
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
            
            // 代码切到另一轴，目标轴不是当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页规则+1推进
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
            
            // 代码切到另一轴，目标轴不是当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页规则+1推进
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
        // 快速连点时先把上一段还在播的代码切页动画瞬间落到终点(否则新动画会打断旧的，结束回调丢失、偏移停在半路无人落定，页面卡在两页之间)
        completeOngoingProgrammaticSwitch()
        
        // 同轴只查数量、跨轴只查是否存在，滑动开关仅拦截手势，API调用与轮播不受其约束
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
        // 标记正处于代码切页的动画中，动画期间两轴都放行，防止还没判出方向时位移全被钳回中心、前几帧位移丢失，最后停的位置不够一整页
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
            
            // 代码切到另一轴，目标轴不是当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页规则-1回退
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
            
            // 只有在第一页时才要求无限轮播开启(用于循环回到最后一页)，非第一页无论是否无限轮播都允许切上一页
            if currentVerticalIndex <= 0 {
                guard verticalUnlimitedCarousel else { return }
            }
            
            // 代码切到另一轴，目标轴不是当前展示轴时按crossAxisSwitchStyle呈现(默认瞬时直切，可选滑动/渐变/缩放)，下标按翻页规则-1回退
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
    
    /**
     *  切换到指定方向指定下标处(下标超出数量范围时自动钳制到最近的有效页)
     *  @param direction  要切换的方向(不支持传omnidirectional)
     *  @param index      目标下标(inout参数，越界钳制后的实际落地值会写回给调用方)
     */
    public func switchContent(_ direction: WYContentSlidingDirection, index: inout Int) {
        // 快速连点时先把上一次未播完的切换动画直接落到终点(不先落地时，上一段动画的落定处理会改变当前下标，这里基于旧下标做的预设就会出错)
        completeOngoingProgrammaticSwitch()
        
        switch direction {
        case .leftOrRight:
            
            if index < 0 { index = 0 }
            if index > (numberOfHorizontalContent - 1) { index = (numberOfHorizontalContent - 1) }
            
            guard (contentSlidingDirection != .topOrBottom) || (index != currentHorizontalIndex) else {
                return
            }
            
            // 先把当前下标预设到目标旁边一格再借翻页到达目标(向后跳先设目标+1再切上一页，向前跳先设目标-1再切下一页)，预设值不落在目标本身，避开"目标页即当前页"的判断与无限轮播的边界拦截
            if index < currentHorizontalIndex {
                currentHorizontalIndex = (index + 1)
                lastContent(direction)
            }else if index > currentHorizontalIndex {
                currentHorizontalIndex = (index - 1)
                nextContent(direction)
            }else if (contentSlidingDirection == .omnidirectional) && (axisIsHorizontal(of: .unknown) == false) {
                // 同下标但展示轴在另一侧，只需翻转展示轴(下标不变、只发didSwitch、样式随crossAxisSwitchStyle)，同轴相等时保持原有no-op
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
            
            // 向后跳先预设目标+1再lastContent，向前跳先预设目标-1再nextContent，预设值不落在目标本身，避开"目标页即当前页"的判断与边界拦截
            if index < currentVerticalIndex {
                currentVerticalIndex = (index + 1)
                lastContent(direction)
            }else if index > currentVerticalIndex {
                currentVerticalIndex = (index - 1)
                nextContent(direction)
            }else if (contentSlidingDirection == .omnidirectional) && axisIsHorizontal(of: .unknown) {
                // 同下标但展示轴在另一侧，只需翻转展示轴(下标不变、只发didSwitch、样式随crossAxisSwitchStyle)，同轴相等时保持原有no-op
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
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 检查(设置)contentSize与contentOffset
        checkContentSizeAndContentOffset()
        // 如果frame发生变化需要及时更新内容视图的frame
        internalSettingsContentView(isReload: false)
    }
    
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
    }
    
    /// 告诉系统我能响应哪些方法
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
    }
