//
//  WYChatTextCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit

/// 文本消息内表情的播放方式
@objc public enum WYChatEmojiPlaybackMode: Int {
    /// 每条消息在当前聊天界面首次展示时播放一轮
    case firstDisplay
    /// 消息每次进入可见区域时播放一轮
    case everyDisplay
    /// 始终显示静态图
    case staticOnly
}

/// 文本聊天配置选项
public struct WYTextChatConfig {
    /// 动态表情刷新间隔，单位秒，0时关闭动图播放
    public var emojiAnimationFrameInterval: TimeInterval = 1.0 / 30.0
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
    /// 文本消息内表情的播放方式，默认仅首次展示时播放
    public var emojiPlaybackMode: WYChatEmojiPlaybackMode = .firstDisplay
    public init() {}
}

/// 文本消息Cell
open class WYChatTextCell: WYChatBasicCell {
    /// 文本控件
    public let textView: UITextView = {
        // 播放时仅重绘附件字形，避免逐帧重新布局文本。
        if #available(iOS 16.0, *) { return WYChatMessageTextView(usingTextLayoutManager: false) }
        return WYChatMessageTextView()
    }()
    let textState = WYChatTextCellPrivateState()

    override func wy_layoutContent(width maximum: CGFloat) { wy_textLayout(width: maximum) }

    override func wy_measureContent(_ view: UIView, width: CGFloat) -> CGSize? { wy_textMeasure(view, width: width) }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        wy_setupText()
    }

    open override func renderContent() { wy_renderText() }

    open override func prepareForReuse() {
        wy_endEmojiDisplay()
        super.prepareForReuse()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { wy_suspendEmojiPlayback() }
        else { wy_scheduleEmojiPlayback() }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
