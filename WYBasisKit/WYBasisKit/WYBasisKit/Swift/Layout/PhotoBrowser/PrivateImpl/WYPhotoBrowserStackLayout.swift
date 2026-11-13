//
//  WYPhotoBrowserStackLayout.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 图片浏览器叠卡布局与连续翻页动画
final class WYPhotoBrowserStackLayout: UICollectionViewFlowLayout {
    var configuration = WYPhotoBrowserConfiguration()
    var sourceItemCount = 0
    var cycleDirection = 1
    private var wasMovingBack = false

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        configuration.layoutStyle == .stackedCards || super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard configuration.layoutStyle == .stackedCards, let collectionView, collectionView.numberOfSections > 0 else { return super.layoutAttributesForElements(in: rect) }
        let count = collectionView.numberOfItems(inSection: 0)
        guard count > 0 else { return [] }
        let horizontal = scrollDirection == .horizontal
        let length = horizontal ? collectionView.bounds.width : collectionView.bounds.height
        guard length > 0 else { return [] }
        let progress = (horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y) / length
        let center = min(max(0, Int(floor(progress))), count - 1)
        let depth = min(count, max(1, configuration.stackedCardCount))
        let lower = max(0, center - depth)
        let upper = min(count - 1, center + depth)
        return (lower...upper).compactMap { index in layoutAttributesForItem(at: IndexPath(item: index, section: 0)) }
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let original = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        guard configuration.layoutStyle == .stackedCards, let collectionView else { return original }
        let horizontal = scrollDirection == .horizontal
        let width = collectionView.bounds.width
        let height = collectionView.bounds.height
        let length = horizontal ? width : height
        guard length > 0 else { return original }
        let progress = (horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y) / length
        if collectionView.panGestureRecognizer.state == .changed { wasMovingBack = (horizontal ? collectionView.panGestureRecognizer.translation(in: collectionView).x : collectionView.panGestureRecognizer.translation(in: collectionView).y) > 0 }
        else if !collectionView.isDragging && !collectionView.isDecelerating { wasMovingBack = false }
        let movingBack = configuration.stackedCardCyclesForward && configuration.allowsLoopScrolling ? cycleDirection < 0 : wasMovingBack
        let count = collectionView.numberOfItems(inSection: 0)
        let front = min(max(0, movingBack ? Int(ceil(progress)) : Int(floor(progress))), max(0, count - 1))
        let depth = (indexPath.item - front) * (movingBack ? -1 : 1)
        let visible = min(max(1, sourceItemCount), max(1, configuration.stackedCardCount))
        let fraction = min(1, abs(progress - CGFloat(front)))
        guard depth >= 0 && (depth < visible || (depth == visible && fraction > 0)) else { original.alpha = 0; original.isHidden = true; return original }
        let finite: (CGFloat) -> CGFloat = { $0.isFinite ? $0 : 0 }
        let offset = CGSize(width: max(0, finite(configuration.stackedCardOffset.width)), height: max(0, finite(configuration.stackedCardOffset.height)))
        let stillAngle: CGFloat = visible > 1 ? min(.pi / 4, abs(finite(configuration.stackedCardRotationAngle))) : 0
        let dragAngle = min(.pi / 2, abs(finite(configuration.stackedCardDragRotationAngle)))
        let anchor = CGPoint(x: min(1, max(0, finite(configuration.stackedCardAnchorPoint.x))), y: min(1, max(0, finite(configuration.stackedCardAnchorPoint.y))))
        let insetX = CGFloat(visible - 1) * offset.width + height * sin(stillAngle) * max(anchor.y, 1 - anchor.y)
        let insetY = CGFloat(visible - 1) * offset.height + width * sin(stillAngle) * max(anchor.x, 1 - anchor.x)
        original.size = CGSize(width: max(1, width - insetX * 2), height: max(1, height - insetY * 2))
        let direction: CGFloat = movingBack ? 1 : -1
        let depthPosition = depth == 0 ? fraction * CGFloat(visible - 1) : CGFloat(depth) - fraction
        let movement = depth == 0 ? direction * sin(fraction * .pi) * length * 0.25 : 0
        original.center = CGPoint(x: collectionView.bounds.midX + depthPosition * offset.width + (horizontal ? movement : 0), y: collectionView.bounds.midY + depthPosition * offset.height + (horizontal ? 0 : movement))
        let restAngle: (Int) -> CGFloat = { $0 == 0 ? 0 : ($0.isMultiple(of: 2) ? -stillAngle : stillAngle) }
        let angle = depth == 0 ? direction * sin(fraction * .pi) * dragAngle + restAngle(visible - 1) * fraction : restAngle(depth) * (1 - fraction) + restAngle(depth - 1) * fraction
        let pivot = CGPoint(x: (anchor.x - 0.5) * original.size.width, y: (anchor.y - 0.5) * original.size.height)
        original.transform = CGAffineTransform(translationX: pivot.x, y: pivot.y).rotated(by: angle).translatedBy(x: -pivot.x, y: -pivot.y)
        original.zIndex = depth == 0 && fraction >= 0.5 ? 0 : visible - depth + 1
        original.alpha = depth == visible ? fraction : (depth == 0 && sourceItemCount > visible ? 1 - max(0, fraction - 0.5) * 2 : 1)
        original.isHidden = false
        return original
    }
}
