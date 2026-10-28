//
//  WYTestPhotoBrowserController.swift
//  SwiftVerify
//
//  Created by 官人 on 2026/10/19.
//

import UIKit
import AVFoundation
import SnapKit
import WYBasisKitSwift

/// 浏览器测试配置(导航栏配置页里修改，保存后点缩略图按新配置弹浏览器)
struct PhotoBrowserSettingsModel {

    /// 翻页方向(0横向 1纵向)
    var scrollDirection: Int = 0

    /// 同屏布局(0整页 1多页同屏)
    var layoutStyle: Int = 0

    /// 多页同屏两侧露出宽度档位(0窄20 1宽40)
    var revealWidthLevel: Int = 0

    /// 多页同屏页间距档位(0窄10 1宽20)
    var multiPageSpacingLevel: Int = 0

    /// 多页同屏过渡特效(0无 1缩小 2缩小压暗 3横向压缩 4堆叠 5重叠)
    var transformStyle: Int = 0

    /// 转场样式(0缩放 1渐隐)
    var transitionStyle: Int = 0

    /// 页码样式(0文本 1圆点 2无)
    var pageIndicatorStyle: Int = 0

    /// 原图加载方式(0手动 1自动)
    var originalLoadStyle: Int = 0

    /// 双击放大倍数档位(0两倍 1两倍半 2三倍)
    var doubleTapZoomScaleLevel: Int = 0

    /// 捏合上限倍数档位(0三倍 1四倍 2五倍)
    var maxZoomScaleLevel: Int = 0

    /// 拖拽关闭阈值档位(0常规110 1轻拖60 2重拖160)
    var dragDismissThresholdLevel: Int = 0

    /// 相邻页预加载数量(0关闭 1一页 2两页)
    var prefetchCount: Int = 1

    /// 单击是否关闭
    var allowsTapDismiss: Bool = true

    /// 拖拽是否关闭
    var allowsDragDismiss: Bool = true

    /// 长按菜单是否带内置保存动作
    var showsSaveAction: Bool = true

    /// 长按菜单是否带方法演示动作(跳页、数据加一、关闭浏览器)
    var showsMethodActions: Bool = true

    /// 是否循环翻页(滑到末页继续滑回首页)
    var allowsLoopScrolling: Bool = false

    /// 自动轮播档位(0关闭 1两秒 2四秒，需要循环翻页开启才生效)
    var autoCarouselLevel: Int = 0

    /// 外观主题(0默认黑 1深蓝 2浅色)
    var theme: Int = 0
}

