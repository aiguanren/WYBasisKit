//
//  WYChatRecordsCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatRecordsCell {
    func wy_recordsRender() {
        guard let value = message.content.chatRecords else { return }
        wy_showMessageIcon("WYChatViewChatRecords")
        state.title.text = value.title
        state.detail.text = value.messages.prefix(max(1, messageContentConfiguration.detailNumberOfLines)).map {
            let summary = $0.content.wy_summary(provider: configuration.messageSummary, unsupportedText: configuration.unsupportedMessageText)
            return $0.sender.name + configuration.records.summarySenderSeparator + summary
        }.joined(separator: configuration.records.summaryLineSeparator)
        state.footer.text = value.remarks
    }
}
