//
//  WYChatWithdrawnCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatWithdrawnCell: WYChatBasicCell {
    let withdrawnState = WYChatWithdrawnCellPrivateState()

    override var wy_isNotice: Bool { true }
    override var wy_hidesContent: Bool { state.title.isHidden && withdrawnState.reeditButton.isHidden && message.content.withdrawn != nil }

    override func wy_setupContent() { wy_withdrawnSetup() }

    override func wy_resetContent() { wy_withdrawnReset() }

    override func wy_measureContent(_ view: UIView, width: CGFloat) -> CGSize? { wy_withdrawnMeasure(view, width: width) }

    open override func renderContent() { wy_withdrawnRender() }
}
