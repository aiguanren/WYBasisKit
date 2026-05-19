//
//  WYPagingView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/7.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// delegate回调
@objc public protocol WYPagingViewDelegate {
    
    /**
     * Controller页面(Item)切换回调
     *
     * @param pagingView        当前WYPagingView的实例对象
     * @param pagingIndex       当前Controller在WYPagingView中的页面下标
     * @param isFirstDisplayed       当前Controller是否是第一次在WYPagingView中显示(可用来判断网络请求或页面UI加载时机，避免初始化WYPagingView时就请求所有的Controller的页面数据或者加载UI)，true表示第一次显示，否则为第二次及以后
     */
    @objc(wy_pagingViewItemDidScroll:pagingIndex:displayed:)
    optional func wy_pagingViewItemDidScroll(_ pagingView: WYPagingView, pagingIndex: Int, isFirstDisplayed: Bool)
    
    /**
     * PagingView页面布局完成
     *
     * @param pagingView 当前WYPagingView的实例对象
     */
    @objc(wy_pagingViewLayoutDidCompleted:)
    optional func wy_pagingViewLayoutDidCompleted(_ pagingView: WYPagingView)
}

public class WYPagingView: UIView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    public weak var delegate: WYPagingViewDelegate?
    
    /**
     * 点击或滚动事件(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    public func itemDidScroll(handler: @escaping ((_ pagingView: WYPagingView, _ pagingIndex: Int, _ isFirstDisplayed: Bool) -> Void)) {
        clickOrScrollHandler = handler
    }
    
    /**
     * PagingView页面布局完成(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    public func itemDidLayout(handler: @escaping ((_ pagingView: WYPagingView) -> Void)) {
        itemDidLayoutHandler = handler
    }
    
    /// 分页栏的高度 默认45
    public var bar_height: CGFloat = UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels)
    
    /// 图片和文字显示模式
    public var buttonPosition: WYButtonPosition = .imageLeftTitleRight
    
    /// 分页栏左起始点距离(第一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlLeftOffset: CGFloat = 0
    
    /// 分页栏右起始点距离(最后一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlRightOffset: CGFloat = 0
    
    /// item距离分页栏顶部的偏移量，默认nil
    public var bar_itemTopOffset: CGFloat? = nil
    
    /// 显示整体宽度小于一屏，且设置了bar_Width != 0，是否需要居中显示，默认 居中 (居中后，将会动态调整bar_originlLeftOffset和bar_originlRightOffset的距离)
    public var bar_adjustOffset: Bool = true
    
    /// 左右分页栏之间的间距，默认20像素
    public var bar_dividingOffset: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)
    
    /// 内部按钮图片和文字的上下或左右间距 默认5
    public var barButton_dividingOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
    /// 分页控制器底部背景色(即分页控制器所在的scrollView的背景色) 默认白色
    public var bar_pagingContro_content_color: UIColor = .white
    
    /// 分页控制器背景色
    public var bar_pagingContro_bg_color: UIColor? = nil
    
    /// 分页控制器是否需要弹跳效果
    public var bar_pagingContro_bounce: Bool = true
    
    /// 分页栏默认背景色 默认白色
    public var bar_bg_defaultColor: UIColor = .white
    
    /// 分页栏Item宽度 默认对应每页标题文本宽度(若传入则整体使用传入宽度)
    public var bar_item_width: CGFloat = 0
    
    /// 分页栏Item高度 默认bar_height-bar_dividingStripHeight(若传入则整体使用传入高度)
    public var bar_item_height: CGFloat = 0
    
    /// 分页栏Item按钮内边距，默认.zero(如果bar_item_width和bar_item_height没传入的话，内部会智能调整)
    public var bar_item_insideMargins: UIEdgeInsets = .zero
    
    /// 分页栏Item按钮内部imageView大小Size，默认.zero(图片本身Size)，仅图文混排时生效，只有图片时可通过bar_item_insideMargins来控制其Size
    public var bar_item_imageViewSize: CGSize = .zero
    
    /// 分页栏item圆角半径, 默认0
    public var bar_item_cornerRadius: CGFloat = 0
    
    /// 分页栏item边框宽度, 默认0
    public var bar_item_borderWidth: CGFloat = 0
    
    /// 分页栏item Normal状态 边框颜色
    public var bar_item_normalBorderColor: UIColor?
    
    /// 分页栏item Selected状态 边框颜色
    public var bar_item_selectedBorderColor: UIColor?
    
    /// 分页栏item Normal状态 背景色 默认透明
    public var bar_item_bg_defaultColor: UIColor = .clear
    
    /// 分页栏item Selected状态 背景色 默认透明
    public var bar_item_bg_selectedColor: UIColor = .clear
    
    /// 分页栏标题 Normal状态 颜色 默认<#7B809E>
    public var bar_title_defaultColor: UIColor = .wy_hex("#7B809E")
    
    /// 分页栏标题 Selected状态 颜色 默认<#2D3952>
    public var bar_title_selectedColor: UIColor = .wy_hex("#2D3952")
    
    /// 分页栏底部分隔带背景色 默认<#F2F2F2>
    public var bar_dividingStripColor: UIColor = .wy_hex("#F2F2F2")
    
    /// 分页栏底部分隔带背景图 默认为空
    public var bar_dividingStripImage: UIImage? = nil
    
    /// 滑动线条背景色 默认<#2D3952>
    public var bar_scrollLineColor: UIColor = .wy_hex("#2D3952")
    
    /// 滑动线条背景图 默认为空
    public var bar_scrollLineImage: UIImage? = nil
    
    /// 滑动线条宽度 默认0(如传入的数值大于0，则使用传入的宽度，否则宽度会按照分页栏Item宽度来显示)
    public var bar_scrollLineWidth: CGFloat = 0
    
    /// 滑动线条距离分页栏底部的距离 默认0
    public var bar_scrollLineBottomOffset: CGFloat = 0
    
    /// 分隔带高度 默认2像素
    public var bar_dividingStripHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)
    
    /// 滑动线条高度 默认2像素
    public var bar_scrollLineHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)
    
    /// 分页栏标题 Normal状态 字号 默认15号；
    public var bar_title_defaultFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    
    /// 分页栏标题 Selected状态 字号 默认15号；
    public var bar_title_selectedFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
    
    /// 当前选中的页面的Index，初始化时也可以用来设置默认选中第几个页面
    public var bar_selectedIndex: Int = 0
    
    /// 控制器是否需要左右滑动(默认支持)
    public var canScrollController: Bool = true
    
    /// 分页栏是否需要左右滑动(默认支持)
    public var canScrollBar: Bool = true
    
    /// 滑动线条是否需要支持跟随手指滑动(默认true)
    public var bar_scrollLineFollowFinger: Bool = true
    
    /// 传入的控制器数组
    public private(set) var controllers: [UIViewController] = []
    
    /// 传入的标题数组
    public private(set) var titles: [String] = []
    
    /// 传入的未选中的图片数组
    public private(set) var defaultImages: [UIImage] = []
    
    /// 传入的选中的图片数组
    public private(set) var selectedImages: [UIImage] = []
    
    /// 按钮栏所有按钮组件
    public private(set) var buttonItems: [WYPagingItem] = []
    
    /// 传入的父控制器
    public private(set) weak var superController: UIViewController?
    
    /**
     * 调用后开始布局
     *
     * @param controllers 控制器数组
     * @param titles 标题数组
     * @param defaultImages 未选中状态图片数组(可不传)
     * @param selectedImages 选中状态图片数组(可不传)
     * @param superViewController 父控制器
     */
    public func layout(controllers: [UIViewController], titles: [String] = [], defaultImages: [UIImage] = [], selectedImages: [UIImage] = [], superViewController: UIViewController) {
        
        DispatchQueue.main.async {
            
            guard controllers.isEmpty == false else {
                fatalError("❌ 错误：传入的controllers为空")
            }
            
            if !self.buttonItems.isEmpty {
                self.buttonItems.forEach { $0.removeFromSuperview() }
                self.buttonItems.removeAll()
            }
            
            if !self.controllers.isEmpty {
                self.controllers.forEach {
                    $0.view.removeFromSuperview()
                    $0.removeFromParent()
                }
                self.controllerScrollView.removeFromSuperview()
                objc_setAssociatedObject(self, &WYAssociatedKeys.controllerScrollView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            self.controllers = controllers
            self.titles = titles
            self.defaultImages = defaultImages
            self.selectedImages = selectedImages
            self.superController = superViewController
            
            if (self.bar_item_height <= 0) {
                self.bar_item_height = self.bar_height - self.bar_dividingStripHeight
            }
            
            self.layoutMethod()
        }
    }
    
    public init() { super.init(frame: .zero) }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
}

extension WYPagingView: UIScrollViewDelegate {
    
    /// 监听滚动事件判断当前拖动到哪一个了
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if (scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0) {
            
            let index: Int = Int(scrollView.contentOffset.x / self.frame.size.width)
            
            let changeItem: WYPagingItem =  barScrollView.viewWithTag(buttonItemTagBegin + index) as! WYPagingItem
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: changeItem)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        if (scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0) {
            
            isClickScrolling = false
            
            let index: Int = Int(scrollView.contentOffset.x / self.frame.size.width)
            
            let changeItem: WYPagingItem =  barScrollView.viewWithTag(buttonItemTagBegin + index) as! WYPagingItem
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: changeItem)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if isClickScrolling { return }
        
        // 内容区域滚动时才处理指示线跟随逻辑
        if (scrollView == controllerScrollView) && (controllers.count > 1) && canScrollController {
            
            // 如果未开启跟随手指功能，则不实时更新指示线
            guard bar_scrollLineFollowFinger else { return }
            
            let offsetX: CGFloat = scrollView.contentOffset.x
            let width: CGFloat = self.frame.size.width
            let progress: CGFloat = offsetX / width
            
            let currentIndex: Int = Int(floor(progress))
            let fractional: CGFloat = progress - CGFloat(currentIndex)
            
            // 边界保护，避免索引越界
            if (currentIndex < 0) || (currentIndex >= buttonItems.count - 1) { return }
            
            let currentButton: WYPagingItem = buttonItems[currentIndex]
            let nextButton: WYPagingItem = buttonItems[currentIndex + 1]
            
            // 计算当前和下一页的指示线宽度（支持固定宽度或跟随item宽度）
            let currentWidth: CGFloat = bar_scrollLineWidth > 0 ? bar_scrollLineWidth : currentButton.wy_width
            let nextWidth: CGFloat = bar_scrollLineWidth > 0 ? bar_scrollLineWidth : nextButton.wy_width
            
            // 宽度插值计算
            let deltaWidth: CGFloat = nextWidth - currentWidth
            let targetWidth: CGFloat = currentWidth + deltaWidth * fractional
            
            // 计算指示线左侧位置（中心对齐方式）
            let currentLeft: CGFloat = currentButton.center.x - (currentWidth / 2)
            let nextLeft: CGFloat = nextButton.center.x - (nextWidth / 2)
            
            let deltaLeft: CGFloat = nextLeft - currentLeft
            let targetLeft: CGFloat = currentLeft + deltaLeft * fractional
            
            // 实时更新约束
            barScrollLineLeftConstraint?.constant = targetLeft
            barScrollLineWidthConstraint?.constant = targetWidth
            
            // 更新圆角（如果指示线是圆角样式）
            barScrollLine.wy_rectCorner(.allCorners).wy_cornerRadius(targetWidth / 2).wy_showVisual()
            
            barScrollLine.superview?.layoutIfNeeded()
            
            // 让标题栏跟随滚动，尽量保持选中项居中
            let centerX: CGFloat = targetLeft + targetWidth / 2
            var needScrollOffsetX: CGFloat = centerX - (barScrollView.bounds.size.width / 2)
            
            let maxAllowScrollOffsetX: CGFloat = barScrollView.contentSize.width - barScrollView.bounds.size.width
            
            if (needScrollOffsetX < 0) { needScrollOffsetX = 0 }
            
            if (needScrollOffsetX > maxAllowScrollOffsetX) { needScrollOffsetX = maxAllowScrollOffsetX }
            
            if (barScrollView.contentSize.width > self.frame.size.width) && canScrollBar {
                
                barScrollView.setContentOffset(CGPoint(x: needScrollOffsetX, y: 0), animated: false)
            }
        }
    }
}

