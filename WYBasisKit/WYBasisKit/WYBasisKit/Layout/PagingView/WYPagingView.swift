//
//  WYPagingView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/7.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

@objc public protocol WYPagingViewDelegate {
    
    @objc optional func itemDidScroll(_ pagingIndex: Int)
}
    
public class WYPagingView: UIView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    public weak var delegate: WYPagingViewDelegate?
    
    /**
     * 点击或滚动事件(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    public func itemDidScroll(handler: @escaping ((_ pagingIndex: Int) -> Void)) {
        actionHandler = handler
    }

    /// 分页栏的高度 默认45
    public var bar_Height: CGFloat = UIDevice.wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels)
    
    /// 图片和文字显示模式
    public var buttonPosition: WYButtonPosition = .imageTopTitleBottom

    /// 分页栏左起始点距离(第一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlLeftOffset: CGFloat = 0

    /// 分页栏右起始点距离(最后一个标题栏距离屏幕边界的距离) 默认0
    public var bar_originlRightOffset: CGFloat = 0
    
    /// item距离分页栏顶部的偏移量， 默认nil
    public var bar_itemTopOffset: CGFloat?
    
    /// 显示整体宽度小于一屏，且设置了bar_Width != 0，是否需要居中显示，默认 居中 (居中后，将会动态调整bar_originlLeftOffset和bar_originlRightOffset的距离)
    public var bar_adjustOffset: Bool = true

    /// 左右分页栏之间的间距，默认20像素
    public var bar_dividingOffset: CGFloat = UIDevice.wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)

    /// 内部按钮图片和文字的上下或左右间距 默认5
    public var barButton_dividingOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
    /// 分页控制器底部背景色 默认白色
    public var bar_pagingContro_content_color: UIColor = .white
    
    /// 分页控制器背景色
    public var bar_pagingContro_bg_color: UIColor? = nil
    
    /// 分页控制器是否需要弹跳效果
    public var bar_pagingContro_bounce: Bool = true
    
    /// 分页栏默认背景色 默认白色
    public var bar_bg_defaultColor: UIColor = .white
    
    /// 分页栏Item宽度 默认对应每页标题文本宽度(若传入则整体使用传入宽度)
    public var bar_item_width: CGFloat = 0
    
    /// 分页栏Item高度 默认bar_Height-bar_dividingStripHeight(若传入则整体使用传入高度)
    public var bar_item_height: CGFloat = 0
    
    /// 分页栏Item在约束size的基础上追加传入的size大小，默认.zero(高度等于bar_Height)
    public var bar_item_appendSize: CGSize = .zero

    /// 分页栏item默认背景色 默认白色
    public var bar_item_bg_defaultColor: UIColor = .white

    /// 分页栏item选中背景色 默认白色
    public var bar_item_bg_selectedColor: UIColor = .white
    
    /// 分页栏item圆角半径, 默认0
    public var bar_item_cornerRadius: CGFloat = 0.0

    /// 分页栏标题默认颜色 默认<#7B809E>
    public var bar_title_defaultColor: UIColor = .wy_hex("#7B809E")

    /// 分页栏标题选中颜色 默认<#2D3952>
    public var bar_title_selectedColor: UIColor = .wy_hex("#2D3952")

    /// 分页栏底部分隔带背景色 默认<#F2F2F2>
    public var bar_dividingStripColor: UIColor = .wy_hex("#F2F2F2")
    
    /// 分页栏底部分隔带背景图 默认为空
    public var bar_dividingStripImage: UIImage? = nil

    /// 滑动线条背景色 默认<#2D3952>
    public var bar_scrollLineColor: UIColor = .wy_hex("#2D3952")
    
    /// 滑动线条背景图 默认为空
    public var bar_scrollLineImage: UIImage? = nil

    /// 滑动线条宽度 默认25像素
    public var bar_scrollLineWidth: CGFloat = UIDevice.wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条距离分页栏底部的距离 默认5像素
    public var bar_scrollLineBottomOffset: CGFloat = UIDevice.wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 分隔带高度 默认2像素
    public var bar_dividingStripHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条高度 默认2像素
    public var bar_scrollLineHeight: CGFloat = UIDevice.wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 分页栏标题默认字号 默认15号；
    public var bar_title_defaultFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 分页栏标题选中字号 默认15号；
    public var bar_title_selectedFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 初始选中第几项  默认第一项
    public var bar_selectedIndex: Int = 0
    
    /// 控制器是否需要左右滑动(默认支持)
    public var canScrollController: Bool = true
    
    /// 分页栏是否需要左右滑动(默认支持)
    public var canScrollBar: Bool = true
    
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
     *调用后开始布局
     *
     * @param controllerAry 控制器数组
     * @param titleAry 标题数组
     * @param defaultImageAry 未选中状态图片数组(可不传)
     * @param selectedImageAry 选中状态图片数组(可不传)
     * @param superViewController 父控制器
     */
    public func layout(controllerAry: [UIViewController], titleAry: [String] = [], defaultImageAry: [UIImage] = [], selectedImageAry: [UIImage] = [], superViewController: UIViewController) {
        
        DispatchQueue.main.async {
            
            self.controllers = controllerAry
            self.titles = titleAry
            self.defaultImages = defaultImageAry
            self.selectedImages = selectedImageAry
            self.superController = superViewController
            
            self.layoutMethod()
        }
    }
    
    private var currentButtonItem: WYPagingItem!
    private var actionHandler: ((_ index: Int) -> Void)?
    private var barScrollLineLeftConstraint: NSLayoutConstraint?
    
    public init() {
        super.init(frame: .zero)
    }
    
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
        
        if((scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0)) {

            let index: CGFloat = scrollView.contentOffset.x / self.frame.size.width
            
            let changeItem: WYPagingItem =  barScrollView.viewWithTag(buttonItemTagBegin + Int(index)) as! WYPagingItem
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: changeItem)
        }
    }
}

