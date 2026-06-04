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
        linkView?.textContainer.maximumNumberOfLines = 0 // 限制最多显示6行
        linkView?.wy_enableClickConfig()
        linkView?.isScrollEnabled = false
        contentView.addSubview(linkView!)
        linkView?.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
        }
        
        textView = UITextView()
        textView?.wy_enableClickConfig()
        textView?.textContainer.lineBreakMode = .byTruncatingTail; // 文本截断方式
        textView?.isScrollEnabled = false
        contentView.addSubview(textView!)
        textView?.snp.makeConstraints { make in
            make.top.equalTo(linkView!.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func reload(clickEffectColor: UIColor?, longPressMinimumDuration: TimeInterval, eventPenetration: Bool, useCustomFont: Bool, randomText: Bool) {
        
        var text: String = ""
        if randomText {
            text = String.wy_random(minimum: 280, maximum: 390)
        }else {
            text = "早知混成这样，不如找个对象，少妇一直是我的理想，她已有车有房，不用我去闯荡，吃着软饭是真的很香。关关雎鸠，在河之洲。窈窕淑女，君子好逑。参差荇菜，左右流之。窈窕淑女，寤寐求之。求之不得，寤寐思服。悠哉悠哉，辗转反侧。参差荇菜，左右采之。窈窕淑女，琴瑟友之。参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。漫步海边，脚下的沙砾带着白日阳光的余温，细腻而柔软。海浪层层叠叠地涌来，热情地亲吻沙滩，又恋恋不舍地退去，发出悦耳声响。海风肆意穿梭，咸湿气息钻进鼻腔，带来大海独有的韵味。抬眼望去，落日熔金，余晖将海面染成橙红，粼粼波光像是无数碎钻在闪烁。我沉醉其中，心也被这梦幻海景悄然填满。"
        }
        let block_tap: Any = ["左右", "韵味", "窈窕淑女", "参差荇菜"]
        let block_longPress: Any = ["左右", "沙滩", "海浪", "参差荇菜"]
        let delegate_tap: Any = ["钟鼓乐之", "韵味", "理想", "参差荇菜"]
        let delegate_longPress: Any = ["粼粼波光", "沙滩", "关关雎鸠", "参差荇菜"]
        
        linkView?.wy_clickEffectColor = clickEffectColor
        linkView?.wy_longPressMinimumDuration = longPressMinimumDuration
        linkView?.wy_eventPenetration = eventPenetration
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributedText.wy_lineSpacing(5)
        attributedText.wy_underline(color: .blue, rangeValue: block_tap)
        attributedText.wy_underline(color: .purple, rangeValue: block_longPress)
        attributedText.wy_underline(color: .orange, rangeValue: delegate_tap)
        attributedText.wy_underline(color: .green, rangeValue: delegate_longPress)
        let font: UIFont = useCustomFont ? UIFont(name: "NotoSans-Regular", size: 16)! : UIFont.boldSystemFont(ofSize: 16);
        attributedText.wy_setFont([font: attributedText.string])
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
        
        for view in [linkView, textView] {
            view?.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        }
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

extension WYTestTextViewCell: WYTextViewTouchDelegate {
    
    func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int) {
        wy_print("自定义代理，点击\ntext:\(text),index:\(index),range:\(range)")
    }
    
    func wy_textViewTextDidLongPress(_ textView: UITextView, text: String, range: NSRange, index: Int) {
        wy_print("自定义代理，长按\ntext:\(text),index:\(index),range:\(range)")
    }
}
