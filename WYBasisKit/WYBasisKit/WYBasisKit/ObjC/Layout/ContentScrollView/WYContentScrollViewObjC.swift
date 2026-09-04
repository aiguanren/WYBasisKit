//
//  WYContentScrollViewObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/1.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

#if canImport(WYBasisKitSwift)

import WYBasisKitSwift

@objc public extension WYContentScrollView {

    /// 滑动事件代理
    @objc(contentDelegate)
    public weak var contentDelegateObjC: WYContentScrollViewDelegate? {
        get { return contentDelegate }
        set { contentDelegate = newValue }
    }

    /// 水平方向内容页视图数量（Int.max表示无限数量）
    @objc(numberOfHorizontalContent)
    public var numberOfHorizontalContentObjC: Int {
        get { return numberOfHorizontalContent }
        set { numberOfHorizontalContent = newValue }
    }

    /// 垂直方向内容页视图数量（Int.max表示无限数量）
    @objc(numberOfVerticalContent)
    public var numberOfVerticalContentObjC: Int {
        get { return numberOfVerticalContent }
        set { numberOfVerticalContent = newValue }
    }

    /// 支持的滑动方向
    @objc(contentSlidingDirection)
    public var contentSlidingDirectionObjC: WYContentSlidingDirection {
        get { return contentSlidingDirection }
        set { contentSlidingDirection = newValue }
    }

    /// 当前正在水平方向显示的Views(用户传入的View)
    @objc(horizontalViews)
    public var horizontalViewsObjC: [UIView]? {
        return horizontalViews
    }

    /// 当前正在垂直方向显示的Views(用户传入的View)
    @objc(verticalViews)
    public var verticalViewsObjC: [UIView]? {
        return verticalViews
    }

    /// 当前水平方向内容页索引
    @objc(currentHorizontalIndex)
    public var currentHorizontalIndexObjC: Int {
        return currentHorizontalIndex
    }

    /// 水平方向储备内容页索引
    @objc(reserveHorizontalIndex)
    public var reserveHorizontalIndexObjC: Int {
        return reserveHorizontalIndex
    }

    /// 当前垂直方向内容页索引
    @objc(currentVerticalIndex)
    public var currentVerticalIndexObjC: Int {
        return currentVerticalIndex
    }

    /// 垂直方向储备内容页索引
    @objc(reserveVerticalIndex)
    public var reserveVerticalIndexObjC: Int {
        return reserveVerticalIndex
    }

    /// 自动轮播时每一页停留时间，默认为3s，最少1s(当设置的值小于1s时，则为默认值，同时修改值后会立即生效)；
    @objc(standingTime)
    public var standingTimeObjC: TimeInterval {
        get { return standingTime }
        set { standingTime = newValue }
    }

    /// 轻扫跨轴直切的速度阈值(单位：pt/s，默认500，范围限制50 - 3000，仅影响全向模式的轻扫跨轴判定，同轴翻页不经过此阈值，值越低越灵敏，越高越保守)
    @objc(crossAxisFlickVelocityThreshold)
    public var crossAxisFlickVelocityThresholdObjC: CGFloat {
        get { return crossAxisFlickVelocityThreshold }
        set { crossAxisFlickVelocityThreshold = newValue }
    }

    /// 跨轴切换(换方向)的呈现样式，默认.instant，作用于跨轴API切换与轻扫直切，同轴切换不受影响
    @objc(crossAxisSwitchStyle)
    public var crossAxisSwitchStyleObjC: WYContentSwitchStyle {
        get { return crossAxisSwitchStyle }
        set { crossAxisSwitchStyle = newValue }
    }

    /// 跨轴切换动画时长(单位：秒)，默认0.25s，钳制范围[0.1, 2.0]，仅.slide/.fade/.zoom生效
    @objc(crossAxisSwitchDuration)
    public var crossAxisSwitchDurationObjC: TimeInterval {
        get { return crossAxisSwitchDuration }
        set { crossAxisSwitchDuration = newValue }
    }

    /// 缩放切入(.zoom)的缩放比例，默认1.15，钳制范围[1.0, 2.0]，仅.zoom生效
    @objc(crossAxisSwitchZoomScale)
    public var crossAxisSwitchZoomScaleObjC: CGFloat {
        get { return crossAxisSwitchZoomScale }
        set { crossAxisSwitchZoomScale = newValue }
    }

    /// 水平方向是否支持滑动(仅内容页数量大于1时生效)，默认true；仅拦截手势，API切换与轮播不受影响
    @objc(horizontalSliderEnabled)
    public var horizontalSliderEnabledObjC: Bool {
        get { return horizontalSliderEnabled }
        set { horizontalSliderEnabled = newValue }
    }

