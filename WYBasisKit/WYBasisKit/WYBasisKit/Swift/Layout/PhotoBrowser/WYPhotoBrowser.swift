//
//  WYPhotoBrowser.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

import UIKit
import Photos
import PhotosUI
import Kingfisher

/// 浏览项类型(视频项只浏览封面图，点击播放按钮的事件抛给接入方自行处理)
@objc public enum WYPhotoBrowserMediaType: Int {
    /// 普通图片
    case photo = 0
    /// 视频封面(浏览封面图，页中央显示播放按钮，点击播放按钮回调代理方法)
    case video = 1
    /// LivePhoto(先显静态图，素材合成好后长按播放，左上角显示Live角标)
    case livePhoto = 2
}

/// 同屏布局样式(整页一次一张铺满，多页一次看到多张一起滑动)
@objc public enum WYPhotoBrowserLayoutStyle: Int {
    /// 整页浏览(一次一张铺满视口)
    case fullPage = 0
    /// 多页同屏(当前页居中，两侧露出相邻页边缘，多张一起联动滑动)
    case multiPage = 1
}

/// 多页同屏布局下非当前页的过渡特效(滑动过程中随离中心距离变化)
@objc public enum WYPhotoBrowserTransformStyle: Int {
    /// 无特效
    case none = 0
    /// 等比缩小(离中心越远越小)
    case scale = 1
    /// 缩小并压暗(离中心越远越小越暗)
    case depth = 2
    /// 横向压缩(离中心越远横向越窄)
    case accordion = 3
    /// 向旁堆叠(相邻页向一侧平移缩小堆在一起)
    case stack = 4
    /// 相邻页重叠(滑动中相邻页盖到当前页边缘上)
    case overlap = 5
}

/// 翻页方向(横向为聊天与相册常用样式，纵向为信息流上下滑样式)
@objc public enum WYPhotoBrowserScrollDirection: Int {
    /// 横向左右翻页
    case horizontal = 0
    /// 纵向上下翻页(该方向下不支持拖拽关闭手势，上下滑动用于翻页)
    case vertical = 1
}

/// 进出页转场样式(缩放样式需要代理提供来源视图，取不到来源视图时自动降级为渐隐)
@objc public enum WYPhotoBrowserTransitionStyle: Int {
    /// 从来源视图位置放大进入，退出时缩回来源视图位置
    case zoom = 0
    /// 整页渐隐进入与退出
    case fade = 1
}

/// 页码指示样式(仅一页时所有样式都不显示)
@objc public enum WYPhotoBrowserPageIndicatorStyle: Int {
    /// 不显示页码
    case none = 0
    /// 文本页码(底部居中显示3/9样式)
    case text = 1
    /// 圆点页码(底部居中显示系统圆点)
    case dots = 2
}

/// 原图加载方式(浏览项同时提供缩略图与原图时生效)
@objc public enum WYPhotoBrowserOriginalLoadStyle: Int {
    /// 显示完缩略图后自动加载原图
    case automatic = 0
    /// 手动加载(底部显示查看原图按钮，点击后才开始加载)
    case manual = 1
}

/// 长按菜单动作(自定义动作追加在内置保存动作前面，按传入顺序展示)
@objcMembers public class WYPhotoBrowserAction: NSObject {

    /// 动作标题(菜单里显示的文字)
    public var title: String

    /// 动作图标(菜单里显示在标题左侧的图标，nil时只显示标题)
    public var icon: UIImage?

    /// 动作回调(点菜单项时回调，参数为回调来源浏览器与当前页下标)
    public var handler: ((_ browser: WYPhotoBrowser, _ index: Int) -> Void)?

    /**
     * 菜单动作初始化
     *   @param actionTitle 动作标题(菜单里显示的文字)
     *   @param actionIcon 动作图标(nil时菜单里只显示标题)
     *   @param handler 动作回调(点菜单项时回调，参数为回调来源浏览器与当前页下标)
     */
    public init(title actionTitle: String, icon actionIcon: UIImage? = nil, handler: ((_ browser: WYPhotoBrowser, _ index: Int) -> Void)? = nil) {
        self.title = actionTitle
        self.icon = actionIcon
        self.handler = handler
        super.init()
    }
}