extension WYPagingView {
    
    @objc fileprivate func buttonItemClick(sender: WYPagingItem) {
        
        if(sender.tag != currentButtonItem.tag) {
            
            isClickScrolling = true
            
            // 点击切换页面，使用动画滚动
            controllerScrollView.setContentOffset(CGPoint(x: CGFloat(self.frame.size.width) * CGFloat((sender.tag - buttonItemTagBegin)), y: 0), animated: true)
        }
        bar_selectedIndex = sender.tag - buttonItemTagBegin
        
        /// 重新赋值标签属性
        updateButtonItemProperty(currentItem: sender)
    }
    
    func scrollMethod() {
        
        barScrollLine.superview?.layoutIfNeeded()
        
        /// 计算应该滚动多少（让当前选中项尽量居中）
        var needScrollOffsetX: CGFloat = currentButtonItem.center.x - (barScrollView.bounds.size.width * 0.5)
        
        /// 最大允许滚动的距离
        let maxAllowScrollOffsetX: CGFloat = barScrollView.contentSize.width - barScrollView.bounds.size.width
        
        if (needScrollOffsetX < 0) { needScrollOffsetX = 0 }
        
        if (needScrollOffsetX > maxAllowScrollOffsetX) { needScrollOffsetX = maxAllowScrollOffsetX }
        
        if (barScrollView.contentSize.width > self.frame.size.width) {
            barScrollView.setContentOffset(CGPoint(x: needScrollOffsetX, y: 0), animated: true)
        }
        
        UIView.animate(withDuration: 0.2) {
            
            let bar_scrollLineWidth: CGFloat = self.bar_scrollLineWidth > 0 ? self.bar_scrollLineWidth : self.currentButtonItem.wy_width
            
            self.barScrollLineLeftConstraint?.constant = self.currentButtonItem.center.x - (bar_scrollLineWidth * 0.5)
            
            self.barScrollLineWidthConstraint?.constant = bar_scrollLineWidth
            
            self.barScrollLine.wy_rectCorner(.allCorners).wy_cornerRadius(bar_scrollLineWidth / 2).wy_showVisual()
            
            self.barScrollLine.superview?.layoutIfNeeded()
        }
        
        bar_selectedIndex = currentButtonItem.tag-buttonItemTagBegin
        
        let pagingIndex: Int = currentButtonItem.tag-buttonItemTagBegin
        
        let controller: UIViewController = self.controllers[pagingIndex]
        
        if let clickOrScrollHandler = clickOrScrollHandler {
            clickOrScrollHandler(self, pagingIndex, !controller.wy_pageControllerIsLastDisplayed)
        }
        
        delegate?.wy_pagingViewItemDidScroll?(self, pagingIndex: pagingIndex, isFirstDisplayed: !controller.wy_pageControllerIsLastDisplayed)
        
        controller.wy_pageControllerIsLastDisplayed = true
    }
    
