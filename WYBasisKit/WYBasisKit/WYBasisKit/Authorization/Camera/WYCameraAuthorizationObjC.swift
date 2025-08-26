//
//  WYCameraAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import Foundation

@objcMembers public class WYCameraAuthorizationObjC: NSObject {
    
    /// 检查相机权限
    @objc public static func authorizeCameraAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void) {
        wy_authorizeCameraAccess(showAlert: showAlert, handler: handler)
    }
}

