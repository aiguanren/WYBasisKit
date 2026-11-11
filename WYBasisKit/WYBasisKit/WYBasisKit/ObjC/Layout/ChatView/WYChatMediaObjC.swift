//
//  WYChatMediaObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

@objc(WYChatMediaItem)
@objcMembers public class WYChatMediaItemObjC: NSObject {
    /// 媒体ID
    public var id: String
    /// 媒体类型
    public var kind: WYChatMediaKind
    /// 图片原图或视频文件
    public var original: WYChatAssetsModelObjC
    /// 列表缩略图或视频封面
    public var thumbnail: WYChatAssetsModelObjC
    /// 原始显示尺寸，零尺寸时使用配置尺寸
    public var size: CGSize
    /// 视频时长，单位秒
    public var duration: TimeInterval
    public override convenience init() { self.init(WYChatMediaItem()) }
    @nonobjc public init(_ value: WYChatMediaItem) {
        id = value.id; kind = value.kind; original = WYChatAssetsModelObjC(value.original); thumbnail = WYChatAssetsModelObjC(value.thumbnail); size = value.size; duration = value.duration
        super.init()
    }
    @nonobjc public func toValue() -> WYChatMediaItem {
        var value = WYChatMediaItem()
        value.id = id; value.kind = kind; value.original = original.toValue(); value.thumbnail = thumbnail.toValue(); value.size = size; value.duration = duration
        return value
    }
}

@objc(WYChatMediaGroupModel)
@objcMembers public class WYChatMediaGroupModelObjC: NSObject {
    /// 媒体列表
    public var items: [WYChatMediaItemObjC]
    /// 是否展开为纵向列表，默认false
    public var isExpanded: Bool
    /// 叠卡当前显示的媒体下标
    public var visibleIndex: Int
    public override convenience init() { self.init(WYChatMediaGroupModel()) }
    @nonobjc public init(_ value: WYChatMediaGroupModel) {
        items = value.items.map(WYChatMediaItemObjC.init); isExpanded = value.isExpanded; visibleIndex = value.visibleIndex
        super.init()
    }
    @nonobjc public func toValue() -> WYChatMediaGroupModel {
        var value = WYChatMediaGroupModel(items: items.map { $0.toValue() })
        value.isExpanded = isExpanded; value.visibleIndex = visibleIndex
        return value
    }
}

