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
    
    /**
     *  水平方向内容页视图数量（Int.max表示无限数量）
     *  当设置Int.max时，会强制设置automaticCarousel和unlimitedCarousel为false
     */
    public var numberOfHorizontalContent: Int = Int.max {
        // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
        didSet { checkCarouselStatus() }
    }
    
    /**
     *  垂直方向内容页视图数量（Int.max表示无限数量）
     *  当设置Int.max时，会强制设置automaticCarousel和unlimitedCarousel为false
     */
    public var numberOfVerticalContent: Int = Int.max {
        // 这里必须调用一次checkCarouselStatus，以便数量发生变化后可以动态更新scrollView的isScrollEnabled状态
        didSet { checkCarouselStatus() }
    }
    
    /// 支持的滑动方向
    public var contentSlidingDirection: WYContentSlidingDirection = .leftOrRight {
        didSet { checkContentSizeAndContentOffset() }
    }
    
    /// 当前水平方向内容页索引
    public private(set) var currentHorizontalIndex: Int = 0
    
    /// 水平方向储备内容页索引
    public private(set) var reserveHorizontalIndex: Int = 0
    
    /// 当前垂直方向内容页索引
    public private(set) var currentVerticalIndex: Int = 0
    
    /// 垂直方向储备内容页索引
    public private(set) var reserveVerticalIndex: Int = 0
    
    /**
     *  自动轮播时每一页停留时间，默认为3s，最少1s
     *  当设置的值小于1s时，则为默认值
     *  contentSlidingDirection == omnidirectional时不会生效，且会强制停止计时器
     */
    public var standingTime: TimeInterval = 3
    
    /// 水平方向只有一张图片时，是否需要支持滑动，默认false
    public var horizontalSliderForSinglePage: Bool = false
    
    /// 垂直方向只有一张图片时，是否需要支持滑动，默认false
    public var verticalSliderForSinglePage: Bool = false
    
    /// 水平方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)
    public var horizontalSliderForMultiPage: Bool = true
    
    /// 垂直方向有多个内容页面时，是否需要支持滑动(contentSlidingDirection == omnidirectional时固定为false)
    public var verticalSliderForMultiPage: Bool = true
    
    /**
     *  是否需要无限轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启
     *  当设置false时，会强制设置automaticCarousel为false
     */
    public var unlimitedCarousel: Bool = true
    
    /**
     *  是否需要自动轮播，除contentSlidingDirection == omnidirectional时固定为false外，其余默认开启
     *  当设置false时，会关闭定时器
     */
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
    public var prioritySlidingDirection: WYContentSlidingDirection = .leftOrRight
    
    /**
     *  开启定时器(不支持contentSlidingDirection == omnidirectional时调用)
     *  默认开启，调用该方法会重新开启
     */
    public func startTimer() {
        
        // 如果已经开启了，就先关闭计时器
        if timer != nil {
            // 停止计时器
            stopTimer()
        }
        
        // 检查(设置)属性状态
        checkCarouselStatus()
        
        // 未开启轮播或不支持无限循环或者当前支持的滑动方向是omnidirectional则不开启
        guard (contentSlidingDirection != .omnidirectional) &&
                (unlimitedCarousel != false) &&
                (automaticCarousel != false) else {
            return
        }
        
        switch contentSlidingDirection {
        case .leftOrRight:
            // 判断水平方向是否可以开启定时器
            if ((numberOfHorizontalContent < 2) ||
                (unlimitedCarousel == false) ||
                (automaticCarousel == false) ||
                (numberOfHorizontalContent == Int.max)) {
                return
            }
            break
        case .topOrBottom:
            // 判断垂直方向是否可以开启定时器
            if ((numberOfVerticalContent < 2) ||
                (unlimitedCarousel == false) ||
                (automaticCarousel == false) ||
                (numberOfVerticalContent == Int.max)) {
                return
            }
            break
        case .omnidirectional:
            // 全向滑动时，不支持开启定时器
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            guard let self = self else { return }
            lastContent(contentSlidingDirection)
        })
        RunLoop.current.add(timer!, forMode: .common)
        
        canRestartedTimer = true
    }
    
    /// 停止定时器(不支持contentSlidingDirection == omnidirectional时调用)
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
            
            guard (currentHorizontalIndex <= 0) && (unlimitedCarousel == false) else {
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
                addSubview(currentVerticalView)
                addSubview(reserveVerticalView)
                switchContentCallback(isDidSwitch: true)
            }
        }
    }
    
    /// 检查(设置)属性状态
    private func checkCarouselStatus() {
        
        if (numberOfHorizontalContent == Int.max) ||
            (numberOfVerticalContent == Int.max) ||
            (unlimitedCarousel == false) ||
            (automaticCarousel == false) ||
            (contentSlidingDirection == .omnidirectional) {
            unlimitedCarousel = false
            automaticCarousel = false
            
            if (contentSlidingDirection == .omnidirectional) {
                horizontalSliderForMultiPage = false
                verticalSliderForMultiPage = false
            }
        }
        
        switch contentSlidingDirection {
        case .leftOrRight:
            isScrollEnabled = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
            bounces = numberOfHorizontalContent > 1 ? false : horizontalSliderForSinglePage
            break
        case .topOrBottom:
            isScrollEnabled = numberOfVerticalContent > 1 ? verticalSliderForMultiPage : verticalSliderForSinglePage
            bounces = numberOfVerticalContent > 1 ? false : verticalSliderForSinglePage
            break
        case .omnidirectional:
            if (wy_slidingDirection() == .left) || (wy_slidingDirection() == .right) {
                isScrollEnabled = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
                bounces = numberOfHorizontalContent > 1 ? false : horizontalSliderForSinglePage
            }
            if (wy_slidingDirection() == .up) || (wy_slidingDirection() == .down) {
                isScrollEnabled = numberOfVerticalContent > 1 ? verticalSliderForMultiPage : verticalSliderForSinglePage
                bounces = numberOfVerticalContent > 1 ? false : verticalSliderForSinglePage
            }
            break
        }
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
    
    /// 滚动方向
    private var internalSliderDirection: WYSlidingDirection {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            if ((newValue == .up) || (newValue == .down) && (contentSlidingDirection != .leftOrRight)) {
                
                guard numberOfVerticalContent > 0 else { return }
                
                guard verticalViews?.count == 2,
                      let currentVerticalView = verticalViews?.first,
                      let reserveVerticalView = verticalViews?.last else { return }
                
                // 滑动前根据滑动方向设置预备显示View的frame(必须放这里优先处理，否则往左右滑动后可能会出现空白页面)
                if newValue == .up {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                }else {
                    reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                }
                
                // 如果方向没变，reserveVerticalIndex 跟上一次配置的相同，则不重复加载
                guard reserveVerticalIndex != configVerticalReserveIndex else { return }
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringSubviewToFront(currentVerticalView)
                bringSubviewToFront(reserveVerticalView)
            }
            
            if ((newValue == .left) || (newValue == .right) && (contentSlidingDirection != .topOrBottom)) {
                
                guard numberOfHorizontalContent > 0 else { return }
                
                guard horizontalViews?.count == 2,
                      let currentHorizontalView = horizontalViews?.first,
                      let reserveHorizontalView = horizontalViews?.last else { return }
                
                // 滑动前根据滑动方向设置预备显示View的frame(必须放这里优先处理，否则往上下滑动后可能会出现空白页面)
                if newValue == .left {
                    reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }else {
                    reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                }
                
                // 如果方向没变，reserveHorizontalIndex 跟上一次配置的相同，则不重复加载
                guard reserveHorizontalIndex != configHorizontalReserveIndex else { return }
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex
                
                // 将对应方向的正在显示的View移到WYContentScrollView的最上面
                bringSubviewToFront(currentHorizontalView)
                bringSubviewToFront(reserveHorizontalView)
            }
            
            // 向上滚动
            if (newValue == .up) {
                guard verticalViews?.count == 2, let reserveVerticalView = verticalViews?.last else { return }
                
                reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                switchContentCallback(isDidSwitch: false)
            }
            
            // 向下滑动
            if newValue == .down {
                
                guard verticalViews?.count == 2, let reserveVerticalView = verticalViews?.last else { return }
                
                reserveVerticalIndex = currentVerticalIndex - 1
                if (reserveVerticalIndex < 0)  {
                    reserveVerticalIndex = numberOfVerticalContent - 1
                }
                switchContentCallback(isDidSwitch: false)
            }
            
            // 向左滚动
            if newValue == .left {
                
                guard horizontalViews?.count == 2, let reserveHorizontalView = horizontalViews?.last else { return }

                reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                
                switchContentCallback(isDidSwitch: false)
            }
            
            // 向右滚动
            if (newValue == .right) {
                
                guard horizontalViews?.count == 2, let reserveHorizontalView = horizontalViews?.last else { return }

                reserveHorizontalIndex = currentHorizontalIndex - 1
                if (reserveHorizontalIndex < 0)  {
                    reserveHorizontalIndex = numberOfHorizontalContent - 1
                }
                switchContentCallback(isDidSwitch: false)
            }
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.internalSliderDirection) as? WYSlidingDirection ?? .unknown
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
        
        guard let contentDelegate = contentDelegate else { return }
        
        guard internalSliderDirection != .unknown else { return }
        
        let isOmnidirectional: Bool = (contentSlidingDirection == .omnidirectional)
        
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
        
        guard canSwitchedPage == true else { return }
        
        guard internalSliderDirection != .unknown else { return }
        
        switch contentSlidingDirection {
        case .leftOrRight:
            
            guard horizontalViews?.count == 2,
                  let currentHorizontalView = horizontalViews?.first,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            currentHorizontalIndex = reserveHorizontalIndex
            
            // 交换horizontalViews数组中两个View的位置
            horizontalViews?.swapAt(0, 1)
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
            
            switchContentCallback(isDidSwitch: true)
            
            contentOffset = CGPoint(x: wy_width, y: 0)
            
            // 下一次方向改变时需要重新设置 reserveHorizontalView
            configHorizontalReserveIndex = nil
            
            break
        case .topOrBottom:
            
            guard verticalViews?.count == 2,
                  let currentVerticalView = verticalViews?.first,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            currentVerticalIndex = reserveVerticalIndex
            
            // 交换verticalViews数组中两个View的位置
            verticalViews?.swapAt(0, 1)
            
            // 滑动后根据滑动方向设置已经显示View的frame
            reserveVerticalView.frame = CGRect(x: 0, y: wy_height, width: wy_width, height: wy_height)
            
            switchContentCallback(isDidSwitch: true)
            contentOffset = CGPoint(x: 0, y: wy_height)
            
            // 下一次方向改变时需要重新设置 reserveVerticalView
            configVerticalReserveIndex = nil
            
            break
        case.omnidirectional:
            
            guard horizontalViews?.count == 2,
                  let reserveHorizontalView = horizontalViews?.last else { return }
            
            guard verticalViews?.count == 2,
                  let reserveVerticalView = verticalViews?.last else { return }
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
                
                currentHorizontalIndex = reserveHorizontalIndex
                
                // 交换horizontalViews数组中两个View的位置
                horizontalViews?.swapAt(0, 1)
                
                reserveHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                switchContentCallback(isDidSwitch: true)
                
                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil
                
            }else {
                currentVerticalIndex = reserveVerticalIndex
                
                // 交换verticalViews数组中两个View的位置
                verticalViews?.swapAt(0, 1)
                
                reserveVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                switchContentCallback(isDidSwitch: true)
                
                // 下一次方向改变时需要重新设置 reserveVerticalView
                configVerticalReserveIndex = nil
            }
            
            contentOffset = CGPoint(x: wy_width, y: wy_height)
            
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
                if (unlimitedCarousel == false) || (numberOfHorizontalContent == Int.max) {
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
                if (unlimitedCarousel == false) || (numberOfVerticalContent == Int.max) {
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
    
    /// 判断手动拖拽后是否需要启动定时器
    private var canRestartedTimer: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.canRestartedTimer) as? Bool ?? false
        }
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
    }
}

