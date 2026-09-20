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
     * @param textView    当前 UITextView 实例
     * @param text        被点击的字符串内容
     * @param range       被点击字符串在整个文本中的 NSRange
     * @param index       被点击字符串在传入 strings 数组中的索引
     */
    @objc(wy_textViewTextDidClick:clickText:range:index:)
    optional func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int)
    
    /**
     * 文本长按回调
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
    
    /// 长按触发的最小时长（秒），默认(最小) 0.5 秒
    var wy_longPressMinimumDuration: TimeInterval {
        set {
            let minValue = 0.5
            let finalValue = max(minValue, newValue)
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, finalValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    /// 非链接区域的点击事件是否需要穿透UITextView，默认False(为False时点击指定字符串之外区域，事件按照UITextVeiw默认响应链响应，为True时，将跳过UITextVeiw，直接响应事件到UITextVeiw的父View)
    var wy_eventPenetration: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration) as? Bool ?? false }
    }
    
    /// 是否禁用 `UITextView` 的 `intrinsicContentSize`，在没有文本内容时，`intrinsicContentSize.height`仍然会返回一个默认的最小高度，禁用后，如果无文本显示，高度将变为0，更接近UILabel
    var wy_disableIntrinsicContentSize: Bool {
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_disableIntrinsicContentSize) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_disableIntrinsicContentSize, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            _ = UITextView.wy_swizzleIntrinsicSize
        }
    }
    
    /// 开启点击响应配置
    func wy_enableClickConfig() {
        // 关闭系统检测，手动控制样式
        dataDetectorTypes = UIDataDetectorTypes()
        // 去除左右边距
        textContainer.lineFragmentPadding = 0
        // 文本截断方式
        textContainer.lineBreakMode = .byTruncatingTail;
    }
    
    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 点击事件回调闭包
     *
     */
    func wy_addTextTapHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        Task { @MainActor in
            let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: handler, delegate: nil)
            addRegistration(registration)
            reloadTouchActions()
            configureForTouchEvents()
            startObservingTextChanges()
            enableSwizzleMethods()
        }
    }
    
    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 长按事件回调闭包
     */
    func wy_addTextLongPressHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        Task { @MainActor in
            let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .longPress, handler: handler, delegate: nil)
            addRegistration(registration)
            reloadTouchActions()
            configureForTouchEvents()
            startObservingTextChanges()
            enableSwizzleMethods()
        }
    }
    
    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 点击代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    func wy_addTextTapDelegate(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        Task { @MainActor in
            let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: nil, delegate: delegate)
            addRegistration(registration)
            reloadTouchActions()
            configureForTouchEvents()
            startObservingTextChanges()
            enableSwizzleMethods()
        }
    }
    
    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 长按代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    func wy_addTextLongPressDelegate(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        Task { @MainActor in
            let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .longPress, handler: nil, delegate: delegate)
            addRegistration(registration)
            reloadTouchActions()
            configureForTouchEvents()
            startObservingTextChanges()
            enableSwizzleMethods()
        }
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
    /// 缓存该 range 在 UITextView 中的矩形，用于快速命中检测
    var rects: [CGRect] = []
    
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

/// 按下高亮前备份的单段原背景色信息(用于手指移开后还原)
private class WYHighlightBackupItem {
    
    /// 该段在文本中的子区间
    let range: NSRange
    /// 该段原有背景色(整段无背景色则为 nil)
    let color: UIColor?
    
    init(range: NSRange, color: UIColor?) {
        self.range = range
        self.color = color
    }
}

private extension UITextView {
    
    /// 用于关联对象（Associated Object）的静态键值结构
    struct WYAssociatedKeys {
        /// 点击效果颜色关联键
        static var wy_clickEffectColor: UInt8 = 0
        /// 长按效果颜色关联键
        static var wy_longPressEffectColor: UInt8 = 0
        /// 自带背景色覆盖开关关联键
        static var wy_overlaysOriginalBackground: UInt8 = 0
        /// 长按最小持续时间关联键
        static var wy_longPressMinimumDuration: UInt8 = 0
        /// 长按允许移动距离关联键
        static var wy_longPressAllowableMovement: UInt8 = 0
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
        /// 事件穿透开关关联键
        static var wy_eventPenetration: UInt8 = 0
        /// 当前高亮的文本区间关联键
        static var wy_highlightedRange: UInt8 = 0
        /// 高亮覆盖的原背景色备份关联键
        static var wy_highlightBackup: UInt8 = 0
        /// 触摸开始时记录的点
        static var wy_touchStartPoint: UInt8 = 0
        /// 触摸开始时匹配到的所有点击动作（数组）
        static var wy_touchStartTapActions: UInt8 = 0
        /// 长按计时器
        static var wy_longPressTimer: UInt8 = 0
        /// 长按是否已触发
        static var wy_longPressTriggered: UInt8 = 0
        /// 是否禁用 `UITextView` 的 `intrinsicContentSize`
        static var wy_disableIntrinsicContentSize: UInt8 = 0
    }
    
