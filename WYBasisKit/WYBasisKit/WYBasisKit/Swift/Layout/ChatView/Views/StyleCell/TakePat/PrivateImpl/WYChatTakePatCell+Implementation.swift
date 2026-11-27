//
//  WYChatTakePatCell+Implementation.swift
//  WYBasisKit
//

import UIKit

extension WYChatTakePatCell {
    func wy_takePatRender() {
        guard let value = message.content.takePat else { return }
        if let template = configuration.notice.patText {
            state.title.text = template.replacingOccurrences(of: "{sender}", with: value.striking.name)
                .replacingOccurrences(of: "{recipient}", with: value.beaten.name)
                .replacingOccurrences(of: "{note}", with: value.notes)
        } else {
            state.title.text = String(format: WYLocalized("%@拍了拍%@%@", table: WYBasisKitConfig.kitLocalizableTable), value.striking.name, value.beaten.name, value.notes)
        }
        let font = messageContentConfiguration.detailFont
        state.preferredContentWidth = ceil(((state.title.text ?? "") as NSString).size(withAttributes: [.font: font]).width)
        wy_applyNoticeTextStyle()
    }
}
