//
//  WYContentScrollView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/4/13.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

@objc public protocol WYContentScrollViewDelegate {
    
    /// 监听ContentScrollView点击事件
    @objc(wy_contentScrollViewDidClick:index:)
    optional func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, index: Int)
    
    /// 监听ContentScrollView的轮播事件
    @objc(wy_contentScrollViewDidScroll:offset:index:)
    optional func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGFloat, index: Int)
}

public class WYContentScrollView: UIScrollView {
    
    /// 点击或滑动事件代理(也可以通过传入block监听)
    public weak var contentDelegate: WYContentScrollViewDelegate?
    
    /**
     * 监听ContentScrollView点击事件(也可以通过实现代理监听)
     *
     * @param handler 点击事件的block
     */
    public func didClick(handler: @escaping ((_ index: Int) -> Void)) {
        clickHandler = handler
    }
    
    /**
     * 监听ContentScrollView的轮播事件(也可以通过实现代理监听)
     *
     * @param handler 轮播事件的block
     */
    public func didScroll(handler: @escaping ((_ offset: CGFloat, _ index: Int) -> Void)) {
        scrollHandler = handler
    }
    
    /// 当前内容页视图数量（Int.max表示无限数量）
    public var numberOfContent: Int = Int.max
    
    /// 当前页内容视图
    public var currentContent: UIImageView = UIImageView()
    
    /// 储备页内容视图
    public var reserveContent: UIImageView = UIImageView()
    
