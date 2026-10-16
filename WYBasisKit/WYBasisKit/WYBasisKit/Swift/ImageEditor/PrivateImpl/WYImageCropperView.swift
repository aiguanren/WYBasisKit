//
//  WYImageCropperView.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/15.
//

import UIKit

/// 裁剪框把手位置(四个角与四条边，用选项集合方便判断横竖方向)
struct WYImageCropHandleZone: OptionSet {
    let rawValue: UInt
    /// 上边
    static let top = WYImageCropHandleZone(rawValue: 1 << 0)
    /// 下边
    static let bottom = WYImageCropHandleZone(rawValue: 1 << 1)
    /// 左边
    static let left = WYImageCropHandleZone(rawValue: 1 << 2)
    /// 右边
    static let right = WYImageCropHandleZone(rawValue: 1 << 3)
    /// 框线本体(把手之间的线段，拖着平移整个裁剪框)
    static let boxBody = WYImageCropHandleZone(rawValue: 1 << 4)
    /// 左上角
    static let topLeft: WYImageCropHandleZone = [.top, .left]
    /// 右上角
    static let topRight: WYImageCropHandleZone = [.top, .right]
    /// 左下角
    static let bottomLeft: WYImageCropHandleZone = [.bottom, .left]
    /// 右下角
    static let bottomRight: WYImageCropHandleZone = [.bottom, .right]
}

/// 裁剪视图(图片可捏合缩放与拖动，自由模式裁剪框可拖把手调整且松手立即应用裁剪，固定尺寸模式下裁剪框锁死只能动图片)
class WYImageCropperView: UIView {

    /// 裁剪形状
    private(set) var shape: WYImageCropShape = .rectangle

    /// 固定输出尺寸(nil表示不固定，由用户自由拖动裁剪框决定)
    private var fixedOutputSize: CGSize?

    /// 进入时的原图(点还原时恢复它)
    private var originalImage: UIImage = UIImage()

    /// 当前裁剪基准图(自由模式松手应用裁剪后会换成裁剪出的新图)
    private var cropImage: UIImage = UIImage()

    /// 即时裁剪回调(参数为裁剪出的新基准图与本次裁掉区域在旧基准图中的坐标，编辑器用它同步标记画布)
    var onCropCommitted: ((UIImage, CGRect) -> Void)?

    /// 用户是否动过裁剪框(动过后切标记模式才需要应用裁剪，没动过不做无意义裁剪)
    private(set) var hasUserAdjustedCropBox = false

    /// 裁剪历史栈(每次应用裁剪压入旧基准图与本次裁掉区域，逐步还原时回退用)
    private var cropHistory: [(image: UIImage, region: CGRect)] = []

    /// 裁剪回退回调(参数为回退到的旧基准图与当初裁掉的区域，编辑器用它把标记坐标平移回去)
    var onCropReverted: ((UIImage, CGRect) -> Void)?

    /// 界面外观(遮罩框线网格与把手样式从这里取)
    var appearance = WYImageEditorAppearance()

    /// 图片是否支持捏合缩放(false时最大缩放钉死在最小值，只能拖动平移)
    var zoomEnabled = true

    /// 进入页面时图片的初始缩放倍数(相对适配大小的倍数，1为适配显示，0也按适配；会被钳制在允许缩放范围内)
    var initialZoomMultiplier: CGFloat = 1

    /// 适配画布的基准缩放(最小缩放的基线，动态最小缩放=它与覆盖裁剪框的较大者)
    private var baseFitScale: CGFloat = 1

    /// 当前裁剪基准图(出成品图时按它绘制)
    var currentBaseImage: UIImage {
        return cropImage
    }

    /// 当前裁剪框(本视图坐标的矩形框，圆形裁剪时圆内切于这个框)
    private var cropBox: CGRect = .zero

    /// 自由模式拖拽起始时的裁剪框(拖拽过程基于它累加位移，避免误差累积)
    private var dragStartBox: CGRect = .zero