    fileprivate func updateButtonItemProperty(currentItem: WYPagingItem) {
        
        if(currentItem.tag != currentButtonItem.tag) {
            
            currentButtonItem.setIsSelected(false)
            
            /// 将当前选中的item赋值
            currentButtonItem = currentItem
            
            currentButtonItem.setIsSelected(true)
            
            /// 调用最终的方法
            scrollMethod()
        }
    }
}

extension WYPagingView {
    
    private func layoutMethod() {
        
        layoutIfNeeded()
        
        if ((bar_adjustOffset == true) && (bar_item_width > 0) && (bar_item_width * CGFloat(controllers.count) <= UIDevice.wy_screenWidth)) {
            
            bar_originlLeftOffset = (self.frame.size.width - (bar_item_width * CGFloat(controllers.count)) - bar_dividingOffset) / 2
            
            bar_originlRightOffset = bar_originlLeftOffset
        }
        
        var lastView: UIView? = nil
        for index in 0..<controllers.count {
            
            let pagingItemNormalImage: UIImage? = (defaultImages.isEmpty == false) ? defaultImages[index] : nil
            let pagingItemSelectedImage: UIImage? = (selectedImages.isEmpty == false) ? selectedImages[index] : nil
            
            let pagingItemText: String? = (titles.isEmpty == false) ? titles[index] : nil
            
            let finalItemHeight = (self.bar_item_height > 0)
            ? self.bar_item_height
            : (self.bar_height - self.bar_dividingStripHeight)
            
            let buttonItem = WYPagingItem(insideMargins: bar_item_insideMargins,
                                          normalImage: pagingItemNormalImage,
                                          selectedImage: pagingItemSelectedImage,
                                          imageViewSize: bar_item_imageViewSize,
                                          normalText: pagingItemText,
                                          selectedText: pagingItemText,
                                          normalTextColor: bar_title_defaultColor,
                                          selectedTextColor: bar_title_selectedColor,
                                          normalTextFont: bar_title_defaultFont,
                                          selectedTextFont: bar_title_selectedFont,
                                          buttonPosition: buttonPosition,
                                          dividingOffset: barButton_dividingOffset,
                                          itemWidth: bar_item_width,
                                          itemHeight: finalItemHeight,
                                          borderWidth: bar_item_borderWidth,
                                          cornerRadius: bar_item_cornerRadius,
                                          normalBorderColor: bar_item_normalBorderColor,
                                          selectedBorderColor: bar_item_selectedBorderColor,
                                          normalBackgroundColor: bar_item_bg_defaultColor,
                                          selectedBackgroundColor: bar_item_bg_selectedColor,)
            buttonItem.translatesAutoresizingMaskIntoConstraints = false
            buttonItem.contentHorizontalAlignment = .center
            buttonItem.tag = buttonItemTagBegin+index
            buttonItem.addTarget(self, action: #selector(buttonItemClick(sender:)), for: .touchUpInside)
            
            if(index == bar_selectedIndex) {
                buttonItem.setIsSelected(true)
                currentButtonItem = buttonItem
            }
            
            barScrollView.insertSubview(buttonItem, at: 0)
            
            // 设置顶部和底部约束
            if let bar_itemTopOffset = bar_itemTopOffset {
                
                buttonItem.topAnchor.constraint(equalTo: barScrollView.topAnchor, constant: bar_itemTopOffset).isActive = true
                
            }else  {
                buttonItem.centerYAnchor.constraint(equalTo: barScrollView.centerYAnchor).isActive = true
            }
            
            // 设置按钮左右约束
            if lastView == nil {
                buttonItem.leadingAnchor.constraint(equalTo: barScrollView.leadingAnchor, constant: bar_originlLeftOffset).isActive = true
            } else {
                buttonItem.leadingAnchor.constraint(equalTo: lastView!.trailingAnchor, constant: bar_dividingOffset).isActive = true
            }
            
            if index == (controllers.count-1) {
                buttonItem.trailingAnchor.constraint(equalTo: barScrollView.trailingAnchor, constant: -bar_originlRightOffset).isActive = true
            }
            
            buttonItems.append(buttonItem)
            
            lastView = buttonItem
            
            /// 设置scrollView的ContentSize让其滚动
            if(index == (controllers.count-1)) {
                
                controllerScrollView.superview?.layoutIfNeeded()
                controllerScrollView.contentOffset = CGPoint(x: self.frame.size.width * CGFloat(bar_selectedIndex), y: 0)
            }
        }
        DispatchQueue.main.async(execute: {
            self.scrollMethod()
            if let itemDidLayoutHandler = self.itemDidLayoutHandler {
                itemDidLayoutHandler(self)
            }
            self.delegate?.wy_pagingViewLayoutDidCompleted?(self)
        })
    }
    
    var controllerScrollView: UIScrollView {
        
        var scrollView: UIScrollView? = objc_getAssociatedObject(self, &WYAssociatedKeys.controllerScrollView) as? UIScrollView
        
        if scrollView == nil {
            
            scrollView = UIScrollView()
            scrollView!.translatesAutoresizingMaskIntoConstraints = false
            scrollView!.delegate = self
            scrollView!.isPagingEnabled = true
            scrollView!.isScrollEnabled = canScrollController
            scrollView!.showsHorizontalScrollIndicator = false
            scrollView!.showsVerticalScrollIndicator = false
            scrollView!.backgroundColor = bar_pagingContro_content_color
            scrollView!.bounces = bar_pagingContro_bounce
            addSubview(scrollView!)
            
            // 设置控制器滚动视图约束
            scrollView!.topAnchor.constraint(equalTo: barScrollView.bottomAnchor).isActive = true
            scrollView!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            scrollView!.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            scrollView!.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            
            scrollView!.contentInsetAdjustmentBehavior = .never
            
            var lastView: UIView? = nil
            for index in 0..<controllers.count {
                
                superController?.addChild(controllers[index])
                
                let controllerView = controllers[index].view
                controllerView?.translatesAutoresizingMaskIntoConstraints = false
                if let controller_bg_color: UIColor = bar_pagingContro_bg_color {
                    controllerView?.backgroundColor = controller_bg_color
                }
                scrollView!.addSubview(controllerView!)
                
                // 设置控制器视图约束
                controllerView!.topAnchor.constraint(equalTo: scrollView!.topAnchor).isActive = true
                controllerView!.bottomAnchor.constraint(equalTo: scrollView!.bottomAnchor).isActive = true
                controllerView!.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -bar_height).isActive = true
                controllerView!.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
                
                if lastView == nil {
                    controllerView!.leadingAnchor.constraint(equalTo: scrollView!.leadingAnchor).isActive = true
                } else {
                    controllerView!.leadingAnchor.constraint(equalTo: lastView!.trailingAnchor).isActive = true
                }
                
                if index == (controllers.count - 1) {
                    controllerView!.trailingAnchor.constraint(equalTo: scrollView!.trailingAnchor).isActive = true
                }
                
                lastView = controllerView!
            }
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.controllerScrollView, scrollView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return scrollView!
    }
    
    var barScrollView: UIScrollView {
        
        var barScroll: UIScrollView? = objc_getAssociatedObject(self, &WYAssociatedKeys.barScrollView) as? UIScrollView
        
        if barScroll == nil {
            
            barScroll = UIScrollView()
            barScroll!.translatesAutoresizingMaskIntoConstraints = false
            barScroll!.showsHorizontalScrollIndicator = false
            barScroll!.showsVerticalScrollIndicator = false
            barScroll!.backgroundColor = bar_bg_defaultColor
            barScroll!.bounces = bar_pagingContro_bounce
            barScroll!.isScrollEnabled = canScrollBar
            addSubview(barScroll!)
            
            // 设置分页栏滚动视图约束
            barScroll!.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            barScroll!.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            barScroll!.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
            barScroll!.heightAnchor.constraint(equalToConstant: bar_height).isActive = true
            
            /// 底部分隔带
            let dividingView = UIImageView()
            dividingView.translatesAutoresizingMaskIntoConstraints = false
            dividingView.backgroundColor = bar_dividingStripColor
            if let dividingStripImage: UIImage = bar_dividingStripImage {
                dividingView.image = dividingStripImage
            }
            barScroll!.addSubview(dividingView)
            
            // 设置分隔带约束
            dividingView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            dividingView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            dividingView.heightAnchor.constraint(equalToConstant: bar_dividingStripHeight).isActive = true
            dividingView.topAnchor.constraint(equalTo: barScroll!.bottomAnchor, constant: bar_height - bar_dividingStripHeight).isActive = true
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollView, barScroll, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        barScroll!.contentSize = CGSize(width: barScroll!.contentSize.width, height: bar_height)
        
        return barScroll!
    }
    
    var barScrollLine: UIImageView {
        
        var scrollLine: UIImageView? = objc_getAssociatedObject(self, &WYAssociatedKeys.barScrollLine) as? UIImageView
        
        if scrollLine == nil {
            
            scrollLine = UIImageView()
            scrollLine!.translatesAutoresizingMaskIntoConstraints = false
            scrollLine!.backgroundColor = (controllers.count > 1) ? bar_scrollLineColor : .clear
            barScrollView.addSubview(scrollLine!)
            if let scrollLineImage: UIImage = bar_scrollLineImage {
                scrollLine?.image = scrollLineImage
            }
            
            // 设置滑动线条约束
            barScrollLineLeftConstraint = scrollLine!.leadingAnchor.constraint(equalTo: barScrollView.leadingAnchor)
            barScrollLineLeftConstraint!.isActive = true
            barScrollLineWidthConstraint = scrollLine!.widthAnchor.constraint(equalToConstant: bar_scrollLineWidth)
            barScrollLineWidthConstraint!.isActive = true
            scrollLine!.heightAnchor.constraint(equalToConstant: bar_scrollLineHeight).isActive = true
            scrollLine!.topAnchor.constraint(equalTo: barScrollView.topAnchor, constant: bar_height - bar_scrollLineBottomOffset - bar_scrollLineHeight).isActive = true
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollLine, scrollLine!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return scrollLine!
    }
    
    var currentButtonItem: WYPagingItem {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentButtonItem, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            
            guard let item = objc_getAssociatedObject(self, &WYAssociatedKeys.currentButtonItem) as? WYPagingItem  else {
                fatalError("❌ currentButtonItem 未初始化或未赋值")
            }
            return item
        }
    }
    
    var clickOrScrollHandler: ((_ pagingView: WYPagingView, _ pagingIndex: Int, _ isFirstDisplayed : Bool) -> Void)? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.clickOrScrollHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.clickOrScrollHandler) as? (WYPagingView, Int, Bool) -> Void
        }
    }
    
    var itemDidLayoutHandler: ((_ pagingView: WYPagingView) -> Void)? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.itemDidLayoutHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.itemDidLayoutHandler) as? (WYPagingView) -> Void
        }
    }
    
    var barScrollLineLeftConstraint: NSLayoutConstraint? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollLineLeftConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.barScrollLineLeftConstraint) as? NSLayoutConstraint)
        }
    }
    
    var barScrollLineWidthConstraint: NSLayoutConstraint? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollLineWidthConstraint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &WYAssociatedKeys.barScrollLineWidthConstraint) as? NSLayoutConstraint)
        }
    }
    
    // 标记是否为点击触发的滚动（用于避免点击动画与scrollViewDidScroll跟随动画冲突）
    var isClickScrolling: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isClickScrolling, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isClickScrolling) as? Bool ?? false
        }
    }
    
    var buttonItemTagBegin: Int {
        return 1000
    }
    
    private struct WYAssociatedKeys {
        
        static var barScrollView: UInt8 = 0
        
        static var controllerScrollView: UInt8 = 0
        
        static var barScrollLine: UInt8 = 0
        
        static var currentButtonItem: UInt8 = 0
        
        static var clickOrScrollHandler: UInt8 = 0
        
        static var itemDidLayoutHandler: UInt8 = 0
        
        static var barScrollLineLeftConstraint: UInt8 = 0
        
        static var barScrollLineWidthConstraint: UInt8 = 0
        
        static var isClickScrolling: UInt8 = 0
    }
}

