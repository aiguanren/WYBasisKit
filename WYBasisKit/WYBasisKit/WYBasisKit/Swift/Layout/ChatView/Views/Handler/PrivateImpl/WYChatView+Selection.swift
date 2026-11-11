//
//  WYChatView+Selection.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 多选区间与转发快照
extension WYChatView {
    func wy_setSelectedMessages(_ identifiers: [String]) -> Bool {
        let selected = Set(identifiers)
        let available = Set(dataSource.map(\.messageID))
        let limit = configuration.selection.maximumCount
        guard selected.isSubset(of: available), limit <= 0 || selected.count <= limit else { return false }
        if !isSelectingMessages { isSelectingMessages = true }
        selectedMessageIDs = selected
        state.selectionAnchorID = identifiers.last
        wy_updateSelectionUI()
        tableView.reloadData()
        return true
    }
    func wy_selectRange(from first: String, through last: String) -> Bool {
        guard configuration.selection.allowsRangeSelection,
              let start = dataSource.firstIndex(where: { $0.messageID == first }),
              let end = dataSource.firstIndex(where: { $0.messageID == last }) else { return false }
        let identifiers = dataSource[min(start, end)...max(start, end)].map(\.messageID)
        let selection = selectedMessageIDs.union(identifiers)
        guard configuration.selection.maximumCount <= 0 || selection.count <= configuration.selection.maximumCount else { return false }
        guard wy_setSelectedMessages(dataSource.map(\.messageID).filter { selection.contains($0) }) else { return false }
        state.selectionAnchorID = first
        return true
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