    /// 上次适配图片时的bounds(用于识别屏幕旋转等尺寸变化)
    private var lastLaidOutBounds: CGRect = .zero

    /// 首次布局或bounds变化后需要重新适配图片
    var needsRelayoutAfterBoundsChange: Bool {
        return !bounds.equalTo(lastLaidOutBounds)
    }

    /// 承载图片的滚动视图(捏合缩放与拖动图片都靠它)
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = self
        scroll.backgroundColor = UIColor.clear
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    /// 展示图片的视图
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = true
        return view
    }()

    /// 裁剪框遮罩层(挖孔压暗加网格线加拖拽把手，不挡把手以外的触摸)
    private lazy var overlayView: WYImageCropOverlayView = {
        let overlay = WYImageCropOverlayView()
        overlay.onPanHandle = { [weak self] state, zone, translation in
            self?.cropBoxPanned(state: state, zone: zone, translation: translation)
        }
        return overlay
    }()

    /**
     * 初始化裁剪视图内容
     * - Parameters:
     *   - image: 要裁剪的图片
     *   - shape: 裁剪形状(矩形或圆形)
     *   - fixedOutputSize: 固定输出尺寸(nil表示不固定)
     *   - appearance: 界面外观
     */
    func setup(image: UIImage, shape: WYImageCropShape, fixedOutputSize: CGSize?, appearance: WYImageEditorAppearance, zoomEnabled: Bool, initialZoomMultiplier: CGFloat = 1) {
        originalImage = image
        cropImage = image
        self.shape = shape
        self.fixedOutputSize = fixedOutputSize
        self.appearance = appearance
        self.zoomEnabled = zoomEnabled
        self.initialZoomMultiplier = initialZoomMultiplier
        overlayView.appearance = appearance
        scrollView.addSubview(imageView)
        addSubview(scrollView)
        addSubview(overlayView)
        rebuildContentView(with: image)
    }

    /// 还原(恢复原图并把裁剪框位置大小与图片缩放位移退回刚进来时的状态)
    func reset() {
        cropImage = originalImage
        hasUserAdjustedCropBox = false
        cropHistory.removeAll()
        rebuildContentView(with: originalImage)
        applyInitialLayout()
    }

    /// bounds变化后重新适配(首次布局与屏幕旋转时调用)
    func relayoutForNewBounds() {
        applyInitialLayout()
    }

    /// 当前裁剪框映射到图片坐标系的范围(与图片实际范围取交集，拖出图片边界的部分自动裁掉)
    func cropRectInImageCoordinates() -> CGRect {
        let zoom = scrollView.zoomScale
        guard zoom > 0 else { return .zero }
        let offset = scrollView.contentOffset
        let boxInContent = CGRect(x: cropBox.origin.x + offset.x, y: cropBox.origin.y + offset.y, width: cropBox.width, height: cropBox.height)
        let imageRect = CGRect(origin: .zero, size: CGSize(width: cropImage.size.width * zoom, height: cropImage.size.height * zoom))
        let intersected = boxInContent.intersection(imageRect)
        guard !intersected.isNull else { return .zero }
        return CGRect(x: intersected.origin.x / zoom, y: intersected.origin.y / zoom, width: intersected.width / zoom, height: intersected.height / zoom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayView.frame = bounds
        if needsRelayoutAfterBoundsChange {
            applyInitialLayout()
        }
    }

    /// 计算并应用初始布局(裁剪框摆中间，图片缩放到合适倍数)
    private func applyInitialLayout() {
        lastLaidOutBounds = bounds
        let boundsWidth = bounds.width
        let boundsHeight = bounds.height
        let imageWidth = cropImage.size.width
        let imageHeight = cropImage.size.height
        guard boundsWidth > 0, boundsHeight > 0, imageWidth > 0, imageHeight > 0 else { return }

        let fitScale = min(boundsWidth / imageWidth, boundsHeight / imageHeight)
        baseFitScale = fitScale

        if let fixedSize = fixedOutputSize {

            // 固定尺寸模式，滚动视图就是裁剪框区域，图片至少铺满它，把手收起来只能动图片
            let aspectRatio: CGFloat
            if shape == .circle {
                aspectRatio = 1
            } else {
                aspectRatio = fixedSize.width / max(fixedSize.height, 1)
            }
            let maxBoxWidth = boundsWidth * 0.85
            let maxBoxHeight = boundsHeight * 0.85
            var boxWidth = maxBoxWidth
            var boxHeight = boxWidth / aspectRatio
            if boxHeight > maxBoxHeight {
                boxHeight = maxBoxHeight
                boxWidth = boxHeight * aspectRatio
            }
            cropBox = CGRect(x: (boundsWidth - boxWidth) / 2, y: (boundsHeight - boxHeight) / 2, width: boxWidth, height: boxHeight)

            // 滚动视图铺满画布，图片至少铺满整个画布，取景框外透过遮罩隐约可见而不是纯黑像被裁掉
            scrollView.frame = bounds
            scrollView.bounces = false
            let coverScale = max(boxWidth / imageWidth, boxHeight / imageHeight, boundsWidth / imageWidth, boundsHeight / imageHeight)
            scrollView.minimumZoomScale = coverScale
            scrollView.maximumZoomScale = zoomEnabled ? max(coverScale * 8, fitScale * 8) : coverScale
            scrollView.zoomScale = min(max(coverScale * max(initialZoomMultiplier, 1), coverScale), scrollView.maximumZoomScale)
            scrollView.contentInset = .zero

            // 图片居中摆(内容比画布大多少就往回挪一半)
            let contentWidth = imageWidth * coverScale
            let contentHeight = imageHeight * coverScale
            scrollView.contentOffset = CGPoint(x: max(0, (contentWidth - boundsWidth) / 2), y: max(0, (contentHeight - boundsHeight) / 2))
        } else {

            // 自由模式，滚动视图铺满画布；关闭弹跳(拖到边界硬停，弹跳瞬间图片被拉离裁剪框会露出黑底，苹果照片裁剪页同样无弹跳)
            scrollView.frame = bounds
            scrollView.bounces = false
            let fitWidth = imageWidth * fitScale
            let fitHeight = imageHeight * fitScale
            let fitRect = CGRect(x: (boundsWidth - fitWidth) / 2, y: (boundsHeight - fitHeight) / 2, width: fitWidth, height: fitHeight)
            if shape == .circle {

                // 圆形裁剪框保持正方形，边长取适配后图片的短边铺满
                let side = min(fitWidth, fitHeight)
                cropBox = CGRect(x: (boundsWidth - side) / 2, y: (boundsHeight - side) / 2, width: side, height: side)
            } else {
                cropBox = fitRect
            }
            scrollView.maximumZoomScale = zoomEnabled ? fitScale * 8 : fitScale
            scrollView.zoomScale = min(max(fitScale * max(initialZoomMultiplier, 1), fitScale), scrollView.maximumZoomScale)
            updateMinimumZoomScale()
            centerContentWithInset()
        }

        overlayView.updateCropBox(cropBox, shape: shape, showsHandles: fixedOutputSize == nil)
    }

    /// 回退上一次裁剪(有历史才回退，标记坐标由编辑器经回调平移回去，返回false表示没有可回退的裁剪)
    func undoLastCrop() -> Bool {
        guard let last = cropHistory.last else { return false }
        cropHistory.removeLast()
        cropImage = last.image
        hasUserAdjustedCropBox = false

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rebuildContentView(with: cropImage)
        applyInitialLayout()
        scrollView.layoutIfNeeded()
        CATransaction.commit()
        onCropReverted?(cropImage, last.region)
        return true
    }

    /// 干净重建内容视图(先把缩放归一再拆下重挂图片视图，滚动视图内部缩放基准彻底重置，任何脏状态都归位)
    private func rebuildContentView(with image: UIImage) {
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = 1
        imageView.removeFromSuperview()
        scrollView.addSubview(imageView)
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size
        scrollView.contentInset = .zero
        scrollView.contentOffset = .zero
    }

    /**
     * 应用当前裁剪框的裁剪(CGImage像素直裁不重采样，裁完框回满图内收状态)
     * - Parameter force: true为无条件按当前框真裁(顶部裁剪按钮)，false为框没动过或固定尺寸模式时不裁(切标记模式的保护)
     */
    func commitCrop(force: Bool = false) {
        if !force {
            guard fixedOutputSize == nil, hasUserAdjustedCropBox else { return }
        }

        // 先强制收敛进行中的把手拖拽与滚动缩放手势，避免手势结束时把旧缩放位移套回新布局(表现为裁完图片反而放大超出画布，且逐次叠加)
        overlayView.cancelActivePan()
        if scrollView.isTracking || scrollView.isZooming || scrollView.isDragging || scrollView.isDecelerating {
            if let pinch = scrollView.pinchGestureRecognizer {
                pinch.isEnabled = false
                pinch.isEnabled = true
            }
            scrollView.panGestureRecognizer.isEnabled = false
            scrollView.panGestureRecognizer.isEnabled = true
        }
        let region = cropRectInImageCoordinates()
        guard region.width >= 1, region.height >= 1, let cgImage = cropImage.cgImage else { return }

        // 像素坐标裁剪并夹回图片实际范围(cropping越界会返回nil)
        let scale = cropImage.scale
        var pixelRect = CGRect(x: region.minX * scale, y: region.minY * scale, width: region.width * scale, height: region.height * scale)
        pixelRect.origin.x = max(0, min(pixelRect.origin.x, CGFloat(cgImage.width) - pixelRect.width))
        pixelRect.origin.y = max(0, min(pixelRect.origin.y, CGFloat(cgImage.height) - pixelRect.height))
        pixelRect.size.width = min(pixelRect.width, CGFloat(cgImage.width) - pixelRect.origin.x)
        pixelRect.size.height = min(pixelRect.height, CGFloat(cgImage.height) - pixelRect.origin.y)
        guard pixelRect.width >= 1, pixelRect.height >= 1, let croppedCG = cgImage.cropping(to: pixelRect) else { return }

        // 换基准图重摆布局(标记画布由编辑器经回调同步平移)
        let regionInOldBase = CGRect(x: pixelRect.origin.x / scale, y: pixelRect.origin.y / scale, width: pixelRect.width / scale, height: pixelRect.height / scale)
        let oldBaseImage = cropImage
        cropImage = UIImage(cgImage: croppedCG, scale: scale, orientation: .up)
        hasUserAdjustedCropBox = false

        // 禁隐式动画并归零旧偏移后重摆，规避真实手势下旧缩放位移瞬间套进新布局
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rebuildContentView(with: cropImage)
        applyInitialLayout()
        scrollView.layoutIfNeeded()
        CATransaction.commit()

        cropHistory.append((image: oldBaseImage, region: regionInOldBase))

        // 落定保护(下一个主线程周期核对，真实手势时序里若有任何环节把框改回旧值或漏刷遮罩，强制纠正回裁剪后的满图状态)
        let settledBox = cropBox
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.fixedOutputSize == nil else { return }
            if self.cropBox != settledBox {
                self.cropBox = settledBox
            }
            self.overlayView.updateCropBox(self.cropBox, shape: self.shape, showsHandles: self.fixedOutputSize == nil)
        }
        onCropCommitted?(cropImage, regionInOldBase)
    }

    /// 图片当前显示区(本视图坐标，随缩放平移实时变化，裁剪框始终被钳制在它内部防选到照片外黑边)
    private var imageDisplayRect: CGRect {
        let zoom = scrollView.zoomScale
        let originX = scrollView.frame.minX - scrollView.contentOffset.x
        let originY = scrollView.frame.minY - scrollView.contentOffset.y
        return CGRect(x: originX, y: originY, width: cropImage.size.width * zoom, height: cropImage.size.height * zoom)
    }

    /// 更新最小缩放(图不许缩到小于当前裁剪框，捏合到图等于框时停住，框内始终有图不会露出画布底色)
    private func updateMinimumZoomScale() {
        guard fixedOutputSize == nil else { return }
        let coverBoxScale = max(cropBox.width / max(cropImage.size.width, 1), cropBox.height / max(cropImage.size.height, 1))
        scrollView.minimumZoomScale = max(baseFitScale, coverBoxScale)
        if scrollView.zoomScale < scrollView.minimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
            centerContentWithInset()
        }
    }

    /// 把裁剪框钳回图片显示区内(拖动缩放图片后图片动了框跟着收，尺寸超图时收成图内最大并居中)
    private func clampCropBoxToImage() {
        let imageRect = imageDisplayRect
        guard imageRect.width > 10, imageRect.height > 10 else { return }
        var box = cropBox
        if box.width > imageRect.width {
            box.size.width = imageRect.width
            box.origin.x = imageRect.midX - box.width / 2
        }
        if box.height > imageRect.height {
            box.size.height = imageRect.height
            box.origin.y = imageRect.midY - box.height / 2
        }
        box.origin.x = min(max(box.minX, imageRect.minX), imageRect.maxX - box.width)
        box.origin.y = min(max(box.minY, imageRect.minY), imageRect.maxY - box.height)
        if box != cropBox {
            cropBox = box
            overlayView.updateCropBox(cropBox, shape: shape, showsHandles: fixedOutputSize == nil)
        }
        updateMinimumZoomScale()
    }

    /// 自由模式图片比画布小时用内容边距把它居中
    private func centerContentWithInset() {
        let contentWidth = cropImage.size.width * scrollView.zoomScale
        let contentHeight = cropImage.size.height * scrollView.zoomScale
        let insetX = max(0, (bounds.width - contentWidth) / 2)
        let insetY = max(0, (bounds.height - contentHeight) / 2)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        if contentWidth < bounds.width || contentHeight < bounds.height {
            scrollView.contentOffset = CGPoint(x: -insetX, y: -insetY)
        }
    }

    /// 自由模式拖拽把手(移动或缩放裁剪框，圆形保持正方形等比缩放)
    private func cropBoxPanned(state: UIGestureRecognizer.State, zone: WYImageCropHandleZone, translation: CGPoint) {

        if state == .began {
            dragStartBox = cropBox
        }

        // 松手只保持预览状态，应用裁剪由编辑器在用户点标记或完成时调commitCrop
        if state == .ended, zone != [], abs(translation.x) > 1 || abs(translation.y) > 1 {
            hasUserAdjustedCropBox = true
            updateMinimumZoomScale()
        }
        guard state == .began || state == .changed else { return }

        let margin: CGFloat = 4
        let minSize: CGFloat = 44
        let maxWidth = bounds.width - margin * 2
        let maxHeight = bounds.height - margin * 2
        let start = dragStartBox

        // 抓框线本体拖着走，整个裁剪框平移(位置微调不用再靠缩放框或动图)
        if zone == .boxBody {
            var box = start
            let imageRect = imageDisplayRect
            box.origin.x = min(max(start.minX + translation.x, imageRect.minX), imageRect.maxX - box.width)
            box.origin.y = min(max(start.minY + translation.y, imageRect.minY), imageRect.maxY - box.height)
            cropBox = box
            overlayView.updateCropBox(cropBox, shape: shape, showsHandles: fixedOutputSize == nil)
            return
        }

        let aspectLocked = shape == .circle
        var box: CGRect

        if aspectLocked {

            // 圆形保持正方形，按拖拽方向推算新的边长，对边或对角固定不动
            var proposedSide = start.width
            switch zone {
            case .topLeft: proposedSide = min(start.width - translation.x, start.height - translation.y)
            case .topRight: proposedSide = min(start.width + translation.x, start.height - translation.y)
            case .bottomLeft: proposedSide = min(start.width - translation.x, start.height + translation.y)
            case .bottomRight: proposedSide = min(start.width + translation.x, start.height + translation.y)
            case .left: proposedSide = start.width - translation.x
            case .right: proposedSide = start.width + translation.x
            case .top: proposedSide = start.height - translation.y
            case .bottom: proposedSide = start.height + translation.y
            default: proposedSide = start.width
            }
            let side = min(max(proposedSide, minSize), min(maxWidth, maxHeight))

            var x = start.minX
            var y = start.minY
            if zone == .top || zone == .bottom {
                x = start.midX - side / 2
            } else if zone.contains(.left) {
                x = start.maxX - side
            }
            if zone == .left || zone == .right {
                y = start.midY - side / 2
            } else if zone.contains(.top) {
                y = start.maxY - side
            }
            box = CGRect(x: x, y: y, width: side, height: side)
        } else {

            // 自由矩形，边把手只动一条边，角把手动两条边
            var x = start.origin.x
            var y = start.origin.y
            var width = start.width
            var height = start.height
            if zone.contains(.left) {
                width = min(max(start.width - translation.x, minSize), maxWidth)
                x = start.maxX - width
            }
            if zone.contains(.right) {
                width = min(max(start.width + translation.x, minSize), maxWidth)
            }
            if zone.contains(.top) {
                height = min(max(start.height - translation.y, minSize), maxHeight)
                y = start.maxY - height
            }
            if zone.contains(.bottom) {
                height = min(max(start.height + translation.y, minSize), maxHeight)
            }
            box = CGRect(x: x, y: y, width: width, height: height)
        }

        // 整体不拖出照片显示区，出界时贴图边(尺寸超图时收成图内最大)
        let imageRect = imageDisplayRect
        if box.width > imageRect.width {
            box.size.width = imageRect.width
        }
        if box.height > imageRect.height {
            box.size.height = imageRect.height
        }
        box.origin.x = min(max(box.origin.x, imageRect.minX), imageRect.maxX - box.width)
        box.origin.y = min(max(box.origin.y, imageRect.minY), imageRect.maxY - box.height)
        cropBox = box
        overlayView.updateCropBox(cropBox, shape: shape, showsHandles: fixedOutputSize == nil)
    }
}

