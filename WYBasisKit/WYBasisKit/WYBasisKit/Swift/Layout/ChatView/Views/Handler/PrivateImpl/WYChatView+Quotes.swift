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
        quotePreview.wy_updateQuote(state.inputQuote, style: configuration.quote.input, configuration: configuration)
        wy_refreshInputAnchors()
        wy_layoutQuoteComposer()
        setNeedsLayout()
    }
    func wy_layoutQuoteComposer() {
        let quote = configuration.quote
        let insets = quote.inputOuterInsets
        let fieldWidth = chatInput.textVoiceContentView.bounds.width
        let availableWidth = quote.inputAlignsWithTextField && fieldWidth > 0 ? fieldWidth : safeAreaLayoutGuide.layoutFrame.width
        let width = max(1, availableWidth - max(0, insets.left) - max(0, insets.right))
        let height = quotePreview.isHidden ? 0 : quotePreview.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        if state.quoteHeight?.constant != height { state.quoteHeight?.constant = height }
        let reservedHeight = height > 0 && quote.inputBelowTextField ? height + max(0, insets.top) + max(0, insets.bottom) : 0
        if chatInput.quoteReservedHeight != reservedHeight { chatInput.quoteReservedHeight = reservedHeight }
    }
    func wy_openReference(_ quote: WYChatQuoteModel) {
        guard eventsHandler?.wy_shouldPerformMessageAction?(self, action: .reference, messageID: quote.messageID) ?? true else { return }
        inputViewResignFirstResponder()
        if let row = dataSource.firstIndex(where: { $0.messageID == quote.messageID }), row < tableView.numberOfRows(inSection: 0) {
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: !UIAccessibility.isReduceMotionEnabled)
        }
        actionHandler?(self, .reference, quote.messageID)
        delegate?.wy_messageAction?(self, action: .reference, messageID: quote.messageID)
    }
}
