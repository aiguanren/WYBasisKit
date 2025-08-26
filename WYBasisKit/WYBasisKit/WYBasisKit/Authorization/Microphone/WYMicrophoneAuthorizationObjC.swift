//
//  WYMicrophoneAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

@objcMembers public class WYMicrophoneAuthorizationObjC: NSObject {
    
    /// 检查麦克风权限
    @objc public static func authorizeMicrophoneAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void) {
        wy_authorizeMicrophoneAccess(showAlert: showAlert, handler: handler)
    }
}