extension WYImageCropperView: UIScrollViewDelegate {

    /// 缩放锚定在图片本身
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    /// 拖动图片结束(无惯性)，若框悬到图片外一次性钳回(交互进行中框保持画布位置不动)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if fixedOutputSize == nil, !decelerate {
            clampCropBoxToImage()
        }
    }

    /// 拖动惯性滚动结束，若框悬到图片外一次性钳回
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if fixedOutputSize == nil {
            clampCropBoxToImage()
        }
    }

    /// 缩放结束后图片比画布小时重新居中，若框悬到图片外一次性钳回
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if fixedOutputSize == nil {
            centerContentWithInset()
            clampCropBoxToImage()
        }
    }
}

/// 裁剪框遮罩层(裁剪框外压暗，框上画白边网格线与拖拽把手，把手以外区域不拦截触摸)
class WYImageCropOverlayView: UIView {

    /// 把手拖拽回调(状态加把手位置加累计位移)
    var onPanHandle: ((UIGestureRecognizer.State, WYImageCropHandleZone, CGPoint) -> Void)?

    /// 界面外观(遮罩框线网格与把手样式)
    var appearance = WYImageEditorAppearance()

    /// 当前裁剪框
    private var cropBox: CGRect = .zero

    /// 裁剪形状
    private var shape: WYImageCropShape = .rectangle

