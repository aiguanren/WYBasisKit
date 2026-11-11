//
//  WYChatTestAdvancedConfigurationChecks.swift
//  SwiftVerify
//
//  Created by guanren on 2026/11/11.
//

import UIKit

/// 外部资源回调和组合配置的实际调用检查
@MainActor
enum WYChatTestAdvancedConfigurationChecks {
    static var toastFields: [WYChatTestConfigurationField] {
        let prefix = "media.browser.appearance.toastConfig."
        let fields: [WYChatTestConfigurationField] = [
            .color(prefix + "backgroundColor", "提示背景色", get: { ($0.media.browser.appearance.toastConfig ?? WYActivityConfig.info).backgroundColor }, set: { config, color in
                var value = config.media.browser.appearance.toastConfig ?? WYActivityConfig.info
                value.backgroundColor = color
                config.media.browser.appearance.toastConfig = value
            }),
            .color(prefix + "textColor", "提示文字颜色", get: { ($0.media.browser.appearance.toastConfig ?? WYActivityConfig.info).textColor }, set: { config, color in
                var value = config.media.browser.appearance.toastConfig ?? WYActivityConfig.info
                value.textColor = color
                config.media.browser.appearance.toastConfig = value
            }),
            .font(prefix + "textFont", "提示文字字体", get: { ($0.media.browser.appearance.toastConfig ?? WYActivityConfig.info).textFont }, set: { config, font in
                var value = config.media.browser.appearance.toastConfig ?? WYActivityConfig.info
                value.textFont = font
                config.media.browser.appearance.toastConfig = value
            })
        ]
        return fields.map { field in
            var result = field
            result.clear = { $0.media.browser.appearance.toastConfig = nil }
            result.clearTitle = "使用默认提示"
            return result
        }
    }

