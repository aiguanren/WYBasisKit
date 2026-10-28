//
//  WYPhotoBrowser+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/21.
//

import UIKit
import Photos
import PhotosUI
import Kingfisher

/// 图片浏览器的加载、交互和翻页实现
extension WYPhotoBrowser {

    /// 浏览项数量(数据源缺位时为0)
    var numberOfItems: Int {
        return dataSource?.numberOfItems(in: self) ?? 0
    }

    /// 统一取浏览项(WYPhotoBrowserItem与实现toItem()的类型两种返回归一，并把已合成的LivePhoto缓存填回)
    func item(at index: Int) -> WYPhotoBrowserItem? {
        var item: WYPhotoBrowserItem?
        if let anyItem = dataSource?.photoBrowser(self, itemAt: index) {
            if let structItem = anyItem as? WYPhotoBrowserItem {
                item = structItem
            } else if let convertibleItem = anyItem as? WYPhotoBrowserItemConvertible {
                item = convertibleItem.toItem()
            }
        }
        if item?.livePhoto == nil, let cachedLivePhoto = livePhotoCache[index] {
            item?.livePhoto = cachedLivePhoto
        }
        return item
    }

    /// 缓存页Cell合成的LivePhoto(结构体浏览项写不回去，合成结果存浏览器侧供复用)
    func cacheLivePhoto(_ livePhoto: PHLivePhoto, for index: Int) {
        livePhotoCache[index] = livePhoto
    }

    /// 单击背景关闭(图片区域的单击由页Cell回调dismissByTap)
    @objc func backgroundTapped() {
        dismissByTap()
    }

    /// 长按集合视图(定位长按页下标，LivePhoto页长按播放松手停，其余页长按弹菜单)
    @objc func collectionLongPressed(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        let displayIndex = displayIndex(fromCollection: indexPath.item)
        switch gesture.state {
        case .began:
            guard isTransitioningContent == false, isDragDismissing == false else { return }
            handleLongPress(at: displayIndex, touchPoint: gesture.location(in: view))
        case .ended, .cancelled, .failed:
            cellForItem(at: displayIndex)?.stopLivePhoto()
        default:
            break
        }
    }

    /// 处理长按(按项类型分播放或菜单，菜单场景同时回调代理)
    func handleLongPress(at index: Int, touchPoint: CGPoint) {
        guard index >= 0, index < numberOfItems, let item = item(at: index) else { return }
        if item.mediaType == .livePhoto, let cell = cellForItem(at: index) {
            cell.playLivePhoto()
            return
        }
        browserDelegate?.wy_photoBrowser?(self, didLongPressItemAt: index)
        showMenu(at: touchPoint, index: index)
    }

    /// 弹出长按菜单(内置保存动作按配置开关，自定义动作按传入顺序排前)
    func showMenu(at point: CGPoint, index: Int) {
        guard menuView.superview == nil else { return }

        var actions = configuration.customActions
        if configuration.showsSaveAction {
            let saveTitle = WYLocalized("保存图片", table: WYBasisKitConfig.kitLocalizableTable)
            actions.append(WYPhotoBrowserAction(title: saveTitle, icon: menuSaveIcon, handler: { browser, _ in
                browser.saveCurrentItemToAlbum()
            }))
        }
        guard actions.isEmpty == false else { return }

        view.addSubview(menuDimmingView)
        view.addSubview(menuView)
        menuDimmingView.frame = view.bounds
        menuView.show(actions: actions, anchorPoint: point, in: view) { [weak self] action in
            guard let self = self else { return }
            self.hideMenu()
            action.handler?(self, index)
        }
    }

    /// 收起长按菜单与遮罩
    func hideMenu() {
        menuView.removeFromSuperview()
        menuDimmingView.removeFromSuperview()
    }

    /// 点菜单遮罩收起菜单
    @objc func menuDimmingTapped() {
        hideMenu()
    }

    /// 内置保存动作的图标(系统下载图标，iOS15自带)
    var menuSaveIcon: UIImage? {
        return UIImage(systemName: "square.and.arrow.down")
    }

