//
//  WYChatMediaConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 接入方选择结果的消息排布
@objc public enum WYChatMediaPresentation: Int { case individual, merged }

/// 媒体展开与收起按钮位置
@objc public enum WYChatMediaButtonPlacement: Int { case beside, below }

/// 图片和视频消息展示配置
public struct WYChatMediaConfig {
    /// 折叠媒体组在消息列表内的布局
    public var embeddedLayoutStyle: WYPhotoBrowserLayoutStyle = .stackedCards
    /// 折叠媒体组在消息列表内的页码指示样式
    public var embeddedPageIndicatorStyle: WYPhotoBrowserPageIndicatorStyle = .none
    /// 折叠媒体组在消息列表内的背景色
    public var embeddedBackgroundColor: UIColor = .clear
    /// 折叠媒体组内是否提供保存操作
    public var embeddedShowsSaveAction: Bool = false
    /// 展开媒体在视口上下的预加载距离，nil时采用折叠卡片高度
    public var expandedPrefetchDistance: CGFloat? = nil
    /// 格式化展开或收起按钮的标题和媒体数
    public var itemCountText: ((_ title: String, _ count: Int) -> String)? = nil
    /// 视频播放底板圆角，nil时采用圆形
    public var videoPlayBackgroundCornerRadius: CGFloat? = nil
    /// 视频播放图标的显示方式
    public var videoPlayContentMode: UIView.ContentMode = .scaleAspectFit
    /// 视频时长文字对齐方式
    public var videoDurationTextAlignment: NSTextAlignment = .center
    /// 视频播放图标在背景内的单侧留白比例
    public var videoPlayIconInsetRatio: CGFloat = 0.18
    /// 时长标签距离视频封面边缘的间距
    public var videoDurationEdgeInset: CGFloat = 6
    /// 时长标签的水平与垂直总内边距
    public var videoDurationPadding: CGSize = CGSize(width: 12, height: 4)
    /// 时长标签圆角
    public var videoDurationCornerRadius: CGFloat = 6
    /// 设置视频、音乐和通话时长文字的格式
    public var durationFormatter: ((_ duration: TimeInterval) -> String)? = nil
    /// 选择多个媒体后的排布，默认合并
    public var presentation: WYChatMediaPresentation = .merged
    /// 更多面板中的相册项目下标，负数时不自动关联
    public var albumMoreItemIndex: Int = -1
    /// 叠卡主体尺寸
    public var cardSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(200, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(240, WYBasisKitConfig.defaultScreenPixels))
    /// 图片圆角
    public var cornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
    /// 展开后图片之间的间距
    public var expandedSpacing: CGFloat = UIDevice.wy_screenHeight(12, WYBasisKitConfig.defaultScreenPixels)
    /// 展开后是否使用原始宽高比，默认true
    public var usesOriginalAspectRatio: Bool = true
    /// 展开后单个媒体最大高度
    public var maximumExpandedItemHeight: CGFloat = UIDevice.wy_screenHeight(440, WYBasisKitConfig.defaultScreenPixels)
    /// 展开后是否在每个媒体旁显示头像，默认true
    public var showsExpandedAvatars: Bool = true
    /// 合并媒体是否显示外部气泡，默认false
    public var showsBubble: Bool = false
    /// 合并媒体内容内边距
    public var contentInsets: UIEdgeInsets = .zero
    /// 展开和收起按钮位置，默认在首个媒体旁边
    public var buttonPlacement: WYChatMediaButtonPlacement = .beside
    /// 展开和收起按钮是否显示媒体数量，默认false
    public var showsItemCountInButton: Bool = false
    /// 展开和收起按钮宽度
    public var buttonWidth: CGFloat = UIDevice.wy_screenWidth(44, WYBasisKitConfig.defaultScreenPixels)
    /// 展开和收起按钮圆角
    public var buttonCornerRadius: CGFloat = UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels)
    /// 展开和收起按钮高度
    public var buttonHeight: CGFloat = UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels)
    /// 按钮距离图片的间距
    public var buttonSpacing: CGFloat = UIDevice.wy_screenHeight(8, WYBasisKitConfig.defaultScreenPixels)
    /// 展开和收起按钮字体
    public var buttonFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(13, WYBasisKitConfig.defaultScreenPixels))
    /// 展开和收起按钮颜色
    public var buttonColor: UIColor = .secondaryLabel
    /// 展开和收起按钮背景色
    public var buttonBackgroundColor: UIColor = .tertiarySystemFill
    /// 展开按钮文字
    public var expandText: String = WYLocalized("展开", table: WYBasisKitConfig.kitLocalizableTable)
    /// 收起按钮文字
    public var collapseText: String = WYLocalized("收起", table: WYBasisKitConfig.kitLocalizableTable)
    /// 视频播放图标
    public var videoPlayImage: UIImage? = UIImage.wy_find("WYChatViewPlay", inBundle: WYChatSourceBundle)
    /// 视频播放图标尺寸
    public var videoPlaySize: CGSize = CGSize(width: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels))
    /// 视频播放图标颜色
    public var videoPlayColor: UIColor = .white
    /// 是否给视频播放图标应用videoPlayColor
    public var tintsVideoPlayImage: Bool = true
    /// 单条视频消息是否显示时长
    public var showsVideoDuration: Bool = true
    /// 单条视频的播放和时长底板颜色
    public var videoOverlayBackgroundColor: UIColor = .black.withAlphaComponent(0.54)
    /// 单条视频的时长文字颜色
    public var videoDurationColor: UIColor = .white
    /// 是否自动打开内置媒体浏览器，默认true，设置mediaPreviewHandler后由接入方处理
    public var automaticallyPresentsBrowser: Bool = true
    /// 视频播放器的展示方式，默认全屏
    public var videoPresentationStyle: UIModalPresentationStyle = .fullScreen
    /// 是否显示系统视频播放控件，默认true
    public var showsVideoPlaybackControls: Bool = true
    /// 媒体浏览器配置
    public var browser: WYPhotoBrowserConfiguration = {
        var value = WYPhotoBrowserConfiguration()
        value.allowsLoopScrolling = true
        value.stackedCardCyclesForward = true
        value.appearance.playButtonIcon = WYChatSourceBundle.image(named: "WYChatViewPlay")
        return value
    }()
    public init() {}
}
