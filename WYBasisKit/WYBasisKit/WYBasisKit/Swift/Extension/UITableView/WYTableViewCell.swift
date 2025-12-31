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
        var responder: UIResponder? = self
        while let current = responder {
            if let tableView = current as? UITableView {
                return tableView
            }
            responder = current.next
        }
        return nil
    }
    
    /// 获取当前Cell的IndexPath
    var wy_currentIndexPath: IndexPath? {
        guard let parentTableView = wy_parentTableView else { return nil }
        return parentTableView.indexPath(for: self)
    }
    
    /// 当前 Cell 对应的 TableView 总共有几个 Section
    var wy_numberOfSectionsInTableView: Int {
        return wy_parentTableView?.numberOfSections ?? 0
    }
    
    /// 当前 Cell 对应的 Section 在 TableView 中的 Index
    var wy_sectionIndexInTableView: Int {
        return wy_currentIndexPath?.section ?? 0
    }
    
    /// 当前 Cell 对应的 Section 总共有几个 Item(Row)
    var wy_numberOfItemsInSection: Int {
        guard let tableView = wy_parentTableView,
              let indexPath = wy_currentIndexPath else { return 0 }
        return tableView.numberOfRows(inSection: indexPath.section)
    }
    
    /// 是否是 TableView 中的第一个 Section
    var wy_isFirstSectionInTableView: Bool {
        return wy_sectionIndexInTableView == 0
    }
    
    /// 是否是 TableView 中的最后一个 Section
    var wy_isLastSectionInTableView: Bool {
        guard wy_numberOfSectionsInTableView > 0 else { return false }
        return wy_sectionIndexInTableView == (wy_numberOfSectionsInTableView - 1)
    }
        
    /// 当前 Cell 对应的 Item(Row) 在 Section 中的 Index
    var wy_itemIndexInSection: Int {
        return wy_currentIndexPath?.row ?? 0
    }
    
    /// 是否是当前 Section 中的第一个 Item(Row)
    var wy_isFirstItemInSection: Bool {
        return wy_itemIndexInSection == 0
    }
    
    /// 是否是当前 Section 中的最后一个 Item(Row)
    var wy_isLastItemInSection: Bool {
        guard wy_numberOfItemsInSection > 0 else { return false }
        return wy_itemIndexInSection == (wy_numberOfItemsInSection - 1)
    }
}

public extension UITableViewCell {
    
