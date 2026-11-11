//
//  WYChatView+Quotes.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 引用预览与消息跳转
extension WYChatView {
    func wy_refreshQuote() {
        quotedMessageID = state.inputQuote?.messageID
        quotePreview.update(quote: state.inputQuote, style: configuration.quote.input, imageLoader: configuration.imageLoader)
        quotePreview.isHidden = state.inputQuote == nil || !configuration.showsInputBar
        wy_refreshInputAnchors()
        wy_layoutQuoteComposer()
        setNeedsLayout()
    }
    func wy_layoutQuoteComposer() {
        let insets = configuration.quote.inputOuterInsets
        let width = max(1, bounds.width - safeAreaInsets.left - safeAreaInsets.right - max(0, insets.left) - max(0, insets.right))
        let height = state.inputQuote == nil ? 0 : quotePreview.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        if state.quoteHeight?.constant != height { state.quoteHeight?.constant = height }
    }
    func wy_openReference(_ quote: WYChatQuoteModel) {
        guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: .reference, messageID: quote.messageID) ?? true else { return }
        inputViewResignFirstResponder()
        if let row = dataSource.firstIndex(where: { $0.messageID == quote.messageID }) { tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: true) }
        actionHandler?(self, .reference, quote.messageID)
        delegate?.wy_messageAction?(self, action: .reference, messageID: quote.messageID)
    }
}
