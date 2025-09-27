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
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    
    /** header.size */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    
    /** footer.size */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
    
    /** number of lines(scrollDirection == .horizontal时需设置) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfLinesIn section: Int) -> Int
    
    /** number of columns(scrollDirection == .vertical时需设置) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfColumnsIn section: Int) -> Int
    
    /** inset for section */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    
    /** item.leftRightSpacing */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    
    /** item.upDownSpacing */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    
    /** 分区header与上个分区footer之间的间距(仅UICollectionView滚动方向为竖向时生效) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, spacingBetweenHeaderAndLastPartitionFooter section: Int) -> CGFloat
    
    /** 分区item对齐方式(默认左对齐，如果调用此方法并且返回值不是`default`，则需要保证该分区每个cell的高度相同，且该分区不支持设置isPagingEnabled) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, flowLayoutAlignmentForSectionAt section: Int) -> WYFlowLayoutAlignment
    
    /** 当控件所需宽度超过 分区最大的显示宽度时，最多能显示几行, 默认0(无限换行) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, itemNumberOfLinesForSectionAt section: Int) -> Int
    
    /** 水平滚动时，分区的item排列方式是否需要调整为水平排列(系统默认为竖向排列) */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, horizontalScrollItemArrangementDirectionForSectionAt section: Int) -> Bool
    
    /** 分区header是否需要悬停 */
    @objc optional func wy_collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, hoverForHeaderForSectionAt section: Int) -> Bool
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
}

public extension WYCollectionViewFlowLayout {
    
