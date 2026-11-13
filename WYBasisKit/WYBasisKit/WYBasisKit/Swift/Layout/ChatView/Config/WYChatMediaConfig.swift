//
//  WYChatMediaConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 宿主选择结果的消息排布
@objc public enum WYChatMediaPresentation: Int { case individual, merged }

/// 媒体展开与收起按钮位置
@objc public enum WYChatMediaButtonPlacement: Int { case beside, below }

/// 图片和视频消息展示配置
public struct WYChatMediaConfig {
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
    public var videoPlayImage: UIImage? = UIImage(systemName: "play.circle.fill")
    /// 视频播放图标尺寸
    public var videoPlaySize: CGSize = CGSize(width: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(40, WYBasisKitConfig.defaultScreenPixels))
    /// 视频播放图标颜色
    public var videoPlayColor: UIColor = .white
    /// 是否自动打开内置媒体浏览器，默认true，设置mediaPreviewHandler后由宿主处理
    public var automaticallyPresentsBrowser: Bool = true
    /// 视频播放器的展示方式，默认全屏
    public var videoPresentationStyle: UIModalPresentationStyle = .fullScreen
    /// 是否显示系统视频播放控件，默认true
    public var showsVideoPlaybackControls: Bool = true
    /// 媒体浏览器配置
    public var browser: WYPhotoBrowserConfiguration = { var value = WYPhotoBrowserConfiguration(); value.allowsLoopScrolling = true; value.stackedCardCyclesForward = true; return value }()
    public init() {}
}
