//
//  WYTestLiveStreamingController.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit
import SnapKit
import FSPlayer
import AVKit

class WYTestLiveStreamingController: UIViewController {
    
    // MARK: - 播放器
    let player: WYMediaPlayer = WYMediaPlayer()
    
    // MARK: - 控制面板
    let controlPanel = UIView()
    let panelScrollView = UIScrollView()
    let closePanelButton = UIButton(type: .system)
    
    // MARK: - 播放控制滑块
    let volumeSlider = UISlider() // 音量
    let rateSlider = UISlider() // 倍速
    let seekSlider = UISlider() // 进度
    
    // MARK: - 播放控制按钮
    let playPauseButton = UIButton(type: .system)
    let stopButton = UIButton(type: .system)
    let scalingButton = UIButton(type: .system)
    let rotateXButton = UIButton(type: .system)
    let rotateYButton = UIButton(type: .system)
    let rotateZButton = UIButton(type: .system)
    let snapshotButton = UIButton(type: .system)
    let mediaButton = UIButton(type: .system)
    let subtitleButton = UIButton(type: .system)
    let frameButton = UIButton(type: .system)
    let audioDelayButton = UIButton(type: .system)
    let subtitleDelayButton = UIButton(type: .system)
    let colorButton = UIButton(type: .system)
    let aspectButton = UIButton(type: .system)
    let snapshotTypeButton = UIButton(type: .system)
    
    // MARK: - 新增按钮
    let pipButton = UIButton(type: .system)          // 画中画按钮
    let fullScreenButton = UIButton(type: .system)   // 全屏/半屏按钮
    let orientationButton = UIButton(type: .system)  // 横竖屏切换按钮
    
    // MARK: - 信息显示
    let infoLabel = UILabel()
    let stateLabel = UILabel()
    let streamLabel = UILabel()
    
    // MARK: - 播放数据
    var mediaList: [(name: String, url: String)] = []
    var subtitleList: [URL] = []
    var currentIndex = 0
    var updateTimer: Timer?
    
    // 当前旋转偏好
    var rotatePreference: FSRotatePreference = {
        var pref = FSRotatePreference()
        pref.type = FSRotateNone
        pref.degrees = 0
        return pref
    }()
    
    // 当前色彩偏好
    var colorPreference: FSColorConvertPreference = {
        var pref = FSColorConvertPreference()
        pref.brightness = 1.0
        pref.saturation = 1.0
        pref.contrast = 1.0
        return pref
    }()
    
    // 当前画面比例
    var aspectPreference: FSDARPreference = {
        var pref = FSDARPreference()
        pref.ratio = 0 // 默认比例
        return pref
    }()
    
    // 当前快照类型
    var currentSnapshotType: FSSnapshotType = FSSnapshotTypeScreen
    
    // 控制面板是否显示
    var isControlPanelVisible = false
    
    // 是否全屏模式
    var isFullScreen = true
    
