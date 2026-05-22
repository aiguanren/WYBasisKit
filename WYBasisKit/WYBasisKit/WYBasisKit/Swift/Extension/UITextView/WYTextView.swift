//
//  UITextView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/16.
//

import UIKit

/// 文本交互事件的代理协议，可选择性实现点击或长按回调。
@objc public protocol WYTextViewTouchDelegate {
    
    /**
     * 文本点击回调
     *
     * @param textView    当前 UITextView 实例
     * @param text        被点击的字符串内容
     * @param range       被点击字符串在整个文本中的 NSRange
     * @param index       被点击字符串在传入 strings 数组中的索引
     */
    @objc(wy_textViewTextDidClick:clickText:range:index:)
    optional func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int)
    
    /**
     * 文本长按回调
     *
     * @param textView    当前 UITextView 实例
     * @param text        被长按的字符串内容
     * @param range       被长按字符串在整个文本中的 NSRange
     * @param index       被长按字符串在传入 strings 数组中的索引
     */
    @objc(wy_textViewTextDidLongPress:text:range:index:)
    optional func wy_textViewTextDidLongPress(_ textView: UITextView, text: String, range: NSRange, index: Int)
}

public extension UITextView {
    
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
     * - 若用户未主动设置，则自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    var wy_longPressEffectColor: UIColor? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var wy_longPressMinimumDuration: TimeInterval {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    /// 非链接区域的点击事件是否需要穿透UITextView，默认False(为False时点击指定字符串之外区域，事件按照UITextVeiw默认响应链响应，为True时，将跳过UITextVeiw，直接响应事件到UITextVeiw的父View)
    var wy_eventPenetration: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setNeedsLayout()
            // 确保 hitTest 方法交换已执行
            self.enableHitTestPenetrationIfNeeded()
            // 主动触发一次 hitTest 调用，使方法交换立即在系统中注册，保证第一次点击就能使用新逻辑
            if newValue {
                _ = self.hitTest(CGPoint(x: -100, y: -100), with: nil)
            }
        }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration) as? Bool ?? false }
    }
    
    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler     点击事件回调闭包
     *
     */
    func wy_addTextTapHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: handler, delegate: nil)
        addRegistration(registration)
        reloadTouchActions()
        configureForTouchEvents()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 长按事件回调闭包
     */
    func wy_addTextLongPressHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .longPress, handler: handler, delegate: nil)
        addRegistration(registration)
        reloadTouchActions()
        configureForTouchEvents()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 点击代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    func wy_addTextTapDelegate(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: nil, delegate: delegate)
        addRegistration(registration)
        reloadTouchActions()
        configureForTouchEvents()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 长按代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    func wy_addTextLongPressDelegate(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .longPress, handler: nil, delegate: delegate)
        addRegistration(registration)
        reloadTouchActions()
        configureForTouchEvents()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
}

/// 动作类型
private enum WYActionType {
    // 点击
    case tap
    // 长按
    case longPress
}

/// 单个文本交互动作（点击或长按）的内部模型，包含作用区间、类型、回调等信息。
private class WYTextTouchAction {
    
    /// 作用文本范围
    let range: NSRange
    /// 动作类型
    let type: WYActionType
    /// 在注册的多个区间中的索引
    let index: Int
    /// 闭包回调
    let handler: ((UITextView, String, NSRange, Int) -> Void)?
    /// 代理回调
    weak var delegate: WYTextViewTouchDelegate?
    
    init(range: NSRange,
         type: WYActionType,
         index: Int,
         handler: ((UITextView, String, NSRange, Int) -> Void)? = nil,
         delegate: WYTextViewTouchDelegate? = nil) {
        self.range = range
        self.type = type
        self.index = index
        self.handler = handler
        self.delegate = delegate
    }
}

/// 用户通过公开API注册的原始请求，尚未解析为具体的区间。
private class WYTextTouchRegistration {

    /// 用户传入的原始区间描述（支持字符串、NSRange、数组等）
    let rangeValue: Any
    /// 动作类型
    let type: WYActionType
    /// 闭包回调
    let handler: ((UITextView, String, NSRange, Int) -> Void)?
    /// 代理回调
    weak var delegate: WYTextViewTouchDelegate?
    
