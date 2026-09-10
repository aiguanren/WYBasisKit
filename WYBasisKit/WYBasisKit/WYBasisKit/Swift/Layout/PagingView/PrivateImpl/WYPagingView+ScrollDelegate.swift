//
//  WYPagingView+ScrollDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/9.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingView 滚动代理实现，内容滚动视图的滚动中联动(指示线跟随与标题栏居中)与各类滚动结束后的选中态落位
extension WYPagingView: UIScrollViewDelegate {

    /// 监听滚动事件判断当前拖动到哪一个了
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        if (scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0) {

            let index: Int = Int(scrollView.contentOffset.x / self.frame.size.width)

            // 防重载竞态导致tag查不到按钮时强转崩溃:查不到就直接跳过这次落位
            guard let changeItem: WYPagingItem = barScrollView.viewWithTag(buttonItemTagBegin + index) as? WYPagingItem else { return }
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: changeItem)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {

        if (scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0) {

            isClickScrolling = false

            let index: Int = Int(scrollView.contentOffset.x / self.frame.size.width)

            // 防重载竞态导致tag查不到按钮时强转崩溃:查不到就直接跳过这次落位
            guard let changeItem: WYPagingItem = barScrollView.viewWithTag(buttonItemTagBegin + index) as? WYPagingItem else { return }
            //重新赋值标签属性
            updateButtonItemProperty(currentItem: changeItem)
        }
    }

    /// 防手指拖动恰好停在整页位置松手(没有减速过程)时scrollViewDidEndDecelerating不会回调导致选中态不同步:拖动结束时没触发减速就手动落一次选中态
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        if (decelerate == false) && (scrollView == controllerScrollView) && (controllerScrollView.contentOffset.x >= 0) {

            let index: Int = Int(scrollView.contentOffset.x / self.frame.size.width)

            // 防重载竞态导致tag查不到按钮时强转崩溃:查不到就直接跳过这次落位
            guard let changeItem: WYPagingItem = barScrollView.viewWithTag(buttonItemTagBegin + index) as? WYPagingItem else { return }
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
            if (bar_scrollLineCornerRadius > 0) {
                barScrollLine.wy_rectCorner(.allCorners).wy_cornerRadius(bar_scrollLineCornerRadius).wy_showVisual()
            }

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