    override func prepare() {
        
        super.prepare()
        
        // 清除之前数组开始创建每一组cell的布局属性
        contentSize = .zero
        lastContentWidth = 0
        lastContentHeight = 0
        columnWidths.removeAll()
        columnHeights.removeAll()
        attributesArray.removeAll()
        
        // 开始创建每一组cell的布局属性
        let sectionCount: Int = collectionView?.numberOfSections ?? 0
        // 遍历section
        for section in 0..<sectionCount {
            
            lastContentWidth = contentSize.width
            lastContentHeight = contentSize.height
            
            // 初始化分区 x 值
            let numberOfLinesInSection: Int = numberOfLinesIn(section)
            for _ in 0..<numberOfLinesInSection {
                columnWidths.append(contentSize.width)
            }
            
            // 初始化分区 y 值
            let numberOfColumnsInSection: Int = numberOfColumnsIn(section)
            for _ in 0..<numberOfColumnsInSection {
                columnHeights.append(contentSize.height)
            }
            
            // 开始创建组内的每一个cell的布局属性
            let itemCount: Int = collectionView?.numberOfItems(inSection: section) ?? 0
            
            // 分区对齐方式
            let alignment: WYFlowLayoutAlignment = flowLayoutAlignmentIn(section)
            
            var itemOffset: CGPoint = .zero
            var adjustAttributes: [UICollectionViewLayoutAttributes] = []
            var adjustWidth: CGFloat = 0
            for item in 0..<itemCount {
                
                let indexPath: IndexPath = IndexPath(item: item, section: section)
                // 获取indexPath位置cell对应的布局属性
                if let itemAttributes = layoutAttributesForItem(at: indexPath) {
                    
                    if (scrollDirection == .vertical) && (alignment != .default) {
                        
                        // section.Insets
                        let sectionInsets: UIEdgeInsets = insetForSectionAt(indexPath.section)
                        
                        // headerSize
                        let headerSize: CGSize = referenceSizeForHeaderIn(indexPath.section)
                        
                        // 布局宽度
                        let collectionWidth: CGFloat = headerSize.width - sectionInsets.left - sectionInsets.right
                        
                        // 行间距
                        let lineSpacing: CGFloat = minimumLineSpacingForSectionAt(indexPath.section)
                        
                        // 列间距
                        let columnsSpacing: CGFloat = minimumInteritemSpacingForSectionAt(indexPath.section)
                        
                        // 是否是最后一个item
                        let isLastItem: Bool = ((item + 1) == itemCount)
                        
                        if indexPath.item == 0 {
                            
                            // 分区header与上个分区footer之间的间距
                            let sectionOffset: CGFloat = spacingBetweenHeaderAndLastPartitionFooter(indexPath.section)
                            
                            // headerOffset
                            let headerOffset = sectionOffset + sectionInsets.top + headerSize.height
                            
                            itemOffset.y = headerOffset + lastContentHeight
                        }
                        
                        if ((adjustWidth + itemAttributes.frame.size.width + columnsSpacing) > collectionWidth) || (isLastItem == true) {
                            
                            let isFirstAttributes: Bool = adjustAttributes.isEmpty
                        
                            if (adjustAttributes.isEmpty == true) {
                                adjustWidth += itemAttributes.frame.size.width
                                adjustAttributes.append(itemAttributes)
                            }else {
                                adjustWidth = (adjustWidth - columnsSpacing)
                            }

                            adjustAlignmentAttributesAt(indexPath: indexPath, attributes: adjustAttributes, itemOffset: &itemOffset, layoutMaxWidth: collectionWidth, totalWidth: adjustWidth, sectionInsets: sectionInsets, lineSpacing: lineSpacing, columnsSpacing: columnsSpacing, alignment: alignment)
                            
                            adjustWidth = 0
                            itemOffset.x = 0
                            
                            if isLastItem {
                                if adjustAttributes.last! == itemAttributes {
                                    itemOffset.y += itemAttributes.frame.size.height
                                    contentSize = CGSize(width: collectionView?.frame.size.width ?? 0, height: itemOffset.y + sectionInsets.bottom)
                                }else {
                                    itemOffset.y += (adjustAttributes.last!.frame.size.height + lineSpacing)
                                }
                                
                            }else {
                                itemOffset.y += (adjustAttributes.last!.frame.size.height + lineSpacing)
                            }
                            
                            adjustAttributes.removeAll()
                            
                            if isFirstAttributes == false {
                                adjustWidth += (itemAttributes.frame.size.width + columnsSpacing)
                                adjustAttributes.append(itemAttributes)
                                
                                if isLastItem == true {
                                    adjustWidth = adjustWidth - columnsSpacing
                                }
                                
                                adjustAlignmentAttributesAt(indexPath: indexPath, attributes: adjustAttributes, itemOffset: &itemOffset, layoutMaxWidth: collectionWidth, totalWidth: adjustWidth, sectionInsets: sectionInsets, lineSpacing: lineSpacing, columnsSpacing: columnsSpacing, alignment: alignment)
                                
                                adjustWidth = 0
                                itemOffset.x = 0
                                adjustAttributes.removeAll()
                                
                                if isLastItem {
                                    itemOffset.y += itemAttributes.frame.size.height
                                    contentSize = CGSize(width: collectionView?.frame.size.width ?? 0, height: itemOffset.y + sectionInsets.bottom)
                                }else {
                                    itemOffset.y += (itemAttributes.frame.size.height + lineSpacing)
                                }
                            }
                        }else {
                            
                            adjustWidth += ((adjustAttributes.isEmpty ? 0 : columnsSpacing) + itemAttributes.frame.size.width + columnsSpacing)
                            adjustAttributes.append(itemAttributes)
                        }
                    }
                    attributesArray.append(itemAttributes)
                }
            }
            
            // 获取每一组header的UICollectionViewLayoutAttributes
            let headerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
            if headerAttributes != nil {
                attributesArray.append(headerAttributes!)
                columnWidths.removeAll()
                columnHeights.removeAll()
            }
            
            // 获取每一组footer的UICollectionViewLayoutAttributes
            let footerAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section))
            if footerAttributes != nil {
                attributesArray.append(footerAttributes!)
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesArray
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        // 分区对齐方式
        let alignment: WYFlowLayoutAlignment = flowLayoutAlignmentIn(indexPath.section)
        if (scrollDirection == .vertical) && (alignment != .default) {
            return alignmentAttributesAt(indexPath: indexPath)
        }else {
            return attributesAt(indexPath: indexPath)
        }
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        
        let sectionInsets: UIEdgeInsets = insetForSectionAt(indexPath.section)
        
        let footerSize: CGSize = referenceSizeForFooterIn(indexPath.section)
        
        if elementKind == UICollectionView.elementKindSectionHeader {
            
            let headerSize: CGSize = referenceSizeForHeaderIn(indexPath.section)
            
            let sectionOffset: CGFloat = spacingBetweenHeaderAndLastPartitionFooter(indexPath.section)
            
            var headerOffset: CGFloat = 0.0
            
            let sectionHeaderHover: Bool = hoverForHeaderIn(indexPath.section)
            
            // 悬浮方案
            if sectionHeaderHover == true {
                
                // 设置headerView在最上层
                let headerView: UICollectionReusableView? = collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath)
                headerView?.layer.zPosition = 1
                
                if scrollDirection == .vertical {
                    
                    let contentOffsety: CGFloat = collectionView?.contentOffset.y ?? 0.0
                    let minOffsety: CGFloat = max(sectionOffset + lastContentHeight, contentOffsety)
                    let maxOffsety: CGFloat = max((columnHeights.max() ?? 0.0) - footerSize.height + sectionInsets.bottom, sectionOffset)
                    
                    headerOffset = min(minOffsety, maxOffsety)
                }
            }else {

                // 不悬浮方案
                if scrollDirection == .vertical {
                    headerOffset = (sectionOffset + lastContentHeight)
                }
            }

            if scrollDirection == .vertical {
                attributes.frame = CGRect(x: (scrollDirection == .vertical) ? 0 : headerOffset, y: (scrollDirection == .vertical) ? headerOffset : 0, width: headerSize.width, height: headerSize.height)
            }else {
                attributes.frame = .zero
            }
            
            let itemCount: Int = collectionView?.numberOfItems(inSection: indexPath.section) ?? 0
            if itemCount == 0 {
                contentSize.height = attributes.frame.maxY
            }
            
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            
            contentSize.height += sectionInsets.bottom
            
            if scrollDirection == .vertical {
                
                attributes.frame = CGRect(x: 0, y: contentSize.height, width: footerSize.width, height: footerSize.height)
                
            }else {
                attributes.frame = .zero
            }
            contentSize.height += footerSize.height
        }
        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        if scrollDirection == .vertical {
            return CGSize(width: collectionView?.frame.size.width ?? 0, height: contentSize.height)
        }else {
            return CGSize(width: contentSize.width, height: collectionView?.frame.size.height ?? 0)
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        if (scrollDirection == .horizontal) || (collectionView?.isPagingEnabled == true) {
            return false
        }else {
            let visibleSections: [IndexPath]? = collectionView?.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader)
            
            if visibleSections?.isEmpty == false {
                let firstVisibleSection: Int = (visibleSections?.first?.section == 0) ? 0 : (visibleSections?.last!.section)!
                return hoverForHeaderIn(firstVisibleSection)
                
            }else {
                return false
            }
        }
    }
}

