//
//  WYChatView+Measurement.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/9.
//

import UIKit

/// 消息在实际列表宽度下的高度
struct WYChatMeasuredHeight {
    let width: CGFloat
    let height: CGFloat
}

/// 消息高度缓存位置
enum WYChatMeasurementKey: Hashable {
    case identifier(String)
    case index(Int)
}

/// 阅读中的消息及其可见位置
struct WYChatReadingAnchor {
    var row: Int
    let distance: CGFloat
    let height: CGFloat
    let width: CGFloat
}

extension WYChatView {
    func wy_cancelAutomaticScroll() {
        state.followsBottom = false
        state.readingAnchor = nil
        state.pendingScrollToBottom = false
        state.scrollRevision += 1
    }

    func wy_captureReadingPosition() {
        guard !state.followsBottom, !state.pendingScrollToBottom, state.readingAnchor == nil,
              let row = tableView.indexPathsForVisibleRows?.min(), dataSource.indices.contains(row.row) else { return }
        state.readingAnchor = wy_readingAnchor(at: row)
    }

    func wy_readingAnchor(at path: IndexPath) -> WYChatReadingAnchor {
        let rect = tableView.rectForRow(at: path)
        return WYChatReadingAnchor(row: path.row, distance: rect.minY - tableView.contentOffset.y, height: rect.height, width: tableView.bounds.width)
    }

    func wy_restoreReadingPosition() {
        guard let anchor = state.readingAnchor, dataSource.indices.contains(anchor.row), tableView.bounds.height > 0,
              let table = tableView as? WYChatMessageTableView else { return }
        let path = IndexPath(row: anchor.row, section: 0)
        if table.indexPathsForVisibleRows?.contains(path) != true { table.wy_scrollInternally(to: path, at: .top, animated: false) }
        let rect = table.rectForRow(at: path)
        let pixel = 1 / max(1, traitCollection.displayScale)
        let clipped = anchor.distance < 0 && anchor.width != table.bounds.width && anchor.height > 0 ? -min(1, -anchor.distance / anchor.height) * rect.height : anchor.distance
        let distance = max(clipped, -max(0, rect.height - pixel))
        let desired = rect.minY - distance
        let maximum = max(-table.adjustedContentInset.top, table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height)
        let offset = min(maximum, max(-table.adjustedContentInset.top, desired))
        if abs(table.contentOffset.y - offset) > pixel {
            table.wy_setOffsetInternally(CGPoint(x: table.contentOffset.x, y: offset))
        }
    }

    func wy_followBottomLayout() {
        guard state.followsBottom, window != nil, !dataSource.isEmpty, tableView.bounds.height > 0 else { return }
        let last = IndexPath(row: dataSource.count - 1, section: 0)
        let bottom = max(-tableView.adjustedContentInset.top, tableView.contentSize.height + tableView.adjustedContentInset.bottom - tableView.bounds.height)
        if tableView.indexPathsForVisibleRows?.contains(last) != true || abs(tableView.contentOffset.y - bottom) > 1 / max(1, traitCollection.displayScale) {
            (tableView as? WYChatMessageTableView)?.wy_scrollInternally(to: last, at: .bottom, animated: false)
        }
    }

    func wy_measurementKey(at indexPath: IndexPath) -> WYChatMeasurementKey {
        state.hasUniqueMessageIDs ? .identifier(dataSource[indexPath.row].messageID) : .index(indexPath.row)
    }

    func wy_cachedHeight(at indexPath: IndexPath) -> CGFloat? {
        guard dataSource.indices.contains(indexPath.row), configuration.customCellClasses.isEmpty,
              let cached = state.measuredHeights[wy_measurementKey(at: indexPath)], cached.width == tableView.bounds.width else { return nil }
        return cached.height
    }

    func wy_prepareBottomMeasurements() {
        guard tableView.bounds.width > 0, tableView.bounds.height > 0, configuration.customCellClasses.isEmpty else { return }
        var remaining = tableView.bounds.height * 2
        for row in dataSource.indices.reversed() {
            let height = wy_heightForMessage(at: IndexPath(row: row, section: 0))
            remaining -= max(1, height)
            if remaining <= 0 { break }
        }
    }

