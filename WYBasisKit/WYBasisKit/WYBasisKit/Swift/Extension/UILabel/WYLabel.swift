//
//  UILabel.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import CoreText
import Foundation

/// 文本交互事件的代理协议，可选择性实现点击或长按回调。
@objc public protocol WYRichTextTouchDelegate {

    /**
     * 文本点击回调
     *
     * @param label    当前 UILabel 实例
     * @param text     被点击的字符串内容
     * @param range    被点击字符串在整个文本中的 NSRange
     * @param index    本次命中的词在其所属注册解析出的全部范围中按文本出现顺序的下标(同一词多次出现时用于区分点中的是哪一处)
     */
    @objc(wy_richTextDidClick:text:range:index:)
    optional func wy_richTextDidClick(_ label: UILabel, text: String, range: NSRange, index: Int)

    /**
     * 文本长按回调
     *
     * @param label    当前 UILabel 实例
     * @param text     被长按的字符串内容
     * @param range    被长按字符串在整个文本中的 NSRange
     * @param index    本次命中的词在其所属注册解析出的全部范围中按文本出现顺序的下标(同一词多次出现时用于区分点中的是哪一处)
     */
    @objc(wy_richTextDidLongPress:text:range:index:)
    optional func wy_richTextDidLongPress(_ label: UILabel, text: String, range: NSRange, index: Int)
}

public extension UILabel {
    
    /**
     * 点击效果颜色（按下时的背景色）
     *
     * - 若用户未主动设置，则自动使用被点击富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    var wy_clickEffectColor: UIColor? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /**
     * 长按效果颜色（长按时背景色）
     *
     * - 若用户未主动设置，则先回退使用 wy_clickEffectColor；两者都未设置时，自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     * - 显示时机为只注册了长按的文本按下立即显示本颜色；同时注册了点击的文本按下先显示点击效果色，达到长按最小时长后才切换为本颜色（因为按下瞬间无法区分用户想点击还是长按）。
     */
    var wy_longPressEffectColor: UIColor? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 true 时按下用效果色盖住、手指移开后还原自带背景色；为 false 时自带背景色的文本按下不显示高亮)
    var wy_overlaysOriginalBackground: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_overlaysOriginalBackground) as? Bool ?? true }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_overlaysOriginalBackground, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var wy_longPressMinimumDuration: TimeInterval {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }

    /// 是否需要模仿 UIButton 的 TouchUpInside 效果（即按下并抬起时在相同富文本上才触发回调），默认 true，若设置为 false，则在 touchesBegan 命中后立即触发回调（类似 TouchDown；注意此时同词又注册了长按的话，一次长按操作会先触发点击回调、到时长再触发长按回调）
    var wy_touchUpInside: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_needTouchUpInside) as? Bool ?? true }
    }

    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 点击事件回调闭包
     *
     */
    func wy_addTextTapHandler(rangeValue: Any, handler:((_ label: UILabel, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.superview?.layoutIfNeeded()
            self.wy_registerTouchTargets(rangeValue: rangeValue, isLongPress: false, handler: handler, delegate: nil)
        }
    }

    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 长按事件回调闭包
     *
     */
    func wy_addTextLongPressHandler(rangeValue: Any, handler:((_ label: UILabel, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.superview?.layoutIfNeeded()
            self.wy_registerTouchTargets(rangeValue: rangeValue, isLongPress: true, handler: handler, delegate: nil)
        }
    }

    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 点击代理（需实现 WYRichTextTouchDelegate 协议）
     *
     */
    func wy_addTextTapDelegate(rangeValue: Any, delegate: WYRichTextTouchDelegate) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.superview?.layoutIfNeeded()
            self.wy_registerTouchTargets(rangeValue: rangeValue, isLongPress: false, handler: nil, delegate: delegate)
        }
    }

    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 长按代理（需实现 WYRichTextTouchDelegate 协议）
     *
     */
    func wy_addTextLongPressDelegate(rangeValue: Any, delegate: WYRichTextTouchDelegate) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.superview?.layoutIfNeeded()
            self.wy_registerTouchTargets(rangeValue: rangeValue, isLongPress: true, handler: nil, delegate: delegate)
        }
    }
}

extension UILabel {

    /// 布局变化时刷新排版缓存(富文本对象或尺寸变化才重新排版，并做陈旧高亮防护)
    private func wy_refreshLayoutCacheIfNeeded() {
        guard let attributedText = attributedText else {
            wy_clearCache()
            return
        }
        // 使用指针比较代替 isEqual，避免深度遍历，提升性能（仅当对象引用变化时才刷新）
        let textChanged = wy_cachedAttributedText !== attributedText
        let boundsChanged = wy_cachedBounds != bounds
        // 防陈旧高亮:按下期间文本被外部替换时，高亮矩形与剥离备份均已过期，直接丢弃且不回写还原(还原会覆盖外部新文本)；仅尺寸变化时正常还原清除
        if wy_highlight != nil {
            if textChanged {
                wy_highlight = nil
                setNeedsDisplay()
            } else if boundsChanged {
                wy_clearHighlight()
            }
        }
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

    /// 按下时记录起点并做命中检测，命中点击词应用点击高亮，命中长按词开表(纯长按词立即显示长按色)
    private func wy_handleTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }
        let touch = touches.first
        let point: CGPoint = touch?.location(in: self) ?? .zero
        wy_touchBeginPoint = point
        wy_touchBeginTime = Date().timeIntervalSince1970
        wy_longPressTriggered = false

