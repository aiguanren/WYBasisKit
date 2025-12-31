//
//  WYMainController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYMainController: UIViewController {
    
    // 由于字典是无序的，所以每次显示的排序位置都可能会不一样
    let cellObjs: [String: String] = [
        "暗夜、白昼模式": "WYTestDarkNightModeController",
        "约束view添加动画": "WYTestAnimationController",
        "边框、圆角、阴影、渐变": "WYTestVisualController",
        "ButtonEdgeInsets": "WYTestButtonEdgeInsetsController",
        "Banner轮播": "WYTestBannerController",
        "富文本": "WYTestRichTextController",
        "无限层折叠TableView": "WYMultilevelTableViewController",
        "tableView.plain": "WYTableViewPlainController",
        "tableView.grouped": "WYTableViewGroupedController",
        "下载与缓存": "WYTestDownloadController",
        "网络请求": "WYTestRequestController",
        "屏幕旋转": "WYTestInterfaceOrientationController",
        "二维码": "WYQRCodeController",
        "Gif加载": "WYParseGifController",
        "瀑布流": "WYFlowLayoutAlignmentController",
        "直播、点播播放器": "WYTestLiveStreamingController",
        "IM即时通讯(开发中)": "WYTestChatController",
        "语音识别": "WYSpeechRecognitionController",
        "泛型": "WYGenericTypeController",
        "离线方法调用": "WYOffLineMethodController",
        "WKWebView进度条": "WYWebViewController",
        "归档/解归档": "WYArchivedController",
        "日志输出与保存": "WYLogController",
        "音频录制与播放": "TestAudioController",
        "设备振动": "WYTestVibrateController",
        "文本轮播": "WYTestScrollTextController",
        "分页控制器": "WYTestPagingViewController",
        "TableViewCell侧滑": "WYTestSideslipCellController"
    ]
    
    lazy var tableView: UITableView = {
        
        let tableview = UITableView.wy_shared(style: .plain, separatorStyle: .singleLine, delegate: self, dataSource: self, superView: view)
        tableview.wy_register(UITableViewCell.self, .cell)
        tableview.wy_register(WYLeftControllerHeaderView.self, .headerFooterView)
        tableview.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UIDevice.wy_tabBarHeight)
        }
        return tableview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        navigationItem.title = "各种测试样例"
        tableView.backgroundColor = UIColor.wy_dynamic(.white, .black)
        
        WYEventHandler.shared.register(event: AppEvent.buttonDidMove, target: self) { data in
            if let stringValue = data {
                WYLogManager.output("data = \(stringValue), controller: \(type(of: self))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.buttonDidReturn, target: self) { data in
            if let stringValue = data {
                WYLogManager.output("data = \(stringValue), controller: \(type(of: self))")
            }
        }
        
        WYEventHandler.shared.register(event: AppEvent.didShowBannerView, target: self) { [weak self] data in
            if let dataString = data as? String,
               let delegate = self {
                delegate.didShowBannerView(data: dataString)
            }
        }
        
        // 网络监听
        WYNetworkStatus.listening("left") { nwpath in
            
            // ✅ 是否已连接网络
            if WYNetworkStatus.isReachable {
                WYLogManager.output("✅ 网络连接正常")
            }
            
            // ❌ 是否无法连接
            if WYNetworkStatus.isNotReachable {
                WYLogManager.output("❌ 当前没有网络连接（可能是飞行模式、断网或信号太差）")
            }
            
            // ⚠️ 是否需要额外步骤（如登录认证）
            if WYNetworkStatus.requiresConnection {
                WYLogManager.output("⚠️ 网络需要建立连接（可能需要认证登录）")
            }
            
            // 📱 是否蜂窝数据网络
            if WYNetworkStatus.isReachableOnCellular {
                WYLogManager.output("📱 当前使用蜂窝移动网络（4G/5G 数据流量）")
            }
            
            // 📶 是否 Wi-Fi
            if WYNetworkStatus.isReachableOnWiFi {
                WYLogManager.output("📶 当前通过 Wi-Fi 连接网络")
            }
            
            // 🖥️ 是否有线网络
            if WYNetworkStatus.isReachableOnWiredEthernet {
                WYLogManager.output("🖥️ 当前使用有线网络（例如 Lightning 转网线适配器）")
            }
            
            // 🛡️ 是否 VPN 连接
            if WYNetworkStatus.isReachableOnVPN {
                WYLogManager.output("🛡️ 当前通过 VPN 连接（加密通道，可能改变出口 IP）")
            }
            
            // 🔁 是否本地回环接口
            if WYNetworkStatus.isLoopback {
                WYLogManager.output("🔁 当前网络是本地回环接口（仅限设备内部通信）")
            }
            
            // 💰 是否昂贵连接（蜂窝或热点）
            if WYNetworkStatus.isExpensive {
                WYLogManager.output("💰 当前网络连接昂贵（例如蜂窝数据或个人热点）")
            }
            
            // 🌐 是否其他(未知类型)
            if WYNetworkStatus.isReachableOnOther {
                WYLogManager.output("🌐 当前是其他(未知类型)的网络接口（不在常规分类中）")
            }
            
            // 🌍 是否支持 IPv4
            if WYNetworkStatus.supportsIPv4 {
                WYLogManager.output("🌍 当前网络支持 IPv4 协议")
            }
            
            // 🌏 是否支持 IPv6
            if WYNetworkStatus.supportsIPv6 {
                WYLogManager.output("🌏 当前网络支持 IPv6 协议")
            }
            
            // 🧩 当前网络状态值
            let status = nwpath.status
            switch status {
            case .satisfied:
                WYActivity.showInfo("🟢 当前网络状态：已连接（satisfied）")
            case .unsatisfied:
                WYActivity.showInfo("🔴 当前网络状态：未连接（unsatisfied）")
            case .requiresConnection:
                WYActivity.showInfo("🟡 当前网络状态：需要额外连接步骤（requiresConnection）")
            @unknown default:
                WYActivity.showInfo("⚪️ 当前网络状态：未知")
            }
        }
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

extension WYMainController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellObjs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        
        cell.textLabel?.text = Array(cellObjs.keys)[indexPath.row]
        cell.textLabel?.textColor = UIColor.wy_dynamic(.black, .white)
        //cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = .systemFont(ofSize: UIDevice.wy_screenWidth(15))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let className: String = Array(cellObjs.values)[indexPath.row]
        let nextController = wy_showViewController(className: className)
        nextController?.navigationItem.title = Array(cellObjs.keys)[indexPath.row]
    }
}

extension WYMainController: AppEventDelegate {
    func didShowBannerView(data: String) {
        WYLogManager.output("data = \(data), controller: \(type(of: self))")
    }
}
