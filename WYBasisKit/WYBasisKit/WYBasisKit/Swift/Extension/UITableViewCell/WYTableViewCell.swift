//
//  WYTableViewCell.swift
//  WYBasisKit
//
//  Created by guanren on 2025/11/15.
//

import UIKit

/// UITableViewCell侧滑方向
@frozen public enum WYTableViewSideslipDirection: Int {
    /// 右侧开启侧滑(从右往左侧滑)
    case right = 0
    /// 左侧开启侧滑(从左往右侧滑)
    case left
    /// 两侧都开启侧滑
    case both
}

/// 手势优先级
@frozen public enum WYSideslipGesturePriority: Int {
    
    /// 自动检查后选择，如果从边缘开始滑动时优先导航栏手势，如果从左侧边缘30pt内开始就优先侧滑手势
    case autoSelection = 0
    /// 侧滑手势优先
    case sideslipFirst
    /// 导航栏返回手势优先
    case navigationBackFirst
}

/// 侧滑事件回调
@frozen public enum WYSideslipEventHandler: Int {
    
    /// 即将打开侧滑区域
    case willOpenSideslip = 0
    /// 已经打开侧滑区域
    case didOpenSideslip
    /// 即将关闭侧滑区域
    case willCloseSideslip
    /// 已经关闭侧滑区域
    case didCloseSideslip
}

public extension UITableViewCell {
    
    /// 获取父级UITableView
    var wy_parentTableView: UITableView? {
        get { return wy_impl_parentTableView }
    }
    
    /// 获取当前Cell的IndexPath
    var wy_currentIndexPath: IndexPath? {
        get { return wy_impl_currentIndexPath }
    }
    
    /// 当前 Cell 对应的 TableView 总共有几个 Section
    var wy_numberOfSectionsInTableView: Int {
        get { return wy_impl_numberOfSectionsInTableView }
    }
    
    /// 当前 Cell 对应的 Section 在 TableView 中的 Index
    var wy_sectionIndexInTableView: Int {
        get { return wy_impl_sectionIndexInTableView }
    }
    
    /// 当前 Cell 对应的 Section 总共有几个 Item(Row)
    var wy_numberOfItemsInSection: Int {
        get { return wy_impl_numberOfItemsInSection }
    }
    
    /// 是否是 TableView 中的第一个 Section
    var wy_isFirstSectionInTableView: Bool {
        get { return wy_impl_isFirstSectionInTableView }
    }
    
    /// 是否是 TableView 中的最后一个 Section
    var wy_isLastSectionInTableView: Bool {
        get { return wy_impl_isLastSectionInTableView }
    }
    
    /// 当前 Cell 对应的 Item(Row) 在 Section 中的 Index
    var wy_itemIndexInSection: Int {
        get { return wy_impl_itemIndexInSection }
    }
    
    /// 是否是当前 Section 中的第一个 Item(Row)
    var wy_isFirstItemInSection: Bool {
        get { return wy_impl_isFirstItemInSection }
    }
    
    /// 是否是当前 Section 中的最后一个 Item(Row)
    var wy_isLastItemInSection: Bool {
        get { return wy_impl_isLastItemInSection }
    }
}

public extension UITableViewCell {
    
