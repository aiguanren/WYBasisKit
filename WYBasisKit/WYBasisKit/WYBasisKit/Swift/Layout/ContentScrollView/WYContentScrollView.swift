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
     *
     *  @param offset             当前的偏移量
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param index              当前滑动的Index
     */
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)
    
    /**
     *  监听ContentScrollView的点击事件
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param index              当前点击的Index
     */
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int)
    
    /**
     *  监听ContentScrollView即将切换页面的事件
     (contentSlidingDirection != omnidirectional时可用)
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     */
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView)
    
    /**
     *  监听ContentScrollView页面已经切换完成的事件
     (contentSlidingDirection != omnidirectional时可用)
     *
     *  @param contentScrollView  当前WYContentScrollView的实例对象
     *
     *  @param direction          当前的滑动方向
     *
     *  @param currentView        当前正在显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     *
     *  @param reserveView        当前预备显示的用户传入的View
     (左右滑动时为水平方向的View，上下滑动时为垂直方向的View)
     */
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView)
    
    /**
     *  监听ContentScrollView即将切换页面的事件
     (contentSlidingDirection == omnidirectional时可用)
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *
     *  @param direction             当前的滑动方向
     *
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView)
    
    /**
     *  监听ContentScrollView页面已经切换完成的事件
     (contentSlidingDirection == omnidirectional时可用)
     *
     *  @param contentScrollView     当前WYContentScrollView的实例对象
     *
     *  @param direction             当前的滑动方向
     *
     *  @param currentHorizontalView 当前正在水平方向显示的View(用户传入的View)
     *
     *  @param reserveHorizontalView 当前水平方向预备显示的View(用户传入的View)
     *
     *  @param currentVerticalView   当前正在垂直方向显示的View(用户传入的View)
     *
     *  @param reserveVerticalView   当前垂直方向预备显示的View(用户传入的View)
     */
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView)
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
            bringContentToFront()
            // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
            checkCarouselStatus()
        }
    }
    
    /// 垂直方向内容页视图数量（Int.max表示无限数量）
    public var numberOfVerticalContent: Int = Int.max {
        didSet {
            bringContentToFront()
            // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
            checkCarouselStatus()
        }
    }
    
    /// 支持的滑动方向
    public var contentSlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet {
            bringContentToFront()
            checkContentSizeAndContentOffset()
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
    
    /// 水平方向只有一张图片时，是否需要支持滑动，默认false
    public var horizontalSliderForSinglePage: Bool = false
    
    /// 垂直方向只有一张图片时，是否需要支持滑动，默认false
    public var verticalSliderForSinglePage: Bool = false
    
    /// 水平方向有多个内容页面时，是否需要支持滑动
    public var horizontalSliderForMultiPage: Bool = true
    
    /// 垂直方向有多个内容页面时，是否需要支持滑动
    public var verticalSliderForMultiPage: Bool = true
    
    /// 是否需要无限轮播
    public var unlimitedCarousel: Bool = true
    
    /// 是否需要自动轮播
    public var automaticCarousel: Bool = true
    
    /**
     *  需要加载到内容页视图上的自定义View
     (contentSlidingDirection != omnidirectional时调用)
     *
     *  @param currentView      需要添加到正在水平或者垂直方向上显示的自定义View，
     其Size将等于当前WYContentScrollView的Size
     *
     *  @param reserveView      需要添加到预备显示在水平或者垂直方向上的自定义View，
     其Size将等于当前WYContentScrollView的Size
     *
     */
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
    
    /**
     *  需要加载到内容页视图上的自定义View
     (contentSlidingDirection == omnidirectional时调用)
     *
     *  @param currentHorizontalView    需要添加到正在水平方向上显示的自定义View，
     其Size将等于当前WYContentScrollView的Size
     *
     *  @param reserveHorizontalView    需要添加到预备显示在水平方向上的自定义View
     ，其Size将等于当前WYContentScrollView的Size
     *
     *  @param currentVerticalView      需要添加到正在垂直方向上显示的自定义View，
     其Size将等于当前WYContentScrollView的Size
     *
     *  @param reserveVerticalView      需要添加到预备显示在垂直方向上的自定义View
     ，其Size将等于当前WYContentScrollView的Size
     *
     */
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
            guard contentSlidingDirection != .topOrBottom else {
                return
            }
            
            guard (currentHorizontalIndex != (numberOfHorizontalContent - 1)) && (unlimitedCarousel != false) else {
                return
            }
            
            setContentOffset(CGPoint(x: wy_width*2, y: (contentSlidingDirection == .omnidirectional) ? wy_height : 0), animated: true)
            
            break
        case .topOrBottom:
            guard contentSlidingDirection != .leftOrRight else {
                return
            }
            
            guard (currentVerticalIndex != (numberOfVerticalContent - 1)) && (unlimitedCarousel != false) else {
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
            guard contentSlidingDirection != .topOrBottom else {
                return
            }
            
            guard (currentHorizontalIndex <= 0) && (unlimitedCarousel != false) else {
                return
            }
            
            setContentOffset(CGPoint(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0)), animated: true)
            
            break
        case .topOrBottom:
            guard contentSlidingDirection != .leftOrRight else {
                return
            }
            
            guard (currentVerticalIndex <= 0) && (unlimitedCarousel == false) else {
                return
            }
            
            setContentOffset(CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0), animated: true)
            break
            
        default:
            break
        }
    }
    
    /// 切换到指定方向指定下标处(不支持直接传入direction为omnidirectional)
    public func switchContent(_ direction: WYContentSlidingDirection, index: inout Int) {
        switch direction {
        case .leftOrRight:
            
            if index < 0 { index = 0 }
            if index > (numberOfHorizontalContent - 1) { index = (numberOfHorizontalContent - 1) }
            
            guard (contentSlidingDirection != .topOrBottom) || (index != currentHorizontalIndex) else {
                return
            }
            
            if index < currentHorizontalIndex {
                if (index - 1) >= 0 {
                    currentHorizontalIndex = (index - 1)
                    lastContent(direction)
                }
            }else if index > currentHorizontalIndex {
                if (index + 1) <= (numberOfHorizontalContent - 1) {
                    currentHorizontalIndex = (index + 1)
                    nextContent(direction)
                }
            }
            
            break
        case .topOrBottom:
            
            if index < 0 { index = 0 }
            if index > (numberOfVerticalContent - 1) { index = (numberOfVerticalContent - 1) }
            
            guard (contentSlidingDirection != .leftOrRight) || (index != currentVerticalIndex) else {
                return
            }
            
            if index < currentVerticalIndex {
                if (index - 1) >= 0 {
                    currentVerticalIndex = (index - 1)
                    lastContent(direction)
                }
            }else if index > currentVerticalIndex {
                if (index + 1) <= (numberOfVerticalContent - 1) {
                    currentVerticalIndex = (index + 1)
                    nextContent(direction)
                }
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
        
        switch direction {
        case .leftOrRight:
            horizontalViews?.forEach { $0.removeFromSuperview() }
            horizontalViews = nil
            break
        case .topOrBottom:
            verticalViews?.forEach { $0.removeFromSuperview() }
            verticalViews = nil
            break
        case .omnidirectional:
            horizontalViews?.forEach { $0.removeFromSuperview() }
            horizontalViews = nil
            verticalViews?.forEach { $0.removeFromSuperview() }
            verticalViews = nil
            break
        }
    }
    
    /// 内部初始化设置
    private func internalInitializationSettings() {
        
        super.delegate = self
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickContent))
        addGestureRecognizer(gestureRecognizer)
        
        bounces = false
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
    }
    
    /// 内部设置添加ContentView
    private func internalSettingsContentView(isReload: Bool) {
        
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
    }
    
    private func layoutContentSubViews(_ direction: WYContentSlidingDirection, isReload: Bool) {
        
        if direction == .leftOrRight {
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
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
                addSubview(currentHorizontalView)
                addSubview(reserveHorizontalView)
                switchContentCallback(isDidSwitch: true)
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
                addSubview(currentVerticalView)
                addSubview(reserveVerticalView)
                switchContentCallback(isDidSwitch: true)
            }
        }
        // 初始化时同步contentOffset
        lastValidContentOffset = contentOffset
    }
    
    /// 检查当前滚动能力（只控制整体是否可滚动，不参与方向控制）
    private func checkCarouselStatus() {
        
        switch contentSlidingDirection {
        case .leftOrRight:
            // 横向滑动
            isScrollEnabled = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
            break
        case .topOrBottom:
            // 纵向滑动
            isScrollEnabled = numberOfVerticalContent > 1 ? verticalSliderForMultiPage : verticalSliderForSinglePage
            break
        case .omnidirectional:
            // 横向是否可滑动
            let horizontalCanScroll = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
            // 纵向是否可滑动
            let verticalCanScroll = numberOfVerticalContent > 1 ? verticalSliderForMultiPage : verticalSliderForSinglePage
            
            // 此模式下只要有一个方向可以滑，就需要允许滚动，否则某个方向设置数量为1后，就会导致另一个方向也会锁死不能滑动，因为isScrollEnabled是全局的，具体方向锁定通过handleScrollDirectionLock方法来实现
            isScrollEnabled = horizontalCanScroll || verticalCanScroll
            break
        }
    }
    
    /// 判断设置展示在顶层的对应方向的View，若contentViews为空则内部自行判断
    private func bringContentToFront(_ contentViews: [UIView]? = nil) {
        
        // 直接将传入的对应的ContentView移到WYContentScrollView的最顶层，且因为currentView和reserveView的frame有可能是一样的，所有需要最后执行bringSubviewToFront(currentView)
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
                if ((numberOfHorizontalContent > 1) && (numberOfVerticalContent > 1)) || (numberOfHorizontalContent == numberOfVerticalContent) {
                    // 都大于1或者都等于1，则依据优先显示方向来处理
                    if (prioritySlidingDirection == .leftOrRight) && (upperContentView != currentVerticalView) {
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
                    if (numberOfHorizontalContent > numberOfVerticalContent) && (upperContentView != currentHorizontalView) {
                        bringSubviewToFront(reserveHorizontalView)
                        bringSubviewToFront(currentHorizontalView)
                        upperContentView = currentHorizontalView
                        return
                    }else if (upperContentView != currentVerticalView) {
                        bringSubviewToFront(reserveVerticalView)
                        bringSubviewToFront(currentVerticalView)
                        upperContentView = currentVerticalView
                        return
                    }
                }
            }
        }
    }
    
    /// 处理方向锁定（控制某个方向不能滑动）
    private func handleScrollDirectionLock() -> WYSlidingDirection {
        
        // 横向是否允许滑动
        let horizontalCanScroll = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
        
        // 纵向是否允许滑动
        let verticalCanScroll = numberOfVerticalContent > 1 ? verticalSliderForMultiPage : verticalSliderForSinglePage
        
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

        /// 仅在全方向模式下处理
        if contentSlidingDirection == .omnidirectional {
            
            let centerX = wy_width
            let centerY = wy_height

            /// 相对中心点的偏移
            let deltaX = offsetX - centerX
            let deltaY = offsetY - centerY
        
            /// 未锁定时，根据主方向判断一次
            if isDirectionLocked == false {
                
                let threshold: CGFloat = 2.0  // 防抖
                
                if abs(deltaX) > threshold || abs(deltaY) > threshold {
                    if abs(deltaX) > abs(deltaY) {
                        // 横向
                        if deltaX > 0 {
                            slidingDirection = .left
                        } else {
                            slidingDirection = .right
                        }
                        
                    } else {
                        // 纵向
                        if deltaY > 0 {
                            slidingDirection = .up
                        } else {
                            slidingDirection = .down
                        }
                    }
                    // 一旦判断完成，立即锁定
                    isDirectionLocked = true
                    // 同步记录本次拖拽锁定的方向，用于边界拦截后 internalSliderDirection 未更新时仍能保持方向
                    dragLockedDirection = slidingDirection
                }
            } else {
                // 已锁定时优先使用本次拖拽锁定的方向，避免 internalSliderDirection 未更新时 slidingDirection 退化为 .unknown 导致 canScroll 拦截失效
                if dragLockedDirection != .unknown {
                    slidingDirection = dragLockedDirection
                }
            }
            
            /// 锁死另一方向（防止出现多方向同时滑动的问题）
            if isDirectionLocked {
                if slidingDirection == .left || slidingDirection == .right {
                    /// 锁死 Y
                    if offsetY != centerY {
                        contentOffset.y = centerY
                    }
                    
                } else if slidingDirection == .up || slidingDirection == .down {
                    /// 锁死 X
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
    
    /// 检查(设置)contentSize与contentOffset
    private func checkContentSizeAndContentOffset() {
        
        switch contentSlidingDirection {
        case .leftOrRight:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                contentOffset = CGPoint(x: wy_width, y: 0)
            }
            break
        case .topOrBottom:
            let targetSize: CGSize = CGSize(width: wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                contentOffset = CGPoint(x: 0, y: wy_height)
            }
            break
        case .omnidirectional:
            let targetSize: CGSize = CGSize(width: 3*wy_width, height: 3*wy_height)
            if !contentSize.equalTo(targetSize) {
                contentSize = targetSize
                contentOffset = CGPoint(x: wy_width, y: wy_height)
            }
            break
        }
    }
    
    /**
     *  切换内容页回调
     *
     *  参数:
     *  - contentView: 要切换到的内容视图
     *  - isDidSwitch: 切换是否已完成，为true时表示是已经切换完成，false时表示false时表示是即将切换
     */
    private func switchContentCallback(isDidSwitch: Bool) {
        
        guard let contentDelegate = contentDelegate, internalSliderDirection != .unknown else { return }
        
        let isOmnidirectional: Bool = (contentSlidingDirection == .omnidirectional)
        
        print("\(isDidSwitch ? "isDidSwitch" : "isWillSwitch"), direction：\(internalSliderDirection)")
        
        if isOmnidirectional {
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            if isDidSwitch {
                contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentHorizontalView: currentHorizontalView, reserveHorizontalView: reserveHorizontalView, currentVerticalView: currentVerticalView, reserveVerticalView: reserveVerticalView)
            }else {
                contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentHorizontalView: currentHorizontalView, reserveHorizontalView: reserveHorizontalView, currentVerticalView: currentVerticalView, reserveVerticalView: reserveVerticalView)
            }
            
        }else {
            if (internalSliderDirection == .up) || (internalSliderDirection == .down) {
                
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                
                if isDidSwitch {
                    contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView)
                }else {
                    contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView)
                }
            }
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
                
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                
                if isDidSwitch {
                    contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView)
                }else {
                    contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView)
                }
            }
        }
    }
    
    /// 停止滚动并切换contentViews的位置与frame
    func pauseScroll() {
        
        guard (canSwitchedPage == true), (internalSliderDirection != .unknown) else { return }
        
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
                
                currentHorizontalIndex = reserveHorizontalIndex
                
                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                // 交换horizontalViews数组中两个View的位置
                horizontalViews?.swapAt(0, 1)
                
                bringContentToFront([reserveHorizontalView, currentHorizontalView])
                
                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil
                
                switchContentCallback(isDidSwitch: true)
                
            }else {
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
    
    /// 判断是否可以滚动
    private func canScroll(_ slidingDirection: WYSlidingDirection) -> Bool {
        // 检查(设置)轮播状态
        checkCarouselStatus()
        
        guard slidingDirection != .unknown else { return false }
        
        if (slidingDirection == .left) || (slidingDirection == .right) {
            
            guard contentSlidingDirection != .topOrBottom else { return false }
            
            // 当前停留页面是否是第一页
            let isFirstPage = (currentHorizontalIndex == 0) && ((reserveHorizontalIndex == 0) || (reserveHorizontalIndex == 1))
            
            // 当前停留页面是否是最后一页
            let isLastPage = (currentHorizontalIndex == (numberOfHorizontalContent - 1)) && (reserveHorizontalIndex == (numberOfHorizontalContent - 1))
            
            // 如果当前在第一页或者最后一页的时候，需要根据numberOfHorizontalContent是否等于Int.max和unlimitedCarousel是否为true来判断是否可以切换页面
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
            
            // 当前停留页面是否是第一页
            let isFirstPage = (currentVerticalIndex == 0) && ((reserveVerticalIndex == 0) || (reserveVerticalIndex == 1))
            
            // 当前停留页面是否是最后一页
            let isLastPage = (currentVerticalIndex == (numberOfVerticalContent - 1)) && (reserveVerticalIndex == (numberOfVerticalContent - 1))
            
            // 如果当前在第一页或者最后一页的时候，需要根据numberOfVerticalContent是否等于Int.max和unlimitedCarousel是否为true来判断是否可以切换页面
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
        
        guard internalSliderDirection != .unknown else { return }
        
        guard let contentDelegate = contentDelegate else { return }
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            contentDelegate.wy_contentScrollViewDidClick(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
        }else {
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            contentDelegate.wy_contentScrollViewDidClick(self, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
        }
    }
    
    /// 滚动方向
    private var internalSliderDirection: WYSlidingDirection {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 当前显示在最顶层的ContentView
            guard let upperContentView: UIView = upperContentView else { return }
            
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
                
                if newValue == .up {
                    reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                    if (reserveVerticalIndex == 0) && (unlimitedCarousel == false) {
                        reserveVerticalIndex = currentVerticalIndex
                    }
                }else {
                    reserveVerticalIndex = currentVerticalIndex - 1
                    if (reserveVerticalIndex < 0)  {
                        reserveVerticalIndex = numberOfVerticalContent - 1
                    }
                }
                
                if configVerticalReserveIndex != reserveVerticalIndex {
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
                
                if newValue == .left {
                    reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                    if (reserveHorizontalIndex == 0) && (unlimitedCarousel == false) {
                        reserveHorizontalIndex = currentHorizontalIndex
                    }
                }else {
                    reserveHorizontalIndex = currentHorizontalIndex - 1
                    if (reserveHorizontalIndex < 0)  {
                        reserveHorizontalIndex = numberOfHorizontalContent - 1
                    }
                }
                
                if configHorizontalReserveIndex != reserveHorizontalIndex {
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

    /// 本次拖拽中锁定的滑动方向(仅omnidirectional模式下使用)，持久化本次拖拽锁定的方向，配合 handleScrollDirectionLock 避免边界拦截后方向丢失，用于在 canScroll 在边界处拦截(返回false)导致 internalSliderDirection 未更新时仍能保持本次拖拽的方向
    private var dragLockedDirection: WYSlidingDirection {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.dragLockedDirection) as? WYSlidingDirection ?? .unknown }
    }
    
    /// 上一次合法的偏移量（用于方向锁定）
    private var lastValidContentOffset: CGPoint {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.lastValidContentOffset) as? CGPoint ?? .zero
        }
    }
    
    /// 判断是否可以切换页面
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
        
        // internalSliderDirection 必须放在canScroll之后设置，否则可能会出现屏幕无法铺满的情况
        internalSliderDirection = slidingDirection
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
            
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
    
    // 监听ContentScrollView的偏移量变化事件
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGPoint, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {}
    
    // 监听ContentScrollView的点击事件
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView, index: Int) {}
    
    // 监听ContentScrollView即将切换页面的事件(contentSlidingDirection != omnidirectional时可用)
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {}
    
    // 监听ContentScrollView页面已经切换完成的事件(contentSlidingDirection != omnidirectional时可用)
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentView: UIView, reserveView: UIView) {}
    
    // 监听ContentScrollView即将切换页面的事件(contentSlidingDirection == omnidirectional时可用)
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {}
    
    // 监听ContentScrollView页面已经切换完成的事件(contentSlidingDirection == omnidirectional时可用)
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {}
}

private class WYWeakBox {
    weak var value: AnyObject?
    init(_ value: AnyObject?) {
        self.value = value
    }
}
