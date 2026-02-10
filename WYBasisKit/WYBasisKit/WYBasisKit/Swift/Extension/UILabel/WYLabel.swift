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
     *  WYRichTextDelegate
     *
     *  @param richText  点击的字符串
     *  @param range   点击的字符串range
     *  @param index   点击的字符在数组中的index
     */
    @objc(wy_didClickRichText:range:index:)
    optional func wy_didClick(richText: String, range: NSRange, index: Int)
}

public extension UILabel {
    
    /// 是否打开点击效果,默认开启
    var wy_enableClickEffect: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_isClickEffect = newValue
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect) as? Bool ?? true
        }
    }
    
    /// 点击效果颜色,默认透明
    var wy_clickEffectColor: UIColor {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor ?? .clear
        }
    }
    
    /// 是否需要模仿按钮的TouchUpInside效果，默认true
    var wy_needTouchUpInside: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside) as? Bool ?? true
        }
    }
    
    /**
     *  给文本添加Block点击事件回调
     *
     *  @param strings  需要添加点击事件的字符串数组
     *  @param handler  点击事件回调
     *
     */
    func wy_addRichText(strings: [String], handler:((_ string: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRanges(strings: strings)
            self.wy_clickBlock = handler
        }
    }
    
    /**
     *  给文本添加点击事件delegate回调
     *
     *  @param strings  需要添加点击事件的字符串数组
     *  @param delegate 富文本代理
     *
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
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            return
        }
        wy_isClickEffect = wy_enableClickEffect
        let touch = touches.first
        let point: CGPoint = touch?.location(in: self) ?? .zero
        
        // 记录触摸开始信息
        wy_touchBeginPoint = point
        wy_touchBeginTime = Date().timeIntervalSince1970
        
        wy_richTextFrame(touchPoint: point) {[weak self] (string, range, index) in
            
            // 保存当前触摸的富文本信息
            self?.wy_currentTouchModel = (string, range, index)
            
            // isTouchUpInside为false时立即响应点击事件
            if self?.wy_needTouchUpInside == false {
                if self?.wy_clickBlock != nil {
                    self?.wy_clickBlock!(string, range, index)
                }
                
                if (self?.wy_richTextDelegate != nil) {
                    self?.wy_richTextDelegate?.wy_didClick?(richText: string, range: range, index: index)
                }
            }
            
            if self?.wy_isClickEffect == true {
                self?.wy_saveEffectDic(range: range)
                self?.wy_clickEffect(true)
            }
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // TouchUpInside 模式处理
        if wy_needTouchUpInside == true, let model = wy_currentTouchModel {
            
            if let touch = touches.first {
                let endPoint: CGPoint = touch.location(in: self)
                
                // 检查是否还在同一个富文本区域内
                var isSameRichText = false
                wy_richTextFrame(touchPoint: endPoint) { (string, range, index) in
                    if string == model.string && range == model.range && index == model.index {
                        isSameRichText = true
                    }
                }
                
                // 检查移动距离是否在允许范围内
                let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: endPoint)
                let isMoveDistanceValid = moveDistance <= wy_maxTouchMoveDistance
                
                // 检查触摸时长是否合理（防止长按触发）
                let currentTime = Date().timeIntervalSince1970
                let touchDuration = currentTime - (wy_touchBeginTime ?? currentTime)
                let isTouchDurationValid = touchDuration < 0.5 // 500ms 内
                
                // 只有满足所有条件才触发
                if isSameRichText && isMoveDistanceValid && isTouchDurationValid {
                    if wy_clickBlock != nil {
                        wy_clickBlock!(model.string, model.range, model.index)
                    }
                    
                    if (wy_richTextDelegate != nil) {
                        wy_richTextDelegate?.wy_didClick?(richText: model.string, range: model.range, index: model.index)
                    }
                }
            }
            
            // 重置触摸状态
            wy_resetTouchState()
        }
        
        if wy_isClickEffect == true {
            performSelector(onMainThread: #selector(wy_clickEffect(_:)), with: nil, waitUntilDone: false)
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // TouchUpInside 模式下，取消触摸重置状态
        if wy_needTouchUpInside == true {
            wy_resetTouchState()
        }
        
        if wy_isClickEffect == true {
            performSelector(onMainThread: #selector(wy_clickEffect(_:)), with: nil, waitUntilDone: false)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // TouchUpInside 模式下，如果触摸移出富文本区域，清除点击效果
        if wy_needTouchUpInside == true, let touch = touches.first, wy_currentTouchModel != nil {
            let point: CGPoint = touch.location(in: self)
            var isStillInRichText = false
            
            wy_richTextFrame(touchPoint: point) { [weak self] (string, range, index) in
                if let currentModel = self?.wy_currentTouchModel,
                   string == currentModel.string && range == currentModel.range && index == currentModel.index {
                    isStillInRichText = true
                }
            }
            
            // 如果移出了富文本区域，清除点击效果并重置状态
            if !isStillInRichText {
                if wy_isClickEffect == true {
                    performSelector(onMainThread: #selector(wy_clickEffect(_:)), with: nil, waitUntilDone: false)
                }
                // 重置触摸状态，防止 touchesEnded 时误触发
                wy_currentTouchModel = nil
            }
        }
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
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        var path = CGMutablePath()
        path.addRect(bounds, transform: CGAffineTransform.identity)
        
        var frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        let range = CTFrameGetVisibleStringRange(frame)
        
        // 处理文本超出一行的情况
        if attributedText.length > range.length {
            var m_font: UIFont = font ?? UIFont.systemFont(ofSize: 17)
            let u_font = attributedText.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil)
            if let fontValue = u_font as? UIFont {
                m_font = fontValue
            }
            
            var lineSpace: CGFloat = 0.0
            if let paragraphStyle = attributedText.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                lineSpace = paragraphStyle.lineSpacing
            }
            
            path = CGMutablePath()
            let height = bounds.size.height + m_font.lineHeight - lineSpace
            path.addRect(CGRect(x: 0, y: 0, width: bounds.size.width, height: height), transform: CGAffineTransform.identity)
            frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        }
        
        let lines = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lines)
        guard lineCount > 0 else { return false }
        
        var origins = [CGPoint](repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
        
        let transform = CGAffineTransform(translationX: 0, y: bounds.size.height).scaledBy(x: 1.0, y: -1.0)
        
        for i in 0..<lineCount {
            let linePoint = origins[i]
            let line = CFArrayGetValueAtIndex(lines, i)
            let lineRef = unsafeBitCast(line, to: CTLine.self)
            let flippedRect = wy_sharedBounds(line: lineRef, point: linePoint)
            var rect = flippedRect.applying(transform)
            rect = rect.insetBy(dx: 0, dy: 0)
            
            // 根据文本对齐方式调整 rect 的 x 位置
            let lineWidth = CGFloat(CTLineGetTypographicBounds(lineRef, nil, nil, nil))
            
            switch textAlignment {
            case .center:
                // 居中对齐：计算偏移量并调整 rect
                let xOffset = (bounds.width - lineWidth) / 2.0
                rect.origin.x += xOffset
            case .right:
                // 右对齐
                let xOffset = bounds.width - lineWidth
                rect.origin.x += xOffset
            case .left, .natural, .justified:
                // 左对齐和其他情况保持原样
                break
            @unknown default:
                break
            }
            
            // 垂直方向调整
            let style = attributedText.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            let lineSpace: CGFloat = style?.lineSpacing ?? 0.0
            
            let totalLineHeight = CGFloat(lineCount) * rect.size.height + CGFloat(lineCount - 1) * lineSpace
            let verticalOffset = (bounds.size.height - totalLineHeight) / 2.0
            
            // 垂直居中调整（如果文本垂直居中）
            if numberOfLines != 1 {
                rect.origin.y = verticalOffset + (rect.size.height + lineSpace) * CGFloat(i)
            }
            
            if rect.contains(touchPoint) {
                // 计算点击位置的字符索引
                let relativePoint = CGPoint(
                    x: touchPoint.x - rect.minX,
                    y: touchPoint.y - rect.minY
                )
                
                var index = CTLineGetStringIndexForPosition(lineRef, relativePoint)
                var offset: CGFloat = 0.0
                CTLineGetOffsetForStringIndex(lineRef, index, &offset)
                
                if offset > relativePoint.x {
                    index = index - 1
                }
                
                // 检查点击位置是否在可点击的富文本范围内
                for (j, model) in wy_attributeStrings.enumerated() {
                    let linkRange = model.wy_range
                    if NSLocationInRange(index, linkRange) {
                        handler?(model.wy_richText, model.wy_range, j)
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
        
        return CGRect(x: point.x, y: point.y, width: CGFloat(width), height: height)
    }
    
    @objc private func wy_clickEffect(_ status: Bool) {
        
        if (wy_isClickEffect == true) && (wy_effectDic?.values.isEmpty == false) && (attributedText != nil) {
            
            let attStr = NSMutableAttributedString.init(attributedString: attributedText!)
            let subAtt = NSMutableAttributedString.init(attributedString: (wy_effectDic?.values.first)!)
            let range = NSRangeFromString((wy_effectDic?.keys.first!)!)
            
            if status {
                subAtt.addAttribute(NSAttributedString.Key.backgroundColor, value: wy_clickEffectColor, range: NSMakeRange(0, subAtt.length))
                attStr.replaceCharacters(in: range, with: subAtt)
            }else {
                attStr.replaceCharacters(in: range, with: subAtt)
            }
            attributedText = attStr
        }
    }
    
    private func wy_saveEffectDic(range: NSRange) {
        
        wy_effectDic = [:]
        
        guard let subAttribute = attributedText?.attributedSubstring(from: range) else { return }
        
        _ = wy_effectDic?[String(describing: range)] = subAttribute
    }
    
    private func wy_richTextRanges(strings: [String]) {
        
        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        
        wy_isClickEffect = true
        isUserInteractionEnabled = true
        
        var totalString = attributed.string
        wy_attributeStrings = []
        
        for str in strings {
            guard let range = totalString.range(of: str) else { continue }
            
            // 先生成模型 NSRange
            var model = WYRichTextModel()
            model.wy_range = NSRange(range, in: totalString)
            model.wy_richText = str
            wy_attributeStrings.append(model)
            
            // 用占位符替换原文本
            totalString.replaceSubrange(range, with: wy_sharedString(count: str.count))
        }
    }
    
    private func wy_sharedString(count: Int) -> String {
        
        var string = ""
        for _ in 0 ..< count {
            string = string + " "
        }
        return string
    }
    
    private var wy_currentTouchModel: (string: String, range: NSRange, index: Int)? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel) as? (String, NSRange, Int)
        }
    }
    
    private var wy_touchBeginPoint: CGPoint? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint) as? CGPoint
        }
    }
    
    private var wy_touchBeginTime: TimeInterval? {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime) as? TimeInterval
        }
    }
    
    private var wy_maxTouchMoveDistance: CGFloat {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance) as? CGFloat ?? 10.0
        }
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
    
    private var wy_clickBlock: ((_ richText: String, _ range: NSRange, _ index : Int) -> Void)? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock) as? (String, NSRange, Int) -> Void
        }
    }
    
    private weak var wy_richTextDelegate: WYRichTextDelegate? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate) as? WYRichTextDelegate
        }
    }
    
    private var wy_isClickEffect: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect) as? Bool ?? true
        }
    }
    
    private var wy_isClickAction: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction) as? Bool ?? true
        }
    }
    
    private var wy_attributeStrings: [WYRichTextModel] {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings) as? [WYRichTextModel] ?? []
        }
    }
    
    private var wy_effectDic: [String: NSAttributedString]? {
        
        set(newValue) {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_effectDic, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_effectDic) as? [String: NSAttributedString]
        }
    }
    
    private struct WYAssociatedKeys {
        
        static var wy_richTextDelegate: UInt8 = 0
        static var wy_enableClickEffect: UInt8 = 0
        static var wy_isClickEffect: UInt8 = 0
        static var wy_isClickAction: UInt8 = 0
        static var wy_clickEffectColor: UInt8 = 0
        static var wy_attributeStrings: UInt8 = 0
        static var wy_effectDic: UInt8 = 0
        static var wy_clickBlock: UInt8 = 0
        static var wy_transformForCoreText: UInt8 = 0
        static var wy_currentTouchModel: UInt8 = 0
        static var wy_needTouchUpInside: UInt8 = 0
        static var wy_touchBeginPoint: UInt8 = 0
        static var wy_touchBeginTime: UInt8 = 0
        static var wy_maxTouchMoveDistance: UInt8 = 0
    }
}

private struct WYRichTextModel {
    
    var wy_richText: String = ""
    var wy_range: NSRange = NSRange()
}

private extension String {
    
    func nsRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range,in : self)
    }
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
}