/// 浏览项(一个页面对应一个浏览项，图片内容按缩略占位图、缩略图、原图的顺序分级显示)
public struct WYPhotoBrowserItem {

    /// 项类型(视频项只浏览封面图，LivePhoto项先显静态图再合成LivePhoto)
    public var mediaType: WYPhotoBrowserMediaType = .photo

    /// 缩略占位图(进入页面立即可见的本地小图，通常传消息列表里已显示的缩略图)
    public var placeholder: UIImage?

    /// 缩略图本地文件路径(有本地缩略图时先显示它，绝对路径沙盒路径均可)
    public var thumbnailPath: String?

    /// 缩略图网络地址(没有本地缩略图时从该地址下载)
    public var thumbnailURL: URL?

    /// 原图本地文件路径(有本地原图时直接显示，不再走网络加载)
    public var originalPath: String?

    /// 原图网络地址(手动加载方式下显示查看原图按钮，点击后从该地址下载)
    public var originalURL: URL?

    /// 原图字节数(手动加载方式下按钮标题显示大小用，0表示大小未知不显示大小)
    public var originalFileSize: Int64 = 0

    /// 现成的LivePhoto对象(有它时直接显示播放，优先级最高)
    public var livePhoto: PHLivePhoto?

    /// 相册素材(从相册Asset生成LivePhoto，livePhoto属性为nil时生效)
    public var livePhotoAsset: PHAsset?

    /// LivePhoto静态图地址(LivePhoto的静图素材，本地file地址或网络地址均可，与前两个属性互斥生效)
    public var livePhotoStillURL: URL?

    /// LivePhoto视频地址(LivePhoto的视频素材，本地file地址或网络地址均可，需要与livePhotoStillURL成对传入)
    public var livePhotoVideoURL: URL?

    /// 接入方自定义标记(浏览器不使用，原样带回代理回调，通常存消息id方便对回业务数据)
    public var identifier: String?

    /**
     * 浏览项初始化(全部属性都有默认值，初始化后按需赋值)
     */
    public init() {
    }

    /**
     * 图片浏览项便捷初始化
     *   @param localImage 本地图片(只有一张本地图时用它一步到位)
     */
    public init(localImage: UIImage) {
        placeholder = localImage
    }

    /**
     * 网络图片浏览项便捷初始化
     *   @param remoteURL 图片网络地址
     *   @param localThumbnail 本地缩略图(可先显示它再下载大图，nil时显示加载进度)
     */
    public init(remoteURL: URL, localThumbnail: UIImage? = nil) {
        placeholder = localThumbnail
        originalURL = remoteURL
    }
}

/// 浏览项转换协议(把实现它的对象转成WYPhotoBrowserItem)
public protocol WYPhotoBrowserItemConvertible: AnyObject {
    /**
     * 转成结构体浏览项
     * @return 转换出的WYPhotoBrowserItem
     */
    func toItem() -> WYPhotoBrowserItem
}

/// 浏览器界面外观配置(全部属性都有默认值，按需覆盖，不设置时与默认外观一致)
public struct WYPhotoBrowserAppearance {

    /// 浏览页背景色(进出页转场时背景透明度会跟随动画渐变)
    public var backgroundColor: UIColor = .black

    /// 文本页码文字颜色
    public var pageIndicatorTextColor: UIColor = UIColor(white: 1, alpha: 0.9)

    /// 文本页码字号(设计值，按基准屏换算)
    public var pageIndicatorFontSize: CGFloat = 14

    /// 圆点页码未选中圆点颜色
    public var pageIndicatorDotColor: UIColor = UIColor(white: 1, alpha: 0.35)

    /// 圆点页码当前页圆点颜色
    public var pageIndicatorCurrentDotColor: UIColor = .white

    /// 视频封面播放按钮图标(nil用内置播放三角图标)
    public var playButtonIcon: UIImage?

    /// 视频封面播放按钮图标颜色(内置图标生效，自定义图标原样显示)
    public var playButtonIconColor: UIColor = .white

