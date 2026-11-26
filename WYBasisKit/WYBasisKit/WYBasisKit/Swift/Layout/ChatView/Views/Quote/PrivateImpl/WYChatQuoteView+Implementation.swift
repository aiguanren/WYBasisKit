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
    let openButton = UIButton(type: .custom)
    var isUpdating = false
    var emoji: WYEmojiViewConfig?
    var emojiPattern: String?
    var summaryProvider: ((WYChatMessageContentModel) -> String?)?
    var unsupportedMessageText = WYLocalized("不支持的消息类型", table: WYBasisKitConfig.kitLocalizableTable)
    var accessibilitySummary: String?
}

extension WYChatQuoteView {
    func wy_setupQuote() {
        for view in [state.openButton, titleView, textView, thumbnailView, closeButton] { addSubview(view) }
        thumbnailView.clipsToBounds = true
        state.openButton.addTarget(self, action: #selector(wy_tapQuote), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(wy_closeQuote), for: .touchUpInside)
        closeButton.accessibilityIdentifier = "WYChatQuote.close"
        accessibilityIdentifier = "WYChatQuote.preview"
        wy_renderQuote()
    }

    func wy_updateQuote(_ quote: WYChatQuoteModel?, style: WYChatQuoteStyle, configuration: WYChatConfig) {
        state.emoji = configuration.emoji
        state.emojiPattern = configuration.input.emojiPattern
        state.summaryProvider = configuration.messageSummary
        state.unsupportedMessageText = configuration.unsupportedMessageText
        update(quote: quote, style: style, imageLoader: configuration.imageLoader)
    }

    func wy_updateQuoteAccessibility() {
        let opensReference = tapHandler != nil
        state.openButton.isHidden = !opensReference
        state.openButton.accessibilityLabel = state.accessibilitySummary
        state.openButton.accessibilityIdentifier = accessibilityIdentifier.map { $0 + ".open" }
        titleView.isAccessibilityElement = !opensReference && !titleView.isHidden
        textView.isAccessibilityElement = !opensReference
    }

    func wy_renderQuote() {
        isHidden = quote == nil
        closeButton.isHidden = quote == nil || !style.showsCloseButton
        closeButton.setImage(closeButton.isHidden ? nil : wy_closeImage(), for: .normal)
        closeButton.tintColor = style.closeColor
        backgroundColor = style.backgroundColor
        layer.cornerRadius = finite(style.cornerRadius)
        clipsToBounds = true

        let name = quote?.sender.name ?? ""
        let showsSender = style.showsSender && !name.isEmpty
        closeButton.accessibilityLabel = style.closeAccessibilityLabel
        let summary = quote?.content.wy_summary(provider: state.summaryProvider, unsupportedText: state.unsupportedMessageText) ?? ""
        let sender = showsSender ? style.prefix + name + (style.showsSenderInline ? style.inlineSenderSeparator : "") : ""
        let body = showsSender ? summary : style.prefix + summary
        titleView.isHidden = !showsSender || style.showsSenderInline
        titleView.text = titleView.isHidden ? nil : sender
        titleView.font = style.titleFont
        titleView.numberOfLines = max(0, style.titleNumberOfLines)
        titleView.textColor = style.titleColor
        textView.font = style.textFont
        textView.lineBreakMode = style.textLineBreakMode
        thumbnailView.contentMode = style.thumbnailContentMode
        textView.textColor = style.textColor
        textView.numberOfLines = max(0, style.maximumTextLines)
        let text: NSMutableAttributedString
        if quote?.content.text != nil {
            let emoji = state.emoji ?? WYEmojiViewConfig()
            text = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: body, textColor: style.textColor, textFont: style.textFont, emojiTable: emoji.emojiSource, sourceBundle: emoji.emojiBundle, pattern: state.emojiPattern ?? WYInputBarConfig().emojiPattern, customImageLoader: { name, _ in emoji.staticEmojiImage(name) })
        } else {
            text = NSMutableAttributedString(string: body, attributes: [.font: style.textFont, .foregroundColor: style.textColor])
        }
        if showsSender && style.showsSenderInline {
            text.insert(NSAttributedString(string: sender, attributes: [.font: style.titleFont, .foregroundColor: style.titleColor]), at: 0)
        }
        textView.attributedText = text
        state.accessibilitySummary = showsSender && !style.showsSenderInline ? sender + style.accessibilitySeparator + body : sender + body
        textView.accessibilityLabel = titleView.isHidden ? state.accessibilitySummary : body
        wy_updateQuoteAccessibility()

        thumbnailView.layer.cornerRadius = finite(style.thumbnailCornerRadius)
        let asset = style.showsThumbnail ? quote.flatMap { wy_thumbnail($0.content) } : nil
        thumbnailView.isHidden = asset == nil
        thumbnailView.kf.cancelDownloadTask()
        thumbnailView.image = asset == nil ? nil : style.thumbnailPlaceholder
        if let asset, let quote, !isMeasuring { wy_loadThumbnail(asset, messageID: quote.messageID) }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func wy_thumbnail(_ content: WYChatMessageContentModel) -> WYChatAssetsModel? {
        let empty = WYChatAssetsModel()
        if let photo = content.photo { return photo.thumbnail == empty ? photo.original : photo.thumbnail }
        if let video = content.video { return video.thumbnailCover == empty ? video.cover : video.thumbnailCover }
        if let item = content.mediaGroup?.items.first, item.kind == .photo { return item.thumbnail == empty ? item.original : item.thumbnail }
        if let item = content.mediaGroup?.items.first { return item.thumbnail }
        return content.webpage?.cover
    }

    private func wy_loadThumbnail(_ asset: WYChatAssetsModel, messageID: String) {
        if let imageLoader {
            imageLoader(asset, thumbnailView, messageID)
        } else if !asset.localPath.isEmpty {
            let url = URL(string: asset.localPath).flatMap { $0.isFileURL ? $0 : nil } ?? URL(fileURLWithPath: asset.localPath)
            thumbnailView.kf.setImage(with: .provider(LocalFileImageDataProvider(fileURL: url)), placeholder: style.thumbnailPlaceholder)
        } else if let url = URL(string: asset.downloadPath), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            thumbnailView.kf.setImage(with: url, placeholder: style.thumbnailPlaceholder)
        } else if let image = WYChatSourceBundle.image(named: asset.name) {
            thumbnailView.image = image
        }
    }

