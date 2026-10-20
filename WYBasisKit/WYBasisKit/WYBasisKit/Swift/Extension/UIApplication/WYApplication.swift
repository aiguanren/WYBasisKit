//
//  UIApplication.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

extension UIApplication: @retroactive UIApplicationDelegate {
    
    /// 获取当前正在显示的 keyWindow 的 windowScene
    public var wy_keyWindowScene: UIWindowScene {
        
        // 尝试从 keyWindow 获取
        if let windowScene = wy_keyWindow.windowScene {
            return windowScene
        }
        
        // keyWindow 没挂场景的兜底窗口时，取第一个已连接的场景兜底
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            return windowScene
        }
        
        // 都没有找到，抛出fatalError
        fatalError("❌ 错误：没有找到可用的 UIWindowScene，请确保应用已正确初始化并显示了窗口。")
    }
    
    /// 获取当前正在显示的 keyWindow
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
        
        // 场景里已有窗口但都还没显示(启动最早期 rootVC 初始化阶段)，取第一个窗口
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first {
            return window
        }
        
        // 场景已连接但窗口还没建，创建挂靠第一个场景的全屏窗口(会被场景持有，之后走前面的分支就能找到)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            return UIWindow(windowScene: windowScene)
        }
        
        // 连场景都还没连接的启动极早期，创建游离全屏窗口(UIWindow() 默认取主屏尺寸)
        return UIWindow()
    }
    
    /// 切换为深色或浅色模式
    public func wy_switchAppDisplayBrightness(style: UIUserInterfaceStyle) {
        // 优先设置 keyWindow
        wy_keyWindow.rootViewController?.overrideUserInterfaceStyle = style
        
        // 多 Scene 支持：遍历所有活跃 Scene，统一设置
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .forEach { scene in
                scene.windows.forEach { window in
                    window.rootViewController?.overrideUserInterfaceStyle = style
                    
                    // 同时设置 window 级别
                    if window.overrideUserInterfaceStyle != style {
                        window.overrideUserInterfaceStyle = style
                    }
                }
            }
    }
    
    /// 全局关闭暗夜模式
    public func wy_closeDarkMode() {
        // 优先使用 keyWindow 的 rootViewController，更可靠
        if let rootVC = wy_keyWindow.rootViewController {
            rootVC.overrideUserInterfaceStyle = .light
        } else {
            delegate?.window??.overrideUserInterfaceStyle = .light
        }
        
        // 多 Scene 支持：遍历所有 Scene 统一关闭暗夜模式
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .forEach { scene in
                scene.windows.forEach { window in
                    // 设置 window 级别
                    window.overrideUserInterfaceStyle = .light
                    
                    // 设置 rootViewController 级别
                    window.rootViewController?.overrideUserInterfaceStyle = .light
                    
                    // 递归设置所有子控制器
                    window.rootViewController?.children.forEach {
                        $0.overrideUserInterfaceStyle = .light
                    }
                }
            }
    }
}
