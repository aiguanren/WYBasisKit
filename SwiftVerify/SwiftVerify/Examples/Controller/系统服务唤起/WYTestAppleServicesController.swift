//
//  WYTestAppleServicesController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/30.
//

import UIKit
import SnapKit
import WYBasisKitSwift

/// 系统服务唤起测试页(邮件、短信、电话、系统设置页、App Store，唤起失败的路径会弹提示)
class WYTestAppleServicesController: UIViewController {

    /// 内容滚动区(字段与按钮较多，小屏也放得下)
    let scrollView = UIScrollView()

    /// 字段与按钮竖排容器
    let stackView = UIStackView()

    /// 收件人邮箱输入框(默认填一段测试值，可换成真实邮箱)
    let mailToField = UITextField()

    /// 邮件主题输入框
    let mailSubjectField = UITextField()

    /// 邮件正文输入框
    let mailBodyField = UITextField()

    /// 收件人手机号输入框(短信与电话共用)
    let phoneField = UITextField()

    /// 短信内容输入框
    let smsBodyField = UITextField()

    /// App Store 数字 id 输入框(默认填一段测试值，可换成真实 App 的 id)
    let appIdField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupViews()
    }

    /// 布局界面并挂按钮点击事件
    private func setupViews() {

        stackView.axis = .vertical
        stackView.spacing = 16
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        configField(mailToField, text: "test@example.com", placeholder: "收件人邮箱")
        configField(mailSubjectField, text: "主题测试", placeholder: "邮件主题")
        configField(mailBodyField, text: "正文测试", placeholder: "邮件正文")
        configField(phoneField, text: "10086", placeholder: "手机号(短信与电话共用)")
        configField(smsBodyField, text: "短信内容测试", placeholder: "短信内容")
        configField(appIdField, text: "310633997", placeholder: "App Store 数字 id")

        addButton(title: "发邮件", action: #selector(sendMailClicked))
        addButton(title: "发短信", action: #selector(sendSmsClicked))
        addButton(title: "打电话", action: #selector(callClicked))
        addButton(title: "跳App设置页", action: #selector(openSettingsClicked))
        addButton(title: "App Store 详情页", action: #selector(openAppStoreClicked))
        addButton(title: "去评分", action: #selector(writeReviewClicked))
    }

    /// 配置一个圆角输入框并加入竖排容器
    private func configField(_ field: UITextField, text: String, placeholder: String) {

        field.text = text
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .systemFont(ofSize: 14)
        field.clearButtonMode = .whileEditing
        stackView.addArrangedSubview(field)
        field.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    /// 造一个动作按钮并加入竖排容器
    private func addButton(title: String, action: Selector) {

        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    /// 点击发邮件
    @objc private func sendMailClicked() {

        WYAppleServices.sendMail(to: [mailToField.text ?? ""], subject: mailSubjectField.text ?? "", body: mailBodyField.text ?? "") { [weak self] success in
            if !success {
                self?.showResult("唤起失败，设备可能没有可用邮件应用")
            }
        }
    }

    /// 点击发短信
    @objc private func sendSmsClicked() {

        WYAppleServices.sendSms(to: [phoneField.text ?? ""], body: smsBodyField.text ?? "") { [weak self] success in
            if !success {
                self?.showResult("唤起失败，设备可能不支持发短信")
            }
        }
    }

    /// 点击打电话
    @objc private func callClicked() {

        WYAppleServices.call(number: phoneField.text ?? "") { [weak self] success in
            // 模拟器没有电话应用也会走这里
            if !success {
                self?.showResult("唤起失败，设备可能不支持拨号")
            }
        }
    }

    /// 点击跳系统设置里当前 App 的设置页
    @objc private func openSettingsClicked() {

        WYAppleServices.openAppSettings { [weak self] success in
            if !success {
                self?.showResult("唤起失败，系统无法打开设置页")
            }
        }
    }

    /// 点击打开 App Store 详情页
    @objc private func openAppStoreClicked() {

        WYAppleServices.openAppPage(appId: appIdField.text ?? "") { [weak self] success in
            if !success {
                self?.showResult("唤起失败，系统无法打开 App Store")
            }
        }
    }

    /// 点击打开 App Store 评分页
    @objc private func writeReviewClicked() {

        WYAppleServices.writeReview(appId: appIdField.text ?? "") { [weak self] success in
            if !success {
                self?.showResult("唤起失败，系统无法打开 App Store")
            }
        }
    }

    /// 弹出结果提示
    private func showResult(_ message: String) {

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    deinit {
        WYLogManager.output("WYTestAppleServicesController release")
    }
}
