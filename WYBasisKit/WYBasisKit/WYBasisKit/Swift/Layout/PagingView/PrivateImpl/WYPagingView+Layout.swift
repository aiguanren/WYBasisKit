//
//  WYPagingView+Layout.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/9.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingView 布局构建，标题按钮的创建与排布(layoutMethod)、旧内容的整体拆装(removeAllSubviewsAndReset)、分页栏/内容滚动视图/指示线三个懒加载视图的构建
extension WYPagingView {

    func layoutMethod() {

        layoutIfNeeded()

        // 防居中计算漏算item之间的间距(只扣一份间距，数量不等于2时左右留白不对称甚至右侧被截断)和触发条件没算间距(数量多时会算出负偏移，第一项被挤出屏幕左侧):按真实占宽(含所有间距)判断并均分
        let barTotalWidth: CGFloat = (bar_item_width * CGFloat(controllers.count)) + (bar_dividingOffset * CGFloat(controllers.count - 1))

        if (bar_adjustOffset == true) && (bar_item_width > 0) && (barTotalWidth <= self.frame.size.width) {

            bar_originlLeftOffset = (self.frame.size.width - barTotalWidth) / 2

            bar_originlRightOffset = bar_originlLeftOffset
        }

        var lastView: UIView? = nil
        for index in 0..<controllers.count {

            let pagingItemNormalImage: UIImage? = (defaultImages.isEmpty == false) ? defaultImages[index] : nil
            let pagingItemSelectedImage: UIImage? = (selectedImages.isEmpty == false) ? selectedImages[index] : nil

            let pagingItemText: String? = (titles.isEmpty == false) ? titles[index] : nil

            var finalItemHeight = (self.bar_item_height > 0)
            ? self.bar_item_height
            : (self.bar_height - self.bar_dividingStripHeight)

            // 防顶部偏移后固定高度把item底部顶出分页栏可见区域:有顶部偏移时高度收敛到剩余可用空间(栏高减偏移再减栏底装饰，装饰取分隔带与滑动线条占位大者)
            if let bar_itemTopOffset = bar_itemTopOffset {
                let bottomDecorations: CGFloat = max(self.bar_dividingStripHeight, self.bar_scrollLineBottomOffset + self.bar_scrollLineHeight)
                finalItemHeight = max(0, min(finalItemHeight, self.bar_height - bar_itemTopOffset - bottomDecorations))
            }

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
                applySelectedScale(to: buttonItem, isSelected: true, animated: false)
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
        Task { @MainActor in
            // 初始化与重载落位:指示线与标题栏直接到位，不播从起点飞过来的动画
            self.scrollMethod(animated: false)
            if let itemDidLayoutHandler = self.itemDidLayoutHandler {
                itemDidLayoutHandler(self)
            }
            self.delegate?.wy_pagingViewLayoutDidCompleted?(self)
        }
    }

    func removeAllSubviewsAndReset() {

        // 防动态修改title数量或顺序后选中页错位(中间插删页、换顺序时下标对不上):调用方没重设bar_selectedIndex时记住当前页的控制器实例，重载后优先按实例找回选中页
        if let currentItem = objc_getAssociatedObject(self, &WYAssociatedKeys.currentButtonItem) as? WYPagingItem {

            let currentIndex: Int = currentItem.tag - buttonItemTagBegin

            if (self.bar_selectedIndex == currentIndex) && (currentIndex >= 0) && (currentIndex < self.controllers.count) {
                self.preservedController = self.controllers[currentIndex]
            }
        }

        // 防点击切页动画进行中触发重载导致isClickScrolling残留true(旧的controllerScrollView被移除后scrollViewDidEndScrollingAnimation不再回调):之后手指滑动内容时指示线将不再跟随
        self.isClickScrolling = false

        self.buttonItems.forEach { $0.removeFromSuperview() }
        self.buttonItems.removeAll()

        self.controllers.forEach {
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        self.controllerScrollView.removeFromSuperview()

        // 移除所有子视图（包括按钮栏、内容滚动视图、指示线等）
        self.subviews.forEach { $0.removeFromSuperview() }

        // 清空关联对象中的视图引用，强制下次访问懒加载属性时重新创建
        objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &WYAssociatedKeys.controllerScrollView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &WYAssociatedKeys.barScrollLine, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // 重置当前选中的按钮引用
        objc_setAssociatedObject(self, &WYAssociatedKeys.currentButtonItem, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
            barScroll!.bounces = bar_bounce
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
}