@objc(WYChatMediaConfig)
@objcMembers public class WYChatMediaConfigObjC: NSObject {
    /// 选择多个媒体后的排布，默认合并
    public var presentation: WYChatMediaPresentation
    /// 更多面板中的相册项目下标，负数时不自动关联
    public var albumMoreItemIndex: Int
    /// 叠卡主体尺寸
    public var cardSize: CGSize
    /// 图片圆角
    public var cornerRadius: CGFloat
    /// 展开后图片之间的间距
    public var expandedSpacing: CGFloat
    /// 展开后是否使用原始宽高比，默认true
    public var usesOriginalAspectRatio: Bool
    /// 展开后单个媒体最大高度
    public var maximumExpandedItemHeight: CGFloat
    /// 展开后是否在每个媒体旁显示头像，默认true
    public var showsExpandedAvatars: Bool
    /// 合并媒体是否显示外部气泡，默认false
    public var showsBubble: Bool
    /// 合并媒体内容内边距
    public var contentInsets: UIEdgeInsets
    /// 展开和收起按钮位置，默认在首个媒体旁边
    public var buttonPlacement: WYChatMediaButtonPlacement
    /// 展开和收起按钮是否显示媒体数量，默认false
    public var showsItemCountInButton: Bool
    /// 展开和收起按钮宽度
    public var buttonWidth: CGFloat
    /// 展开和收起按钮圆角
    public var buttonCornerRadius: CGFloat
    /// 展开和收起按钮高度
    public var buttonHeight: CGFloat
    /// 按钮距离图片的间距
    public var buttonSpacing: CGFloat
    /// 展开和收起按钮字体
    public var buttonFont: UIFont
    /// 展开和收起按钮颜色
    public var buttonColor: UIColor
    /// 展开和收起按钮背景色
    public var buttonBackgroundColor: UIColor
    /// 展开按钮文字
    public var expandText: String
    /// 收起按钮文字
    public var collapseText: String
    /// 视频播放图标
    public var videoPlayImage: UIImage?
    /// 视频播放图标尺寸
    public var videoPlaySize: CGSize
    /// 视频播放图标颜色
    public var videoPlayColor: UIColor
    /// 是否自动打开内置媒体浏览器，默认true，设置mediaPreviewHandler后由宿主处理
    public var automaticallyPresentsBrowser: Bool
    /// 视频播放器的展示方式，默认全屏
    public var videoPresentationStyle: UIModalPresentationStyle
    /// 是否显示系统视频播放控件，默认true
    public var showsVideoPlaybackControls: Bool
    /// 媒体浏览器配置
    public var browser: WYPhotoBrowserConfigurationObjC
    public override convenience init() { self.init(WYChatMediaConfig()) }
    @nonobjc public init(_ value: WYChatMediaConfig) {
        presentation = value.presentation
        albumMoreItemIndex = value.albumMoreItemIndex
        cardSize = value.cardSize
        cornerRadius = value.cornerRadius
        expandedSpacing = value.expandedSpacing
        usesOriginalAspectRatio = value.usesOriginalAspectRatio
        maximumExpandedItemHeight = value.maximumExpandedItemHeight
        showsExpandedAvatars = value.showsExpandedAvatars
        showsBubble = value.showsBubble
        contentInsets = value.contentInsets
        buttonPlacement = value.buttonPlacement
        showsItemCountInButton = value.showsItemCountInButton
        buttonWidth = value.buttonWidth
        buttonCornerRadius = value.buttonCornerRadius
        buttonHeight = value.buttonHeight
        buttonSpacing = value.buttonSpacing
        buttonFont = value.buttonFont
        buttonColor = value.buttonColor
        buttonBackgroundColor = value.buttonBackgroundColor
        expandText = value.expandText
        collapseText = value.collapseText
        videoPlayImage = value.videoPlayImage
        videoPlaySize = value.videoPlaySize
        videoPlayColor = value.videoPlayColor
        automaticallyPresentsBrowser = value.automaticallyPresentsBrowser
        videoPresentationStyle = value.videoPresentationStyle
        showsVideoPlaybackControls = value.showsVideoPlaybackControls
        browser = wy_photoBrowserBridge(value.browser)
        super.init()
    }
    @nonobjc public func toValue() -> WYChatMediaConfig {
        var value = WYChatMediaConfig()
        value.presentation = presentation
        value.albumMoreItemIndex = albumMoreItemIndex
        value.cardSize = cardSize
        value.cornerRadius = cornerRadius
        value.expandedSpacing = expandedSpacing
        value.usesOriginalAspectRatio = usesOriginalAspectRatio
        value.maximumExpandedItemHeight = maximumExpandedItemHeight
        value.showsExpandedAvatars = showsExpandedAvatars
        value.showsBubble = showsBubble
        value.contentInsets = contentInsets
        value.buttonPlacement = buttonPlacement
        value.showsItemCountInButton = showsItemCountInButton
        value.buttonWidth = buttonWidth
        value.buttonCornerRadius = buttonCornerRadius
        value.buttonHeight = buttonHeight
        value.buttonSpacing = buttonSpacing
        value.buttonFont = buttonFont
        value.buttonColor = buttonColor
        value.buttonBackgroundColor = buttonBackgroundColor
        value.expandText = expandText
        value.collapseText = collapseText
        value.videoPlayImage = videoPlayImage
        value.videoPlaySize = videoPlaySize
        value.videoPlayColor = videoPlayColor
        value.automaticallyPresentsBrowser = automaticallyPresentsBrowser
        value.videoPresentationStyle = videoPresentationStyle
        value.showsVideoPlaybackControls = showsVideoPlaybackControls
        value.browser = WYPhotoBrowserObjC.convertConfiguration(browser)
        return value
    }
}

#endif
