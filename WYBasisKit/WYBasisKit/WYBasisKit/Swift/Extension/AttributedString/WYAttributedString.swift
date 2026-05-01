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
     设置富文本中指定范围或字符串的颜色
     
     - Parameter colorRanges: 颜色与范围对应的字典序列，每个字典包含一个颜色键和对应的范围值
     
     - Note: 范围参数支持三种格式：
     1. 字符串格式：自动查找字符串中首次出现的该子串并应用颜色
     2. 范围数组：["起始位置字符串", "长度字符串"] 如 ["0", "5"]
     3. 字符串格式与范围数组组合
     
     使用示例：
     // 通过字符串匹配设置颜色
     attributedString.wy_colorsOfRanges(
         [
             .red: "需要标红的文本",
             .blue: "蓝色文本"
         ]
     )
     
     // 通过范围设置颜色
     attributedString.wy_colorsOfRanges(
         [
             .red: ["0", "5"],  // 从第0个字符开始，长度为5
             .blue: ["10", "3"]  // 从第10个字符开始，长度为3
         ]
     )
     
     // 通过组合设置颜色
     attributedString.wy_colorsOfRanges(
         [
             .red: "需要标红的文本",
             .blue: ["10", "3"]  // 从第10个字符开始，长度为3
         ]
     )
     */
    @discardableResult
    func wy_colorsOfRanges(_ colorRanges: Dictionary<UIColor, Any>) -> NSMutableAttributedString {
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
     设置富文本中指定范围或字符串的字体
     
     - Parameter fontRanges: 字体与范围对应的字典序列，每个字典包含一个字体键和对应的范围值
     
     - Note: 范围参数支持三种格式：
     1. 字符串格式：自动查找字符串中首次出现的该子串并应用字体
     2. 范围数组：["起始位置字符串", "长度字符串"] 如 ["0", "5"]
     3. 字符串格式与范围数组组合
     
     使用示例：
     // 通过字符串匹配设置字体
     attributedString.wy_fontsOfRanges(
         [
             UIFont.boldSystemFont(ofSize: 16): "加粗文本", UIFont.italicSystemFont(ofSize: 14): "斜体文本"
         ]
     )
     
     // 通过范围设置字体
     attributedString.wy_fontsOfRanges(
         [
             UIFont.systemFont(ofSize: 18): ["0", "5"], UIFont.systemFont(ofSize: 12): ["10", "3"]
         ]
     )
     
     // 通过组合设置字体
     attributedString.wy_fontsOfRanges(
         [
             UIFont.boldSystemFont(ofSize: 16): "加粗文本", UIFont.systemFont(ofSize: 12): ["10", "3"] // 从第10个字符开始，长度为3
         ]
     )
     */
    @discardableResult
    func wy_fontsOfRanges(_ fontRanges: Dictionary<UIFont, Any>) -> NSMutableAttributedString {
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
     *  修改富文本字体(整个富文本统一设置字体)
     */
    @discardableResult
    func wy_setFont(_ font: UIFont) -> NSMutableAttributedString {
        addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: self.length))
        return self
    }
    
    /**
     *  设置行间距
     *
     *  - Parameters:
     *    - lineSpacing: 行间距值（单位：pt）
     *    - subString:  需要设置行间距的子字符串，传 `nil` 则对整个富文本生效
     *    - alignment:  段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 如果 `subString` 不为 `nil` 但在文本中未找到，则不会进行任何修改。
     */
    @discardableResult
    func wy_lineSpacing(_ lineSpacing: CGFloat, subString: String? = nil, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        
        // 确定目标范围（整个文本或指定子串）
        let targetRange = wy_range(for: subString)
        
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        // 获取或创建段落样式
        let paragraphStyle = wy_paragraphStyle(at: targetRange)
        
        // 设置新属性
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = alignment
        
        // 应用更新到目标范围
        self.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: targetRange
        )
        
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
     *  设置字间距（字符间距）
     *
     *  - Parameters:
     *    - wordsSpacing: 字间距值（单位：pt）
     *    - string:       需要设置字间距的子字符串，传 `nil` 则对整个富文本生效
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 如果 `string` 不为 `nil` 但在文本中未找到，则不会进行任何修改。
     */
    @discardableResult
    func wy_wordsSpacing(_ wordsSpacing: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        
        let targetRange = wy_range(for: string)
        
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        addAttribute(.kern, value: wordsSpacing, range: targetRange)
        
        return self
    }
    
    /**
     *  文本添加内边距
     *  @param string  要添加内边距的字符串，不传则代码所有字符串
     *  @param firstLineHeadIndent  首行左边距
     *  @param headIndent  第二行及以后的左边距(换行符\n除外)
     *  @param tailIndent  尾部右边距
     *  @param alignment  对齐方式
     */
    @discardableResult
    func wy_innerMargin(string: String? = nil,
                        firstLineHeadIndent: CGFloat = 0,
                        headIndent: CGFloat = 0,
                        tailIndent: CGFloat = 0,
                        alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        
        let targetRange = wy_range(for: string)
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        // 获取或创建段落样式
        let paragraphStyle = wy_paragraphStyle(at: targetRange)
        
        // 设置内边距属性
        paragraphStyle.alignment = alignment
        paragraphStyle.firstLineHeadIndent = firstLineHeadIndent
        paragraphStyle.headIndent = headIndent
        paragraphStyle.tailIndent = tailIndent
        
        // 应用更新到目标范围
        self.addAttribute(.paragraphStyle, value: paragraphStyle, range: targetRange)
        
        return self
    }
    
    /**
     *  调整文本基线偏移（实现文字上下移动）
     *
     *  - Parameters:
     *    - offset: 偏移量（单位：pt），**正值向上移动，负值向下移动**
     *    - string: 需要调整的子字符串，传 `nil` 则对整个富文本生效
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 如果 `string` 不为 `nil` 但在文本中未找到，则不会进行任何修改。
     */
    @discardableResult
    func wy_baseline(offset: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        
        let targetRange = wy_range(for: string)
        
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        addAttribute(.baselineOffset, value: offset, range: targetRange)
        return self
    }
    
    /**
     *  为文本添加下划线
     *
     *  - Parameters:
     *    - color:  下划线的颜色
     *    - string: 需要添加下划线的子字符串，传 `nil` 则对整个富文本生效
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 如果 `string` 不为 `nil` 但在文本中未找到，则不会进行任何修改。
     *          下划线样式为单线（`.single`）。
     */
    @discardableResult
    func wy_underline(color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        
        let targetRange = wy_range(for: string)
        
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: targetRange)
        addAttribute(.underlineColor, value: color, range: targetRange)
        
        return self
    }
    
    /**
     *  为文本添加删除线
     *
     *  - Parameters:
     *    - color:  删除线的颜色
     *    - string: 需要添加删除线的子字符串，传 `nil` 则对整个富文本生效
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象，支持链式调用
     *
     *  - Note: 如果 `string` 不为 `nil` 但在文本中未找到，则不会进行任何修改。
     *          删除线样式为单线（`.single`）。
     */
    @discardableResult
    func wy_strikethrough(color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        
        let targetRange = wy_range(for: string)
        guard targetRange.location != NSNotFound, targetRange.length > 0 else { return self }
        
        addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: targetRange)
        addAttribute(.strikethroughColor, value: color, range: targetRange)
        
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
     *  内部通用方法：根据 rangeValue 类型(字符串或区间数组)批量设置属性
     */
    private func wy_applyFontsOrColorsAttributes(key: NSAttributedString.Key, value: Any, rangeValue: Any) {
        
        if let rangeStr = rangeValue as? String {
            // 按字符串查找并设置属性
            if let range = self.string.range(of: rangeStr) {
                let nsRange = NSRange(range, in: self.string)
                addAttribute(key, value: value, range: nsRange)
            }
        } else if let rangeAry = rangeValue as? [String],
                  rangeAry.count == 2,
                  let location = Int(rangeAry[0]),
                  let length = Int(rangeAry[1]) {
            // 按区间范围设置属性
            let nsRange = NSRange(location: location, length: length)
            if nsRange.location + nsRange.length <= self.length {
                addAttribute(key, value: value, range: nsRange)
            }
        }
    }
    
    /// 获取包含指定范围的段落范围
    func wy_paragraphRange(containing range: Range<String.Index>, value: String) -> Range<String.Index>? {
        guard !value.isEmpty else { return nil }
        
        let paragraphStart = value[..<range.lowerBound].lastIndex(of: "\n") ?? value.startIndex
        let paragraphEnd = value[range.upperBound...].firstIndex(of: "\n") ?? value.endIndex
        return paragraphStart..<paragraphEnd
    }
    
    /**
     * 根据可选子字符串计算需要应用属性的范围
     * - Parameter string: 要查找的子字符串，如果为 nil 则返回整个富文本的范围
     * - Returns: 对应的 NSRange，如果子字符串未找到则返回无效范围 `(NSNotFound, 0)`
     */
    func wy_range(for string: String?) -> NSRange {
        // 如果没有指定子字符串，则对整个富文本生效
        guard let targetStr = string else {
            return NSRange(location: 0, length: self.length)
        }
        
        // 尝试在字符串中查找子串的位置
        if let range = self.string.range(of: targetStr) {
            return NSRange(range, in: self.string)
        }
        
        // 未找到子串，返回无效范围（后续需要进行有效性检查）
        return NSRange(location: NSNotFound, length: 0)
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
