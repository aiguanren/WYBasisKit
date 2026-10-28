//
//  WYLabel+TextLayout.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import CoreText
import Foundation

/**
 *  基于 TextKit 的文本排版引擎，一次排版后对外提供每行矩形、每行字符范围、文本块整体高度、坐标反查字符下标与任意子范围的分行矩形
 *
 *  内部走 TextKit2(NSTextLayoutManager)，与 UILabel 渲染同源，系统字体与第三方自定义字体的行高、基线、换行位置均与实际显示一致。
 *  供 WYLabel 的富文本点击命中与 WYAttributedString 的 wy_calculateFrame 共用，
 *  排版结果在初始化时一次算好，后续查询只读缓存数据，重复命中检测(如滑动列表)不会重复排版。
 */
final class WYTextLayoutEngine {

    /// 每行文本的实际显示矩形(x 已含水平对齐偏移，y 从文本内容顶部向下，宽度为该行内容的紧凑宽度)
    let lineRects: [CGRect]

    /// 每行文本在整个字符串中的字符范围(与 lineRects 下标一一对应，行尾换行符属于所在行)
    let lineCharacterRanges: [NSRange]

    /// 文本块整体高度(全部行高度之和，含行间距，用于垂直居中换算)
    let textBlockHeight: CGFloat

    /**
     *  用指定尺寸对富文本排版
     *
     *  @param attributedText  要排版的富文本(字体、行间距、字间距、对齐、缩进、换行模式等属性请提前设置进该对象，排版结果才会与预期一致)
     *  @param containerSize   排版容器尺寸(宽高传 .greatestFiniteMagnitude 表示不限制)
     *  @param numberOfLines   最大行数，0 表示不限制(与 UILabel.numberOfLines 语义一致)
     *  @param lineBreakMode   换行/截断模式(与 UILabel.lineBreakMode 语义一致)
     */
    init(attributedText: NSAttributedString, containerSize: CGSize, numberOfLines: Int, lineBreakMode: NSLineBreakMode) {

        let layout = Self.wy_layoutTextKit2Capped(attributedText: attributedText, containerSize: containerSize, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)
        lineRects = layout.rects
        lineCharacterRanges = layout.ranges
        textBlockHeight = layout.blockHeight
        if let realLayout = layout.layout {
            tk2Storage = realLayout
        } else {
            tk2Storage = nil
        }
        tk1Layout = nil
    }

    /**
     *  反查指定坐标点落在哪个字符上
     *
     *  @param point 排版坐标系中的位置(y 从文本内容顶部向下，与 lineRects 同一坐标系)
     *  @return 字符在整个字符串中的下标，没有任何行(如空字符串)时返回 nil
     */
    func characterIndex(at point: CGPoint) -> Int? {

        guard !lineRects.isEmpty else { return nil }

        guard let layout = tk2Storage as? WYTextKit2Layout else { return nil }
        return Self.wy_tk2CharacterIndex(at: point, lineRects: lineRects, layout: layout)
    }

    /**
     *  获取任意子范围文本的分行显示矩形(一个范围跨多行时会按行拆成多个矩形)
     *
     *  @param range 要查询的字符范围(越界部分会被自动裁剪到有效范围内)
     *  @return 每行一个 WYTextBoundingRects(含矩形、该行内的子串与子范围)，范围为空或无交集时返回空数组
     */
    func wy_boundingRects(for range: NSRange) -> [WYTextBoundingRects] {

        let clipped = NSIntersectionRange(range, NSRange(location: 0, length: totalLength))
        guard clipped.length > 0, !lineRects.isEmpty else { return [] }

        guard let layout = tk2Storage as? WYTextKit2Layout else { return [] }
        let segments = Self.wy_tk2BoundingRects(for: clipped, layout: layout)
        guard layout.isLineCapped, let lastRect = lineRects.last, let lastLineRange = lineCharacterRanges.last else { return segments }
        /**
         *  行数受限截断时，末行之上的可见行保留原始行片段矩形(矩形更紧凑)，末行可见内容按裁剪后的行范围构造
         *  截断头部/中间的末行显示的是全文末尾内容，其原始位置在被截掉的行上，不能用原始行片段反查；截断尾部的末行可见终点就是 totalLength，clipped 已自动裁到可见边界
         */
        var results = segments.filter { $0.rect.midY < lastRect.midY }
        let intersection = NSIntersectionRange(clipped, lastLineRange)
        if intersection.length > 0 {
            let nsString = (layout.contentStorage.attributedString?.string ?? "") as NSString
            results.append(WYTextBoundingRects(rect: lastRect, string: nsString.substring(with: intersection), range: intersection))
        }
        return results
    }

