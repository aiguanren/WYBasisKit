//
//  WYTestTextViewController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/5/16.
//

import UIKit

class WYTestTextViewController: UIViewController {
    
    /// 点击效果颜色（按下时的背景色）
    var clickEffectColor: UIColor?
    
    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var longPressMinimumDuration: TimeInterval = 0.5
    
    /// 非链接区域事件穿透，默认false，第一响应者为UITextView，为true时将穿透至父View
    var eventPenetration: Bool = false
    
    /// 字符文本的字体
    var useCustomFont: Bool = false
    
    /// 随机文本
    var randomText: Bool = false
    
    var tableView: UITableView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let contentView: UIView = UIView()
        contentView.backgroundColor = .white
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(UIDevice.wy_navViewHeight + 20)
            make.centerX.equalTo(view)
        }
        
        let clickEffectColorView: UIButton = createButton(title: "点击效果颜色", selecror: #selector(selectedClickEffectColor), superView: contentView, leftView: nil, topView: nil)
        
        let longPressMinimumDurationView: UIButton = createButton(title: "长按手势触发\n的最小时长", selecror: #selector(longPressMinimumDuration(sender:)), superView: contentView, leftView: clickEffectColorView, topView: nil)
        
        let eventPenetrationView: UIButton = createButton(title: "(已关闭)非链接\n区域事件穿透", selecror: #selector(eventPenetration(sender:)), superView: contentView, leftView: longPressMinimumDurationView, topView: nil, isRight: true)
        eventPenetrationView.setTitle("(已开启)非链接\n区域事件穿透", for: .selected)
        
        let useCustomFontView: UIButton = createButton(title: "未使用自定义字体", selecror: #selector(useCustomFont(sender:)), superView: contentView, leftView: nil, topView: longPressMinimumDurationView)
        useCustomFontView.setTitle("已使用自定义字体", for: .selected)
        
        let randomTextView: UIButton = createButton(title: "未使用随机文本", selecror: #selector(useRandomText(sender:)), superView: contentView, leftView: useCustomFontView, topView: longPressMinimumDurationView, isLast: true)
        randomTextView.setTitle("已使用随机文本", for: .selected)
        
        tableView = UITableView.wy_shared(delegate: self, dataSource: self, superView: view)
        tableView?.wy_register(WYTestTextViewCell.self, .cell)
        tableView?.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    func createButton(title: String, selecror: Selector, superView: UIView, leftView: UIView?, topView: UIView?, isRight: Bool = false, isLast: Bool = false) -> UIButton {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.setTitleColor(.wy_random, for: .normal)
        button.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        button.addTarget(self, action: selecror, for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        superView.addSubview(button)
        button.snp.makeConstraints { make in
            
            if let leftView = leftView {
                make.left.equalTo(leftView.snp.right).offset(15)
            }else {
                make.left.equalToSuperview()
            }
            
            if (isRight) {
                make.right.equalToSuperview()
            }
            
            if let topView = topView {
                make.top.equalTo(topView.snp.bottom).offset(20)
            }else {
                make.top.equalToSuperview()
            }
            
            if (isLast) {
                make.bottom.equalToSuperview()
            }
            
            make.size.equalTo(CGSize(width: (UIDevice.wy_screenWidth - 60) / 3, height: 50))
        }
        
        return button
    }
    
    @objc func selectedClickEffectColor() {
        UIAlertController.wy_show(style: .alert,title: "点击效果颜色", message: "按下时的背景色", actions: ["透明", "随机", "跟随文本"]) { [weak self] action, inputTexts in
            guard let self = self else { return }
            if action == "透明" {
                clickEffectColor = .clear
            }else if action == "随机" {
                clickEffectColor = .wy_random
            }else {
                clickEffectColor = nil
            }
            tableView?.reloadData()
        }
    }
    
    @objc func longPressMinimumDuration(sender: UIButton) {
        UIAlertController.wy_show(style: .alert,title: "长按手势触发的最小时长(秒)", textFieldPlaceholders: ["当前\(longPressMinimumDuration)秒"], actions: ["确定", "取消"]) { [weak self] action, inputTexts in
            
            guard let self = self else { return }
            
            guard action == "确定" else { return }
            
            if let inputText: String = inputTexts.first {
                longPressMinimumDuration = max(TimeInterval(inputText) ?? 0.5, 0.5)
            }
            tableView?.reloadData()
        }
    }
    
    @objc func eventPenetration(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        eventPenetration = sender.isSelected
        tableView?.reloadData()
    }
    
    @objc func useCustomFont(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        useCustomFont = sender.isSelected
        tableView?.reloadData()
    }
    
    @objc func useRandomText(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        randomText = sender.isSelected
        tableView?.reloadData()
    }
    
    deinit {
        wy_print("WYTestTextViewController release")
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

extension WYTestTextViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: WYTestTextViewCell = tableView.dequeueReusableCell(withIdentifier: "WYTestTextViewCell", for: indexPath) as! WYTestTextViewCell
        cell.reload(clickEffectColor: clickEffectColor, longPressMinimumDuration: longPressMinimumDuration,
                    eventPenetration: eventPenetration,
                    useCustomFont: useCustomFont,
                    randomText: randomText)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        wy_print("点击了UITableView")
    }
}
