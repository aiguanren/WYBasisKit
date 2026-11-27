//
//  WYChatMediaGroupCell+Implementation.swift
//  WYBasisKit
//

import UIKit

final class WYChatMediaGroupCellPrivateState {
    let mediaView = WYChatMediaGroupView()
    let mediaToggle = UIButton(type: .system)
    var mediaHeight: NSLayoutConstraint?
    var mediaToggleHeight: NSLayoutConstraint?
}

extension WYChatMediaGroupCell {
    func wy_mediaGroupSetup() {
        bodyView.insertArrangedSubview(mediaGroupState.mediaView, at: 0)
        mediaGroupState.mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaGroupState.mediaView.isHidden = true
        mediaGroupState.mediaHeight = mediaGroupState.mediaView.heightAnchor.constraint(equalToConstant: 0)
        mediaGroupState.mediaHeight?.priority = UILayoutPriority(999)
        mediaGroupState.mediaHeight?.isActive = true
        contentView.addSubview(mediaGroupState.mediaToggle)
        mediaGroupState.mediaToggle.isHidden = true
        mediaGroupState.mediaToggle.accessibilityIdentifier = "WYChatMedia.toggle"
        mediaGroupState.mediaToggle.addTarget(self, action: #selector(wy_toggleMediaGroup), for: .touchUpInside)
        mediaGroupState.mediaToggleHeight = mediaGroupState.mediaToggle.heightAnchor.constraint(equalToConstant: 0)
        mediaGroupState.mediaToggleHeight?.priority = UILayoutPriority(999)
    }

    func wy_mediaGroupReset() {
        mediaGroupState.mediaView.isHidden = true
        mediaGroupState.mediaToggle.isHidden = true
        mediaGroupState.mediaHeight?.constant = 0
    }

    func wy_mediaGroupLayout(width: CGFloat) {
        guard message.content.mediaGroup != nil else { return }
        let contentWidth = max(1, min(state.preferredWidth?.constant ?? state.width.constant, width))
        mediaGroupState.mediaHeight?.constant = mediaGroupState.mediaView.height(for: contentWidth)
    }

    func wy_mediaGroupMeasure(_ view: UIView, width: CGFloat) -> CGSize? {
        if view === mediaGroupState.mediaToggle { return CGSize(width: 0, height: mediaGroupState.mediaToggleHeight?.constant ?? 0) }
        if view === mediaGroupState.mediaView { return CGSize(width: 0, height: mediaGroupState.mediaView.height(for: width)) }
        return nil
    }

    func wy_mediaGroupUpdateItemTransferProgress(visible: Bool) -> Bool {
        mediaGroupState.mediaView.setTransferProgressVisible(visible)
        return message.content.mediaGroup?.items.contains { $0.transferState != .automatic } ?? false
    }

    func wy_updateMediaPage(_ model: WYChatMessageModel, at index: Int) {
        state.isUpdating = true
        message = model
        state.isUpdating = false
        mediaGroupState.mediaView.updatePage(index)
    }

    func wy_mediaGroupRender() {
        guard let group = message.content.mediaGroup else { return }
        state.title.isHidden = true
        mediaGroupState.mediaView.isHidden = false
        let sender = message.isSender(userID)
        let side = sender ? configuration.sender : configuration.receiver
        mediaGroupState.mediaView.configure(group, configuration: configuration.media, contentConfiguration: messageContentConfiguration, avatarConfiguration: configuration.basic, avatar: message.sender.avatar, avatarSize: side.showsAvatar ? configuration.basic.avatarSize : .zero, avatarSpacing: side.contentSpacing, sender: sender, measuring: state.isMeasuring) { [weak self] asset, image, isPhoto, loadsRemoteImage in
            self?.wy_loadImage(asset, into: image, isPhoto: isPhoto, loadsRemoteImage: loadsRemoteImage)
        }
        mediaGroupState.mediaView.transferTitle = configuration.actionTitle
        mediaGroupState.mediaView.transferAction = { [weak self] action, id in
            guard let self else { return }
            self.state.mediaTransferHandler?(action, self.message.messageID, id)
        }
        mediaGroupState.mediaView.avatarAction = { [weak self] action in self?.wy_avatarAction(action) }
        let identifier = message.messageID
        mediaGroupState.mediaView.action = { [weak self] action, index in self?.mediaActionHandler?(action, identifier, index) }
        state.preferredWidth?.constant = max(1, configuration.media.cardSize.width)
        mediaGroupState.mediaToggle.isHidden = group.items.count < 2
        let title = group.isExpanded ? configuration.media.collapseText : configuration.media.expandText
        let media = configuration.media
        let count = group.items.count
        let buttonTitle = media.showsItemCountInButton ? (media.itemCountText?(title, count) ?? "\(title) (\(count))") : title
        mediaGroupState.mediaToggle.setTitle(buttonTitle, for: .normal)
        mediaGroupState.mediaToggle.titleLabel?.font = configuration.media.buttonFont
        mediaGroupState.mediaToggle.setTitleColor(configuration.media.buttonColor, for: .normal)
        mediaGroupState.mediaToggle.backgroundColor = configuration.media.buttonBackgroundColor
        mediaGroupState.mediaToggle.layer.cornerRadius = max(0, configuration.media.buttonCornerRadius)
        let below = configuration.media.buttonPlacement == .below
        mediaGroupState.mediaToggleHeight?.isActive = below
        mediaGroupState.mediaToggle.translatesAutoresizingMaskIntoConstraints = !below
        if below {
            if mediaGroupState.mediaToggle.superview !== bodyView { bodyView.insertArrangedSubview(mediaGroupState.mediaToggle, at: min(1, bodyView.arrangedSubviews.count)) }
        } else if mediaGroupState.mediaToggle.superview !== contentView {
            bodyView.removeArrangedSubview(mediaGroupState.mediaToggle)
            mediaGroupState.mediaToggle.removeFromSuperview()
            contentView.addSubview(mediaGroupState.mediaToggle)
        }
        mediaGroupState.mediaToggleHeight?.constant = max(1, configuration.media.buttonHeight)
        bodyView.spacing = max(0, configuration.media.buttonSpacing)
    }
}

/// 展开按钮的布局与事件。
extension WYChatMediaGroupCell {
    func wy_layoutMediaToggle() {
        guard !mediaGroupState.mediaToggle.isHidden, configuration.media.buttonPlacement == .beside else { return }
        let config = configuration.media
        let bounds = contentView.bounds
        let mediaFrame = mediaGroupState.mediaView.convert(mediaGroupState.mediaView.bounds, to: contentView)
        let center = mediaGroupState.mediaView.convert(CGPoint(x: 0, y: mediaGroupState.mediaView.firstItemCenterY), to: contentView).y
        let sender = message.isSender(userID)
        let bubbleIsOnRight = sender == (contentView.effectiveUserInterfaceLayoutDirection == .leftToRight)
        let inset = wy_chatNonnegative(sender ? configuration.sender.edgeInset : configuration.receiver.edgeInset)
        let selectionWidth = wy_selectionIndicatorWidth
        let left = min(bounds.width, inset + (wy_selectionIndicatorIsOnLeft ? selectionWidth : 0))
        let right = max(left, bounds.width - inset - (wy_selectionIndicatorIsOnLeft ? 0 : selectionWidth))
        let width = min(right - left, wy_chatNonnegative(config.buttonWidth))
        let height = min(bounds.height, wy_chatNonnegative(config.buttonHeight))
        let spacing = wy_chatNonnegative(config.buttonSpacing)
        let x = bubbleIsOnRight ? mediaFrame.minX - spacing - width : mediaFrame.maxX + spacing
        let y = min(bounds.height - height, max(0, center - height / 2))
        var frame = CGRect(x: min(right - width, max(left, x)), y: y, width: width, height: height)

        if sender && (!loadingView.isHidden || activityView.isAnimating) {
            let indicator: UIView = loadingView.isHidden ? activityView : loadingView
            let statusFrame = indicator.convert(indicator.bounds, to: contentView)
            let gap = wy_chatNonnegative(config.buttonSendingStatusSpacing)
            let exclusion = statusFrame.insetBy(dx: -gap, dy: -gap)
            if !statusFrame.isEmpty && frame.intersects(exclusion) {
                let besideX = bubbleIsOnRight ? exclusion.minX - width : exclusion.maxX
                if besideX >= left && besideX + width <= right {
                    frame.origin.x = besideX
                } else {
                    let roomAbove = max(0, statusFrame.minY)
                    let roomBelow = max(0, bounds.height - statusFrame.maxY)
                    let room = max(roomAbove, roomBelow)
                    let verticalGap = min(gap, max(0, room - height))
                    frame.size.height = min(height, room - verticalGap)
                    frame.origin.y = roomAbove >= roomBelow
                        ? statusFrame.minY - verticalGap - frame.height
                        : statusFrame.maxY + verticalGap
                }
            }
        }
        mediaGroupState.mediaToggle.frame = frame
    }

    @objc func wy_toggleMediaGroup() {
        guard let group = message.content.mediaGroup else { return }
        let index = min(max(0, group.visibleIndex), max(0, group.items.count - 1))
        mediaActionHandler?(group.isExpanded ? .collapse : .expand, message.messageID, index)
    }
}

extension WYChatMediaGroupCell {
    var mediaView: WYChatMediaGroupView { mediaGroupState.mediaView }
}