    /// 左侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    var wy_leftSideslipWidth: CGFloat {
        get { return wy_impl_leftSideslipWidth }
        set { wy_impl_leftSideslipWidth = newValue }
    }
    
    /// 右侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    var wy_rightSideslipWidth: CGFloat {
        get { return wy_impl_rightSideslipWidth }
        set { wy_impl_rightSideslipWidth = newValue }
    }
    
    /// 侧滑方向，默认从右往左开始侧滑
    var wy_sideslipDirection: WYTableViewSideslipDirection {
        get { return wy_impl_sideslipDirection }
        set { wy_impl_sideslipDirection = newValue }
    }
    
    /// 左侧自定义侧滑视图（只读）
    var wy_leftSideslipView: UIView {
        get { return wy_impl_leftSideslipView }
    }
    
    /// 右侧自定义侧滑视图（只读）
    var wy_rightSideslipView: UIView {
        get { return wy_impl_rightSideslipView }
    }
    
    /// 是否已经打开侧滑
    var wy_isSideslipOpened: Bool {
        get { return wy_impl_isSideslipOpened }
        set { wy_impl_isSideslipOpened = newValue }
    }
    
    /// 侧滑动画持续时间，默认0.5秒
    var wy_animationDuration: TimeInterval {
        get { return wy_impl_animationDuration }
        set { wy_impl_animationDuration = newValue }
    }
    
    /// 侧滑触发阈值（0.5 表示滑动超过一半宽度时触发）
    var wy_triggerThreshold: CGFloat {
        get { return wy_impl_triggerThreshold }
        set { wy_impl_triggerThreshold = newValue }
    }
    
    /// 是否开启长拉执行事件（默认false）
    var wy_enableLongPullAction: Bool {
        get { return wy_impl_enableLongPullAction }
        set { wy_impl_enableLongPullAction = newValue }
    }
    
    /// 长拉触发阈值（默认1.5，表示需要拉出侧滑宽度的1.5倍距离）
    var wy_longPullThreshold: CGFloat {
        get { return wy_impl_longPullThreshold }
        set { wy_impl_longPullThreshold = newValue }
    }
    
    /// 长拉触发时的震动反馈（默认true）
    var wy_longPullHapticFeedback: Bool {
        get { return wy_impl_longPullHapticFeedback }
        set { wy_impl_longPullHapticFeedback = newValue }
    }
    
    /// 手势优先级（默认自动检测）
    var wy_gesturePriority: WYSideslipGesturePriority {
        get { return wy_impl_gesturePriority }
        set { wy_impl_gesturePriority = newValue }
    }
    
    /// 设置侧滑事件回调
    func wy_sideslipEventHandler(_ handler: ((WYSideslipEventHandler, WYTableViewSideslipDirection) -> Void)? = nil) {
        wy_sideslipEventHandler = handler
    }
    
    /// 设置长拉事件回调
    func wy_sideslipLongPullHandler(progress: ((CGFloat, WYTableViewSideslipDirection) -> Void)? = nil, completion: ((WYTableViewSideslipDirection) -> Void)? = nil) {
        wy_longPullProgress = progress
        wy_longPullCompletion = completion
    }
    
    /// 启用侧滑功能（需要在 cell 初始化后调用）
    func wy_enableSideslip() {
        // 确保方法交换只执行一次
        UITableViewCell.wy_enableSideslipFeature()
        
        // 添加侧滑容器视图
        if wy_leftSideslipContainer.superview == nil {
            contentView.addSubview(wy_leftSideslipContainer)
        }
        if wy_rightSideslipContainer.superview == nil {
            contentView.addSubview(wy_rightSideslipContainer)
        }
        
        // 添加自定义视图到侧滑容器
        if wy_leftSideslipView.superview == nil {
            wy_leftSideslipContainer.addSubview(wy_leftSideslipView)
        }
        
        if wy_rightSideslipView.superview == nil {
            wy_rightSideslipContainer.addSubview(wy_rightSideslipView)
        }
        
        // 添加手势
        if !contentView.gestureRecognizers!.contains(wy_panGesture) {
            contentView.addGestureRecognizer(wy_panGesture)
        }
        
        if !contentView.gestureRecognizers!.contains(wy_tapGesture) {
            contentView.addGestureRecognizer(wy_tapGesture)
        }
        
        // 初始布局
        wy_updateSideslipViewLayout()
    }
    
    /// 设置自定义侧滑视图
    func wy_setSideslipView(_ view: UIView, for direction: WYTableViewSideslipDirection = .right) {
        if direction == .left {
            // 移除旧的子视图
            wy_leftSideslipView.subviews.forEach { $0.removeFromSuperview() }
            
            // 确保容器视图可以交互
            wy_leftSideslipView.isUserInteractionEnabled = true
            
            // 添加新的自定义视图
            wy_leftSideslipView.addSubview(view)
            view.frame = wy_leftSideslipView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else {
            // 移除旧的子视图
            wy_rightSideslipView.subviews.forEach { $0.removeFromSuperview() }
            
            // 确保容器视图可以交互
            wy_rightSideslipView.isUserInteractionEnabled = true
            
            // 添加新的自定义视图
            wy_rightSideslipView.addSubview(view)
            view.frame = wy_rightSideslipView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    /// 打开侧滑区域
    func wy_openSideslip(animated: Bool, direction: WYTableViewSideslipDirection = .right) {
        
        let sideslipWidth: CGFloat = wy_getSideslipViewWidth(direction: direction)
        
        guard sideslipWidth > 0 else { return }
        
        let tableView = wy_parentTableView
        // 打开新cell时关闭其他已打开的cell
        tableView?.wy_closeCurrentOpenedSideslipCellIfNeeded(except: self)
        
        tableView?.wy_sideslipViewDidDismiss = false
        
        // 发送即将打开侧滑事件
        wy_sideslipEventHandler?(.willOpenSideslip, direction)
        
        wy_currentSideslipDirection = direction
        wy_isSideslipOpened = true
        
        tableView?.wy_currentOpenedSideslipCell = self
        
        // 确保使用原始侧滑宽度（打开侧滑时不应该有长拉效果）
        wy_updateSideslipViewLayout()
        
        let targetX = direction == .left ? sideslipWidth : -sideslipWidth
        wy_animateContentView(to: targetX, animated: animated) {
            // 发送已经打开侧滑事件
            self.wy_sideslipEventHandler?(.didOpenSideslip, direction)
        }
    }
    
    /// 关闭侧滑区域
    func wy_closeSideslip(animated: Bool) {
        guard wy_isSideslipOpened else { return }
        
        // 保存当前方向，因为恢复过程中会被重置
        let currentDirection = wy_currentSideslipDirection
        
        // 发送即将关闭侧滑事件
        wy_sideslipEventHandler?(.willCloseSideslip, currentDirection)
        
        wy_restoreContentView(animated: animated) {
            // 发送已经关闭侧滑事件，使用保存的方向
            self.wy_sideslipEventHandler?(.didCloseSideslip, currentDirection)
        }
    }
    
    /// 重置侧滑状态（用于cell重用）
    func wy_resetSideslipState() {
        wy_isSideslipOpened = false
        wy_longPullTriggered = false
        wy_longPullConfirmed = false
        contentView.frame.origin.x = 0
    }
}

public extension UITableView {
    
    /// 启用自动关闭侧滑功能（只需要调用一次）
    static func wy_enableAutoCloseSideslip() {
        _ = swizzleHitTest
        _ = UIScrollView.wy_swizzleTouchesBegan
    }
    
    /// 当前打开的侧滑cell
    weak var wy_currentOpenedSideslipCell: UITableViewCell? {
        get { return wy_impl_currentOpenedSideslipCell }
        set { wy_impl_currentOpenedSideslipCell = newValue }
    }
    
    /**
     * 关闭当前打开的侧滑cell（如果需要）
     * @param cell 需要排除的cell（不关闭此cell）
     */
    func wy_closeCurrentOpenedSideslipCellIfNeeded(except cell: UITableViewCell? = nil) {
        if let openedCell = wy_currentOpenedSideslipCell, openedCell != cell {
            openedCell.wy_closeSideslip(animated: true)
        }
    }
    
    /**
     * 重置所有可见cell的侧滑状态
     * 在数据刷新、页面显示等场景下调用，避免cell重用导致的显示问题
     */
    func wy_resetAllVisibleCellsSideslipState() {
        visibleCells.forEach { $0.wy_resetSideslipState() }
    }
}


extension UITableViewCell {
    
    /**
     * 手势识别器是否应该同时识别其他手势
     * @param gestureRecognizer 当前手势识别器
     * @param otherGestureRecognizer 其他手势识别器
     * @return 是否允许同时识别
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return wy_shouldRecognizeSimultaneously(gestureRecognizer, otherGestureRecognizer: otherGestureRecognizer)
    }
    
    /**
     * 手势识别器是否应该接收触摸事件
     * @param gestureRecognizer 手势识别器
     * @param touch 触摸事件
     * @return 是否应该接收触摸事件
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return wy_shouldReceive(gestureRecognizer, touch: touch)
    }
}
