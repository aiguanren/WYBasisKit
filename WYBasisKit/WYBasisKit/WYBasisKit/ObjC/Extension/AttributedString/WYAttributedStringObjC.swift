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
     设置富文本中指定范围或字符串的颜色
     
     - Parameter colorRanges: 颜色与范围对应的字典序列，每个字典包含一个字体键和对应的范围值
     
     - Note: 范围参数支持三种格式：
     1. 字符串格式：自动查找字符串中首次出现的该子串并应用颜色
     2. 范围数组：@{@"起始位置字符串", @"长度字符串"} 如 @{@"0", @"5"}
     3. 字符串格式与范围数组组合
     
     使用示例：
     // 通过字符串匹配设置颜色
     [attributedString wy_colorsOfRanges:@{
          UIColor.redColor: @"需要标红的文本",
          UIColor.blueColor: @"蓝色文本"
     }];
     
     // 通过范围设置颜色
     [attributedString wy_colorsOfRanges:@{
           @{UIColor.redColor: @[@"0", @"5"]}, // 从第0个字符开始，长度为5
           @{UIColor.blueColor: @[@"10", @"3"]}, // 从第10个字符开始，长度为3
     }];
     
     // 通过组合设置颜色
     [attributedString wy_colorsOfRanges:@{
          @{UIColor.redColor: @"需要标红的文本"},
          @{UIColor.blueColor: @[@"10", @"3"]}, // 从第10个字符开始，长度为3
     }];
     */
    @discardableResult
    @objc(wy_colorsOfRanges:)
    func wy_colorsOfRangesObjC(_ colorRanges: Dictionary<UIColor, Any>) -> NSMutableAttributedString {
        return wy_colorsOfRanges(colorRanges)
    }
    
    /**
     设置富文本中指定范围或字符串的字体
     
     - Parameter fontRanges: 字体与范围对应的字典序列，每个字典包含一个字体键和对应的范围值
     
     - Note: 范围参数支持三种格式：
     1. 字符串格式：自动查找字符串中首次出现的该子串并应用字体
     2. 范围数组：@{@"起始位置字符串", @"长度字符串"} 如 @{@"0", @"5"}
     3. 字符串格式与范围数组组合
     
     使用示例：
     // 通过字符串匹配设置字体
     attributedString.wy_fontsOfRanges:@{
         [UIFont.boldSystemFont(ofSize: 16): "加粗文本"],
         [UIFont.italicSystemFont(ofSize: 14): "斜体文本"]
     }];
     
     // 通过范围设置字体
     attributedString.wy_fontsOfRanges:@{
         [UIFont.systemFont(ofSize: 18): ["0", "5"]],
         [UIFont.systemFont(ofSize: 12): ["10", "3"]
     }];
     
     // 通过组合设置字体
     attributedString.wy_fontsOfRanges:@{
         [UIFont.boldSystemFont(ofSize: 16): "加粗文本"],
         [UIFont.systemFont(ofSize: 12): ["10", "3"] // 从第10个字符开始，长度为3
     }];
     */
    @discardableResult
    @objc(wy_fontsOfRanges:)
    func wy_fontsOfRangesObjC(_ fontRanges: Dictionary<UIFont, Any>) -> NSMutableAttributedString {
        return wy_fontsOfRanges(fontRanges)
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
    @objc(wy_lineSpacing:)
    func wy_lineSpacingObjC(_ lineSpacing: CGFloat) -> NSMutableAttributedString {
        return wy_lineSpacingObjC(lineSpacing, subString: nil, alignment: .left)
    }
    @discardableResult
    @objc(wy_alignment:)
    func wy_alignmentObjC(_ alignment: NSTextAlignment = .left) -> NSMutableAttributedString {
        return wy_lineSpacingObjC(0, subString: nil, alignment: alignment)
    }
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
    @objc(wy_wordsSpacing:)
    func wy_wordsSpacingObjC(_ wordsSpacing: CGFloat) -> NSMutableAttributedString {
        return wy_wordsSpacingObjC(wordsSpacing, string: nil)
    }
    @objc(wy_wordsSpacing:string:)
    func wy_wordsSpacingObjC(_ wordsSpacing: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        return wy_wordsSpacing(wordsSpacing, string: string)
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
    @objc func wy_innerMarginWith(firstLineHeadIndent: CGFloat = 0,
                                  headIndent: CGFloat = 0,
                                  tailIndent: CGFloat = 0,
                                  alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        return wy_innerMarginWith(string: nil, firstLineHeadIndent: firstLineHeadIndent, headIndent: headIndent, tailIndent: tailIndent, alignment: alignment)
    }
    @discardableResult
    @objc func wy_innerMarginWith(string: String?,
                                  firstLineHeadIndent: CGFloat = 0,
                                  headIndent: CGFloat = 0,
                                  tailIndent: CGFloat = 0,
                                  alignment: NSTextAlignment = .justified) -> NSMutableAttributedString {
        return wy_innerMargin(string: string, firstLineHeadIndent: firstLineHeadIndent, headIndent: headIndent, tailIndent: tailIndent, alignment: alignment)
    }
    
    /// 文本上下偏移(正数向上，负数向下)
    @discardableResult
    @objc func wy_baselineOffsetY(_ offset: CGFloat) -> NSMutableAttributedString {
        return wy_baseline(offset: offset)
    }
    @discardableResult
    @objc func wy_baselineOffsetY(_ offset: CGFloat, string: String? = nil) -> NSMutableAttributedString {
        return wy_baseline(offset: offset, string: string)
    }
    
    /// 文本添加下划线
    @discardableResult
    @objc func wy_underline(_ color: UIColor) -> NSMutableAttributedString {
        return wy_underline(color, string: nil)
    }
    @discardableResult
    @objc func wy_underline(_ color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        return wy_underline(color: color, string: string)
    }
    
    /// 文本添加删除线
    @discardableResult
    @objc func wy_strikethrough(_ color: UIColor) -> NSMutableAttributedString {
        return wy_strikethrough(color, string: nil)
    }
    @discardableResult
    @objc func wy_strikethrough(_ color: UIColor, string: String? = nil) -> NSMutableAttributedString {
        return wy_strikethrough(color: color, string: string)
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
    
    /// 获取每行显示的字符串(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    @objc func wy_stringPerLineWith(controlWidth: CGFloat) -> [String] {
        return wy_stringPerLine(controlWidth: controlWidth)
    }
    
    /// 判断字符串显示完毕需要几行(为了计算准确，尽量将使用到的属性如字间距、缩进、换行模式、字体等设置到调用本方法的attributedString对象中来, 没有用到的直接忽略)
    @objc func wy_numberOfRowsWith(controlWidth: CGFloat) -> Int {
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