    /// 是否显示拖拽把手(固定尺寸模式不显示)
    private var showsHandles = true

    /// 把手拖拽手势(只认单指，多指全部让给下层滚动视图的捏合)
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()

    /// 手势起点命中的把手位置
    private var activeZone: WYImageCropHandleZone = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isOpaque = false
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新裁剪框数据并重画
    func updateCropBox(_ box: CGRect, shape: WYImageCropShape, showsHandles: Bool) {
        cropBox = box
        self.shape = shape
        self.showsHandles = showsHandles
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), cropBox.width > 0, cropBox.height > 0 else { return }

        // 框外压暗(矩形按矩形挖孔，圆形按内切圆挖孔)
        context.setFillColor(UIColor(white: 0, alpha: max(0, min(1, appearance.maskDimmingAmount))).cgColor)
        let fillPath = UIBezierPath(rect: bounds)
        let holePath: UIBezierPath
        if shape == .circle {
            holePath = UIBezierPath(ovalIn: cropBox)
        } else {
            holePath = UIBezierPath(rect: cropBox)
        }
        fillPath.append(holePath)
        fillPath.usesEvenOddFillRule = true
        fillPath.fill()

        // 框线(线宽必须设在UIBezierPath自身上，设CGContext线宽对path.stroke()不生效)
        context.setStrokeColor(appearance.cropBorderColor.cgColor)
        let borderPath: UIBezierPath
        if shape == .circle {
            borderPath = UIBezierPath(ovalIn: cropBox.insetBy(dx: 0.75, dy: 0.75))
        } else {
            borderPath = UIBezierPath(rect: cropBox.insetBy(dx: 0.75, dy: 0.75))
        }
        borderPath.lineWidth = appearance.cropBorderWidth
        borderPath.stroke()

