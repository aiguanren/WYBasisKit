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
        appearance.imagePadding = 6
        button.configuration = appearance
        button.addTarget(self, action: #selector(wy_selectToVisibleMessage), for: .touchUpInside)
        addSubview(button)
        let top = button.topAnchor.constraint(equalTo: tableView.topAnchor)
        let bottom = button.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        let leading = button.leadingAnchor.constraint(equalTo: tableView.leadingAnchor)
        let trailing = button.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor)
        trailing.priority = UILayoutPriority(999)
        state.selectionRangeEdges = (top, bottom, leading, trailing)
        NSLayoutConstraint.activate([bottom, leading, trailing, button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)])
    }

    func wy_refreshRangeSelectionButton() {
        let button = state.selectionRangeButton
        let style = configuration.selection
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
            appearance.background.strokeColor = rangeButton.borderColor ?? rangeButton.tintColor.withAlphaComponent(0.25)
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
              tableView.bounds.height >= 44 + 2 * edges.top.constant,
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
        let content: [WYChatMessageContentModel]
        if mode == .merged { content = [WYChatMessageContentModel(chatRecords: WYChatRecordsModel(title: title ?? configuration.selection.recordsTitle, messages: sources))] }
        else { content = sources.map(\.content) }
        return content.map { value in
            var result = WYChatMessageModel(messageID: UUID().uuidString, timestamp: String(Date().timeIntervalSince1970), sender: userInfo, content: value)
            result.sendState = .sending
            return result
        }
    }
    func wy_forwardMenu(_ identifiers: [String]) -> UIMenu {
        var included = Set<Int>()
        return UIMenu(children: configuration.selection.forwardModes.filter { included.insert($0.rawValue).inserted }.map { mode in
            UIAction(title: mode == .merged ? configuration.selection.mergedTitle : configuration.selection.individualTitle) { [weak self] _ in
                guard let self, let sources = self.wy_selectedSources(identifiers), let handler = self.forwardHandler else { return }
                guard sources.allSatisfy({ self.eventsHandler?.wy_shouldPerformMessageAction?(self, action: .forward, messageID: $0.messageID) ?? true }) else { return }
                handler(mode, sources)
                self.isSelectingMessages = false
            }
        })
    }
    func wy_refreshSelectionStyle() {
        let style = configuration.selection
        selectionToolbar.backgroundColor = style.backgroundColor
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
        selectionForwardButton.showsMenuAsPrimaryAction = forwardHandler != nil
        selectionForwardButton.menu = forwardHandler == nil ? nil : wy_forwardMenu(dataSource.map(\.messageID).filter { selectedMessageIDs.contains($0) })
    }
}
