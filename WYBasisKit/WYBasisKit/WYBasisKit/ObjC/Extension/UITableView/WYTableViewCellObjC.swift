//
//  WYTableViewCell.swift
//  WYBasisKit
//
//  Created by guanren on 2025/11/15.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

/// UITableViewCell侧滑方向
@objc(WYTableViewSideslipDirection)
@frozen public enum WYTableViewSideslipDirectionObjC: Int {
    
    /// 右侧开启侧滑(从右往左侧滑)
    case right = 0
    /// 左侧开启侧滑(从左往右侧滑)
    case left
    /// 两侧都开启侧滑
    case both
}

/// 手势优先级
@objc(WYSideslipGesturePriority)
@frozen public enum WYSideslipGesturePriorityObjC: Int {
    
    /// 自动检查后选择，如果从边缘开始滑动时优先导航栏手势，如果从左侧边缘30pt内开始就优先侧滑手势
    case autoSelection = 0
    /// 侧滑手势优先
    case sideslipFirst
    /// 导航栏返回手势优先
    case navigationBackFirst
}

/// 侧滑事件回调
@objc(WYSideslipEventHandler)
@frozen public enum WYSideslipEventHandlerObjC: Int {
    
    /// 即将打开侧滑区域
    case willOpenSideslip = 0
    /// 已经打开侧滑区域
    case didOpenSideslip
    /// 即将关闭侧滑区域
    case willCloseSideslip
    /// 已经关闭侧滑区域
    case didCloseSideslip
}

@objc public extension UITableViewCell {
    
    /// 获取父级UITableView
    @objc(wy_parentTableView)
    var wy_parentTableViewObjC: UITableView? {
        return wy_parentTableView
    }
    
    /// 获取当前Cell的IndexPath
    @objc(wy_currentIndexPath)
    var wy_currentIndexPathObjC: IndexPath? {
        return wy_currentIndexPath
    }
    
    /// 当前 Cell 对应的 TableView 总共有几个 Section
    @objc(wy_numberOfSectionsInTableView)
    var wy_numberOfSectionsInTableViewObjC: Int {
        return wy_numberOfSectionsInTableView
    }
    
    /// 当前 Cell 对应的 Section 在 TableView 中的 Index
    @objc(wy_sectionIndexInTableView)
    var wy_sectionIndexInTableViewObjC: Int {
        return wy_sectionIndexInTableView
    }
    
    /// 当前 Cell 对应的 Section 总共有几个 Item(Row)
    @objc(wy_numberOfItemsInSection)
    var wy_numberOfItemsInSectionObjC: Int {
        return wy_numberOfItemsInSection
    }
    
    /// 是否是 TableView 中的第一个 Section
    @objc(wy_isFirstSectionInTableView)
    var wy_isFirstSectionInTableViewObjC: Bool {
        return wy_isFirstSectionInTableView
    }
    
    /// 是否是 TableView 中的最后一个 Section
    @objc(wy_isLastSectionInTableView)
    var wy_isLastSectionInTableViewObjc: Bool {
        return wy_isLastSectionInTableView
    }
        
    /// 当前 Cell 对应的 Item(Row) 在 Section 中的 Index
    @objc(wy_itemIndexInSection)
    var wy_itemIndexInSectionObjC: Int {
        return wy_itemIndexInSection
    }
    
    /// 是否是当前 Section 中的第一个 Item(Row)
    @objc(wy_isFirstItemInSection)
    var wy_isFirstItemInSectionObjC: Bool {
        return wy_isFirstItemInSection
    }
    
    /// 是否是当前 Section 中的最后一个 Item(Row)
    @objc(wy_isLastItemInSection)
    var wy_isLastItemInSectionObjC: Bool {
        return wy_isLastItemInSection
    }
}

@objc public extension UITableViewCell {
    
    /// 左侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    @objc(wy_leftSideslipWidth)
    var wy_leftSideslipWidthObjC: CGFloat {
        get {
            return wy_leftSideslipWidth
        }
        set {
            wy_leftSideslipWidth = newValue
        }
    }
    
