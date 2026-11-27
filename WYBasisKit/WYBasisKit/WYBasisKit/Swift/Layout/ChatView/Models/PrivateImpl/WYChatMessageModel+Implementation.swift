//
//  WYChatMessageModel+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatTimestampUnit {
    func wy_epochSeconds(from text: String) -> TimeInterval? {
        guard let value = Double(text), value.isFinite else { return nil }
        switch self {
        case .automatic: return value > 100_000_000_000 ? value / 1000 : value
        case .seconds: return value
        case .milliseconds: return value / 1000
        }
    }

    func wy_timestamp(for date: Date = Date()) -> String {
        String(date.timeIntervalSince1970 * (self == .milliseconds ? 1000 : 1))
    }
}

extension WYChatMessageModel {
    func wy_lastMessageTimestamp(_ messages: [WYChatMessageModel], minimumTimeSpan: TimeInterval, unit: WYChatTimestampUnit) -> String {
        guard let last = messages.last else { return "" }
        guard !last.lastMessageTimestamp.isEmpty else { return last.timestamp }
        let current = unit.wy_epochSeconds(from: last.timestamp) ?? 0
        let previous = unit.wy_epochSeconds(from: last.lastMessageTimestamp) ?? 0
        return current - previous >= minimumTimeSpan ? last.timestamp : last.lastMessageTimestamp
    }
}

extension WYChatMessageModel {
    var wy_effectiveTransferState: WYChatTransferState {
        guard transferState == .automatic else { return transferState }
        if !transferError.isEmpty { return .failed }
        return isTransferring ? .transferring : .automatic
    }
}
