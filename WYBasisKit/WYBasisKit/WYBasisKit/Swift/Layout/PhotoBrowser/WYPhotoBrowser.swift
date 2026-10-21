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
     * @param return 转换出的WYPhotoBrowserItem
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
     * @param return 弹出的浏览器实例
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

        guard view.bounds.size != lastLayoutSize else { return }
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

    /// 浏览项数量(数据源缺位时为0)
    var numberOfItems: Int {
        return dataSource?.numberOfItems(in: self) ?? 0
    }

    /// 统一取浏览项(WYPhotoBrowserItem与实现toItem()的类型两种返回归一，并把已合成的LivePhoto缓存填回)
    func item(at index: Int) -> WYPhotoBrowserItem? {
        var item: WYPhotoBrowserItem?
        if let anyItem = dataSource?.photoBrowser(self, itemAt: index) {
            if let structItem = anyItem as? WYPhotoBrowserItem {
                item = structItem
            } else if let convertibleItem = anyItem as? WYPhotoBrowserItemConvertible {
                item = convertibleItem.toItem()
            }
        }
        if item?.livePhoto == nil, let cachedLivePhoto = livePhotoCache[index] {
            item?.livePhoto = cachedLivePhoto
        }
        return item
    }

    /// 缓存页Cell合成的LivePhoto(结构体浏览项写不回去，合成结果存浏览器侧供复用)
    func cacheLivePhoto(_ livePhoto: PHLivePhoto, for index: Int) {
        livePhotoCache[index] = livePhoto
    }

    /// 单击背景关闭(图片区域的单击由页Cell回调dismissByTap)
    @objc func backgroundTapped() {
        dismissByTap()
    }

    /// 长按集合视图(定位长按页下标，LivePhoto页长按播放松手停，其余页长按弹菜单)
    @objc func collectionLongPressed(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        let displayIndex = displayIndex(fromCollection: indexPath.item)
        switch gesture.state {
        case .began:
            guard isTransitioningContent == false, isDragDismissing == false else { return }
            handleLongPress(at: displayIndex, touchPoint: gesture.location(in: view))
        case .ended, .cancelled, .failed:
            cellForItem(at: displayIndex)?.stopLivePhoto()
        default:
            break
        }
    }

    /// 处理长按(按项类型分播放或菜单，菜单场景同时回调代理)
    func handleLongPress(at index: Int, touchPoint: CGPoint) {
        guard index >= 0, index < numberOfItems, let item = item(at: index) else { return }
        if item.mediaType == .livePhoto, let cell = cellForItem(at: index) {
            cell.playLivePhoto()
            return
        }
        browserDelegate?.wy_photoBrowser?(self, didLongPressItemAt: index)
        showMenu(at: touchPoint, index: index)
    }

    /// 弹出长按菜单(内置保存动作按配置开关，自定义动作按传入顺序排前)
    func showMenu(at point: CGPoint, index: Int) {
        guard menuView.superview == nil else { return }

        var actions = configuration.customActions
        if configuration.showsSaveAction {
            let saveTitle = WYLocalized("保存图片", table: WYBasisKitConfig.kitLocalizableTable)
            actions.append(WYPhotoBrowserAction(title: saveTitle, icon: menuSaveIcon, handler: { browser, _ in
                browser.saveCurrentItemToAlbum()
            }))
        }
        guard actions.isEmpty == false else { return }

        view.addSubview(menuDimmingView)
        view.addSubview(menuView)
        menuDimmingView.frame = view.bounds
        menuView.show(actions: actions, anchorPoint: point, in: view) { [weak self] action in
            guard let self = self else { return }
            self.hideMenu()
            action.handler?(self, index)
        }
    }

    /// 收起长按菜单与遮罩
    func hideMenu() {
        menuView.removeFromSuperview()
        menuDimmingView.removeFromSuperview()
    }

    /// 点菜单遮罩收起菜单
    @objc func menuDimmingTapped() {
        hideMenu()
    }

    /// 内置保存动作的图标(系统下载图标，iOS15自带)
    var menuSaveIcon: UIImage? {
        return UIImage(systemName: "square.and.arrow.down")
    }

    /// 保存当前页图片到系统相册(先过相册授权，保存结果用Activity提示窗口反馈)
    func saveCurrentItemToAlbum() {
        let toastConfig = configuration.appearance.toastConfig ?? WYActivityConfig.info
        guard let image = currentCell?.currentDisplayImage() else {
            WYActivity.showInfo(WYLocalized("保存失败，请重试", table: WYBasisKitConfig.kitLocalizableTable), in: view, position: .middle, config: toastConfig)
            return
        }
        wy_authorizeAlbumAccess(showSettingsAlert: true) { [weak self] authorized, limited in
            guard let self = self else { return }
            guard authorized || limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                Task { @MainActor in
                    let key = success ? "已保存到相册" : "保存失败，请重试"
                    WYActivity.showInfo(WYLocalized(key, table: WYBasisKitConfig.kitLocalizableTable), in: self.view, position: .middle, config: toastConfig)
                }
            }
        }
    }

    /// 单击关闭(尊重配置开关，转场与拖拽进行中不响应)
    func dismissByTap() {
        guard configuration.allowsTapDismiss, isTransitioningContent == false, isDragDismissing == false else { return }
        dismissBrowser(animated: true)
    }

    /// 取指定显示页的Cell(只有可见页能取到，循环模式下换算到集合页码)
    func cellForItem(at index: Int) -> WYPhotoBrowserPageCell? {
        return collectionView.cellForItem(at: IndexPath(item: collectionIndex(for: index), section: 0)) as? WYPhotoBrowserPageCell
    }

    /// 当前页Cell
    var currentCell: WYPhotoBrowserPageCell? {
        return cellForItem(at: internalCurrentIndex)
    }

    /// 指定页的转场来源屏幕位置(取不到可用来源时返回nil，转场降级渐隐)
    func sourceFrameForItem(at index: Int) -> CGRect? {
        guard let sourceView = browserDelegate?.wy_photoBrowser?(self, sourceViewForItemAt: index) else { return nil }
        guard let window = sourceView.window, sourceView.isHidden == false, sourceView.alpha > 0.01 else { return nil }
        let frame = sourceView.convert(sourceView.bounds, to: window)
        guard frame.intersects(window.bounds.insetBy(dx: -50, dy: -50)) else { return nil }
        return frame
    }

    /// 隐藏或恢复当前页图片内容(转场动画期间用快照替代真内容，避免双层图片)
    func setCurrentContentHidden(_ hidden: Bool) {
        currentCell?.setMainContentHidden(hidden)
    }

    /// 页Cell点击了视频封面播放按钮(转发代理由接入方自行播放)
    func pageCellDidTapPlayVideo(_ cell: WYPhotoBrowserPageCell) {
        browserDelegate?.wy_photoBrowser?(self, didTapPlayVideoItemAt: cell.index)
    }

    /// 页Cell原图加载完成(转发代理)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didFinishLoadingOriginalAt index: Int) {
        browserDelegate?.wy_photoBrowser?(self, didFinishLoadingOriginalItemAt: index)
    }

    /// 页Cell拖拽进度变化(背景与页码跟随变淡)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didUpdateDragProgress progress: CGFloat) {
        backgroundView.alpha = 1 - progress * 0.85
        setChromeHidden(progress > 0.05)
    }

    /// 页Cell开始拖拽(停用翻页滚动)
    func pageCellDidBeginDrag(_ cell: WYPhotoBrowserPageCell) {
        collectionView.isScrollEnabled = false
    }

    /// 页Cell拖拽结束(超过阈值或甩动速度够大走关闭动画，否则弹回)
    func pageCell(_ cell: WYPhotoBrowserPageCell, didEndDragWithTranslation translation: CGPoint, velocity: CGPoint) {
        collectionView.isScrollEnabled = true
        let distance = abs(translation.y)
        let speed = abs(velocity.y)
        if distance > configuration.dragDismissThreshold || speed > 800 {
            startDragDismiss(from: cell, velocity: velocity)
        } else {
            cell.springBack()
            UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction]) {
                self.backgroundView.alpha = 1
            } completion: { _ in
                self.setChromeHidden(false)
            }
        }
    }

    /// 执行拖拽关闭(快照飞回来源位置或顺速度飘出屏，然后无动画移除浏览器)
    func startDragDismiss(from cell: WYPhotoBrowserPageCell, velocity: CGPoint) {
        guard isDragDismissing == false else { return }
        isDragDismissing = true
        hideMenu()

        let snapshotView = cell.takeMainContentSnapshot()
        let startFrame = cell.mainContentScreenFrame() ?? cell.frame
        let sourceFrame = sourceFrameForItem(at: internalCurrentIndex)

        collectionView.isHidden = true
        setChromeHidden(true)
        if let snapshotView = snapshotView {
            snapshotView.frame = startFrame
            view.addSubview(snapshotView)
            let fallbackY = velocity.y >= 0 ? view.bounds.maxY + startFrame.height : -startFrame.height
            let endFrame = sourceFrame ?? CGRect(x: startFrame.midX - startFrame.width / 2, y: fallbackY, width: startFrame.width, height: startFrame.height)
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
                snapshotView.frame = endFrame
                self.backgroundView.alpha = 0
            } completion: { [weak self] _ in
                snapshotView.removeFromSuperview()
                self?.dismiss(animated: false)
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundView.alpha = 0
            }) { [weak self] _ in
                self?.dismiss(animated: false)
            }
        }
    }

    /// 页码与覆盖层的隐藏开关(拖拽与转场时淡出)
    func setChromeHidden(_ hidden: Bool) {
        let indicatorVisible = numberOfItems > 1
        pageTextLabel.isHidden = hidden || configuration.pageIndicatorStyle != .text || indicatorVisible == false
        pageControl.isHidden = hidden || configuration.pageIndicatorStyle != .dots || indicatorVisible == false
        currentCell?.setChromeHidden(hidden)
    }

    /// 刷新页码显示(翻页落定与数据刷新后调用)
    func refreshIndicator() {
        let indicatorVisible = numberOfItems > 1
        switch configuration.pageIndicatorStyle {
        case .none:
            pageTextLabel.isHidden = true
            pageControl.isHidden = true
        case .text:
            pageControl.isHidden = true
            pageTextLabel.isHidden = indicatorVisible == false
            pageTextLabel.text = "\(internalCurrentIndex + 1)/\(numberOfItems)"
        case .dots:
            pageTextLabel.isHidden = true
            pageControl.isHidden = indicatorVisible == false
            pageControl.numberOfPages = numberOfItems
            pageControl.currentPage = internalCurrentIndex
        }
    }

    /// 摆放页码(底部居中，避开底部安全区)
    func layoutIndicator() {
        let indicatorHeight = UIDevice.wy_screenHeight(20, WYBasisKitConfig.defaultScreenPixels)
        let bottomMargin = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)
        let indicatorY = view.bounds.height - view.safeAreaInsets.bottom - bottomMargin - indicatorHeight
        pageTextLabel.frame = CGRect(x: 0, y: indicatorY, width: view.bounds.width, height: indicatorHeight)
        pageControl.frame = CGRect(x: 0, y: indicatorY, width: view.bounds.width, height: indicatorHeight)
    }

    /// 指定显示页的翻页偏移(循环模式下真实页落在缓冲区中间段，翻页方向不同偏移轴向不同)
    func targetOffset(for index: Int) -> CGPoint {
        guard numberOfItems > 0 else { return .zero }
        let boundedIndex = max(0, min(index, numberOfItems - 1))
        return targetRawOffset(collectionIndex: collectionIndex(for: boundedIndex))
    }

    /// 预加载相邻页图片(按配置的预加载数量取前后页的原图或缩略图地址)
    func prefetchNeighbors() {
        guard configuration.prefetchCount > 0, numberOfItems > 0 else { return }
        var urls: [URL] = []
        for offset in 1...configuration.prefetchCount {
            for index in [internalCurrentIndex - offset, internalCurrentIndex + offset] {
                guard index >= 0, index < numberOfItems, let item = item(at: index), item.mediaType != .video else { continue }
                if let url = item.originalURL {
                    urls.append(url)
                } else if let url = item.thumbnailURL {
                    urls.append(url)
                }
            }
        }
        guard urls.isEmpty == false else { return }
        imagePrefetcher = ImagePrefetcher(urls: urls)
        imagePrefetcher?.start()
    }
}

