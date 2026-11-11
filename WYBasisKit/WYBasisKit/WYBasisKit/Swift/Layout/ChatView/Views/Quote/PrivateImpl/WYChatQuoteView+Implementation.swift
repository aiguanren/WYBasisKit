//
//  WYChatQuoteView+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit
import Kingfisher

/// 引用预览资源与布局
final class WYChatQuoteViewPrivateState {
    var asset: WYChatAssetsModel?
    var isUpdating = false
}

extension WYChatQuoteView {
    func wy_setupQuote() {
        for view in [titleView, textView, thumbnailView, closeButton] { addSubview(view) }
        titleView.numberOfLines = 1
        thumbnailView.clipsToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        closeButton.addTarget(self, action: #selector(wy_closeQuote), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "WYChatQuote.close"
        accessibilityIdentifier = "WYChatQuote.preview"
        let tap = UITapGestureRecognizer(target: self, action: #selector(wy_tapQuote))
        titleView.isUserInteractionEnabled = true
        textView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(tap)
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wy_tapQuote)))
        thumbnailView.isUserInteractionEnabled = true
        thumbnailView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wy_tapQuote)))
        wy_renderQuote()
    }
    private func finite(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }
    private var safeInsets: UIEdgeInsets { UIEdgeInsets(top: finite(style.insets.top), left: finite(style.insets.left), bottom: finite(style.insets.bottom), right: finite(style.insets.right)) }
    private var sideWidth: CGFloat {
        (thumbnailView.isHidden ? 0 : finite(style.thumbnailSize.width) + finite(style.itemSpacing)) + (closeButton.isHidden ? 0 : finite(style.closeSize.width) + finite(style.itemSpacing))
    }
    func wy_renderQuote() {
        isHidden = quote == nil
        closeButton.isHidden = quote == nil || !style.showsCloseButton
        closeButton.setImage(style.closeImage, for: .normal)
        closeButton.tintColor = style.closeColor
        titleView.isHidden = !style.showsSender || quote?.sender.name.isEmpty != false
        titleView.text = quote.map { style.prefix + $0.sender.name }
        titleView.font = style.titleFont
        titleView.textColor = style.titleColor
        textView.text = quote.map { (titleView.isHidden ? style.prefix : "") + $0.content.wy_summary }
        textView.font = style.textFont
        textView.textColor = style.textColor
        textView.numberOfLines = max(0, style.maximumTextLines)
        backgroundColor = style.backgroundColor
        layer.cornerRadius = finite(style.cornerRadius)
        clipsToBounds = true
        thumbnailView.layer.cornerRadius = finite(style.thumbnailCornerRadius)
        let asset = quote.flatMap { thumbnail($0.content) }
        thumbnailView.isHidden = !style.showsThumbnail || asset == nil
        if asset == nil { thumbnailView.kf.cancelDownloadTask(); thumbnailView.image = nil }
        if asset != state.asset {
            state.asset = asset
            thumbnailView.kf.cancelDownloadTask()
            thumbnailView.image = style.thumbnailPlaceholder
            if let asset, !isMeasuring {
                if let imageLoader { imageLoader(asset, thumbnailView, quote?.messageID ?? "") }
                else if !asset.localPath.isEmpty {
                    let url = URL(string: asset.localPath).flatMap { $0.isFileURL ? $0 : nil } ?? URL(fileURLWithPath: asset.localPath)
                    thumbnailView.kf.setImage(with: .provider(LocalFileImageDataProvider(fileURL: url)), placeholder: style.thumbnailPlaceholder)
                } else if let url = URL(string: asset.downloadPath), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    thumbnailView.kf.setImage(with: url, placeholder: style.thumbnailPlaceholder)
                } else if !asset.name.isEmpty { thumbnailView.image = UIImage(systemName: asset.name) ?? UIImage.wy_find(asset.name, inBundle: WYChatSourceBundle) }
            }
        }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    private func thumbnail(_ content: WYChatMessageContentModel) -> WYChatAssetsModel? {
        if let photo = content.photo { return photo.thumbnail == WYChatAssetsModel() ? photo.original : photo.thumbnail }
        if let video = content.video { return video.thumbnailCover == WYChatAssetsModel() ? video.cover : video.thumbnailCover }
        if let group = content.mediaGroup, let item = group.items.first { return item.thumbnail == WYChatAssetsModel() ? item.original : item.thumbnail }
        if let web = content.webpage { return web.cover }
        return nil
    }
    func wy_quoteSize(width: CGFloat) -> CGSize {
        guard quote != nil else { return .zero }
        let width = max(1, finite(width))
        let insets = safeInsets
        let textWidth = max(1, width - insets.left - insets.right - sideWidth)
        let title = titleView.isHidden ? 0 : titleView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height + finite(style.spacing)
        let text = textView.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        var height = max(max(title + text, thumbnailView.isHidden ? 0 : finite(style.thumbnailSize.height)), closeButton.isHidden ? 0 : finite(style.closeSize.height)) + insets.top + insets.bottom
        height = max(finite(style.minimumHeight), height)
        if style.maximumHeight.isFinite && style.maximumHeight > 0 { height = min(height, max(finite(style.minimumHeight), style.maximumHeight)) }
        return CGSize(width: width, height: ceil(height))
    }
    func wy_layoutQuote() {
        let insets = safeInsets
        var x = insets.left
        let height = max(0, bounds.height - insets.top - insets.bottom)
        if !thumbnailView.isHidden {
            let size = CGSize(width: min(finite(style.thumbnailSize.width), max(0, bounds.width - x - insets.right)), height: min(height, finite(style.thumbnailSize.height)))
            thumbnailView.frame = CGRect(x: x, y: insets.top + (height - size.height) / 2, width: size.width, height: size.height)
            x += size.width + finite(style.itemSpacing)
        }
        var right = bounds.width - insets.right
        if !closeButton.isHidden {
            let size = CGSize(width: min(finite(style.closeSize.width), max(0, right - x)), height: min(height, finite(style.closeSize.height)))
            closeButton.frame = CGRect(x: right - size.width, y: insets.top + (height - size.height) / 2, width: size.width, height: size.height)
            right -= size.width + finite(style.itemSpacing)
        }
        let width = max(0, right - x)
        let titleHeight = titleView.isHidden ? 0 : min(height, titleView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height)
        titleView.frame = CGRect(x: x, y: insets.top, width: width, height: titleHeight)
        let y = insets.top + titleHeight + (titleView.isHidden ? 0 : finite(style.spacing))
        textView.frame = CGRect(x: x, y: y, width: width, height: max(0, bounds.height - insets.bottom - y))
    }
}