extension WYCollectionViewFlowLayout {
    
    private func attributesAt(indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        
        // item.attributes
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // itemSize
        let itemLayoutSize: CGSize = sizeForItemAt(indexPath)
        
        // section.Insets
        let sectionInsets: UIEdgeInsets = insetForSectionAt(indexPath.section)
        
        // 分区header与上个分区footer之间的间距
        let sectionOffset: CGFloat = spacingBetweenHeaderAndLastPartitionFooter(indexPath.section)
        
        // headerSize
        let headerSize: CGSize = CGSize(width: collectionView?.frame.size.width ?? 0, height: referenceSizeForHeaderIn(indexPath.section).height)
        
        // headerOffset
        let headerOffset = sectionOffset + sectionInsets.top + headerSize.height
        
        if scrollDirection == .vertical {
            
            // 分区列数
            let numberOfColumns: Int = numberOfColumnsIn(indexPath.section)
            
            // 布局宽度
            let collectionWidth: CGFloat = headerSize.width - sectionInsets.left - sectionInsets.right
            
            let adjustColumns: Int = (collectionView?.numberOfItems(inSection: indexPath.section) ?? 0) < numberOfColumns ? (collectionView?.numberOfItems(inSection: indexPath.section) ?? 0) : numberOfColumns
            
            // 总的item宽度
            let totalItemWidth: CGFloat = CGFloat(adjustColumns) * itemLayoutSize.width
            
            // 列间距
            var columnsSpacing: CGFloat = minimumInteritemSpacingForSectionAt(indexPath.section)
            if (CGFloat(adjustColumns) * (itemLayoutSize.width + columnsSpacing)) > (collectionWidth + columnsSpacing) {
                columnsSpacing = (CGFloat(adjustColumns - 1) > 0) ? ((collectionWidth - totalItemWidth) / CGFloat(adjustColumns - 1)) : (collectionWidth - totalItemWidth)
            }
            
            // 行间距
            var lineSpacing: CGFloat = minimumLineSpacingForSectionAt(indexPath.section)
            
            // 最小的列高
            var minColumnHeight: CGFloat = columnHeights.min() ?? 0.0
            
            // 最小的列
            let minColumn: Int = columnHeights.firstIndex(of: minColumnHeight) ?? 0
            
            // item的x值
            var itemOffsetx: CGFloat = sectionInsets.left + (CGFloat(minColumn) * (itemLayoutSize.width + columnsSpacing))
            
            // item的y值
            var itemOffsety: CGFloat = 0
            
            // 计算每页可以显示几行
            var numberOfLines: Int = 0
            
            if collectionView?.isPagingEnabled == true {
                
                // 布局高度
                let collectionHeight: CGFloat = (collectionView?.frame.size.height ?? 0) - sectionInsets.top - sectionInsets.bottom
                
                numberOfLines = Int(round(((collectionHeight + lineSpacing) / (lineSpacing + itemLayoutSize.height))))
                if numberOfLines <= 0 {
                    numberOfLines = 1
                }
                
                // 总页数
                let pageNumber: Int = indexPath.item / (numberOfLines * numberOfColumns)
                
                // 每页总的item高度
                let totalItemHeight: CGFloat = CGFloat(numberOfLines) * itemLayoutSize.height
                
                if (CGFloat(numberOfLines) * (itemLayoutSize.height + lineSpacing) != (collectionHeight + lineSpacing)) {
                    
                    lineSpacing = (CGFloat(numberOfLines - 1) > 0) ? ((collectionHeight - totalItemHeight) / CGFloat(numberOfLines - 1)) : (collectionHeight - totalItemHeight)
                }
                
                // 该页中item的序号
                let itemInPage: Int = indexPath.item % (numberOfLines * numberOfColumns)
                
                // item的所在列
                let itemInColumns: Int = itemInPage % numberOfColumns

                // item的所在行
                let itemInLines: Int = itemInPage / numberOfColumns
                
                itemOffsetx = sectionInsets.left + ((itemLayoutSize.width + columnsSpacing)) * CGFloat(itemInColumns)
                
                itemOffsety = (sectionInsets.top + ((itemLayoutSize.height + lineSpacing) * CGFloat(itemInLines)) + CGFloat(pageNumber) * (collectionView?.frame.size.height ?? 0)) + lastContentHeight
                
            }else {
                
                itemOffsety = minColumnHeight + ((minColumnHeight != lastContentHeight) ? lineSpacing : 0) + ((indexPath.item < numberOfColumns) ? headerOffset : 0)
            }
            
            attributes.frame = CGRect(x: itemOffsetx, y: itemOffsety, width: itemLayoutSize.width, height: itemLayoutSize.height)
            
            if ((indexPath.item + 1) == collectionView?.numberOfItems(inSection: indexPath.section) && (collectionView?.isPagingEnabled == true)) {
                
                // 总页数
                var lastPageNumber: Int = Int(ceil(CGFloat(indexPath.item + 1) / CGFloat((numberOfLines * numberOfColumns))))
                if lastPageNumber <= 0 {
                    lastPageNumber = 1
                }

                minColumnHeight = (CGFloat(lastPageNumber) * (collectionView?.frame.size.height ?? 0) - sectionInsets.bottom) + lastContentHeight
            }
            
            contentSize.height = (contentSize.height < minColumnHeight) ? minColumnHeight : contentSize.height
            
            if columnHeights.isEmpty == false {
                columnHeights[minColumn] = attributes.frame.maxY
            }
            
            contentSize.height = ((columnHeights.max() ?? 0.0) > contentSize.height) ? (columnHeights.max() ?? 0.0) : contentSize.height
            
        }else {
            // 分区行数
            let numberOfLines: Int = numberOfLinesIn(indexPath.section)
            
            // 布局高度
            let collectionHeight: CGFloat = (collectionView?.frame.size.height ?? 0.0) - sectionInsets.top - sectionInsets.bottom
            
            // 布局宽度
            let collectionWidth: CGFloat = (collectionView?.frame.size.width ?? 0) - sectionInsets.left - sectionInsets.right
            
            let adjustLines: Int = (collectionView?.numberOfItems(inSection: indexPath.section) ?? 0) < numberOfLines ? (collectionView?.numberOfItems(inSection: indexPath.section) ?? 0) : numberOfLines
            
            // 总的item高度
            let totalItemHeight: CGFloat = CGFloat(adjustLines) * itemLayoutSize.height
            
            // 行间距
            var lineSpacing: CGFloat = minimumLineSpacingForSectionAt(indexPath.section)
            if CGFloat(adjustLines) * (itemLayoutSize.height + lineSpacing) > (collectionHeight + lineSpacing) {
                lineSpacing = (CGFloat(adjustLines - 1) > 0) ? ((collectionHeight - totalItemHeight) / CGFloat(adjustLines - 1)) : (collectionHeight - totalItemHeight)
            }
            
            // 列间距
            var columnsSpacing: CGFloat = minimumInteritemSpacingForSectionAt(indexPath.section)
            
            // 计算每页可以显示几列
            var numberOfColumns: Int = Int(round(((collectionWidth + columnsSpacing) / (columnsSpacing + itemLayoutSize.width))))
            if numberOfColumns <= 0 {
                numberOfColumns = 1
            }
            
            // 每页总的item宽度
            let totalItemWidth: CGFloat = CGFloat(numberOfColumns) * itemLayoutSize.width
            
            // 最短的行宽
            var minLineWidth: CGFloat = columnWidths.min() ?? 0.0
            
            // 最短的行
            let minLine: Int = columnWidths.firstIndex(of: minLineWidth) ?? 0
            
            // item的x值
            var itemOffsetx: CGFloat = 0
            // item的y值
            var itemOffsety: CGFloat = 0
            
            // 每页可以显示多少个item
            let totalItemInPage: Int = numberOfLines * numberOfColumns
            
            // item的所在行
            var itemInLines: Int = 0
            
            // 水平滚动时，分区的item排列方式是否需要调整为水平排列(系统默认为竖向排列)
            if horizontalScrollItemArrangementDirectionIn(indexPath.section) == true {
                
                if collectionView?.isPagingEnabled == false {
                    
                    // 总共有多少个item需要显示
                    let totalItem: Int = collectionView?.numberOfItems(inSection: indexPath.section) ?? 0
                    
                    if totalItem > totalItemInPage {
                        numberOfColumns = Int(ceil(CGFloat(totalItem) / CGFloat(numberOfLines)))
                    }
                }
                
                if (collectionView?.isPagingEnabled == true) || (numberOfColumns <= 1) {
                    
                    if (CGFloat(numberOfColumns) * (itemLayoutSize.width + columnsSpacing) != (collectionWidth + columnsSpacing)) {
                        columnsSpacing = (CGFloat(numberOfColumns - 1) > 0) ? ((collectionWidth - totalItemWidth) / CGFloat(numberOfColumns - 1)) : (collectionWidth - totalItemWidth)
                    }
                }
                
                // 该页中item的序号
                let itemInPage: Int = indexPath.item % (numberOfLines * numberOfColumns)
                
                itemInLines = itemInPage / numberOfColumns
                
                if collectionView?.isPagingEnabled == true {
                    
                    // 是否是每页的第一列
                    let isFirstColumnsInPage: Bool = ((itemInLines * numberOfColumns) + 1) == ((indexPath.item + 1) % totalItemInPage)
                    
                    // 是否是每页的最后一列
                    let isLastColumnsInPage: Bool = (numberOfColumns * (numberOfLines + 1)) == ((indexPath.item + 1) % totalItemInPage)
                    
                    itemOffsetx = (isFirstColumnsInPage ? sectionInsets.left : 0) + columnWidths[itemInLines] + ((columnWidths[itemInLines] == 0) ? 0 : columnsSpacing) + (isLastColumnsInPage ? sectionInsets.right : 0) - ((isFirstColumnsInPage && ((indexPath.item + 1) > totalItemInPage)) ? columnsSpacing : 0) + ((isFirstColumnsInPage && ((indexPath.item + 1) > totalItemInPage)) ? sectionInsets.left : 0) - (((indexPath.section > 0) && isFirstColumnsInPage) ? columnsSpacing : 0) + (((indexPath.section > 0) && ((indexPath.item + 1) > totalItemInPage) && isFirstColumnsInPage) ? columnsSpacing : 0)
                    
                }else {
                    itemOffsetx = ((columnWidths[itemInLines] == 0) ? sectionInsets.left : 0) + columnWidths[itemInLines] + ((columnWidths[itemInLines] == 0) ? 0 : columnsSpacing)
                }
                
                itemOffsety = sectionInsets.top + (itemLayoutSize.height + lineSpacing) * CGFloat(itemInLines)
                
            }else {
                
                if (collectionView?.isPagingEnabled == true) || (numberOfColumns <= 1) {
                    if (CGFloat(numberOfColumns) * (itemLayoutSize.width + columnsSpacing) != (collectionWidth + columnsSpacing)) {
                        columnsSpacing = (CGFloat(numberOfColumns - 1) > 0) ? ((collectionWidth - totalItemWidth) / CGFloat(numberOfColumns - 1)) : (collectionWidth - totalItemWidth)
                    }
                }
                
                if collectionView?.isPagingEnabled == true {
                    
                    itemOffsetx = (((indexPath.item % totalItemInPage) < numberOfLines) ? sectionInsets.left : 0) + minLineWidth + (((indexPath.item % totalItemInPage) < numberOfLines) ? 0 : columnsSpacing) + ((((indexPath.item % totalItemInPage) < numberOfLines) && (minLineWidth > 0)) ? sectionInsets.right : 0) - ((indexPath.section == 0) ? 0 : (((indexPath.item % totalItemInPage) < numberOfLines) && (indexPath.item < numberOfLines)) ? sectionInsets.right : 0)
                }else {
                    itemOffsetx = ((minLineWidth == 0) ? sectionInsets.left : 0) + minLineWidth + ((minLineWidth == 0) ? 0 : columnsSpacing)
                }
                
                itemOffsety = sectionInsets.top + (CGFloat(minLine) * (itemLayoutSize.height + lineSpacing))
            }
            
            attributes.frame = CGRect(x: itemOffsetx, y: itemOffsety, width: itemLayoutSize.width, height: itemLayoutSize.height)
            
            if columnWidths.isEmpty == false {
                if horizontalScrollItemArrangementDirectionIn(indexPath.section) == true {
                    columnWidths[itemInLines] = attributes.frame.maxX
                }else {
                    columnWidths[minLine] = attributes.frame.maxX
                }
            }
            
            if ((indexPath.item + 1) == collectionView?.numberOfItems(inSection: indexPath.section) && (collectionView?.isPagingEnabled == true)) {
                
                // 总页数
                var lastPageNumber: Int = Int(ceil(CGFloat(indexPath.item + 1) / CGFloat((numberOfLines * numberOfColumns))))
                if lastPageNumber <= 0 {
                    lastPageNumber = 1
                }

                minLineWidth = (CGFloat(lastPageNumber) * (collectionView?.frame.size.width ?? 0) - sectionInsets.right) + lastContentWidth
            }
            
            contentSize.width = (contentSize.width < minLineWidth) ? minLineWidth : contentSize.width
            
            contentSize.width = ((columnWidths.max() ?? 0.0) > contentSize.width) ? (columnWidths.max() ?? 0.0) : contentSize.width
            
            if (indexPath.item + 1) == collectionView?.numberOfItems(inSection: indexPath.section) {
                contentSize.width += sectionInsets.right
            }
        }
        return attributes
    }
    