extension WYPagingView {
    
    @objc fileprivate func buttonItemClick(sender: WYPagingItem) {
        
        if(sender.tag != currentButtonItem.tag) {
            
            controllerScrollView.contentOffset = CGPoint(x: CGFloat(self.frame.size.width) * CGFloat((sender.tag - buttonItemTagBegin)), y: 0)
        }
        bar_selectedIndex = sender.tag - buttonItemTagBegin
        
        /// 重新赋值标签属性
        updateButtonItemProperty(currentItem: sender)
    }
    
    func scrollMethod() {
        
        barScrollLine.superview?.layoutIfNeeded()
        
        /// 计算应该滚动多少
        var needScrollOffsetX: CGFloat = currentButtonItem.center.x - (barScrollView.bounds.size.width * 0.5)
        
        /// 最大允许滚动的距离
        let maxAllowScrollOffsetX: CGFloat = barScrollView.contentSize.width - barScrollView.bounds.size.width
        
        if (needScrollOffsetX < 0) { needScrollOffsetX = 0 }
        
        if (needScrollOffsetX > maxAllowScrollOffsetX) { needScrollOffsetX = maxAllowScrollOffsetX }
        
        if (barScrollView.contentSize.width > self.frame.size.width) {
            
            barScrollView.setContentOffset(CGPoint(x: needScrollOffsetX, y: 0), animated: true)
        }
        
        UIView.animate(withDuration: 0.2) {
            self.barScrollLineLeftConstraint?.constant = self.currentButtonItem.center.x - (self.barScrollLine.frame.size.width * 0.5)
            self.barScrollLine.superview?.layoutIfNeeded()
        }
        
        bar_selectedIndex = currentButtonItem.tag-buttonItemTagBegin
        
        if actionHandler != nil {
            
            actionHandler!(currentButtonItem.tag-buttonItemTagBegin)
        }
        
        delegate?.itemDidScroll?(currentButtonItem.tag-buttonItemTagBegin)
    }
    
