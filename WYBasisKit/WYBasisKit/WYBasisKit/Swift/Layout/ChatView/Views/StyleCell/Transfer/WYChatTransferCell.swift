//
//  WYChatTransferCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatTransferCell: WYChatBasicCell {
    let transferState = WYChatTransferCellPrivateState()

    override var wy_bubbleFillColor: UIColor? { wy_fundsBubbleColor(message.content.transfer) }
    override func wy_setupContent() { transferState.fundsCaption.install(in: self) }
    override func wy_resetContent() { transferState.fundsCaption.isHidden = true }
    override func wy_layoutContent(width: CGFloat) { transferState.fundsCaption.layout(in: self, width: width) }

    open override func renderContent() { wy_transferRender() }
}

/// 居中显示红包或转账回执。
public final class WYChatFundsReceiptCell: WYChatBasicCell {
    override var wy_isNotice: Bool { true }
    override var wy_noticeBackgroundColor: UIColor? { configuration.notice.fundsReceiptBackgroundColor }

    public override func renderContent() { wy_fundsReceiptRender() }
}
