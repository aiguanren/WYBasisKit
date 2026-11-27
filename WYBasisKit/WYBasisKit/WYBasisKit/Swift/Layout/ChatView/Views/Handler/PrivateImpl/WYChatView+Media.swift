//
//  WYChatView+Media.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import AVKit

/// 接入方选择结果接入与媒体操作
extension WYChatView {
    func wy_sendMedia(_ items: [WYChatMediaItem], presentation: WYChatMediaPresentation) -> [WYChatMessageModel] {
        guard !items.isEmpty else { return [] }
        let folds = presentation == .merged && items.count > max(1, configuration.media.foldingThreshold)
        let batches = folds ? [items] : items.map { [$0] }
        let reference = state.inputQuote
        var messages: [WYChatMessageModel] = []
        for batch in batches {
            var identifiers = Set<String>()
            let entries = batch.map { source -> WYChatMediaItem in
                var item = source
                while item.id.isEmpty || !identifiers.insert(item.id).inserted { item.id = UUID().uuidString }
                return item
            }
            var message = WYChatMessageModel(messageID: UUID().uuidString, timestamp: configuration.basic.timestampUnit.wy_timestamp(), sender: userInfo, content: WYChatMessageContentModel(mediaGroup: WYChatMediaGroupModel(items: entries)))
            message.index = dataSource.count + messages.count
            message.reference = reference
            message.sendState = .sending
            message.lastMessageTimestamp = message.wy_lastMessageTimestamp((messages.last ?? dataSource.last).map { [$0] } ?? [], minimumTimeSpan: configuration.basic.messageMinimumTimeSpan, unit: configuration.basic.timestampUnit)
            messages.append(message)
        }
        if configuration.automaticallyInsertsSentMessages { dataSource.append(contentsOf: messages); scrollToLastMessage() }
        quoteMessage(nil)
        for message in messages { messagePreparedHandler?(message) }
        return messages
    }

    func wy_mediaItems(_ message: WYChatMessageModel) -> [WYChatMediaItem] {
        if let group = message.content.mediaGroup { return group.items }
        var item = WYChatMediaItem()
        if let photo = message.content.photo { item.original = photo.original; item.thumbnail = photo.thumbnail; return [item] }
        if let video = message.content.video { item.id = video.id; item.kind = .video; item.original = video.video; item.thumbnail = video.thumbnailCover.localPath.isEmpty && video.thumbnailCover.downloadPath.isEmpty ? video.cover : video.thumbnailCover; item.duration = video.duration; return [item] }
        return []
    }

    func wy_performMediaTransferAction(_ action: WYChatAction, messageID: String, itemID: String) {
        guard let message = messageModelFrom(messageID),
              let item = message.content.mediaGroup?.items.first(where: { $0.id == itemID }) else { return }
        if isSelectingMessages { wy_performAction(.select, messageID: messageID); return }
        switch (action, item.transferState) {
        case (.startTransfer, .waiting), (.pauseTransfer, .transferring), (.resumeTransfer, .paused), (.retry, .failed):
            guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: action, messageID: messageID) ?? true else { return }
            mediaTransferActionHandler?(action, messageID, itemID)
        default: break
        }
    }

    func wy_performMediaAction(_ action: WYChatMediaAction, messageID: String, index: Int) {
        guard let row = dataSource.firstIndex(where: { $0.messageID == messageID }) else { return }
        let model = dataSource[row]
        let items = wy_mediaItems(model)
        guard items.indices.contains(index), eventsHandler?.wy_shouldPerformMediaAction?(self, action: action, messageID: messageID, index: index) ?? true else { return }
        if isSelectingMessages { wy_performAction(.select, messageID: messageID); return }
        switch action {
        case .expand, .collapse:
            let expanded = action == .expand
            guard let group = model.content.mediaGroup else { return }
            if group.isExpanded != expanded {
                state.updatingMessageRows = true
                dataSource[row].content.mediaGroup?.isExpanded = expanded
                state.updatingMessageRows = false
                wy_refreshMessageRows([IndexPath(row: row, section: 0)])
            }
        case .pageChanged:
            guard model.content.mediaGroup != nil else { return }
            guard model.content.mediaGroup?.visibleIndex != index else { return }
            state.updatingMediaPage = true
            dataSource[row].content.mediaGroup?.visibleIndex = index
            state.updatingMediaPage = false
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatMediaGroupCell
            cell?.wy_updateMediaPage(dataSource[row], at: index)
        case .preview:
            inputViewResignFirstResponder()
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatBasicCell
            let mediaView = (cell as? WYChatMediaGroupCell)?.mediaView
            let source = mediaView?.sourceView(at: index) ?? cell?.previewImageView
            mediaView?.stopEmbeddedPlayback()
            let resolved = cell?.configuration ?? wy_configuration(forMessage: model)
            if let handler = mediaPreviewHandler { handler(items, index, source) }
            else if resolved.media.automaticallyPresentsBrowser {
                var responder: UIResponder? = self
                while let next = responder?.next {
                    if let controller = next as? UIViewController {
                        guard controller.presentedViewController == nil else { break }
                        state.mediaBrowser?.dispose()
                        let adapter = WYChatMediaBrowserAdapter(chatView: self, messageID: messageID, items: items, media: resolved.media)
                        state.mediaBrowser = adapter
                        var browserConfiguration = resolved.media.browser
                        browserConfiguration.isEmbedded = false
                        adapter.browser = WYPhotoBrowser.show(from: controller, index: index, dataSource: adapter, configuration: browserConfiguration, delegate: adapter)
                        adapter.configureBrowser()
                        break
                    }
                    responder = next
                }
            }
        }
        mediaActionHandler?(action, messageID, index)
        delegate?.wy_chatView?(self, mediaAction: action, messageID: messageID, index: index)
    }
}

