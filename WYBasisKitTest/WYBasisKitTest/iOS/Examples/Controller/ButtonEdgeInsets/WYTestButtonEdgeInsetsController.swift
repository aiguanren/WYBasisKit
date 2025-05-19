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
            make.centerY.equalToSuperview()
        }
        button.wy_adjust(position: .imageRightTitleLeft, spacing: 5)
        
        let itemButton: UIButton = UIButton(type: .custom)
        itemButton.backgroundColor = .wy_random
        itemButton.titleLabel?.textAlignment = .center
        itemButton.imageView?.backgroundColor = .wy_random
        itemButton.titleLabel?.backgroundColor = .wy_random
        itemButton.wy_titleRect = CGRect(x: 10, y: 10, width: 80, height: 30)
        itemButton.wy_imageRect = CGRect(x: 100, y: 10, width: 80, height: 80)
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
            make.centerY.equalTo(button.snp.bottom).offset(100)
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
