//
//  WYVideoPlayerDefaultShell.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//  Copyright © 2026 官人. All rights reserved.
//

import AVKit
import UIKit

/// 壳的宿主视图(尺寸变化时回调给壳重排，只被默认壳使用)
final class WYVideoPlayerShellHostView: UIView {

    /// 布局回调
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

/// 默认控制壳(顶栏返回标题、底栏播停进度倍速清晰度字幕弹幕投屏全屏、加载指示、快进预览与音量亮度提示、选项菜单)
final class WYVideoPlayerDefaultShell: NSObject, WYVideoPlayerControlShell {

    /// 绑定的播放器
    private weak var player: WYVideoPlayer?

    /// 壳根视图(就是壳宿主视图，协议要求暴露成 UIView)
    var shellView: UIView {
        return shellHostView
    }

    /// 壳宿主视图(尺寸变化时回调重排)
    private let shellHostView = WYVideoPlayerShellHostView()

    /// 顶栏(返回加标题)
    private let topBar = UIView()

    /// 底栏(播停加进度加各功能按钮)
    private let bottomBar = UIView()
    private let topControls = UIScrollView()
    private let bottomControls = UIScrollView()
    private let timeControls = UIScrollView()
    private let timeline = UIView()
    private let topGradient = CAGradientLayer()
    private let bottomGradient = CAGradientLayer()
    private let moreButton = UIButton(type: .system)
    private let pipButton = UIButton(type: .system)
    private let routePicker = AVRoutePickerView()
    private var hasBuiltView = false

    private var controls: [WYVideoPlayerControl: UIView] {
        return [.playPause: playPauseButton, .currentTime: currentTimeLabel, .progress: progressView,
                .duration: durationLabel, .back: backButton, .title: titleLabel, .fullscreen: fullscreenButton,
                .rate: rateButton, .quality: qualityButton, .subtitle: subtitleButton, .danmaku: danmakuButton,
                .snapshot: snapshotButton, .airPlay: airPlayButton, .pictureInPicture: pipButton,
                .more: moreButton, .loop: loopButton, .centerPlay: centerPlayButton]
    }

    /// 返回按钮
    private let backButton = UIButton(type: .system)

    /// 顶栏标题
    private let titleLabel = UILabel()

    /// 播放暂停按钮
    private let playPauseButton = UIButton(type: .system)

    /// 当前时间标签
    private let currentTimeLabel = UILabel()

    /// 进度条
    private let progressView = WYVideoPlayerProgressView()

    /// 总时长标签
    private let durationLabel = UILabel()

    /// 倍速按钮
    private let rateButton = UIButton(type: .system)

    /// 清晰度按钮
    private let qualityButton = UIButton(type: .system)

    /// 字幕按钮
    private let subtitleButton = UIButton(type: .system)

    /// 弹幕开关按钮
    private let danmakuButton = UIButton(type: .system)

    /// 截图按钮
    private let snapshotButton = UIButton(type: .system)

    /// 投屏按钮
    private let airPlayButton = UIButton(type: .system)

    /// 循环按钮
    private let loopButton = UIButton(type: .system)

    /// 全屏切换按钮
    private let fullscreenButton = UIButton(type: .system)

    /// 加载指示器(装载中转圈)
    private let indicator = UIActivityIndicatorView(style: .large)

    /// 加载失败后的重试按钮
    private let retryButton = UIButton(type: .system)

    /// 中心大播放按钮(暂停时显示)
    private let centerPlayButton = UIButton(type: .system)

    /// 快进预览提示浮层
    private let seekPreviewLabel = UILabel()

    /// 长按倍速提示浮层
    private let ratePromptLabel = UILabel()

    /// 竖滑音量亮度提示浮层
    private let panIndicatorLabel = UILabel()

    /// 选项菜单面板
    private let menuPanel = WYVideoPlayerMenuPanel()

    /// 菜单当前展示的种类(0 倍速 1 清晰度 2 字幕)
    private var menuKind = 0

    /// 各档清晰度名
    private var qualityNames: [String] = []

    /// 当前清晰度下标
    private var selectedQualityIndex = 0
    private var durationText = "00:00"

    /// 各条字幕轨名
    private var subtitleNames: [String] = []

    /// 当前字幕轨下标(-1 关闭)
    private var selectedSubtitleIndex = -1

    /// 壳是否正在显示
    var isShellVisible = true

    /// 上一次壳重排的尺寸与安全区特征(未变化时跳过重排，防止全屏旋转下布局反复触发形成死循环)
    private var lastLayoutKey = ""

    /// 壳显隐时顶底栏一起动
    private var barsAlpha: CGFloat {
        return isShellVisible ? 1 : 0
    }

