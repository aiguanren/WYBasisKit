//
//  WYChatView+Selection.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 多选区间与转发快照
extension WYChatView {
    func wy_setSelectedMessages(_ identifiers: [String], anchorID: String? = nil) -> Bool {
        let selected = Set(identifiers)
        let available = Set(dataSource.map(\.messageID))
        let limit = configuration.selection.maximumCount
        guard selected.isSubset(of: available), limit <= 0 || selected.count <= limit else { return false }
        let changed = selectedMessageIDs.symmetricDifference(selected)
        selectedMessageIDs = selected
        state.selectionAnchorID = anchorID.flatMap { selected.contains($0) ? $0 : nil } ?? identifiers.last
        guard isSelectingMessages else {
            isSelectingMessages = true
            return true
        }
        guard !changed.isEmpty else {
            wy_refreshRangeSelectionButton()
            return true
        }

        var customRows: [IndexPath] = []
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard dataSource.indices.contains(indexPath.row), let cell = tableView.cellForRow(at: indexPath) else { continue }
            let identifier = dataSource[indexPath.row].messageID
            guard changed.contains(identifier) else { continue }
            if let messageCell = cell as? WYChatBasicCell, messageCell.wy_isSelectingMessages, messageCell.message.messageID == identifier {
                messageCell.isMessageSelected = selected.contains(identifier)
            } else {
                customRows.append(indexPath)
            }
        }
        wy_updateSelectionUI()
        if !customRows.isEmpty {
            UIView.performWithoutAnimation { tableView.reloadRows(at: customRows, with: .none) }
        }
        return true
    }
    func wy_selectRange(from first: String, through last: String) -> Bool {
        guard configuration.selection.allowsRangeSelection,
              let start = dataSource.firstIndex(where: { $0.messageID == first }),
              let end = dataSource.firstIndex(where: { $0.messageID == last }) else { return false }
        let identifiers = dataSource[min(start, end)...max(start, end)].map(\.messageID)
        let selection = selectedMessageIDs.union(identifiers)
        guard configuration.selection.maximumCount <= 0 || selection.count <= configuration.selection.maximumCount else { return false }
        return wy_setSelectedMessages(dataSource.map(\.messageID).filter { selection.contains($0) }, anchorID: first)
    }

    func wy_setupRangeSelectionButton() {
        let button = state.selectionRangeButton
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "WYChatView.selectionRange"
        button.isHidden = true
        var appearance = UIButton.Configuration.filled()
        appearance.cornerStyle = .fixed
        button.configuration = appearance
        button.addTarget(self, action: #selector(wy_selectToVisibleMessage), for: .touchUpInside)
        addSubview(button)
        let top = button.topAnchor.constraint(equalTo: tableView.topAnchor)
        let bottom = button.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        let leading = button.leadingAnchor.constraint(equalTo: tableView.leadingAnchor)
        let trailing = button.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor)
        trailing.priority = UILayoutPriority(999)
        state.selectionRangeEdges = (top, bottom, leading, trailing)
        let minimumHeight = button.heightAnchor.constraint(greaterThanOrEqualToConstant: wy_chatNonnegative(configuration.selection.rangeButtonMinimumHeight))
        state.selectionRangeMinimumHeight = minimumHeight
        NSLayoutConstraint.activate([bottom, leading, trailing, minimumHeight])
    }

    func wy_refreshRangeSelectionButton() {
        let button = state.selectionRangeButton
        let style = configuration.selection
        state.selectionRangeMinimumHeight?.constant = wy_chatNonnegative(style.rangeButtonMinimumHeight)
        guard isSelectingMessages, style.allowsRangeSelection, style.showsRangeButton, !selectedMessageIDs.isEmpty,
              let edges = state.selectionRangeEdges else {
            state.selectionRangeAnchorRow = nil
            state.selectionRangePrefersEarlier = false
            state.selectionRangeScrollOffset = nil
            button.isHidden = true
            return
        }
        state.selectionRangeAnchorRow = dataSource.firstIndex { $0.messageID == state.selectionAnchorID }
            ?? dataSource.firstIndex { selectedMessageIDs.contains($0.messageID) }
        let rangeButton = style.rangeButton
        let title = rangeButton.title ?? style.rangeTitle
        let inset = rangeButton.edgeInset.isFinite ? max(0, rangeButton.edgeInset) : 0
        edges.top.constant = inset
        edges.bottom.constant = -inset
        edges.leading.constant = inset
        edges.trailing.constant = -inset
        if var appearance = button.configuration {
            appearance.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: rangeButton.font]))
            appearance.baseForegroundColor = rangeButton.tintColor
            appearance.baseBackgroundColor = rangeButton.backgroundColor
            appearance.background.cornerRadius = max(0, rangeButton.cornerRadius)
            appearance.background.strokeWidth = max(0, rangeButton.borderWidth)
            appearance.background.strokeColor = rangeButton.borderColor ?? rangeButton.tintColor.withAlphaComponent(min(1, wy_chatNonnegative(rangeButton.defaultBorderOpacity)))
            appearance.imagePadding = wy_chatNonnegative(rangeButton.imageSpacing)
            appearance.image = edges.top.isActive ? rangeButton.topImage : rangeButton.bottomImage
            let padding = rangeButton.contentInsets
            appearance.contentInsets = NSDirectionalEdgeInsets(top: padding.top, leading: padding.left, bottom: padding.bottom, trailing: padding.right)
            button.configuration = appearance
        }
        button.accessibilityLabel = title
        if state.selectionRangeScrollOffset == nil { state.selectionRangeScrollOffset = tableView.contentOffset.y }
        wy_updateRangeSelectionButton()
    }

    func wy_updateRangeSelectionScroll(_ scrollView: UIScrollView) {
        guard state.selectionRangeAnchorRow != nil, scrollView === tableView else { return }
        let offset = scrollView.contentOffset.y
        let insets = scrollView.adjustedContentInset
        let maximum = max(-insets.top, scrollView.contentSize.height - scrollView.bounds.height + insets.bottom)
        let clampedOffset = min(maximum, max(-insets.top, offset))
        if let previous = state.selectionRangeScrollOffset, previous != clampedOffset,
           scrollView.isDragging || scrollView.isDecelerating {
            state.selectionRangePrefersEarlier = clampedOffset < previous
        }
        state.selectionRangeScrollOffset = clampedOffset
        wy_updateRangeSelectionButton()
    }

    func wy_updateRangeSelectionButton() {
        let button = state.selectionRangeButton
        guard let target = wy_visibleRangeTarget(), let edges = state.selectionRangeEdges else {
            button.isHidden = true
            return
        }
        if edges.top.isActive != target.earlier {
            NSLayoutConstraint.deactivate([edges.top, edges.bottom])
            (target.earlier ? edges.top : edges.bottom).isActive = true
            if var appearance = button.configuration {
                let style = configuration.selection.rangeButton
                appearance.image = target.earlier ? style.topImage : style.bottomImage
                button.configuration = appearance
            }
        }
        button.isHidden = false
    }

    private func wy_visibleRangeTarget() -> (identifier: String, earlier: Bool)? {
        guard let anchor = state.selectionRangeAnchorRow, dataSource.indices.contains(anchor),
              let edges = state.selectionRangeEdges,
              selectedMessageIDs.contains(dataSource[anchor].messageID),
              tableView.bounds.height >= wy_chatNonnegative(configuration.selection.rangeMinimumViewportHeight) + max(0, edges.top.constant) + max(0, -edges.bottom.constant),
              tableView.bounds.width > 2 * edges.leading.constant,
              let rows = tableView.indexPathsForVisibleRows?.map(\.row),
              let first = rows.min(), let last = rows.max() else { return nil }
        let earlier = first < anchor && (last <= anchor || state.selectionRangePrefersEarlier)
        let row = earlier ? first : last
        guard row != anchor, dataSource.indices.contains(row) else { return nil }

        let range = min(anchor, row)...max(anchor, row)
        let limit = configuration.selection.maximumCount
        let remaining = limit > 0 ? limit - selectedMessageIDs.count : Int.max
        guard remaining > 0, limit <= 0 || range.count <= limit else { return nil }
        let additions = dataSource[range].lazy.filter { !self.selectedMessageIDs.contains($0.messageID) }
            .prefix(limit > 0 ? remaining + 1 : 1).count
        guard additions > 0, additions <= remaining else { return nil }
        let target = dataSource[row]
        guard configuration.allowsAction?(.selectRange, target) ?? true else { return nil }
        return (target.messageID, earlier)
    }

    @objc private func wy_selectToVisibleMessage() {
        guard let target = wy_visibleRangeTarget() else { return }
        wy_performAction(.selectRange, messageID: target.identifier)
    }

    func wy_selectedSources(_ identifiers: [String]) -> [WYChatMessageModel]? {
        let requested = Set(identifiers)
        guard !requested.isEmpty, requested.isSubset(of: Set(dataSource.map(\.messageID))) else { return nil }
        return dataSource.filter { requested.contains($0.messageID) }
    }
    func wy_makeForwardMessages(_ identifiers: [String], mode: WYChatForwardMode, title: String?) -> [WYChatMessageModel] {
        guard let sources = wy_selectedSources(identifiers) else { return [] }
        return wy_makeForwardMessages(from: sources, mode: mode, title: title)
    }

    private func wy_makeForwardMessages(from sources: [WYChatMessageModel], mode: WYChatForwardMode, title: String?) -> [WYChatMessageModel] {
        let content: [WYChatMessageContentModel]
        if mode == .merged { content = [WYChatMessageContentModel(chatRecords: WYChatRecordsModel(title: title ?? configuration.selection.recordsTitle, messages: sources))] }
        else { content = sources.map(\.content) }
        return content.map { value in
            var result = WYChatMessageModel(messageID: UUID().uuidString, timestamp: configuration.basic.timestampUnit.wy_timestamp(), sender: userInfo, content: value)
            result.sendState = .sending
            return result
        }
    }
    private var wy_forwardModes: [WYChatForwardMode] {
        var included = Set<Int>()
        return configuration.selection.forwardModes.filter { included.insert($0.rawValue).inserted }
    }

    private func wy_forwardTitle(_ mode: WYChatForwardMode) -> String {
        let style = configuration.selection
        return mode == .merged ? style.mergedTitle : style.individualTitle
    }

    var wy_usesForwardMenu: Bool {
        wy_hasForwardHandler && forwardOptionsHandler == nil && !configuration.selection.usesForwardActionSheet
    }

    func wy_forwardMenu(_ identifiers: [String]) -> UIMenu {
        let style = configuration.selection
        return UIMenu(children: wy_forwardModes.map { mode in
            let image = mode == .merged ? style.forwardMergedImage : style.forwardIndividualImage
            return UIAction(title: wy_forwardTitle(mode), image: image) { [weak self] _ in
                self?.wy_dispatchForward(identifiers, mode: mode)
            }
        })
    }

    func wy_presentForwardOptions() {
        let identifiers = dataSource.map(\.messageID).filter { selectedMessageIDs.contains($0) }
        let modes = wy_forwardModes
        guard !identifiers.isEmpty, !modes.isEmpty else { return }
        if let handler = forwardOptionsHandler {
            var answered = false
            handler(modes, identifiers, selectionForwardButton) { [weak self] mode in
                let finish = {
                    guard !answered else { return }
                    answered = true
                    if let mode, modes.contains(mode) { self?.wy_dispatchForward(identifiers, mode: mode) }
                }
                if Thread.isMainThread { finish() } else { DispatchQueue.main.async(execute: finish) }
            }
            return
        }
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let presenter = next as? UIViewController {
                guard presenter.presentedViewController == nil else { return }
                let style = configuration.selection
                let title = style.forwardSheetTitle ?? configuration.actionTitle?(.forward) ?? wy_actionTitle(.forward, configuration: configuration)
                let alert = UIAlertController(title: title, message: style.forwardSheetMessage, preferredStyle: .actionSheet)
                alert.view.tintColor = style.forwardSheetTintColor
                for mode in modes {
                    alert.addAction(UIAlertAction(title: wy_forwardTitle(mode), style: .default) { [weak self, weak alert] _ in
                        let forward = { [weak self] in self?.wy_dispatchForward(identifiers, mode: mode) }
                        if alert?.transitionCoordinator?.animate(alongsideTransition: nil, completion: { _ in forward() }) != true {
                            DispatchQueue.main.async { forward() }
                        }
                    })
                }
                alert.addAction(UIAlertAction(title: style.forwardSheetCancelTitle, style: .cancel))
                alert.popoverPresentationController?.sourceView = selectionForwardButton
                alert.popoverPresentationController?.sourceRect = selectionForwardButton.bounds
                presenter.present(alert, animated: true)
                return
            }
            responder = next
        }
    }

    func wy_dispatchForward(_ identifiers: [String], mode: WYChatForwardMode) {
        guard wy_hasForwardHandler, let sources = wy_selectedSources(identifiers),
              configuration.selection.forwardModes.contains(mode),
              sources.allSatisfy({ message in
                  (configuration.allowsAction?(.forward, message) ?? true) &&
                  (eventsHandler?.wy_shouldPerformMessageAction?(self, action: .forward, messageID: message.messageID) ?? true)
              }) else { return }
        if let forwardHandler {
            forwardHandler(mode, sources)
        } else {
            preparedForwardHandler?(mode, wy_makeForwardMessages(from: sources, mode: mode, title: nil))
        }
        if isSelectingMessages { isSelectingMessages = false }
    }

    func wy_refreshSelectionStyle() {
        let style = configuration.selection
        selectionToolbar.backgroundColor = style.backgroundColor
        selectionToolbar.distribution = style.toolbarDistribution
        selectionToolbar.isLayoutMarginsRelativeArrangement = true
        selectionToolbar.layoutMargins = style.insets
        selectionToolbar.spacing = max(0, style.spacing)
        state.selectionHeight?.constant = max(0, style.height)
        for button in [selectionCancelButton, selectionForwardButton, selectionDeleteButton] {
            button.titleLabel?.font = style.font
            button.tintColor = button === selectionDeleteButton ? style.deleteColor : style.tintColor
        }
        selectionCancelButton.isHidden = !style.showsCancelButton
        selectionForwardButton.isHidden = !style.showsForwardButton
        selectionDeleteButton.isHidden = !style.showsDeleteButton
        selectionForwardButton.showsMenuAsPrimaryAction = wy_usesForwardMenu
        selectionForwardButton.menu = wy_usesForwardMenu ? wy_forwardMenu(dataSource.map(\.messageID).filter { selectedMessageIDs.contains($0) }) : nil
    }
}
