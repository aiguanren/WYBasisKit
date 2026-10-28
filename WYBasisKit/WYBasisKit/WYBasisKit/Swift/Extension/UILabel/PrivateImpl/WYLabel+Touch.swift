//
//  WYLabel+Touch.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import UIKit
import CoreText
import Foundation

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
        // 按下期间文本被外部替换时高亮矩形与剥离备份均已过期，直接丢弃且不回写还原(还原会覆盖外部新文本)，仅尺寸变化时正常还原清除
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

    /// 按下时记录起点并做命中检测，命中点击词应用点击高亮，命中长按词开计时器(纯长按词立即显示长按色)
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

        // 长按检测，按下时立即检测是否命中长按专用字符串，命中则开计时器
        if !wy_longPressAttributeStrings.isEmpty {
            let longMatches = wy_allMatchedModels(at: point, models: wy_longPressAttributeStrings, lineGroups: wy_longPressLineRanges)
            if let firstLongMatch = longMatches.first {
                // 记录当前命中的长按模型
                wy_currentLongPressModel = firstLongMatch
                // 只注册了长按的词不存在点击歧义，按下即显示长按效果色，双注册词保持已应用的点击效果色
                if wy_currentTouchModel == nil {
                    wy_applyHighlight(range: firstLongMatch.wy_range, isLongPress: true)
                }
                // 命中长按目标即开计时器，到最小时长就地触发回调(不等松手)
                wy_scheduleLongPressTimer()
            }
        }
    }

    /// 松手时停长按计时器，未触发的按按钮模式规则回调点击，最后清除按下高亮
    private func wy_handleTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }

        // 松手即停计时器(到时长的长按已在定时器触发时就地回调，提前松手则取消不触发)
        wy_invalidateLongPressTimer()

        // 按钮模式直接用 touchesBegan 中记录的结果，长按已触发的本次触摸不再响应点击(防止长按松手后又触发点击回调)
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

    /// 触摸被系统取消时停计时器并清理按下状态与高亮
    private func wy_handleTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard ((wy_isClickAction == true) && (attributedText != nil)) else { return }
        // 触摸被系统取消(来电、手势竞争等)时停计时器，长按不再触发
        wy_invalidateLongPressTimer()
        if wy_touchUpInside == true {
            wy_resetTouchState()
        }
        // 清除按下高亮(若有)
        wy_clearHighlight()
        wy_currentLongPressModel = nil
    }

    /// 移动时按距离与所在词区域做取消判定，移出清高亮停计时器，移回重新应用效果色
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

        // 长按的移动检测，手指移动距离超出阈值或移出当前长按目标区域时清除高亮并停计时器
        if let longPressModel = wy_currentLongPressModel, let touch = touches.first {
            let currentPoint = touch.location(in: self)
            let moveDistance = wy_calculateDistance(from: wy_touchBeginPoint, to: currentPoint)
            // 超出允许移动距离则取消长按效果并停计时器
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
     *   @param touchPoint 触摸点在当前 label 坐标系中的位置
     *   @param targetModels 要匹配的富文本模型数组（可选，不传则使用点击专用模型）
     *   @param targetLineGroups 对应按行分组的模型（可选，不传则使用点击专用分组）
     *   @param handler 命中后执行的回调，参数为命中的富文本模型(含字符串、range、索引与所属注册的回调)
     * @return 是否命中任何富文本
     *
     * - Note: 该方法正确处理了文本水平对齐（左/中/右）和垂直居中对齐。
     *         排版使用 TextKit，与 UILabel 渲染走同一套引擎
     *         自定义字体的行高、基线、换行位置也与实际显示一致，字符索引计算基于行实际矩形，点击区域严格等于字符区域。
     */
    @discardableResult
    private func wy_richTextFrame(touchPoint: CGPoint,
                                  targetModels: [WYRichTextModel]? = nil,
                                  targetLineGroups: [[WYRichTextModel]]? = nil,
                                  handler:((_ model: WYRichTextModel) -> Void)? = nil) -> Bool {
        guard let attributedText = attributedText else { return false }

        /**
         *  缓存过期(富文本对象或尺寸变化)时重新排版，行分组一并重建
         *  注册回调时label可能尚未布局完成(bounds为零)，只刷行矩形不重建分组时，会用旧分组把别的行的字符误当成这行的
         */
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

        // 命中检测，先定位行，再反查行内字符下标(内部走TextKit2)
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

        // 用TextKit排版(自定义字体上CoreText与UILabel渲染的行高/基线不一致会导致命中偏移，换成与UILabel同源的TextKit)
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

    /// 交换 UILabel 的 drawText(in:)，在文字绘制前先画按下高亮矩形(高亮画在文字下层，未命中高亮的 label 只多一次空判断)
    static let wy_swizzleDrawText: Void = {
        wy_swizzlerDrawText(for: UILabel.self, before: { currentLabel, _ in
            guard let highlight = currentLabel.wy_highlight else { return }
            highlight.color.setFill()
            for highlightRect in highlight.rects {
                UIRectFill(highlightRect)
            }
        })
    }()

    /// 注册触摸目标(点击与长按各自累加、同参数重复注册去重，解析全部注册的关键词重建模型并按行分组，注册即启用交互)
    func wy_registerTouchTargets(rangeValue: Any, isLongPress: Bool, handler: ((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)?, delegate: WYRichTextTouchDelegate?) {

        wy_isClickAction = attributedText != nil
        guard let attributed = attributedText else { return }
        // 注册点击或长按都必须打开isUserInteractionEnabled(UILabel默认为false，不打开则收不到触摸)
        isUserInteractionEnabled = true
        // 激活 touches/layoutSubviews/drawText 三处方法交换(静态量保证全局只交换一次)
        wy_enableSwizzleMethods()

        // 同区间描述同回调方式的注册只保留一份，防止重复注册(回调只区分有无，闭包每次调用都是新实例不能比内容)
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
     @param models 需要分组的富文本模型数组
     * @return 按行索引组织的二维数组
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

    /// 按下命中最小时长后到点就地触发长按回调的定时器(不等松手，与 UILongPressGestureRecognizer 行为一致)
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

    /// 取消尚未到时长的长按定时器(重复调用安全)
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

    /// 触摸允许的最大移动距离(pt)，超出视为取消本次点击或长按，默认 15(按下后拖动松手会误触，UITextView 侧对应 wy_longPressAllowableMovement 同为私有且默认值统一为 15)
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

    /// TextKit 排版引擎缓存（内部为TextKit2，命中检测时用它反查触摸点对应的字符下标）
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

    /// 长按触发定时器(按下时开计时器，到 wy_longPressMinimumDuration 就地触发回调)
    private var wy_longPressTimer: Timer? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer) as? Timer }
    }

    /// 长按是否已触发（防止重复回调）
    private var wy_longPressTriggered: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered) as? Bool ?? false }
    }

    struct WYAssociatedKeys {
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

