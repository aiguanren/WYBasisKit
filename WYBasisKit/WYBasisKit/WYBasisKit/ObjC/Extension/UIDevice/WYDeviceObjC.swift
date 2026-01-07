//
//  UIDeviceObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/6.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 设备振动模式
@objc(WYVibrationStyle)
@frozen public enum WYVibrationStyleObjC: Int {
    /// 系统震动（强烈）
    case system = 0
    /// 轻
    case light
    /// 中
    case medium
    /// 重
    case heavy
    /// 柔和
    case soft
    /// 生硬
    case rigid
    /// 成功提示
    case success
    /// 警告提示
    case warning
    /// 错误提示
    case error
}

@objc public extension UIDevice {
    
    /// 状态栏高度
    @objc(wy_statusBarHeight)
    static var wy_statusBarHeightObjC: CGFloat {
        return UIDevice.wy_statusBarHeight
    }
    
    /// 导航栏安全区域高度
    @objc(wy_navBarSafetyZone)
    static var wy_navBarSafetyZoneObjC: CGFloat {
        return UIDevice.wy_navBarSafetyZone
    }
    
    /// 导航栏高度
    @objc(wy_navBarHeight)
    static var wy_navBarHeightObjC: CGFloat {
        return UIDevice.wy_navBarHeight
    }
    
    /// 导航视图高度（状态栏+导航栏）
    @objc(wy_navViewHeight)
    static var wy_navViewHeightObjC: CGFloat {
        return UIDevice.wy_navViewHeight
    }
    
    /// tabBar安全区域高度
    @objc(wy_tabbarSafetyZone)
    static var wy_tabbarSafetyZoneObjC: CGFloat {
        return UIDevice.wy_tabbarSafetyZone
    }
    
    /// tabBar高度(含安全区域高度)
    @objc(wy_tabBarHeight)
    static var wy_tabBarHeightObjC: CGFloat {
        return UIDevice.wy_tabBarHeight
    }
    
    /// 屏幕宽
    @objc(wy_screenWidth)
    static var wy_screenWidthObjC: CGFloat {
        return UIDevice.wy_screenWidth
    }
    
    /// 屏幕高
    @objc(wy_screenHeight)
    static var wy_screenHeightObjC: CGFloat {
        return UIDevice.wy_screenHeight
    }
    
