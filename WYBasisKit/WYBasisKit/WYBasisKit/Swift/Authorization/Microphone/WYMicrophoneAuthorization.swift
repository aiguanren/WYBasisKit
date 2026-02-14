//
//  WYMicrophoneAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import AVFoundation

/// 麦克风权限KEY
public let microphoneKey: String = "NSMicrophoneUsageDescription"

/// 检查麦克风权限
public func wy_authorizeMicrophoneAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void?) {
    
    guard let _ = Bundle.main.infoDictionary?[microphoneKey] as? String else {
        WYLogManager.output("请先在Info.plist中添加key：\(microphoneKey)")
        handler(false)
        return
    }
    
    if #available(iOS 17.0, *) {
        // iOS 17+ 推荐使用 AVAudioApplication
        let permission = AVAudioApplication.shared.recordPermission
        
        switch permission {
        case .granted:
            handler(true)
            
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        handler(true)
                    } else {
                        wy_showMicrophoneAuthorizeAlert(show: showAlert)
                        handler(false)
                    }
                }
            }
            
        default:  // .denied
            wy_showMicrophoneAuthorizeAlert(show: showAlert)
            handler(false)
        }
        
    } else {
        // iOS 16 及以下使用 AVCaptureDevice
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch authStatus {
        case .authorized:
            handler(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        handler(true)
                    } else {
                        wy_showMicrophoneAuthorizeAlert(show: showAlert)
                        handler(false)
                    }
                }
            }
            
        default:
            wy_showMicrophoneAuthorizeAlert(show: showAlert)
            handler(false)
        }
    }
    
    // 弹出麦克风授权提示
    func wy_showMicrophoneAuthorizeAlert(show: Bool) {
        guard show else { return }
        
        let message = WYLocalized("App没有访问麦克风的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable)
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
