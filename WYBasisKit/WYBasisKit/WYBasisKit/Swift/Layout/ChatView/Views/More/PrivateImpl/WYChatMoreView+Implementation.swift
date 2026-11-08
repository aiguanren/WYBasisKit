//
//  WYChatMoreView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import SnapKit

extension WYChatMoreView {
    
    /// 分页控制器设置选项
    internal var pageControlSetting: (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.pageControlSetting, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.pageControlSetting) as? (currentColor: UIColor?, defaultColor: UIColor?, currentImage: UIImage?, defaultImage: UIImage?) ?? (currentColor: nil, defaultColor: nil, currentImage: nil, defaultImage: nil)
        }
    }
    
    /// 自定义设置分页控件图片及颜色
    internal func updatePageControlStyle() {
        
        if pageControl?.hidesForSinglePage != self.moreViewConfig.pageControlHideForSingle {
            pageControl?.hidesForSinglePage = self.moreViewConfig.pageControlHideForSingle
        }
        
        if let defaultColor: UIColor = pageControlSetting.defaultColor {
            pageControl?.pageIndicatorTintColor = defaultColor
            pageControlSetting.defaultColor = nil
        }
        if let currentColor: UIColor = pageControlSetting.currentColor {
            pageControl?.currentPageIndicatorTintColor = currentColor
            pageControlSetting.currentColor = nil
        }
        
        if let defaultImage: UIImage = pageControlSetting.defaultImage, let currentImage: UIImage = pageControlSetting.currentImage {
            for page: Int in 0..<(pageControl?.numberOfPages ?? 0) {
                pageControl?.setIndicatorImage(page == pageControl?.currentPage ? currentImage : defaultImage, forPage: page)
            }
        }else {
            if let defaultImage: UIImage = pageControlSetting.defaultImage {
                pageControl?.preferredIndicatorImage = defaultImage
                pageControlSetting.defaultImage = nil
            }
            
            if let currentImage: UIImage = pageControlSetting.currentImage {
                pageControl?.preferredIndicatorImage = currentImage
                pageControlSetting.currentImage = nil
            }
        }
    }
    
    internal struct WYAssociatedKeys {
        static var pageControl: UInt8 = 0
        static var pageControlSetting: UInt8 = 0
    }
}

extension WYChatMoreView {

    func wy_makeCollectionView() -> UICollectionView {

        let minimumInteritemSpacing: CGFloat = 0

        let flowLayout: WYCollectionViewFlowLayout = WYCollectionViewFlowLayout(delegate: self)
        flowLayout.itemSize = self.moreViewConfig.moreItemSize()
        flowLayout.minimumLineSpacing = self.moreViewConfig.minimumLineSpacing
        flowLayout.minimumInteritemSpacing = minimumInteritemSpacing
        flowLayout.scrollDirection = self.moreViewConfig.scrollDirection

        let collectionView: UICollectionView = UICollectionView.wy_shared(flowLayout: flowLayout, delegate: self, dataSource: self, superView: self)

        collectionView.register(WYMoreViewCell.self, forCellWithReuseIdentifier: "WYMoreViewCell")
        collectionView.isPagingEnabled = self.moreViewConfig.isPagingEnabled
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return collectionView
    }
}

extension WYChatMoreView {
    func wy_layoutMore() {
        guard bounds.width > 0, let flow = collectionView.collectionViewLayout as? WYCollectionViewFlowLayout else { return }
        let columns = max(1, moreViewConfig.scrollDirection == .horizontal ? moreViewConfig.itemMaxCountWithLine : moreViewConfig.itemMaxCountWithColumn)
        let available = max(1, bounds.width - moreViewConfig.contentInset.left - moreViewConfig.contentInset.right)
        let width = min(max(1, moreViewConfig.imageViewSize.width), available / CGFloat(columns))
        let spacing = columns > 1 ? max(0, (available - CGFloat(columns) * width) / CGFloat(columns - 1)) : 0
        let size = CGSize(width: width, height: max(1, moreViewConfig.moreItemSize().height))
        if flow.itemSize != size || flow.minimumInteritemSpacing != spacing {
            flow.itemSize = size
            flow.minimumInteritemSpacing = spacing
            flow.invalidateLayout()
        }
        if let pageControl {
            let point = moreViewConfig.pageControlPosition ?? moreViewConfig.defaultPageControlPosition(pageControl, containerWidth: bounds.width)
            pageControl.snp.updateConstraints { make in make.left.equalToSuperview().offset(point.x); make.top.equalToSuperview().offset(point.y) }
        }
    }

    func wy_reloadMoreConfiguration() {
        collectionView.removeFromSuperview()
        collectionView = wy_makeCollectionView()
        pageControl?.removeFromSuperview()
        pageControl = nil
        backgroundColor = moreViewConfig.backgroundColor
        setNeedsLayout()
    }
}
