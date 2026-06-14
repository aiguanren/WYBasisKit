//
//  WYChatTextCell.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/14.
//

import UIKit
import SnapKit

/// 文本聊天配置选项
public struct WYTextChatConfig {
    
    /// basicCell配置选项
    public var basic: WYBasicChatConfig = WYBasicChatConfig()
    
    /// 单聊时气泡图距离昵称控件的偏移量
    public var bubbleOffsetForSingle: (sendor: CGPoint, receive: CGPoint) = (sendor: CGPoint(x: UIDevice.wy_screenWidth(12), y: 0), receive: CGPoint(x: -UIDevice.wy_screenWidth(12), y: 0))
    
    /// 群聊时气泡图距离昵称控件的偏移量
    public var bubbleOffsetForGroup: (sendor: CGPoint, receive: CGPoint) = (sendor: CGPoint(x: UIDevice.wy_screenWidth(12), y: 0), receive: CGPoint(x: -UIDevice.wy_screenWidth(12), y: 0))
    
    /// 气泡图距离对侧头像控件的间距
    public var bubbleMaxOffset: CGFloat = UIDevice.wy_screenWidth(5)
    
    /// 左侧(接收方)气泡图
    public var receiveBubbleImage: UIImage = UIImage.wy_find("WYChatTextBubblesRight", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: UIDevice.wy_screenWidth(35), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(10), right: UIDevice.wy_screenWidth(10)), resizingMode: .stretch)
    
    /// 右侧(发送方)气泡图
    public var sendorBubbleImage: UIImage = UIImage.wy_find("WYChatTextBubblesLeft", inBundle: WYChatSourceBundle).withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: UIDevice.wy_screenWidth(35), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(10), right: UIDevice.wy_screenWidth(10)), resizingMode: .stretch)
    
    /// 左侧(接收方)气泡背景色
    public var receiveBubbleColor: UIColor? = .white
    
    /// 右侧(发送方)气泡背景色
    public var sendorBubbleColor: UIColor? = .wy_rgb(169, 233, 121)
    
    /// 气泡图距离cell底部的间距
    public var bubbleOffsetForBottom: CGFloat = -UIDevice.wy_screenWidth(15)
    
    /// 文本距离气泡内部的边界距离
    public var textEdgeInsets: (sendor: UIEdgeInsets, receive: UIEdgeInsets) = (
        
        sendor: UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(10), right: UIDevice.wy_screenWidth(15)),
        
        receive: UIEdgeInsets(top: UIDevice.wy_screenWidth(10), left: UIDevice.wy_screenWidth(15), bottom: UIDevice.wy_screenWidth(10), right: UIDevice.wy_screenWidth(10)))
    
    /// 字符行数限制(0为不限制行数)
    public var textMaximumNumberOfLines: Int = 0
    
    /// 文本字体、字号
    public var textFont: UIFont = .systemFont(ofSize: UIFont.wy_fontSize(15))
    
    /// 文本字体颜色
    public var textColor: UIColor = .black
    
    /// 输入框文本行间距
    public var textLineSpacing: CGFloat = UIDevice.wy_screenWidth(5)
    
    public init() {}
}

public class WYChatTextCell: WYChatBasicCell {
    