        // 命中点击的全部富文本模型(同一点多路注册全部命中，各自携带回调)
        let tapMatches = wy_allMatchedModels(at: point, models: nil, lineGroups: nil)
        wy_touchStartTapModels = tapMatches
        if let firstMatch = tapMatches.first {
            wy_currentTouchModel = firstMatch
            if wy_touchUpInside == false {
                // 非按钮模式：立即响应点击（不等待 touchesEnded）
                for model in tapMatches {
                    model.handler?(self, model.wy_richText, model.wy_range, model.registrationIndex)
                    model.delegate?.wy_richTextDidClick?(self, text: model.wy_richText, range: model.wy_range, index: model.registrationIndex)
                }
            }
            // 命中点击的词按下先显示点击效果色(同时注册了长按的词到长按时长后再切长按效果色，因为按下瞬间无法区分意图)
            wy_applyHighlight(range: firstMatch.wy_range, isLongPress: false)
        }

        // 长按检测：按下时立即检测是否命中长按专用字符串，命中则开表
        if !wy_longPressAttributeStrings.isEmpty {
            let longMatches = wy_allMatchedModels(at: point, models: wy_longPressAttributeStrings, lineGroups: wy_longPressLineRanges)
            if let firstLongMatch = longMatches.first {
                // 记录当前命中的长按模型
                wy_currentLongPressModel = firstLongMatch
                // 只注册了长按的词不存在点击歧义，按下即显示长按效果色；双注册词保持上面已应用的点击效果色
                if wy_currentTouchModel == nil {
                    wy_applyHighlight(range: firstLongMatch.wy_range, isLongPress: true)
                }
                // 命中长按目标即开表，到最小时长就地触发回调(不等松手)
                wy_scheduleLongPressTimer()
            }
        }
    }

    /// 松手时停表，长按未触发的按按钮模式规则回调点击，最后清除按下高亮
    private func wy_handleTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }

        // 松手即停表(到时长的长按已在定时器触发时就地回调，提前松手则取消不触发)
        wy_invalidateLongPressTimer()

        // 按钮模式：直接使用 touchesBegan 中记录的结果（点击专用），不再重复计算位置
        // 长按已触发的本次触摸不再响应点击(防止长按松手后又触发点击回调)
        if wy_touchUpInside == true, !wy_touchStartTapModels.isEmpty, wy_longPressTriggered == false {
            let endPoint = touches.first?.location(in: self) ?? .zero
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: endPoint)

            if moveDistance <= wy_maxTouchMoveDistance {
                for model in wy_touchStartTapModels {
                    model.handler?(self, model.wy_richText, model.wy_range, model.registrationIndex)
                    model.delegate?.wy_richTextDidClick?(self, text: model.wy_richText, range: model.wy_range, index: model.registrationIndex)
                }
            }
            wy_resetTouchState()
        }

        // 清除按下高亮(长按已触发的也在此清除，高亮保持到手指移开，与 UITextView 行为一致)
        wy_clearHighlight()
        wy_currentLongPressModel = nil
    }

    /// 触摸被系统取消时停表并清理按下状态与高亮
    private func wy_handleTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }
        // 触摸被系统取消(来电、手势竞争等)时停表，长按不再触发
        wy_invalidateLongPressTimer()
        if wy_touchUpInside == true {
            wy_resetTouchState()
        }
        // 清除按下高亮(若有)
        wy_clearHighlight()
        wy_currentLongPressModel = nil
    }

    /// 移动时按距离与所在词区域做取消判定，移出清高亮停表，移回重新应用效果色
    private func wy_handleTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }

        // 处理点击的移动检测
        if wy_touchUpInside == true, let touch = touches.first, wy_currentTouchModel != nil {
            let currentPoint = touch.location(in: self)
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: currentPoint)

            // 超出允许移动距离 → 取消本次点击（清除效果色和 model）
            if moveDistance > wy_maxTouchMoveDistance {
                wy_clearHighlight()
                wy_currentTouchModel = nil
                wy_touchStartTapModels = []
            }
            else {
                // 仍在允许距离内，但可能需要根据是否移出富文本区域来消除高亮效果（保持 model 不清除）
                var isInsideRichText = false
                // 移出检测仍以点击模型为准（高亮同步）
                wy_richTextFrame(touchPoint: currentPoint) { [weak self] hitModel in
                    if let currentModel = self?.wy_currentTouchModel,
                       hitModel.wy_range == currentModel.wy_range {
                        isInsideRichText = true
                    }
                }

                // 如果手指移出了原富文本区域，则移除效果色（视觉反馈），但不清空 model
                if !isInsideRichText {
                    wy_clearHighlight()
                }
                else {
                    // 移回区域内时重新应用效果色(长按已触发后不再回切点击效果色，防止长按完成后移回又闪点击色)
                    if let currentModel = wy_currentTouchModel, wy_longPressTriggered == false {
                        wy_applyHighlight(range: currentModel.wy_range, isLongPress: false)
                    }
                }
            }
        }

        // 处理长按的移动检测：如果手指移动距离超出阈值或移出当前长按目标区域，则清除高亮并停表
        if let longPressModel = wy_currentLongPressModel, let touch = touches.first {
            let currentPoint = touch.location(in: self)
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: currentPoint)
            // 超出允许移动距离则取消长按效果并停表
            if moveDistance > wy_maxTouchMoveDistance {
                wy_invalidateLongPressTimer()
                wy_clearHighlight()
                wy_currentLongPressModel = nil
            } else {
                // 检查是否仍在长按目标区域内
                var isInsideLongPressText = false
                wy_richTextFrame(touchPoint: currentPoint,
                                 targetModels: wy_longPressAttributeStrings,
                                 targetLineGroups: wy_longPressLineRanges) { hitModel in
                    if hitModel.wy_range == longPressModel.wy_range {
                        isInsideLongPressText = true
                    }
                }
                if !isInsideLongPressText {
                    wy_invalidateLongPressTimer()
                    wy_clearHighlight()
                    wy_currentLongPressModel = nil
                }
            }
        }
    }

    /// 交换 touches 系列方法(按下/移动/松手/系统取消的处理都挂在原方法执行前)
    static let wy_swizzleTouchMethods: Void = {
        wy_swizzlerTouchesBegan(for: UILabel.self, before: { responder, touches, event in
            guard let label = responder as? UILabel else { return }
            label.wy_handleTouchesBegan(touches, with: event)
        })
        wy_swizzlerTouchesMoved(for: UILabel.self, before: { responder, touches, event in
            guard let label = responder as? UILabel else { return }
            label.wy_handleTouchesMoved(touches, with: event)
        })
        wy_swizzlerTouchesEnded(for: UILabel.self, before: { responder, touches, event in
            guard let label = responder as? UILabel else { return }
            label.wy_handleTouchesEnded(touches, with: event)
        })
        wy_swizzlerTouchesCancelled(for: UILabel.self, before: { responder, touches, event in
            guard let label = responder as? UILabel else { return }
            label.wy_handleTouchesCancelled(touches, with: event)
        })
    }()

    /// 交换 layoutSubviews(布局完成后按需刷新排版缓存，等价于原实现的 super 先行)
    static let wy_swizzleLayoutMethod: Void = {
        wy_swizzlerLayoutSubviews(for: UILabel.self, after: { currentView in
            guard let label = currentView as? UILabel else { return }
            label.wy_refreshLayoutCacheIfNeeded()
        })
    }()

    /// 如果尚未实现方法交换，则进行交换
    func wy_enableSwizzleMethods() {
        _ = Self.wy_swizzleTouchMethods
        _ = Self.wy_swizzleLayoutMethod
        _ = Self.wy_swizzleDrawText
    }

    /**
     * 根据触摸点查找命中的富文本（支持指定目标模型）
     *
     * - Parameters:
     *   - touchPoint: 触摸点在当前 label 坐标系中的位置
     *   - targetModels: 要匹配的富文本模型数组（可选，不传则使用点击专用模型）
     *   - targetLineGroups: 对应按行分组的模型（可选，不传则使用点击专用分组）
     *   - handler: 命中后执行的回调，参数为命中的富文本模型(含字符串、range、索引与所属注册的回调)
     * - Returns: 是否命中任何富文本
     *
     * - Note: 该方法正确处理了文本水平对齐（左/中/右）和垂直居中对齐。
     *         排版使用 TextKit（iOS 15+优先TextKit2，旧系统TextKit1），与 UILabel 渲染走同一套引擎，
     *         自定义字体的行高、基线、换行位置也与实际显示一致，字符索引计算基于行实际矩形，点击区域严格等于字符区域。
     */
    @discardableResult
    private func wy_richTextFrame(touchPoint: CGPoint,
                                  targetModels: [WYRichTextModel]? = nil,
                                  targetLineGroups: [[WYRichTextModel]]? = nil,
                                  handler:((_ model: WYRichTextModel) -> Void)? = nil) -> Bool {
        guard let attributedText = attributedText else { return false }

        // 缓存过期（富文本对象或尺寸变化）时重新排版，行分组一并重建
        // 防行分组过期:注册回调时label可能尚未布局完成(bounds为零)，之后命中时若发现缓存过期只刷行矩形不重建分组，会用旧分组把别的行的字符张冠李戴
        if wy_cachedAttributedText !== attributedText || wy_cachedBounds != bounds {
            wy_refreshFrameCache(attributedText: attributedText)
            if !wy_attributeStrings.isEmpty {
                wy_refreshLineRanges()
            }
            if !wy_longPressAttributeStrings.isEmpty {
                wy_longPressLineRanges = wy_groupModelsByLine(for: wy_longPressAttributeStrings)
            }
        }
        guard let layoutEngine = wy_layoutEngine,
              let lineRects = wy_lineRects,
              !lineRects.isEmpty else { return false }

        // 决定使用哪套模型数据（优先使用传入的，否则使用点击专用）
        let useTarget = (targetModels != nil && targetLineGroups != nil)
        let modelsToCheckPerLine = useTarget ? targetLineGroups! : (wy_lineRanges ?? wy_groupModelsByLine(for: wy_attributeStrings))

        // 触摸点换算回排版布局坐标（布局坐标 y 从文本内容顶部向下，行矩形本身不含垂直居中偏移）
        let layoutPoint = CGPoint(x: touchPoint.x, y: touchPoint.y - wy_verticalOffset)

        // 命中检测：先定位行，再反查行内字符下标（iOS 15+内部走TextKit2，旧系统TextKit1）
        for (i, lineRect) in lineRects.enumerated() {
            guard lineRect.contains(layoutPoint) else { continue }

            guard let index = layoutEngine.characterIndex(at: layoutPoint) else { return false }

            // 同一点重叠注册的模型全部回调(各自携带所属注册的回调)，与 UITextView 的全部触发语义一致
            var found = false
            let modelsToCheck = (i < modelsToCheckPerLine.count) ? modelsToCheckPerLine[i] : []
            for model in modelsToCheck {
                if NSLocationInRange(index, model.wy_range) {
                    handler?(model)
                    found = true
                }
            }
            if found { return true }
        }
        return false
    }

    /// 获取触摸点命中的全部富文本模型(同一点重叠注册的词全部返回)
    private func wy_allMatchedModels(at point: CGPoint, models: [WYRichTextModel]?, lineGroups: [[WYRichTextModel]]?) -> [WYRichTextModel] {
        var matched: [WYRichTextModel] = []
        wy_richTextFrame(touchPoint: point, targetModels: models, targetLineGroups: lineGroups) { model in
            matched.append(model)
        }
        return matched
    }

    /// 刷新布局缓存：用TextKit对当前富文本排版，记录每行矩形、字符范围与垂直居中偏移
    private func wy_refreshFrameCache(attributedText: NSAttributedString) {
        wy_cachedAttributedText = attributedText
        wy_cachedBounds = bounds

        // 用TextKit排版(iOS 15+优先TextKit2，旧系统TextKit1；防自定义字体命中偏移:CoreText与UILabel渲染在自定义字体上行高/基线不一致，换成与UILabel同源的TextKit)
        let layoutEngine = WYTextLayoutEngine(attributedText: attributedText,
                                              containerSize: bounds.size,
                                              numberOfLines: numberOfLines,
                                              lineBreakMode: lineBreakMode)

        // UILabel 内容整体垂直居中，按文本块整体高度算顶部偏移
        wy_verticalOffset = max(0, (bounds.height - layoutEngine.textBlockHeight) / 2.0)

        wy_lineRects = layoutEngine.lineRects
        wy_lineCharacterRanges = layoutEngine.lineCharacterRanges
        wy_layoutEngine = layoutEngine
    }

    /// 按行重新分组点击专用富文本模型（用于优化每行查找）
    private func wy_refreshLineRanges() {
        wy_lineRanges = wy_groupModelsByLine(for: wy_attributeStrings)
    }

    /// 为命中的富文本应用按下高亮(按效果色规则取色，用排版引擎算出词语各分行矩形后重绘，不动 attributedText)
    private func wy_applyHighlight(range: NSRange, isLongPress: Bool) {
        wy_clearHighlight()

        guard let attributedText = attributedText, let layoutEngine = wy_layoutEngine else { return }

        // wy_overlaysOriginalBackground 为 false 时，自带背景色的文本不高亮(原背景色保持不动)
        let hasOriginalBackground = attributedText.attribute(.backgroundColor, at: range.location, effectiveRange: nil) != nil
        if hasOriginalBackground && wy_overlaysOriginalBackground == false { return }

        // 效果色取色与 UITextView 同规则，长按优先长按效果色，未单独设置回退点击效果色，都未设置动态取文字色 + 0.25 透明度
        let effectColor: UIColor
        if isLongPress, let longPressColor = wy_longPressEffectColor {
            effectColor = longPressColor
        } else if let customColor = wy_clickEffectColor {
            effectColor = customColor
        } else {
            let textColor = attributedText.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor ?? .black
            effectColor = textColor.withAlphaComponent(0.25)
        }

        // 用排版引擎取词的分行矩形，加垂直居中偏移换算到 label 坐标系
        let rects = layoutEngine.wy_boundingRects(for: range).map { $0.rect.offsetBy(dx: 0, dy: wy_verticalOffset) }
        guard !rects.isEmpty else { return }

        // 覆盖模式下自带背景色的词，先暂时剥离其背景色(原背景画在文字绘制阶段，会盖住下层高亮)，手指移开后整体还原
        var originalText: NSAttributedString? = nil
        if hasOriginalBackground {
            let strippedText = NSMutableAttributedString(attributedString: attributedText)
            strippedText.removeAttribute(.backgroundColor, range: range)
            self.attributedText = strippedText
            // 缓存同步为当前显示文本(用 getter 结果，UILabel 可能返回内部副本)，避免 layoutSubviews 误判文本变化触发重新排版
            wy_cachedAttributedText = self.attributedText
            originalText = attributedText
        }

        wy_highlight = WYLabelHighlight(rects: rects, color: effectColor, originalText: originalText)
        setNeedsDisplay()
    }

    /// 清除按下高亮(若覆盖模式剥离过原背景色，这里整体回写还原原富文本)
    private func wy_clearHighlight() {
        guard let highlight = wy_highlight else { return }
        if let originalText = highlight.originalText {
            attributedText = originalText
            // 缓存同步还原后的文本，理由同应用时
            wy_cachedAttributedText = self.attributedText
        }
        wy_highlight = nil
        setNeedsDisplay()
    }

    /// 交换 UILabel 的 drawText(in:)，在文字绘制前先画按下高亮矩形(高亮画在文字下层；未命中高亮的 label 只多一次空判断)
    static let wy_swizzleDrawText: Void = {
        wy_swizzlerDrawText(for: UILabel.self, before: { currentLabel, _ in
            guard let highlight = currentLabel.wy_highlight else { return }
            highlight.color.setFill()
            for highlightRect in highlight.rects {
                UIRectFill(highlightRect)
            }
        })
    }()

    /// 注册触摸目标(点击与长按各自累加、同参数重复注册去重；解析全部注册的关键词重建模型并按行分组，注册即启用交互)
    private func wy_registerTouchTargets(rangeValue: Any, isLongPress: Bool, handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)?, delegate: WYRichTextTouchDelegate?) {

        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        // 防注册后收不到触摸:UILabel默认isUserInteractionEnabled为false，注册点击或长按都必须打开
        isUserInteractionEnabled = true
        // 激活 touches/layoutSubviews/drawText 三处方法交换(静态量保证全局只交换一次)
        wy_enableSwizzleMethods()

        // 防重复注册:同区间描述同回调方式的注册只保留一份(回调只区分有无，闭包每次调用都是新实例不能比内容)
        let registration = WYRichTextRegistration(rangeValue: rangeValue, handler: handler, delegate: delegate)
        let isTap = !isLongPress
        var registrations = isTap ? wy_tapRegistrations : wy_longPressRegistrations
        let exists = registrations.contains { existing in
            String(describing: existing.rangeValue) == String(describing: registration.rangeValue) &&
            (existing.handler != nil) == (registration.handler != nil) &&
            (existing.delegate != nil) == (registration.delegate != nil)
        }
        if !exists {
            registrations.append(registration)
            if isTap {
                wy_tapRegistrations = registrations
            } else {
                wy_longPressRegistrations = registrations
            }
        }

        // 按全部注册重建点击与长按模型(后注册不再覆盖先注册，与 UITextView 的累加语义一致)
        let nsString = attributed.string as NSString
        let parse = { (registered: WYRichTextRegistration) -> [WYRichTextModel] in
            attributed.string.wy_parseRanges(from: registered.rangeValue).enumerated().map { index, range in
                WYRichTextModel(wy_richText: nsString.substring(with: range), wy_range: range, registrationIndex: index, handler: registered.handler, delegate: registered.delegate)
            }
        }
        let tapModels = wy_tapRegistrations.flatMap(parse)
        let longPressModels = wy_longPressRegistrations.flatMap(parse)
        wy_attributeStrings = tapModels
        wy_longPressAttributeStrings = longPressModels

        // 排版缓存仍新鲜时跳过重排版(连续多次注册文本与尺寸未变，避免每次注册都全文排版一次)
        if wy_cachedAttributedText !== attributed || wy_cachedBounds != bounds {
            wy_refreshFrameCache(attributedText: attributed)
        }
        wy_lineRanges = wy_groupModelsByLine(for: tapModels)
        wy_longPressLineRanges = wy_groupModelsByLine(for: longPressModels)
    }

    /**
     * 将给定的富文本模型按行分组，便于在命中时只检查当前行（性能优化）
     *
     * - Parameter models: 需要分组的富文本模型数组
     * - Returns: 按行索引组织的二维数组
     */
    private func wy_groupModelsByLine(for models: [WYRichTextModel]) -> [[WYRichTextModel]] {
        guard let lineCharacterRanges = wy_lineCharacterRanges, !lineCharacterRanges.isEmpty else { return [] }
        var groups = [[WYRichTextModel]](repeating: [], count: lineCharacterRanges.count)
        for model in models {
            let modelRange = model.wy_range
            for (i, lineRange) in lineCharacterRanges.enumerated() {
                let intersection = NSIntersectionRange(modelRange, lineRange)
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

    /// 开表：按下命中最小时长后到点就地触发长按回调的定时器(不等松手，与 UILongPressGestureRecognizer 行为一致)
    private func wy_scheduleLongPressTimer() {

        guard wy_longPressTimer == nil else { return }

        // .common 模式保证 label 处于滑动列表中时定时器不被滑动事件推迟
        let timer = Timer(timeInterval: max(0, wy_longPressMinimumDuration), repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.wy_longPressTimer = nil
            // 松手/移出/超距取消时模型已被清空，这里二次校验防止边界状态下误触发
            guard self.wy_longPressTriggered == false,
                  let longPressModel = self.wy_currentLongPressModel else { return }

            self.wy_longPressTriggered = true
            // 双注册词此时从点击效果色切换为长按效果色(纯长按词颜色不变)，色变本身就是"已识别为长按"的反馈，与 UITextView 行为一致
            self.wy_applyHighlight(range: longPressModel.wy_range, isLongPress: true)
            // 同一点重叠注册的长按模型全部回调(各自携带所属注册的回调)，与 UITextView 的全部触发语义一致
            let longMatches = self.wy_allMatchedModels(at: self.wy_touchBeginPoint ?? .zero, models: self.wy_longPressAttributeStrings, lineGroups: self.wy_longPressLineRanges)
            for model in longMatches {
                model.handler?(self, model.wy_richText, model.wy_range, model.registrationIndex)
                model.delegate?.wy_richTextDidLongPress?(self, text: model.wy_richText, range: model.wy_range, index: model.registrationIndex)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        wy_longPressTimer = timer
    }

    /// 停表：取消尚未到时长的长按定时器(重复调用安全)
    private func wy_invalidateLongPressTimer() {
        wy_longPressTimer?.invalidate()
        wy_longPressTimer = nil
    }

    /// 重置触摸状态（清空当前触摸模型、开始坐标、开始时间）
    private func wy_resetTouchState() {
        wy_currentTouchModel = nil
        wy_touchStartTapModels = []
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

    /// 清除所有缓存数据（排版引擎、行信息及按下高亮）
    private func wy_clearCache() {
        wy_layoutEngine = nil
        wy_lineRects = nil
        wy_lineCharacterRanges = nil
        wy_verticalOffset = 0
        wy_cachedAttributedText = nil
        wy_cachedBounds = .zero
        // 高亮直接丢弃且不回写还原(此时文本已被外部清空，还原会覆盖外部操作)
        wy_highlight = nil
    }

    /// 当前触摸命中的点击富文本模型
    private var wy_currentTouchModel: WYRichTextModel? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentTouchModel) as? WYRichTextModel }
    }

    /// 触摸开始时命中的全部点击富文本模型（用于松手时全部回调）
    private var wy_touchStartTapModels: [WYRichTextModel] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchStartTapModels, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchStartTapModels) as? [WYRichTextModel] ?? [] }
    }

    /// 当前触摸命中的长按富文本模型（用于长按效果色）
    private var wy_currentLongPressModel: WYRichTextModel? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_currentLongPressModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_currentLongPressModel) as? WYRichTextModel }
    }

    /// 当前按下高亮的绘制信息(nil 表示无高亮)
    private var wy_highlight: WYLabelHighlight? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlight, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlight) as? WYLabelHighlight }
    }

    /// 触摸开始时的坐标点
    private var wy_touchBeginPoint: CGPoint? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginPoint) as? CGPoint }
    }

    /// 触摸允许的最大移动距离(pt)，超出视为取消本次点击或长按，默认 15(防按下后拖动松手误触；UITextView 侧对应 wy_longPressAllowableMovement 同为私有且默认值统一为 15)
    private var wy_maxTouchMoveDistance: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_maxTouchMoveDistance) as? CGFloat ?? 15.0 }
    }

    /// 触摸开始时的系统时间戳
    private var wy_touchBeginTime: TimeInterval? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchBeginTime) as? TimeInterval }
    }

    /// 点击注册列表(多次注册累加，各自保留回调)
    private var wy_tapRegistrations: [WYRichTextRegistration] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations) as? [WYRichTextRegistration] ?? [] }
    }

    /// 长按注册列表(多次注册累加，各自保留回调)
    private var wy_longPressRegistrations: [WYRichTextRegistration] {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations) as? [WYRichTextRegistration] ?? [] }
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

    /// TextKit 排版引擎缓存（iOS 15+内部是TextKit2，旧系统是TextKit1；命中检测时用它反查触摸点对应的字符下标）
    private var wy_layoutEngine: WYTextLayoutEngine? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_layoutEngine, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_layoutEngine) as? WYTextLayoutEngine }
    }

    /// 每行在 TextKit 布局坐标系中的矩形缓存（紧凑宽度，y 从文本内容顶部向下，与 wy_lineCharacterRanges 下标一一对应）
    private var wy_lineRects: [CGRect]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineRects, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineRects) as? [CGRect] }
    }

    /// 每行的字符范围缓存（用于富文本模型按行分组）
    private var wy_lineCharacterRanges: [NSRange]? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lineCharacterRanges, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lineCharacterRanges) as? [NSRange] }
    }

    /// 文本块整体垂直居中偏移（UILabel 内容垂直居中，命中检测前用它把触摸点换算回布局坐标）
    private var wy_verticalOffset: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_verticalOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_verticalOffset) as? CGFloat ?? 0 }
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

    /// 长按触发定时器(按下时开表，到 wy_longPressMinimumDuration 就地触发回调)
    private var wy_longPressTimer: Timer? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer) as? Timer }
    }

    /// 长按是否已触发（防止重复回调）
    private var wy_longPressTriggered: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered) as? Bool ?? false }
    }

    private struct WYAssociatedKeys {
        static var wy_isClickAction: UInt8 = 0
        static var wy_clickEffectColor: UInt8 = 0
        static var wy_longPressEffectColor: UInt8 = 0
        static var wy_overlaysOriginalBackground: UInt8 = 0
        static var wy_attributeStrings: UInt8 = 0
        static var wy_longPressAttributeStrings: UInt8 = 0
        static var wy_tapRegistrations: UInt8 = 0
        static var wy_longPressRegistrations: UInt8 = 0
        static var wy_currentTouchModel: UInt8 = 0
        static var wy_touchStartTapModels: UInt8 = 0
        static var wy_currentLongPressModel: UInt8 = 0
        static var wy_highlight: UInt8 = 0
        static var wy_needTouchUpInside: UInt8 = 0
        static var wy_touchBeginPoint: UInt8 = 0
        static var wy_touchBeginTime: UInt8 = 0
        static var wy_maxTouchMoveDistance: UInt8 = 0
        static var wy_layoutEngine: UInt8 = 0
        static var wy_lineRects: UInt8 = 0
        static var wy_lineCharacterRanges: UInt8 = 0
        static var wy_verticalOffset: UInt8 = 0
        static var wy_cachedAttributedText: UInt8 = 0
        static var wy_cachedBounds: UInt8 = 0
        static var wy_lineRanges: UInt8 = 0
        static var wy_longPressLineRanges: UInt8 = 0
        static var wy_longPressMinimumDuration: UInt8 = 0
        static var wy_longPressTriggered: UInt8 = 0
        static var wy_longPressTimer: UInt8 = 0
    }
}