    // 画中画控制器
    var pipController: AVPictureInPictureController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupMediaList()
        setupPlayer()
        setupUI()
        setupNavigationBar()
        playCurrentMedia()
        startInfoUpdateTimer()
        setupPictureInPicture()
    }
    
    // 设置导航栏
    func setupNavigationBar() {
        // 创建菜单按钮
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(toggleControlPanel))
        navigationItem.rightBarButtonItem = menuButton
    }
    
    // 设置播放器
    func setupPlayer() {
        player.delegate = self
        player.looping = 1
        player.backgroundColor = .black
        player.scalingStyle(.aspectFit)
        player.layer.borderWidth = 2
        player.layer.borderColor = UIColor.orange.cgColor
        view.addSubview(player)
        
        player.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    // 设置画中画功能(待API支持)
    func setupPictureInPicture() {
//        guard let playerLayer = player.ijkPlayer else { return }
//        pipController = AVPictureInPictureController(playerLayer: playerLayer)
//        pipController?.delegate = self
    }
    
    // 设置UI控件
    func setupUI() {
        // 设置控制面板
        controlPanel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        controlPanel.layer.cornerRadius = 12
        controlPanel.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        controlPanel.clipsToBounds = true
        controlPanel.isHidden = true
        view.addSubview(controlPanel)
        
        controlPanel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.7)
        }
        
        // 设置关闭按钮
        closePanelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closePanelButton.tintColor = .white
        closePanelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closePanelButton.layer.cornerRadius = 15
        closePanelButton.addTarget(self, action: #selector(toggleControlPanel), for: .touchUpInside)
        controlPanel.addSubview(closePanelButton)
        
        closePanelButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(30)
        }
        
        // 设置滚动视图
        panelScrollView.showsVerticalScrollIndicator = true
        panelScrollView.alwaysBounceVertical = true
        controlPanel.addSubview(panelScrollView)
        
        panelScrollView.snp.makeConstraints { make in
            make.top.equalTo(closePanelButton.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        
        // 创建内容容器
        let contentView = UIView()
        panelScrollView.addSubview(contentView)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(panelScrollView)
        }
        
        // 设置按钮样式
        let buttonConfig = { (button: UIButton, title: String, color: UIColor) in
            button.setTitle(title, for: .normal)
            button.backgroundColor = color
            button.layer.cornerRadius = 8
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            contentView.addSubview(button)
        }
        
        // 播放/暂停按钮
        buttonConfig(playPauseButton, "暂停", .systemBlue)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        
        // 停止按钮
        buttonConfig(stopButton, "停止", .systemRed)
        stopButton.addTarget(self, action: #selector(stopPlaying), for: .touchUpInside)
        
        // 缩放模式按钮
        buttonConfig(scalingButton, "缩放模式", .systemPurple)
        scalingButton.addTarget(self, action: #selector(changeScaling), for: .touchUpInside)
        
        // X轴旋转按钮
        buttonConfig(rotateXButton, "X轴旋转", .systemOrange)
        rotateXButton.addTarget(self, action: #selector(rotateX), for: .touchUpInside)
        
        // Y轴旋转按钮
        buttonConfig(rotateYButton, "Y轴旋转", .systemOrange)
        rotateYButton.addTarget(self, action: #selector(rotateY), for: .touchUpInside)
        
        // Z轴旋转按钮
        buttonConfig(rotateZButton, "Z轴旋转", .systemOrange)
        rotateZButton.addTarget(self, action: #selector(rotateZ), for: .touchUpInside)
        
        // 截图按钮
        buttonConfig(snapshotButton, "截图", .systemGreen)
        snapshotButton.addTarget(self, action: #selector(takeSnapshot), for: .touchUpInside)
        
        // 媒体选择器按钮
        buttonConfig(mediaButton, "选择媒体源", .systemTeal)
        mediaButton.addTarget(self, action: #selector(showMediaPicker), for: .touchUpInside)
        
        // 字幕按钮
        buttonConfig(subtitleButton, "字幕", .systemIndigo)
        subtitleButton.addTarget(self, action: #selector(handleSubtitle), for: .touchUpInside)
        
        // 逐帧按钮
        buttonConfig(frameButton, "逐帧", .systemPink)
        frameButton.addTarget(self, action: #selector(stepFrame), for: .touchUpInside)
        
        // 音频延迟
        buttonConfig(audioDelayButton, "音频延迟", .systemBrown)
        audioDelayButton.addTarget(self, action: #selector(adjustAudioDelay), for: .touchUpInside)
        
        // 字幕延迟
        if #available(iOS 15.0, *) {
            buttonConfig(subtitleDelayButton, "字幕延迟", .systemCyan)
        }
        subtitleDelayButton.addTarget(self, action: #selector(adjustSubtitleDelay), for: .touchUpInside)
        
        // 色彩调整
        buttonConfig(colorButton, "色彩", .systemYellow)
        colorButton.setTitleColor(.black, for: .normal)
        colorButton.addTarget(self, action: #selector(showColorSettings), for: .touchUpInside)
        
        // 画面比例
        if #available(iOS 15.0, *) {
            buttonConfig(aspectButton, "画面比例", .systemMint)
        }
        aspectButton.addTarget(self, action: #selector(showAspectSettings), for: .touchUpInside)
        
        // 快照类型按钮
        buttonConfig(snapshotTypeButton, "快照类型", .systemGray)
        snapshotTypeButton.addTarget(self, action: #selector(changeSnapshotType), for: .touchUpInside)
        
        // 画中画按钮
        buttonConfig(pipButton, "画中画", .systemBlue)
        pipButton.addTarget(self, action: #selector(togglePictureInPicture), for: .touchUpInside)
        
        // 全屏/半屏按钮
        buttonConfig(fullScreenButton, isFullScreen ? "半屏" : "全屏", .systemRed)
        fullScreenButton.addTarget(self, action: #selector(toggleFullScreen), for: .touchUpInside)
        
        // 横竖屏切换按钮
        let orientation = UIDevice.wy_currentInterfaceOrientation
        buttonConfig(orientationButton, (orientation == .portrait) ? "横屏" : "竖屏", .systemGreen)
        orientationButton.addTarget(self, action: #selector(toggleOrientation), for: .touchUpInside)
        
        // 音量滑块
        let volumeSliderTitle = UILabel()
        volumeSliderTitle.text = "音量"
        volumeSliderTitle.textColor = .white
        contentView.addSubview(volumeSliderTitle)
        
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 0.5
        volumeSlider.tintColor = .systemBlue
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        contentView.addSubview(volumeSlider)
        
        // 倍速滑块
        let rateSliderTitle = UILabel()
        rateSliderTitle.text = "倍速"
        rateSliderTitle.textColor = .white
        contentView.addSubview(rateSliderTitle)
        
        rateSlider.minimumValue = 0.5
        rateSlider.maximumValue = 2.0
        rateSlider.value = 1.0
        rateSlider.tintColor = .systemOrange
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        contentView.addSubview(rateSlider)
        
        // 进度滑块
        let seekSliderTitle = UILabel()
        seekSliderTitle.text = "进度"
        seekSliderTitle.textColor = .white
        contentView.addSubview(seekSliderTitle)
        
        seekSlider.minimumValue = 0
        seekSlider.maximumValue = 1
        seekSlider.tintColor = .systemGreen
        seekSlider.addTarget(self, action: #selector(seekChanged), for: .valueChanged)
        contentView.addSubview(seekSlider)
        
        // 信息标签
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = .white
        contentView.addSubview(infoLabel)
        
        stateLabel.numberOfLines = 0
        stateLabel.font = UIFont.systemFont(ofSize: 14)
        stateLabel.textColor = .white
        contentView.addSubview(stateLabel)
        
        streamLabel.numberOfLines = 0
        streamLabel.font = UIFont.systemFont(ofSize: 14)
        streamLabel.textColor = .white
        contentView.addSubview(streamLabel)
        
        // 布局所有控件
        let buttonWidth = (view.bounds.width - 48) / 3
        let buttonHeight: CGFloat = 44
        
        playPauseButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(buttonWidth)
            make.height.equalTo(buttonHeight)
        }
        
        stopButton.snp.makeConstraints { make in
            make.top.equalTo(playPauseButton)
            make.left.equalTo(playPauseButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        scalingButton.snp.makeConstraints { make in
            make.top.equalTo(playPauseButton)
            make.left.equalTo(stopButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        rotateXButton.snp.makeConstraints { make in
            make.top.equalTo(playPauseButton.snp.bottom).offset(16)
            make.left.equalTo(playPauseButton)
            make.width.height.equalTo(playPauseButton)
        }
        
        rotateYButton.snp.makeConstraints { make in
            make.top.equalTo(rotateXButton)
            make.left.equalTo(rotateXButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        rotateZButton.snp.makeConstraints { make in
            make.top.equalTo(rotateXButton)
            make.left.equalTo(rotateYButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        mediaButton.snp.makeConstraints { make in
            make.top.equalTo(rotateXButton.snp.bottom).offset(16)
            make.left.equalTo(playPauseButton)
            make.width.height.equalTo(playPauseButton)
        }
        
        subtitleButton.snp.makeConstraints { make in
            make.top.equalTo(mediaButton)
            make.left.equalTo(mediaButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        frameButton.snp.makeConstraints { make in
            make.top.equalTo(mediaButton)
            make.left.equalTo(subtitleButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        audioDelayButton.snp.makeConstraints { make in
            make.top.equalTo(mediaButton.snp.bottom).offset(16)
            make.left.equalTo(playPauseButton)
            make.width.height.equalTo(playPauseButton)
        }
        
        subtitleDelayButton.snp.makeConstraints { make in
            make.top.equalTo(audioDelayButton)
            make.left.equalTo(audioDelayButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        colorButton.snp.makeConstraints { make in
            make.top.equalTo(audioDelayButton)
            make.left.equalTo(subtitleDelayButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        aspectButton.snp.makeConstraints { make in
            make.top.equalTo(audioDelayButton.snp.bottom).offset(16)
            make.left.equalTo(playPauseButton)
            make.width.height.equalTo(playPauseButton)
        }
        
        snapshotButton.snp.makeConstraints { make in
            make.top.equalTo(aspectButton)
            make.left.equalTo(aspectButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        snapshotTypeButton.snp.makeConstraints { make in
            make.top.equalTo(aspectButton)
            make.left.equalTo(snapshotButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        // MARK: - 新增按钮布局
        pipButton.snp.makeConstraints { make in
            make.top.equalTo(snapshotTypeButton.snp.bottom).offset(16)
            make.left.equalTo(playPauseButton)
            make.width.height.equalTo(playPauseButton)
        }
        
        fullScreenButton.snp.makeConstraints { make in
            make.top.equalTo(pipButton)
            make.left.equalTo(pipButton.snp.right).offset(8)
            make.width.height.equalTo(playPauseButton)
        }
        
        orientationButton.snp.makeConstraints { make in
            make.top.equalTo(pipButton)
            make.left.equalTo(fullScreenButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(playPauseButton)
        }
        
        seekSliderTitle.snp.makeConstraints { make in
            make.top.equalTo(pipButton.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(35)
            make.height.equalTo(30)
        }
        
        seekSlider.snp.makeConstraints { make in
            make.top.equalTo(pipButton.snp.bottom).offset(20)
            make.left.equalTo(seekSliderTitle.snp.right).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        rateSliderTitle.snp.makeConstraints { make in
            make.top.equalTo(seekSlider.snp.bottom).offset(16)
            make.left.width.height.equalTo(seekSliderTitle)
        }
        
        rateSlider.snp.makeConstraints { make in
            make.top.equalTo(seekSlider.snp.bottom).offset(16)
            make.left.right.equalTo(seekSlider)
            make.height.equalTo(30)
        }
        
        volumeSliderTitle.snp.makeConstraints { make in
            make.top.equalTo(rateSlider.snp.bottom).offset(16)
            make.left.width.height.equalTo(seekSliderTitle)
        }
        
        volumeSlider.snp.makeConstraints { make in
            make.top.equalTo(rateSlider.snp.bottom).offset(16)
            make.left.right.equalTo(seekSlider)
            make.height.equalTo(30)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(volumeSlider.snp.bottom).offset(20)
            make.left.right.equalTo(seekSlider)
        }
        
        stateLabel.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(10)
            make.left.right.equalTo(seekSlider)
        }
        
        streamLabel.snp.makeConstraints { make in
            make.top.equalTo(stateLabel.snp.bottom).offset(10)
            make.left.right.equalTo(seekSlider)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    // 播放当前媒体
    func playCurrentMedia() {
        guard currentIndex < mediaList.count else { return }
        
        let media = mediaList[currentIndex]
        navigationItem.title = media.name
        
        WYActivity.showLoading(in: view, animation: .gifOrApng, config: WYActivityConfig.concise)
        player.play(with: media.url)
    }
    
    // 启动信息更新定时器
    func startInfoUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlayerInfo()
        }
    }
    
    // 更新播放器信息
    func updatePlayerInfo() {
        guard player.state == .playing || player.state == .buffering || player.state == .paused else { return }
        
        let duration = player.videoDuration()
        let currentTime = player.ijkPlayer?.currentPlaybackTime ?? 0
        let progress = duration > 0 ? Float(currentTime / duration) : 0
        
        seekSlider.setValue(progress, animated: true)
        
        let bufferingProgress = player.bufferingProgress()
        let downloadSpeed = player.downloadSpeed()
        let playableDuration = player.playableDuration()
        
        let speedMB = Double(downloadSpeed) / (1024 * 1024)
        
        infoLabel.text = """
        进度: \(String(format: "%.1f", currentTime))/\(String(format: "%.1f", duration))s
        缓冲: \(bufferingProgress)%
        可播时长: \(String(format: "%.1f", playableDuration))s
        下载速度: \(String(format: "%.2f", speedMB)) MB/s
        """
        
        stateLabel.text = "状态: \(playerStateDescription(player.state))"
        
        if let mediaMeta = player.ijkPlayer?.monitor.mediaMeta {
            streamLabel.text = "流信息: \(mediaMeta)"
        }
    }
    
    // 播放器状态描述
    func playerStateDescription(_ state: WYMediaPlayerState) -> String {
        switch state {
        case .unknown: return "未知"
        case .rendered: return "第一帧渲染"
        case .ready: return "准备就绪"
        case .playing: return "播放中"
        case .buffering: return "缓冲中"
        case .playable: return "可播放"
        case .paused: return "已暂停"
        case .interrupted: return "中断"
        case .seekingForward: return "快进"
        case .seekingBackward: return "快退"
        case .ended: return "结束"
        case .userExited: return "用户退出"
        case .error: return "错误"
        case .playUrlEmpty: return "空URL"
        }
    }
    
    // MARK: - 控制功能
    
    @objc func togglePlayPause() {
        if player.state == .playing {
            player.pause()
            playPauseButton.setTitle("播放", for: .normal)
            playPauseButton.backgroundColor = .systemGreen
        } else {
            player.play()
            playPauseButton.setTitle("暂停", for: .normal)
            playPauseButton.backgroundColor = .systemBlue
        }
    }
    
    @objc func stopPlaying() {
        player.stop(false)
    }
    
    @objc func volumeChanged() {
        player.playbackVolume(CGFloat(volumeSlider.value))
    }
    
    @objc func rateChanged() {
        player.playbackRate(CGFloat(rateSlider.value))
    }
    
    @objc func seekChanged() {
        let duration = player.videoDuration()
        let targetTime = TimeInterval(seekSlider.value) * duration
        player.playbackTime(targetTime)
    }
    
    @objc func changeScaling() {
        let currentMode = player.scalingStyle
        let nextMode: FSScalingMode
        
        switch currentMode {
        case .aspectFit:
            nextMode = .aspectFill
        case .aspectFill:
            nextMode = .fill
        default:
            nextMode = .aspectFit
        }
        
        player.scalingStyle(nextMode)
        showAlert(title: "缩放模式已更改", message: "当前模式: \(scalingModeDescription(nextMode))")
    }
    
    func scalingModeDescription(_ mode: FSScalingMode) -> String {
        switch mode {
        case .aspectFit: return "适应"
        case .aspectFill: return "填充"
        case .fill: return "拉伸"
        @unknown default: return "未知"
        }
    }
    
    @objc func rotateX() {
        rotatePreference.type = FSRotateX
        rotatePreference.degrees += 90
        if rotatePreference.degrees >= 360 {
            rotatePreference.degrees = 0
        }
        player.rotatePreference(rotatePreference)
        showAlert(title: "X轴旋转", message: "已旋转至 \(Int(rotatePreference.degrees))°")
    }
    
    @objc func rotateY() {
        rotatePreference.type = FSRotateY
        rotatePreference.degrees += 90
        if rotatePreference.degrees >= 360 {
            rotatePreference.degrees = 0
        }
        player.rotatePreference(rotatePreference)
        showAlert(title: "Y轴旋转", message: "已旋转至 \(Int(rotatePreference.degrees))°")
    }
    
    @objc func rotateZ() {
        rotatePreference.type = FSRotateZ
        rotatePreference.degrees += 90
        if rotatePreference.degrees >= 360 {
            rotatePreference.degrees = 0
        }
        player.rotatePreference(rotatePreference)
        showAlert(title: "Z轴旋转", message: "已旋转至 \(Int(rotatePreference.degrees))°")
    }
    
    @objc func takeSnapshot() {
        let snapshot = player.currentSnapshot()
        showAlert(title: "截图成功", message: "尺寸: \(snapshot.size)")
    }
    
    @objc func showMediaPicker() {
        let alert = UIAlertController(title: "选择媒体源", message: nil, preferredStyle: .actionSheet)
        
        for (index, media) in mediaList.enumerated() {
            alert.addAction(UIAlertAction(title: media.name, style: .default) { _ in
                self.currentIndex = index
                self.playCurrentMedia()
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = mediaButton
            popover.sourceRect = mediaButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func handleSubtitle() {
        let alert = UIAlertController(title: "字幕操作", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "加载并激活字幕", style: .default) { _ in
            if let url = self.subtitleList.randomElement() {
                self.player.loadThenActiveSubtitle(url)
                self.showAlert(title: "字幕加载", message: "已加载并激活字幕")
            }
        })
        
        alert.addAction(UIAlertAction(title: "关闭字幕流", style: .destructive) { _ in
            self.player.closeCurrentStream("FS_VAL_TYPE__SUBTITLE")
            self.showAlert(title: "字幕流关闭", message: "已关闭当前字幕流")
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = subtitleButton
            popover.sourceRect = subtitleButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func stepFrame() {
        player.stepToNextFrame()
        showAlert(title: "逐帧播放", message: "已前进一帧")
    }
    
    @objc func adjustAudioDelay() {
        let alert = UIAlertController(
            title: "音频延迟设置",
            message: "输入延迟时间（秒）",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "例如: 0.5 或 -0.3"
            textField.keyboardType = .decimalPad
            textField.text = "0.0"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, let delay = Double(text) {
                self.player.audioExtraDelay(CGFloat(delay))
                self.showAlert(title: "音频延迟设置", message: "已设置为 \(text)秒")
            } else {
                self.showAlert(title: "输入错误", message: "请输入有效的延迟时间")
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc func adjustSubtitleDelay() {
        let alert = UIAlertController(
            title: "字幕延迟设置",
            message: "输入延迟时间（秒）",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "例如: 0.5 或 -0.3"
            textField.keyboardType = .decimalPad
            textField.text = "0.0"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            if let text = alert.textFields?.first?.text, let delay = Double(text) {
                self.player.subtitleExtraDelay(CGFloat(delay))
                self.showAlert(title: "字幕延迟设置", message: "已设置为 \(text)秒")
            } else {
                self.showAlert(title: "输入错误", message: "请输入有效的延迟时间")
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc func showColorSettings() {
        let alert = UIAlertController(title: "色彩设置", message: "调整画面色彩", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "默认", style: .default) { _ in
            self.colorPreference.brightness = 1.0
            self.colorPreference.saturation = 1.0
            self.colorPreference.contrast = 1.0
            self.player.colorPreference(self.colorPreference)
            self.showAlert(title: "色彩设置", message: "已恢复默认色彩")
        })
        
        alert.addAction(UIAlertAction(title: "黑白", style: .default) { _ in
            self.colorPreference.saturation = 0.0
            self.player.colorPreference(self.colorPreference)
            self.showAlert(title: "色彩设置", message: "已设为黑白")
        })
        
        alert.addAction(UIAlertAction(title: "复古", style: .default) { _ in
            self.colorPreference.contrast = 1.5
            self.colorPreference.saturation = 0.8
            self.player.colorPreference(self.colorPreference)
            self.showAlert(title: "色彩设置", message: "已设为复古")
        })
        
        alert.addAction(UIAlertAction(title: "高亮度", style: .default) { _ in
            self.colorPreference.brightness = 1.5
            self.player.colorPreference(self.colorPreference)
            self.showAlert(title: "色彩设置", message: "已提高亮度")
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = colorButton
            popover.sourceRect = colorButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func showAspectSettings() {
        let alert = UIAlertController(title: "画面比例", message: "选择画面宽高比", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "默认", style: .default) { _ in
            self.aspectPreference.ratio = 0
            self.player.darPreference(self.aspectPreference)
        })
        
        alert.addAction(UIAlertAction(title: "4:3", style: .default) { _ in
            self.aspectPreference.ratio = 4.0/3.0
            self.player.darPreference(self.aspectPreference)
        })
        
        alert.addAction(UIAlertAction(title: "16:9", style: .default) { _ in
            self.aspectPreference.ratio = 16.0/9.0
            self.player.darPreference(self.aspectPreference)
        })
        
        alert.addAction(UIAlertAction(title: "1:1", style: .default) { _ in
            self.aspectPreference.ratio = 1.0
            self.player.darPreference(self.aspectPreference)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = aspectButton
            popover.sourceRect = aspectButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc func changeSnapshotType() {
        let alert = UIAlertController(title: "快照类型", message: "选择截图方式", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "原始尺寸(无字幕无特效)", style: .default) { _ in
            self.currentSnapshotType = FSSnapshotTypeOrigin
        })
        
        alert.addAction(UIAlertAction(title: "屏幕截图(当前画面)", style: .default) { _ in
            self.currentSnapshotType = FSSnapshotTypeScreen
        })
        
        alert.addAction(UIAlertAction(title: "原始尺寸(有字幕无特效)", style: .default) { _ in
            self.currentSnapshotType = FSSnapshotTypeEffect_Origin
        })
        
        alert.addAction(UIAlertAction(title: "原始尺寸(有字幕有特效)", style: .default) { _ in
            self.currentSnapshotType = FSSnapshotTypeEffect_Subtitle_Origin
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = snapshotTypeButton
            popover.sourceRect = snapshotTypeButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - 新增按钮功能
    
    // 切换画中画模式
    @objc func togglePictureInPicture() {
        guard let pipController = pipController else {
            showAlert(title: "画中画不可用", message: "无法初始化画中画控制器")
            return
        }
        
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
            pipButton.backgroundColor = .systemBlue
        } else {
            pipController.startPictureInPicture()
            pipButton.backgroundColor = .systemRed
        }
    }
    
    // 切换全屏/半屏模式
    @objc func toggleFullScreen() {
        isFullScreen.toggle()
        
        player.snp.remakeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            
            if isFullScreen {
                make.bottom.equalToSuperview()
                fullScreenButton.setTitle("半屏", for: .normal)
            } else {
                make.height.equalTo(view.snp.height).multipliedBy(0.5)
                fullScreenButton.setTitle("全屏", for: .normal)
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // 横竖屏切换
    @objc func toggleOrientation() {
        // 这里只实现按钮状态切换，具体横竖屏实现由您完成
        let orientation = UIDevice.wy_currentInterfaceOrientation
        if orientation == .portrait {
            orientationButton.backgroundColor = .systemOrange
            orientationButton.setTitle("竖屏", for: .normal)
            UIDevice.wy_setInterfaceOrientation = .landscapeLeft
        } else {
            orientationButton.backgroundColor = .systemGreen
            orientationButton.setTitle("横屏", for: .normal)
            UIDevice.wy_setInterfaceOrientation = .portrait
        }
    }
    
    // 显示/隐藏控制面板
    @objc func toggleControlPanel() {
        isControlPanelVisible.toggle()
        
        if isControlPanelVisible {
            controlPanel.isHidden = false
            controlPanel.transform = CGAffineTransform(translationX: 0, y: -controlPanel.bounds.height)
            UIView.animate(withDuration: 0.3) {
                self.controlPanel.transform = .identity
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.controlPanel.transform = CGAffineTransform(translationX: 0, y: -self.controlPanel.bounds.height)
            }) { _ in
                self.controlPanel.isHidden = true
            }
        }
    }
    
    // 显示提示
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.wy_setInterfaceOrientation = .portrait
    }
    
    deinit {
        updateTimer?.invalidate()
        player.releaseAll()
        WYLogManager.output("WYTestLiveStreamingController release")
    }
}

// MARK: - 播放器代理
extension WYTestLiveStreamingController: WYMediaPlayerDelegate {
    
    func mediaPlayerDidChangeState(player: WYMediaPlayer, state: WYMediaPlayerState) {
        switch state {
        case .unknown:
            WYLogManager.output("未知状态")
        case .rendered:
            WYLogManager.output("第一帧渲染完成")
            WYActivity.dismissLoading(in: view, animate: false)
        case .ready:
            WYLogManager.output("可以播放了")
        case .playing:
            WYLogManager.output("正在播放：\(player.mediaUrl)")
            WYActivity.dismissLoading(in: view, animate: false)
        case .buffering:
            WYLogManager.output("缓冲中")
            WYActivity.showLoading(in: view, animation: .gifOrApng, config: WYActivityConfig.concise)
        case .playable:
            WYLogManager.output("缓冲结束")
            WYActivity.dismissLoading(in: view, animate: false)
        case .paused:
            WYLogManager.output("播放暂停")
            WYActivity.dismissLoading(in: view, animate: false)
        case .interrupted:
            WYLogManager.output("播放被中断")
            WYActivity.dismissLoading(in: view, animate: false)
        case .seekingForward:
            WYLogManager.output("快进")
            WYActivity.showLoading(in: view, animation: .gifOrApng, config: WYActivityConfig.concise)
        case .seekingBackward:
            WYLogManager.output("快退")
            WYActivity.showLoading(in: view, animation: .gifOrApng, config: WYActivityConfig.concise)
        case .ended:
            WYLogManager.output("播放完毕")
            WYActivity.dismissLoading(in: view, animate: false)
            if isControlPanelVisible {
                toggleControlPanel()
            }
            currentIndex = ((currentIndex + 1) > mediaList.count) ? 0 : (currentIndex + 1)
            playCurrentMedia()
        case .userExited:
            WYLogManager.output("用户中断播放")
            WYActivity.dismissLoading(in: view, animate: false)
        case .error:
            WYLogManager.output("播放出现异常")
            WYActivity.dismissLoading(in: view, animate: false)
        case .playUrlEmpty:
            WYLogManager.output("播放为空")
            WYActivity.dismissLoading(in: view, animate: false)
        }
    }
    
    func mediaPlayerDidChangeSubtitleStream(player: WYMediaPlayer, mediaMeta: [AnyHashable : Any]) {
        streamLabel.text = "流信息: \(mediaMeta)"
    }
}

// MARK: - 画中画代理
extension WYTestLiveStreamingController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipButton.backgroundColor = .systemRed
        pipButton.setTitle("退出画中画", for: .normal)
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipButton.backgroundColor = .systemBlue
        pipButton.setTitle("画中画", for: .normal)
    }
}

extension WYTestLiveStreamingController {
    
    // 设置播放列表
    func setupMediaList() {
        mediaList =  [
            ("外国公园", "https://files.cochat.lenovo.com/download/dbb26a06-4604-3d2b-bb2c-6293989e63a7/55deb281e01b27194daf6da391fdfe83.mp4"),
            ("棕熊与鸟", "http://www.w3school.com.cn/i/movie.mp4"),
            ("勇闯冰川", "https://media.w3.org/2010/05/sintel/trailer.mp4"),
            ("哔啵", "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"),
            ("雍正王朝", "https://live.metshop.top/douyu/74374"),
            ("万合出品", "https://live.metshop.top/douyu/9220456"),
            ("周星驰", "https://live.metshop.top/huya/11342412"),
            ("林正英", "https://live.metshop.top/huya/11342421"),
            ("漫威君", "https://live.metshop.top/douyu/1713615"),
            ("小黛兮(别扫码，只测试)", "https://live.metshop.top/douyu/11553944"),
            ("动物世界", "https://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8"),
            ("动漫世界", "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"),
            ("海底盛宴", "http://vjs.zencdn.net/v/oceans.mp4"),
            ("胆子不小的郑吉祥", "https://live.metshop.top/douyu/9171887"),
            ("宇宙探索飞船", "https://live.metshop.top/douyu/9456028"),
            ("堇姑娘", "https://live.metshop.top/douyu/297689"),
            ("十七岁的道姑", "https://live.metshop.top/douyu/3186217"),
            ("工藤新医heart", "https://live.metshop.top/douyu/8741860"),
            ("粤语电影丶", "https://live.metshop.top/douyu/1226741"),
            ("我砸晕了牛顿奥", "https://live.metshop.top/douyu/1218414"),
            ("小姐姐不记得", "https://live.metshop.top/douyu/3700024"),
            ("魔术师丶西索", "https://live.metshop.top/douyu/6610883"),
            ("v刺猬猪v", "https://live.metshop.top/douyu/2436390"),
            ("周星驰", "https://live.metshop.top/huya/11342412"),
            ("林正英", "https://live.metshop.top/huya/11342421"),
            ("萌新司机", "https://live.metshop.top/huya/11352881"),
            ("四大裁子之首", "https://live.metshop.top/huya/11602058"),
            ("核桃姐姐", "https://live.metshop.top/huya/11342390"),
            ("铁血真汉子", "https://live.metshop.top/huya/11342395"),
            ("嫣然", "https://live.metshop.top/huya/11601977"),
            ("元芳看不到", "https://live.metshop.top/huya/11342414"),
            ("yoo", "https://live.metshop.top/huya/11352876"),
            ("喜来乐狮子头", "https://live.metshop.top/huya/21059580"),
            ("春晚1983", "https://alimov2.a.kwimgs.com/upic/2022/01/31/15/BMjAyMjAxMzExNTU5MTRfNDAzMDAxOTlfNjYyNzMxNjcwMjBfMF8z_b_Beb3bda599f76c60c463c433ca7460153.mp4"),
            ("春晚1984", "https://alimov2.a.kwimgs.com/upic/2022/01/31/15/BMjAyMjAxMzExNTU5NTRfNDAzMDAxOTlfNjYyNzMyMzg3MTRfMF8z_b_B192356dadbc90d207ba16964d4c2914c.mp4"),
            ("春晚1985", "https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDFfNDAzMDAxOTlfNjYyNzMyNTAwMzJfMF8z_b_Be73c5abcbc0eeb2ec9fce6842e1362a4.mp4"),
            ("春晚1986", "https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDRfNDAzMDAxOTlfNjYyNzMyNTU0OTRfMF8z_b_B24f7d19f1132fa5d7f502f8377ad5567.mp4"),
            ("春晚1987", "https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMDhfNDAzMDAxOTlfNjYyNzMyNjMyMDNfMF8z_b_B570493ed8f7200d4013a66b2d21b2de9.mp4"),
            ("春晚1988", "https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMTJfNDAzMDAxOTlfNjYyNzMyNjkxNjBfMF8z_b_B8c835b83a92d25bde81ba22c5cd9521e.mp4"),
            ("春晚1989", "https://alimov2.a.kwimgs.com/upic/2022/01/31/16/BMjAyMjAxMzExNjAwMTVfNDAzMDAxOTlfNjYyNzMyNzQ2OTlfMF8z_b_Be477b27b9ce655d2372df56a5a3d96ef.mp4"),
            ("春晚1990", "https://cdn8.yzzy-online.com/20220704/597_e0d90c37/1000k/hls/index.m3u8"),
            ("春晚1992", "https://txmov2.a.kwimgs.com/bs3/video-hls/5256826755663896297_hlshd15.m3u8"),
            ("春晚1993", "https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYwODJfMF8z_b_B647d10e431b4cc5e48e6c77347d69021.mp4"),
            ("春晚1994", "https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYxMjNfMF8z_b_B3dde97f36273f04403d4dc5eec611a35.mp4"),
            ("春晚1995", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQwNzVfMF8z_b_B811c0dec6b9a3d3074a18522c185010a.mp4"),
            ("春晚1996", "https://alimov2.a.kwimgs.com/upic/2023/01/13/22/BMjAyMzAxMTMyMjEwMDNfNDAzMDAxOTlfOTM1MTIzMzYxNTJfMF8z_b_Bd841eae10ab1c9955ef55fbedfae6c45.mp4"),
            ("春晚1997", "https://txmov2.a.kwimgs.com/bs3/video-hls/5230649583590411879_hlshd15.m3u8"),
            ("春晚1998", "https://txmov2.a.kwimgs.com/bs3/video-hls/5225864507896315430_hlshd15.m3u8"),
            ("春晚1999", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQxNTRfMF8z_b_B0b5e52bc003285ef66ec0cbb2be08556.mp4"),
            ("春晚2000", "https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxMTNfMF8z_b_Bdddf4e7ef0ff6cfd477857bb40e78419.mp4"),
            ("春晚2001", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyMDFfMF8z_b_B70592cb7c4054e9cabb675e849bbf4bd.mp4"),
            ("春晚2002", "https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxNDdfMF8z_b_Ba6271d10b7e6cfae83759033a091f257.mp4"),
            ("春晚2003", "https://alimov2.a.kwimgs.com/upic/2023/01/14/23/BMjAyMzAxMTQyMzQxNDdfNDAzMDAxOTlfOTM2MTU0MTk1NDFfMF8z_b_B182749d2cd2ea9323639254af385f24b.mp4"),
            ("春晚2004", "https://alimov2.a.kwimgs.com/upic/2023/01/13/21/BMjAyMzAxMTMyMTE4MzRfNDAzMDAxOTlfOTM1MDY4ODIxOTVfMF8z_b_B86c4430b82ff5a7f4e8132f6ee558536.mp4"),
            ("春晚2005", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyMzhfMF8z_b_B35ad7cc86aec8fc9e5ddfb31fc7bed63.mp4"),
            ("春晚2006", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQyNzlfMF8z_b_Bbc3703fc331dc994c50859c19aad28ff.mp4"),
            ("春晚2007", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzMjNfMF8z_b_B00b069c7899976459ceeaa99353dfefe.mp4"),
            ("春晚2008", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzNTNfMF8z_b_Bd7346962e61bd7b84e11a1fa6e4616f9.mp4"),
            ("春晚2009", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQzOTBfMF8z_b_B29a36a85e0277f6c2a1f033ef7c10708.mp4"),
            ("春晚2010", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ0MjlfMF8z_b_B8818807a00eed329a69fb494f405bd43.mp4"),
            ("春晚2011", "https://alimov2.a.kwimgs.com/upic/2023/01/16/11/BMjAyMzAxMTYxMTA3MjFfNDAzMDAxOTlfOTM3MjcyMjA3ODhfMF8z_b_B8214200efc869dc6fcf99dad619fa4c1.mp4"),
            ("春晚2012", "https://cdn8.yzzy-online.com/20220704/591_82b72f82/1000k/hls/index.m3u8"),
            ("春晚2013", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ1NjNfMF8z_b_B4fea55408dca4471a68a963ae096be59.mp4"),
            ("春晚2014", "https://alimov2.a.kwimgs.com/upic/2023/01/06/16/BMjAyMzAxMDYxNjMxMTNfNDAzMDAxOTlfOTI4OTY2ODAzNjlfMF8z_b_Bdee65c77f9e7b2120a185c919dad81d2.mp4"),
            ("春晚2015", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ2MTZfMF8z_b_B4851f43f5a2bc2871a9b0ec87294a6e7.mp4"),
            ("春晚2016", "https://cdn8.yzzy-online.com/20220704/577_cda9c8d1/1000k/hls/index.m3u8"),
            ("春晚2017", "https://alimov2.a.kwimgs.com/upic/2023/01/13/20/BMjAyMzAxMTMyMDA5MjJfNDAzMDAxOTlfOTM0OTkwNDQ2NDhfMF8z_b_B6527b0c2ce3dda1d9b3f34edd4fdb9aa.mp4"),
            ("春晚2018", "https://alimov2.a.kwimgs.com/upic/2023/01/06/16/BMjAyMzAxMDYxNjMxMTRfNDAzMDAxOTlfOTI4OTY2ODE2MTBfMF8z_b_B11a778e34390a21de42d407e94f45b91.mp4"),
            ("春晚2020", "https://alimov2.a.kwimgs.com/upic/2022/01/30/17/BMjAyMjAxMzAxNzA5NDdfNDAzMDAxOTlfNjYxNzQ2MDAyMTFfMF8z_b_B5d51d9564c5670dc66faeba20aa7af3f.mp4"),
            ("春晚2021", "https://alimov2.a.kwimgs.com/upic/2022/01/30/17/BMjAyMjAxMzAxNzE4NTJfNDAzMDAxOTlfNjYxNzUzOTg3NjlfMF8z_b_Be41d9503181d7b0608a839ed401e02c2.mp4"),
            ("春晚2022", "https://alimov2.a.kwimgs.com/upic/2022/02/01/11/BMjAyMjAyMDExMTEwMjNfNDAzMDAxOTlfNjYzNzA4MTk4NzNfMF8z_b_B898cc7ddd0025bf54ddb18ec1f723c84.mp4"),
            ("春晚2023", "https://txmov2.a.kwimgs.com/bs3/video-hls/5251197255879398624_hlshd15.m3u8"),
            ("韩国DJSodaRemix2021电音", "https://vd3.bdstatic.com/mda-mev3hw0htz28h5wn/1080p/cae_h264/1622343504467773766/mda-mev3hw0htz28h5wn.mp4"),
            ("韩国歌团001", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240095359203.mp4"),
            ("韩国歌团002", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239978750464.mp4"),
            ("韩国歌团003", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239858729476.mp4"),
            ("韩国歌团004", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239755956819.mp4"),
            ("韩国歌团005", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239987758613.mp4"),
            ("韩国歌团006", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239880949246.mp4"),
            ("韩国歌团007", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239903717006.mp4"),
            ("韩国歌团008", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239903321355.mp4"),
            ("韩国歌团009", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239799872402.mp4"),
            ("韩国歌团010", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239799088974.mp4"),
            ("韩国歌团011", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240024786285.mp4"),
            ("韩国歌团012", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240142715042.mp4"),
            ("韩国歌团013", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240025046562.mp4"),
            ("韩国歌团014", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240145171654.mp4"),
            ("韩国歌团015", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240147051191.mp4"),
            ("韩国歌团016", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239805200933.mp4"),
            ("韩国歌团017", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239910253332.mp4"),
            ("韩国歌团018", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239806164759.mp4"),
            ("韩国歌团019", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239807872136.mp4"),
            ("韩国歌团020", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240032526123.mp4"),
            ("歌团★021", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239808028600.mp4"),
            ("歌团★022", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240031614983.mp4"),
            ("歌团★023", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240150331617.mp4"),
            ("歌团★024", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239809100782.mp4"),
            ("歌团★025", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151167718.mp4"),
            ("歌团★026", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240033362815.mp4"),
            ("歌团★027", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151167938.mp4"),
            ("歌团★029", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239811800375.mp4"),
            ("歌团★030", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239916285148.mp4"),
            ("歌团★031", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239927589941.mp4"),
            ("歌团★032", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239931661209.mp4"),
            ("歌团★033", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240171579858.mp4"),
            ("歌团★034", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239831144046.mp4"),
            ("歌团★035", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240056530470.mp4"),
            ("歌团★036", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239832040344.mp4"),
            ("歌团★037", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240173879894.mp4"),
            ("歌团★038", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240057078179.mp4"),
            ("歌团★040", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240059018784.mp4"),
            ("歌团★041", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239834324813.mp4"),
            ("歌团★042", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239834716201.mp4"),
            ("歌团★043", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239837532125.mp4"),
            ("歌团★044", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240179867562.mp4"),
            ("歌团★045", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240063650207.mp4"),
            ("歌团★046", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181243061.mp4"),
            ("歌团★047", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181363115.mp4"),
            ("歌团★048", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239944465251.mp4"),
            ("歌团★049", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240065122134.mp4"),
            ("歌团★050", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239840536452.mp4"),
            ("歌团★051", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240065838644.mp4"),
            ("歌团★052", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239945877111.mp4"),
            ("歌团★053", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240184339138.mp4"),
            ("歌团★054", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239842640589.mp4"),
            ("歌团★055", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240186067562.mp4"),
            ("歌团★056", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240187071401.mp4"),
            ("歌团★057", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240069974546.mp4"),
            ("歌团★058", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070346911.mp4"),
            ("歌团★059", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070818783.mp4"),
            ("歌团★060", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239846692034.mp4"),
            ("歌团★061", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239951329234.mp4"),
            ("歌团★062", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240191295627.mp4"),
            ("歌团★063", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240026585459.mp4"),
            ("歌团★064", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240192067467.mp4"),
            ("歌团★065", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239911732892.mp4"),
            ("歌团★066", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240196491782.mp4"),
            ("歌团★067", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239960909980.mp4"),
            ("歌团★068", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240017737344.mp4"),
            ("歌团★069", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240202339353.mp4"),
            ("歌团★070", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240203243765.mp4"),
            ("歌团★071", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240205555546.mp4"),
            ("歌团★072", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239983417489.mp4"),
            ("歌团★074", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240221687198.mp4"),
            ("歌团★075", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240222023079.mp4"),
            ("歌团★076", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240107150280.mp4"),
            ("歌团★077", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240224523227.mp4"),
            ("歌团★078", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239987569147.mp4"),
            ("歌团★079", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225803033.mp4"),
            ("歌团★080", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239989445779.mp4"),
            ("歌团★081", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240229579224.mp4"),
            ("歌团★082", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239993533054.mp4"),
            ("歌团★083", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994225085.mp4"),
            ("歌团★084", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994741288.mp4"),
            ("歌团★085", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239995197198.mp4"),
            ("歌团★086", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240232939168.mp4"),
            ("歌团★087", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239890536417.mp4"),
            ("歌团★088", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239890568711.mp4"),
            ("歌团★089", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240233783820.mp4"),
            ("歌团★090", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239894180409.mp4"),
            ("歌团★092", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239895496483.mp4"),
            ("歌团★093", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240119938989.mp4"),
            ("歌团★094", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240002397273.mp4"),
            ("歌团★095", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240241527208.mp4"),
            ("歌团★096", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239899840062.mp4"),
            ("歌团★097", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240243499351.mp4"),
            ("歌团★098", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240127638122.mp4"),
            ("歌团★099", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240030505796.mp4"),
            ("歌团★100", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240245283772.mp4"),
            ("歌团★101", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240247623420.mp4"),
            ("歌团★102", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240043672242.mp4"),
            ("歌团★103", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240339124000.mp4"),
            ("歌团★104", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240221702622.mp4"),
            ("歌团★105", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239993732827.mp4"),
            ("歌团★106", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239994460907.mp4"),
            ("歌团★107", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240340899550.mp4"),
            ("歌团★108", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239995692215.mp4"),
            ("歌团★109", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240341971789.mp4"),
            ("歌团★110", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239996664565.mp4"),
            ("歌团★111", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240342839842.mp4"),
            ("歌团★112", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225254466.mp4"),
            ("歌团★113", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240225226897.mp4"),
            ("歌团★114", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239998000351.mp4"),
            ("歌团★115", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240105989528.mp4"),
            ("歌团★116", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/239998340711.mp4"),
            ("歌团★117", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240106477140.mp4"),
            ("歌团★118", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240107389699.mp4"),
            ("歌团★119", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240345787129.mp4"),
            ("歌团★120", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240227966801.mp4"),
            ("歌团★121", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240228462625.mp4"),
            ("歌团★122", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240108721427.mp4"),
            ("歌团★123", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001176191.mp4"),
            ("歌团★125", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001228776.mp4"),
            ("歌团★126", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240109533631.mp4"),
            ("歌团★127", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240347663598.mp4"),
            ("歌团★128", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240001932458.mp4"),
            ("歌团★129", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240002044738.mp4"),
            ("歌团★130", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240111085001.mp4"),
            ("歌团★131", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240350575186.mp4"),
            ("歌团★132", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240350771160.mp4"),
            ("歌团★133", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240113261859.mp4"),
            ("歌团★134", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240352039996.mp4"),
            ("歌团★135", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240236014123.mp4"),
            ("歌团★136", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240008036293.mp4"),
            ("歌团★137", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240354863286.mp4"),
            ("歌团★138", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240008780109.mp4"),
            ("歌团★139", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240009608741.mp4"),
            ("歌团★140", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240379515679.mp4"),
            ("歌团★141", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240262842385.mp4"),
            ("歌团★142", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240264262344.mp4"),
            ("歌团★143", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240384227055.mp4"),
            ("歌团★145", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240267170778.mp4"),
            ("歌团★146", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240386743317.mp4"),
            ("歌团★147", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240268654616.mp4"),
            ("歌团★148", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240387107547.mp4"),
            ("歌团★149", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240150573492.mp4"),
            ("歌团★150", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240388683474.mp4"),
            ("歌团★151", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240270774376.mp4"),
            ("歌团★152", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240151273206.mp4"),
            ("歌团★153", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240389031565.mp4"),
            ("韩国太妍02", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240167997205.mp4"),
            ("韩国太妍03", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240059400880.mp4"),
            ("韩国太妍04", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240407847242.mp4"),
            ("韩国太妍05", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240062596020.mp4"),
            ("韩国太妍06", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240170661907.mp4"),
            ("韩国太妍07", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240411259014.mp4"),
            ("韩国太妍08", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240174309994.mp4"),
            ("韩国太妍09", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240175225325.mp4"),
            ("韩国太妍10", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240066736888.mp4"),
            ("韩国太妍11", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240175161903.mp4"),
            ("韩国太妍12", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240295526170.mp4"),
            ("韩国太妍13", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240295818399.mp4"),
            ("韩国太妍14", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240177321736.mp4"),
            ("韩国太妍15", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240177941288.mp4"),
            ("韩国太妍16", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070652257.mp4"),
            ("韩国太妍17", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240298266546.mp4"),
            ("韩国太妍18", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240070884570.mp4"),
            ("韩国太妍19", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240298694512.mp4"),
            ("韩国太妍20", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240418087243.mp4"),
            ("韩国太妍21", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240299394846.mp4"),
            ("韩国太妍22", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240181409471.mp4"),
            ("韩国太妍23", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240182993056.mp4"),
            ("韩国太妍24", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240301854532.mp4"),
            ("韩国太妍25", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240075164377.mp4"),
            ("韩国太妍26", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240349762400.mp4"),
            ("韩国太妍27", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240121912724.mp4"),
            ("韩国太妍28", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240126480392.mp4"),
            ("韩国太妍29", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240355262537.mp4"),
            ("韩国太妍30", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240355734488.mp4"),
            ("韩国太妍31", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240237453313.mp4"),
            ("韩国太妍32", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240130092025.mp4"),
            ("韩国太妍33", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240478207039.mp4"),
            ("韩国太妍34", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240361330093.mp4"),
            ("韩国太妍35", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240139316317.mp4"),
            ("韩国太妍36", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240248465975.mp4"),
            ("韩国太妍37", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240139720035.mp4"),
            ("韩国太妍38", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240368550193.mp4"),
            ("韩国太妍40", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240370230905.mp4"),
            ("韩国太妍41", "https://cloud.video.taobao.com//play/u/57349687/p/1/e/6/t/1/240160716008.mp4"),
            ("献血车(本地)", URL(fileURLWithPath: Bundle.main.path(forResource: "mpeg4_local", ofType: "mp4").wy_safe).absoluteString),
            ("某办公楼", URL(fileURLWithPath: Bundle.main.path(forResource: "1650855755919", ofType: "mp4").wy_safe).absoluteString)]
        
        // 示例字幕（实际使用时替换为真实URL）
        subtitleList = [
            URL(string: "https://example.com/subtitle1.srt")!,
            URL(string: "https://example.com/subtitle2.srt")!,
            URL(string: "https://example.com/subtitle3.srt")!
        ]
    }
}
