//
//  WYQRCodeController.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/2/4.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

class WYQRCodeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        let qrData = try! JSONSerialization.data(withJSONObject: ["简书": "https://www.jianshu.com/p/dec880e5d401", "GitHub": "https://github.com/gaunren/WYBasisKit-swift"], options: [JSONSerialization.WritingOptions.prettyPrinted])
        //let qrData = "WYBasisKit".data(using: .utf8)!

        let imageView = UIImageView(image: UIImage.wy_createQrCode(with: qrData, size: CGSize(width: 350, height: 350), waterImage: UIImage.wy_find("WYBasisKit_60*60")))
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 获取二维码信息(必须要真机环境才能获取到相关信息)
        guard let infoArr = imageView.image?.wy_recognitionQRCode() else {return}
        WYLogManager.output("二维码信息 = \(infoArr)")
    }
    
    deinit {
        WYLogManager.output("WYQRCodeController release")
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
