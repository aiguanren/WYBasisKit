//
//  WYTestInfiniteSwitchController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/7/20.
//

import UIKit

class WYTestInfiniteSwitchController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let contentView = WYContentScrollView()
        contentView.backgroundColor = .white
        contentView.contentDelegate = self
        contentView.scrollForSinglePage = true
        contentView.unlimitedCarousel = false
        contentView.automaticCarousel = false
        contentView.numberOfContent = 5
        contentView.currentContent.backgroundColor = .systemRed
        contentView.reserveContent.backgroundColor = .systemBlue
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 300, height: 600))
        }
        
        contentView.didClick { index in
            WYLogManager.output("Block监听，点击了第 \(index) 个内容页")
        }
        
        contentView.didScroll { offset, index in
            //WYLogManager.output("Block监听，滑动contentScrollView到第 \(index) 个内容页了， offset = \(offset)")
        }
        
        contentView.willSwitch { currentIndex, targetIndex in
            WYLogManager.output("Block监听，即将切换contentScrollView到第 \(targetIndex) 个内容页， 当前在第 \(currentIndex) 个内容页")
        }
        
        contentView.didSwitch { currentIndex in
            WYLogManager.output("代理监听，已经切换contentScrollView到第 \(currentIndex) 个内容页")
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

extension WYTestInfiniteSwitchController: WYContentScrollViewDelegate {
    
    func wy_contentScrollViewDidClick(_ contentScrollView: WYContentScrollView, index: Int) {
        WYLogManager.output("代理监听，点击了第 \(index) 个内容页")
    }
    
    func wy_contentScrollViewDidScroll(_ contentScrollView: WYContentScrollView, offset: CGFloat, index: Int) {
        //WYLogManager.output("代理监听，滑动contentScrollView到第 \(index) 个内容页了， offset = \(offset)")
    }
    
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, currentIndex: Int, targetIndex: Int) {
        WYLogManager.output("代理监听，即将切换contentScrollView到第 \(targetIndex) 个内容页， 当前在第 \(currentIndex) 个内容页")
    }
    
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, currentIndex: Int) {
        WYLogManager.output("代理监听，已经切换contentScrollView到第 \(currentIndex) 个内容页")
    }
}