    /// 长按时允许手指移动的最大距离（点），超过则取消长按识别，默认10像素
    var wy_longPressAllowableMovement: CGFloat {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressAllowableMovement, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressAllowableMovement) as? CGFloat ?? 10 }
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
    
    /// 当前高亮覆盖前的原背景色分段备份(整词同色时只有一段)，手指移开后按它还原。
    var wy_highlightBackup: [WYHighlightBackupItem]? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlightBackup) as? [WYHighlightBackupItem] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlightBackup, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
    
    /// KVO 观察者类，用于监听 text / attributedText 变化。
    class WYTextObserver: NSObject {
        weak var textView: UITextView?
        init(textView: UITextView) {
            self.textView = textView
            super.init()
        }
        
        deinit {
            // 移除 KVO 观察，避免崩溃
            if let textView = textView {
                textView.removeObserver(self, forKeyPath: "text")
                textView.removeObserver(self, forKeyPath: "attributedText")
            }
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
        // 不可编辑
        isEditable = false
        
        // 必须为 False 才能响应链接（保持 false 避免系统手势干扰，且不影响矩形获取）
        isSelectable = false
        
        // 禁用视图自身的延迟触摸（不影响父视图）
        self.delaysContentTouches = false
        
        Task { @MainActor in
            self.setNeedsLayout()
            // 确保方法交换已执行
            self.enableSwizzleMethods()
            // 主动触发一次 hitTest 调用，使方法交换立即在系统中注册，保证第一次点击就能使用
            _ = self.hitTest(CGPoint(x: -100, y: -100), with: nil)
        }
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
        
        // 重新计算所有 action 的矩形区域，用于快速命中检测
        Task { @MainActor in
            updateActionRects()
        }
    }
    
    /// 更新所有点击和长按动作的矩形缓存
    func updateActionRects() {
        for action in wy_tapActions {
            action.rects = rectsForRange(action.range)
        }
        for action in wy_longPressActions {
            action.rects = rectsForRange(action.range)
        }
    }
    
    /// 获取指定 NSRange 在 UITextView 中的所有矩形区域（支持跨行）
    func rectsForRange(_ range: NSRange) -> [CGRect] {
        guard let textRange = textRange(from: range) else { return [] }
        // selectionRects(for:) 返回的 rect 是相对于 UITextView 的坐标系统（已包含 textContainerInset）
        return self.selectionRects(for: textRange).map { $0.rect }
    }
    
    /// 将 NSRange 转换为 UITextRange
    func textRange(from nsRange: NSRange) -> UITextRange? {
        guard let start = position(from: beginningOfDocument, offset: nsRange.location),
              let end = position(from: start, offset: nsRange.length) else { return nil }
        return textRange(from: start, to: end)
    }
    
    /// 开始 KVO 监听 text 和 attributedText 的变化，以便文本更新时重新解析区间。
    func startObservingTextChanges() {
        guard wy_textObserver == nil else { return }
        let observer = WYTextObserver(textView: self)
        self.addObserver(observer, forKeyPath: "text", options: [], context: nil)
        self.addObserver(observer, forKeyPath: "attributedText", options: [], context: nil)
        wy_textObserver = observer
    }
    
    /// 方法交换决定是否禁用 `UITextView` 的 `intrinsicContentSize`
    static let wy_swizzleIntrinsicSize: Void = {
        
        wy_swizzlerIntrinsicContentSize(for: UITextView.self, after: { currentView, originalResult in
            
            guard let textView = currentView as? UITextView else { return originalResult}
            
            // 未开启开关 → 完全走系统逻辑
            guard textView.wy_disableIntrinsicContentSize else {
                return originalResult
            }
            
            // 获取系统原始 intrinsic
            var targetSize = originalResult
            
            // 判断是否真的有内容
            if (textView.attributedText.length <= 0) && (textView.text.count <= 0) {
                targetSize.height = 0
            }
            
            return targetSize
        })
    }()
    
    /// 如果尚未实现方法交换，则进行交换
    func enableSwizzleMethods() {
        _ = Self.wy_swizzleTouchMethods
        _ = Self.wy_swizzleHitTestMethod
    }
    
    /// 清理当前高亮区间（若有）。
    func clearHighlightIfNeeded() {
        if let range = wy_highlightedRange {
            removeHighlight(for: range)
            wy_highlightedRange = nil
        }
    }
    
    /// 获取给定屏幕点所匹配的所有动作（点击或长按）—— 基于矩形缓存
    func allActionsForPoint(_ point: CGPoint, actions: [WYTextTouchAction]) -> [WYTextTouchAction] {
        return actions.filter { action in
            action.rects.contains { $0.contains(point) }
        }
    }
    
    /// 为指定区间应用高亮效果（按下或长按时的背景色），并记录高亮区间与被覆盖的原背景色。
    func applyHighlight(for range: NSRange, isLongPress: Bool) {
        // 防状态残留:上一次高亮未清理时先还原，保证接下来备份到的是文本原背景色而不是上次的效果色
        clearHighlightIfNeeded()
        
        // 防越界崩溃:动作区间来自缓存，文本被整体替换后可能越界，addAttribute 越界会直接崩溃
        guard range.location + range.length <= textStorage.length else { return }
        
        // wy_overlaysOriginalBackground 为 false 时，自带背景色的文本不高亮(原背景色保持不动)
        if wy_overlaysOriginalBackground == false,
           textStorage.attribute(.backgroundColor, at: range.location, effectiveRange: nil) != nil {
            return
        }
        
        let finalColor: UIColor
        if isLongPress, let longPressColor = wy_longPressEffectColor {
            // 长按高亮优先用长按效果色
            finalColor = longPressColor
        } else if let customColor = wy_clickEffectColor {
            // 长按未单独设置时回退点击效果色（保持旧版只设点击色时点按/长按同色的行为）
            finalColor = customColor
        } else {
            let textColor = attributedText?.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor ?? .black
            finalColor = textColor.withAlphaComponent(0.25)
        }
        
        // 覆盖前按分段备份原背景色(只枚举命中词那一段，不拷贝整个富文本)，手指移开后按备份还原
        var backupItems: [WYHighlightBackupItem] = []
        textStorage.enumerateAttribute(.backgroundColor, in: range) { value, subRange, _ in
            backupItems.append(WYHighlightBackupItem(range: subRange, color: value as? UIColor))
        }
        wy_highlightBackup = backupItems
        
        textStorage.beginEditing()
        textStorage.addAttribute(.backgroundColor, value: finalColor, range: range)
        textStorage.endEditing()
        
        wy_highlightedRange = range
    }
    
    /// 移除指定区间的高亮效果，并按备份还原高亮前的原背景色。
    func removeHighlight(for range: NSRange) {
        // 防越界还原:手指按下期间文本被替换后原区间可能失效，此时放弃还原(全新文本没有旧背景可还原)
        guard range.location + range.length <= textStorage.length else {
            wy_highlightBackup = nil
            return
        }
        
        textStorage.beginEditing()
        if let backupItems = wy_highlightBackup, !backupItems.isEmpty {
            // 按备份分段还原(有色段还原原背景色，无色段只移除效果色)
            for item in backupItems {
                if let color = item.color {
                    textStorage.addAttribute(.backgroundColor, value: color, range: item.range)
                } else {
                    textStorage.removeAttribute(.backgroundColor, range: item.range)
                }
            }
        } else {
            // 原文本无背景色，直接移除效果色
            textStorage.removeAttribute(.backgroundColor, range: range)
        }
        textStorage.endEditing()
        
        wy_highlightBackup = nil
    }
    
    /// 判断当前触摸点是否应该让事件穿透（即忽略自身，传递给父视图）。
    func shouldPenetrateHitTest(at point: CGPoint) -> Bool {
        
        // 穿透前尝试清理高亮
        clearHighlightIfNeeded()
        
        let hasMatchingTap = !allActionsForPoint(point, actions: wy_tapActions).isEmpty
        let hasMatchingLongPress = !allActionsForPoint(point, actions: wy_longPressActions).isEmpty
        if hasMatchingTap || hasMatchingLongPress {
            return false
        }
        
        return wy_eventPenetration
    }
    
    /// 长按计时器管理
    func startLongPressTimer(for action: WYTextTouchAction, at point: CGPoint) {
        wy_longPressTimer?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, !self.wy_longPressTriggered else { return }
            self.wy_longPressTriggered = true
            // 长按时应用高亮
            self.applyHighlight(for: action.range, isLongPress: true)
            // 执行长按回调
            let point = self.wy_touchStartPoint
            let longActions = self.allActionsForPoint(point, actions: self.wy_longPressActions)
            for longAction in longActions {
                let text = (self.attributedText?.string as? NSString ?? self.text as NSString?)?.substring(with: longAction.range) ?? ""
                
                // 长按Block回调
                if let handler = longAction.handler {
                    handler(self, text, longAction.range, longAction.index)
                }
                // 长按Delegate回调
                if let delegate = longAction.delegate {
                    delegate.wy_textViewTextDidLongPress?(self, text: text, range: longAction.range, index: longAction.index)
                }
            }
        }
        wy_longPressTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + wy_longPressMinimumDuration, execute: work)
    }
    
    /// 交换 hitTest 方法，注入穿透判断逻辑
    static let wy_swizzleHitTestMethod: Void = {
        wy_swizzlerHitTest(for: UITextView.self, after: { view, point, event, originalResult in
            if let textView = view as? UITextView, textView.shouldPenetrateHitTest(at: point) {
                return nil
            }
            return originalResult
        })
    }()
    
    /// 交换触摸方法（touchesBegan/Moved/Ended/Cancelled）
    static let wy_swizzleTouchMethods: Void = {
        // 交换 touchesBegan：记录起点，应用高亮，启动长按计时器
        wy_swizzlerTouchesBegan(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView,
                  let touch = touches.first else { return }
            let point = touch.location(in: textView)
            textView.wy_touchStartPoint = point
            
            // 查找点击动作（可能多个）
            let tapActions = textView.allActionsForPoint(point, actions: textView.wy_tapActions)
            textView.wy_touchStartTapActions = tapActions
            if !tapActions.isEmpty {
                // 应用点击高亮（取第一个动作的区间）
                if let firstTap = tapActions.first {
                    textView.applyHighlight(for: firstTap.range, isLongPress: false)
                }
            } else {
                // 如果没有点击动作，但有长按动作，则直接应用长按高亮（只注册了长按的文本不存在点击歧义，按下即显示长按效果色）
                let longActions = textView.allActionsForPoint(point, actions: textView.wy_longPressActions)
                if let firstLong = longActions.first {
                    textView.applyHighlight(for: firstLong.range, isLongPress: true)
                }
            }
            
            // 查找长按动作，启动长按计时器（取第一个）
            let longActions = textView.allActionsForPoint(point, actions: textView.wy_longPressActions)
            if let longAction = longActions.first {
                textView.startLongPressTimer(for: longAction, at: point)
            }
        })
        
        // 交换 touchesMoved：检测移动是否超出允许范围，若超出则取消长按并清除高亮，同时清空待执行的点击动作
        wy_swizzlerTouchesMoved(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView,
                  let touch = touches.first else { return }
            let point = touch.location(in: textView)
            let startPoint = textView.wy_touchStartPoint
            let dx = point.x - startPoint.x
            let dy = point.y - startPoint.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance > textView.wy_longPressAllowableMovement {
                textView.wy_longPressTimer?.cancel()
                textView.wy_longPressTimer = nil
                textView.clearHighlightIfNeeded()
                // 清空点击动作，避免 touchesEnded 时误触发
                textView.wy_touchStartTapActions = []
            }
        })
        
        // 交换 touchesEnded：取消计时器，若长按未触发则执行点击回调，最后清除高亮
        wy_swizzlerTouchesEnded(for: UITextView.self, before: { responder, touches, event in
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
                        
                        // 点击Block回调
                        if let handler = tapAction.handler {
                            handler(textView, text, tapAction.range, tapAction.index)
                        }
                        // 执行Delegate回调
                        if let delegate = tapAction.delegate {
                            delegate.wy_textViewTextDidClick?(textView, text: text, range: tapAction.range, index: tapAction.index)
                        }
                    }
                }
            }
            
            // 清除高亮
            textView.clearHighlightIfNeeded()
            textView.wy_touchStartTapActions = []
        })
        
        // 交换 touchesCancelled：取消计时器，清除高亮，清空点击动作
        wy_swizzlerTouchesCancelled(for: UITextView.self, before: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            textView.wy_longPressTimer?.cancel()
            textView.wy_longPressTimer = nil
            textView.wy_longPressTriggered = false
            textView.clearHighlightIfNeeded()
            textView.wy_touchStartTapActions = []
        })
    }()
}
