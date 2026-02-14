//
//  WYLocationAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by guanren on 2026/2/13.
//

import UIKit
import CoreLocation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// 定位授权类型
@objc(WYLocationAuthorizationStyle)
public enum WYLocationAuthorizationStyleObjC: Int {
    
    /// 仅使用中（推荐，大多数场景足够，隐私&省电更好）
    case whenInUse = 0
    
    /// 始终（仅在必须后台定位时使用，如导航、签到）
    case always
}

/// 定位授权与管理工具
public extension WYLocationAuthorization {
    
    /// 代理
    @objc(delegate)
    weak var delegateObjC: WYLocationAuthorizationDelegate? {
        get { return delegate }
        set { delegate = newValue }
    }
    
    /// 唯一初始化方法
    @objc convenience init(style: WYLocationAuthorizationStyleObjC = .whenInUse) {
        self.init(style: WYLocationAuthorizationStyle(rawValue: style.rawValue) ?? .whenInUse)
    }
    
    /**
     * 请求定位权限
     * @param showAlert: 未授权时是否弹出跳转设置弹窗
     * @param completion: 权限请求完成后的单次回调
     */
    @objc(wy_authorizeLocationAccess:completion:)
    func wy_authorizeLocationAccessObjC(showAlert: Bool = true, completion: ((Bool, Bool) -> Void)? = nil) {
        wy_authorizeLocationAccess(showAlert: showAlert, completion: completion)
    }
    
    /// 开始更新位置
    @objc(startUpdatingLocation:distanceFilter:allowsBackground:showAlert:)
    func startUpdatingLocationObjC(
        desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        distanceFilter: CLLocationDistance = kCLDistanceFilterNone,
        allowsBackground: Bool = false,
        showAlert: Bool = true
    ) {
        startUpdatingLocation(desiredAccuracy: desiredAccuracy, distanceFilter: distanceFilter, allowsBackground: allowsBackground, showAlert: showAlert)
    }
    
    /// 停止位置更新
    @objc(stopUpdatingLocation)
    func stopUpdatingLocationObjC() {
        stopUpdatingLocation()
    }
    
    /// 开始显著位置变化监听
    @objc(startMonitoringSignificantLocationChanges:)
    func startMonitoringSignificantLocationChangesObjC(showAlert: Bool = true) {
        startMonitoringSignificantLocationChanges(showAlert: showAlert)
    }
    
    /// 停止显著位置变化监听
    @objc(stopMonitoringSignificantLocationChanges)
    func stopMonitoringSignificantLocationChangesObjC() {
        stopMonitoringSignificantLocationChanges()
    }
    
    /// 开始监控指定区域
    @objc(startMonitoring:showAlert:)
    func startMonitoring(region: CLRegion, showAlert: Bool = true) {
        startMonitoring(region, showAlert: showAlert)
    }
    
    /// 停止监控指定区域
    @objc(stopMonitoring:)
    func stopMonitoringObjC(region: CLRegion) {
        stopMonitoring(region)
    }
    
    /// 开始方向更新
    @objc(startUpdatingHeading:showAlert:)
    func startUpdatingHeadingObjC(desiredAccuracy: CLLocationDirectionAccuracy = kCLLocationAccuracyBest, showAlert: Bool = true) {
        startUpdatingHeading(desiredAccuracy: desiredAccuracy, showAlert: showAlert)
    }
    
    /// 停止方向更新
    @objc(stopUpdatingHeading)
    func stopUpdatingHeadingObjC() {
        stopUpdatingHeading()
    }
    
    /// 释放所有资源（强烈建议在不再使用时调用，例如 viewController deinit 或手动释放时）
    @objc(releaseAll)
    func releaseAllObjC() {
        releaseAll()
    }
}
