//
//  WYTestLabelViewController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/9/20.
//

import UIKit

class WYTestLabelViewController: UIViewController {

    /// 点击效果颜色（按下时的背景色）
    var clickEffectColor: UIColor?

    /// 长按效果颜色（长按时背景色，未设置时回退点击效果色）
    var longPressEffectColor: UIColor?

    /// 文本自带背景色时按下高亮要不要盖住它，默认 true(为 false 时自带背景色的文本按下不显示高亮)
    var overlaysOriginalBackground: Bool = true

    /// 长按手势触发的最小时长（秒），默认 0.5 秒
    var longPressMinimumDuration: TimeInterval = 0.5

    /// 是否模仿 UIButton 的 TouchUpInside(按下并抬起在同一富文本上才触发)，默认 true，为 false 时按下命中立即触发
    var touchUpInside: Bool = true

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

        let clickEffectColorView: UIButton = createButton(title: "点击效果颜色", selector: #selector(selectedClickEffectColor), superView: contentView, leftView: nil, topView: nil)

        let longPressEffectColorView: UIButton = createButton(title: "长按效果颜色", selector: #selector(selectedLongPressEffectColor), superView: contentView, leftView: clickEffectColorView, topView: nil)

        let longPressMinimumDurationView: UIButton = createButton(title: "长按手势触发\n的最小时长", selector: #selector(longPressMinimumDuration(sender:)), superView: contentView, leftView: longPressEffectColorView, topView: nil, isRight: true)

        let overlaysOriginalBackgroundView: UIButton = createButton(title: "(覆盖)自带\n背景色高亮", selector: #selector(overlaysOriginalBackground(sender:)), superView: contentView, leftView: nil, topView: longPressMinimumDurationView)
        overlaysOriginalBackgroundView.setTitle("(忽略)自带\n背景色高亮", for: .selected)

        let useCustomFontView: UIButton = createButton(title: "未使用自定义字体", selector: #selector(useCustomFont(sender:)), superView: contentView, leftView: overlaysOriginalBackgroundView, topView: longPressMinimumDurationView)
        useCustomFontView.setTitle("已使用自定义字体", for: .selected)

        let randomTextView: UIButton = createButton(title: "未使用随机文本", selector: #selector(useRandomText(sender:)), superView: contentView, leftView: useCustomFontView, topView: longPressMinimumDurationView, isRight: true)
        randomTextView.setTitle("已使用随机文本", for: .selected)

        let touchUpInsideView: UIButton = createButton(title: "(已开启)\n抬起时触发", selector: #selector(touchUpInsideToggle(sender:)), superView: contentView, leftView: nil, topView: overlaysOriginalBackgroundView, isLast: true)
        touchUpInsideView.setTitle("(已关闭)\n抬起时触发", for: .selected)

        tableView = UITableView.wy_shared(delegate: self, dataSource: self, superView: view)
        tableView?.wy_register(WYTestLabelCell.self, .cell)
        tableView?.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }

    func createButton(title: String, selector: Selector, superView: UIView, leftView: UIView?, topView: UIView?, isRight: Bool = false, isLast: Bool = false) -> UIButton {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.setTitleColor(.wy_random, for: .normal)
        button.wy_addBorder(edges: .all, color: .wy_random, thickness: 1)
        button.addTarget(self, action: selector, for: .touchUpInside)
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

    @objc func overlaysOriginalBackground(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        overlaysOriginalBackground = !sender.isSelected
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

    @objc func touchUpInsideToggle(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        touchUpInside = !sender.isSelected
        tableView?.reloadData()
    }

    deinit {
        wy_print("WYTestLabelViewController release")
    }

}

extension WYTestLabelViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: WYTestLabelCell = tableView.dequeueReusableCell(withIdentifier: "WYTestLabelCell", for: indexPath) as! WYTestLabelCell
        cell.reload(clickEffectColor: clickEffectColor, longPressEffectColor: longPressEffectColor, overlaysOriginalBackground: overlaysOriginalBackground, longPressMinimumDuration: longPressMinimumDuration,
                    touchUpInside: touchUpInside,
                    useCustomFont: useCustomFont,
                    randomText: randomText)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
