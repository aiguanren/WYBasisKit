//
//  WYChatNoticeCells+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit

/// 居中提示消息共用的文字样式。
extension WYChatBasicCell {
    func wy_applyNoticeTextStyle() {
        let style = messageContentConfiguration
        state.title.textAlignment = configuration.notice.centeredTextAlignment
        state.title.font = style.detailFont
        state.title.textColor = style.detailColor
    }
}
