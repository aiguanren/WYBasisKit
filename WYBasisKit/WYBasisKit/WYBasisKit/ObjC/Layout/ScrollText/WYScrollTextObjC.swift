//
//  WYScrollTextObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/10/6.
//

import UIKit

/// ScrollText滚动方向
@objc(WYScrollTextDirection)
@frozen public enum WYScrollTextDirectionObjC: Int {
    
    /// 上下
    case upAndDown = 0
    
    /// 左右
    case leftAndRight
}

@objc public extension WYScrollText {
    
    /// 点击事件代理(也可以通过传入block监听)
    @objc(delegate)
    weak var delegateObjC: WYScrollTextDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /// 点击事件(也可以通过实现代理监听)
    @objc(didClickWithHandler:)
    func didClickObjC(handler:((_ index: Int) -> Void)? = .none) {
        didClick(handler: handler)
    }
    
    /// 占位文本
    @objc(placeholder)
    var placeholderObjC: String {
        get { return placeholder }
        set { placeholder = newValue }
    }
    
    /// 文本颜色
    @objc(textColor)
    var textColorObjC: UIColor {
        get { return textColor }
        set { textColor = newValue }
    }
    
    /// 文本字体
    @objc(textFont)
    var textFontObjC: UIFont {
        get { return textFont }
        set { textFont = newValue }
    }
    
    /// 轮播方向(默认:upAndDown)
    @objc(scrollDirection)
    var scrollDirectionObjC: WYScrollTextDirectionObjC {
        get { return WYScrollTextDirectionObjC(rawValue: scrollDirection.rawValue) ?? .upAndDown }
        set { scrollDirection = WYScrollTextDirection(rawValue: newValue.rawValue) ?? .upAndDown }
    }
    
    /// 轮播动画时长(默认0.5)
    @objc(carouselDuration)
    var carouselDurationObjC: TimeInterval {
        get { return carouselDuration }
        set { carouselDuration = newValue }
    }
    
    /// 轮播间隔，默认3s  为保证轮播流畅，该值要求最小为2s
    @objc(interval)
    var intervalObjC: TimeInterval {
        get { return interval }
        set { interval = newValue }
    }
    
    /// 背景色, 默认透明色
    @objc(contentColor)
    var contentColorObjC: UIColor {
        get { return contentColor }
        set { contentColor = newValue }
    }
    
    /// 设置标签文本
    @objc(textArray)
    var textArrayObjC: [String] {
        get { return textArray }
        set { textArray = newValue }
    }
}
