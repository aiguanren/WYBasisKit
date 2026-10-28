//
//  WYPhotoBrowserObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/19.
//

#if canImport(WYBasisKitSwift)
import UIKit
import Photos
import PhotosUI
import WYBasisKitSwift

/// 浏览项(一个页面对应一个浏览项，图片内容按缩略占位图、缩略图、原图的顺序分级显示)
@objc(WYPhotoBrowserItem)
@objcMembers public class WYPhotoBrowserItemObjC: NSObject, WYPhotoBrowserItemConvertible {

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
    public override init() {
        super.init()
    }

    /**
     * 图片浏览项便捷初始化
     *   @param localImage 本地图片(只有一张本地图时用它一步到位)
     */
    public convenience init(localImage: UIImage) {
        self.init()
        placeholder = localImage
    }

    /**
     * 转成结构体浏览项
     * @return 与自身字段一致的WYPhotoBrowserItem
     */
    public func toItem() -> WYPhotoBrowserItem {
        var item = WYPhotoBrowserItem()
        item.mediaType = mediaType
        item.placeholder = placeholder
        item.thumbnailPath = thumbnailPath
        item.thumbnailURL = thumbnailURL
        item.originalPath = originalPath
        item.originalURL = originalURL
        item.originalFileSize = originalFileSize
        item.livePhoto = livePhoto
        item.livePhotoAsset = livePhotoAsset
        item.livePhotoStillURL = livePhotoStillURL
        item.livePhotoVideoURL = livePhotoVideoURL
        item.identifier = identifier
        return item
    }
}

/// 浏览器界面外观配置(全部属性都有默认值，按需覆盖，不设置时与默认外观一致，颜色与图片对象传nil、数值传负数表示该项用默认值)
@objc(WYPhotoBrowserAppearance)
@objcMembers public class WYPhotoBrowserAppearanceObjC: NSObject {

    /// 浏览页背景色(进出页转场时背景透明度会跟随动画渐变)
    public var backgroundColor: UIColor?

    /// 文本页码文字颜色
    public var pageIndicatorTextColor: UIColor?

    /// 文本页码字号(设计值，按基准屏换算)
    public var pageIndicatorFontSize: CGFloat = -1

    /// 圆点页码未选中圆点颜色
    public var pageIndicatorDotColor: UIColor?

    /// 圆点页码当前页圆点颜色
    public var pageIndicatorCurrentDotColor: UIColor?

    /// 视频封面播放按钮图标(nil用内置播放三角图标)
    public var playButtonIcon: UIImage?

    /// 视频封面播放按钮图标颜色(内置图标生效，自定义图标原样显示)
    public var playButtonIconColor: UIColor?

    /// 视频封面播放按钮底色(圆形按钮的底)
    public var playButtonBackgroundColor: UIColor?

    /// LivePhoto角标底色(左上角Live胶囊的底)
    public var livePhotoBadgeBackgroundColor: UIColor?

    /// LivePhoto角标文字颜色(播放中角标会临时压暗)
    public var livePhotoBadgeTextColor: UIColor?

    /// LivePhoto角标字号(设计值，按基准屏换算)
    public var livePhotoBadgeFontSize: CGFloat = -1

    /// 加载进度环颜色(没有可显示的图片时屏幕中央的环形进度)
    public var progressRingColor: UIColor?

    /// 加载进度环轨道颜色(进度环的底环)
    public var progressRingTrackColor: UIColor?

    /// 加载进度百分比文字颜色(进度环中央的百分数)
    public var progressLabelColor: UIColor?

    /// 加载进度百分比字号(设计值，按基准屏换算)
    public var progressLabelFontSize: CGFloat = -1

    /// 加载失败重试胶囊底色(下载失败时屏幕中央显示的点击重试胶囊)
    public var retryButtonBackgroundColor: UIColor?

    /// 加载失败重试胶囊文字颜色
    public var retryButtonTextColor: UIColor?

    /// 加载失败重试胶囊字号(设计值，按基准屏换算)
    public var retryButtonFontSize: CGFloat = -1

    /// 查看原图按钮底色(底部居中的查看原图与原图进度按钮)
    public var originalButtonBackgroundColor: UIColor?

    /// 查看原图按钮文字颜色
    public var originalButtonTextColor: UIColor?

    /// 查看原图按钮字号(设计值，按基准屏换算)
    public var originalButtonFontSize: CGFloat = -1

    /// 长按菜单底色(深色圆角浮层)
    public var menuBackgroundColor: UIColor?

    /// 长按菜单文字颜色
    public var menuTextColor: UIColor?

