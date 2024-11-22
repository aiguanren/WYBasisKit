//
//  UIApplication.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

extension UIApplication: UIApplicationDelegate {
    
    /// 获取当前当前正在显示的window
    public class var wy_sharedWindow: UIWindow {
        get {
            if #available(iOS 13.0, *) {
                let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.first
                return window!
            } else {
                return UIApplication.shared.windows.first!
            }
        }
    }
    
    /// 切换为深色或浅色模式
    @available(iOS 13.0, *)
    public func wy_switchAppDisplayBrightness(style: UIUserInterfaceStyle) {
        delegate!.window!?.rootViewController?.overrideUserInterfaceStyle = style
    }
    
    /// 全局关闭暗夜模式
    @available(iOS 13.0, *)
    public func wy_closeDarkModel() {
        delegate!.window!?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
    }
}
