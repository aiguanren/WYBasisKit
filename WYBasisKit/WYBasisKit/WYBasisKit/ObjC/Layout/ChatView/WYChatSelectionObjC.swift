//
//  WYChatSelectionObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

#if canImport(WYBasisKitSwift)
import UIKit
import WYBasisKitSwift

/// 多选操作与转发外观
@objc(WYChatSelectionConfig)
@objcMembers public class WYChatSelectionConfigObjC: NSObject {
    /// 最多可选择的消息数，0表示不限
    public var maximumCount: Int
    /// 是否允许长按选择连续区间，默认true
    public var allowsRangeSelection: Bool
    /// 区间选择菜单标题
    public var rangeTitle: String
    /// 工具条背景色
    public var backgroundColor: UIColor
    /// 工具条高度
    public var height: CGFloat
    /// 工具条内边距
    public var insets: UIEdgeInsets
    /// 工具条按钮间距
    public var spacing: CGFloat
    /// 工具条按钮字体
    public var font: UIFont
    /// 普通操作颜色
    public var tintColor: UIColor
    /// 删除操作颜色
    public var deleteColor: UIColor
    /// 是否显示删除按钮，默认true
    public var showsDeleteButton: Bool
    /// 是否显示转发按钮，默认true
    public var showsForwardButton: Bool
    /// 是否显示取消按钮，默认true
    public var showsCancelButton: Bool
    /// 可用转发形式，空数组时禁用内置转发入口
    public var forwardModes: [NSNumber]
    /// 逐条转发菜单标题
    public var individualTitle: String
    /// 合并转发菜单标题
    public var mergedTitle: String
    /// 合并记录默认标题
    public var recordsTitle: String
    /// 是否显示多选指示图标，默认true
    public var showsIndicator: Bool
    /// 多选指示图标尺寸
    public var indicatorSize: CGSize
    /// 多选指示图标周围间距
    public var indicatorInsets: UIEdgeInsets
    /// 选中图标
    public var selectedImage: UIImage?
    /// 未选中图标
    public var unselectedImage: UIImage?
    /// 选中图标颜色
    public var selectedColor: UIColor
    /// 未选中图标颜色
    public var unselectedColor: UIColor
    /// 是否使用模板方式渲染多选图标，默认true
    public var rendersIndicatorAsTemplate: Bool
    public override convenience init() { self.init(WYChatSelectionConfig()) }
    @nonobjc public init(_ value: WYChatSelectionConfig) {
        maximumCount = value.maximumCount
        allowsRangeSelection = value.allowsRangeSelection
        rangeTitle = value.rangeTitle
        backgroundColor = value.backgroundColor
        height = value.height
        insets = value.insets
        spacing = value.spacing
        font = value.font
        tintColor = value.tintColor
        deleteColor = value.deleteColor
        showsDeleteButton = value.showsDeleteButton
        showsForwardButton = value.showsForwardButton
        showsCancelButton = value.showsCancelButton
        forwardModes = value.forwardModes.map { NSNumber(value: $0.rawValue) }
        individualTitle = value.individualTitle
        mergedTitle = value.mergedTitle
        recordsTitle = value.recordsTitle
        showsIndicator = value.showsIndicator
        indicatorSize = value.indicatorSize
        indicatorInsets = value.indicatorInsets
        selectedImage = value.selectedImage
        unselectedImage = value.unselectedImage
        selectedColor = value.selectedColor
        unselectedColor = value.unselectedColor
        rendersIndicatorAsTemplate = value.rendersIndicatorAsTemplate
        super.init()
    }
    @nonobjc public func toValue() -> WYChatSelectionConfig {
        var value = WYChatSelectionConfig()
        value.maximumCount = maximumCount
        value.allowsRangeSelection = allowsRangeSelection
        value.rangeTitle = rangeTitle
        value.backgroundColor = backgroundColor
        value.height = height
        value.insets = insets
        value.spacing = spacing
        value.font = font
        value.tintColor = tintColor
        value.deleteColor = deleteColor
        value.showsDeleteButton = showsDeleteButton
        value.showsForwardButton = showsForwardButton
        value.showsCancelButton = showsCancelButton
        value.forwardModes = forwardModes.compactMap { WYChatForwardMode(rawValue: $0.intValue) }
        value.individualTitle = individualTitle
        value.mergedTitle = mergedTitle
        value.recordsTitle = recordsTitle
        value.showsIndicator = showsIndicator
        value.indicatorSize = indicatorSize
        value.indicatorInsets = indicatorInsets
        value.selectedImage = selectedImage
        value.unselectedImage = unselectedImage
        value.selectedColor = selectedColor
        value.unselectedColor = unselectedColor
        value.rendersIndicatorAsTemplate = rendersIndicatorAsTemplate
        return value
    }
}

public extension WYChatView {
    /// 转发请求，参数为转发形式及按列表顺序排列的原消息快照
    @objc(forwardHandler) var forwardHandlerObjC: ((_ mode: WYChatForwardMode, _ messages: [WYChatMessageModelObjC]) -> Void)? {
        get { forwardHandler.map { handler in { mode, messages in handler(mode, messages.map { $0.toValue() }) } } }
        set { forwardHandler = newValue.map { handler in { mode, messages in handler(mode, messages.map(WYChatMessageModelObjC.init)) } } }
    }
    /// 设置多选消息，超出数量上限或包含无效消息ID时保持原选择，参数为消息ID
    @objc(selectMessages) var selectMessagesObjC: @convention(block) (_ messageIDs: [String]) -> Bool { { [self] identifiers in selectMessages(identifiers) } }
    /// 在当前选择中加入连续区间，参数为区间起点和终点消息ID
    @objc(selectMessageRange) var selectMessageRangeObjC: @convention(block) (_ firstMessageID: String, _ lastMessageID: String) -> Bool { { [self] first, last in selectMessages(from: first, through: last) } }
    /// 组装转发消息，不加入当前列表，参数为原消息ID、转发形式和合并记录标题
    @objc(makeForwardMessages) var makeForwardMessagesObjC: @convention(block) (_ messageIDs: [String], _ mode: WYChatForwardMode, _ title: String?) -> [WYChatMessageModelObjC] {
        { [self] identifiers, mode, title in makeForwardMessages(identifiers, mode: mode, title: title).map(WYChatMessageModelObjC.init) }
    }
}
#endif
