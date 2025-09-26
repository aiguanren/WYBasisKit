//
//  WYTestAnimationController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/12.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTestAnimationController: UIViewController {
    
    var testButton: UIButton = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let button = UIButton(type: .custom)
        button.setTitle("让约束支持动画", for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.wy_backgroundColor(.orange, forState: .normal)
        button.addTarget(self, action: #selector(clickButton(sender:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        
        testButton.backgroundColor = .wy_random
        view.addSubview(testButton)
        testButton.addTarget(self, action: #selector(clickTestButton(sender:)), for: .touchUpInside)
        testButton.snp.makeConstraints { make in
            make.centerX.bottom.equalToSuperview()
            make.size.equalTo(button)
        }
    }
    
    @objc func clickButton(sender: UIButton) {
        
        WYEventHandler.shared.response(event: AppEvent.buttonDidMove, data: "按钮开始向下移动")

        /// 约束控件实现动画的关键是在animate方法中调用父视图的layoutIfNeeded方法
        UIView.animate(withDuration: 1) {
            sender.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(350)
            }
            sender.superview!.layoutIfNeeded()
        }completion: { _ in
            WYEventHandler.shared.response(event: AppEvent.buttonDidReturn, data: "按钮开始归位")
            sender.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(100)
            }
        }
    }
    
    @objc func clickTestButton(sender: UIButton) {
        testButton.wy_temporarilyDisable(for: 10)
        WYLogManager.output("clickTestButton")
    }
    
    deinit {
        WYLogManager.output("WYTestAnimationController deinit")
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
