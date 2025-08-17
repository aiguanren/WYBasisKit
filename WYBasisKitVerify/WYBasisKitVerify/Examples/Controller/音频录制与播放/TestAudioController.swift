//
//  TestAudioController.swift
//  WYBasiskitVerify
//
//  Created by guanren on 2025/8/12.
//

import UIKit
import AVFoundation

/// 测试音频控制器，用于演示WYAudioKit的功能
class TestAudioController: UIViewController {
    
    /// 音频工具实例
    private let audioKit: WYAudioKit = WYAudioKit()
    
    /// 界面元素
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoTextView = UITextView()
    
    // 录音控制
    private let recordButton = UIButton(type: .system)
    private let pauseRecordButton = UIButton(type: .system)
    private let stopRecordButton = UIButton(type: .system)
    private let resumeRecordButton = UIButton(type: .system)
    
    // 播放控制
    private let playButton = UIButton(type: .system)
    private let pausePlayButton = UIButton(type: .system)
    private let stopPlayButton = UIButton(type: .system)
    private let resumePlayButton = UIButton(type: .system)
    private let seekButton = UIButton(type: .system)
    private let seekSlider = UISlider()
    
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
    
    // 网络音频
    private let remoteURLField = UITextField()
    private let downloadButton = UIButton(type: .system)
    
    // 文件管理
    private let fileListTextView = UITextView()
    private let refreshFilesButton = UIButton(type: .system)
    private let deleteAllRecordingsButton = UIButton(type: .system)
    private let deleteAllDownloadsButton = UIButton(type: .system)
    
    // 格式转换
    private let convertButton = UIButton(type: .system)
    private let targetFormatPicker = UIPickerView()
    
    // 其他功能
    private let playRecordedButton = UIButton(type: .system)
    private let saveRecordButton = UIButton(type: .system)
    private let deleteRecordButton = UIButton(type: .system)
    private let customSettingsButton = UIButton(type: .system)
    private let releaseButton = UIButton(type: .system)
    
    /// 支持的音频格式
    private let supportedFormats: [WYAudioFormat] = [
        .aac, .wav, .caf, .m4a, .aiff, .mp3, .flac, .au, .amr, .ac3, .eac3
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = contentView.frame.size
    }
    
