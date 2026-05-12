//
//  UILabelObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import UIKit
import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc public extension UILabel {
    
    /// 是否打开点击效果（按下时改变背景色，仅点击有效，长按可以通过设置 `wy_longPressEffectColor` 来达到开启或者透明关闭的功能），默认开启
    @objc(wy_enableClickEffect)
    var wy_enableClickEffectObjC: Bool {
        set { wy_enableClickEffect = newValue }
        get { return wy_enableClickEffect }
    }
    
    /**
     * 点击效果颜色（按下时的背景色），默认透明（即无效果）
     *
     * - 若用户未主动设置，则自动使用被点击富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    @objc(wy_clickEffectColor)
    var wy_clickEffectColorObjC: UIColor {
        set { wy_clickEffectColor = newValue }
        get { return wy_clickEffectColor }
    }
    
    /**
     * 长按效果颜色（长按时背景色），默认透明（即无效果）
     *
     * - 若用户未主动设置，则自动使用被长按富文本的文字颜色 + 0.25 透明度。
     * - 若用户主动设置（包括设置为 `.clear`），则使用该颜色（不再动态取色）。
     */
    @objc(wy_longPressEffectColor)
    var wy_longPressEffectColorObjC: UIColor {
        set { wy_longPressEffectColor = newValue }
        get { return wy_longPressEffectColor }
    }
    
    /// 是否启用长按回调，默认 false
    @objc(wy_enableLongPress)
    var wy_enableLongPressObjC: Bool {
        set { wy_enableLongPress = newValue }
        get { return wy_enableLongPress }
    }
    
    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    @objc(wy_longPressMinimumDuration)
    var wy_longPressMinimumDurationObjC: TimeInterval {
        set { wy_longPressMinimumDuration = newValue }
        get { return wy_longPressMinimumDuration }
    }
    
    /// 是否需要模仿 UIButton 的 TouchUpInside 效果（即按下并抬起时在相同富文本上才触发回调），默认 true，若设置为 false，则在 touchesBegan 命中后立即触发回调（类似 TouchDown）
    @objc(wy_touchUpInside)
    var wy_touchUpInsideObjC: Bool {
        set { wy_touchUpInside = newValue }
        get { return wy_touchUpInside }
    }
    
    /// 最大允许的触摸移动距离（pt），超出则视为取消点击，默认 15.0（仅在 wy_touchUpInside = true 时有效）
    @objc(wy_maxTouchMoveDistance)
    var wy_maxTouchMoveDistanceObjC: CGFloat {
        set { wy_maxTouchMoveDistance = newValue }
        get { return wy_maxTouchMoveDistance }
    }
    
    /// 点击时是否启用触摸时长检查，默认 false（立即响应），若为 true，则触摸时长必须小于 wy_touchDurationLimit 才会响应点击
    @objc(wy_enableTouchDurationCheck)
    var wy_enableTouchDurationCheckObjC: Bool {
        set { wy_enableTouchDurationCheck = newValue }
        get { return wy_enableTouchDurationCheck }
    }
    
    /// 最长允许的触摸时长（秒），仅在 wy_enableTouchDurationCheck = true 时生效，默认 0.6 秒
    @objc(wy_touchDurationLimit)
    var wy_touchDurationLimitObjC: TimeInterval {
        set { wy_touchDurationLimit = newValue }
        get { return wy_touchDurationLimit }
    }
    
    /**
     * 给文本添加点击事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings 需要添加点击事件的字符串数组
     * @param handler 点击事件回调闭包，参数依次为：label 自身、点击的字符串、range、在数组中的索引
     */
    @objc(wy_addRichTextTapStrings:handler:)
    func wy_addRichTextTapObjC(strings: [String], handler:((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addRichTextTapHandler(strings: strings, handler: handler)
    }
    
    /**
     * 给文本添加长按事件的 Block 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings 需要添加长按事件的字符串数组
     * @param handler 长按事件回调闭包，参数依次为：label 自身、长按的字符串、range、在数组中的索引
     *
     * 注意：必须先设置 wy_enableLongPress = true 并保证 wy_longPressMinimumDuration 合理。
     */
    @objc(wy_addRichTextLongPressStrings:handler:)
    func wy_addRichTextLongPressObjC(strings: [String], handler:((_ label: UILabel, _ richText: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addRichTextLongPressHandler(strings: strings, handler: handler)
    }
    
    /**
     * 给文本添加点击事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings  需要添加点击事件的字符串数组
     * @param delegate 富文本代理（需实现 WYRichTextDelegate 协议）
     */
    @objc(wy_addRichTextTapStrings:delegate:)
    func wy_addRichTextTapObjC(strings: [String], delegate: WYRichTextDelegate) {
        wy_addRichTextTapDelegate(strings: strings, delegate: delegate)
    }
    
    /**
     * 给文本添加长按事件的 Delegate 回调（支持同一文本中多次出现，全部生效）
     *
     * @param strings  需要添加长按事件的字符串数组
     * @param delegate 富文本代理（需实现 WYRichTextDelegate 协议）
     */
    @objc(wy_addRichTextLongPressStrings:delegate:)
    func wy_addRichTextLongPressObjC(strings: [String], delegate: WYRichTextDelegate) {
        wy_addRichTextLongPressDelegate(strings: strings, delegate: delegate)
    }
}