    /// 左侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    var wy_leftSideslipWidth: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.leftSideslipWidth) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.leftSideslipWidth, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_updateSideslipViewLayout()
        }
    }
    
    /// 右侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    var wy_rightSideslipWidth: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.rightSideslipWidth) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.rightSideslipWidth, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_updateSideslipViewLayout()
        }
    }
    
    /// 侧滑方向，默认从右往左开始侧滑
    var wy_sideslipDirection: WYTableViewSideslipDirection {
        get {
            let rawValue = objc_getAssociatedObject(self, &WYAssociatedKeys.sideslipDirection) as? Int ?? 0
            return WYTableViewSideslipDirection(rawValue: rawValue) ?? .right
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.sideslipDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 左侧自定义侧滑视图（只读）
    var wy_leftSideslipView: UIView {
        if let view = objc_getAssociatedObject(self, &WYAssociatedKeys.leftSideslipView) as? UIView {
            return view
        }
        
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.leftSideslipView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return view
    }
    
    /// 右侧自定义侧滑视图（只读）
    var wy_rightSideslipView: UIView {
        if let view = objc_getAssociatedObject(self, &WYAssociatedKeys.rightSideslipView) as? UIView {
            return view
        }
        
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.rightSideslipView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return view
    }
    
    /// 是否已经打开侧滑
    var wy_isSideslipOpened: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.isSideslipOpened) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.isSideslipOpened, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 侧滑动画持续时间，默认0.5秒
    var wy_animationDuration: TimeInterval {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.animationDuration) as? TimeInterval ?? 0.5
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.animationDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 侧滑触发阈值（0.5 表示滑动超过一半宽度时触发）
    var wy_triggerThreshold: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.triggerThreshold) as? CGFloat ?? 0.5
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.triggerThreshold, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否开启长拉执行事件（默认false）
    var wy_enableLongPullAction: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.enableLongPullAction) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.enableLongPullAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉触发阈值（默认1.5，表示需要拉出侧滑宽度的1.5倍距离）
    var wy_longPullThreshold: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullThreshold) as? CGFloat ?? 1.5
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullThreshold, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉触发时的震动反馈（默认true）
    var wy_longPullHapticFeedback: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullHapticFeedback) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullHapticFeedback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 手势优先级（默认自动检测）
    var wy_gesturePriority: WYSideslipGesturePriority {
        get {
            let rawValue = objc_getAssociatedObject(self, &WYAssociatedKeys.gesturePriority) as? Int ?? 0
            return WYSideslipGesturePriority(rawValue: rawValue) ?? .autoSelection
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.gesturePriority, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.currentOpenedCellKey) as? UITableViewCell
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentOpenedCellKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
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

private extension UITableViewCell {
    
    /// 左侧滑容器视图
    var wy_leftSideslipContainer: UIView {
        if let view = objc_getAssociatedObject(self, &WYAssociatedKeys.leftSideslipContainer) as? UIView {
            return view
        }
        
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.leftSideslipContainer, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return view
    }
    
    /// 右侧滑容器视图
    var wy_rightSideslipContainer: UIView {
        if let view = objc_getAssociatedObject(self, &WYAssociatedKeys.rightSideslipContainer) as? UIView {
            return view
        }
        
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.rightSideslipContainer, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return view
    }
    
    /// 滑动手势
    var wy_panGesture: UIPanGestureRecognizer {
        if let gesture = objc_getAssociatedObject(self, &WYAssociatedKeys.panGesture) as? UIPanGestureRecognizer {
            return gesture
        }
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(wy_handlePan(_:)))
        gesture.delegate = self
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.panGesture, gesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return gesture
    }
    
    /// 点击手势
    var wy_tapGesture: UITapGestureRecognizer {
        if let gesture = objc_getAssociatedObject(self, &WYAssociatedKeys.tapGesture) as? UITapGestureRecognizer {
            return gesture
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(wy_handleTap(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        
        objc_setAssociatedObject(self, &WYAssociatedKeys.tapGesture, gesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return gesture
    }
    
    /// 当前侧滑方向
    var wy_currentSideslipDirection: WYTableViewSideslipDirection {
        get {
            let rawValue = objc_getAssociatedObject(self, &WYAssociatedKeys.currentSideslipDirection) as? Int ?? 0
            return WYTableViewSideslipDirection(rawValue: rawValue) ?? .right
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.currentSideslipDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 滑动手势起始点
    var wy_startPanPoint: CGPoint {
        get {
            if let value = objc_getAssociatedObject(self, &WYAssociatedKeys.startPanPoint) as? NSValue {
                return value.cgPointValue
            }
            return .zero
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.startPanPoint, NSValue(cgPoint: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 内容视图起始X坐标
    var wy_contentViewStartX: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.contentViewStartX) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.contentViewStartX, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 侧滑事件回调
    var wy_sideslipEventHandler: ((WYSideslipEventHandler, WYTableViewSideslipDirection) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.sideslipEventHandler) as? ((WYSideslipEventHandler, WYTableViewSideslipDirection) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.sideslipEventHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉进度回调（0.0 - 1.0）
    var wy_longPullProgress: ((CGFloat, WYTableViewSideslipDirection) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullProgress) as? ((CGFloat, WYTableViewSideslipDirection) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullProgress, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉完成回调
    var wy_longPullCompletion: ((WYTableViewSideslipDirection) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullCompletion) as? ((WYTableViewSideslipDirection) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullCompletion, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否已经触发了长拉事件
    var wy_longPullTriggered: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullTriggered) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉事件是否已确认（手指快速离开屏幕）
    var wy_longPullConfirmed: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullConfirmed) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullConfirmed, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 长拉最大进度值
    var wy_longPullMaxProgress: CGFloat {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.longPullMaxProgress) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.longPullMaxProgress, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 获取侧滑控件对应的宽度
    func wy_getSideslipViewWidth(direction: WYTableViewSideslipDirection = .right) -> CGFloat {
        return (direction == .right) ? wy_rightSideslipWidth : wy_leftSideslipWidth
    }
    
    /// 当前侧滑宽度（根据方向返回对应的宽度）
    private var wy_currentSideslipWidth: CGFloat {
        switch wy_currentSideslipDirection {
        case .left:
            return wy_leftSideslipWidth
        case .right:
            return wy_rightSideslipWidth
        case .both:
            // 在双向模式下，返回当前滑动方向对应的宽度
            return contentView.frame.origin.x > 0 ? wy_leftSideslipWidth : wy_rightSideslipWidth
        }
    }
    
    /// 恢复内容视图到初始位置（无论是否已打开侧滑）
    func wy_restoreContentView(animated: Bool, completion: (() -> Void)? = nil) {
        
        let tableView = wy_parentTableView
        if tableView?.wy_currentOpenedSideslipCell == self {
            tableView?.wy_currentOpenedSideslipCell = nil
        }
        
        wy_isSideslipOpened = false
        wy_currentSideslipDirection = .right
        wy_longPullTriggered = false
        wy_longPullConfirmed = false
        wy_longPullMaxProgress = 0
        
        // 重置侧滑视图到原始宽度
        wy_updateSideslipViewLayout()
        
        wy_animateContentView(to: 0, animated: animated) {
            tableView?.wy_sideslipViewDidDismiss = true
            completion?()
        }
    }
    
    /**
     * 更新侧滑视图布局
     * 根据侧滑宽度和方向调整左右侧滑视图的位置和大小
     */
    func wy_updateSideslipViewLayout(dynamicWidth: CGFloat? = nil) {
        let bounds = self.bounds
        
        // 使用动态宽度或原始宽度
        let leftWidth = dynamicWidth ?? wy_leftSideslipWidth
        let rightWidth = dynamicWidth ?? wy_rightSideslipWidth
        
        // 左侧滑容器（在 contentView 左侧，默认隐藏）
        wy_leftSideslipContainer.frame = CGRect(x: -leftWidth, y: 0, width: leftWidth, height: bounds.height)
        
        // 右侧滑容器（在 contentView 右侧，默认隐藏）
        wy_rightSideslipContainer.frame = CGRect(x: bounds.width, y: 0, width: rightWidth, height: bounds.height)
        
        // 自定义视图在侧滑容器内
        wy_leftSideslipView.frame = wy_leftSideslipContainer.bounds
        wy_rightSideslipView.frame = wy_rightSideslipContainer.bounds
        
        // 禁用侧滑时隐藏侧滑容器
        wy_leftSideslipContainer.isHidden = wy_leftSideslipWidth <= 0
        wy_rightSideslipContainer.isHidden = wy_rightSideslipWidth <= 0
    }
    
    /// 更新布局并保持侧滑状态
    func wy_updateLayoutAndMaintainSideslip() {
        // 调用原始布局更新
        wy_updateSideslipViewLayout()
        
        // 保持侧滑状态
        if wy_isSideslipOpened {
            let offset = wy_currentSideslipDirection == .left ? wy_leftSideslipWidth : -wy_rightSideslipWidth
            contentView.frame.origin.x = offset
        }
    }
    
    /**
     * 处理滑动手势
     * @param pan 滑动手势识别器
     */
    @objc func wy_handlePan(_ pan: UIPanGestureRecognizer) {
        
        // 检查是否有有效的侧滑宽度
        let hasLeftSideslip = wy_leftSideslipWidth > 0
        let hasRightSideslip = wy_rightSideslipWidth > 0
        guard hasLeftSideslip || hasRightSideslip else { return }
        
        let translation = pan.translation(in: self)
        let velocity = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            wy_startPanPoint = translation
            wy_contentViewStartX = contentView.frame.origin.x
            wy_longPullTriggered = false
            wy_longPullConfirmed = false
            wy_longPullMaxProgress = 0
            
            // 开始拖动时关闭其他已打开的 cell
            let tableView = wy_parentTableView
            tableView?.wy_closeCurrentOpenedSideslipCellIfNeeded(except: self)
            
        case .changed:
            var newX = wy_contentViewStartX + (translation.x - wy_startPanPoint.x)
            
            // 根据设置的侧滑方向限制滑动边界
            switch wy_sideslipDirection {
            case .left:
                // 左侧滑：只能向右滑动（显示左侧控件）
                newX = max(0, min(newX, wy_leftSideslipWidth * (wy_enableLongPullAction ? wy_longPullThreshold : 1.0)))
                wy_currentSideslipDirection = .left
                
            case .right:
                // 右侧滑：只能向左滑动（显示右侧控件）
                newX = min(0, max(newX, -wy_rightSideslipWidth * (wy_enableLongPullAction ? wy_longPullThreshold : 1.0)))
                wy_currentSideslipDirection = .right
                
            case .both:
                // 两侧滑：可以向左或向右滑动
                let leftMaxPull = wy_leftSideslipWidth * (wy_enableLongPullAction ? wy_longPullThreshold : 1.0)
                let rightMaxPull = wy_rightSideslipWidth * (wy_enableLongPullAction ? wy_longPullThreshold : 1.0)
                newX = max(-rightMaxPull, min(newX, leftMaxPull))
                
                // 根据实际滑动方向确定当前方向
                if newX > 0 {
                    wy_currentSideslipDirection = .left
                } else if newX < 0 {
                    wy_currentSideslipDirection = .right
                }
            }
            
            // 更新位置
            contentView.frame.origin.x = newX
            
            // 动态调整侧滑视图的宽度（长拉效果）
            if wy_enableLongPullAction {
                let progress = wy_calculateLongPullProgress(currentX: newX)
                
                // 更新最大进度值
                wy_longPullMaxProgress = max(wy_longPullMaxProgress, progress)
                
                // 动态调整侧滑视图宽度
                let currentWidth = wy_currentSideslipWidth
                let dynamicWidth = currentWidth + (progress * (currentWidth * (wy_longPullThreshold - 1.0)))
                
                // 根据当前滑动方向更新对应的侧滑视图
                switch wy_currentSideslipDirection {
                case .left:
                    // 向右滑动，更新左侧容器
                    var leftFrame = wy_leftSideslipContainer.frame
                    leftFrame.size.width = dynamicWidth
                    leftFrame.origin.x = -dynamicWidth
                    wy_leftSideslipContainer.frame = leftFrame
                    wy_leftSideslipView.frame = wy_leftSideslipContainer.bounds
                    
                case .right:
                    // 向左滑动，更新右侧容器
                    var rightFrame = wy_rightSideslipContainer.frame
                    rightFrame.size.width = dynamicWidth
                    rightFrame.origin.x = bounds.width
                    wy_rightSideslipContainer.frame = rightFrame
                    wy_rightSideslipView.frame = wy_rightSideslipContainer.bounds
                    
                case .both:
                    // 两侧都支持，根据实际滑动方向处理
                    if newX > 0 {
                        // 向右滑动，更新左侧
                        var leftFrame = wy_leftSideslipContainer.frame
                        leftFrame.size.width = dynamicWidth
                        leftFrame.origin.x = -dynamicWidth
                        wy_leftSideslipContainer.frame = leftFrame
                        wy_leftSideslipView.frame = wy_leftSideslipContainer.bounds
                    } else {
                        // 向左滑动，更新右侧
                        var rightFrame = wy_rightSideslipContainer.frame
                        rightFrame.size.width = dynamicWidth
                        rightFrame.origin.x = bounds.width
                        wy_rightSideslipContainer.frame = rightFrame
                        wy_rightSideslipView.frame = wy_rightSideslipContainer.bounds
                    }
                }
                
                wy_longPullProgress?(progress, wy_currentSideslipDirection)
                
                // 检查是否触发长拉事件（达到阈值但未确认）
                if progress >= 1.0 && !wy_longPullTriggered {
                    wy_longPullTriggered = true
                    if wy_longPullHapticFeedback {
                        wy_triggerHapticFeedback()
                    }
                }
            } else {
                // 未开启长拉时，确保使用原始布局
                wy_updateSideslipViewLayout()
            }
            
        case .ended, .cancelled:
            let currentX = contentView.frame.origin.x
            
            // 处理长拉确认逻辑（像苹果短信界面那样）
            if wy_enableLongPullAction && wy_longPullTriggered {
                // 检查是否是快速释放（速度足够快）并且当前进度超过确认阈值
                let isQuickRelease = abs(velocity.x) > 300
                let currentProgress = wy_calculateLongPullProgress(currentX: currentX)
                let shouldConfirmLongPull = isQuickRelease && currentProgress >= 0.9
                
                if shouldConfirmLongPull {
                    // 快速释放且当前进度足够高，确认执行长拉事件
                    wy_longPullConfirmed = true
                    wy_longPullCompletion?(wy_currentSideslipDirection)
                    // 执行长拉事件后，恢复到初始位置
                    wy_restoreContentView(animated: true)
                } else {
                    // 慢速释放或当前进度不够，取消长拉事件，使用弹性回弹
                    wy_longPullConfirmed = false
                    wy_elasticRestoreContentView()
                }
            } else {
                // 普通侧滑逻辑
                let shouldOpen: Bool
                let velocityThreshold: CGFloat = 500
                let currentWidth = wy_currentSideslipWidth
                
                if abs(velocity.x) > velocityThreshold {
                    // 快速滑动时根据速度方向决定
                    shouldOpen = (velocity.x > 0 && wy_currentSideslipDirection == .left) ||
                                (velocity.x < 0 && wy_currentSideslipDirection == .right)
                } else {
                    // 慢速滑动时根据位置决定，使用绝对值计算进度
                    let progress = abs(currentX) / currentWidth
                    shouldOpen = progress > wy_triggerThreshold
                }
                
                if shouldOpen {
                    wy_openSideslip(animated: true, direction: wy_currentSideslipDirection)
                } else {
                    // 当不应该打开时，确保完全恢复到初始位置
                    wy_restoreContentView(animated: true)
                }
            }
            
        default:
            break
        }
    }
    
    /**
     * 计算长拉进度
     * @param currentX 当前contentView的X坐标
     * @return 进度值（0.0 - 1.0）
     */
    func wy_calculateLongPullProgress(currentX: CGFloat) -> CGFloat {
        let currentWidth = wy_currentSideslipWidth
        
        let absoluteX = abs(currentX)
        let threshold = currentWidth
        let maxPull = currentWidth * wy_longPullThreshold
        
        if absoluteX <= threshold {
            return 0.0
        } else {
            return min(1.0, (absoluteX - threshold) / (maxPull - threshold))
        }
    }
    
    /**
     * 弹性恢复内容视图到初始位置
     * 用于长拉取消时的回弹效果
     */
    func wy_elasticRestoreContentView() {
        let tableView = wy_parentTableView
        if tableView?.wy_currentOpenedSideslipCell == self {
            tableView?.wy_currentOpenedSideslipCell = nil
        }
        
        wy_isSideslipOpened = false
        wy_currentSideslipDirection = .right
        wy_longPullTriggered = false
        wy_longPullConfirmed = false
        wy_longPullMaxProgress = 0
        
        // 重置侧滑视图到原始宽度
        wy_updateSideslipViewLayout()
        
        // 使用更弹性的动画
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
            self.contentView.frame.origin.x = 0
        })
    }
    
    /**
     * 触发触觉反馈
     */
    func wy_triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /**
     * 处理点击手势
     * @param tap 点击手势识别器
     */
    @objc func wy_handleTap(_ tap: UITapGestureRecognizer) {
        if wy_isSideslipOpened {
            wy_closeSideslip(animated: true)
        }
    }
    
    /**
     * 动画移动内容视图
     * @param x 目标X坐标
     * @param animated 是否启用动画
     * @param completion 动画完成回调
     */
    func wy_animateContentView(to x: CGFloat, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            // 使用更弹性的动画
            let damping: CGFloat = x == 0 ? 0.7 : 0.8
            UIView.animate(withDuration: wy_animationDuration,
                           delay: 0,
                           usingSpringWithDamping: damping,
                           initialSpringVelocity: 0.5,
                           options: [.curveEaseOut, .allowUserInteraction],
                           animations: {
                self.contentView.frame.origin.x = x
            }) { _ in
                completion?()
            }
        } else {
            contentView.frame.origin.x = x
            completion?()
        }
    }
    
    /// 关联对象键值
    struct WYAssociatedKeys {
        static var leftSideslipWidth: UInt8 = 0
        static var rightSideslipWidth: UInt8 = 0
        static var sideslipDirection: UInt8 = 0
        static var leftSideslipView: UInt8 = 0
        static var rightSideslipView: UInt8 = 0
        static var isSideslipOpened: UInt8 = 0
        static var leftSideslipContainer: UInt8 = 0
        static var rightSideslipContainer: UInt8 = 0
        static var panGesture: UInt8 = 0
        static var tapGesture: UInt8 = 0
        static var currentSideslipDirection: UInt8 = 0
        static var animationDuration: UInt8 = 0
        static var triggerThreshold: UInt8 = 0
        static var startPanPoint: UInt8 = 0
        static var contentViewStartX: UInt8 = 0
        static var enableLongPullAction: UInt8 = 0
        static var longPullThreshold: UInt8 = 0
        static var longPullHapticFeedback: UInt8 = 0
        static var longPullProgress: UInt8 = 0
        static var longPullCompletion: UInt8 = 0
        static var longPullTriggered: UInt8 = 0
        static var gesturePriority: UInt8 = 0
        static var longPullConfirmed: UInt8 = 0
        static var longPullMaxProgress: UInt8 = 0
        static var sideslipEventHandler: UInt8 = 0
    }
}

private extension UITableViewCell {
    
    /// 交换layoutSubviews方法实现
    static let wy_swizzleLayoutSubviews: Void = {
        let originalSelector = #selector(layoutSubviews)
        let swizzledSelector = #selector(wy_layoutSubviews)
        
        guard let originalMethod = class_getInstanceMethod(UITableViewCell.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITableViewCell.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc func wy_layoutSubviews() {
        // 调用原始实现
        self.wy_layoutSubviews()
        
        // 更新侧滑布局
        wy_updateLayoutAndMaintainSideslip()
    }
    
    /// 启用侧滑功能特性
    static func wy_enableSideslipFeature() {
        _ = wy_swizzleLayoutSubviews
    }
}

private extension UIScrollView {
    
    /// 交换touchesBegan方法实现
    static let wy_swizzleTouchesBegan: Void = {
        let originalSelector = #selector(touchesBegan(_:with:))
        let swizzledSelector = #selector(wy_touchesBegan(_:with:))
        
        guard let originalMethod = class_getInstanceMethod(UIScrollView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIScrollView.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    /**
     * 处理触摸开始事件
     * @param touches 触摸集合
     * @param event 事件对象
     */
    @objc func wy_touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 确保在触摸开始时关闭已侧滑的cell
        if let tableView = self as? UITableView {
            tableView.wy_closeCurrentOpenedSideslipCellIfNeeded()
        }
        self.wy_touchesBegan(touches, with: event)
    }
}

private extension UITableView {
    
    /// 获取父级UIViewController
    var wy_parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
    
    /// 侧滑区域已完全关闭(区别于wy_isSideslipOpened属性，因为wy_isSideslipOpened可能动画还未完全执行完毕，用这个属性来拦截处理侧滑区域展示期间cell的点击事件)
    var wy_sideslipViewDidDismiss: Bool {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.sideslipViewDidDismiss) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.sideslipViewDidDismiss, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 交换hitTest方法实现
    private static let swizzleHitTest: Void = {
        let originalSelector = #selector(hitTest(_:with:))
        let swizzledSelector = #selector(wy_hitTest(_:with:))
        
        guard let originalMethod = class_getInstanceMethod(UITableView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITableView.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    /**
     * 处理hitTest事件
     * @param point 触摸点
     * @param event 事件对象
     * @return 响应的视图
     */
    @objc private func wy_hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 如果当前有打开的侧滑 cell
        if let cell = wy_currentOpenedSideslipCell, cell.wy_isSideslipOpened {
            
            // 检查左侧滑视图
            let pointInLeftView = convert(point, to: cell.wy_leftSideslipContainer)
            if cell.wy_leftSideslipContainer.bounds.contains(pointInLeftView) {
                // 让侧滑视图自己处理 hitTest
                let hitView = cell.wy_leftSideslipContainer.hitTest(pointInLeftView, with: event)
                if hitView != nil {
                    return hitView
                }
            }
            
            // 检查右侧滑视图
            let pointInRightView = convert(point, to: cell.wy_rightSideslipContainer)
            if cell.wy_rightSideslipContainer.bounds.contains(pointInRightView) {
                // 让侧滑视图自己处理 hitTest
                let hitView = cell.wy_rightSideslipContainer.hitTest(pointInRightView, with: event)
                if hitView != nil {
                    return hitView
                }
            }
            
            // 点击在别处，关闭侧滑
            cell.wy_closeSideslip(animated: true)
        }
        
        // 如果侧滑区域还未关闭或者关闭动画还未执行完毕，此时点击事件落在在非侧滑区域，就return一个nil出去，避免侧滑期间，点击cell后响应cell上控件的点击事件
        if wy_sideslipViewDidDismiss == false {
            return nil
        }
        
        // 走原始 hitTest 行为
        return self.wy_hitTest(point, with: event)
    }
    
    /// 关联对象键值
    struct WYAssociatedKeys {
        static var currentOpenedCellKey: UInt8 = 0
        static var sideslipViewDidDismiss: UInt8 = 0
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
        // 允许与 UITableView 的手势同时识别
        if otherGestureRecognizer.view is UITableView {
            return true
        }
        
        // 与导航栏返回手势同时识别
        if let navController = wy_parentTableView?.wy_parentViewController?.navigationController,
           otherGestureRecognizer == navController.interactivePopGestureRecognizer {
            return true
        }
        
        return false
    }
    
    /**
     * 手势识别器是否应该接收触摸事件
     * @param gestureRecognizer 手势识别器
     * @param touch 触摸事件
     * @return 是否应该接收触摸事件
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == wy_tapGesture {
            // 点击手势只在侧滑打开时生效
            return wy_isSideslipOpened
        }
        
        if gestureRecognizer == wy_panGesture {
            // 如果侧滑被禁用，不处理滑动手势
            if wy_leftSideslipWidth <= 0 && wy_rightSideslipWidth <= 0 {
                return false
            }
            
            // 检查是否在滚动，如果是则优先滚动
            if let tableView = wy_parentTableView {
                if tableView.isDragging || tableView.isDecelerating {
                    return false
                }
            }
            
            // 如果触摸点在侧滑按钮上，不处理滑动手势，让按钮接收事件
            if wy_isSideslipOpened {
                let location = touch.location(in: self)
                let currentWidth = wy_currentSideslipWidth
                
                // 计算侧滑按钮在当前 cell 中的实际位置
                var sideslipFrame = CGRect.zero
                if wy_currentSideslipDirection == .left {
                    sideslipFrame = CGRect(x: 0, y: 0, width: currentWidth, height: bounds.height)
                } else {
                    sideslipFrame = CGRect(x: bounds.width - currentWidth, y: 0, width: currentWidth, height: bounds.height)
                }
                
                // 如果点击在侧滑按钮区域，不处理滑动手势
                if sideslipFrame.contains(location) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /**
     * 手势识别器是否应该开始识别
     * @param gestureRecognizer 手势识别器
     * @return 是否应该开始识别
     */
    @objc public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == wy_panGesture {
            let translation = wy_panGesture.translation(in: self)
            
            // 检查是否是水平滑动
            let isHorizontal = abs(translation.x) > abs(translation.y)
            if !isHorizontal {
                return false
            }
            
            // 根据手势优先级处理导航栏返回手势冲突
            let location = wy_panGesture.location(in: self)
            let isFromLeftEdge = location.x < 30
            
            switch wy_gesturePriority {
            case .sideslipFirst:
                // 侧滑优先：总是允许侧滑手势
                break
                
            case .navigationBackFirst:
                // 导航栏返回优先：从左侧边缘开始时禁用侧滑
                if isFromLeftEdge {
                    return false
                }
                
            case .autoSelection:
                // 自动检测：根据cell支持的滑动方向和触摸位置智能判断
                if isFromLeftEdge {
                    // 从左侧边缘开始
                    if wy_sideslipDirection == .right {
                        // 如果cell只支持右侧滑，从左侧开始的手势应该交给导航栏
                        return false
                    }
                    // 检查是否有导航控制器且不是根视图控制器
                    if let navController = wy_parentTableView?.wy_parentViewController?.navigationController,
                       navController.viewControllers.count > 1,
                       navController.interactivePopGestureRecognizer?.isEnabled == true {
                        // 如果有导航控制器且可以返回，优先交给导航栏返回手势
                        return false
                    }
                }
            }
            
            // 根据滑动方向检查是否允许
            if translation.x > 0 {
                // 向右滑动：只有在支持左侧滑或两侧滑时才允许（显示左侧控件）
                return wy_sideslipDirection == .left || wy_sideslipDirection == .both
            } else {
                // 向左滑动：只有在支持右侧滑或两侧滑时才允许（显示右侧控件）
                return wy_sideslipDirection == .right || wy_sideslipDirection == .both
            }
        }
        return true
    }
}