    /// 屏幕宽度比率
    @objc(wy_screenWidthRatio)
    static func wy_screenWidthRatioObjC() -> CGFloat {
        return wy_screenWidthRatioObjC(WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc(wy_screenWidthRatio:)
    static func wy_screenWidthRatioObjC(_ pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIDevice.wy_screenWidthRatio(WYScreenPixels(width: pixels.width, height: pixels.height))
    }
    
    /// 屏幕高度比率
    @objc(wy_screenHeightRatio)
    static func wy_screenHeightRatioObjC() -> CGFloat {
        return wy_screenHeightRatioObjC(WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc(wy_screenHeightRatio:)
    static func wy_screenHeightRatioObjC(_ pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIDevice.wy_screenHeightRatio(WYScreenPixels(width: pixels.width, height: pixels.height))
    }
    
    /// 屏幕宽度比率转换
    @objc(wy_screenWidth:)
    static func wy_screenWidthObjC(_ ratioValue: CGFloat) -> CGFloat {
        return wy_screenWidthObjC(ratioValue, pixels: WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc(wy_screenWidth:pixels:)
    static func wy_screenWidthObjC(_ ratioValue: CGFloat, pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIDevice.wy_screenWidth(ratioValue, WYScreenPixels(width: pixels.width, height: pixels.height))
    }
    
    /// 屏幕高度比率转换
    @objc(wy_screenHeight:)
    static func wy_screenHeightObjC(_ ratioValue: CGFloat) -> CGFloat {
        return wy_screenHeightObjC(ratioValue, pixels: WYBasisKitConfigObjC.defaultScreenPixels)
    }
    @objc(wy_screenHeight:pixels:)
    static func wy_screenHeightObjC(_ ratioValue: CGFloat, pixels: WYScreenPixelsObjC = WYBasisKitConfigObjC.defaultScreenPixels) -> CGFloat {
        return UIDevice.wy_screenHeight(ratioValue, WYScreenPixels(width: pixels.width, height: pixels.height))
    }
    
    /// 设备型号
    @objc(wy_deviceName)
    static var wy_deviceNameObjC: String {
        return UIDevice.wy_deviceName
    }
    
    /// 系统名称
    @objc(wy_systemName)
    static var wy_systemNameObjC: String {
        return UIDevice.wy_systemName
    }
    
    /// 系统版本号
    @objc(wy_systemVersion)
    static var wy_systemVersionObjC: String {
        return UIDevice.wy_systemVersion
    }
    
    /// 是否是iPhone系列
    @objc(wy_iPhoneSeries)
    static var wy_iPhoneSeriesObjC: Bool {
        return UIDevice.wy_iPhoneSeries
    }
    
    /// 是否是iPad系列
    @objc(wy_iPadSeries)
    static var wy_iPadSeriesObjC: Bool {
        return UIDevice.wy_iPadSeries
    }
    
    /// 是否是模拟器
    @objc(wy_simulatorSeries)
    static var wy_simulatorSeriesObjC: Bool {
        return UIDevice.wy_simulatorSeries
    }
    
    ///获取CPU核心数
    @objc(wy_numberOfCPUCores)
    static var wy_numberOfCPUCoresObjC: Int {
        return UIDevice.wy_numberOfCPUCores
    }
    
    ///获取CPU类型
    @objc(wy_cpuType)
    static var wy_cpuTypeObjC: String {
        return UIDevice.wy_cpuType
    }
    
    /// UUID (注意：UUID并不是唯一不变的)
    @objc(wy_uuid)
    static var wy_uuidObjC: String {
        return UIDevice.wy_uuid
    }
    
    /// 是否是全屏手机
    @objc(wy_isFullScreen)
    static var wy_isFullScreenObjC: Bool {
        return UIDevice.wy_isFullScreen
    }
    
    /// 是否是传入的分辨率
    @objc static func wy_resolutionRatio(with horizontal: CGFloat, vertical: CGFloat) -> Bool {
        return UIDevice.wy_resolutionRatio(horizontal: horizontal, vertical: vertical)
    }
    
    /// 是否是竖屏模式
    @objc(wy_verticalScreen)
    static var wy_verticalScreenObjC: Bool {
        return UIDevice.wy_verticalScreen
    }
    
    /// 是否是横屏模式
    @objc(wy_horizontalScreen)
    static var wy_horizontalScreenObjC: Bool {
        return UIDevice.wy_horizontalScreen
    }
    
    /// 获取运营商IP地址
    @objc(wy_carrierIP)
    static var wy_carrierIPObjC: String {
        return UIDevice.wy_carrierIP
    }
    
    /// 获取 Wifi IP地址
    @objc(wy_wifiIP)
    static var wy_wifiIPObjC: String {
        return UIDevice.wy_wifiIP
    }
    
    /// 当前电池健康度
    @objc(wy_batteryLevel)
    static var wy_batteryLevelObjC: CGFloat {
        return UIDevice.wy_batteryLevel
    }
    
    /// 磁盘总大小
    @objc(wy_totalDiskSize)
    static var wy_totalDiskSizeObjC: String {
        return UIDevice.wy_totalDiskSize
    }
    
    /// 磁盘可用大小
    @objc(wy_availableDiskSize)
    static var wy_availableDiskSizeObjC: String {
        return UIDevice.wy_availableDiskSize
    }
    
    /// 磁盘已使用大小
    @objc(wy_usedDiskSize)
    static var wy_usedDiskSizeObjC: String {
        return UIDevice.wy_usedDiskSize
    }
    
    /// 旋转屏幕，设置界面方向，支持重力感应切换(默认竖屏)
    @objc(wy_setInterfaceOrientation)
    static var wy_setInterfaceOrientationObjC: UIInterfaceOrientationMask {
        set(newValue) {
            UIDevice.wy_setInterfaceOrientation = newValue
        }
        get {
            return UIDevice.wy_setInterfaceOrientation
        }
    }
    
    /// 获取当前设备屏幕方向(只会出现 portrait、landscapeLeft、landscapeRight、portraitUpsideDown 四种情况)
    @objc(wy_currentInterfaceOrientation)
    static var wy_currentInterfaceOrientationObjC: UIInterfaceOrientationMask {
        return UIDevice.wy_currentInterfaceOrientation
    }
    
    /**
     *  设备震动一次
     *  @param style   震动风格
     */
    @objc static func wy_vibrate(with style: WYVibrationStyleObjC) {
        let style: WYVibrationStyle = WYVibrationStyle(rawValue: style.rawValue) ?? .system
        UIDevice.wy_vibrate(style)
    }
    
    /**
     *  设备连续震动
     *  @param style         震动风格
     *  @param repeatCount   重复次数
     *  @param interval      间隔（秒）
     */
    @objc static func wy_vibrate(with style: WYVibrationStyleObjC, repeatCount: Int, interval: TimeInterval) {
        
        let style: WYVibrationStyle = WYVibrationStyle(rawValue: style.rawValue) ?? .system
        UIDevice.wy_vibrate(style, repeatCount: repeatCount, interval: interval)
    }
}
