//
//  SDKResponse.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/8/27.
//

import UIKit

public protocol SDKResponseProtocol {}
@objcMembers public class SDKResponse: Codable, SDKResponseProtocol {

    public var errorCode: String = ""
    
    public var errorMessage: String = ""
}
