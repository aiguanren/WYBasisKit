//
//  SDKRequestContext.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/8/27.
//

import UIKit

@objcMembers public class SDKRequestContext<TRequest: SDKRequestProtocol, TResponse: SDKResponseProtocol>: NSObject {

    public var request: TRequest?
    
    public func setResponse(response: SDKResponse) {
        
        if let request: SDKRequest = request as? SDKRequest, let data = try? WYCodable().encode(String.self, from: response) {
            wy_print("eventId = \(request.eventId), responseJson = \(data)")
        }
    }
}
