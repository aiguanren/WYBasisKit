//
//  UICollectionView.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/8/28.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

/// UICollectionView注册类型
@frozen public enum WYCollectionViewRegisterStyle: Int {
    
    /// 注册Cell
    case cell = 0
    /// 注册HeaderView
    case headerView
    /// 注册FooterView
    case footerView
}

public extension UICollectionView {
    
    /**
     *  创建一个UICollectionView
     *  @param frame: collectionView的frame, 如果是约束布局，请直接使用默认值：.zero
     *  @param flowLayout: UICollectionViewLayout 或继承至 UICollectionViewLayout 的流式布局
     *  @param delegate: delegate
     *  @param dataSource: dataSource
     *  @param backgroundColor: 背景色
     *  @param superView: 父view
     */
    static func wy_shared(frame: CGRect = .zero,
                         flowLayout: UICollectionViewLayout,
                         delegate: UICollectionViewDelegate,
                         dataSource: UICollectionViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UICollectionView {
        
        let collectionview = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        collectionview.delegate = delegate
        collectionview.dataSource = dataSource
        collectionview.backgroundColor = backgroundColor
        superView?.addSubview(collectionview)
        
        return collectionview
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
    static func wy_shared(frame: CGRect = .zero,
                         scrollDirection: UICollectionView.ScrollDirection = .vertical,
                         sectionInset: UIEdgeInsets = .zero,
                         minimumLineSpacing: CGFloat = 0,
                         minimumInteritemSpacing: CGFloat = 0,
                         itemSize: CGSize? = nil,
                         delegate: UICollectionViewDelegate,
                         dataSource: UICollectionViewDataSource,
                         backgroundColor: UIColor = .white,
                         superView: UIView? = nil) -> UICollectionView {
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = scrollDirection
        flowLayout.sectionInset = sectionInset
        flowLayout.minimumLineSpacing = minimumLineSpacing
        flowLayout.minimumInteritemSpacing = minimumInteritemSpacing
        if let itemSize = itemSize {
            flowLayout.itemSize = itemSize
        }
        
        let collectionview = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        collectionview.delegate = delegate
        collectionview.dataSource = dataSource
        collectionview.backgroundColor = backgroundColor
        superView?.addSubview(collectionview)
        
        return collectionview
    }
    
    /// 滚动到底部
    func wy_scrollToBottom(animated: Bool) {
        let section = max(0, numberOfSections - 1)
        let item = max(0, numberOfItems(inSection: section) - 1)
        guard section >= 0, item >= 0 else { return }
        let indexPath = IndexPath(item: item, section: section)
        scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
    
    /// 滚动到指定 IndexPath
    func wy_scrollTo(indexPath: IndexPath, at position: UICollectionView.ScrollPosition = .centeredVertically, animated: Bool = true) {
        guard indexPath.section < numberOfSections,
              indexPath.item < numberOfItems(inSection: indexPath.section) else { return }
        scrollToItem(at: indexPath, at: position, animated: animated)
    }
    
    /// 批量注册UICollectionView的Cell或Header/FooterView
    func wy_registers(_ contentClasss: [AnyClass], _ style: WYCollectionViewRegisterStyle) {
        for index in 0..<contentClasss.count {
            wy_register(contentClasss[index], style)
        }
    }
    
    /// 注册UICollectionView的Cell或Header/FooterView
    func wy_register(_ contentClass: AnyClass, _ style: WYCollectionViewRegisterStyle) {
        
        let reuseIdentifier: String = String(describing: contentClass).components(separatedBy: ".").last ?? ""
        
        switch style {
        case .cell:
            register(contentClass, forCellWithReuseIdentifier: reuseIdentifier)
            break
            
        case .headerView:
            register(contentClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: reuseIdentifier)
            break
            
        case .footerView:
            register(contentClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: reuseIdentifier)
            break
        }
    }
    
    /// 滑动或点击收起键盘
    @discardableResult
    func wy_swipeOrTapCollapseKeyboard(target: Any? = nil, action: Selector? = nil) -> UITapGestureRecognizer {
        self.keyboardDismissMode = .onDrag
        let gesture = UITapGestureRecognizer(target: ((target == nil) ? self : target!), action: ((action == nil) ? action : #selector(keyboardHide)))
        gesture.numberOfTapsRequired = 1
        // 设置成 false 表示当前控件响应后会传播到其他控件上，默认为 true
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)
        
        return gesture
    }
    
    @objc private func keyboardHide() {
        self.endEditing(true)
        self.superview?.endEditing(true)
    }
}
