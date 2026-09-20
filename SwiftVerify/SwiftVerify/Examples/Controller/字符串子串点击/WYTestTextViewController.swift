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
    
    /// 长按效果颜色（长按时背景色，未设置时回退点击效果色）
    var longPressEffectColor: UIColor?
    
    /// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 false 时自带背景色的文本按下不显示高亮)
    var overlaysOriginalBackground: Bool = true
    
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
        
        let longPressEffectColorView: UIButton = createButton(title: "长按效果颜色", selecror: #selector(selectedLongPressEffectColor), superView: contentView, leftView: clickEffectColorView, topView: nil)
        
        let longPressMinimumDurationView: UIButton = createButton(title: "长按手势触发\n的最小时长", selecror: #selector(longPressMinimumDuration(sender:)), superView: contentView, leftView: longPressEffectColorView, topView: nil, isRight: true)
        
        let eventPenetrationView: UIButton = createButton(title: "(已关闭)非链接\n区域事件穿透", selecror: #selector(eventPenetration(sender:)), superView: contentView, leftView: nil, topView: longPressMinimumDurationView)
        eventPenetrationView.setTitle("(已开启)非链接\n区域事件穿透", for: .selected)
        
        let useCustomFontView: UIButton = createButton(title: "未使用自定义字体", selecror: #selector(useCustomFont(sender:)), superView: contentView, leftView: eventPenetrationView, topView: longPressMinimumDurationView)
        useCustomFontView.setTitle("已使用自定义字体", for: .selected)
        
        let randomTextView: UIButton = createButton(title: "未使用随机文本", selecror: #selector(useRandomText(sender:)), superView: contentView, leftView: useCustomFontView, topView: longPressMinimumDurationView, isRight: true, isLast: true)
        randomTextView.setTitle("已使用随机文本", for: .selected)
        
        let overlaysOriginalBackgroundView: UIButton = createButton(title: "(覆盖)自带\n背景色高亮", selecror: #selector(overlaysOriginalBackground(sender:)), superView: contentView, leftView: nil, topView: eventPenetrationView, isLast: true)
        overlaysOriginalBackgroundView.setTitle("(忽略)自带\n背景色高亮", for: .selected)
        
        tableView = UITableView.wy_shared(delegate: self, dataSource: self, superView: view)
        tableView?.wy_register(WYTestTextViewCell.self, .cell)
        tableView?.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        
        // 点击空白处或任意文本收起键盘(不拦截不延迟触摸，交互词的点击/长按回调不受影响)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(tapGesture)
        
        // 滑动列表时收起键盘
        tableView?.keyboardDismissMode = .onDrag
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
    
    @objc func selectedLongPressEffectColor() {
        UIAlertController.wy_show(style: .alert,title: "长按效果颜色", message: "长按时背景色，未设置时先回退点击效果色，再跟随文本色", actions: ["透明", "随机", "未设置"]) { [weak self] action, inputTexts in
            guard let self = self else { return }
            if action == "透明" {
                longPressEffectColor = .clear
            }else if action == "随机" {
                longPressEffectColor = .wy_random
            }else {
                longPressEffectColor = nil
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
    
    @objc func overlaysOriginalBackground(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        overlaysOriginalBackground = !sender.isSelected
        tableView?.reloadData()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
        cell.reload(clickEffectColor: clickEffectColor, longPressEffectColor: longPressEffectColor, overlaysOriginalBackground: overlaysOriginalBackground, longPressMinimumDuration: longPressMinimumDuration,
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
