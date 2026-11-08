//
//  WYChatTextCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit

/// 文本聊天配置选项
public struct WYTextChatConfig {
    /// 文本行数，0表示不限
    public var textMaximumNumberOfLines: Int = 0
    /// 文本字体
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(16, WYBasisKitConfig.defaultScreenPixels))
    /// 文本颜色
    public var textColor: UIColor = .label
    /// 行间距
    public var textLineSpacing: CGFloat = UIDevice.wy_screenHeight(4, WYBasisKitConfig.defaultScreenPixels)
    /// 是否支持选择文本，默认true
    public var isSelectable: Bool = true
    /// 自动识别的链接类型
    public var dataDetectorTypes: UIDataDetectorTypes = [.link, .phoneNumber]
    public init() {}
}

/// 文本消息Cell
open class WYChatTextCell: WYChatBasicCell {
    /// 文本控件
    public let textView: UITextView = UITextView()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        wy_setupText()
    }

    open override func renderContent() { wy_renderText() }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
