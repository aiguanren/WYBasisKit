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
    @objc optional func wy_didClick(richText: String, range: NSRange, index: NSInteger)
}

public extension UILabel {
    
    /// 是否打开点击效果,默认开启
    var wy_enableClickEffect: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_enableClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_isClickEffect = newValue
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_enableClickEffect) as? Bool ?? true
        }
    }
    
    /// 点击效果颜色,默认透明
    var wy_clickEffectColor: UIColor {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_clickEffectColor) as? UIColor ?? .clear
        }
    }
    
    /**
     *  给文本添加Block点击事件回调
     *
     *  @param strings  需要添加点击事件的字符串数组
     *  @param handler  点击事件回调
     *
     */
    func wy_addRichText(strings: [String], handler:((_ string: String, _ range: NSRange, _ index: NSInteger) -> Void)? = nil) {
        
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
        wy_richTextFrame(touchPoint: point) {[weak self] (string, range, index) in
            
            if self?.wy_clickBlock != nil {
                self?.wy_clickBlock!(string, range, index)
            }
            
            if (self?.wy_richTextDelegate != nil) {
                self?.wy_richTextDelegate?.wy_didClick?(richText: string, range: range, index: index)
            }
            
            if self?.wy_isClickEffect == true {
                self?.wy_saveEffectDic(range: range)
                self?.wy_clickEffect(true)
            }
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if wy_isClickEffect == true {
            performSelector(onMainThread: #selector(wy_clickEffect(_:)), with: nil, waitUntilDone: false)
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if wy_isClickEffect == true {
            performSelector(onMainThread: #selector(wy_clickEffect(_:)), with: nil, waitUntilDone: false)
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
    private func wy_richTextFrame(touchPoint: CGPoint, handler:((_ string: String, _ range: NSRange, _ index: NSInteger) -> Void)? = nil) -> Bool {
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText!)
        
        var path = CGMutablePath()
        
        path.addRect(bounds, transform: CGAffineTransform.identity)
        
        var frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        let range = CTFrameGetVisibleStringRange(frame)
        
        if attributedText!.length > range.length {
            
            var m_font: UIFont = font
            let u_font = attributedText?.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil)
            if u_font != nil {
                m_font = u_font as! UIFont
            }

            var lineSpace: CGFloat = 0.0
            let paragraphStyleObj = attributedText?.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            if paragraphStyleObj != nil {
                lineSpace = (paragraphStyleObj?.value(forKey: "_lineSpacing") as? CGFloat) ?? 0
            }
            
            path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height + m_font.lineHeight - lineSpace), transform: CGAffineTransform.identity)
            frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        }
        
        let lines = CTFrameGetLines(frame)
        let count = CFArrayGetCount(lines)
        guard count > 0 else {
            return false
        }
        
        var origins = [CGPoint](repeating: CGPoint.zero, count: count)
        
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
        
        let transform = CGAffineTransform(translationX: 0, y: self.bounds.size.height).scaledBy(x: 1.0, y: -1.0);
        let verticalOffset = 0.0
        for i : CFIndex in 0..<count {
            
            let linePoint = origins[i]
            let line = CFArrayGetValueAtIndex(lines, i)
            let lineRef = unsafeBitCast(line,to: CTLine.self)
            let flippedRect: CGRect = wy_sharedBounds(line: lineRef, point: linePoint)
            var rect = flippedRect.applying(transform)
            rect = rect.insetBy(dx: 0, dy: 0)
            rect = rect.offsetBy(dx: 0, dy: CGFloat(verticalOffset))
            let style = attributedText?.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil)
            var lineSpace : CGFloat = 0.0
            if (style != nil) {
                lineSpace = (style as! NSParagraphStyle).lineSpacing
            }else {
                lineSpace = 0.0
            }
            let lineOutSpace = (CGFloat(bounds.size.height) - CGFloat(lineSpace) * CGFloat(count - 1) - CGFloat(rect.size.height) * CGFloat(count)) / 2
            
            rect.origin.y = lineOutSpace + rect.size.height * CGFloat(i) + lineSpace * CGFloat(i)
            
            if rect.contains(touchPoint) {
                
                let relativePoint = CGPoint(x: touchPoint.x - rect.minX, y: touchPoint.y - rect.minY)
                var index = CTLineGetStringIndexForPosition(lineRef, relativePoint)
                var offset: CGFloat = 0.0
                CTLineGetOffsetForStringIndex(lineRef, index, &offset)
                if offset > relativePoint.x {
                    index = index - 1
                }
                let link_count = wy_attributeStrings.count
                for j in 0 ..< link_count {
                    
                    let model = wy_attributeStrings[j]
                    
                    let link_range = model.wy_range

                    if NSLocationInRange(index, link_range) {
                        
                        if handler != nil {
                            handler!(model.wy_richText, model.wy_range, j)
                        }
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
        
        return CGRect(x: point.x, y: point.y , width: CGFloat(width), height: height)
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
        
        let subAttribute = attributedText?.attributedSubstring(from: range)
        
        _ = wy_effectDic?.updateValue(subAttribute!, forKey: NSStringFromRange(range))
    }
    
    private func wy_richTextRanges(strings: [String]) {
        
        wy_isClickAction = (attributedText == nil) ? false : true
        if attributedText == nil {
            return
        }
        
        wy_isClickEffect = true
        
        isUserInteractionEnabled = true
        
        var totalString = attributedText?.string
        
        wy_attributeStrings = []
        
        for str: String in strings {
            
            let nsrange: NSRange = ((attributedText?.string ?? "") as NSString).range(of: str)
            let range: Range? = attributedText?.string.range(from: nsrange)
            if (range?.lowerBound != nil) {
                
                totalString = totalString?.replacingCharacters(in: range!, with: wy_sharedString(count: str.count))

                var model = WYRichTextModel()
                model.wy_range = totalString?.nsRange(from: range!) ?? NSRange()
                model.wy_richText = str
                
                wy_attributeStrings.append(model)
            }
        }
    }
    
    private func wy_sharedString(count: Int) -> String {
        
        var string = ""
        for _ in 0 ..< count {
            string = string + " "
        }
        return string
    }
    
    private var wy_clickBlock: ((_ richText: String, _ range: NSRange, _ index : NSInteger) -> Void)? {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_clickBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_clickBlock) as? (String, NSRange, NSInteger) -> Void
        }
    }
    
    private weak var wy_richTextDelegate: WYRichTextDelegate? {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_richTextDelegate, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_richTextDelegate) as? WYRichTextDelegate
        }
    }
    
    private var wy_isClickEffect: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_isClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_isClickEffect) as? Bool ?? true
        }
    }
    
    private var wy_isClickAction: Bool {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_isClickAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_isClickAction) as? Bool ?? true
        }
    }
    
    private var wy_attributeStrings: [WYRichTextModel] {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_attributeStrings, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_attributeStrings) as? [WYRichTextModel] ?? []
        }
    }
    
    private var wy_effectDic: [String: NSAttributedString]? {
        
        set(newValue) {
            objc_setAssociatedObject(self, WYAssociatedKeys.wy_effectDic, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, WYAssociatedKeys.wy_effectDic) as? [String: NSAttributedString]
        }
    }
    
    private struct WYAssociatedKeys {
        
        static let wy_richTextDelegate = UnsafeRawPointer(bitPattern: "wy_richTextDelegate".hashValue)!
        static let wy_enableClickEffect = UnsafeRawPointer(bitPattern: "wy_enableClickEffect".hashValue)!
        static let wy_isClickEffect = UnsafeRawPointer(bitPattern: "wy_isClickEffect".hashValue)!
        static let wy_isClickAction = UnsafeRawPointer(bitPattern: "wy_isClickAction".hashValue)!
        static let wy_clickEffectColor = UnsafeRawPointer(bitPattern: "wy_clickEffectColor".hashValue)!
        static let wy_attributeStrings = UnsafeRawPointer(bitPattern: "wy_attributeStrings".hashValue)!
        static let wy_effectDic = UnsafeRawPointer(bitPattern: "wy_effectDic".hashValue)!
        static let wy_clickBlock = UnsafeRawPointer(bitPattern: "wy_clickBlock".hashValue)!
        static let wy_transformForCoreText = UnsafeRawPointer(bitPattern: "wy_transformForCoreText".hashValue)!
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
