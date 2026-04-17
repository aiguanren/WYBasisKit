//
//  WYTestAudioController.swift
//  WYBasiskitVerify
//
//  Created by guanren on 2025/8/12.
//

import UIKit
import AVFoundation

class WYVoiceWaveView: UIView {
    private let barCount = 20
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private var barHeights: [CGFloat] = []   // 每个条形的当前高度
    private var targetHeights: [CGFloat] = [] // 每个条形的目标高度
    private var displayLink: CADisplayLink?
    private let smoothing: CGFloat = 0.6   // 平滑系数，值越小过渡越慢（0~1）
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
        startDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
        startDisplayLink()
    }
    
    private func setupBars() {
        // 初始化数组
        barHeights = Array(repeating: 0, count: barCount)
        targetHeights = Array(repeating: 0, count: barCount)
    }
    
    /// 更新音量能量值（由外部调用，传入归一化值 0~1）
    func updatePower(_ normalizedPower: Float) {
        let power = CGFloat(max(0, min(1, normalizedPower)))
        let maxHeight = bounds.height > 0 ? bounds.height : 60
        // 计算每个条形的目标高度（应用正弦因子，使中间高两边低）
        for i in 0..<barCount {
            let factor = sin(CGFloat(i) / CGFloat(barCount) * .pi)
            let target = maxHeight * power * factor
            targetHeights[i] = max(1, target)   // 最小高度1像素
        }
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateHeights))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateHeights() {
        var needsRedraw = false
        for i in 0..<barCount {
            let diff = targetHeights[i] - barHeights[i]
            // 如果音量突然降低超过 8 像素，直接跳变，不进行平滑
            if diff < -8 {
                barHeights[i] = targetHeights[i]
                needsRedraw = true
            } else if abs(diff) > 0.1 {
                barHeights[i] += diff * smoothing
                needsRedraw = true
            } else {
                barHeights[i] = targetHeights[i]
            }
        }
        if needsRedraw {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let maxHeight = bounds.height
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        var x = (bounds.width - totalWidth) / 2
        context.setFillColor(UIColor.systemBlue.cgColor)
        
        for i in 0..<barCount {
            let height = barHeights[i]
            let y = maxHeight - height
            let barRect = CGRect(x: x, y: y, width: barWidth, height: height)
            context.fill(barRect)
            x += barWidth + barSpacing
        }
    }
    
    // 兼容原有接口（如果不需要额外操作可留空）
    func startAnimating() { }
    func stopAnimating() { }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
}

// MARK: - 下载任务卡片视图（保持不变）
class DownloadTaskCardView: UIView {
    let urlTextField = UITextField()
    let progressLabel = UILabel()
    let progressBar = UIProgressView()
    let downloadButton = UIButton(type: .system)
    let pauseButton = UIButton(type: .system)
    let resumeButton = UIButton(type: .system)
    let cancelButton = UIButton(type: .system)
    let deleteButton = UIButton(type: .system)
    
    var url: URL? { URL(string: urlTextField.text ?? "") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 8
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.cgColor
        
        urlTextField.borderStyle = .roundedRect
        urlTextField.placeholder = "音频URL"
        urlTextField.font = .systemFont(ofSize: 12)
        
        progressLabel.font = .systemFont(ofSize: 12)
        progressLabel.text = "进度: 0%"
        
        progressBar.progressTintColor = .systemGreen
        
        downloadButton.setTitle("下载", for: .normal)
        downloadButton.titleLabel?.font = .systemFont(ofSize: 12)
        pauseButton.setTitle("暂停", for: .normal)
        pauseButton.titleLabel?.font = .systemFont(ofSize: 12)
        resumeButton.setTitle("恢复", for: .normal)
        resumeButton.titleLabel?.font = .systemFont(ofSize: 12)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 12)
        deleteButton.setTitle("删除", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 12)
        deleteButton.setTitleColor(.red, for: .normal)
        
