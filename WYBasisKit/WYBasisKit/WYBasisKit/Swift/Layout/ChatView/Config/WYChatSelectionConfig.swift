//
//  WYChatSelectionConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 消息转发形式
@objc public enum WYChatForwardMode: Int { case individual, merged }

/// 多选指示图标所在的一侧
@objc public enum WYChatSelectionIndicatorPosition: Int { case leading, trailing }

/// 浮动区间选择按钮外观
public struct WYChatRangeButtonConfig {
    /// 未设置borderColor时的边框透明度
    public var defaultBorderOpacity: CGFloat = 0.25
    /// 浮动区间选择按钮图标和文字间距
    public var imageSpacing: CGFloat = 6
    /// 按钮文案，nil时使用selection.rangeTitle
    public var title: String?
    /// 按钮字体
    public var font: UIFont = .preferredFont(forTextStyle: .subheadline)
    /// 文案和模板图标颜色
    public var tintColor: UIColor = .systemIndigo
    /// 按钮背景色
    public var backgroundColor: UIColor = .secondarySystemGroupedBackground
    /// 按钮圆角
    public var cornerRadius: CGFloat = 12
    /// 按钮边框宽度，0表示隐藏边框
    public var borderWidth: CGFloat = 1
    /// 按钮边框颜色，nil时使用淡化后的tintColor
    public var borderColor: UIColor?
    /// 按钮与列表边缘的间距
    public var edgeInset: CGFloat = 8
    /// 按钮内容内边距
    public var contentInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    /// 列表上缘按钮的图标，nil表示隐藏图标
    public var topImage: UIImage? = UIImage(systemName: "arrow.down")
    /// 列表下缘按钮的图标，nil表示隐藏图标
    public var bottomImage: UIImage? = UIImage(systemName: "arrow.up")

    public init() {}
}

/// 多选操作与转发外观
public struct WYChatSelectionConfig {
    /// 多选工具条按钮的排列方式
    public var toolbarDistribution: UIStackView.Distribution = .fillEqually
    /// 多选状态图标的显示方式
    public var indicatorContentMode: UIView.ContentMode = .scaleAspectFit
    /// 格式化多选转发按钮的标题和消息数
    public var forwardCountTitle: ((_ title: String, _ count: Int) -> String)? = nil
    /// 多选工具条的转发按钮是否显示消息数
    public var showsForwardCount: Bool = true
    /// 浮动区间选择按钮最小高度
    public var rangeButtonMinimumHeight: CGFloat = 44
    /// 最多可选择的消息数，0表示不限
    public var maximumCount: Int = 0
    /// 是否允许选择连续区间，默认true
    public var allowsRangeSelection = true
    /// 是否显示浮动的区间选择按钮，默认true
    public var showsRangeButton = true
    /// 浮动区间选择按钮外观
    public var rangeButton = WYChatRangeButtonConfig()
    /// 区间选择菜单标题及浮动按钮的默认文案
    public var rangeTitle = WYLocalized("选择到这里", table: WYBasisKitConfig.kitLocalizableTable)
    /// 工具条背景色
    public var backgroundColor: UIColor = .secondarySystemBackground
    /// 工具条高度
    public var height = UIDevice.wy_screenHeight(60, WYBasisKitConfig.defaultScreenPixels)
    /// 工具条内边距
    public var insets = UIEdgeInsets.zero
    /// 工具条按钮间距
    public var spacing: CGFloat = 0
    /// 工具条按钮字体
    public var font = UIFont.systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 普通操作颜色
    public var tintColor: UIColor = .systemIndigo
    /// 删除操作颜色
    public var deleteColor: UIColor = .systemRed
    /// 是否显示删除按钮，默认true
    public var showsDeleteButton = true
    /// 是否显示转发按钮，默认true
    public var showsForwardButton = true
    /// 是否显示取消按钮，默认true
    public var showsCancelButton = true
    /// 可用转发形式，空数组时禁用内置转发入口
    public var forwardModes: [WYChatForwardMode] = [.individual, .merged]
    /// 逐条转发菜单标题
    public var individualTitle = WYLocalized("逐条转发", table: WYBasisKitConfig.kitLocalizableTable)
    /// 合并转发菜单标题
    public var mergedTitle = WYLocalized("合并转发", table: WYBasisKitConfig.kitLocalizableTable)
    /// 合并记录默认标题
    public var recordsTitle = WYLocalized("聊天记录", table: WYBasisKitConfig.kitLocalizableTable)
    /// 是否显示多选指示图标，默认true
    public var showsIndicator: Bool = true
    /// 多选指示图标的位置，默认在消息列表起始侧
    public var indicatorPosition: WYChatSelectionIndicatorPosition = .leading
    /// 多选指示图标尺寸
    public var indicatorSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels))
    /// 多选指示图标周围间距
    public var indicatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), bottom: 0, right: UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels))
    /// 选中图标，默认使用圆形勾选模板图标
    public var selectedImage: UIImage? = WYChatSelectionConfig.defaultSelectedImage
    /// 未选中图标，默认使用空心圆形模板图标
    public var unselectedImage: UIImage? = WYChatSelectionConfig.defaultUnselectedImage
    /// 选中图标颜色
    public var selectedColor: UIColor = .systemIndigo
    /// 未选中图标颜色
    public var unselectedColor: UIColor = .systemGray
    /// 是否强制使用模板方式渲染多选图标，默认false
    public var rendersIndicatorAsTemplate: Bool = false

    private static let defaultSelectedImage = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
    private static let defaultUnselectedImage = UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(weight: .light))?.withRenderingMode(.alwaysTemplate)

    public init() {}
}
