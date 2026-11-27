//
//  WYChatLuckyMoneyCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/20.
//

import UIKit

/// 消息内容Cell
open class WYChatLuckyMoneyCell: WYChatBasicCell {
    let luckyMoneyState = WYChatLuckyMoneyCellPrivateState()

    override var wy_bubbleFillColor: UIColor? { wy_fundsBubbleColor(message.content.luckyMoney) }
    override func wy_setupContent() { luckyMoneyState.fundsCaption.install(in: self) }
    override func wy_resetContent() { luckyMoneyState.fundsCaption.isHidden = true }
    override func wy_layoutContent(width: CGFloat) { luckyMoneyState.fundsCaption.layout(in: self, width: width) }

    open override func renderContent() { wy_luckyMoneyRender() }
}
