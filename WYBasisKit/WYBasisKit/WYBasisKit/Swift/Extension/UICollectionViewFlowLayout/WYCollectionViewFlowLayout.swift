//
//  UICollectionViewFlowLayout.swift
//  WYBasisKit
//
//  Created by guanren on 2025/11/16.
//

import UIKit

/// 瀑布流对齐方式
@objc @frozen public enum WYFlowLayoutAlignment: Int {
    
    /// 默认左对齐，等同于left，该选项只是内部用来判断是否需要调整分区对齐方式的
    case `default` = 0
    
    /// 左对齐
    case left
    
    /// 居中对齐
    case center
    
    /// 右对齐
    case right
}

@objc public protocol WYCollectionViewFlowLayoutDelegate {
    
    /** item.size */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    
    /** header.size */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    
    /** footer.size */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
    
    /** number of lines(scrollDirection == .horizontal时需设置) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfLinesInSection section: Int) -> Int
    
    /** number of columns(scrollDirection == .vertical时需设置) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfColumnsInSection section: Int) -> Int
    
    /** inset for section */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSection section: Int) -> UIEdgeInsets
    
    /** item.leftRightSpacing */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSection section: Int) -> CGFloat
    
    /** item.upDownSpacing */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSection section: Int) -> CGFloat
    
    /** 分区header与上个分区footer之间的间距(仅UICollectionView滚动方向为竖向时生效) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, spacingBetweenHeaderAndLastPartitionFooter section: Int) -> CGFloat
    
    /** 分区item对齐方式(默认左对齐，如果调用此方法并且返回值不是`default`，则需要保证该分区每个cell的高度相同，且该分区不支持设置isPagingEnabled) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flowLayoutAlignmentForSection section: Int) -> WYFlowLayoutAlignment
    
    /** 当控件所需宽度超过 分区最大的显示宽度时，最多能显示几行, 默认0(无限换行) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemNumberOfLinesForSection section: Int) -> Int
    
    /** 水平滚动时，分区的item排列方式是否需要调整为水平排列(系统默认为竖向排列) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalScrollItemArrangementDirectionForSection section: Int) -> Bool
    
    /** 分区header是否需要悬停 */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, hoverForHeaderForSection section: Int) -> Bool
}

/**
 *  自定义瀑布流使用说明
 *  当设置UICollectionView滚动方向为横向时(不支持headerView与footerView)，务必保证每个cell的高度相同，否则布局会错乱
 *  当设置UICollectionView滚动方向为竖向时，如果没有设置item对齐方式(默认左对齐)，则需要保证每个item的宽度相同，否则布局会错乱，如果设置item对齐方式不是 WYFlowLayoutAlignment.default，则item的宽高可以随意
 *
 *  isPagingEnabled为true时(不支持headerView与footerView)，务必保证每个cell的宽与每个cell的高均相同，否则布局会错乱
 */
public class WYCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    /** delegate */
    public weak var delegate: WYCollectionViewFlowLayoutDelegate?
    
    public override init() {
        super.init()
    }
    
    public init(delegate: WYCollectionViewFlowLayoutDelegate?) {
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepare() {
        super.prepare()
        wy_prepareLayout()
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesArray
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return wy_layoutAttributesForItem(at: indexPath)
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return wy_layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    
    public override var collectionViewContentSize: CGSize {
        if scrollDirection == .vertical {
            return CGSize(width: collectionView?.frame.size.width ?? 0, height: contentSize.height)
        }else {
            return CGSize(width: contentSize.width, height: collectionView?.frame.size.height ?? 0)
        }
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return wy_shouldInvalidateLayout(forBoundsChange: newBounds)
    }
}
