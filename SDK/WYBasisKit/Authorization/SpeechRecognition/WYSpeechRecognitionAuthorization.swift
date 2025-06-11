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
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_49", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            case .restricted:
                // 保密，也就是不授权
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_49", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            case .notDetermined:
                // 用户尚未决定是否授权
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_49", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
            @unknown default:
                // 其他可能情况
                wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_49", table: WYBasisKitConfig.kitLocalizableTable))
                handler(false)
                return
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
        
    }else {
        wy_print("请先在Info.plist中添加key：\(speechRecognitionKey)")
        handler(false)
    }
}