    /// 视频封面播放按钮底色(圆形按钮的底)
    public var playButtonBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.4)

    /// LivePhoto角标底色(左上角Live胶囊的底)
    public var livePhotoBadgeBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.35)

    /// LivePhoto角标文字颜色(播放中角标会临时压暗)
    public var livePhotoBadgeTextColor: UIColor = .white

    /// LivePhoto角标字号(设计值，按基准屏换算)
    public var livePhotoBadgeFontSize: CGFloat = 11

    /// 加载进度环颜色(没有可显示的图片时屏幕中央的环形进度)
    public var progressRingColor: UIColor = .white

    /// 加载进度环轨道颜色(进度环的底环)
    public var progressRingTrackColor: UIColor = UIColor(white: 1, alpha: 0.3)

    /// 加载进度百分比文字颜色(进度环中央的百分数)
    public var progressLabelColor: UIColor = .white

    /// 加载进度百分比字号(设计值，按基准屏换算)
    public var progressLabelFontSize: CGFloat = 13

    /// 加载失败重试胶囊底色(下载失败时屏幕中央显示的点击重试胶囊)
    public var retryButtonBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.55)

    /// 加载失败重试胶囊文字颜色
    public var retryButtonTextColor: UIColor = .white

    /// 加载失败重试胶囊字号(设计值，按基准屏换算)
    public var retryButtonFontSize: CGFloat = 14

    /// 查看原图按钮底色(底部居中的查看原图与原图进度按钮)
    public var originalButtonBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.45)

    /// 查看原图按钮文字颜色
    public var originalButtonTextColor: UIColor = .white

    /// 查看原图按钮字号(设计值，按基准屏换算)
    public var originalButtonFontSize: CGFloat = 14

    /// 长按菜单底色(深色圆角浮层)
    public var menuBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.82)

    /// 长按菜单文字颜色
    public var menuTextColor: UIColor = .white

    /// 长按菜单字号(设计值，按基准屏换算)
    public var menuFontSize: CGFloat = 15

    /// 长按菜单动作按住高亮色(手指按住某行动作的背景色)
    public var menuHighlightBackgroundColor: UIColor = UIColor(white: 1, alpha: 0.12)

    /// 长按菜单圆角(设计值，按基准屏换算)
    public var menuCornerRadius: CGFloat = 12

    /// 保存结果提示窗口配置(nil用Activity全局默认样式，保存成功或失败时借WYActivity显示提示)
    public var toastConfig: WYMessageInfoConfig?

    public init() {}
}

/// 浏览器行为配置(全部属性都有默认值，按需覆盖，不设置时与默认行为一致)
public struct WYPhotoBrowserConfiguration {

    /// 翻页方向(默认横向左右翻页)
    public var scrollDirection: WYPhotoBrowserScrollDirection = .horizontal

    /// 同屏布局样式(默认整页一次一张，多页同屏时一次看到多张一起滑动)
    public var layoutStyle: WYPhotoBrowserLayoutStyle = .fullPage

    /// 多页同屏时两侧露出相邻页的宽度(设计值，按基准屏换算，仅layoutStyle为multiPage时生效)
    public var multiPageRevealWidth: CGFloat = 40

    /// 多页同屏时页与页的间距(设计值，按基准屏换算，仅layoutStyle为multiPage时生效)
    public var multiPageSpacing: CGFloat = 10

    /// 多页同屏时非当前页的过渡特效(仅layoutStyle为multiPage时生效)
    public var transformStyle: WYPhotoBrowserTransformStyle = .none

    /// 进出页转场样式(默认从来源视图位置缩放，取不到来源视图时自动降级为渐隐)
    public var transitionStyle: WYPhotoBrowserTransitionStyle = .zoom

    /// 页码指示样式(默认文本页码3/9样式，仅一页时所有样式都不显示)
    public var pageIndicatorStyle: WYPhotoBrowserPageIndicatorStyle = .text

    /// 原图加载方式(默认手动点击查看原图按钮加载，浏览项提供原图地址时生效)
    public var originalLoadStyle: WYPhotoBrowserOriginalLoadStyle = .manual

    /// 双击放大倍数(双击图片时放大的目标倍数，相对适配大小的倍数)
    public var doubleTapZoomScale: CGFloat = 2

    /// 捏合最大缩放倍数(相对适配大小的倍数)
    public var maxZoomScale: CGFloat = 3

    /// 单击是否关闭浏览器(单击图片或空白处时关闭，true关闭)
    public var allowsTapDismiss: Bool = true

