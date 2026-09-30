//
//  WYEmojiPreviewView.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/4/27.
//

import UIKit

public struct WYEmojiPreviewConfig {
    
    /// Emoji表情是否需要支持长按预览详情
    public var show: Bool = true
    
    /// 表情预览控件的背景图
    public var backgroundImage: UIImage = UIImage.wy_find("WYChatEmojiPreview", inBundle: WYChatSourceBundle)
    
    /// 表情预览控件的size
    public var previewSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(80), height: UIDevice.wy_screenWidth(120))
    
    /// 表情预览控件内Emoji的size
    public var emojiSize: CGSize = CGSize(width: UIDevice.wy_screenWidth(30), height: UIDevice.wy_screenWidth(30))
    
    /// Emoji距离表情预览控件顶部的间距
    public var emojiTopOffset: CGFloat = UIDevice.wy_screenWidth(16)
    
    /// 表情预览控件内文本控件的字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(12))
    
    /// 表情预览控件内文本控件的字体颜色
    public var textColor: UIColor = .wy_rgb(120, 120, 120)
    
    /// 表情预览控件内文本控件顶部距离Emoji控件底部的间距
    public var textTopOffsetWithEmoji: CGFloat = UIDevice.wy_screenWidth(5)

    public init() {}
}

private var previewView: WYEmojiPreviewView?
public class WYEmojiPreviewView: UIImageView {

    /// 表情图控件(长按拖动切换表情时只更新它的图片)
    private let emojiView: UIImageView = UIImageView()

    /// 表情文本控件(长按拖动切换表情时只更新它的文本)
    private let textView: UILabel = UILabel()

    init(emoji: String) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        alpha = 0.0
        image = emojiViewConfig.previewConfig.backgroundImage

        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(emojiViewConfig.previewConfig.emojiSize)
            make.top.equalToSuperview().offset(emojiViewConfig.previewConfig.emojiTopOffset)
        }
        updateContent(emoji)

        textView.textColor = emojiViewConfig.previewConfig.textColor
        textView.font = emojiViewConfig.previewConfig.textFont
        textView.textAlignment = .center
        textView.adjustsFontSizeToFitWidth = true
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(UIDevice.wy_screenWidth(5))
            make.right.equalToSuperview().offset(UIDevice.wy_screenWidth(-5))
            make.top.equalTo(emojiView.snp.bottom).offset(emojiViewConfig.previewConfig.textTopOffsetWithEmoji)
        }
    }

    /// 更新预览的内容(依次尝试gif、apng动图，两者都没有时展示静态图)
    private func updateContent(_ emoji: String) {
        
        if let gifInfo: WYGifInfo = UIImage.wy_animatedParse(.GIF, name: emoji, inBundle: emojiViewConfig.emojiBundle) {
            emojiView.image = gifInfo.animatedImage
            
        }else if let gifInfo: WYGifInfo = UIImage.wy_animatedParse(.APNG, name: "apng_"+emoji, inBundle: emojiViewConfig.emojiBundle) {
            emojiView.image = gifInfo.animatedImage
            
        }else {
            emojiView.image = UIImage.wy_find(emoji, inBundle: emojiViewConfig.emojiBundle)
        }

        textView.text = WYLocalized(emoji.wy_substring(from: 1, to: emoji.count - 1), table: WYBasisKitConfig.kitLocalizableTable)
    }
    
    @discardableResult
    public static func show(emoji: String, according: UIView) ->WYEmojiPreviewView?  {

        releaseAll()

        guard emojiViewConfig.previewConfig.show == true else {
            return nil
        }

        previewView = WYEmojiPreviewView(emoji: emoji)
        UIViewController.wy_currentController()?.view.addSubview(previewView!)
        let offset: CGPoint = previewOffset(according: according, superView: previewView!.superview!)
        previewView?.snp.makeConstraints({ make in
            make.size.equalTo(emojiViewConfig.previewConfig.previewSize)
            make.top.equalToSuperview().offset(offset.y)
            make.left.equalToSuperview().offset(offset.x)
        })

        previewView?.show()

        return previewView
    }

    /// 更新预览浮层的内容和位置(长按拖动切换表情时用，浮层不存在时不动作)
    public static func update(emoji: String, according: UIView) {

        guard let existPreview: WYEmojiPreviewView = previewView, let superView: UIView = existPreview.superview else {
            return
        }

        existPreview.updateContent(emoji)

        let offset: CGPoint = previewOffset(according: according, superView: superView)
        existPreview.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(offset.y)
            make.left.equalToSuperview().offset(offset.x)
        }
    }

    /// 轻量隐藏或恢复预览浮层(长按拖动滑出表情有效区时隐藏，滑回有效区恢复，不销毁浮层)
    public static func setHidden(_ hidden: Bool) {
        previewView?.isHidden = hidden
    }

    /// 依据锚定控件计算预览浮层的偏移(浮层显示在锚定控件正上方水平居中)
    private static func previewOffset(according: UIView, superView: UIView) -> CGPoint {
        let offset: CGPoint = according.convert(according.frame.origin, to: superView)
        return CGPoint(x: offset.x + (according.wy_width / 2) - (emojiViewConfig.previewConfig.previewSize.width / 2), y: offset.y - emojiViewConfig.previewConfig.previewSize.height)
    }
    
    private func show() {
        UIView.animate(withDuration: 0.25) {
            previewView?.alpha = 1.0
        }
    }
    
    public static func dismiss() {
        
        guard previewView != nil else {
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            previewView?.alpha = 0.0
        }completion: { _ in
            releaseAll()
        }
    }
    
    private static func releaseAll() {
        previewView?.wy_removeAllSubviews()
        previewView?.removeFromSuperview()
        previewView = nil
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView: UIView? = super.hitTest(point, with: event)
        if hitView != previewView {
            WYEmojiPreviewView.dismiss()
        }
        return hitView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
