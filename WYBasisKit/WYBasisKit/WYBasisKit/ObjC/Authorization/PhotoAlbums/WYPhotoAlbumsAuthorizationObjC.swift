//
//  WYPhotoAlbumsAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

#if compiler(>=6)
@MainActor
#endif
@objc(WYPhotoAlbumsAuthorization)
@objcMembers public class WYPhotoAlbumsAuthorizationObjC: NSObject {
    
    /// 检查相册权限
    @objc(authorizeAlbumAccessWithShowAlert:completionHandler:)
    public static func authorizeAlbumAccess(showAlert: Bool = true, handler: @escaping (_ authorized: Bool, _ limited: Bool) -> Void) {
        wy_authorizeAlbumAccess(showAlert: showAlert, handler: handler)
    }
}
