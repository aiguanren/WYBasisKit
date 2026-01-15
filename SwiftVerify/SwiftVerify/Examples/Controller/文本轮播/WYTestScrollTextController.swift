//
//  WYTestScrollTextController.swift
//  SwiftVerify
//
//  Created by guanren on 2025/9/3.
//

import UIKit

class WYTestScrollTextController: UIViewController {
    
    /// 滚动文本视图
    private var scrollText: WYScrollText!
    
    /// 测试按钮
    private var testButton: UIButton!
    
    /// 属性控制开关
    private var placeholderSwitch: UISwitch!
    private var textColorSwitch: UISwitch!
    private var textFontSwitch: UISwitch!
    private var intervalSwitch: UISwitch!
    private var contentColorSwitch: UISwitch!
    
    /// 测试数据数组
    private let testTexts = [
        "这是第一条滚动文本",
        "这是第二条滚动文本，内容稍长一些",
        "第三条文本",
        "第四条文本，用于测试不同的文本长度",
        "第五条文本"
    ]
    
    // MARK: - 生命周期方法
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图背景色
        view.backgroundColor = .white
        
        // 设置标题
        title = "WYScrollText 测试"
        
        // 初始化UI
        setupUI()
        
        // 配置滚动文本
        configureScrollText()
    }
    
    // MARK: - UI设置
    
    /// 初始化UI
    private func setupUI() {
        // 创建滚动文本视图
        scrollText = WYScrollText()
        scrollText.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollText)
        
        // 创建测试按钮
        testButton = UIButton(type: .system)
        testButton.setTitle("更改文本数组", for: .normal)
        testButton.addTarget(self, action: #selector(changeTextArray), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)
        
        // 创建属性控制开关和标签
        createControlSwitches()
        
        // 设置约束
        setupConstraints()
    }
    
    /// 创建属性控制开关
    private func createControlSwitches() {
        // 占位文本开关
        let placeholderLabel = createLabel(text: "显示占位文本:")
        placeholderSwitch = createSwitch(action: #selector(togglePlaceholder(_:)))
        
        // 文本颜色开关
        let textColorLabel = createLabel(text: "切换文本颜色:")
        textColorSwitch = createSwitch(action: #selector(toggleTextColor(_:)))
        
        // 文本字体开关
        let textFontLabel = createLabel(text: "切换文本字体:")
        textFontSwitch = createSwitch(action: #selector(toggleTextFont(_:)))
        
        // 轮播间隔开关
        let intervalLabel = createLabel(text: "切换轮播间隔:")
        intervalSwitch = createSwitch(action: #selector(toggleInterval(_:)))
        
        // 背景色开关
        let contentColorLabel = createLabel(text: "切换背景颜色:")
        contentColorSwitch = createSwitch(action: #selector(toggleContentColor(_:)))
        
        // 添加到视图
        let controls = [
            (placeholderLabel, placeholderSwitch),
            (textColorLabel, textColorSwitch),
            (textFontLabel, textFontSwitch),
            (intervalLabel, intervalSwitch),
            (contentColorLabel, contentColorSwitch)
        ]
        
        var previousView: UIView? = testButton
        for (label, switchControl) in controls {
            view.addSubview(label)
            view.addSubview(switchControl!)
            
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                label.topAnchor.constraint(equalTo: previousView!.bottomAnchor, constant: 20),
                
                switchControl!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                switchControl!.centerYAnchor.constraint(equalTo: label.centerYAnchor)
            ])
            
            previousView = label
        }
    }
    
    /// 创建标签
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    /// 创建开关
    private func createSwitch(action: Selector) -> UISwitch {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: action, for: .valueChanged)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }
    
    /// 设置约束
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 滚动文本约束
            scrollText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollText.heightAnchor.constraint(equalToConstant: 40),
            
            // 测试按钮约束
            testButton.topAnchor.constraint(equalTo: scrollText.bottomAnchor, constant: 30),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - 配置滚动文本
    
    /// 配置滚动文本属性
    private func configureScrollText() {
        // 设置文本数组
        scrollText.textArray = testTexts
        
        // 设置占位文本
        scrollText.placeholder = "这是占位文本"
        
        // 设置文本颜色
        scrollText.textColor = .black
        
        // 设置文本字体
        scrollText.textFont = UIFont.systemFont(ofSize: 16)
        
        // 设置轮播间隔
        scrollText.interval = 3.0
        
        // 设置背景色
        scrollText.contentColor = .lightGray.withAlphaComponent(0.3)
        
        // 设置代理
        scrollText.delegate = self
        
        // 设置点击回调
        scrollText.didClick { index in
            print("Block回调: 点击了第 \(index) 项")
        }
    }
    
    // MARK: - 测试方法
    
    /// 更改文本数组
    @objc private func changeTextArray() {
        let newTexts = [
            "新的第一条文本",
            "新的第二条文本，长度不同",
            "第三条新文本",
            "这是更新的第四条文本内容",
            "最后一条文本"
        ]
        
        scrollText.textArray = newTexts
        print("文本数组已更改")
    }
    
    /// 切换占位文本显示
    @objc private func togglePlaceholder(_ sender: UISwitch) {
        if sender.isOn {
            scrollText.placeholder = "这是占位文本"
            // 设置为空数组以触发占位文本
            scrollText.textArray = []
        } else {
            // 恢复原始文本数组
            scrollText.textArray = testTexts
        }
        print("占位文本状态: \(sender.isOn ? "显示" : "隐藏")")
    }
    
    /// 切换文本颜色
    @objc private func toggleTextColor(_ sender: UISwitch) {
        scrollText.textColor = sender.isOn ? .blue : .black
        print("文本颜色: \(sender.isOn ? "蓝色" : "黑色")")
    }
    
    /// 切换文本字体
    @objc private func toggleTextFont(_ sender: UISwitch) {
        scrollText.textFont = sender.isOn ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 16)
        print("文本字体: \(sender.isOn ? "粗体18号" : "常规16号")")
    }
    
    /// 切换轮播间隔
    @objc private func toggleInterval(_ sender: UISwitch) {
        scrollText.interval = sender.isOn ? 5.0 : 3.0
        print("轮播间隔: \(sender.isOn ? "5秒" : "3秒")")
    }
    
    /// 切换背景颜色
    @objc private func toggleContentColor(_ sender: UISwitch) {
        scrollText.contentColor = sender.isOn ? .yellow.withAlphaComponent(0.2) : .lightGray.withAlphaComponent(0.3)
        print("背景颜色已\(sender.isOn ? "更改" : "恢复")")
    }
    
    deinit {
        WYLogManager.output("WYTestScrollTextController release")
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

extension WYTestScrollTextController: WYScrollTextDelegate {
    
    /// 项点击事件代理方法
    func itemDidClick(_ itemIndex: Int) {
        print("代理方法: 点击了第 \(itemIndex) 项")
    }
}
