//
//  WYPhotoAlbumsAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import Photos

/// 相册权限KEY
public let photoLibraryKey: String = "NSPhotoLibraryUsageDescription"

/// 检查相册权限
public func wy_authorizeAlbumAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool, _ limited: Bool) -> Void?) {
    
    if let _ = Bundle.main.infoDictionary?[photoLibraryKey] as? String {
        if #available(iOS 14, *) {
            let requiredAccessLevel: PHAccessLevel = .readWrite
            PHPhotoLibrary.requestAuthorization(for: requiredAccessLevel) { (authStatus) in
                DispatchQueue.main.async {
                    wy_checkAlbumAccess(showAlert: showAlert, authStatus: authStatus, handler: handler)
                    return
                }
            }
            
        }else {
            wy_checkAlbumAccess(showAlert: showAlert, authStatus: PHPhotoLibrary.authorizationStatus(), handler: handler)
            return
        }
    }else {
        wy_print("请先在Info.plist中添加key：\(photoLibraryKey)")
        handler(false, false)
        return
    }
    
    // 检查相册权限
    func wy_checkAlbumAccess(showAlert: Bool, authStatus: PHAuthorizationStatus, handler: @escaping (_ authorized: Bool, _ limited: Bool) -> Void?) {
        
        if let _ = Bundle.main.infoDictionary?[photoLibraryKey] as? String {
            
            switch authStatus {
            case .notDetermined:
                /// 用户尚未授权(弹出授权提示)
                PHPhotoLibrary.requestAuthorization { (status) in
                    
                    if status == .authorized {
                        /// 用户授权访问
                        handler(true, false)
                    }else {
                        /// App无权访问照片库 用户已明确拒绝
                        wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_13", table: WYBasisKitConfig.kitLocalizableTable))
                        handler(false, false)
                    }
                }
                
            case .authorized:
                /// 可以访问
                handler(true, false)
            case .limited:
                /// 部分可访问
                handler(true, true)
            default:
                /// App无权访问相册 用户已明确拒绝
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_13", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false, false)
            }
            
        }else {
            handler(false, false)
        }
    }
    
    // 弹出授权弹窗
    func wy_showAuthorizeAlert(show: Bool, message: String) {
        
        if show {
            UIAlertController.wy_show(message: message, actions: [WYLocalized("WYLocalizable_03", table: WYBasisKitConfig.kitLocalizableTable), WYLocalized("WYLocalizable_12", table: WYBasisKitConfig.kitLocalizableTable)]) { (actionStr, _) in
                
                DispatchQueue.main.async {
                    
                    if actionStr == WYLocalized("WYLocalizable_12", table: WYBasisKitConfig.kitLocalizableTable) {
                        
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
