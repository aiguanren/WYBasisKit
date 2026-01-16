//
//  WYPagingViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/6.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif
    
@objc public extension WYPagingView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    @objc(delegate)
    weak var delegateObjC: WYPagingViewDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /**
     * 点击或滚动事件(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    @objc(itemDidScroll:)
    func itemDidScrollObjC(handler: @escaping ((_ pagingIndex: Int) -> Void)) {
        itemDidScroll(handler: handler)
    }

    /// 分页栏的高度 默认45
    @objc(bar_Height)
    var bar_HeightObjC: CGFloat {
        get { return bar_Height }
        set { bar_Height = newValue }
    }
    
    /// 图片和文字显示模式
    @objc(buttonPosition)
    var buttonPositionObjC: WYButtonPositionObjC {
        get { return WYButtonPositionObjC(rawValue: buttonPosition.rawValue) ?? .imageLeftTitleRight }
        set { buttonPosition = WYButtonPosition(rawValue: newValue.rawValue) ?? .imageLeftTitleRight }
    }

    /// 分页栏左起始点距离(第一个标题栏距离屏幕边界的距离) 默认0
    @objc(bar_originlLeftOffset)
    var bar_originlLeftOffsetObjC: CGFloat {
        get { return bar_originlLeftOffset }
        set { bar_originlLeftOffset = newValue }
    }

    /// 分页栏右起始点距离(最后一个标题栏距离屏幕边界的距离) 默认0
    @objc(bar_originlRightOffset)
    var bar_originlRightOffsetObjC: CGFloat {
        get { return bar_originlRightOffset }
        set { bar_originlRightOffset = newValue }
    }
    
    /// item距离分页栏顶部的偏移量(需要设置bar_item_height后才会生效)， 默认0(默认0时会强制转为nil传给swift)，如需传入0则传入0.01等具体值
    @objc(bar_itemTopOffset)
    var bar_itemTopOffsetObjC: CGFloat {
        get { return bar_itemTopOffset ?? 0 }
        set {
            bar_itemTopOffset = newValue > 0 ? newValue : nil
        }
    }
    
    /// 显示整体宽度小于一屏，且设置了bar_Width != 0，是否需要居中显示，默认 居中 (居中后，将会动态调整bar_originlLeftOffset和bar_originlRightOffset的距离)
    @objc(bar_adjustOffset)
    var bar_adjustOffsetObjC: Bool {
        get { return bar_adjustOffset }
        set { bar_adjustOffset = newValue }
    }

    /// 左右分页栏之间的间距，默认20像素
    @objc(bar_dividingOffset)
    var bar_dividingOffsetObjC: CGFloat {
        get { return bar_dividingOffset }
        set { bar_dividingOffset = newValue }
    }

    /// 内部按钮图片和文字的上下或左右间距 默认5
    @objc(barButton_dividingOffset)
    var barButton_dividingOffsetObjC: CGFloat {
        get { return barButton_dividingOffset }
        set { barButton_dividingOffset = newValue }
    }
    
    /// 分页控制器底部背景色(即分页控制器所在的scrollView的背景色) 默认白色
    @objc(bar_pagingContro_content_color)
    var bar_pagingContro_content_colorObjC: UIColor {
        get { return bar_pagingContro_content_color }
        set { bar_pagingContro_content_color = newValue }
    }
    
    /// 分页控制器背景色
    @objc(bar_pagingContro_bg_color)
    var bar_pagingContro_bg_colorObjC: UIColor? {
        get { return bar_pagingContro_bg_color }
        set { bar_pagingContro_bg_color = newValue }
    }
    
    /// 分页控制器是否需要弹跳效果
    @objc(bar_pagingContro_bounce)
    var bar_pagingContro_bounceObjC: Bool {
        get { return bar_pagingContro_bounce }
        set { bar_pagingContro_bounce = newValue }
    }
    
    /// 分页栏默认背景色 默认白色
    @objc(bar_bg_defaultColor)
    var bar_bg_defaultColorObjC: UIColor {
        get { return bar_bg_defaultColor }
        set { bar_bg_defaultColor = newValue }
    }
    
    /// 分页栏Item宽度 默认对应每页标题文本宽度(若传入则整体使用传入宽度)
    @objc(bar_item_width)
    var bar_item_widthObjC: CGFloat {
        get { return bar_item_width }
        set { bar_item_width = newValue }
    }
    
    /// 分页栏Item高度 默认bar_Height-bar_dividingStripHeight(若传入则整体使用传入高度)
    @objc(bar_item_height)
    var bar_item_heightObjC: CGFloat {
        get { return bar_item_height }
        set { bar_item_height = newValue }
    }
    
    /// 分页栏Item在约束size的基础上追加传入的size大小，默认.zero(高度等于bar_Height)
    @objc(bar_item_appendSize)
    var bar_item_appendSizeObjC: CGSize {
        get { return bar_item_appendSize }
        set { bar_item_appendSize = newValue }
    }

    /// 分页栏item默认背景色 默认白色
    @objc(bar_item_bg_defaultColor)
    var bar_item_bg_defaultColorObjC: UIColor {
        get { return bar_item_bg_defaultColor }
        set { bar_item_bg_defaultColor = newValue }
    }

    /// 分页栏item选中背景色 默认白色
    @objc(bar_item_bg_selectedColor)
    var bar_item_bg_selectedColorObjC: UIColor {
        get { return bar_item_bg_selectedColor }
        set { bar_item_bg_selectedColor = newValue }
    }
    
    /// 分页栏item圆角半径, 默认0
    @objc(bar_item_cornerRadius)
    var bar_item_cornerRadiusObjC: CGFloat {
        get { return bar_item_cornerRadius }
        set { bar_item_cornerRadius = newValue }
    }

    /// 分页栏标题默认颜色 默认<#7B809E>
    @objc(bar_title_defaultColor)
    var bar_title_defaultColorObjC: UIColor {
        get { return bar_title_defaultColor }
        set { bar_title_defaultColor = newValue }
    }

    /// 分页栏标题选中颜色 默认<#2D3952>
    @objc(bar_title_selectedColor)
    var bar_title_selectedColorObjC: UIColor {
        get { return bar_title_selectedColor }
        set { bar_title_selectedColor = newValue }
    }

    /// 分页栏底部分隔带背景色 默认<#F2F2F2>
    @objc(bar_dividingStripColor)
    var bar_dividingStripColorObjC: UIColor {
        get { return bar_dividingStripColor }
        set { bar_dividingStripColor = newValue }
    }
    
    /// 分页栏底部分隔带背景图 默认为空
    @objc(bar_dividingStripImage)
    var bar_dividingStripImageObjC: UIImage? {
        get { return bar_dividingStripImage }
        set { bar_dividingStripImage = newValue }
    }

    /// 滑动线条背景色 默认<#2D3952>
    @objc(bar_scrollLineColor)
    var bar_scrollLineColorObjC: UIColor {
        get { return bar_scrollLineColor }
        set { bar_scrollLineColor = newValue }
    }
    
    /// 滑动线条背景图 默认为空
    @objc(bar_scrollLineImage)
    var bar_scrollLineImageObjC: UIImage? {
        get { return bar_scrollLineImage }
        set { bar_scrollLineImage = newValue }
    }

    /// 滑动线条宽度 默认25像素
    @objc(bar_scrollLineWidth)
    var bar_scrollLineWidthObjC: CGFloat {
        get { return bar_scrollLineWidth }
        set { bar_scrollLineWidth = newValue }
    }

    /// 滑动线条距离分页栏底部的距离 默认5像素
    @objc(bar_scrollLineBottomOffset)
    var bar_scrollLineBottomOffsetObjC: CGFloat {
        get { return bar_scrollLineBottomOffset }
        set { bar_scrollLineBottomOffset = newValue }
    }

    /// 分隔带高度 默认2像素
    @objc(bar_dividingStripHeight)
    var bar_dividingStripHeightObjC: CGFloat {
        get { return bar_dividingStripHeight }
        set { bar_dividingStripHeight = newValue }
    }

    /// 滑动线条高度 默认2像素
    @objc(bar_scrollLineHeight)
    var bar_scrollLineHeightObjC: CGFloat {
        get { return bar_scrollLineHeight }
        set { bar_scrollLineHeight = newValue }
    }

    /// 分页栏标题默认字号 默认15号；
    @objc(bar_title_defaultFont)
    var bar_title_defaultFontObjC: UIFont {
        get { return bar_title_defaultFont }
        set { bar_title_defaultFont = newValue }
    }

    /// 分页栏标题选中字号 默认15号；
    @objc(bar_title_selectedFont)
    var bar_title_selectedFontObjC: UIFont {
        get { return bar_title_selectedFont }
        set { bar_title_selectedFont = newValue }
    }

    /// 初始选中第几项  默认第一项
    @objc(bar_selectedIndex)
    var bar_selectedIndexObjC: Int {
        get { return bar_selectedIndex }
        set { bar_selectedIndex = newValue }
    }
    
    /// 控制器是否需要左右滑动(默认支持)
    @objc(canScrollController)
    var canScrollControllerObjC: Bool {
        get { return canScrollController }
        set { canScrollController = newValue }
    }
    
    /// 分页栏是否需要左右滑动(默认支持)
    @objc(canScrollBar)
    var canScrollBarObjC: Bool {
        get { return canScrollBar }
        set { canScrollBar = newValue }
    }
    
    /// 传入的控制器数组
    @objc(controllers)
    var controllersObjC: [UIViewController] {
        return controllers
    }
    
    /// 传入的标题数组
    @objc(titles)
    var titlesObjC: [String] {
        return titles
    }
    
    /// 传入的未选中的图片数组
    @objc(defaultImages)
    var defaultImagesObjC: [UIImage] {
        return defaultImages
    }
    
    /// 传入的选中的图片数组
    @objc(selectedImages)
    var selectedImagesObjC: [UIImage] {
        return selectedImages
    }
    
    /// 按钮栏所有按钮组件
    @objc(buttonItems)
    var buttonItemsObjC: [WYPagingItem] {
        return buttonItems
    }
    
    /// 传入的父控制器
    @objc(superController)
    weak var superControllerObjC: UIViewController? {
        return superController
    }
    
    /**
     *调用后开始布局
     *
     * @param controllers 控制器数组
     * @param titles 标题数组
     * @param defaultImages 未选中状态图片数组(可不传)
     * @param selectedImages 选中状态图片数组(可不传)
     * @param superViewController 父控制器
     */
    @objc(layoutWithControllers:titles:defaultImages:selectedImages:superViewController:)
    func layoutObjC(controllers: [UIViewController], titles: [String]?, defaultImages: [UIImage]?, selectedImages: [UIImage]?, superViewController: UIViewController) {
        layout(controllers: controllers, titles: titles ?? [], defaultImages: defaultImages ?? [], selectedImages: selectedImages ?? [], superViewController: superViewController)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
