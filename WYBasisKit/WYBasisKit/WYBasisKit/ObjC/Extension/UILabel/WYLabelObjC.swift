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
