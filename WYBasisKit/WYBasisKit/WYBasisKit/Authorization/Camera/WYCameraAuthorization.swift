//
//  WYCameraAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

/// 相机权限KEY
public let cameraKey: String = "NSCameraUsageDescription"

/// 检查相机权限
public func wy_authorizeCameraAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void?) {
    
    if let _ = Bundle.main.infoDictionary?[cameraKey] as? String {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .notDetermined:
            /// 用户尚未授权(弹出授权提示)
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    if status == .authorized {
                        /// 用户授权访问
                        handler(true)
                        return
                    }else {
                        /// App无权访问相机 用户已明确拒绝
                        wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问相机的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
                        handler(false)
                        return
                    }
                }
            }
            
        case .authorized:
            /// 可以访问
            handler(true)
            return
        default:
            /// App无权访问相机 用户已明确拒绝
            wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问相机的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
            handler(false)
            return
        }
        
    }else {
        WYLogManager.output("请先在Info.plist中添加key：\(cameraKey)")
        handler(false)
        return
    }
    
    // 弹出授权弹窗
    func wy_showAuthorizeAlert(show: Bool, message: String) {
        
        if show {
            UIAlertController.wy_show(message: message, actions: [WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable)]) { (actionStr, _) in
                
                DispatchQueue.main.async {
                    
                    if actionStr == WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable) {
                        
                        let settingUrl = URL(string: UIApplication.openSettingsURLString)
                        if let url = settingUrl, UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(settingUrl!, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }
    }
}