/// 图片浏览测试页(九宫格混排真实内容，点任意缩略图从该位置进浏览器滑动浏览，配置经导航栏按钮进配置页修改)
class WYTestPhotoBrowserController: UIViewController, WYPhotoBrowserDataSource, WYPhotoBrowserDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// 测试配置(配置页保存后更新)
    var settings: PhotoBrowserSettingsModel = PhotoBrowserSettingsModel()

    /// 混排浏览项(本地Resource照片、GIF、两级文件、视频封面、LivePhoto，加网络图、网络视频、网络LivePhoto与失败地址)
    var items: [WYPhotoBrowserItem] = []

    /// 本地照片名(Resource里加载，缩略图墙与浏览器共用)
    let localPhotoNames: [String] = ["樱花", "夕阳下的花", "秋天的树", "蓝色小屋", "帆船", "沙滩上的花"]

    /// 事件日志(单行显示最近一条，浏览器关闭后回看)
    var logLabel: UILabel = UILabel()

    /// 九宫格缩略图墙
    var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "图片浏览"
        items = buildItems()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "配置", style: .plain, target: self, action: #selector(settingsButtonTapped))

        logLabel.textAlignment = .center
        logLabel.font = .systemFont(ofSize: 12)
        logLabel.textColor = .darkGray
        logLabel.backgroundColor = UIColor(white: 0.95, alpha: 1)
        logLabel.text = "点缩略图进浏览器，配置经右上角按钮修改"
        view.addSubview(logLabel)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        for (index, item) in items.enumerated() where item.mediaType == .video {
            guard let identifier = item.identifier, identifier.hasPrefix("play:/") else { continue }
            let path = String(identifier.dropFirst("play:".count))
            videoPoster(path: path) { [weak self] image in
                guard let self = self, self.items.indices.contains(index), self.items[index].identifier == item.identifier else { return }
                self.items[index].placeholder = image
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
        }

        logLabel.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            make.left.right.equalToSuperview()
            make.height.equalTo(28)
        }
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(logLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(4)
            make.bottom.equalToSuperview()
        }
    }

    /// 打开配置页(取消不改，保存后按新配置弹浏览器)
    @objc func settingsButtonTapped() {
        let settingsController = WYTestPhotoBrowserSettingsViewController()
        settingsController.settings = settings
        settingsController.onSettingsChanged = { [weak self] newSettings in
            guard let self = self else { return }
            self.settings = newSettings
            self.log("配置已更新(\(self.settingsSummary()))")
        }
        let navigation = UINavigationController(rootViewController: settingsController)
        present(navigation, animated: true)
    }

    /// 配置摘要(日志显示当前关键配置)
    func settingsSummary() -> String {
        let directions = ["横向", "纵向"]
        let transitions = ["缩放", "渐隐"]
        let indicators = ["文本页码", "圆点页码", "无页码"]
        let originals = ["手动原图", "自动原图"]
        let themes = ["默认黑", "深蓝", "浅色"]
        return "\(directions[settings.scrollDirection]) \(transitions[settings.transitionStyle]) \(indicators[settings.pageIndicatorStyle]) \(originals[settings.originalLoadStyle]) \(themes[settings.theme])"
    }

    /// 按当前配置组装浏览器配置
    func buildConfiguration() -> WYPhotoBrowserConfiguration {
        var configuration = WYPhotoBrowserConfiguration()
        configuration.scrollDirection = settings.scrollDirection == 0 ? .horizontal : .vertical
        configuration.layoutStyle = settings.layoutStyle == 0 ? .fullPage : .multiPage
        configuration.multiPageRevealWidth = [40, 60][settings.revealWidthLevel]
        configuration.multiPageSpacing = [10, 20][settings.multiPageSpacingLevel]
        configuration.transformStyle = WYPhotoBrowserTransformStyle(rawValue: settings.transformStyle) ?? .none
        configuration.transitionStyle = settings.transitionStyle == 0 ? .zoom : .fade
        configuration.pageIndicatorStyle = [.text, .dots, .none][settings.pageIndicatorStyle]
        configuration.originalLoadStyle = settings.originalLoadStyle == 0 ? .manual : .automatic
        configuration.doubleTapZoomScale = [2, 2.5, 3][settings.doubleTapZoomScaleLevel]
        configuration.maxZoomScale = [3, 4, 5][settings.maxZoomScaleLevel]
        configuration.dragDismissThreshold = [110, 60, 160][settings.dragDismissThresholdLevel]
        configuration.prefetchCount = settings.prefetchCount
        configuration.allowsLoopScrolling = settings.allowsLoopScrolling
        configuration.autoCarouselInterval = [0, 2, 4][settings.autoCarouselLevel]
        configuration.allowsTapDismiss = settings.allowsTapDismiss
        configuration.allowsDragDismiss = settings.allowsDragDismiss
        configuration.showsSaveAction = settings.showsSaveAction

        var actions: [WYPhotoBrowserAction] = []
        if settings.showsMethodActions {
            actions.append(WYPhotoBrowserAction(title: "跳到最后一页", icon: UIImage(systemName: "forward.end"), handler: { [weak self] browser, _ in
                guard let self = self else { return }
                browser.scrollToItem(at: self.items.count - 1, animated: true)
                self.log("scrollToItem 到最后一页")
            }))
            actions.append(WYPhotoBrowserAction(title: "当前页+1", icon: UIImage(systemName: "plus.forwardslash.minus"), handler: { [weak self] browser, _ in
                let next = min(browser.currentIndex + 1, self?.items.count ?? 0 - 1)
                browser.currentIndex = next
                self?.log("currentIndex 写为 \(next)")
            }))
            actions.append(WYPhotoBrowserAction(title: "数据+1并刷新", icon: UIImage(systemName: "plus.circle"), handler: { [weak self] browser, _ in
                guard let self = self else { return }
                var extra = WYPhotoBrowserItem()
                extra.placeholder = UIImage(named: self.localPhotoNames.randomElement() ?? "樱花")
                extra.identifier = "appended_\(self.items.count)"
                self.items.append(extra)
                browser.reloadData()
                self.log("数据+1 现在共\(self.items.count)项")
            }))
            actions.append(WYPhotoBrowserAction(title: "关闭浏览器", icon: UIImage(systemName: "xmark"), handler: { browser, _ in
                browser.dismissBrowser(animated: true)
            }))
        }
        configuration.customActions = actions
        configuration.appearance = buildAppearance()
        return configuration
    }

    /// 按主题档位组装外观(深蓝与浅色档覆盖大部分外观字段)
    func buildAppearance() -> WYPhotoBrowserAppearance {
        var appearance = WYPhotoBrowserAppearance()
        if settings.theme == 1 {
            appearance.backgroundColor = UIColor(red: 0.04, green: 0.1, blue: 0.24, alpha: 1)
            appearance.pageIndicatorTextColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
            appearance.pageIndicatorDotColor = UIColor(white: 1, alpha: 0.25)
            appearance.pageIndicatorCurrentDotColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
            appearance.playButtonBackgroundColor = UIColor(red: 0.1, green: 0.35, blue: 0.9, alpha: 0.75)
            appearance.livePhotoBadgeBackgroundColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 0.85)
            appearance.livePhotoBadgeTextColor = UIColor(red: 0.04, green: 0.1, blue: 0.24, alpha: 1)
            appearance.progressRingColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
            appearance.progressRingTrackColor = UIColor(white: 1, alpha: 0.2)
            appearance.retryButtonBackgroundColor = UIColor(red: 0.75, green: 0.15, blue: 0.15, alpha: 0.9)
            appearance.originalButtonBackgroundColor = UIColor(red: 0.1, green: 0.35, blue: 0.9, alpha: 0.85)
            appearance.menuBackgroundColor = UIColor(red: 0.06, green: 0.16, blue: 0.36, alpha: 0.95)
            appearance.menuTextColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
            appearance.menuHighlightBackgroundColor = UIColor(white: 1, alpha: 0.18)
            appearance.menuCornerRadius = 20
        } else if settings.theme == 2 {
            appearance.backgroundColor = UIColor(white: 0.92, alpha: 1)
            appearance.pageIndicatorTextColor = .darkGray
            appearance.playButtonIcon = UIImage(systemName: "arrow.up.right.and.arrow.down.left.square.fill")
            appearance.playButtonBackgroundColor = UIColor(white: 0.2, alpha: 0.5)
            appearance.menuBackgroundColor = UIColor(white: 1, alpha: 0.95)
            appearance.menuTextColor = .darkGray
            appearance.menuHighlightBackgroundColor = UIColor(white: 0, alpha: 0.06)
        }
        return appearance
    }

    /// 构造混排浏览项(本地Resource照片6张、两级文件、GIF动图、本地视频封面2张、本地LivePhoto对、网络图2张、网络视频封面、网络LivePhoto对、失败地址)
    func buildItems() -> [WYPhotoBrowserItem] {
        var result: [WYPhotoBrowserItem] = []
        for (index, photoName) in localPhotoNames.enumerated() {
            var item = WYPhotoBrowserItem()
            item.placeholder = UIImage(named: photoName)
            item.identifier = "local_\(index)"
            result.append(item)
        }

        var twoLevelItem = WYPhotoBrowserItem()
        twoLevelItem.thumbnailPath = resourcePath("沙滩上的花", "png")
        twoLevelItem.originalPath = resourcePath("夕阳下的花", "png")
        twoLevelItem.identifier = "two_level_local"
        result.append(twoLevelItem)

        var gifItem = WYPhotoBrowserItem()
        gifItem.originalPath = resourcePath("关注主播", "gif")
        gifItem.identifier = "local_gif"
        result.append(gifItem)

        for videoName in ["乌篷转桨晃一晃，春风牵衣过平江", "树屋"] {
            let videoPath = resourcePath(videoName, "mp4")
            var videoItem = WYPhotoBrowserItem()
            videoItem.mediaType = .video
            videoItem.identifier = "play:\(videoPath)"
            result.append(videoItem)
        }

        var localLiveItem = WYPhotoBrowserItem()
        localLiveItem.mediaType = .livePhoto
        localLiveItem.placeholder = UIImage(contentsOfFile: resourcePath("棕榈步道", "heic"))
        localLiveItem.livePhotoStillURL = URL(fileURLWithPath: resourcePath("棕榈步道", "heic"))
        localLiveItem.livePhotoVideoURL = URL(fileURLWithPath: resourcePath("棕榈步道", "mov"))
        localLiveItem.identifier = "live_local"
        result.append(localLiveItem)

        for index in 0..<2 {
            var networkItem = WYPhotoBrowserItem()
            networkItem.thumbnailURL = URL(string: "https://picsum.photos/seed/wybrowser\(index)/400/500")
            networkItem.originalURL = URL(string: "https://picsum.photos/seed/wybrowser\(index)/1200/1500")
            networkItem.originalFileSize = 2_411_724
            networkItem.identifier = "remote_\(index)"
            result.append(networkItem)
        }

        var networkVideoItem = WYPhotoBrowserItem()
        networkVideoItem.thumbnailURL = URL(string: "https://picsum.photos/seed/wyvideo/400/500")
        networkVideoItem.mediaType = .video
        networkVideoItem.identifier = "play:https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4"
        result.append(networkVideoItem)

        var networkLiveItem = WYPhotoBrowserItem()
        networkLiveItem.mediaType = .livePhoto
        networkLiveItem.livePhotoStillURL = URL(string: "https://raw.githubusercontent.com/NightMean/MotionPhotoSamples/main/Apple%20Live%20Photo/Apple%20iPhone%2015%20-%20photo.HEIC")
        networkLiveItem.livePhotoVideoURL = URL(string: "https://raw.githubusercontent.com/NightMean/MotionPhotoSamples/main/Apple%20Live%20Photo/Apple%20iPhone%2015%20-%20video.MOV")
        networkLiveItem.identifier = "live_remote"
        result.append(networkLiveItem)

        var invalidItem = WYPhotoBrowserItem()
        invalidItem.thumbnailURL = URL(string: "https://invalid.wybasiskit.test/none.jpg")
        invalidItem.identifier = "invalid_url"
        result.append(invalidItem)

        var secondLiveItem = WYPhotoBrowserItem()
        secondLiveItem.mediaType = .livePhoto
        secondLiveItem.placeholder = UIImage(contentsOfFile: resourcePath("水中游鸟", "heic"))
        secondLiveItem.livePhotoStillURL = URL(fileURLWithPath: resourcePath("水中游鸟", "heic"))
        secondLiveItem.livePhotoVideoURL = URL(fileURLWithPath: resourcePath("水中游鸟", "mov"))
        secondLiveItem.identifier = "live_local_2"
        result.append(secondLiveItem)
        return result
    }

    /// 取Resource里的文件全路径(主包资源)
    func resourcePath(_ name: String, _ ext: String) -> String {
        return Bundle.main.path(forResource: name, ofType: ext) ?? ""
    }

    /// 抽视频首帧做封面(本地视频封面格用)
    func videoPoster(path: String, completion: @escaping (UIImage?) -> Void) {
        guard path.isEmpty == false else { completion(nil); return }
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTime(seconds: 0.5, preferredTimescale: 600))]) { _, frame, _, _, _ in
            let image = frame.map { UIImage(cgImage: $0) }
            DispatchQueue.main.async { completion(image) }
        }
    }

    /// 写一条事件日志(代理回调与菜单动作都走这里)
    func log(_ text: String) {
        logLabel.text = text
    }

    // UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.accessibilityIdentifier = "WYPhotoGrid." + String(indexPath.item)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let item = items[indexPath.item]

        let placeholderView = UIView(frame: cell.contentView.bounds)
        placeholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholderView.backgroundColor = UIColor(white: 0.92, alpha: 1)
        let textLabel = UILabel(frame: placeholderView.bounds)
        textLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textLabel.textAlignment = .center
        textLabel.font = .systemFont(ofSize: 11)
        textLabel.textColor = .darkGray
        textLabel.numberOfLines = 2
        textLabel.text = placeholderText(for: item, index: indexPath.item)
        placeholderView.addSubview(textLabel)
        cell.contentView.addSubview(placeholderView)

        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.image = item.placeholder
        if item.thumbnailPath != nil {
            imageView.image = UIImage(contentsOfFile: item.thumbnailPath ?? "")
        }
        cell.contentView.addSubview(imageView)

        if item.mediaType == .video {
            let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
            playIcon.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
            playIcon.center = cell.contentView.center
            playIcon.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            playIcon.tintColor = .white
            cell.contentView.addSubview(playIcon)
        }
        if item.mediaType == .livePhoto {
            let liveBadge = UILabel(frame: CGRect(x: 4, y: 4, width: 34, height: 14))
            liveBadge.text = "Live"
            liveBadge.font = .systemFont(ofSize: 9, weight: .semibold)
            liveBadge.textColor = .white
            liveBadge.textAlignment = .center
            liveBadge.backgroundColor = UIColor(white: 0, alpha: 0.4)
            liveBadge.layer.cornerRadius = 7
            liveBadge.layer.masksToBounds = true
            cell.contentView.addSubview(liveBadge)
        }
        return cell
    }

    /// 缩略图墙占位文案(网络与失败格在图未到时显示)
    func placeholderText(for item: WYPhotoBrowserItem, index: Int) -> String {
        let identifier = item.identifier ?? ""
        if identifier == "invalid_url" {
            return "失败重试"
        }
        if identifier == "remote_0" {
            return "网络图1"
        }
        if identifier == "remote_1" {
            return "网络图2"
        }
        if identifier == "local_gif" {
            return "GIF动图"
        }
        if identifier.hasPrefix("play:http") {
            return "网络视频"
        }
        if identifier.hasPrefix("play:") {
            return "本地视频"
        }
        if identifier == "live_remote" {
            return "网络Live"
        }
        return ""
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let edge = (view.bounds.width - 8 - 8) / 3
        return CGSize(width: edge, height: edge)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log("进入第\(indexPath.item + 1)格 [\(items[indexPath.item].identifier ?? "")]")
        WYPhotoBrowser.show(from: self, index: indexPath.item, dataSource: self, configuration: buildConfiguration(), delegate: self)
    }

    // WYPhotoBrowserDataSource

    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int {
        return items.count
    }

    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any {
        return items[index]
    }

    // WYPhotoBrowserDelegate

    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, sourceViewForItemAt index: Int) -> UIView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell?.contentView.subviews.first(where: { $0 is UIImageView })
    }

    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int) {
        log("翻页落定 第\(index + 1)页 共\(items.count)页")
    }

    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didLongPressItemAt index: Int) {
        log("长按 第\(index + 1)页(菜单已弹出)")
    }

    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int) {
        guard index >= 0, index < items.count else { return }
        let identifier = items[index].identifier ?? ""
        guard identifier.hasPrefix("play:"), let playURL = URL(string: String(identifier.dropFirst(5))) else { return }
        log("播放回调 第\(index + 1)页(\(identifier.hasPrefix("play:http") ? "网络" : "本地")视频，已接管播放)")
        let playerController = WYTestBrowserPlayerController(playURL: playURL)
        playerController.modalPresentationStyle = .overFullScreen
        present(playerController, animated: true)
    }

    func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didFinishLoadingOriginalItemAt index: Int) {
        log("原图加载完成 第\(index + 1)页")
    }

    func wy_photoBrowserDidDismiss(_ photoBrowser: WYPhotoBrowser) {
        log("浏览器已关闭")
    }
}

