//
//  WYVideoPlayerMoreController.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/23.
//

import UIKit

/// 播放功能网格与选项面板
final class WYVideoPlayerMoreController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    init(player: WYVideoPlayer) {
        self.player = player
        self.configuration = player.configuration
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        player?.playbackOptions.stateChanged = { [weak self] in self?.refreshSelection() }
        view.backgroundColor = configuration.moreDimmingColor
        let background = UIButton(type: .custom)
        background.addTarget(self, action: #selector(close), for: .touchUpInside)
        background.frame = view.bounds
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(background)
        view.addSubview(panel)
        panel.backgroundColor = configuration.moreBackgroundColor
        panel.layer.cornerRadius = configuration.moreCornerRadius
        panel.clipsToBounds = true
        panel.addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.font = configuration.moreTitleFont
        titleLabel.textColor = configuration.moreTextColor
        panel.addSubview(closeButton)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = configuration.moreTextColor
        closeButton.accessibilityLabel = localized("关闭")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        panel.addSubview(backButton)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = configuration.moreTextColor
        backButton.addTarget(self, action: #selector(showGrid), for: .touchUpInside)
        panel.addSubview(grid)
        panel.addSubview(table)
        grid.showsVerticalScrollIndicator = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.rowHeight = configuration.menuPanelRowHeight
        showGrid()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refreshSelection() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = configuration.moreContentInsets
        let header = max(0, configuration.moreHeaderHeight)
        let fullscreen = player?.isFullscreen == true
        let safe = view.safeAreaInsets
        let width = fullscreen ? min(view.bounds.width - safe.left, max(0, configuration.moreFullscreenWidth) + safe.right) : view.bounds.width
        let contentWidth = max(0, width - insets.left - insets.right - (fullscreen ? safe.right : 0))
        let columns = max(1, min(max(1, configuration.moreColumnCount), Int(contentWidth / max(1, configuration.moreIconSize + insets.left))))
        let rows = Int(ceil(Double(actions.count) / Double(columns)))
        let height = fullscreen ? view.bounds.height : min(view.bounds.height - safe.top, header + insets.top + CGFloat(rows) * max(1, configuration.moreItemHeight) + insets.bottom + safe.bottom)
        panel.frame = CGRect(x: fullscreen ? view.bounds.width - width : 0, y: fullscreen ? 0 : view.bounds.height - height, width: width, height: height)
        let top = fullscreen ? safe.top : 0
        titleLabel.frame = CGRect(x: header, y: top, width: max(0, width - header * 2), height: header)
        closeButton.frame = CGRect(x: width - header - (fullscreen ? safe.right : 0), y: top, width: header, height: header)
        backButton.frame = CGRect(x: insets.left, y: top, width: header, height: header)
        let rect = CGRect(x: insets.left, y: top + header + insets.top, width: contentWidth, height: max(0, height - top - header - insets.top - insets.bottom - safe.bottom))
        grid.frame = rect
        table.frame = rect
        let cellWidth = contentWidth / CGFloat(columns)
        for (index, item) in itemButtons.enumerated() {
            item.frame = CGRect(x: CGFloat(index % columns) * cellWidth, y: CGFloat(index / columns) * configuration.moreItemHeight, width: cellWidth, height: configuration.moreItemHeight)
            let icon = item.viewWithTag(10001)!
            let label = item.viewWithTag(10002) as! UILabel
            let iconSize = min(configuration.moreIconSize, cellWidth)
            icon.frame = CGRect(x: (cellWidth - iconSize) / 2, y: 0, width: iconSize, height: iconSize)
            icon.layer.cornerRadius = iconSize / 2
            label.frame = CGRect(x: 0, y: iconSize, width: cellWidth, height: max(0, configuration.moreItemHeight - iconSize))
        }
        grid.contentSize = CGSize(width: contentWidth, height: CGFloat(rows) * configuration.moreItemHeight)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
        player?.resumeShellAutoHide()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return optionTitles.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        var content = cell.defaultContentConfiguration()
        content.text = optionTitles[indexPath.row]
        content.textProperties.font = configuration.menuPanelItemFont
        content.textProperties.color = indexPath.row == selectedOption ? configuration.moreSelectedColor : configuration.moreTextColor
        content.directionalLayoutMargins.leading = configuration.menuOptionHorizontalInset
        content.directionalLayoutMargins.trailing = configuration.menuOptionHorizontalInset
        cell.contentConfiguration = content
        cell.backgroundColor = indexPath.row == selectedOption ? configuration.moreSelectedBackgroundColor : .clear
        let image = UIImageView(image: UIImage(systemName: "checkmark"))
        image.tintColor = configuration.moreSelectedColor
        image.frame.size = CGSize(width: configuration.menuCheckmarkSize, height: configuration.menuCheckmarkSize)
        image.alpha = indexPath.row == selectedOption ? 1 : 0
        cell.accessoryView = image
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        optionHandler?(indexPath.row)
        showGrid()
    }

    private weak var player: WYVideoPlayer?
    private let configuration: WYVideoPlayerConfig
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private let grid = UIScrollView()
    private let table = UITableView(frame: .zero, style: .plain)
    private var actions: [WYVideoPlayerMoreAction] = []
    private var itemButtons: [UIButton] = []
    private var optionTitles: [String] = []
    private var selectedOption = -1
    private var optionHandler: ((_ index: Int) -> Void)?
    private var refreshTimer: Timer?

    private func localized(_ text: String) -> String { return WYLocalized(text, table: WYBasisKitConfig.kitLocalizableTable) }

    @objc private func close() { dismiss(animated: true) }

    @objc private func showGrid() {
        actions = configuration.moreActions
        titleLabel.text = localized("更多")
        backButton.isHidden = true
        table.isHidden = true
        grid.isHidden = false
        itemButtons.forEach { $0.removeFromSuperview() }
        itemButtons = actions.enumerated().map { index, action in
            let button = UIButton(type: .custom)
            button.tag = index
            button.accessibilityIdentifier = "WYVideoPlayer.more." + action.identifier
            button.addTarget(self, action: #selector(performAction(_:)), for: .touchUpInside)
            let image = UIImageView(image: action.image ?? UIImage(systemName: iconName(action.kind), withConfiguration: UIImage.SymbolConfiguration(pointSize: configuration.moreIconPointSize)))
            image.tag = 10001
            image.contentMode = .center
            image.isUserInteractionEnabled = false
            button.addSubview(image)
            let label = UILabel()
            label.tag = 10002
            label.font = configuration.moreItemFont
            label.textAlignment = .center
            label.numberOfLines = 2
            label.isUserInteractionEnabled = false
            button.addSubview(label)
            grid.addSubview(button)
            return button
        }
        refreshSelection()
        view.setNeedsLayout()
    }

    private func refreshSelection() {
        guard let player = player else { return }
        for (index, button) in itemButtons.enumerated() {
            let action = actions[index]
            var selected = action.isSelected
            var title = action.title ?? localized(actionTitle(action.kind))
            switch action.kind {
            case .pictureInPicture: selected = player.isPictureInPictureActive
            case .sleepTimer: selected = player.sleepTimerRemaining > 0 || player.sleepsAtVideoEnd
            case .audioOnly: selected = player.isAudioOnly
            case .backgroundPlayback: selected = player.isBackgroundPlaybackEnabled
            case .loopPlayback: selected = player.configuration.loopCount == 0
            case .download:
                selected = player.isDownloading || player.offlineFileURL != nil
                if player.isDownloading { title += String(format: " %.0f%%", player.downloadProgress * 100) }
            default: break
            }
            button.isEnabled = action.isEnabled
            if action.kind == .pictureInPicture { button.isEnabled = action.isEnabled && player.configuration.allowsPictureInPicture }
            if action.kind == .subtitle && configuration.shellHidesUnavailableSubtitleButton && player.subtitleTracks.isEmpty { button.isEnabled = false }
            if action.kind == .quality && (player.currentAsset?.qualities.count ?? 0) < 2 { button.isEnabled = false }
            button.alpha = button.isEnabled ? 1 : 0.4
            button.accessibilityLabel = title
            button.accessibilityValue = selected ? localized("开启") : localized("关闭")
            let label = button.viewWithTag(10002) as! UILabel
            label.text = title
            label.textColor = selected ? configuration.moreSelectedColor : configuration.moreSecondaryTextColor
            let image = button.viewWithTag(10001) as! UIImageView
            image.tintColor = selected ? configuration.moreSelectedColor : configuration.moreTextColor
            image.backgroundColor = selected ? configuration.moreSelectedBackgroundColor : configuration.moreIconBackgroundColor
        }
    }

    @objc private func performAction(_ sender: UIButton) {
        guard let player = player, actions.indices.contains(sender.tag) else { return }
        let action = actions[sender.tag]
        if let handler = action.handler { handler(player); refreshSelection(); return }
        switch action.kind {
        case .pictureInPicture:
            dismiss(animated: true) { player.isPictureInPictureActive ? player.stopPictureInPicture() : player.startPictureInPicture() }
        case .sleepTimer:
            let intervals = configuration.sleepTimerOptions.filter { $0.isFinite && $0 > 0 }
            var titles = [localized("关闭")] + intervals.map { WYVideoPlayerDefaultShell.timeText($0) }
            if configuration.showsSleepAtVideoEndOption { titles.append(localized("本集结束")) }
            let selected = player.sleepsAtVideoEnd ? titles.count - 1 : (player.sleepTimerRemaining > 0 ? -1 : 0)
            showOptions(title: action.title ?? localized("定时关闭"), options: titles, selected: selected) { [weak player] index in
                if index == 0 { player?.setSleepTimer(after: 0) }
                else if index <= intervals.count { player?.setSleepTimer(after: intervals[index - 1]) }
                else { player?.sleepAtVideoEnd() }
            }
        case .playbackRate:
            let rates = configuration.rateOptions
            showOptions(title: action.title ?? localized("倍速"), options: rates.map { String(format: "%.2gx", $0) }, selected: rates.firstIndex(of: player.rate) ?? -1) { [weak player] index in player?.rate = rates[index] }
        case .download:
            if player.isDownloading { player.cancelVideoDownload() } else { player.downloadCurrentVideo(completion: nil) }
        case .audioOnly: player.isAudioOnly.toggle()
        case .backgroundPlayback: player.isBackgroundPlaybackEnabled.toggle()
        case .loopPlayback: player.configuration.loopCount = player.configuration.loopCount == 0 ? 1 : 0
        case .quality:
            guard let asset = player.currentAsset else { break }
            showOptions(title: action.title ?? localized("清晰度"), options: asset.qualities.map { $0.name }, selected: asset.selectedIndex) { [weak player] index in player?.selectQuality(at: index) }
        case .subtitle:
            showOptions(title: action.title ?? localized("字幕"), options: [localized("关闭")] + player.subtitleTracks.map { $0.name }, selected: player.selectedSubtitleIndex + 1) { [weak player] index in player?.selectSubtitle(at: index - 1) }
        case .custom: break
        }
        refreshSelection()
    }

    private func showOptions(title: String, options: [String], selected: Int, handler: @escaping (_ index: Int) -> Void) {
        titleLabel.text = title
        optionTitles = options
        selectedOption = selected
        optionHandler = handler
        grid.isHidden = true
        table.isHidden = false
        backButton.isHidden = false
        table.reloadData()
    }

    private func actionTitle(_ kind: WYVideoPlayerMoreActionKind) -> String {
        switch kind {
        case .pictureInPicture: return "画中画"
        case .sleepTimer: return "定时关闭"
        case .download: return "下载"
        case .playbackRate: return "倍速"
        case .audioOnly: return "音频播放"
        case .backgroundPlayback: return "后台播放"
        case .loopPlayback: return "循环播放"
        case .quality: return "清晰度"
        case .subtitle: return "字幕"
        case .custom: return "更多"
        }
    }

    private func iconName(_ kind: WYVideoPlayerMoreActionKind) -> String {
        switch kind {
        case .pictureInPicture: return "pip"
        case .sleepTimer: return "moon.zzz"
        case .download: return "arrow.down.to.line"
        case .playbackRate: return "speedometer"
        case .audioOnly: return "waveform"
        case .backgroundPlayback: return "headphones"
        case .loopPlayback: return "repeat"
        case .quality: return "slider.horizontal.3"
        case .subtitle: return "captions.bubble"
        case .custom: return "ellipsis"
        }
    }
}
