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
    
    /// 是否打开点击效果,默认开启
    @objc(wy_enableClickEffect)
    var wy_enableClickEffectObjC: Bool {
        set(newValue) { wy_enableClickEffect = newValue }
        get { return wy_enableClickEffect }
    }
    
    /// 点击效果颜色,默认透明
    @objc(wy_clickEffectColor)
    var wy_clickEffectColorObjC: UIColor {
        set(newValue) { wy_clickEffectColor = newValue }
        get { return wy_clickEffectColor }
    }
    
    /// 是否需要模仿按钮的TouchUpInside效果，默认true
    @objc(wy_needTouchUpInside)
    var wy_needTouchUpInsideObjC: Bool {
        set(newValue) { wy_needTouchUpInside = newValue }
        get { return wy_needTouchUpInside }
    }
    
    /// 最大允许的触摸移动距离（pt），超出则视为取消点击，默认15.0
    @objc(wy_maxTouchMoveDistance)
    var wy_maxTouchMoveDistanceObjC: CGFloat {
        set { wy_maxTouchMoveDistance = newValue }
        get { return wy_maxTouchMoveDistance }
    }
    
    /// 是否启用触摸时长检查（若启用，则触摸时长必须小于 wy_touchDurationLimit 才会响应），默认 false
    @objc(wy_enableTouchDurationCheck)
    var wy_enableTouchDurationCheckObjC: Bool {
        set { wy_enableTouchDurationCheck = newValue }
        get { return wy_enableTouchDurationCheck }
    }
    
    /// 最长允许的触摸时长（秒），仅在 wy_enableTouchDurationCheck = true 时生效，默认0.6秒
    @objc(wy_touchDurationLimit)
    var wy_touchDurationLimitObjC: TimeInterval {
        set { wy_touchDurationLimit = newValue }
        get { return wy_touchDurationLimit }
    }
    
    /**
     * 自定义扩大/缩小点击热区，默认 .zero。
     * 正数表示向外扩大点击区域，负数表示向内缩小。
     * 示例：UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) 表示上下左右各扩大10pt。
     */
    @objc(wy_touchEdgeInsets)
    var wy_touchEdgeInsetsObjC: UIEdgeInsets {
        set { wy_touchEdgeInsets = newValue }
        get { return wy_touchEdgeInsets }
    }
    
    /**
     *  给文本添加Block点击事件回调
     *
     *  @param strings  需要添加点击事件的字符串数组
     *  @param handler  点击事件回调
     *
     */
    @objc(wy_addRichTexts:handler:)
    func wy_addRichTextObjC(strings: [String], handler:((_ string: String, _ range: NSRange, _ index: Int) -> Void)? = nil) {
        wy_addRichText(strings: strings, handler: handler)
    }
    
    /**
     *  给文本添加点击事件delegate回调
     *
     *  @param strings  需要添加点击事件的字符串数组
     *  @param delegate 富文本代理
     *
     */
    @objc(wy_addRichTexts:delegate:)
    func wy_addRichTextObjC(strings: [String], delegate: WYRichTextDelegate) {
        wy_addRichText(strings: strings, delegate: delegate)
    }
}
