//
//  WYChatWithdrawnCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatWithdrawnCellPrivateState {
    let reeditButton = UIButton(type: .system)
    var reeditHeight: NSLayoutConstraint?
}

extension WYChatWithdrawnCell {
    func wy_withdrawnSetup() {
        withdrawnState.reeditButton.translatesAutoresizingMaskIntoConstraints = false
        withdrawnState.reeditHeight = withdrawnState.reeditButton.heightAnchor.constraint(equalToConstant: 0)
        withdrawnState.reeditHeight?.priority = UILayoutPriority(999)
        withdrawnState.reeditHeight?.isActive = true
        withdrawnState.reeditButton.addTarget(self, action: #selector(wy_reeditMessage), for: .touchUpInside)
        withdrawnState.reeditButton.accessibilityIdentifier = "WYChatNotice.reedit"
        withdrawnState.reeditButton.isHidden = true
        bodyView.addArrangedSubview(withdrawnState.reeditButton)
    }

    func wy_withdrawnReset() {
        withdrawnState.reeditButton.isHidden = true
        bodyView.setCustomSpacing(UIStackView.spacingUseDefault, after: state.header)
    }

    func wy_withdrawnMeasure(_ view: UIView, width: CGFloat) -> CGSize? {
        guard view === withdrawnState.reeditButton else { return nil }
        return CGSize(width: 0, height: withdrawnState.reeditHeight?.constant ?? 0)
    }

    @objc func wy_reeditMessage() { actionHandler?(.reedit, message.messageID) }

    func wy_withdrawnRender() {
        guard message.content.withdrawn != nil else { return }
        let template = configuration.notice.wy_withdrawalTemplate(for: message, userID: userID)
        state.title.text = template.replacingOccurrences(of: "%@", with: message.sender.name)
        state.title.isHidden = template.isEmpty
        let show = wy_chatCanReedit(message, userID: userID, configuration: configuration.notice, at: Date())
        withdrawnState.reeditButton.isHidden = !show
        withdrawnState.reeditButton.setTitle(configuration.notice.reeditText, for: .normal)
        withdrawnState.reeditButton.titleLabel?.font = configuration.notice.reeditFont
        withdrawnState.reeditButton.setTitleColor(configuration.notice.reeditColor, for: .normal)
        withdrawnState.reeditHeight?.constant = max(0, configuration.notice.reeditHeight)
        bodyView.setCustomSpacing(max(0, configuration.notice.reeditSpacing), after: state.header)
        wy_applyNoticeTextStyle()
    }
}
