//
//  WYSpeechRecognitionAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit

@objc(WYSpeechRecognitionAuthorization)
@objcMembers public class WYSpeechRecognitionAuthorizationObjC: NSObject {
    /// 检查语音识别权限
    @objc(authorizeSpeechRecognition:handler:)
    public static func authorizeSpeechRecognition(showAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void) {
        wy_authorizeSpeechRecognition(showAlert: showAlert, handler: handler)
    }
}
