//
//  WYBiometricAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import Foundation
import LocalAuthentication

/// FaceID 权限KEY
public let faceIDKey: String = "NSFaceIDUsageDescription"

/// 生物识别模式
@frozen public enum WYBiometricMode {
    
    /// 未知或者不支持
    case none
    
    /// 指纹识别
    case touchID
    
    /// 面部识别
    case faceID
}

/// 获取设备支持的生物识别类型
public func wy_checkBiometric() -> WYBiometricMode {
    
    var biometric = WYBiometricMode.none
    
    // 该参数必须在canEvaluatePolicy方法后才有值
    let authContent = LAContext()
    var error: NSError?
    if authContent.canEvaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        error: &error) {
        // iPhoneX出厂最低系统版本号：iOS11.0.0
        if #available(iOS 11.0, *) {
            if authContent.biometryType == .faceID {
                biometric = .faceID
            }else if authContent.biometryType == .touchID {
                biometric = .touchID
            }else {
                biometric = .none
            }
        } else {
            guard let laError = error as? LAError else {
                
                biometric = .none
                return biometric
            }
            if laError.code != .touchIDNotAvailable {
                biometric = .touchID
            }
        }
    }
    return biometric
}

/// 生物识别认证
public func wy_verifyBiometrics(localizedFallbackTitle: String = "", localizedReason: String, handler: @escaping (_ isBackupHandler: Bool, _ isSuccess: Bool, _ error: String) -> Void?) {
    
    if wy_checkBiometric() == .faceID {
        
        if let _ = Bundle.main.infoDictionary?[faceIDKey] as? String {
            wy_checkBiometrics(localizedFallbackTitle: localizedFallbackTitle, localizedReason: localizedReason, handler: handler)
            return
        }else {
            WYLogManager.output("请先在Info.plist中添加key：\(faceIDKey)")
            handler(false, false, WYLocalized("WYLocalizable_05", table: WYBasisKitConfig.kitLocalizableTable))
            return
        }
        
    }else {
        wy_checkBiometrics(localizedFallbackTitle: localizedFallbackTitle, localizedReason: localizedReason, handler: handler)
        return
    }
    
    func wy_checkBiometrics(localizedFallbackTitle: String = "", localizedReason: String, handler: @escaping (_ isBackupHandler: Bool ,_ isSuccess: Bool, _ error: String) -> Void?) {
        
        let authContent = LAContext()
        
        // 如果为空不展示输入密码的按钮
        authContent.localizedFallbackTitle = localizedFallbackTitle
        
        var error: NSError?
        /*
         LAPolicy有2个参数：
         用TouchID/FaceID验证，如果连续出错则需要锁屏验证手机密码，
         但是很多app都是用这个参数，等需要输入密码解锁touchId&faceId再弃用该参数。
         优点：用户在单次使用后就可以取消验证。
         1，deviceOwnerAuthenticationWithBiometrics
         
         用TouchID/FaceID或密码验证, 默认是错误两次或锁定后, 弹出输入密码界面
         等错误次数过多验证被锁时启用该参数
         2，deviceOwnerAuthentication
         
         */
        if authContent.canEvaluatePolicy (.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            authContent.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason) { (success, error) in
                
                if success {
                    
                    // evaluatedPolicyDomainState 只有生物验证成功才会有值
                    if let _ = authContent.evaluatedPolicyDomainState {
                        
                        // 如果不放在主线程回调可能会有5-6s的延迟
                        DispatchQueue.main.async {
                            handler(false, true, "")
                        }
                        
                    }else {
                        
                        DispatchQueue.main.async {
                            // 设备密码输入正确
                            handler(false, true, "")
                        }
                    }
                    
                }else {
                    
                    guard let laError = error as? LAError else {
                        
                        // 生物识别不可用
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_05", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                        return
                    }
                    
                    switch laError.code {
                    case .authenticationFailed:
                        
                        DispatchQueue.main.async {
                            
                            wy_unlockLocalAuth { (_success) in
                                
                                DispatchQueue.main.async {
                                    
                                    if _success == true {
                                        
                                        handler(false, true, "")
                                    }else {
                                        
                                        // 生物识别已被锁定，锁屏并成功解锁iPhone后可重新打开本页面开启
                                        handler(false, false, WYLocalized("WYLocalizable_06", table: WYBasisKitConfig.kitLocalizableTable))
                                    }
                                }
                            }
                        }
                    case .userCancel:
                        DispatchQueue.main.async {
                            
                            // 用户点击取消按钮
                            handler(false, false, "")
                        }
                    case .userFallback:
                        DispatchQueue.main.async {
                            // 用户点击了输入密码按钮，在这里处理点击事件"
                            handler(true, false, "")
                        }
                    case .systemCancel:
                        
                        // 系统取消
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_07", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                    case .passcodeNotSet:
                        
                        // 用户未设置解锁密码
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_08", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                    case .touchIDNotAvailable:
                        
                        // 生物识别不可用
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_05", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                    case .touchIDNotEnrolled:
                        
                        // 未设置生物识别
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_09", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                    case .touchIDLockout:
                        
                        // 生物识别已被锁定，锁屏并成功解锁iPhone后可重新打开本页面开启
                        DispatchQueue.main.async {
                            
                            handler(false, false, WYLocalized("WYLocalizable_06", table: WYBasisKitConfig.kitLocalizableTable))
                        }
                    default:break
                    }
                }
            }
            
        }else {
            
            // 生物识别已被锁定，锁屏并成功解锁iPhone后可重新打开本页面开启
            DispatchQueue.main.async {
                
                handler(false, false, WYLocalized("WYLocalizable_06", table: WYBasisKitConfig.kitLocalizableTable))
            }
        }
    }
    
    /// 解锁生物识别
    func wy_unlockLocalAuth(handler:((_ isSuccess: Bool) -> Void)?) {
        
        let passwordContent = LAContext()
        var error: NSError?
        if passwordContent.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error){
            
            // 输入密码开启生物识别
            passwordContent.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: WYLocalized("WYLocalizable_10", table: WYBasisKitConfig.kitLocalizableTable)) { (success, err) in
                if success {
                    handler!(true)
                }else{
                    handler!(false)
                }
            }
            
    }else {}}
}
