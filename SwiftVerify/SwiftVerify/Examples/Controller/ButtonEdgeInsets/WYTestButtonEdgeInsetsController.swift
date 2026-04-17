//
//  WYTestButtonEdgeInsetsController.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2023/4/21.
//

import UIKit

class WYTestButtonEdgeInsetsController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white

        let button: UIButton = UIButton(type: .custom)
        button.wy_nTitle = "wy_adjust"
        button.wy_nImage = UIImage.wy_find("tabbar_right_selected")
        button.wy_titleFont = .boldSystemFont(ofSize: 30)
        button.wy_makeVisual { make in
            make.wy_cornerRadius(5)
            make.wy_borderWidth(1)
            make.wy_borderColor(.wy_random)
        }
        button.wy_title_nColor = .red
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(200)
            make.centerY.equalToSuperview().offset(-100)
        }
        button.imageView?.backgroundColor = .wy_random
        button.titleLabel?.backgroundColor = .wy_random
        button.contentHorizontalAlignment = .right
        button.wy_adjust(position: .imageTopTitleBottom, spacing: 5)
        
        let itemButton: UIButton = UIButton(type: .custom)
        itemButton.backgroundColor = .wy_random
        itemButton.titleLabel?.textAlignment = .center
        itemButton.imageView?.backgroundColor = .wy_random
        itemButton.titleLabel?.backgroundColor = .wy_random
        itemButton.wy_titleFont = .boldSystemFont(ofSize: 30)
        itemButton.wy_titleRect = CGRect(x: 10, y: 10, width: 100, height: 30)
        itemButton.wy_imageRect = CGRect(x: 120, y: 10, width: 80, height: 80)
        itemButton.wy_nTitle = "frame"
        itemButton.wy_nImage = UIImage.wy_find("tabbar_right_selected")
        itemButton.wy_makeVisual { make in
            make.wy_cornerRadius(5)
            make.wy_borderWidth(1)
            make.wy_borderColor(.wy_random)
        }
        itemButton.wy_title_nColor = .orange
        view.addSubview(itemButton)
        itemButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(200)
            make.centerY.equalTo(button.snp.bottom).offset(150)
        }
        
        if #available(iOS 15.0, *) {
            
            var config = UIButton.Configuration.plain()
            config.title = "config按钮"
            config.image = UIImage.wy_find("tabbar_right_selected")
            config.imagePlacement = .top
            config.imagePadding = 5
            config.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30)
            
            let configButton = UIButton(configuration: config)
            configButton.backgroundColor = .wy_random
            
            configButton.titleLabel?.backgroundColor = .wy_random
            configButton.imageView?.backgroundColor = .wy_random
            configButton.contentHorizontalAlignment = .left
            
            view.addSubview(configButton)
            configButton.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(10)
                make.centerY.equalTo(itemButton.snp.bottom).offset(100)
            }
            configButton.wy_adjust(position: .imageTopTitleBottom, spacing: 10)
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