    private func wy_closeImage() -> UIImage? {
        guard let image = style.closeImage, image.size.width > 0, image.size.height > 0 else { return nil }
        let scale = min(finite(style.closeSize.width) / image.size.width, finite(style.closeSize.height) / image.size.height)
        guard scale > 0 else { return nil }
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(image.renderingMode)
    }

    private func finite(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }

    private var safeInsets: UIEdgeInsets {
        UIEdgeInsets(top: finite(style.insets.top), left: finite(style.insets.left), bottom: finite(style.insets.bottom), right: finite(style.insets.right))
    }

    private var sideWidths: (thumbnail: CGFloat, close: CGFloat, spacing: CGFloat) {
        (thumbnailView.isHidden ? 0 : finite(style.thumbnailSize.width),
         closeButton.isHidden ? 0 : max(finite(style.closeMinimumTouchWidth), finite(style.closeSize.width)),
         finite(style.itemSpacing))
    }

    private func wy_columns(width: CGFloat) -> (thumbnailX: CGFloat, thumbnailWidth: CGFloat, textX: CGFloat, textWidth: CGFloat, closeX: CGFloat, closeWidth: CGFloat) {
        let insets = safeInsets
        let sides = sideWidths
        let right = max(0, width - insets.right)
        let left = min(insets.left, right)
        let close = min(sides.close, right - left)
        let closeX = right - close
        let textEnd = max(left, closeX - (close > 0 ? sides.spacing : 0))
        let thumbnail = min(sides.thumbnail, textEnd - left)
        let textX = min(textEnd, left + thumbnail + (thumbnail > 0 ? sides.spacing : 0))
        return (left, thumbnail, textX, textEnd - textX, closeX, close)
    }

    func wy_fittedQuoteWidth(maximum: CGFloat) -> CGFloat {
        let insets = safeInsets
        let sides = sideWidths
        let sideWidth = (sides.thumbnail > 0 ? sides.thumbnail + sides.spacing : 0) + (sides.close > 0 ? sides.close + sides.spacing : 0)
        let textSpace = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let title = titleView.isHidden ? 0 : titleView.sizeThatFits(textSpace).width
        let text = textView.sizeThatFits(textSpace).width
        return min(maximum, max(1, ceil(max(title, text) + insets.left + insets.right + sideWidth)))
    }

    private func wy_textHeights(width: CGFloat) -> (title: CGFloat, text: CGFloat, spacing: CGFloat) {
        guard width > 0 else { return (0, 0, 0) }
        let fit = CGSize(width: width, height: .greatestFiniteMagnitude)
        let title = titleView.isHidden ? 0 : titleView.sizeThatFits(fit).height
        return (title, textView.sizeThatFits(fit).height, title > 0 ? finite(style.spacing) : 0)
    }

    func wy_quoteSize(width: CGFloat) -> CGSize {
        guard quote != nil else { return .zero }
        let width = max(1, finite(width))
        let insets = safeInsets
        let columns = wy_columns(width: width)
        let text = wy_textHeights(width: columns.textWidth)
        let thumbnail = columns.thumbnailWidth > 0 ? finite(style.thumbnailSize.height) : 0
        let close = columns.closeWidth > 0 ? finite(style.closeSize.height) : 0
        let minimum = finite(style.minimumHeight)
        let maximum = finite(style.maximumHeight)
        let fitted = max(minimum, max(text.title + text.spacing + text.text, thumbnail, close) + insets.top + insets.bottom)
        return CGSize(width: width, height: ceil(maximum > 0 ? min(fitted, max(minimum, maximum)) : fitted))
    }

    func wy_layoutQuote() {
        let insets = safeInsets
        let columns = wy_columns(width: bounds.width)
        let contentHeight = max(0, bounds.height - insets.top - insets.bottom)
        let text = wy_textHeights(width: columns.textWidth)
        let titleHeight = min(contentHeight, text.title)
        let spacing = min(text.spacing, contentHeight - titleHeight)
        let textHeight = min(text.text, contentHeight - titleHeight - spacing)
        let textTop = min(insets.top, bounds.height) + (contentHeight - titleHeight - spacing - textHeight) / 2
        titleView.frame = CGRect(x: columns.textX, y: textTop, width: columns.textWidth, height: titleHeight)
        textView.frame = CGRect(x: columns.textX, y: textTop + titleHeight + spacing, width: columns.textWidth, height: textHeight)
        let thumbnailHeight = min(contentHeight, finite(style.thumbnailSize.height))
        thumbnailView.frame = CGRect(x: columns.thumbnailX, y: min(insets.top, bounds.height) + (contentHeight - thumbnailHeight) / 2, width: columns.thumbnailWidth, height: thumbnailHeight)
        closeButton.frame = CGRect(x: columns.closeX, y: 0, width: columns.closeWidth, height: bounds.height)
        state.openButton.frame = CGRect(x: 0, y: 0, width: closeButton.isHidden ? bounds.width : columns.closeX, height: bounds.height)
    }
}
