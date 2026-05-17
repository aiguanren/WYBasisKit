//
//  WYTestTextViewCell.swift
//  SwiftVerify
//
//  Created by guanren on 2026/5/17.
//

import UIKit
import SnapKit

class WYTestTextViewCell: UITableViewCell {
    
    var linkView: UITextView?
    
    var textView: UITextView?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        linkView = UITextView()
        linkView?.isEditable = false // 不可编辑
        linkView?.isSelectable = true // 必须为 YES 才能响应链接
        linkView?.dataDetectorTypes = UIDataDetectorTypes() // 关闭系统检测，手动控制样式
        linkView?.textContainer.lineFragmentPadding = 0 // 去除左右边距
        linkView?.isScrollEnabled = false
        linkView?.textContainer.lineBreakMode = .byTruncatingTail; // 文本截断方式
        linkView?.textContainer.maximumNumberOfLines = 0 // 限制最多显示6行
        linkView?.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        contentView.addSubview(linkView!)
        linkView?.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
        }
        
        textView = UITextView()
        textView?.isEditable = false // 不可编辑
        textView?.isSelectable = true // 必须为 YES 才能响应链接
        textView?.dataDetectorTypes = UIDataDetectorTypes() // 关闭系统检测，手动控制样式
        textView?.textContainer.lineFragmentPadding = 0 // 去除左右边距
        textView?.isScrollEnabled = false
        textView?.textContainer.maximumNumberOfLines = 0 // 限制最多显示8行
        textView?.textContainer.lineBreakMode = .byTruncatingTail; // 文本截断方式
        textView?.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        contentView.addSubview(textView!)
        textView?.snp.makeConstraints { make in
            make.top.equalTo(linkView!.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func reload(clickEffectColor: UIColor?, longPressEffectColor: UIColor?, enableLongPress: Bool, longPressMinimumDuration: TimeInterval, eventPenetration: Bool) {
        
        let text: String = "早知混成这样，不如找个对象，少妇一直是我的理想，她已有车有房，不用我去闯荡，吃着软饭是真的很香。关关雎鸠，在河之洲。窈窕淑女，君子好逑。参差荇菜，左右流之。窈窕淑女，寤寐求之。求之不得，寤寐思服。悠哉悠哉，辗转反侧。参差荇菜，左右采之。窈窕淑女，琴瑟友之。参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。漫步海边，脚下的沙砾带着白日阳光的余温，细腻而柔软。海浪层层叠叠地涌来，热情地亲吻沙滩，又恋恋不舍地退去，发出悦耳声响。海风肆意穿梭，咸湿气息钻进鼻腔，带来大海独有的韵味。抬眼望去，落日熔金，余晖将海面染成橙红，粼粼波光像是无数碎钻在闪烁。我沉醉其中，心也被这梦幻海景悄然填满。"
         
        let block_tap: Any = ["左右", "韵味", "窈窕淑女", "参差荇菜"]
        let block_longPress: Any = ["左右", "沙滩", "海浪", "参差荇菜"]
        let delegate_tap: Any = ["钟鼓乐之", "韵味", "理想", "参差荇菜"]
        let delegate_longPress: Any = ["粼粼波光", "沙滩", "关关雎鸠", "参差荇菜"]
        
        linkView?.wy_clickEffectColor = clickEffectColor
        linkView?.wy_longPressEffectColor = longPressEffectColor
        linkView?.wy_longPressMinimumDuration = longPressMinimumDuration
        linkView?.wy_eventPenetration = eventPenetration
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedText.wy_lineSpacing(5)
        attributedText.wy_underline(color: .blue, rangeValue: block_tap)
        attributedText.wy_underline(color: .purple, rangeValue: block_longPress)
        attributedText.wy_underline(color: .orange, rangeValue: delegate_tap)
        attributedText.wy_underline(color: .green, rangeValue: delegate_longPress)
        attributedText.wy_setFont([UIFont.boldSystemFont(ofSize: 16): attributedText.string])
        linkView?.attributedText = attributedText
        
        linkView?.wy_addTextTapHandler(rangeValue: block_tap) { textView, text, range, index in
            wy_print("自定义Block，点击\ntext:\(text),index:\(index),range:\(range)")
        }
        linkView?.wy_addTextTapDelegate(rangeValue: delegate_tap, delegate: self)
        linkView?.wy_addTextLongPressHandler(rangeValue: block_longPress) { textView, text, range, index in
            wy_print("自定义Block，长按\ntext:\(text),index:\(index),range:\(range)")
        }
        linkView?.wy_addTextLongPressDelegate(rangeValue: delegate_longPress, delegate: self)
        
        textView?.attributedText = attributedText
    }
    
    deinit {
        wy_print("WYTestTextViewCell release")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension WYTestTextViewCell: WYTextViewTouchDelegate, UITextViewDelegate {
    
    func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int) {
        wy_print("自定义代理，点击\ntext:\(text),index:\(index),range:\(range)")
    }
    
    func wy_textViewTextDidLongPress(_ textView: UITextView, text: String, range: NSRange, index: Int) {
        wy_print("自定义代理，长按\ntext:\(text),index:\(index),range:\(range)")
    }
    
    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        // 只处理链接类型的交互（可根据需要添加 .attachment 等）
        switch textItem.content {
        case .link(let url):
            wy_print("原生代理，点击\ntext:\(url.absoluteString)")
            return defaultAction
        default:
            // 其他类型（如附件）可以返回默认行为，或返回 nil 使用系统默认
            return defaultAction
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if #available(iOS 17.0, *) {} else {
            wy_print("原生代理，点击\ntext:\(URL.absoluteString)")
        }
        return false    // 阻止系统默认处理
    }
}
