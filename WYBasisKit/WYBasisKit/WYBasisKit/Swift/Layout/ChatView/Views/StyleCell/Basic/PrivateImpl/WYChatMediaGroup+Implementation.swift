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
    private var avatarConfiguration = WYBasicChatConfig()
    private var avatarGestures: [Int: WYChatAvatarGestures] = [:]
    private var model = WYChatMediaGroupModel()
    private var configuration = WYChatMediaConfig()
    private var browser: WYPhotoBrowser?
    private var images: [Int: UIImageView] = [:]
    private var avatars: [Int: UIImageView] = [:]
    private var frames: [CGRect] = []
    private var loaded = Set<Int>()
    private var loader: ((WYChatAssetsModel, UIImageView, Bool) -> Void)?
    private var avatar = WYChatAssetsModel()
    private var avatarSize = CGSize.zero
    private var avatarSpacing: CGFloat = 0
    private var avatarCornerRadius: CGFloat = 0
    private var avatarContentMode = UIView.ContentMode.scaleAspectFill
    private var sender = false
    private var measuring = false
    private var lastSize = CGSize.zero

    func configure(_ model: WYChatMediaGroupModel, configuration: WYChatMediaConfig, avatarConfiguration: WYBasicChatConfig, avatar: WYChatAssetsModel, avatarSize: CGSize, avatarSpacing: CGFloat, avatarCornerRadius: CGFloat, avatarContentMode: UIView.ContentMode, sender: Bool, measuring: Bool, loader: @escaping (WYChatAssetsModel, UIImageView, Bool) -> Void) {
        reset()
        self.model = model
        self.configuration = configuration
        self.avatarConfiguration = avatarConfiguration
        self.avatar = avatar
        self.avatarSize = avatarSize
        self.avatarSpacing = avatarSpacing
        self.avatarCornerRadius = avatarCornerRadius
        self.avatarContentMode = avatarContentMode
        self.sender = sender
        self.measuring = measuring
        self.loader = loader
        guard !measuring else { return }
        if model.isExpanded {
            for index in model.items.indices {
                let image = UIImageView()
                image.contentMode = .scaleAspectFill
                image.clipsToBounds = true
                image.layer.cornerRadius = finite(configuration.cornerRadius)
                image.tag = index
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
                image.accessibilityIdentifier = "WYChatMedia.item.\(index)"
                addSubview(image)
                images[index] = image
                if model.items[index].kind == .video {
                    let play = UIImageView(image: configuration.videoPlayImage)
                    play.tintColor = configuration.videoPlayColor
                    play.contentMode = .scaleAspectFit
                    play.frame.size = configuration.videoPlaySize
                    image.addSubview(play)
                }
            }
        } else {
            var config = configuration.browser
            config.layoutStyle = .stackedCards
            config.isEmbedded = true
            config.allowsTapDismiss = false
            config.allowsDragDismiss = false
            config.pageIndicatorStyle = .none
            config.appearance.backgroundColor = .clear
            config.showsSaveAction = false
            let controller = WYPhotoBrowser(configuration: config)
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
    override func didMoveToWindow() { super.didMoveToWindow(); if window == nil { detachBrowser() } else { attachBrowser() } }
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
        let visible = window.map { convert($0.bounds, from: $0).insetBy(dx: 0, dy: -max(1, finite(configuration.cardSize.height))) } ?? bounds
        var lower = 0
        var upper = frames.count
        while lower < upper { let middle = (lower + upper) / 2; if frames[middle].maxY < visible.minY { lower = middle + 1 } else { upper = middle } }
        var wanted = Set<Int>()
        while lower < frames.count && frames[lower].minY <= visible.maxY { wanted.insert(lower); lower += 1 }
        for index in loaded.subtracting(wanted) { images[index]?.kf.cancelDownloadTask(); images[index]?.image = nil; avatars[index]?.isHidden = true }
        for index in wanted.subtracting(loaded) {
            guard let image = images[index] else { continue }
            let item = model.items[index]
            loader?(item.thumbnail.localPath.isEmpty && item.thumbnail.downloadPath.isEmpty ? item.original : item.thumbnail, image, false)
            if index > 0 && configuration.showsExpandedAvatars && avatarSize.width > 0 && avatars[index] == nil {
                let view = UIImageView()
                view.clipsToBounds = true
                view.layer.cornerRadius = finite(avatarCornerRadius)
                view.contentMode = avatarContentMode
                addSubview(view)
                avatars[index] = view
                let gestures = WYChatAvatarGestures(view: view) { [weak self] action in self?.avatarAction?(action) }
                gestures.apply(avatarConfiguration)
                avatarGestures[index] = gestures
                loader?(avatar, view, true)
            }
        }
        for index in wanted {
            if let avatar = avatars[index] { avatar.isHidden = false; avatar.frame = CGRect(x: sender ? bounds.width + avatarSpacing : -avatarSpacing - avatarSize.width, y: frames[index].minY, width: avatarSize.width, height: avatarSize.height) }
        }
        loaded = wanted
    }
    func updatePage(_ index: Int) {
        guard model.items.indices.contains(index) else { return }
        model.visibleIndex = index
        if browser?.currentIndex != index { browser?.currentIndex = index }
    }
    func sourceView(at index: Int) -> UIView? { model.isExpanded ? images[index] : browser?.sourceView(at: index) }
    func reset() {
        detachBrowser()
        browser?.view.removeFromSuperview()
        browser?.dataSource = nil
        browser?.browserDelegate = nil
        browser = nil
        for image in images.values { image.kf.cancelDownloadTask(); image.removeFromSuperview() }
        for avatar in avatars.values { avatar.kf.cancelDownloadTask(); avatar.removeFromSuperview() }
        avatarGestures.removeAll()
        images.removeAll(); avatars.removeAll(); frames.removeAll(); loaded.removeAll(); lastSize = .zero
    }
    private func remoteURL(_ path: String) -> URL? {
        guard let url = URL(string: path), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int { model.items.count }
    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any {
        guard model.items.indices.contains(index) else { return WYPhotoBrowserItem() }
        let item = model.items[index]
        var result = WYPhotoBrowserItem()
        result.identifier = item.id
        result.mediaType = item.kind == .video ? .video : .photo
        let thumb = item.thumbnail.localPath.isEmpty && item.thumbnail.downloadPath.isEmpty ? item.original : item.thumbnail
        result.thumbnailPath = thumb.localPath.isEmpty ? nil : thumb.localPath
        result.thumbnailURL = remoteURL(thumb.downloadPath)
        if item.kind == .photo { result.originalPath = item.original.localPath.isEmpty ? nil : item.original.localPath; result.originalURL = remoteURL(item.original.downloadPath) }
        let image = UIImageView()
        loader?(thumb, image, false)
        result.placeholder = image.image
        return result
    }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) { if index != model.visibleIndex { action?(.pageChanged, index) } }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapItemAt index: Int) { action?(.preview, index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int) { action?(.preview, index) }
    @objc private func tapped(_ tap: UITapGestureRecognizer) { if let index = tap.view?.tag { action?(.preview, index) } }
}

