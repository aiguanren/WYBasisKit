//
//  WYTestBannerController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/15.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTestBannerController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let bannerView = WYBannerView()
        bannerView.backgroundColor = .white
        bannerView.delegate = self
        
//        bannerView.updatePageControl(defaultColor: .purple, currentColor: .green)
//        bannerView.updatePageControl(defaultImage: UIImage(named: "banner_dot_default")!, currentImage: UIImage(named: "banner_dot_current")!)
//        bannerView.pageControlHideForSingle = false
//        bannerView.scrollForSinglePage = true
//        bannerView.imageContentMode = .scaleAspectFit
//        bannerView.unlimitedCarousel = false
//        bannerView.automaticCarousel = false
//        bannerView.describeViewPosition = CGRect(x: 50, y: 50, width: 100, height: 20)
//        bannerView.placeholderDescribe = "测试"
        
        bannerView.reload(images: [UIImage(named: "banner_1")!, UIImage(named: "banner_2")!, UIImage(named: "banner_3")!, UIImage(named: "banner_4")!, UIImage(named: "banner_5")!, UIImage(named: "banner_6")!, UIImage(named: "banner_7")!, UIImage(named: "banner_8")!, UIImage(named: "banner_9")!], describes: ["banner_1", "banner_2", "banner_3", "banner_4", "banner_5", "banner_6", "banner_7", "banner_8", "banner_9"])
        view.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 300, height: 600))
        }
        
        bannerView.didClick { index in
           //wy_print("Block监听，点击了第 \(index+1) 张图片")
        }
        
        bannerView.didScroll { offset, index in
            //wy_print("Block监听，滑动Banner到第 \(index+1) 张图片了， offset = \(offset)")
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

extension WYTestBannerController: WYBannerViewDelegate {
    
    func didClick(_ bannerView: WYBannerView, _ index: Int) {
        //wy_print("代理监听，点击了第 \(index+1) 张图片")
    }
    
    func didScroll(_ bannerView: WYBannerView, _ offset: CGFloat, _ index: Int) {
        //wy_print("代理监听，滑动Banner到第 \(index+1) 张图片了， offset = \(offset)")
    }
}
