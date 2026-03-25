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

@objc(WYPhotoAlbumsAuthorization)
@objcMembers public class WYPhotoAlbumsAuthorizationObjC: NSObject {
    
    /// 检查相册权限
    @objc(authorizeAlbumAccessWithShowSettingsAlert:completionHandler:)
    public static func authorizeAlbumAccess(showSettingsAlert: Bool = true, handler: @escaping (_ authorized: Bool, _ limited: Bool) -> Void) {
        wy_authorizeAlbumAccess(showSettingsAlert: showSettingsAlert, handler: handler)
    }
}
