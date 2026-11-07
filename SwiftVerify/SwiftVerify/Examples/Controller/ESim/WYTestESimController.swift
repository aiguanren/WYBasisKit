//
//  WYTestESimController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/10/30.
//

import UIKit
import SnapKit
import WYBasisKitSwift

/// eSIM 能力查询、安装链接请求与二维码示例
class WYTestESimController: UIViewController {

    /// LPA 串输入框(默认填一段测试值，可粘贴获取到的真实 LPA 串)
    let lpaTextField = UITextField()

    /// 立即安装按钮
    let installButton = UIButton(type: .system)

    /// 生成二维码按钮
    let qrCodeButton = UIButton(type: .system)

    /// LPA 串二维码展示图
    let qrCodeImageView = UIImageView()

    /// 能力查询按钮
    let capabilityButton = UIButton(type: .system)

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
        lpaTextField.font = .systemFont(ofSize: UIFont.wy_fontSize(14, WYBasisKitConfig.defaultScreenPixels))
        lpaTextField.clearButtonMode = .whileEditing
        view.addSubview(lpaTextField)

        installButton.setTitle("请求打开安装入口", for: .normal)
        installButton.addTarget(self, action: #selector(installClicked), for: .touchUpInside)
        view.addSubview(installButton)

        qrCodeButton.setTitle("生成二维码", for: .normal)
        qrCodeButton.addTarget(self, action: #selector(qrCodeClicked), for: .touchUpInside)
        view.addSubview(qrCodeButton)

        capabilityButton.setTitle("查看 eSIM 能力", for: .normal)
        capabilityButton.addTarget(self, action: #selector(capabilityClicked), for: .touchUpInside)
        view.addSubview(capabilityButton)

        qrCodeImageView.contentMode = .scaleAspectFit
        view.addSubview(qrCodeImageView)

        lpaTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels))
            make.leading.trailing.equalToSuperview().inset(UIDevice.wy_screenWidth(24, WYBasisKitConfig.defaultScreenPixels))
            make.height.equalTo(UIDevice.wy_screenHeight(44, WYBasisKitConfig.defaultScreenPixels))
        }

        capabilityButton.snp.makeConstraints { make in
            make.top.equalTo(lpaTextField.snp.bottom).offset(UIDevice.wy_screenHeight(16, WYBasisKitConfig.defaultScreenPixels))
            make.centerX.equalToSuperview()
        }

        installButton.snp.makeConstraints { make in
            make.top.equalTo(capabilityButton.snp.bottom).offset(UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels))
            make.centerX.equalToSuperview()
        }

        qrCodeButton.snp.makeConstraints { make in
            make.top.equalTo(installButton.snp.bottom).offset(UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels))
            make.centerX.equalToSuperview()
        }

        qrCodeImageView.snp.makeConstraints { make in
            make.top.equalTo(qrCodeButton.snp.bottom).offset(UIDevice.wy_screenHeight(24, WYBasisKitConfig.defaultScreenPixels))
            make.centerX.equalToSuperview()
            make.width.height.equalTo(UIDevice.wy_screenWidth(240, WYBasisKitConfig.defaultScreenPixels))
        }
    }

    /// 请求打开 eSIM 安装入口
    @objc private func installClicked() {

        WYAppleServices.requestEsimInstallation(lpa: lpaTextField.text ?? "") { [weak self] result in
            switch result {
            case .invalidLpa: self?.showResult("LPA 格式不合法")
            case .linkUnavailable: self?.showResult("系统版本没有 eSIM 通用链接入口，请使用二维码或运营商提供的方式")
            case .requestRejected: self?.showResult("系统未接受 eSIM 安装链接，不能据此判断设备不支持")
            case .requestAccepted: self?.showResult("系统已接受链接，请在系统设置中确认安装与激活结果")
            @unknown default: self?.showResult("无法确定请求结果")
            }
        }
    }

    /// 查询 eSIM 能力
    @objc private func capabilityClicked() {
        let capability = WYAppleServices.esimCapability
        let hardware = capability == .unknown ? "无法确定" : capability == .unsupported ? "已确认不支持" : "已确认支持"
        let link = WYAppleServices.isEsimInstallationLinkAvailable ? "系统版本提供入口" : "系统版本没有入口"
        showResult("eSIM 硬件：\(hardware)\n大陆与境外运营商适用范围：无法确定\n链接入口：\(link)\n可在设置的蜂窝网络中检查添加 eSIM，并由运营商核对设备与套餐资格")
    }

    /// 点击生成二维码，把 LPA 串编成二维码展示
    @objc private func qrCodeClicked() {

        // 按显示尺寸乘屏幕缩放比生成，保证二维码清晰
        let side = UIDevice.wy_screenWidth(240, WYBasisKitConfig.defaultScreenPixels) * max(traitCollection.displayScale, 1)
        qrCodeImageView.image = WYAppleServices.qrCode(lpa: lpaTextField.text ?? "", size: CGSize(width: side, height: side))
        if qrCodeImageView.image == nil { showResult("LPA 格式不合法或无法生成二维码") }
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
