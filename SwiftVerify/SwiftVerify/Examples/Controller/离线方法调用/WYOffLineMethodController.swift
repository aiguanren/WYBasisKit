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
        
        let className = String(describing: WYGenericTypeController.self)
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
        let fullClassName = namespace + "." + className

        if let classType = NSClassFromString(fullClassName) as? UIViewController.Type {
            let obj = classType.init()
            
            let selector = NSSelectorFromString("testMothodWithData:data2:")
            
            if obj.responds(to: selector) {
                
                typealias Func = @convention(c) (AnyObject, Selector, NSString, Int) -> Unmanaged<AnyObject>?
                
                let imp = obj.method(for: selector)
                let function = unsafeBitCast(imp, to: Func.self)
                
                _ = function(obj, selector, "context", 99999)
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