    /// 当前内容页索引
    private var currentIndex: Int {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.currentIndex) as? Int ?? 0
        }
    }
    
    /// 储备内容页索引
    private var reserveIndex: Int {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.reserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.reserveIndex) as? Int ?? 0
        }
    }
    
    /**
     *  自动轮播时每一页停留时间，默认为3s，最少1s
     *  当设置的值小于1s时，则为默认值
     */
    public var standingTime: TimeInterval = 3
    
    /// 只有一个内容页面时，是否需要支持滑动，默认false
    public var scrollForSinglePage: Bool = false
    
    /// 多个内容页面时，是否需要支持滑动，默认true
    public var scrollForMultiPage: Bool = true
    
    /**
     *  是否需要无限轮播，默认开启
     *  当设置false时，会强制设置automaticCarousel为false
     */
    public var unlimitedCarousel: Bool = true {
        willSet {
            if (newValue == false) {
                stopTimer()
                automaticCarousel = false
            }
        }
    }
    
    /**
     *  是否需要自动轮播，默认开启
     *  当设置false时，会关闭定时器
     *  当设置true时，unlimitedCarousel会强制设置为True
     */
    public var automaticCarousel: Bool = true {
        willSet {
            if newValue == false {
                stopTimer()
            }else {
                unlimitedCarousel = true
                startTimer()
            }
        }
    }
    
    /**
     *  开启定时器
     *  默认开启，调用该方法会重新开启
     */
    public func startTimer() {
        
        // 如果定时器已开启，先停止再根据条件重新开启
        if (timer != nil) {
            stopTimer()
        }
        // 判断是否需要开启定时器
        if (((numberOfContent < 1)) || ((scrollForSinglePage == false) && (numberOfContent == 1)) || (unlimitedCarousel == false) || (automaticCarousel == false)) { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            self?.lastContent()
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
    
    /// 切换下一个内容页面
    public func nextContent() {
        setContentOffset(CGPoint(x: wy_width*2, y: 0), animated: true)
    }
    
    /// 切换上一个内容页面
    public func lastContent() {
        setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    /// 切换到指定下标处
    public func switchContent(_ index: Int) {
        
        guard index != currentIndex else {
            return
        }
        
        if index < currentIndex {
            currentIndex = (index + 1)
            lastContent()
        }else {
            currentIndex = (index - 1)
            lastContent()
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
        isScrollEnabled = numberOfContent > 1 ? scrollForMultiPage : scrollForSinglePage
    }
    
    /// 内部初始化设置
    private func internalInitializationSettings() {
        delegate = self
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = false
        contentSize = CGSize(width: 3*wy_width, height: wy_height)
        contentOffset = CGPoint(x: wy_width, y: 0)
        
        contentInsetAdjustmentBehavior = .never
        
        currentIndex = 0
        reserveIndex = 0
        
        currentContent.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
        currentContent.layer.masksToBounds = true
        addSubview(currentContent)
        
        reserveContent.frame = CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height)
        reserveContent.layer.masksToBounds = true
        addSubview(reserveContent)
        
        switchContent(currentContent)
        
        if automaticCarousel == true {
            automaticCarousel = true
        }
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickContent))
        addGestureRecognizer(gestureRecognizer)
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
    
    private enum WYContentScrollDirection {
        /// 未滑动
        case none
        /// 向左滑动
        case left
        /// 向右滑动
        case right
    }
    
    /// 滚动方向
    private var scrollDirection: WYContentScrollDirection {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.scrollDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 向右滚动
            if newValue == .right {
                reserveContent.frame = CGRect(x: 0, y: 0, width: wy_width, height: wy_height)
                reserveIndex = currentIndex - 1
                if (reserveIndex < 0)  {
                    reserveIndex = numberOfContent - 1
                }
            }
            // 向左滚动
            if newValue == .left {
                reserveContent.frame = CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height)
                reserveIndex = (currentIndex + 1) % numberOfContent
            }
            
            // 如果方向没变，reserveIndex 跟上一次配置的相同，则不重复加载
            guard reserveIndex != configuredReserveIndex else { return }
            
            // 更新标记
            configuredReserveIndex = reserveIndex
            
            switchContent(reserveContent)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.scrollDirection) as? WYContentScrollDirection ?? .none
        }
    }
    
    /// 切换内容页
    private func switchContent(_ contentView: UIImageView) {
        
    }
    
    /// 停止滚动
    func pauseScroll() {
        
        guard canSwitchedPage == true else {
            return
        }
        
        currentIndex = reserveIndex
        currentContent.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
        
        switchContent(currentContent)
        contentOffset = CGPoint(x: wy_width, y: 0)
        
        // 下一次方向改变时需要重新设置 reserveContent
        configuredReserveIndex = nil
    }
    
    /// 判断是否可以滚动
    private func canScroll(_ offsetX: CGFloat) -> Bool {
        if (unlimitedCarousel == false) && (((offsetX < wy_width) && (currentIndex == 0)) || ((offsetX > wy_width) && (currentIndex == (numberOfContent - 1)))) {
            contentOffset = CGPoint(x: wy_width, y: 0)
            return false
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
    
    /// block点击事件
    private var clickHandler: ((_ index: Int) -> Void)? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.clickHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.clickHandler) as? (Int) -> Void
        }
    }
    
    /// block轮播事件
    private var scrollHandler: ((_ offset: CGFloat, _ index: Int) -> Void)? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.scrollHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.scrollHandler) as? (CGFloat, Int) -> Void
        }
    }
    
    /// 点击了内容页面
    @objc func didClickContent() {
        if let contentDelegate = contentDelegate {
            contentDelegate.wy_contentScrollViewDidClick?(self, index: currentIndex)
        }
        
        if let handler = clickHandler {
            handler(currentIndex)
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
    
    /// 记录上一次为 reserveContent 配置的索引，避免重复设置
    private var configuredReserveIndex: Int? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.configuredReserveIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.configuredReserveIndex) as? Int }
    }
    
    private struct WYAssociatedKeys {
        static var currentView: UInt8 = 0
        static var reserverView: UInt8 = 0
        static var currentIndex: UInt8 = 0
        static var reserveIndex: UInt8 = 0
        static var timer: UInt8 = 0
        static var scrollDirection: UInt8 = 0
        static var canRestartedTimer: UInt8 = 0
        static var clickHandler: UInt8 = 0
        static var scrollHandler: UInt8 = 0
        static var canSwitchedPage: UInt8 = 0
        static var configuredReserveIndex: UInt8 = 0
    }
}

extension WYContentScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if canRestartedTimer == true {
            startTimer()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        guard canScroll(offsetX) == true else {
            return
        }
        
        canSwitchedPage = (abs(offsetX - wy_width) >= wy_width)
        
        scrollDirection = offsetX > wy_width ? .left : (offsetX < wy_width ? .right : .none)
        
        if let contentDelegate = contentDelegate {
            contentDelegate.wy_contentScrollViewDidScroll?(self, offset: offsetX - wy_width, index: currentIndex)
        }
        
        if let handler = scrollHandler {
            handler(offsetX - wy_width, currentIndex);
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pauseScroll()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        pauseScroll()
    }
}

