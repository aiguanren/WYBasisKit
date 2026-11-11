//
//  WYChatQuoteView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/11/10.
//

import UIKit

/// 消息与输入框共用的引用预览
public class WYChatQuoteView: UIView {
    /// 引用快照，nil时隐藏预览
    public var quote: WYChatQuoteModel? { didSet { if !state.isUpdating { wy_renderQuote() } } }
    /// 引用外观
    public var style = WYChatQuoteStyle() { didSet { if !state.isUpdating { wy_renderQuote() } } }
    /// 引用发送者控件
    public let titleView = UILabel()
    /// 引用摘要控件
    public let textView = UILabel()
    /// 引用缩略图控件
    public let thumbnailView = UIImageView()
    /// 引用关闭控件
    public let closeButton = UIButton(type: .system)
    /// 点击引用内容
    public var tapHandler: (() -> Void)?
    /// 关闭引用
    public var closeHandler: (() -> Void)?
    /// 自定义图片加载，参数为资源、目标控件及被引用消息ID
    public var imageLoader: ((_ asset: WYChatAssetsModel, _ imageView: UIImageView, _ messageID: String) -> Void)?

    /**
     更新引用内容与外观
     @param quote 引用快照，nil时隐藏预览
     @param style 引用外观
     @param imageLoader 图片加载回调，参数为资源、目标控件及被引用消息ID
     */
    public func update(quote: WYChatQuoteModel?, style: WYChatQuoteStyle, imageLoader: ((_ asset: WYChatAssetsModel, _ imageView: UIImageView, _ messageID: String) -> Void)? = nil) {
        state.isUpdating = true
        self.quote = quote
        self.style = style
        self.imageLoader = imageLoader
        state.asset = nil
        state.isUpdating = false
        wy_renderQuote()
    }

    public override init(frame: CGRect) { super.init(frame: frame); wy_setupQuote() }
    public required init?(coder: NSCoder) { super.init(coder: coder); wy_setupQuote() }
    public override func layoutSubviews() { super.layoutSubviews(); wy_layoutQuote() }
    public override func sizeThatFits(_ size: CGSize) -> CGSize { wy_quoteSize(width: size.width) }
    public override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: wy_quoteSize(width: bounds.width).height) }

    internal let state = WYChatQuoteViewPrivateState()
    internal var isMeasuring = false
    @objc func wy_closeQuote() { closeHandler?() }
    @objc func wy_tapQuote() { tapHandler?() }
}
