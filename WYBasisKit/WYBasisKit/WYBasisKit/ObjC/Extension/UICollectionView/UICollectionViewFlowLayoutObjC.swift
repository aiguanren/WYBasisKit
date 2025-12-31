//
//  UICollectionViewFlowLayoutObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/11/16.
//

import UIKit

/**
 *  自定义瀑布流使用说明
 *  当设置UICollectionView滚动方向为横向时(不支持headerView与footerView)，务必保证每个cell的高度相同，否则布局会错乱
 *  当设置UICollectionView滚动方向为竖向时，如果没有设置item对齐方式(默认左对齐)，则需要保证每个item的宽度相同，否则布局会错乱，如果设置item对齐方式不是 WYFlowLayoutAlignment.default，则item的宽高可以随意
 *
 *  isPagingEnabled为true时(不支持headerView与footerView)，务必保证每个cell的宽与每个cell的高均相同，否则布局会错乱
 */
@objc public extension WYCollectionViewFlowLayout {
    
    /** delegate */
    @objc(delegate)
    weak var delegateObjC: WYCollectionViewFlowLayoutDelegate? {
        set(newValue) { delegate = newValue }
        get { return delegate }
    }
    
    @objc(initWithDelegate:)
    convenience init(with delegate: WYCollectionViewFlowLayoutDelegate) {
        self.init(delegate: delegate)
    }
}
