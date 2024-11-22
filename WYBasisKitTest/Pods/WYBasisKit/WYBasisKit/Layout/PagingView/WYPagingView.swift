//
//  WYPagingView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/7.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import SnapKit

@objc public protocol WYPagingViewDelegate {
    
    @objc optional func itemDidScroll(_ pagingIndex: NSInteger)
}

public class WYPagingView: UIView {
    
    /// 点击或滚动事件代理(也可以通过传入block监听)
    public weak var delegate: WYPagingViewDelegate?
    
    /**
     * 点击或滚动事件(也可以通过实现代理监听)
     *
     * @param handler 点击或滚动事件的block
     */
    public func itemDidScroll(handler: @escaping ((_ pagingIndex: NSInteger) -> Void)) {
        actionHandler = handler
    }

    /// 分页栏的高度 默认45
    public var bar_Height: CGFloat = wy_screenWidth(45, WYBasisKitConfig.defaultScreenPixels)
    
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
    public var bar_dividingOffset: CGFloat = wy_screenWidth(20, WYBasisKitConfig.defaultScreenPixels)

    /// 内部按钮图片和文字的上下或左右间距 默认5
    public var barButton_dividingOffset: CGFloat = wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)
    
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
    
    /// 分页栏Item在约束size的基础上追加如传入的size大小，默认.zero(高度等于bar_Height)
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
    public var bar_scrollLineWidth: CGFloat = wy_screenWidth(25, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条距离分页栏底部的距离 默认5像素
    public var bar_scrollLineBottomOffset: CGFloat = wy_screenWidth(5, WYBasisKitConfig.defaultScreenPixels)

    /// 分隔带高度 默认2像素
    public var bar_dividingStripHeight: CGFloat = wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 滑动线条高度 默认2像素
    public var bar_scrollLineHeight: CGFloat = wy_screenWidth(2, WYBasisKitConfig.defaultScreenPixels)

    /// 分页栏标题默认字号 默认15号；
    public var bar_title_defaultFont: UIFont = .systemFont(ofSize: wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 分页栏标题选中字号 默认15号；
    public var bar_title_selectedFont: UIFont = .systemFont(ofSize: wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

    /// 初始选中第几项  默认第一项
    public var bar_selectedIndex: NSInteger = 0
    
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
    
    /// 传入的父控制器
    public private(set) weak var superController: UIViewController!
    
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
    
    private var actionHandler: ((_ index: NSInteger) -> Void)?
    
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
            
            let channeItem: WYPagingItem =  barScrollView.viewWithTag(buttonItemTagBegin + Int(index)) as! WYPagingItem
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: channeItem)
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

            self.barScrollLine.snp.updateConstraints { (make) in

                make.left.equalToSuperview().offset(self.currentButtonItem.center.x-(self.barScrollLine.frame.size.width * 0.5))
            }
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
            
            sender.wy_updateInsets(position: buttonPosition, spacing: barButton_dividingOffset)
            
            sender.superview?.wy_rectCorner(.allCorners).wy_cornerRadius(bar_item_cornerRadius).wy_showVisual()
        }
    }
}

extension WYPagingView {
    
    private func layoutMethod() {
        
        layoutIfNeeded()
        
        if ((bar_adjustOffset == true) && (bar_item_width > 0) && (bar_item_width * CGFloat(controllers.count) <= wy_screenWidth)) {
            
            bar_originlLeftOffset = (self.frame.size.width - (bar_item_width * CGFloat(controllers.count)) - bar_dividingOffset) / 2
            
            bar_originlRightOffset = bar_originlLeftOffset
        }
        
        var lastView: UIView? = nil
        for index in 0..<controllers.count {
            
            let buttonItem = WYPagingItem(appendSize: bar_item_appendSize)
            
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
            barScrollView.insertSubview(buttonItem, at: 0)
            
            buttonItem.snp.makeConstraints { (make) in

                if bar_itemTopOffset == nil {
                    make.centerY.equalToSuperview()
                }else {
                    make.top.equalToSuperview().offset(bar_itemTopOffset!)
                }
                if lastView == nil {
                    make.left.equalToSuperview().offset(bar_originlLeftOffset)
                }else {
                    make.left.equalTo(lastView!.snp.right).offset(bar_dividingOffset)
                }
                if bar_item_width > 0 {
                    make.width.equalTo(bar_item_width)
                }
                if bar_item_height > 0 {
                    make.height.equalTo(bar_item_height)
                }else {
                    if (bar_item_appendSize.equalTo(.zero)) {
                        
                        make.top.equalToSuperview()
                        make.bottom.equalToSuperview().offset(-bar_dividingStripHeight)
                    }
                }
                if(index == (controllers.count-1)) {
                    make.right.equalToSuperview().offset(-bar_originlRightOffset)
                }
            }
            
            if (bar_item_cornerRadius > 0) {
                
                buttonItem.wy_rectCorner(.allCorners).wy_cornerRadius(bar_item_cornerRadius).wy_showVisual()
            }
            
            lastView = buttonItem
            
            /// 设置scrollView的ContentSize让其滚动
            if(index == (controllers.count-1)) {

                controllerScrollView.superview?.layoutIfNeeded()
                controllerScrollView.contentOffset = CGPoint(x: self.frame.size.width * CGFloat(bar_selectedIndex), y: 0)

                /// 底部分隔带
                let dividingView = UIImageView()
                dividingView.backgroundColor = bar_dividingStripColor
                if let dividingStripImage: UIImage = bar_dividingStripImage {
                    dividingView.image = dividingStripImage
                }
                addSubview(dividingView)
                dividingView.snp.makeConstraints { (make) in

                    make.left.right.equalToSuperview()
                    make.height.equalTo(bar_dividingStripHeight)
                    make.bottom.equalTo(barScrollView)
                }
            }
        }
        DispatchQueue.main.async(execute: {
            self.scrollMethod()
        })
    }
    