    /// 拖拽是否关闭浏览器(图片缩放为1倍时按住图片拖动，松手超过阈值关闭，仅横向翻页方向生效)
    public var allowsDragDismiss: Bool = true

    /// 拖拽关闭的距离阈值(单位为点，松手时拖拽距离超过该值即关闭)
    public var dragDismissThreshold: CGFloat = 110

    /// 长按菜单是否显示内置保存动作(保存当前页图片到系统相册，false时只显示自定义动作)
    public var showsSaveAction: Bool = true

    /// 自定义长按菜单动作(按传入顺序展示在内置保存动作前面)
    public var customActions: [WYPhotoBrowserAction] = []

    /// 相邻页预加载数量(翻页落定后预下载前后各几页的图片，0不预加载)
    public var prefetchCount: Int = 1

    /// 是否循环翻页(true时滑到末页继续滑无缝回到首页，仅多于一张时生效)
    public var allowsLoopScrolling: Bool = false

    /// 自动轮播间隔秒数(大于0时每隔该秒数自动翻到下一张，末页回绕到首页，需要多于一张且allowsLoopScrolling为true才生效，手动拖动后重新计时)
    public var autoCarouselInterval: TimeInterval = 0

    /// 外观配置
    public var appearance: WYPhotoBrowserAppearance = WYPhotoBrowserAppearance()

    public init() {}
}

/// 浏览器数据源(浏览项数量与内容都从数据源取，内容变化后调reloadData刷新)
@objc public protocol WYPhotoBrowserDataSource: AnyObject {

    /**
     * 浏览项数量
     * @param photoBrowser 回调来源浏览器
     * @return 浏览项数量
     */
    @objc(numberOfItemsInPhotoBrowser:)
    func numberOfItems(in photoBrowser: WYPhotoBrowser) -> Int

    /**
     * 指定下标的浏览项
     * @param photoBrowser 回调来源浏览器
     * @param index 浏览项下标
     * @return 该页要显示的浏览项(返回WYPhotoBrowserItem或实现toItem()的类型均可，内部自动归一)
     */
    @objc(photoBrowser:itemAtIndex:)
    func photoBrowser(_ photoBrowser: WYPhotoBrowser, itemAt index: Int) -> Any
}

/// 浏览器代理(全部方法可选实现)
@objc public protocol WYPhotoBrowserDelegate: AnyObject {

    /**
     * 缩放转场的来源视图(进出页转场样式为zoom时取该视图的屏幕位置做缩放动画，返回nil或视图不在窗口上时该页降级为渐隐)
     * @param photoBrowser 回调来源浏览器
     * @param index 浏览项下标
     * @return 该页在来源界面里的缩略图视图
     */
    @objc(wy_photoBrowser:sourceViewForItemAt:)
    optional func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, sourceViewForItemAt index: Int) -> UIView?

    /**
     * 翻页落定(翻页或程序化跳页后当前页变化时回调)
     * @param photoBrowser 回调来源浏览器
     * @param index 落定页的下标
     */
    @objc(wy_photoBrowser:didShowItemAt:)
    optional func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didShowItemAt index: Int)

    /**
     * 长按图片(LivePhoto项长按用于播放不回调这里，其余项长按弹出菜单的同时回调这里)
     * @param photoBrowser 回调来源浏览器
     * @param index 长按页的下标
     */
    @objc(wy_photoBrowser:didLongPressItemAt:)
    optional func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didLongPressItemAt index: Int)

    /**
     * 点击视频封面的播放按钮(浏览器不播放视频，接入方在回调里自行处理，通常关闭浏览器并弹出视频播放器)
     * @param photoBrowser 回调来源浏览器
     * @param index 视频页的下标
     */
    @objc(wy_photoBrowser:didTapPlayVideoItemAt:)
    optional func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didTapPlayVideoItemAt index: Int)

    /**
     * 原图加载完成(原图显示出来时回调，手动与自动方式都回调)
     * @param photoBrowser 回调来源浏览器
     * @param index 原图页的下标
     */
    @objc(wy_photoBrowser:didFinishLoadingOriginalItemAt:)
    optional func wy_photoBrowser(_ photoBrowser: WYPhotoBrowser, didFinishLoadingOriginalItemAt index: Int)

    /**
     * 浏览器已关闭(点击关闭、拖拽关闭、调用dismiss关闭都会回调，此时动画已结束)
     * @param photoBrowser 回调来源浏览器
     */
    @objc(wy_photoBrowserDidDismiss:)
    optional func wy_photoBrowserDidDismiss(_ photoBrowser: WYPhotoBrowser)
}

