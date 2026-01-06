//
//  UIApplicationObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/25.
//

import UIKit
#if WYBasisKit_Supports_ObjC
import WYBasisKitSwift
#endif

@objc extension UIApplication {
    
    /// 获取当前当前正在显示的window
    @objc(wy_keyWindow)
    public var wy_keyWindowObjC: UIWindow {
        return wy_keyWindow
    }
    
    /// 切换为深色或浅色模式
    @objc(wy_switchAppDisplayBrightness:)
    public func wy_switchAppDisplayBrightnessObjC(style: UIUserInterfaceStyle) {
        wy_switchAppDisplayBrightness(style: style)
    }
    
    /// 全局关闭暗夜模式
    @objc(wy_closeDarkModel)
    public func wy_closeDarkModelObjC() {
        wy_closeDarkModel()
    }
}
