//
//  UIApplication.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

extension UIApplication: @retroactive UIApplicationDelegate {
    
    /// 获取当前当前正在显示的window
    public var wy_keyWindow: UIWindow {
        if let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow(frame: UIScreen.main.bounds)
    }
    
    /// 切换为深色或浅色模式
    public func wy_switchAppDisplayBrightness(style: UIUserInterfaceStyle) {
        wy_keyWindow.rootViewController?.overrideUserInterfaceStyle = style
    }
    
    /// 全局关闭暗夜模式
    public func wy_closeDarkModel() {
        delegate?.window??.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
    }
}
