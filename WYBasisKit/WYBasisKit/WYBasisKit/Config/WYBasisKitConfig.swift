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
    
    /// 设置屏幕分辨率宽度比最大最小比率数
    public static var screenWidthRatio: WYRatio = WYRatio(min: 0.5, max: 1.5)
    
    /// 设置屏幕分辨率高度比最大最小比率数
    public static var screenHeightRatio: WYRatio = WYRatio(min: 0.5, max: 1.5)
    
    /// 设置国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
    public static var localizableTable: String = ""
    
    /// 设置WYBasisKit内部国际化语言读取表，设置后需自己将WYLocalizable表中的国际化文本写入自定义的表中(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)，默认使用自带的表：WYLocalizable
    public static var kitLocalizableTable: String = "WYLocalizable"
    
    /// Debug模式下是否打印日志
    public static var debugModeLog: Bool = true
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
}

/// DEBUG打印日志
public func wy_print(_ messages: Any..., file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
    if WYBasisKitConfig.debugModeLog == true {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let time = timeFormatter.string(from: Date())
        let message = messages.compactMap { "\($0)" }.joined(separator: " ")
        print("\n\(time) ——> \((file as NSString).lastPathComponent) ——> \(function) ——> line:\(line)\n\n\(message)\n\n\n")
    }
#endif
}
