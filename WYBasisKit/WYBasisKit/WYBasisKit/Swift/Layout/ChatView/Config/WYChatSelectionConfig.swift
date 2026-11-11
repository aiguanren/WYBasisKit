//
//  WYChatSelectionConfig.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 消息转发形式
@objc public enum WYChatForwardMode: Int { case individual, merged }

/// 多选操作与转发外观
public struct WYChatSelectionConfig {
    /// 最多可选择的消息数，0表示不限
    public var maximumCount: Int = 0
    /// 是否允许长按选择连续区间，默认true
    public var allowsRangeSelection = true
    /// 区间选择菜单标题
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
    /// 多选指示图标尺寸
    public var indicatorSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels), height: UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels))
    /// 多选指示图标周围间距
    public var indicatorInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: UIDevice.wy_screenWidth(8, WYBasisKitConfig.defaultScreenPixels), bottom: 0, right: UIDevice.wy_screenWidth(12, WYBasisKitConfig.defaultScreenPixels))
    /// 选中图标
    public var selectedImage: UIImage? = UIImage(systemName: "checkmark.circle.fill")
    /// 未选中图标
    public var unselectedImage: UIImage? = UIImage(systemName: "circle")
    /// 选中图标颜色
    public var selectedColor: UIColor = .systemIndigo
    /// 未选中图标颜色
    public var unselectedColor: UIColor = .tertiaryLabel
    /// 是否使用模板方式渲染多选图标，默认true
    public var rendersIndicatorAsTemplate: Bool = true
    public init() {}
}
