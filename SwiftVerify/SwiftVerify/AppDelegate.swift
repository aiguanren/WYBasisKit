//
//  AppDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
@_exported import WYBasisKitSwift

protocol AppEventDelegate: AnyObject {
    func didShowBannerView(data: String)
}

enum AppEvent {
    static let buttonDidMove = "button starts to move downwards"
    static let buttonDidReturn = "button starts to return to its original position"
    static let didShowBannerView = "didShowBannerView"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 屏蔽控制台约束输出
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        WYBasisKitConfig.defaultScreenPixels = WYScreenPixels(width: 375, height: 812)
        
        return true
    }
    
    /// 切换为深色或浅色模式
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.wy_switchAppDisplayBrightness(style: (WYLocalizableManager.currentLanguage() == .english) ? .dark : .light)
    }

    /// 屏幕旋转需要支持的方向
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIDevice.wy_currentInterfaceOrientation
    }
}

extension AppDelegate {
    
    class func shared() -> AppDelegate {
        
        return UIApplication.shared.delegate as! AppDelegate
    }
}

