//
//  WYBasisKitConfigObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/11/21.
//  Copyright © 2023 官人. All rights reserved.
//  

import Foundation

/// 屏幕分辨率
@objc(WYScreenPixels)
@objcMembers public class WYScreenPixelsObjC: NSObject {
    
    /// 屏幕宽
    @objc public var width: Double = 0
    
    /// 屏幕高
    @objc public var height: Double = 0
    
    @objc public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

/// 最大最小分辨比率
@objc(WYRatio)
@objcMembers public class WYRatioObjC: NSObject {
    
    /// 最小比率
    @objc public var min: Double = 0
    
    /// 最大比率
    @objc public var max: Double = 0
    
    @objc public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

@objc(WYBasisKitConfig)
@objcMembers public class WYBasisKitConfigObjC: NSObject {
    
    /// 设置默认屏幕分辨率(建议根据设计图的分辨率设置)
    @objc public static var defaultScreenPixels: WYScreenPixelsObjC {
        get {
            let pixels = WYBasisKitConfig.defaultScreenPixels
            return WYScreenPixelsObjC(width: pixels.width, height: pixels.height)
        }
        set {
            WYBasisKitConfig.defaultScreenPixels = WYScreenPixels(width: newValue.width, height: newValue.height)
        }
    }
    
    /// 设置字号适配的最大最小比率数
    @objc public static var fontRatio: WYRatioObjC {
        get {
            let ratio = WYBasisKitConfig.fontRatio
            return WYRatioObjC(min: ratio.min, max: ratio.max)
        }
        set {
            WYBasisKitConfig.fontRatio = WYRatio(min: newValue.min, max: newValue.max)
        }
    }
    
    /// 设置屏幕分辨率宽度比最大最小比率数
    @objc public static var screenWidthRatio: WYRatioObjC {
        get {
            let ratio = WYBasisKitConfig.screenWidthRatio
            return WYRatioObjC(min: ratio.min, max: ratio.max)
        }
        set {
            WYBasisKitConfig.screenWidthRatio = WYRatio(min: newValue.min, max: newValue.max)
        }
    }
    
    /// 设置屏幕分辨率高度比最大最小比率数
    @objc public static var screenHeightRatio: WYRatioObjC {
        get {
            let ratio = WYBasisKitConfig.screenHeightRatio
            return WYRatioObjC(min: ratio.min, max: ratio.max)
        }
        set {
            WYBasisKitConfig.screenHeightRatio = WYRatio(min: newValue.min, max: newValue.max)
        }
    }
    
    /// 设置国际化语言读取表(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)
    @objc public static var localizableTable: String {
        get { return WYBasisKitConfig.localizableTable }
        set { WYBasisKitConfig.localizableTable = newValue }
    }
    
    /// 设置WYBasisKit内部国际化语言读取表，设置后需自己将WYLocalizable表中的国际化文本写入自定义的表中(如果有Bundle，则要求Bundle名与表名一致，否则会读取失败)，默认使用自带的表：WYLocalizable
    @objc public static var kitLocalizableTable: String {
        get { return WYBasisKitConfig.kitLocalizableTable }
        set { WYBasisKitConfig.kitLocalizableTable = newValue }
    }
}

@objc(WYProjectInfo)
@objcMembers public class WYProjectInfoObjC: NSObject {
    
    /// 获取项目名称
    @objc public static var projectName: String {
        return WYProjectInfo.projectName
    }
    
    /// 获取AppStore名称
    @objc public static var appStoreName: String {
        return WYProjectInfo.appStoreName
    }
    
    /// 获取BundleID
    @objc public static var appIdentifier: String {
        return WYProjectInfo.appIdentifier
    }
    
    /// 获取AppStore版本号
    @objc public static var appStoreVersion: String {
        return WYProjectInfo.appStoreVersion
    }
    
    /// 获取Build版本号
    @objc public static var appBuildVersion: String {
        return WYProjectInfo.appBuildVersion
    }
    
    /// 判断Xcode工程是Swift还是Objective-C(true为Swift，否则为Objective-C)
    @objc public static var isSwiftProject: Bool {
        return WYProjectInfo.isSwiftProject
    }
}
