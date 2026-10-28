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

    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var wy_longPressMinimumDuration: TimeInterval {
        set { objc_setAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &WYAssociatedKeys.wy_longPressMinimumDuration) as? TimeInterval ?? 0.5 }
    }

    /// 是否需要模仿 UIButton 的 TouchUpInside 效果（即按下并抬起时在相同富文本上才触发回调），默认 true，若设置为 false，则在 touchesBegan 命中后立即触发回调（类似 TouchDown，注意此时同词同时注册了长按时，一次长按操作会先触发点击回调、到时长再触发长按回调）
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
