//
//  WYChatNoticeConfig+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatNoticeConfig {
    func wy_withdrawalTemplate(for message: WYChatMessageModel, userID: String) -> String {
        if message.content.withdrawn?.messageStyle == .takePat && !patWithdrawnText.isEmpty { return patWithdrawnText }
        return message.isSender(userID) ? outgoingWithdrawnText ?? withdrawnText : withdrawnText
    }
}
