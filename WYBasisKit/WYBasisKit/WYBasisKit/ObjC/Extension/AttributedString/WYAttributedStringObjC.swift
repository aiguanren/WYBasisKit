//
//  AttributedStringObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/21.
//

import Foundation
import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc public extension NSMutableAttributedString {
    
    /**
     设置富文本中指定范围的颜色。
     - Parameter colorRanges: 字典，Key为颜色，Value为范围定义(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc func wy_setColorForRanges(_ colorRanges: [UIColor : Any]) -> NSMutableAttributedString {
        return wy_setColor(colorRanges)
    }
    
    /**
     设置富文本中指定范围的字体。
     - Parameter fontRanges: 字典，Key为字体，Value为范围定义(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc func wy_setFontForRanges(_ fontRanges: [UIFont : Any]) -> NSMutableAttributedString {
        return wy_setFont(fontRanges)
    }
    
    /**
     设置富文本中指定范围的背景色
     - Parameter color:       背景色
     - Parameter rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_setBackgroundColor:rangeValue:)
    func wy_setBackgroundColorObjC(_ color: UIColor, rangeValue: Any? = nil) -> NSMutableAttributedString {
        wy_setBackgroundColor(color, rangeValue: rangeValue)
    }
    
    /**
     *  设置富文本字体(整个富文本统一设置字体)
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_setFont:)
    func wy_setFontObjC(_ font: UIFont) -> NSMutableAttributedString {
        return wy_setFont(font)
    }
    
    /**
     *  设置富文本的截断方式(默认 `.byTruncatingTail`（尾部截断）)
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_setLineBreakMode:)
    func wy_setLineBreakModeObjC(_ lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> NSMutableAttributedString {
        return wy_setLineBreakMode(lineBreakMode)
    }
    
    /**
     *  设置行间距，支持多种范围定义

     *  - Parameters:
     *    - lineSpacing: 行间距值（单位：pt）
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *    - alignment:  段落对齐方式，默认为 `.left`
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_lineSpacing:rangeValue:alignment:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat, rangeValue: Any?, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacing(lineSpacing, rangeValue: rangeValue, alignment: alignment)
    }
    @discardableResult
    @objc(wy_lineSpacing:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat) -> NSMutableAttributedString {
        return wy_lineSpacing(lineSpacing, rangeValue: nil, alignment: .left)
    }
    @discardableResult
    @objc(wy_alignment:)
    func wy_alignmentObjC(_ alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacing(0, rangeValue: nil, alignment: alignment)
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
     *  - Returns: 当前 `NSMutableAttributedString` 对象，
     */
    @discardableResult
    @objc(wy_lineSpacing:beforeString:afterString:alignment:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat,
                            beforeString: String,
                            afterString: String,
                            alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacing(lineSpacing, beforeString: beforeString, afterString: afterString, alignment: alignment)
    }
    
    /**
     *  设置字间距（字符间距），支持多种范围定义
     *
     *  - Parameters:
     *    - wordsSpacing: 字间距值（单位：pt）
     *    - rangeValue:   范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_wordsSpacing:rangeValue:)
    func wy_wordsSpacingObjC(_ wordsSpacing: CGFloat, rangeValue: Any?) -> NSMutableAttributedString {
        return wy_wordsSpacing(wordsSpacing, rangeValue: rangeValue)
    }
    @discardableResult
    @objc(wy_wordsSpacing:)
    func wy_wordsSpacingObjC(_ wordsSpacing: CGFloat) -> NSMutableAttributedString {
        return wy_wordsSpacing(wordsSpacing, rangeValue: nil)
    }
    
    /**
     *  文本添加内边距，支持多种范围定义
     *
     *  - Parameters:
     *    - rangeValue:  范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *    - firstLineHeadIndent:  首行左边距
     *    - headIndent:  第二行及以后的左边距(换行符\n除外)
     *    - tailIndent:  尾部右边距
     *    - alignment:  对齐方式
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_innerMarginWithRangeValue:firstLineHeadIndent:headIndent:tailIndent:alignment:)
    func wy_innerMarginObjC(rangeValue: Any?,
                            firstLineHeadIndent: CGFloat = 0,
                            headIndent: CGFloat = 0,
                            tailIndent: CGFloat = 0,
                            alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        return wy_innerMargin(rangeValue: rangeValue, firstLineHeadIndent: firstLineHeadIndent, headIndent: headIndent, tailIndent: tailIndent, alignment: alignment)
    }
    @discardableResult
    @objc func wy_innerMarginWith(firstLineHeadIndent: CGFloat = 0,
                                  headIndent: CGFloat = 0,
                                  tailIndent: CGFloat = 0,
                                  alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        return wy_innerMargin(rangeValue: nil, firstLineHeadIndent: firstLineHeadIndent, headIndent: headIndent, tailIndent: tailIndent, alignment: alignment)
    }
    
    /**
     *  调整文本基线偏移（实现文字上下移动），支持多种范围定义
     *
     *  - Parameters:
     *    - offset: 偏移量（单位：pt），**正值向上移动，负值向下移动**
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_baselineOffsetY:rangeValue:)
    func wy_baselineObjC(offset: CGFloat, rangeValue: Any?) -> NSMutableAttributedString {
        return wy_baseline(offset: offset, rangeValue: rangeValue)
    }
    @discardableResult
    @objc func wy_baselineOffsetY(_ offset: CGFloat) -> NSMutableAttributedString {
        return wy_baseline(offset: offset, rangeValue: nil)
    }
    
    /**
     *  为文本添加下划线，支持多种范围定义
     *
     *  - Parameters:
     *    - color:  下划线的颜色
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_underline:rangeValue:)
    func wy_underlineObjC(color: UIColor, rangeValue: Any?) -> NSMutableAttributedString {
        return wy_underline(color: color, rangeValue: rangeValue)
    }
    @discardableResult
    @objc func wy_underline(_ color: UIColor) -> NSMutableAttributedString {
        return wy_underline(color: color, rangeValue: nil)
    }
    
    /**
     *  为文本添加删除线，支持多种范围定义
     *
     *  - Parameters:
     *    - color:  删除线的颜色
     *    - rangeValue: 范围定义，传 `nil` 则对整个富文本生效(支持类型：`String`、`NSRange(NSValue包装)`、`[String]`、`[NSRange(NSValue包装)]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange(NSValue包装)]`）)
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @discardableResult
    @objc(wy_strikethrough:rangeValue:)
    func wy_strikethroughObjC(color: UIColor, rangeValue: Any?) -> NSMutableAttributedString {
        return wy_strikethrough(color: color, rangeValue: rangeValue)
    }
    @discardableResult
    @objc func wy_strikethrough(_ color: UIColor) -> NSMutableAttributedString {
        return wy_strikethrough(color: color, rangeValue: nil)
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
    @objc(wy_insertImageWithAttachments:)
    func wy_insertImageObjC(_ attachments: [WYImageAttachmentOptionObjC]) -> NSMutableAttributedString {
        let swiftAttachments: [WYImageAttachmentOption] = attachments.map { objCOption in
            return WYImageAttachmentOption(
                image: objCOption.image,
                size: objCOption.size,
                position: {
                    switch objCOption.position {
                    case .before:
                        return .before(text: objCOption.positionValue as? String ?? "")
                    case .after:
                        return .after(text: objCOption.positionValue as? String ?? "")
                    case .index:
                        return .index((objCOption.positionValue as? NSNumber)?.intValue ?? 0)
                    }
                }(),
                offsetY: objCOption.offsetY,
                spacingBefore: objCOption.spacingBefore,
                spacingAfter: objCOption.spacingAfter
            )
        }
        return wy_insertImage(swiftAttachments)
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
    @objc static func wy_convertEmojiAttributed(_ emojiString: String, textColor: UIColor, textFont: UIFont, emojiTable: [String]) -> NSMutableAttributedString {
        return wy_convertEmojiAttributed(emojiString, textColor: textColor, textFont: textFont, emojiTable: emojiTable, sourceBundle: nil, pattern: nil)
    }
    @objc static func wy_convertEmojiAttributed(_ emojiString: String, textColor: UIColor, textFont: UIFont, emojiTable: [String], sourceBundle: WYSourceBundleObjC? = nil, pattern: String?) -> NSMutableAttributedString {
        return wy_convertEmojiAttributed(emojiString: emojiString, textColor: textColor, textFont: textFont, emojiTable: emojiTable, sourceBundle: sourceBundle?.wy_convertToSwift(), pattern: pattern ?? "\\[.{1,3}\\]")
    }
    
    /**
     *  将表情富文本生成对应的富文本字符串，例如表情富文本 "哈哈😄" 会生成 "哈哈[哈哈]"
     *  @param textColor     富文本的字体颜色
     *  @param textFont      富文本的字体
     *  @param replace       未知图片(表情)的标识替换符，默认：[未知]
     *
     *  - Returns: 当前 `NSMutableAttributedString` 对象
     */
    @objc func wy_convertEmojiAttributedString(_ textColor: UIColor, textFont: UIFont, replace: String = "[未知]") -> NSMutableAttributedString {
        return wy_convertEmojiAttributedString(textColor: textColor, textFont: textFont, replace: replace)
    }
}

