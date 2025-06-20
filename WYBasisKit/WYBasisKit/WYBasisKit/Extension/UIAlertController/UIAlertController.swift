//
//  UIAlertController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import Foundation
import UIKit

public extension UIAlertController {
    
    class func wy_show(style: UIAlertController.Style = .alert, title: Any? = nil, message: Any? = nil, duration: TimeInterval = 0.0, actionSheetNeedCancel: Bool = true, textFieldPlaceholders: [Any] = [], actions: [Any] = [], handler:((_ action: String, _ inputTexts: [String]) -> Void)? = nil) {
        
        DispatchQueue.main.async {
            
            let alertTitle: String = wy_sharedGenericString(object: title)
            
            let alertMessage: String = wy_sharedGenericString(object: message)
            
            var alertPlaceholders: [String] = []
            if style == .alert {
                for placeholder: Any in textFieldPlaceholders {
                    alertPlaceholders.append(wy_sharedGenericString(object: placeholder))
                }
            }
            
            var alertTitles: [String] = []
            for actionTitle: Any in actions {
                alertTitles.append(wy_sharedGenericString(object: actionTitle))
            }
            
            let alertController: UIAlertController? = wy_internalShow(style: style, title: alertTitle, message: alertMessage, duration: duration, actionSheetNeedCancel: actionSheetNeedCancel, textFieldPlaceholders: alertPlaceholders, actions: alertTitles, handler: handler)
            
            if (title != nil) && (title is NSAttributedString) && (checkPropertySecurity(property: "_attributedTitle", object: alertController, className: "UIAlertController")) {
                alertController?.setValue(title as! NSAttributedString, forKey: "attributedTitle")
            }
            
            if (message != nil) && (message is NSAttributedString) && (checkPropertySecurity(property: "_attributedMessage", object: alertController, className: "UIAlertController")) {
                alertController?.setValue(message as! NSAttributedString, forKey: "attributedMessage")
            }
            
            if alertController?.textFields?.isEmpty == false {
                for index in 0 ..< alertController!.textFields!.count {
                    let textField: UITextField = alertController!.textFields![index]
                    let placeholder = textFieldPlaceholders[index]
                    if placeholder is NSAttributedString {
                        textField.attributedPlaceholder = (placeholder as! NSAttributedString)
                    }
                }
            }
            
            if alertController?.actions.isEmpty == false {
                for index in 0 ..< alertController!.actions.count {
                    let alertAction: UIAlertAction = alertController!.actions[index]
                    if index < actions.count {
                        let actionTitle = actions[index]
                        if (actionTitle is NSAttributedString) && (checkPropertySecurity(property: "_titleTextColor", object: alertAction, className: "UIAlertAction")) {
                            alertAction.setValue((actionTitle as! NSAttributedString).attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: nil), forKey: "titleTextColor")
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    private class func wy_internalShow(style: UIAlertController.Style = .alert, title: String = "", message: String = "", duration: TimeInterval = 0.0, actionSheetNeedCancel: Bool = true, textFieldPlaceholders: [String] = [], actions: [String] = [], handler:((_ actionStr: String, _ textFieldTexts: [String]) -> Void)? = nil) -> UIAlertController? {
        
        if title.isEmpty && message.isEmpty && textFieldPlaceholders.isEmpty && actions.isEmpty {
            return nil
        }
        
        let alertController: UIAlertController! = UIAlertController(title: (title.isEmpty ? nil : title), message: (message.isEmpty ? nil : message), preferredStyle: style)
        
        for placeholder: String in textFieldPlaceholders {
            
            alertController.addTextField { (textField) in
                
                textField.placeholder = placeholder
                textField.isSecureTextEntry = alertController.wy_sharedSecureTextEntry(placeholder: placeholder)
            }
        }
        
        for actionStr: String in actions {
            
            alertController.wy_addAlertAction(actionStr: actionStr, actionStyle: alertController.wy_sharedActionStyle(actionStr: actionStr, alertStyle: style), alertController: alertController, textFieldPlaceholders: textFieldPlaceholders, handler: handler)
        }
        
        if ((style == .actionSheet) && (actionSheetNeedCancel == true)) {
            
            alertController.wy_addAlertAction(actionStr: WYLocalized("WYLocalizable_03", table: WYBasisKitConfig.kitLocalizableTable), actionStyle: .cancel, alertController: alertController, textFieldPlaceholders: textFieldPlaceholders, handler: nil)
        }
        
        alertController.modalPresentationStyle = .fullScreen
        alertController.wy_alertWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        
        if duration > 0.0 {
            
            DispatchQueue.main.asyncAfter(deadline: .now()+duration) {
                
                if (handler != nil) {

                    handler!("", [])
                }
                alertController.wy_alertWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                alertController.wy_sharedAppDelegate().window?!.makeKeyAndVisible()
            }
        }
        return alertController
    }
    
    private func wy_addAlertAction(actionStr: String, actionStyle: UIAlertAction.Style, alertController: UIAlertController, textFieldPlaceholders: [String] = [], handler:((_ actionStr: String, _ textFieldTexts: [String]) -> Void)? = nil) {
        
        let action: UIAlertAction = UIAlertAction(title: actionStr, style: actionStyle) { (alertAction) in
            
            if (handler != nil) {

                let texts: NSMutableArray = []
                if !textFieldPlaceholders.isEmpty {
                    
                    for textField: UITextField in alertController.textFields! {
                        
                        texts.add(textField.text ?? "")
                    }
                }
                handler!(alertAction.title!, texts.copy() as! Array<String>)
            }
            alertController.wy_sharedAppDelegate().window?!.makeKeyAndVisible()
        }
        alertController.addAction(action)
    }
    
    private func wy_sharedActionStyle(actionStr: String!, alertStyle: UIAlertController.Style!) -> UIAlertAction.Style {
        
        var actionStyle: UIAlertAction.Style! = UIAlertAction.Style.default
        switch actionStr {
        case WYLocalized("WYLocalizable_04", table: WYBasisKitConfig.kitLocalizableTable):
            actionStyle = UIAlertAction.Style.destructive
        default:
            actionStyle = UIAlertAction.Style.default
        }
        return actionStyle
    }
    
    private func wy_sharedSecureTextEntry(placeholder: String!) -> Bool {
        
        return placeholder.range(of: WYLocalized("WYLocalizable_02", table: WYBasisKitConfig.kitLocalizableTable), options: .caseInsensitive) != nil
    }
    
    private class func wy_sharedGenericString<T>(object: T?) -> String {
        
        guard let obj = object else {
            return ""
        }

        if obj is String {
            return obj as! String
        }
        else if obj is NSAttributedString {
            return (obj as! NSAttributedString).string
        }else {
            fatalError("\(obj)" + "只能是 String 或者 NSAttributedString 类型的")
        }
    }
    
    private class func checkPropertySecurity(property: String, object: AnyObject?, className: String) -> Bool {
        
        var propertys: [String: Any] = [:]
        
        if (object != nil) {
            Mirror(reflecting: object!).children.forEach { (child) in
                propertys[child.label ?? "未知"] = type(of: child.value)
            }
        }
        guard let objClass = NSClassFromString(className) else {
            return propertys.keys.contains(property)
        }
        
        var count: UInt32 = 0
        let ivars = class_copyIvarList(objClass, &count)
        for i in 0..<count {
            let ivar = ivars?[Int(i)]
            let ivarName = NSString(cString: ivar_getName(ivar!)!, encoding: String.Encoding.utf8.rawValue)
            let ivarType = NSString(cString: ivar_getTypeEncoding(ivar!)!, encoding: String.Encoding.utf8.rawValue)
            
            propertys[((ivarName ?? "") as String)] = (ivarType as String?) ?? "未知"
        }
        return propertys.keys.contains(property)
    }
    
    private struct UIAlertControllerRuntimeKey {
        
        static let wy_alertWindow = UnsafeRawPointer(bitPattern: "wy_alertWindow".hashValue)!
    }
    
    private var wy_alertWindow: UIWindow? {
        
        get {
            var showWindow: UIWindow? = objc_getAssociatedObject(self, UIAlertControllerRuntimeKey.wy_alertWindow) as? UIWindow
            
            if showWindow == nil {
                
                showWindow = UIWindow(frame: UIScreen.main.bounds)
                showWindow!.rootViewController = UIViewController()
                objc_setAssociatedObject(self, UIAlertControllerRuntimeKey.wy_alertWindow, showWindow, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            showWindow?.makeKeyAndVisible()
            
            return showWindow
        }
    }
    
    private func wy_sharedAppDelegate() -> UIApplicationDelegate {
        return UIApplication.shared.delegate!
    }
}
