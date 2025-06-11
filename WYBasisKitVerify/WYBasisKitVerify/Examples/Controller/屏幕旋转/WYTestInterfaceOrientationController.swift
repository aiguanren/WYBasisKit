//
//  WYTestInterfaceOrientationController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/12/23.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit
import CloudKit

class WYTestInterfaceOrientationController: UIViewController {
    
    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        navigationItem.title = "设置屏幕旋转方向"
        
        /*
         *  实现屏幕旋转步骤
         
         *  1.在AppDelegate中重写屏幕旋转代理方法，即：
         func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
             return UIDevice.current.wy_currentInterfaceOrientation
         }
         
         *  2.在需要旋转操作的时候，动态设置 UIDevice.current.wy_interfaceOrientation 属性为需要支持的旋转方向
         
         *  3.在旋转结束时，恢复 UIDevice.current.wy_interfaceOrientation 属性为默认方向(看具体需求，也可以不用恢复为默认方向)
         */
        
        label.textColor = .wy_dynamic(.black, .white)
        label.backgroundColor = .purple
        label.font = .systemFont(ofSize: 15)
        label.text = sharedInterfaceOrientationString()
        label.textAlignment = .center
        label.numberOfLines = 0
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(layoutInterfaceOrientation))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
    }
    
    @objc func layoutInterfaceOrientation() {
        
        UIAlertController.wy_show(style: .alert, message: "设置屏幕方向", actions: ["竖向", "横向-左", "横向-右", "竖向-颠倒", "横向", "竖向 / 横向", "竖向 / 横向 /  竖向-颠倒"]) {[weak self] actionStr, textFieldTexts in
            
            DispatchQueue.main.async {
                
                if actionStr != self?.label.text {
                    
                    switch actionStr {
                    case "竖向":
                        UIDevice.current.wy_interfaceOrientation = .portrait

                    case "横向-左":
                        UIDevice.current.wy_interfaceOrientation = .landscapeLeft

                    case "横向-右":
                        UIDevice.current.wy_interfaceOrientation = .landscapeRight
                        
                    case "竖向-颠倒":
                        UIDevice.current.wy_interfaceOrientation = .portraitUpsideDown
                        
                    case "横向":
                        UIDevice.current.wy_interfaceOrientation = .landscape
                        
                    case "竖向 / 横向":
                        UIDevice.current.wy_interfaceOrientation = .allButUpsideDown
                     
                    case "竖向 / 横向 /  竖向-颠倒":
                        UIDevice.current.wy_interfaceOrientation = .all
                        
                    default:
                        break
                    }
                    self?.label.text = self?.sharedInterfaceOrientationString()
                }
            }
        }
    }
    
    func sharedInterfaceOrientationString() -> String {
        
        var string: String = ""
        switch UIDevice.current.wy_interfaceOrientation {
        case .portrait:
            string = "竖向\n\(sharedScreenResolution())"
        case .landscapeLeft:
            string = "横向-左\n\(sharedScreenResolution())"
        case .landscapeRight:
            string = "横向-右\n\(sharedScreenResolution())"
        case .portraitUpsideDown:
            string = "竖向-颠倒\n\(sharedScreenResolution())"
        case .landscape:
            string = "横向\n\(sharedScreenResolution())"
        case .allButUpsideDown:
            string = "竖向 / 横向\n\(sharedScreenResolution())"
        case .all:
            string = "竖向 / 横向 /  竖向-颠倒\n\(sharedScreenResolution())"
        default:
            string = "未知\n\(sharedScreenResolution())"
        }
        return string
    }
    
    func sharedScreenResolution() -> String {
        
        let screen = UIScreen.main
        let scale = screen.scale
        let bounds = screen.bounds
        let width = bounds.width * scale
        let height = bounds.height * scale
        
        return "宽\(width) 高\(height)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.wy_interfaceOrientation = .portrait
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
