//
//  UILabel.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import Foundation
import CoreText

@objc public protocol WYRichTextDelegate {
    
    /**
     * WYRichTextDelegate
     *
     * @param richText 点击的字符串
     * @param range    点击的字符串range
     * @param index    点击的字符在数组中的index
     */
    @objc(wy_richTextDidClick:range:index:)
    optional func wy_richTextDidClick(_ richText: String, range: NSRange, index: Int)
}

public extension UILabel {
    
    /// 是否打开点击效果,默认开启
    var wy_enableClickEffect: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_isClickEffect = newValue }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect) as? Bool ?? true }
    }
    
    /// 点击效果颜色,默认透明
    var wy_clickEffectColor: UIColor {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor ?? .clear }
    }
    
    /// 是否需要模仿按钮的TouchUpInside效果，默认true
    var wy_needTouchUpInside: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside) as? Bool ?? true }
    }
    
    /// 最大允许的触摸移动距离（pt），超出则视为取消点击，默认15.0
    var wy_maxTouchMoveDistance: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance) as? CGFloat ?? 15.0 }
    }
    
    /// 是否启用触摸时长检查（若启用，则触摸时长必须小于 wy_touchDurationLimit 才会响应），默认 false（立即响应）
    var wy_enableTouchDurationCheck: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableTouchDurationCheck, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableTouchDurationCheck) as? Bool ?? false }
    }
    
    /// 最长允许的触摸时长（秒），仅在 wy_enableTouchDurationCheck = true 时生效，默认0.6秒
    var wy_touchDurationLimit: TimeInterval {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchDurationLimit, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchDurationLimit) as? TimeInterval ?? 0.6 }
    }
    
    /**
     * 自定义扩大/缩小点击热区，默认 .zero。
     * 正数表示向外扩大点击区域，负数表示向内缩小。
     * 示例：UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) 表示上下左右各扩大10pt。
     */
    var wy_touchEdgeInsets: UIEdgeInsets {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchEdgeInsets, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchEdgeInsets) as? UIEdgeInsets ?? .zero }
    }
    
    /**
     * 给文本添加Block点击事件回调
     *
     * @param strings 需要添加点击事件的字符串数组
     * @param handler 点击事件回调
     */
    func wy_addRichText(strings: [String], handler:((_ string: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRanges(strings: strings)
            self.wy_clickBlock = handler
        }
    }
    
    /**
     * 给文本添加点击事件delegate回调
     *
     * @param strings 需要添加点击事件的字符串数组
     * @param delegate 富文本代理
     */
    func wy_addRichText(strings: [String], delegate: WYRichTextDelegate) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRanges(strings: strings)
            self.wy_richTextDelegate = delegate
        }
    }
}

extension UILabel {
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !wy_isUpdatingAttributedText else { return }
        guard let attributedText = attributedText else {
            wy_clearCache()
            return
        }
        let textChanged = wy_cachedAttributedText?.isEqual(to: attributedText) == false
        let boundsChanged = wy_cachedBounds != bounds
        if textChanged || boundsChanged {
            wy_refreshFrameCache(attributedText: attributedText)
            if textChanged && !wy_attributeStrings.isEmpty {
                wy_refreshLineRanges()
            }
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            super.touchesBegan(touches, with: event)
            return
        }
        wy_isClickEffect = wy_enableClickEffect
        let touch = touches.first
        let point: CGPoint = touch?.location(in: self) ?? .zero
        wy_touchBeginPoint = point
        wy_touchBeginTime = Date().timeIntervalSince1970
        