extension WYChatMediaItem {
    var wy_videoURL: URL? {
        guard kind == .video else { return nil }
        if !original.localPath.isEmpty, FileManager.default.fileExists(atPath: original.localPath) {
            return URL(fileURLWithPath: original.localPath)
        }
        return URL(string: original.downloadPath).flatMap { ["https", "http"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil }
    }
}

/// 全屏预览和折叠叠卡共用的内联视频窗口。
final class WYChatInlineVideoPlayback {
    private var layer: AVPlayerLayer?
    private var url: URL?

    func play(_ url: URL, in container: CALayer, bounds: CGRect, muted: Bool, fillsCard: Bool) {
        if self.url == url, let layer, layer.superlayer === container {
            layer.frame = bounds
            layer.player?.isMuted = muted
            return
        }
        stop()
        let player = AVPlayer(url: url)
        player.isMuted = muted
        let layer = AVPlayerLayer(player: player)
        layer.frame = bounds
        layer.videoGravity = fillsCard ? .resizeAspectFill : .resizeAspect
        container.addSublayer(layer)
        self.layer = layer
        self.url = url
        player.play()
    }

    func stop() {
        layer?.player?.pause()
        layer?.removeFromSuperlayer()
        layer = nil
        url = nil
    }

    deinit { stop() }
}

/// 浏览器数据、转场来源与视频播放
final class WYChatMediaBrowserAdapter: NSObject, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate {
    weak var chatView: WYChatView?
    weak var browser: WYPhotoBrowser?
    weak var player: AVPlayerViewController?
    private let inlinePlayback = WYChatInlineVideoPlayback()
    let messageID: String
    let items: [WYChatMediaItem]
    private let initialMedia: WYChatMediaConfig

    init(chatView: WYChatView, messageID: String, items: [WYChatMediaItem], media: WYChatMediaConfig) {
        self.chatView = chatView
        self.messageID = messageID
        self.items = items
        self.initialMedia = media
    }

