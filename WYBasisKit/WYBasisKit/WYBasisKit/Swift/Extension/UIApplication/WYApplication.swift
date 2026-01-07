//
//  UIApplication.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

extension UIApplication: @retroactive UIApplicationDelegate {
    
    /// 获取当前当前正在显示的 keyWindow 的 windowScene
    public var wy_keyWindowScene: UIWindowScene {
        
        // 尝试从 keyWindow 获取
        if let windowScene = wy_keyWindow.windowScene {
            return windowScene
        }
        
        // 都没有找到，抛出fatalError
        fatalError("❌ 错误：没有找到可用的 UIWindowScene，请确保应用已正确初始化并显示了窗口。")
    }
    
    /// 获取当前当前正在显示的 keyWindow
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
        
        // 都没有找到，抛出fatalError
        fatalError("❌ 错误：没有找到可用的 UIWindow，请确保应用已正确初始化并显示了窗口。")
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

