//
//  SDKRequest.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/8/27.
//

import UIKit

public protocol SDKRequestProtocol {}
@objcMembers public class SDKRequest: Codable, SDKRequestProtocol {

    public var eventId: String = ""
}
