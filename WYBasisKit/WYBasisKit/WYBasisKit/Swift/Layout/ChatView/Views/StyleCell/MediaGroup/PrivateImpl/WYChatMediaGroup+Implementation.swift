//
//  WYChatMediaGroup+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import Kingfisher

/// 聊天媒体的折叠浏览与展开列表
final class WYChatMediaGroupView: UIView, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate {
    var action: ((WYChatMediaAction, Int) -> Void)?
    var avatarAction: ((WYChatAvatarAction) -> Void)?
    var transferAction: ((WYChatAction, String) -> Void)?
    var transferTitle: ((WYChatAction) -> String?)?
    private var transferProgressVisible = false
    private var expandedProgress: [Int: UIView] = [:]
    private var expandedVideoChrome: [Int: WYChatVideoOverlayView] = [:]
    private var avatarConfiguration = WYBasicChatConfig()
    private var avatarGestures: [Int: WYChatAvatarGestures] = [:]
    private var model = WYChatMediaGroupModel()
    private var configuration = WYChatMediaConfig()
    private var contentConfiguration = WYChatContentConfig()
    private var browser: WYPhotoBrowser?
    private let inlinePlayback = WYChatInlineVideoPlayback()
    private var embeddedPage: Int?
    private var swipeAutoplayItemID: String?
    private var images: [Int: UIImageView] = [:]
    private var avatars: [Int: UIImageView] = [:]
    private var frames: [CGRect] = []
    private var loaded = Set<Int>()
    private var loader: ((_ asset: WYChatAssetsModel, _ imageView: UIImageView, _ isPhoto: Bool, _ loadsRemoteImage: Bool) -> Void)?
    private var avatar = WYChatAssetsModel()
    private var avatarSize = CGSize.zero
    private var avatarSpacing: CGFloat = 0
    private var sender = false
    private var measuring = false
    private var lastSize = CGSize.zero