extension WYPhotoBrowser: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loopCollectionItemCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WYPhotoBrowserPageCell.reuseIdentifier, for: indexPath) as! WYPhotoBrowserPageCell
        cell.browser = self
        let displayIndex = displayIndex(fromCollection: indexPath.item)
        if let item = item(at: displayIndex) {
            cell.configure(item: item, index: displayIndex, configuration: configuration)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutItemSize()
    }
}

extension WYPhotoBrowser: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        settleCurrentPage()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        settleCurrentPage()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseCarouselTimer()
    }

    /// 多页同屏的松手吸附(按单页步长取整落位，快速甩动按速度方向跳页)
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard configuration.layoutStyle == .multiPage, pageStep > 0 else { return }
        let isHorizontal = flowLayout.scrollDirection == .horizontal
        let rawTarget = isHorizontal ? targetContentOffset.pointee.x : targetContentOffset.pointee.y
        let velocityValue = isHorizontal ? velocity.x : velocity.y
        var pageIndex = (rawTarget - pageStepLeading) / pageStep
        if velocityValue > 0.5 {
            pageIndex = ceil(pageIndex - 0.2)
        } else if velocityValue < -0.5 {
            pageIndex = floor(pageIndex + 0.2)
        } else {
            pageIndex = round(pageIndex)
        }
        let bounded = max(0, min(pageIndex, CGFloat(loopCollectionItemCount - 1)))
        let snappedTarget = pageStepLeading + bounded * pageStep
        if isHorizontal {
            targetContentOffset.pointee.x = snappedTarget
        } else {
            targetContentOffset.pointee.y = snappedTarget
        }
    }

    /// 滚动中给可见页施加多页同屏过渡特效(按页中心离视口中心的比例变化)
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        applyTransformToVisibleCells()
    }

    /// 给可见页施加多页同屏过渡特效(进入静止时与滚动中都调用，非多页同屏或无特效时不做)
    func applyTransformToVisibleCells() {
        guard configuration.layoutStyle == .multiPage, configuration.transformStyle != .none, pageStep > 0 else { return }
        let isHorizontal = flowLayout.scrollDirection == .horizontal
        let viewportCenter = isHorizontal ? collectionView.bounds.midX : collectionView.bounds.midY
        for case let cell as WYPhotoBrowserPageCell in collectionView.visibleCells {
            guard cell.isDraggingToDismiss == false else { continue }
            let cellCenter = isHorizontal ? cell.center.x : cell.center.y
            let ratio = (cellCenter - viewportCenter) / pageStep
            cell.applyLayoutTransform(style: configuration.transformStyle, ratio: ratio)
        }
    }

    /// 翻页落定(算出当前页、循环模式缓冲页无感回跳、刷页码、回调代理、预加载相邻页、重启自动轮播)
    func settleCurrentPage() {
        guard pageStep > 0, numberOfItems > 0 else { return }
        let offset = collectionView.contentOffset.x + collectionView.contentOffset.y
        let collectionIndex = Int(round((offset - pageStepLeading) / pageStep))
        let displayIndex = displayIndex(fromCollection: collectionIndex)
        let changed = displayIndex != internalCurrentIndex
        internalCurrentIndex = displayIndex
        normalizeLoopPosition(collectionIndex: collectionIndex)
        refreshIndicator()
        if changed {
            browserDelegate?.wy_photoBrowser?(self, didShowItemAt: internalCurrentIndex)
        }
        applyTransformToVisibleCells()
        prefetchNeighbors()
        restartCarouselTimer()
    }

    /// 循环翻页生效判定(多于一张且配置开启)
    var isLoopScrollingEnabled: Bool {
        return configuration.allowsLoopScrolling && numberOfItems > 1
    }

    /// 集合视图页数(循环模式下首尾各插一页缓冲，0页显示末页、末页后一页显示首页)
    var loopCollectionItemCount: Int {
        if isLoopScrollingEnabled {
            return numberOfItems + 2
        }
        return numberOfItems
    }

    /**
     * 集合页码换显示页码(循环模式缓冲页映射回真实页，非循环模式原样返回)
     *   @param collectionIndex 集合视图页码
     * @param return 数据源真实页码
     */
    func displayIndex(fromCollection collectionIndex: Int) -> Int {
        guard isLoopScrollingEnabled else { return collectionIndex }
        if collectionIndex <= 0 {
            return numberOfItems - 1
        }
        if collectionIndex >= numberOfItems + 1 {
            return 0
        }
        return collectionIndex - 1
    }

    /**
     * 显示页码换集合页码(循环模式真实页码落在缓冲区中间段)
     *   @param displayIndex 数据源真实页码
     * @param return 集合视图页码
     */
    func collectionIndex(for displayIndex: Int) -> Int {
        guard isLoopScrollingEnabled else { return displayIndex }
        return displayIndex + 1
    }

    /// 停在缓冲页时无动画跳回对应真实页(视觉无感，用户继续滑像无限循环)
    func normalizeLoopPosition(collectionIndex: Int) {
        guard isLoopScrollingEnabled else { return }
        var targetCollectionIndex: Int? = nil
        if collectionIndex <= 0 {
            targetCollectionIndex = numberOfItems
        } else if collectionIndex >= numberOfItems + 1 {
            targetCollectionIndex = 1
        }
        if let targetCollectionIndex = targetCollectionIndex {
            collectionView.setContentOffset(targetRawOffset(collectionIndex: targetCollectionIndex), animated: false)
        }
    }

    /// 集合页码的翻页偏移(按单页步长与起点偏移计算，整页与多页同屏两种布局共用，不经显示页码换算)
    func targetRawOffset(collectionIndex: Int) -> CGPoint {
        let offset = pageStepLeading + CGFloat(collectionIndex) * pageStep
        if flowLayout.scrollDirection == .horizontal {
            return CGPoint(x: offset, y: 0)
        }
        return CGPoint(x: 0, y: offset)
    }

    /// 按布局样式配置集合视图布局(整页铺满按视口分页，多页同屏按页宽加间距分页并露出两侧)
    func configureFlowLayout() {
        if configuration.layoutStyle == .multiPage {
            let reveal = UIDevice.wy_screenWidth(configuration.multiPageRevealWidth, WYBasisKitConfig.defaultScreenPixels)
            let spacing = UIDevice.wy_screenWidth(configuration.multiPageSpacing, WYBasisKitConfig.defaultScreenPixels)
            let edge = reveal + spacing
            if flowLayout.scrollDirection == .horizontal {
                flowLayout.itemSize = CGSize(width: collectionView.bounds.width - edge * 2, height: collectionView.bounds.height)
                flowLayout.sectionInset = UIEdgeInsets(top: 0, left: edge, bottom: 0, right: edge)
            } else {
                flowLayout.itemSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height - edge * 2)
                flowLayout.sectionInset = UIEdgeInsets(top: edge, left: 0, bottom: edge, right: 0)
            }
            flowLayout.minimumLineSpacing = spacing
            collectionView.isPagingEnabled = false
        } else {
            flowLayout.itemSize = collectionView.bounds.size
            flowLayout.sectionInset = .zero
            flowLayout.minimumLineSpacing = 0
            collectionView.isPagingEnabled = true
        }
    }

    /// 布局给页的尺寸(与configureFlowLayout的itemSize一致)
    func layoutItemSize() -> CGSize {
        if configuration.layoutStyle == .multiPage {
            return flowLayout.itemSize == .zero ? collectionView.bounds.size : flowLayout.itemSize
        }
        return collectionView.bounds.size
    }

    /// 单页步长(整页为视口宽或高，多页同屏为页尺寸加页间距)
    var pageStep: CGFloat {
        if configuration.layoutStyle == .multiPage {
            let spacing = UIDevice.wy_screenWidth(configuration.multiPageSpacing, WYBasisKitConfig.defaultScreenPixels)
            if flowLayout.scrollDirection == .horizontal {
                return layoutItemSize().width + spacing
            }
            return layoutItemSize().height + spacing
        }
        if flowLayout.scrollDirection == .horizontal {
            return collectionView.bounds.width
        }
        return collectionView.bounds.height
    }

    /// 步长起点偏移(整页为0，多页同屏为分组内边距)
    var pageStepLeading: CGFloat {
        if configuration.layoutStyle == .multiPage {
            if flowLayout.scrollDirection == .horizontal {
                return flowLayout.sectionInset.left
            }
            return flowLayout.sectionInset.top
        }
        return 0
    }

    /// 重启自动轮播计时(满足条件才启动，翻页落定与程序化跳页后调用)
    func restartCarouselTimer() {
        pauseCarouselTimer()
        guard isViewLoaded, view.window != nil, configuration.autoCarouselInterval > 0, isLoopScrollingEnabled, isDragDismissing == false else { return }
        carouselTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoCarouselInterval, repeats: false) { [weak self] _ in
            self?.carouselToNext()
        }
    }

    /// 暂停自动轮播计时(手动拖动、拖拽关闭、离屏时调用)
    func pauseCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    /// 自动翻到下一张(末页回绕到首页，自动轮播计时触发)
    func carouselToNext() {
        let next = (internalCurrentIndex + 1) % max(numberOfItems, 1)
        scrollToItem(at: next, animated: true)
    }
}

extension WYPhotoBrowser: UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = true
        return transitionAnimator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = false
        return transitionAnimator
    }
}
