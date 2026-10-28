//
//  WYTestMediaCacheController.swift
//  SwiftVerify
//
//  Created by 官人 on 2026/10/19.
//

import UIKit
import AVFoundation
import SnapKit
import WYBasisKitSwift

/// 视频边下边播测试页(用 WYMediaCache 播放在线 mp4，演示边下边播、重播秒开、预下载、完整缓存本地播、LRU 容量淘汰与清空缓存)
class WYTestMediaCacheController: UIViewController {

    /// 播放器
    let player = AVPlayer()

    /// 播放器画面层
    var playerLayer: AVPlayerLayer?

    /// 播放区容器(画面层挂它上面)
    let playerContainer = UIView()

    /// 播放暂停按钮
    let playButton = UIButton(type: .system)

    /// 播放进度滑块
    let progressSlider = UISlider()

    /// 播放时间标签
    let timeLabel = UILabel()

    /// 素材切换条(三个公共示例视频，后两个体积小适合演示容量淘汰)
    let mediaSegment = UISegmentedControl(items: ["正片 87MB", "花絮 33MB", "小视频1", "小视频2"])

    /// 素材清单(地址为数英、test-videos 与 MDN 的公共示例视频，前两项为长片方便观察缓存进度)
    let mediaList: [(name: String, url: URL)] = [
        (name: "正片 87MB", url: URL(string: "https://file.digitaling.com/eImg/uvideos/2026/0202/1770014172754013.mp4")!),
        (name: "花絮 33MB", url: URL(string: "https://file.digitaling.com/eImg/uvideos/2026/0202/1770014287213328.mp4")!),
        (name: "小视频1", url: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4")!),
        (name: "小视频2", url: URL(string: "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4")!)
    ]

    /// 当前素材下标
    var currentIndex = 0

    /// 自定义视频地址(点过播放输入框地址后生效，优先于素材清单)
    var activeCustomURL: URL?

    /// 自定义视频地址输入框
    let urlTextField = UITextField()

    /// 蜂窝流量确认是否开启(测试开关状态随页面)
    var cellularConfirmEnabled = false

    /// 播放进度监听
    var timeObserver: Any?

    /// 缓存区间可视化条
    let rangesView = WYMediaCacheRangesView()

    /// 缓存状态文字
    let statusLabel = UILabel()

    /// 动作清单(标题与点击行为)
    lazy var actions: [(String, () -> Void)] = [
        ("在线播放(边下边播)", { [weak self] in self?.playCurrentMedia(useCache: true) }),
        ("停止后重播(已缓存部分秒开)", { [weak self] in self?.replayCachedMedia() }),
        ("预下载整个视频", { [weak self] in self?.downloadCurrentMedia() }),
        ("取消预下载", { [weak self] in self?.cancelDownload() }),
        ("播放本地完整缓存文件", { [weak self] in self?.playLocalCachedFile() }),
        ("播放输入框地址(边下边播)", { [weak self] in self?.playCustomURL() }),
        ("蜂窝流量确认(阈值5MB)开/关", { [weak self] in self?.toggleCellularConfirm() }),
        ("清除当前素材缓存", { [weak self] in self?.removeCurrentCache() }),
        ("LRU容量淘汰演示(临时上限2MB)", { [weak self] in self?.runLRUDemo() }),
        ("清空全部缓存", { [weak self] in self?.clearAllCache() })
    ]

    /// 动作列表
    let tableView = UITableView(frame: .zero, style: .plain)

    /// 状态刷新定时器
    var statusTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "视频边下边播"
        setupPlayerUI()
        setupStatusUI()
        setupActionList()
        startStatusTimer()
        playCurrentMedia(useCache: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: playerContainer.bounds.height)
    }

    /// 搭建播放区(画面、素材切换、播放暂停、进度条)
    func setupPlayerUI() {
        playerContainer.backgroundColor = .black
        view.addSubview(playerContainer)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerContainer.layer.addSublayer(layer)
        playerLayer = layer

        mediaSegment.selectedSegmentIndex = 0
        mediaSegment.addTarget(self, action: #selector(mediaSegmentChanged), for: .valueChanged)
        view.addSubview(mediaSegment)

        playButton.setTitle("播放", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonClicked), for: .touchUpInside)
        view.addSubview(playButton)

        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        view.addSubview(progressSlider)

        timeLabel.text = "00:00 / 00:00"
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .darkGray
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)