/**
 * 图片浏览器(全屏大图浏览页，支持缩略图与原图分级加载、双击与捏合缩放、缩放转场、
 * 拖拽关闭、长按菜单、LivePhoto长按播放、视频封面点击播放回调，网络图片的下载与缓存依赖Kingfisher)
 * 用法示例：
 * let browser = WYPhotoBrowser.show(from: viewController, index: 0, dataSource: self)
 */
public class WYPhotoBrowser: UIViewController {

    /// 数据源(浏览项数量与内容，Swift返回结构体浏览项、OC返回WYPhotoBrowserItemObjC都行)
    public weak var dataSource: WYPhotoBrowserDataSource?

    /// 代理(转场来源与各类事件回调，全部方法可选)
    public weak var browserDelegate: WYPhotoBrowserDelegate?

    /// 行为与外观配置(弹出前设置生效，弹出后修改不保证生效)
    public var configuration: WYPhotoBrowserConfiguration

    /// 当前页下标(翻页与跳页后更新，写入会立即跳到该页不带动画)
    @objc public var currentIndex: Int {
        get {
            return internalCurrentIndex
        }
        set {
            scrollToItem(at: newValue, animated: false)
        }
    }

    /**
     * 便利弹出入口(一行代码从指定控制器弹出浏览器并返回浏览器实例，弹出后可继续持有它调用reloadData等方法)
     *   @param viewController 从哪个控制器弹出(浏览器全屏盖在它上面)
     *   @param index 进入时显示的页下标
     *   @param dataSource 数据源(浏览项数量与内容)
     *   @param configuration 行为与外观配置(不传用默认配置)
     *   @param delegate 代理(不传无事件回调)
     * @return 弹出的浏览器实例
     */
    @discardableResult
    public static func show(from viewController: UIViewController, index: Int, dataSource: WYPhotoBrowserDataSource, configuration: WYPhotoBrowserConfiguration = WYPhotoBrowserConfiguration(), delegate: WYPhotoBrowserDelegate? = nil) -> WYPhotoBrowser {
        let browser = WYPhotoBrowser(configuration: configuration)
        browser.dataSource = dataSource
        browser.browserDelegate = delegate
        browser.internalCurrentIndex = max(0, index)
        browser.modalPresentationStyle = .overFullScreen
        browser.transitioningDelegate = browser
        viewController.present(browser, animated: true)
        return browser
    }

    /**
     * 浏览器初始化
     *   @param configuration 行为与外观配置(不传用默认配置)
     */
    public init(configuration: WYPhotoBrowserConfiguration = WYPhotoBrowserConfiguration()) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        flowLayout.scrollDirection = configuration.scrollDirection == .horizontal ? .horizontal : .vertical
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * 跳到指定页
     *   @param index 目标页下标
     *   @param animated true带翻页动画，false立即落定
     */
    @objc public func scrollToItem(at index: Int, animated: Bool) {
        guard numberOfItems > 0, index >= 0, index < numberOfItems else { return }
        internalCurrentIndex = index
        guard isViewLoaded else { return }
        let target = targetOffset(for: index)
        if animated {
            collectionView.setContentOffset(target, animated: true)
        } else {
            collectionView.setContentOffset(target, animated: false)
            refreshIndicator()
        }
    }

    /// 刷新浏览项(数据源内容或数量变化后调用，尽量保持当前页下标)
    @objc public func reloadData() {
        guard isViewLoaded else { return }
        livePhotoCache.removeAll()
        collectionView.reloadData()
        scrollToItem(at: min(internalCurrentIndex, max(numberOfItems - 1, 0)), animated: false)
    }

    /**
     * 关闭浏览器
     *   @param animated true按配置的转场样式退出，false立即消失
     */
    @objc public func dismissBrowser(animated: Bool) {
        hideMenu()
        dismiss(animated: animated)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.addSubview(backgroundView)
        view.addSubview(collectionView)
        view.addSubview(pageTextLabel)
        view.addSubview(pageControl)

        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(backgroundTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(collectionLongPressed(_:)))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)

