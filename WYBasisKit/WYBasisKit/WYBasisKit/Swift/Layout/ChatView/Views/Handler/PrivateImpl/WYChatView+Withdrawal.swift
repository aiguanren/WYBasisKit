//
//  WYChatView+Withdrawal.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

func wy_chatCanReedit(_ message: WYChatMessageModel, userID: String, configuration: WYChatNoticeConfig, unit: WYChatTimestampUnit, at date: Date) -> Bool {
    guard configuration.allowsReedit, message.isSender(userID), let value = message.content.withdrawn, value.originalText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return false }
    if configuration.reeditTimeLimit == 0 { return true }
    guard configuration.reeditTimeLimit.isFinite, configuration.reeditTimeLimit > 0, let timestamp = unit.wy_epochSeconds(from: value.withdrawnTime) else { return false }
    return max(0, date.timeIntervalSince1970 - timestamp) < configuration.reeditTimeLimit
}

/// 接入方撤回结果与文本恢复
extension WYChatView {
    func wy_configuration(forMessage message: WYChatMessageModel) -> WYChatConfig {
        configuration.messageConfiguration?(message, configuration) ?? configuration
    }

    func wy_canWithdraw(_ message: WYChatMessageModel, at date: Date, configuration resolved: WYChatConfig? = nil) -> Bool {
        let configuration = resolved ?? wy_configuration(forMessage: message)
        guard message.content.withdrawn == nil else { return false }
        let pat = message.content.takePat
        guard (pat?.striking.id ?? message.sender.id) == userInfo.id, pat == nil || configuration.notice.allowsPatWithdrawal else { return false }
        let limit = pat == nil ? configuration.notice.withdrawalTimeLimit : configuration.notice.patWithdrawalTimeLimit
        if limit == 0 { return true }
        guard limit.isFinite, limit > 0, let timestamp = configuration.basic.timestampUnit.wy_epochSeconds(from: message.timestamp) else { return false }
        return max(0, date.timeIntervalSince1970 - timestamp) < limit
    }

    func wy_markWithdrawn(_ messageID: String, at date: Date, allowsReedit: Bool) -> Bool {
        guard let row = dataSource.firstIndex(where: { $0.messageID == messageID }), dataSource[row].content.withdrawn == nil else { return false }
        var message = dataSource[row]
        let configuration = wy_configuration(forMessage: message)
        var value = WYChatWithdrawnModel(sendTime: message.timestamp, withdrawalInterval: message.content.takePat == nil ? configuration.notice.withdrawalTimeLimit : configuration.notice.patWithdrawalTimeLimit, withdrawnTime: configuration.basic.timestampUnit.wy_timestamp(for: date), messageStyle: message.content.style())
        if allowsReedit && message.isSender(userInfo.id), let text = message.content.text {
            value.originalText = text
            value.reference = message.reference
            value.mentions = message.mentions
        }
        message.content = WYChatMessageContentModel(withdrawn: value)
        message.reference = nil
        message.mentions = []
        var updated = dataSource
        updated[row] = message
        var unavailable = value
        unavailable.originalText = nil
        unavailable.reference = nil
        unavailable.mentions = []
        let content = WYChatMessageContentModel(withdrawn: unavailable)
        for index in updated.indices {
            if updated[index].reference?.messageID == messageID { updated[index].reference?.content = content }
            if updated[index].content.withdrawn?.reference?.messageID == messageID { updated[index].content.withdrawn?.reference?.content = content }
        }
        dataSource = updated
        if state.inputQuote?.messageID == messageID { state.inputQuote?.content = content; wy_refreshQuote() }
        return true
    }

    func wy_reeditMessage(_ messageID: String) -> Bool {
        guard let message = messageModelFrom(messageID), let value = message.content.withdrawn, let text = value.originalText else { return false }
        let config = wy_configuration(forMessage: message)
        guard wy_chatCanReedit(message, userID: userInfo.id, configuration: config.notice, unit: config.basic.timestampUnit, at: Date()),
              wy_applyInputDraft(text, mentions: value.mentions, replacesInput: config.notice.reeditReplacesInput) else { return false }
        state.inputQuote = value.reference
        wy_refreshQuote()
        wy_activateInputDraft()
        return true
    }

    func wy_scheduleReeditExpiration() {
        state.reeditTimer?.cancel()
        state.reeditTimer = nil
        state.reeditRequestID = nil
        let now = Date().timeIntervalSince1970
        let expirations = dataSource.compactMap { message -> TimeInterval? in
            guard message.isSender(userInfo.id), let value = message.content.withdrawn, value.originalText != nil else { return nil }
            let resolved = wy_configuration(forMessage: message)
            let limit = resolved.notice.reeditTimeLimit
            guard resolved.notice.allowsReedit, limit.isFinite, limit > 0,
                  let date = resolved.basic.timestampUnit.wy_epochSeconds(from: value.withdrawnTime), date + limit > now else { return nil }
            return date + limit
        }
        guard let deadline = expirations.min() else { return }
        let requestID = UUID()
        state.reeditRequestID = requestID
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.state.reeditRequestID == requestID else { return }
            let paths = self.dataSource.indices.filter { self.dataSource[$0].content.withdrawn?.originalText != nil }.map { IndexPath(row: $0, section: 0) }
            for path in paths { self.state.measuredHeights.removeValue(forKey: self.wy_measurementKey(at: path)) }
            let visible = Set(self.tableView.indexPathsForVisibleRows ?? [])
            let refresh = paths.filter { visible.contains($0) }
            if !refresh.isEmpty { UIView.performWithoutAnimation { self.tableView.reconfigureRows(at: refresh) } }
            if self.state.reeditRequestID == requestID { self.wy_scheduleReeditExpiration() }
        }
        state.reeditTimer = item
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, deadline - now), execute: item)
    }
}