/// 内部富文本模型(一次注册解析出的单个可交互词，保留所属注册的回调)
private final class WYRichTextModel {

    /// 要匹配的字符串内容
    let wy_richText: String
    /// 在完整文本中的位置
    let wy_range: NSRange
    /// 在所属注册解析出的全部范围中的索引
    let registrationIndex: Int
    /// 所属注册的闭包回调
    let handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)?
    /// 所属注册的代理回调
    weak var delegate: WYRichTextTouchDelegate?

    init(wy_richText: String,
         wy_range: NSRange,
         registrationIndex: Int,
         handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil,
         delegate: WYRichTextTouchDelegate? = nil) {
        self.wy_richText = wy_richText
        self.wy_range = wy_range
        self.registrationIndex = registrationIndex
        self.handler = handler
        self.delegate = delegate
    }
}

/// 用户通过公开API注册的原始请求(点击或长按，未解析为具体范围，保留各自回调)
private class WYRichTextRegistration {

    /// 用户传入的原始区间描述（支持字符串、NSRange、数组等）
    let rangeValue: Any
    /// 闭包回调
    let handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)?
    /// 代理回调
    weak var delegate: WYRichTextTouchDelegate?

    init(rangeValue: Any,
         handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil,
         delegate: WYRichTextTouchDelegate? = nil) {
        self.rangeValue = rangeValue
        self.handler = handler
        self.delegate = delegate
    }
}

