//
//  WYChatBasicCell+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/8.
//

import UIKit
import Kingfisher

/// 随消息实际尺寸调整箭头位置与安全尺寸
final class WYChatBubbleView: WYAirBubbleView {
    var configuredRadius: CGFloat = 0
    var configuredArrow: CGSize = .zero
    var configuredShowsArrow = false
    var configuredOffset: CGFloat = 0
    var configuredPadding: CGFloat = 0
    var alignmentFromTop: CGFloat?

    override func layoutSubviews() {
        let width = max(0, bounds.width)
        let height = max(0, bounds.height)
        let base = configuredArrow.width.isFinite ? max(0, configuredArrow.width) : 0
        let protrusion = configuredArrow.height.isFinite ? max(0, configuredArrow.height) : 0
        let hasArrow = configuredShowsArrow && width > protrusion && height > base
        let radiusLimit = max(0, min(width - (hasArrow ? protrusion : 0), height - (hasArrow ? base : 0)) / 2)
        let radius = min(configuredRadius.isFinite ? max(0, configuredRadius) : 0, radiusLimit)
        cornerRadius = radius
        showsArrow = hasArrow
        arrowSize = hasArrow ? CGSize(width: base, height: protrusion) : .zero
        let space = max(0, height - radius * 2 - base)
        arrowEdgePadding = hasArrow ? min(configuredPadding.isFinite ? max(0, configuredPadding) : 0, space) : 0
        let offset = (alignmentFromTop.map { $0 - height / 2 } ?? 0) + (configuredOffset.isFinite ? configuredOffset : 0)
        let limit = max(0, space - arrowEdgePadding)
        arrowOffset = hasArrow ? min(limit, max(-limit, offset)) : 0
        super.layoutSubviews()
    }
}

/// 消息公共布局与内容视图
final class WYChatBasicCellPrivateState {
    var left: [NSLayoutConstraint] = []
    var right: [NSLayoutConstraint] = []
    var common: [NSLayoutConstraint] = []
    var center: NSLayoutConstraint!
    var width: NSLayoutConstraint!
    var avatarWidth: NSLayoutConstraint!
    var avatarHeight: NSLayoutConstraint!
    var nicknameHeight: NSLayoutConstraint!
    var timeHeight: NSLayoutConstraint!
    var timeBottom: NSLayoutConstraint!
    var bodyInsets: [NSLayoutConstraint] = []
    var bubbleTop: NSLayoutConstraint!
    var bubbleBottom: NSLayoutConstraint!
    var statusWidth: NSLayoutConstraint!
    var statusHeight: NSLayoutConstraint!
    var contentMinimum: NSLayoutConstraint!
    var isSender: Bool? = nil
    var isUpdating = false
    var isReady: Bool = false
    let header = UIStackView()
    let textStack = UIStackView()
    let thumbnail = UIImageView()
    var thumbnailSize: [NSLayoutConstraint] = []
    let title = UILabel()
    let detail = UILabel()
    let image = UIImageView()
    let footer = UILabel()
    var imageHeight: NSLayoutConstraint?
    var preferredWidth: NSLayoutConstraint?
}

