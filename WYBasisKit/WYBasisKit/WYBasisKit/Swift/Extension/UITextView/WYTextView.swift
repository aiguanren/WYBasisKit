//
//  UITextView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/16.
//

import UIKit
import ObjectiveC

// MARK: - 代理协议

/**
 文本交互事件的代理协议，可选择性实现点击或长按回调。
 */
@objc public protocol WYTextViewTouchDelegate {
    
    /**
     点击事件回调
     - parameter textView: 当前文本视图
     - parameter text:     被点击的文本内容
     - parameter range:    被点击文本在整体字符串中的范围
     - parameter index:    如果有多个相同范围注册时的索引
     */
    @objc(wy_textViewTextDidClick:clickText:range:index:)
    optional func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int)
    
    /**
     长按事件回调
     */
    @objc(wy_textViewTextDidLongPress:text:range:index:)
    optional func wy_textViewTextDidLongPress(_ textView: UITextView, text: String, range: NSRange, index: Int)
}

// MARK: - 内部数据结构

/// 存储一次注册的交互动作（点击或长按）
private class WYTextTouchAction {
    enum ActionType {
        case tap
        case longPress
    }
    let range: NSRange      // 交互文本的范围
    let type: ActionType    // 动作类型
    let index: Int          // 多个相同范围注册时的序号
    let handler: ((UITextView, String, NSRange, Int) -> Void)?   // 闭包回调
    weak var delegate: WYTextViewTouchDelegate?                  // 代理回调
    
