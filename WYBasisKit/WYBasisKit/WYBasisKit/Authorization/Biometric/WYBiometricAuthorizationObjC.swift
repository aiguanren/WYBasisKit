//
//  WYBiometricAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import Foundation

/// 生物识别模式
@objc(WYBiometricMode)
public enum WYBiometricModeObjC: Int {
    
    /// 未知或者不支持
    case none = 0
    
    /// 指纹识别
    case touchID
    
    /// 面部识别
    case faceID
}

@objc(WYBiometricAuthorization)
@objcMembers public class WYBiometricAuthorizationObjC: NSObject {
    
    /// 获取设备支持的生物识别类型
    @objc public static func checkBiometric() -> WYBiometricModeObjC {
        return WYBiometricModeObjC(rawValue: wy_checkBiometric().rawValue) ?? .none
    }

    /**
     * 生物识别认证（指纹或面部识别）
     *
     * - Parameters:
     *   - localizedFallbackTitle: 认证失败时显示的备选按钮标题（如"使用密码"）
     *             传入空字符串则不显示备选按钮，默认为空
     *   - localizedReason: 向用户解释为什么需要生物识别认证的描述文本
     *             此文本将显示在系统弹出的认证对话框中
     *   - handler: 认证完成后的回调闭包
     *             - isBackupHandler: 用户是否点击了备选按钮（如"使用密码"）
     *             - isSuccess: 认证是否成功
     *             - error: 认证失败时的错误描述信息，认证成功时为空
     */
    @objc(verifyBiometrics:localizedReason:handler:)
    public static func verifyBiometrics(_ localizedFallbackTitle: String = "", localizedReason: String, handler: @escaping (_ isBackupHandler: Bool, _ isSuccess: Bool, _ error: String) -> Void) {
        wy_verifyBiometrics(localizedFallbackTitle, localizedReason: localizedReason, handler: handler)
    }
}
