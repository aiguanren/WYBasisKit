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
        userMoudleSuccessMethod(context: context)
    }
    
    func userMoudleSuccessMethod(context: SDKRequestContext<UserRequest, UserResponse>) {
        wy_print("context.request?.eventId = \(context.request?.eventId ?? "")")
    
        let respone: UserResponse = UserResponse()
        respone.errorCode = "100"
        respone.errorMessage = "测试消息"
        
        context.setResponse(response: respone)
    }
    
    @objc func testMothod(data: String) {
        wy_print("离线方法调用,data = \(data)")
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