        configureFlowLayout()
        collectionView.setContentOffset(targetOffset(for: internalCurrentIndex), animated: false)
        refreshIndicator()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard view.bounds.size != lastLayoutSize else {
            layoutIndicator()
            return
        }
        hideMenu()
        lastLayoutSize = view.bounds.size
        backgroundView.frame = view.bounds
        collectionView.frame = view.bounds
        configureFlowLayout()
        collectionView.setContentOffset(targetOffset(for: internalCurrentIndex), animated: false)
        layoutIndicator()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.collectionView.setContentOffset(self.targetOffset(for: self.internalCurrentIndex), animated: false)
            self.layoutIndicator()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isTransitioningContent = false
        applyTransformToVisibleCells()
        restartCarouselTimer()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideMenu()
        pauseCarouselTimer()
        if isBeingDismissed || presentingViewController == nil {
            for cell in collectionView.visibleCells { (cell as? WYPhotoBrowserPageCell)?.cancelLoadingTasks() }
            browserDelegate?.wy_photoBrowserDidDismiss?(self)
        }
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// 背景幕布(默认黑色底，透明度跟随拖拽关闭与转场动画渐变，单击关闭浏览器)
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = configuration.appearance.backgroundColor
        return view
    }()

    /// 翻页集合视图布局(整页一个浏览项，无页间距)
    let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    /// 翻页集合视图
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WYPhotoBrowserPageCell.self, forCellWithReuseIdentifier: WYPhotoBrowserPageCell.reuseIdentifier)
        return collectionView
    }()

    /// 文本页码(3/9样式，底部居中)
    lazy var pageTextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: UIFont.wy_fontSize(configuration.appearance.pageIndicatorFontSize, WYBasisKitConfig.defaultScreenPixels), weight: .semibold)
        label.textColor = configuration.appearance.pageIndicatorTextColor
        label.isHidden = true
        return label
    }()

    /// 圆点页码
    lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.pageIndicatorTintColor = configuration.appearance.pageIndicatorDotColor
        control.currentPageIndicatorTintColor = configuration.appearance.pageIndicatorCurrentDotColor
        control.hidesForSinglePage = true
        control.isUserInteractionEnabled = false
        control.isHidden = true
        return control
    }()

    /// 转场动画器(弱引用浏览器，按配置样式做进出页动画)
    lazy var transitionAnimator: WYPhotoBrowserTransitionAnimator = {
        return WYPhotoBrowserTransitionAnimator(browser: self)
    }()

    /// 长按菜单(深色圆角浮层，点动作项或点空白处收起)
    lazy var menuView: WYPhotoBrowserMenuView = {
        return WYPhotoBrowserMenuView(appearance: configuration.appearance)
    }()

    /// 菜单遮罩(盖住浏览页，点击收起菜单)
    lazy var menuDimmingView: UIControl = {
        let control = UIControl()
        control.addTarget(self, action: #selector(menuDimmingTapped), for: .touchUpInside)
        return control
    }()

    /// 当前页下标(内部真源，公开属性读写都走它)
    var internalCurrentIndex: Int = 0

    /// 上次布局尺寸(尺寸变化时重刷集合视图布局，避免旋转后页宽不匹配)
    var lastLayoutSize: CGSize = .zero

    /// 拖拽关闭进行中标记(进行中时停用翻页与手势响应)
    var isDragDismissing: Bool = false

    /// 转场进行中标记(present动画期间为true，防止单击与拖拽抢事件)
    var isTransitioningContent: Bool = false

    /// 图片预取器(相邻页图片预下载，换页后重建)
    var imagePrefetcher: ImagePrefetcher?

    /// 自动轮播计时(翻页落定后重置，手动拖动与离屏时暂停)
    var carouselTimer: Timer?

    /// 已合成的LivePhoto缓存(页下标到LivePhoto，结构体浏览项写不回去故存浏览器侧)
    var livePhotoCache: [Int: PHLivePhoto] = [:]

    let livePhotoResources = WYPhotoBrowserResourceStore()

}