    /// 右侧滑区域的宽度（默认0，为0时表示禁用侧滑）
    @objc(wy_rightSideslipWidth)
    var wy_rightSideslipWidthObjC: CGFloat {
        get {
            return wy_rightSideslipWidth
        }
        set {
            wy_rightSideslipWidth = newValue
        }
    }
    
    /// 侧滑方向，默认从右往左开始侧滑
    @objc(wy_sideslipDirection)
    var wy_sideslipDirectionObjC: WYTableViewSideslipDirectionObjC {
        get {
            return WYTableViewSideslipDirectionObjC(rawValue: wy_sideslipDirection.rawValue) ?? .right
        }
        set {
            wy_sideslipDirection = WYTableViewSideslipDirection(rawValue: newValue.rawValue) ?? .right
        }
    }
    
    /// 左侧自定义侧滑视图（只读）
    @objc(wy_leftSideslipView)
    var wy_leftSideslipViewObjC: UIView {
        return wy_leftSideslipView
    }
    
    /// 右侧自定义侧滑视图（只读）
    @objc(wy_rightSideslipView)
    var wy_rightSideslipViewObjC: UIView {
        return wy_rightSideslipView
    }
    
    /// 是否已经打开侧滑
    @objc(wy_isSideslipOpened)
    var wy_isSideslipOpenedObjC: Bool {
        get {
            return wy_isSideslipOpened
        }
        set {
            wy_isSideslipOpened = newValue
        }
    }
    
    /// 侧滑动画持续时间，默认0.5秒
    @objc(wy_animationDuration)
    var wy_animationDurationObjC: TimeInterval {
        get {
            return wy_animationDuration
        }
        set {
            wy_animationDuration = newValue
        }
    }
    
    /// 侧滑触发阈值（0.5 表示滑动超过一半宽度时触发）
    @objc(wy_triggerThreshold)
    var wy_triggerThresholdObjC: CGFloat {
        get {
            return wy_triggerThreshold
        }
        set {
            wy_triggerThreshold = newValue
        }
    }
    
    /// 是否开启长拉执行事件（默认false）
    @objc(wy_enableLongPullAction)
    var wy_enableLongPullActionObjC: Bool {
        get {
            return wy_enableLongPullAction
        }
        set {
            wy_enableLongPullAction = newValue
        }
    }
    
    /// 长拉触发阈值（默认1.5，表示需要拉出侧滑宽度的1.5倍距离）
    @objc(wy_longPullThreshold)
    var wy_longPullThresholdObjC: CGFloat {
        get {
            return wy_longPullThreshold
        }
        set {
            wy_longPullThreshold = newValue
        }
    }
    
    /// 长拉触发时的震动反馈（默认true）
    @objc(wy_longPullHapticFeedback)
    var wy_longPullHapticFeedbackObjC: Bool {
        get {
            return wy_longPullHapticFeedback
        }
        set {
            wy_longPullHapticFeedback = newValue
        }
    }
    
    /// 手势优先级（默认自动检测）
    @objc(wy_gesturePriority)
    var wy_gesturePriorityObjC: WYSideslipGesturePriorityObjC {
        get {
            return WYSideslipGesturePriorityObjC(rawValue: wy_gesturePriority.rawValue) ?? .autoSelection
        }
        set {
            wy_gesturePriority = WYSideslipGesturePriority(rawValue: newValue.rawValue) ?? .autoSelection
        }
    }
    
    /// 设置侧滑事件回调
    @objc(wy_sideslipEventHandler:)
    func wy_sideslipEventHandlerObjC(_ handler: (@convention(block) (WYSideslipEventHandlerObjC, WYTableViewSideslipDirectionObjC) -> Void)? = nil) {
        
        if let handler = handler {
            let swiftHandler: (WYSideslipEventHandler, WYTableViewSideslipDirection) -> Void =
            { swiftEvent, swiftDirection in
                
                let eventObjC = WYSideslipEventHandlerObjC(rawValue: swiftEvent.rawValue)
                ?? .willOpenSideslip
                
                let directionObjC = WYTableViewSideslipDirectionObjC(rawValue: swiftDirection.rawValue)
                ?? .right
                
                handler(eventObjC, directionObjC)
            }
            
            wy_sideslipEventHandler(swiftHandler)
        } else {
            wy_sideslipEventHandler(nil)
        }
    }
        