/// PagingView按钮栏Item
public class WYPagingItem: UIButton {
    
    /// 标题View
    public var textView: UILabel?
    
    /// 图片View
    public var iconView: UIImageView?
    
    /// 内边距
    public private(set) var insideMargins: UIEdgeInsets = .zero
    
    /// Normal状态文本
    public private(set) var normalText: String?
    
    /// Selected状态文本
    public private(set) var selectedText: String?
    
    /// Normal状态图片
    public private(set) var normalImage: UIImage?
    
    /// Selected状态图片
    public private(set) var selectedImage: UIImage?
    
    /// Normal状态文本颜色
    public private(set) var normalTextColor: UIColor?
    
    /// Selected状态文本颜色
    public private(set) var selectedTextColor: UIColor?
    
    /// Normal状态文本字体
    public private(set) var normalTextFont: UIFont?
    
    /// Selected状态文本字体
    public private(set) var selectedTextFont: UIFont?
    
    /// 边框宽度
    public private(set) var borderWidth: CGFloat = 0
    
    /// 圆角半径
    public private(set) var cornerRadius: CGFloat = 0
    
    /// Normal状态边框颜色
    public private(set) var normalBorderColor: UIColor?
    
    /// Selected状态边框颜色
    public private(set) var selectedBorderColor: UIColor?
    