    func attach(to player: WYVideoPlayer) {
        self.player = player
        buildShellView()
        shellHostView.onLayout = { [weak self] in
            guard let self = self, let player = self.player else { return }
            let size = self.shellHostView.bounds.size
            let insets = player.shellSafeAreaInsets
            let layoutKey = "\(size.width)x\(size.height)_\(insets.top)_\(insets.bottom)_\(insets.left)_\(insets.right)"
            guard layoutKey != self.lastLayoutKey else { return }
            self.lastLayoutKey = layoutKey
            self.layoutShell()
        }
        applyConfiguration()
        updateState(player.state)
    }

    func detach() {
        player = nil
    }

    func showShell(animated: Bool) {
        setShell(visible: true, animated: animated)
    }

    func hideShell(animated: Bool) {
        setShell(visible: false, animated: animated)
    }

    func updateProgress(currentTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval) {
        guard duration.isFinite, currentTime.isFinite else { return }
        let ratio = duration > 0 ? CGFloat(currentTime / duration) : 0
        if progressView.isDragging == false {
            progressView.progress = ratio
        }
        progressView.bufferProgress = duration > 0 && playableDuration.isFinite ? CGFloat(playableDuration / duration) : 0
        currentTimeLabel.text = WYVideoPlayerDefaultShell.timeText(currentTime)
        durationText = WYVideoPlayerDefaultShell.timeText(duration)
        durationLabel.text = durationText
        layoutShell()
    }

    func updateState(_ state: WYVideoPlayerState) {
        if state == .preparing { updateProgress(currentTime: 0, duration: 0, playableDuration: 0) }
        let isPlaying = (state == .playing)
        let configuration = player?.configuration
        let playImage = configuration?.playImage ?? UIImage(systemName: "play.fill")
        let pauseImage = configuration?.pauseImage ?? UIImage(systemName: "pause.fill")
        playPauseButton.setImage(isPlaying ? pauseImage : playImage, for: .normal)
        centerPlayButton.setImage(playImage, for: .normal)
        centerPlayButton.isHidden = state != .paused || configuration?.shellHiddenControls.contains(.centerPlay) == true
        let isLoading = state == .preparing || state == .buffering || state == .seeking || ((state == .readyToPlay || state == .playing) && player?.isAudioOnly == false && player?.playerLayer.isReadyForDisplay == false)
        retryButton.isHidden = state != .failed
        if state == .failed || state == .paused { showShell(animated: false) }
        indicator.isHidden = !isLoading
        if isLoading {
            indicator.startAnimating()
        }else {
            indicator.stopAnimating()
        }
    }

    func updateRate(_ rate: Float) {
        let title = String(format: "%.2gx", rate)
        rateButton.setImage(player?.configuration.rateImage, for: .normal)
        rateButton.setTitle(player?.configuration.rateImage == nil ? title : nil, for: .normal)
        rateButton.accessibilityLabel = title
    }

    func updateMuted(_ isMuted: Bool) {
        // 默认壳不单独摆静音按钮，静音经竖滑音量手势或宿主调用设置，配置里的 muteImage/volumeImage 留给自定义壳用
    }

    func updateFullscreen(_ isFullscreen: Bool) {
        let configuration = player?.configuration
        let image = isFullscreen ? (configuration?.fullscreenExitImage ?? UIImage(systemName: "arrow.down.right.and.arrow.up.left")) : (configuration?.fullscreenEnterImage ?? UIImage(systemName: "arrow.up.left.and.arrow.down.right"))
        fullscreenButton.setImage(image, for: .normal)
        backButton.isHidden = !isFullscreen
        lastLayoutKey = ""
        shellView.setNeedsLayout()
    }

    func updateMediaInfo(qualityNames: [String], selectedQualityIndex: Int, subtitleNames: [String], selectedSubtitleIndex: Int) {
        self.qualityNames = qualityNames
        self.selectedQualityIndex = selectedQualityIndex
        self.subtitleNames = subtitleNames
        self.selectedSubtitleIndex = selectedSubtitleIndex
        applyConfiguration()
        layoutShell()
    }

    func showSeekPreview(targetTime: TimeInterval, delta: TimeInterval) {
        seekPreviewLabel.isHidden = false
        let sign = delta >= 0 ? "+" : "-"
        seekPreviewLabel.text = "\(sign)\(Int(abs(delta)))" + WYLocalized("秒", table: WYBasisKitConfig.kitLocalizableTable) + "  \(WYVideoPlayerDefaultShell.timeText(targetTime))"
    }

    func hideSeekPreview() {
        seekPreviewLabel.isHidden = true
    }

    func showRatePrompt(rate: Float) {
        ratePromptLabel.isHidden = false
        ratePromptLabel.text = String(format: "%.2gx %@", rate, WYLocalized("快放中", table: WYBasisKitConfig.kitLocalizableTable))
    }

