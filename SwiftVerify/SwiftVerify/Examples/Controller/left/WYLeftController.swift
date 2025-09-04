//
//  WYLeftController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYLeftController: UIViewController {

    // 由于字典是无序的，所以每次显示的排序位置都可能会不一样
    let cellObjs: [String: String] = [
        "暗夜、白昼模式": "WYTestDarkNightModeController",
        "约束view添加动画": "WYTestAnimationController",
        "边框、圆角、阴影、渐变": "WYTestVisualController",
        "ButtonEdgeInsets": "WYTestButtonEdgeInsetsController",
        "Banner": "WYTestBannerController",
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
        "ScrollText": "WYTestScrollTextController",
        "分页控制器": "WYTestPagingViewController"
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
        WYNetworkStatus.listening("left") { status in
            switch status {
            case .notReachable:
                WYActivity.showInfo("无网络连接")
            case .unknown :
                WYActivity.showInfo("未知网络连接状态")
            case .reachable(.ethernetOrWiFi):
                WYActivity.showInfo("连接到WiFi网络")
            case .reachable(.cellular):
                WYActivity.showInfo("连接到移动网络")
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

extension WYLeftController: UITableViewDelegate, UITableViewDataSource {

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

extension WYLeftController: AppEventDelegate {
    func didShowBannerView(data: String) {
        WYLogManager.output("data = \(data), controller: \(type(of: self))")
    }
}
