//
//  WYChatView+Media.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import AVKit

/// 宿主选择结果接入与媒体操作
extension WYChatView {
    func wy_sendMedia(_ items: [WYChatMediaItem]) -> [WYChatMessageModel] {
        guard !items.isEmpty else { return [] }
        let batches = configuration.media.presentation == .merged ? [items] : items.map { [$0] }
        let reference = state.inputQuote
        var messages: [WYChatMessageModel] = []
        for batch in batches {
            var message = WYChatMessageModel(messageID: UUID().uuidString, timestamp: String(Date().timeIntervalSince1970), sender: userInfo, content: WYChatMessageContentModel(mediaGroup: WYChatMediaGroupModel(items: batch)))
            message.index = dataSource.count + messages.count
            message.reference = reference
            message.sendState = .sending
            message.lastMessageTimestamp = message.sharedLastMessageTimestamp((messages.last ?? dataSource.last).map { [$0] } ?? [], minimumTimeSpan: configuration.basic.messageMinimumTimeSpan)
            messages.append(message)
        }
        if configuration.automaticallyInsertsSentMessages { dataSource.append(contentsOf: messages); scrollToLastMessage() }
        quoteMessage(nil)
        for message in messages { messagePreparedHandler?(message) }
        return messages
    }

    private func wy_updateMediaGroup(row: Int, change: (inout WYChatMediaGroupModel) -> Void) {
        guard dataSource.indices.contains(row), var group = dataSource[row].content.mediaGroup else { return }
        tableView.layoutIfNeeded()
        let anchor = tableView.indexPathsForVisibleRows?.min()
        let reading = anchor.map { wy_readingAnchor(at: $0) }
        let preserving = state.preservingHistory
        state.preservingHistory = true
        change(&group)
        dataSource[row].content.mediaGroup = group
        state.preservingHistory = preserving
        if let reading { state.readingAnchor = reading; tableView.layoutIfNeeded(); wy_restoreReadingPosition() }
    }

    func wy_mediaItems(_ message: WYChatMessageModel) -> [WYChatMediaItem] {
        if let group = message.content.mediaGroup { return group.items }
        var item = WYChatMediaItem()
        if let photo = message.content.photo { item.original = photo.original; item.thumbnail = photo.thumbnail; return [item] }
        if let video = message.content.video { item.id = video.id; item.kind = .video; item.original = video.video; item.thumbnail = video.thumbnailCover.localPath.isEmpty && video.thumbnailCover.downloadPath.isEmpty ? video.cover : video.thumbnailCover; item.duration = video.duration; return [item] }
        return []
    }

    func wy_performMediaAction(_ action: WYChatMediaAction, messageID: String, index: Int) {
        guard let row = dataSource.firstIndex(where: { $0.messageID == messageID }) else { return }
        let model = dataSource[row]
        let items = wy_mediaItems(model)
        guard items.indices.contains(index), eventsHandler?.wy_shouldPerformMediaAction?(self, action: action, messageID: messageID, index: index) ?? true else { return }
        if isSelectingMessages { wy_performAction(.select, messageID: messageID); return }
        switch action {
        case .expand, .collapse:
            guard model.content.mediaGroup != nil else { return }
            wy_updateMediaGroup(row: row) { $0.isExpanded = action == .expand }
        case .pageChanged:
            guard model.content.mediaGroup != nil else { return }
            guard model.content.mediaGroup?.visibleIndex != index else { return }
            state.updatingMediaPage = true
            dataSource[row].content.mediaGroup?.visibleIndex = index
            state.updatingMediaPage = false
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatBasicCell {
                cell.state.updatingMediaPage = true
                cell.message = dataSource[row]
                cell.state.updatingMediaPage = false
                cell.state.mediaView.updatePage(index)
            }
        case .preview:
            inputViewResignFirstResponder()
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? WYChatBasicCell
            let source = cell?.state.mediaView.sourceView(at: index) ?? cell?.previewImageView
            if let handler = mediaPreviewHandler { handler(items, index, source) }
            else if configuration.media.automaticallyPresentsBrowser {
                var responder: UIResponder? = self
                while let next = responder?.next {
                    if let controller = next as? UIViewController {
                        guard controller.presentedViewController == nil else { break }
                        state.mediaBrowser?.dispose()
                        let adapter = WYChatMediaBrowserAdapter(chatView: self, messageID: messageID, items: items)
                        state.mediaBrowser = adapter
                        var browserConfiguration = configuration.media.browser
                        browserConfiguration.isEmbedded = false
                        adapter.browser = WYPhotoBrowser.show(from: controller, index: index, dataSource: adapter, configuration: browserConfiguration, delegate: adapter)
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

/// 浏览器数据、转场来源与视频播放
final class WYChatMediaBrowserAdapter: NSObject, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate {
    weak var chatView: WYChatView?
    weak var browser: WYPhotoBrowser?
    weak var player: AVPlayerViewController?
    let messageID: String
    let items: [WYChatMediaItem]

    init(chatView: WYChatView, messageID: String, items: [WYChatMediaItem]) {
        self.chatView = chatView
        self.messageID = messageID
        self.items = items
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
        return cell.state.mediaView.sourceView(at: index) ?? cell.previewImageView
    }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, sourceViewForItemAt index: Int) -> UIView? { wy_sourceView(index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) { chatView?.wy_performMediaAction(.pageChanged, messageID: messageID, index: index) }
    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int) {
        guard items.indices.contains(index), items[index].kind == .video, photoBrowser.presentedViewController == nil else { return }
        let asset = items[index].original
        let url: URL?
        if !asset.localPath.isEmpty { url = URL(fileURLWithPath: asset.localPath) }
        else { url = URL(string: asset.downloadPath).flatMap { ["https", "http"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil } }
        guard let url else { return }
        let controller = AVPlayerViewController()
        controller.modalPresentationStyle = chatView?.configuration.media.videoPresentationStyle ?? .fullScreen
        controller.showsPlaybackControls = chatView?.configuration.media.showsVideoPlaybackControls ?? true
        controller.view.accessibilityIdentifier = "WYChatMedia.videoPlayer"
        controller.player = AVPlayer(url: url)
        player = controller
        photoBrowser.present(controller, animated: true) { [weak controller] in controller?.player?.play() }
    }
    func wy_photoBrowserDidDismiss(_ photoBrowser: WYPhotoBrowser) {
        player?.player?.pause()
        if chatView?.state.mediaBrowser === self { chatView?.state.mediaBrowser = nil }
    }
    func dispose() { player?.player?.pause(); browser?.dismiss(animated: false) }
}
