//
//  WYTestVibrateController.swift
//  WYBasisKitVerify
//
//  Created by guanren on 2025/8/16.
//

import UIKit

class WYTestVibrateController: UIViewController {
    
    // 输入框：重复次数
    private let repeatCountField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "重复次数 (默认1)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        return textField
    }()
    
    // 输入框：间隔时间
    private let intervalField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "间隔秒数 (默认0.3)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    // 震动类型列表
    private let vibrationTypes: [(name: String, style: WYVibrationStyle)] = [
        ("系统震动", .system),
        ("轻", .light),
        ("中", .medium),
        ("重", .heavy),
        ("柔和", .soft),
        ("生硬", .rigid),
        ("成功提示", .success),
        ("警告提示", .warning),
        ("错误提示", .error)
    ]
    
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "震动测试"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // 输入区
        let inputStack = UIStackView(arrangedSubviews: [repeatCountField, intervalField])
        inputStack.axis = .horizontal
        inputStack.spacing = 10
        inputStack.distribution = .fillEqually
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputStack)
        
        NSLayoutConstraint.activate([
            inputStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            inputStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputStack.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 按钮区
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: inputStack.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 添加测试按钮
        for (name, type) in vibrationTypes {
            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            if #available(iOS 14.0, *) {
                button.addAction(UIAction { [weak self] _ in
                    self?.testVibration(type)
                }, for: .touchUpInside)
            }
            stackView.addArrangedSubview(button)
        }
    }
    
    private func testVibration(_ style: WYVibrationStyle) {
        // 解析用户输入
        let repeatCount = Int(repeatCountField.text ?? "") ?? 1
        let interval = Double(intervalField.text ?? "") ?? 0.3
        view.endEditing(true)
        
        if repeatCount <= 1 {
            UIDevice.wy_vibrate(style)
        } else {
            UIDevice.wy_vibrate(style, repeatCount: repeatCount, interval: interval)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
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
