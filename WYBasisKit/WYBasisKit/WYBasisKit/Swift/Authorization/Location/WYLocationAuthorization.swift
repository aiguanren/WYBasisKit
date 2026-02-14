//
//  WYLocationAuthorization.swift
//  WYBasisKit
//
//  Created by guanren on 2026/2/13.
//

import UIKit
import Foundation
import CoreLocation
import ObjectiveC.runtime

/// 定位权限KEY（WhenInUse 必填，Always 额外需要）
public let locationWhenInUseKey: String = "NSLocationWhenInUseUsageDescription"
public let locationAlwaysKey: String = "NSLocationAlwaysAndWhenInUseUsageDescription"

/// 定位授权类型
public enum WYLocationAuthorizationStyle: Int {
    
    /// 仅使用中（推荐，大多数场景足够，隐私&省电更好）
    case whenInUse = 0
    
    /// 始终（仅在必须后台定位时使用，如导航、签到）
    case always
}

/// 定位授权代理协议
@objc public protocol WYLocationAuthorizationDelegate {
    
    /// 授权状态变化（权限请求完成、精度变化、授权被撤销等）
    @objc(wy_locationAuthorizationDidChange:fullAccuracy:status:)
    optional func wy_locationAuthorizationDidChange(authorized: Bool, fullAccuracy: Bool, status: CLAuthorizationStatus)
    
    /// 接收到新的位置更新
    @objc(wy_locationDidUpdate:)
    optional func wy_locationDidUpdate(location: CLLocation)
    
    /// 接收到新的显著位置变化更新
    @objc(wy_locationDidUpdateSignificant:)
    optional func wy_locationDidUpdateSignificant(location: CLLocation)
    
    /// 进入监控区域
    @objc(wy_locationDidEnterRegion:)
    optional func wy_locationDidEnterRegion(region: CLRegion)
    
    /// 离开监控区域
    @objc(wy_locationDidExitRegion:)
    optional func wy_locationDidExitRegion(region: CLRegion)
    
    /// 接收到新的方向更新
    @objc(wy_locationDidUpdateHeading:)
    optional func wy_locationDidUpdateHeading(heading: CLHeading)
    
    /// 定位出现错误（例如权限被撤销、定位服务关闭、超时等）
    @objc(wy_locationDidFail:)
    optional func wy_locationDidFail(error: Error)
    
    /// 区域监控错误
    @objc(wy_locationMonitoringDidFail:error:)
    optional func wy_locationMonitoringDidFail(region: CLRegion?, error: Error)
}

/// 定位授权与管理工具
public final class WYLocationAuthorization: NSObject {
    
    /// 代理
    public weak var delegate: WYLocationAuthorizationDelegate?
    
    /// 唯一初始化方法
    public init(style: WYLocationAuthorizationStyle = .whenInUse) {
        super.init()
        self.authorizationStyle = style
    }
    
    /**
     * 请求定位权限
     * @param showAlert: 未授权时是否弹出跳转设置弹窗
     * @param completion: 权限请求完成后的单次回调
     */
    public func wy_authorizeLocationAccess(showAlert: Bool = true, completion: ((Bool, Bool) -> Void)? = nil) {
        // 检查 Info.plist 配置
        guard Bundle.main.infoDictionary?[locationWhenInUseKey] as? String != nil else {
            WYLogManager.output("请先在Info.plist中添加key：\(locationWhenInUseKey)")
            completion?(false, false)
            delegate?.wy_locationAuthorizationDidChange?(authorized: false, fullAccuracy: false, status: .notDetermined)
            return
        }
        
        if authorizationStyle == .always {
            guard Bundle.main.infoDictionary?[locationAlwaysKey] as? String != nil else {
                WYLogManager.output("请先在Info.plist中添加key：\(locationAlwaysKey)")
                completion?(false, false)
                delegate?.wy_locationAuthorizationDidChange?(authorized: false, fullAccuracy: false, status: .notDetermined)
                return
            }
        }
        
        setupLocationManagerIfNeeded()
        
        let authStatus = currentAuthorizationStatus()
        let isAuthorized = authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse
        let fullAccuracy = currentFullAccuracy()
        
        completion?(isAuthorized, fullAccuracy)
        delegate?.wy_locationAuthorizationDidChange?(authorized: isAuthorized, fullAccuracy: fullAccuracy, status: authStatus)
        
        if authStatus == .notDetermined && !isRequestingPermission {
            requestPermission(showAlert: showAlert)
        } else if !isAuthorized {
            showLocationAuthorizeAlert(show: showAlert)
        }
    }
    
