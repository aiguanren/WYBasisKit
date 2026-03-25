//
//  WYMicrophoneAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc(WYMicrophoneAuthorization)
@objcMembers public class WYMicrophoneAuthorizationObjC: NSObject {
    
    /// 检查麦克风权限
    @objc(authorizeMicrophoneAccessWithShowSettingsAlert:completionHandler:)
    public static func authorizeMicrophoneAccess(showSettingsAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void) {
        wy_authorizeMicrophoneAccess(showSettingsAlert: showSettingsAlert, handler: handler)
    }
}
