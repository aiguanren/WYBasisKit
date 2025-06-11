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
        
        let lineView1 = createLineView()
        lineView1.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.equalToSuperview().offset(wy_navViewHeight)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        
        let lineView2 = createLineView()
        lineView2.snp.makeConstraints { make in
            make.width.top.bottom.equalTo(lineView1)
            make.right.equalToSuperview().offset(-220)
        }
        
        let lineView3 = createLineView()
        lineView3.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(200)
            make.height.equalTo(1)
        }
        
        let lineView4 = createLineView()
        lineView4.snp.makeConstraints { make in
            make.left.right.height.equalTo(lineView3)
            make.top.equalToSuperview().offset(300)
        }
        
        let lineView5 = createLineView()
        lineView5.snp.makeConstraints { make in
            make.left.right.height.equalTo(lineView3)
            make.top.equalToSuperview().offset(350)
        }
        
        let lineView6 = createLineView()
        lineView6.snp.makeConstraints { make in
            make.width.top.bottom.equalTo(lineView1)
            make.right.equalToSuperview().offset(-120)
        }
        
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
        button.wy_makeVisual { make in
            make.wy_gradualColors([.yellow, .purple])
            make.wy_gradientDirection(.leftToLowRight)
            make.wy_borderWidth(5)
            make.wy_borderColor(UIColor.black)
            make.wy_rectCorner(.topRight)
            make.wy_cornerRadius(20)
            make.wy_shadowRadius(30)
            make.wy_shadowColor(.green)
            make.wy_shadowOffset(.zero)
            make.wy_shadowOpacity(0.5)
            //make.wy_bezierPath(UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 50)))
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
        gradualView.wy_rectCorner(.allCorners)
        gradualView.wy_cornerRadius(10)
        gradualView.wy_borderColor(.black)
        gradualView.wy_borderWidth(5)
        gradualView.wy_gradualColors([UIColor.orange,
                                      UIColor.red])
        gradualView.wy_gradientDirection(.leftToRight)
        gradualView.wy_showVisual()
    }
    
    @objc func updateButtonConstraints(button: UIButton) {
        button.snp.updateConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(200)
            make.size.equalTo(CGSize(width: 200, height: 150))
        }
        button.wy_gradualColors([.orange, .red])
        button.wy_gradientDirection(.topToBottom)
        button.wy_borderWidth(10)
        button.wy_borderColor(UIColor.purple)
        button.wy_rectCorner(.topLeft)
        button.wy_cornerRadius(30)
        button.wy_shadowRadius(10)
        button.wy_shadowColor(.red)
        button.wy_shadowOffset(.zero)
        button.wy_shadowOpacity(0.5)
        button.wy_showVisual()
    }
    
    func createLineView() -> UIView {
        let lineView = UIView()
        lineView.backgroundColor = .wy_random
        view.addSubview(lineView)
        return lineView
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
