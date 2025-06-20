//
//  WYBannerView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/4/13.
//  Copyright © 2021 官人. All rights reserved.
//
import UIKit
import Kingfisher

@objc public protocol WYBannerViewDelegate {
    
    /// 监控banner点击事件
    @objc optional func didClick(_ bannerView: WYBannerView, _ index: Int)
    
    /// 监控banner的轮播事件
    @objc optional func didScroll(_ bannerView: WYBannerView, _ offset: CGFloat, _ index: Int)
}

public class WYBannerView: UIView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    public weak var delegate: WYBannerViewDelegate?
    
    /**
     * 监控banner点击事件(也可以通过实现代理监听)
     *
     * @param handler 点击事件的block
     */
    public func didClick(handler: @escaping ((_ index: Int) -> Void)) {
        clickHandler = handler
    }
    
    /**
     * 监控banner的轮播事件(也可以通过实现代理监听)
     *
     * @param handler 轮播事件的block
     */
    public func didScroll(handler: @escaping ((_ offset: CGFloat, _ index: Int) -> Void)) {
        scrollHandler = handler
    }
    
    /**
     *  刷新/显示轮播图
     *
     *  @param images    轮播图片数组(支持UIImage、URL、String)
     */
    public func reload(images: [Any] = [], describes: [String] = []) {
        imageSource = images
        describeSource = describes
    }
    
    /**
     *  自动轮播时每一页停留时间，默认为3s，最少1s
     *  当设置的值小于1s时，则为默认值
     */
    public var standingTime: TimeInterval = 3
    
    /// 描述文本控件
    public var describeView: UILabel?
    
    /// 描述占位文本
    public var placeholderDescribe: String = ""
    
    /// 描述文本控件位置，默认底部居中
    public var describeViewPosition: CGRect = .zero {
        willSet {
            if let _ = objc_getAssociatedObject(self, WYAssociatedKeys.nextDescribeView) as? UILabel {
                describeView?.frame = CGRect(x: newValue.origin.x, y: newValue.origin.y, width: newValue.size.width, height: newValue.size.height)
                nextDescribeView?.frame = CGRect(x: newValue.origin.x, y: newValue.origin.y, width: newValue.size.width, height: newValue.size.height)
            }
        }
    }
    
    /// 占位图
    public var placeholderImage: UIImage = WYBannerView.getPlaceholderImage()
    
    /// 图片显示模式
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill {
        willSet {
            currentView?.contentMode = newValue
            nextView?.contentMode = newValue
        }
    }
    
    /// 只有一张图片时，是否需要支持滑动，默认false
    public var scrollForSinglePage: Bool = false
    
    /// 多张图片时，是否需要支持滑动，默认true
    public var scrollForMultiPage: Bool = true
    
    /// 只有一张图片时，是否需要隐藏PageControl，默认True
    public var pageControlHideForSingle: Bool = true
    
    /// pageControl 是否允许用户交互
    public var pageControlIsUserInteractionEnabled: Bool = true
    
    /**
     *  是否需要无限轮播，默认开启
     *  当设置false时，会强制设置automaticCarousel为false
     */
    public var unlimitedCarousel: Bool = true {
        willSet {
            if newValue == false {
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
    
    /// 分页控件原点位置，默认底部居中
    public var pageControlPosition: CGPoint = .zero {
        willSet {
            guard let pagecontrol: UIPageControl = objc_getAssociatedObject(self, WYAssociatedKeys.pageControl) as? UIPageControl else {
                return
            }
            let pageControlSize: CGSize = pagecontrol.size(forNumberOfPages: pagecontrol.numberOfPages)
            pagecontrol.frame = CGRect(x: newValue.x, y: newValue.y, width: pageControlSize.width, height: pageControlSize.height)
        }
    }
    
    /**
     *  设置分页控件指示器的颜色
     *  不设置则为系统默认
     *
     *  @param defaultColor    其他页码的颜色
     *  @param currentColor    当前页码的颜色
     */
    public func updatePageControl(defaultColor: UIColor, currentColor: UIColor) {
        pageControlSetting.defaultColor = defaultColor
        pageControlSetting.currentColor = currentColor
    }
    
    /**
     *  设置分页控件指示器的图片
     *  iOS14以前两个图片必须同时设置，否则设置无效，iOS14及以后可以只设置其中一张
     *  不设置则为系统默认
     *
     *  @param defaultImage    其他页码的图片
     *  @param currentImage    当前页码的图片
     */
    public func updatePageControl(defaultImage: UIImage? = nil, currentImage: UIImage? = nil) {
        pageControlSetting.currentImage = currentImage
        pageControlSetting.defaultImage = defaultImage
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
        if (((imageSource.count < 1)) || ((scrollForSinglePage == false) && (imageSource.count == 1)) || (unlimitedCarousel == false) || (automaticCarousel == false)) { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: (standingTime < 1) ? 3 : standingTime, repeats: true, block:{ [weak self] (timer: Timer) -> Void in
            self?.nextImage()
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
    
    /// 切换下一张图片
    @objc public func nextImage() {
        scrollView.setContentOffset(CGPoint(x: wy_width*2, y: 0), animated: true)
    }
    
    /// 切换上一张图片
    @objc public func lastImage() {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    /// 切换到指定下标处
    @objc public func switchImage(_ pageIndex: NSInteger) {
        
        guard pageIndex != currentIndex else {
            return
        }
        
        if pageIndex < currentIndex {
            currentIndex = (pageIndex + 1)
            lastImage()
        }else {
            currentIndex = (pageIndex - 1)
            nextImage()
        }
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

extension WYBannerView {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.isScrollEnabled = imageSource.count > 1 ? scrollForMultiPage : scrollForSinglePage
        pageControl.superview?.bringSubviewToFront(pageControl)
    }
    
    /// 滚动控件
    private var scrollView: UIScrollView {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.scrollView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let scrollview: UIScrollView = objc_getAssociatedObject(self, WYAssociatedKeys.scrollView) as? UIScrollView else {
                
                let scrollview = UIScrollView(frame: CGRect(x: 0, y: 0, width: wy_width, height: wy_height))
                scrollview.delegate = self
                scrollview.isPagingEnabled = true
                scrollview.showsHorizontalScrollIndicator = false
                scrollview.showsVerticalScrollIndicator = false
                scrollview.bounces = false
                scrollview.contentSize = CGSize(width: 3*wy_width, height: wy_height)
                scrollview.contentOffset = CGPoint(x: wy_width, y: 0)
                addSubview(scrollview)
                
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
                
                currentIndex = 0
                nextIndex = 0
                
                currentView = UIImageView(frame: CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height))
                currentView?.contentMode = imageContentMode
                currentView?.layer.masksToBounds = true
                scrollview.addSubview(currentView!)
                
                nextView = UIImageView(frame: CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height))
                nextView?.contentMode = imageContentMode
                nextView?.layer.masksToBounds = true
                scrollview.addSubview(nextView!)
                
                describeView = UILabel()
                describeView?.lineBreakMode = .byTruncatingTail
                describeView?.textAlignment = .center
                describeView?.font = .systemFont(ofSize: wy_screenWidth(15, WYBasisKitConfig.defaultScreenPixels))
                describeView?.textColor = .white
                describeView?.numberOfLines = 1
                describeView?.backgroundColor = .clear
                currentView?.addSubview(describeView!)
                
                nextDescribeView = UILabel()
                nextView?.addSubview(nextDescribeView!)
                
                if describeViewPosition == .zero {
                    describeViewPosition = CGRect(x: wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels), y: wy_height - describeView!.font.lineHeight - wy_screenWidth(30, WYBasisKitConfig.defaultScreenPixels), width: wy_width - (wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels) * 2), height: describeView!.font.lineHeight)
                }else {
                    describeViewPosition = CGRect(x: describeViewPosition.origin.x, y: describeViewPosition.origin.y, width: describeViewPosition.size.width, height: describeViewPosition.size.height)
                }
                
                setData(with: imageSource.first, describe: describeSource.first, imageView: currentView, textView: describeView)
                
                if automaticCarousel == true {
                    automaticCarousel = true
                }
                
                let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didClickBanner))
                    scrollview.addGestureRecognizer(gestureRecognizer)
                
                objc_setAssociatedObject(self, WYAssociatedKeys.scrollView, scrollview, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return scrollview
            }
            return scrollview
        }
    }
    
    /// 分页控件
    private var pageControl: UIPageControl {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.pageControl, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let pagecontrol: UIPageControl = objc_getAssociatedObject(self, WYAssociatedKeys.pageControl) as? UIPageControl else {
                
                let pagecontrol = UIPageControl()
                pagecontrol.hidesForSinglePage = pageControlHideForSingle
                pagecontrol.isUserInteractionEnabled = pageControlIsUserInteractionEnabled
                pagecontrol.currentPage = 0
                pagecontrol.addTarget(self, action: #selector(didClickPageControl(_:)), for: .valueChanged)
                pagecontrol.numberOfPages = imageSource.count
                if #available(iOS 14.0, *) {
                    pagecontrol.backgroundStyle = .minimal
                }
                addSubview(pagecontrol)
                
                objc_setAssociatedObject(self, WYAssociatedKeys.pageControl, pagecontrol, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                updatePageControlStyle()
                
                if pageControlPosition == .zero {
                    let pageControlSize: CGSize = pagecontrol.size(forNumberOfPages: pagecontrol.numberOfPages)
                    pageControlPosition = CGPoint(x: (wy_width - pageControlSize.width) / 2, y: wy_height - pageControlSize.height - wy_screenWidth(10))
                }else {
                    pageControlPosition = CGPoint(x: pageControlPosition.x, y: pageControlPosition.y)
                }
                
                return pagecontrol
            }
            return pagecontrol
        }
    }
    
    /// 当前banner
    private var currentView: UIImageView? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.currentView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.currentView) as? UIImageView
        }
    }
    
    /// 下一个banner
    private var nextView: UIImageView? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.nextView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.nextView) as? UIImageView
        }
    }
    
    /// 下一个描述文本控件
    private var nextDescribeView: UILabel? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.nextDescribeView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.nextDescribeView) as? UILabel
        }
    }
    
    /// 当前banner索引
    private var currentIndex: Int {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.currentIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.currentIndex) as? Int ?? 0
        }
    }
    
    /// 下一个banner索引
    private var nextIndex: Int {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.nextIndex, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.nextIndex) as? Int ?? 0
        }
    }
    
    /// 图片数据源
    private var imageSource: [Any] {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.imageSource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.imageSource) as? [Any] ?? []
        }
    }
    
    /// 描述文本数据源
    private var describeSource: [String] {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.describeSource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.describeSource) as? [String] ?? []
        }
    }
    
    /// 计时器
    private var timer: Timer? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.timer) as? Timer
        }
    }
    
    private enum WYBannerScrollDirection {
        /// 未滑动
        case none
        /// 向左滑动
        case left
        /// 向右滑动
        case right
    }
    
    /// 滚动方向
    private var scrollDirection: WYBannerScrollDirection {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.scrollDirection, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            // 向右滚动
            if newValue == .right {
                nextView?.frame = CGRect(x: 0, y: 0, width: wy_width, height: wy_height)
                nextIndex = currentIndex - 1
                if (nextIndex < 0) {
                    nextIndex = imageSource.count - 1
                }
            }
            // 向左滚动
            if newValue == .left {
                nextView?.frame = CGRect(x: 2 * wy_width, y: 0, width: wy_width, height: wy_height)
                nextIndex = (currentIndex + 1) % imageSource.count
            }
            
            var describeString: String?
            if (describeSource.isEmpty == false) && (describeSource.count > nextIndex) {
                describeString = describeSource[nextIndex]
            }
            
            setData(with: imageSource[nextIndex], describe: describeString, imageView: nextView, textView: nextDescribeView)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.scrollDirection) as? WYBannerScrollDirection ?? .none
        }
    }
    
    private func setData(with imageSource: Any?, describe: String? = nil, imageView: UIImageView?, textView: UILabel?) {
        
        if let imageUrl: URL = imageSource as? URL {
            imageView?.kf.setImage(with: URL(string: (imageUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")), placeholder: placeholderImage)
        }
        
        if let imageString: String = imageSource as? String {
            imageView?.kf.setImage(with: URL(string: (imageString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")), placeholder: placeholderImage)
        }
        
        if let image: UIImage = imageSource as? UIImage {
            imageView?.image = image
        }
        
        textView?.text = (describe?.isEmpty ?? true) ? placeholderDescribe : describe
        
        updatDescribeViewStyle()
    }
    
    /// 停止滚动
    func pauseScroll() {
        
        guard canSwitchedPage == true else {
            return
        }
        
        currentIndex = nextIndex
        pageControl.currentPage = currentIndex
        currentView?.frame = CGRect(x: wy_width, y: 0, width: wy_width, height: wy_height)
        
        var describeString: String?
        if (describeSource.isEmpty == false) && (describeSource.count > nextIndex) {
            describeString = describeSource[nextIndex]
        }
        
        setData(with: imageSource[nextIndex], describe:describeString, imageView: currentView, textView: describeView)
        scrollView.contentOffset = CGPoint(x: wy_width, y: 0)
        
        updatePageControlStyle()
    }
    
    private class func getPlaceholderImage() -> UIImage {
        guard let imageSource = UIImage(named: "wy_placeholder_" + WYLocalizableManager.currentLanguage().rawValue) ?? UIImage(named: "wy_placeholder_" + WYLanguage.english.rawValue) else {
            
            let resourcePath = ((Bundle(for: WYBannerView.self).path(forResource: "WYBannerView", ofType: "bundle")) ?? (Bundle.main.path(forResource: "WYBannerView", ofType: "bundle"))) ?? ""
            
            return (UIImage(named: "wy_placeholder_" + WYLocalizableManager.currentLanguage().rawValue, in: Bundle(path: resourcePath), compatibleWith: nil) ?? UIImage(named: "wy_placeholder_" + WYLanguage.english.rawValue, in: Bundle(path: resourcePath), compatibleWith: nil))!
        }
        return imageSource
    }
    
    /// 分页控制器设置选项
    private var pageControlSetting: (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.pageControlSetting, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.pageControlSetting) as? (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) ?? (currentColor: nil, defaultColor: nil, currentImage: nil, defaultImage: nil)
        }
    }
    
    /// 分页指示器点击事件
    @objc private func didClickPageControl(_ sender: UIPageControl) {
        
        stopTimer()
        
        switchImage(sender.currentPage)
        
        if canRestartedTimer == true {
            startTimer()
        }
    }
    
    /// 自定义设置文本描述控件样式
    private func updatDescribeViewStyle() {
        guard let describeview: UILabel = describeView else {
            return
        }
        nextDescribeView?.lineBreakMode = describeview.lineBreakMode
        nextDescribeView?.textAlignment = describeview.textAlignment
        nextDescribeView?.font = describeview.font
        nextDescribeView?.textColor = describeview.textColor
        nextDescribeView?.backgroundColor = describeview.backgroundColor
        nextDescribeView?.numberOfLines = describeview.numberOfLines
        nextDescribeView?.isHidden = describeview.isHidden
    }
    
    /// 自定义设置分页控件图片及颜色
    private func updatePageControlStyle() {
        
        if pageControl.hidesForSinglePage != pageControlHideForSingle {
            pageControl.hidesForSinglePage = pageControlHideForSingle
        }
        
        if let defaultColor: UIColor = pageControlSetting.defaultColor {
            pageControl.pageIndicatorTintColor = defaultColor
            pageControlSetting.defaultColor = nil
        }
        if let currentColor: UIColor = pageControlSetting.currentColor {
            pageControl.currentPageIndicatorTintColor = currentColor
            pageControlSetting.currentColor = nil
        }
        
        if #available(iOS 14.0, *) {
            if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
                for page: Int in 0..<pageControl.numberOfPages {
                    pageControl.setIndicatorImage(page == pageControl.currentPage ? currentImage : defaultImage, forPage: page)
                }
            }else {
                if let defaultImage: UIImage = pageControlSetting.defaultImage {
                    pageControl.preferredIndicatorImage = defaultImage
                    pageControlSetting.defaultImage = nil
                }
                
                if let currentImage: UIImage = pageControlSetting.currentImage {
                    pageControl.preferredIndicatorImage = currentImage
                    pageControlSetting.currentImage = nil
                }
            }
            
        }else {
            if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
                pageControl.setValue(defaultImage, forKey: "_pageImage")
                pageControl.setValue(currentImage, forKey: "_currentPageImage")
                pageControlSetting.defaultImage = nil
                pageControlSetting.currentImage = nil
            }
        }
    }
    
    /// 判断是否可以滚动
    private func canScroll(_ offsetX: CGFloat) -> Bool {
        if (unlimitedCarousel == false) && (((offsetX < wy_width) && (pageControl.currentPage == 0)) || ((offsetX > wy_width) && (pageControl.currentPage == (pageControl.numberOfPages - 1)))) {
            scrollView.contentOffset = CGPoint(x: wy_width, y: 0)
            return false
        }
        return true
    }
    
    /// 判断手动拖拽后是否需要启动定时器
    private var canRestartedTimer: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.canRestartedTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.canRestartedTimer) as? Bool ?? false
        }
    }
    
    /// block点击事件
    private var clickHandler: ((_ index: Int) -> Void)? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.clickHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.clickHandler) as? (Int) -> Void
        }
    }
    
    /// block轮播事件
    private var scrollHandler: ((_ offset: CGFloat, _ index: Int) -> Void)? {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.scrollHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.scrollHandler) as? (CGFloat, Int) -> Void
        }
    }
    
    /// 点击了Banner控件
    @objc func didClickBanner() {
        if let delegate = delegate {
            delegate.didClick?(self, currentIndex)
        }
        
        if let handler = clickHandler {
            handler(currentIndex)
        }
    }
    
    /// 判断是否可以切换页面
    private var canSwitchedPage: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.canSwitchedPage, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.canSwitchedPage) as? Bool ?? false
        }
    }
    
    private struct WYAssociatedKeys {
        static let scrollView = UnsafeRawPointer(bitPattern: "scrollView".hashValue)!
        static let pageControl = UnsafeRawPointer(bitPattern: "pageControl".hashValue)!
        static let currentView = UnsafeRawPointer(bitPattern: "currentView".hashValue)!
        static let nextView = UnsafeRawPointer(bitPattern: "nextView".hashValue)!
        static let nextDescribeView = UnsafeRawPointer(bitPattern: "nextDescribeView".hashValue)!
        static let currentIndex = UnsafeRawPointer(bitPattern: "currentIndex".hashValue)!
        static let nextIndex = UnsafeRawPointer(bitPattern: "nextIndex".hashValue)!
        static let imageSource = UnsafeRawPointer(bitPattern: "imageSource".hashValue)!
        static let describeSource = UnsafeRawPointer(bitPattern: "describeSource".hashValue)!
        static let timer = UnsafeRawPointer(bitPattern: "timer".hashValue)!
        static let scrollDirection = UnsafeRawPointer(bitPattern: "scrollDirection".hashValue)!
        static let pageControlSetting = UnsafeRawPointer(bitPattern: "pageControlSetting".hashValue)!
        static let canRestartedTimer = UnsafeRawPointer(bitPattern: "canRestartedTimer".hashValue)!
        static let clickHandler = UnsafeRawPointer(bitPattern: "clickHandler".hashValue)!
        static let scrollHandler = UnsafeRawPointer(bitPattern: "scrollHandler".hashValue)!
        static let canSwitchedPage = UnsafeRawPointer(bitPattern: "canSwitchedPage".hashValue)!
    }
}

extension WYBannerView: UIScrollViewDelegate {
    
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
        
        if let delegate = delegate {
            delegate.didScroll?(self, offsetX - wy_width, currentIndex)
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