    /// Normal状态背景色
    public private(set) var normalBackgroundColor: UIColor = .clear
    
    /// Selected状态背景色
    public private(set) var selectedBackgroundColor: UIColor = .clear
    
    /**
     *  唯一初始化方法
     *  @param insideMargins           按钮内边距
     *  @param normalImage             按钮Normal状态图片
     *  @param selectedImage           按钮Selected状态图片
     *  @param imageViewSize           按钮图片ViewSize
     *  @param normalText              按钮Normal状态文本
     *  @param selectedText            按钮Selected状态文本
     *  @param normalTextColor         按钮Normal状态文本颜色
     *  @param selectedTextColor       按钮Selected状态文本颜色
     *  @param normalTextFont          按钮Normal状态文本字体字号
     *  @param selectedTextFont        按钮Selected状态文本字体字号
     *  @param buttonPosition          图片和文字显示模式
     *  @param dividingOffset          按钮内部图片和文字的上下或左右间距
     *  @param itemWidth               外部指定的Item固定宽度（0表示自适应）
     *  @param itemHeight              外部指定的Item固定高度（0表示自适应）
     *  @param borderWidth             边框宽度
     *  @param cornerRadius            圆角半径
     *  @param normalBorderColor       Normal状态边框颜色
     *  @param selectedBorderColor     Selected状态边框颜色
     *  @param normalBackgroundColor   Normal状态背景色
     *  @param selectedBackgroundColor Selected状态背景色
     */
    public init(insideMargins: UIEdgeInsets,
                normalImage: UIImage?,
                selectedImage: UIImage?,
                imageViewSize: CGSize,
                normalText: String?,
                selectedText: String?,
                normalTextColor: UIColor,
                selectedTextColor: UIColor,
                normalTextFont: UIFont,
                selectedTextFont: UIFont,
                buttonPosition: WYButtonPosition,
                dividingOffset: CGFloat,
                itemWidth: CGFloat = 0,
                itemHeight: CGFloat = 0,
                borderWidth: CGFloat = 0,
                cornerRadius: CGFloat = 0,
                normalBorderColor: UIColor?,
                selectedBorderColor: UIColor?,
                normalBackgroundColor: UIColor,
                selectedBackgroundColor: UIColor) {
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true
        
        // 保存状态数据
        self.normalText = normalText
        self.selectedText = selectedText
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
        self.normalTextFont = normalTextFont
        self.selectedTextFont = selectedTextFont
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.normalBorderColor = normalBorderColor
        self.selectedBorderColor = selectedBorderColor
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        
        // 设置默认边框圆角
        if let borderColor = normalBorderColor, cornerRadius > 0, borderWidth > 0 {
            self.wy_rectCorner(.allCorners).wy_cornerRadius(cornerRadius).wy_borderWidth(borderWidth).wy_borderColor(borderColor).wy_showVisual()
        }
        
        // 设置默认背景色
        self.backgroundColor = normalBackgroundColor
        
        // ==================== 智能计算 insideMargins ====================
        var finalMargins = insideMargins
        
        // 只有用户没有主动设置 insideMargins 时才自动计算
        if insideMargins == .zero {
            let iconSize = (imageViewSize == .zero ? normalImage?.size : imageViewSize) ?? .zero
            let textSize = (normalText as NSString?)?.size(withAttributes: [.font: normalTextFont]) ?? .zero
            
            switch buttonPosition {
            case .imageTopTitleBottom, .imageBottomTitleTop:
                // 竖向布局
                if itemHeight > 0 {
                    let contentHeight = iconSize.height + dividingOffset + textSize.height
                    let remaining = max(0, itemHeight - contentHeight)
                    finalMargins.top = remaining / 2
                    finalMargins.bottom = remaining / 2
                }
                // 水平方向：如果有固定宽度则居中，否则不加额外左右边距（让内容自然显示）
                if itemWidth > 0 {
                    let contentWidth = iconSize.width + dividingOffset + textSize.width
                    let remaining = max(0, itemWidth - contentWidth)
                    finalMargins.left = remaining / 2
                    finalMargins.right = remaining / 2
                }
                
            case .imageLeftTitleRight, .imageRightTitleLeft:
                // 横向布局
                if itemWidth > 0 {
                    let contentWidth = iconSize.width + dividingOffset + textSize.width
                    let remaining = max(0, itemWidth - contentWidth)
                    finalMargins.left = remaining / 2
                    finalMargins.right = remaining / 2
                }
                // 垂直方向：如果有固定高度则居中，否则不加额外上下边距
                if itemHeight > 0 {
                    let contentHeight = max(iconSize.height, textSize.height)
                    let remaining = max(0, itemHeight - contentHeight)
                    finalMargins.top = remaining / 2
                    finalMargins.bottom = remaining / 2
                }
            }
        }
        
        self.insideMargins = finalMargins
        
        // ==================== 创建内容视图 ====================
        let contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = false
        addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
        ])
        
        // ==================== 图文混排 ====================
        if let normalImage = normalImage, let _ = selectedImage,
           let normalText = normalText, let _ = selectedText {
            
            let icon = UIImageView(image: normalImage)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            contentView.addSubview(icon)
            self.iconView = icon
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = normalText
            label.textColor = normalTextColor
            label.font = normalTextFont
            label.textAlignment = .center
            contentView.addSubview(label)
            self.textView = label
            
            let iconSize = (imageViewSize == .zero) ? normalImage.size : imageViewSize
            let textSize = (normalText as NSString).size(withAttributes: [.font: normalTextFont])
            
            switch buttonPosition {
            case .imageLeftTitleRight:
                let totalWidth = iconSize.width + dividingOffset + textSize.width
                NSLayoutConstraint.activate([
                    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: dividingOffset),
                    label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: totalWidth)
                ])
                
            case .imageRightTitleLeft:
                let totalWidth = iconSize.width + dividingOffset + textSize.width
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: dividingOffset),
                    icon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: totalWidth)
                ])
                
            case .imageTopTitleBottom:
                let maxWidth = max(iconSize.width, textSize.width)
                let totalHeight = iconSize.height + dividingOffset + textSize.height
                NSLayoutConstraint.activate([
                    icon.topAnchor.constraint(equalTo: contentView.topAnchor),
                    icon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: dividingOffset),
                    label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: maxWidth),
                    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: totalHeight)
                ])
                
            case .imageBottomTitleTop:
                let maxWidth = max(iconSize.width, textSize.width)
                let totalHeight = iconSize.height + dividingOffset + textSize.height
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: contentView.topAnchor),
                    label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.topAnchor.constraint(equalTo: label.bottomAnchor, constant: dividingOffset),
                    icon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    icon.widthAnchor.constraint(equalToConstant: iconSize.width),
                    icon.heightAnchor.constraint(equalToConstant: iconSize.height),
                    contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: maxWidth),
                    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: totalHeight)
                ])
            }
        }
        // ==================== 仅图片 ====================
        else if let normalImage = normalImage, let _ = selectedImage {
            let icon = UIImageView(image: normalImage)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.contentMode = .scaleAspectFit
            addSubview(icon)
            self.iconView = icon
            
            NSLayoutConstraint.activate([
                icon.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
                icon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
                icon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
            ])
        }
        // ==================== 仅文本 ====================
        else if let normalText = normalText, let _ = selectedText {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = normalText
            label.textColor = normalTextColor
            label.font = normalTextFont
            label.textAlignment = .center
            addSubview(label)
            self.textView = label
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: topAnchor, constant: finalMargins.top),
                label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -finalMargins.bottom),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: finalMargins.left),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -finalMargins.right)
            ])
        } else {
            fatalError("❌ 不支持的WYPagingItem显示类型")
        }
        
        // 外部强制固定尺寸
        if itemWidth > 0 {
            widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
        }
        if itemHeight > 0 {
            heightAnchor.constraint(equalToConstant: itemHeight).isActive = true
        }
    }
    
    /// 设置WYPagingItem的选中状态
    public func setIsSelected(_ isSelected: Bool) {
        self.isSelected = isSelected
        
        // 切换图片
        if let iconView = iconView {
            iconView.image = isSelected ? selectedImage : normalImage
        }
        
        // 切换文本、颜色、字体
        if let textView = textView {
            textView.text = isSelected ? selectedText : normalText
            textView.textColor = isSelected ? selectedTextColor : normalTextColor
            textView.font = isSelected ? selectedTextFont : normalTextFont
        }
        
        // 设置边框圆角
        if cornerRadius > 0, borderWidth > 0, let borderColor = isSelected ? selectedBorderColor : normalBorderColor {
            self.wy_rectCorner(.allCorners)
                .wy_cornerRadius(cornerRadius)
                .wy_borderWidth(borderWidth)
                .wy_borderColor(borderColor)
                .wy_showVisual()
        }
        
        // 切换背景色
        backgroundColor = isSelected ? selectedBackgroundColor : normalBackgroundColor
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIViewController {
    
    /// Controller是否是第二次及以后在WYPagingView中显示
    var wy_pageControllerIsLastDisplayed: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_pageControllerIsLastDisplayed, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_pageControllerIsLastDisplayed) as? Bool ?? false
        }
    }
    
    struct WYAssociatedKeys {
        static var wy_pageControllerIsLastDisplayed: UInt8 = 0
    }
}