        playerContainer.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(playerContainer.snp.width).multipliedBy(9.0 / 16.0)
        }
        mediaSegment.snp.makeConstraints { (make) in
            make.top.equalTo(playerContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        playButton.snp.makeConstraints { (make) in
            make.top.equalTo(mediaSegment.snp.bottom).offset(8)
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

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] (time) in
            self?.refreshPlaybackTime(time)
        }
    }

    /// 搭建缓存状态区(区间可视化条与状态文字)
    func setupStatusUI() {
        rangesView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        rangesView.layer.cornerRadius = 3
        rangesView.clipsToBounds = true
        view.addSubview(rangesView)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .darkGray
        statusLabel.numberOfLines = 0
        statusLabel.text = "等待缓存状态"
        view.addSubview(statusLabel)

        rangesView.snp.makeConstraints { (make) in
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(8)
        }
        statusLabel.snp.makeConstraints { (make) in
            make.top.equalTo(rangesView.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        urlTextField.placeholder = "输入 mp4 视频直链，点下方播放输入框地址"
        urlTextField.font = .systemFont(ofSize: 13)
        urlTextField.textColor = .darkGray
        urlTextField.borderStyle = .roundedRect
        urlTextField.clearButtonMode = .whileEditing
        urlTextField.autocorrectionType = .no
        urlTextField.autocapitalizationType = .none
        view.addSubview(urlTextField)
        urlTextField.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
    }

    /// 搭建动作列表
    func setupActionList() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        // 表头放一份操作指引，照着点就能把缓存能力过一遍
        let guideLabel = UILabel()
        guideLabel.text = Self.guideText
        guideLabel.font = .systemFont(ofSize: 12)
        guideLabel.textColor = .darkGray
        guideLabel.numberOfLines = 0
        let guideWidth = view.bounds.width - 32
        let guideTextNSString = (guideLabel.text ?? "") as NSString
        let guideSize = guideTextNSString.boundingRect(with: CGSize(width: guideWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: guideLabel.font as Any], context: nil)
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: guideSize.height + 20))
        guideLabel.frame = CGRect(x: 16, y: 10, width: guideWidth, height: ceil(guideSize.height))
        headerView.addSubview(guideLabel)
        tableView.tableHeaderView = headerView

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(urlTextField.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 开启缓存状态刷新定时器
    func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] (_) in
            self?.refreshCacheStatus()
        }
    }

    /// 当前生效的播放地址(输入框地址生效时用它，否则用素材清单当前项)
    var currentMediaURL: URL {
        return activeCustomURL ?? mediaList[currentIndex].url
    }

    /// 用当前素材构造带缓存的播放条并播放(使用缓存在 false 时直接播原地址对照)
    func playCurrentMedia(useCache: Bool) {
        let mediaURL = currentMediaURL
        let item = useCache ? WYMediaCache.shared.playerItem(with: mediaURL) : AVPlayerItem(url: mediaURL)
        player.replaceCurrentItem(with: item)
        player.play()
        playButton.setTitle("暂停", for: .normal)
    }

    /// 停止后重播当前素材(已缓存部分直接读盘，起播明显变快)
    func replayCachedMedia() {
        player.pause()
        player.seek(to: .zero)
        playCurrentMedia(useCache: true)
    }

    /// 预下载当前素材整个视频
    func downloadCurrentMedia() {
        let mediaURL = currentMediaURL
        statusLabel.text = "开始预下载"
        WYMediaCache.shared.download(url: mediaURL, progress: { [weak self] (cachedBytes, contentLength) in
            self?.statusLabel.text = "预下载中 \(Self.sizeText(cachedBytes)) / \(Self.sizeText(contentLength))"
        }, completion: { [weak self] (error) in
            if let error = error {
                self?.statusLabel.text = "预下载失败 \(error.localizedDescription)"
            }else {
                self?.statusLabel.text = "预下载完成，可断网重播验证"
            }
        })
    }

    /// 取消预下载
    func cancelDownload() {
        WYMediaCache.shared.cancelDownload(url: currentMediaURL)
        statusLabel.text = "已取消预下载"
    }

    /// 播放本地完整缓存文件(没缓存完整时提示)
    func playLocalCachedFile() {
        guard let filePath = WYMediaCache.shared.cachedFilePath(for: currentMediaURL) else {
            statusLabel.text = "还没有完整缓存，先预下载或完整播一遍"
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: URL(fileURLWithPath: filePath)))
        player.play()
        playButton.setTitle("暂停", for: .normal)
        statusLabel.text = "正在播放本地缓存文件"
    }

    /// LRU 容量淘汰演示(临时把上限调到 2MB，依次下载两个小视频，第二个完成后第一个应被淘汰，最后恢复原上限)
    func runLRUDemo() {
        isDemoRunning = true
        let originalLimit = WYMediaCache.shared.config.maxCacheSize
        WYMediaCache.shared.config.maxCacheSize = 2 * 1024 * 1024
        statusLabel.text = "容量上限临时调为 2MB，开始下载小视频1"
        let first = mediaList[2].url
        let second = mediaList[3].url
        WYMediaCache.shared.download(url: first, progress: nil, completion: { [weak self] (_) in
            guard let self = self else { return }
            let status = WYMediaCache.shared.cacheStatus(for: first)
            self.statusLabel.text = "小视频1完成(完整 \(status.isFullyCached))，开始下载小视频2"
            WYMediaCache.shared.download(url: second, progress: nil, completion: { [weak self] (_) in
                guard let self = self else { return }
                let firstStatus = WYMediaCache.shared.cacheStatus(for: first)
                let secondStatus = WYMediaCache.shared.cacheStatus(for: second)
                WYMediaCache.shared.config.maxCacheSize = originalLimit
                self.isDemoRunning = false
                self.statusLabel.text = "小视频1被淘汰(\(Self.sizeText(firstStatus.cachedBytes)))，小视频2保留(完整 \(secondStatus.isFullyCached))，容量上限已恢复"
            })
        })
    }

    /// 切换蜂窝流量确认开关(开为阈值 5MB，关为不限制，真机蜂窝网络下生效)
    func toggleCellularConfirm() {
        cellularConfirmEnabled.toggle()
        WYMediaCache.shared.config.cellularConfirmSizeLimit = cellularConfirmEnabled ? 5 * 1024 * 1024 : 0
        statusLabel.text = cellularConfirmEnabled ? "蜂窝流量确认已开启(阈值 5MB，真机蜂窝网络下生效)" : "蜂窝流量确认已关闭"
    }

    /// 播放输入框地址(地址非法时提示)
    func playCustomURL() {
        guard let text = urlTextField.text, text.isEmpty == false, let url = URL(string: text), url.scheme?.hasPrefix("http") == true else {
            statusLabel.text = "输入框里先填一个 http/https 的视频直链"
            return
        }
        activeCustomURL = url
        playCurrentMedia(useCache: true)
    }

    /// 清除当前素材缓存(正在播放的条目闲置后自动清理)
    func removeCurrentCache() {
        WYMediaCache.shared.removeCache(for: currentMediaURL)
        statusLabel.text = "已清除当前素材缓存"
        refreshCacheStatus()
    }

    /// 清空全部缓存
    func clearAllCache() {
        player.pause()
        WYMediaCache.shared.clearCache()
        statusLabel.text = "已清空全部缓存"
        refreshCacheStatus()
    }

    /// 是否正在跑演示(演示文案不被状态定时器冲掉)
    var isDemoRunning = false

    /// 刷新缓存状态展示(区间条、进度文字、总容量)
    func refreshCacheStatus() {
        if isDemoRunning { return }
        let media = mediaList[currentIndex]
        let status = WYMediaCache.shared.cacheStatus(for: media.url)
        rangesView.cachedRanges = status.cachedRanges
        rangesView.contentLength = status.contentLength
        if let duration = player.currentItem?.duration, duration.isValid, duration.seconds > 0 {
            rangesView.playbackRatio = CGFloat(CMTimeGetSeconds(player.currentTime()) / duration.seconds)
        }
        rangesView.setNeedsDisplay()
        let totalSize = WYMediaCache.shared.totalCacheSize()
        let networkText = WYMediaCache.shared.isNetworkOnline ? (WYMediaCache.shared.isNetworkCellular ? "蜂窝" : "WiFi") : "断网"
        statusLabel.text = "已缓存 \(Self.sizeText(status.cachedBytes)) / \(Self.sizeText(status.contentLength))，区间数 \(status.cachedRanges.count)，缓存目录共 \(Self.sizeText(totalSize))，网络 \(networkText)"
    }

    /// 刷新播放时间展示
    func refreshPlaybackTime(_ time: CMTime) {
        let duration = player.currentItem?.duration.seconds ?? 0
        guard duration.isFinite, duration > 0 else { return }
        progressSlider.value = Float(CMTimeGetSeconds(time) / duration)
        timeLabel.text = "\(Self.timeText(CMTimeGetSeconds(time))) / \(Self.timeText(duration))"
    }

    /// 素材切换
    @objc func mediaSegmentChanged() {
        currentIndex = mediaSegment.selectedSegmentIndex
        activeCustomURL = nil
        player.pause()
        playCurrentMedia(useCache: true)
    }

    /// 播放暂停切换
    @objc func playButtonClicked() {
        if player.timeControlStatus == .playing {
            player.pause()
            playButton.setTitle("播放", for: .normal)
        }else {
            player.play()
            playButton.setTitle("暂停", for: .normal)
        }
    }

    /// 拖动进度条定位
    @objc func progressSliderChanged() {
        let duration = player.currentItem?.duration.seconds ?? 0
        guard duration.isFinite, duration > 0 else { return }
        player.seek(to: CMTime(seconds: duration * Double(progressSlider.value), preferredTimescale: 600))
    }

    /// 操作指引文案(每步带预期结果)
    static let guideText = "操作指引\n1 在线播放，绿色缓存条随播放增长，已缓存数字变大\n2 播一段后点停止后重播，起播明显变快(已缓存部分读的本地盘)\n3 预下载整个视频，等进度走完提示完成\n4 断网后点播放本地完整缓存文件，无网也能正常播\n5 LRU容量淘汰演示，上限临时调为 2MB，最久未用的缓存被自动清掉\n6 切换顶部素材再重复，各素材缓存互不影响\n7 在输入框贴自己的视频直链点播放输入框地址，任意网络视频都能测\n8 清除当前素材缓存后重播，重新经历一遍首次缓存\n9 真机蜂窝网络下开启蜂窝流量确认后，播大视频会先弹窗征询\n10 断网再恢复或回前台，播放与预下载自动续起"

    /// 字节数转显示文字
    static func sizeText(_ bytes: Int64) -> String {
        let megaBytes = Double(bytes) / 1024 / 1024
        return String(format: "%.1fMB", megaBytes)
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
        statusTimer?.invalidate()
    }
}