    func configure(_ model: WYChatMediaGroupModel, configuration: WYChatMediaConfig, contentConfiguration: WYChatContentConfig, avatarConfiguration: WYBasicChatConfig, avatar: WYChatAssetsModel, avatarSize: CGSize, avatarSpacing: CGFloat, sender: Bool, measuring: Bool, loader: @escaping (WYChatAssetsModel, UIImageView, Bool, Bool) -> Void) {
        reset()
        self.model = model
        self.configuration = configuration
        self.contentConfiguration = contentConfiguration
        self.avatarConfiguration = avatarConfiguration
        self.avatar = avatar
        self.avatarSize = avatarSize
        self.avatarSpacing = avatarSpacing
        self.sender = sender
        self.measuring = measuring
        self.loader = loader
        guard !measuring else { return }
        if model.isExpanded {
            for index in model.items.indices {
                let image = WYChatPlaceholderImageView()
                image.clipsToBounds = true
                image.imageContentMode = contentConfiguration.previewContentMode
                image.imageCornerRadius = finite(configuration.cornerRadius)
                image.tag = index
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
                image.accessibilityIdentifier = "WYChatMedia.item.\(index)"
                addSubview(image)
                images[index] = image
                if model.items[index].kind == .video {
                    let tint = contentConfiguration.iconTintColor ?? (configuration.tintsVideoPlayImage && contentConfiguration.usesDefaultIconTint ? configuration.videoPlayColor : nil)
                    let icon = contentConfiguration.iconImage ?? configuration.videoPlayImage
                    let chrome = WYChatVideoOverlayView()
                    chrome.frame = image.bounds
                    chrome.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    let seconds = Int(min(86_400, finite(model.items[index].duration)))
                    let duration = configuration.durationFormatter?(Double(seconds)) ?? String(format: "%d:%02d", seconds / 60, seconds % 60)
                    chrome.apply(configuration, icon: icon, tint: tint, font: contentConfiguration.detailFont, duration: duration)
                    image.addSubview(chrome)
                    expandedVideoChrome[index] = chrome
                }
            }
        } else {
            var config = configuration.browser
            config.layoutStyle = configuration.embeddedLayoutStyle
            if model.items.count == 1 { config.stackedCardInsets = .zero }
            config.isEmbedded = true
            config.allowsTapDismiss = false
            config.allowsDragDismiss = false
            config.pageIndicatorStyle = configuration.embeddedPageIndicatorStyle
            config.appearance.backgroundColor = configuration.embeddedBackgroundColor
            config.showsSaveAction = configuration.embeddedShowsSaveAction
            let controller = WYPhotoBrowser(configuration: config)
            controller.itemDidSettleAfterSwipe = { [weak self] index in
                guard let self, self.model.items.indices.contains(index) else { return }
                self.swipeAutoplayItemID = self.model.items[index].id
            }
            controller.itemDidSettle = { [weak self] index in
                guard let self else { return }
                if !self.model.items.indices.contains(index) || self.model.items[index].id != self.swipeAutoplayItemID {
                    self.swipeAutoplayItemID = nil
                }
                self.resumeEmbeddedPlayback()
            }
            controller.itemDidBeginDrag = { [weak self] in self?.stopEmbeddedPlayback() }
            controller.itemOverlayProvider = { [weak self] index in self?.makeTransferOverlay(index) }
            controller.dataSource = self
            controller.browserDelegate = self
            browser = controller
            addSubview(controller.view)
            controller.currentIndex = min(max(0, model.visibleIndex), max(0, model.items.count - 1))
            attachBrowser()
        }
        setNeedsLayout()
    }
    private func finite(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
    private func itemHeight(_ index: Int, width: CGFloat) -> CGFloat {
        let size = model.items[index].size
        if configuration.usesOriginalAspectRatio && size.width.isFinite && size.width > 0 && size.height.isFinite && size.height > 0 { return max(1, min(finite(configuration.maximumExpandedItemHeight), width * size.height / size.width)) }
        return max(1, finite(configuration.cardSize.height))
    }
    var firstItemCenterY: CGFloat { model.isExpanded && !model.items.isEmpty ? itemHeight(0, width: max(1, bounds.width)) / 2 : bounds.midY }
    func height(for width: CGFloat) -> CGFloat {
        guard !model.items.isEmpty else { return 0 }
        if !model.isExpanded { return max(1, finite(configuration.cardSize.height)) }
        return model.items.indices.reduce(CGFloat.zero) { $0 + itemHeight($1, width: max(1, width)) } + CGFloat(max(0, model.items.count - 1)) * finite(configuration.expandedSpacing)
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { stopEmbeddedPlayback(); detachBrowser() }
        else { attachBrowser(); setNeedsLayout() }
    }
    private func attachBrowser() {
        guard let browser, browser.parent == nil, window != nil else { return }
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let parent = next as? UIViewController { parent.addChild(browser); browser.didMove(toParent: parent); return }
            responder = next
        }
    }
    private func detachBrowser() { browser?.willMove(toParent: nil); browser?.removeFromParent() }
    override func layoutSubviews() {
        super.layoutSubviews()
        browser?.view.frame = bounds
        browser?.view.layoutIfNeeded()
        resumeEmbeddedPlayback()
        guard model.isExpanded, !measuring else { return }
        if lastSize != bounds.size {
            lastSize = bounds.size
            frames.removeAll(keepingCapacity: true)
            var y: CGFloat = 0
            for index in model.items.indices {
                let frame = CGRect(x: 0, y: y, width: bounds.width, height: itemHeight(index, width: bounds.width))
                frames.append(frame)
                images[index]?.frame = frame
                if let image = images[index] { for view in image.subviews { view.center = CGPoint(x: image.bounds.midX, y: image.bounds.midY) } }
                y = frame.maxY + finite(configuration.expandedSpacing)
            }
        }
        updateVisibleImages()
    }
    func updateVisibleImages() {
        guard model.isExpanded, !frames.isEmpty, window != nil else { return }
        let prefetchDistance = configuration.expandedPrefetchDistance.map(finite) ?? max(1, finite(configuration.cardSize.height))
        let visible = window.map { convert($0.bounds, from: $0).insetBy(dx: 0, dy: -prefetchDistance) } ?? bounds
        var lower = 0
        var upper = frames.count
        while lower < upper { let middle = (lower + upper) / 2; if frames[middle].maxY < visible.minY { lower = middle + 1 } else { upper = middle } }
        var wanted = Set<Int>()
        while lower < frames.count && frames[lower].minY <= visible.maxY { wanted.insert(lower); lower += 1 }
        for index in loaded.subtracting(wanted) {
            images[index]?.kf.cancelDownloadTask()
            images[index]?.kf.indicatorType = .none
            images[index]?.kf.setImage(with: nil as Source?)
            avatars[index]?.isHidden = true
        }
        for index in wanted.subtracting(loaded) {
            guard let image = images[index] else { continue }
            let item = model.items[index]
            loader?(thumbnail(for: item), image, item.kind == .photo, true)
            if index > 0 && configuration.showsExpandedAvatars && avatarSize.width > 0 && avatars[index] == nil {
                let view = WYChatAvatarImageView()
                view.clipsToBounds = true
                addSubview(view)
                avatars[index] = view
                let gestures = WYChatAvatarGestures(view: view) { [weak self] action in self?.avatarAction?(action) }
                gestures.apply(avatarConfiguration, isOwnAvatar: sender)
                avatarGestures[index] = gestures
                loader?(avatar, view, false, true)
            }
        }
        for index in wanted {
            if let avatar = avatars[index] { avatar.isHidden = false; avatar.frame = CGRect(x: sender ? bounds.width + avatarSpacing : -avatarSpacing - avatarSize.width, y: frames[index].minY, width: avatarSize.width, height: avatarSize.height) }
        }
        loaded = wanted
    }
    func setTransferProgressVisible(_ visible: Bool) {
        guard transferProgressVisible != visible else { return }
        transferProgressVisible = visible
        refreshTransferOverlays()
    }

