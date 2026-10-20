//
//  WYTestDanmakuController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/19.
//

import UIKit
import AVFoundation
import SnapKit
import WYBasisKitSwift

/// 弹幕测试页(视频边下边播叠弹幕，演示播放时间注入驱动、暂停冻结、定位清屏与外观轨道配置)
class WYTestDanmakuController: UIViewController {

    /// 播放器
    let player = AVPlayer()

    /// 播放器画面层
    var playerLayer: AVPlayerLayer?

    /// 播放区容器(画面层挂它上面)
    let playerContainer = UIView()

    /// 弹幕视图(叠在视频上)
    let danmakuView = WYDanmakuView()

    /// 自定义弹幕输入框
    let inputTextField = UITextField()

    /// 播放进度滑块(拖动时联动弹幕定位清屏)
    let progressSlider = UISlider()

    /// 播放时间标签
    let timeLabel = UILabel()

    /// 播放暂停按钮
    let playButton = UIButton(type: .system)

    /// 弹幕操作列表
    let tableView = UITableView(frame: .zero, style: .plain)

    /// 播放进度监听
    var timeObserver: Any?

    /// 自动弹幕定时器
    var autoDanmakuTimer: Timer?

    /// 自动弹幕计数
    var autoDanmakuIndex = 0

    /// 拖动滑块时暂停注入的标记
    var isDraggingSlider = false