extension WYChatBasicCell {
    func wy_setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        bodyView.axis = .vertical
        bodyView.alignment = .fill
        bodyView.isLayoutMarginsRelativeArrangement = false
        for view in [timeView, avatarView, nicknameView, bubblesView, loadingView, activityView, readMarkView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bubblesView.addSubview(bodyView)
        for label in [state.title, state.detail, state.footer, referenceView] { label.numberOfLines = 0 }
        state.image.contentMode = .scaleAspectFill
        state.image.clipsToBounds = true
        state.header.axis = .horizontal
        state.header.alignment = .center
        state.textStack.axis = .vertical
        state.thumbnail.contentMode = .scaleAspectFit
        state.thumbnail.clipsToBounds = true
        state.thumbnail.translatesAutoresizingMaskIntoConstraints = false
        state.thumbnailSize = [state.thumbnail.widthAnchor.constraint(equalToConstant: configuration.basic.avatarSize.width), state.thumbnail.heightAnchor.constraint(equalToConstant: configuration.basic.avatarSize.height)]
        NSLayoutConstraint.activate(state.thumbnailSize)
        state.header.addArrangedSubview(state.thumbnail)
        for label in [state.title, state.detail, state.footer] { state.textStack.addArrangedSubview(label) }
        state.header.addArrangedSubview(state.textStack)
        bodyView.addArrangedSubview(state.image)
        bodyView.addArrangedSubview(state.header)
        bodyView.addArrangedSubview(referenceView)
        state.image.translatesAutoresizingMaskIntoConstraints = false
        state.imageHeight = state.image.heightAnchor.constraint(equalToConstant: 0)
        state.imageHeight?.isActive = true
        state.preferredWidth = bodyView.widthAnchor.constraint(equalToConstant: 240)
        state.preferredWidth?.priority = .defaultHigh
        state.preferredWidth?.isActive = true
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        nicknameView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wy_avatarTap)))
        nicknameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wy_nicknameTap)))
        bubblesView.isUserInteractionEnabled = true
        bubblesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(wy_contentTap)))
        loadingView.addTarget(self, action: #selector(wy_retryTap), for: .touchUpInside)
        state.avatarWidth = avatarView.widthAnchor.constraint(equalToConstant: 40)
        state.avatarHeight = avatarView.heightAnchor.constraint(equalToConstant: 40)
        state.timeHeight = timeView.heightAnchor.constraint(equalToConstant: 0)
        state.nicknameHeight = nicknameView.heightAnchor.constraint(equalToConstant: 0)
        state.timeBottom = avatarView.topAnchor.constraint(equalTo: timeView.bottomAnchor)
        state.bubbleTop = bubblesView.topAnchor.constraint(equalTo: nicknameView.bottomAnchor)
        state.bubbleBottom = bubblesView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        state.center = bubblesView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        state.width = bubblesView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        state.statusWidth = loadingView.widthAnchor.constraint(equalToConstant: 20)
        state.statusHeight = loadingView.heightAnchor.constraint(equalToConstant: 20)
        state.contentMinimum = bubblesView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        state.common = [
            timeView.topAnchor.constraint(equalTo: contentView.topAnchor), timeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            state.timeHeight, state.avatarWidth, state.avatarHeight, state.timeBottom, state.nicknameHeight,
            nicknameView.topAnchor.constraint(equalTo: avatarView.topAnchor), state.bubbleTop, state.bubbleBottom, state.width, state.contentMinimum,
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            loadingView.centerYAnchor.constraint(equalTo: bubblesView.centerYAnchor), state.statusWidth, state.statusHeight,
            activityView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor), activityView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            readMarkView.bottomAnchor.constraint(equalTo: bubblesView.bottomAnchor), readMarkView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor)
        ]
        state.bodyInsets = [bodyView.topAnchor.constraint(equalTo: bubblesView.topAnchor), bodyView.leadingAnchor.constraint(equalTo: bubblesView.leadingAnchor), bodyView.bottomAnchor.constraint(equalTo: bubblesView.bottomAnchor), bodyView.trailingAnchor.constraint(equalTo: bubblesView.trailingAnchor)]
        state.left = [avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), bubblesView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor), nicknameView.leadingAnchor.constraint(equalTo: bubblesView.leadingAnchor), nicknameView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor), loadingView.leadingAnchor.constraint(equalTo: bubblesView.trailingAnchor)]
        state.right = [avatarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), bubblesView.trailingAnchor.constraint(equalTo: avatarView.leadingAnchor), nicknameView.trailingAnchor.constraint(equalTo: bubblesView.trailingAnchor), nicknameView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor), loadingView.trailingAnchor.constraint(equalTo: bubblesView.leadingAnchor)]
        NSLayoutConstraint.activate(state.common + state.bodyInsets)
        state.isReady = true
        wy_render()
    }

    func wy_render() {
        guard state.isReady, !state.isUpdating else { return }
        let basic = configuration.basic
        let sender = message.isSender(userID)
        let side = sender ? configuration.sender : configuration.receiver
        timeView.font = basic.timeFont
        timeView.textColor = basic.timeColor
        timeView.text = basic.timeFormatter?(message) ?? message.timeFormat ?? wy_timeText()
        timeView.textAlignment = .center
        nicknameView.text = message.sender.name
        nicknameView.font = basic.nicknameFont
        nicknameView.textColor = basic.nicknameColor
        nicknameView.textAlignment = sender ? .right : .left
        nicknameView.isHidden = !(message.group == nil ? side.showsSingleNickname : side.showsGroupNickname)
        avatarView.isHidden = !side.showsAvatar || wy_isNotice
        avatarView.contentMode = basic.avatarContentMode
        avatarView.layer.cornerRadius = max(0, basic.avatarCornerRadius)
        wy_loadImage(message.sender.avatar, into: avatarView)
        let style = messageContentConfiguration
        state.title.font = style.titleFont
        state.title.textColor = style.titleColor
        state.title.numberOfLines = max(0, style.titleNumberOfLines)
        state.detail.font = style.detailFont
        state.detail.textColor = style.detailColor
        state.detail.numberOfLines = max(0, style.detailNumberOfLines)
        state.footer.font = style.detailFont
        state.footer.textColor = style.detailColor
        bodyView.spacing = max(0, style.spacing)
        state.textStack.spacing = max(0, style.spacing)
        state.header.spacing = max(0, style.spacing)
        state.thumbnail.isHidden = true
        state.thumbnailSize[0].constant = max(0, configuration.basic.avatarSize.width)
        state.thumbnailSize[1].constant = max(0, configuration.basic.avatarSize.height)
        state.title.textAlignment = .natural
        state.title.isHidden = false
        state.title.text = nil
        state.detail.text = nil
        state.footer.text = nil
        state.image.isHidden = true
        state.imageHeight?.constant = 0
        state.preferredWidth?.isActive = true
        referenceView.font = style.detailFont
        referenceView.textColor = style.detailColor
        referenceView.text = message.reference.map { "↪ " + $0.wy_summary }
        referenceView.isHidden = message.reference == nil
        renderContent()
        if message.isTransferring {
            let progress = message.transferProgress.isFinite ? min(1, max(0, message.transferProgress)) : 0
            state.footer.text = String(format: "%.0f%%", progress * 100)
        } else if !message.transferError.isEmpty {
            state.footer.text = message.transferError
        }
        state.detail.isHidden = state.detail.text?.isEmpty ?? true
        state.footer.isHidden = state.footer.text?.isEmpty ?? true
        state.header.isHidden = state.title.isHidden && state.detail.isHidden && state.footer.isHidden && state.thumbnail.isHidden
        wy_applyBubble(sender ? configuration.senderBubble : configuration.receiverBubble)
        loadingView.setImage(message.sendState == .notSent ? basic.messagePendingImage : basic.messageSendErrorImage, for: .normal)
        loadingView.tintColor = message.sendState == .notSent ? basic.messagePendingColor : basic.messageSendErrorColor
        loadingView.isUserInteractionEnabled = message.sendState == .failed
        activityView.color = basic.messageSendingColor
        loadingView.isHidden = !sender || (message.sendState != .failed && message.sendState != .notSent) || wy_isNotice
        if sender && message.sendState == .sending && !wy_isNotice { activityView.startAnimating() } else { activityView.stopAnimating() }
        readMarkView.isHidden = !sender || !basic.showReadMark || message.sendState != .success || wy_isNotice
        readMarkView.text = (Double(message.readers) ?? 0) > 0 ? basic.readText : basic.unreadText
        readMarkView.font = basic.readMarkFont
        readMarkView.textColor = basic.readMarkColor
        setNeedsLayout()
    }

    var wy_isNotice: Bool { message.content.style() == .withdrawn || message.content.style() == .takePat }

    func wy_updateLayout() {
        guard state.isReady else { return }
        let sender = message.isSender(userID)
        let side = sender ? configuration.sender : configuration.receiver
        let basic = configuration.basic
        if state.isSender != sender {
            NSLayoutConstraint.deactivate(state.left + state.right)
            NSLayoutConstraint.activate(sender ? state.right : state.left)
            state.isSender = sender
        }
        let active = sender ? state.right : state.left
        active[1].isActive = !wy_isNotice
        state.center.isActive = wy_isNotice
        let sign: CGFloat = sender ? -1 : 1
        let avatarWidth = avatarView.isHidden ? 0 : max(0, basic.avatarSize.width)
        let avatarHeight = avatarView.isHidden ? 0 : max(0, basic.avatarSize.height)
        state.avatarWidth.constant = avatarWidth
        state.avatarHeight.constant = avatarHeight
        state.left[0].constant = max(0, configuration.receiver.edgeInset)
        state.right[0].constant = -max(0, configuration.sender.edgeInset)
        let gap = avatarWidth > 0 ? max(0, side.contentSpacing) : 0
        (sender ? state.right : state.left)[1].constant = sign * gap
        (sender ? state.right : state.left)[4].constant = sign * basic.messageSendingStateOffset
        state.statusWidth.constant = max(0, basic.messageSendingStateSize.width)
        state.statusHeight.constant = max(0, basic.messageSendingStateSize.height)
        let timeHeight: CGFloat = (timeView.text?.isEmpty ?? true) ? 0 : basic.timeFont.lineHeight + max(0, basic.timeViewOffset)
        state.timeHeight.constant = timeHeight
        state.timeBottom.constant = max(0, configuration.messageSpacing / 2)
        let nicknameHeight = nicknameView.isHidden || wy_isNotice ? 0 : basic.nicknameFont.lineHeight + max(0, configuration.nicknameSpacing)
        state.nicknameHeight.constant = nicknameHeight
        state.bubbleTop.constant = side.contentTopOffset
        state.bubbleBottom.constant = -max(0, configuration.messageSpacing / 2)
        state.contentMinimum.constant = wy_isNotice ? 0 : max(0, avatarHeight - nicknameHeight)
        let style = messageContentConfiguration
        let ratio = style.maximumWidthRatio.isFinite ? min(1, max(0.1, style.maximumWidthRatio)) : 0.75
        let available = max(1, contentView.bounds.width - max(0, side.edgeInset) * 2 - avatarWidth - gap - max(0, basic.messageSendingStateOffset) - max(0, basic.messageSendingStateSize.width))
        state.width.constant = style.maximumWidth > 0 && style.maximumWidth.isFinite ? min(available, style.maximumWidth) : max(1, available * ratio)
        state.preferredWidth?.constant = max(1, min(style.preferredWidth, state.width.constant - style.insets.left - style.insets.right))
        if let cell = self as? WYChatTextCell {
            let padding = max(0, style.insets.left) + max(0, style.insets.right) + (bubblesView.showsArrow ? max(0, bubblesView.arrowSize.height) : 0)
            let maximum = max(1, state.width.constant - padding)
            let rect = cell.textView.attributedText.boundingRect(with: CGSize(width: maximum, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            state.preferredWidth?.constant = min(maximum, max(1, ceil(rect.width)))
        }
        let arrow = bubblesView.showsArrow ? max(0, bubblesView.arrowSize.height) : 0
        state.bodyInsets[0].constant = max(0, style.insets.top)
        state.bodyInsets[1].constant = max(0, style.insets.left) + (sender ? 0 : arrow)
        state.bodyInsets[2].constant = -max(0, style.insets.bottom)
        state.bodyInsets[3].constant = -max(0, style.insets.right) - (sender ? arrow : 0)
        let bubbleConfig = sender ? configuration.senderBubble : configuration.receiverBubble
        (bubblesView as? WYChatBubbleView)?.alignmentFromTop = bubbleConfig.alignsArrowWithAvatar && !wy_isNotice ? max(0, basic.avatarSize.height / 2 - nicknameHeight - side.contentTopOffset) : nil
    }

    func wy_applyBubble(_ value: WYChatBubbleConfig) {
        let show = messageContentConfiguration.showsBubble && !wy_isNotice
        if let bubble = bubblesView as? WYChatBubbleView {
            bubble.configuredRadius = value.cornerRadius
            bubble.configuredArrow = value.arrowSize
            bubble.configuredShowsArrow = show && value.showsArrow
            bubble.configuredOffset = value.arrowOffset
            bubble.configuredPadding = value.arrowEdgePadding
        }
        bubblesView.fillColor = show ? value.fillColor : .clear
        bubblesView.cornerRadius = value.cornerRadius
        bubblesView.cornersPosition = value.cornersPosition
        bubblesView.showsArrow = show && value.showsArrow
        bubblesView.arrowDirection = message.isSender(userID) ? .right : .left
        bubblesView.arrowSize = value.arrowSize
        bubblesView.arrowOffset = value.arrowOffset
        bubblesView.arrowEdgePadding = value.arrowEdgePadding
        bubblesView.arrowTipRadius = value.arrowTipRadius
        bubblesView.borderColor = show ? value.borderColor : .clear
        bubblesView.borderWidth = show ? value.borderWidth : 0
        bubblesView.gradientColors = show ? value.gradientColors : []
        bubblesView.gradientDirection = value.gradientDirection
        bubblesView.shadowColor = show ? value.shadowColor : nil
        bubblesView.shadowOffset = value.shadowOffset
        bubblesView.shadowRadius = value.shadowRadius
        bubblesView.shadowOpacity = value.shadowOpacity
    }

    func wy_loadImage(_ asset: WYChatAssetsModel, into imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
        imageView.image = imageView === avatarView ? configuration.basic.defaultAvatar : messageContentConfiguration.placeholderImage
        if let loader = configuration.imageLoader { loader(asset, imageView, message.messageID); return }
        if !asset.localPath.isEmpty, let image = UIImage(contentsOfFile: asset.localPath) { imageView.image = image; return }
        guard let url = URL(string: asset.downloadPath), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return }
        imageView.kf.setImage(with: url, placeholder: imageView.image)
    }

    func wy_timeText() -> String {
        guard var timestamp = Double(message.timestamp), timestamp.isFinite else { return "" }
        if timestamp > 100_000_000_000 { timestamp /= 1000 }
        if var previous = Double(message.lastMessageTimestamp), previous.isFinite {
            if previous > 100_000_000_000 { previous /= 1000 }
            if timestamp - previous < max(0, configuration.basic.messageMinimumTimeSpan) { return "" }
        }
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = configuration.basic.showAmPmSymbol ? "a h:mm" : "HH:mm"
        let time = formatter.string(from: date)
        if calendar.isDateInToday(date) { return time }
        if calendar.isDateInYesterday(date) { return WYLocalized("昨天", table: WYBasisKitConfig.kitLocalizableTable) + " " + time }
        if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days >= 0 && days < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date) + " " + time
        }
        formatter.setLocalizedDateFormatFromTemplate(calendar.component(.year, from: date) == calendar.component(.year, from: Date()) ? "MMMd" : "yyyyMMMd")
        return formatter.string(from: date) + " " + time
    }

    func wy_prepareForReuse() {
        avatarView.kf.cancelDownloadTask()
        state.image.kf.cancelDownloadTask()
        state.thumbnail.kf.cancelDownloadTask()
        activityView.stopAnimating()
        actionHandler = nil
        isMessageSelected = false
    }

    @objc func wy_avatarTap() { actionHandler?(.avatar, message.messageID) }
    @objc func wy_nicknameTap() { actionHandler?(.nickname, message.messageID) }
    @objc func wy_contentTap() { actionHandler?(.content, message.messageID) }
    @objc func wy_retryTap() { actionHandler?(.retry, message.messageID) }
}