@objc public extension NSAttributedString {
    
    /// 计算富文本宽度
    @objc func wy_calculateWidthWith(controlHeight: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: .greatestFiniteMagnitude, height: controlHeight)).width
    }
    
    /// 计算富文本高度
    @objc func wy_calculateHeightWith(controlWidth: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: controlWidth, height: .greatestFiniteMagnitude)).height
    }
    
    /// 计算富文本宽高
    @objc func wy_calculateSizeWith(controlSize: CGSize) -> CGSize {
        return wy_calculateSize(controlSize: controlSize)
    }
}

@objcMembers public class WYTextAttachmentObjC: NSTextAttachment {
    @objc public var imageName: String = ""
    @objc public var imageRange: NSRange = NSMakeRange(0, 0)
}

/// 富文本图片插入配置
@objc(WYImageAttachmentOption)
@objcMembers public class WYImageAttachmentOptionObjC: NSObject {
    
    /// 图片插入位置类型
    @objc(WYImageAttachmentPosition)
    @frozen public enum WYImageAttachmentPositionObjC: Int {
        /// 插入到文本前面
        case before = 0
        /// 插入到文本后面
        case after
        /// 根据文本下标插入到指定位置
        case index
    }
    
    /// 要插入的图片
    @objc public let image: UIImage
    
    /// 图片尺寸
    @objc public let size: CGSize
    
    /// 图片插入位置类型
    @objc public let position: WYImageAttachmentPositionObjC
    
    /// 插入位置的参数（before/after 时传 NSString，index 时传 NSNumber）
    @objc public let positionValue: Any?
    
    /// 图片相对于文本的偏移量(正值向上，负值向下)
    public let offsetY: CGFloat
    
    /// 图片与前面文本的间距（单位：pt）
    @objc public let spacingBefore: CGFloat
    
    /// 图片与后面文本的间距（单位：pt）
    @objc public let spacingAfter: CGFloat
    
    @objc public init(image: UIImage,
                      size: CGSize,
                      position: WYImageAttachmentPositionObjC,
                      positionValue: Any? = nil,
                      offsetY: CGFloat = 0,
                      spacingBefore: CGFloat = 0,
                      spacingAfter: CGFloat = 0) {
        self.image = image
        self.size = size
        self.position = position
        self.positionValue = positionValue
        self.offsetY = offsetY
        self.spacingBefore = spacingBefore
        self.spacingAfter = spacingAfter
    }
}