    /// TextKit2 排版对象(以 Any 装箱存储，使用处再解箱)
    private let tk2Storage: Any?

    /// TextKit1 排版对象
    private let tk1Layout: WYTextKit1Layout?

    /// 排版文本的 UTF-16 总长度(用于裁剪越界范围)
    private var totalLength: Int {
        return lineCharacterRanges.last.map { NSMaxRange($0) } ?? 0
    }

    /// TextKit2 行片段 characterIndex(for:) 的索引基准(不同系统版本返回基准存在差异，排版时探测一次统一换算)
    private enum WYTK2IndexBase {
        /// 返回整个字符串内的下标
        case absolute
        /// 返回所在段落内的下标
        case paragraph
        /// 返回所在行内的下标
        case line
    }

    /// TextKit2 排版对象包(保留强引用供后续查询使用，行片段对象与段落偏移下标和 lineRects 一一对应)
    private final class WYTextKit2Layout {
        let contentStorage: NSTextContentStorage
        let layoutManager: NSTextLayoutManager
        let container: NSTextContainer
        /// 每行的行片段对象与其所在段落偏移(下标与 lineRects 一致，供坐标反查使用)
        let lineFragments: [(line: NSTextLineFragment, paragraphOffset: Int)]
        /// characterIndex(for:) 的索引基准(排版时探测得到)
        let indexBase: WYTK2IndexBase
        /// 是否为行数受限截断的排版(截断后末行可见内容与原始行片段不一致，矩形查询要走引擎保留的可见行范围)
        let isLineCapped: Bool

        init(contentStorage: NSTextContentStorage, layoutManager: NSTextLayoutManager, container: NSTextContainer, lineFragments: [(line: NSTextLineFragment, paragraphOffset: Int)], indexBase: WYTK2IndexBase, isLineCapped: Bool = false) {
            self.contentStorage = contentStorage
            self.layoutManager = layoutManager
            self.container = container
            self.lineFragments = lineFragments
            self.indexBase = indexBase
            self.isLineCapped = isLineCapped
        }

        /// 把行片段反查到的原始下标换算成整个字符串内的下标
        func wy_absoluteIndex(_ rawIndex: Int, line: NSTextLineFragment, paragraphOffset: Int) -> Int {
            switch indexBase {
            case .absolute:
                return rawIndex
            case .paragraph:
                return paragraphOffset + rawIndex
            case .line:
                return paragraphOffset + line.characterRange.location + rawIndex
            }
        }

        /// 把行片段反查到的原始下标换算成所在段落内的下标
        func wy_paragraphIndex(_ rawIndex: Int, line: NSTextLineFragment, paragraphOffset: Int) -> Int {
            switch indexBase {
            case .absolute:
                return rawIndex - paragraphOffset
            case .paragraph:
                return rawIndex
            case .line:
                return line.characterRange.location + rawIndex
            }
        }
    }

    /// TextKit1 排版对象包(保留强引用供后续查询使用)
    private final class WYTextKit1Layout {
        let layoutManager: NSLayoutManager
        let container: NSTextContainer

        init(layoutManager: NSLayoutManager, container: NSTextContainer) {
            self.layoutManager = layoutManager
            self.container = container
        }
    }