    static func run(source: WYChatView) async -> [WYChatTestResult] {
        var checks: [WYChatTestResult] = []
        func check(_ name: String, _ passed: Bool) { checks.append(WYChatTestResult(name: name, passed: passed, detail: "", milliseconds: 0)) }
        var toastConfig = WYChatConfig()
        check("advanced-toast-inherits-global", toastFields.last?.read(toastConfig).contains(String(Double(WYActivityConfig.info.textFont.pointSize))) == true)
        for field in toastFields {
            let value = field.path.hasSuffix("textFont") ? "22" : "#C653AD"
            check("advanced-toast-edit-" + field.path, field.apply?(&toastConfig, value) == true && toastConfig.media.browser.appearance.toastConfig != nil)
        }
        toastFields.first?.clear?(&toastConfig)
        check("advanced-toast-clear", toastConfig.media.browser.appearance.toastConfig == nil)
        let image = UIImage(systemName: "star.fill")!
        var loadedIDs: [String] = []
        var configuredIDs: [String] = []
        var config = WYChatConfig()
        config.input.draftStorageKey = ""
        config.basic.timeFormatter = { _ in "自定义时间" }
        config.imageLoader = { _, target, identifier in loadedIDs.append(identifier); target.image = image }
        config.messageConfiguration = { message, original in
            configuredIDs.append(message.messageID)
            var changed = original
            changed.content.titleFont = .systemFont(ofSize: 23)
            changed.content.preferredWidth = 141
            return changed
        }
        let view = WYChatView(userInfo: source.userInfo, configuration: config)
        view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
        let host = source.window ?? source
        host.addSubview(view)
        defer { view.releaseAll(); view.removeFromSuperview() }
        let message = WYChatMessageModel(messageID: "advanced-photo", timestamp: String(Date().timeIntervalSince1970), sender: WYChatUserModel(id: "advanced-other"), content: WYChatMessageContentModel(photo: WYChatPhotoModel()))
        view.dataSource = [message]
        view.layoutIfNeeded()
        view.tableView.layoutIfNeeded()
        let cell = view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? WYChatBasicCell
        check("advanced-message-configuration", configuredIDs.contains(message.messageID) && cell?.configuration.content.titleFont.pointSize == 23 && view.configuration.content.titleFont.pointSize != 23)
        check("advanced-image-loader", loadedIDs.contains(message.messageID) && cell?.previewImageView.image === image)
        check("advanced-time-formatter", cell?.timeView.text == "自定义时间")
        check("advanced-message-style-members", WYChatMessageStyle.members() == Array(WYChatMessageStyle.allCases))

        var emojiLoads: [String] = []
        var emojiConfig = WYEmojiViewConfig()
        emojiConfig.customImageLoader = { name, _ in emojiLoads.append(name); return image }
        check("advanced-emoji-image-loader", emojiConfig.staticEmojiImage("[配置表情]") === image && emojiLoads == ["[配置表情]"])
        emojiConfig.emojiFolders = true
        emojiConfig.emojiBundle = WYSourceBundle(targetClass: WYChatView.self, bundleName: "ConfigurationTest", subdirectory: "Emoji")
        check("advanced-emoji-source-folder", emojiConfig.emojiSourceBundle(for: "[配置表情]")?.subdirectory == "Emoji/配置表情")
        emojiConfig.emojiFolders = false
        check("advanced-emoji-source-flat", emojiConfig.emojiSourceBundle(for: "[配置表情]")?.subdirectory == "Emoji")
        var iconNames: [String] = []
        var moreConfig = WYMoreViewConfig()
        moreConfig.moreSource = (0..<20).map { ["入口\($0)": "icon-\($0)"] }
        moreConfig.imageProvider = { name in iconNames.append(name); return image }
        let more = WYChatMoreView(config: moreConfig)
        more.frame = CGRect(x: 0, y: 0, width: 393, height: moreConfig.contentHeight())
        host.addSubview(more)
        defer { more.removeFromSuperview() }
        more.layoutIfNeeded()
        more.collectionView.layoutIfNeeded()
        let moreCell = more.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        @MainActor func descendants(_ root: UIView) -> [UIView] { root.subviews + root.subviews.flatMap { descendants($0) } }
        check("advanced-more-image-provider", iconNames.contains("icon-0") && (moreCell.map { descendants($0) } ?? []).compactMap { $0 as? UIImageView }.contains { $0.image === image })
        more.updatePageControl(defaultColor: .systemOrange, currentColor: .systemPurple)
        more.updatePageControl(defaultImage: image, currentImage: image)
        await Task.yield()
        check("advanced-more-page-colors", more.pageControl?.pageIndicatorTintColor == .systemOrange && more.pageControl?.currentPageIndicatorTintColor == .systemPurple)
        check("advanced-more-page-images", more.pageControl?.indicatorImage(forPage: 0) === image)
        if let page = more.pageControl {
            page.currentPage = min(1, page.numberOfPages - 1)
            more.switchCurrentPage(page)
            try? await Task.sleep(nanoseconds: 400_000_000)
            check("advanced-more-page-switch", abs(more.collectionView.contentOffset.x - CGFloat(page.currentPage) * more.bounds.width) < 1)
            more.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            more.scrollViewDidEndDecelerating(more.collectionView)
            check("advanced-more-page-settled", page.currentPage == 0)
        } else { check("advanced-more-page-created", false) }
        moreConfig.scrollDirection = .vertical
        more.moreViewConfig = moreConfig
        more.layoutIfNeeded()
        check("advanced-more-layout-direction", (more.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .vertical)


        let events = WYChatTestAdvancedEvents()
        view.delegate = events
        view.eventsHandler = events
        events.allowScroll = false
        view.scrollViewDidScroll(view.tableView)
        check("advanced-scroll-event-veto", events.scrolls == 0)
        events.allowScroll = true
        view.scrollViewDidScroll(view.tableView)
        check("advanced-scroll-event-forwarding", events.scrolls == 1)
        let custom = UITableViewCell(style: .default, reuseIdentifier: nil)
        custom.textLabel?.text = "Custom cell"
        events.cell = custom
        var managed = view.configuration
        managed.customCellClasses = [UITableViewCell.self]
        view.configuration = managed
        view.tableView.reloadData()
        view.tableView.layoutIfNeeded()
        check("advanced-custom-cell-event", view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) === custom)
        events.cell = nil
        view.tableView.reloadData()
        view.tableView.layoutIfNeeded()
        check("advanced-custom-cell-default", view.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) is WYChatBasicCell)
        let text = view.chatInput.textView
        let clipboard = UIPasteboard.general.items
        defer { UIPasteboard.general.items = clipboard }
        text.text = "复制[微笑]"
        view.chatInput.textViewDidChange(text, silence: true)
        let original = view.chatInput.sharedEmojiAttributedText(attributed: text.attributedText).string
        text.selectedRange = NSRange(location: 0, length: text.attributedText.length)
        text.copy(nil)
        check("advanced-input-copy-attachments", UIPasteboard.general.string == original)
        text.selectedRange = NSRange(location: text.attributedText.length, length: 0)
        text.paste(nil)
        check("advanced-input-paste-attachments", view.chatInput.sharedEmojiAttributedText(attributed: text.attributedText).string == original + original)
        view.chatInput.textViewDidChange(text)
        view.inputViewResignFirstResponder()
        return checks
    }
}

/// 自定义消息Cell与滚动接管检查
private final class WYChatTestAdvancedEvents: NSObject, WYChatViewDelegate, WYChatViewEventsHandler {
    var allowScroll = true
    var scrolls = 0
    var cell: UITableViewCell?
    func wy_canManagerScrollViewDidScrollEvents(_ scrollView: UIScrollView) -> Bool { allowScroll }
    func wy_scrollViewDidScroll(_ scrollView: UIScrollView) { scrolls += 1 }
    func wy_canManagerCellForRowEvents(_ chatView: WYChatView, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell? { cell }
}
