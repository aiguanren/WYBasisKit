//
//  WYPagingView+PageSwitching.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/9.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingView 页面切换，标题点击与滚动落位后的选中态更新、指示线落位动画、标题栏居中滚动与对外回调分发
extension WYPagingView {

    @objc func buttonItemClick(sender: WYPagingItem) {

        if(sender.tag != currentButtonItem.tag) {

            isClickScrolling = true

            let targetIndex: Int = sender.tag - buttonItemTagBegin

            // 相隔超过一页时按slideThroughIntermediatePages决定内容行为(true依次滑动经过中间页，false直接落位仅保留指示线与标题栏动画)，相邻页始终滑动切换
            let needAnimatedScroll: Bool = (abs(targetIndex - bar_selectedIndex) <= 1) || slideThroughIntermediatePages

            controllerScrollView.setContentOffset(CGPoint(x: CGFloat(self.frame.size.width) * CGFloat(targetIndex), y: 0), animated: needAnimatedScroll)

            // 直切不会触发scrollViewDidEndScrollingAnimation，这里手动复位点击滚动标记
            if (needAnimatedScroll == false) {
                isClickScrolling = false
            }
        }else {
            // 点击当前已选中的页面:通知业务层做"再点当前页回顶部/刷新"这类交互(不产生切页回调)
            let repeatIndex: Int = sender.tag - buttonItemTagBegin

            if let repeatClickHandler = repeatClickHandler {
                repeatClickHandler(self, repeatIndex)
            }

            delegate?.wy_pagingViewItemDidRepeatClick?(self, pagingIndex: repeatIndex)
        }
        bar_selectedIndex = sender.tag - buttonItemTagBegin

        /// 重新赋值标签属性
        updateButtonItemProperty(currentItem: sender)
    }

    func scrollMethod(animated: Bool = true) {

        barScrollLine.superview?.layoutIfNeeded()

        /// 计算应该滚动多少（让当前选中项尽量居中）
        var needScrollOffsetX: CGFloat = currentButtonItem.center.x - (barScrollView.bounds.size.width * 0.5)

        /// 最大允许滚动的距离
        let maxAllowScrollOffsetX: CGFloat = barScrollView.contentSize.width - barScrollView.bounds.size.width

        if (needScrollOffsetX < 0) { needScrollOffsetX = 0 }

        if (needScrollOffsetX > maxAllowScrollOffsetX) { needScrollOffsetX = maxAllowScrollOffsetX }

        if (barScrollView.contentSize.width > self.frame.size.width) {
            barScrollView.setContentOffset(CGPoint(x: needScrollOffsetX, y: 0), animated: animated)
        }

        let bar_scrollLineWidth: CGFloat = self.bar_scrollLineWidth > 0 ? self.bar_scrollLineWidth : self.currentButtonItem.wy_width

        barScrollLineLeftConstraint?.constant = self.currentButtonItem.center.x - (bar_scrollLineWidth * 0.5)

        barScrollLineWidthConstraint?.constant = bar_scrollLineWidth

        if (self.bar_scrollLineCornerRadius > 0) {
            self.barScrollLine.wy_rectCorner(.allCorners).wy_cornerRadius(self.bar_scrollLineCornerRadius).wy_showVisual()
        }

        // 初始化与重载落位时指示线直接到位(没有"上一个位置"可以过渡，播放动画会看到它从起点飞过来)，用户切页时才播动画
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.barScrollLine.superview?.layoutIfNeeded()
            }
        }else {
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

    // 应用/还原标题按钮的选中缩放(带短动画，系数为1时等于没有缩放；初始化与重载落位时不播动画直接到位)
    func applySelectedScale(to item: WYPagingItem, isSelected: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.15) {
                item.transform = isSelected ? CGAffineTransform(scaleX: self.selectedScale, y: self.selectedScale) : .identity
            }
        }else {
            item.transform = isSelected ? CGAffineTransform(scaleX: self.selectedScale, y: self.selectedScale) : .identity
        }
    }

    func updateButtonItemProperty(currentItem: WYPagingItem) {

        if(currentItem.tag != currentButtonItem.tag) {

            currentButtonItem.setIsSelected(false)
            applySelectedScale(to: currentButtonItem, isSelected: false)

            /// 将当前选中的item赋值
            currentButtonItem = currentItem

            currentButtonItem.setIsSelected(true)
            applySelectedScale(to: currentButtonItem, isSelected: true)

            /// 调用最终的方法
            scrollMethod()
        }
    }
}