    init(rangeValue: Any,
         type: WYActionType,
         handler: ((UITextView, String, NSRange, Int) -> Void)? = nil,
         delegate: WYTextViewTouchDelegate? = nil) {
        self.rangeValue = rangeValue
        self.type = type
        self.handler = handler
        self.delegate = delegate
    }
}

private extension UITextView {
    
    /// 用于关联对象（Associated Object）的静态键值结构
    struct WYAssociatedKeys {
        /// 点击效果颜色关联键
        static var wy_clickEffectColor: UInt8 = 0
        /// 长按效果颜色关联键
        static var wy_longPressEffectColor: UInt8 = 0
        /// 长按最小持续时间关联键
        static var wy_longPressMinimumDuration: UInt8 = 0
        /// 长按允许移动距离关联键
        static var wy_longPressAllowableMovement: UInt8 = 0
        /// 是否启用链接点击关联键
        static var wy_enableLinkHitTest: UInt8 = 0
        /// 链接点击回调关联键
        static var wy_linkTapHandler: UInt8 = 0
        /// 所有点击动作列表关联键
        static var wy_tapActions: UInt8 = 0
        /// 所有长按动作列表关联键
        static var wy_longPressActions: UInt8 = 0
        /// 点击原始注册信息列表关联键
        static var wy_tapRegistrations: UInt8 = 0
        /// 长按原始注册信息列表关联键
        static var wy_longPressRegistrations: UInt8 = 0
        /// 文本内容观察者关联键
        static var wy_textObserver: UInt8 = 0
        /// 是否已交换hitTest方法关联键
        static var wy_hasSwizzledHitTest: UInt8 = 0
        /// 事件穿透开关关联键
        static var wy_eventPenetration: UInt8 = 0
        /// 当前高亮的文本区间关联键
        static var wy_highlightedRange: UInt8 = 0
        /// 触摸开始时记录的点
        static var wy_touchStartPoint: UInt8 = 0
        /// 触摸开始时匹配到的所有点击动作（数组）
        static var wy_touchStartTapActions: UInt8 = 0
        /// 长按计时器
        static var wy_longPressTimer: UInt8 = 0
        /// 长按是否已触发
        static var wy_longPressTriggered: UInt8 = 0
        /// 触摸开始时匹配到的长按动作（用于计时器）
        static var wy_touchStartLongAction: UInt8 = 0
    }
    
