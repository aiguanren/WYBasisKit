//
//  WYSpeechRecognitionAuthorizationObjC.swift
//  WYBasisKit
//
//  Created by 官人 on 2023/6/8.
//  Copyright © 2023 官人. All rights reserved.
//

import UIKit
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

@objc(WYSpeechRecognitionAuthorization)
@objcMembers public class WYSpeechRecognitionAuthorizationObjC: NSObject {
    /// 检查语音识别权限
    @objc(authorizeSpeechRecognitionWithShowSettingsAlert:completionHandler:)
    public static func authorizeSpeechRecognition(showSettingsAlert: Bool = true, handler: @escaping (_ authorized: Bool) -> Void) {
        wy_authorizeSpeechRecognition(showSettingsAlert: showSettingsAlert, handler: handler)
    }
}
