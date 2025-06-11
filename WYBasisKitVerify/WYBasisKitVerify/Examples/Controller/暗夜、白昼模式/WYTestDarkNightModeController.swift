//
//  WYTestDarkNightModeController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/12.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTestDarkNightModeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let button = UIButton(type: .custom)
        button.wy_backgroundColor(.orange, forState: .normal)
        button.wy_backgroundColor(.green, forState: .selected)
        button.titleLabel?.numberOfLines = 0
        button.setTitle("亮色/中文", for: .normal)
        button.setTitle("Dark night/English", for: .selected)
        button.isSelected = (WYLocalizableManager.currentLanguage() == .english)
        view.addSubview(button)
        button.addTarget(self, action: #selector(clickButton(sender:)), for: .touchUpInside)
        button.snp.makeConstraints { (make) in

            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
    }
    
    @objc func clickButton(sender: UIButton) {

        if WYLocalizableManager.currentLanguage() == .zh_Hans {

            WYLocalizableManager.switchLanguage(language: .english) {

                DispatchQueue.main.async(execute: {

                    let tabbarController = AppDelegate.shared().window?.rootViewController! as! WYTabBarController
                    let navController = tabbarController.selectedViewController as! UINavigationController
                    navController.topViewController!.wy_showViewController(className: "WYTestDarkNightModeController", animated: false)
                })
            }
            if #available(iOS 13.0, *) {
                UIApplication.shared.wy_switchAppDisplayBrightness(style: .dark)
            }

        }else {

            WYLocalizableManager.switchLanguage(language: .zh_Hans) {

                DispatchQueue.main.async(execute: {

                    let tabbarController = AppDelegate.shared().window?.rootViewController! as! WYTabBarController
                    let navController = tabbarController.selectedViewController as! UINavigationController
                    navController.topViewController!.wy_showViewController(className: "WYTestDarkNightModeController", animated: false)
                })
            }
            if #available(iOS 13.0, *) {
                UIApplication.shared.wy_switchAppDisplayBrightness(style: .light)
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
