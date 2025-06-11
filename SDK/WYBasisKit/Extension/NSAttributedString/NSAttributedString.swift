//
//  NSAttributedString.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
    
    /**
     
     *  需要修改的字符颜色数组及量程，由字典组成  key = 颜色   value = 量程或需要修改的字符串
     *  例：NSArray *colorsOfRanges = @[@{color:@[@"0",@"1"]},@{color:@[@"1",@"2"]}]
     *  或：NSArray *colorsOfRanges = @[@{color:str},@{color:str}]
     */
    @discardableResult
    func wy_colorsOfRanges(colorsOfRanges: Array<Dictionary<UIColor, Any>>) -> NSMutableAttributedString {
        
        for dic: Dictionary in colorsOfRanges {
            
            let color: UIColor = dic.keys.first!
            let rangeValue = dic.values.first
            if rangeValue is String || rangeValue is NSString {
                
                let rangeStr: String = rangeValue as! String
                let selfStr = self.string as NSString
                
                addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: selfStr.range(of: rangeStr))
                
            }else {
                
                let rangeAry: Array = rangeValue as! Array<Any>
                let firstRangeStr: String = rangeAry.first as! String
                let lastRangeStr: String = rangeAry.last as! String
                addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSMakeRange(Int(firstRangeStr) ?? 0, Int(lastRangeStr) ?? 0))
            }
        }
        
        return self
    }
    
    /**
     
     *  需要修改的字符字体数组及量程，由字典组成  key = 颜色   value = 量程或需要修改的字符串
     *  例：NSArray *fontsOfRanges = @[@{font:@[@"0",@"1"]},@{font:@[@"1",@"2"]}]
     *  或：NSArray *fontsOfRanges = @[@{font:str},@{font:str}]
     */
    @discardableResult
    func wy_fontsOfRanges(fontsOfRanges: Array<Dictionary<UIFont, Any>>) -> NSMutableAttributedString {
        for dic: Dictionary in fontsOfRanges {
            
            let font: UIFont = dic.keys.first!
            let rangeValue = dic.values.first
            if rangeValue is String || rangeValue is NSString {
                
                let rangeStr: String = rangeValue as! String
                let selfStr = self.string as NSString
                
                addAttribute(NSAttributedString.Key.font, value: font, range: selfStr.range(of: rangeStr))
                
            }else {
                
                let rangeAry = rangeValue as! Array<Any>
                let firstRangeStr: String = rangeAry.first as! String
                let lastRangeStr: String = rangeAry.last as! String
                addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(Int(firstRangeStr) ?? 0, Int(lastRangeStr) ?? 0))
            }
        }
        return self
    }
    
    /// 设置行间距
    @discardableResult
    func wy_lineSpacing(lineSpacing: CGFloat, string: String? = nil, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = alignment
        
        let selfStr: NSString = self.string as NSString
        addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: selfStr.range(of: (string == nil ? self.string : string!)))
        
        return self
    }
    
    /// 设置字间距
    @discardableResult
    func wy_wordsSpacing(wordsSpacing: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        
        let selfStr: NSString = self.string as NSString
        addAttributes([NSAttributedString.Key.kern: NSNumber(value: Double(wordsSpacing))], range: selfStr.range(of: string == nil ? self.string : string!))
        
        return self
    }
    
    /// 文本添加下滑线
    @discardableResult
    func wy_underline(color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        
        let selfStr: NSString = self.string as NSString
        addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selfStr.range(of: string == nil ? self.string : string!))
        addAttribute(NSAttributedString.Key.underlineColor, value: color, range: selfStr.range(of: string == nil ? self.string : string!))
        
        return self
    }
    
    /// 文本添加删除线
    @discardableResult
    func wy_strikethrough(color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        
        let selfStr: NSString = self.string as NSString
        addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selfStr.range(of: string == nil ? self.string : string!))
        addAttribute(NSAttributedString.Key.strikethroughColor, value: color, range: selfStr.range(of: string == nil ? self.string : string!))
        
        return self
    }
    
    /**
     *  文本添加内边距
     *  @param firstLineHeadIndent  首行左边距
     *  @param headIndent  第二行及以后的左边距(换行符\n除外)
     *  @param tailIndent  尾部右边距
     */
    @discardableResult
    func wy_innerMargin(firstLineHeadIndent: CGFloat = 0, headIndent: CGFloat = 0, tailIndent: CGFloat = 0, alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.firstLineHeadIndent = firstLineHeadIndent
        paragraphStyle.headIndent = headIndent
        paragraphStyle.tailIndent = tailIndent
        
        let selfStr: NSString = self.string as NSString
        addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: selfStr.range(of: self.string))
        
        return self
    }
    
    /**
     *  根据传入的表情字符串生成富文本，例如字符串 "哈哈[哈哈]" 会生成 "哈哈😄"
     *  @param emojiString   待转换的表情字符串
     *  @param textColor     富文本的字体颜色
     *  @param textFont      富文本的字体
     *  @param emojiTable    表情解析对照表，如 ["哈哈](哈哈表情对应的图片名)", [嘿嘿(嘿嘿表情对应的图片名)]]
     *  @param bundle        从哪个bundle文件内查找图片资源，如果为空，则直接在本地路径下查找
     *  @param pattern       正则匹配规则, 默认匹配1到3位, 如 [哈] [哈哈] [哈哈哈] 这种
     */
    class func wy_convertEmojiAttributed(emojiString: String, textColor: UIColor, textFont: UIFont, emojiTable: [String], sourceBundle: WYSourceBundle? = nil, pattern: String = "\\[.{1,3}\\]") -> NSMutableAttributedString {
        
        // 字体、颜色
        let textAttributes = [NSAttributedString.Key.font: textFont, NSAttributedString.Key.foregroundColor: textColor]
        
        // 获取字体的行高，作为表情的高度
        let attachmentHeight = textFont.lineHeight
        
        // 通过 emojiString 获得 NSMutableAttributedString
        let attributedString = NSMutableAttributedString(string: emojiString, attributes: textAttributes)
        
        var regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch let error {
            wy_print(error.localizedDescription)
        }
        
        // 获取到匹配正则的数据
        if let matches = regex?.matches(in: emojiString, options: .withoutAnchoringBounds, range: NSMakeRange(0, attributedString.string.utf16.count)) {
            if matches.count > 0 {
                // 遍历符合的数据进行解析
                for i in 0..<matches.count {
                    let result = matches[matches.count-i-1]
                    let range = result.range
                    let emojiStr = (emojiString as NSString).substring(with: range)
                    // 符合的数据是否为表情
                    if emojiTable.contains(emojiStr) {
                        
                        // 获取表情对应的图片名
                        let image: UIImage = UIImage.wy_find(emojiStr, inBundle: sourceBundle)
                        
                        // 创建一个NSTextAttachment
                        let attachment = WYTextAttachment()
                        attachment.image  = image
                        attachment.imageName = emojiStr
                        attachment.imageRange = range
                        
                        let attachmentWidth = attachmentHeight * (image.size.width / image.size.height)
                        
                        attachment.bounds = CGRect(x: 0, y: (textFont.capHeight - textFont.lineHeight)/2, width: attachmentWidth, height: attachmentHeight)
                        
                        // 通过NSTextAttachment生成一个NSAttributedString
                        let replace = NSAttributedString(attachment: attachment)
                        
                        // 替换表情字符串
                        attributedString.replaceCharacters(in: range, with: replace)
                    }
                }
            }
        }
        return attributedString
    }
    
    /**
     *  将表情富文本生成对应的富文本字符串，例如表情富文本 "哈哈😄" 会生成 "哈哈[哈哈]"
     *  @param textColor     富文本的字体颜色
     *  @param textFont      富文本的字体
     *  @param replace       未知图片(表情)的标识替换符，默认：[未知]
     */
    func wy_convertEmojiAttributedString(textColor: UIColor, textFont: UIFont, replace: String = "[未知]") -> NSMutableAttributedString {
        
        let attributed: NSAttributedString = self
        
        let mutableString: NSMutableString = NSMutableString(string: attributed.string)
        attributed.enumerateAttribute(NSAttributedString.Key.attachment, in: NSMakeRange(0, attributed.string.utf16.count), options: NSAttributedString.EnumerationOptions.reverse) { value, range, stop in
            
            if value is WYTextAttachment {
                // 拿到文本附件
                let attachment: WYTextAttachment = value as! WYTextAttachment
                let string: String = String(format: "%@", attachment.imageName)
                // 替换成图片表情的标识
                mutableString.replaceCharacters(in: range, with: string)
            }else {
                if value is NSTextAttachment {
                    // 替换成图片表情的标识
                    mutableString.replaceCharacters(in: range, with: replace)
                }
            }
        }
        
        // 字体、颜色
        let textAttributes = [NSAttributedString.Key.font: textFont, NSAttributedString.Key.foregroundColor: textColor]
        return NSMutableAttributedString(string: mutableString.copy() as! String, attributes: textAttributes)
    }
}