    var controllerScrollView: UIScrollView {
        
        var scrollView: UIScrollView? = objc_getAssociatedObject(self, WYAssociatedKeys.controllerScrollView) as? UIScrollView
        
        if scrollView == nil {
            
            scrollView = UIScrollView()
            scrollView!.delegate = self
            scrollView!.isPagingEnabled = true
            scrollView!.isScrollEnabled = canScrollController
            scrollView!.showsHorizontalScrollIndicator = false
            scrollView!.showsVerticalScrollIndicator = false
            scrollView!.backgroundColor = bar_pagingContro_content_color
            scrollView!.bounces = bar_pagingContro_bounce
            addSubview(scrollView!)
            scrollView!.snp.makeConstraints { (make) in
                make.top.equalTo(barScrollView.snp.bottom)
                make.left.bottom.width.equalToSuperview()
            }
            
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
            
            var lastView: UIView? = nil
            for index in 0..<controllers.count {
                
                superController.addChild(controllers[index])
                
                let controllerView = controllers[index].view
                if let controller_bg_color: UIColor = bar_pagingContro_bg_color {
                    controllerView?.backgroundColor = controller_bg_color
                }
                scrollView!.addSubview(controllerView!)
                controllerView!.snp.makeConstraints({ (make) in

                    make.top.bottom.equalToSuperview()
                    make.height.equalTo(self).offset(-bar_Height)
                    make.width.equalTo(self)
                    if lastView == nil {
                        make.left.equalToSuperview()
                    }else {
                        make.left.equalTo(lastView!.snp.right)
                    }
                    if (index == (controllers.count - 1)) {
                        make.right.equalToSuperview()
                    }
                })
                lastView = controllerView!
            }
            
            objc_setAssociatedObject(self, WYAssociatedKeys.controllerScrollView, scrollView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return scrollView!
    }
    
    var barScrollView: UIScrollView {
        
        var barScroll: UIScrollView? = objc_getAssociatedObject(self, WYAssociatedKeys.barScrollView) as? UIScrollView
        
        if barScroll == nil {
            
            barScroll = UIScrollView()
            barScroll!.showsHorizontalScrollIndicator = false
            barScroll!.showsVerticalScrollIndicator = false
            barScroll!.backgroundColor = bar_bg_defaultColor
            barScroll!.bounces = bar_pagingContro_bounce
            barScroll!.isScrollEnabled = canScrollBar
            addSubview(barScroll!)
            barScroll!.snp.makeConstraints { (make) in
                make.top.left.width.equalToSuperview()
                make.height.equalTo(bar_Height)
            }
            objc_setAssociatedObject(self, WYAssociatedKeys.barScrollView, barScroll, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        barScroll!.contentSize = CGSize(width: barScroll!.contentSize.width, height: bar_Height)
        
        return barScroll!
    }
    
    var barScrollLine: UIImageView {
        
        var scrollLine: UIImageView? = objc_getAssociatedObject(self, WYAssociatedKeys.barScrollLine) as? UIImageView
        
        if scrollLine == nil {
            
            scrollLine = UIImageView()
            scrollLine!.backgroundColor = (controllers.count > 1) ? bar_scrollLineColor : .clear
            barScrollView.addSubview(scrollLine!)
            if let scrollLineImage: UIImage = bar_scrollLineImage{
                scrollLine?.image = scrollLineImage
            }
            
            scrollLine!.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.size.equalTo(CGSize(width: bar_scrollLineWidth, height: bar_scrollLineHeight))
                make.top.equalToSuperview().offset(bar_Height-bar_scrollLineBottomOffset-bar_scrollLineHeight)
            }
            scrollLine?.wy_rectCorner(.allCorners).wy_cornerRadius(bar_scrollLineHeight / 2).wy_showVisual()
            
            objc_setAssociatedObject(self, WYAssociatedKeys.barScrollLine, scrollLine!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return scrollLine!
    }
    
    var buttonItemTagBegin: NSInteger {
        return 1000
    }
    
    private struct WYAssociatedKeys {
        
        static let barScrollView = UnsafeRawPointer(bitPattern: "barScrollView".hashValue)!
        
        static let controllerScrollView = UnsafeRawPointer(bitPattern: "controllerScrollView".hashValue)!
        
        static let barScrollLine = UnsafeRawPointer(bitPattern: "barScrollLine".hashValue)!
    }
}

private class WYPagingItem: UIButton {
    
    let contentView: UIButton = UIButton(type: .custom)
    
    init(appendSize: CGSize) {
        
        super.init(frame: .zero)
        contentView.isUserInteractionEnabled = false
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            
            make.left.equalToSuperview().offset(appendSize.width / 2)
            make.top.equalToSuperview().offset(appendSize.height / 2)
            make.right.equalToSuperview().offset(-(appendSize.width / 2))
            make.bottom.equalToSuperview().offset(-(appendSize.height / 2))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
