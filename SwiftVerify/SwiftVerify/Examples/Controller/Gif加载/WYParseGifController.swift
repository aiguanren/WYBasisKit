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
        
        let spacing = UIDevice.wy_screenWidth(10, WYBasisKitConfig.defaultScreenPixels)
        let topSpacing = UIDevice.wy_screenHeight(80, WYBasisKitConfig.defaultScreenPixels)
        let rowSpacing = UIDevice.wy_screenHeight(50, WYBasisKitConfig.defaultScreenPixels)
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        let contentMode: UIView.ContentMode = .scaleAspectFit
        
        let oneGifView = UIImageView()
        oneGifView.accessibilityIdentifier = "WYAnimation.oneGifView"
        oneGifView.isAccessibilityElement = true
        oneGifView.contentMode = contentMode
        contentView.addSubview(oneGifView)
        oneGifView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(spacing)
            make.top.equalToSuperview().offset(topSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(oneGifView.snp.width)
        }
        
        let animatedGifView = UIImageView()
        animatedGifView.accessibilityIdentifier = "WYAnimation.animatedGifView"
        animatedGifView.isAccessibilityElement = true
        animatedGifView.contentMode = contentMode
        contentView.addSubview(animatedGifView)
        animatedGifView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(topSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(animatedGifView.snp.width)
        }
        
        let customGifView = UIImageView()
        customGifView.accessibilityIdentifier = "WYAnimation.customGifView"
        customGifView.isAccessibilityElement = true
        customGifView.contentMode = contentMode
        contentView.addSubview(customGifView)
        customGifView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-spacing)
            make.top.equalToSuperview().offset(topSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(customGifView.snp.width)
        }
        
        
        let oneApngView = UIImageView()
        oneApngView.accessibilityIdentifier = "WYAnimation.oneApngView"
        oneApngView.isAccessibilityElement = true
        oneApngView.contentMode = contentMode
        contentView.addSubview(oneApngView)
        oneApngView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(spacing)
            make.top.equalTo(oneGifView.snp.bottom).offset(rowSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(oneApngView.snp.width)
        }
        
        let animatedApngView = UIImageView()
        animatedApngView.accessibilityIdentifier = "WYAnimation.animatedApngView"
        animatedApngView.isAccessibilityElement = true
        animatedApngView.contentMode = contentMode
        contentView.addSubview(animatedApngView)
        animatedApngView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(oneGifView.snp.bottom).offset(rowSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(animatedApngView.snp.width)
        }
        
        let customApngView = UIImageView()
        customApngView.accessibilityIdentifier = "WYAnimation.customApngView"
        customApngView.isAccessibilityElement = true
        customApngView.contentMode = contentMode
        customApngView.layer.masksToBounds = true
        contentView.addSubview(customApngView)
        customApngView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-spacing)
            make.top.equalTo(oneGifView.snp.bottom).offset(rowSpacing)
            make.width.equalTo(contentView).multipliedBy(1.0 / 3).offset(-spacing * 4 / 3)
            make.height.equalTo(customApngView.snp.width)
            make.bottom.equalToSuperview().offset(-topSpacing)
        }
        
        let apngInfo: WYGifInfo? = UIImage.wy_animatedParse(.APNG, name: "连线主播")
        
        let gifInfo: WYGifInfo? = UIImage.wy_animatedParse(name: "关注主播")
        
        // 直接显示解析得到的图片(实际上就是无限循环播放)
        oneGifView.image = gifInfo?.animatedImage
        oneApngView.image = apngInfo?.animatedImage
        
        // 只播放一次解析得到的图片
        for imageView: UIImageView in [animatedGifView, animatedApngView] {
            imageView.animationImages = (imageView == animatedGifView) ? gifInfo!.animationImages : apngInfo!.animationImages
            imageView.animationDuration = (imageView == animatedGifView) ? gifInfo!.animationDuration : apngInfo!.animationDuration
            imageView.animationRepeatCount = 1
            imageView.startAnimating()

            UIView.animate(withDuration: imageView.animationDuration) {
            }completion: { _ in
                imageView.image = imageView.animationImages?.last
            }
        }
        
        // 无限循环播放(和直接调用解析得到的animatedImage效果一样)
        for imageView: UIImageView in [customGifView, customApngView] {
            imageView.animationImages = (imageView == customGifView) ? gifInfo!.animationImages : apngInfo!.animationImages
            imageView.animationDuration = (imageView == customGifView) ? gifInfo!.animationDuration : apngInfo!.animationDuration
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
        WYLogManager.output("release")
    }
    

    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
