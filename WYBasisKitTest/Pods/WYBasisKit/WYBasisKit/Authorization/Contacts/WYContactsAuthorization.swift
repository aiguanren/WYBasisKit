//
//  WYContactsAuthorization.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
import Contacts

/// 通讯录权限KEY
public let contactsKey: String = "NSContactsUsageDescription"

/// 检查通讯录权限并获取通讯录
public func wy_authorizeAddressBookAccess(showAlert: Bool = true, keysToFetch: [String] = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactNicknameKey], handler: @escaping (_ authorized: Bool, _ userInfo: [CNContact]?) -> Void?) {
    
    if let _ = Bundle.main.infoDictionary?[contactsKey] as? String {
        
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        let contactStore = CNContactStore()
        switch authStatus {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        wy_openContact(contactStore: contactStore, keysToFetch: keysToFetch, handler: handler)
                        return
                    }else {
                        /// App无权访问通讯录 用户已明确拒绝
                        wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_17", table: WYBasisKitConfig.kitLocalizableTable))
                        handler(false, nil)
                        return
                    }
                 }
            }
        case .authorized:
            /// 可以访问
            wy_openContact(contactStore: contactStore, keysToFetch: keysToFetch, handler: handler)
            return
        default:
            /// App无权访问通讯录 用户已明确拒绝
            wy_showAuthorizeAlert(show: showAlert, message: WYLocalized("WYLocalizable_17", table: WYBasisKitConfig.kitLocalizableTable))
            handler(false, nil)
            return
        }
        
    }else {
        wy_print("请先在Info.plist中添加key：\(contactsKey)")
        handler(false, nil)
        return
    }
    
    // 获取通讯录
    func wy_openContact(contactStore: CNContactStore, keysToFetch: [String], handler: @escaping (_ authorized: Bool, _ userInfo: [CNContact]?) -> Void?) {
        
        if let _ = Bundle.main.infoDictionary?[contactsKey] as? String {
            
            contactStore.requestAccess(for: .contacts) {(granted, error) in
                if (granted) && (error == nil) {
                    
                    let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
                    do {
                        var contacts: [CNContact] = []
                        // 需要传入一个CNContactFetchRequest
                        try contactStore.enumerateContacts(with: request, usingBlock: {(contact : CNContact, stop : UnsafeMutablePointer) -> Void in
                            contacts.append(contact)
                        })
                        handler(true, contacts)
                    } catch {
                        handler(true, nil)
                    }
                } else {
                    handler(true, nil)
                }
            }
        }else {
            handler(false, nil)
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
}