    private var mediaConfiguration: WYChatMediaConfig {
        guard let chatView else { return initialMedia }
        guard let message = chatView.messageModelFrom(messageID) else { return chatView.configuration.media }
        return chatView.wy_configuration(forMessage: message).media
    }
    func configureBrowser() {
        browser?.itemOverlayProvider = { [weak self] index in self?.transferOverlay(at: index) }
        browser?.itemDidSettle = { [weak self] index in self?.autoplay(at: index) }
        browser?.itemDidBeginDrag = { [weak self] in self?.inlinePlayback.stop() }
        browser?.refreshItemOverlays()
        if let chatView, let message = chatView.messageModelFrom(messageID), message.sendState == .sending {
            let configuration = chatView.wy_configuration(forMessage: message)
            let style = configuration.contentOverrides[.mediaGroup] ?? configuration.content
            let elapsed = Date().timeIntervalSince(message.sendStartedAt ?? .distantPast)
            let remaining = wy_chatNonnegative(style.transferProgressDelay) - elapsed
            if remaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in self?.browser?.refreshItemOverlays() }
            }
        }
    }

    func refreshProgress(for identifier: String) {
        guard identifier == messageID else { return }
        browser?.refreshItemOverlays()
        if let browser, !browser.collectionView.isDragging, !browser.collectionView.isDecelerating {
            autoplay(at: browser.currentIndex)
        }
    }

    private func transferOverlay(at index: Int) -> UIView? {
        guard let chatView, let message = chatView.messageModelFrom(messageID),
              let group = message.content.mediaGroup, group.items.indices.contains(index) else { return nil }
        let configuration = chatView.wy_configuration(forMessage: message)
        let style = configuration.contentOverrides[.mediaGroup] ?? configuration.content
        let sender = message.isSender(chatView.userInfo.id)
        let item = group.items[index]
        let delay = wy_chatNonnegative(style.transferProgressDelay)
        let lifetime = Date().timeIntervalSince(message.sendStartedAt ?? .distantPast)
        guard style.transferShowsProgress, item.transferState != .automatic, item.transferState != .completed,
              !sender || message.sendState != .sending || lifetime >= delay else { return nil }
        let overlay = WYChatAttachmentProgressView()
        if let action = overlay.showPhase(item.transferState, progress: item.transferProgress, error: item.transferError,
                                          style: style, overlaysMedia: true, sender: sender, title: configuration.actionTitle,
                                          mediaConfig: configuration.media) {
            overlay.button.addAction(UIAction { [weak chatView] _ in
                chatView?.wy_performMediaTransferAction(action, messageID: message.messageID, itemID: item.id)
            }, for: .touchUpInside)
        }
        return overlay
    }

    private func autoplay(at index: Int) {
        let media = mediaConfiguration
        guard let chatView, media.automaticallyPlaysVideo, let browser,
              browser.presentedViewController == nil, items.indices.contains(index), let url = items[index].wy_videoURL,
              let image = browser.sourceView(at: index) else { inlinePlayback.stop(); return }
        if let group = chatView.messageModelFrom(messageID)?.content.mediaGroup, group.items.indices.contains(index) {
            let phase = group.items[index].transferState
            guard phase == .automatic || phase == .completed else { inlinePlayback.stop(); return }
        }
        inlinePlayback.play(url, in: image.layer, bounds: image.bounds, muted: media.automaticVideoStartsMuted, fillsCard: false)
    }

    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int { items.count }
    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any {
        guard items.indices.contains(index) else { return WYPhotoBrowserItem() }
        let item = items[index]
        var value = WYPhotoBrowserItem()
        value.identifier = item.id
        value.mediaType = item.kind == .video ? .video : .photo
        value.thumbnailPath = item.thumbnail.localPath.isEmpty ? nil : item.thumbnail.localPath
        value.thumbnailURL = URL(string: item.thumbnail.downloadPath)
        if item.kind == .photo {
            value.originalPath = item.original.localPath.isEmpty ? nil : item.original.localPath
            value.originalURL = URL(string: item.original.downloadPath)
        }
        if let image = self.wy_sourceView(index) as? UIImageView { value.placeholder = image.image }
        return value
    }
    private func wy_sourceView(_ index: Int) -> UIView? {
        guard let chatView, let row = chatView.dataSource.firstIndex(where: { $0.messageID == messageID }), let cell = chatView.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatBasicCell else { return nil }
        return (cell as? WYChatMediaGroupCell)?.mediaView.sourceView(at: index) ?? cell.previewImageView
    }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, sourceViewForItemAt index: Int) -> UIView? { wy_sourceView(index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) { chatView?.wy_performMediaAction(.pageChanged, messageID: messageID, index: index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int) {
        guard photoBrowser.presentedViewController == nil, items.indices.contains(index), let url = items[index].wy_videoURL else { return }
        inlinePlayback.stop()
        let media = mediaConfiguration
        let controller = AVPlayerViewController()
        controller.modalPresentationStyle = media.videoPresentationStyle
        controller.showsPlaybackControls = media.showsVideoPlaybackControls
        controller.view.accessibilityIdentifier = "WYChatMedia.videoPlayer"
        controller.player = AVPlayer(url: url)
        player = controller
        photoBrowser.present(controller, animated: true) { [weak controller] in controller?.player?.play() }
    }
    func wy_photoBrowserDidDismiss(_ photoBrowser: WYPhotoBrowser) {
        inlinePlayback.stop()
        player?.player?.pause()
        guard let chatView, chatView.state.mediaBrowser === self else { return }
        chatView.state.mediaBrowser = nil
        if let row = chatView.dataSource.firstIndex(where: { $0.messageID == messageID }),
           let cell = chatView.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatMediaGroupCell {
            cell.mediaView.resumeEmbeddedPlayback()
        }
    }
    func dispose() { inlinePlayback.stop(); player?.player?.pause(); browser?.dismiss(animated: false) }
}