    /// TextKit2 排版过程与结果(rects/ranges/blockHeight 与 lineRects/lineCharacterRanges/textBlockHeight 对应)
    private final class WYTextLayoutOutput {
        let rects: [CGRect]
        let ranges: [NSRange]
        let blockHeight: CGFloat
        let layout: WYTextKit2Layout?

        init(rects: [CGRect], ranges: [NSRange], blockHeight: CGFloat, layout: WYTextKit2Layout?) {
            self.rects = rects
            self.ranges = ranges
            self.blockHeight = blockHeight
            self.layout = layout
        }
    }

    /// TextKit1 排版过程与结果
    private final class WYTextLayoutOutput1 {
        let rects: [CGRect]
        let ranges: [NSRange]
        let blockHeight: CGFloat
        let layout: WYTextKit1Layout?

        init(rects: [CGRect], ranges: [NSRange], blockHeight: CGFloat, layout: WYTextKit1Layout?) {
            self.rects = rects
            self.ranges = ranges
            self.blockHeight = blockHeight
            self.layout = layout
        }
    }

    /**
     *  推导排版容器高度上限，在传入高度上补 2pt 余量(UILabel 的内在高度与其内部排版的行高存在亚像素级取整出入，容器高度卡得太死会把最后一行整体裁掉，导致行矩形与实际显示错位、命中偏移)
     *  行数有限的截断场景由 wy_layoutTextKit2Capped 把高度精确钳到第 N 行底部，这里只负责不限行数的排版
     */
    private static func wy_layoutHeightLimit(containerSize: CGSize, numberOfLines: Int) -> CGFloat {
        if numberOfLines > 0 {
            // 单行高度现实中远小于 1000pt，按行数加一行余量推导的有限上限足够容纳全部行
            return min(containerSize.height, CGFloat(numberOfLines + 1) * 1000)
        }
        return min(containerSize.height + 2, CGFloat.greatestFiniteMagnitude)
    }

    /**
     *  不限行数时把富文本内各段落的换行模式归一到目标换行模式，返回原对象或可变副本
     *  段落样式的换行模式默认值是 byTruncatingTail(设置过行间距、对齐等属性的富文本都会携带)，
     *  TextKit2 对段落截断模式加不限行数加充裕有限高度的组合会把全部文字并进第一行，截断由容器的 lineBreakMode 统一控制(与 UILabel 内部实现一致)，段落归一不影响显示语义，
     *  段落与容器必须归一到同一换行模式(TextKit 排版段落样式优先于容器设置，只改容器不改段落会导致按字换行时引擎与 UILabel 实际显示逐行错位)，
     *  UILabel 不限行数时的实际换行只有 byCharWrapping 按字，截断类与 byClipping 都按词
     */
    private static func wy_wordWrappedAttributed(_ attributedText: NSAttributedString, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> NSAttributedString {

        guard numberOfLines <= 0, attributedText.length > 0 else { return attributedText }

        // 不限行数时段落与容器统一到的换行模式(仅 byCharWrapping 按字换行，截断类与 byClipping 都按词换行)
        let wrapMode: NSLineBreakMode = lineBreakMode == .byCharWrapping ? .byCharWrapping : .byWordWrapping

        let fullRange = NSRange(location: 0, length: attributedText.length)
        var containsDifferent = false
        attributedText.enumerateAttribute(.paragraphStyle, in: fullRange) { value, _, _ in
            if let style = value as? NSParagraphStyle, style.lineBreakMode != wrapMode {
                containsDifferent = true
            }
        }
        guard containsDifferent else { return attributedText }

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            guard let style = value as? NSParagraphStyle, style.lineBreakMode != wrapMode else { return }
            let mutableStyle = style.mutableCopy() as! NSMutableParagraphStyle
            mutableStyle.lineBreakMode = wrapMode
            mutable.addAttribute(.paragraphStyle, value: mutableStyle, range: range)
        }
        return mutable
    }