        let buttonStack = UIStackView(arrangedSubviews: [downloadButton, pauseButton, resumeButton, cancelButton, deleteButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 6
        
        let stack = UIStackView(arrangedSubviews: [urlTextField, progressLabel, progressBar, buttonStack])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}

/// 测试音频控制器
class WYTestAudioController: UIViewController {
    
    /// 音频工具实例
    private let audioKit: WYAudioKit = WYAudioKit()
    
    /// 当前播放音频的总时长（用于seek）
    private var currentPlayingDuration: TimeInterval = 0
    
    /// 界面元素
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoTextView = UITextView()
    
    // 录音控制
    private let recordButton = UIButton(type: .system)
    private let pauseRecordButton = UIButton(type: .system)
    private let stopRecordButton = UIButton(type: .system)
    private let resumeRecordButton = UIButton(type: .system)
    private let voiceWaveView = WYVoiceWaveView()
    
    // 播放控制
    private let playButton = UIButton(type: .system)
    private let pausePlayButton = UIButton(type: .system)
    private let stopPlayButton = UIButton(type: .system)
    private let resumePlayButton = UIButton(type: .system)
    private let seekButton = UIButton(type: .system)
    private let seekSlider = UISlider()
    private let rateSlider = UISlider()
    private let rateLabel = UILabel()
    
    // 进度显示
    private let recordProgressLabel = UILabel()
    private let playProgressLabel = UILabel()
    private let downloadProgressLabel = UILabel()
    private let conversionProgressLabel = UILabel()
    
    // 设置控件
    private let minDurationSlider = UISlider()
    private let maxDurationSlider = UISlider()
    private let minDurationLabel = UILabel()
    private let maxDurationLabel = UILabel()
    private let qualitySegmentedControl = UISegmentedControl(items: ["低", "中", "高"])
    private let formatPicker = UIPickerView()
    private let storageDirSegmentedControl = UISegmentedControl(items: ["临时", "文档", "缓存"])
    
    // 网络音频 - 多任务管理
    private let downloadTasksContainer = UIView()
    private let addTaskButton = UIButton(type: .system)
    private var taskCards: [DownloadTaskCardView] = []
    private var containerHeightConstraint: NSLayoutConstraint?
    
    // 单个下载控件（保留原有）
    private let remoteURLField = UITextField()
    private let downloadButton = UIButton(type: .system)
    private let streamingButton = UIButton(type: .system)
    
    // 文件管理
    private let fileLabel = UILabel()
    private let fileListTextView = UITextView()
    private let refreshFilesButton = UIButton(type: .system)
    private let saveRecordButton = UIButton(type: .system)
    private let deleteRecordButton = UIButton(type: .system)
    private let deleteAllRecordingsButton = UIButton(type: .system)
    private let deleteAllDownloadsButton = UIButton(type: .system)
    
    // 格式转换
    private let convertLabel = UILabel()
    private let targetFormatPicker = UIPickerView()
    private let convertButton = UIButton(type: .system)
    
    // 其他功能
    private let playRecordedButton = UIButton(type: .system)
    private let customSettingsButton = UIButton(type: .system)
    private let releaseButton = UIButton(type: .system)
    
    /// 支持的录音格式（所有格式）
    private let supportedFormats: [WYAudioFormat] = [
        .aac, .wav, .caf, .m4a, .aiff, .mp3, .flac, .au, .amr, .ac3, .eac3
    ]
    
    /// 支持的转换格式（仅限 AVAssetExportSession 支持的格式）
    private let supportedConvertFormats: [WYAudioFormat] = [
        .aac, .m4a, .caf, .wav, .aiff
    ]
    
    /// 当前选中的格式
    private var selectedFormat: WYAudioFormat = .aac
    
    /// 当前选中的目标格式
    private var targetFormat: WYAudioFormat = .mp3
    
    /// 最小录音时长
    private var minRecordingDuration: TimeInterval = 0 {
        didSet {
            minDurationLabel.text = "最短时长: \(String(format: "%.1f", minRecordingDuration))秒"
        }
    }
    
    /// 最大录音时长
    private var maxRecordingDuration: TimeInterval = 60 {
        didSet {
            maxDurationLabel.text = "最长时长: \(String(format: "%.1f", maxRecordingDuration))秒"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "音频工具测试"
        
        setupUI()
        setupAudioKit()
        refreshFileList()
        addDefaultDownloadTasks()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = contentView.frame.size
    }
    
    private func setupAudioKit() {
        audioKit.delegate = self
        audioKit.minimumRecordDuration = minRecordingDuration
        audioKit.maximumRecordDuration = maxRecordingDuration
        
        /// 检查是否拥有麦克风权限
        wy_authorizeMicrophoneAccess(showSettingsAlert: true) { [weak self] authorized in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let status = authorized ? "已授权" : "未授权"
                self.logInfo("录音权限: \(status)")
            }
        }
    }
    
    private func addDefaultDownloadTasks() {
        let urls = [
            "http://music.163.com/song/media/outer/url?id=1466027974.mp3",
            "http://music.163.com/song/media/outer/url?id=2105354877.mp3"
        ]
        for urlString in urls {
            addDownloadTask(with: urlString)
        }
    }
    
    private func addDownloadTask(with urlString: String = "") {
        let card = DownloadTaskCardView()
        card.urlTextField.text = urlString
        card.downloadButton.addTarget(self, action: #selector(downloadTask(_:)), for: .touchUpInside)
        card.pauseButton.addTarget(self, action: #selector(pauseTask(_:)), for: .touchUpInside)
        card.resumeButton.addTarget(self, action: #selector(resumeTask(_:)), for: .touchUpInside)
        card.cancelButton.addTarget(self, action: #selector(cancelTask(_:)), for: .touchUpInside)
        card.deleteButton.addTarget(self, action: #selector(deleteTask(_:)), for: .touchUpInside)
        downloadTasksContainer.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: downloadTasksContainer.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: downloadTasksContainer.trailingAnchor),
            card.topAnchor.constraint(equalTo: taskCards.last?.bottomAnchor ?? downloadTasksContainer.topAnchor, constant: taskCards.isEmpty ? 0 : 12)
        ])
        taskCards.append(card)
        updateContainerHeight()
        refreshLayoutAfterTaskChange()
    }
    
    private func updateContainerHeight() {
        downloadTasksContainer.layoutIfNeeded()
        var totalHeight: CGFloat = 0
        for card in taskCards {
            totalHeight += card.frame.height + 12
        }
        if !taskCards.isEmpty {
            totalHeight -= 12
        }
        containerHeightConstraint?.constant = max(totalHeight, 0)
        view.layoutIfNeeded()
    }
    
    @objc private func downloadTask(_ sender: UIButton) {
        guard let card = findCard(from: sender), let url = card.url else { return }
        audioKit.downloadRemoteAudio(remoteUrls: [url]) { infos in
            self.logInfo("下载成功: \(infos.first?.local.lastPathComponent ?? "")")
        } failed: { error in
            self.logInfo("下载失败: \(error?.localizedDescription ?? "")")
        }
    }
    
    @objc private func pauseTask(_ sender: UIButton) {
        guard let card = findCard(from: sender), let url = card.url else { return }
        audioKit.pauseDownload([url]) { url in
            self.logInfo("暂停成功: \(url)")
        } failed: { url, error in
            self.logInfo("暂停失败: \(url), 错误: \(error?.localizedDescription ?? "未知")")
        }
    }
    
    @objc private func resumeTask(_ sender: UIButton) {
        guard let card = findCard(from: sender), let url = card.url else { return }
        audioKit.resumeDownload([url])
        logInfo("恢复下载: \(url)")
    }
    
    @objc private func cancelTask(_ sender: UIButton) {
        guard let card = findCard(from: sender), let url = card.url else { return }
        audioKit.cancelDownload([url])
        logInfo("取消下载: \(url)")
        card.progressBar.progress = 0
        card.progressLabel.text = "进度: 0%"
    }
    
    @objc private func deleteTask(_ sender: UIButton) {
        guard let card = findCard(from: sender), let index = taskCards.firstIndex(of: card) else { return }
        if let url = card.url {
            audioKit.cancelDownload([url])
        }
        taskCards.remove(at: index)
        card.removeFromSuperview()
        for (i, card) in taskCards.enumerated() {
            if let prevCard = i > 0 ? taskCards[i-1] : nil {
                card.topAnchor.constraint(equalTo: prevCard.bottomAnchor, constant: 12).isActive = true
            } else {
                card.topAnchor.constraint(equalTo: downloadTasksContainer.topAnchor).isActive = true
            }
        }
        updateContainerHeight()
        refreshLayoutAfterTaskChange()
    }
    
    private func findCard(from button: UIButton) -> DownloadTaskCardView? {
        var view = button.superview
        while view != nil && !(view is DownloadTaskCardView) {
            view = view?.superview
        }
        return view as? DownloadTaskCardView
    }
    
    private func refreshLayoutAfterTaskChange() {
        view.layoutIfNeeded()
        let containerBottom = downloadTasksContainer.frame.maxY
        var yOffset = containerBottom + 20
        
        // 文件管理区域
        fileLabel.frame = CGRect(x: 20, y: yOffset, width: 200, height: 30)
        refreshFilesButton.frame = CGRect(x: view.bounds.width - 120, y: yOffset, width: 100, height: 30)
        yOffset += 40
        fileListTextView.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 150)
        yOffset += 160
        saveRecordButton.frame = CGRect(x: 20, y: yOffset, width: 100, height: 40)
        deleteRecordButton.frame = CGRect(x: 130, y: yOffset, width: 100, height: 40)
        deleteAllRecordingsButton.frame = CGRect(x: 240, y: yOffset, width: 120, height: 40)
        yOffset += 50
        deleteAllDownloadsButton.frame = CGRect(x: 20, y: yOffset, width: 150, height: 40)
        yOffset += 50
        
        // 格式转换区域
        convertLabel.frame = CGRect(x: 20, y: yOffset, width: 200, height: 30)
        yOffset += 30
        targetFormatPicker.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 100)
        yOffset += 110
        convertButton.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 40)
        yOffset += 50
        conversionProgressLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        yOffset += 40
        
        // 其他功能
        customSettingsButton.frame = CGRect(x: 20, y: yOffset, width: 150, height: 40)
        releaseButton.frame = CGRect(x: 180, y: yOffset, width: 100, height: 40)
        yOffset += 50
        
        // 更新 contentView 高度
        contentView.frame.size.height = yOffset + 100
        scrollView.contentSize = contentView.frame.size
    }
    
    // MARK: - UI 布局
    private func setupUI() {
        scrollView.frame = CGRect(x: 0, y: UIDevice.wy_navViewHeight, width: UIDevice.wy_screenWidth, height: UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: scrollView.frame.size.height)
        contentView.backgroundColor = .white
        scrollView.addSubview(contentView)
        
        var yOffset: CGFloat = 20
        
        // 信息文本框
        infoTextView.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 190)
        infoTextView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        infoTextView.textColor = .black
        infoTextView.layer.borderColor = UIColor.lightGray.cgColor
        infoTextView.layer.borderWidth = 1
        infoTextView.layer.cornerRadius = 8
        infoTextView.font = .systemFont(ofSize: 14)
        infoTextView.isEditable = false
        infoTextView.text = "操作日志将显示在这里...\n"
        contentView.addSubview(infoTextView)
        yOffset += 200
        
        // 格式选择器
        let formatLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        formatLabel.text = "选择录音格式:"
        contentView.addSubview(formatLabel)
        yOffset += 30
        formatPicker.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 100)
        formatPicker.backgroundColor = .white
        formatPicker.dataSource = self
        formatPicker.delegate = self
        contentView.addSubview(formatPicker)
        yOffset += 110
        
