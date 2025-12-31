//
//  WYSpeechRecognitionAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import Speech

/// 语音识别 权限KEY
public let speechRecognitionKey: String = "NSSpeechRecognitionUsageDescription"

/// 检查语音识别权限
public func wy_authorizeSpeechRecognition(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void?) {
    
    if let _ = Bundle.main.infoDictionary?[speechRecognitionKey] as? String {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            // 识别器的授权状态
            switch status {
            case .authorized:
                // 已授权
                handler(true)
                return
            case .denied:
                // 拒绝授权
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问语音识别的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            case .restricted:
                // 保密，也就是不授权
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问语音识别的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            case .notDetermined:
                // 用户尚未决定是否授权
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问语音识别的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            @unknown default:
                // 其他可能情况
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("App没有访问语音识别的权限，现在去授权?", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            }
        }
        
        // 弹出授权弹窗
        func wy_showAuthorizeAlert(show: Bool, message: String) {
            
            guard show else { return }
            
            // 公共处理逻辑
            let actions = [
                WYLocalized("取消", table: WYBasisKitConfig.kitLocalizableTable),
                WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable)
            ]
            
            let handleResult = { (actionStr: String?) in
                guard actionStr == WYLocalized("去授权", table: WYBasisKitConfig.kitLocalizableTable) else { return }
                #if compiler(>=6)
                Task { @MainActor in
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                #else
                DispatchQueue.main.async {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                #endif
            }
            
            #if compiler(>=6)
            Task { @MainActor in
                UIAlertController.wy_show(
                    message: message,
                    actions: actions
                ) { actionStr, _ in
                    handleResult(actionStr)
                }
            }
            #else
            DispatchQueue.main.async {
                UIAlertController.wy_show(
                    message: message,
                    actions: actions
                ) { actionStr, _ in
                    handleResult(actionStr)
                }
            }
            #endif
        }
        
    }else {
        WYLogManager.output("请先在Info.plist中添加key：\(speechRecognitionKey)")
        handler(false)
    }
}
