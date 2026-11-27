//
//  WYChatTakePatCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatTakePatCell: WYChatBasicCell {
    override var wy_isNotice: Bool { true }
    override var wy_noticeBackgroundColor: UIColor? { configuration.notice.patBackgroundColor }
    override var wy_noticeCornerRadius: CGFloat? {
        let radius = configuration.notice.patCornerRadius
        return radius.isFinite ? max(0, radius) : nil
    }

    open override func renderContent() { wy_takePatRender() }
}