    /**
     *  TextKit2 排版的外层包装(仅处理 numberOfLines 大于 0 的场景)
     *  TextKit2 的容器截断(maximumNumberOfLines 加截断模式)在部分系统版本上会把全部文字并进第一行，
     *  所以行数限制统一在引擎层实现，先不限行数排一次，文本未超限直接用该结果，超限则裁掉多余行并对末行按截断方式裁剪可见内容
     *  行数受限时 UILabel 的真实末行显示为截断尾部/直接裁剪保留末行开头(前者省略号在前者预留宽度、后者不预留)
     *  截断头部显示"…+全文末尾内容"，截断中间显示"末行开头…+全文末尾内容"，显示内容不按顺序
     */
    private static func wy_layoutTextKit2Capped(attributedText: NSAttributedString, containerSize: CGSize, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> WYTextLayoutOutput {

        guard numberOfLines > 0 else {
            return wy_layoutTextKit2(attributedText: attributedText, containerSize: containerSize, numberOfLines: 0, lineBreakMode: lineBreakMode)
        }

        let unlimited = wy_layoutTextKit2(attributedText: attributedText, containerSize: containerSize, numberOfLines: 0, lineBreakMode: lineBreakMode)

        // 文本没有超过行数限制，无需截断，直接用不限行数的排版结果
        guard unlimited.ranges.count > numberOfLines,
              let unlimitedLayout = unlimited.layout else {
            return unlimited
        }

        let rects = Array(unlimited.rects.prefix(numberOfLines))
        var ranges = Array(unlimited.ranges.prefix(numberOfLines))
        let fragments = Array(unlimitedLayout.lineFragments.prefix(numberOfLines))

        // 末行可见内容按截断方式裁剪(行数受限时末行会跨过原换行边界按可用宽度连续填充，不能只在原行片段内探测)
        if let lastRange = ranges.last {
            // 直接裁剪不显示省略号，右缘预留宽度为 0，其余模式按末行字体省略号宽度预留
            let ellipsisWidth = lineBreakMode == .byClipping ? 0 : Self.wy_ellipsisWidth(attributedText: attributedText, at: lastRange.location)

            switch lineBreakMode {
            case .byTruncatingHead:
                // 截断头部:末行显示"…+全文末尾内容"，末尾内容跨原行重排成一行，从文末向前用排版断行建议找放得下的最长后缀
                let tail = Self.wy_tailFittingSuffix(of: attributedText, availableWidth: containerSize.width - ellipsisWidth)
                if tail.range.length > 0 {
                    ranges[ranges.count - 1] = tail.range
                }
            case .byTruncatingMiddle:
                /**
                 *  截断中间时末行显示"末行开头…+全文末尾内容"，末尾段按约一半预算量出占宽，开头段在剩余宽度内按断行建议连续填充
                 *  行字符范围是单个连续区间，末行只能表达开头段，末尾段的全文末尾内容暂无法合进同一行范围
                 */
                let tail = Self.wy_tailFittingSuffix(of: attributedText, availableWidth: (containerSize.width - ellipsisWidth) / 2)
                let prefixLength = Self.wy_typesetterVisibleLength(of: attributedText, from: lastRange.location, budget: containerSize.width - ellipsisWidth - tail.width)
                let visibleEnd = min(attributedText.length, lastRange.location + max(1, prefixLength))
                if visibleEnd > lastRange.location {
                    ranges[ranges.count - 1] = NSRange(location: lastRange.location, length: visibleEnd - lastRange.location)
                }
            case .byClipping:
                // 直接裁剪，从末行起点按全宽簇断行建议连续填充，行尾的 CJK 标点按系统标点悬挂/压缩规则补入(显示时压缩悬挂在行尾，簇断行建议按全宽计算未计入)
                var visibleLength = Self.wy_typesetterVisibleLength(of: attributedText, from: lastRange.location, budget: containerSize.width)
                let punctuationEnd = lastRange.location + visibleLength
                if punctuationEnd < attributedText.length {
                    let nextScalar = (attributedText.string as NSString).character(at: punctuationEnd)
                    if "。，、；：！？）》」』".unicodeScalars.contains(where: { $0.value == nextScalar }) {
                        visibleLength += 1
                    }
                }
                let visibleEnd = min(attributedText.length, lastRange.location + max(1, visibleLength))
                ranges[ranges.count - 1] = NSRange(location: lastRange.location, length: visibleEnd - lastRange.location)
            default:
                // 截断尾部与换行类(行数受限时 UILabel 默认按尾部截断):从末行起点按预算用簇断行建议连续填充(可越过原换行边界，行尾标点压缩也由排版器处理)
                let visibleLength = Self.wy_typesetterVisibleLength(of: attributedText, from: lastRange.location, budget: containerSize.width - ellipsisWidth)
                let visibleEnd = min(attributedText.length, lastRange.location + max(1, visibleLength))
                ranges[ranges.count - 1] = NSRange(location: lastRange.location, length: visibleEnd - lastRange.location)
            }
        }

        let blockHeight = rects.map({ $0.maxY }).max() ?? 0
        let layout = WYTextKit2Layout(contentStorage: unlimitedLayout.contentStorage,
                                      layoutManager: unlimitedLayout.layoutManager,
                                      container: unlimitedLayout.container,
                                      lineFragments: fragments,
                                      indexBase: unlimitedLayout.indexBase,
                                      isLineCapped: true)
        return WYTextLayoutOutput(rects: rects, ranges: ranges, blockHeight: blockHeight, layout: layout)
    }

    /// 用 CTTypesetter 簇断行建议测从 from 起放得下 budget 宽度的连续可见字符数(与系统截断行填充同源，逐字符簇连续填充可越过换行边界，行尾标点压缩也由排版器处理)
    private static func wy_typesetterVisibleLength(of attributedText: NSAttributedString, from: Int, budget: CGFloat) -> Int {
        guard attributedText.length > from, budget > 0 else { return 0 }
        let typesetter = CTTypesetterCreateWithAttributedString(attributedText)
        return CTTypesetterSuggestClusterBreak(typesetter, from, Double(budget))
    }

    /// 从文本末尾向前用 CTTypesetter 簇断行建议找放得下可用宽度的最长后缀及其占宽(截断头部/截断中间在行数受限时末行显示的全文末尾内容会被重排成一行)
    private static func wy_tailFittingSuffix(of attributedText: NSAttributedString, availableWidth: CGFloat) -> (range: NSRange, width: CGFloat) {

        let total = attributedText.length
        guard total > 0, availableWidth > 0 else { return (NSRange(location: total, length: 0), 0) }
        let typesetter = CTTypesetterCreateWithAttributedString(attributedText)
        var start = total - 1
        while start > 0 {
            let suggested = CTTypesetterSuggestClusterBreak(typesetter, start - 1, Double(availableWidth))
            if start - 1 + suggested < total { break }
            start -= 1
        }
        let suffix = attributedText.attributedSubstring(from: NSRange(location: start, length: total - start))
        let width = CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(suffix), []).width
        return (NSRange(location: start, length: total - start), width)
    }