    public lazy var bubblesView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        contentView.addSubview(imageView)
        return imageView
    }()
    
    public lazy var textView: UITextView = {
        let textView: UITextView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.bounces = false
        textView.isEditable = false
        textView.textContainer.maximumNumberOfLines = chatTextConfig.textMaximumNumberOfLines
        bubblesView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return textView
    }()
    
    public override var message: WYChatMessageModel {
        didSet {
            updateContent(config: chatTextConfig)
            updateOtherConstraints(bubblesView)
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    /// 数据(页面)刷新
    public func updateContent(config: WYTextChatConfig) {
        super.updateContent(config: config.basic)
        
        bubblesView.tintColor = message.isSender(userID) ? config.sendorBubbleColor : config.receiveBubbleColor
        bubblesView.image = (message.isSender(userID) ? config.sendorBubbleImage : config.receiveBubbleImage)
        
        textView.attributedText = sharedEmojiAttributed(string: message.content.text ?? "")
        
        // textView文本宽度
        let textWidth: CGFloat = textView.attributedText.wy_calculateWidth(controlHeight: textView.font?.lineHeight ?? 0)
        
        // textView显示行数是否大于1
        let areMultipleRows: Bool = (textWidth > sharedTextMaxWidth() + 1)
        
        if message.isSender(userID) {
            if areMultipleRows {
                textView.textContainerInset = chatTextConfig.textEdgeInsets.sendor
            }else {
                textView.textContainerInset = UIEdgeInsets(top: (config.basic.avatarSize.height - config.textFont.lineHeight) / 2, left: chatTextConfig.textEdgeInsets.sendor.left, bottom: (config.basic.avatarSize.height - config.textFont.lineHeight) / 2, right: chatTextConfig.textEdgeInsets.sendor.right)
            }
        }else {
            if areMultipleRows {
                textView.textContainerInset = chatTextConfig.textEdgeInsets.receive
            }else {
                textView.textContainerInset = UIEdgeInsets(top: (config.basic.avatarSize.height - config.textFont.lineHeight) / 2, left: chatTextConfig.textEdgeInsets.receive.left, bottom: (config.basic.avatarSize.height - config.textFont.lineHeight) / 2, right: chatTextConfig.textEdgeInsets.receive.right)
            }
        }
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        bubblesView.snp.remakeConstraints { make in
            make.height.greaterThanOrEqualTo(avatarView)
            if message.isSender(userID) {
                
                make.left.greaterThanOrEqualToSuperview().offset((chatTextConfig.basic.avatarSize.width + abs(chatTextConfig.basic.avatarOffset.receive.x) + chatTextConfig.bubbleMaxOffset))
                if message.group == nil {
                    make.right.equalTo(nicknameView).offset(chatTextConfig.bubbleOffsetForSingle.sendor.x)
                    make.top.equalTo(nicknameView.snp.bottom).offset(chatTextConfig.bubbleOffsetForSingle.sendor.y)
                    
                }else {
                    make.right.equalTo(nicknameView).offset(chatTextConfig.bubbleOffsetForGroup.sendor.x)
                    make.top.equalTo(nicknameView.snp.bottom).offset(chatTextConfig.bubbleOffsetForGroup.sendor.y)
                }
            }else {
                make.right.lessThanOrEqualToSuperview().offset(-(chatTextConfig.basic.avatarSize.width + abs(chatTextConfig.basic.avatarOffset.sendor.x) + chatTextConfig.bubbleMaxOffset))
                if message.group == nil {
                    make.left.equalTo(nicknameView).offset(chatTextConfig.bubbleOffsetForSingle.receive.x)
                    make.top.equalTo(nicknameView.snp.bottom).offset(chatTextConfig.bubbleOffsetForSingle.receive.y)
                }else {
                    make.right.equalTo(nicknameView).offset(chatTextConfig.bubbleOffsetForGroup.receive.x)
                    make.top.equalTo(nicknameView.snp.bottom).offset(chatTextConfig.bubbleOffsetForGroup.receive.y)
                }
            }
            make.bottom.equalToSuperview().offset(chatTextConfig.bubbleOffsetForBottom)
        }
    }
    
    // 根据传入的表情字符串生成富文本，例如字符串 "哈哈[哈哈]" 会生成 "哈哈😄"
    public func sharedEmojiAttributed(string: String) -> NSAttributedString {
        let attributed: NSMutableAttributedString = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: string, textColor: chatTextConfig.textColor, textFont: chatTextConfig.textFont, emojiTable: emojiViewConfig.emojiSource, sourceBundle: emojiViewConfig.emojiBundle, pattern: inputBarConfig.emojiPattern)
        
        attributed.wy_lineSpacing(chatTextConfig.textLineSpacing, alignment: .left)
        
        return attributed
    }
    
    // 获取textView的最大显示宽度
    public func sharedTextMaxWidth() -> CGFloat {
        if message.isSender(userID) {
            return sharedContentMaxWidth() - abs(chatTextConfig.textEdgeInsets.sendor.left) - abs(chatTextConfig.textEdgeInsets.sendor.right)
        }else {
            return sharedContentMaxWidth() - abs(chatTextConfig.textEdgeInsets.receive.left) - abs(chatTextConfig.textEdgeInsets.receive.right)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