    private func alignmentAttributesAt(indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        // item.attributes
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // itemSize
        let itemLayoutSize: CGSize = sizeForItemAt(indexPath)
    
        attributes.frame = CGRect(x: 0, y: 0, width: itemLayoutSize.width, height: itemLayoutSize.height)
        
        return attributes
    }
    
    private func adjustAlignmentAttributesAt(indexPath: IndexPath, attributes: [UICollectionViewLayoutAttributes], itemOffset: inout CGPoint, layoutMaxWidth: CGFloat, totalWidth: CGFloat, sectionInsets: UIEdgeInsets, lineSpacing: CGFloat, columnsSpacing: CGFloat, alignment: WYFlowLayoutAlignment) {
 
        let collectionWidth: CGFloat = collectionView?.frame.size.width ?? 0
        for index: Int in 0..<attributes.count {
            
            let attribute: UICollectionViewLayoutAttributes = attributes[index]
            
            switch alignment {
            case .center:
                itemOffset.x = (index == 0) ? (((layoutMaxWidth - totalWidth) / 2) + sectionInsets.left) : (itemOffset.x + columnsSpacing)
                attribute.frame.origin = itemOffset
                itemOffset.x = itemOffset.x + attribute.frame.size.width
                break
            case .right:
                itemOffset.x = (index == 0) ?  (collectionWidth - sectionInsets.right - attribute.frame.size.width) : (itemOffset.x - columnsSpacing)
                attribute.frame.origin = itemOffset
                let nextAttribute: UICollectionViewLayoutAttributes? = ((index + 1) == attributes.count) ? nil : attributes[index + 1]
                itemOffset.x = itemOffset.x - (nextAttribute?.frame.size.width ?? 0)
                break
            default:
                itemOffset.x = (index == 0) ? sectionInsets.left : (itemOffset.x + columnsSpacing)
                attribute.frame.origin = itemOffset
                itemOffset.x = itemOffset.x + attribute.frame.size.width
                break
            }
        }
    }
    
