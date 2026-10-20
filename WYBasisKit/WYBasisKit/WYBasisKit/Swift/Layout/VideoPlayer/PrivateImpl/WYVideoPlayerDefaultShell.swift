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

    /// 各条字幕轨名
    private var subtitleNames: [String] = []

    /// 当前字幕轨下标(-1 关闭)
    private var selectedSubtitleIndex = -1

    /// 壳是否正在显示
    var isShellVisible = true

    /// 壳显隐时顶底栏一起动
    private var barsAlpha: CGFloat {
        return isShellVisible ? 1 : 0
    }

    func attach(to player: WYVideoPlayer) {
        self.player = player
        buildShellView()
        shellHostView.onLayout = { [weak self] in
            self?.layoutShell()
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
        guard duration > 0 else { return }
        let ratio = CGFloat(currentTime / duration)
        if progressView.isDragging == false {
            progressView.progress = ratio
        }
        progressView.bufferProgress = CGFloat(playableDuration / duration)
        currentTimeLabel.text = WYVideoPlayerDefaultShell.timeText(currentTime)
        durationLabel.text = WYVideoPlayerDefaultShell.timeText(duration)
    }

    func updateState(_ state: WYVideoPlayerState) {
        let isPlaying = (state == .playing)
        let configuration = player?.configuration
        let playImage = configuration?.playImage ?? UIImage(systemName: "play.fill")
        let pauseImage = configuration?.pauseImage ?? UIImage(systemName: "pause.fill")
        playPauseButton.setImage(isPlaying ? pauseImage : playImage, for: .normal)
        centerPlayButton.setImage(playImage, for: .normal)
        centerPlayButton.isHidden = isPlaying
        indicator.isHidden = (state != .preparing)
        if state == .preparing {
            indicator.startAnimating()
        }else {
            indicator.stopAnimating()
        }
    }

    func updateRate(_ rate: Float) {
        rateButton.setTitle(String(format: "%.2gx", rate), for: .normal)
    }

    func updateMuted(_ isMuted: Bool) {
        // 默认壳不单独摆静音按钮，静音经竖滑音量手势或宿主调用设置，配置里的 muteImage/volumeImage 留给自定义壳用
    }

    func updateFullscreen(_ isFullscreen: Bool) {
        let configuration = player?.configuration
        let image = isFullscreen ? (configuration?.fullscreenExitImage ?? UIImage(systemName: "arrow.down.right.and.arrow.up.left")) : (configuration?.fullscreenEnterImage ?? UIImage(systemName: "arrow.up.left.and.arrow.down.right"))
        fullscreenButton.setImage(image, for: .normal)
        backButton.isHidden = false
    }

    func updateMediaInfo(qualityNames: [String], selectedQualityIndex: Int, subtitleNames: [String], selectedSubtitleIndex: Int) {
        qualityButton.isHidden = (player?.configuration.shellShowsQualityButton == false) || qualityNames.count <= 1
        self.qualityNames = qualityNames
        self.selectedQualityIndex = selectedQualityIndex
        self.subtitleNames = subtitleNames
        self.selectedSubtitleIndex = selectedSubtitleIndex
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
        ratePromptLabel.text = String(format: "%%.2gx %@", rate, WYLocalized("快放中", table: WYBasisKitConfig.kitLocalizableTable))
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

        shellHostView.addSubview(indicator)
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

        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        centerPlayButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        rateButton.addTarget(self, action: #selector(handleRateMenu), for: .touchUpInside)
        qualityButton.addTarget(self, action: #selector(handleQualityMenu), for: .touchUpInside)
        subtitleButton.addTarget(self, action: #selector(handleSubtitleMenu), for: .touchUpInside)
        danmakuButton.addTarget(self, action: #selector(handleDanmakuToggle), for: .touchUpInside)
        snapshotButton.addTarget(self, action: #selector(handleSnapshot), for: .touchUpInside)
        airPlayButton.addTarget(self, action: #selector(handleAirPlay), for: .touchUpInside)
        loopButton.addTarget(self, action: #selector(handleLoopToggle), for: .touchUpInside)
        fullscreenButton.addTarget(self, action: #selector(handleFullscreen), for: .touchUpInside)
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
        shellView.setNeedsLayout()
    }

    /// 按配置刷新外观与按钮显隐
    private func applyConfiguration() {
        guard let player = player else { return }
        let configuration = player.configuration
        shellHostView.frame = player.bounds
        topBar.backgroundColor = configuration.shellBarBackgroundColor
        bottomBar.backgroundColor = configuration.shellBarBackgroundColor
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
        for button in [backButton, playPauseButton, rateButton, qualityButton, subtitleButton, danmakuButton, snapshotButton, airPlayButton, loopButton, fullscreenButton] {
            button.tintColor = configuration.shellButtonTintColor
        }
        backButton.setImage(configuration.backImage ?? UIImage(systemName: "chevron.left"), for: .normal)
        qualityButton.setImage(configuration.qualityImage ?? UIImage(systemName: "textformat.size"), for: .normal)
        qualityButton.setTitle(configuration.qualityImage == nil ? nil : "", for: .normal)
        subtitleButton.setImage(configuration.subtitleImage ?? UIImage(systemName: "captions.bubble"), for: .normal)
        danmakuButton.setImage(configuration.danmakuOnImage ?? UIImage(systemName: "text.bubble"), for: .normal)
        snapshotButton.setImage(configuration.snapshotImage ?? UIImage(systemName: "camera"), for: .normal)
        airPlayButton.setImage(configuration.airPlayImage ?? UIImage(systemName: "airplayvideo"), for: .normal)
        loopButton.setImage(configuration.loopImage ?? UIImage(systemName: "repeat"), for: .normal)
        rateButton.setTitleColor(configuration.shellButtonTintColor, for: .normal)
        rateButton.titleLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
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
    }

    /// 壳布局(顶底栏铺满、按钮成排)
    private func layoutShell() {
        guard let player = player else { return }
        shellHostView.frame = player.bounds
        let barHeight: CGFloat = UIDevice.wy_screenHeight(44, WYBasisKitConfig.defaultScreenPixels)
        let safeTop = player.safeAreaInsets.top
        let safeBottom = player.safeAreaInsets.bottom
        topBar.frame = CGRect(x: 0, y: 0, width: shellHostView.bounds.width, height: barHeight + safeTop)
        bottomBar.frame = CGRect(x: 0, y: shellHostView.bounds.height - barHeight - safeBottom, width: shellHostView.bounds.width, height: barHeight + safeBottom)
        backButton.frame = CGRect(x: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels), y: safeTop, width: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), height: barHeight)
        titleLabel.frame = CGRect(x: UIDevice.wy_screenWidth(52, WYBasisKitConfig.defaultScreenPixels), y: safeTop, width: shellHostView.bounds.width - UIDevice.wy_screenWidth(104, WYBasisKitConfig.defaultScreenPixels), height: barHeight)
        let buttonSize: CGFloat = UIDevice.wy_screenWidth(34, WYBasisKitConfig.defaultScreenPixels)
        var x = shellHostView.bounds.width - buttonSize
        fullscreenButton.frame = CGRect(x: x, y: safeBottom + (barHeight - buttonSize) / 2, width: buttonSize, height: buttonSize)
        var functionButtons: [UIButton] = []
        if loopButton.isHidden == false { functionButtons.append(loopButton) }
        if airPlayButton.isHidden == false { functionButtons.append(airPlayButton) }
        if snapshotButton.isHidden == false { functionButtons.append(snapshotButton) }
        if danmakuButton.isHidden == false { functionButtons.append(danmakuButton) }
        if subtitleButton.isHidden == false { functionButtons.append(subtitleButton) }
        if qualityButton.isHidden == false { functionButtons.append(qualityButton) }
        if rateButton.isHidden == false { functionButtons.append(rateButton) }
        x -= buttonSize + UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels)
        for button in functionButtons {
            button.frame = CGRect(x: x, y: safeBottom + (barHeight - buttonSize) / 2, width: buttonSize, height: buttonSize)
            x -= buttonSize + UIDevice.wy_screenWidth(4, WYBasisKitConfig.defaultScreenPixels)
        }
        durationLabel.sizeToFit()
        durationLabel.frame = CGRect(x: x - durationLabel.bounds.width - UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels), y: safeBottom, width: durationLabel.bounds.width + UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels), height: barHeight)
        currentTimeLabel.sizeToFit()
        currentTimeLabel.frame = CGRect(x: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels), y: safeBottom, width: max(UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), currentTimeLabel.bounds.width), height: barHeight)
        progressView.frame = CGRect(x: currentTimeLabel.frame.maxX + UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels), y: safeBottom, width: durationLabel.frame.minX - UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels) - (currentTimeLabel.frame.maxX + UIDevice.wy_screenWidth(6, WYBasisKitConfig.defaultScreenPixels)), height: barHeight)
        indicator.center = CGPoint(x: shellHostView.bounds.midX, y: shellHostView.bounds.midY)
        let centerSize: CGFloat = UIDevice.wy_screenWidth(56, WYBasisKitConfig.defaultScreenPixels)
        centerPlayButton.frame = CGRect(x: shellHostView.bounds.midX - centerSize / 2, y: shellHostView.bounds.midY - centerSize / 2, width: centerSize, height: centerSize)
        seekPreviewLabel.frame = CGRect(x: shellHostView.bounds.midX - UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), y: shellHostView.bounds.midY - UIDevice.wy_screenHeight(70, WYBasisKitConfig.defaultScreenPixels), width: UIDevice.wy_screenWidth(160, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels))
        ratePromptLabel.frame = CGRect(x: shellHostView.bounds.midX - UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), y: shellHostView.bounds.midY - UIDevice.wy_screenHeight(70, WYBasisKitConfig.defaultScreenPixels), width: UIDevice.wy_screenWidth(160, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels))
        panIndicatorLabel.frame = CGRect(x: shellHostView.bounds.midX - UIDevice.wy_screenWidth(80, WYBasisKitConfig.defaultScreenPixels), y: shellHostView.bounds.midY - UIDevice.wy_screenHeight(70, WYBasisKitConfig.defaultScreenPixels), width: UIDevice.wy_screenWidth(160, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(34, WYBasisKitConfig.defaultScreenPixels))
        menuPanel.frame = shellHostView.bounds
    }

    /// 显隐壳(顶底栏与中心按钮一起动)
    private func setShell(visible: Bool, animated: Bool) {
        guard isShellVisible != visible else { return }
        isShellVisible = visible
        let apply = { [weak self] in
            guard let self = self else { return }
            self.topBar.alpha = self.barsAlpha
            self.bottomBar.alpha = self.barsAlpha
            self.centerPlayButton.alpha = self.barsAlpha
            if visible == false {
                self.menuPanel.dismiss()
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: apply)
        }else {
            apply()
        }
    }

    /// 处理返回(退出全屏或在全屏外交给页面自己响应)
    @objc private func handleBack() {
        player?.exitFullscreen()
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
        menuKind = 0
        let options = player.configuration.rateOptions.map { String(format: "%.2gx", $0) }
        let currentIndex = player.configuration.rateOptions.firstIndex(of: player.rate) ?? -1
        menuPanel.show(options: options, selected: currentIndex)
    }

    /// 打开清晰度菜单
    @objc private func handleQualityMenu() {
        menuKind = 1
        menuPanel.show(options: qualityNames, selected: selectedQualityIndex)
    }

    /// 打开字幕菜单
    @objc private func handleSubtitleMenu() {
        menuKind = 2
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
        let routePickerView = AVRoutePickerView()
        for view in routePickerView.subviews where view is UIControl {
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
