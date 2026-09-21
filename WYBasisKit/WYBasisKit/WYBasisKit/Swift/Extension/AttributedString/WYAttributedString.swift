//
//  AttributedString.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

/// 间距插入位置
@frozen public enum WYSpacingPosition: Int {
    /// 在范围之前插入间距
    case before = 0
    /// 在范围之后插入间距
    case after
}

public extension NSMutableAttributedString {
    
    /**
     设置富文本中指定范围的颜色。
     - Parameter colorRanges: 字典，Key为颜色，Value为范围定义(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
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
     - Parameter fontRanges: 字典，Key为字体，Value为范围定义(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
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
     - Parameter rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_setBackgroundColor(_ color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.backgroundColor, value: color, range: targetRange)
        }
        return self
    }
    
    /**
     *  设置富文本字体(整个富文本统一设置字体)
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_setFont(_ font: UIFont) -> NSMutableAttributedString {
        addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: self.length))
        return self
    }
    
    /**
     *  设置富文本的截断方式(默认 `.byTruncatingTail`（尾部截断）)
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_setLineBreakMode(_ lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let fullRange = NSRange(location: 0, length: self.length)
        let paragraphStyle = wy_paragraphStyle(at: fullRange)
        paragraphStyle.lineBreakMode = lineBreakMode
        addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        return self
    }
    
    /**
     *  设置行间距，支持多种范围定义
     
     *  - Parameters:
     *    - lineSpacing: 行间距值（单位：pt）
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *    - alignment:  段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_lineSpacing(_ lineSpacing: CGFloat, rangeValue: Any? = nil, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
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
     *  该方法会在 `beforeString` 所在段落的末尾增加 `paragraphSpace` 间距，
     *  从而影响其与 `afterString` 所在段落之间的距离。
     *
     *  如原始文本: 这是第一段，包含 beforeString。\n(换行)
     *            这是第二段，包含 afterString。
     *  调用后第一段底部和第二段头部之间会增加 paragraphSpace 的空白间距
     *
     *  - Parameters:
     *    - paragraphSpace:   段落间距值（单位：pt），需大于 0
     *    - beforeString:     起始字符串，其所在段落的底部将会增加间距
     *    - afterString:      结束字符串，必须位于 `beforeString` 之后
     *    - alignment:        段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，
     */
    @discardableResult
    func wy_paragraphSpace(_ paragraphSpace: CGFloat,
                           beforeString: String,
                           afterString: String,
                           alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        guard paragraphSpace > 0,
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
            paragraphStyle.paragraphSpacing = paragraphSpace
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
     *    - rangeValue:   范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_wordsSpacing(_ wordsSpacing: CGFloat, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        for targetRange in ranges {
            addAttribute(.kern, value: wordsSpacing, range: targetRange)
        }
        return self
    }
    
    /**
     在指定范围 前/后 插入水平间距
     
     - Parameters:
     - spacing:     要插入的间距值（单位：pt），需大于 0
     - position:    插入位置，`.before`（范围之前）或 `.after`（范围之后）
     - rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     
     - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_insertSpacing(_ spacing: CGFloat,
                          position: WYSpacingPosition,
                          rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        guard spacing > 0, self.length > 0 else { return self }
        
        // 解析范围
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
        } else {
            ranges = [NSRange(location: 0, length: self.length)]
        }
        
        guard !ranges.isEmpty else { return self }
        
        // 构建间距附件
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(x: 0, y: 0, width: spacing, height: 0)
        let spacingAttr = NSAttributedString(attachment: attachment)
        
        // 收集需要插入的位置（降序排序，避免偏移）
        var insertPositions: [Int] = []
        for range in ranges {
            // 确保 range 有效
            guard range.location >= 0,
                  range.location + range.length <= self.length else {
                continue
            }
            let insertIndex: Int
            switch position {
            case .before:
                insertIndex = range.location
            case .after:
                insertIndex = range.location + range.length
            }
            insertPositions.append(insertIndex)
        }
        
        // 去重并降序排序
        let sortedPositions = Set(insertPositions).sorted(by: >)
        
        for pos in sortedPositions {
            self.insert(spacingAttr, at: pos)
        }
        
        return self
    }
    
    /**
     *  文本添加段落缩进
     *
     *  - Parameters:
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *    - firstLineHeadIndent:  首行左边距
     *    - headIndent:  第二行及以后的左边距(换行符\n除外)
     *    - tailIndent:  尾部右边距
     *    - alignment:  对齐方式
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_paragraphIndents(rangeValue: Any? = nil,
                             firstLineHeadIndent: CGFloat = 0,
                             headIndent: CGFloat = 0,
                             tailIndent: CGFloat = 0,
                             alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
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
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_baseline(offset: CGFloat, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
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
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_underline(color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
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
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    func wy_strikethrough(color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        
        guard self.length > 0 else { return self }
        
        let ranges: [NSRange]
        if let value = rangeValue {
            ranges = self.string.wy_parseRanges(from: value)
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
     - Returns: 当前 `NSMutableAttributedString` 对象
     
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
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
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
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
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

    /**
     *  获取指定`string`的文本矩形区域信息(用到的排版属性(字体、对齐、行间距、字间距、内边距、基线偏移等)请尽量提前设置进富文本，计算才准确)
     *
     *  @param rangeValue     范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     *
     *  @param controlSize    排版容器尺寸(宽度即换行宽度，传极大值表示不限)
     *
     *  @param numberOfLines  最大行数，0 表示不限制(语义同 `UILabel.numberOfLines`)
     *
     *  @param lineBreakMode  换行/截断模式(语义同 `UILabel.lineBreakMode`)
     *
     *  - Returns: 文本矩形区域信息，单个目标查 `boundingRect`，数组目标按元素分组查 `boundingRects`，被截断隐藏的部分不产生矩形
     */
    func wy_calculateFrame(rangeValue: Any? = nil, controlSize: CGSize, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> WYTextBoundingInfos {

        // 解析目标与返回值类型(单个 String/NSRange/nil 用 boundingRect，数组类型用 boundingRects 按输入元素分组)
        let (valueStyle, elementTargets) = wy_boundingTargets(from: rangeValue)

        guard length > 0, !elementTargets.isEmpty else {
            return WYTextBoundingInfos(valueStyle: valueStyle, boundingRect: nil, boundingRects: nil)
        }

        // 一次排版供全部目标共用，避免同一份富文本重复布局
        let engine = WYTextLayoutEngine(attributedText: self,
                                        containerSize: controlSize,
                                        numberOfLines: max(0, numberOfLines),
                                        lineBreakMode: lineBreakMode)

        switch valueStyle {
        case .string, .range:
            // 单目标返回一维数组(同一文本多次出现或跨行显示都会拆成多个矩形，全部平铺)
            let rects = elementTargets.flatMap { $0 }.flatMap { engine.wy_boundingRects(for: $0) }
            return WYTextBoundingInfos(valueStyle: valueStyle, boundingRect: rects, boundingRects: nil)
        case .stringArray, .rangeArray, .stringAndRange:
            // 数组目标返回二维数组(外层与输入元素一一对应，未命中的元素对应空数组)
            let rects = elementTargets.map { elementRanges in
                elementRanges.flatMap { engine.wy_boundingRects(for: $0) }
            }
            return WYTextBoundingInfos(valueStyle: valueStyle, boundingRect: nil, boundingRects: rects)
        }
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

/// 文本矩形区域信息
public struct WYTextBoundingRects {

    /// 矩形区域
    public let rect: CGRect

    /// 矩形对应的字符串
    public let string: String

    /// 矩形对应的字符串范围
    public let range: NSRange

    /// 初始化方法
    public init(rect: CGRect, string: String, range: NSRange) {
        self.rect = rect
        self.string = string
        self.range = range
    }
}

public struct WYTextBoundingInfos {

    /// 返回值类型(枚举)
    @frozen public enum WYTextBoundingInfoValueStyle: Int {
        /// 单个文本 String
        case string = 0
        /// 单个区间 NSRange
        case range
        /// 文本数组 [String]
        case stringArray
        /// 区间数组 [NSRange]
        case rangeArray
        /// 文本与区间组合数组 [String, NSRange]
        case stringAndRange
    }

    /// 返回值具体类型
    public let valueStyle: WYTextBoundingInfoValueStyle

    /// String或NSRange对应的BoundingRects(因为单个文本可能也会存在换行显示，所以这里用数组来返回)
    public let boundingRect: [WYTextBoundingRects]?

    /// [String]或[NSRange]或[String,NSRange]对应的BoundingRects(因为单个文本可能也会存在换行显示，所以这里用数组来组合返回)
    public let boundingRects: [[WYTextBoundingRects]]?

    /// 初始化方法
    public init(valueStyle: WYTextBoundingInfoValueStyle, boundingRect: [WYTextBoundingRects]?, boundingRects: [[WYTextBoundingRects]]?) {
        self.valueStyle = valueStyle
        self.boundingRect = boundingRect
        self.boundingRects = boundingRects
    }
}

private extension NSMutableAttributedString {
    
    /**
     根据 rangeValue 批量设置属性（如字体、颜色）。
     - Parameters:
     - key: 属性键，如 `.font`
     - value: 属性值，如 UIFont
     - rangeValue: 范围，支持 `wy_parseRanges` 定义的所有格式（子串匹配、区间数组等）
     */
    func wy_applyFontsOrColorsAttributes(key: NSAttributedString.Key, value: Any, rangeValue: Any) {
        
        let ranges = self.string.wy_parseRanges(from: rangeValue)
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
        
        // 空字符串或越界时直接返回新实例
        guard self.length > 0,
              range.location >= 0,
              range.location < self.length else {
            return NSMutableParagraphStyle()
        }
        
        if let existingStyle = self.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle,
           let mutableStyle = existingStyle.mutableCopy() as? NSMutableParagraphStyle {
            return mutableStyle
        }
        return NSMutableParagraphStyle()
    }
}

private extension NSAttributedString {
    
    /**
     解析 wy_calculateFrame 的 rangeValue 为返回值类型与每个输入元素命中的全部范围
     
     - Parameter rangeValue: 支持类型，单个 `String`、`NSRange`(OC 侧为 NSValue 包装)、上述两类元素组成的任意数组（如 `[String]`、`[NSRange]`、`[String, NSRange]`），传 `nil` 表示整个富文本
     - Returns: (返回值类型, 按输入元素分组的命中范围，单个输入也按一个元素分组，未命中元素的分组为空数组)
     */
    func wy_boundingTargets(from rangeValue: Any?) -> (valueStyle: WYTextBoundingInfos.WYTextBoundingInfoValueStyle, elementTargets: [[NSRange]]) {
        
        let fullLength = self.length
        
        // 传 nil → 整个富文本作为一个目标(返回逐行矩形)
        guard let rangeValue = rangeValue else {
            return (.range, [[NSRange(location: 0, length: fullLength)]])
        }
        
        // 单个字符串 → 找出全部出现位置
        if let keyword = rangeValue as? String {
            return (.string, [self.string.wy_parseRanges(from: keyword)])
        }
        
        // 单个 NSRange(OC 侧会以 NSValue 包装传入)
        if let range = self.wy_validatedRange(rangeValue, fullLength: fullLength) {
            return (.range, [[range]])
        }
        
        // 数组 → 逐元素解析并按元素分组，元素类型决定最终返回值类型
        if let elements = rangeValue as? [Any] {
            guard !elements.isEmpty else { return (.rangeArray, []) }
            var elementTargets: [[NSRange]] = []
            var containsString = false
            var containsRange = false
            for element in elements {
                if let keyword = element as? String {
                    containsString = true
                    elementTargets.append(self.string.wy_parseRanges(from: keyword))
                } else if let range = self.wy_validatedRange(element, fullLength: fullLength) {
                    containsRange = true
                    elementTargets.append([range])
                } else {
                    elementTargets.append([])
                }
            }
            let valueStyle: WYTextBoundingInfos.WYTextBoundingInfoValueStyle = (containsString && containsRange) ? .stringAndRange : (containsString ? .stringArray : .rangeArray)
            return (valueStyle, elementTargets)
        }
        
        return (.rangeArray, [])
    }
    
    /// 把 NSRange 或 NSValue 包装的 NSRange 校验并裁剪到有效范围内(无法识别的类型或无交集时返回 nil)
    func wy_validatedRange(_ value: Any, fullLength: Int) -> NSRange? {
        
        if let range = value as? NSRange {
            let clipped = NSIntersectionRange(range, NSRange(location: 0, length: fullLength))
            return clipped.length > 0 ? clipped : nil
        }
        
        // OC 侧的 NSRange 以 NSValue 传入，objCType 为 {_NSRange=QQ} 时才可安全取 rangeValue
        if let nsValue = value as? NSValue, strcmp(nsValue.objCType, "{_NSRange=QQ}") == 0 {
            let clipped = NSIntersectionRange(nsValue.rangeValue, NSRange(location: 0, length: fullLength))
            return clipped.length > 0 ? clipped : nil
        }
        
        return nil
    }
}
