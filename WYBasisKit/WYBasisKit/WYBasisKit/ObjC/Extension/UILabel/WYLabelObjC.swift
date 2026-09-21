//
//  UILabel.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/9/21.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

@objc public extension UILabel {

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
     * - 若用户未主动设置，则先回退使用 wy_clickEffectColor；两者都未设置时，自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     * - 显示时机为只注册了长按的文本按下立即显示本颜色；同时注册了点击的文本按下先显示点击效果色，达到长按最小时长后才切换为本颜色（因为按下瞬间无法区分用户想点击还是长按）。
     */
    @objc(wy_longPressEffectColor)
    var wy_longPressEffectColorObjC: UIColor? {
        get { return wy_longPressEffectColor }
        set { wy_longPressEffectColor = newValue }
    }

    /// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 true 时按下用效果色盖住、手指移开后还原自带背景色；为 false 时自带背景色的文本按下不显示高亮)
    @objc(wy_overlaysOriginalBackground)
    var wy_overlaysOriginalBackgroundObjC: Bool {
        get { return wy_overlaysOriginalBackground }
        set { wy_overlaysOriginalBackground = newValue }
    }

    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    @objc(wy_longPressMinimumDuration)
    var wy_longPressMinimumDurationObjC: TimeInterval {
        get { return wy_longPressMinimumDuration }
        set { wy_longPressMinimumDuration = newValue }
    }

    /// 是否需要模仿 UIButton 的 TouchUpInside 效果（即按下并抬起时在相同富文本上才触发回调），默认 true，若设置为 false，则在 touchesBegan 命中后立即触发回调（类似 TouchDown；注意此时同词又注册了长按的话，一次长按操作会先触发点击回调、到时长再触发长按回调）
    @objc(wy_touchUpInside)
    var wy_touchUpInsideObjC: Bool {
        get { return wy_touchUpInside }
        set { wy_touchUpInside = newValue }
    }

    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 点击事件回调闭包
     *
     */
    @objc(wy_addTextTapEventsWithRangeValue:handler:)
    func wy_addTextTapHandlerObjC(rangeValue: Any, handler:((_ label: UILabel, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addTextTapHandler(rangeValue: rangeValue, handler: handler)
    }

    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param handler 长按事件回调闭包
     */
    @objc(wy_addTextLongPressEventsWithRangeValue:handler:)
    func wy_addTextLongPressHandlerObjC(rangeValue: Any, handler:((_ label: UILabel, _ text: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addTextLongPressHandler(rangeValue: rangeValue, handler: handler)
    }

    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加点击事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 点击代理（需实现 WYRichTextTouchDelegate 协议）
     *
     */
    @objc(wy_addTextTapEventsWithRangeValue:delegate:)
    func wy_addTextTapDelegateObjC(rangeValue: Any, delegate: WYRichTextTouchDelegate) {
        wy_addTextTapDelegate(rangeValue: rangeValue, delegate: delegate)
    }

    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param rangeValue  需要添加长按事件的字符串或区间或数组(支持类型：`String`、`NSRange`、`[String]`、`[NSRange]`，以及上述类型的任意嵌套组合（例如 `[String, NSRange]`）)
     * @param delegate 长按代理（需实现 WYRichTextTouchDelegate 协议）
     *
     */
    @objc(wy_addTextLongPressEventsWithRangeValue:delegate:)
    func wy_addTextLongPressDelegateObjC(rangeValue: Any, delegate: WYRichTextTouchDelegate) {
        wy_addTextLongPressDelegate(rangeValue: rangeValue, delegate: delegate)
    }
}
