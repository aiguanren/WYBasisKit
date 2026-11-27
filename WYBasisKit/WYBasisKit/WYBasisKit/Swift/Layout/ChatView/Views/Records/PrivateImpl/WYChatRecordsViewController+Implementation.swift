//
//  WYChatRecordsViewController+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 合并记录布局与只读交互
extension WYChatRecordsViewController {
    func wy_setupRecords() {
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)
        NSLayoutConstraint.activate([chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor), chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor), chatView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        closeButton.target = self
        closeButton.action = #selector(wy_closeRecords)
        closeButton.accessibilityIdentifier = "WYChatRecords.close"
        wy_renderRecords()
    }
    func wy_renderRecords() {
        let style = configuration.records
        title = records.title.isEmpty ? configuration.selection.recordsTitle : records.title
        let label = UILabel()
        label.text = title
        label.font = style.titleFont
        label.textColor = style.titleColor
        label.adjustsFontSizeToFitWidth = style.titleAdjustsFontSizeToFitWidth
        label.sizeToFit()
        navigationItem.titleView = label
        navigationItem.leftBarButtonItem = style.showsCloseButton ? closeButton : nil
        closeButton.title = style.closeText
        closeButton.tintColor = style.closeColor
        for state in [UIControl.State.normal, .highlighted, .disabled] { closeButton.setTitleTextAttributes([.font: style.closeFont], for: state) }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = style.navigationColor
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        var detail = configuration
        detail.showsInputBar = style.showsInputBar
        detail.basic.avatarLongPressAction = style.avatarLongPressAction
        detail.basic.avatarDoubleTapAction = style.avatarDoubleTapAction
        detail.sender.showsSingleNickname = style.showsNicknames
        detail.receiver.showsSingleNickname = style.showsNicknames
        detail.menuActions.removeAll { style.excludedMenuActions.contains($0) }
        chatView.configuration = detail
        chatView.dataSource = records.messages
        let insets = chatView.tableView.adjustedContentInset
        chatView.tableView.setContentOffset(CGPoint(x: -insets.left, y: -insets.top), animated: false)
        view.backgroundColor = configuration.backgroundColor
    }
    @objc func wy_closeRecords() { dismiss(animated: true) }
}

/// 接入方接管或内置展示合并记录
extension WYChatView {
    func wy_previewRecords(_ messageID: String) {
        guard let message = messageModelFrom(messageID), let records = message.content.chatRecords else { return }
        inputViewResignFirstResponder()
        if let recordsPreviewHandler { recordsPreviewHandler(records); return }
        let configuration = wy_configuration(forMessage: message)
        guard configuration.records.automaticallyPresentsDetail else { return }
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let controller = next as? UIViewController {
                guard controller.presentedViewController == nil else { return }
                let detail = WYChatRecordsViewController(records: records, userInfo: userInfo, configuration: configuration)
                let navigation = UINavigationController(rootViewController: detail)
                navigation.modalPresentationStyle = configuration.records.presentationStyle
                controller.present(navigation, animated: true)
                return
            }
            responder = next
        }
    }
}