/// 按下高亮的绘制信息
private class WYLabelHighlight {

    /// 词语各分行的矩形(已含垂直居中偏移，label 坐标系)
    let rects: [CGRect]
    /// 高亮颜色
    let color: UIColor
    /// 覆盖模式剥离原背景色时暂存的原富文本(清除高亮时整体回写还原，nil 表示未改动过原文本)
    let originalText: NSAttributedString?

    init(rects: [CGRect], color: UIColor, originalText: NSAttributedString?) {
        self.rects = rects
        self.color = color
        self.originalText = originalText
    }
}

/**
 *  基于 TextKit 的文本排版引擎，一次排版后对外提供每行矩形、每行字符范围、文本块整体高度、坐标反查字符下标与任意子范围的分行矩形
 *
 *  iOS 15 及以上内部走 TextKit2(NSTextLayoutManager)，旧系统自动降级为 TextKit1(NSLayoutManager)；
 *  两条路径都与 UILabel 渲染同源，系统字体与第三方自定义字体的行高、基线、换行位置均与实际显示一致。
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

        if #available(iOS 15.0, *) {
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
        } else {
            let layout = Self.wy_layoutTextKit1(attributedText: attributedText, containerSize: containerSize, numberOfLines: numberOfLines, lineBreakMode: lineBreakMode)
            lineRects = layout.rects
            lineCharacterRanges = layout.ranges
            textBlockHeight = layout.blockHeight
            tk2Storage = nil
            tk1Layout = layout.layout
        }
    }

    /**
     *  反查指定坐标点落在哪个字符上
     *
     *  @param point 排版坐标系中的位置(y 从文本内容顶部向下，与 lineRects 同一坐标系)
     *  @return 字符在整个字符串中的下标，没有任何行(如空字符串)时返回 nil
     */
    func characterIndex(at point: CGPoint) -> Int? {

        guard !lineRects.isEmpty else { return nil }

        if #available(iOS 15.0, *) {
            guard let layout = tk2Storage as? WYTextKit2Layout else { return nil }
            return Self.wy_tk2CharacterIndex(at: point, lineRects: lineRects, layout: layout)
        } else {
            return tk1Layout.flatMap { Self.wy_tk1CharacterIndex(at: point, layout: $0) }
        }
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

        if #available(iOS 15.0, *) {
            guard let layout = tk2Storage as? WYTextKit2Layout else { return [] }
            let segments = Self.wy_tk2BoundingRects(for: clipped, layout: layout)
            guard layout.isLineCapped, let lastRect = lineRects.last, let lastLineRange = lineCharacterRanges.last else { return segments }
            // 行数受限截断:末行之上的可见行保留原始行片段矩形(矩形更紧凑)，末行可见内容按裁剪后的行范围构造
            // (截断头部/中间的末行显示的是全文末尾内容，其原始位置在被截掉的行上，不能用原始行片段反查；截断尾部的末行可见终点就是 totalLength，clipped 已自动裁到可见边界)
            var results = segments.filter { $0.rect.midY < lastRect.midY }
            let intersection = NSIntersectionRange(clipped, lastLineRange)
            if intersection.length > 0 {
                let nsString = (layout.contentStorage.attributedString?.string ?? "") as NSString
                results.append(WYTextBoundingRects(rect: lastRect, string: nsString.substring(with: intersection), range: intersection))
            }
            return results
        } else {
            return tk1Layout.map { Self.wy_tk1BoundingRects(for: clipped, layout: $0) } ?? []
        }
    }

    /// TextKit2 排版对象(以 Any 装箱存储，iOS 15 以下固定为 nil，使用处再解箱)
    private let tk2Storage: Any?

    /// TextKit1 排版对象(仅 iOS 15 以下有值)
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
    @available(iOS 15.0, *)
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
    @available(iOS 15.0, *)
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

    /// 推导排版容器高度上限
    /// 在传入高度上补 2pt 余量(UILabel 的内在高度与其内部排版的行高存在亚像素级取整出入，容器高度卡得太死会把最后一行整体裁掉，导致行矩形与实际显示错位、命中偏移)；
    /// 行数有限的截断场景由 wy_layoutTextKit2Capped 把高度精确钳到第 N 行底部，这里只负责不限行数的排版
    private static func wy_layoutHeightLimit(containerSize: CGSize, numberOfLines: Int) -> CGFloat {
        if numberOfLines > 0 {
            // 单行高度现实中远小于 1000pt，按行数加一行余量推导的有限上限足够容纳全部行
            return min(containerSize.height, CGFloat(numberOfLines + 1) * 1000)
        }
        return min(containerSize.height + 2, CGFloat.greatestFiniteMagnitude)
    }

    /// 不限行数时把富文本内各段落的换行模式归一到目标换行模式，返回原对象或可变副本
    /// 段落样式的换行模式默认值是 byTruncatingTail(设置过行间距、对齐等属性的富文本都会携带)，
    /// TextKit2 对段落截断模式加不限行数加充裕有限高度的组合会把全部文字并进第一行；截断由容器的 lineBreakMode 统一控制(与 UILabel 内部实现一致)，段落归一不影响显示语义；
    /// 段落与容器必须归一到同一换行模式(TextKit 排版段落样式优先于容器设置，只改容器不改段落会导致按字换行时引擎与 UILabel 实际显示逐行错位)；
    /// UILabel 不限行数时的实际换行(2026-09-21 用 Vision OCR 逐模式核对模拟器显示确认)只有 byCharWrapping 按字，截断类与 byClipping 都按词
    private static func wy_wordWrappedAttributed(_ attributedText: NSAttributedString, numberOfLines: Int, lineBreakMode: NSLineBreakMode) -> NSAttributedString {

        guard numberOfLines <= 0, attributedText.length > 0 else { return attributedText }

        // 不限行数时段落与容器统一到的换行模式(仅 byCharWrapping 按字换行，截断类与 byClipping 都按词换行——2026-09-21 用 Vision OCR 逐模式核对 UILabel 实际显示确认)
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

    /// TextKit2 排版的外层包装(仅处理 numberOfLines 大于 0 的场景)
    /// TextKit2 的容器截断(maximumNumberOfLines 加截断模式)在部分系统版本上会把全部文字并进第一行，
    /// 所以行数限制统一在引擎层实现，先不限行数排一次，文本未超限直接用该结果，超限则裁掉多余行并对末行按截断方式裁剪可见内容；
    /// 行数受限时 UILabel 的真实末行显示(2026-09-21 用 Vision OCR 核对模拟器显示确认)为截断尾部/直接裁剪保留末行开头(前者省略号在前者预留宽度、后者不预留)，
    /// 截断头部显示"…+全文末尾内容"，截断中间显示"末行开头…+全文末尾内容"，显示内容不按顺序
    @available(iOS 15.0, *)
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

        var rects = Array(unlimited.rects.prefix(numberOfLines))
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
                // 截断中间:末行显示"末行开头…+全文末尾内容"，末尾段按约一半预算量出占宽，开头段在剩余宽度内按断行建议连续填充
                // (行字符范围是单个连续区间，末行只能表达开头段，末尾段的全文末尾内容暂无法合进同一行范围)
                let tail = Self.wy_tailFittingSuffix(of: attributedText, availableWidth: (containerSize.width - ellipsisWidth) / 2)
                let prefixLength = Self.wy_typesetterVisibleLength(of: attributedText, from: lastRange.location, budget: containerSize.width - ellipsisWidth - tail.width)
                let visibleEnd = min(attributedText.length, lastRange.location + max(1, prefixLength))
                if visibleEnd > lastRange.location {
                    ranges[ranges.count - 1] = NSRange(location: lastRange.location, length: visibleEnd - lastRange.location)
                }
            case .byClipping:
                // 直接裁剪:从末行起点按全宽簇断行建议连续填充；行尾的 CJK 标点按系统标点悬挂/压缩规则补入(显示时压缩悬挂在行尾，簇断行建议按全宽计算未计入)
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

    /// TextKit2 排版(NSTextContentStorage + NSTextLayoutManager，iOS 15+)
    @available(iOS 15.0, *)
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

        // 探测 characterIndex(for:) 的索引基准(行左缘反查的原始值 0/行内起点/全下起点分别对应 行内/段落/全下 三种基准)
        // 选样按区分度排优先级(段落偏移和行内位置都大于0的行能三分；只有段落偏移大于0能区分全下基准；只有行内位置大于0能区分行内基准)，
        // 单段落或各段皆单行的文本各基准换算结果本就一致，取不到高优先级样本时按段落基准兜底
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

        // 截断裁剪：行数被 numberOfLines 封顶(截断行会把余下整段吞进自身范围)或文本被容器高度裁剪时，
        // 最后一行的 characterRange 会包含未显示的文本，用行右缘反查到的可见边界裁剪，防止隐藏文本被算进可见行导致点击误命中
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

    /// TextKit1 排版(NSTextStorage + NSLayoutManager，iOS 15 以下降级使用)
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
    @available(iOS 15.0, *)
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
    @available(iOS 15.0, *)
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