    private func setupAudioKit() {
        audioKit.delegate = self
        audioKit.setRecordingDurations(min: minRecordingDuration, max: maxRecordingDuration)
        
        // 请求录音权限
        audioKit.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                let status = granted ? "已授权" : "未授权"
                self?.logInfo("录音权限: \(status)")
            }
        }
    }
    
    private func setupUI() {
        // 创建滚动视图
        scrollView.frame = CGRect(x: 0, y: UIDevice.wy_navViewHeight, width: UIDevice.wy_screenWidth, height: UIDevice.wy_screenHeight - UIDevice.wy_navViewHeight)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: scrollView.frame.size.height)
        scrollView.addSubview(contentView)
        
        // 信息文本框
        infoTextView.frame = CGRect(x: 20, y: 20, width: view.bounds.width - 40, height: 190)
        infoTextView.layer.borderColor = UIColor.lightGray.cgColor
        infoTextView.layer.borderWidth = 1
        infoTextView.layer.cornerRadius = 8
        infoTextView.font = .systemFont(ofSize: 14)
        infoTextView.isEditable = false
        infoTextView.isEditable = false
        infoTextView.text = "操作日志将显示在这里...\n"
        contentView.addSubview(infoTextView)
        
        // 格式选择器
        let formatLabel = UILabel(frame: CGRect(x: 20, y: 230, width: 200, height: 30))
        formatLabel.text = "选择录音格式:"
        contentView.addSubview(formatLabel)
        
        formatPicker.frame = CGRect(x: 20, y: 260, width: view.bounds.width - 40, height: 100)
        formatPicker.dataSource = self
        formatPicker.delegate = self
        contentView.addSubview(formatPicker)
        
        // 存储目录选择
        let storageDirLabel = UILabel(frame: CGRect(x: 20, y: 370, width: 200, height: 30))
        storageDirLabel.text = "存储目录:"
        contentView.addSubview(storageDirLabel)
        
        storageDirSegmentedControl.frame = CGRect(x: 20, y: 400, width: view.bounds.width - 40, height: 30)
        storageDirSegmentedControl.selectedSegmentIndex = 0
        storageDirSegmentedControl.addTarget(self, action: #selector(storageDirChanged), for: .valueChanged)
        contentView.addSubview(storageDirSegmentedControl)
        storageDirChanged()
        
        // 录音控制
        let recordLabel = UILabel(frame: CGRect(x: 20, y: 440, width: 200, height: 30))
        recordLabel.text = "录音控制:"
        contentView.addSubview(recordLabel)
        
        recordButton.frame = CGRect(x: 20, y: 480, width: 80, height: 40)
        recordButton.setTitle("开始录音", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        contentView.addSubview(recordButton)
        
        pauseRecordButton.frame = CGRect(x: 110, y: 480, width: 80, height: 40)
        pauseRecordButton.setTitle("暂停录音", for: .normal)
        pauseRecordButton.addTarget(self, action: #selector(pauseRecording), for: .touchUpInside)
        contentView.addSubview(pauseRecordButton)
        
        resumeRecordButton.frame = CGRect(x: 200, y: 480, width: 80, height: 40)
        resumeRecordButton.setTitle("恢复录音", for: .normal)
        resumeRecordButton.addTarget(self, action: #selector(resumeRecording), for: .touchUpInside)
        contentView.addSubview(resumeRecordButton)
        
        stopRecordButton.frame = CGRect(x: 290, y: 480, width: 80, height: 40)
        stopRecordButton.setTitle("停止录音", for: .normal)
        stopRecordButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        contentView.addSubview(stopRecordButton)
        
        // 录音进度
        recordProgressLabel.frame = CGRect(x: 20, y: 530, width: view.bounds.width - 40, height: 30)
        recordProgressLabel.text = "录音进度: 0.0秒/0.0秒"
        contentView.addSubview(recordProgressLabel)
        
        // 播放录音文件
        playRecordedButton.frame = CGRect(x: 20, y: 560, width: 150, height: 40)
        playRecordedButton.setTitle("播放录音文件", for: .normal)
        playRecordedButton.addTarget(self, action: #selector(playRecordedFile), for: .touchUpInside)
        contentView.addSubview(playRecordedButton)
        
        // 播放控制
        let playLabel = UILabel(frame: CGRect(x: 20, y: 610, width: 200, height: 30))
        playLabel.text = "播放控制:"
        contentView.addSubview(playLabel)
        
        playButton.frame = CGRect(x: 20, y: 650, width: 150, height: 40)
        playButton.setTitle("播放本地音频", for: .normal)
        playButton.addTarget(self, action: #selector(playLocalAudio), for: .touchUpInside)
        contentView.addSubview(playButton)
        
        pausePlayButton.frame = CGRect(x: 180, y: 650, width: 80, height: 40)
        pausePlayButton.setTitle("暂停播放", for: .normal)
        pausePlayButton.addTarget(self, action: #selector(pausePlayback), for: .touchUpInside)
        contentView.addSubview(pausePlayButton)
        
        stopPlayButton.frame = CGRect(x: 270, y: 650, width: 80, height: 40)
        stopPlayButton.setTitle("停止播放", for: .normal)
        stopPlayButton.addTarget(self, action: #selector(stopPlayback), for: .touchUpInside)
        contentView.addSubview(stopPlayButton)
        
        resumePlayButton.frame = CGRect(x: 20, y: 700, width: 80, height: 40)
        resumePlayButton.setTitle("恢复播放", for: .normal)
        resumePlayButton.addTarget(self, action: #selector(resumePlayback), for: .touchUpInside)
        contentView.addSubview(resumePlayButton)
        
        // 跳转播放
        seekSlider.frame = CGRect(x: 110, y: 700, width: 150, height: 40)
        seekSlider.minimumValue = 0
        seekSlider.maximumValue = 1
        contentView.addSubview(seekSlider)
        
        seekButton.frame = CGRect(x: 270, y: 700, width: 80, height: 40)
        seekButton.setTitle("跳转播放", for: .normal)
        seekButton.addTarget(self, action: #selector(seekPlayback), for: .touchUpInside)
        contentView.addSubview(seekButton)
        
        // 播放进度
        playProgressLabel.frame = CGRect(x: 20, y: 750, width: view.bounds.width - 40, height: 30)
        playProgressLabel.text = "播放进度: 0.0秒/0.0秒 (0.0%)"
        contentView.addSubview(playProgressLabel)
        
        // 时长设置
        let durationLabel = UILabel(frame: CGRect(x: 20, y: 790, width: 200, height: 30))
        durationLabel.text = "录音时长设置:"
        contentView.addSubview(durationLabel)
        
        minDurationSlider.frame = CGRect(x: 20, y: 830, width: view.bounds.width - 40, height: 30)
        minDurationSlider.minimumValue = 0
        minDurationSlider.maximumValue = 60
        minDurationSlider.value = 0
        minDurationSlider.addTarget(self, action: #selector(minDurationChanged), for: .valueChanged)
        contentView.addSubview(minDurationSlider)
        
        minDurationLabel.frame = CGRect(x: 20, y: 860, width: view.bounds.width - 40, height: 30)
        minDurationLabel.text = "最短时长: 0.0秒"
        contentView.addSubview(minDurationLabel)
        
        maxDurationSlider.frame = CGRect(x: 20, y: 890, width: view.bounds.width - 40, height: 30)
        maxDurationSlider.minimumValue = 1
        maxDurationSlider.maximumValue = 300
        maxDurationSlider.value = 60
        maxDurationSlider.addTarget(self, action: #selector(maxDurationChanged), for: .valueChanged)
        contentView.addSubview(maxDurationSlider)
        
        maxDurationLabel.frame = CGRect(x: 20, y: 920, width: view.bounds.width - 40, height: 30)
        maxDurationLabel.text = "最长时长: 60.0秒"
        contentView.addSubview(maxDurationLabel)
        
        // 质量设置
        let qualityLabel = UILabel(frame: CGRect(x: 20, y: 960, width: 200, height: 30))
        qualityLabel.text = "音频质量:"
        contentView.addSubview(qualityLabel)
        
        qualitySegmentedControl.frame = CGRect(x: 20, y: 1000, width: view.bounds.width - 40, height: 30)
        qualitySegmentedControl.selectedSegmentIndex = 2
        qualitySegmentedControl.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        contentView.addSubview(qualitySegmentedControl)
        
        // 网络音频
        let remoteLabel = UILabel(frame: CGRect(x: 20, y: 1040, width: 200, height: 30))
        remoteLabel.text = "网络音频测试:"
        contentView.addSubview(remoteLabel)
        
        remoteURLField.frame = CGRect(x: 20, y: 1080, width: view.bounds.width - 40, height: 40)
        remoteURLField.borderStyle = .roundedRect
        remoteURLField.placeholder = "输入音频URL"
        remoteURLField.text = "http://music.163.com/song/media/outer/url?id=2105354877.mp3"
        contentView.addSubview(remoteURLField)
        
        downloadButton.frame = CGRect(x: 20, y: 1130, width: view.bounds.width - 40, height: 40)
        downloadButton.setTitle("下载并播放网络音频", for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadAndPlay), for: .touchUpInside)
        contentView.addSubview(downloadButton)
        
        downloadProgressLabel.frame = CGRect(x: 20, y: 1180, width: view.bounds.width - 40, height: 30)
        downloadProgressLabel.text = "下载进度: 0.0%"
        contentView.addSubview(downloadProgressLabel)
        
        // 文件管理
        let fileLabel = UILabel(frame: CGRect(x: 20, y: 1220, width: 200, height: 30))
        fileLabel.text = "录音文件列表:"
        contentView.addSubview(fileLabel)
        
        refreshFilesButton.frame = CGRect(x: view.bounds.width - 120, y: 1220, width: 100, height: 30)
        refreshFilesButton.setTitle("刷新列表", for: .normal)
        refreshFilesButton.addTarget(self, action: #selector(refreshFileList), for: .touchUpInside)
        contentView.addSubview(refreshFilesButton)
        
        fileListTextView.frame = CGRect(x: 20, y: 1260, width: view.bounds.width - 40, height: 150)
        fileListTextView.layer.borderColor = UIColor.lightGray.cgColor
        fileListTextView.layer.borderWidth = 1
        fileListTextView.layer.cornerRadius = 8
        fileListTextView.font = .systemFont(ofSize: 12)
        fileListTextView.isEditable = false
        contentView.addSubview(fileListTextView)
        
        // 文件操作
        saveRecordButton.frame = CGRect(x: 20, y: 1420, width: 100, height: 40)
        saveRecordButton.setTitle("保存录音", for: .normal)
        saveRecordButton.addTarget(self, action: #selector(saveRecording), for: .touchUpInside)
        contentView.addSubview(saveRecordButton)
        
        deleteRecordButton.frame = CGRect(x: 130, y: 1420, width: 100, height: 40)
        deleteRecordButton.setTitle("删除录音", for: .normal)
        deleteRecordButton.addTarget(self, action: #selector(deleteRecording), for: .touchUpInside)
        contentView.addSubview(deleteRecordButton)
        
        deleteAllRecordingsButton.frame = CGRect(x: 240, y: 1420, width: 120, height: 40)
        deleteAllRecordingsButton.setTitle("删除所有录音", for: .normal)
        deleteAllRecordingsButton.addTarget(self, action: #selector(deleteAllRecordings), for: .touchUpInside)
        contentView.addSubview(deleteAllRecordingsButton)
        
        // 格式转换
        let convertLabel = UILabel(frame: CGRect(x: 20, y: 1470, width: 200, height: 30))
        convertLabel.text = "格式转换:"
        contentView.addSubview(convertLabel)
        
        targetFormatPicker.frame = CGRect(x: 20, y: 1510, width: view.bounds.width - 40, height: 100)
        targetFormatPicker.dataSource = self
        targetFormatPicker.delegate = self
        contentView.addSubview(targetFormatPicker)
        
        convertButton.frame = CGRect(x: 20, y: 1620, width: view.bounds.width - 40, height: 40)
        convertButton.setTitle("转换音频文件格式", for: .normal)
        convertButton.addTarget(self, action: #selector(convertAudio), for: .touchUpInside)
        contentView.addSubview(convertButton)
        
        conversionProgressLabel.frame = CGRect(x: 20, y: 1670, width: view.bounds.width - 40, height: 30)
        conversionProgressLabel.text = "转换进度: 0.0%"
        contentView.addSubview(conversionProgressLabel)
        
        // 其他功能
        customSettingsButton.frame = CGRect(x: 20, y: 1710, width: 150, height: 40)
        customSettingsButton.setTitle("自定义录音设置", for: .normal)
        customSettingsButton.addTarget(self, action: #selector(setCustomSettings), for: .touchUpInside)
        contentView.addSubview(customSettingsButton)
        
        releaseButton.frame = CGRect(x: 180, y: 1710, width: 100, height: 40)
        releaseButton.setTitle("释放资源", for: .normal)
        releaseButton.addTarget(self, action: #selector(releaseResources), for: .touchUpInside)
        contentView.addSubview(releaseButton)
        
        contentView.wy_height = CGRectGetMaxY(releaseButton.frame) + 100
    }
    
    // MARK: - 状态更新
    private func logInfo(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let log = "\(timestamp): \(message)\n"
            self.infoTextView.text = self.infoTextView.text + log
            
            // 滚动到底部
            let bottom = NSMakeRange(self.infoTextView.text.count - 1, 1)
            self.infoTextView.scrollRangeToVisible(bottom)
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
        audioKit.pauseRecording()
    }
    
    @objc private func resumeRecording() {
        audioKit.resumeRecording()
    }
    
    @objc private func stopRecording() {
        audioKit.stopRecording()
    }
    
    // MARK: - 播放控制
    @objc private func playLocalAudio() {
        if let testFileURL = Bundle.main.url(forResource: "世间美好与你环环相扣", withExtension: "mp3") {
            do {
                try audioKit.playAudio(at: testFileURL)
            } catch {
                handleError(error)
            }
        } else {
            logInfo("测试音频文件未找到")
        }
    }
    
    @objc private func playRecordedFile() {
        do {
            try audioKit.playRecordedFile()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func pausePlayback() {
        audioKit.pausePlayback()
    }
    
    @objc private func stopPlayback() {
        audioKit.stopPlayback()
    }
    
    @objc private func resumePlayback() {
        audioKit.resumePlayback()
    }
    
    @objc private func seekPlayback() {
        guard let player = audioKit.audioPlayer else {
            logInfo("没有正在播放的音频")
            return
        }
        
        let seekTime = Double(seekSlider.value) * player.duration
        audioKit.seekPlayback(to: seekTime)
        logInfo("跳转到: \(String(format: "%.1f", seekTime))秒")
    }
    
    // MARK: - 设置控制
    @objc private func minDurationChanged() {
        minRecordingDuration = TimeInterval(minDurationSlider.value)
        audioKit.setRecordingDurations(min: minRecordingDuration, max: maxRecordingDuration)
        logInfo("设置最小录音时长: \(minRecordingDuration)秒")
    }
    
    @objc private func maxDurationChanged() {
        maxRecordingDuration = TimeInterval(maxDurationSlider.value)
        audioKit.setRecordingDurations(min: minRecordingDuration, max: maxRecordingDuration)
        logInfo("设置最大录音时长: \(maxRecordingDuration)秒")
    }
    
    @objc private func qualityChanged() {
        let quality: WYAudioQuality
        switch qualitySegmentedControl.selectedSegmentIndex {
        case 0: quality = .low
        case 1: quality = .medium
        default: quality = .high
        }
        
        audioKit.setAudioQuality(quality)
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
        
        audioKit.playRemoteAudio(from: url) { [weak self] result in
            switch result {
            case .success(let url):
                self?.logInfo("网络音频播放成功,存储地址：\(url.lastPathComponent)")
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - 文件管理
    @objc private func refreshFileList() {
        let tempDir = FileManager.default.temporaryDirectory
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        
        var fileList = "临时目录文件:\n"
        fileList += listFiles(in: tempDir)
        
        fileList += "\n文档目录文件:\n"
        fileList += listFiles(in: docDir)
        
        fileList += "\n缓存目录文件:\n"
        fileList += listFiles(in: cacheDir)
        
        fileListTextView.text = fileList
    }
    
    private func listFiles(in directory: URL) -> String {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var fileInfo = ""
            
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                let size = attributes[.size] as? Int64 ?? 0
                let date = attributes[.creationDate] as? Date ?? Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let sizeMB = Double(size) / (1024 * 1024)
                
                fileInfo += "\(file.lastPathComponent)\n"
                fileInfo += "  大小: \(String(format: "%.2f", sizeMB)) MB\n"
                fileInfo += "  创建时间: \(dateFormatter.string(from: date))\n"
                fileInfo += "  格式: \(file.pathExtension.uppercased())\n\n"
            }
            
            return fileInfo.isEmpty ? "无文件\n" : fileInfo
        } catch {
            return "读取文件失败: \(error.localizedDescription)\n"
        }
    }
    
    @objc private func saveRecording() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "saved_audio_\(Date().timeIntervalSince1970).\(selectedFormat.rawValue)"
        let destinationURL = docDir.appendingPathComponent(fileName)
        
        do {
            try audioKit.saveRecording(to: destinationURL)
            logInfo("文件已保存到: \(destinationURL.lastPathComponent)")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func deleteRecording() {
        do {
            try audioKit.deleteRecording()
            logInfo("录音文件已删除")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    @objc private func deleteAllRecordings() {
        do {
            try audioKit.deleteAllRecordings()
            logInfo("所有录音文件已删除")
            refreshFileList()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - 格式转换
    @objc private func convertAudio() {
        guard let sourceURL = audioKit.currentRecordFileURL else {
            logInfo("没有可转换的录音文件")
            return
        }
        
        logInfo("开始转换格式: \(sourceURL.lastPathComponent) -> \(targetFormat.rawValue)")
        
        audioKit.convertAudioFile(sourceURL: sourceURL, targetFormat: targetFormat) { [weak self] result in
            switch result {
            case .success(let newURL):
                self?.logInfo("格式转换成功: \(newURL.lastPathComponent)")
                self?.refreshFileList()
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    // MARK: - 其他功能
    @objc private func setCustomSettings() {
        // 自定义录音参数：采样率22050，比特率64000，双声道
        let customSettings: [String: Any] = [
            AVSampleRateKey: 22050.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 64000
        ]
        
        audioKit.setRecordSettings(customSettings)
        logInfo("设置自定义录音参数: 采样率22.05kHz, 比特率64kbps, 双声道")
    }
    
    @objc private func releaseResources() {
        audioKit.release()
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
        case .permissionDenied: return "录音权限被拒绝"
        case .fileNotFound: return "音频文件未找到"
        case .recordingInProgress: return "录音正在进行中"
        case .playbackError: return "播放错误"
        case .fileSaveFailed: return "录音文件保存失败"
        case .minDurationNotReached: return "录音时长未达到最小值"
        case .maxDurationReached: return "录音达到最大时长"
        case .downloadFailed: return "音频下载失败"
        case .invalidRemoteURL: return "无效的远程URL"
        case .conversionFailed: return "格式转换失败"
        case .conversionCancelled: return "格式转换已取消"
        case .formatNotSupported: return "不支持的录制格式"
        case .outOfMemory: return "内存不足"
        case .sessionConfigurationFailed: return "音频会话配置失败"
        case .directoryCreationFailed: return "文件目录创建失败"
        }
    }
    
    private func directoryDescription(for directory: WYAudioStorageDirectory) -> String {
        switch directory {
        case .temporary: return "临时目录"
        case .documents: return "文档目录"
        case .caches: return "缓存目录"
        }
    }
    
    deinit {
        audioKit.release()
    }
}

// MARK: - WYAudioKitDelegate
extension TestAudioController: WYAudioKitDelegate {
    
    func audioRecorderDidStart() {
        logInfo("开始录制 \(selectedFormat.rawValue) 格式音频")
    }
    
    func audioRecorderDidPause() {
        logInfo("录音已暂停")
    }
    
    func audioRecorderDidResume() {
        logInfo("录音已恢复")
    }
    
    func audioRecorderDidStop() {
        logInfo("录音停止")
    }
    
    func audioRecorderTimeUpdated(currentTime: TimeInterval, duration: TimeInterval) {
        recordProgressLabel.text = String(format: "录音进度: %.1f秒/%.1f秒 (%.1f%%)",
                                          currentTime, duration, (currentTime/duration)*100)
    }
    
    func audioRecorderDidFail(error: WYAudioError) {
        logInfo("录音错误: \(errorDescription(for: error))")
    }
    
    func audioPlayerDidStart() {
        logInfo("播放开始")
    }
    
    func audioPlayerDidPause() {
        logInfo("播放暂停")
    }
    
    func audioPlayerDidResume() {
        logInfo("播放恢复")
    }
    
    func audioPlayerDidStop() {
        logInfo("播放停止")
    }
    
    func audioPlayerTimeUpdated(currentTime: TimeInterval, duration: TimeInterval, progress: Double) {
        playProgressLabel.text = String(format: "播放进度: %.1f秒/%.1f秒 (%.1f%%)",
                                        currentTime, duration, progress*100)
    }
    
    func audioPlayerDidFinishPlaying() {
        logInfo("播放完成")
    }
    
    func audioPlayerDidFail(error: WYAudioError) {
        logInfo("播放失败: \(errorDescription(for: error))")
    }
    
    func remoteAudioDownloadProgressUpdated(progress: Double) {
        downloadProgressLabel.text = String(format: "下载进度: %.1f%%", progress*100)
    }
    
    func conversionProgressUpdated(progress: Double) {
        conversionProgressLabel.text = String(format: "转换进度: %.1f%%", progress*100)
    }
    
    func conversionDidComplete(url: URL) {
        logInfo("格式转换完成: \(url.lastPathComponent)")
    }
    
    func audioSessionConfigurationFailed(error: any Error) {
        logInfo("音频会话配置失败: \(error.localizedDescription)")
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension TestAudioController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return supportedFormats.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let format = supportedFormats[row]
        return "\(format.rawValue.uppercased()) (\(formatDescription(for: format)))"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == formatPicker {
            selectedFormat = supportedFormats[row]
            logInfo("已选择录音格式: \(selectedFormat.rawValue.uppercased())")
        } else {
            targetFormat = supportedFormats[row]
            logInfo("已选择目标格式: \(targetFormat.rawValue.uppercased())")
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
