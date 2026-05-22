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
        contentView.addSubview(textView!)
        textView?.snp.makeConstraints { make in
            make.top.equalTo(linkView!.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func reload(clickEffectColor: UIColor?, longPressEffectColor: UIColor?, longPressMinimumDuration: TimeInterval, eventPenetration: Bool, useCustomFont: Bool) {
        
        let text: String = String.wy_random(minimum: 200, maximum: 300)
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