    /// 长按菜单字号(设计值，按基准屏换算)
    public var menuFontSize: CGFloat = -1

    /// 长按菜单动作按住高亮色(手指按住某行动作的背景色)
    public var menuHighlightBackgroundColor: UIColor?

    /// 长按菜单圆角(设计值，按基准屏换算)
    public var menuCornerRadius: CGFloat = -1
}

/// 浏览器行为配置(全部属性都有默认值，按需覆盖，不设置时与默认行为一致)
@objc(WYPhotoBrowserConfiguration)
@objcMembers public class WYPhotoBrowserConfigurationObjC: NSObject {

    /// 翻页方向(默认横向左右翻页)
    public var scrollDirection: WYPhotoBrowserScrollDirection = .horizontal

    /// 同屏布局样式(默认整页一次一张，多页同屏时一次看到多张一起滑动)
    public var layoutStyle: WYPhotoBrowserLayoutStyle = .fullPage

    /// 多页同屏时两侧露出相邻页的宽度(设计值，按基准屏换算，仅layoutStyle为multiPage时生效)
    public var multiPageRevealWidth: CGFloat = -1

    /// 多页同屏时页与页的间距(设计值，按基准屏换算，仅layoutStyle为multiPage时生效)
    public var multiPageSpacing: CGFloat = -1

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
    public var customActions: [WYPhotoBrowserAction]?

    /// 相邻页预加载数量(翻页落定后预下载前后各几页的图片，0不预加载)
    public var prefetchCount: Int = 1

    /// 是否循环翻页(true时滑到末页继续滑无缝回到首页，仅多于一张时生效)
    public var allowsLoopScrolling: Bool = false

    /// 自动轮播间隔秒数(大于0时每隔该秒数自动翻到下一张，末页回绕到首页，需要多于一张且allowsLoopScrolling为true才生效，手动拖动后重新计时)
    public var autoCarouselInterval: TimeInterval = 0

    /// 外观配置(传nil用默认外观)
    public var appearance: WYPhotoBrowserAppearanceObjC?
}

/// 图片浏览器入口(封装WYPhotoBrowser的弹出，数据源实现WYPhotoBrowserDataSourceObjC返回WYPhotoBrowserItemObjC)
@objc(WYPhotoBrowserController)
@objcMembers public class WYPhotoBrowserObjC: NSObject {

    /**
     * 便利弹出入口(一行代码从指定控制器弹出浏览器，需要进一步操作浏览器实例的场合改用init构造)
     *
     *  @param viewController 从哪个控制器弹出(浏览器全屏盖在它上面)
     *  @param index          进入时显示的页下标
     *  @param dataSource     数据源(浏览项数量与内容)
     *  @param configuration  行为与外观配置(传nil用默认配置)
     *  @param delegate       代理(不传无事件回调)
     */
    @objc(showFromViewController:index:dataSource:configuration:delegate:)
    public static func show(from viewController: UIViewController, index: Int, dataSource: WYPhotoBrowserDataSource?, configuration: WYPhotoBrowserConfigurationObjC? = nil, delegate: WYPhotoBrowserDelegate? = nil) {
        guard let dataSource = dataSource else { return }
        let browser = WYPhotoBrowser(configuration: convertConfiguration(configuration))
        browser.dataSource = dataSource
        browser.browserDelegate = delegate
        browser.scrollToItem(at: max(0, index), animated: false)
        browser.modalPresentationStyle = .overFullScreen
        browser.transitioningDelegate = browser
        viewController.present(browser, animated: true)
    }