    func wy_heightForMessage(at indexPath: IndexPath) -> CGFloat {
        guard dataSource.indices.contains(indexPath.row), configuration.customCellClasses.isEmpty else { return UITableView.automaticDimension }
        let width = tableView.bounds.width
        guard width > 0 else { return UITableView.automaticDimension }
        let key = wy_measurementKey(at: indexPath)
        if let cached = state.measuredHeights[key], cached.width == width { return cached.height }
        let model = dataSource[indexPath.row]
        let style = model.content.style()
        let cell: WYChatBasicCell
        if let existing = state.measuringCells[style] { cell = existing }
        else {
            cell = style.makeCell()
            cell.state.isMeasuring = true
            cell.isHidden = true
            cell.accessibilityElementsHidden = true
            addSubview(cell)
            state.measuringCells[style] = cell
        }
        cell.bounds.size.width = width
        cell.contentView.bounds.size.width = width
        cell.update(message: model, configuration: configuration.messageConfiguration?(model, configuration) ?? configuration, userID: userInfo.id)
        cell.wy_isSelectingMessages = isSelectingMessages
        cell.wy_updateLayout(width: width)
        let bodyWidth = max(1, min(cell.state.preferredWidth?.constant ?? width, cell.state.width.constant - cell.state.bodyInsets[1].constant + cell.state.bodyInsets[3].constant))
        let bodyHeight = wy_contentHeight(cell.bodyView, width: bodyWidth, cell: cell)
        let bubbleHeight = max(cell.state.contentMinimum.constant, bodyHeight + cell.state.bodyInsets[0].constant - cell.state.bodyInsets[2].constant)
        let top = cell.state.timeHeight.constant + cell.state.timeBottom.constant
        let measured = max(top + cell.state.avatarHeight.constant, top + cell.state.nicknameHeight.constant + cell.state.bubbleTop.constant + bubbleHeight - cell.state.bubbleBottom.constant)
        let scale = max(1, traitCollection.displayScale)
        let height = max(1, ceil(measured * scale) / scale)
        state.measuredHeights[key] = WYChatMeasuredHeight(width: width, height: height)
        return height
    }

    private func wy_contentHeight(_ view: UIView, width: CGFloat, cell: WYChatBasicCell) -> CGFloat {
        if view.isHidden { return 0 }
        if view === cell.state.voiceRateButton { return cell.state.voiceRateHeight?.constant ?? 0 }
        if view === cell.state.reeditButton { return cell.state.reeditHeight?.constant ?? 0 }
        if view === cell.state.mediaToggle { return cell.state.mediaToggleHeight?.constant ?? 0 }
        if view === cell.state.mediaView { return cell.state.mediaView.height(for: width) }
        if view === cell.previewImageView { return cell.state.imageHeight?.constant ?? 0 }
        if view === cell.thumbnailImageView { return cell.state.thumbnailSize[1].constant }
        if let textCell = cell as? WYChatTextCell, view === textCell.textView { return cell.state.textHeight?.constant ?? 0 }
        if let stack = view as? UIStackView {
            let visible = stack.arrangedSubviews.filter { !$0.isHidden }
            let gaps = visible.dropLast().reduce(CGFloat.zero) { sum, child in
                let custom = stack.customSpacing(after: child)
                return sum + (custom == UIStackView.spacingUseDefault || custom == UIStackView.spacingUseSystem || !custom.isFinite ? stack.spacing : custom)
            }
            if stack.axis == .vertical { return visible.reduce(gaps) { $0 + wy_contentHeight($1, width: width, cell: cell) } }
            let thumbnailWidth = visible.contains { $0 === cell.thumbnailImageView } ? cell.state.thumbnailSize[0].constant : 0
            let rateWidth = visible.contains { $0 === cell.state.voiceRateButton } ? cell.state.voiceRateWidth?.constant ?? 0 : 0
            return visible.map { wy_contentHeight($0, width: max(1, width - thumbnailWidth - rateWidth - gaps), cell: cell) }.max() ?? 0
        }
        return view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}