    /// 开始更新位置
    public func startUpdatingLocation(
        desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        distanceFilter: CLLocationDistance = kCLDistanceFilterNone,
        allowsBackground: Bool = false,
        showAlert: Bool = true
    ) {
        setupLocationManagerIfNeeded()
        
        let status = currentAuthorizationStatus()
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        
        if isAuthorized {
            configureAndStartUpdating(
                desiredAccuracy: desiredAccuracy,
                distanceFilter: distanceFilter,
                allowsBackground: allowsBackground
            )
        } else {
            wy_authorizeLocationAccess(showAlert: showAlert) { [weak self] authorized, _ in
                guard let self else { return }
                if authorized {
                    self.configureAndStartUpdating(
                        desiredAccuracy: desiredAccuracy,
                        distanceFilter: distanceFilter,
                        allowsBackground: allowsBackground
                    )
                } else {
                    
                    showLocationAuthorizeAlert(show: showAlert)
                    
                    let error = NSError(domain: "WYLocationAuthorization", code: -1, userInfo: [NSLocalizedDescriptionKey: WYLocalized("定位权限被限制", table: WYBasisKitConfig.kitLocalizableTable)])
                    
                    self.delegate?.wy_locationDidFail?(error: error)
                }
            }
        }
    }
    
    /// 停止位置更新
    public func stopUpdatingLocation() {
        locationManager?.stopUpdatingLocation()
    }
    
    /// 开始显著位置变化监听
    public func startMonitoringSignificantLocationChanges(showAlert: Bool = true) {
        setupLocationManagerIfNeeded()
        
        let status = currentAuthorizationStatus()
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        
        if isAuthorized {
            if authorizationStyle == .always || status == .authorizedAlways {
                locationManager?.startMonitoringSignificantLocationChanges()
            } else {
                locationManager?.requestAlwaysAuthorization()
            }
        } else {
            wy_authorizeLocationAccess(showAlert: showAlert) { [weak self] authorized, _ in
                guard let self, authorized else { return }
                self.startMonitoringSignificantLocationChanges()
            }
        }
    }
    
    /// 停止显著位置变化监听
    public func stopMonitoringSignificantLocationChanges() {
        locationManager?.stopMonitoringSignificantLocationChanges()
    }
    
    /// 开始监控指定区域
    public func startMonitoring(_ region: CLRegion, showAlert: Bool = true) {
        setupLocationManagerIfNeeded()
        
        let status = currentAuthorizationStatus()
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        
        if isAuthorized {
            if status == .authorizedAlways {
                locationManager?.startMonitoring(for: region)
            } else {
                locationManager?.requestAlwaysAuthorization()
            }
        } else {
            wy_authorizeLocationAccess(showAlert: showAlert) { [weak self] authorized, _ in
                guard let self, authorized else { return }
                self.startMonitoring(region)
            }
        }
    }
    
    /// 停止监控指定区域
    public func stopMonitoring(_ region: CLRegion) {
        locationManager?.stopMonitoring(for: region)
    }
    
    /// 开始方向更新
    public func startUpdatingHeading(desiredAccuracy: CLLocationDirectionAccuracy = kCLLocationAccuracyBest, showAlert: Bool = true) {
        setupLocationManagerIfNeeded()
        
        let status = currentAuthorizationStatus()
        let isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
        
        if isAuthorized {
            locationManager?.headingFilter = desiredAccuracy
            locationManager?.startUpdatingHeading()
        } else {
            wy_authorizeLocationAccess(showAlert: showAlert) { [weak self] authorized, _ in
                guard let self, authorized else { return }
                self.startUpdatingHeading(desiredAccuracy: desiredAccuracy)
            }
        }
    }
    
    /// 停止方向更新
    public func stopUpdatingHeading() {
        locationManager?.stopUpdatingHeading()
    }
    
