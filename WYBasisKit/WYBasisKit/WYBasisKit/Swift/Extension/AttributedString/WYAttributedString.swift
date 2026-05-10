//
//  AttributedString.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
    
    /**
     设置富文本中指定范围的颜色。
     
     - Parameter colorRanges: 字典，键为颜色，值为范围定义。
     
     范围支持以下格式：
     - `String`：匹配该子串的所有出现。
     - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     - `[NSRange]`：多个 `NSRange` 值。
     
     - Returns: 当前对象，支持链式调用。
     */
    @discardableResult
    func wy_setColor(_ colorRanges: Dictionary<UIColor, Any>) -> NSMutableAttributedString {
        for (color, rangeValue) in colorRanges {
            wy_applyFontsOrColorsAttributes(
                key: NSAttributedString.Key.foregroundColor,
                value: color,
                rangeValue: rangeValue
            )
        }
        return self
    }
    
    /**
     设置富文本中指定范围的字体。
     
     - Parameter fontRanges: 字典，键为字体，值为范围定义。
     
     范围支持以下格式：
     - `String`：匹配该子串的所有出现。
     - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     - `[NSRange]`：多个 `NSRange` 值。
     
     - Returns: 当前对象，支持链式调用。
     */
    @discardableResult
    func wy_setFont(_ fontRanges: Dictionary<UIFont, Any>) -> NSMutableAttributedString {
        for (font, rangeValue) in fontRanges {
            wy_applyFontsOrColorsAttributes(
                key: .font,
                value: font,
                rangeValue: rangeValue
            )
        }
        return self
    }
    
    /**
     设置富文本中指定范围的背景色
     
     - Parameter color:       背景色
     - Parameter rangeValue:  范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     - `String`：匹配该子串的所有出现。
     - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     - `[NSRange]`：多个 `NSRange` 值。
     
     - Returns: 当前对象，支持链式调用
     */
    @discardableResult
    func wy_setBackgroundColor(_ color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.backgroundColor, value: color, range: targetRange)
        }
        return self
    }
    
    /**
     *  修改富文本字体(整个富文本统一设置字体)
     */
    @discardableResult
    func wy_setFont(_ font: UIFont) -> NSMutableAttributedString {
        addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: self.length))
        return self
    }
    
    /**
     *  设置行间距，支持多种范围定义
     *
     *  - Parameters:
     *    - lineSpacing: 行间距值（单位：pt）
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *    - alignment:  段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     */
    @discardableResult
    func wy_lineSpacing(_ lineSpacing: CGFloat, rangeValue: Any? = nil, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            let paragraphStyle = wy_paragraphStyle(at: targetRange)
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.alignment = alignment
            addAttribute(.paragraphStyle, value: paragraphStyle, range: targetRange)
        }
        return self
    }
    
    /**
     *  设置两个指定字符串之间的段落间距
     *
     *  该方法会在 `beforeString` 所在段落的末尾增加 `lineSpacing` 间距，
     *  从而影响其与 `afterString` 所在段落之间的距离。
     *
     *  - Parameters:
     *    - lineSpacing:   段落间距值（单位：pt），需大于 0
     *    - beforeString:  起始字符串，其所在段落的底部将会增加间距
     *    - afterString:   结束字符串，必须位于 `beforeString` 之后
     *    - alignment:     段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 若 `beforeString` 或 `afterString` 未找到，或间距 ≤ 0，则不进行任何修改。
     */
    @discardableResult
    func wy_lineSpacing(_ lineSpacing: CGFloat,
                        beforeString: String,
                        afterString: String,
                        alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        
        guard lineSpacing > 0,
              !beforeString.isEmpty,
              !afterString.isEmpty,
              self.length > 0 else {
            return self
        }
        
        let fullText = self.string
        
        // 查找 beforeString 的位置
        guard let beforeRange = fullText.range(of: beforeString) else {
            return self
        }
        
        // 在 beforeString 之后查找 afterString
        let afterSearchStart = beforeRange.upperBound
        let afterSearchRange = afterSearchStart..<fullText.endIndex
        
        guard let _ = fullText.range(of: afterString, range: afterSearchRange) else {
            return self
        }
        
        // 获取 beforeString 所在段落范围
        if let paragraphRange = wy_paragraphRange(containing: beforeRange, value: fullText) {
            
            // 创建或获取段落样式
            let range = NSRange(paragraphRange, in: fullText)
            let paragraphStyle = wy_paragraphStyle(at: range)
            
            // 配置段落样式
            paragraphStyle.paragraphSpacing = lineSpacing
            paragraphStyle.alignment = alignment
            
            // 应用段落样式
            self.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: range
            )
        }
        
        return self
    }
    
    /**
     *  设置字间距（字符间距），支持多种范围定义
     *
     *  - Parameters:
     *    - wordsSpacing: 字间距值（单位：pt）
     *    - rangeValue:   范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     */
    @discardableResult
    func wy_wordsSpacing(_ wordsSpacing: CGFloat, rangeValue: Any? = nil) -> NSMutableAttributedString {
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.kern, value: wordsSpacing, range: targetRange)
        }
        return self
    }
    
    /**
     *  文本添加内边距，支持多种范围定义
     *
     *  - Parameters:
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *    - firstLineHeadIndent:  首行左边距
     *    - headIndent:  第二行及以后的左边距(换行符\n除外)
     *    - tailIndent:  尾部右边距
     *    - alignment:  对齐方式
     */
    @discardableResult
    func wy_innerMargin(rangeValue: Any? = nil,
                        firstLineHeadIndent: CGFloat = 0,
                        headIndent: CGFloat = 0,
                        tailIndent: CGFloat = 0,
                        alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            let paragraphStyle = wy_paragraphStyle(at: targetRange)
            paragraphStyle.alignment = alignment
            paragraphStyle.firstLineHeadIndent = firstLineHeadIndent
            paragraphStyle.headIndent = headIndent
            paragraphStyle.tailIndent = tailIndent
            addAttribute(.paragraphStyle, value: paragraphStyle, range: targetRange)
        }
        return self
    }
    
    /**
     *  调整文本基线偏移（实现文字上下移动），支持多种范围定义
     *
     *  - Parameters:
     *    - offset: 偏移量（单位：pt），**正值向上移动，负值向下移动**
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     */
    @discardableResult
    func wy_baseline(offset: CGFloat, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.baselineOffset, value: offset, range: targetRange)
        }
        return self
    }
    
    /**
     *  为文本添加下划线，支持多种范围定义
     *
     *  - Parameters:
     *    - color:  下划线的颜色
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *  - Note: 下划线样式为单线（`.single`）。
     */
    @discardableResult
    func wy_underline(color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: targetRange)
            addAttribute(.underlineColor, value: color, range: targetRange)
        }
        return self
    }
    
    /**
     *  为文本添加删除线，支持多种范围定义
     *
     *  - Parameters:
     *    - color:  删除线的颜色
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效。支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *  - Note: 删除线样式为单线（`.single`）。
     */
    @discardableResult
    func wy_strikethrough(color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: targetRange)
            addAttribute(.strikethroughColor, value: color, range: targetRange)
        }
        return self
    }
    
    /**
     向富文本中插入图片（支持图文混排，自动处理位置和对齐方式）
     
     - Parameter attachments: 富文本图片插入配置数组，每个元素定义了图片、位置、尺寸、对齐方式和间距
     - Returns: 当前 NSMutableAttributedString 对象本身（链式返回）
     
     使用说明：
     1. position 支持插入到指定文本前/后或指定字符下标处；
     2. offsetY 图片相对于文本的偏移量(正值向上，负值向下)
     3. spacingBefore / spacingAfter 可用于设置插入图片前后的间距；
     */
    @discardableResult
    func wy_insertImage(_ attachments: [WYImageAttachmentOption]) -> NSMutableAttributedString {
        
        guard !string.isEmpty, !attachments.isEmpty else { return self }
        
        // 将插入项统一转换为 (index, attr) 类型，便于排序和插入
        var insertionItems: [(index: Int, attr: NSAttributedString)] = []
        
        for option in attachments {
            
            // 计算插入位置 index
            let insertIndex: Int
            switch option.position {
            case .index(let value):
                insertIndex = max(0, min(self.length, value))
                
            case .before(let target):
                if let range = string.range(of: target) {
                    insertIndex = string.distance(from: string.startIndex, to: range.lowerBound)
                } else {
                    insertIndex = self.length
                }
                
            case .after(let target):
                if let range = string.range(of: target) {
                    insertIndex = string.distance(from: string.startIndex, to: range.upperBound)
                } else {
                    insertIndex = self.length
                }
            }
            
            // 构建图片 attachment
            let attachment = NSTextAttachment()
            attachment.image = option.image
            
            attachment.bounds = CGRect(x: 0, y: option.offsetY, width: option.size.width, height: option.size.height)
            let imageAttr = NSAttributedString(attachment: attachment)
            
            // 构建前后间距（使用透明附件）
            let beforeSpace: NSAttributedString = {
                guard option.spacingBefore > 0 else { return NSAttributedString() }
                let space = NSTextAttachment()
                space.bounds = CGRect(x: 0, y: 0, width: option.spacingBefore, height: 0)
                return NSAttributedString(attachment: space)
            }()
            
            let afterSpace: NSAttributedString = {
                guard option.spacingAfter > 0 else { return NSAttributedString() }
                let space = NSTextAttachment()
                space.bounds = CGRect(x: 0, y: 0, width: option.spacingAfter, height: 0)
                return NSAttributedString(attachment: space)
            }()
            
            // 拼接完整插入内容：前间距 + 图片 + 后间距
            let fullInsert = NSMutableAttributedString()
            fullInsert.append(beforeSpace)
            fullInsert.append(imageAttr)
            fullInsert.append(afterSpace)
            
            // 保存待插入数据
            insertionItems.append((index: insertIndex, attr: fullInsert))
        }
        
        // 倒序插入，避免偏移
        for item in insertionItems.sorted(by: { $0.index > $1.index }) {
            insert(item.attr, at: item.index)
        }
        
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
    static func wy_convertEmojiAttributed(emojiString: String, textColor: UIColor, textFont: UIFont, emojiTable: [String], sourceBundle: WYSourceBundle? = nil, pattern: String = "\\[.{1,3}\\]") -> NSMutableAttributedString {
        
        // 字体、颜色
        let textAttributes: [NSAttributedString.Key: Any] = [.font: textFont, .foregroundColor: textColor]
        
        // 富文本初始对象
        let attributedString = NSMutableAttributedString(string: emojiString, attributes: textAttributes)
        
        // 表情高度
        let attachmentHeight = textFont.lineHeight
        
        // 正则匹配
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch let error {
            WYLogManager.output(error.localizedDescription)
            regex = nil
        }
        
        guard let matches = regex?.matches(in: emojiString, options: [], range: NSRange(emojiString.startIndex..., in: emojiString)),
              !matches.isEmpty else {
            return attributedString
        }
        
        // 倒序遍历，防止替换偏移
        for result in matches.reversed() {
            let nsRange = result.range
            guard let range = Range(nsRange, in: emojiString) else { continue }
            let emojiStr = String(emojiString[range])
            
            // 检查是否是表情
            if emojiTable.contains(emojiStr) {
                let image = UIImage.wy_find(emojiStr, inBundle: sourceBundle)
                
                let attachment = WYTextAttachment()
                attachment.image = image
                attachment.imageName = emojiStr
                attachment.imageRange = nsRange
                
                // 计算宽度，保持图片比例
                let attachmentWidth = attachmentHeight * (image.size.width / image.size.height)
                attachment.bounds = CGRect(x: 0, y: (textFont.capHeight - textFont.lineHeight)/2,
                                           width: attachmentWidth, height: attachmentHeight)
                
                // 替换表情为附件
                let replace = NSAttributedString(attachment: attachment)
                attributedString.replaceCharacters(in: nsRange, with: replace)
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
    
    /**
     *  范围解析，返回对应的 NSRange 数组
     *
     *  - Parameter rangeValue: 范围定义，支持以下格式：
     *        - `String`：匹配该子串的所有出现。
     *        - `[String]`：若数组长度为2且可转为整数，视为单个区间 `[起始, 长度]`；否则视为多个子串，每个子串的所有出现均匹配。
     *        - `[Int]`：两个整数，视为单个区间 `[起始, 长度]`。
     *        - `[[String]]` 或 `[[Int]]`：多个区间，如 `[["0","5"], ["10","3"]]` 或 `[[0,5], [10,3]]`。
     *        - `[NSRange]`：多个 `NSRange` 值。
     *  - Returns: 对应的 NSRange 数组（已进行边界有效性检查）
     */
    func wy_parseRanges(from rangeValue: Any) -> [NSRange] {
        let fullString = self.string
        let fullLength = fullString.utf16.count
        
        // 递归解析函数
        func parse(_ value: Any) -> [NSRange] {
            // 1. 单个字符串 → 查找所有出现
            if let singleString = value as? String {
                guard !singleString.isEmpty else { return [] }
                var ranges: [NSRange] = []
                var searchStart = fullString.startIndex
                while let range = fullString.range(of: singleString, range: searchStart..<fullString.endIndex) {
                    let nsRange = NSRange(range, in: fullString)
                    ranges.append(nsRange)
                    searchStart = range.upperBound
                    if searchStart >= fullString.endIndex { break }
                }
                return ranges
            }
            
            // 2. 两个整数的数组 → 区间
            if let ints = value as? [Int], ints.count == 2 {
                let location = ints[0]
                let length = ints[1]
                guard location >= 0, length >= 0, location + length <= fullLength else { return [] }
                return [NSRange(location: location, length: length)]
            }
            
            // 3. 字符串数组
            if let strings = value as? [String] {
                // 长度为2且都可转为整数 → 区间
                if strings.count == 2,
                   let location = Int(strings[0]),
                   let length = Int(strings[1]),
                   location >= 0, length >= 0,
                   location + length <= fullLength {
                    return [NSRange(location: location, length: length)]
                } else {
                    // 否则每个字符串作为子串匹配
                    var ranges: [NSRange] = []
                    for sub in strings {
                        ranges.append(contentsOf: parse(sub))
                    }
                    return ranges
                }
            }
            
            // 4. NSRange 数组
            if let nsRanges = value as? [NSRange] {
                return nsRanges.filter {
                    $0.location >= 0 && $0.length >= 0 && $0.location + $0.length <= fullLength
                }
            }
            
            // 5. 通用数组（混合类型） → 递归解析每个元素
            if let array = value as? [Any] {
                return array.flatMap { parse($0) }
            }
            
            // 6. 单个 NSRange 对象
            if let nsRange = value as? NSRange {
                guard nsRange.location >= 0, nsRange.length >= 0, nsRange.location + nsRange.length <= fullLength else { return [] }
                return [nsRange]
            }
            
            // 无法识别
            assertionFailure("Unsupported rangeValue type: \(type(of: value))")
            return []
        }
        
        let allRanges = parse(rangeValue)
        
        // 内联去重（基于 location 和 length）
        var uniqueRanges: [NSRange] = []
        var seen = Set<String>()
        for range in allRanges {
            let key = "\(range.location),\(range.length)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueRanges.append(range)
            }
        }
        return uniqueRanges
    }
}

public extension NSAttributedString {
    
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
    func wy_numberOfRows(controlWidth: CGFloat) -> Int {
        return wy_stringPerLine(controlWidth: controlWidth).count
    }
}

public class WYTextAttachment: NSTextAttachment {
    public var imageName: String = ""
    public var imageRange: NSRange = NSMakeRange(0, 0)
}

/// 富文本图片插入配置
public struct WYImageAttachmentOption {
    
    /// 图片插入位置
    @frozen public enum WYImageAttachmentPosition {
        /// 插入到文本前面
        case before(text: String)
        /// 插入到文本后面
        case after(text: String)
        /// 根据文本下标插入到指定位置
        case index(Int)
    }
    
    /// 要插入的图片
    public let image: UIImage
    
    /// 图片尺寸
    public let size: CGSize
    
    /// 图片插入位置
    public let position: WYImageAttachmentPosition
    
    /// 图片相对于文本的偏移量(正值向上，负值向下)
    public let offsetY: CGFloat
    
    /// 图片与前面文本的间距（单位：pt）
    public let spacingBefore: CGFloat
    
    /// 图片与后面文本的间距（单位：pt）
    public let spacingAfter: CGFloat
    
    public init(image: UIImage,
                size: CGSize,
                position: WYImageAttachmentPosition,
                offsetY: CGFloat = 0,
                spacingBefore: CGFloat = 0,
                spacingAfter: CGFloat = 0) {
        self.image = image
        self.size = size
        self.position = position
        self.offsetY = offsetY
        self.spacingBefore = spacingBefore
        self.spacingAfter = spacingAfter
    }
}

private extension NSMutableAttributedString {
    
    /**
     内部通用方法：根据 rangeValue 批量设置属性（如字体、颜色）。
     - Parameters:
     - key: 属性键，如 `.font`
     - value: 属性值，如 UIFont
     - rangeValue: 范围，支持 `wy_parseRanges` 定义的所有格式（子串匹配、区间数组等）
     */
    func wy_applyFontsOrColorsAttributes(key: NSAttributedString.Key, value: Any, rangeValue: Any) {
        
        let ranges = wy_parseRanges(from: rangeValue)
        for range in ranges {
            addAttribute(key, value: value, range: range)
        }
    }
    
    /**
     获取包含指定字符位置的完整段落范围（基于原始字符串，以 `\n` 为界）。
     - Parameters:
     - range: 字符索引范围
     - value: 原始字符串
     - Returns: 段落边界范围，若字符串为空则返回 nil
     */
    func wy_paragraphRange(containing range: Range<String.Index>, value: String) -> Range<String.Index>? {
        guard !value.isEmpty else { return nil }
        
        let paragraphStart = value[..<range.lowerBound].lastIndex(of: "\n") ?? value.startIndex
        let paragraphEnd = value[range.upperBound...].firstIndex(of: "\n") ?? value.endIndex
        return paragraphStart..<paragraphEnd
    }
    
    /**
     * 创建或者获取指定富文本范围内的可变段落样式
     *
     * 该方法会尝试获取指定 range 处的现有段落样式，如果存在则返回其可变副本；
     * 如果不存在，则返回一个新的 `NSMutableParagraphStyle` 实例。
     *
     * - Parameter range: 需要获取段落样式的富文本范围（通常用目标 range 的起始位置即可）
     * - Returns: 可变的段落样式对象，调用方可以修改其属性，然后自行通过 `addAttribute` 应用到指定范围
     *
     */
    func wy_paragraphStyle(at range: NSRange) -> NSMutableParagraphStyle {
        if let existingStyle = self.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle,
           let mutableStyle = existingStyle.mutableCopy() as? NSMutableParagraphStyle {
            return mutableStyle
        }
        return NSMutableParagraphStyle()
    }
}
