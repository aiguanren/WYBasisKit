//
//  WYBasisKitConfig.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/11/21.
//  Copyright © 2020 官人. All rights reserved.
//

/**
 * 可编译通过的特殊字符 𝟬 𝟭 𝟮 𝟯 𝟰 𝟱 𝟲 𝟳 𝟴 𝟵  ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉   ․﹒𝙭ｘ𝙓
 * 设备数据参考文库 https://blog.csdn.net/Scorpio_27/article/details/52297643
 */

import UIKit

/// 屏幕分辨率
public struct WYScreenPixels {
    /// 屏幕宽
    public var width: Double
    /// 屏幕高
    public var height: Double
    
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

/// 最大最小分辨比率
public struct WYRatio {
    
    /// 最小比率
    public var min: Double
    
    /// 最大比率
    public var max: Double
    
    public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

public struct WYBasisKitConfig {
    
    /// 设置默认屏幕分辨率
    public static var defaultScreenPixels: WYScreenPixels = WYScreenPixels(width: 390, height: 844)
    
    /// 设置字号适配的最大最小比率数
    public static var fontRatio: WYRatio = WYRatio(min: 0.5, max: 1.5)
    
    /// 导航控制器是否开启了液态玻璃效果
    public static var navigationBarIsLiquidGlass: Bool = false
    
    /// UITabbar是否开启了液态玻璃效果
    public static var tabBarIsLiquidGlass: Bool = false
    
    /// 设置屏幕分辨率宽度比最大最小比率数
    public static var screenWidthRatio: WYRatio = WYRatio(min: 0.5, max: 1.5)
    
    /// 设置屏幕分辨率高度比最大最小比率数
    public static var screenHeightRatio: WYRatio = WYRatio(min: 0.5, max: 1.5)
    
    /// 设置国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
    public static var localizableTable: String = ""
    
    /// 设置WYBasisKit内部国际化语言读取表，设置后需自己将WYLocalizable表中的国际化文本写入自定义的表中(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)，默认使用自带的表：WYLocalizable
    public static var kitLocalizableTable: String = "WYLocalizable"
}

public struct WYProjectInfo {
    
    /// 项目名字
    public static let projectName: String = Bundle.main.infoDictionary!["CFBundleName"] as? String ?? ""
    
    /// 项目APP名
    public static let appStoreName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    
    /// BundleID
    public static let appIdentifier: String = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    
    /// 应用 AppStore 版本号
    public static let appStoreVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    /// 应用Build版本号
    public static let appBuildVersion: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    /// 判断Xcode工程是Swift还是Objective-C(true为Swift，否则为Objective-C)
    public static var isSwiftProject: Bool {
        
        // 检查是否有 main.m 文件（OC项目有main.m，Swift项目没有）
        if Bundle.main.path(forResource: "main", ofType: "m") != nil {
            return false
        }
        
        // 检查 AppDelegate 类名特征（OC项目AppDelegate不包含模块名，Swift包含模块名）
        if let appDelegate = UIApplication.shared.delegate {
            let className = NSStringFromClass(type(of: appDelegate))
            if className.contains(".") {
                return true
            } else {
                return false
            }
        }

        // 如果前两个方法都无法确定，默认认为是Swift项目， 因为现代项目更倾向于使用Swift
        return true
    }
}
