//
//  UITextView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/16.
//

import UIKit
import ObjectiveC

// MARK: - 代理协议

@objc public protocol WYTextViewTouchDelegate {
    
    @objc(wy_textViewTextDidClick:clickText:range:index:)
    optional func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int)
    
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
    let range: NSRange
    let type: ActionType
    let index: Int
    let handler: ((UITextView, String, NSRange, Int) -> Void)?
    weak var delegate: WYTextViewTouchDelegate?
    
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
    let rangeValue: Any
    let type: ActionType
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
    
    var wy_clickEffectColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_clickEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var wy_longPressEffectColor: UIColor? {
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var wy_longPressMinimumDuration: TimeInterval {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let gesture = wy_longPressGesture {
                gesture.minimumPressDuration = newValue
            }
        }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }
    
    var wy_eventPenetration: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_eventPenetration) as? Bool ?? false
        }
    }
    
    var wy_enableLinkHitTest: Bool {
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_enableLinkHitTest) as? Bool ?? false
        }
    }
    
    var wy_linkTapHandler: ((URL) -> Void)? {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_linkTapHandler) as? (URL) -> Void }
    }
    
    // MARK: - 公共方法
    
    func wy_addTextTapHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: handler, delegate: nil)
        addRegistration(registration)
        reloadTouchActions()
        setupTapGestureIfNeeded()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
    func wy_addTextLongPressHandler(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .longPress, handler: handler, delegate: nil)
        addRegistration(registration)
        reloadTouchActions()
        setupLongPressGestureIfNeeded()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
    func wy_addTextTapDelegate(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        let registration = WYTextTouchRegistration(rangeValue: rangeValue, type: .tap, handler: nil, delegate: delegate)
        addRegistration(registration)
        reloadTouchActions()
        setupTapGestureIfNeeded()
        startObservingTextChanges()
        enableHitTestPenetrationIfNeeded()
    }
    
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
    }
    
    private var wy_tapActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_longPressActions: [WYTextTouchAction] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions) as? [WYTextTouchAction] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressActions, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_tapRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_longPressRegistrations: [WYTextTouchRegistration] {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations) as? [WYTextTouchRegistration] ?? [] }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressRegistrations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_tapGesture: UITapGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture) as? UITapGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_tapGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_longPressGesture: UILongPressGestureRecognizer? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture) as? UILongPressGestureRecognizer }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressGesture, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_highlightedRange: NSRange? {
        get { (objc_getAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange) as? NSValue)?.rangeValue }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_highlightedRange, newValue.map { NSValue(range: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private var wy_isLongPressTriggered: Bool {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isLongPressTriggered, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private class WYTextObserver: NSObject {
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
    
    private var wy_textObserver: WYTextObserver? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_textObserver) as? WYTextObserver }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_textObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private func addRegistration(_ registration: WYTextTouchRegistration) {
        switch registration.type {
        case .tap:
            var arr = wy_tapRegistrations
            arr.append(registration)
            wy_tapRegistrations = arr
        case .longPress:
            var arr = wy_longPressRegistrations
            arr.append(registration)
            wy_longPressRegistrations = arr
        }
    }
    
    private func reloadTouchActions() {
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
    
    private func startObservingTextChanges() {
        guard wy_textObserver == nil else { return }
        let observer = WYTextObserver(textView: self)
        self.addObserver(observer, forKeyPath: "text", options: [], context: nil)
        self.addObserver(observer, forKeyPath: "attributedText", options: [], context: nil)
        wy_textObserver = observer
    }
    
    private func enableHitTestPenetrationIfNeeded() {
        if objc_getAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest) == nil {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_hasSwizzledHitTest, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            swizzleHitTestMethod()
        }
    }
    
    private func swizzleHitTestMethod() {
        let originalSelector = #selector(hitTest(_:with:))
        let swizzledSelector = #selector(wy_textViewHitTest(_:with:))
        
        guard let originalMethod = class_getInstanceMethod(UITextView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UITextView.self, swizzledSelector) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc func wy_textViewHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let originalView = self.wy_textViewHitTest(point, with: event)
        if let textView = originalView as? UITextView, textView.shouldPenetrateHitTest(at: point) {
            return nil
        }
        return originalView
    }
    
    // MARK: - 手势设置
    
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
    
    private func removeLongPressGesture() {
        if let gesture = wy_longPressGesture {
            removeGestureRecognizer(gesture)
            wy_longPressGesture = nil
        }
    }
    
    // MARK: - 高亮处理（立即响应）
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let point = touches.first?.location(in: self) else { return }
        
        let tapActions = allActionsForPoint(point, actions: wy_tapActions)
        let longActions = allActionsForPoint(point, actions: wy_longPressActions)
        
        if let action = tapActions.first ?? longActions.first {
            let isLongPressStyle = !longActions.isEmpty
            applyHighlight(for: action.range, isLongPress: isLongPressStyle)
            wy_highlightedRange = action.range
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
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
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let range = wy_highlightedRange {
            removeHighlight(for: range)
            wy_highlightedRange = nil
        }
        wy_isLongPressTriggered = false
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let range = wy_highlightedRange {
            removeHighlight(for: range)
            wy_highlightedRange = nil
        }
        wy_isLongPressTriggered = false
    }
    
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
        let hasMatchingTap = !allActionsForPoint(point, actions: wy_tapActions).isEmpty
        let hasMatchingLongPress = !allActionsForPoint(point, actions: wy_longPressActions).isEmpty
        if hasMatchingTap || hasMatchingLongPress {
            return false
        }
        
        if wy_enableLinkHitTest {
            if let _ = linkURLAtPoint(point) {
                return false
            }
        }
        
        return wy_eventPenetration
    }
}