    /// 垂直方向是否支持滑动(仅内容页数量大于1时生效)，默认true；仅拦截手势，API切换与轮播不受影响
    @objc(verticalSliderEnabled)
    public var verticalSliderEnabledObjC: Bool {
        get { return verticalSliderEnabled }
        set { verticalSliderEnabled = newValue }
    }

    /// 水平方向同轴翻页的最小时间间隔(单位：秒，默认0不限制，负数按0处理)，手势翻页提交后间隔内的新同轴拖动无效，跨轴切换与API切换不受影响
    @objc(horizontalMinimumSwitchInterval)
    public var horizontalMinimumSwitchIntervalObjC: TimeInterval {
        get { return horizontalMinimumSwitchInterval }
        set { horizontalMinimumSwitchInterval = newValue }
    }

    /// 垂直方向同轴翻页的最小时间间隔(单位：秒，默认0不限制，负数按0处理)，手势翻页提交后间隔内的新同轴拖动无效，跨轴切换与API切换不受影响
    @objc(verticalMinimumSwitchInterval)
    public var verticalMinimumSwitchIntervalObjC: TimeInterval {
        get { return verticalMinimumSwitchInterval }
        set { verticalMinimumSwitchInterval = newValue }
    }

    /// 水平方向是否无限翻页(末页/首页环绕到另一端)，默认true；展示轴关闭本开关时轮播随之停止
    @objc(horizontalUnlimitedCarousel)
    public var horizontalUnlimitedCarouselObjC: Bool {
        get { return horizontalUnlimitedCarousel }
        set { horizontalUnlimitedCarousel = newValue }
    }

    /// 垂直方向是否无限翻页(末页/首页环绕到另一端)，默认true；展示轴关闭本开关时轮播随之停止
    @objc(verticalUnlimitedCarousel)
    public var verticalUnlimitedCarouselObjC: Bool {
        get { return verticalUnlimitedCarousel }
        set { verticalUnlimitedCarousel = newValue }
    }

    /// 是否需要自动轮播，默认false；开启后首次展示自动开始轮播，运行中修改即时生效(关闭就停、再开继续播)
    @objc(automaticCarousel)
    public var automaticCarouselObjC: Bool {
        get { return automaticCarousel }
        set { automaticCarousel = newValue }
    }

    /// 设置需要显示的自定义View(contentSlidingDirection != omnidirectional 时调用)，currentView 为正在显示的View、reserveView 为预备显示的View，两者Size都将等于当前WYContentScrollView的Size
    @objc(horizontalOrVerticalDisplayWithCurrentView:reserveView:)
    public func horizontalOrVerticalDisplayObjC(currentView: UIView, reserveView: UIView) {
        horizontalOrVerticalDisplay(currentView: currentView, reserveView: reserveView)
    }

    /// 设置需要显示的自定义View(contentSlidingDirection == omnidirectional 时调用)，水平/垂直方向各需 current(正在显示)与 reserve(预备显示)两个View，Size都将等于当前WYContentScrollView的Size
    @objc(omnidirectionalDisplayWithCurrentHorizontalView:reserveHorizontalView:currentVerticalView:reserveVerticalView:)
    public func omnidirectionalDisplayObjC(currentHorizontalView: UIView, reserveHorizontalView: UIView, currentVerticalView: UIView, reserveVerticalView: UIView) {
        omnidirectionalDisplay(currentHorizontalView: currentHorizontalView, reserveHorizontalView: reserveHorizontalView, currentVerticalView: currentVerticalView, reserveVerticalView: reserveVerticalView)
    }

    /// 当contentSlidingDirection == .omnidirectional时，优先支持哪个滑动方向，默认左右滑动(不支持设置为.omnidirectional)
    @objc(prioritySlidingDirection)
    public var prioritySlidingDirectionObjC: WYContentSlidingDirection {
        get { return prioritySlidingDirection }
        set { prioritySlidingDirection = newValue }
    }

    /// 开启定时器(默认开启，调用该方法会重新开启)
    @objc(startTimer)
    public func startTimerObjC() {
        startTimer()
    }

    /// 停止定时器
    @objc(stopTimer)
    public func stopTimerObjC() {
        stopTimer()
    }

    /// 切换指定方向下一个内容页面(不支持直接传入direction为omnidirectional)
    @objc(nextContent:)
    public func nextContentObjC(_ direction: WYContentSlidingDirection) {
        nextContent(direction)
    }

    /// 切换指定方向上一个内容页面(不支持直接传入direction为omnidirectional)
    @objc(lastContent:)
    public func lastContentObjC(_ direction: WYContentSlidingDirection) {
        lastContent(direction)
    }

    /// 切换到指定方向指定下标处(不支持direction为omnidirectional)
    @objc(switchContent:index:)
    public func switchContentObjC(_ direction: WYContentSlidingDirection, index: UnsafeMutablePointer<Int>) {
        switchContent(direction, index: &index.pointee)
    }
}

#endif
