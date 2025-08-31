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
            if let stingValue = data {
                WYLogManager.output("data = \(stingValue), controller: \(NSStringFromClass(type(of: self)))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.buttonDidReturn, target: self) { data in
            if let stingValue = data {
                WYLogManager.output("data = \(stingValue), controller: \(NSStringFromClass(type(of: self)))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.didShowBannerView, target: self) { [weak self] data in
            if let dataString = data as? String,
               let delegate = self {
                delegate.didShowBannerView(data: dataString)
            }
        }
        
        var controllerAry: [UIViewController] = []
        var titleAry: [String] = []
        var simageAry: [UIImage] = []
        var dimageAry: [UIImage] = []

        for index in 0..<20 {

            let controller = UIViewController()
            controller.view.backgroundColor = .wy_random
            controllerAry.append(controller)

            simageAry.append(UIImage(named: "tabbar_right_selected")!)
            dimageAry.append(UIImage(named: "tabbar_right_default")!)

            titleAry.append("测试" + "\(index)")
        }

        let pagingView = WYPagingView()
        view.addSubview(pagingView)
        pagingView.snp.makeConstraints { (make) in

            make.left.bottom.right.equalToSuperview()
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight)
        }
        pagingView.delegate = self
        pagingView.bar_Height = 100
        pagingView.bar_bg_defaultColor = .yellow
        pagingView.bar_item_bg_defaultColor = .orange
        pagingView.bar_item_bg_selectedColor = .green
        pagingView.bar_selectedIndex = 2
        //pagingView.bar_scrollLineBottomOffset = 0
        //pagingView.bar_scrollLineColor = .orange
        pagingView.bar_scrollLineImage = UIImage.wy_createImage(from: .wy_random)
//        pagingView.buttonPosition = .imageTop_titleBottom
//        pagingView.barButton_dividingOffset = 20
//        pagingView.bar_dividingStripColor = .clear
        pagingView.bar_dividingStripImage = UIImage.wy_createImage(from: .wy_random)
//        pagingView.bar_item_height = 50
//        pagingView.bar_item_width = 80
        pagingView.bar_item_cornerRadius = 5
        //pagingView.bar_item_appendSize = CGSize(width: 0.01, height: 0)

        pagingView.layout(controllerAry: controllerAry, titleAry: titleAry, defaultImageAry: dimageAry, selectedImageAry: simageAry, superViewController: self)
        pagingView.itemDidScroll { (pagingIndex) in

            //wy_print("pagingIndex = \(pagingIndex)")
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

extension WYRightController: WYPagingViewDelegate {
    
    func itemDidScroll(_ pagingIndex: Int) {
        
        //wy_print("pagingIndex = \(pagingIndex)")
    }
}

extension WYRightController: AppEventDelegate {
    
    func didShowBannerView(data: String) {
        WYLogManager.output("data = \(data), controller: \(NSStringFromClass(type(of: self)))")
    }
}
