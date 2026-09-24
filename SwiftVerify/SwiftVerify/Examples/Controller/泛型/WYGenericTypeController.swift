//
//  WYGenericTypeController.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/9/4.
//  Copyright © 2024 官人. All rights reserved.
//

import UIKit

class WYGenericTypeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let context: SDKRequestContext = SDKRequestContext<UserRequest, UserResponse>()
        let request: UserRequest = UserRequest()
        request.eventId = "测试eventId"
        context.request = request
        userModuleSuccessMethod(context: context)
    }
    
    func userModuleSuccessMethod(context: SDKRequestContext<UserRequest, UserResponse>) {
        WYLogManager.output("context.request?.eventId = \(context.request?.eventId ?? "")")
    
        let response: UserResponse = UserResponse()
        response.errorCode = "100"
        response.errorMessage = "测试消息"
        
        context.setResponse(response: response)
    }
    
    @objc func testMethod(data: String) {
        WYLogManager.output("离线方法调用,data = \(data)")
    }
    
    @objc func testMethod(data: String, data2: Int) {
        WYLogManager.output("离线方法调用, data = \(data), data2 = \(data2)")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
