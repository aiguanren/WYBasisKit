//
//  WYLocationAuthorization+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation
import CoreLocation
import UIKit

extension WYLocationAuthorization {

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
        return locationManager?.authorizationStatus ?? .notDetermined
    }

    func currentFullAccuracy() -> Bool {
        return locationManager?.accuracyAuthorization == .fullAccuracy
    }

    func requestPermission() {
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
            if manager.authorizationStatus == .authorizedWhenInUse {
                manager.requestAlwaysAuthorization()
                return  // 等 delegate 回调确认后再启动
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
            Task { @MainActor in
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