    /// 动作清单(标题与点击行为)
    lazy var actions: [(String, () -> Void)] = [
        ("发滚动弹幕", { [weak self] in
            self?.danmakuView.send(Self.randomText())
            self?.danmakuView.send(Self.randomText())
        }),
        ("发顶部弹幕", { [weak self] in self?.danmakuView.send(Self.randomText(), type: .top) }),
        ("发底部弹幕", { [weak self] in self?.danmakuView.send(Self.randomText(), type: .bottom) }),
        ("发彩色富文本弹幕", { [weak self] in self?.sendColoredDanmaku() }),
        ("发送输入框内容", { [weak self] in self?.sendInputText() }),
        ("自动弹幕 开/关", { [weak self] in self?.toggleAutoDanmaku() }),
        ("轨道条数 0/3/6 切换", { [weak self] in self?.toggleTrackCount() }),
        ("显示区域 1/4~全部循环", { [weak self] in self?.toggleDisplayArea() }),
        ("滚动时长 4/8/12秒循环", { [weak self] in self?.toggleScrollDuration() }),
        ("满轨策略 排队/丢弃切换", { [weak self] in self?.toggleOverflowPolicy() }),
        ("清屏", { [weak self] in self?.danmakuView.clear() })
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "弹幕"
        setupPlayerUI()
        setupControlUI()
        setupActionList()
        setupPlayerClock()
        startAutoDanmaku()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: playerContainer.bounds.height)
    }

    /// 搭建播放区(视频画面与弹幕叠加)
    func setupPlayerUI() {
        playerContainer.backgroundColor = .black
        view.addSubview(playerContainer)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerContainer.layer.addSublayer(layer)
        playerLayer = layer

        view.addSubview(danmakuView)

        playerContainer.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(playerContainer.snp.width).multipliedBy(9.0 / 16.0)
        }
        danmakuView.snp.makeConstraints { (make) in
            make.edges.equalTo(playerContainer)
        }
    }

    /// 搭建播放控制区(播放暂停、进度滑块、时间标签、弹幕输入框)
    func setupControlUI() {
        playButton.setTitle("播放", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonClicked), for: .touchUpInside)
        view.addSubview(playButton)

        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        view.addSubview(progressSlider)

        timeLabel.text = "00:00 / 00:00"
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .darkGray
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)

        inputTextField.placeholder = "输入弹幕内容点下方发送"
        inputTextField.font = .systemFont(ofSize: 13)
        inputTextField.textColor = .darkGray
        inputTextField.borderStyle = .roundedRect
        inputTextField.clearButtonMode = .whileEditing
        view.addSubview(inputTextField)

        playButton.snp.makeConstraints { (make) in
            make.top.equalTo(playerContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(64)
        }
        progressSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.left.equalTo(playButton.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(progressSlider.snp.bottom).offset(4)
            make.left.right.equalTo(progressSlider)
        }
        inputTextField.snp.makeConstraints { (make) in
            make.top.equalTo(timeLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
    }

    /// 搭建弹幕操作列表
    func setupActionList() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextField.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 接播放器时钟(把播放时间注入弹幕，播放暂停冻结弹幕，拖进度定位清屏)
    func setupPlayerClock() {
        let mediaURL = URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_5MB.mp4")!
        player.replaceCurrentItem(with: WYMediaCache.shared.playerItem(with: mediaURL))
        player.play()
        playButton.setTitle("暂停", for: .normal)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] (time) in
            guard let self = self, self.isDraggingSlider == false else { return }
            let seconds = CMTimeGetSeconds(time)
            self.danmakuView.play(at: seconds)
            self.progressSlider.value = Float(seconds / 10)
            self.timeLabel.text = "\(Self.timeText(seconds)) / 00:10"
        }
    }

    /// 发彩色富文本弹幕(演示富文本与描边外观)
    func sendColoredDanmaku() {
        let colors: [UIColor] = [.systemYellow, .systemRed, .systemTeal, .systemPink]
        let color = colors.randomElement() ?? .systemYellow
        let attributes: [NSAttributedString.Key: Any] = [.font: danmakuView.configuration.font,
                                                         .foregroundColor: color,
                                                         .strokeColor: danmakuView.configuration.textStrokeColor,
                                                         .strokeWidth: danmakuView.configuration.textStrokeWidth]
        danmakuView.send(NSAttributedString(string: Self.randomText(), attributes: attributes))
    }

    /// 发输入框内容(空内容提示)
    func sendInputText() {
        guard let text = inputTextField.text, text.isEmpty == false else { return }
        danmakuView.send(text)
        inputTextField.text = nil
    }

    /// 自动弹幕开关切换
    func toggleAutoDanmaku() {
        if autoDanmakuTimer != nil {
            stopAutoDanmaku()
        }else {
            startAutoDanmaku()
        }
    }

    /// 开自动弹幕(每 0.5 秒随机发一条)
    func startAutoDanmaku() {
        guard autoDanmakuTimer == nil else { return }
        autoDanmakuTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] (_) in
            guard let self = self else { return }
            let types: [WYDanmakuType] = [.scroll, .scroll, .scroll, .top, .bottom]
            self.danmakuView.send(Self.randomText(index: self.autoDanmakuIndex), type: types[self.autoDanmakuIndex % types.count])
            self.autoDanmakuIndex += 1
        }
    }

    /// 停自动弹幕
    func stopAutoDanmaku() {
        autoDanmakuTimer?.invalidate()
        autoDanmakuTimer = nil
    }

    /// 轨道条数 0(自适应)/3/6 循环切换
    func toggleTrackCount() {
        let next: Int
        if danmakuView.configuration.trackCount == 0 {
            next = 3
        }else if danmakuView.configuration.trackCount == 3 {
            next = 6
        }else {
            next = 0
        }
        danmakuView.configuration.trackCount = next
    }

    /// 显示区域比例 1/4、1/2、3/4、全部循环切换
    func toggleDisplayArea() {
        let ratios: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
        let currentIndex = ratios.firstIndex(of: danmakuView.configuration.displayAreaRatio) ?? 2
        danmakuView.configuration.displayAreaRatio = ratios[(currentIndex + 1) % ratios.count]
    }

    /// 滚动时长 4/8/12 秒循环切换
    func toggleScrollDuration() {
        let durations: [TimeInterval] = [4, 8, 12]
        let currentIndex = durations.firstIndex(of: danmakuView.configuration.scrollDuration) ?? 1
        danmakuView.configuration.scrollDuration = durations[(currentIndex + 1) % durations.count]
    }

    /// 满轨策略排队/丢弃切换
    func toggleOverflowPolicy() {
        danmakuView.configuration.overflowPolicy = (danmakuView.configuration.overflowPolicy == .queue) ? .discard : .queue
    }

    /// 播放暂停切换(暂停时弹幕随之冻结)
    @objc func playButtonClicked() {
        if player.timeControlStatus == .playing {
            player.pause()
            danmakuView.pause()
            playButton.setTitle("播放", for: .normal)
        }else {
            player.play()
            playButton.setTitle("暂停", for: .normal)
        }
    }

    /// 拖动进度条定位(弹幕定位清屏，松手前不回写滑块位置)
    @objc func progressSliderChanged() {
        isDraggingSlider = true
        let target = Double(progressSlider.value) * 10
        danmakuView.seek(to: target)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { [weak self] (_) in
            self?.isDraggingSlider = false
        }
    }

    /// 随机弹幕文案
    static func randomText(index: Int? = nil) -> String {
        let samples = ["前方高能", "这段太好看了", "弹幕测试走一波", "官人的弹幕组件", "轨道分配不重叠", "暂停冻结定位清屏",
                       "滚动顶部底部三类型", "边下边播叠弹幕", "富文本带描边", "排队策略满轨不丢"]
        let number = index ?? Int.random(in: 0..<samples.count)
        return "\(samples[number % samples.count])\(number % 97)"
    }

    /// 秒数转分秒文字
    static func timeText(_ seconds: Double) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        stopAutoDanmaku()
    }
}

extension WYTestDanmakuController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = actions[indexPath.row].0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        actions[indexPath.row].1()
    }
}