        // 矩形画九宫格辅助线(圆形不画)
        if shape == .rectangle {
            context.setStrokeColor(appearance.gridLineColor.cgColor)
            let gridPath = UIBezierPath()
            for index in 1...2 {
                let xPosition = cropBox.origin.x + cropBox.width * CGFloat(index) / 3
                gridPath.move(to: CGPoint(x: xPosition, y: cropBox.origin.y))
                gridPath.addLine(to: CGPoint(x: xPosition, y: cropBox.maxY))
                let yPosition = cropBox.origin.y + cropBox.height * CGFloat(index) / 3
                gridPath.move(to: CGPoint(x: cropBox.origin.x, y: yPosition))
                gridPath.addLine(to: CGPoint(x: cropBox.maxX, y: yPosition))
            }
            gridPath.lineWidth = 1
            gridPath.stroke()
        }

        guard showsHandles else { return }

        // 四角L形把手(线宽设在路径自身才生效，与四边短把手同厚)
        context.setStrokeColor(appearance.handleColor.cgColor)
        let armLength: CGFloat = appearance.handleArmLength
        let cornerPath = UIBezierPath()
        cornerPath.lineWidth = 4
        cornerPath.lineCapStyle = .round
        cornerPath.lineJoinStyle = .round
        let corners = [CGPoint(x: cropBox.minX, y: cropBox.minY), CGPoint(x: cropBox.maxX, y: cropBox.minY), CGPoint(x: cropBox.minX, y: cropBox.maxY), CGPoint(x: cropBox.maxX, y: cropBox.maxY)]
        for corner in corners {
            let horizontalDirection: CGFloat = corner.x == cropBox.minX ? 1 : -1
            let verticalDirection: CGFloat = corner.y == cropBox.minY ? 1 : -1
            cornerPath.move(to: corner)
            cornerPath.addLine(to: CGPoint(x: corner.x + horizontalDirection * armLength, y: corner.y))
            cornerPath.move(to: corner)
            cornerPath.addLine(to: CGPoint(x: corner.x, y: corner.y + verticalDirection * armLength))
        }
        cornerPath.stroke()

