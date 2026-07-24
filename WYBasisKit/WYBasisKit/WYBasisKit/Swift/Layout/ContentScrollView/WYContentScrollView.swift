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
    public var numberOfHorizontalContent: Int = Int.max
    
    /**
     *  垂直方向内容页视图数量（Int.max表示无限数量）
     *  当设置Int.max时，会强制设置automaticCarousel和unlimitedCarousel为false
     */
    public var numberOfVerticalContent: Int = Int.max
    
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
        switch contentSlidingDirection {
        case .leftOrRight:
            currentHorizontalView = currentView
            reserveHorizontalView = reserveView
            break
        case .topOrBottom:
            currentVerticalView = currentView
            reserveVerticalView = reserveView
            break
        case .omnidirectional:
            return
        }
        internalInitializationSettings()
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
            self.currentHorizontalView = currentHorizontalView
            self.reserveHorizontalView = reserveHorizontalView
            self.currentVerticalView = currentVerticalView
            self.reserveVerticalView = reserveVerticalView
            
            internalInitializationSettings()
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
    
    /**
     *  停止定时器
     *  滚动视图将不再自动轮播
     */
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
            
            guard (contentSlidingDirection != .topOrBottom) || (index != currentHorizontalIndex) else {
                return
            }
            
            if index < 0 { index = 0 }
            if index > (numberOfHorizontalContent - 1) { index = (numberOfHorizontalContent - 1) }
            
            if index < currentHorizontalIndex {
                currentHorizontalIndex = (index + 1)
                lastContent(direction)
            }else {
                currentHorizontalIndex = (index - 1)
                lastContent(direction)
            }
            break
        case .topOrBottom:
            
            guard (contentSlidingDirection != .leftOrRight) || (index != currentVerticalIndex) else {
                return
            }
            
            if index < 0 { index = 0 }
            if index > (numberOfVerticalContent - 1) { index = (numberOfVerticalContent - 1) }
            
            if index < currentVerticalIndex {
                currentVerticalIndex = (index + 1)
                lastContent(direction)
            }else {
                currentVerticalIndex = (index - 1)
                lastContent(direction)
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
    }
    
    /// 从故事板或 XIB 加载时所需的初始化方法
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
        checkContentSizeAndContentOffset()
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
    
    /// 内部初始化设置
    private func internalInitializationSettings() {
        Task { @MainActor in
            if (contentSlidingDirection == .omnidirectional) {
                if prioritySlidingDirection == .topOrBottom {
                    addContentView(.leftOrRight)
                    addContentView(.topOrBottom)
                }else {
                    addContentView(.topOrBottom)
                    addContentView(.leftOrRight)
                }
            }else {
                addContentView(contentSlidingDirection)
            }
            
            // 设置自定义Tag，用来标记是否添加过手势事件
            if (tag != 9898) {
                
                tag = 9898
                
                // 在这里设置 super.delegate = self，确保只执行一次
                super.delegate = self
                
                let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickContent))
                addGestureRecognizer(gestureRecognizer)
                
                isPagingEnabled = true
                showsHorizontalScrollIndicator = false
                showsVerticalScrollIndicator = false
                contentInsetAdjustmentBehavior = .never
            }
        }
    }
    
    private func addContentView(_ direction: WYContentSlidingDirection) {
        
        if direction == .leftOrRight {
            guard let currentHorizontalView = currentHorizontalView, let reserveHorizontalView = reserveHorizontalView else { return }
            
            if (contentSlidingDirection == .omnidirectional) {
                
                currentHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: 2 * wy_height, width: wy_width, height: wy_height)
                
            }else {
                currentHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
                
                reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height)
            }
            
            if (currentHorizontalView.superview == nil) && (reserveHorizontalView.superview == nil) {
                addSubview(currentHorizontalView)
                addSubview(reserveHorizontalView)
                switchContentCallback(currentHorizontalView, isDidSwitch: true)
            }
        }
        
        if direction == .topOrBottom {
            guard let currentVerticalView = currentVerticalView, let reserveVerticalView = reserveVerticalView else { return }
            
            if (contentSlidingDirection == .omnidirectional) {
                
                currentVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                reserveVerticalView.frame = CGRect(x: 2 * wy_width, y: 2 * wy_height, width: wy_width, height: wy_height)
                
            }else {
                currentVerticalView.frame = CGRect(x: 0, y: wy_height, width: wy_width, height: wy_height)
                
                reserveVerticalView.frame = CGRect(x: 0, y: 2 * wy_height, width: wy_width, height: wy_height)
            }
            
            if (currentVerticalView.superview == nil) && (reserveVerticalView.superview == nil) {
                addSubview(currentVerticalView)
                addSubview(reserveVerticalView)
                switchContentCallback(currentVerticalView, isDidSwitch: true)
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
            if (wy_slidingDirection == .left) || (wy_slidingDirection == .right) {
                isScrollEnabled = numberOfHorizontalContent > 1 ? horizontalSliderForMultiPage : horizontalSliderForSinglePage
                bounces = numberOfHorizontalContent > 1 ? false : horizontalSliderForSinglePage
            }
            if (wy_slidingDirection == .up) || (wy_slidingDirection == .down) {
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
            if !contentSize.equalTo(CGSize(width: 3*wy_width, height: wy_height)) {
                contentSize = CGSize(width: 3*wy_width, height: wy_height)
            }
            if !alreadySwitchedPages {
                contentOffset = CGPoint(x: wy_width, y: 0)
            }
            break
        case .topOrBottom:
            if !contentSize.equalTo(CGSize(width: wy_width, height: 3*wy_height)) {
                contentSize = CGSize(width: wy_width, height: 3*wy_height)
            }
            if !alreadySwitchedPages {
                contentOffset = CGPoint(x: 0, y: wy_height)
            }
            break
        case .omnidirectional:
            if !contentSize.equalTo(CGSize(width: 3*wy_width, height: 3*wy_height)) {
                contentSize = CGSize(width: 3*wy_width, height: 3*wy_height)
            }
            if !alreadySwitchedPages {
                contentOffset = CGPoint(x: wy_width, y: wy_height)
            }
            break
        }
    }
    
    /// 当前正在水平方向显示的View(用户传入的View)
    private var currentHorizontalView: UIView? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentHorizontalView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.currentHorizontalView) as? UIView
        }
    }
    
    /// 当前水平方向预备显示的View(用户传入的View)
    private var reserveHorizontalView: UIView? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.reserveHorizontalView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.reserveHorizontalView) as? UIView
        }
    }
    
    /// 当前正在垂直方向显示的View(用户传入的View)
    private var currentVerticalView: UIView? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentVerticalView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.currentVerticalView) as? UIView
        }
    }
    
    /// 当前垂直方向预备显示的View(用户传入的View)
    private var reserveVerticalView: UIView? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.reserveVerticalView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.reserveVerticalView) as? UIView
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
            
            if (newValue == .up) || (newValue == .down) {
                // 如果方向没变，reserveVerticalIndex 跟上一次配置的相同，则不重复加载
                guard reserveVerticalIndex != configVerticalReserveIndex else { return }
                // 更新标记
                configVerticalReserveIndex = reserveVerticalIndex
                
                guard let currentVerticalView = currentVerticalView else { return }
                
                // 将对应方向的currentVerticalView移到WYContentScrollView的最上面
                bringSubviewToFront(currentVerticalView)
            }
            
            if (newValue == .left) || (newValue == .right) {
                // 如果方向没变，reserveHorizontalIndex 跟上一次配置的相同，则不重复加载
                guard reserveHorizontalIndex != configHorizontalReserveIndex else { return }
                // 更新标记
                configHorizontalReserveIndex = reserveHorizontalIndex
                
                guard let currentHorizontalView = currentHorizontalView else { return }
                
                // 将对应方向的currentHorizontalView移到WYContentScrollView的最上面
                bringSubviewToFront(currentHorizontalView)
            }
            
            // 向上滚动
            if (newValue == .up) {
                guard let reserveVerticalView = reserveVerticalView else { return }
                
                reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 2 * wy_height, width: wy_width, height: wy_height)
                reserveVerticalIndex = (currentVerticalIndex + 1) % numberOfVerticalContent
                switchContentCallback(reserveVerticalView, isDidSwitch: false)
            }
            
            // 向下滑动
            if newValue == .down {
                guard let reserveVerticalView = reserveVerticalView else { return }
                
                reserveVerticalView.frame = CGRect(x: ((contentSlidingDirection == .omnidirectional) ? wy_width : 0), y: 0, width: wy_width, height: wy_height)
                reserveVerticalIndex = reserveVerticalIndex - 1
                if (reserveVerticalIndex < 0)  {
                    reserveVerticalIndex = numberOfVerticalContent - 1
                }
                switchContentCallback(reserveVerticalView, isDidSwitch: false)
            }
            
            // 向左滚动
            if newValue == .left {
                guard let reserveHorizontalView = reserveHorizontalView else { return }
                
                reserveHorizontalView.frame = CGRect(x: 2 * wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                reserveHorizontalIndex = (currentHorizontalIndex + 1) % numberOfHorizontalContent
                
                switchContentCallback(reserveHorizontalView, isDidSwitch: false)
            }
            
            // 向右滚动
            if (newValue == .right) {
                guard let reserveHorizontalView = reserveHorizontalView else { return }
                
                reserveHorizontalView.frame = CGRect(x: 0, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), width: wy_width, height: wy_height)
                reserveHorizontalIndex = currentHorizontalIndex - 1
                if (reserveHorizontalIndex < 0)  {
                    reserveHorizontalIndex = numberOfHorizontalContent - 1
                }
                switchContentCallback(reserveHorizontalView, isDidSwitch: false)
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
    private func switchContentCallback(_ contentView: UIView, isDidSwitch: Bool) {
        
        guard let contentDelegate = contentDelegate else { return }
        
        guard internalSliderDirection != .unknown else { return }
        
        let isOmnidirectional: Bool = (contentSlidingDirection == .omnidirectional)
        
        if isOmnidirectional {
            
            guard let currentHorizontalView = currentHorizontalView, let reserveHorizontalView = reserveHorizontalView else { return }
            guard let currentVerticalView = currentVerticalView, let reserveVerticalView = reserveVerticalView else { return }
            
            if isDidSwitch {
                contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentHorizontalView: currentHorizontalView, reserveHorizontalView: reserveHorizontalView, currentVerticalView: currentVerticalView, reserveVerticalView: reserveVerticalView)
            }else {
                contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentHorizontalView: currentHorizontalView, reserveHorizontalView: reserveHorizontalView, currentVerticalView: currentVerticalView, reserveVerticalView: reserveVerticalView)
            }
            
        }else {
            if (internalSliderDirection == .up) || (internalSliderDirection == .down) {
                
                guard let currentVerticalView = currentVerticalView, let reserveVerticalView = reserveVerticalView else { return }
                
                if isDidSwitch {
                    contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView)
                }else {
                    contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentView: currentVerticalView, reserveView: reserveVerticalView)
                }
            }
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
                
                guard let currentHorizontalView = currentHorizontalView, let reserveHorizontalView = reserveHorizontalView else { return }
                
                if isDidSwitch {
                    contentDelegate.wy_contentScrollViewDidSwitch(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView)
                }else {
                    contentDelegate.wy_contentScrollViewWillSwitch(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView)
                }
            }
        }
    }
    
    /// 停止滚动并重置currentView的frame
    func pauseScroll() {
        
        guard canSwitchedPage == true else { return }
        
        guard internalSliderDirection != .unknown else { return }
        
        switch contentSlidingDirection {
        case .leftOrRight:
            
            guard let currentHorizontalView = currentHorizontalView else { return }
            
            currentHorizontalIndex = reserveHorizontalIndex
            currentHorizontalView.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
            
            switchContentCallback(currentHorizontalView, isDidSwitch: true)
            contentOffset = CGPoint(x: wy_width, y: 0)
            
            // 下一次方向改变时需要重新设置 reserveHorizontalView
            configHorizontalReserveIndex = nil
            
            break
        case .topOrBottom:
            guard let currentVerticalView = currentVerticalView else { return }
            
            currentVerticalIndex = reserveVerticalIndex
            currentVerticalView.frame = CGRect(x: 0, y: wy_height, width: wy_width, height: wy_height)
            
            switchContentCallback(currentVerticalView, isDidSwitch: true)
            contentOffset = CGPoint(x: 0, y: wy_height)
            
            // 下一次方向改变时需要重新设置 reserveVerticalView
            configVerticalReserveIndex = nil
            break
        case.omnidirectional:
            guard let currentHorizontalView = currentHorizontalView, let currentVerticalView = currentVerticalView else { return }
            
            if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
                
                currentHorizontalIndex = reserveHorizontalIndex
                currentHorizontalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                switchContentCallback(currentHorizontalView, isDidSwitch: true)
                
                // 下一次方向改变时需要重新设置 reserveHorizontalView
                configHorizontalReserveIndex = nil
                
            }else {
                currentVerticalIndex = reserveVerticalIndex
                currentVerticalView.frame = CGRect(x: wy_width, y: wy_height, width: wy_width, height: wy_height)
                
                switchContentCallback(currentVerticalView, isDidSwitch: true)
                
                // 下一次方向改变时需要重新设置 reserveVerticalView
                configVerticalReserveIndex = nil
            }
            
            contentOffset = CGPoint(x: wy_width, y: wy_height)
            
            break
        }
        
        // 标记为已经切换过内容页面
        alreadySwitchedPages = true
    }
    
    /// 判断是否可以滚动
    private func canScroll() -> Bool {
        
        guard internalSliderDirection != .unknown else { return false }
        
        // 检查(设置)轮播状态
        checkCarouselStatus()
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
            
            // 当前停留页面是否是第一页
            let isFirstPage = (currentHorizontalIndex == 0) && (reserveHorizontalIndex == 0)
            
            // 当前停留页面是否是最后一页
            let isLastPage = (currentHorizontalIndex == (numberOfHorizontalContent - 1)) && (reserveHorizontalIndex == (numberOfHorizontalContent - 1))
            
            // 如果当前在第一页或者最后一页的时候，需要根据numberOfHorizontalContent是否等于Int.max和unlimitedCarousel是否为true来判断是否可以切换页面
            if isFirstPage || isLastPage {
                if (unlimitedCarousel == false) || (numberOfHorizontalContent == Int.max) {
                    if (!CGPointEqualToPoint(contentOffset, CGPoint(x: wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0)))) {
                        contentOffset = CGPoint(x: wy_width, y: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0))
                    }
                    return false
                }
            }
            
        }else {
            // 当前停留页面是否是第一页
            let isFirstPage = (currentVerticalIndex == 0) && (reserveVerticalIndex == 0)
            
            // 当前停留页面是否是最后一页
            let isLastPage = (currentVerticalIndex == (numberOfVerticalContent - 1)) && (reserveVerticalIndex == (numberOfVerticalContent - 1))
            
            // 如果当前在第一页或者最后一页的时候，需要根据numberOfVerticalContent是否等于Int.max和unlimitedCarousel是否为true来判断是否可以切换页面
            if isFirstPage || isLastPage {
                if (unlimitedCarousel == false) || (numberOfVerticalContent == Int.max) {
                    if (!CGPointEqualToPoint(contentOffset, CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), y: wy_width))) {
                        contentOffset = CGPoint(x: ((contentSlidingDirection == .omnidirectional) ? wy_height : 0), y: wy_width)
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
            guard let currentHorizontalView = currentHorizontalView, let reserveHorizontalView = reserveHorizontalView else { return }
            contentDelegate.wy_contentScrollViewDidClick(self, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
        }else {
            guard let currentVerticalView = currentVerticalView, let reserveVerticalView = reserveVerticalView else { return }
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
    
    /// 判断是否已经切换过内容页面
    private var alreadySwitchedPages: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.alreadySwitchedPages, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.alreadySwitchedPages) as? Bool ?? false
        }
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
        static var currentHorizontalView: UInt8 = 0
        static var reserveHorizontalView: UInt8 = 0
        static var currentVerticalView: UInt8 = 0
        static var reserveVerticalView: UInt8 = 0
        static var internalSliderDirection: UInt8 = 0
        static var canRestartedTimer: UInt8 = 0
        static var canSwitchedPage: UInt8 = 0
        static var configHorizontalReserveIndex: UInt8 = 0
        static var configVerticalReserveIndex: UInt8 = 0
        static var alreadySwitchedPages: UInt8 = 0
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
        
        guard canScroll() == true else { return }
        
        if (internalSliderDirection == .left) || (internalSliderDirection == .right) {
            let offsetX = scrollView.contentOffset.x
            canSwitchedPage = (abs(offsetX - wy_width) >= wy_width)
            
            internalSliderDirection = offsetX > wy_width ? .left : (offsetX < wy_width ? .right : .unknown)
            
            if let contentDelegate = contentDelegate, let currentHorizontalView = currentHorizontalView, let reserveHorizontalView = reserveHorizontalView {
                
                contentDelegate.wy_contentScrollViewDidScroll(self, offset: scrollView.contentOffset, direction: internalSliderDirection, currentView: currentHorizontalView, reserveView: reserveHorizontalView, index: currentHorizontalIndex)
            }
            
        }else {
            let offsetY = scrollView.contentOffset.y
            canSwitchedPage = (abs(offsetY - wy_height) >= wy_height)
            
            internalSliderDirection = offsetY > wy_height ? .up : (offsetY < wy_height ? .down : .unknown)
            
            if let contentDelegate = contentDelegate, let currentVerticalView = currentVerticalView, let reserveVerticalView = reserveVerticalView {
                
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
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 放大实现逻辑
        internalDelegate?.scrollViewDidZoom?(scrollView)
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
