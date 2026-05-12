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
     * 富文本点击回调
     *
     * @param label    当前 UILabel 实例
     * @param richText 被点击的字符串内容
     * @param range    被点击字符串在整个文本中的 NSRange
     * @param index    被点击字符串在传入 strings 数组中的索引
     */
    @objc(wy_richTextDidClick:richText:range:index:)
    optional func wy_richTextDidClick(_ label: UILabel, richText: String, range: NSRange, index: Int)
    
    /**
     * 富文本长按回调
     *
     * @param label    当前 UILabel 实例
     * @param richText 被长按的字符串内容
     * @param range    被长按字符串在整个文本中的 NSRange
     * @param index    被长按字符串在传入 strings 数组中的索引
     */
    @objc(wy_richTextDidLongPress:richText:range:index:)
    optional func wy_richTextDidLongPress(_ label: UILabel, richText: String, range: NSRange, index: Int)
}

public extension UILabel {
    
    /// 是否打开点击效果（按下时改变背景色，仅点击有效，长按可以通过设置 `wy_longPressEffectColor` 来达到开启或者透明关闭的功能），默认开启
    var wy_enableClickEffect: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_isClickEffect = newValue
        }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableClickEffect) as? Bool ?? true }
    }
    
    /**
     * 点击效果颜色（按下时的背景色），默认透明（即无效果）
     *
     * - 若用户未主动设置，则自动使用被点击富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    var wy_clickEffectColor: UIColor {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            // 标记为用户主动设置过
            wy_hasCustomEffectColor = true
        }
        get {
            if let color = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor {
                return color
            }
            return .clear
        }
    }
    
    /**
     * 长按效果颜色（长按时背景色），默认透明（即无效果）
     *
     * - 若用户未主动设置，则自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    var wy_longPressEffectColor: UIColor {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            wy_hasCustomLongPressEffectColor = true
        }
        get {
            if let color = objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor {
                return color
            }
            return .clear
        }
    }
    
    /// 是否需要模仿 UIButton 的 TouchUpInside 效果（即按下并抬起时在相同富文本上才触发回调），默认 true，若设置为 false，则在 touchesBegan 命中后立即触发回调（类似 TouchDown）
    var wy_touchUpInside: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside) as? Bool ?? true }
    }
    
    /// 最大允许的触摸移动距离（pt），超出则视为取消点击，默认 15.0(仅在 wy_touchUpInside = true 时有效)
    var wy_maxTouchMoveDistance: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance) as? CGFloat ?? 15.0 }
    }
    
    /// 点击时是否启用触摸时长检查，默认 false（立即响应），若为 true，则触摸时长必须小于 wy_touchDurationLimit 才会响应点击
    var wy_enableTouchDurationCheck: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableTouchDurationCheck, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableTouchDurationCheck) as? Bool ?? false }
    }
    
    /// 最长允许的触摸时长（秒），仅在 wy_enableTouchDurationCheck = true 时生效，默认 0.6 秒
    var wy_touchDurationLimit: TimeInterval {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchDurationLimit, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchDurationLimit) as? TimeInterval ?? 0.6 }
    }
    
    /// 是否启用长按回调，默认 false
    var wy_enableLongPress: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableLongPress, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableLongPress) as? Bool ?? false }
    }
    
    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var wy_longPressMinimumDuration: TimeInterval {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings 需要添加点击事件的字符串数组
     * @param handler 点击事件回调闭包，参数依次为：label 自身、点击的字符串、range、在数组中的索引
     *
     */
    func wy_addRichTextTapHandler(strings: [String], handler:((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRanges(strings: strings)
            self.wy_clickBlock = handler
        }
    }
    
    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings 需要添加长按事件的字符串数组
     * @param handler 长按事件回调闭包，参数依次为：label 自身、长按的字符串、range、在数组中的索引
     *
     * 注意：必须先设置 wy_enableLongPress = true 并保证 wy_longPressMinimumDuration 合理。
     */
    func wy_addRichTextLongPressHandler(strings: [String], handler:((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRangesForLongPress(strings: strings)
            self.wy_longPressBlock = handler
        }
    }
    
    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings  需要添加点击事件的字符串数组
     * @param delegate 富文本代理（需实现 WYRichTextDelegate 协议）
     *
     */
    func wy_addRichTextTapDelegate(strings: [String], delegate: WYRichTextDelegate) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRanges(strings: strings)
            self.wy_richTextDelegate = delegate
        }
    }
    
    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings  需要添加长按事件的字符串数组
     * @param delegate 富文本代理（需实现 WYRichTextDelegate 协议）
     *
     */
    func wy_addRichTextLongPressDelegate(strings: [String], delegate: WYRichTextDelegate) {
        DispatchQueue.main.async {
            self.superview?.layoutIfNeeded()
            self.wy_richTextRangesForLongPress(strings: strings)
            self.wy_richTextDelegate = delegate
        }
    }
}