    fileprivate func updateButtonItemProperty(currentItem: WYPagingItem) {
        
        if(currentItem.tag != currentButtonItem.tag) {
            
            currentButtonItem.isSelected = false
            currentButtonItem.contentView.isSelected = false
            
            currentButtonItem.backgroundColor = bar_item_bg_defaultColor
            currentButtonItem.contentView.setTitleColor(bar_title_defaultColor, for: .normal)
            currentButtonItem.contentView.titleLabel?.font = bar_title_defaultFont
            updateButtonContentMode(sender: currentButtonItem.contentView)
            
            /// 将当前选中的item赋值
            currentItem.isSelected = true
            currentItem.contentView.isSelected = true
            currentButtonItem = currentItem
            
            currentButtonItem.backgroundColor = bar_item_bg_selectedColor
            currentButtonItem.contentView.setTitleColor(bar_title_selectedColor, for: .selected)
            currentButtonItem.contentView.titleLabel?.font = bar_title_selectedFont
            updateButtonContentMode(sender: currentButtonItem.contentView)
            
            /// 调用最终的方法
            scrollMethod()
        }
    }
    
    func updateButtonContentMode(sender: UIButton) {
        
        if(((defaultImages.count == controllers.count) || (selectedImages.count == controllers.count)) && (titles.count == controllers.count)) {
            
            sender.wy_adjust(position: buttonPosition, spacing: barButton_dividingOffset)
            sender.superview?.wy_rectCorner(.allCorners).wy_cornerRadius(bar_item_cornerRadius).wy_showVisual()
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
            
            let buttonItem = WYPagingItem(appendSize: bar_item_appendSize)
            buttonItem.translatesAutoresizingMaskIntoConstraints = false
            
            if (titles.isEmpty == false) {
                
                buttonItem.contentView.setTitleColor(bar_title_defaultColor, for: .normal)
                buttonItem.contentView.setTitleColor(bar_title_selectedColor, for: .selected)
                buttonItem.contentView.titleLabel?.font = (index == bar_selectedIndex) ? bar_title_selectedFont : bar_title_defaultFont
                buttonItem.contentView.setTitle(titles[index], for: .normal)
            }
            
            if ((defaultImages.isEmpty == false) || (selectedImages.isEmpty == false)) {
                if (defaultImages.isEmpty == false) {
                    buttonItem.contentView.setImage(defaultImages[index], for: .normal)
                }
                if (selectedImages.isEmpty == false) {
                    buttonItem.contentView.setImage(selectedImages[index], for: .selected)
                }
                buttonItem.contentView.imageView?.contentMode = .center
                updateButtonContentMode(sender: buttonItem.contentView)
            }
            buttonItem.contentView.contentHorizontalAlignment = .center
            buttonItem.backgroundColor = (index == bar_selectedIndex) ? bar_item_bg_selectedColor : bar_item_bg_defaultColor
            buttonItem.tag = buttonItemTagBegin+index
            buttonItem.addTarget(self, action: #selector(buttonItemClick(sender:)), for: .touchUpInside)
            
            if(index == bar_selectedIndex) {
                
                buttonItem.isSelected = true
                buttonItem.contentView.isSelected = true
                currentButtonItem = buttonItem
            }
            barScrollView.addSubview(buttonItem)
            
            // 设置约束
            if bar_itemTopOffset == nil {
                buttonItem.centerYAnchor.constraint(equalTo: barScrollView.centerYAnchor).isActive = true
            } else {
                buttonItem.topAnchor.constraint(equalTo: barScrollView.topAnchor, constant: bar_itemTopOffset!).isActive = true
            }
            
            if lastView == nil {
                buttonItem.leadingAnchor.constraint(equalTo: barScrollView.leadingAnchor, constant: bar_originlLeftOffset).isActive = true
            } else {
                buttonItem.leadingAnchor.constraint(equalTo: lastView!.trailingAnchor, constant: bar_dividingOffset).isActive = true
            }
            
            if bar_item_width > 0 {
                buttonItem.widthAnchor.constraint(equalToConstant: bar_item_width).isActive = true
            }
            
            if bar_item_height > 0 {
                buttonItem.heightAnchor.constraint(equalToConstant: bar_item_height).isActive = true
            } else if bar_item_appendSize.equalTo(.zero) {
                buttonItem.topAnchor.constraint(equalTo: barScrollView.topAnchor).isActive = true
                buttonItem.bottomAnchor.constraint(equalTo: barScrollView.bottomAnchor, constant: -bar_dividingStripHeight).isActive = true
            }
            
            if index == (controllers.count-1) {
                buttonItem.trailingAnchor.constraint(equalTo: barScrollView.trailingAnchor, constant: -bar_originlRightOffset).isActive = true
            }
            
            if (bar_item_cornerRadius > 0) {
                
                buttonItem.wy_rectCorner(.allCorners).wy_cornerRadius(bar_item_cornerRadius).wy_showVisual()
            }
            
            buttonItems.append(buttonItem)
            
            lastView = buttonItem
            
            /// 设置scrollView的ContentSize让其滚动
            if(index == (controllers.count-1)) {

                controllerScrollView.superview?.layoutIfNeeded()
                controllerScrollView.contentOffset = CGPoint(x: self.frame.size.width * CGFloat(bar_selectedIndex), y: 0)

                /// 底部分隔带
                let dividingView = UIImageView()
                dividingView.translatesAutoresizingMaskIntoConstraints = false
                dividingView.backgroundColor = bar_dividingStripColor
                if let dividingStripImage: UIImage = bar_dividingStripImage {
                    dividingView.image = dividingStripImage
                }
                addSubview(dividingView)
                
                // 设置分隔带约束
                dividingView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
                dividingView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
                dividingView.heightAnchor.constraint(equalToConstant: bar_dividingStripHeight).isActive = true
                dividingView.bottomAnchor.constraint(equalTo: barScrollView.bottomAnchor).isActive = true
            }
        }
        DispatchQueue.main.async(execute: {
            self.scrollMethod()
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
            
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
            
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
                controllerView!.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -bar_Height).isActive = true
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
            barScroll!.heightAnchor.constraint(equalToConstant: bar_Height).isActive = true
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollView, barScroll, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        barScroll!.contentSize = CGSize(width: barScroll!.contentSize.width, height: bar_Height)
        
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
            scrollLine!.widthAnchor.constraint(equalToConstant: bar_scrollLineWidth).isActive = true
            scrollLine!.heightAnchor.constraint(equalToConstant: bar_scrollLineHeight).isActive = true
            scrollLine!.topAnchor.constraint(equalTo: barScrollView.topAnchor, constant: bar_Height - bar_scrollLineBottomOffset - bar_scrollLineHeight).isActive = true
            
            scrollLine?.wy_rectCorner(.allCorners).wy_cornerRadius(bar_scrollLineHeight / 2).wy_showVisual()
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollLine, scrollLine!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return scrollLine!
    }
    
    var buttonItemTagBegin: Int {
        return 1000
    }
    
    private struct WYAssociatedKeys {
        
        static var barScrollView: UInt8 = 0
        
        static var controllerScrollView: UInt8 = 0
        
        static var barScrollLine: UInt8 = 0
    }
}

public class WYPagingItem: UIButton {
    
    public let contentView: UIButton = UIButton(type: .custom)
    
    public init(appendSize: CGSize) {
        
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = false
        contentView.titleLabel?.textAlignment = .center
        addSubview(contentView)
        
        // 设置内容视图约束
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: appendSize.width / 2).isActive = true
        contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: appendSize.height / 2).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -(appendSize.width / 2)).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -(appendSize.height / 2)).isActive = true
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
