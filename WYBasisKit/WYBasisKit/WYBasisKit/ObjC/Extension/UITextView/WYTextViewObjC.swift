//
//  UITextView.swift
//  WYBasisKit
//
//  Created by guanren on 2026/5/16.
//

import UIKit

@objc public extension UITextView {
    
    /**
     * 点击效果颜色（按下时的背景色）
     *
     * - 若用户未主动设置，则自动使用被点击富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    @objc(wy_clickEffectColor)
    var wy_clickEffectColorObjC: UIColor? {
        get { return wy_clickEffectColor }
        set { wy_clickEffectColor = newValue }
    }
    
    /**
     * 长按效果颜色（长按时背景色）
     *
     * - 若用户未主动设置，则自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    @objc(wy_longPressEffectColor)
    var wy_longPressEffectColorObjC: UIColor? {
        get { return wy_longPressEffectColor }
        set { wy_longPressEffectColor = newValue }
    }
    
    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    @objc(wy_longPressMinimumDuration)
    var wy_longPressMinimumDurationObjC: TimeInterval {
        set { wy_longPressMinimumDuration = newValue }
        get { return wy_longPressMinimumDuration }
    }
    
    /// 非链接区域事件是否需要穿透UITextView，默认False(为False时点击指定字符串之外区域，事件按照UITextVeiw默认响应链响应，为True时，将跳过UITextVeiw，直接响应事件到UITextVeiw的父View)
    @objc(wy_eventPenetration)
    var wy_eventPenetrationObjC: Bool {
        set { wy_eventPenetration = newValue }
        get { return wy_eventPenetration }
    }
    
    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler     点击事件回调闭包
     *
     */
    @objc(wy_addTextTapEventsWithRangeValue:handler:)
    func wy_addTextTapHandlerObjC(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addTextTapHandler(rangeValue: rangeValue, handler: handler)
    }
    
    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 长按事件回调闭包
     */
    @objc(wy_addTextLongPressEventsWithRangeValue:handler:)
    func wy_addTextLongPressHandlerObjC(rangeValue: Any, handler:((_ textView: UITextView, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addTextLongPressHandler(rangeValue: rangeValue, handler: handler)
    }
    
    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 点击代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    @objc(wy_addTextTapEventsWithRangeValue:delegate:)
    func wy_addTextTapDelegateObjC(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        wy_addTextTapDelegate(rangeValue: rangeValue, delegate: delegate)
    }
    
    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 长按代理（需实现 WYTextTouchDelegate 协议）
     *
     */
    @objc(wy_addTextLongPressEventsWithRangeValue:delegate:)
    func wy_addTextLongPressDelegateObjC(rangeValue: Any, delegate: WYTextViewTouchDelegate) {
        wy_addTextLongPressDelegate(rangeValue: rangeValue, delegate: delegate)
    }
}
