//
//  WYTestVisualController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/12.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTestVisualController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let button1 = UIButton(type: .custom)
        view.addSubview(button1)
        button1.wy_backgroundColor(.orange, forState: .normal)
        button1.titleLabel?.numberOfLines = 0
        button1.setTitle("frame控件", for: .normal)
        button1.wy_borderWidth(5).wy_borderColor(.yellow).wy_rectCorner([.bottomLeft, .topRight]).wy_cornerRadius(10).wy_shadowRadius(20).wy_shadowColor(.green).wy_shadowOpacity(0.5).wy_showVisual()
        button1.frame = CGRect(x: 20, y: 200, width: 100, height: 100)
        
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(updateButtonConstraints(button:)), for: .touchUpInside)
        button.titleLabel?.numberOfLines = 0
        button.setTitle("约束控件", for: .normal)
        view.addSubview(button)
        button.wy_makeVisual { (current) in
            
            current.wy_gradualColors([.yellow, .purple])
            current.wy_gradientDirection(.leftToLowRight)
            current.wy_borderWidth(5)
            current.wy_borderColor(.black)
            current.wy_rectCorner(.topRight)
            current.wy_cornerRadius(20)
            current.wy_shadowRadius(30)
            current.wy_shadowColor(.green)
            current.wy_shadowOffset(.zero)
            current.wy_shadowOpacity(0.5)
            //current.wy_bezierPath(UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 50)))
        }
        button.snp.makeConstraints { (make) in
            
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(200)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        
        let gradualView = UIView()
        gradualView.backgroundColor = .orange
        view.addSubview(gradualView)
        gradualView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(500)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        gradualView.wy_add(rectCorner: .allCorners, cornerRadius: 10, borderColor: .black, borderWidth: 5, gradualColors: [UIColor.orange,
                                                                                                          UIColor.red], gradientDirection: .leftToRight)
        
        
    }
    
    @objc func updateButtonConstraints(button: UIButton) {
        button.snp.updateConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(200)
            make.size.equalTo(CGSize(width: 200, height: 100))
        }
        button.wy_showVisual()
    }
    
    deinit {
        wy_print("WYTestVisualController release")
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
