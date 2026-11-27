//
//  WYChatMessageModel+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatMessageModel {
    var wy_effectiveTransferState: WYChatTransferState {
        guard transferState == .automatic else { return transferState }
        if !transferError.isEmpty { return .failed }
        return isTransferring ? .transferring : .automatic
    }
}
