//
//  WYTestRichTextController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/1/15.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

class WYTestRichTextController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white

        let scrollView: UIScrollView = UIScrollView()
        view.addSubview(scrollView);
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let label = UILabel()
        let str = "治性之道，必审己之所有余而强其所不足，盖聪明疏通者戒于太察，寡闻少见者戒于壅蔽，勇猛刚强者戒于太暴，仁爱温良者戒于无断，湛静安舒者戒于后时，广心浩大者戒于遗忘。必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"
        label.numberOfLines = 0
        let attribute = NSMutableAttributedString(string: str)
        
        attribute.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 20), range: NSMakeRange(0, str.count))
        attribute.wy_colorsOfRanges([[UIColor.blue: "勇猛刚强"], [UIColor.orange: "仁爱温良者戒于无断"], [UIColor.purple: "安舒"], [UIColor.magenta: "必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"]])
        attribute.wy_lineSpacing(15, subString: attribute.string)
        
        label.attributedText = attribute
        label.wy_clickEffectColor = .green
        label.wy_addRichText(strings: ["勇猛刚强", "仁爱温良者戒于无断", "安舒", "必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"]) { [weak self] (string, range, index) in
            //wy_print("string = \(string), range = \(range), index = \(index)")
            
            if string == "勇猛刚强" {
                WYActivity.showInfo("string = \(string) range = \(range) index = \(index)", in: self?.view, position: .middle)
            }
            if string == "仁爱温良者戒于无断" {
                WYActivity.showInfo("string = \(string) range = \(range) index = \(index)", in: self?.view, position: .top)
            }
            if string == "安舒" {
                WYActivity.showInfo("string = \(string) range = \(range) index = \(index)", in: self?.view, position: .bottom)
            }
        }
        label.wy_addRichText(strings: ["勇猛刚强", "仁爱温良者戒于无断", "安舒", "必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。"], delegate: self)
        scrollView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight + 20)
        }
        
        let emojiLabel = UILabel()
        emojiLabel.font = .systemFont(ofSize: 18)
        emojiLabel.numberOfLines = 0
        emojiLabel.backgroundColor = .white
        emojiLabel.textColor = .black
        let emojiLabelAttributed = NSMutableAttributedString.wy_convertEmojiAttributed(emojiString: "Hello，这是一个测试表情匹配的UILabel，现在开始匹配，喝彩[喝彩] 唇[唇]  爱心[爱心] 三个表情，看见了吗，他可以用在即时通讯等需要表情匹配的地方，嘻嘻，哈哈", textColor: emojiLabel.textColor, textFont: emojiLabel.font, emojiTable: ["[喝彩]","[唇]","[爱心]"])
        emojiLabelAttributed.wy_lineSpacing(5)
        emojiLabel.attributedText = emojiLabelAttributed
        scrollView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
        }
        
        let marginLabel = UILabel()
        marginLabel.text = "测试内边距"
        marginLabel.font = .systemFont(ofSize: 18)
        marginLabel.backgroundColor = .purple
        marginLabel.textColor = .orange
        
        let attrText = NSMutableAttributedString(string: marginLabel.text!)
        attrText.wy_innerMargin(firstLineHeadIndent: 10, tailIndent: -10)
        
        marginLabel.numberOfLines = 0
        marginLabel.attributedText = attrText
        scrollView.addSubview(marginLabel)
        
        marginLabel.sizeToFit()
        marginLabel.snp.makeConstraints { (make) in
            
            make.centerX.equalToSuperview()
            make.width.equalTo(marginLabel.wy_width + 10)
            make.top.equalTo(emojiLabel.snp.bottom).offset(50)
        }
        
        WYLogManager.output("每行显示的分别是 \(String(describing: label.attributedText?.wy_stringPerLine(controlWidth: UIDevice.wy_screenWidth))), 一共 \(String(describing: label.attributedText?.wy_numberOfRows(controlWidth: UIDevice.wy_screenWidth))) 行")
        
        label.layoutIfNeeded()
        let subFrameRange = attribute.wy_calculateFrame(range: NSMakeRange(attribute.string.count - 7, 6), controlSize: label.frame.size)
        
        let subFrameString = attribute.wy_calculateFrame(subString: "敢比周而望进", controlSize: label.frame.size)
        WYLogManager.output("subFrameRange = \(subFrameRange), subFrameString = \(subFrameString), labelFrame = \(label.frame)")
        
        let frameView = UIView(frame: CGRect(x: subFrameRange.origin.x, y: subFrameRange.origin.y, width: subFrameRange.size.width, height: subFrameRange.size.height))
        frameView.backgroundColor = .red.withAlphaComponent(0.2)
        label.addSubview(frameView)
        
        let attachmentView: UILabel = UILabel()
        attachmentView.font = UIFont.systemFont(ofSize: 15)
        attachmentView.numberOfLines = 0
        let string_font_30: String = "嘴唇"
        let string_font_40: String = "爱心"
        let string_font_50: String = "喝彩"
        let image_font_30: UIImage = UIImage.wy_find("嘴唇")
        let image_font_40: UIImage = UIImage.wy_find("爱心")
        let image_font_50: UIImage = UIImage.wy_find("喝彩")
        let attributed: NSMutableAttributedString = NSMutableAttributedString(string: String.wy_random(minimux:10, maximum: 20) + "\n" + string_font_30  + "\n" + string_font_40  + "\n" + string_font_50  + "\n" + String.wy_random(minimux:10, maximum: 20))
        
        var string_font_50Index: Int = 0
        if let range = attributed.string.range(of: string_font_50) {
            string_font_50Index = attributed.string.distance(from: attributed.string.startIndex, to: range.lowerBound) - 1
        } else {
            string_font_50Index = 0 // 未找到的情况，可根据需求调整
        }
        let options: [WYImageAttachmentOption] = [
            .init(image: image_font_30, size: CGSize(width: 20, height: 20), position: .before(text: string_font_30), alignment: .top, spacingAfter:20),
            .init(image: image_font_30, size: CGSize(width: 10, height: 10), position: .index(1), alignment: .top, spacingAfter:20),
            .init(image: image_font_40, size: CGSize(width: 20, height: 20), position: .after(text: string_font_40), alignment: .center, spacingBefore: 10),
            .init(image: image_font_50, size: CGSize(width: 20, height: 20), position: .after(text: string_font_50), alignment: .bottom),
            .init(image: image_font_50, size: CGSize(width: 10, height: 10), position: .index(string_font_50Index + 2), alignment: .custom(offset: -30))
        ]
        attributed.wy_fontsOfRanges([[UIFont.systemFont(ofSize: 30): string_font_30], [UIFont.systemFont(ofSize: 40): string_font_40], [UIFont.systemFont(ofSize: 50): string_font_50]])
        attributed.wy_insertImage(options)
        attributed.wy_lineSpacing(10)
        attachmentView.attributedText = attributed
        scrollView.addSubview(attachmentView)
        attachmentView.snp.makeConstraints { make in
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.centerX.equalToSuperview()
            make.top.equalTo(marginLabel.snp.bottom).offset(50)
        }
        
        let spacingView = UILabel()
        spacingView.textColor = .wy_random
        spacingView.numberOfLines = 0
        scrollView.addSubview(spacingView)
        spacingView.snp.makeConstraints { make in
            make.width.equalTo(UIDevice.wy_screenWidth - 30)
            make.centerX.equalToSuperview()
            make.top.equalTo(attachmentView.snp.bottom).offset(50)
        }
        
        let spacing10: String = String.wy_random(minimux: 50, maximum: 100)
        
        let spacing15: String = String.wy_random(minimux: 30, maximum: 80)
        
        let spacing30: String = String.wy_random(minimux: 25, maximum: 60)
        
        let spacing20: String = String.wy_random(minimux: 80, maximum: 100)
        
        WYLogManager.output("spacing10 = \(spacing10), spacing15 = \(spacing15), spacing30 = \(spacing30), spacing20 = \(spacing20)")
        
        let spacingAttributed = NSMutableAttributedString(string: spacing10 + "\n" + spacing15 + "\n" + spacing30 + "\n" + spacing20)
        spacingAttributed.wy_lineSpacing(10, beforeString: spacing10, afterString: spacing15, alignment: .left)
        spacingAttributed.wy_lineSpacing(15, beforeString: spacing15, afterString: spacing30, alignment: .right)
        spacingAttributed.wy_lineSpacing(30, beforeString: spacing30, afterString: spacing20, alignment: .left)
        spacingAttributed.wy_lineSpacing(50, subString: spacing20)
        spacingView.attributedText = spacingAttributed
        
        let sizeWidth: CGFloat = UIDevice.wy_screenWidth - 30
        let sizeHeight: CGFloat = 30

        let widthView: UILabel = UILabel()
        widthView.backgroundColor = .wy_random
        widthView.font = UIFont.boldSystemFont(ofSize: 15)
        widthView.text = String.wy_random(minimux: 5, maximum: 20)
        scrollView.addSubview(widthView)
        widthView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(spacingView.snp.bottom).offset(UIDevice.wy_screenWidth(50))
            make.height.equalTo(sizeHeight)
        }
        
        let textWidth: CGFloat = widthView.text!.wy_calculateWidth(controlHeight: sizeHeight, controlFont: widthView.font)
        
        let widthAttributed: NSMutableAttributedString = NSMutableAttributedString(string: widthView.text!)
        widthAttributed.wy_setFont(widthView.font)
        let attributedWidth: CGFloat = widthAttributed.wy_calculateWidth(controlHeight: sizeHeight)
        
        let heightView: UILabel = UILabel()
        heightView.backgroundColor = .wy_random
        heightView.numberOfLines = 0
        heightView.font = UIFont.boldSystemFont(ofSize: 15)
        heightView.text = String.wy_random(minimux: 150, maximum: 300)
        scrollView.addSubview(heightView)
        heightView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(widthView.snp.bottom).offset(UIDevice.wy_screenWidth(50))
            make.width.equalTo(sizeWidth)
            make.bottom.equalToSuperview().offset(-50)
        }
        
        let textHeight: CGFloat = heightView.text!.wy_calculateHeight(controlWidth: sizeWidth, controlFont: heightView.font)
        
        let heightAttributed: NSMutableAttributedString = NSMutableAttributedString(string: heightView.text!)
        heightAttributed.wy_setFont(heightView.font)
        let attributedHeight: CGFloat = heightAttributed.wy_calculateHeight(controlWidth: sizeWidth)
        
        let textWidthLine: UIView = UIView()
        textWidthLine.backgroundColor = .orange
        scrollView.addSubview(textWidthLine)
        textWidthLine.snp.makeConstraints { make in
            make.left.top.equalTo(widthView)
            make.height.equalTo(2)
            make.width.equalTo(textWidth)
        }
        
        let attributedWidthLine: UIView = UIView()
        attributedWidthLine.backgroundColor = .orange
        scrollView.addSubview(attributedWidthLine)
        attributedWidthLine.snp.makeConstraints { make in
            make.left.bottom.equalTo(widthView)
            make.height.equalTo(2)
            make.width.equalTo(attributedWidth)
        }

        let textHeightLine: UIView = UIView()
        textHeightLine.backgroundColor = .red
        scrollView.addSubview(textHeightLine)
        textHeightLine.snp.makeConstraints { make in
            make.left.top.equalTo(heightView)
            make.height.equalTo(textHeight)
            make.width.equalTo(2)
        }
        
        let attributedHeightLine: UIView = UIView()
        attributedHeightLine.backgroundColor = .red
        scrollView.addSubview(attributedHeightLine)
        attributedHeightLine.snp.makeConstraints { make in
            make.right.top.equalTo(heightView)
            make.height.equalTo(attributedHeight)
            make.width.equalTo(2)
        }
    }
    
    deinit {
        WYLogManager.output("deinit")
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension WYTestRichTextController: WYRichTextDelegate {
    
    func wy_didClick(richText: String, range: NSRange, index: Int) {
        
        //wy_print("string = \(richText), range = \(range), index = \(index)")
        //WYActivity.showInfo("string = \(richText), range = \(range), index = \(index)", in: self.view, position: .middle)
        if (richText == "必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。") {
            WYActivity.showScrollInfo("必审己之所当戒而齐之以义，然后中和之化应，而巧伪之徒不敢比周而望进。")
        }
    }
}