        var handled = false
        wy_richTextFrame(touchPoint: point) {[weak self] (string, range, index) in
            handled = true
            self?.wy_currentTouchModel = (string, range, index)
            if self?.wy_needTouchUpInside == false {
                if self?.wy_clickBlock != nil {
                    self?.wy_clickBlock!(string, range, index)
                }
                if (self?.wy_richTextDelegate != nil) {
                    self?.wy_richTextDelegate?.wy_richTextDidClick?(string, range: range, index: index)
                }
            }
            if self?.wy_isClickEffect == true {
                self?.wy_saveEffectDic(range: range)
                self?.wy_clickEffect(true)
            }
        }
        if !handled {
            super.touchesBegan(touches, with: event)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            super.touchesEnded(touches, with: event)
            return
        }
        if wy_needTouchUpInside == true, let model = wy_currentTouchModel {
            if let touch = touches.first {
                let endPoint: CGPoint = touch.location(in: self)
                var isSameRichText = false
                wy_richTextFrame(touchPoint: endPoint) { (string, range, index) in
                    if string == model.string && range == model.range && index == model.index {
                        isSameRichText = true
                    }
                }
                let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: endPoint)
                let isMoveDistanceValid = moveDistance <= wy_maxTouchMoveDistance
                var isTouchDurationValid = true
                if wy_enableTouchDurationCheck {
                    let currentTime = Date().timeIntervalSince1970
                    let touchDuration = currentTime - (wy_touchBeginTime ?? currentTime)
                    isTouchDurationValid = touchDuration < wy_touchDurationLimit
                }
                if isSameRichText && isMoveDistanceValid && isTouchDurationValid {
                    if wy_clickBlock != nil {
                        wy_clickBlock!(model.string, model.range, model.index)
                    }
                    if (wy_richTextDelegate != nil) {
                        wy_richTextDelegate?.wy_richTextDidClick?(model.string, range: model.range, index: model.index)
                    }
                }
            }
            wy_resetTouchState()
        }
        if wy_isClickEffect == true {
            wy_clickEffect(false)
        }
        super.touchesEnded(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            super.touchesCancelled(touches, with: event)
            return
        }
        if wy_needTouchUpInside == true {
            wy_resetTouchState()
        }
        if wy_isClickEffect == true {
            wy_clickEffect(false)
        }
        super.touchesCancelled(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            super.touchesMoved(touches, with: event)
            return
        }
        if wy_needTouchUpInside == true, let touch = touches.first, wy_currentTouchModel != nil {
            let point: CGPoint = touch.location(in: self)
            var isStillInRichText = false
            wy_richTextFrame(touchPoint: point) { [weak self] (string, range, index) in
                if let currentModel = self?.wy_currentTouchModel,
                   string == currentModel.string && range == currentModel.range && index == currentModel.index {
                    isStillInRichText = true
                }
            }
            if !isStillInRichText {
                if wy_isClickEffect == true {
                    wy_clickEffect(false)
                }
                wy_currentTouchModel = nil
            }
        }
        super.touchesMoved(touches, with: event)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            return super.hitTest(point, with: event)
        }
        if (wy_richTextFrame(touchPoint: point) == true) {
            return self
        }
        return super.hitTest(point, with: event)
    }
    
    @discardableResult
    private func wy_richTextFrame(touchPoint: CGPoint, handler:((_ string: String, _ range: NSRange, _ index: Int) -> Void)? = nil) -> Bool {
        guard let attributedText = attributedText else { return false }
        let (_, lines, origins) = wy_getCachedFrameInfo(attributedText: attributedText)
        guard let lines = lines, let origins = origins else { return false }
        let lineCount = CFArrayGetCount(lines)
        guard lineCount > 0 else { return false }
        let useLineGroups = (wy_lineRanges?.count == lineCount)
        let originsArray = origins
        let transform = CGAffineTransform(translationX: 0, y: bounds.size.height).scaledBy(x: 1.0, y: -1.0)
        
        let totalTextHeight = wy_calculateTotalTextHeight(attributedText: attributedText, lines: lines, lineCount: lineCount)
        var currentY = max(0, (bounds.height - totalTextHeight) / 2.0)
        
        for i in 0..<lineCount {
            let linePoint = originsArray[i]
            let line = CFArrayGetValueAtIndex(lines, i)
            let lineRef = unsafeBitCast(line, to: CTLine.self)
            let flippedRect = wy_sharedBounds(line: lineRef, point: linePoint)
            var originalRect = flippedRect.applying(transform)   // 原始矩形（未扩大）
            
            let lineWidth = CGFloat(CTLineGetTypographicBounds(lineRef, nil, nil, nil))
            switch textAlignment {
            case .center:
                originalRect.origin.x += (bounds.width - lineWidth) / 2.0
            case .right:
                originalRect.origin.x += bounds.width - lineWidth
            default: break
            }
            originalRect.origin.y = currentY
            
            let lineSpacing = wy_lineSpacing(from: attributedText)
            let lineHeight = originalRect.size.height
            currentY += lineHeight + (i < lineCount - 1 ? lineSpacing : 0)
            
            // 热区扩大（仅用于命中判断）
            let insets = wy_touchEdgeInsets
            var hitRect = originalRect
            if insets != .zero {
                let newX = hitRect.minX - insets.left
                let newY = hitRect.minY - insets.top
                let newWidth = hitRect.width + insets.left + insets.right
                let newHeight = hitRect.height + insets.top + insets.bottom
                hitRect = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            }
            
            if hitRect.contains(touchPoint) {
                // 使用原始矩形计算相对坐标
                let relativePoint = CGPoint(
                    x: touchPoint.x - originalRect.minX,
                    y: touchPoint.y - originalRect.minY
                )
                var index = CTLineGetStringIndexForPosition(lineRef, relativePoint)
                var offset: CGFloat = 0.0
                CTLineGetOffsetForStringIndex(lineRef, index, &offset)
                if offset > relativePoint.x {
                    index = index - 1
                }
                let modelsToCheck = useLineGroups ? (wy_lineRanges?[i] ?? []) : wy_attributeStrings
                for (j, model) in modelsToCheck.enumerated() {
                    let linkRange = model.wy_range
                    if NSLocationInRange(index, linkRange) {
                        let globalIndex = useLineGroups ? wy_attributeStrings.firstIndex(where: { $0.wy_range == linkRange }) ?? j : j
                        handler?(model.wy_richText, model.wy_range, globalIndex)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func wy_sharedBounds(line: CTLine, point: CGPoint) -> CGRect {
        var ascent: CGFloat = 0.0
        var descent: CGFloat = 0.0
        var leading: CGFloat = 0.0
        let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        let height = ascent + abs(descent) + leading
        return CGRect(x: point.x, y: point.y, width: width, height: height)
    }
    
    // MARK: - 缓存相关
    private func wy_getCachedFrameInfo(attributedText: NSAttributedString) -> (CTFrame?, CFArray?, [CGPoint]?) {
        if wy_cachedAttributedText?.isEqual(to: attributedText) == false || wy_cachedBounds != bounds {
            wy_refreshFrameCache(attributedText: attributedText)
        }
        return (wy_ctFrame, wy_lines, wy_lineOrigins)
    }
    
    private func wy_refreshFrameCache(attributedText: NSAttributedString) {
        wy_cachedAttributedText = attributedText
        wy_cachedBounds = bounds
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        let path = CGMutablePath()
        path.addRect(bounds, transform: .identity)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        wy_ctFrame = frame
        wy_lines = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(wy_lines!)
        var origins = [CGPoint](repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
        wy_lineOrigins = origins
    }
    
    private func wy_refreshLineRanges() {
        wy_lineRanges = wy_groupModelsByLine()
    }
    
    // MARK: - 点击效果
    private func wy_clickEffect(_ status: Bool) {
        guard wy_isClickEffect,
              let effectRanges = wy_effectRanges,
              !effectRanges.isEmpty,
              let currentText = attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: currentText)
        var didChange = false
        for rangeKey in effectRanges {
            let range = NSRangeFromString(rangeKey)
            if status {
                if mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) == nil {
                    mutableText.addAttribute(.backgroundColor, value: wy_clickEffectColor, range: range)
                    didChange = true
                }
            } else {
                if let bgColor = mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? UIColor,
                   bgColor == wy_clickEffectColor {
                    mutableText.removeAttribute(.backgroundColor, range: range)
                    didChange = true
                }
            }
        }
        if didChange {
            wy_isUpdatingAttributedText = true
            attributedText = mutableText
            wy_isUpdatingAttributedText = false
        }
    }
    
    private func wy_saveEffectDic(range: NSRange) {
        wy_effectRanges = Set([NSStringFromRange(range)])
    }
    
    private func wy_richTextRanges(strings: [String]) {
        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        wy_isClickEffect = true
        isUserInteractionEnabled = true
        let originalString = attributed.string
        wy_attributeStrings = []
        for str in strings {
            var searchStart = originalString.startIndex
            while let range = originalString.range(of: str, range: searchStart..<originalString.endIndex) {
                let nsRange = NSRange(range, in: originalString)
                var model = WYRichTextModel()
                model.wy_range = nsRange
                model.wy_richText = str
                wy_attributeStrings.append(model)
                searchStart = range.upperBound
            }
        }
        wy_refreshFrameCache(attributedText: attributed)
        wy_lineRanges = wy_groupModelsByLine()
    }
    
    private func wy_groupModelsByLine() -> [[WYRichTextModel]] {
        guard let lines = wy_lines, let _ = attributedText else { return [] }
        let lineCount = CFArrayGetCount(lines)
        guard lineCount > 0 else { return [] }
        var groups = [[WYRichTextModel]](repeating: [], count: lineCount)
        for model in wy_attributeStrings {
            let modelRange = model.wy_range
            for i in 0..<lineCount {
                guard let line = CFArrayGetValueAtIndex(lines, i) else { continue }
                let lineRef = unsafeBitCast(line, to: CTLine.self)
                let lineRange = CTLineGetStringRange(lineRef)
                let intersection = NSIntersectionRange(modelRange, NSRange(location: lineRange.location, length: lineRange.length))
                if intersection.length > 0 {
                    groups[i].append(model)
                    if modelRange.location >= lineRange.location &&
                        modelRange.location + modelRange.length <= lineRange.location + lineRange.length {
                        break
                    }
                }
            }
        }
        return groups
    }
    
    private func wy_calculateTotalTextHeight(attributedText: NSAttributedString, lines: CFArray, lineCount: Int) -> CGFloat {
        var totalHeight: CGFloat = 0
        let lineSpacing = wy_lineSpacing(from: attributedText)
        for i in 0..<lineCount {
            guard let line = CFArrayGetValueAtIndex(lines, i) else { continue }
            let lineRef = unsafeBitCast(line, to: CTLine.self)
            var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
            CTLineGetTypographicBounds(lineRef, &ascent, &descent, &leading)
            let lineHeight = ascent + abs(descent) + leading
            totalHeight += lineHeight
            if i < lineCount - 1 {
                totalHeight += lineSpacing
            }
        }
        return totalHeight
    }
    
    private func wy_lineSpacing(from attributedText: NSAttributedString) -> CGFloat {
        if let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
            return paragraphStyle.lineSpacing
        }
        return 0
    }
    
    private func wy_resetTouchState() {
        wy_currentTouchModel = nil
        wy_touchBeginPoint = nil
        wy_touchBeginTime = nil
    }
    
    private func wy_calculateDistance(from point1: CGPoint?, to point2: CGPoint) -> CGFloat {
        guard let point1 = point1 else { return .greatestFiniteMagnitude }
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func wy_clearCache() {
        wy_ctFrame = nil
        wy_lines = nil
        wy_lineOrigins = nil
        wy_cachedAttributedText = nil
        wy_cachedBounds = .zero
    }
    
    // MARK: - Associated Properties
    private var wy_currentTouchModel: (string: String, range: NSRange, index: Int)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel) as? (String, NSRange, Int) }
    }
    private var wy_touchBeginPoint: CGPoint? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint) as? CGPoint }
    }
    private var wy_touchBeginTime: TimeInterval? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime) as? TimeInterval }
    }
    private var wy_clickBlock: ((_ richText: String, _ range: NSRange, _ index : Int) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock) as? (String, NSRange, Int) -> Void }
    }
    private weak var wy_richTextDelegate: WYRichTextDelegate? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate, newValue, .OBJC_ASSOCIATION_ASSIGN) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate) as? WYRichTextDelegate }
    }
    private var wy_isClickEffect: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect) as? Bool ?? true }
    }
    private var wy_isClickAction: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction) as? Bool ?? false }
    }
    private var wy_attributeStrings: [WYRichTextModel] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings) as? [WYRichTextModel] ?? [] }
    }
    private var wy_effectRanges: Set<String>? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_effectRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_effectRanges) as? Set<String> }
    }
    private var wy_ctFrame: CTFrame? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_ctFrame, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_ctFrame) as! CTFrame? }
    }
    private var wy_lines: CFArray? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lines, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lines) as! CFArray? }
    }
    private var wy_lineOrigins: [CGPoint]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineOrigins, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineOrigins) as? [CGPoint] }
    }
    private var wy_cachedAttributedText: NSAttributedString? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_cachedAttributedText, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_cachedAttributedText) as? NSAttributedString }
    }
    private var wy_cachedBounds: CGRect {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_cachedBounds, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_cachedBounds) as? CGRect ?? .zero }
    }
    private var wy_isUpdatingAttributedText: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isUpdatingAttributedText, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isUpdatingAttributedText) as? Bool ?? false }
    }
    private var wy_lineRanges: [[WYRichTextModel]]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineRanges) as? [[WYRichTextModel]] }
    }
    
    private struct WYAssociatedKeys {
        static var wy_richTextDelegate: UInt8 = 0
        static var wy_enableClickEffect: UInt8 = 0
        static var wy_isClickEffect: UInt8 = 0
        static var wy_isClickAction: UInt8 = 0
        static var wy_clickEffectColor: UInt8 = 0
        static var wy_attributeStrings: UInt8 = 0
        static var wy_effectRanges: UInt8 = 0
        static var wy_clickBlock: UInt8 = 0
        static var wy_currentTouchModel: UInt8 = 0
        static var wy_needTouchUpInside: UInt8 = 0
        static var wy_touchBeginPoint: UInt8 = 0
        static var wy_touchBeginTime: UInt8 = 0
        static var wy_maxTouchMoveDistance: UInt8 = 0
        static var wy_enableTouchDurationCheck: UInt8 = 0
        static var wy_touchDurationLimit: UInt8 = 0
        static var wy_touchEdgeInsets: UInt8 = 0
        static var wy_ctFrame: UInt8 = 0
        static var wy_lines: UInt8 = 0
        static var wy_lineOrigins: UInt8 = 0
        static var wy_cachedAttributedText: UInt8 = 0
        static var wy_cachedBounds: UInt8 = 0
        static var wy_isUpdatingAttributedText: UInt8 = 0
        static var wy_lineRanges: UInt8 = 0
    }
}

private struct WYRichTextModel {
    var wy_richText: String = ""
    var wy_range: NSRange = NSRange()
}
