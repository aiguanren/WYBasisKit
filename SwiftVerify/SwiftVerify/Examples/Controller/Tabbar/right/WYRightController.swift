//
//  WYRightController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYRightController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        WYEventHandler.shared.register(event: AppEvent.buttonDidMove, target: self) { data in
            if let stringValue = data {
                WYLogManager.output("data = \(stringValue), controller: \(type(of: self))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.buttonDidReturn, target: self) { data in
            if let stringValue = data {
                WYLogManager.output("data = \(stringValue), controller: \(type(of: self))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.didShowBannerView, target: self) { [weak self] data in
            if let dataString = data as? String,
               let delegate = self {
                delegate.didShowBannerView(data: dataString)
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

extension WYRightController: AppEventDelegate {
    
    func didShowBannerView(data: String) {
        WYLogManager.output("data = \(data), controller: \(type(of: self))")
    }
}
