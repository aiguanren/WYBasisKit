//
//  UITableViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit

/// UITableView注册类型
@objc(WYTableViewRegisterStyle)
@frozen public enum WYTableViewRegisterStyleObjC: Int {
    
    /// 注册Cell
    case cell = 0
    /// 注册HeaderFooterView
    case headerFooterView
}

@objc public extension UITableView {
    
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
    @objc(wy_sharedWithFrame:style:headerHeight:footerHeight:rowHeight:separatorStyle:delegate:dataSource:backgroundColor:superView:)
    static func wy_sharedObjC(frame: CGRect = .zero,
                         style: UITableView.Style = .plain,
                         headerHeight: CGFloat = UITableView.automaticDimension,
                         footerHeight: CGFloat = UITableView.automaticDimension,
                         rowHeight: CGFloat = UITableView.automaticDimension,
                         separatorStyle: UITableViewCell.SeparatorStyle = .none,
                         delegate: UITableViewDelegate,
                         dataSource: UITableViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UITableView {
        
        return wy_shared(frame: frame, style: style, headerHeight: headerHeight, footerHeight: footerHeight, rowHeight: rowHeight, separatorStyle: separatorStyle, delegate: delegate, dataSource: dataSource, backgroundColor: backgroundColor, superView: superView)
    }
    
    /// 滚动到底部
    @objc(wy_scrollToBottomWithAnimated:)
    func wy_scrollToBottomObjC(animated: Bool) {
        wy_scrollToBottom(animated: animated)
    }
    
    /// 滚动到指定 IndexPath
    @objc(wy_scrollToIndexPath:position:animated:)
    func wy_scrollToObjC(indexPath: IndexPath, at position: UITableView.ScrollPosition = .middle, animated: Bool = true) {
        wy_scrollTo(indexPath: indexPath, at: position, animated: animated)
    }
    
    /// 是否允许其它手势识别，默认false，在tableView嵌套的类似需求下可设置为true
    @objc(wy_allowOtherGestureRecognizer)
    var wy_allowOtherGestureRecognizerObjC: Bool {
        set(newValue) { wy_allowOtherGestureRecognizer = newValue }
        get { return wy_allowOtherGestureRecognizer }
    }
    
    /// 批量注册UITableView的Cell或HeaderFooterView
    @objc(wy_registers:style:)
    func wy_registersObjC(_ contentClasss: [AnyClass], _ style: WYTableViewRegisterStyleObjC) {
        wy_registers(contentClasss, WYTableViewRegisterStyle(rawValue: style.rawValue) ?? .cell)
    }
    
    /// 注册UITableView的Cell或HeaderFooterView
    @objc(wy_register:style:)
    func wy_registerObjC(_ contentClass: AnyClass, _ style: WYTableViewRegisterStyleObjC) {
        wy_register(contentClass, WYTableViewRegisterStyle(rawValue: style.rawValue) ?? .cell)
    }
    
    /// 滑动或点击收起键盘
    @discardableResult
    @objc(wy_swipeOrTapCollapseKeyboardWithTarget:action:slideMode:)
    func wy_swipeOrTapCollapseKeyboardObjC(target: Any? = nil, action: Selector? = nil, slideMode: UIScrollView.KeyboardDismissMode = .onDrag) -> UITapGestureRecognizer {
        return wy_swipeOrTapCollapseKeyboard(target: target, action: action, slideMode: slideMode)
    }
}
