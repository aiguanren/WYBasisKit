//
//  WYPhotoBrowserPageCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI
import Kingfisher

/// 浏览器页Cell(单页图片的缩放容器，负责分级加载显示、LivePhoto合成播放、视频封面播放按钮与拖拽关闭手势)
class WYPhotoBrowserPageCell: UICollectionViewCell, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    /// 复用标识
    static let reuseIdentifier: String = "WYPhotoBrowserPageCell"

    /// 所属浏览器(手势决策与事件转发都走它)
    weak var browser: WYPhotoBrowser?

    /// 当前页浏览项
    var item: WYPhotoBrowserItem?

    /// 当前页下标
    var index: Int = 0

    /// 行为配置(configure时刷新)
    var configuration: WYPhotoBrowserConfiguration = WYPhotoBrowserConfiguration()

    /// 配置代数(复用后递增，旧回调按代数丢弃，防止把旧内容错当这次的)
    var configureGeneration: Int = 0

    /// LivePhoto合成请求的代数(与配置代数对不上时丢弃回调)
    var livePhotoRequestGeneration: Int = -1

    /// LivePhoto素材下载任务(取消旧下载用)
    var livePhotoAssemblyTask: Task<Void, Never>?
    var livePhotoRequestID: PHLivePhotoRequestID?
    var livePhotoAssetRequestID: PHImageRequestID?

    /// LivePhoto是否已就绪(就绪后才显示角标并允许长按播放)
    var isLivePhotoReady: Bool = false

    /// LivePhoto播放中标记
    var isLivePhotoPlaying: Bool = false

    /// 原图已显示标记(原图链路走完后不再重复加载)
    var isOriginalLoaded: Bool = false

    /// 原图按钮当前状态
    var originalButtonState: OriginalButtonState = .hidden

    /// 拖拽关闭进行中标记(方向确认后为true，手势结束前不再响应翻页)
    var isDraggingToDismiss: Bool = false

    /// 已显示图片的尺寸(布局与转场取适配框用)
    var displayedImageSize: CGSize?

    /// 原图按钮状态(隐藏、待点击加载、加载中、失败、完成提示)
    enum OriginalButtonState: Int {
        /// 不显示按钮
        case hidden = 0
        /// 待点击加载(显示查看原图与大小)
        case idle = 1
        /// 加载中(显示百分比)
        case loading = 2
        /// 加载失败(显示点击重试)
        case failed = 3
        /// 加载完成(短暂显示已显示原图后隐藏)
        case finished = 4
    }

    /// 双击手势(声明为属性供单击手势等待它失败)
    lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        contentView.addSubview(zoomScrollView)
        zoomScrollView.addSubview(zoomContainer)
        zoomContainer.addSubview(contentImageView)
        zoomContainer.addSubview(livePhotoView)
        contentView.addSubview(playButton)
        contentView.addSubview(livePhotoBadge)
        contentView.addSubview(progressContainerView)
        contentView.addSubview(retryButton)
        contentView.addSubview(originalButton)

        progressContainerView.layer.addSublayer(progressTrackLayer)
        progressContainerView.layer.addSublayer(progressRingLayer)
        progressContainerView.addSubview(progressLabel)

        zoomScrollView.addGestureRecognizer(doubleTapGesture)
        zoomScrollView.panGestureRecognizer.isEnabled = false
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        singleTap.require(toFail: doubleTapGesture)
        contentView.addGestureRecognizer(singleTap)

        let dragPan = UIPanGestureRecognizer(target: self, action: #selector(dragPanned(_:)))
        dragPan.maximumNumberOfTouches = 1
        dragPan.delegate = self
        zoomScrollView.addGestureRecognizer(dragPan)
    }

    deinit {
        cancelLoadingTasks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 缩放滚动视图(捏合缩放与放大后的拖动看图)
    lazy var zoomScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    /// 缩放容器(双击与捏合的缩放对象，内部装图片与LivePhoto视图)
    let zoomContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 图片视图(Kingfisher动画视图，GIF动图直接动)
    let contentImageView: AnimatedImageView = {
        let view = AnimatedImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    /// LivePhoto视图(系统视图，接管播放，不参与触摸)
    let livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    /// 视频封面播放按钮(点它回调代理，浏览器不播视频)
    let playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        return button
    }()

    /// LivePhoto角标(左上角Live胶囊，素材就绪后显示)
    let livePhotoBadge: UILabel = {
        let label = UILabel()
        label.text = "Live"
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    /// 加载进度容器(环形进度与百分比文字)
    let progressContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    /// 环形进度(描边圆环，进度走strokeEnd)
    let progressRingLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2.5
        layer.strokeEnd = 0
        return layer
    }()

    /// 进度轨道环(进度环的底环)
    let progressTrackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2.5
        return layer
    }()

    /// 进度百分比文字
    let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    /// 加载失败重试胶囊(点它重走加载链路)
    let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        return button
    }()

    /// 查看原图按钮(底部居中，手动加载方式下显示)
    let originalButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        return button
    }()

    /**
     * 配置页内容
     *   @param item 该页浏览项
     *   @param index 该页下标
     *   @param configuration 浏览器行为与外观配置
     */
    func configure(item: WYPhotoBrowserItem, index: Int, configuration: WYPhotoBrowserConfiguration) {
        configureGeneration += 1
        self.item = item
        self.index = index
        self.configuration = configuration
        zoomScrollView.maximumZoomScale = max(1, configuration.maxZoomScale)

        cancelLoadingTasks()
        contentImageView.kf.cancelDownloadTask()
        isOriginalLoaded = false
        isLivePhotoReady = false
        isLivePhotoPlaying = false
        isDraggingToDismiss = false
        originalButtonState = .hidden
        displayedImageSize = nil
        transform = .identity
        contentImageView.image = nil
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        retryButton.isHidden = true
        progressContainerView.isHidden = true
        originalButton.isHidden = true

        applyAppearance()

        if let placeholder = item.placeholder {
            applyImage(placeholder)
        }
        if item.mediaType == .video {
            loadThumbnail(item: item)
            return
        }
        loadThumbnail(item: item)
        prepareLivePhotoIfNeeded(item: item)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        configureGeneration += 1
        cancelLoadingTasks()
        contentImageView.kf.cancelDownloadTask()
        contentImageView.image = nil
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        isLivePhotoReady = false
        isLivePhotoPlaying = false
        displayedImageSize = nil
        transform = .identity
        alpha = 1
        zoomScrollView.setZoomScale(1, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let sizeChanged = zoomScrollView.bounds.size != contentView.bounds.size
        let previousZoom = zoomScrollView.zoomScale
        let center = zoomScrollView.convert(CGPoint(x: zoomScrollView.bounds.midX, y: zoomScrollView.bounds.midY), to: zoomContainer)
        let relativeCenter = CGPoint(x: zoomContainer.bounds.width > 0 ? center.x / zoomContainer.bounds.width : 0.5,
                                     y: zoomContainer.bounds.height > 0 ? center.y / zoomContainer.bounds.height : 0.5)
        zoomScrollView.frame = contentView.bounds
        if sizeChanged {
            layoutMainContent()
            if previousZoom > 1, displayedImageSize != nil {
                zoomScrollView.setZoomScale(min(previousZoom, zoomScrollView.maximumZoomScale), animated: false)
                centerZoomContainer()
                let x = zoomContainer.frame.minX + max(0, min(1, relativeCenter.x)) * zoomContainer.frame.width - zoomScrollView.bounds.width / 2
                let y = zoomContainer.frame.minY + max(0, min(1, relativeCenter.y)) * zoomContainer.frame.height - zoomScrollView.bounds.height / 2
                let inset = zoomScrollView.adjustedContentInset
                let maxX = max(-inset.left, zoomScrollView.contentSize.width - zoomScrollView.bounds.width + inset.right)
                let maxY = max(-inset.top, zoomScrollView.contentSize.height - zoomScrollView.bounds.height + inset.bottom)
                zoomScrollView.contentOffset = CGPoint(x: max(-inset.left, min(maxX, x)), y: max(-inset.top, min(maxY, y)))
            }
        }
        layoutOverlays()
    }

    /// 按外观配置刷新页内控件样式(控件是懒加载且初次构建在配置就位前，配置后统一重套一次)
    func applyAppearance() {
        let appearance = configuration.appearance

        let iconSize = UIDevice.wy_screenWidth(28, WYBasisKitConfig.defaultScreenPixels)
        let playIcon = appearance.playButtonIcon ?? UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: UIFont.wy_fontSize(24, WYBasisKitConfig.defaultScreenPixels), weight: .medium))
        let sizedIcon = scaleIconIfNeeded(playIcon, maxSize: iconSize)
        playButton.setImage(sizedIcon?.withTintColor(appearance.playButtonIconColor, renderingMode: .alwaysOriginal), for: .normal)
        playButton.imageView?.contentMode = .center
        playButton.wy_backgroundColor(appearance.playButtonBackgroundColor, forState: .normal)
        playButton.layer.cornerRadius = UIDevice.wy_screenWidth(31, WYBasisKitConfig.defaultScreenPixels)
        playButton.clipsToBounds = true

        let badgeHeight = UIDevice.wy_screenHeight(18, WYBasisKitConfig.defaultScreenPixels)
        livePhotoBadge.font = .systemFont(ofSize: UIFont.wy_fontSize(appearance.livePhotoBadgeFontSize, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        livePhotoBadge.textColor = appearance.livePhotoBadgeTextColor
        livePhotoBadge.backgroundColor = appearance.livePhotoBadgeBackgroundColor
        livePhotoBadge.layer.cornerRadius = badgeHeight / 2
        livePhotoBadge.layer.masksToBounds = true

        progressRingLayer.strokeColor = appearance.progressRingColor.cgColor
        progressTrackLayer.strokeColor = appearance.progressRingTrackColor.cgColor
        progressLabel.font = .systemFont(ofSize: UIFont.wy_fontSize(appearance.progressLabelFontSize, WYBasisKitConfig.defaultScreenPixels))
        progressLabel.textColor = appearance.progressLabelColor

        styleCapsule(retryButton, backgroundColor: appearance.retryButtonBackgroundColor, textColor: appearance.retryButtonTextColor, fontSize: appearance.retryButtonFontSize, capsuleHeight: UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels))
        styleCapsule(originalButton, backgroundColor: appearance.originalButtonBackgroundColor, textColor: appearance.originalButtonTextColor, fontSize: appearance.originalButtonFontSize, capsuleHeight: UIDevice.wy_screenHeight(32, WYBasisKitConfig.defaultScreenPixels))
        retryButton.wy_nTitle = WYLocalized("加载失败，点击重试", table: WYBasisKitConfig.kitLocalizableTable)
        livePhotoBadge.accessibilityIdentifier = "WYPhotoBrowser.liveBadge"
        retryButton.accessibilityIdentifier = "WYPhotoBrowser.retry"
        originalButton.accessibilityIdentifier = "WYPhotoBrowser.original"
        playButton.accessibilityIdentifier = "WYPhotoBrowser.videoPlay"
    }

    /**
     * 自定义图标超尺寸压回(内置符号图标自带点号尺寸不受影响)
     *   @param icon 播放图标
     *   @param maxSize 允许的最大边长(设计值换算后的点)
     * @return 不超尺寸返回原图，超了返回缩放图
     */
    func scaleIconIfNeeded(_ icon: UIImage?, maxSize: CGFloat) -> UIImage? {
        guard let icon = icon else { return nil }
        let longest = max(icon.size.width, icon.size.height) / icon.scale
        guard longest > maxSize, longest > 0 else { return icon }
        let scale = maxSize / longest
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = icon.scale * scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: icon.size.width * scale, height: icon.size.height * scale), format: format)
        return renderer.image { _ in
            icon.draw(in: CGRect(origin: .zero, size: CGSize(width: icon.size.width * scale, height: icon.size.height * scale)))
        }
    }

    /**
     * 给胶囊按钮套样式(WYButton扩展实现，无过时API)
     *   @param button 目标按钮
     *   @param backgroundColor 胶囊底色
     *   @param textColor 文字颜色
     *   @param fontSize 文字字号(设计值，按基准屏换算)
     *   @param capsuleHeight 胶囊高度(设计值，按基准屏换算，圆角取高度一半)
     */
    func styleCapsule(_ button: UIButton, backgroundColor: UIColor, textColor: UIColor, fontSize: CGFloat, capsuleHeight: CGFloat) {
        button.wy_title_nColor = textColor
        button.wy_titleFont = .systemFont(ofSize: UIFont.wy_fontSize(fontSize, WYBasisKitConfig.defaultScreenPixels))
        button.wy_backgroundColor(backgroundColor, forState: .normal)
        button.layer.cornerRadius = capsuleHeight / 2
        button.clipsToBounds = true
        button.wy_contentInsets(UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(18, WYBasisKitConfig.defaultScreenPixels), bottom: 0, right: UIDevice.wy_screenWidth(18, WYBasisKitConfig.defaultScreenPixels)))
    }

    /// 当前显示的图片(优先取图片视图里最高清的静图，LivePhoto封面兜底)
    func currentDisplayImage() -> UIImage? {
        return contentImageView.image
    }

    /// 隐藏或恢复图片内容(转场动画期间隐藏真内容避免双层图)
    func setMainContentHidden(_ hidden: Bool) {
        zoomScrollView.isHidden = hidden
    }

    /// 页内覆盖层隐藏开关(拖拽与转场时淡出播放按钮、角标与按钮)
    func setChromeHidden(_ hidden: Bool) {
        playButton.isHidden = hidden || item?.mediaType != .video
        livePhotoBadge.isHidden = hidden || isLivePhotoReady == false
        originalButton.isHidden = hidden || originalButtonState == .hidden
    }

    /// 图片内容的屏幕位置(拖拽关闭动画的起点)
    func mainContentScreenFrame() -> CGRect? {
        guard displayedImageSize != nil else { return nil }
        return zoomContainer.convert(zoomContainer.bounds, to: nil)
    }

    /// 图片内容在指定视图里的位置(转场动画算缩放目标框用)
    func mainContentFrame(in view: UIView) -> CGRect? {
        guard displayedImageSize != nil else { return nil }
        return zoomContainer.convert(zoomContainer.bounds, to: view)
    }

    /// 图片内容快照(转场与拖拽关闭动画用替代真内容)
    func takeMainContentSnapshot() -> UIView? {
        guard displayedImageSize != nil else { return nil }
        return zoomContainer.snapshotView(afterScreenUpdates: false)
    }

    /**
     * 施加多页同屏的过渡特效(按页中心离视口中心的比例做缩放平移与压暗，拖拽关闭进行中不调用)
     *   @param style 过渡特效样式
     *   @param ratio 页中心偏离视口中心的比例(0为居中，负在左正在右)
     */
    func applyLayoutTransform(style: WYPhotoBrowserTransformStyle, ratio: CGFloat) {
        let clamped = max(-1.5, min(1.5, ratio))
        let distance = abs(clamped)
        switch style {
        case .none:
            transform = .identity
            alpha = 1
        case .scale:
            let scale = max(0.8, 1 - distance * 0.18)
            transform = CGAffineTransform(scaleX: scale, y: scale)
            alpha = 1
        case .depth:
            let scale = max(0.72, 1 - distance * 0.24)
            transform = CGAffineTransform(scaleX: scale, y: scale)
            alpha = max(0.4, 1 - distance * 0.5)
        case .accordion:
            let scaleX = max(0.5, 1 - distance * 0.42)
            transform = CGAffineTransform(scaleX: scaleX, y: 1)
            alpha = 1
        case .stack:
            let scale = max(0.78, 1 - distance * 0.16)
            let shift = -clamped * contentView.bounds.width * 0.35
            transform = CGAffineTransform(translationX: shift, y: 0).scaledBy(x: scale, y: scale)
            alpha = 1
        case .overlap:
            let shift = -clamped * contentView.bounds.width * 0.18
            transform = CGAffineTransform(translationX: shift, y: 0)
            alpha = 1
        }
    }

    /// 弹回原位(拖拽未达阈值松手时调用)
    func springBack() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.4, options: [.allowUserInteraction]) {
            self.transform = .identity
        }
    }

    /// 播放LivePhoto(素材未就绪时忽略)
    func playLivePhoto() {
        guard isLivePhotoReady, livePhotoView.livePhoto != nil else { return }
        isLivePhotoPlaying = true
        livePhotoBadge.alpha = 0.45
        livePhotoView.startPlayback(with: .full)
    }

    /// 停止LivePhoto播放(松手时由浏览器回调)
    func stopLivePhoto() {
        guard isLivePhotoPlaying else { return }
        isLivePhotoPlaying = false
        livePhotoBadge.alpha = 1
        livePhotoView.stopPlayback()
    }

    /// 取消进行中的加载与合成任务(复用与重新配置时调用)
    func cancelLoadingTasks() {
        livePhotoAssemblyTask?.cancel()
        livePhotoAssemblyTask = nil
        livePhotoRequestGeneration = -1
        if let request = livePhotoRequestID { PHLivePhoto.cancelRequest(withRequestID: request) }
        livePhotoRequestID = nil
        if let request = livePhotoAssetRequestID { PHImageManager.default().cancelImageRequest(request) }
        livePhotoAssetRequestID = nil
    }

    /// 显示图片并按新尺寸重摆(用户正在缩放时只换图不重摆，避免打断手势)
    func applyImage(_ image: UIImage) {
        contentImageView.image = image
        displayedImageSize = image.size
        if zoomScrollView.zoomScale <= 1.01 {
            layoutMainContent()
        }
    }

    /// 摆放图片内容(适配进滚动视图并居中，重置缩放)
    func layoutMainContent() {
        guard let imageSize = displayedImageSize else {
            zoomContainer.frame = contentView.bounds
            contentImageView.frame = zoomContainer.bounds
            livePhotoView.frame = zoomContainer.bounds
            zoomScrollView.contentSize = contentView.bounds.size
            return
        }
        zoomScrollView.setZoomScale(1, animated: false)
        let fitRect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: zoomScrollView.bounds.size))
        zoomContainer.frame = fitRect
        contentImageView.frame = zoomContainer.bounds
        livePhotoView.frame = zoomContainer.bounds
        zoomScrollView.contentSize = CGSize(width: max(fitRect.width, zoomScrollView.bounds.width), height: max(fitRect.height, zoomScrollView.bounds.height))
        centerZoomContainer()
    }

    /// 居中缩放容器(内容小于视口时补边距居中，放大后由滚动接管)
    func centerZoomContainer() {
        let boundsSize = zoomScrollView.bounds.size
        var frameToCenter = zoomContainer.frame
        frameToCenter.origin.x = boundsSize.width > frameToCenter.width ? (boundsSize.width - frameToCenter.width) / 2 : 0
        frameToCenter.origin.y = boundsSize.height > frameToCenter.height ? (boundsSize.height - frameToCenter.height) / 2 : 0
        zoomContainer.frame = frameToCenter
    }

    /// 摆放页内覆盖层(播放按钮居中、角标左上、进度居中、胶囊按钮各归其位)
    func layoutOverlays() {
        let playSize = UIDevice.wy_screenWidth(62, WYBasisKitConfig.defaultScreenPixels)
        playButton.frame = CGRect(x: (contentView.bounds.width - playSize) / 2, y: (contentView.bounds.height - playSize) / 2, width: playSize, height: playSize)

        let badgeHeight = UIDevice.wy_screenHeight(18, WYBasisKitConfig.defaultScreenPixels)
        let badgeWidth = UIDevice.wy_screenWidth(42, WYBasisKitConfig.defaultScreenPixels)
        let badgeMargin = UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)
        let badgeTop = contentView.safeAreaInsets.top + badgeMargin
        livePhotoBadge.frame = CGRect(x: badgeMargin, y: badgeTop, width: badgeWidth, height: badgeHeight)

        let ringSize = UIDevice.wy_screenWidth(44, WYBasisKitConfig.defaultScreenPixels)
        let labelWidth = UIDevice.wy_screenWidth(64, WYBasisKitConfig.defaultScreenPixels)
        let labelHeight = UIDevice.wy_screenHeight(16, WYBasisKitConfig.defaultScreenPixels)
        let containerWidth = max(ringSize, labelWidth)
        let containerHeight = ringSize + labelHeight + UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels)
        progressContainerView.frame = CGRect(x: (contentView.bounds.width - containerWidth) / 2, y: (contentView.bounds.height - containerHeight) / 2, width: containerWidth, height: containerHeight)
        progressTrackLayer.frame = CGRect(x: (containerWidth - ringSize) / 2, y: 0, width: ringSize, height: ringSize)
        progressRingLayer.frame = CGRect(x: (containerWidth - ringSize) / 2, y: 0, width: ringSize, height: ringSize)
        progressLabel.frame = CGRect(x: (containerWidth - labelWidth) / 2, y: ringSize + UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels), width: labelWidth, height: labelHeight)

        retryButton.sizeToFit()
        let retryHeight = UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels)
        retryButton.frame = CGRect(x: (contentView.bounds.width - retryButton.bounds.width) / 2, y: (contentView.bounds.height - retryHeight) / 2, width: retryButton.bounds.width, height: retryHeight)

        originalButton.sizeToFit()
        let originalHeight = UIDevice.wy_screenHeight(32, WYBasisKitConfig.defaultScreenPixels)
        let originalBottom = contentView.bounds.height - contentView.safeAreaInsets.bottom - UIDevice.wy_screenHeight(28, WYBasisKitConfig.defaultScreenPixels)
        originalButton.frame = CGRect(x: (contentView.bounds.width - originalButton.bounds.width) / 2, y: originalBottom - originalHeight, width: originalButton.bounds.width, height: originalHeight)
    }

    /// 加载缩略图(本地路径与网络地址都走Kingfisher保留GIF动画，无可显内容时显示进度环)
    func loadThumbnail(item: WYPhotoBrowserItem) {
        let generation = configureGeneration
        if let thumbnailPath = item.thumbnailPath {
            let fileURL = URL(string: thumbnailPath).flatMap { $0.isFileURL ? $0 : nil } ?? URL(fileURLWithPath: thumbnailPath)
            contentImageView.kf.setImage(with: .provider(LocalFileImageDataProvider(fileURL: fileURL)), options: [.backgroundDecode]) { [weak self] result in
                guard let self = self, generation == self.configureGeneration else { return }
                if case .success(let value) = result {
                    self.hideProgressAndRetry()
                    self.applyImage(value.image)
                    self.loadOriginalIfSuitable(item: item)
                } else {
                    self.continueWithoutThumbnail(item: item)
                }
            }
            return
        }
        if let thumbnailURL = item.thumbnailURL {
            contentImageView.kf.setImage(with: thumbnailURL, options: [.backgroundDecode, .transition(.fade(0.15))], progressBlock: { [weak self] received, total in
                guard let self = self, generation == self.configureGeneration, total > 0 else { return }
                if self.contentImageView.image == nil {
                    self.showProgress(percent: CGFloat(received) / CGFloat(total))
                }
            }, completionHandler: { [weak self] result in
                guard let self = self, generation == self.configureGeneration else { return }
                switch result {
                case .success(let value):
                    self.hideProgressAndRetry()
                    self.applyImage(value.image)
                    self.loadOriginalIfSuitable(item: item)
                case .failure:
                    self.continueWithoutThumbnail(item: item)
                }
            })
            return
        }
        continueWithoutThumbnail(item: item)
    }

    /// 缩略图缺路或加载失败后的兜底(有可显内容就接着走原图链路，否则显示重试胶囊)
    func continueWithoutThumbnail(item: WYPhotoBrowserItem) {
        hideProgressAndRetry()
        if contentImageView.image != nil || item.originalPath != nil || item.originalURL != nil {
            loadOriginalIfSuitable(item: item)
        } else {
            showRetryOrNothing()
        }
    }

    /// 按配置决定是否加载原图(本地原图直接加载，自动方式与视频封面直接下载，手动方式显示按钮)
    func loadOriginalIfSuitable(item: WYPhotoBrowserItem) {
        if let originalPath = item.originalPath {
            let fileURL = URL(string: originalPath).flatMap { $0.isFileURL ? $0 : nil } ?? URL(fileURLWithPath: originalPath)
            let generation = configureGeneration
            contentImageView.kf.setImage(with: .provider(LocalFileImageDataProvider(fileURL: fileURL)), options: [.backgroundDecode, .keepCurrentImageWhileLoading]) { [weak self] result in
                guard let self = self, generation == self.configureGeneration else { return }
                if case .success(let value) = result {
                    self.isOriginalLoaded = true
                    self.applyImage(value.image)
                    self.browser?.pageCell(self, didFinishLoadingOriginalAt: self.index)
                } else {
                    self.loadOriginalFromNetworkIfPossible(item: item)
                }
            }
            return
        }
        loadOriginalFromNetworkIfPossible(item: item)
    }

    /// 原图网络加载入口(手动加载方式且非视频封面时改为显示按钮)
    func loadOriginalFromNetworkIfPossible(item: WYPhotoBrowserItem) {
        guard let originalURL = item.originalURL, isOriginalLoaded == false else { return }
        if item.mediaType == .video || configuration.originalLoadStyle == .automatic {
            loadOriginalFromNetwork(item: item, url: originalURL, showButtonProgress: false)
        } else {
            originalButtonState = .idle
            refreshOriginalButtonTitle(item: item)
        }
    }

    /**
     * 从网络加载原图
     *   @param item 浏览项
     *   @param url 原图网络地址
     *   @param showButtonProgress true在原图按钮上显示百分比进度，false静默加载(无可显内容时才显示中央进度环)
     */
    func loadOriginalFromNetwork(item: WYPhotoBrowserItem, url: URL, showButtonProgress: Bool) {
        let generation = configureGeneration
        if showButtonProgress {
            originalButtonState = .loading
            setOriginalButtonProgress(0)
        }
        contentImageView.kf.setImage(with: url, options: [.backgroundDecode, .keepCurrentImageWhileLoading], progressBlock: { [weak self] received, total in
            guard let self = self, generation == self.configureGeneration, total > 0 else { return }
            let percent = CGFloat(received) / CGFloat(total)
            if showButtonProgress {
                self.setOriginalButtonProgress(percent)
            } else if self.contentImageView.image == nil {
                self.showProgress(percent: percent)
            }
        }, completionHandler: { [weak self] result in
            guard let self = self, generation == self.configureGeneration else { return }
            switch result {
            case .success(let value):
                self.hideProgressAndRetry()
                self.isOriginalLoaded = true
                self.applyImage(value.image)
                if showButtonProgress {
                    self.celebrateOriginalLoaded()
                }
                self.browser?.pageCell(self, didFinishLoadingOriginalAt: self.index)
            case .failure:
                self.hideProgressAndRetry()
                if showButtonProgress {
                    self.originalButtonState = .failed
                    self.refreshOriginalButtonTitle(item: item)
                } else if self.contentImageView.image == nil {
                    self.retryButton.isHidden = false
                }
            }
        })
    }

    /// 刷新原图按钮文案(按状态显示查看原图与大小、重试或完成提示)
    func refreshOriginalButtonTitle(item: WYPhotoBrowserItem) {
        switch originalButtonState {
        case .hidden:
            originalButton.isHidden = true
        case .idle:
            let titleKey = item.originalFileSize > 0 ? "查看原图(%@)" : "查看原图"
            let sizeText = ByteCountFormatter.string(fromByteCount: item.originalFileSize, countStyle: .file)
            originalButton.wy_nTitle = String(format: WYLocalized(titleKey, table: WYBasisKitConfig.kitLocalizableTable), sizeText)
            originalButton.isHidden = false
        case .loading:
            setOriginalButtonProgress(0)
        case .failed:
            originalButton.wy_nTitle = WYLocalized("加载失败，点击重试", table: WYBasisKitConfig.kitLocalizableTable)
            originalButton.isHidden = false
        case .finished:
            originalButton.wy_nTitle = WYLocalized("已显示原图", table: WYBasisKitConfig.kitLocalizableTable)
            originalButton.isHidden = false
        }
        layoutOverlays()
    }

    /// 设置原图按钮百分比进度
    func setOriginalButtonProgress(_ percent: CGFloat) {
        let clamped = max(0, min(percent, 1))
        originalButton.wy_nTitle = "\(Int(round(clamped * 100)))%"
        originalButton.isHidden = false
        layoutOverlays()
    }

    /// 原图完成提示(短暂显示已显示原图后隐藏按钮)
    func celebrateOriginalLoaded() {
        originalButtonState = .finished
        refreshOriginalButtonTitle(item: item ?? WYPhotoBrowserItem())
        Task { @MainActor [weak self] in
            try? await Task.wy_delay(0.8, cancelThrows: false)
            guard let self = self, self.originalButtonState == .finished else { return }
            self.originalButtonState = .hidden
            self.originalButton.isHidden = true
        }
    }

    /// 显示中央进度环与百分比
    func showProgress(percent: CGFloat) {
        progressContainerView.isHidden = false
        retryButton.isHidden = true
        let clamped = max(0, min(percent, 1))
        progressRingLayer.strokeEnd = clamped
        progressLabel.text = "\(Int(round(clamped * 100)))%"
    }

    /// 收起中央进度环
    func hideProgressAndRetry() {
        progressContainerView.isHidden = true
    }

    /// 无任何内容可显时的兜底(显示重试胶囊)
    func showRetryOrNothing() {
        retryButton.isHidden = false
    }

    /// 准备LivePhoto素材(现成对象、相册素材、静图视频地址对三种来源依次生效)
    func prepareLivePhotoIfNeeded(item: WYPhotoBrowserItem) {
        guard item.mediaType == .livePhoto else { return }
        if let livePhoto = item.livePhoto {
            applyLivePhoto(livePhoto)
            return
        }
        if let asset = item.livePhotoAsset {
            let generation = configureGeneration
            livePhotoRequestGeneration = generation
            let options = PHLivePhotoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            livePhotoAssetRequestID = PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] livePhoto, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                Task { @MainActor [weak self] in
                    guard let self = self, self.livePhotoRequestGeneration == generation else { return }
                    if let livePhoto = livePhoto {
                        self.applyLivePhoto(livePhoto)
                        self.isLivePhotoReady = !isDegraded
                        self.livePhotoBadge.isHidden = isDegraded
                        if !isDegraded { self.browser?.cacheLivePhoto(livePhoto, for: self.index) }
                    } else if !isDegraded {
                        self.showRetryOrNothing()
                        if self.contentImageView.image == nil {
                            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil) { [weak self] posterImage, _ in
                                Task { @MainActor [weak self] in
                                    guard let self = self, self.livePhotoRequestGeneration == generation, self.contentImageView.image == nil else { return }
                                    if let posterImage = posterImage { self.applyImage(posterImage) }
                                }
                            }
                        }
                    }
                }
            }
            return
        }
        if let stillURL = item.livePhotoStillURL, let videoURL = item.livePhotoVideoURL {
            assembleLivePhoto(stillURL: stillURL, videoURL: videoURL, item: item)
        }
    }

    /// 生效LivePhoto(接管显示并亮角标)
    func applyLivePhoto(_ livePhoto: PHLivePhoto) {
        isLivePhotoReady = true
        displayedImageSize = livePhoto.size
        livePhotoView.livePhoto = livePhoto
        livePhotoView.isHidden = false
        livePhotoBadge.isHidden = false
        layoutMainContent()
        hideProgressAndRetry()
    }

    /// 下载并合成LivePhoto素材对(网络地址先落成本地文件再交系统合成)
    func assembleLivePhoto(stillURL: URL, videoURL: URL, item: WYPhotoBrowserItem) {
        let generation = configureGeneration
        livePhotoRequestGeneration = generation
        showProgress(percent: 0)
        livePhotoAssemblyTask?.cancel()
        livePhotoAssemblyTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                var resources: [URL] = []
                var directory: URL?
                for (position, source) in [stillURL, videoURL].enumerated() {
                    try Task.checkCancellation()
                    guard generation == self.configureGeneration else { return }
                    if source.isFileURL {
                        guard FileManager.default.fileExists(atPath: source.path) else { throw CocoaError(.fileNoSuchFile) }
                        resources.append(source)
                    } else {
                        if directory == nil {
                            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("wy_photo_browser_live_" + UUID().uuidString, isDirectory: true)
                            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                            directory = folder
                            self.browser?.livePhotoResources.directories.append(folder)
                        }
                        let (downloaded, response) = try await URLSession.shared.download(from: source)
                        try Task.checkCancellation()
                        guard generation == self.configureGeneration else { return }
                        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                            throw URLError(.badServerResponse)
                        }
                        let ext = source.pathExtension.isEmpty ? (position == 0 ? "jpg" : "mov") : source.pathExtension
                        let destination = directory!.appendingPathComponent(String(position) + "." + ext)
                        try FileManager.default.moveItem(at: downloaded, to: destination)
                        resources.append(destination)
                    }
                    self.showProgress(percent: CGFloat(position + 1) / 2)
                }
                try Task.checkCancellation()
                guard generation == self.configureGeneration else { return }
                self.livePhotoRequestID = PHLivePhoto.request(withResourceFileURLs: resources, placeholderImage: item.placeholder, targetSize: self.contentView.bounds.size, contentMode: .aspectFit) { [weak self] livePhoto, info in
                    guard let self = self, self.livePhotoRequestGeneration == generation else { return }
                    let degraded = (info[PHLivePhotoInfoIsDegradedKey] as? Bool) ?? false
                    if let livePhoto = livePhoto {
                        self.applyLivePhoto(livePhoto)
                        self.isLivePhotoReady = !degraded
                        self.livePhotoBadge.isHidden = degraded
                        if !degraded { self.browser?.cacheLivePhoto(livePhoto, for: self.index) }
                    } else if !degraded {
                        self.hideProgressAndRetry()
                        self.showRetryOrNothing()
                    }
                }
            } catch {
                guard !Task.isCancelled, generation == self.configureGeneration else { return }
                self.hideProgressAndRetry()
                self.showRetryOrNothing()
            }
        }
    }

    /// 单击关闭(等双击失败后触发，走浏览器的单击关闭判定)
    @objc func singleTapped() {
        browser?.dismissByTap()
    }

    /// 双击缩放(已放大时还原，未放大时以点击位置为中心放大到配置倍数)
    @objc func doubleTapped(_ gesture: UITapGestureRecognizer) {
        guard displayedImageSize != nil else { return }
        if zoomScrollView.zoomScale > 1.01 {
            zoomScrollView.setZoomScale(1, animated: true)
            return
        }
        let targetScale = min(max(configuration.doubleTapZoomScale, 1), configuration.maxZoomScale)
        let point = gesture.location(in: zoomContainer)
        let zoomWidth = zoomScrollView.bounds.width / targetScale
        let zoomHeight = zoomScrollView.bounds.height / targetScale
        let zoomRect = CGRect(x: point.x - zoomWidth / 2, y: point.y - zoomHeight / 2, width: zoomWidth, height: zoomHeight)
        zoomScrollView.zoom(to: zoomRect, animated: true)
    }

    /// 拖拽关闭手势(缩放为1且横向翻页方向生效，先确认垂直主导再接管手势)
    @objc func dragPanned(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)
        switch gesture.state {
        case .began:
            isDraggingToDismiss = false
        case .changed:
            if isDraggingToDismiss == false {
                guard canBeginDragDismiss(), abs(translation.y) > 12, abs(translation.y) > abs(translation.x) else { return }
                isDraggingToDismiss = true
                alpha = 1
                browser?.pageCellDidBeginDrag(self)
            }
            let scale = max(0.6, 1 - min(abs(translation.y) / contentView.bounds.height, 1) * 0.4)
            transform = CGAffineTransform(translationX: translation.x * 0.5, y: translation.y).scaledBy(x: scale, y: scale)
            let progress = min(abs(translation.y) / (contentView.bounds.height * 0.35), 1)
            browser?.pageCell(self, didUpdateDragProgress: progress)
        case .ended, .cancelled, .failed:
            guard isDraggingToDismiss else { return }
            isDraggingToDismiss = false
            let velocity = gesture.velocity(in: contentView)
            browser?.pageCell(self, didEndDragWithTranslation: gesture.state == .ended ? translation : .zero, velocity: gesture.state == .ended ? velocity : .zero)
        default:
            break
        }
    }

    /// 拖拽关闭的准入判定(开关、方向、缩放状态与浏览器状态都过关才允许)
    func canBeginDragDismiss() -> Bool {
        guard let browser = browser else { return false }
        guard configuration.allowsDragDismiss, configuration.scrollDirection == .horizontal else { return false }
        guard zoomScrollView.zoomScale <= 1.01 else { return false }
        guard browser.isDragDismissing == false, browser.isTransitioningContent == false else { return false }
        return true
    }

    /// 播放按钮点击(转发浏览器由代理抛给接入方)
    @objc func playButtonTapped() {
        browser?.pageCellDidTapPlayVideo(self)
    }

    /// 重试按钮点击(重走该页加载链路)
    @objc func retryButtonTapped() {
        guard let item = item else { return }
        retryButton.isHidden = true
        progressContainerView.isHidden = true
        loadThumbnail(item: item)
        prepareLivePhotoIfNeeded(item: item)
    }

    /// 原图按钮点击(待加载时开始下载，失败时重试，完成态忽略)
    @objc func originalButtonTapped() {
        guard let item = item, let originalURL = item.originalURL else { return }
        switch originalButtonState {
        case .idle, .failed:
            loadOriginalFromNetwork(item: item, url: originalURL, showButtonProgress: true)
        default:
            break
        }
    }

    // UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomContainer
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerZoomContainer()
        let isZoomed = scrollView.zoomScale > 1.01
        scrollView.panGestureRecognizer.isEnabled = isZoomed
        guard browser?.currentIndex == index else { return }
        if let collectionView = browser?.collectionView, collectionView.isScrollEnabled == isZoomed {
            collectionView.isScrollEnabled = !isZoomed
        }
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    // UIGestureRecognizerDelegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        guard canBeginDragDismiss() else { return false }
        let velocity = pan.velocity(in: contentView)
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer, otherGestureRecognizer == zoomScrollView.panGestureRecognizer {
            return true
        }
        return false
    }
}