    /// 桥接配置转Swift配置(nil项保留Swift默认值)
    private static func convertConfiguration(_ bridgeConfiguration: WYPhotoBrowserConfigurationObjC?) -> WYPhotoBrowserConfiguration {
        var configuration = WYPhotoBrowserConfiguration()
        if let bridgeConfiguration = bridgeConfiguration {
            configuration.scrollDirection = bridgeConfiguration.scrollDirection
            configuration.layoutStyle = bridgeConfiguration.layoutStyle
            if bridgeConfiguration.multiPageRevealWidth >= 0 { configuration.multiPageRevealWidth = bridgeConfiguration.multiPageRevealWidth }
            if bridgeConfiguration.multiPageSpacing >= 0 { configuration.multiPageSpacing = bridgeConfiguration.multiPageSpacing }
            configuration.transformStyle = bridgeConfiguration.transformStyle
            configuration.transitionStyle = bridgeConfiguration.transitionStyle
            configuration.pageIndicatorStyle = bridgeConfiguration.pageIndicatorStyle
            configuration.originalLoadStyle = bridgeConfiguration.originalLoadStyle
            if bridgeConfiguration.doubleTapZoomScale > 0 { configuration.doubleTapZoomScale = bridgeConfiguration.doubleTapZoomScale }
            if bridgeConfiguration.maxZoomScale > 0 { configuration.maxZoomScale = bridgeConfiguration.maxZoomScale }
            configuration.allowsTapDismiss = bridgeConfiguration.allowsTapDismiss
            configuration.allowsDragDismiss = bridgeConfiguration.allowsDragDismiss
            if bridgeConfiguration.dragDismissThreshold > 0 { configuration.dragDismissThreshold = bridgeConfiguration.dragDismissThreshold }
            configuration.showsSaveAction = bridgeConfiguration.showsSaveAction
            if let customActions = bridgeConfiguration.customActions, customActions.isEmpty == false { configuration.customActions = customActions }
            if bridgeConfiguration.prefetchCount >= 0 { configuration.prefetchCount = bridgeConfiguration.prefetchCount }
            configuration.allowsLoopScrolling = bridgeConfiguration.allowsLoopScrolling
            if bridgeConfiguration.autoCarouselInterval > 0 { configuration.autoCarouselInterval = bridgeConfiguration.autoCarouselInterval }
            if let bridgeAppearance = bridgeConfiguration.appearance {
                var appearance = WYPhotoBrowserAppearance()
                if let color = bridgeAppearance.backgroundColor { appearance.backgroundColor = color }
                if let color = bridgeAppearance.pageIndicatorTextColor { appearance.pageIndicatorTextColor = color }
                if bridgeAppearance.pageIndicatorFontSize >= 0 { appearance.pageIndicatorFontSize = bridgeAppearance.pageIndicatorFontSize }
                if let color = bridgeAppearance.pageIndicatorDotColor { appearance.pageIndicatorDotColor = color }
                if let color = bridgeAppearance.pageIndicatorCurrentDotColor { appearance.pageIndicatorCurrentDotColor = color }
                if let icon = bridgeAppearance.playButtonIcon { appearance.playButtonIcon = icon }
                if let color = bridgeAppearance.playButtonIconColor { appearance.playButtonIconColor = color }
                if let color = bridgeAppearance.playButtonBackgroundColor { appearance.playButtonBackgroundColor = color }
                if let color = bridgeAppearance.livePhotoBadgeBackgroundColor { appearance.livePhotoBadgeBackgroundColor = color }
                if let color = bridgeAppearance.livePhotoBadgeTextColor { appearance.livePhotoBadgeTextColor = color }
                if bridgeAppearance.livePhotoBadgeFontSize >= 0 { appearance.livePhotoBadgeFontSize = bridgeAppearance.livePhotoBadgeFontSize }
                if let color = bridgeAppearance.progressRingColor { appearance.progressRingColor = color }
                if let color = bridgeAppearance.progressRingTrackColor { appearance.progressRingTrackColor = color }
                if let color = bridgeAppearance.progressLabelColor { appearance.progressLabelColor = color }
                if bridgeAppearance.progressLabelFontSize >= 0 { appearance.progressLabelFontSize = bridgeAppearance.progressLabelFontSize }
                if let color = bridgeAppearance.retryButtonBackgroundColor { appearance.retryButtonBackgroundColor = color }
                if let color = bridgeAppearance.retryButtonTextColor { appearance.retryButtonTextColor = color }
                if bridgeAppearance.retryButtonFontSize >= 0 { appearance.retryButtonFontSize = bridgeAppearance.retryButtonFontSize }
                if let color = bridgeAppearance.originalButtonBackgroundColor { appearance.originalButtonBackgroundColor = color }
                if let color = bridgeAppearance.originalButtonTextColor { appearance.originalButtonTextColor = color }
                if bridgeAppearance.originalButtonFontSize >= 0 { appearance.originalButtonFontSize = bridgeAppearance.originalButtonFontSize }
                if let color = bridgeAppearance.menuBackgroundColor { appearance.menuBackgroundColor = color }
                if let color = bridgeAppearance.menuTextColor { appearance.menuTextColor = color }
                if bridgeAppearance.menuFontSize >= 0 { appearance.menuFontSize = bridgeAppearance.menuFontSize }
                if let color = bridgeAppearance.menuHighlightBackgroundColor { appearance.menuHighlightBackgroundColor = color }
                if bridgeAppearance.menuCornerRadius >= 0 { appearance.menuCornerRadius = bridgeAppearance.menuCornerRadius }
                configuration.appearance = appearance
            }
        }
        return configuration
    }
}
#endif
