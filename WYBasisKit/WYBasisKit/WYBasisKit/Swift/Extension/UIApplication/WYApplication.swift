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
        // 尝试找到前台 active scene 的 keyWindow
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // 如果没有找到 active scene 的 keyWindow，则找所有 scene 中的 keyWindow
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // 最后再找第一个非隐藏 window
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { !$0.isHidden }) {
            return window
        }
        
        // 都没有就创建一个 window
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

