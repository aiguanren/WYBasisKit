//
//  WYChatTextCell+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

struct WYChatEmojiMessageKey: Hashable {
    let sessionID: String
    let messageID: String
    let text: String
    let senderID: String
    let timestamp: String
    let index: Int?

    init(_ message: WYChatMessageModel) {
        sessionID = message.sessionID
        messageID = message.messageID
        text = message.content.text ?? ""
        senderID = messageID.isEmpty ? message.sender.id : ""
        timestamp = messageID.isEmpty ? message.timestamp : ""
        index = messageID.isEmpty ? message.index : nil
    }
}

struct WYChatTextEmoji {
    let range: NSRange
    let attachment: WYTextAttachment
    let staticImage: UIImage
    let customAnimation: WYChatEmojiAnimation?
}

final class WYChatTextEmojiPlayback {
    weak var chatView: WYChatView?
    var messageKey: WYChatEmojiMessageKey?
    var attempted = false
    var emojis: [WYChatTextEmoji] = []
    var animations: [String: WYChatEmojiAnimation] = [:]
    var startedAt: CFTimeInterval = 0
    var timer: Timer?

    deinit { timer?.invalidate() }
}

private func wy_chatIsSingleEmoji(_ text: NSAttributedString) -> Bool {
    if text.length == 1 && text.attribute(.attachment, at: 0, effectiveRange: nil) is WYTextAttachment { return true }
    guard text.string.count == 1 else { return false }
    return text.string.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.value == 0xFE0F || $0.value == 0x20E3 }
}

final class WYChatMessageTextView: UITextView {
    var hasEmojiAttachments = false

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        if wy_chatIsSingleEmoji(textStorage) { return false }
        guard hasEmojiAttachments else { return true }
        // 让消息菜单处理表情字形上的触点，普通文字仍交给文本控件。
        let location = CGPoint(x: point.x - textContainerInset.left, y: point.y - textContainerInset.top)
        let glyph = layoutManager.glyphIndex(for: location, in: textContainer)
        guard glyph < layoutManager.numberOfGlyphs,
              layoutManager.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: textContainer).contains(location) else { return true }
        let index = layoutManager.characterIndexForGlyph(at: glyph)
        guard index < textStorage.length else { return true }
        return !(textStorage.attribute(.attachment, at: index, effectiveRange: nil) is WYTextAttachment)
    }
}

final class WYChatMessageTextInteractionDelegate: NSObject, UITextViewDelegate {
    @available(iOS, introduced: 10.0, deprecated: 17.0)
    func textView(_ textView: UITextView, shouldInteractWith attachment: NSTextAttachment, in range: NSRange, interaction: UITextItemInteraction) -> Bool {
        !(attachment is WYTextAttachment)
    }

    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        if case let .textAttachment(attachment) = textItem.content, attachment is WYTextAttachment { return nil }
        return defaultAction
    }

    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        if case let .textAttachment(attachment) = textItem.content, attachment is WYTextAttachment { return nil }
        return UITextItem.MenuConfiguration(menu: defaultMenu)
    }
}

/// 文本消息内容
extension WYChatTextCell {
    func wy_setupText() {
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.delegate = textInteractionDelegate
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        bodyView.insertArrangedSubview(textView, at: 0)
        state.textHeight = textView.heightAnchor.constraint(equalToConstant: 1)
        state.textHeight?.isActive = true
        state.measuredText = nil
        state.title.isHidden = true
        wy_render()
    }

    var wy_isSingleEmoji: Bool { wy_chatIsSingleEmoji(textView.textStorage) }