extension WYContentScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
        internalDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if canRestartedTimer == true {
            startTimer()
        }
        internalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetX = scrollView.contentOffset.x
        let offsetY = scrollView.contentOffset.y
        
        var slidingDirection: WYSlidingDirection = internalSliderDirection
        
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
        
        guard canScroll(slidingDirection) == true else { return }
        
        // internalSliderDirection 必须放在canScroll之后设置，否则可能会出现屏幕无法铺满的情况
        internalSliderDirection = slidingDirection
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
            
            canSwitchedPage = (abs(offsetX - wy_width) >= wy_width)
            
            if let contentDelegate = contentDelegate,
               horizontalViews?.count == 2,
               let currentHorizontalView = horizontalViews?.first,
               let reserveHorizontalView = horizontalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
            }
            
        }else {
            
            canSwitchedPage = (abs(offsetY - wy_height) >= wy_height)
            
            if let contentDelegate = contentDelegate,
               verticalViews?.count == 2,
               let currentVerticalView = verticalViews?.first,
               let reserveVerticalView = verticalViews?.last {
                
                contentDelegate.wy_contentScrollViewDidScroll(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView, index: currentVerticalIndex)
            }
        }
        
        internalDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pauseScroll()
        internalDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        pauseScroll()
        internalDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
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