    /// 测量省略号在指定下标字体下的宽度(末行可见边界裁剪的右缘预留量)
    private static func wy_ellipsisWidth(attributedText: NSAttributedString, at location: Int) -> CGFloat {

        let safeLocation = min(max(0, location), max(0, attributedText.length - 1))
        let font = attributedText.attribute(.font, at: safeLocation, effectiveRange: nil) as? UIFont ?? .systemFont(ofSize: 17)
        return NSAttributedString(string: "…", attributes: [.font: font]).size().width
    }

    /// TextKit2 排版(NSTextContentStorage + NSTextLayoutManager)
    private static func wy_layoutTextKit2(attributedText: NSAttributedString, containerSize: CGSize, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> WYTextLayoutOutput {

        let layoutText = wy_wordWrappedAttributed(attributedText, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)

        let contentStorage = NSTextContentStorage()
        contentStorage.attributedString = layoutText

        let layoutManager = NSTextLayoutManager()
        let container = NSTextContainer(size: CGSize(width: containerSize.width,
                                                     height: Self.wy_layoutHeightLimit(containerSize: containerSize, numberOfLines: numberOfLines)))
        // 行内边距归零，保证行矩形与文字实际位置一致(UILabel 内部排版同样不保留默认 5pt 边距)
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = max(0, numberOfLines)
        // 不限行数时截断模式没有意义(TextKit2 对不限行数+截断模式+充裕高度的组合只会排出第一行)，统一按换行处理
        container.lineBreakMode = numberOfLines > 0 ? lineBreakMode : (lineBreakMode == .byCharWrapping ? .byCharWrapping : .byWordWrapping)
        layoutManager.textContainer = container
        contentStorage.addTextLayoutManager(layoutManager)

        var rects: [CGRect] = []
        var ranges: [NSRange] = []
        var lineFragments: [(line: NSTextLineFragment, paragraphOffset: Int)] = []
        let documentRange = contentStorage.documentRange

        layoutManager.enumerateTextLayoutFragments(from: nil, options: [.ensuresLayout, .ensuresExtraLineFragment]) { fragment in

            // TextKit2 的行片段字符范围是相对所在段落(text element)的，换算成整个字符串的范围要加上段落偏移
            let paragraphOffset = contentStorage.offset(from: documentRange.location, to: fragment.rangeInElement.location)
            let fragmentFrame = fragment.layoutFragmentFrame

            for line in fragment.textLineFragments {
                // 空范围行是文本末尾换行符产生的占位行，跳过保证新旧系统行为一致
                guard line.characterRange.length > 0 else { continue }
                let bounds = line.typographicBounds
                rects.append(CGRect(x: fragmentFrame.minX + bounds.minX,
                                    y: fragmentFrame.minY + bounds.minY,
                                    width: bounds.width,
                                    height: bounds.height))
                ranges.append(NSRange(location: paragraphOffset + line.characterRange.location, length: line.characterRange.length))
                lineFragments.append((line, paragraphOffset))
            }
            return true
        }
        
        /*
         * 探测 characterIndex(for:) 的索引基准(行左缘反查的原始值 0/行内起点/全下起点分别对应 行内/段落/全下 三种基准)
         
         * 选样按区分度排优先级(段落偏移和行内位置都大于0的行能三分，只有段落偏移大于0能区分全下基准，只有行内位置大于0能区分行内基准)
         
         * 单段落或各段皆单行的文本各基准换算结果本就一致，取不到高优先级样本时按段落基准兜底
         */
        var indexBase: WYTK2IndexBase = .paragraph
        let probePriority: ((Int, Int)) -> Int = { entry in
            let (offset, location) = entry
            if offset > 0 && location > 0 { return 2 }
            if offset > 0 || location > 0 { return 1 }
            return 0
        }
        let probeEntry = lineFragments
            .filter { probePriority(($0.paragraphOffset, $0.line.characterRange.location)) > 0 }
            .max { probePriority(($0.paragraphOffset, $0.line.characterRange.location)) < probePriority(($1.paragraphOffset, $1.line.characterRange.location)) }
        if let entry = probeEntry {
            let probePoint = CGPoint(x: 1, y: entry.line.typographicBounds.height / 2)
            let rawIndex = entry.line.characterIndex(for: probePoint)
            if rawIndex == 0 {
                indexBase = .line
            } else if rawIndex == entry.paragraphOffset + entry.line.characterRange.location {
                indexBase = .absolute
            } else {
                indexBase = .paragraph
            }
        }

        let blockHeight = rects.map({ $0.maxY }).max() ?? 0
        let layout = WYTextKit2Layout(contentStorage: contentStorage, layoutManager: layoutManager, container: container, lineFragments: lineFragments, indexBase: indexBase)

        /**
         *  行数被 numberOfLines 封顶(截断行会把余下整段吞进自身范围)或文本被容器高度裁剪时，最后一行的 characterRange 会包含未显示的文本
         *  用行右缘反查到的可见边界裁剪，防止隐藏文本被算进可见行导致点击误命中
         */
        let cappedByLineLimit = container.maximumNumberOfLines > 0 && ranges.count == container.maximumNumberOfLines
        if var lastRange = ranges.last, let lastLine = lineFragments.last, cappedByLineLimit || NSMaxRange(lastRange) < layoutText.length {
            let bounds = lastLine.line.typographicBounds
            let rawVisible = lastLine.line.characterIndex(for: CGPoint(x: max(0, bounds.maxX - 1), y: bounds.height / 2))
            let visibleParagraphEnd = layout.wy_paragraphIndex(rawVisible, line: lastLine.line, paragraphOffset: lastLine.paragraphOffset) + 1
            let visibleAbsoluteEnd = min(NSMaxRange(lastRange), lastLine.paragraphOffset + visibleParagraphEnd)
            if visibleAbsoluteEnd > lastRange.location {
                lastRange.length = visibleAbsoluteEnd - lastRange.location
                ranges[ranges.count - 1] = lastRange
            }
        }

        return WYTextLayoutOutput(rects: rects, ranges: ranges, blockHeight: blockHeight, layout: layout)
    }

    /// TextKit1 排版(NSTextStorage + NSLayoutManager)
    private static func wy_layoutTextKit1(attributedText: NSAttributedString, containerSize: CGSize, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> WYTextLayoutOutput1 {

        let layoutText = wy_wordWrappedAttributed(attributedText, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)

        let textStorage = NSTextStorage(attributedString: layoutText)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: containerSize.width,
                                                     height: Self.wy_layoutHeightLimit(containerSize: containerSize, numberOfLines: numberOfLines)))
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = max(0, numberOfLines)
        // 不限行数时统一按换行处理，原因同 TextKit2 路径
        container.lineBreakMode = numberOfLines > 0 ? lineBreakMode : (lineBreakMode == .byCharWrapping ? .byCharWrapping : .byWordWrapping)
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        // 触发完整排版
        let glyphRange = layoutManager.glyphRange(for: container)

        var rects: [CGRect] = []
        var ranges: [NSRange] = []
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, _, _, lineGlyphRange, _ in
            let lineCharRange = layoutManager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
            // boundingRect 给出该行文字的紧凑水平范围(含对齐偏移)，行高沿用行片段矩形保证行间距计算一致
            let textRect = layoutManager.boundingRect(forGlyphRange: lineGlyphRange, in: container)
            rects.append(CGRect(x: textRect.minX,
                                y: lineRect.minY,
                                width: textRect.width,
                                height: lineRect.height))
            ranges.append(lineCharRange)
        }

