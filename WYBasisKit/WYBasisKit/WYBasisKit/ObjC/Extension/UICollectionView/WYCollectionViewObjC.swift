//
//  UICollectionViewObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

/// UICollectionView注册类型
@objc(WYCollectionViewRegisterStyle)
@frozen public enum WYCollectionViewRegisterStyleObjC: Int {
    
    /// 注册Cell
    case cell = 0
    /// 注册HeaderView
    case headerView
    /// 注册FooterView
    case footerView
}

@objc public extension UICollectionView {
    
    /**
     *  创建一个UICollectionView
     *  @param frame: collectionView的frame, 如果是约束布局，请直接使用默认值：.zero
     *  @param flowLayout: UICollectionViewLayout 或继承至 UICollectionViewLayout 的流式布局
     *  @param delegate: delegate
     *  @param dataSource: dataSource
     *  @param backgroundColor: 背景色
     *  @param superView: 父view
     */
    @objc(wy_sharedWithFrame:flowLayout:delegate:dataSource:backgroundColor:superView:)
    static func wy_sharedObjC(frame: CGRect = .zero,
                         flowLayout: UICollectionViewLayout,
                         delegate: UICollectionViewDelegate,
                         dataSource: UICollectionViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UICollectionView {
        
        return wy_shared(frame: frame, flowLayout: flowLayout, delegate: delegate, dataSource: dataSource, backgroundColor: backgroundColor, superView: superView)
    }
    
    /**
     *  创建一个UICollectionView
     *  @param frame: collectionView的frame, 如果是约束布局，请直接使用默认值：.zero
     *  @param scrollDirection: 滚动方向
     *  @param sectionInset: 分区 上、左、下、右 的间距(该设置仅适用于一个分区或者每个分区sectionInset都相同的情况，多个分区请调用相关代理进行针对性设置)
     *  @param minimumLineSpacing: item 上下行间距
     *  @param minimumInteritemSpacing: item 左右列间距
     *  @param itemSize: item 大小(该设置仅适用于一个分区或者每个分区itemSize都相同的情况，多个分区请调用相关代理进行针对性设置)
     *  @param delegate: delegate
     *  @param dataSource: dataSource
     *  @param backgroundColor: 背景色
     *  @param superView: 父view
     */
    @objc(wy_sharedWithFrame:scrollDirection:sectionInset:minimumLineSpacing:minimumInteritemSpacing:itemSize:delegate:dataSource:backgroundColor:superView:)
    static func wy_sharedObjC(frame: CGRect = .zero,
                         scrollDirection: UICollectionView.ScrollDirection = .vertical,
                         sectionInset: UIEdgeInsets = .zero,
                         minimumLineSpacing: CGFloat = 0,
                         minimumInteritemSpacing: CGFloat = 0,
                         itemSize: CGSize = .zero,
                         delegate: UICollectionViewDelegate,
                         dataSource: UICollectionViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UICollectionView {
        
        return wy_shared(frame: frame, scrollDirection: scrollDirection, sectionInset: sectionInset, minimumLineSpacing: minimumLineSpacing, minimumInteritemSpacing: minimumInteritemSpacing, itemSize: itemSize, delegate: delegate, dataSource: dataSource, backgroundColor: backgroundColor, superView: superView)
    }
    
    /// 滚动到底部
    @objc(wy_scrollToBottomWithAnimated:)
    func wy_scrollToBottomObjC(animated: Bool) {
        wy_scrollToBottom(animated: animated)
    }
    
    /// 滚动到指定 IndexPath
    @objc(wy_scrollToIndexPath:position:animated:)
    func wy_scrollToObjC(indexPath: IndexPath, at position: UICollectionView.ScrollPosition = .centeredVertically, animated: Bool = true) {
        wy_scrollTo(indexPath: indexPath, at: position, animated: animated)
    }
    
    /// 批量注册UICollectionView的Cell或Header/FooterView
    @objc(wy_registers:style:)
    func wy_registersObjC(_ contentClasss: [AnyClass], _ style: WYCollectionViewRegisterStyleObjC) {
        wy_registers(contentClasss, WYCollectionViewRegisterStyle(rawValue: style.rawValue) ?? .cell)
    }
    
    /// 注册UICollectionView的Cell或Header/FooterView
    @objc(wy_register:style:)
    func wy_registerObjC(_ contentClass: AnyClass, _ style: WYCollectionViewRegisterStyleObjC) {
        wy_register(contentClass, WYCollectionViewRegisterStyle(rawValue: style.rawValue) ?? .cell)
    }
    
    /// 滑动或点击收起键盘
    @discardableResult
    @objc(wy_swipeOrTapCollapseKeyboardWithTarget:action:)
    func wy_swipeOrTapCollapseKeyboardObjC(target: Any? = nil, action: Selector? = nil) -> UITapGestureRecognizer {
        return wy_swipeOrTapCollapseKeyboard(target: target, action: action)
    }
}
