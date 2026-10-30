//
//  WYTestESimController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/30.
//

import UIKit
import SnapKit
import WYBasisKitSwift

/// eSIM 安装唤起测试页(输入 LPA 串唤起系统 eSIM 安装页或生成扫码兜底二维码，系统安装页需 iOS 17.4+ 且仅真机支持)
class WYTestESimController: UIViewController {

    /// LPA 串输入框(默认填一段测试值，可粘贴获取到的真实 LPA 串)
    let lpaTextField = UITextField()

    /// 立即安装按钮
    let installButton = UIButton(type: .system)

    /// 生成二维码按钮
    let qrCodeButton = UIButton(type: .system)

    /// LPA 串二维码展示图
    let qrCodeImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupViews()
    }

    /// 布局界面并挂按钮点击事件
    private func setupViews() {

        lpaTextField.text = "1$esim.test.example.com$1EXAMPLE1234567-1"
        lpaTextField.placeholder = "LPA 串"
        lpaTextField.borderStyle = .roundedRect
        lpaTextField.font = .systemFont(ofSize: 14)
        lpaTextField.clearButtonMode = .whileEditing
        view.addSubview(lpaTextField)

        installButton.setTitle("立即安装", for: .normal)
        installButton.addTarget(self, action: #selector(installClicked), for: .touchUpInside)
        view.addSubview(installButton)

        qrCodeButton.setTitle("生成二维码", for: .normal)
        qrCodeButton.addTarget(self, action: #selector(qrCodeClicked), for: .touchUpInside)
        view.addSubview(qrCodeButton)

        qrCodeImageView.contentMode = .scaleAspectFit
        view.addSubview(qrCodeImageView)

        lpaTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        installButton.snp.makeConstraints { make in
            make.top.equalTo(lpaTextField.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        qrCodeButton.snp.makeConstraints { make in
            make.top.equalTo(installButton.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        qrCodeImageView.snp.makeConstraints { make in
            make.top.equalTo(qrCodeButton.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(240)
        }
    }

    /// 点击立即安装，唤起系统 eSIM 安装页
    @objc private func installClicked() {

        guard WYAppleServices.isEsimSupported else {
            showResult("系统低于 iOS 17.4，没有系统 eSIM 安装页")
            return
        }

        // 唤起失败由 WYAppleServices 自动弹默认提示，这里不再重复弹
        if #available(iOS 17.4, *) {
            WYAppleServices.install(lpa: lpaTextField.text ?? "", completion: nil)
        }
    }

    /// 点击生成二维码，把 LPA 串编成二维码展示
    @objc private func qrCodeClicked() {

        // 按显示尺寸乘屏幕缩放比生成，保证二维码清晰
        let side = 240 * max(traitCollection.displayScale, 1)
        qrCodeImageView.image = WYAppleServices.qrCode(lpa: lpaTextField.text ?? "", size: CGSize(width: side, height: side))
    }

    /// 弹出结果提示
    private func showResult(_ message: String) {

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    deinit {
        WYLogManager.output("WYTestESimController release")
    }
}