    /// 设置长拉事件回调
    @objc(wy_sideslipLongPullHandlerWithProgress:completion:)
    func wy_sideslipLongPullHandlerObjC(progress: (@convention(block) (CGFloat, WYTableViewSideslipDirectionObjC) -> Void)? = nil, completion: (@convention(block) (WYTableViewSideslipDirectionObjC) -> Void)? = nil) {
        
        let swiftProgress: ((CGFloat, WYTableViewSideslipDirection) -> Void)? = {
            guard let progress = progress else { return nil }
            return { value, swiftDirection in
                let objcDirection = WYTableViewSideslipDirectionObjC(rawValue: swiftDirection.rawValue)
                ?? .right
                progress(value, objcDirection)
            }
        }()
        
        let swiftCompletion: ((WYTableViewSideslipDirection) -> Void)? = {
            guard let completion = completion else { return nil }
            return { swiftDirection in
                let objcDirection = WYTableViewSideslipDirectionObjC(rawValue: swiftDirection.rawValue)
                ?? .right
                completion(objcDirection)
            }
        }()
        
        wy_sideslipLongPullHandler(progress: swiftProgress,completion: swiftCompletion)
    }
    
    /// 启用侧滑功能（需要在 cell 初始化后调用）
    @objc(wy_enableSideslip)
    func wy_enableSideslipObjC() {
        wy_enableSideslip()
    }
    
    /// 设置自定义侧滑视图
    @objc(wy_setSideslipView:direction:)
    func wy_setSideslipViewObjC(_ view: UIView, for direction: WYTableViewSideslipDirectionObjC = .right) {
        wy_setSideslipView(view, for: WYTableViewSideslipDirection(rawValue: direction.rawValue) ?? .right)
    }
    
    /// 打开侧滑区域
    @objc(wy_openSideslipWithAnimated:direction:)
    func wy_openSideslipObjC(animated: Bool, direction: WYTableViewSideslipDirectionObjC = .right) {
        wy_openSideslip(animated: animated, direction: WYTableViewSideslipDirection(rawValue: direction.rawValue) ?? .right)
    }
    
    /// 关闭侧滑区域
    @objc(wy_closeSideslipWithAnimated:)
    func wy_closeSideslipObjC(animated: Bool) {
        guard wy_isSideslipOpened else { return }
        wy_closeSideslip(animated: animated)
    }
    
    /// 重置侧滑状态（用于cell重用）
    @objc(wy_resetSideslipState)
    func wy_resetSideslipStateObjC() {
        wy_resetSideslipState()
    }
}

@objc public extension UITableView {
    
    /// 启用自动关闭侧滑功能（只需要调用一次）
    @objc(wy_enableAutoCloseSideslip)
    static func wy_enableAutoCloseSideslipObjC() {
        wy_enableAutoCloseSideslip()
    }
    
    /// 当前打开的侧滑cell
    @objc(wy_currentOpenedSideslipCell)
    weak var wy_currentOpenedSideslipCellObjC: UITableViewCell? {
        get {
            return wy_currentOpenedSideslipCell
        }
        set {
            wy_currentOpenedSideslipCell = newValue
        }
    }
    
    /**
     * 关闭当前打开的侧滑cell（如果需要）
     * @param cell 需要排除的cell（不关闭此cell）
     */
    @objc(wy_closeCurrentOpenedSideslipCellIfNeededExceptCell:)
    func wy_closeCurrentOpenedSideslipCellIfNeededObjC(except cell: UITableViewCell? = nil) {
        wy_closeCurrentOpenedSideslipCellIfNeeded(except: cell)
    }
    
    /**
     * 重置所有可见cell的侧滑状态
     * 在数据刷新、页面显示等场景下调用，避免cell重用导致的显示问题
     */
    @objc(wy_resetAllVisibleCellsSideslipState)
    func wy_resetAllVisibleCellsSideslipStateObjC() {
        wy_resetAllVisibleCellsSideslipState()
    }
}
