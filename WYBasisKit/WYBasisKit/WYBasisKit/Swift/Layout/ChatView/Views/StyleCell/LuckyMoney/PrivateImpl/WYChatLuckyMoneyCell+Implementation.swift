//
//  WYChatLuckyMoneyCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatLuckyMoneyCellPrivateState {
    let fundsCaption = WYChatFundsCaptionView()
}

extension WYChatLuckyMoneyCell {
    func wy_luckyMoneyRender() {
        guard let value = message.content.luckyMoney else { return }
        wy_renderFundsCard(value, isPacket: true, caption: luckyMoneyState.fundsCaption)
    }
}