extension UILabel {
    
    // MARK: - 生命周期与触摸事件
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !wy_isUpdatingAttributedText else { return }
        guard let attributedText = attributedText else {
            wy_clearCache()
            return
        }
        // 使用指针比较代替 isEqual，避免深度遍历，提升性能（仅当对象引用变化时才刷新）
        let textChanged = wy_cachedAttributedText !== attributedText
        let boundsChanged = wy_cachedBounds != bounds
        if textChanged || boundsChanged {
            wy_refreshFrameCache(attributedText: attributedText)
            // 只要缓存信息变化且存在富文本，就重新按行分组
            if !wy_attributeStrings.isEmpty {
                wy_refreshLineRanges()
            }
            // 同时刷新长按的行分组（如果有配置）
            if !wy_longPressAttributeStrings.isEmpty {
                wy_longPressLineRanges = wy_groupModelsByLine(for: wy_longPressAttributeStrings)
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
        wy_longPressTriggered = false
        
        var handled = false
        // 尝试命中富文本（使用点击专用的字符串模型），如果命中则记录并处理点击效果
        wy_richTextFrame(touchPoint: point) { [weak self] (string, range, index) in
            handled = true
            self?.wy_currentTouchModel = (string, range, index)
            // 保存效果色（传入当前富文本）
            if let attributedText = self?.attributedText {
                self?.wy_saveEffect(range: range, in: attributedText)
            }
            if self?.wy_touchUpInside == false {
                // 非按钮模式：立即响应点击（不等待 touchesEnded）
                if let block = self?.wy_clickBlock {
                    block(self!, string, range, index)
                }
                if let delegate = self?.wy_richTextDelegate {
                    delegate.wy_richTextDidClick?(self!, richText: string, range: range, index: index)
                }
            }
            if self?.wy_isClickEffect == true {
                self?.wy_clickEffect(true)
            }
        }
        
        // 长按效果色：按下时立即检测是否命中长按专用字符串，若命中则显示长按背景色
        if wy_enableLongPress && !wy_longPressAttributeStrings.isEmpty {
            wy_richTextFrame(touchPoint: point,
                             targetModels: wy_longPressAttributeStrings,
                             targetLineGroups: wy_longPressLineRanges) { [weak self] (string, range, index) in
                guard let self = self else { return }
                // 记录当前命中的长按模型
                self.wy_currentLongPressModel = (string, range, index)
                // 保存长按效果色并立即显示
                if let attributedText = self.attributedText {
                    self.wy_saveLongPressEffect(range: range, in: attributedText)
                }
                self.wy_longPressEffect(true)
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
        let currentTime = Date().timeIntervalSince1970
        let touchDuration = currentTime - (wy_touchBeginTime ?? currentTime)
        var isLongPress = false
        
        // 长按检测（使用长按专用的字符串模型进行命中）
        if wy_enableLongPress && wy_longPressTriggered == false && touchDuration >= wy_longPressMinimumDuration {
            isLongPress = true
            wy_longPressTriggered = true
            // 以开始触摸的位置为准进行长按命中检测，如果有命中的长按模型则触发回调
            if let longPressModel = wy_currentLongPressModel {
                // 回调（长按效果色已经在按下时显示，此处不再重复添加）
                wy_longPressBlock?(self, longPressModel.string, longPressModel.range, longPressModel.index)
                wy_richTextDelegate?.wy_richTextDidLongPress?(self, richText: longPressModel.string, range: longPressModel.range, index: longPressModel.index)
                
                // 长按回调结束后移除效果色（延迟一小段时间让用户看到效果）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.wy_longPressEffect(false)
                    self.wy_currentLongPressModel = nil
                }
            } else {
                // 没有命中的长按模型，直接清除效果色
                wy_longPressEffect(false)
                wy_currentLongPressModel = nil
            }
        }
        
        // 按钮模式：直接使用 touchesBegan 中记录的结果（点击专用），不再重复计算位置
        if wy_touchUpInside == true, let model = wy_currentTouchModel, !isLongPress {
            let endPoint = touches.first?.location(in: self) ?? .zero
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: endPoint)
            let isMoveDistanceValid = moveDistance <= wy_maxTouchMoveDistance
            
            var isTouchDurationValid = true
            if wy_enableTouchDurationCheck {
                isTouchDurationValid = touchDuration < wy_touchDurationLimit
            }
            
            if isMoveDistanceValid && isTouchDurationValid {
                wy_clickBlock?(self, model.string, model.range, model.index)
                wy_richTextDelegate?.wy_richTextDidClick?(self, richText: model.string, range: model.range, index: model.index)
            }
            wy_resetTouchState()
        }
        
        // 如果没有触发长按，清除长按效果色
        if !isLongPress {
            wy_longPressEffect(false)
            wy_currentLongPressModel = nil
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
        if wy_touchUpInside == true {
            wy_resetTouchState()
        }
        if wy_isClickEffect == true {
            wy_clickEffect(false)
        }
        // 长按效果色取消时也清除
        wy_longPressEffect(false)
        wy_currentLongPressModel = nil
        super.touchesCancelled(touches, with: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            super.touchesMoved(touches, with: event)
            return
        }
        
        // 处理点击的移动检测
        if wy_touchUpInside == true, let touch = touches.first, wy_currentTouchModel != nil {
            let currentPoint = touch.location(in: self)
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: currentPoint)
            
            // 超出允许移动距离 → 取消本次点击（清除效果色和 model）
            if moveDistance > wy_maxTouchMoveDistance {
                if wy_isClickEffect == true {
                    wy_clickEffect(false)
                }
                wy_currentTouchModel = nil
            }
            else {
                // 仍在允许距离内，但可能需要根据是否移出富文本区域来消除高亮效果（保持 model 不清除）
                var isInsideRichText = false
                // 移出检测仍以点击模型为准（高亮同步）
                wy_richTextFrame(touchPoint: currentPoint) { [weak self] (string, range, index) in
                    if let currentModel = self?.wy_currentTouchModel,
                       string == currentModel.string && range == currentModel.range && index == currentModel.index {
                        isInsideRichText = true
                    }
                }
                
                // 如果手指移出了原富文本区域，则移除效果色（视觉反馈），但不清空 model
                if !isInsideRichText {
                    if wy_isClickEffect == true {
                        wy_clickEffect(false)
                    }
                }
                else {
                    // 移回区域内时，重新添加效果色（如果之前被移除了）
                    if wy_isClickEffect == true && wy_currentTouchModel != nil {
                        wy_clickEffect(true)
                    }
                }
            }
        }
        
        // 处理长按效果色的移动检测：如果手指移动距离超出阈值或移出当前长按目标区域，则清除长按效果色
        if wy_enableLongPress, let longPressModel = wy_currentLongPressModel, let touch = touches.first {
            let currentPoint = touch.location(in: self)
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: currentPoint)
            // 超出允许移动距离则取消长按效果
            if moveDistance > wy_maxTouchMoveDistance {
                wy_longPressEffect(false)
                wy_currentLongPressModel = nil
            } else {
                // 检查是否仍在长按目标区域内
                var isInsideLongPressText = false
                wy_richTextFrame(touchPoint: currentPoint,
                                 targetModels: wy_longPressAttributeStrings,
                                 targetLineGroups: wy_longPressLineRanges) { (string, range, index) in
                    if string == longPressModel.string && range == longPressModel.range && index == longPressModel.index {
                        isInsideLongPressText = true
                    }
                }
                if !isInsideLongPressText {
                    wy_longPressEffect(false)
                    wy_currentLongPressModel = nil
                }
            }
        }
        
        super.touchesMoved(touches, with: event)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else {
            return super.hitTest(point, with: event)
        }
        // 如果触摸点落在富文本区域（点击专用模型），则当前 label 接收事件
        if wy_richTextFrame(touchPoint: point) == true {
            return self
        }
        return super.hitTest(point, with: event)
    }
    
