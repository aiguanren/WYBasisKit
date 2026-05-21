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
            if let gesture = wy_longPressGesture {
                gesture.minimumPressDuration = newValue
            }
        }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    /// 非链接区域事件是否需要穿透UITextView，默认False(为False时点击指定字符串之外区域，事件按照UITextVeiw默认响应链响应，为True时，将跳过UITextVeiw，直接响应事件到UITextVeiw的父View)
    var wy_eventPenetration: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
        setupTapGestureIfNeeded()
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
        setupLongPressGestureIfNeeded()
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
        setupTapGestureIfNeeded()
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
        setupLongPressGestureIfNeeded()
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
        /// 是否启用链接点击关联键
        static var wy_enableLinkHitTest: UInt8 = 0
        /// 链接点击回调关联键
        static var wy_linkTapHandler: UInt8 = 0
        /// 所有点击动作列表关联键
        static var wy_tapActions: UInt8 = 0
        /// 所有长按动作列表关联键
        static var wy_longPressActions: UInt8 = 0
        /// 点击手势关联键
        static var wy_tapGesture: UInt8 = 0
        /// 长按手势关联键
        static var wy_longPressGesture: UInt8 = 0
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
        /// 长按是否已触发标记关联键
        static var wy_isLongPressTriggered: UInt8 = 0
        /// 是否正在处理点击标记关联键
        static var wy_isTapHandling: UInt8 = 0
        /// 最后一次点击处理的时间戳关联键
        static var wy_lastTapHandledTime: UInt8 = 0
    }
    
    /// 是否启用对链接（.link）的点击响应。若开启，则点击链接时会调用 `wy_linkTapHandler`。
    var wy_enableLinkHitTest: Bool {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest) as? Bool ?? false }
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
    
    /// 添加的点击手势识别器。
    var wy_tapGesture: UITapGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture) as? UITapGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 添加的长按手势识别器。
    var wy_longPressGesture: UILongPressGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture) as? UILongPressGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前正在高亮显示的文本区间，用于按下时背景色。
    var wy_highlightedRange: NSRange? {
        get { (objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange) as? NSValue)?.rangeValue }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange, newValue.map { NSValue(range: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 长按手势是否已经触发的标记，用于避免点击和长按冲突。
    var wy_isLongPressTriggered: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 是否正在处理点击事件的标记，用于防止短时间内重复触发。
    var wy_isTapHandling: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isTapHandling) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isTapHandling, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 上一次成功处理点击事件的时间戳，用于防抖。
    var wy_lastTapHandledTime: TimeInterval {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lastTapHandledTime) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lastTapHandledTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// KVO 观察者类，用于监听 text / attributedText 变化。
    class WYTextObserver: NSObject {
        /// 被观察的 UITextView 实例（弱引用）
        weak var textView: UITextView?
        init(textView: UITextView) {
            self.textView = textView
            super.init()
        }
        /// 当监听的属性发生变化时，触发重新解析动作列表
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let textView = textView else { return }
            if keyPath == "text" || keyPath == "attributedText" {
                textView.reloadTouchActions()
            }
        }
    }
    
    /// 文本内容观察者对象。
    var wy_textObserver: WYTextObserver? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_textObserver) as? WYTextObserver }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_textObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
            if let textView = originalResult as? UITextView, textView.shouldPenetrateHitTest(at: point) {
                return nil
            }
            return originalResult
        })
    }
    
    /// 添加点击手势
    func setupTapGestureIfNeeded() {
        guard wy_tapGesture == nil else { return }
        isSelectable = false
        isEditable = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        wy_tapGesture = tap
    }
    
    /// 添加长按手势
    func setupLongPressGestureIfNeeded() {
        guard !wy_longPressActions.isEmpty, wy_longPressGesture == nil else { return }
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = wy_longPressMinimumDuration
        longPress.cancelsTouchesInView = false
        addGestureRecognizer(longPress)
        wy_longPressGesture = longPress
    }
    
    /// 处理点击手势
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let now = Date().timeIntervalSince1970
        if wy_isTapHandling || (now - wy_lastTapHandledTime < 0.2) { return }
        
        wy_isTapHandling = true
        wy_lastTapHandledTime = now
        
        defer {
            // 无论是否命中，都尝试清理高亮
            self.clearHighlightIfNeeded()
            self.wy_isTapHandling = false
        }
        
        if wy_isLongPressTriggered {
            wy_isLongPressTriggered = false
            return
        }
        
        let point = gesture.location(in: self)
        let actions = allActionsForPoint(point, actions: wy_tapActions)
        
        if !actions.isEmpty {
            for action in actions {
                let text = (self.attributedText?.string as? NSString ?? self.text as NSString?)?.substring(with: action.range) ?? ""
                if let handler = action.handler {
                    handler(self, text, action.range, action.index)
                }
                if let delegate = action.delegate {
                    delegate.wy_textViewTextDidClick?(self, text: text, range: action.range, index: action.index)
                }
            }
            return
        }
        
        if wy_enableLinkHitTest, let url = linkURLAtPoint(point) {
            wy_linkTapHandler?(url)
            return
        }
        
        if wy_eventPenetration {
            gesture.isEnabled = false
            DispatchQueue.main.async {
                gesture.isEnabled = true
            }
        }
    }
    
    /// 清理当前高亮区间（若有）。
    func clearHighlightIfNeeded() {
        if let range = wy_highlightedRange {
            removeHighlight(for: range)
            wy_highlightedRange = nil
        }
    }
    
    /// 处理长按手势
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            guard !wy_longPressActions.isEmpty, gesture.state == .began else { return }
            wy_isLongPressTriggered = true
            let point = gesture.location(in: self)
            let actions = allActionsForPoint(point, actions: wy_longPressActions)
            for action in actions {
                let text = (self.attributedText?.string as? NSString ?? self.text as NSString?)?.substring(with: action.range) ?? ""
                if let handler = action.handler {
                    handler(self, text, action.range, action.index)
                }
                if let delegate = action.delegate {
                    delegate.wy_textViewTextDidLongPress?(self, text: text, range: action.range, index: action.index)
                }
            }
        default:
            // 兜底清理（防止 touchesEnded 没来得及执行的情况）
            clearHighlightIfNeeded()
            wy_isLongPressTriggered = false
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
    
    /// 一次性交换触摸开始、结束、取消以及 hitTest 方法，用于实现高亮和穿透。
    static let wy_swizzleTouchMethods: Void = {
        // 交换 touchesBegan，在触摸开始时根据触摸点高亮对应的区间
        wy_exchangeTouchesBegan(for: UITextView.self, after: { responder, touches, event in
            guard let textView = responder as? UITextView,
                  let point = touches.first?.location(in: textView) else { return }
            
            let tapActions = textView.allActionsForPoint(point, actions: textView.wy_tapActions)
            let longActions = textView.allActionsForPoint(point, actions: textView.wy_longPressActions)
            
            if let action = tapActions.first ?? longActions.first {
                let isLongPressStyle = !longActions.isEmpty
                textView.applyHighlight(for: action.range, isLongPress: isLongPressStyle)
                textView.wy_highlightedRange = action.range
            }
        })
        
        // 交换 touchesEnded，触摸结束时清除高亮并重置长按标志
        wy_exchangeTouchesEnded(for: UITextView.self, after: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            textView.clearHighlightIfNeeded()
            textView.wy_isLongPressTriggered = false
        })
        
        // 交换 touchesCancelled，触摸取消时清除高亮并重置长按标志
        wy_exchangeTouchesCancelled(for: UITextView.self, after: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            textView.clearHighlightIfNeeded()
            textView.wy_isLongPressTriggered = false
        })
    }()
}