    init(range: NSRange,
         type: ActionType,
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

/// 存储用户的注册请求（用于延迟解析和文本变化后重新解析）
private class WYTextTouchRegistration {
    enum ActionType {
        case tap
        case longPress
    }
    let rangeValue: Any     // 注册时传入的范围描述（可以是 NSRange、[NSRange] 等）
    let type: ActionType    // 动作类型
    let handler: ((UITextView, String, NSRange, Int) -> Void)?
    weak var delegate: WYTextViewTouchDelegate?
    
    init(rangeValue: Any,
         type: ActionType,
         handler: ((UITextView, String, NSRange, Int) -> Void)? = nil,
         delegate: WYTextViewTouchDelegate? = nil) {
        self.rangeValue = rangeValue
        self.type = type
        self.handler = handler
        self.delegate = delegate
    }
}

// MARK: - 公共扩展

public extension UITextView {
    
    // MARK: - 公共属性
    
    /**
     点击时的高亮背景色，若不设置则使用文字颜色的 25% 透明度版本
     */
    var wy_clickEffectColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /**
     长按时的高亮背景色
     */
    var wy_longPressEffectColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /**
     长按手势触发的最小持续时间，默认 0.5 秒
     */
    var wy_longPressMinimumDuration: TimeInterval {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let gesture = wy_longPressGesture {
                gesture.minimumPressDuration = newValue   // 同步更新已存在的手势
            }
        }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    /**
     是否允许事件穿透：当点击区域没有匹配任何可交互文本或链接时，是否将触摸事件传递给下层视图（例如父视图上的按钮）。
     默认为 false
     */
    var wy_eventPenetration: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration) as? Bool ?? false
        }
    }
    
    /**
     是否启用对 NSAttributedString.Key.link 的点击检测，若启用且点击到链接，会触发 wy_linkTapHandler。
     默认为 false
     */
    var wy_enableLinkHitTest: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest) as? Bool ?? false
        }
    }
    
    /**
     当 wy_enableLinkHitTest 为 true 且点击到链接时的回调闭包
     */
    var wy_linkTapHandler: ((URL) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler) as? (URL) -> Void }
    }
    
    // MARK: - 公共方法
    
    /**
     为指定范围的文本添加点击回调（闭包形式）
     - parameter rangeValue: 可接受 NSRange、[NSRange] 或自定义对象（需实现 wy_parseRanges 解析）
     - parameter handler:    点击时执行的闭包
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
     为指定范围的文本添加长按回调（闭包形式）
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
     为指定范围的文本添加点击回调（代理形式）
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
     为指定范围的文本添加长按回调（代理形式）
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

// MARK: - 私有辅助实现

extension UITextView {
    
    // MARK: - Associated Keys
    struct WYAssociatedKeys {
        static var wy_clickEffectColor: UInt8 = 0
        static var wy_longPressEffectColor: UInt8 = 0
        static var wy_longPressMinimumDuration: UInt8 = 0
        static var wy_enableLinkHitTest: UInt8 = 0
        static var wy_linkTapHandler: UInt8 = 0
        static var wy_tapActions: UInt8 = 0
        static var wy_longPressActions: UInt8 = 0
        static var wy_tapGesture: UInt8 = 0
        static var wy_longPressGesture: UInt8 = 0
        static var wy_tapRegistrations: UInt8 = 0
        static var wy_longPressRegistrations: UInt8 = 0
        static var wy_textObserver: UInt8 = 0
        static var wy_hasSwizzledHitTest: UInt8 = 0
        static var wy_eventPenetration: UInt8 = 0
        static var wy_highlightedRange: UInt8 = 0
        static var wy_isLongPressTriggered: UInt8 = 0
        static var wy_isTapHandling: UInt8 = 0   // 防重入标志（点击手势）
        static var wy_lastTapHandledTime: UInt8 = 0   // 时间戳防抖
    }
    
    // MARK: - 存储属性（通过关联对象实现）
    
    /// 当前所有有效的点击动作列表
    private var wy_tapActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前所有有效的长按动作列表
    private var wy_longPressActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 用户注册的点击请求（原始范围描述）
    private var wy_tapRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 用户注册的长按请求
    private var wy_longPressRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 自定义的点击手势识别器
    private var wy_tapGesture: UITapGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture) as? UITapGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 自定义的长按手势识别器
    private var wy_longPressGesture: UILongPressGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture) as? UILongPressGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 当前正在高亮显示的文本范围
    private var wy_highlightedRange: NSRange? {
        get { (objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange) as? NSValue)?.rangeValue }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange, newValue.map { NSValue(range: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 标记长按是否已经触发，用于避免在长按结束时的 touchesEnded 误触发点击
    private var wy_isLongPressTriggered: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 标记点击手势是否正在处理中，防止因事件穿透导致的手势重复触发
    private var wy_isTapHandling: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isTapHandling) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isTapHandling, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 最近一次成功处理点击的时间戳（用于防抖）
    private var wy_lastTapHandledTime: TimeInterval {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_lastTapHandledTime) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_lastTapHandledTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - KVO 观察者类
    private class WYTextObserver: NSObject {
        weak var textView: UITextView?
        init(textView: UITextView) {
            self.textView = textView
            super.init()
        }
        /**
         监听 text 和 attributedText 的变化，当文本改变时重新解析注册的范围，更新 wy_tapActions / wy_longPressActions
         */
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let textView = textView else { return }
            if keyPath == "text" || keyPath == "attributedText" {
                textView.reloadTouchActions()
            }
        }
    }
    
    /// KVO 观察者对象
    private var wy_textObserver: WYTextObserver? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_textObserver) as? WYTextObserver }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_textObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - 注册与动作刷新
    
    /// 添加一个注册请求（新增去重逻辑）
    private func addRegistration(_ registration: WYTextTouchRegistration) {
        var registrations: [WYTextTouchRegistration]
        
        switch registration.type {
        case .tap:
            registrations = wy_tapRegistrations
            // 去重：相同 type + rangeValue 只保留一份
            if !registrations.contains(where: {
                $0.type == registration.type &&
                String(describing: $0.rangeValue) == String(describing: registration.rangeValue)
            }) {
                registrations.append(registration)
                wy_tapRegistrations = registrations
            }
        case .longPress:
            registrations = wy_longPressRegistrations
            if !registrations.contains(where: {
                $0.type == registration.type &&
                String(describing: $0.rangeValue) == String(describing: registration.rangeValue)
            }) {
                registrations.append(registration)
                wy_longPressRegistrations = registrations
            }
        }
    }
    
    /**
     根据当前文本和所有注册的 rangeValue，重新生成 wy_tapActions 和 wy_longPressActions。
     当文本内容变化或新注册时调用。
     */
    private func reloadTouchActions() {
        let currentText = (self.attributedText?.string ?? self.text) ?? ""
        guard !currentText.isEmpty else {
            wy_tapActions = []
            wy_longPressActions = []
            return
        }
        
        // 解析点击动作
        var newTapActions: [WYTextTouchAction] = []
        for reg in wy_tapRegistrations {
            let ranges = currentText.wy_parseRanges(from: reg.rangeValue)
            for (idx, range) in ranges.enumerated() {
                let action = WYTextTouchAction(range: range, type: .tap, index: idx, handler: reg.handler, delegate: reg.delegate)
                newTapActions.append(action)
            }
        }
        // actions 也去重（防止解析后仍有重复）
        wy_tapActions = newTapActions.uniqueActions()
        
        // 解析长按动作
        var newLongPressActions: [WYTextTouchAction] = []
        for reg in wy_longPressRegistrations {
            let ranges = currentText.wy_parseRanges(from: reg.rangeValue)
            for (idx, range) in ranges.enumerated() {
                let action = WYTextTouchAction(range: range, type: .longPress, index: idx, handler: reg.handler, delegate: reg.delegate)
                newLongPressActions.append(action)
            }
        }
        wy_longPressActions = newLongPressActions.uniqueActions()
    }
    
    /// 开始 KVO 监听文本变化
    private func startObservingTextChanges() {
        guard wy_textObserver == nil else { return }
        let observer = WYTextObserver(textView: self)
        self.addObserver(observer, forKeyPath: "text", options: [], context: nil)
        self.addObserver(observer, forKeyPath: "attributedText", options: [], context: nil)
        wy_textObserver = observer
    }
    
    // ... 其他代码保持不变（handleTap、shouldPenetrateHitTest 等）...
    
    // MARK: - HitTest 穿透（通过方法交换）
    
    /// 启用 hitTest 穿透（交换 hitTest 方法）
    private func enableHitTestPenetrationIfNeeded() {
        // 先确保触摸方法交换已执行（静态常量保证只执行一次）
        _ = Self.wy_swizzleTouchMethods
        
        if objc_getAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            swizzleHitTestMethod()
        }
    }
    
    /// 交换 hitTest:withEvent: 方法
    private func swizzleHitTestMethod() {
        wy_exchangeHitTest(for: UITextView.self, after: { view, point, event, originalResult in
            // 如果原始返回值是 UITextView 且需要穿透，则返回 nil
            if let textView = originalResult as? UITextView, textView.shouldPenetrateHitTest(at: point) {
                return nil
            }
            return originalResult
        })
    }
    
    // MARK: - 手势设置（保持不变）
    
    private func setupTapGestureIfNeeded() {
        guard wy_tapGesture == nil else { return }
        isSelectable = false
        isEditable = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        wy_tapGesture = tap
    }
    
    private func setupLongPressGestureIfNeeded() {
        guard !wy_longPressActions.isEmpty else { return }
        guard wy_longPressGesture == nil else { return }
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = wy_longPressMinimumDuration
        longPress.cancelsTouchesInView = false
        addGestureRecognizer(longPress)
        wy_longPressGesture = longPress
    }
    
    // MARK: - 点击处理（加强防重入）
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let now = Date().timeIntervalSince1970
        if wy_isTapHandling || (now - wy_lastTapHandledTime < 0.2) {
            return
        }
        
        wy_isTapHandling = true
        wy_lastTapHandledTime = now
        
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.wy_isTapHandling = false
            }
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
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard !wy_longPressActions.isEmpty else { return }
        
        if gesture.state == .began {
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
        }
    }
    
    // MARK: - 辅助函数
    
    private func allActionsForPoint(_ point: CGPoint, actions: [WYTextTouchAction]) -> [WYTextTouchAction] {
        guard let characterIndex = characterIndexAtPoint(point) else { return [] }
        return actions.filter { NSLocationInRange(characterIndex, $0.range) }
    }
    
    private func characterIndexAtPoint(_ point: CGPoint) -> Int? {
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
    
    private func linkURLAtPoint(_ point: CGPoint) -> URL? {
        guard let characterIndex = characterIndexAtPoint(point) else { return nil }
        let linkAttribute = attributedText?.attribute(.link, at: characterIndex, effectiveRange: nil)
        if let url = linkAttribute as? URL {
            return url
        }
        if let string = linkAttribute as? String, let url = URL(string: string) {
            return url
        }
        return nil
    }
    
    private func applyHighlight(for range: NSRange, isLongPress: Bool) {
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
    
    private func removeHighlight(for range: NSRange) {
        textStorage.beginEditing()
        textStorage.removeAttribute(.backgroundColor, range: range)
        textStorage.endEditing()
    }
    
    fileprivate func shouldPenetrateHitTest(at point: CGPoint) -> Bool {
        guard wy_eventPenetration else { return false }
        
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
    
    // MARK: - 方法交换
    private static let wy_swizzleTouchMethods: Void = {
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
        
        wy_exchangeTouchesEnded(for: UITextView.self, after: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            if let range = textView.wy_highlightedRange {
                textView.removeHighlight(for: range)
                textView.wy_highlightedRange = nil
            }
            textView.wy_isLongPressTriggered = false
        })
        
        wy_exchangeTouchesCancelled(for: UITextView.self, after: { responder, touches, event in
            guard let textView = responder as? UITextView else { return }
            if let range = textView.wy_highlightedRange {
                textView.removeHighlight(for: range)
                textView.wy_highlightedRange = nil
            }
            textView.wy_isLongPressTriggered = false
        })
    }()
}

// MARK: - WYTextTouchAction 去重扩展
private extension Array where Element == WYTextTouchAction {
    func uniqueActions() -> [WYTextTouchAction] {
        var seen = Set<String>()
        var result: [WYTextTouchAction] = []
        for action in self {
            let key = "\(action.range.location)-\(action.range.length)-\(action.type)"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(action)
            }
        }
        return result
    }
}
