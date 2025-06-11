//
//  WYOffLineMethodController.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2024/9/4.
//  Copyright © 2024 官人. All rights reserved.
//

import UIKit

class WYOffLineMethodController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let className: String = String(describing: WYGenericTypeController.self)
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let fullClassName = namespace + "." + className
        if let classType = NSClassFromString(fullClassName) as? UIViewController.Type {
            let moudleClass = classType.init()
            let method: String = "testMothodWithData:"
            if moudleClass.responds(to: NSSelectorFromString(method)) {
                _ = moudleClass.perform(NSSelectorFromString(method), with: "context")
            }
        }
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