        // 存储目录
        let storageDirLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        storageDirLabel.text = "存储目录:"
        contentView.addSubview(storageDirLabel)
        yOffset += 30
        storageDirSegmentedControl.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        storageDirSegmentedControl.selectedSegmentIndex = 0
        storageDirSegmentedControl.addTarget(self, action: #selector(storageDirChanged), for: .valueChanged)
        contentView.addSubview(storageDirSegmentedControl)
        yOffset += 40
        
        // 录音控制
        let recordLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        recordLabel.text = "录音控制:"
        contentView.addSubview(recordLabel)
        yOffset += 30
        recordButton.frame = CGRect(x: 20, y: yOffset, width: 80, height: 40)
        recordButton.setTitle("开始录音", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        contentView.addSubview(recordButton)
        pauseRecordButton.frame = CGRect(x: 110, y: yOffset, width: 80, height: 40)
        pauseRecordButton.setTitle("暂停录音", for: .normal)
        pauseRecordButton.addTarget(self, action: #selector(pauseRecording), for: .touchUpInside)
        contentView.addSubview(pauseRecordButton)
        resumeRecordButton.frame = CGRect(x: 200, y: yOffset, width: 80, height: 40)
        resumeRecordButton.setTitle("恢复录音", for: .normal)
        resumeRecordButton.addTarget(self, action: #selector(resumeRecording), for: .touchUpInside)
        contentView.addSubview(resumeRecordButton)
        stopRecordButton.frame = CGRect(x: 290, y: yOffset, width: 80, height: 40)
        stopRecordButton.setTitle("停止录音", for: .normal)
        stopRecordButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        contentView.addSubview(stopRecordButton)
        yOffset += 50
        
        recordProgressLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        recordProgressLabel.textColor = .black
        recordProgressLabel.text = "录音进度: 0.0秒/0.0秒"
        contentView.addSubview(recordProgressLabel)
        yOffset += 40
        
        voiceWaveView.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 60)
        voiceWaveView.backgroundColor = UIColor.systemGray5
        voiceWaveView.layer.cornerRadius = 8
        contentView.addSubview(voiceWaveView)
        yOffset += 70
        
        playRecordedButton.frame = CGRect(x: 20, y: yOffset, width: 150, height: 40)
        playRecordedButton.setTitle("播放录音文件", for: .normal)
        playRecordedButton.addTarget(self, action: #selector(playRecordedFile), for: .touchUpInside)
        contentView.addSubview(playRecordedButton)
        yOffset += 50
        
        // 播放控制
        let playLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        playLabel.text = "播放控制:"
        contentView.addSubview(playLabel)
        yOffset += 30
        playButton.frame = CGRect(x: 20, y: yOffset, width: 150, height: 40)
        playButton.setTitle("播放本地音频", for: .normal)
        playButton.addTarget(self, action: #selector(playLocalAudio), for: .touchUpInside)
        contentView.addSubview(playButton)
        pausePlayButton.frame = CGRect(x: 180, y: yOffset, width: 80, height: 40)
        pausePlayButton.setTitle("暂停播放", for: .normal)
        pausePlayButton.addTarget(self, action: #selector(pausePlayback), for: .touchUpInside)
        contentView.addSubview(pausePlayButton)
        stopPlayButton.frame = CGRect(x: 270, y: yOffset, width: 80, height: 40)
        stopPlayButton.setTitle("停止播放", for: .normal)
        stopPlayButton.addTarget(self, action: #selector(stopPlayback), for: .touchUpInside)
        contentView.addSubview(stopPlayButton)
        yOffset += 50
        resumePlayButton.frame = CGRect(x: 20, y: yOffset, width: 80, height: 40)
        resumePlayButton.setTitle("恢复播放", for: .normal)
        resumePlayButton.addTarget(self, action: #selector(resumePlayback), for: .touchUpInside)
        contentView.addSubview(resumePlayButton)
        seekSlider.frame = CGRect(x: 110, y: yOffset, width: 150, height: 40)
        seekSlider.minimumValue = 0
        seekSlider.maximumValue = 1
        contentView.addSubview(seekSlider)
        seekButton.frame = CGRect(x: 270, y: yOffset, width: 80, height: 40)
        seekButton.setTitle("跳转播放", for: .normal)
        seekButton.addTarget(self, action: #selector(seekPlayback), for: .touchUpInside)
        contentView.addSubview(seekButton)
        yOffset += 50
        
        // 倍速控制
        let rateLabelTitle = UILabel(frame: CGRect(x: 20, y: yOffset, width: 100, height: 30))
        rateLabelTitle.text = "播放倍速:"
        contentView.addSubview(rateLabelTitle)
        rateSlider.frame = CGRect(x: 120, y: yOffset, width: 150, height: 30)
        rateSlider.minimumValue = 0.5
        rateSlider.maximumValue = 2.0
        rateSlider.value = 1.0
        rateSlider.addTarget(self, action: #selector(rateChanged), for: .valueChanged)
        contentView.addSubview(rateSlider)
        rateLabel.frame = CGRect(x: 280, y: yOffset, width: 40, height: 30)
        rateLabel.text = "1.0x"
        contentView.addSubview(rateLabel)
        yOffset += 40
        
        playProgressLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        playProgressLabel.text = "播放进度: 0.0秒/0.0秒 (0.0%)"
        contentView.addSubview(playProgressLabel)
        yOffset += 40
        
        // 时长设置
        let durationLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        durationLabel.text = "录音时长设置:"
        contentView.addSubview(durationLabel)
        yOffset += 30
        minDurationSlider.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        minDurationSlider.minimumValue = 0
        minDurationSlider.maximumValue = 60
        minDurationSlider.value = 0
        minDurationSlider.addTarget(self, action: #selector(minDurationChanged), for: .valueChanged)
        contentView.addSubview(minDurationSlider)
        yOffset += 35
        minDurationLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        contentView.addSubview(minDurationLabel)
        yOffset += 40
        maxDurationSlider.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        maxDurationSlider.minimumValue = 1
        maxDurationSlider.maximumValue = 300
        maxDurationSlider.value = 60
        maxDurationSlider.addTarget(self, action: #selector(maxDurationChanged), for: .valueChanged)
        contentView.addSubview(maxDurationSlider)
        yOffset += 35
        maxDurationLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        contentView.addSubview(maxDurationLabel)
        yOffset += 50
        
        let qualityLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        qualityLabel.text = "音频质量:"
        contentView.addSubview(qualityLabel)
        yOffset += 30
        qualitySegmentedControl.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        qualitySegmentedControl.selectedSegmentIndex = 2
        qualitySegmentedControl.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        contentView.addSubview(qualitySegmentedControl)
        yOffset += 50
        
        // 网络音频测试（单个下载 + 流式播放）
        let remoteLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        remoteLabel.text = "网络音频测试:"
        contentView.addSubview(remoteLabel)
        yOffset += 30
        remoteURLField.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 40)
        remoteURLField.borderStyle = .roundedRect
        remoteURLField.placeholder = "输入音频URL（单个）"
        remoteURLField.text = "http://music.163.com/song/media/outer/url?id=2105354877.mp3"
        contentView.addSubview(remoteURLField)
        yOffset += 50
        downloadButton.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 40)
        downloadButton.setTitle("下载并播放", for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadAndPlay), for: .touchUpInside)
        contentView.addSubview(downloadButton)
        yOffset += 50
        streamingButton.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 40)
        streamingButton.setTitle("流式播放（边下边播）", for: .normal)
        streamingButton.addTarget(self, action: #selector(testStreaming), for: .touchUpInside)
        contentView.addSubview(streamingButton)
        yOffset += 50
        downloadProgressLabel.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 30)
        downloadProgressLabel.text = "下载进度: 0.0%"
        contentView.addSubview(downloadProgressLabel)
        yOffset += 50
        
        // 多任务下载列表
        let multiTaskLabel = UILabel(frame: CGRect(x: 20, y: yOffset, width: 200, height: 30))
        multiTaskLabel.text = "多任务下载列表:"
        contentView.addSubview(multiTaskLabel)
        yOffset += 30
        
        addTaskButton.frame = CGRect(x: view.bounds.width - 100, y: yOffset - 30, width: 80, height: 30)
        addTaskButton.setTitle("添加任务", for: .normal)
        addTaskButton.addTarget(self, action: #selector(addTaskButtonTapped), for: .touchUpInside)
        contentView.addSubview(addTaskButton)
        
        downloadTasksContainer.frame = CGRect(x: 20, y: yOffset, width: view.bounds.width - 40, height: 0)
        downloadTasksContainer.backgroundColor = .clear
        downloadTasksContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(downloadTasksContainer)
        NSLayoutConstraint.activate([
            downloadTasksContainer.topAnchor.constraint(equalTo: multiTaskLabel.bottomAnchor, constant: 8),
            downloadTasksContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            downloadTasksContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        containerHeightConstraint = downloadTasksContainer.heightAnchor.constraint(equalToConstant: 0)
        containerHeightConstraint?.isActive = true
        
        // 后续控件先创建，位置由 refreshLayoutAfterTaskChange 设置
        fileLabel.text = "录音文件列表:"
        contentView.addSubview(fileLabel)
        
        refreshFilesButton.setTitle("刷新列表", for: .normal)
        refreshFilesButton.addTarget(self, action: #selector(refreshFileList), for: .touchUpInside)
        contentView.addSubview(refreshFilesButton)
        
        fileListTextView.layer.borderColor = UIColor.lightGray.cgColor
        fileListTextView.layer.borderWidth = 1
        fileListTextView.layer.cornerRadius = 8
        fileListTextView.font = .systemFont(ofSize: 12)
        fileListTextView.isEditable = false
        contentView.addSubview(fileListTextView)
        
        saveRecordButton.setTitle("保存录音", for: .normal)
        saveRecordButton.addTarget(self, action: #selector(saveRecording), for: .touchUpInside)
        contentView.addSubview(saveRecordButton)
        
        deleteRecordButton.setTitle("删除录音", for: .normal)
        deleteRecordButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        contentView.addSubview(deleteRecordButton)
        
        deleteAllRecordingsButton.setTitle("删除所有录音", for: .normal)
        deleteAllRecordingsButton.addTarget(self, action: #selector(deleteAllRecordings), for: .touchUpInside)
        contentView.addSubview(deleteAllRecordingsButton)
        
        deleteAllDownloadsButton.setTitle("删除所有下载", for: .normal)
        deleteAllDownloadsButton.addTarget(self, action: #selector(deleteAllDownloads), for: .touchUpInside)
        contentView.addSubview(deleteAllDownloadsButton)
        
        convertLabel.text = "格式转换:"
        contentView.addSubview(convertLabel)
        
        targetFormatPicker.dataSource = self
        targetFormatPicker.delegate = self
        contentView.addSubview(targetFormatPicker)
        
        convertButton.setTitle("转换音频文件格式", for: .normal)
        convertButton.addTarget(self, action: #selector(convertAudio), for: .touchUpInside)
        contentView.addSubview(convertButton)
        
        conversionProgressLabel.text = "转换进度: 0.0%"
        contentView.addSubview(conversionProgressLabel)
        
        customSettingsButton.setTitle("自定义录音设置", for: .normal)
        customSettingsButton.addTarget(self, action: #selector(setCustomSettings), for: .touchUpInside)
        contentView.addSubview(customSettingsButton)
        
        releaseButton.setTitle("释放资源", for: .normal)
        releaseButton.addTarget(self, action: #selector(releaseResources), for: .touchUpInside)
        contentView.addSubview(releaseButton)
        
        // 设置一个足够大的初始高度，避免滚动问题
        contentView.frame.size.height = yOffset + 600
        refreshLayoutAfterTaskChange()
    }
    
    @objc private func addTaskButtonTapped() {
        addDownloadTask()
    }
    
    // MARK: - 状态更新
    private func logInfo(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let log = "\(timestamp): \(message)\n"
            self.infoTextView.text = self.infoTextView.text + log
            let bottom = NSMakeRange(self.infoTextView.text.count - 1, 1)
            self.infoTextView.scrollRangeToVisible(bottom)
            WYLogManager.output("log = \(log)")
        }
    }
    
    // MARK: - 录音控制
    @objc private func startRecording() {
        do {
            try audioKit.startRecording(format: selectedFormat)
        } catch {
            handleError(error)
        }
    }
    
    @objc private func pauseRecording() {
        do {
            try audioKit.pauseRecording()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func resumeRecording() {
        do {
            try audioKit.resumeRecording()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func stopRecording() {
        do {
            try audioKit.stopRecording()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - 播放控制
    @objc private func playLocalAudio() {
        if let testFileURL = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: "mp3") {
            audioKit.playPlayback(url: testFileURL,
                                  success: { playURL in
                self.logInfo("本地音频播放成功: \(playURL.lastPathComponent)")
            },
                                  failed: { playURL, error, description in
                self.logInfo("本地音频播放失败: \(error?.localizedDescription ?? "未知错误")")
            })
        } else {
            logInfo("测试音频文件未找到")
        }
    }
    
    @objc private func playRecordedFile() {
        audioKit.playPlayback(url: nil,
                              success: { playURL in
            self.logInfo("录音文件播放成功: \(playURL.lastPathComponent)")
        },
                              failed: { playURL, error, description in
            self.logInfo("录音文件播放失败: \(error?.localizedDescription ?? "未知错误")")
        })
    }
    
    @objc private func pausePlayback() {
        do {
            try audioKit.pausePlayback()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func stopPlayback() {
        audioKit.stopPlayback()
    }
    
    @objc private func resumePlayback() {
        do {
            try audioKit.resumePlayback()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func seekPlayback() {
        guard currentPlayingDuration > 0 else {
            logInfo("无法跳转：未获取到音频总时长")
            return
        }
        let seekTime = Double(seekSlider.value) * currentPlayingDuration
        audioKit.seekPlayback(time: seekTime)
        logInfo("跳转到: \(String(format: "%.1f", seekTime))秒")
    }
    
    @objc private func rateChanged() {
        let rate = rateSlider.value
        audioKit.playbackRate = rate
        rateLabel.text = String(format: "%.1fx", rate)
        logInfo("设置播放倍速: \(rate)")
    }
    
    // MARK: - 设置控制
    @objc private func minDurationChanged() {
        minRecordingDuration = TimeInterval(minDurationSlider.value)
        audioKit.minimumRecordDuration = minRecordingDuration
        logInfo("设置最小录音时长: \(minRecordingDuration)秒")
    }
    
    @objc private func maxDurationChanged() {
        maxRecordingDuration = TimeInterval(maxDurationSlider.value)
        audioKit.maximumRecordDuration = maxRecordingDuration
        logInfo("设置最大录音时长: \(maxRecordingDuration)秒")
    }
    
    @objc private func qualityChanged() {
        let quality: AVAudioQuality
        switch qualitySegmentedControl.selectedSegmentIndex {
        case 0: quality = .low
        case 1: quality = .medium
        default: quality = .high
        }
        audioKit.recordQuality = quality
        logInfo("设置音频质量: \(qualitySegmentedControl.titleForSegment(at: qualitySegmentedControl.selectedSegmentIndex) ?? "")")
    }
    
    @objc private func storageDirChanged() {
        let directory: WYAudioStorageDirectory
        switch storageDirSegmentedControl.selectedSegmentIndex {
        case 0: directory = .temporary
        case 1: directory = .documents
        default: directory = .caches
        }
        audioKit.recordingsDirectory = directory
        logInfo("设置录音存储目录: \(directoryDescription(for: directory))")
    }
    
    // MARK: - 网络音频
    @objc private func downloadAndPlay() {
        guard let urlString = remoteURLField.text, let url = URL(string: urlString) else {
            logInfo("无效的URL")
            return
        }
        audioKit.playRemoteAudio(remoteUrl: url) { [weak self] downloadInfo in
            self?.logInfo("网络音频播放成功,存储地址：\(downloadInfo.local.lastPathComponent)")
        } failed: { [weak self] error in
            if let error = error {
                self?.handleError(error)
            }
        }
    }
    
    @objc private func testStreaming() {
        guard let urlString = remoteURLField.text, let url = URL(string: urlString) else {
            logInfo("无效的URL")
            return
        }
        audioKit.playStreamingRemoteAudio(remoteUrl: url, rate: audioKit.playbackRate) { [weak self] url in
            self?.logInfo("流式播放成功: \(url)")
        } failed: { [weak self] error in
            self?.logInfo("流式播放失败: \(error?.localizedDescription ?? "未知错误")")
        }
    }
    
    // MARK: - 文件管理
    @objc private func refreshFileList() {
        let recordings = audioKit.getAllRecordingsFiles()
        let downloads = audioKit.getAllDownloads()
        
        var fileList = "录音文件 (\(recordings.count)个):\n"
        for url in recordings {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs?[.size] as? Int64 ?? 0) / 1024
            fileList += "\(url.lastPathComponent) (\(size) KB)\n"
        }
        
        fileList += "\n下载文件 (\(downloads.count)个):\n"
        for info in downloads {
            let attrs = try? FileManager.default.attributesOfItem(atPath: info.local.path)
            let size = (attrs?[.size] as? Int64 ?? 0) / 1024
            fileList += "\(info.local.lastPathComponent) (\(size) KB)\n"
        }
        
        fileListTextView.text = fileList
    }
    
    @objc private func saveRecording() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "saved_audio_\(Date().timeIntervalSince1970).\(selectedFormat.rawValue)"
        let destinationURL = docDir.appendingPathComponent(fileName)
        do {
            try audioKit.saveRecording(destinationUrl: destinationURL)
            logInfo("文件已保存到: \(destinationURL.lastPathComponent)")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func deleteRecording() {
        do {
            try audioKit.deleteRecordingFile(localUrl: audioKit.currentRecordFileURL)
            logInfo("录音文件已删除")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func deleteAllRecordings() {
        do {
            try audioKit.deleteRecordingFile()
            logInfo("所有录音文件已删除")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func deleteAllDownloads() {
        let downloads = audioKit.getAllDownloads()
        for info in downloads {
            audioKit.deleteDownloadFile(info: info)
        }
        logInfo("所有下载文件已删除")
        refreshFileList()
        for card in taskCards {
            card.progressBar.progress = 0
            card.progressLabel.text = "进度: 0%"
        }
    }
    
    // MARK: - 格式转换
    @objc private func convertAudio() {
        guard let sourceURL = audioKit.currentRecordFileURL else {
            logInfo("没有可转换的录音文件")
            return
        }
        logInfo("开始转换格式: \(sourceURL.lastPathComponent) -> \(targetFormat.rawValue)")
        audioKit.convertAudioFormat(sourceUrls: [sourceURL], target: targetFormat) { [weak self] results in
            for result in results {
                self?.logInfo("格式转换成功: \(result.lastPathComponent)")
                self?.refreshFileList()
            }
        } failed: { [weak self] error in
            if let error = error {
                self?.handleError(error)
            }
        }
    }
    
    @objc private func stopConvert() {
        guard let sourceURL = audioKit.currentRecordFileURL else {
            logInfo("没有正在转换的任务")
            return
        }
        audioKit.stopAudioFormatConvert([sourceURL])
        logInfo("已停止格式转换")
    }
    
    // MARK: - 其他功能
    @objc private func setCustomSettings() {
        let customSettings: [String: Any] = [
            AVSampleRateKey: 22050.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 64000
        ]
        audioKit.recordSettings = customSettings
        logInfo("设置自定义录音参数: 采样率22.05kHz, 比特率64kbps, 双声道")
    }
    
    @objc private func releaseResources() {
        audioKit.releaseAll()
        logInfo("已释放所有音频资源")
    }
    
    // MARK: - 错误处理
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        if let audioError = WYAudioError(rawValue: nsError.code) {
            logInfo("操作失败: \(errorDescription(for: audioError))")
        } else {
            logInfo("操作失败: \(error.localizedDescription)")
        }
    }
    
    private func errorDescription(for error: WYAudioError) -> String {
        switch error {
        case .startRecordingFailed: return "开始录音失败"
        case .noAudioRecordedTasks: return "没有正在录制的音频任务"
        case .noAudioPauseTasks: return "没有需要暂停的音频任务"
        case .noAudioResumeRecordTasks: return "没有需要恢复录制的音频任务"
        case .deleteAudioFileFailed: return "删除音频(录音)文件失败"
        case .notDetermined: return "未申请录音权限(权限未确定)"
        case .permissionDenied: return "录音权限被拒绝"
        case .fileNotFound: return "音频文件未找到"
        case .noAudiofilesToPlay: return "没有可以播放的音频文件"
        case .fileSaveFailed: return "录音文件保存失败"
        case .recordingInProgress: return "录音正在进行中"
        case .minDurationNotReached: return "录音时长未达到最小值"
        case .isPlayingAudio: return "正在播放音频文件"
        case .playbackError: return "播放错误"
        case .noAudioToPause: return "没有可以暂停播放的音频"
        case .noAudioResumePlayTasks: return "没有可以恢复播放的音频任务"
        case .downloadFailed: return "音频下载失败"
        case .invalidRemoteURL: return "无效的远程URL"
        case .conversionFailed: return "格式转换失败"
        case .conversionCancelled: return "格式转换已取消"
        case .formatNotSupported: return "不支持的录制格式"
        case .sessionConfigurationFailed: return "音频会话配置失败"
        case .directoryCreationFailed: return "目录创建失败"
        default: return "未知错误"
        }
    }
    
    private func directoryDescription(for directory: WYAudioStorageDirectory) -> String {
        switch directory {
        case .temporary: return "临时目录"
        case .documents: return "文档目录"
        case .caches: return "缓存目录"
        }
    }
    
    private func playerPlayStateDescription(for state: WYAudioPlayState) -> String {
        switch state {
        case .start: return "开始播放"
        case .pause: return "暂停播放"
        case .resume: return "恢复播放"
        case .stop: return "停止播放"
        case .finish: return "完成播放"
        }
    }
    
    deinit {
        audioKit.releaseAll()
        WYLogManager.output("WYTestAudioController release")
    }
}

// MARK: - WYAudioKitDelegate
extension WYTestAudioController: WYAudioKitDelegate {
    func wy_audioRecorderDidStart(audioKit: WYAudioKit, isResume: Bool) {
        logInfo("开始录制 \(selectedFormat.rawValue) 格式音频, \(isResume ? "是" : "不是")恢复录音")
        voiceWaveView.startAnimating()
    }
    
    func wy_audioRecorderDidStop(audioKit: WYAudioKit, isPause: Bool, isTimeout: Bool) {
        logInfo("录音停止, \(isPause ? "是" : "不是")暂停录音, \(isTimeout ? "是": "不是")超时(达到最大录音时长)停止")
        voiceWaveView.stopAnimating()
    }
    
    func wy_audioRecorderTimeUpdated(audioKit: WYAudioKit, currentTime: TimeInterval, duration: TimeInterval) {
        let progress = min(currentTime / duration, 1.0) * 100.0
        recordProgressLabel.text = String(format: "录音进度: %.1f秒/%.1f秒 (%.1f%%)",
                                          currentTime, duration, progress)
    }
    
    func wy_audioRecorderDidUpdateMeterings(audioKit: WYAudioKit, peakPowers: [Float], averagePowers: [Float]) {
        // 使用峰值功率，响应更快
        let raw = peakPowers.first ?? 0
        // 放大 80 倍，并限制最大值 1（可根据需要调整倍数）
        let normalized = min(1.0, raw * 80.0)
        // 可选：如果想保留 sqrt 让低音量更明显，可去掉注释，但会略微降低灵敏度
        // normalized = sqrt(normalized)
        DispatchQueue.main.async {
            self.voiceWaveView.updatePower(normalized)
        }
    }
    
    func wy_audioPlayerStateDidChanged(audioKit: WYAudioKit, state: WYAudioPlayState) {
        logInfo("播放状态: \(playerPlayStateDescription(for: state))")
        if state == .finish {
            playProgressLabel.text = "播放进度: 100%"
        }
    }
    
    func wy_audioPlayerTimeUpdated(audioKit: WYAudioKit, localUrl: URL, currentTime: TimeInterval, duration: TimeInterval, progress: Double) {
        currentPlayingDuration = duration
        playProgressLabel.text = String(format: "播放进度: %.1f秒/%.1f秒 (%.1f%%)",
                                        currentTime, duration, progress * 100)
    }
    
    func wy_remoteAudioDownloadProgressUpdated(audioKit: WYAudioKit, remoteUrls: [URL], progress: Double) {
        downloadProgressLabel.text = String(format: "下载进度: %.1f%%, remoteUrls：\(remoteUrls)", progress*100)
        for card in taskCards {
            if let url = card.url, remoteUrls.contains(url) {
                DispatchQueue.main.async {
                    card.progressBar.progress = Float(progress)
                    card.progressLabel.text = String(format: "进度: %.1f%%", progress * 100)
                }
            }
        }
    }
    
    func wy_remoteAudioDownloadSuccess(audioKit: WYAudioKit, fileInfos: [WYAudioDownloadInfo]) {
        for info in fileInfos {
            logInfo("下载成功: \(info.local)")
            for card in taskCards {
                if let url = card.url, url == info.remote {
                    DispatchQueue.main.async {
                        card.progressBar.progress = 1.0
                        card.progressLabel.text = "进度: 100%"
                    }
                }
            }
        }
        refreshFileList()
    }
    
    func wy_formatConversionProgressUpdated(audioKit: WYAudioKit, localUrls: [URL], progress: Double) {
        conversionProgressLabel.text = String(format: "转换进度: %.1f%%, localUrls：\(localUrls)", progress*100)
    }
    
    func wy_formatConversionDidCompleted(audioKit: WYAudioKit, outputUrls: [URL]) {
        for outputUrl in outputUrls {
            logInfo("转换完成: \(outputUrl.lastPathComponent)")
        }
        refreshFileList()
    }
    
    func wy_audioTaskDidFailed(audioKit: WYAudioKit, url: URL?, error: WYAudioError, description: String?) {
        logInfo("任务失败: \(errorDescription(for: error)), 描述: \(description ?? "无"), URL: \(url, default: "空")")
        for card in taskCards {
            if let taskUrl = card.url, taskUrl == url {
                DispatchQueue.main.async {
                    card.progressBar.progress = 0
                    card.progressLabel.text = "进度: 0%"
                }
            }
        }
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension WYTestAudioController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == formatPicker {
            return supportedFormats.count
        } else {
            return supportedConvertFormats.count
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let format = pickerView == formatPicker ? supportedFormats[row] : supportedConvertFormats[row]
        return "\(format.extensionName.uppercased()) (\(formatDescription(for: format)))"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == formatPicker {
            let newFormat = supportedFormats[row]
            if selectedFormat != newFormat {
                selectedFormat = newFormat
            }
        } else {
            let newFormat = supportedConvertFormats[row]
            if targetFormat != newFormat {
                targetFormat = newFormat
            }
        }
    }
    
    private func formatDescription(for format: WYAudioFormat) -> String {
        switch format {
        case .aac: return "高效压缩"
        case .wav: return "无损质量"
        case .caf: return "Apple容器"
        case .m4a: return "MP4音频"
        case .aiff: return "无损格式"
        case .mp3: return "通用格式"
        case .flac: return "无损压缩"
        case .au: return "早期格式"
        case .amr: return "人声优化"
        case .ac3: return "杜比数字"
        case .eac3: return "增强杜比"
        }
    }
}