    func wy_renderText() {
        let value = configuration.text
        if !state.isMeasuring {
            let key = WYChatEmojiMessageKey(message)
            if emojiPlayback.messageKey != key || value.emojiPlaybackMode == .staticOnly {
                wy_suspendEmojiPlayback()
                emojiPlayback.messageKey = key
            }
        }
        state.title.isHidden = true
        let emoji = configuration.emoji
        let attributed = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: message.content.text ?? "", textColor: value.textColor, textFont: value.textFont, emojiTable: emoji.emojiSource, sourceBundle: emoji.emojiBundle, pattern: configuration.input.emojiPattern, customImageLoader: { name, _ in emoji.staticEmojiImage(name) })
        emojiPlayback.emojis.removeAll(keepingCapacity: true)
        var hasEmojiAttachments = false
        attributed.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributed.length)) { item, range, _ in
            guard let attachment = item as? WYTextAttachment else { return }
            hasEmojiAttachments = true
            guard let image = attachment.image else { return }
            let frames = image.images
            let staticImage = (emoji.staticFramePosition == .first ? frames?.first : frames?.last) ?? image
            attachment.image = staticImage
            if !state.isMeasuring && value.emojiPlaybackMode != .staticOnly {
                emojiPlayback.emojis.append(WYChatTextEmoji(range: range, attachment: attachment, staticImage: staticImage, customAnimation: WYChatEmojiAnimation(image: image, defaultFrameDelay: emoji.wy_defaultAnimationFrameDelay)))
            }
        }
        attributed.wy_lineSpacing(value.textLineSpacing, alignment: .natural)
        textView.textColor = value.textColor
        (textView as? WYChatMessageTextView)?.hasEmojiAttachments = hasEmojiAttachments
        textView.isSelectable = value.isSelectable && !wy_chatIsSingleEmoji(attributed)
        textView.dataDetectorTypes = state.isMeasuring ? [] : value.dataDetectorTypes
        textView.textContainer.maximumNumberOfLines = max(0, value.textMaximumNumberOfLines)
        textView.attributedText = attributed
        textView.font = value.textFont
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = value.textLineSpacing
        textView.typingAttributes = [.font: value.textFont, .foregroundColor: value.textColor, .paragraphStyle: paragraph]
        state.measuredText = nil
        if emojiPlayback.timer != nil { wy_advanceEmojiPlayback() }
        else { wy_scheduleEmojiPlayback() }
    }

    func wy_beginEmojiDisplay(in chatView: WYChatView) {
        emojiPlayback.chatView = chatView
        wy_scheduleEmojiPlayback()
    }

    func wy_endEmojiDisplay() {
        wy_suspendEmojiPlayback()
        emojiPlayback.chatView = nil
    }

    func wy_suspendEmojiPlayback() {
        wy_finishEmojiPlayback()
        emojiPlayback.attempted = false
    }

    func wy_scheduleEmojiPlayback() {
        guard window != nil, emojiPlayback.chatView != nil,
              !emojiPlayback.attempted, !emojiPlayback.emojis.isEmpty else { return }
        // 首次布局可能重载列表，等当前布局完成后再记为已播放。
        DispatchQueue.main.async { [weak self] in self?.wy_startEmojiPlaybackIfNeeded() }
    }

    private func wy_startEmojiPlaybackIfNeeded() {
        let mode = configuration.text.emojiPlaybackMode
        let interval = wy_chatNonnegative(configuration.text.emojiAnimationFrameInterval)
        guard interval > 0, window != nil, let chatView = emojiPlayback.chatView, let key = emojiPlayback.messageKey,
              !emojiPlayback.attempted, !emojiPlayback.emojis.isEmpty, mode != .staticOnly,
              let path = chatView.tableView.indexPath(for: self),
              chatView.tableView.indexPathsForVisibleRows?.contains(path) == true else { return }
        emojiPlayback.attempted = true
        guard mode == .everyDisplay || !chatView.state.playedEmojiMessages.contains(key) else { return }

        var resolved: Set<String> = []
        for emoji in emojiPlayback.emojis where resolved.insert(emoji.attachment.imageName).inserted {
            let name = emoji.attachment.imageName
            emojiPlayback.animations[name] = emoji.customAnimation ?? configuration.emoji.emojiAnimation(name)
        }
        guard !emojiPlayback.animations.isEmpty else { return }
        chatView.state.playedEmojiMessages.insert(key)
        emojiPlayback.startedAt = CACurrentMediaTime()
        let timer = Timer(timeInterval: max(1.0 / 120.0, interval), repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.wy_advanceEmojiPlayback() }
        }
        emojiPlayback.timer = timer
        RunLoop.main.add(timer, forMode: .common)
        wy_advanceEmojiPlayback()
    }

    private func wy_advanceEmojiPlayback() {
        let elapsed = CACurrentMediaTime() - emojiPlayback.startedAt
        var isPlaying = false
        for emoji in emojiPlayback.emojis {
            let frame = emojiPlayback.animations[emoji.attachment.imageName]?.frame(at: elapsed)
            if frame != nil { isPlaying = true }
            wy_drawEmoji(emoji, image: frame ?? emoji.staticImage)
        }
        if !isPlaying { wy_finishEmojiPlayback() }
    }

    private func wy_finishEmojiPlayback() {
        guard let timer = emojiPlayback.timer else { return }
        timer.invalidate()
        emojiPlayback.timer = nil
        emojiPlayback.animations.removeAll()
        for emoji in emojiPlayback.emojis { wy_drawEmoji(emoji, image: emoji.staticImage) }
    }

    private func wy_drawEmoji(_ emoji: WYChatTextEmoji, image: UIImage) {
        guard emoji.attachment.image !== image, NSMaxRange(emoji.range) <= textView.textStorage.length,
              textView.textStorage.attribute(.attachment, at: emoji.range.location, effectiveRange: nil) as? WYTextAttachment === emoji.attachment else { return }
        emoji.attachment.image = image
        textView.layoutManager.invalidateDisplay(forCharacterRange: emoji.range)
    }
}