    func hideRatePrompt() {
        ratePromptLabel.isHidden = true
    }

    func showPanIndicator(isVolume: Bool, value: Float) {
        panIndicatorLabel.isHidden = false
        let name = isVolume ? WYLocalized("音量", table: WYBasisKitConfig.kitLocalizableTable) : WYLocalized("亮度", table: WYBasisKitConfig.kitLocalizableTable)
        let percent = max(0, min(100, Int(value * 100)))
        panIndicatorLabel.text = "\(name) \(percent)%"
    }

    func hidePanIndicator() {
        panIndicatorLabel.isHidden = true
    }

    /// 组装壳界面
    private func buildShellView() {
        guard !hasBuiltView else { return }
        hasBuiltView = true
        shellHostView.backgroundColor = .clear
        shellHostView.isUserInteractionEnabled = true

        topBar.backgroundColor = UIColor(white: 0, alpha: 0.01)
        shellHostView.addSubview(topBar)
        topBar.addSubview(backButton)
        topBar.addSubview(titleLabel)

        bottomBar.backgroundColor = UIColor(white: 0, alpha: 0.01)
        shellHostView.addSubview(bottomBar)
        bottomBar.addSubview(playPauseButton)
        bottomBar.addSubview(currentTimeLabel)
        bottomBar.addSubview(progressView)
        bottomBar.addSubview(durationLabel)
        bottomBar.addSubview(rateButton)
        bottomBar.addSubview(qualityButton)
        bottomBar.addSubview(subtitleButton)
        bottomBar.addSubview(danmakuButton)
        bottomBar.addSubview(snapshotButton)
        bottomBar.addSubview(airPlayButton)
        bottomBar.addSubview(loopButton)
        bottomBar.addSubview(fullscreenButton)
        for (button, name) in [(backButton, "back"), (fullscreenButton, "fullscreen"), (rateButton, "rate"), (playPauseButton, "playPause")] {
            button.accessibilityIdentifier = "WYVideoPlayer." + name
        }

        shellHostView.addSubview(indicator)
        shellHostView.addSubview(retryButton)
        retryButton.setTitle(WYLocalized("加载失败，点击重试", table: WYBasisKitConfig.kitLocalizableTable), for: .normal)
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
        retryButton.accessibilityIdentifier = "WYVideoPlayer.retry"
        indicator.accessibilityIdentifier = "WYVideoPlayer.loading"
        currentTimeLabel.accessibilityIdentifier = "WYVideoPlayer.currentTime"
        durationLabel.accessibilityIdentifier = "WYVideoPlayer.duration"
        progressView.accessibilityIdentifier = "WYVideoPlayer.progress"
        currentTimeLabel.text = "00:00"
        durationLabel.text = "00:00"
        shellHostView.addSubview(centerPlayButton)
        shellHostView.addSubview(seekPreviewLabel)
        shellHostView.addSubview(ratePromptLabel)
        shellHostView.addSubview(panIndicatorLabel)
        shellHostView.addSubview(menuPanel)
        menuPanel.isHidden = true
        seekPreviewLabel.isHidden = true
        ratePromptLabel.isHidden = true
        panIndicatorLabel.isHidden = true

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

        for label in [currentTimeLabel, durationLabel] {
            label.textColor = .white
            label.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
        }
        currentTimeLabel.textAlignment = .right

        indicator.color = .white
        indicator.backgroundColor = UIColor(white: 0, alpha: 0.45)

        centerPlayButton.tintColor = .white

        for overlay in [seekPreviewLabel, ratePromptLabel, panIndicatorLabel] {
            overlay.textColor = .white
            overlay.font = .systemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels))
            overlay.textAlignment = .center
            overlay.layer.cornerRadius = UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)
            overlay.layer.masksToBounds = true
        }
        seekPreviewLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        ratePromptLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        panIndicatorLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)

        topBar.layer.insertSublayer(topGradient, at: 0)
        bottomBar.layer.insertSublayer(bottomGradient, at: 0)
        topBar.addSubview(topControls)
        bottomBar.addSubview(bottomControls)
        bottomBar.addSubview(timeline)
        timeline.addSubview(timeControls)
        for scroll in [topControls, bottomControls, timeControls] {
            scroll.showsHorizontalScrollIndicator = false
            scroll.showsVerticalScrollIndicator = false
            scroll.delaysContentTouches = false
        }
        for (kind, view) in controls {
            if let button = view as? UIButton {
                button.tag = kind.rawValue
                button.addTarget(self, action: #selector(handleControl(_:)), for: .touchUpInside)
            }
        }
        moreButton.accessibilityIdentifier = "WYVideoPlayer.more"
        pipButton.accessibilityIdentifier = "WYVideoPlayer.pictureInPicture"
        qualityButton.accessibilityIdentifier = "WYVideoPlayer.quality"
        subtitleButton.accessibilityIdentifier = "WYVideoPlayer.subtitle"
        shellHostView.addSubview(routePicker)
        routePicker.alpha = 0.01
        routePicker.isUserInteractionEnabled = false
        progressView.onDragging = { [weak self] (_) in
            self?.player?.pauseShellAutoHide()
        }
        progressView.onDragEnd = { [weak self] (ratio) in
            guard let self = self, let player = self.player else { return }
            let duration = player.duration
            player.seek(to: duration * TimeInterval(ratio), accurate: true)
            player.resumeShellAutoHide()
        }
        menuPanel.onSelect = { [weak self] (index) in
            self?.handleMenuSelect(index: index)
        }
        menuPanel.onDismissOutside = { [weak self] in
            self?.player?.resumeShellAutoHide()
        }
        shellView.setNeedsLayout()
    }

    /// 按配置刷新外观与按钮显隐
    private func applyConfiguration() {
        guard let player = player else { return }
        let configuration = player.configuration
        shellHostView.frame = player.bounds
        topBar.backgroundColor = configuration.shellUsesGradientBackground ? .clear : configuration.shellBarBackgroundColor
        bottomBar.backgroundColor = topBar.backgroundColor
        topGradient.colors = [configuration.shellBarBackgroundColor.cgColor, UIColor.clear.cgColor]
        bottomGradient.colors = [UIColor.clear.cgColor, configuration.shellBarBackgroundColor.cgColor]
        topGradient.isHidden = !configuration.shellUsesGradientBackground
        bottomGradient.isHidden = !configuration.shellUsesGradientBackground
        titleLabel.text = configuration.shellTitle
        progressView.trackColor = configuration.progressTrackColor
        progressView.bufferColor = configuration.progressBufferColor
        progressView.playColor = configuration.progressPlayColor
        progressView.thumbColor = configuration.progressThumbColor
        currentTimeLabel.font = configuration.shellTimeFont
        currentTimeLabel.textColor = configuration.shellTimeColor
        durationLabel.font = configuration.shellTimeFont
        durationLabel.textColor = configuration.shellTimeColor
        titleLabel.font = configuration.shellTitleFont
        titleLabel.textColor = configuration.shellTitleColor
        seekPreviewLabel.backgroundColor = configuration.gestureOverlayBackgroundColor
        ratePromptLabel.backgroundColor = configuration.gestureOverlayBackgroundColor
        panIndicatorLabel.backgroundColor = configuration.gestureOverlayBackgroundColor
        seekPreviewLabel.textColor = configuration.gestureOverlayTextColor
        ratePromptLabel.textColor = configuration.gestureOverlayTextColor
        panIndicatorLabel.textColor = configuration.gestureOverlayTextColor
        menuPanel.panelBackgroundColor = configuration.menuPanelBackgroundColor
        menuPanel.selectedColor = configuration.menuSelectedColor
        menuPanel.normalColor = configuration.menuNormalColor
        menuPanel.panelCornerRadius = configuration.menuPanelCornerRadius
        menuPanel.panelItemWidth = configuration.menuPanelWidth
        menuPanel.itemRowHeight = configuration.menuPanelRowHeight
        menuPanel.itemFont = configuration.menuPanelItemFont
        menuPanel.optionHorizontalInset = configuration.menuOptionHorizontalInset
        menuPanel.checkmarkSize = configuration.menuCheckmarkSize
        menuPanel.selectedBackgroundColor = configuration.menuSelectedBackgroundColor
        menuPanel.textAlignment = configuration.menuTextAlignment
        progressView.trackBarHeight = configuration.progressTrackHeight
        progressView.thumbNormalSize = configuration.progressThumbSize
        progressView.thumbDraggingSize = configuration.progressThumbDraggingSize
        for button in [backButton, playPauseButton, centerPlayButton, rateButton, qualityButton, subtitleButton, danmakuButton, snapshotButton, airPlayButton, loopButton, fullscreenButton] {
            button.tintColor = configuration.shellButtonTintColor
        }
        indicator.style = configuration.shellLoadingIndicatorStyle
        indicator.backgroundColor = configuration.shellLoadingIndicatorBackgroundColor
        indicator.color = configuration.shellLoadingIndicatorColor
        retryButton.setTitleColor(configuration.shellLoadingIndicatorColor, for: .normal)
        retryButton.titleLabel?.font = configuration.shellTimeFont
        for overlay in [seekPreviewLabel, ratePromptLabel, panIndicatorLabel] {
            overlay.font = configuration.gestureOverlayFont
            overlay.layer.cornerRadius = configuration.gestureOverlayCornerRadius
        }
        backButton.setImage(configuration.backImage ?? UIImage(systemName: "chevron.left"), for: .normal)
        qualityButton.setImage(configuration.qualityImage, for: .normal)
        let qualityName = qualityNames.indices.contains(selectedQualityIndex) ? qualityNames[selectedQualityIndex] : WYLocalized("清晰度", table: WYBasisKitConfig.kitLocalizableTable)
        qualityButton.setTitle(configuration.qualityImage == nil ? qualityName : nil, for: .normal)
        qualityButton.accessibilityLabel = WYLocalized("清晰度", table: WYBasisKitConfig.kitLocalizableTable) + " " + qualityName
        subtitleButton.setImage(configuration.subtitleImage, for: .normal)
        subtitleButton.setTitle(configuration.subtitleImage == nil ? WYLocalized("字幕", table: WYBasisKitConfig.kitLocalizableTable) : nil, for: .normal)
        subtitleButton.accessibilityLabel = WYLocalized("字幕", table: WYBasisKitConfig.kitLocalizableTable)
        moreButton.setImage(configuration.moreImage ?? UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.accessibilityLabel = WYLocalized("更多", table: WYBasisKitConfig.kitLocalizableTable)
        pipButton.setImage(configuration.pictureInPictureImage ?? UIImage(systemName: "pip"), for: .normal)
        pipButton.accessibilityLabel = WYLocalized("画中画", table: WYBasisKitConfig.kitLocalizableTable)
        for button in [qualityButton, subtitleButton, moreButton, pipButton] {
            button.tintColor = configuration.shellButtonTintColor
            button.setTitleColor(configuration.shellButtonTintColor, for: .normal)
            button.titleLabel?.font = configuration.shellRateButtonFont
        }
        danmakuButton.setImage(configuration.danmakuOnImage ?? UIImage(systemName: "text.bubble"), for: .normal)
        snapshotButton.setImage(configuration.snapshotImage ?? UIImage(systemName: "camera"), for: .normal)
        airPlayButton.setImage(configuration.airPlayImage ?? UIImage(systemName: "airplayvideo"), for: .normal)
        loopButton.setImage(configuration.loopImage ?? UIImage(systemName: "repeat"), for: .normal)
        loopButton.tintColor = configuration.loopCount == 0 ? configuration.menuSelectedColor : configuration.shellButtonTintColor
        rateButton.setTitleColor(configuration.shellButtonTintColor, for: .normal)
        rateButton.titleLabel?.font = configuration.shellRateButtonFont
        rateButton.isHidden = configuration.shellShowsRateButton == false
        subtitleButton.isHidden = configuration.shellShowsSubtitleButton == false
        danmakuButton.isHidden = (configuration.shellShowsDanmakuButton == false) || (configuration.showsDanmaku == false)
        snapshotButton.isHidden = configuration.shellShowsSnapshotButton == false
        airPlayButton.isHidden = (configuration.shellShowsAirPlayButton == false) || (configuration.allowsAirPlay == false)
        loopButton.isHidden = configuration.shellShowsLoopButton == false
        fullscreenButton.isHidden = configuration.allowsFullscreenToggle == false
        updateRate(player.rate)
        updateMuted(player.isMuted)
        updateFullscreen(player.isFullscreen)
        lastLayoutKey = ""
        shellView.setNeedsLayout()
    }

    /// 壳布局(顶底栏铺满、按钮成排)
    private func layoutShell() {
        guard let player = player else { return }
        let configuration = player.configuration
        shellHostView.frame = player.bounds
        let barHeight = max(configuration.shellFunctionButtonSize, configuration.shellBarHeight, configuration.shellTimeFont.lineHeight, configuration.shellRateButtonFont.lineHeight, configuration.shellTitleFont.lineHeight)
        let shellInsets = player.shellSafeAreaInsets
        let leading = max(shellInsets.left, configuration.shellHorizontalInset)
        let trailing = max(shellInsets.right, configuration.shellHorizontalInset)
        let width = max(0, shellHostView.bounds.width - leading - trailing)
        let fullscreen = player.isFullscreen
        let timeHeight = (fullscreen || configuration.shellPrefersTwoRows) ? max(configuration.shellFullscreenTimeFont.lineHeight, configuration.shellFullscreenTimeRowHeight) : 0
        let progressHeight = (fullscreen || configuration.shellPrefersTwoRows) ? max(0, configuration.shellFullscreenProgressRowHeight) : 0
        topBar.frame = CGRect(x: 0, y: 0, width: shellHostView.bounds.width, height: barHeight + shellInsets.top)
        let bottomHeight = barHeight + timeHeight + progressHeight + shellInsets.bottom
        bottomBar.frame = CGRect(x: 0, y: max(0, shellHostView.bounds.height - bottomHeight), width: shellHostView.bounds.width, height: bottomHeight)
        topGradient.frame = topBar.bounds
        bottomGradient.frame = bottomBar.bounds
        topControls.frame = CGRect(x: leading, y: shellInsets.top, width: width, height: barHeight)
        bottomControls.frame = CGRect(x: leading, y: timeHeight + progressHeight, width: width, height: barHeight)
        timeline.frame = CGRect(x: leading, y: 0, width: width, height: timeHeight + progressHeight)
        timeControls.frame = CGRect(x: 0, y: 0, width: width, height: timeHeight)
        var top = fullscreen ? configuration.shellFullscreenTopControls : configuration.shellInlineTopControls
        var bottom = fullscreen ? configuration.shellFullscreenBottomControls : configuration.shellInlineBottomControls
        if !fullscreen && configuration.shellShowsInlineOptions { bottom += [.subtitle, .rate, .quality] }
        let overrides = configuration.shellLayoutHandler?(player, shellHostView.bounds, shellInsets, fullscreen) ?? [:]
        for (kind, view) in controls where kind != .centerPlay {
            view.isHidden = true
            view.alpha = 1
        }
        var used = Set<WYVideoPlayerControl>()
        func filtered(_ values: [WYVideoPlayerControl]) -> [WYVideoPlayerControl] {
            return values.filter { kind in
                if kind == .flexibleSpace { return true }
                guard isAvailable(kind), overrides[kind] == nil, !used.contains(kind), kind != .centerPlay else { return false }
                used.insert(kind)
                return true
            }
        }
        if fullscreen || configuration.shellPrefersTwoRows {
            for kind in [WYVideoPlayerControl.currentTime, .duration, .progress] where isAvailable(kind) && overrides[kind] == nil {
                used.insert(kind)
                if let view = controls[kind] {
                    (kind == .progress ? timeline : timeControls).addSubview(view)
                    view.isHidden = false
                }
            }
            currentTimeLabel.font = configuration.shellFullscreenTimeFont
            durationLabel.font = configuration.shellFullscreenTimeFont
            durationLabel.text = currentTimeLabel.isHidden ? durationText : "/ " + durationText
            let currentWidth = currentTimeLabel.isHidden ? 0 : max(configuration.shellMinimumTimeWidth, currentTimeLabel.intrinsicContentSize.width)
            let durationWidth = max(configuration.shellMinimumTimeWidth, durationLabel.intrinsicContentSize.width)
            currentTimeLabel.frame = CGRect(x: 0, y: 0, width: currentWidth, height: timeHeight)
            durationLabel.frame = CGRect(x: currentWidth + (currentWidth > 0 ? configuration.shellTimeSpacing : 0), y: 0, width: durationWidth, height: timeHeight)
            progressView.frame = CGRect(x: 0, y: timeHeight, width: width, height: progressHeight)
            let timeWidth = max(currentTimeLabel.isHidden ? 0 : currentTimeLabel.frame.maxX, durationLabel.isHidden ? 0 : durationLabel.frame.maxX)
            timeControls.contentSize = CGSize(width: max(width, timeWidth), height: timeHeight)
            timeControls.isScrollEnabled = timeWidth > width
            timeControls.contentOffset.x = max(0, min(timeControls.contentOffset.x, timeControls.contentSize.width - width))
        } else {
            durationLabel.text = durationText
            currentTimeLabel.font = configuration.shellTimeFont
            durationLabel.font = configuration.shellTimeFont
        }
        top = filtered(top)
        bottom = filtered(bottom)
        layoutRow(top, in: topControls, spacing: configuration.shellTopButtonSpacing)
        layoutRow(bottom, in: bottomControls, spacing: max(configuration.shellButtonSpacing, configuration.shellTimeSpacing))
        for (kind, rect) in overrides where isAvailable(kind) {
            guard let view = controls[kind], kind != .centerPlay else { continue }
            shellHostView.addSubview(view)
            view.frame = rect.standardized
            view.isHidden = false
            view.alpha = barsAlpha
        }
        routePicker.frame = airPlayButton.convert(airPlayButton.bounds, to: shellHostView)
        indicator.bounds = CGRect(origin: .zero, size: configuration.shellLoadingIndicatorSize)
        indicator.layer.cornerRadius = configuration.shellLoadingIndicatorCornerRadius
        indicator.center = CGPoint(x: shellHostView.bounds.midX, y: shellHostView.bounds.midY)
        retryButton.sizeToFit()
        retryButton.center = indicator.center
        let centerSize = configuration.shellCenterPlayButtonSize
        centerPlayButton.frame = CGRect(x: shellHostView.bounds.midX - centerSize / 2, y: shellHostView.bounds.midY - centerSize / 2, width: centerSize, height: centerSize)
        if let rect = overrides[.centerPlay] { centerPlayButton.frame = rect.standardized }
        centerPlayButton.isHidden = player.state != .paused || configuration.shellHiddenControls.contains(.centerPlay)
        let overlaySize = configuration.gestureOverlaySize
        let overlayY = shellHostView.bounds.midY - UIDevice.wy_screenHeight(70, WYBasisKitConfig.defaultScreenPixels)
        seekPreviewLabel.frame = CGRect(x: shellHostView.bounds.midX - overlaySize.width / 2, y: overlayY, width: overlaySize.width, height: overlaySize.height)
        ratePromptLabel.frame = CGRect(x: shellHostView.bounds.midX - overlaySize.width / 2, y: overlayY, width: overlaySize.width, height: overlaySize.height)
        panIndicatorLabel.frame = CGRect(x: shellHostView.bounds.midX - overlaySize.width / 2, y: overlayY, width: overlaySize.width, height: overlaySize.height)
        menuPanel.frame = shellHostView.bounds
    }

    private func isAvailable(_ control: WYVideoPlayerControl) -> Bool {
        guard let player = player else { return false }
        let config = player.configuration
        if config.shellHiddenControls.contains(control) { return false }
        switch control {
        case .back: return player.isFullscreen
        case .title: return !config.shellTitle.isEmpty
        case .fullscreen: return config.allowsFullscreenToggle
        case .rate: return config.shellShowsRateButton
        case .quality: return config.shellShowsQualityButton && qualityNames.count > 1
        case .subtitle: return config.shellShowsSubtitleButton && (!config.shellHidesUnavailableSubtitleButton || subtitleNames.count > 1)
        case .danmaku: return config.shellShowsDanmakuButton && config.showsDanmaku
        case .snapshot: return config.shellShowsSnapshotButton
        case .airPlay: return config.shellShowsAirPlayButton && config.allowsAirPlay
        case .pictureInPicture: return config.shellShowsPictureInPictureButton && config.allowsPictureInPicture
        case .more: return config.shellShowsMoreButton && !config.moreActions.isEmpty
        case .loop: return config.shellShowsLoopButton
        default: return true
        }
    }

    private func layoutRow(_ row: [WYVideoPlayerControl], in scroll: UIScrollView, spacing: CGFloat) {
        guard let config = player?.configuration else { return }
        let height = scroll.bounds.height
        var widths: [CGFloat] = row.map { kind in
            switch kind {
            case .flexibleSpace: return 0
            case .title: return 0
            case .progress: return max(0, config.shellMinimumProgressWidth)
            case .currentTime, .duration:
                return max(config.shellMinimumTimeWidth, controls[kind]?.intrinsicContentSize.width ?? 0)
            default:
                if let button = controls[kind] as? UIButton, let title = button.title(for: .normal), !title.isEmpty {
                    return max(config.shellTextButtonMinimumWidth, (title as NSString).size(withAttributes: [.font: button.titleLabel?.font ?? config.shellRateButtonFont]).width + config.shellTextButtonHorizontalPadding * 2)
                }
                return max(0, config.shellFunctionButtonSize)
            }
        }
        let count = max(0, row.count - 1)
        let fixed = widths.reduce(0, +)
        let gap = count > 0 ? max(0, min(spacing, (scroll.bounds.width - fixed) / CGFloat(count))) : 0
        let flexible = row.indices.filter { [.flexibleSpace, .title, .progress].contains(row[$0]) }
        let remaining = max(0, scroll.bounds.width - fixed - CGFloat(count) * gap)
        for index in flexible { widths[index] += remaining / CGFloat(flexible.count) }
        var x: CGFloat = 0
        for (index, kind) in row.enumerated() {
            if let view = controls[kind] {
                scroll.addSubview(view)
                view.isHidden = false
                let buttonHeight = max(config.shellFunctionButtonSize, (view as? UIButton)?.titleLabel?.font.lineHeight ?? 0)
                let itemHeight = view is UIButton ? min(height, buttonHeight) : height
                view.frame = CGRect(x: x, y: (height - itemHeight) / 2, width: widths[index], height: itemHeight)
            }
            x += widths[index] + gap
        }
        scroll.contentSize = CGSize(width: max(scroll.bounds.width, x - gap), height: height)
        scroll.isScrollEnabled = x - gap > scroll.bounds.width
    }

    @objc private func handleControl(_ sender: UIButton) {
        guard let player = player, let kind = WYVideoPlayerControl(rawValue: sender.tag) else { return }
        if player.configuration.controlActionHandler?(kind, player) == true { return }
        switch kind {
        case .playPause, .centerPlay: handlePlayPause()
        case .back: handleBack()
        case .fullscreen: handleFullscreen()
        case .rate: handleRateMenu()
        case .quality: handleQualityMenu()
        case .subtitle: handleSubtitleMenu()
        case .danmaku: handleDanmakuToggle()
        case .snapshot: handleSnapshot()
        case .airPlay: handleAirPlay()
        case .loop: handleLoopToggle()
        case .pictureInPicture: player.isPictureInPictureActive ? player.stopPictureInPicture() : player.startPictureInPicture()
        case .more: player.showMoreControls()
        default: break
        }
    }

    /// 显隐壳(顶底栏与中心按钮一起动)
    private func setShell(visible: Bool, animated: Bool) {
        let changes = isShellVisible != visible
        isShellVisible = visible
        // 壳隐藏后整棵壳树不再参与命中，点击落到播放器手势上唤回壳，避免透明按钮吃掉点击
        shellHostView.isUserInteractionEnabled = visible
        let apply = { [weak self] in
            guard let self = self else { return }
            self.topBar.alpha = self.barsAlpha
            self.bottomBar.alpha = self.barsAlpha
            self.centerPlayButton.alpha = self.barsAlpha
            for view in self.controls.values where view.superview === self.shellHostView { view.alpha = self.barsAlpha }
            if visible == false {
                self.menuPanel.dismiss()
            }
        }
        if animated && changes {
            UIView.animate(withDuration: player?.configuration.shellAnimationDuration ?? 0.25, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: apply)
        }else {
            for view in [topBar, bottomBar, centerPlayButton] + controls.values.filter({ $0.superview === shellHostView }) {
                view.layer.removeAllAnimations()
            }
            apply()
        }
    }

    /// 处理返回(退出全屏或在全屏外交给页面自己响应)
    @objc private func handleBack() {
        player?.exitFullscreen()
    }

    @objc private func handleRetry() {
        guard let player = player, let asset = player.currentAsset else { return }
        player.play(with: asset)
    }

    /// 处理播放暂停
    @objc private func handlePlayPause() {
        guard let player = player else { return }
        if player.state == .playing {
            player.pause()
        }else {
            player.resume()
        }
    }

    /// 打开倍速菜单
    @objc private func handleRateMenu() {
        guard let player = player else { return }
        player.pauseShellAutoHide()
        menuKind = 0
        let options = player.configuration.rateOptions.map { String(format: "%.2gx", $0) }
        let currentIndex = player.configuration.rateOptions.firstIndex(of: player.rate) ?? -1
        menuPanel.anchorView = rateButton
        menuPanel.show(options: options, selected: currentIndex)
    }

    /// 打开清晰度菜单
    @objc private func handleQualityMenu() {
        player?.pauseShellAutoHide()
        menuKind = 1
        menuPanel.anchorView = qualityButton
        menuPanel.show(options: qualityNames, selected: selectedQualityIndex)
    }

    /// 打开字幕菜单
    @objc private func handleSubtitleMenu() {
        player?.pauseShellAutoHide()
        menuKind = 2
        menuPanel.anchorView = subtitleButton
        menuPanel.show(options: subtitleNames, selected: selectedSubtitleIndex + 1)
    }

    /// 弹幕开关
    @objc private func handleDanmakuToggle() {
        guard let player = player, let danmakuView = player.danmakuView else { return }
        let configuration = player.configuration
        let willShow = danmakuView.isHidden
        danmakuView.isHidden = !willShow
        danmakuButton.setImage(willShow ? (configuration.danmakuOnImage ?? UIImage(systemName: "text.bubble")) : (configuration.danmakuOffImage ?? UIImage(systemName: "text.bubble")), for: .normal)
    }

    /// 截图
    @objc private func handleSnapshot() {
        player?.snapshot(completion: nil)
    }

    /// 打开系统投屏面板
    @objc private func handleAirPlay() {
        for view in routePicker.subviews where view is UIControl {
            (view as! UIControl).sendActions(for: .touchUpInside)
        }
    }

    /// 循环开关(开=无限循环，关=只播一遍)
    @objc private func handleLoopToggle() {
        guard let player = player else { return }
        let configuration = player.configuration
        configuration.loopCount = (configuration.loopCount == 0) ? 1 : 0
        loopButton.tintColor = (configuration.loopCount == 0) ? configuration.menuSelectedColor : configuration.shellButtonTintColor
    }

    /// 全屏切换
    @objc private func handleFullscreen() {
        guard let player = player else { return }
        if player.isFullscreen {
            player.exitFullscreen()
        }else {
            player.enterFullscreen()
        }
    }

    /// 菜单选项落定
    private func handleMenuSelect(index: Int) {
        guard let player = player else { return }
        defer { player.resumeShellAutoHide() }
        switch menuKind {
        case 0:
            let rates = player.configuration.rateOptions
            if rates.indices.contains(index) {
                player.rate = rates[index]
            }
        case 1:
            player.selectQuality(at: index)
        default:
            player.selectSubtitle(at: index - 1)
        }
    }

    /// 秒数转分秒文字
    static func timeText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, (total % 3600) / 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