    /// 保存当前页图片到系统相册(先过相册授权，保存结果用Activity提示窗口反馈)
    func saveCurrentItemToAlbum() {
        let toastConfig = configuration.appearance.toastConfig ?? WYActivityConfig.info
        guard let image = currentCell?.currentDisplayImage() else {
            WYActivity.showInfo(WYLocalized("保存失败，请重试", table: WYBasisKitConfig.kitLocalizableTable), in: view, position: .middle, config: toastConfig)
            return
        }
        wy_authorizeAlbumAccess(showSettingsAlert: true) { [weak self] authorized, limited in
            guard let self = self else { return }
            guard authorized || limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                Task { @MainActor in
                    let key = success ? "已保存到相册" : "保存失败，请重试"
                    WYActivity.showInfo(WYLocalized(key, table: WYBasisKitConfig.kitLocalizableTable), in: self.view, position: .middle, config: toastConfig)
                }
            }
        }
    }

    /// 单击关闭(尊重配置开关，转场与拖拽进行中不响应)
    func dismissByTap() {
        guard configuration.allowsTapDismiss, isTransitioningContent == false, isDragDismissing == false else { return }
        dismissBrowser(animated: true)
    }

    /// 取指定显示页的Cell(只有可见页能取到，循环模式下换算到集合页码)
    func cellForItem(at index: Int) -> WYPhotoBrowserPageCell? {
        return collectionView.cellForItem(at: IndexPath(item: collectionIndex(for: index), section: 0)) as? WYPhotoBrowserPageCell
    }

    /// 当前页Cell
    var currentCell: WYPhotoBrowserPageCell? {
        return cellForItem(at: internalCurrentIndex)
    }

    /// 指定页的转场来源屏幕位置(取不到可用来源时返回nil，转场降级渐隐)
    func sourceFrameForItem(at index: Int) -> CGRect? {
        guard let sourceView = browserDelegate?.wy_photoBrowser?(self, sourceViewForItemAt: index) else { return nil }
        guard let window = sourceView.window, sourceView.isHidden == false, sourceView.alpha > 0.01 else { return nil }
        let frame = sourceView.convert(sourceView.bounds, to: window)
        guard frame.intersects(window.bounds.insetBy(dx: -50, dy: -50)) else { return nil }
        return frame
    }

    /// 隐藏或恢复当前页图片内容(转场动画期间用快照替代真内容，避免双层图片)
    func setCurrentContentHidden(_ hidden: Bool) {
        currentCell?.setMainContentHidden(hidden)
    }

    /// 页Cell点击了视频封面播放按钮(转发代理由接入方自行播放)
    func pageCellDidTapPlayVideo(_ cell: WYPhotoBrowserPageCell) {
        browserDelegate?.wy_photoBrowser?(self, didTapPlayVideoItemAt: cell.index)
    }

    /// 页Cell原图加载完成(转发代理)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didFinishLoadingOriginalAt index: Int) {
        browserDelegate?.wy_photoBrowser?(self, didFinishLoadingOriginalItemAt: index)
    }

    /// 页Cell拖拽进度变化(背景与页码跟随变淡)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didUpdateDragProgress progress: CGFloat) {
        backgroundView.alpha = 1 - progress * 0.85
        setChromeHidden(progress > 0.05)
    }

    /// 页Cell开始拖拽(停用翻页滚动)
    func pageCellDidBeginDrag(_ cell: WYPhotoBrowserPageCell) {
        collectionView.isScrollEnabled = false
    }

    /// 页Cell拖拽结束(超过阈值或甩动速度够大走关闭动画，否则弹回)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didEndDragWithTranslation translation: CGPoint, velocity: CGPoint) {
        collectionView.isScrollEnabled = true
        let distance = abs(translation.y)
        let speed = abs(velocity.y)
        if distance > configuration.dragDismissThreshold || speed > 800 {
            startDragDismiss(from: cell, velocity: velocity)
        } else {
            cell.springBack()
            UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction]) {
                self.backgroundView.alpha = 1
            } completion: { _ in
                self.setChromeHidden(false)
            }
        }
    }

    /// 执行拖拽关闭(快照飞回来源位置或顺速度飘出屏，然后无动画移除浏览器)
    func startDragDismiss(from cell: WYPhotoBrowserPageCell, velocity: CGPoint) {
        guard isDragDismissing == false else { return }
        isDragDismissing = true
        hideMenu()

        let snapshotView = cell.takeMainContentSnapshot()
        let startFrame = cell.mainContentScreenFrame() ?? cell.frame
        let sourceFrame = sourceFrameForItem(at: internalCurrentIndex)

        collectionView.isHidden = true
        setChromeHidden(true)
        if let snapshotView = snapshotView {
            snapshotView.frame = startFrame
            view.addSubview(snapshotView)
            let fallbackY = velocity.y >= 0 ? view.bounds.maxY + startFrame.height : -startFrame.height
            let endFrame = sourceFrame ?? CGRect(x: startFrame.midX - startFrame.width / 2, y: fallbackY, width: startFrame.width, height: startFrame.height)
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
                snapshotView.frame = endFrame
                self.backgroundView.alpha = 0
            } completion: { [weak self] _ in
                snapshotView.removeFromSuperview()
                self?.dismiss(animated: false)
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundView.alpha = 0
            }) { [weak self] _ in
                self?.dismiss(animated: false)
            }
        }
    }

    /// 页码与覆盖层的隐藏开关(拖拽与转场时淡出)
    func setChromeHidden(_ hidden: Bool) {
        let indicatorVisible = numberOfItems > 1
        pageTextLabel.isHidden = hidden || configuration.pageIndicatorStyle != .text || indicatorVisible == false
        pageControl.isHidden = hidden || configuration.pageIndicatorStyle != .dots || indicatorVisible == false
        currentCell?.setChromeHidden(hidden)
    }

    /// 刷新页码显示(翻页落定与数据刷新后调用)
    func refreshIndicator() {
        let indicatorVisible = numberOfItems > 1
        switch configuration.pageIndicatorStyle {
        case .none:
            pageTextLabel.isHidden = true
            pageControl.isHidden = true
        case .text:
            pageControl.isHidden = true
            pageTextLabel.isHidden = indicatorVisible == false
            pageTextLabel.text = "\(internalCurrentIndex + 1)/\(numberOfItems)"
        case .dots:
            pageTextLabel.isHidden = true
            pageControl.isHidden = indicatorVisible == false
            pageControl.numberOfPages = numberOfItems
            pageControl.currentPage = internalCurrentIndex
        }
    }

    /// 摆放页码(底部居中，避开底部安全区)
    func layoutIndicator() {
        let indicatorHeight = UIDevice.wy_screenHeight(20, WYBasisKitConfig.defaultScreenPixels)
        let bottomMargin = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)
        let indicatorY = view.bounds.height - view.safeAreaInsets.bottom - bottomMargin - indicatorHeight
        pageTextLabel.frame = CGRect(x: 0, y: indicatorY, width: view.bounds.width, height: indicatorHeight)
        pageControl.frame = CGRect(x: 0, y: indicatorY, width: view.bounds.width, height: indicatorHeight)
    }

    /// 指定显示页的翻页偏移(循环模式下真实页落在缓冲区中间段，翻页方向不同偏移轴向不同)
    func targetOffset(for index: Int) -> CGPoint {
        guard numberOfItems > 0 else { return .zero }
        let boundedIndex = max(0, min(index, numberOfItems - 1))
        return targetRawOffset(collectionIndex: collectionIndex(for: boundedIndex))
    }

    /// 预加载相邻页图片(按配置的预加载数量取前后页的原图或缩略图地址)
    func prefetchNeighbors() {
        guard configuration.prefetchCount > 0, numberOfItems > 0 else { return }
        var urls: [URL] = []
        for offset in 1...configuration.prefetchCount {
            for index in [internalCurrentIndex - offset, internalCurrentIndex + offset] {
                guard index >= 0, index < numberOfItems, let item = item(at: index), item.mediaType != .video else { continue }
                if let url = item.originalURL {
                    urls.append(url)
                } else if let url = item.thumbnailURL {
                    urls.append(url)
                }
            }
        }
        guard urls.isEmpty == false else { return }
        imagePrefetcher = ImagePrefetcher(urls: urls)
        imagePrefetcher?.start()
    }
}

