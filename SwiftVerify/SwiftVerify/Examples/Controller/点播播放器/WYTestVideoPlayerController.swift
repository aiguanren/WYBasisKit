//
//  WYTestVideoPlayerController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/19.
//

import UIKit
import AVKit
import SnapKit
import WYBasisKitSwift

/// 点播播放器测试页(边下边播叠弹幕字幕，演示手势壳全屏清晰度切换截图画中画与代理回调)
class WYTestVideoPlayerController: UIViewController, WYVideoPlayerDelegate, UITableViewDataSource, UITableViewDelegate {

    /// 播放器
    let player = WYVideoPlayer()

    /// 截图预览小图
    let snapshotImageView = UIImageView()

    /// 状态文字(状态/时间/最近一条代理日志)
    let statusLabel = UILabel()

    /// 操作列表
    let tableView = UITableView(frame: .zero, style: .plain)

    /// 自动弹幕计数
    var danmakuIndex = 0

    /// 自动弹幕定时器
    var danmakuTimer: Timer?

    /// 演示用多档素材
    let multiAsset: WYVideoPlayerMediaAsset = {
        let high = WYVideoPlayerMediaQuality(name: "高清", url: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_5MB.mp4")!)
        let standard = WYVideoPlayerMediaQuality(name: "标清", url: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4")!)
        return WYVideoPlayerMediaAsset(qualities: [high, standard])
    }()

    /// 演示用单档素材
    let singleAsset = WYVideoPlayerMediaAsset(url: URL(string: "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_5MB.mp4")!)

    /// 动作清单(标题与点击行为)
    lazy var actions: [(String, () -> Void)] = [
        ("播放 / 暂停", { [weak self] in
            guard let self = self else { return }
            if self.player.state == .playing {
                self.player.pause()
            }else {
                self.player.resume()
            }
        }),
        ("定位到中间", { [weak self] in
            self?.player.seek(to: (self?.player.duration ?? 10) / 2, accurate: true)
        }),
        ("倍速 1.0 / 1.5 / 2.0 循环", { [weak self] in
            guard let self = self else { return }
            let options: [Float] = [1.0, 1.5, 2.0]
            let currentIndex = options.firstIndex(of: self.player.rate) ?? -1
            self.player.rate = options[(currentIndex + 1) % options.count]
        }),
        ("切清晰度 高清 / 标清", { [weak self] in
            guard let self = self else { return }
            self.player.selectQuality(at: (self.player.currentAsset?.selectedIndex == 0) ? 1 : 0)
        }),
        ("加内联SRT字幕并选中", { [weak self] in
            self?.loadInlineSubtitle()
        }),
        ("关闭字幕", { [weak self] in
            self?.player.selectSubtitle(at: -1)
        }),
        ("开弹幕 + 发一条", { [weak self] in
            guard let self = self else { return }
            if self.player.danmakuView == nil {
                self.player.configuration.showsDanmaku = true
            }
            self.player.sendDanmaku("弹幕跟播放时间走\(self.danmakuIndex)")
            self.danmakuIndex += 1
        }),
        ("自动弹幕 开/关", { [weak self] in
            self?.toggleAutoDanmaku()
        }),
        ("截图", { [weak self] in
            self?.player.snapshot(completion: nil)
        }),
        ("进 / 退全屏", { [weak self] in
            guard let self = self else { return }
            if self.player.isFullscreen {
                self.player.exitFullscreen()
            }else {
                self.player.enterFullscreen()
            }
        }),
        ("画中画(真机)", { [weak self] in
            self?.player.startPictureInPicture()
        }),
        ("边下边播 开/关", { [weak self] in
            guard let self = self else { return }
            self.player.configuration.usesMediaCache.toggle()
            self.player.play(with: self.multiAsset)
        }),
        ("边播边缓存状态", { [weak self] in
            guard let url = self?.player.currentAsset?.currentQuality.url else { return }
            let status = WYMediaCache.shared.cacheStatus(for: url)
            self?.log("已缓存 \(String(format: "%.1f", Double(status.cachedBytes) / 1024 / 1024))MB / \(String(format: "%.1f", Double(status.contentLength) / 1024 / 1024))MB")
        }),
        ("重播", { [weak self] in
            self?.player.seek(to: 0, accurate: false)
            self?.player.resume()
        })
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "点播播放器"
        setupPlayerUI()
        setupStatusUI()
        setupActionList()
        player.delegate = self
        player.configuration.showsDanmaku = true
        player.configuration.shellShowsSnapshotButton = true
        player.play(with: multiAsset)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    /// 搭建播放器与截图预览
    func setupPlayerUI() {
        view.addSubview(player)
        player.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(player.snp.width).multipliedBy(9.0 / 16.0)
        }
        snapshotImageView.contentMode = .scaleAspectFit
        snapshotImageView.layer.borderWidth = 1
        snapshotImageView.layer.borderColor = UIColor.lightGray.cgColor
        view.addSubview(snapshotImageView)
        snapshotImageView.snp.makeConstraints { (make) in
            make.top.equalTo(player.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(72)
        }
    }

    /// 搭建状态区
    func setupStatusUI() {
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .darkGray
        statusLabel.numberOfLines = 0
        statusLabel.text = "等待播放"
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { (make) in
            make.top.equalTo(player.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(snapshotImageView.snp.left).offset(-8)
        }
    }

    /// 搭建操作列表
    func setupActionList() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(6)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 装入内联 SRT 字幕并选中
    func loadInlineSubtitle() {
        let srt = """
        1
        00:00:00,500 --> 00:00:02,500
        内联SRT字幕第一条

        2
        00:00:03,000 --> 00:00:05,000
        字幕跟播放时间刷新

        3
        00:00:06,000 --> 00:00:08,000
        第三条内联字幕
        """
        let track = WYVideoPlayerSubtitleTrack(name: "内联SRT", srtText: srt)
        player.appendSubtitleTrack(track)
        player.selectSubtitle(at: player.subtitleTracks.firstIndex(of: track) ?? 0)
    }

    /// 自动弹幕开关
    func toggleAutoDanmaku() {
        if danmakuTimer != nil {
            danmakuTimer?.invalidate()
            danmakuTimer = nil
        }else {
            danmakuTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] (_) in
                guard let self = self else { return }
                let types: [WYDanmakuType] = [.scroll, .scroll, .top, .bottom]
                self.player.sendDanmaku("自动弹幕\(self.danmakuIndex)", type: types[self.danmakuIndex % types.count])
                self.danmakuIndex += 1
            }
        }
    }

    /// 记一条日志
    func log(_ text: String) {
        statusLabel.text = text
    }

    // 代理回调逐条记日志
    func wy_videoPlayer(_ player: WYVideoPlayer, stateDidChange state: WYVideoPlayerState) {
        log("状态 \(String(describing: state))")
    }

    func wy_videoPlayer(_ player: WYVideoPlayer, currentTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval) {
        let current = Int(currentTime)
        let total = Int(duration)
        statusLabel.text = "\(current)s / \(total)s，缓冲到 \(Int(playableDuration))s，状态 \(player.state == .playing ? "播放中" : "非播放")"
    }

    func wy_videoPlayer(_ player: WYVideoPlayer, didTakeSnapshot image: UIImage?) {
        snapshotImageView.image = image
        log("截图\(image == nil ? "失败" : "完成")")
    }

    func wy_videoPlayer(_ player: WYVideoPlayer, qualityDidChangeAtIndex qualityIndex: Int) {
        log("清晰度切到 \(player.currentAsset?.qualities[qualityIndex].name ?? "")")
    }

    func wy_videoPlayer(_ player: WYVideoPlayer, subtitleDidChangeAtIndex trackIndex: Int) {
        log("字幕轨 \(trackIndex)")
    }

    func wy_videoPlayer(_ player: WYVideoPlayer, seekPanDidEndWithTargetTime targetTime: TimeInterval) {
        log("横滑定位到 \(Int(targetTime))s")
    }

    deinit {
        danmakuTimer?.invalidate()
    }
}

extension WYTestVideoPlayerController {

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