    private func sizeForItemAt(_ indexPath: IndexPath) -> CGSize {
        guard let collectionView = collectionView else { return itemSize }
        return delegate?.wy_collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? itemSize
    }
    
    private func referenceSizeForHeaderIn(_ section: Int) -> CGSize {
        
        guard let collectionView = collectionView else { return headerReferenceSize }
        return delegate?.wy_collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? ((headerReferenceSize == .zero) ? CGSize(width: collectionView.frame.size.width, height: 0) : headerReferenceSize)
    }
    
    private func referenceSizeForFooterIn(_ section: Int) -> CGSize {
        
        guard let collectionView = collectionView else { return footerReferenceSize }
        return delegate?.wy_collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? ((footerReferenceSize == .zero) ? CGSize(width: collectionView.frame.size.width, height: 0) : footerReferenceSize)
    }
    
    private func numberOfLinesIn(_ section: Int) -> Int {
        guard let collectionView = collectionView else { return 1 }
        return delegate?.wy_collectionView?(collectionView, layout: self, numberOfLinesIn: section) ?? 1
    }
    
    private func numberOfColumnsIn(_ section: Int) -> Int {
        guard let collectionView = collectionView else { return 1 }
        return delegate?.wy_collectionView?(collectionView, layout: self, numberOfColumnsIn: section) ?? 1
    }
    
