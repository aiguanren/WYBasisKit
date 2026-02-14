//
//  WYCameraAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import AVFoundation

/// 相机权限KEY
public let cameraKey: String = "NSCameraUsageDescription"

/// 检查相机权限
public func wy_authorizeCameraAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void?) {
    
    guard let _ = Bundle.main.infoDictionary?[cameraKey] as? String else {
        WYLogManager.output("请先在Info.plist中添加key：\(cameraKey)")
        handler(false)
        return
    }
    
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch authStatus {
    case .authorized:
        handler(true)
        
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    handler(true)
                } else {
                    wy_showCameraAuthorizeAlert(show: showAlert)
                    handler(false)
                }
            }
        }
        
    default:  // .denied / .restricted
        wy_showCameraAuthorizeAlert(show: showAlert)
        handler(false)
    }
    
    // 弹出相机授权提示
    func wy_showCameraAuthorizeAlert(show: Bool) {
        guard show else { return }
        
        let message = WYLocalized("App没有访问相机的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable)
        let cancel   = WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable)
        let settings = WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable)
        
        Task { @MainActor in
            UIAlertController.wy_show(message: message, actions: [cancel, settings]) { actionStr, _ in
                guard actionStr == settings else { return }
                if let url = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
