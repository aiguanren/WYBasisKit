//
//  WYBannerView.swift
//  WYBasisKit
//
//  Created by 官人 on 2025/10/5.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

@objc public extension WYBannerView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    @objc(delegate)
    weak var delegateObjC: WYBannerViewDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /**
     * 监控banner点击事件(也可以通过实现代理监听)
     *
     * @param handler 点击事件的block
     */
    @objc(didClick:)
    func didClickObjC(handler: @escaping ((_ index: Int) -> Void)) {
        didClick(handler: handler)
    }
    
    /**
     * 监控banner的轮播事件(也可以通过实现代理监听)
     *
     * @param handler 轮播事件的block
     */
    @objc(didScroll:)
    func didScrollObjC(handler: @escaping ((_ offset: CGFloat, _ index: Int) -> Void)) {
        didScroll(handler: handler)
    }
    
    /**
     *  刷新/显示轮播图
     *
     *  @param images    轮播图片数组(支持UIImage、URL、String)
     */
    @objc(reloadImages:describes:)
    func reloadObjC(images: [Any] = [], describes: [String]? = nil) {
        reload(images: images, describes: describes ?? [])
    }
    
    /**
     *  自动轮播时每一页停留时间，默认为3s，最少1s
     *  当设置的值小于1s时，则为默认值
     */
    @objc(standingTime)
    var standingTimeObjC: TimeInterval {
        get { return standingTime }
        set { standingTime = newValue }
    }
    
    /// 描述文本控件
    @objc(describeView)
    var describeViewObjC: UILabel? {
        get { return describeView }
        set { describeView = newValue }
    }
    
    /// 描述占位文本
    @objc(placeholderDescribe)
    var placeholderDescribeObjC: String {
        get { return placeholderDescribe }
        set { placeholderDescribe = newValue }
    }
    
    /// 描述文本控件位置，默认底部居中
    @objc(describeViewPosition)
    var describeViewPositionObjC: CGRect {
        get { return describeViewPosition }
        set { describeViewPosition = newValue }
    }
    
    /// 占位图
    @objc(placeholderImage)
    var placeholderImageObjC: UIImage {
        get { return placeholderImage }
        set { placeholderImage = newValue }
    }
    
    /// 图片显示模式
    @objc(imageContentMode)
    var imageContentModeObjC: UIView.ContentMode {
        get { return imageContentMode }
        set { imageContentMode = newValue }
    }
    
    /// 只有一张图片时，是否需要支持滑动，默认false
    @objc(scrollForSinglePage)
    var scrollForSinglePageObjC: Bool {
        get { return scrollForSinglePage }
        set { scrollForSinglePage = newValue }
    }
    
    /// 多张图片时，是否需要支持滑动，默认true
    @objc(scrollForMultiPage)
    var scrollForMultiPageObjC: Bool {
        get { return scrollForMultiPage }
        set { scrollForMultiPage = newValue }
    }
    
    /// 只有一张图片时，是否需要隐藏PageControl，默认True
    @objc(pageControlHideForSingle)
    var pageControlHideForSingleObjC: Bool {
        get { return pageControlHideForSingle }
        set { pageControlHideForSingle = newValue }
    }
    
    /// pageControl 是否允许用户交互
    @objc(pageControlIsUserInteractionEnabled)
    var pageControlIsUserInteractionEnabledObjC: Bool {
        get { return pageControlIsUserInteractionEnabled }
        set { pageControlIsUserInteractionEnabled = newValue }
    }
    
    /**
     *  是否需要无限轮播，默认开启
     *  当设置false时，会强制设置automaticCarousel为false
     */
    @objc(unlimitedCarousel)
    var unlimitedCarouselObjC: Bool {
        get { return unlimitedCarousel }
        set { unlimitedCarousel = newValue }
    }
    
    /**
     *  是否需要自动轮播，默认开启
     *  当设置false时，会关闭定时器
     *  当设置true时，unlimitedCarousel会强制设置为True
     */
    @objc(automaticCarousel)
    var automaticCarouselObjC: Bool {
        get { return automaticCarousel }
        set { automaticCarousel = newValue }
    }
    
    /// 分页控件原点位置，默认底部居中
    @objc(pageControlPosition)
    var pageControlPositionObjC: CGPoint {
        get { return pageControlPosition }
        set { pageControlPosition = newValue }
    }
    
    /**
     *  设置分页控件指示器的颜色
     *  不设置则为系统默认
     *
     *  @param defaultColor    其他页码的颜色
     *  @param currentColor    当前页码的颜色
     */
    @objc(updatePageControlDefaultColor:currentColor:)
    func updatePageControlObjC(defaultColor: UIColor, currentColor: UIColor) {
        updatePageControl(defaultColor: defaultColor, currentColor: currentColor)
    }
    
    /**
     *  设置分页控件指示器的图片
     *  iOS14以前两个图片必须同时设置，否则设置无效，iOS14及以后可以只设置其中一张
     *  不设置则为系统默认
     *
     *  @param defaultImage    其他页码的图片
     *  @param currentImage    当前页码的图片
     */
    @objc(updatePageControlDefaultImage:currentImage:)
    func updatePageControlObjC(defaultImage: UIImage? = nil, currentImage: UIImage? = nil) {
        updatePageControl(defaultImage: defaultImage, currentImage: currentImage)
    }
    
    /**
     *  开启定时器
     *  默认开启，调用该方法会重新开启
     */
    @objc(startTimer)
    func startTimerObjC() {
        startTimer()
    }
    
    /**
     *  停止定时器
     *  滚动视图将不再自动轮播
     */
    @objc(stopTimer)
    func stopTimerObjC() {
        stopTimer()
    }
    
    /// 取消所有下载任务
    @objc(cancelAllDownloads)
    func cancelAllDownloadsObjC() {
        cancelAllDownloads()
    }
    
    /// 切换下一张图片
    @objc(nextImage)
    func nextImageObjC() {
        nextImage()
    }
    
    /// 切换上一张图片
    @objc(lastImage)
    func lastImageObjC() {
        lastImage()
    }
    
    /// 切换到指定下标处
    @objc(switchImageToIndex:)
    func switchImageObjC(_ pageIndex: Int) {
        switchImage(pageIndex)
    }
    
    /// 根据图片url获取缓存图片
    @objc(cacheImageFromUrlString:)
    func cacheImageObjC(_ urlString: String) -> UIImage? {
        return cacheImage(urlString)
    }
    
    /// 获取缓存大小的可读字符串，例如 "1.2 MB"
    @objc(cacheSizeString)
    func cacheSizeStringObjC() -> String {
        return cacheSizeString()
    }
    
    /// 获取缓存目录下所有文件的总大小（单位：字节）
    @objc(cacheSize)
    func cacheSizeObjC() -> UInt64 {
        return cacheSize()
    }
    
    /// 清空缓存目录
    @objc(clearDiskCache)
    func clearDiskCacheObjC() {
        clearDiskCache()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}