extension WYPhotoBrowser: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loopCollectionItemCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WYPhotoBrowserPageCell.reuseIdentifier, for: indexPath) as! WYPhotoBrowserPageCell
        cell.browser = self
        let displayIndex = displayIndex(fromCollection: indexPath.item)
        if let item = item(at: displayIndex) {
            cell.configure(item: item, index: displayIndex, configuration: configuration)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutItemSize()
    }
}

extension WYPhotoBrowser: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settleCurrentPage()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        settleCurrentPage()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseCarouselTimer()
    }

    /// 多页同屏的松手吸附(按单页步长取整落位，快速甩动按速度方向跳页)
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard configuration.layoutStyle == .multiPage, pageStep > 0 else { return }
        let isHorizontal = flowLayout.scrollDirection == .horizontal
        let rawTarget = isHorizontal ? targetContentOffset.pointee.x : targetContentOffset.pointee.y
        let velocityValue = isHorizontal ? velocity.x : velocity.y
        var pageIndex = (rawTarget - pageStepLeading) / pageStep
        if velocityValue > 0.5 {
            pageIndex = ceil(pageIndex - 0.2)
        } else if velocityValue < -0.5 {
            pageIndex = floor(pageIndex + 0.2)
        } else {
            pageIndex = round(pageIndex)
        }
        let bounded = max(0, min(pageIndex, CGFloat(loopCollectionItemCount - 1)))
        let snappedTarget = pageStepLeading + bounded * pageStep
        if isHorizontal {
            targetContentOffset.pointee.x = snappedTarget
        } else {
            targetContentOffset.pointee.y = snappedTarget
        }
    }

    /// 滚动中给可见页施加多页同屏过渡特效(按页中心离视口中心的比例变化)
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyTransformToVisibleCells()
    }

    /// 给可见页施加多页同屏过渡特效(进入静止时与滚动中都调用，非多页同屏或无特效时不做)
    func applyTransformToVisibleCells() {
        guard configuration.layoutStyle == .multiPage, configuration.transformStyle != .none, pageStep > 0 else { return }
        let isHorizontal = flowLayout.scrollDirection == .horizontal
        let viewportCenter = isHorizontal ? collectionView.bounds.midX : collectionView.bounds.midY
        for case let cell as WYPhotoBrowserPageCell in collectionView.visibleCells {
            guard cell.isDraggingToDismiss == false else { continue }
            let cellCenter = isHorizontal ? cell.center.x : cell.center.y
            let ratio = (cellCenter - viewportCenter) / pageStep
            cell.applyLayoutTransform(style: configuration.transformStyle, ratio: ratio)
        }
    }

    /// 翻页落定(算出当前页、循环模式缓冲页无感回跳、刷页码、回调代理、预加载相邻页、重启自动轮播)
    func settleCurrentPage() {
        guard pageStep > 0, numberOfItems > 0 else { return }
        let offset = collectionView.contentOffset.x + collectionView.contentOffset.y
        let collectionIndex = Int(round((offset - pageStepLeading) / pageStep))
        let displayIndex = displayIndex(fromCollection: collectionIndex)
        let changed = displayIndex != internalCurrentIndex
        internalCurrentIndex = displayIndex
        normalizeLoopPosition(collectionIndex: collectionIndex)
        refreshIndicator()
        if changed {
            browserDelegate?.wy_photoBrowser?(self, didShowItemAt: internalCurrentIndex)
        }
        applyTransformToVisibleCells()
        prefetchNeighbors()
        restartCarouselTimer()
    }

    /// 循环翻页生效判定(多于一张且配置开启)
    var isLoopScrollingEnabled: Bool {
        return configuration.allowsLoopScrolling && numberOfItems > 1
    }

    /// 集合视图页数(循环模式下首尾各插一页缓冲，0页显示末页、末页后一页显示首页)
    var loopCollectionItemCount: Int {
        if isLoopScrollingEnabled {
            return numberOfItems + 2
        }
        return numberOfItems
    }

    /**
     * 集合页码换显示页码(循环模式缓冲页映射回真实页，非循环模式原样返回)
     *   @param collectionIndex 集合视图页码
     * @return 数据源真实页码
     */
    func displayIndex(fromCollection collectionIndex: Int) -> Int {
        guard isLoopScrollingEnabled else { return collectionIndex }
        if collectionIndex <= 0 {
            return numberOfItems - 1
        }
        if collectionIndex >= numberOfItems + 1 {
            return 0
        }
        return collectionIndex - 1
    }

    /**
     * 显示页码换集合页码(循环模式真实页码落在缓冲区中间段)
     *   @param displayIndex 数据源真实页码
     * @return 集合视图页码
     */
    func collectionIndex(for displayIndex: Int) -> Int {
        guard isLoopScrollingEnabled else { return displayIndex }
        return displayIndex + 1
    }

    /// 停在缓冲页时无动画跳回对应真实页(视觉无感，用户继续滑像无限循环)
    func normalizeLoopPosition(collectionIndex: Int) {
        guard isLoopScrollingEnabled else { return }
        var targetCollectionIndex: Int? = nil
        if collectionIndex <= 0 {
            targetCollectionIndex = numberOfItems
        } else if collectionIndex >= numberOfItems + 1 {
            targetCollectionIndex = 1
        }
        if let targetCollectionIndex = targetCollectionIndex {
            collectionView.setContentOffset(targetRawOffset(collectionIndex: targetCollectionIndex), animated: false)
        }
    }

    /// 集合页码的翻页偏移(按单页步长与起点偏移计算，整页与多页同屏两种布局共用，不经显示页码换算)
    func targetRawOffset(collectionIndex: Int) -> CGPoint {
        let offset = pageStepLeading + CGFloat(collectionIndex) * pageStep
        if flowLayout.scrollDirection == .horizontal {
            return CGPoint(x: offset, y: 0)
        }
        return CGPoint(x: 0, y: offset)
    }

    /// 按布局样式配置集合视图布局(整页铺满按视口分页，多页同屏按页宽加间距分页并露出两侧)
    func configureFlowLayout() {
        guard collectionView.bounds.width > 0, collectionView.bounds.height > 0 else { return }
        if configuration.layoutStyle == .multiPage {
            let reveal = UIDevice.wy_screenWidth(configuration.multiPageRevealWidth, WYBasisKitConfig.defaultScreenPixels)
            let spacing = UIDevice.wy_screenWidth(configuration.multiPageSpacing, WYBasisKitConfig.defaultScreenPixels)
            let axisLength = flowLayout.scrollDirection == .horizontal ? collectionView.bounds.width : collectionView.bounds.height
            let minimumLength = 1 / max(1, view.traitCollection.displayScale)
            let edge = max(0, min(reveal + spacing, (axisLength - minimumLength) / 2))
            if flowLayout.scrollDirection == .horizontal {
                flowLayout.itemSize = CGSize(width: collectionView.bounds.width - edge * 2, height: collectionView.bounds.height)
                flowLayout.sectionInset = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
            } else {
                flowLayout.itemSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height - edge * 2)
                flowLayout.sectionInset = UIEdgeInsets(top: edge, left: 0, bottom: edge, right: 0)
            }
            flowLayout.minimumLineSpacing = spacing
            collectionView.isPagingEnabled = false
        } else {
            flowLayout.itemSize = collectionView.bounds.size
            flowLayout.sectionInset = .zero
            flowLayout.minimumLineSpacing = 0
            collectionView.isPagingEnabled = true
        }
    }

    /// 布局给页的尺寸(与configureFlowLayout的itemSize一致)
    func layoutItemSize() -> CGSize {
        if configuration.layoutStyle == .multiPage {
            return flowLayout.itemSize == .zero ? collectionView.bounds.size : flowLayout.itemSize
        }
        return collectionView.bounds.size
    }

    /// 单页步长(整页为视口宽或高，多页同屏为页尺寸加页间距)
    var pageStep: CGFloat {
        if configuration.layoutStyle == .multiPage {
            if flowLayout.scrollDirection == .horizontal {
                return layoutItemSize().width + flowLayout.minimumLineSpacing
            }
            return layoutItemSize().height + flowLayout.minimumLineSpacing
        }
        if flowLayout.scrollDirection == .horizontal {
            return collectionView.bounds.width
        }
        return collectionView.bounds.height
    }

    /// 步长起点偏移(整页为0，多页同屏为分组内边距)
    var pageStepLeading: CGFloat {
        if configuration.layoutStyle == .multiPage {
            if flowLayout.scrollDirection == .horizontal {
                return flowLayout.sectionInset.left - (collectionView.bounds.width - layoutItemSize().width) / 2
            }
            return flowLayout.sectionInset.top - (collectionView.bounds.height - layoutItemSize().height) / 2
        }
        return 0
    }

    /// 重启自动轮播计时(满足条件才启动，翻页落定与程序化跳页后调用)
    func restartCarouselTimer() {
        pauseCarouselTimer()
        guard isViewLoaded, view.window != nil, configuration.autoCarouselInterval > 0, isLoopScrollingEnabled, isDragDismissing == false else { return }
        carouselTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoCarouselInterval, repeats: false) { [weak self] _ in
            self?.carouselToNext()
        }
    }

    /// 暂停自动轮播计时(手动拖动、拖拽关闭、离屏时调用)
    func pauseCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    /// 自动翻到下一张(末页回绕到首页，自动轮播计时触发)
    func carouselToNext() {
        let next = (internalCurrentIndex + 1) % max(numberOfItems, 1)
        scrollToItem(at: next, animated: true)
    }
}

extension WYPhotoBrowser: UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = true
        return transitionAnimator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = false
        return transitionAnimator
    }
}

final class WYPhotoBrowserResourceStore {
    var directories: [URL] = []
    deinit {
        for directory in directories { try? FileManager.default.removeItem(at: directory) }
    }
}