extension WYTestMediaCacheController: UITableViewDataSource, UITableViewDelegate {

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

/// 缓存区间可视化条(灰色底表示整个文件，绿色块表示已缓存区间，红线表示播放位置)
class WYMediaCacheRangesView: UIView {

    /// 已缓存区间列表
    var cachedRanges: [WYMediaCacheRange] = []

    /// 媒体文件总大小，单位为字节
    var contentLength: Int64 = 0

    /// 播放位置占全片比例
    var playbackRatio: CGFloat = 0

    override func draw(_ rect: CGRect) {
        guard contentLength > 0 else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let cachedColor = UIColor.systemGreen
        let playColor = UIColor.systemRed
        for range in cachedRanges {
            let startRatio = CGFloat(range.start) / CGFloat(contentLength)
            let endRatio = CGFloat(range.end) / CGFloat(contentLength)
            context.setFillColor(cachedColor.cgColor)
            context.fill(CGRect(x: rect.minX + startRatio * rect.width, y: rect.minY, width: max(1, (endRatio - startRatio) * rect.width), height: rect.height))
        }
        if playbackRatio > 0 {
            context.setFillColor(playColor.cgColor)
            context.fill(CGRect(x: rect.minX + playbackRatio * rect.width, y: rect.minY, width: 2, height: rect.height))
        }
    }
}