    /// 是否启用对链接（.link）的点击响应。若开启，则点击链接时会调用 `wy_linkTapHandler`。
    var wy_enableLinkHitTest: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest) as? Bool ?? false }
    }
    
    /// 长按时允许手指移动的最大距离（点），超过则取消长按识别，默认10像素
    var wy_longPressAllowableMovement: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressAllowableMovement, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressAllowableMovement) as? CGFloat ?? 10 }
    }
    
    /// 链接点击时的回调闭包，接收被点击的 URL。
    var wy_linkTapHandler: ((URL) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler) as? (URL) -> Void }
    }
    
    /// 当前所有已解析的点击动作列表。
    var wy_tapActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前所有已解析的长按动作列表。
    var wy_longPressActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 未解析的点击原始注册列表。
    var wy_tapRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 未解析的长按原始注册列表。
    var wy_longPressRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前正在高亮显示的文本区间，用于按下时背景色。
    var wy_highlightedRange: NSRange? {
        get { (objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange) as? NSValue)?.rangeValue }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange, newValue.map { NSValue(range: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 触摸开始时的点（用于移动距离判断）
    var wy_touchStartPoint: CGPoint {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchStartPoint) as? CGPoint ?? .zero }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchStartPoint, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 触摸开始时匹配到的所有点击动作（用于点击回调）
    var wy_touchStartTapActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchStartTapActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchStartTapActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 长按计时器
    var wy_longPressTimer: DispatchWorkItem? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer) as? DispatchWorkItem }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 长按是否已触发
    var wy_longPressTriggered: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 触摸开始时匹配到的长按动作（用于计时器触发）
    var wy_touchStartLongAction: WYTextTouchAction? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_touchStartLongAction) as? WYTextTouchAction }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_touchStartLongAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// KVO 观察者类，用于监听 text / attributedText 变化。
    class WYTextObserver: NSObject {
        weak var textView: UITextView?
        init(textView: UITextView) {
            self.textView = textView
            super.init()
        }
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let textView = textView else { return }
            if keyPath == "text" || keyPath == "attributedText" {
                textView.reloadTouchActions()
            }
        }
    }
    
    var wy_textObserver: WYTextObserver? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_textObserver) as? WYTextObserver }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_textObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 为触摸事件配置 TextView：禁用编辑和选择，避免系统干扰
    func configureForTouchEvents() {
        if isSelectable {
            isSelectable = false
        }
        if isEditable {
            isEditable = false
        }
        // 禁用视图延迟触摸，使 touchesBegan 能够立即触发，避免系统手势门禁导致的延迟
        self.delaysContentTouches = false
    }
    
    /// 将注册信息添加到对应的注册列表（点击/长按），避免重复添加。
    func addRegistration(_ registration: WYTextTouchRegistration) {
        let isTap = registration.type == .tap
        var registrations = isTap ? wy_tapRegistrations : wy_longPressRegistrations
        
        let exists = registrations.contains { existing in
            existing.type == registration.type &&
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
    }
    
    /// 根据当前文本内容和原始注册列表，重新生成具体的动作列表（wy_tapActions / wy_longPressActions）。
    func reloadTouchActions() {
        let currentText = (self.attributedText?.string ?? self.text) ?? ""
        guard !currentText.isEmpty else {
            wy_tapActions = []
            wy_longPressActions = []
            return
        }
        
        var newTapActions: [WYTextTouchAction] = []
        for reg in wy_tapRegistrations {
            let ranges = currentText.wy_parseRanges(from: reg.rangeValue)
            for (idx, range) in ranges.enumerated() {
                let action = WYTextTouchAction(range: range, type: .tap, index: idx, handler: reg.handler, delegate: reg.delegate)
                newTapActions.append(action)
            }
        }
        wy_tapActions = newTapActions
        
        var newLongPressActions: [WYTextTouchAction] = []
        for reg in wy_longPressRegistrations {
            let ranges = currentText.wy_parseRanges(from: reg.rangeValue)
            for (idx, range) in ranges.enumerated() {
                let action = WYTextTouchAction(range: range, type: .longPress, index: idx, handler: reg.handler, delegate: reg.delegate)
                newLongPressActions.append(action)
            }
        }
        wy_longPressActions = newLongPressActions
    }
    
    /// 开始 KVO 监听 text 和 attributedText 的变化，以便文本更新时重新解析区间。
    func startObservingTextChanges() {
        guard wy_textObserver == nil else { return }
        let observer = WYTextObserver(textView: self)
        self.addObserver(observer, forKeyPath: "text", options: [], context: nil)
        self.addObserver(observer, forKeyPath: "attributedText", options: [], context: nil)
        wy_textObserver = observer
    }
    
    /// 如果尚未交换 hitTest 方法，则进行交换，以便实现事件穿透功能。
    func enableHitTestPenetrationIfNeeded() {
        _ = Self.wy_swizzleTouchMethods
        if objc_getAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            swizzleHitTestMethod()
        }
    }
    
    /// 交换 hitTest 方法，注入穿透判断逻辑。
    func swizzleHitTestMethod() {
        wy_exchangeHitTest(for: UITextView.self, after: { view, point, event, originalResult in
            if let textView = view as? UITextView, textView.shouldPenetrateHitTest(at: point) {
                return nil
            }
            return originalResult
        })
    }
    
    /// 清理当前高亮区间（若有）。
    func clearHighlightIfNeeded() {
        if let range = wy_highlightedRange {
            removeHighlight(for: range)
            wy_highlightedRange = nil
        }
    }
    
    /// 获取给定屏幕点所匹配的所有动作（点击或长按）。
    func allActionsForPoint(_ point: CGPoint, actions: [WYTextTouchAction]) -> [WYTextTouchAction] {
        guard let characterIndex = characterIndexAtPoint(point) else { return [] }
        return actions.filter { NSLocationInRange(characterIndex, $0.range) }
    }
    
    /// 根据触摸点计算对应的字符索引（基于布局管理器和文本容器）。
    func characterIndexAtPoint(_ point: CGPoint) -> Int? {
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        let textContainerInsets = self.textContainerInset
        let locationInTextView = CGPoint(x: point.x - textContainerInsets.left,
                                         y: point.y - textContainerInsets.top)
        
        let characterIndex = layoutManager.characterIndex(for: locationInTextView,
                                                          in: textContainer,
                                                          fractionOfDistanceBetweenInsertionPoints: nil)
        
        let totalLength = attributedText?.length ?? 0
        if characterIndex < totalLength && characterIndex >= 0 {
            return characterIndex
        }
        return nil
    }
    
    /// 获取给定屏幕点所在位置的 URL 链接（如果有 .link 属性）。
    func linkURLAtPoint(_ point: CGPoint) -> URL? {
        guard let characterIndex = characterIndexAtPoint(point) else { return nil }
        let linkAttribute = attributedText?.attribute(.link, at: characterIndex, effectiveRange: nil)
        if let url = linkAttribute as? URL { return url }
        if let string = linkAttribute as? String, let url = URL(string: string) { return url }
        return nil
    }
    
    /// 为指定区间应用高亮效果（按下或长按时的背景色）。
    func applyHighlight(for range: NSRange, isLongPress: Bool) {
        let effectColor = isLongPress ? wy_longPressEffectColor : wy_clickEffectColor
        let finalColor: UIColor
        if let customColor = effectColor {
            finalColor = customColor
        } else {
            let textColor = attributedText?.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor ?? .black
            finalColor = textColor.withAlphaComponent(0.25)
        }
        
        textStorage.beginEditing()
        textStorage.addAttribute(.backgroundColor, value: finalColor, range: range)
        textStorage.endEditing()
    }
    
    /// 移除指定区间的高亮效果。
    func removeHighlight(for range: NSRange) {
        textStorage.beginEditing()
        textStorage.removeAttribute(.backgroundColor, range: range)
        textStorage.endEditing()
    }
    
    /// 判断当前触摸点是否应该让事件穿透（即忽略自身，传递给父视图）。
    func shouldPenetrateHitTest(at point: CGPoint) -> Bool {
        guard wy_eventPenetration else { return false }
        
        // 穿透前尝试清理高亮
        clearHighlightIfNeeded()
        
        let hasMatchingTap = !allActionsForPoint(point, actions: wy_tapActions).isEmpty
        let hasMatchingLongPress = !allActionsForPoint(point, actions: wy_longPressActions).isEmpty
        if hasMatchingTap || hasMatchingLongPress {
            return false
        }
        
        if wy_enableLinkHitTest, linkURLAtPoint(point) != nil {
            return false
        }
        
        return true
    }
    
    // 长按计时器管理
    func startLongPressTimer(for action: WYTextTouchAction, at point: CGPoint) {
        wy_longPressTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.wy_longPressTriggered else { return }
            self.wy_longPressTriggered = true
            // 长按时应用长按高亮（可不同颜色），并清除之前的点击高亮
            self.clearHighlightIfNeeded()
            self.applyHighlight(for: action.range, isLongPress: true)
            self.wy_highlightedRange = action.range
            // 执行长按回调（可能多个动作，但通常只有一个，因为长按通常不会重复注册同一区间，但为了安全，遍历所有匹配的长按动作）
            let point = self.wy_touchStartPoint
            let longActions = self.allActionsForPoint(point, actions: self.wy_longPressActions)
            for longAction in longActions {
                let text = (self.attributedText?.string as? NSString ?? self.text as NSString?)?.substring(with: longAction.range) ?? ""
                if let handler = longAction.handler {
                    handler(self, text, longAction.range, longAction.index)
                }
                if let delegate = longAction.delegate {
                    delegate.wy_textViewTextDidLongPress?(self, text: text, range: longAction.range, index: longAction.index)
                }
            }
        }
        wy_longPressTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + wy_longPressMinimumDuration, execute: work)
    }
    
    /// 交换触摸方法（touchesBegan/Moved/Ended/Cancelled）
    static let wy_swizzleTouchMethods: Void = {
        // 交换 touchesBegan：记录起点，应用高亮，启动长按计时器
        wy_exchangeTouchesBegan(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView,
                  let touch = touches.first else { return }
            let point = touch.location(in: textView)
            textView.wy_touchStartPoint = point
            
            // 查找点击动作（可能多个）
            let tapActions = textView.allActionsForPoint(point, actions: textView.wy_tapActions)
            textView.wy_touchStartTapActions = tapActions
            if !tapActions.isEmpty {
                // 应用点击高亮（取第一个动作的区间，多个动作区间可能不同？通常它们应该指向同一区间，这里取第一个）
                if let firstTap = tapActions.first {
                    textView.applyHighlight(for: firstTap.range, isLongPress: false)
                    textView.wy_highlightedRange = firstTap.range
                }
            } else {
                // 如果没有点击动作，但有长按动作，则为了即时高亮，应用点击高亮（使用长按动作的区间）
                let longActions = textView.allActionsForPoint(point, actions: textView.wy_longPressActions)
                if let firstLong = longActions.first {
                    textView.applyHighlight(for: firstLong.range, isLongPress: false)
                    textView.wy_highlightedRange = firstLong.range
                }
            }
            
            // 查找长按动作，启动长按计时器（取第一个）
            let longActions = textView.allActionsForPoint(point, actions: textView.wy_longPressActions)
            if let longAction = longActions.first {
                textView.wy_touchStartLongAction = longAction
                textView.startLongPressTimer(for: longAction, at: point)
            }
        })
        
        // 交换 touchesMoved：检测移动是否超出允许范围，若超出则取消长按并清除高亮
        wy_exchangeTouchesMoved(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView,
                  let touch = touches.first else { return }
            let point = touch.location(in: textView)
            let startPoint = textView.wy_touchStartPoint
            let dx = point.x - startPoint.x
            let dy = point.y - startPoint.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance > textView.wy_longPressAllowableMovement {
                // 移动超出允许范围，取消长按并清除高亮
                textView.wy_longPressTimer?.cancel()
                textView.wy_longPressTimer = nil
                textView.clearHighlightIfNeeded()
                textView.wy_touchStartTapActions = []
                textView.wy_touchStartLongAction = nil
            }
        })
        
        // 交换 touchesEnded：取消计时器，若长按未触发则执行点击回调，最后清除高亮
        wy_exchangeTouchesEnded(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            // 取消长按计时器
            textView.wy_longPressTimer?.cancel()
            textView.wy_longPressTimer = nil
            
            let triggered = textView.wy_longPressTriggered
            textView.wy_longPressTriggered = false
            
            if !triggered {
                let tapActions = textView.wy_touchStartTapActions
                if !tapActions.isEmpty {
                    for tapAction in tapActions {
                        let text = (textView.attributedText?.string as? NSString ?? textView.text as NSString?)?.substring(with: tapAction.range) ?? ""
                        if let handler = tapAction.handler {
                            handler(textView, text, tapAction.range, tapAction.index)
                        }
                        if let delegate = tapAction.delegate {
                            delegate.wy_textViewTextDidClick?(textView, text: text, range: tapAction.range, index: tapAction.index)
                        }
                    }
                }
            }
            
            // 清除高亮
            textView.clearHighlightIfNeeded()
            textView.wy_touchStartTapActions = []
            textView.wy_touchStartLongAction = nil
        })
        
        // 交换 touchesCancelled：取消计时器，清除高亮
        wy_exchangeTouchesCancelled(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            textView.wy_longPressTimer?.cancel()
            textView.wy_longPressTimer = nil
            textView.wy_longPressTriggered = false
            textView.clearHighlightIfNeeded()
            textView.wy_touchStartTapActions = []
            textView.wy_touchStartLongAction = nil
        })
    }()
}
