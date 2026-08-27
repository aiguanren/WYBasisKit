//
//  WYContentScrollView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/4/13.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

public protocol WYContentScrollViewDelegate: AnyObject {

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
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)

    /**
     *  监听ContentScrollView的点击事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *  @param direction          当前的滑动方向
     *  @param currentView        当前正在显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param reserveView        当前预备显示的View(左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *  @param index              当前点击的Index
     */
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)

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
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?)

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
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?)
}

/// 支持的滑动方向
public enum WYContentSlidingDirection: Int {
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
            
            if currentHorizontalIndex > numberOfHorizontalContent - 1 {
                currentHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            if reserveHorizontalIndex > numberOfHorizontalContent - 1 {
                reserveHorizontalIndex = max(0, numberOfHorizontalContent - 1)
            }
            
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
            if currentVerticalIndex > numberOfVerticalContent - 1 {
                currentVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            if reserveVerticalIndex > numberOfVerticalContent - 1 {
                reserveVerticalIndex = max(0, numberOfVerticalContent - 1)
            }
            
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

    /// 轻扫跨轴直切的速度阈值(单位：pt/s，默认500；仅影响全向模式的轻扫跨轴判定，同轴翻页不经过此阈值，值越低越灵敏，越高越保守
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
    public var unlimitedCarousel: Bool = true
    
    /// 是否需要自动轮播/轮播
    public var automaticCarousel: Bool = true
    
    /// 设置需要显示的自定义View(contentSlidingDirection != omnidirectional 时调用)，currentView 为正在显示的View、reserveView 为预备显示的View，两者Size都将等于当前WYContentScrollView的Size
    public func horizontalOrVerticalDisplay(currentView: UIView,
                                            reserveView: UIView) {
        
        guard contentSlidingDirection != .omnidirectional else {
            return
        }
        
        contentViewInitializationCheck([currentView, reserveView], direction: contentSlidingDirection)
        
        if contentSlidingDirection == .leftOrRight {
            horizontalViews = [currentView, reserveView]
        }
        
        if contentSlidingDirection == .topOrBottom {
            verticalViews = [currentView, reserveView]
        }
        
        internalSettingsContentView(isReload: true)
    }
    
    /// 设置需要显示的自定义View(contentSlidingDirection == omnidirectional 时调用)，水平/垂直方向各需 current(正在显示)与 reserve(预备显示)两个View，Size都将等于当前WYContentScrollView的Size
    public func omnidirectionalDisplay(currentHorizontalView: UIView,
                                       reserveHorizontalView: UIView,
                                       currentVerticalView: UIView,
                                       reserveVerticalView: UIView) {
        
        if contentSlidingDirection == .omnidirectional {
            
            contentViewInitializationCheck([currentHorizontalView, reserveHorizontalView, currentVerticalView, reserveVerticalView], direction: contentSlidingDirection)
            
            horizontalViews = [currentHorizontalView, reserveHorizontalView]
            verticalViews = [currentVerticalView, reserveVerticalView]
            
            internalSettingsContentView(isReload: true)
        }
    }
    
    /// 当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)
    public var prioritySlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet {
            bringContentToFront()
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
        
        var direction: WYContentSlidingDirection = .leftOrRight
        switch contentSlidingDirection {
        case .leftOrRight:
            // 判断水平方向是否可以开启定时器
            if numberOfHorizontalContent < 2 {
                return
            }
            direction = .leftOrRight
            break
        case .topOrBottom:
            // 判断垂直方向是否可以开启定时器
            if numberOfVerticalContent < 2 {
                return
            }
            direction = .topOrBottom
            break
        case .omnidirectional:
            // 全向滑动时，根据当前显示的第一个ContentView支持的滑动方向来处理
            guard let currentContentView = upperContentView else { return }
            if (currentContentView == horizontalViews?.first) {
                direction = .leftOrRight
            }else {
                direction = .topOrBottom
            }
            break
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            guard let self = self else { return }
            nextContent(direction)
        })
        RunLoop.current.add(timer!, forMode: .common)
        
        canRestartedTimer = true
    }
    
    /// 停止定时器
    public func stopTimer() {
        timer?.invalidate()
        timer = nil
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

        switch direction {
        case .leftOrRight:
            guard contentSlidingDirection != .topOrBottom else {
                return
            }
            // 只有在最后一页时才要求无限轮播开启(用于循环回到第一页)，非最后一页无论是否无限轮播都允许切下一页
            if currentHorizontalIndex == (numberOfHorizontalContent - 1) {
                guard unlimitedCarousel else { return }
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

        switch direction {
        case .leftOrRight:
            guard contentSlidingDirection != .topOrBottom else {
                return
            }

            // 只有在第一页时才要求无限轮播开启(用于循环回到最后一页)，非第一页无论是否无限轮播都允许切上一页
            if currentHorizontalIndex <= 0 {
                guard unlimitedCarousel else { return }
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
    private func contentViewInitializationCheck(_ contentViews: [UIView], direction: WYContentSlidingDirection) {

        contentViews.forEach { $0.removeFromSuperview() }

        // 统一清理水平与垂直两个方向的 view，避免残留 view 遮挡新方向内容
        horizontalViews?.forEach { $0.removeFromSuperview() }
        horizontalViews = nil
        verticalViews?.forEach { $0.removeFromSuperview() }
        verticalViews = nil
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
        // 初始化时同步contentOffset
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
        
        // 横向是否允许滑动(非全向：单页/无内容不可滑)
        var horizontalCanScroll = (numberOfHorizontalContent > 1) ? horizontalSliderEnabled : false

        // 纵向是否允许滑动(非全向：单页/无内容不可滑)
        var verticalCanScroll = (numberOfVerticalContent > 1) ? verticalSliderEnabled : false

        if contentSlidingDirection == .omnidirectional {
            
            let displayedAxisIsHorizontal = ((internalSliderDirection == .left) || (internalSliderDirection == .right)) ? true : (((internalSliderDirection == .up) || (internalSliderDirection == .down)) ? false : (prioritySlidingDirection != .topOrBottom))
            horizontalCanScroll = false
            verticalCanScroll = false
            if isDirectionLocked {
                let lockedAxisIsHorizontal = (dragLockedDirection == .left) || (dragLockedDirection == .right)
                horizontalCanScroll = lockedAxisIsHorizontal && displayedAxisIsHorizontal && (numberOfHorizontalContent > 1) && horizontalSliderEnabled
                verticalCanScroll = (lockedAxisIsHorizontal == false) && (displayedAxisIsHorizontal == false) && (numberOfVerticalContent > 1) && verticalSliderEnabled
            }
        }

        if isInstantCrossAxisEntry {
            // 轻扫直切期间：两轴能力临时放开(单轴约束由下方方向锁定逻辑保证)，避免直切偏移被钳回中心
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
        
        let offsetX = contentOffset.x
        let offsetY = contentOffset.y

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
        
        print("\(isDidSwitch ? "isDidSwitch" : "isWillSwitch"), direction：\(callbackDirection)")
        
        if isDidSwitch {
            contentDelegate.wy_contentScrollViewDidSwitch(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
        }else {
            contentDelegate.wy_contentScrollViewWillSwitch(self, direction: callbackDirection, currentHorizontalView: horizontalViews?.first, reserveHorizontalView: horizontalViews?.last, currentVerticalView: verticalViews?.first, reserveVerticalView: verticalViews?.last)
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
        
        let wasInstantCrossAxisEntry = isInstantCrossAxisEntry
        
        if isInstantCrossAxisEntry {
            isInstantCrossAxisEntry = false
            lastValidContentOffset = CGPoint(x: wy_width, y: wy_height)
            if (canSwitchedPage == false) || (internalSliderDirection == .unknown) {
                contentOffset = CGPoint(x: wy_width, y: wy_height)
                return
            }
        }
        
        guard (canSwitchedPage == true), (internalSliderDirection != .unknown) else {
            if (canSwitchedPage == false) && (internalSliderDirection != .unknown) && (isInstantCrossAxisEntry == false) {
                let centerOffset = CGPoint(x: (contentSlidingDirection == .topOrBottom) ? 0 : wy_width, y: (contentSlidingDirection == .leftOrRight) ? 0 : wy_height)
                if (contentOffset.x != centerOffset.x) || (contentOffset.y != centerOffset.y) {
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
            
            // 交换horizontalViews数组中两个View的位置
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
            
            // 交换verticalViews数组中两个View的位置
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
                    bringContentToFront([currentHorizontalView, reserveHorizontalView])
                    configHorizontalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    break
                }

                currentHorizontalIndex = reserveHorizontalIndex

                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换horizontalViews数组中两个View的位置
                horizontalViews?.swapAt(0, 1)

                bringContentToFront([reserveHorizontalView, currentHorizontalView])

                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)

            }else {

                if wasInstantCrossAxisEntry {
                    bringContentToFront([currentVerticalView, reserveVerticalView])
                    configVerticalReserveIndex = nil
                    switchContentCallback(isDidSwitch: true)
                    break
                }

                currentVerticalIndex = reserveVerticalIndex

                reserveVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)

                // 交换verticalViews数组中两个View的位置
                verticalViews?.swapAt(0, 1)

                bringContentToFront([reserveVerticalView, currentVerticalView])

                // 下一次方向改变时需要重新设置 reserveVerticalView
                configVerticalReserveIndex = nil

                switchContentCallback(isDidSwitch: true)
            }
            break
        }
    }
    
    /// 判断当前方向是否可以继续滚动：处于边界页(第一/最后一页)且关闭无限轮播时，往循环方向(无内容方向)的滑动会被拦截并把 contentOffset 拉回中心页
    private func canScroll(_ slidingDirection: WYSlidingDirection) -> Bool {

        guard slidingDirection != .unknown else { return false }

        if (contentSlidingDirection == .omnidirectional) && isDirectionLocked {
            let slidingAxisIsHorizontal = (slidingDirection == .left) || (slidingDirection == .right)
            let displayedAxisIsHorizontal = ((internalSliderDirection == .left) || (internalSliderDirection == .right)) ? true : (((internalSliderDirection == .up) || (internalSliderDirection == .down)) ? false : (prioritySlidingDirection != .topOrBottom))
            if slidingAxisIsHorizontal != displayedAxisIsHorizontal {
                // 跨轴意图的普通拖动一律拦截(零行程且不触发setter，避免拖动中把另一轴View置顶提前换页，任意数量组合与两轴均单页的手感完全一致)；仅轻扫直切路径放行
                return isInstantCrossAxisEntry
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

            contentDelegate.wy_contentScrollViewDidClick(self, direction: clickDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
        }else {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }

            contentDelegate.wy_contentScrollViewDidClick(self, direction: clickDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
        }
    }
    
    /// 当前滑动方向：setter 内同步完成 reserveView 的摆位(按当前偏移量放到滑动方向一侧)、reserveIndex 的计算(含关闭无限轮播时的边界处理)以及 willSwitch 回调的触发
    private var internalSliderDirection: WYSlidingDirection {
        set(newValue) {
            
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

                let previousAxisIsHorizontal = ((previousDirection == .left) || (previousDirection == .right)) ? true : (((previousDirection == .up) || (previousDirection == .down)) ? false : (prioritySlidingDirection != .topOrBottom))
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && previousAxisIsHorizontal
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
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

                let previousAxisIsHorizontal = ((previousDirection == .left) || (previousDirection == .right)) ? true : (((previousDirection == .up) || (previousDirection == .down)) ? false : (prioritySlidingDirection != .topOrBottom))
                let isCrossAxisEntry = (contentSlidingDirection == .omnidirectional) && (previousAxisIsHorizontal == false)
                if isFinalizingSwitch {
                    // 切换收尾期间(pauseScroll复位中心页的重入)：不改动下标，保持刚钳制/落定的值
                }else if isCrossAxisEntry {
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
    }
}

extension WYContentScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        // 回调外部
        internalDelegate?.scrollViewWillBeginDragging?(scrollView)
        
        // 停止计时器
        stopTimer()
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
                if isInstantCrossAxisEntry == false {
                    switchContentCallback(isDidSwitch: true, direction: slidingDirection)
                }
            }
        }else {
            if hasInitialCallbackVertical == false {
                hasInitialCallbackVertical = true
                if isInstantCrossAxisEntry == false {
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
                
                contentDelegate.wy_contentScrollViewDidScroll(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
            }
            
        }else {
            
            canSwitchedPage = (abs(contentOffset.y - wy_height) >= wy_height)
            
            if let contentDelegate = contentDelegate,
               verticalViews?.count == 2,
               let currentVerticalView = verticalViews?.first,
               let reserveVerticalView = verticalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
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

        // 当前展示轴(未滑动过按优先方向推导)
        let displayedAxisIsHorizontal = ((internalSliderDirection == .left) || (internalSliderDirection == .right)) ? true : (((internalSliderDirection == .up) || (internalSliderDirection == .down)) ? false : (prioritySlidingDirection != .topOrBottom))

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

        guard (contentSlidingDirection == .omnidirectional), (isInstantCrossAxisEntry == false) else { return }

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

/// 提供默认空实现，使所有方法变成“可选”
public extension WYContentScrollViewDelegate {
    
    /// 监听偏移量变化事件
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {}

    /// 监听内容页点击事件
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {}

    /// 监听即将切换页面事件
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {}

    /// 监听页面切换完成事件
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {}
}

private class WYWeakBox {
    weak var value: AnyObject?
    init(_ value: AnyObject?) {
        self.value = value
    }
}
