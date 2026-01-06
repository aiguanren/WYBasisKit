//
//  AttributedStringObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/21.
//

import Foundation
import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension NSMutableAttributedString {
    
    /**
     *  需要修改的字符颜色数组及量程，由字典组成  key = 颜色   value = 量程或需要修改的字符串
     *  例：NSArray *colorsOfRanges = @[@{color:@[@"0",@"1"]},@{color:@[@"1",@"2"]}]
     *  或：NSArray *colorsOfRanges = @[@{color:str},@{color:str}]
     */
    @discardableResult
    @objc(wy_colorsOfRanges:)
    func wy_colorsOfRangesObjC(_ colorsOfRanges: Array<Dictionary<UIColor, Any>>) -> NSMutableAttributedString {
        return wy_colorsOfRanges(colorsOfRanges)
    }
    
    /**
     *  需要修改的字符字体数组及量程，由字典组成  key = 颜色   value = 量程或需要修改的字符串
     *  例：NSArray *fontsOfRanges = @[@{font:@[@"0",@"1"]},@{font:@[@"1",@"2"]}]
     *  或：NSArray *fontsOfRanges = @[@{font:str},@{font:str}]
     */
    @discardableResult
    @objc(wy_fontsOfRanges:)
    func wy_fontsOfRangesObjC(_ fontsOfRanges: Array<Dictionary<UIFont, Any>>) -> NSMutableAttributedString {
        return wy_fontsOfRanges(fontsOfRanges)
    }
    
    /**
     *  修改富文本字体(整个富文本统一设置字体)
     */
    @discardableResult
    @objc(wy_setFont:)
    func wy_setFontObjC(_ font: UIFont) -> NSMutableAttributedString {
        return wy_setFont(font)
    }
    
    /// 设置行间距
    @discardableResult
    @objc(wy_lineSpacing:subString:alignment:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat, subString: String? = nil, alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacing(lineSpacing, subString: subString, alignment: alignment)
    }
    
    /// 设置不同段落间的行间距
    @discardableResult
    @objc(wy_lineSpacing:beforeString:afterString:alignment:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat,
                                  beforeString: String,
                                  afterString: String,
                                  alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacing(lineSpacing, beforeString: beforeString, afterString: afterString, alignment: alignment)
    }
    
    /// 设置字间距
    @discardableResult
    @objc(wy_wordsSpacing:string:)
    func wy_wordsSpacingObjC(_ wordsSpacing: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        return wy_wordsSpacing(wordsSpacing, string: string)
    }
    
    /// 文本添加下划线
    @discardableResult
    @objc func wy_underline(_ color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        return wy_underline(color: color, string: string)
    }
    
    /// 文本添加删除线
    @discardableResult
    @objc func wy_strikethrough(_ color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        return wy_strikethrough(color: color, string: string)
    }
    
    /**
     *  文本添加内边距
     *  @param string  要添加内边距的字符串，不传则代码所有字符串
     *  @param firstLineHeadIndent  首行左边距
     *  @param headIndent  第二行及以后的左边距(换行符\n除外)
     *  @param tailIndent  尾部右边距
     */
    @discardableResult
    @objc func wy_innerMargin(with string: String?,
                                  firstLineHeadIndent: CGFloat = 0,
                                  headIndent: CGFloat = 0,
                                  tailIndent: CGFloat = 0,
                                  alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        return wy_innerMargin(string: string, firstLineHeadIndent: firstLineHeadIndent, headIndent: headIndent, tailIndent: tailIndent, alignment: alignment)
    }
    
    /**
     向富文本中插入图片（支持图文混排，自动处理位置和对齐方式）
     
     - Parameter attachments: 富文本图片插入配置数组，每个元素定义了图片、位置、尺寸、对齐方式和间距
     - Returns: 当前 NSMutableAttributedString 对象本身（链式返回）
     
     使用说明：
     1. position 支持插入到指定文本前/后或指定字符下标处；
     2. alignment 支持图片在字体行内的垂直对齐方式；
     3. spacingBefore / spacingAfter 可用于设置插入图片前后的间距；
     */
    @discardableResult
    @objc(wy_insertImage:)
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
                alignment: {
                    switch objCOption.alignment {
                    case .center:
                        return .center
                    case .top:
                        return .top
                    case .bottom:
                        return .bottom
                    case .custom:
                        return .custom(offset: objCOption.alignmentOffset)
                    }
                }(),
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
     */
    @objc static func wy_convertEmojiAttributed(_ emojiString: String, textColor: UIColor, textFont: UIFont, emojiTable: [String], sourceBundle: WYSourceBundleObjC? = nil, pattern: String?) -> NSMutableAttributedString {
        
        return wy_convertEmojiAttributed(emojiString: emojiString, textColor: textColor, textFont: textFont, emojiTable: emojiTable, sourceBundle: sourceBundle?.wy_convertToSwift(), pattern: pattern ?? "\\[.{1,3}\\]")
    }
    
    /**
     *  将表情富文本生成对应的富文本字符串，例如表情富文本 "哈哈😄" 会生成 "哈哈[哈哈]"
     *  @param textColor     富文本的字体颜色
     *  @param textFont      富文本的字体
     *  @param replace       未知图片(表情)的标识替换符，默认：[未知]
     */
    @objc func wy_convertEmojiAttributedString(_ textColor: UIColor, textFont: UIFont, replace: String = "[未知]") -> NSMutableAttributedString {
        return wy_convertEmojiAttributedString(textColor: textColor, textFont: textFont, replace: replace)
    }
}