        // 四边中点短把手
        let barLength: CGFloat = 28
        let barThickness: CGFloat = 4
        let barRadius: CGFloat = 2
        let barColor = appearance.handleColor
        let edgeBars = [
            CGRect(x: cropBox.midX - barLength / 2, y: cropBox.minY - barThickness / 2, width: barLength, height: barThickness),
            CGRect(x: cropBox.midX - barLength / 2, y: cropBox.maxY - barThickness / 2, width: barLength, height: barThickness),
            CGRect(x: cropBox.minX - barThickness / 2, y: cropBox.midY - barLength / 2, width: barThickness, height: barLength),
            CGRect(x: cropBox.maxX - barThickness / 2, y: cropBox.midY - barLength / 2, width: barThickness, height: barLength)
        ]
        for barRect in edgeBars {
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: barRadius)
            barColor.setFill()
            barPath.fill()
        }
    }

    /// 取消进行中的把手拖拽手势(应用裁剪前调用，手势强置失败立即结束)
    func cancelActivePan() {
        if panGesture.isEnabled {
            panGesture.isEnabled = false
            panGesture.isEnabled = true
        }
    }

    /// 只拦截把手与框线段的触摸，框内框外都透给下层滚动视图(拖动捏合图片随时可用)；固定尺寸模式同样只认把手与框线
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let zone = handleZone(at: point)
        if zone == .boxBody || (showsHandles && zone != []) {
            return self
        }
        return nil
    }

    /// 把手拖拽处理(开始时用按下触点记住命中把手，过程中持续回报累计位移)
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:

            // 用按下时刻的触点判热区(pan要移动几像素才触发began，用当前点判定会因手指微滑出热区而抓空)
            let downPoint = gesture.numberOfTouches > 0 ? gesture.location(ofTouch: 0, in: self) : gesture.location(in: self)
            activeZone = handleZone(at: downPoint)
            if activeZone == [] {

                // 判空说明手势被误识别，立即置失败把触摸还给下层滚动视图
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            onPanHandle?(.began, activeZone, .zero)
        case .changed:
            let translation = gesture.translation(in: self)
            onPanHandle?(.changed, activeZone, translation)
        default:
            onPanHandle?(gesture.state, activeZone, gesture.translation(in: self))
            activeZone = []
        }
    }

    /// 判断点落在哪个把手的热区(角把手优先半径30，四条边整条边可抓带宽18，好抓不误触)
    private func handleZone(at point: CGPoint) -> WYImageCropHandleZone {
        let cornerRadius: CGFloat = 30
        let corners: [(CGPoint, WYImageCropHandleZone)] = [
            (CGPoint(x: cropBox.minX, y: cropBox.minY), .topLeft),
            (CGPoint(x: cropBox.maxX, y: cropBox.minY), .topRight),
            (CGPoint(x: cropBox.minX, y: cropBox.maxY), .bottomLeft),
            (CGPoint(x: cropBox.maxX, y: cropBox.maxY), .bottomRight)
        ]
        for (corner, zone) in corners {
            if hypot(point.x - corner.x, point.y - corner.y) <= cornerRadius {
                return zone
            }
        }
        // 边把手只认中点附近(把手之间的框线段留给整框拖动，框内区域还给图片供拖动捏合)
        let edgeBand: CGFloat = 18
        if abs(point.y - cropBox.minY) <= edgeBand, abs(point.x - cropBox.midX) <= 30 {
            return .top
        }
        if abs(point.y - cropBox.maxY) <= edgeBand, abs(point.x - cropBox.midX) <= 30 {
            return .bottom
        }
        if abs(point.x - cropBox.minX) <= edgeBand, abs(point.y - cropBox.midY) <= 30 {
            return .left
        }
        if abs(point.x - cropBox.maxX) <= edgeBand, abs(point.y - cropBox.midY) <= 30 {
            return .right
        }

        // 把手之间的框线段拖着平移整个裁剪框(框内与框外都还给图片，放大缩小随时可操作)
        let nearVerticalLine = abs(point.x - cropBox.minX) <= edgeBand || abs(point.x - cropBox.maxX) <= edgeBand
        let nearHorizontalLine = abs(point.y - cropBox.minY) <= edgeBand || abs(point.y - cropBox.maxY) <= edgeBand
        if nearVerticalLine || nearHorizontalLine {
            return .boxBody
        }
        return []
    }
}
