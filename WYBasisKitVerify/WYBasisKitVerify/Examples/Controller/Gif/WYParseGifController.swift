//
//  WYParseGifController.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/7.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

class WYParseGifController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let widthHeight: CGFloat = (UIScreen.main.bounds.self.width - 40) / 3
        let contentMode: UIView.ContentMode = .scaleAspectFit
        
        let oneGifView = UIImageView()
        oneGifView.contentMode = contentMode
        view.addSubview(oneGifView)
        oneGifView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(wy_navViewHeight + 80)
            make.width.height.equalTo(widthHeight)
        }
        
        let animatedGifView = UIImageView()
        oneGifView.contentMode = contentMode
        view.addSubview(animatedGifView)
        animatedGifView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(wy_navViewHeight + 80)
            make.width.height.equalTo(widthHeight)
        }
        
        let customGifView = UIImageView()
        oneGifView.contentMode = contentMode
        view.addSubview(customGifView)
        customGifView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(wy_navViewHeight + 80)
            make.width.height.equalTo(widthHeight)
        }
        
        
        let oneApngView = UIImageView()
        oneApngView.contentMode = contentMode
        view.addSubview(oneApngView)
        oneApngView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(wy_navViewHeight + 80 + widthHeight + 50)
            make.width.height.equalTo(widthHeight)
        }
        
        let animatedApngView = UIImageView()
        animatedApngView.contentMode = contentMode
        view.addSubview(animatedApngView)
        animatedApngView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(wy_navViewHeight + 80 + widthHeight + 50)
            make.width.height.equalTo(widthHeight)
        }
        
        let customApngView = UIImageView()
        customApngView.contentMode = contentMode
        customApngView.layer.masksToBounds = true
        view.addSubview(customApngView)
        customApngView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(wy_navViewHeight + 80 + widthHeight + 50)
            make.width.height.equalTo(widthHeight)
        }
        
        let apngInfo1: WYGifInfo? = UIImage.wy_animatedParse(.APNG, name: "apng格式图片1")
        let apngInfo2: WYGifInfo? = UIImage.wy_animatedParse(.APNG, name: "apng格式图片2")
        
        let gifInfo1: WYGifInfo? = UIImage.wy_animatedParse(name: "动图1")
        let gifInfo2: WYGifInfo? = UIImage.wy_animatedParse(name: "动图2")
        
        // 直接显示解析得到的图片(实际上就是无限循环播放)
        oneGifView.image = gifInfo2?.animatedImage
        oneApngView.image = apngInfo2?.animatedImage
        
        // 只播放一次解析得到的图片
        for imageView: UIImageView in [animatedGifView, animatedApngView] {
            imageView.animationImages = (imageView == animatedGifView) ? gifInfo1!.animationImages : apngInfo1!.animationImages
            imageView.animationDuration = (imageView == animatedGifView) ? gifInfo1!.animationDuration : apngInfo1!.animationDuration
            imageView.animationRepeatCount = 1
            imageView.startAnimating()

            UIView.animate(withDuration: imageView.animationDuration) {
            }completion: { _ in
                imageView.image = imageView.animationImages?.last
            }
        }
        
        // 无限循环播放(和直接调用解析得到的animatedImage效果一样)
        for imageView: UIImageView in [customGifView, customApngView] {
            imageView.animationImages = (imageView == customGifView) ? gifInfo2!.animationImages : apngInfo2!.animationImages
            imageView.animationDuration = (imageView == customGifView) ? gifInfo2!.animationDuration : apngInfo2!.animationDuration
            // 0 表示无限循环播放
            imageView.animationRepeatCount = 0
            imageView.startAnimating()

            UIView.animate(withDuration: imageView.animationDuration) {
            }completion: { _ in
                imageView.image = imageView.animationImages?.last
            }
        }
    }
    
    deinit {
        wy_print("release")
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
