//
//  AppDelegate.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/8/29.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit
import Kingfisher
import KingfisherWebP
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
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

    /// App主窗口
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 屏蔽控制台约束输出
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        WYBasisKitConfig.defaultScreenPixels = WYScreenPixels(width: 375, height: 812)
        
        // 全局设置KingfisherManager支持显示webp格式图片
        KingfisherManager.shared.defaultOptions += [
            .processor(WebPProcessor.default),
            .cacheSerializer(WebPSerializer.default)
        ]

        // 开启键盘管理(输入框自动带上完成工具条，点页面空白处收起键盘)
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        // 播放器区域不触发点外收回(键盘管理的窗口点按手势不与播放器单击抢事件)
        IQKeyboardManager.shared.touchResignedGestureIgnoreClasses.append(WYVideoPlayer.self)


        return true
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
