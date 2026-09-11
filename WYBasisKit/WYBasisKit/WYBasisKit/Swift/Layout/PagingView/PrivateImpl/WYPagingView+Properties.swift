//
//  WYPagingView+Properties.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/9.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// WYPagingView 私有属性集中管理，关联对象存储的状态与回调(当前选中按钮/重载前记住的控制器/事件闭包/指示线约束/点击滚动标记)、按钮tag基准值与UIViewController的已展示标记
extension WYPagingView {

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

    // 重载前记住的当前页控制器(重载后优先按它找回选中页，中间插删页或换顺序时下标对不上)
    var preservedController: UIViewController? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.preservedController, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.preservedController) as? UIViewController
        }
    }

    // 是否已完成过首次layout(用来区分这次layout是首次还是数据源重载，isReload传给布局完成回调)
    var hasCompletedInitialLayout: Bool {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.hasCompletedInitialLayout, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.hasCompletedInitialLayout) as? Bool ?? false
        }
    }

    var repeatClickHandler: ((_ pagingView: WYPagingView, _ pagingIndex: Int) -> Void)? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.repeatClickHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.repeatClickHandler) as? (WYPagingView, Int) -> Void
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

    var itemDidLayoutHandler: ((_ pagingView: WYPagingView, _ pagingIndex: Int, _ isReload: Bool) -> Void)? {

        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.itemDidLayoutHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.itemDidLayoutHandler) as? (WYPagingView, Int, Bool) -> Void
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

    // 选中缩放生效值(bar_title_selectedScale非正数时按1处理，供标题按钮选中切换时使用)
    var selectedScale: CGFloat {
        return (bar_title_selectedScale > 0) ? bar_title_selectedScale : 1
    }

    // 上次自动算出的Item高度(用于判断bar_item_height是否仍是自动值，分隔带/滑动线条/栏高变化后重载时重新推导)
    var lastAutoItemHeight: CGFloat? {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.lastAutoItemHeight, newValue.map { NSNumber(value: Double($0)) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return CGFloat((objc_getAssociatedObject(self, &WYAssociatedKeys.lastAutoItemHeight) as? NSNumber)?.doubleValue ?? 0)
        }
    }

    var buttonItemTagBegin: Int {
        return 1000
    }

    struct WYAssociatedKeys {

        static var barScrollView: UInt8 = 0

        static var controllerScrollView: UInt8 = 0

        static var barScrollLine: UInt8 = 0

        static var currentButtonItem: UInt8 = 0

        static var preservedController: UInt8 = 0

        static var hasCompletedInitialLayout: UInt8 = 0

        static var clickOrScrollHandler: UInt8 = 0

        static var repeatClickHandler: UInt8 = 0

        static var itemDidLayoutHandler: UInt8 = 0

        static var barScrollLineLeftConstraint: UInt8 = 0

        static var barScrollLineWidthConstraint: UInt8 = 0

        static var isClickScrolling: UInt8 = 0

        static var lastAutoItemHeight: UInt8 = 0


        static var pageControllerIsLastDisplayed: UInt8 = 0
    }
}

/// UIViewController"是否已在WYPagingView中展示过"标记的存储(用于isFirstDisplayed回调判断)
extension UIViewController {

    /// Controller是否是第二次及以后在WYPagingView中显示
    var wy_pageControllerIsLastDisplayed: Bool {

        set(newValue) {
            // 防ASSOCIATION_ASSIGN不持有包装出的NSNumber导致后续读取野指针(目前靠tagged pointer侥幸不崩):换成RETAIN持有
            objc_setAssociatedObject(self, &WYPagingView.WYAssociatedKeys.pageControllerIsLastDisplayed, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYPagingView.WYAssociatedKeys.pageControllerIsLastDisplayed) as? Bool ?? false
        }
    }
}
