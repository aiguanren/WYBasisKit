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

    /// 演示用多档素材(同一支幕后花絮的360p与1080p，切清晰度时画面内容不变，默认标清起播快)
    let multiAsset: WYVideoPlayerMediaAsset = {
        let standard = WYVideoPlayerMediaQuality(name: "标清", url: URL(string: "https://videoal-platform.cdn.huya.com/leaf/1048585/59a91b252545dcc3e53b1e831b45d090/99634977/73467960_2e4da4f83b6e2e39a68377497b56de2f_264_360_1.mp4?hyvid=1093775374&hyauid=1239535418978&hyroomid=1239535418978&hyratio=350&hyscence=vod&appid=66&domainid=41&srckey=NjZfNDFfMTA5Mzc3NTM3NA%3D%3D&&bitrate=328&client=110&definition=350&pid=1239535418978&scene=vod&vid=1093775374")!)
        let high = WYVideoPlayerMediaQuality(name: "高清", url: URL(string: "https://videoal-platform.cdn.huya.com/leaf/1048585/59a91b252545dcc3e53b1e831b45d090/99634977/73467960_d3f67e02fa27857a54ca55b15f2c5878_264_1080_1_max.mp4?hyvid=1093775374&hyauid=1239535418978&hyroomid=1239535418978&hyratio=4000&hyscence=vod&appid=66&domainid=41&srckey=NjZfNDFfMTA5Mzc3NTM3NA%3D%3D&&bitrate=1803&client=110&definition=yuanhua&pid=1239535418978&scene=vod&vid=1093775374")!)
        return WYVideoPlayerMediaAsset(qualities: [standard, high])
    }()

    /// 演示用单档素材(约12分钟的长片，验证单档地址的完整播放流程)
    let singleAsset = WYVideoPlayerMediaAsset(url: URL(string: "https://file.digitaling.com/eImg/uvideos/2026/0202/1770014172754013.mp4")!)

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
        ("换单档素材(长片)", { [weak self] in
            guard let self = self else { return }
            self.player.play(with: self.singleAsset)
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
            guard let self = self else { return }
            self.log("正在启动画中画")
            WYActivity.showInfo("正在启动画中画", in: self.view)
            self.player.startPictureInPicture()
        }),
        ("边下边播 开/关", { [weak self] in
            guard let self = self else { return }
            self.player.configuration.usesMediaCache.toggle()
        }),
        ("边播边缓存状态", { [weak self] in
            guard let url = self?.player.currentAsset?.currentQuality.url else { return }
            let status = WYMediaCache.shared.cacheStatus(for: url)
            self?.log("已缓存 \(String(format: "%.1f", Double(status.cachedBytes) / 1024 / 1024))MB / \(String(format: "%.1f", Double(status.contentLength) / 1024 / 1024))MB")
        }),
        ("播放本地素材", { [weak self] in
            guard let url = Bundle.main.url(forResource: "乌篷转桨晃一晃，春风牵衣过平江", withExtension: "mp4") else { return }
            self?.player.play(with: url)
        }),
        ("播放指定地址", { [weak self] in
            self?.showURLInput()
        }),
        ("控件显隐 开/关", { [weak self] in
            guard let config = self?.player.configuration else { return }
            config.shellHiddenControls = config.shellHiddenControls.isEmpty ? [.airPlay, .duration] : []
        }),
        ("控件顺序 正序/反序", { [weak self] in
            guard let config = self?.player.configuration else { return }
            config.shellInlineBottomControls.reverse()
        }),
        ("自定义按钮位置 开/关", { [weak self] in
            guard let config = self?.player.configuration else { return }
            if config.shellLayoutHandler != nil { config.shellLayoutHandler = nil; return }
            config.shellLayoutHandler = { _, _, safe, _ in
                let size = UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels)
                return [.more: CGRect(x: max(safe.left, UIDevice.wy_screenWidth(16, WYBasisKitConfig.defaultScreenPixels)), y: safe.top, width: size, height: size)]
            }
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
        player.configuration.shellShowsSnapshotButton = true
        player.configuration.sleepTimerOptions = [3, 900, 1800, 3600]
        player.play(with: multiAsset)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    /// 输入地址验证不同视频来源和网络加载行为
    func showURLInput() {
        let alert = UIAlertController(title: "播放指定地址", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "https://"
            field.keyboardType = .URL
            field.autocapitalizationType = .none
            field.accessibilityIdentifier = "WYVideoPlayerDemo.url"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "播放", style: .default) { [weak self, weak alert] action in
            guard let value = alert?.textFields?.first?.text, let url = URL(string: value),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return }
            self?.player.play(with: url)
        })
        present(alert, animated: true)
    }

    /// 搭建播放器与截图预览
    func setupPlayerUI() {
        player.accessibilityIdentifier = "WYVideoPlayerDemo.player"
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
        statusLabel.accessibilityIdentifier = "WYVideoPlayerDemo.status"
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

    func wy_videoPlayer(_ player: WYVideoPlayer, didFailWithError error: Error) {
        log("播放操作失败：\(error.localizedDescription)")
        WYActivity.showInfo("播放操作失败：\(error.localizedDescription)", in: view)
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
