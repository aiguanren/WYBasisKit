//
//  SDKResponse.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/8/27.
//

import UIKit

public protocol SDKResponseProtocol {}
@objcMembers public class SDKResponse: Codable, SDKResponseProtocol {

    @objc public var errorCode: String = ""
    
    @objc public var errorMessage: String = ""
}
