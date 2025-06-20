//
//  UITextField.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

public extension UITextField {
    
    /// 占位文字颜色
    var wy_placeholderColor: UIColor {
        
        set(newValue) {
            
            let ivar: Ivar = class_getInstanceVariable(UITextField.classForCoder(), "_placeholderLabel")!

            let placeholderLabel: UILabel = object_getIvar(self, ivar) as? UILabel ?? UILabel()
            placeholderLabel.textColor = newValue
        }
        get {
            
            let ivar: Ivar = class_getInstanceVariable(UITextField.classForCoder(), "_placeholderLabel")!

            let placeholderLabel: UILabel = object_getIvar(self, ivar) as? UILabel ?? UILabel()
            
            return placeholderLabel.textColor
        }
    }
    
    /// 占位label
    var wy_placeholderLabel: UILabel {
        
        let ivar: Ivar = class_getInstanceVariable(UITextField.classForCoder(), "_placeholderLabel")!
        
        return object_getIvar(self, ivar) as? UILabel ?? UILabel()
    }
}
