//
//  WYContactsAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

#if canImport(WYBasisKitSwift)
import UIKit
import Contacts
import WYBasisKitSwift

@objc(WYContactsAuthorization)
@objcMembers public class WYContactsAuthorizationObjC: NSObject {
    
    /// 检查通讯录权限并获取通讯录
    @objc(authorizeAddressBookAccessWithShowSettingsAlert:keysToFetch:completionHandler:)
    public static func authorizeAddressBookAccess(showSettingsAlert: Bool = true, keysToFetch: [String]?, handler: @escaping @MainActor (_ authorized: Bool, _ userInfo: [CNContact]?) -> Void) {
        
        let keysToFetch: [String] = (keysToFetch?.isEmpty ?? true) ? [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey] : keysToFetch!
        
        wy_authorizeAddressBookAccess(showSettingsAlert: showSettingsAlert, keysToFetch: keysToFetch, handler: handler)
    }
}
#endif