    private func insetForSectionAt(_ section: Int) -> UIEdgeInsets {
        guard let collectionView = collectionView else { return sectionInset }
        return delegate?.wy_collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? sectionInset
    }
    
    private func minimumInteritemSpacingForSectionAt(_ section: Int) -> CGFloat {
        guard let collectionView = collectionView else { return minimumInteritemSpacing }
        return delegate?.wy_collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) ?? minimumInteritemSpacing
    }
    
    private func minimumLineSpacingForSectionAt(_ section: Int) -> CGFloat {
        guard let collectionView = collectionView else { return minimumLineSpacing }
        return delegate?.wy_collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) ?? minimumLineSpacing
    }
    
    private func spacingBetweenHeaderAndLastPartitionFooter(_ section: Int) -> CGFloat {
        guard let collectionView = collectionView else { return 0.0 }
        return delegate?.wy_collectionView?(collectionView, layout: self, spacingBetweenHeaderAndLastPartitionFooter: section) ?? 0.0
    }
    
    private func flowLayoutAlignmentIn(_ section: Int) -> WYFlowLayoutAlignment {
        guard let collectionView = collectionView else { return .center }
        return delegate?.wy_collectionView?(collectionView, layout: self, flowLayoutAlignmentForSectionAt: section) ?? .default
    }
    
    private func itemNumberOfLines(_ section: Int) -> Int {
        guard let collectionView = collectionView else { return 0 }
        return delegate?.wy_collectionView?(collectionView, layout: self, itemNumberOfLinesForSectionAt: section) ?? 0
    }
    
    private func horizontalScrollItemArrangementDirectionIn(_ section: Int) -> Bool {
        guard let collectionView = collectionView else { return false }
        return delegate?.wy_collectionView?(collectionView, layout: self, horizontalScrollItemArrangementDirectionForSectionAt: section) ?? false
    }
    
    private func hoverForHeaderIn(_ section: Int) -> Bool {
        guard let collectionView = collectionView else { return false }
        return delegate?.wy_collectionView?(collectionView, layout: self, hoverForHeaderForSectionAt: section) ?? false
    }
    
    /** 存放所有cell的布局属性 */
    private var attributesArray: [UICollectionViewLayoutAttributes] {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_attributesArray, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_attributesArray) as? [UICollectionViewLayoutAttributes] ?? []
        }
    }
    
    /** 存放每个section中各个行的最后一个宽度 */
    private var columnWidths: [CGFloat] {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_columnWidths, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_columnWidths) as? [CGFloat] ?? []
        }
    }
    
    /** 存放每个section中各个列的最后一个高度 */
    private var columnHeights: [CGFloat] {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_columnHeights, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_columnHeights) as? [CGFloat] ?? []
        }
    }
    
    /** 内容的宽高 */
    private var contentSize: CGSize {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_contentSize, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_contentSize) as? CGSize ?? .zero
        }
    }
    
    /** 记录上个section宽度最宽一行的宽度 */
    private var lastContentWidth: CGFloat {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lastContentWidth, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lastContentWidth) as? CGFloat ?? 0.0
        }
    }
    
    /** 记录上个section高度最高一列的高度 */
    private var lastContentHeight: CGFloat {
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lastContentHeight, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lastContentHeight) as? CGFloat ?? 0.0
        }
    }
    
    private struct WYAssociatedKeys {
        static var wy_attributesArray: UInt8 = 0
        static var wy_columnWidths: UInt8 = 0
        static var wy_columnHeights: UInt8 = 0
        static var wy_contentSize: UInt8 = 0
        static var wy_lastContentWidth: UInt8 = 0
        static var wy_lastContentHeight: UInt8 = 0
    }
}