/// 播放接管演示页(播放回调里接管播放的示例，内嵌WYMediaPlayer播本地或网络视频，单击退出)
class WYTestBrowserPlayerController: UIViewController {

    /// 播放地址(本地文件地址或网络地址)
    let playURL: URL

    /// 播放器(库内组件，本地与网络视频都支持)
    var player: WYMediaPlayer?

    /**
     * 播放演示页初始化
     * - Parameters:
     *   - playURL: 视频地址(本地file地址或网络地址)
     */
    init(playURL: URL) {
        self.playURL = playURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let player = WYMediaPlayer()
        player.contentMode = .scaleAspectFit
        player.frame = view.bounds
        player.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(player)
        player.play(with: playURL.absoluteString)
        self.player = player

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        view.addGestureRecognizer(tap)
    }

    /// 单击退出播放
    @objc func closeTapped() {
        player?.stop()
        dismiss(animated: true)
    }
}

/// 浏览器配置页(选项类点行弹选项单，开关类直接拨动，保存后回调新配置)
class WYTestPhotoBrowserSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    /// 编辑中的配置(保存时回调给主页面)
    var settings: PhotoBrowserSettingsModel = PhotoBrowserSettingsModel()

    /// 保存回调(取消不回调)
    var onSettingsChanged: ((PhotoBrowserSettingsModel) -> Void)?

    /// 配置行描述(取值文案、选项与写入闭包都走weak self改编辑中的配置)
    struct SettingsRow {
        let title: String
        let value: () -> String
        let options: [String]
        let apply: (Int) -> Void
        let isSwitch: Bool
        let switchValue: () -> Bool
        let switchApply: (Bool) -> Void
    }

    /// 选项行便捷构造(点行弹选项单)
    func optionRow(_ title: String, options: [String], currentIndex: @escaping () -> Int, apply: @escaping (Int) -> Void) -> SettingsRow {
        return SettingsRow(title: title, value: { options[currentIndex()] }, options: options, apply: apply, isSwitch: false, switchValue: { false }, switchApply: { _ in })
    }

    /// 开关行便捷构造(行上直接拨动)
    func switchRow(_ title: String, value: @escaping () -> Bool, apply: @escaping (Bool) -> Void) -> SettingsRow {
        return SettingsRow(title: title, value: { "" }, options: [], apply: { _ in }, isSwitch: true, switchValue: value, switchApply: apply)
    }

    /// 分组配置行
    var sectionRows: [(String, [SettingsRow])] = []

    var tableView: UITableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "浏览器配置"
        if #available(iOS 27.0, *) {
            navigationItem.navigationBarMinimization.minimizationBehavior = .never
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelSettings))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveSettings))

        buildRows()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 组装配置行(选项行为点行弹选项单，开关行为行上拨动开关)
    func buildRows() {
        sectionRows = [
            ("浏览与转场", [
                optionRow("翻页方向", options: ["横向左右翻页", "纵向上下翻页"], currentIndex: { [weak self] in self?.settings.scrollDirection ?? 0 }, apply: { [weak self] index in self?.settings.scrollDirection = index }),
                optionRow("转场样式", options: ["缩放(从缩略图飞入)", "渐隐"], currentIndex: { [weak self] in self?.settings.transitionStyle ?? 0 }, apply: { [weak self] index in self?.settings.transitionStyle = index }),
                optionRow("同屏布局", options: ["整页(一次一张)", "多页同屏(一次多张)"], currentIndex: { [weak self] in self?.settings.layoutStyle ?? 0 }, apply: { [weak self] index in self?.settings.layoutStyle = index }),
                optionRow("两侧露出宽度", options: ["常规(40)", "宽(60)"], currentIndex: { [weak self] in self?.settings.revealWidthLevel ?? 0 }, apply: { [weak self] index in self?.settings.revealWidthLevel = index }),
                optionRow("页间距", options: ["窄(10)", "宽(20)"], currentIndex: { [weak self] in self?.settings.multiPageSpacingLevel ?? 0 }, apply: { [weak self] index in self?.settings.multiPageSpacingLevel = index }),
                optionRow("滑动过渡特效", options: ["无", "等比缩小", "缩小并压暗", "横向压缩", "向旁堆叠", "相邻页重叠"], currentIndex: { [weak self] in self?.settings.transformStyle ?? 0 }, apply: { [weak self] index in self?.settings.transformStyle = index }),
            ]),
            ("页码与原图", [
                optionRow("页码样式", options: ["文本页码", "圆点页码", "无页码"], currentIndex: { [weak self] in self?.settings.pageIndicatorStyle ?? 0 }, apply: { [weak self] index in self?.settings.pageIndicatorStyle = index }),
                optionRow("原图加载", options: ["手动(查看原图按钮)", "自动加载"], currentIndex: { [weak self] in self?.settings.originalLoadStyle ?? 0 }, apply: { [weak self] index in self?.settings.originalLoadStyle = index }),
            ]),
            ("缩放与手势", [
                optionRow("双击放大倍数", options: ["2倍", "2.5倍", "3倍"], currentIndex: { [weak self] in self?.settings.doubleTapZoomScaleLevel ?? 0 }, apply: { [weak self] index in self?.settings.doubleTapZoomScaleLevel = index }),
                optionRow("捏合上限倍数", options: ["3倍", "4倍", "5倍"], currentIndex: { [weak self] in self?.settings.maxZoomScaleLevel ?? 0 }, apply: { [weak self] index in self?.settings.maxZoomScaleLevel = index }),
                optionRow("拖拽关闭阈值", options: ["常规110点", "轻拖60点", "重拖160点"], currentIndex: { [weak self] in self?.settings.dragDismissThresholdLevel ?? 0 }, apply: { [weak self] index in self?.settings.dragDismissThresholdLevel = index }),
                switchRow("允许单击关闭", value: { [weak self] in self?.settings.allowsTapDismiss ?? true }, apply: { [weak self] in self?.settings.allowsTapDismiss = $0 }),
                switchRow("允许拖拽关闭", value: { [weak self] in self?.settings.allowsDragDismiss ?? true }, apply: { [weak self] in self?.settings.allowsDragDismiss = $0 }),
            ]),
            ("菜单与预取", [
                optionRow("相邻页预加载数量", options: ["关闭", "前后各1页", "前后各2页"], currentIndex: { [weak self] in self?.settings.prefetchCount ?? 1 }, apply: { [weak self] index in self?.settings.prefetchCount = index }),
                switchRow("长按菜单带保存动作", value: { [weak self] in self?.settings.showsSaveAction ?? true }, apply: { [weak self] in self?.settings.showsSaveAction = $0 }),
                switchRow("长按菜单带方法演示", value: { [weak self] in self?.settings.showsMethodActions ?? true }, apply: { [weak self] in self?.settings.showsMethodActions = $0 }),
            ]),
            ("轮播", [
                switchRow("循环翻页(末页无缝回首页)", value: { [weak self] in self?.settings.allowsLoopScrolling ?? false }, apply: { [weak self] in self?.settings.allowsLoopScrolling = $0 }),
                optionRow("自动轮播间隔", options: ["关闭", "2秒", "4秒"], currentIndex: { [weak self] in self?.settings.autoCarouselLevel ?? 0 }, apply: { [weak self] in self?.settings.autoCarouselLevel = $0 }),
            ]),
            ("外观主题", [
                optionRow("主题", options: ["默认黑", "深蓝定制", "浅色背景"], currentIndex: { [weak self] in self?.settings.theme ?? 0 }, apply: { [weak self] index in self?.settings.theme = index }),
            ]),
        ]
    }

    /// 取消配置(不回调)
    @objc func cancelSettings() {
        dismiss(animated: true)
    }

    /// 保存配置(回调新配置)
    @objc func saveSettings() {
        onSettingsChanged?(settings)
        dismiss(animated: true)
    }

    /// 点选项行弹选项单(选完刷新该行文案)
    func presentOptions(for indexPath: IndexPath) {
        let row = sectionRows[indexPath.section].1[indexPath.row]
        let alert = UIAlertController(title: row.title, message: nil, preferredStyle: .actionSheet)
        for (optionIndex, option) in row.options.enumerated() {
            alert.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                guard let self = self else { return }
                row.apply(optionIndex)
                self.tableView.reloadRows(at: [indexPath], with: .none)
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        present(alert, animated: true)
    }

    // UITableViewDataSource, UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionRows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionRows[section].0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionRows[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        }
        let row = sectionRows[indexPath.section].1[indexPath.row]
        cell!.textLabel?.text = row.title
        cell!.textLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels))
        if row.isSwitch {
            cell!.detailTextLabel?.text = nil
            let switchControl = UISwitch()
            switchControl.isOn = row.switchValue()
            switchControl.tag = indexPath.section * 100 + indexPath.row
            switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell!.accessoryView = switchControl
            cell!.selectionStyle = .none
        } else {
            cell!.accessoryView = nil
            cell!.detailTextLabel?.text = row.value()
            cell!.detailTextLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(12, WYBasisKitConfig.defaultScreenPixels))
            cell!.detailTextLabel?.textColor = .gray
            cell!.selectionStyle = .default
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sectionRows[indexPath.section].1[indexPath.row]
        if row.isSwitch == false {
            presentOptions(for: indexPath)
        }
    }

    /// 开关行拨动(直接写入编辑中的配置)
    @objc func switchChanged(_ sender: UISwitch) {
        let section = sender.tag / 100
        let row = sender.tag % 100
        guard sectionRows.indices.contains(section), sectionRows[section].1.indices.contains(row) else { return }
        let settingsRow = sectionRows[section].1[row]
        settingsRow.switchApply(sender.isOn)
    }
}