        // usedRect 包含末尾换行符占位的额外空行，与 UILabel 对尾部换行的高度计算一致
        let blockHeight = layoutManager.usedRect(for: container).height
        let layout = WYTextKit1Layout(layoutManager: layoutManager, container: container)
        return WYTextLayoutOutput1(rects: rects, ranges: ranges, blockHeight: blockHeight, layout: layout)
    }

    /// TextKit2 坐标反查(先定位行，再用行片段反查原始下标并按探测到的索引基准换算回整个字符串下标)
    private static func wy_tk2CharacterIndex(at point: CGPoint, lineRects: [CGRect], layout: WYTextKit2Layout) -> Int? {

        if let lineIndex = lineRects.firstIndex(where: { $0.contains(point) }) {
            let entry = layout.lineFragments[lineIndex]
            let lineRect = lineRects[lineIndex]
            let localPoint = CGPoint(x: point.x - lineRect.minX, y: point.y - lineRect.minY)
            let rawIndex = entry.line.characterIndex(for: localPoint)
            return layout.wy_absoluteIndex(rawIndex, line: entry.line, paragraphOffset: entry.paragraphOffset)
        }

        // 点不在任何行矩形内时按 y 找最近行并把 x 夹紧到行内，保证行间空隙与行上下空白也能反查到合理下标
        guard let nearest = lineRects.enumerated().min(by: {
            abs($0.element.midY - point.y) < abs($1.element.midY - point.y)
        }) else { return nil }

        let entry = layout.lineFragments[nearest.offset]
        let clampedX = min(max(point.x, nearest.element.minX + 0.5), nearest.element.maxX - 0.5)
        let localPoint = CGPoint(x: clampedX - nearest.element.minX, y: nearest.element.midY - nearest.element.minY)
        return layout.wy_absoluteIndex(entry.line.characterIndex(for: localPoint), line: entry.line, paragraphOffset: entry.paragraphOffset)
    }

    /// TextKit1 坐标反查(NSLayoutManager 原生支持任意点反查最近字形)
    private static func wy_tk1CharacterIndex(at point: CGPoint, layout: WYTextKit1Layout) -> Int? {

        let container = layout.container
        // 把点夹紧到容器范围内，避免容器外点被外推到错误字形
        let clamped = CGPoint(x: min(max(point.x, 0), max(0, container.size.width - 0.5)),
                              y: min(max(point.y, 0), max(0, container.size.height - 0.5)))
        let glyphIndex = layout.layoutManager.glyphIndex(for: clamped, in: container, fractionOfDistanceThroughGlyph: nil)
        return layout.layoutManager.characterIndexForGlyph(at: glyphIndex)
    }

    /// TextKit2 子范围分行矩形(enumerateTextSegments 直接给出每行精确且含对齐偏移的矩形)
    private static func wy_tk2BoundingRects(for range: NSRange, layout: WYTextKit2Layout) -> [WYTextBoundingRects] {

        let contentStorage = layout.contentStorage
        let documentRange = contentStorage.documentRange
        guard let start = contentStorage.location(documentRange.location, offsetBy: range.location),
              let end = contentStorage.location(documentRange.location, offsetBy: NSMaxRange(range)),
              let textRange = NSTextRange(location: start, end: end) else { return [] }

        let nsString = contentStorage.attributedString?.string ?? ""
        var results: [WYTextBoundingRects] = []
        layout.layoutManager.enumerateTextSegments(in: textRange, type: .standard, options: []) { segmentRange, frame, _, _ in
            // 零宽片段是被行数截断隐藏的部分(未真正排版)，跳过不产生矩形
            guard let segmentRange = segmentRange, frame.width > 0 else { return true }
            let location = contentStorage.offset(from: documentRange.location, to: segmentRange.location)
            let length = contentStorage.offset(from: segmentRange.location, to: segmentRange.endLocation)
            let segment = NSRange(location: location, length: length)
            // 文档最后一个片段可能被重复枚举一次，跳过完全相同的片段
            if let last = results.last, last.range == segment, last.rect == frame { return true }
            results.append(WYTextBoundingRects(rect: frame, string: (nsString as NSString).substring(with: segment), range: segment))
            return true
        }
        return results
    }

    /// TextKit1 子范围分行矩形(逐行取交集后用 boundingRect 得到每行的紧凑矩形)
    private static func wy_tk1BoundingRects(for range: NSRange, layout: WYTextKit1Layout) -> [WYTextBoundingRects] {

        let layoutManager = layout.layoutManager
        let container = layout.container
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        guard glyphRange.length > 0 else { return [] }

        let nsString = layoutManager.textStorage?.string ?? ""
        var results: [WYTextBoundingRects] = []
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, _, _, lineGlyphRange, _ in
            let intersection = NSIntersectionRange(lineGlyphRange, glyphRange)
            guard intersection.length > 0 else { return }
            let textRect = layoutManager.boundingRect(forGlyphRange: intersection, in: container)
            let charRange = layoutManager.characterRange(forGlyphRange: intersection, actualGlyphRange: nil)
            results.append(WYTextBoundingRects(rect: CGRect(x: textRect.minX,
                                                            y: lineRect.minY,
                                                            width: textRect.width,
                                                            height: lineRect.height),
                                               string: (nsString as NSString).substring(with: charRange),
                                               range: charRange))
        }
        return results
    }
}