    func updateTransferItems(_ items: [WYChatMediaItem]) {
        model.items = items
        refreshTransferOverlays()
        resumeEmbeddedPlayback()
    }

    private func refreshTransferOverlays() {
        browser?.refreshItemOverlays()
        for index in images.keys { updateExpandedTransferOverlay(index) }
    }

    private func updateExpandedTransferOverlay(_ index: Int) {
        expandedProgress.removeValue(forKey: index)?.removeFromSuperview()
        let progress = makeTransferOverlay(index)
        expandedVideoChrome[index]?.setPlaySuppressed(progress != nil)
        guard let image = images[index], let overlay = progress else { return }
        overlay.frame = image.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        image.addSubview(overlay)
        expandedProgress[index] = overlay
    }

    private func makeTransferOverlay(_ index: Int) -> UIView? {
        guard transferProgressVisible, contentConfiguration.transferShowsProgress, model.items.indices.contains(index) else { return nil }
        let item = model.items[index]
        guard item.transferState != .automatic, item.transferState != .completed else { return nil }
        let overlay = WYChatAttachmentProgressView()
        overlay.accessibilityIdentifier = "WYChatTransfer.mediaItem.\(index)"
        let action = overlay.showPhase(item.transferState, progress: item.transferProgress, error: item.transferError, style: contentConfiguration,
                                       overlaysMedia: true, sender: sender, title: transferTitle, mediaConfig: configuration)
        if let action {
            overlay.button.addAction(UIAction { [weak self] _ in self?.transferAction?(action, item.id) }, for: .touchUpInside)
        }
        return overlay
    }

