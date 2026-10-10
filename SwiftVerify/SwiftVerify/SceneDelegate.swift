//
//  SceneDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2026/10/2.
//  Copyright © 2026 官人. All rights reserved.
//

import UIKit

/// 场景生命周期代理
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// App主窗口
    var window: UIWindow?

    /// 场景建立时创建主窗口并加载Main.storyboard
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene: UIWindowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window?.makeKeyAndVisible()
        // 同步给AppDelegate
        AppDelegate.shared().window = window
    }

    /// 场景变的活跃了(依据当前语言切换深浅色主题，原AppDelegate的applicationDidBecomeActive场景化后不再回调故迁到这里)
    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.wy_switchAppDisplayBrightness(style: (WYLocalizableManager.currentLanguage() == .english) ? .dark : .light)
    }
}