@objc public extension NSAttributedString {
    
    /// 获取某段文字的frame
    @objc(wy_calculateFrameWithRange:controlSize:numberOfLines:lineBreakMode:)
    func wy_calculateFrame(_ range: NSRange, controlSize: CGSize, numberOfLines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> CGRect {
        return wy_calculateFrame(range: range, controlSize: controlSize, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)
    }
    
    /// 获取某段文字的frame
    @objc(wy_calculateFrameWithSubString:controlSize:numberOfLines:lineBreakMode:)
    func wy_calculateFrameObjC(subString: String, controlSize: CGSize, numberOfLines: Int = 0, lineBreakMode: NSLineBreakMode = .byWordWrapping) -> CGRect {
        return wy_calculateFrame(subString: subString, controlSize: controlSize, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)
    }
    
    /// 计算富文本宽度
    @objc func wy_calculateWidth(_ controlHeight: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: .greatestFiniteMagnitude, height: controlHeight)).width
    }
    
    /// 计算富文本高度
    @objc func wy_calculateHeight(_ controlWidth: CGFloat) -> CGFloat {
        return wy_calculateSize(controlSize: CGSize(width: controlWidth, height: .greatestFiniteMagnitude)).height
    }
    
    /// 计算富文本宽高
    @objc(wy_calculateSize:)
    func wy_calculateSize(_ controlSize: CGSize) -> CGSize {
        return wy_calculateSize(controlSize: controlSize)
    }
    
    /// 获取每行显示的字符串(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    @objc func wy_stringPerLine(_ controlWidth: CGFloat) -> [String] {
        return wy_stringPerLine(controlWidth: controlWidth)
    }
    
    /// 判断字符串显示完毕需要几行(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    @objc func wy_numberOfRows(_ controlWidth: CGFloat) -> Int {
        return wy_numberOfRows(controlWidth: controlWidth)
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
        /// 根据文本下标插入到指定为止
        case index
    }
    
    /// 图片对齐方式类型
    @objc(WYImageAttachmentAlignment)
    @frozen public enum WYImageAttachmentAlignmentObjC: Int {
        /// 与文本居中对齐
        case center = 0
        /// 与文本顶部对齐
        case top
        /// 与文本底部对齐
        case bottom
        /// 相对文本底部(Y轴)自定义偏移量对齐(负向上，正向下)
        case custom
    }
    
    /// 要插入的图片
    @objc public let image: UIImage
    
    /// 图片尺寸
    @objc public let size: CGSize
    
    /// 图片插入位置类型
    @objc public let position: WYImageAttachmentPositionObjC
    
    /// 插入位置的参数（before/after 时传 NSString，index 时传 NSNumber）
    @objc public let positionValue: Any?
    
    /// 图片对齐方式类型
    @objc public let alignment: WYImageAttachmentAlignmentObjC
    
    /// 自定义对齐偏移量（仅在 alignmentType = .custom 时生效，负向上，正向下）
    @objc public let alignmentOffset: CGFloat
    
    /// 图片与前面文本的间距（单位：pt）
    @objc public let spacingBefore: CGFloat
    
    /// 图片与后面文本的间距（单位：pt）
    @objc public let spacingAfter: CGFloat
    
    @objc public init(image: UIImage,
                      size: CGSize,
                      position: WYImageAttachmentPositionObjC,
                      positionValue: Any? = nil,
                      alignment: WYImageAttachmentAlignmentObjC = .center,
                      alignmentOffset: CGFloat = 0,
                      spacingBefore: CGFloat = 0,
                      spacingAfter: CGFloat = 0) {
        self.image = image
        self.size = size
        self.position = position
        self.positionValue = positionValue
        self.alignment = alignment
        self.alignmentOffset = alignmentOffset
        self.spacingBefore = spacingBefore
        self.spacingAfter = spacingAfter
    }
}