/// 媒体组的聊天按钮与消息事件
extension WYChatBasicCell {
    func wy_renderMediaGroup() {
        guard let group = message.content.mediaGroup else { return }
        state.title.isHidden = true
        state.mediaView.isHidden = false
        let sender = message.isSender(userID)
        let side = sender ? configuration.sender : configuration.receiver
        state.mediaView.configure(group, configuration: configuration.media, avatarConfiguration: configuration.basic, avatar: message.sender.avatar, avatarSize: side.showsAvatar ? configuration.basic.avatarSize : .zero, avatarSpacing: side.contentSpacing, avatarCornerRadius: configuration.basic.avatarCornerRadius, avatarContentMode: configuration.basic.avatarContentMode, sender: sender, measuring: state.isMeasuring) { [weak self] asset, image, avatar in self?.wy_loadImage(asset, into: image, isAvatar: avatar) }
        state.mediaView.avatarAction = { [weak self] action in self?.wy_avatarAction(action) }
        let identifier = message.messageID
        state.mediaView.action = { [weak self] action, index in self?.mediaActionHandler?(action, identifier, index) }
        state.preferredWidth?.constant = max(1, configuration.media.cardSize.width)
        state.mediaToggle.isHidden = group.items.count < 2
        let title = group.isExpanded ? configuration.media.collapseText : configuration.media.expandText
        state.mediaToggle.setTitle(configuration.media.showsItemCountInButton ? "\(title) (\(group.items.count))" : title, for: .normal)
        state.mediaToggle.titleLabel?.font = configuration.media.buttonFont
        state.mediaToggle.setTitleColor(configuration.media.buttonColor, for: .normal)
        state.mediaToggle.backgroundColor = configuration.media.buttonBackgroundColor
        state.mediaToggle.layer.cornerRadius = max(0, configuration.media.buttonCornerRadius)
        let below = configuration.media.buttonPlacement == .below
        state.mediaToggleHeight?.isActive = below
        state.mediaToggle.translatesAutoresizingMaskIntoConstraints = !below
        if below {
            if state.mediaToggle.superview !== bodyView { bodyView.insertArrangedSubview(state.mediaToggle, at: min(1, bodyView.arrangedSubviews.count)) }
        } else if state.mediaToggle.superview !== contentView {
            bodyView.removeArrangedSubview(state.mediaToggle)
            state.mediaToggle.removeFromSuperview()
            contentView.addSubview(state.mediaToggle)
        }
        state.mediaToggleHeight?.constant = max(1, configuration.media.buttonHeight)
        bodyView.spacing = max(0, configuration.media.buttonSpacing)
    }
    func wy_layoutMediaToggle() {
        guard !state.mediaToggle.isHidden, configuration.media.buttonPlacement == .beside else { return }
        let config = configuration.media
        func finite(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
        let width = min(contentView.bounds.width, finite(config.buttonWidth))
        let height = finite(config.buttonHeight)
        let frame = state.mediaView.convert(state.mediaView.bounds, to: contentView)
        let center = state.mediaView.convert(CGPoint(x: 0, y: state.mediaView.firstItemCenterY), to: contentView).y
        let sender = message.isSender(userID)
        let pending = sender && (!loadingView.isHidden || !activityView.isHidden) ? finite(configuration.basic.messageSendingStateOffset) + finite(configuration.basic.messageSendingStateSize.width) : 0
        let desired = sender ? frame.minX - finite(config.buttonSpacing) - width - pending : frame.maxX + finite(config.buttonSpacing)
        let inset = finite(sender ? configuration.sender.edgeInset : configuration.receiver.edgeInset)
        let x = min(max(0, contentView.bounds.width - width - inset - wy_selectionIndicatorWidth), max(inset, desired))
        state.mediaToggle.frame = CGRect(x: x, y: max(0, center - height / 2), width: width, height: height)
    }

    @objc func wy_toggleMediaGroup() {
        guard let group = message.content.mediaGroup else { return }
        let index = min(max(0, group.visibleIndex), max(0, group.items.count - 1))
        mediaActionHandler?(group.isExpanded ? .collapse : .expand, message.messageID, index)
    }
}
