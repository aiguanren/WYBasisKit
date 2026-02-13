//
//  WYMainController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYMainController: UIViewController {
    
    struct ListItem {
        let title: String
        let controller: String
    }
    
    let cellItems: [ListItem] = [
        ListItem(title: "暗夜、白昼模式",
                 controller: "WYTestDarkNightModeController"),
        
        ListItem(title: "约束view添加动画",
                 controller: "WYTestAnimationController"),
        
        ListItem(title: "边框、圆角、阴影、渐变",
                 controller: "WYTestVisualController"),
        
        ListItem(title: "ButtonEdgeInsets",
                 controller: "WYTestButtonEdgeInsetsController"),
        
        ListItem(title: "Banner轮播",
                 controller: "WYTestBannerController"),
        
        ListItem(title: "富文本",
                 controller: "WYTestRichTextController"),
        
        ListItem(title: "无限层折叠TableView",
                 controller: "WYMultilevelTableViewController"),
        
        ListItem(title: "tableView.plain",
                 controller: "WYTableViewPlainController"),
        
        ListItem(title: "tableView.grouped",
                 controller: "WYTableViewGroupedController"),
        
        ListItem(title: "下载与缓存",
                 controller: "WYTestDownloadController"),
        
        ListItem(title: "网络请求",
                 controller: "WYTestRequestController"),
        
        ListItem(title: "屏幕旋转",
                 controller: "WYTestInterfaceOrientationController"),
        
        ListItem(title: "二维码",
                 controller: "WYQRCodeController"),
        
        ListItem(title: "Gif加载",
                 controller: "WYParseGifController"),
        
        ListItem(title: "瀑布流",
                 controller: "WYFlowLayoutAlignmentController"),
        
        ListItem(title: "直播、点播播放器",
                 controller: "WYTestLiveStreamingController"),
        
        ListItem(title: "语音识别",
                 controller: "WYSpeechRecognitionController"),
        
        ListItem(title: "泛型",
                 controller: "WYGenericTypeController"),
        
        ListItem(title: "离线方法调用",
                 controller: "WYOffLineMethodController"),
        
        ListItem(title: "WKWebView",
                 controller: "WYWebViewController"),
        
        ListItem(title: "归档/解归档",
                 controller: "WYArchivedController"),
        
        ListItem(title: "日志输出与保存",
                 controller: "WYLogController"),
        
        ListItem(title: "音频录制与播放",
                 controller: "WYTestAudioController"),
        
        ListItem(title: "设备振动",
                 controller: "WYTestVibrateController"),
        
        ListItem(title: "文本轮播",
                 controller: "WYTestScrollTextController"),
        
        ListItem(title: "分页控制器",
                 controller: "WYTestPagingViewController"),
        
        ListItem(title: "TableViewCell侧滑",
                 controller: "WYTestSideslipCellController"),
        
        ListItem(title: "图片拼接",
                 controller: "WYTestCombineImagesController"),
        
        ListItem(title: "IM即时通讯(开发中)",
                 controller: "WYTestChatController")
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
        
        return cellItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        
        cell.textLabel?.text = cellItems[indexPath.row].title
        cell.textLabel?.textColor = UIColor.wy_dynamic(.black, .white)
        //cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = .systemFont(ofSize: UIDevice.wy_screenWidth(15))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let className: String = cellItems[indexPath.row].controller
        let nextController = wy_showViewController(className: className)
        nextController?.navigationItem.title = cellItems[indexPath.row].title
    }
}

extension WYMainController: AppEventDelegate {
    func didShowBannerView(data: String) {
        WYLogManager.output("data = \(data), controller: \(type(of: self))")
    }
}