public extension NSAttributedString {
    
    /// 获取某段文字的frame
    func wy_calculateFrame(range: NSRange, controlSize: CGSize, numberOfLines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> CGRect {
        
        let textStorage: NSTextStorage = NSTextStorage(attributedString: self)
        let layoutManager: NSLayoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer: NSTextContainer = NSTextContainer(size: controlSize)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        layoutManager.addTextContainer(textContainer)
        
        var glyphRange: NSRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
    /// 获取某段文字的frame
    func wy_calculateFrame(subString: String, controlSize: CGSize, numberOfLines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> CGRect {
        
        guard subString.isEmpty == false else {
            return CGRect.zero
        }
        
        let textStorage: NSTextStorage = NSTextStorage(attributedString: self)
        let layoutManager: NSLayoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer: NSTextContainer = NSTextContainer(size: controlSize)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        layoutManager.addTextContainer(textContainer)
        
        var glyphRange: NSRange = NSRange()
        layoutManager.characterRange(forGlyphRange: (string as NSString).range(of: subString), actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
    /// 计算富文本宽度
    func wy_calculateWidth(controlHeight: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: .greatestFiniteMagnitude, height: controlHeight)).width
    }
    
    /// 计算富文本高度
    func wy_calculateHeight(controlWidth: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: controlWidth, height: .greatestFiniteMagnitude)).height
    }
    
    /// 计算富文本宽高
    func wy_calculateSize(controlSize: CGSize) -> CGSize {
        let attributedSize = boundingRect(with: controlSize, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        return CGSize(width: ceil(attributedSize.width), height: ceil(attributedSize.height))
    }
    
    /// 获取每行显示的字符串(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    func wy_stringPerLine(controlWidth: CGFloat) -> [String] {
        
        if (self.string.utf16.count <= 0) {
            return []
        }
        
        let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(self)
        
        let path: CGMutablePath = CGMutablePath()
        
        path.addRect(CGRect(x: 0, y: 0, width: controlWidth, height: CGFloat.greatestFiniteMagnitude))
        
        let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        
        var strings = [String]()
        
        if let lines = CTFrameGetLines(frame) as? [CTLine] {
            lines.forEach({
                let linerange = CTLineGetStringRange($0)
                let range = NSMakeRange(linerange.location, linerange.length)
                let subAttributed = NSMutableAttributedString(attributedString: attributedSubstring(from: range))
                let string = subAttributed.wy_convertEmojiAttributedString(textColor: .white, textFont: .systemFont(ofSize: 10)).string
                strings.append(string)
            })
        }
        return strings
    }
    
    /// 判断字符串显示完毕需要几行(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    func wy_numberOfRows(controlWidth: CGFloat) -> NSInteger {
        return wy_stringPerLine(controlWidth: controlWidth).count
    }
}

public class WYTextAttachment: NSTextAttachment {
    public var imageName: String = ""
    public var imageRange: NSRange = NSMakeRange(0, 0)
}