    func updatePage(_ index: Int) {
        guard model.items.indices.contains(index) else { return }
        model.visibleIndex = index
        if browser?.currentIndex != index { browser?.currentIndex = index }
    }
    func sourceView(at index: Int) -> UIView? { model.isExpanded ? images[index] : browser?.sourceView(at: index) }
    func resumeEmbeddedPlayback() {
        guard window != nil, let browser,
              (browser.parent?.presentedViewController == nil || browser.parent?.presentedViewController?.isBeingDismissed == true),
              browser.swipeStartIndex == nil, !browser.collectionView.isDragging, !browser.collectionView.isDecelerating else { return }
        let index = browser.currentIndex
        guard model.items.indices.contains(index) else { stopEmbeddedPlayback(); return }
        let item = model.items[index]
        let autoplay: Bool
        switch configuration.foldedVideoAutoplayMode {
        case .firstItem: autoplay = index == 0
        case .onSwipe: autoplay = item.id == swipeAutoplayItemID
        case .allVideos: autoplay = true
        }
        guard autoplay, let url = item.wy_videoURL,
              item.transferState == .automatic || item.transferState == .completed,
              let image = browser.sourceView(at: index) else { stopEmbeddedPlayback(); return }
        if let previous = embeddedPage, previous != index { browser.setInlineVideoPlaying(false, at: previous) }
        embeddedPage = index
        inlinePlayback.play(url, in: image.layer, bounds: image.bounds, muted: configuration.automaticVideoStartsMuted, fillsCard: true)
        browser.setInlineVideoPlaying(true, at: index)
    }

    func stopEmbeddedPlayback() {
        if let embeddedPage { browser?.setInlineVideoPlaying(false, at: embeddedPage) }
        embeddedPage = nil
        inlinePlayback.stop()
    }

    func reset() {
        stopEmbeddedPlayback()
        swipeAutoplayItemID = nil
        detachBrowser()
        browser?.view.removeFromSuperview()
        browser?.dataSource = nil
        browser?.browserDelegate = nil
        browser = nil
        for image in images.values { image.kf.cancelDownloadTask(); image.removeFromSuperview() }
        for avatar in avatars.values { avatar.kf.cancelDownloadTask(); avatar.removeFromSuperview() }
        avatarGestures.removeAll()
        expandedProgress.removeAll()
        expandedVideoChrome.removeAll()
        transferProgressVisible = false
        images.removeAll(); avatars.removeAll(); frames.removeAll(); loaded.removeAll(); lastSize = .zero
    }
    private func remoteURL(_ path: String) -> URL? {
        guard let url = URL(string: path), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
    private func thumbnail(for item: WYChatMediaItem) -> WYChatAssetsModel {
        var thumbnail = item.thumbnail
        guard item.kind == .photo else { return thumbnail }
        if thumbnail.localPath.isEmpty && thumbnail.downloadPath.isEmpty && thumbnail.name.isEmpty { return item.original }
        if !thumbnail.localPath.isEmpty && thumbnail.downloadPath.isEmpty && thumbnail.name.isEmpty {
            thumbnail.downloadPath = item.original.downloadPath
        }
        return thumbnail
    }
    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int { model.items.count }
    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any {
        guard model.items.indices.contains(index) else { return WYPhotoBrowserItem() }
        let item = model.items[index]
        var result = WYPhotoBrowserItem()
        result.identifier = item.id
        result.mediaType = item.kind == .video ? .video : .photo
        let thumb = thumbnail(for: item)
        result.thumbnailPath = thumb.localPath.isEmpty ? nil : thumb.localPath
        result.thumbnailURL = remoteURL(thumb.downloadPath)
        if item.kind == .photo { result.originalPath = item.original.localPath.isEmpty ? nil : item.original.localPath; result.originalURL = remoteURL(item.original.downloadPath) }
        let image = WYChatPlaceholderImageView()
        loader?(thumb, image, false, false)
        result.placeholder = image.image
        if let generated = image.generatedPlaceholder, generated === image.image {
            result.placeholderCornerRadius = finite(contentConfiguration.placeholderCornerRadius)
            result.showsPlaceholderLoadingIndicator = item.kind == .photo && contentConfiguration.showsPlaceholderLoadingIndicator
        }
        return result
    }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) { if index != model.visibleIndex { action?(.pageChanged, index) } }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapItemAt index: Int) { action?(.preview, index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int) { action?(.preview, index) }
    @objc private func tapped(_ tap: UITapGestureRecognizer) { if let index = tap.view?.tag { action?(.preview, index) } }
}
