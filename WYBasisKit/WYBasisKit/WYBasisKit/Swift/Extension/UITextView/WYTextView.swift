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
     * @param index       本次命中的词在其所属注册解析出的全部范围中按文本出现顺序的下标(同一词多次出现时用于区分点中的是哪一处)
     */
    @objc(wy_textViewTextDidClick:clickText:range:index:)
    optional func wy_textViewTextDidClick(_ textView: UITextView, text: String, range: NSRange, index: Int)
    
    /**
     * 文本长按回调
     * @param textView    当前 UITextView 实例
     * @param text        被长按的字符串内容
     * @param range       被长按字符串在整个文本中的 NSRange
     * @param index       本次命中的词在其所属注册解析出的全部范围中按文本出现顺序的下标(同一词多次出现时用于区分点中的是哪一处)
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
     * - 若用户未主动设置，则先回退使用 wy_clickEffectColor，两者都未设置时，自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     * - 显示时机为只注册了长按的文本按下立即显示本颜色，同时注册了点击的文本按下先显示点击效果色，达到长按最小时长后才切换为本颜色（因为按下瞬间无法区分用户想点击还是长按）。
     */
    var wy_longPressEffectColor: UIColor? {
        get { objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor) as? UIColor }
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressEffectColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 true 时按下用效果色盖住、手指移开后还原自带背景色，为 false 时自带背景色的文本按下不显示高亮)
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
    
    /// 非链接区域的点击事件是否需要穿透UITextView，默认false(为false时点击指定字符串之外区域，事件按照UITextView默认响应链响应，为true时，将跳过UITextView，直接响应事件到UITextView的父View)
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
