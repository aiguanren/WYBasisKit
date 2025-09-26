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
    
    /// 预览详情时图片展示类型
    public var style: WYEmojiPreviewStyle = .default
    
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

@frozen public enum WYEmojiPreviewStyle: Int {
    
    /// 默认静态图展示(png、jpg、jpeg等格式的静态图)
    case `default` = 0
    /// gif格式图片展示
    case gif
    /// apng格式图片展示(为了防止文件名冲突，apng格式图片需要自行拼接为：apng_[666].png样式格式)
    case apng
    /// 其他格式图片展示(需要自己实现相应代理后展示)
    case other
}

private var previewView: WYEmojiPreviewView?
public class WYEmojiPreviewView: UIImageView {
    
    init(emoji: String, according: UIView, handler: @escaping ((_ imageName: String, _ imageView: UIImageView) -> Void)) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        alpha = 0.0
        image = emojiViewConfig.previewConfig.backgroundImage
        
        let emojiView: UIImageView = UIImageView()
        addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(emojiViewConfig.previewConfig.emojiSize)
            make.top.equalToSuperview().offset(emojiViewConfig.previewConfig.emojiTopOffset)
        }
        switch emojiViewConfig.previewConfig.style {
        case .default:
            emojiView.image = UIImage.wy_find(emoji, inBundle: emojiViewConfig.emojiBundle)
            break
        case .gif:
            emojiView.image = UIImage.wy_animatedParse(.GIF, name: emoji, inBundle: emojiViewConfig.emojiBundle)?.animatedImage
            break
        case .apng:
            emojiView.image = UIImage.wy_animatedParse(.APNG, name: "apng_"+emoji, inBundle: emojiViewConfig.emojiBundle)?.animatedImage
            break
        case .other:
            handler(emoji, emojiView)
            break
        }
        
        let textView: UILabel = UILabel()
        textView.text = WYLocalized(emoji.wy_substring(from: 1, to: emoji.count - 2))
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
    
    @discardableResult
    public static func show(emoji: String, according: UIView, handler: @escaping ((_ imageName: String, _ imageView: UIImageView) -> Void)) ->WYEmojiPreviewView?  {
        
        release()
        
        guard emojiViewConfig.previewConfig.show == true else {
            return nil
        }
        
        previewView = WYEmojiPreviewView(emoji: emoji, according: according, handler: handler)
        UIViewController.wy_currentController()?.view.addSubview(previewView!)
        let offset: CGPoint = according.convert(according.frame.origin, to: previewView?.superview!)
        previewView?.snp.makeConstraints({ make in
            make.size.equalTo(emojiViewConfig.previewConfig.previewSize)
            make.top.equalToSuperview().offset(offset.y - emojiViewConfig.previewConfig.previewSize.height)
            make.left.equalToSuperview().offset(offset.x + (according.wy_width / 2) - (emojiViewConfig.previewConfig.previewSize.width / 2))
        })
        
        previewView?.show()
        
        return previewView
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
            release()
        }
    }
    
    private static func release() {
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
