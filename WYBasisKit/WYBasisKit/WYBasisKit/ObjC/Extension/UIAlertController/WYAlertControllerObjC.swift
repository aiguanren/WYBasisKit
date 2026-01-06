//
//  UIAlertControllerObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/25.
//

import Foundation
import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc public extension UIAlertController {
    
    /**
     *  显示 UIAlertController
     *
     *  @param style UIAlertController 的样式，默认为 .alert，可选 .actionSheet
     *  @param title 标题，可以是 String 或 NSAttributedString
     *  @param message 消息内容，可以是 String 或 NSAttributedString
     *  @param duration 显示持续时间，默认为 0.0，若大于 0，会自动消失
     *  @param actionSheetNeedCancel 当 style 为 .actionSheet 时，是否需要自动添加取消按钮，默认为 true
     *  @param textFieldPlaceholders Alert 中文本输入框的占位符数组，支持 String 或 NSAttributedString
     *  @param actions 按钮标题数组，支持 String 或 NSAttributedString
     *  @param handler 点击按钮回调，返回点击的按钮标题以及文本输入框内容数组
     */
    @objc(wy_showStyle:title:message:duration:actionSheetNeedCancel:textFieldPlaceholders:actions:handler:)
    static func wy_showObjC(style: UIAlertController.Style = .alert,
                            title: Any? = nil,
                            message: Any? = nil,
                            duration: TimeInterval = 0.0,
                            actionSheetNeedCancel: Bool = true,
                            textFieldPlaceholders: [Any] = [],
                            actions: [Any] = [],
                            handler:((_ action: String, _ inputTexts: [String]) -> Void)? = nil) {
        wy_show(style: style, title: title, message: message, duration: duration, actionSheetNeedCancel: actionSheetNeedCancel, textFieldPlaceholders: textFieldPlaceholders, actions: actions, handler: handler)
    }
}