    /// 释放所有资源（强烈建议在不再使用时调用，例如 viewController deinit 或手动释放时）
    public func releaseAll() {
        
        // 停止所有定位服务
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager?.stopUpdatingHeading()
        
        // 停止所有区域监控
        if let regions = locationManager?.monitoredRegions {
            for region in regions {
                locationManager?.stopMonitoring(for: region)
            }
        }
        
        // 清空 delegate 防止循环引用
        locationManager?.delegate = nil
        
        // 释放 manager（关联对象会自动清理，但这里显式置 nil）
        locationManager = nil
        
        // 清理关联对象（可选，但显式清理更安全）
        objc_setAssociatedObject(self, &WYAssociatedKeys.wy_locationManagerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isRequestingPermissionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        // authorizationStyle 不需要清理（它是值类型）
        
        // 清空外部 delegate（防止持有外部对象）
        delegate = nil
    }
    
    deinit {
        releaseAll()
    }
}

private extension WYLocationAuthorization {
    
    struct WYAssociatedKeys {
        static var wy_locationAuthorizationStyleKey: UInt8 = 0
        static var wy_locationManagerKey: UInt8 = 0
        static var wy_isRequestingPermissionKey: UInt8 = 0
    }
    
    /// 授权类型
    var authorizationStyle: WYLocationAuthorizationStyle {
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_locationAuthorizationStyleKey) as? WYLocationAuthorizationStyle ?? .whenInUse
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_locationAuthorizationStyleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 定位管理器
    var locationManager: CLLocationManager? {
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_locationManagerKey) as? CLLocationManager
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_locationManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否正在请求权限
    var isRequestingPermission: Bool {
        get {
            objc_getAssociatedObject(self, &WYAssociatedKeys.wy_isRequestingPermissionKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &WYAssociatedKeys.wy_isRequestingPermissionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setupLocationManagerIfNeeded() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
    }
    
    func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager?.authorizationStatus ?? .notDetermined
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    func currentFullAccuracy() -> Bool {
        if #available(iOS 14.0, *) {
            return locationManager?.accuracyAuthorization == .fullAccuracy
        }
        // iOS 13 及以下默认视为 full accuracy
        return true
    }
    
    func requestPermission(showAlert: Bool) {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        
        if authorizationStyle == .whenInUse {
            locationManager?.requestWhenInUseAuthorization()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func configureAndStartUpdating(
        desiredAccuracy: CLLocationAccuracy,
        distanceFilter: CLLocationDistance,
        allowsBackground: Bool
    ) {
        guard let manager = locationManager else { return }
        
        // 处理 always 权限升级
        if authorizationStyle == .always {
            if #available(iOS 14.0, *) {
                if manager.authorizationStatus == .authorizedWhenInUse {
                    manager.requestAlwaysAuthorization()
                    return  // 等 delegate 回调确认后再启动
                }
            } else {
                manager.requestAlwaysAuthorization()
                return
            }
        }
        
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
        manager.allowsBackgroundLocationUpdates = allowsBackground && authorizationStyle == .always
        manager.pausesLocationUpdatesAutomatically = false
        
        manager.startUpdatingLocation()
    }
    
    func showLocationAuthorizeAlert(show: Bool) {
        guard show else { return }
        
        let message: String = WYLocalized("App没有访问定位的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable)
        
        UIAlertController.wy_show(
            message: message,
            actions: [
                WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable)
            ]
        ) { actionStr, _ in
            guard actionStr == WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable) else { return }
            DispatchQueue.main.async {
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WYLocationAuthorization: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        isRequestingPermission = false
        
        let authStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authStatus = manager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }
        
        let isAuthorized = authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse
        
        var fullAccuracy = false
        if #available(iOS 14.0, *) {
            fullAccuracy = manager.accuracyAuthorization == .fullAccuracy
        }
        
        delegate?.wy_locationAuthorizationDidChange?(authorized: isAuthorized, fullAccuracy: fullAccuracy, status: authStatus)
        
        if authorizationStyle == .always && authStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        delegate?.wy_locationDidUpdate?(location: location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        delegate?.wy_locationDidUpdateHeading?(heading: heading)
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            delegate?.wy_locationDidEnterRegion?(region: region)
        case .outside:
            delegate?.wy_locationDidExitRegion?(region: region)
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        delegate?.wy_locationMonitoringDidFail?(region: region, error: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.wy_locationDidFail?(error: error)
    }
}
