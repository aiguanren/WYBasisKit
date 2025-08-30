//
//  UITableView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

/// UITableView注册类型
@frozen public enum WYTableViewRegisterStyle {
    
    /// 注册Cell
    case cell
    /// 注册HeaderFooterView
    case headerFooterView
}

public extension UITableView {
    
    /* UITableView.Style 区别
     
     * plain模式：
                1、如果实现了viewForHeaderInSection、viewForFooterInSection方法之一或两个都实现了，则与之对应的header或者footer在滑动的时候会有悬浮效果
     
                2、如果实现了heightForHeaderInSection、heightForFooterInSection方法之一或两个都实现了，则header或footer的高度会显示为传入的高度，相反，则不会显示header或footer，与之对应的高度也会自动置零
     
                3、该模式下实现对应代理方法后可以在右侧显示分区索引，参考手机通讯录界面可理解
     
                4、有header或footer的时候，header或footer会有个默认的背景色
     
     * grouped模式：
                1、该模式下header、footer不会有悬浮效果
     
                2、该模式下header、footer会有默认高度，如果不需要显示高度，可以设置为0.01
     
                3、默认背景色为透明
     */
    
    /// 创建一个UITableView
    class func wy_shared(frame: CGRect = .zero,
                         style: UITableView.Style = .plain,
                         headerHeight: CGFloat = UITableView.automaticDimension,
                         footerHeight: CGFloat = UITableView.automaticDimension,
                         rowHeight: CGFloat = UITableView.automaticDimension,
                         separatorStyle: UITableViewCell.SeparatorStyle = .none,
                         delegate: UITableViewDelegate,
                         dataSource: UITableViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UITableView {
        
        let tableview = UITableView(frame: frame, style: style)
        tableview.delegate = delegate
        tableview.dataSource = dataSource
        tableview.separatorStyle = separatorStyle
        tableview.backgroundColor = backgroundColor
        tableview.estimatedSectionHeaderHeight = headerHeight
        tableview.sectionHeaderHeight = headerHeight
        tableview.estimatedSectionFooterHeight = footerHeight
        tableview.sectionFooterHeight = footerHeight
        tableview.estimatedRowHeight = rowHeight
        tableview.rowHeight = rowHeight
        tableview.tableHeaderView = UIView()
        tableview.tableFooterView = UIView()
        if #available(iOS 15.0, *) {
            tableview.sectionHeaderTopPadding = 0
        }
        superView?.addSubview(tableview)
        
        return tableview
    }
    
    /// 滚动到底部
    func wy_scrollToBottom(animated: Bool) {
        let section = max(0, numberOfSections - 1)
        let row = max(0, numberOfRows(inSection: section) - 1)
        guard section >= 0, row >= 0 else { return }
        let indexPath = IndexPath(row: row, section: section)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    /// 滚动到指定 IndexPath
    func wy_scrollTo(indexPath: IndexPath, at position: UITableView.ScrollPosition = .middle, animated: Bool = true) {
        guard indexPath.section < numberOfSections,
              indexPath.row < numberOfRows(inSection: indexPath.section) else { return }
        scrollToRow(at: indexPath, at: position, animated: animated)
    }
    
    /// 是否允许其它手势识别，默认false，在tableView嵌套的类似需求下可设置为true
    var wy_allowOtherGestureRecognizer: Bool {
        
        set(newValue) {
            
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_allowOtherGestureRecognizer, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_allowOtherGestureRecognizer) as? Bool ?? false
        }
    }
    
    /// 批量注册UITableView的Cell或HeaderFooterView
    func wy_register(_ contentClasss: [AnyClass], _ styles: [WYTableViewRegisterStyle]) {
        for index in 0..<contentClasss.count {
            wy_register(contentClasss[index], styles[index])
        }
    }
    
    /// 注册UITableView的Cell或HeaderFooterView
    func wy_register(_ contentClass: AnyClass, _ style: WYTableViewRegisterStyle) {
        
        let reuseIdentifier: String = NSStringFromClass(contentClass).components(separatedBy: ".").last ?? ""
        
        switch style {
        case .cell:
            register(contentClass, forCellReuseIdentifier: reuseIdentifier)
            break
        case .headerFooterView:
            register(contentClass, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
            break
        }
    }
    
    /// 滑动或点击收起键盘
    @discardableResult
    func wy_swipeOrTapCollapseKeyboard(target: Any? = nil, action: Selector? = nil, slideMode: UIScrollView.KeyboardDismissMode = .onDrag) -> UITapGestureRecognizer {
        keyboardDismissMode = slideMode
        let gesture = UITapGestureRecognizer(target: ((target == nil) ? self : target!), action: ((action == nil) ? #selector(keyboardHide) : action!))
        gesture.numberOfTapsRequired = 1
        // 设置成 false 表示当前控件响应后会传播到其他控件上，默认为 true
        gesture.cancelsTouchesInView = false
        addGestureRecognizer(gesture)
        
        return gesture
    }
    
    @objc private func keyboardHide() {
        endEditing(true)
        superview?.endEditing(true)
    }
    
    private struct WYAssociatedKeys {
        static var wy_allowOtherGestureRecognizer: UInt8 = 0
    }
}

extension UITableView: @retroactive UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return wy_allowOtherGestureRecognizer
    }
}