    // MARK: - 核心命中检测方法
    
    /**
     * 根据触摸点查找命中的富文本（支持指定目标模型）
     *
     * - Parameters:
     *   - touchPoint: 触摸点在当前 label 坐标系中的位置
     *   - targetModels: 要匹配的富文本模型数组（可选，不传则使用点击专用模型）
     *   - targetLineGroups: 对应按行分组的模型（可选，不传则使用点击专用分组）
     *   - handler: 命中后执行的回调，参数为 (字符串, range, 索引)
     * - Returns: 是否命中任何富文本
     *
     * - Note: 该方法正确处理了文本水平对齐（左/中/右）和垂直居中对齐。
     *         字符索引计算基于行实际矩形，点击区域严格等于字符区域。
     */
    @discardableResult
    private func wy_richTextFrame(touchPoint: CGPoint,
                                  targetModels: [WYRichTextModel]? = nil,
                                  targetLineGroups: [[WYRichTextModel]]? = nil,
                                  handler:((_ string: String, _ range: NSRange, _ index: Int) -> Void)? = nil) -> Bool {
        guard let attributedText = attributedText else { return false }
        let (_, lines, origins) = wy_getCachedFrameInfo(attributedText: attributedText)
        guard let lines = lines, let origins = origins else { return false }
        let lineCount = CFArrayGetCount(lines)
        guard lineCount > 0 else { return false }
        
        // 决定使用哪套模型数据（优先使用传入的，否则使用点击专用）
        let useTarget = (targetModels != nil && targetLineGroups != nil)
        let modelsToCheckPerLine = useTarget ? targetLineGroups! : (wy_lineRanges ?? wy_groupModelsByLine(for: wy_attributeStrings))
        let allModels = useTarget ? targetModels! : wy_attributeStrings
        
        // 1. 计算每行在 UIKit 坐标系中的精确矩形（未经垂直居中）
        var lineRects = [CGRect]()
        var totalHeight: CGFloat = 0
        for i in 0..<lineCount {
            let line = CFArrayGetValueAtIndex(lines, i)
            let lineRef = unsafeBitCast(line, to: CTLine.self)
            let origin = origins[i]   // CoreText 坐标系，原点左下角
            
            // 获取行度量信息
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CTLineGetTypographicBounds(lineRef, &ascent, &descent, &leading)
            let height = ascent + descent + leading
            
            // 转换到 UIKit 坐标系（左上角原点）
            let baselineY = bounds.height - origin.y   // 基线的 Y 坐标
            let rect = CGRect(x: origin.x, y: baselineY - ascent, width: width, height: height)
            lineRects.append(rect)
        }
        // 计算总高度（第一行顶部到最后一行底部）
        if let firstRect = lineRects.first, let lastRect = lineRects.last {
            totalHeight = lastRect.maxY - firstRect.minY
        }
        
        // 2. 垂直居中偏移
        let verticalOffset = max(0, (bounds.height - totalHeight) / 2.0)
        
        // 3. 命中检测
        for i in 0..<lineCount {
            var lineRect = lineRects[i]
            lineRect.origin.y += verticalOffset
            
            let line = CFArrayGetValueAtIndex(lines, i)
            let lineRef = unsafeBitCast(line, to: CTLine.self)
            
            if lineRect.contains(touchPoint) {
                // 计算相对坐标（相对于行矩形左边缘）
                let relativePoint = CGPoint(
                    x: touchPoint.x - lineRect.minX,
                    y: touchPoint.y - lineRect.minY
                )
                var index = CTLineGetStringIndexForPosition(lineRef, relativePoint)
                var offset: CGFloat = 0.0
                CTLineGetOffsetForStringIndex(lineRef, index, &offset)
                if offset > relativePoint.x {
                    index = max(index - 1, 0)
                }
                
                let modelsToCheck = (i < modelsToCheckPerLine.count) ? modelsToCheckPerLine[i] : []
                for (j, model) in modelsToCheck.enumerated() {
                    let linkRange = model.wy_range
                    if NSLocationInRange(index, linkRange) {
                        let globalIndex = allModels.firstIndex(where: { $0.wy_range == linkRange }) ?? j
                        handler?(model.wy_richText, model.wy_range, globalIndex)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // MARK: - 辅助布局方法
    
    /// 获取缓存的 CTFrame、lines 和 line origins，必要时刷新缓存
    private func wy_getCachedFrameInfo(attributedText: NSAttributedString) -> (CTFrame?, CFArray?, [CGPoint]?) {
        if wy_cachedAttributedText !== attributedText || wy_cachedBounds != bounds {
            wy_refreshFrameCache(attributedText: attributedText)
        }
        return (wy_ctFrame, wy_lines, wy_lineOrigins)
    }
    
    /// 刷新布局缓存：创建 CTFrame，提取 lines 和 origins
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
    
    /// 按行重新分组点击专用富文本模型（用于优化每行查找）
    private func wy_refreshLineRanges() {
        wy_lineRanges = wy_groupModelsByLine(for: wy_attributeStrings)
    }
    
    // MARK: - 点击效果处理
    
    /**
     * 添加或移除点击效果背景色
     *
     * - Parameter status: true 表示添加效果色，false 表示移除效果色
     */
    private func wy_clickEffect(_ status: Bool) {
        guard wy_isClickEffect,
              let effectRanges = wy_effectRanges,
              !effectRanges.isEmpty,
              let currentText = attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: currentText)
        var didChange = false
        
        for rangeKey in effectRanges {
            let range = NSRangeFromString(rangeKey)
            /// 获取该 range 应该使用的效果色
            let effectColor: UIColor
            if wy_hasCustomEffectColor {
                /// 用户主动设置了全局颜色，使用该颜色（可能为 .clear）
                effectColor = wy_clickEffectColor
            } else {
                /// 用户未设置，从字典中取动态颜色
                effectColor = wy_effectColors?[rangeKey] ?? .clear
            }
            
            if status {
                /// 仅当该位置没有背景色时才添加效果色，避免覆盖原有背景
                if mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) == nil {
                    mutableText.addAttribute(.backgroundColor, value: effectColor, range: range)
                    didChange = true
                }
            } else {
                /// 移除自己添加的效果色（只移除颜色与效果色相同的背景）
                if let bgColor = mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? UIColor,
                   bgColor == effectColor {
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
        
        if !status {
            /// 清除效果后清空临时存储的 range 和颜色字典
            wy_effectRanges = nil
            wy_effectColors = nil
        }
    }
    
    /// 保存需要添加点击效果的 range 集合，并预先计算效果色（若用户未自定义则使用文字颜色 + 0.25 透明度）
    private func wy_saveEffect(range: NSRange, in attributedString: NSAttributedString) {
        let rangeKey = NSStringFromRange(range)
        wy_effectRanges = Set([rangeKey])
        
        /// 计算该 range 的效果色
        let effectColor: UIColor
        if wy_hasCustomEffectColor {
            effectColor = wy_clickEffectColor
        } else {
            /// 动态获取文字颜色：优先取 foregroundColor，默认黑色
            var textColor = UIColor.black
            if let color = attributedString.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor {
                textColor = color
            }
            effectColor = textColor.withAlphaComponent(0.25)
        }
        wy_effectColors = [rangeKey: effectColor]
    }
    
    // MARK: - 长按效果处理
    
    /// 添加或移除长按效果背景色
    private func wy_longPressEffect(_ status: Bool) {
        guard wy_enableLongPress,
              let effectRanges = wy_longPressEffectRanges,
              !effectRanges.isEmpty,
              let currentText = attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: currentText)
        var didChange = false
        
        for rangeKey in effectRanges {
            let range = NSRangeFromString(rangeKey)
            /// 获取该 range 应该使用的效果色
            let effectColor: UIColor
            if wy_hasCustomLongPressEffectColor {
                effectColor = wy_longPressEffectColor
            } else {
                effectColor = wy_longPressEffectColors?[rangeKey] ?? .clear
            }
            
            if status {
                if mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) == nil {
                    mutableText.addAttribute(.backgroundColor, value: effectColor, range: range)
                    didChange = true
                }
            } else {
                if let bgColor = mutableText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) as? UIColor,
                   bgColor == effectColor {
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
        
        if !status {
            wy_longPressEffectRanges = nil
            wy_longPressEffectColors = nil
        }
    }
    
    /// 保存需要添加长按效果的 range 集合，并预先计算效果色
    private func wy_saveLongPressEffect(range: NSRange, in attributedString: NSAttributedString) {
        let rangeKey = NSStringFromRange(range)
        wy_longPressEffectRanges = Set([rangeKey])
        
        let effectColor: UIColor
        if wy_hasCustomLongPressEffectColor {
            effectColor = wy_longPressEffectColor
        } else {
            var textColor = UIColor.black
            if let color = attributedString.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor {
                textColor = color
            }
            effectColor = textColor.withAlphaComponent(0.25)
        }
        wy_longPressEffectColors = [rangeKey: effectColor]
    }
    
    // MARK: - 富文本模型构建与分组
    
    /// 使用正则表达式一次性查找所有关键词的位置，并构建点击专用富文本模型数组
    private func wy_richTextRanges(strings: [String]) {
        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        wy_isClickEffect = true
        isUserInteractionEnabled = true
        let originalString = attributed.string
        wy_attributeStrings = []
        
        /// 构建正则模式，转义特殊字符，用 "|" 连接所有关键词
        let escapedPatterns = strings.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = escapedPatterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let nsRange = NSRange(location: 0, length: originalString.utf16.count)
        let matches = regex.matches(in: originalString, options: [], range: nsRange)
        for match in matches {
            let nsRange = match.range
            var model = WYRichTextModel()
            model.wy_range = nsRange
            model.wy_richText = (originalString as NSString).substring(with: nsRange)
            wy_attributeStrings.append(model)
        }
        
        wy_refreshFrameCache(attributedText: attributed)
        wy_lineRanges = wy_groupModelsByLine(for: wy_attributeStrings)
    }
    
    /// 使用正则表达式一次性查找所有关键词的位置，并构建长按专用富文本模型数组
    private func wy_richTextRangesForLongPress(strings: [String]) {
        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        let originalString = attributed.string
        wy_longPressAttributeStrings = []
        
        /// 构建正则模式，转义特殊字符，用 "|" 连接所有关键词
        let escapedPatterns = strings.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = escapedPatterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let nsRange = NSRange(location: 0, length: originalString.utf16.count)
        let matches = regex.matches(in: originalString, options: [], range: nsRange)
        for match in matches {
            var model = WYRichTextModel()
            model.wy_range = match.range
            model.wy_richText = (originalString as NSString).substring(with: match.range)
            wy_longPressAttributeStrings.append(model)
        }
        
        wy_longPressLineRanges = wy_groupModelsByLine(for: wy_longPressAttributeStrings)
    }
    
    /**
     * 将给定的富文本模型按行分组，便于在命中时只检查当前行（性能优化）
     *
     * - Parameter models: 需要分组的富文本模型数组
     * - Returns: 按行索引组织的二维数组
     */
    private func wy_groupModelsByLine(for models: [WYRichTextModel]) -> [[WYRichTextModel]] {
        guard let lines = wy_lines, let _ = attributedText else { return [] }
        let lineCount = CFArrayGetCount(lines)
        guard lineCount > 0 else { return [] }
        var groups = [[WYRichTextModel]](repeating: [], count: lineCount)
        for model in models {
            let modelRange = model.wy_range
            for i in 0..<lineCount {
                guard let line = CFArrayGetValueAtIndex(lines, i) else { continue }
                let lineRef = unsafeBitCast(line, to: CTLine.self)
                let lineRange = CTLineGetStringRange(lineRef)
                let intersection = NSIntersectionRange(modelRange, NSRange(location: lineRange.location, length: lineRange.length))
                if intersection.length > 0 {
                    groups[i].append(model)
                    /// 如果模型完全落在这行内，则不再检查后面的行（优化）
                    if modelRange.location >= lineRange.location &&
                        modelRange.location + modelRange.length <= lineRange.location + lineRange.length {
                        break
                    }
                }
            }
        }
        return groups
    }
    
    /// 重置触摸状态（清空当前触摸模型、开始坐标、开始时间）
    private func wy_resetTouchState() {
        wy_currentTouchModel = nil
        wy_touchBeginPoint = nil
        wy_touchBeginTime = nil
    }
    
    /// 计算两点之间的欧氏距离
    private func wy_calculateDistance(from point1: CGPoint?, to point2: CGPoint) -> CGFloat {
        guard let point1 = point1 else { return .greatestFiniteMagnitude }
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// 清除所有缓存数据（CTFrame、lines、origins 及效果色缓存）
    private func wy_clearCache() {
        wy_ctFrame = nil
        wy_lines = nil
        wy_lineOrigins = nil
        wy_cachedAttributedText = nil
        wy_cachedBounds = .zero
        wy_effectRanges = nil
        wy_effectColors = nil
        wy_longPressEffectRanges = nil
        wy_longPressEffectColors = nil
    }
    
    // MARK: - Private Properties
    
    /// 当前触摸命中的富文本模型（字符串、range、索引）—— 用于点击
    private var wy_currentTouchModel: (string: String, range: NSRange, index: Int)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel) as? (String, NSRange, Int) }
    }
    
    /// 当前触摸命中的长按富文本模型（用于长按效果色）
    private var wy_currentLongPressModel: (string: String, range: NSRange, index: Int)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentLongPressModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentLongPressModel) as? (String, NSRange, Int) }
    }
    
    /// 触摸开始时的坐标点
    private var wy_touchBeginPoint: CGPoint? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint) as? CGPoint }
    }
    
    /// 触摸开始时的系统时间戳
    private var wy_touchBeginTime: TimeInterval? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime) as? TimeInterval }
    }
    
    /// 点击事件的 Block 回调
    private var wy_clickBlock: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index : Int) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickBlock) as? (UILabel, String, NSRange, Int) -> Void }
    }
    
    /// 长按事件的 Block 回调
    private var wy_longPressBlock: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index : Int) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressBlock, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressBlock) as? (UILabel, String, NSRange, Int) -> Void }
    }
    
    /// 富文本 Delegate（弱引用），同时用于点击和长按（协议方法可选）
    private weak var wy_richTextDelegate: WYRichTextDelegate? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate, newValue, .OBJC_ASSOCIATION_ASSIGN) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_richTextDelegate) as? WYRichTextDelegate }
    }
    
    /// 内部标志：是否允许当前点击效果
    private var wy_isClickEffect: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickEffect) as? Bool ?? true }
    }
    
    /// 内部标志：当前 label 是否有点击动作（富文本）
    private var wy_isClickAction: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isClickAction) as? Bool ?? false }
    }
    
    /// 存储所有需要响应的富文本模型（点击专用，未分组）
    private var wy_attributeStrings: [WYRichTextModel] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_attributeStrings) as? [WYRichTextModel] ?? [] }
    }
    
    /// 存储长按专用的富文本模型（未分组）
    private var wy_longPressAttributeStrings: [WYRichTextModel] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressAttributeStrings, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressAttributeStrings) as? [WYRichTextModel] ?? [] }
    }
    
    /// 当前需要添加点击效果的 range 集合（用于点击效果）
    private var wy_effectRanges: Set<String>? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_effectRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_effectRanges) as? Set<String> }
    }
    
    /// 存储每个 range 对应的动态效果色（仅在用户未自定义时使用）
    private var wy_effectColors: [String: UIColor]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_effectColors, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_effectColors) as? [String: UIColor] }
    }
    
    /// 当前需要添加长按效果的 range 集合
    private var wy_longPressEffectRanges: Set<String>? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectRanges) as? Set<String> }
    }
    
    /// 存储每个 range 对应的长按动态效果色
    private var wy_longPressEffectColors: [String: UIColor]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColors, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColors) as? [String: UIColor] }
    }
    
    /// CoreText 的 CTFrame 缓存
    private var wy_ctFrame: CTFrame? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_ctFrame, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_ctFrame) as! CTFrame? }
    }
    
    /// CTFrame 中的所有 CTLine 缓存
    private var wy_lines: CFArray? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lines, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lines) as! CFArray? }
    }
    
    /// 每行 line 的原点坐标缓存（CoreText 坐标系）
    private var wy_lineOrigins: [CGPoint]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineOrigins, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineOrigins) as? [CGPoint] }
    }
    
    /// 缓存的富文本（用于比较变化）
    private var wy_cachedAttributedText: NSAttributedString? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_cachedAttributedText, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_cachedAttributedText) as? NSAttributedString }
    }
    
    /// 缓存的 bounds（用于比较变化）
    private var wy_cachedBounds: CGRect {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_cachedBounds, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_cachedBounds) as? CGRect ?? .zero }
    }
    
    /// 是否正在更新 attributdText（避免循环刷新）
    private var wy_isUpdatingAttributedText: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isUpdatingAttributedText, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isUpdatingAttributedText) as? Bool ?? false }
    }
    
    /// 按行分组后的点击专用富文本模型（用于快速命中）
    private var wy_lineRanges: [[WYRichTextModel]]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineRanges) as? [[WYRichTextModel]] }
    }
    
    /// 按行分组后的长按专用富文本模型（用于快速命中）
    private var wy_longPressLineRanges: [[WYRichTextModel]]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressLineRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressLineRanges) as? [[WYRichTextModel]] }
    }
    
    /// 长按是否已触发（防止重复回调）
    private var wy_longPressTriggered: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered) as? Bool ?? false }
    }
    
    /// 用户是否主动设置过 wy_clickEffectColor（若未设置则使用动态取色）
    private var wy_hasCustomEffectColor: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_hasCustomEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_hasCustomEffectColor) as? Bool ?? false }
    }
    
    /// 用户是否主动设置过 wy_longPressEffectColor
    private var wy_hasCustomLongPressEffectColor: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_hasCustomLongPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_hasCustomLongPressEffectColor) as? Bool ?? false }
    }
    
    // MARK: - Associated Keys
    private struct WYAssociatedKeys {
        static var wy_richTextDelegate: UInt8 = 0
        static var wy_enableClickEffect: UInt8 = 0
        static var wy_isClickEffect: UInt8 = 0
        static var wy_isClickAction: UInt8 = 0
        static var wy_clickEffectColor: UInt8 = 0
        static var wy_longPressEffectColor: UInt8 = 0
        static var wy_attributeStrings: UInt8 = 0
        static var wy_longPressAttributeStrings: UInt8 = 0
        static var wy_effectRanges: UInt8 = 0
        static var wy_effectColors: UInt8 = 0
        static var wy_longPressEffectRanges: UInt8 = 0
        static var wy_longPressEffectColors: UInt8 = 0
        static var wy_clickBlock: UInt8 = 0
        static var wy_longPressBlock: UInt8 = 0
        static var wy_currentTouchModel: UInt8 = 0
        static var wy_currentLongPressModel: UInt8 = 0
        static var wy_needTouchUpInside: UInt8 = 0
        static var wy_touchBeginPoint: UInt8 = 0
        static var wy_touchBeginTime: UInt8 = 0
        static var wy_maxTouchMoveDistance: UInt8 = 0
        static var wy_enableTouchDurationCheck: UInt8 = 0
        static var wy_touchDurationLimit: UInt8 = 0
        static var wy_ctFrame: UInt8 = 0
        static var wy_lines: UInt8 = 0
        static var wy_lineOrigins: UInt8 = 0
        static var wy_cachedAttributedText: UInt8 = 0
        static var wy_cachedBounds: UInt8 = 0
        static var wy_isUpdatingAttributedText: UInt8 = 0
        static var wy_lineRanges: UInt8 = 0
        static var wy_longPressLineRanges: UInt8 = 0
        static var wy_enableLongPress: UInt8 = 0
        static var wy_longPressMinimumDuration: UInt8 = 0
        static var wy_longPressTriggered: UInt8 = 0
        static var wy_hasCustomEffectColor: UInt8 = 0
        static var wy_hasCustomLongPressEffectColor: UInt8 = 0
    }
}

// MARK: - 内部富文本模型
private struct WYRichTextModel {
    /// 要匹配的字符串内容
    var wy_richText: String = ""
    /// 在完整文本中的位置
    var wy_range: NSRange = NSRange()
}
