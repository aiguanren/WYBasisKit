//
//  WYCenterController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYCenterController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let testView = UIView()
        testView.backgroundColor = .purple
        testView.frame = CGRect(x: 20, y: 200, width: wy_screenWidth-40, height: 300)
        view.addSubview(testView)
        
        let testView2 = UIView()
        testView2.backgroundColor = .green
        testView2.frame = CGRect(x: 10, y: 100, width: wy_screenWidth-60, height: 200)
        testView.addSubview(testView2)
        
        testView.layer.addSublayer(CALayer.drawDashLine(direction: .leftToRight, bounds: CGRect(x: wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), y: 100, width: wy_screenWidth(315, WYBasisKitConfig.defaultScreenPixels), height: wy_screenWidth(2.5, WYBasisKitConfig.defaultScreenPixels)), color: .orange))
        
        testView.layer.addSublayer(CALayer.drawDashLine(direction: .topToBottom, bounds: CGRect(x: wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels), y: 100, width: wy_screenWidth(2.5, WYBasisKitConfig.defaultScreenPixels), height: wy_screenWidth(190, WYBasisKitConfig.defaultScreenPixels)), color: .black))
        
        view.layer.addSublayer(CALayer.drawDashLine(direction: .leftToRight, bounds: CGRect(x: 20, y: 200, width: wy_screenWidth-40, height: 2.5), color: .orange))
        
        view.layer.addSublayer(CALayer.drawDashLine(direction: .topToBottom, bounds: CGRect(x: 10, y: 100, width: 2.5, height: wy_screenWidth-60), color: .black))
        
        let image: UIImage = UIImage(named: "WYBasisKit_60*60")!.wy_cuttingRound()
        let imageView: UIImageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.backgroundColor = .wy_random
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 150, height: 150))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-150)
        }
        
        let leftLineView: UIView = UIView()
        leftLineView.backgroundColor = .white
        view.addSubview(leftLineView)
        leftLineView.snp.makeConstraints { make in
            make.centerY.equalTo(imageView)
            make.right.equalTo(imageView.snp.centerX).offset(-30)
            make.height.equalTo(60)
            make.width.equalTo(2)
        }
        
        let bottomLineView: UIView = UIView()
        bottomLineView.backgroundColor = .white
        view.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints { make in
            make.centerX.equalTo(imageView)
            make.top.equalTo(imageView.snp.centerY).offset(30)
            make.height.equalTo(2)
            make.width.equalTo(64)
        }
        
        let rightLineView: UIView = UIView()
        rightLineView.backgroundColor = .white
        view.addSubview(rightLineView)
        rightLineView.snp.makeConstraints { make in
            make.centerY.equalTo(imageView)
            make.left.equalTo(imageView.snp.centerX).offset(30)
            make.height.equalTo(60)
            make.width.equalTo(2)
        }

        // Do any additional setup after loading the view.
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
