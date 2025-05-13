//
//  WYLeftController.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/3.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYLeftController: UIViewController {

    let cellTitles: [String] = ["暗夜、白昼模式",
                                "约束view添加动画",
                                "边框、圆角、阴影、渐变",
                                "ButtonEdgeInsets",
                                "Banner",
                                "RichText",
                                "无限层折叠TableView",
                                "tableView.plain",
                                "tableView.grouped",
                                "下载",
                                "网络请求",
                                "屏幕旋转",
                                "二维码",
                                "Gif",
                                "瀑布流",
                                "直播、点播播放器",
                                "IM即时通讯",
                                "语音识别",
                                "泛型",
                                "离线方法调用",
                                "WKWebView进度条"]

    let controller: [String] = ["WYTestDarkNightModeController",
                                "WYTestAnimationController",
                                "WYTestVisualController",
                                "WYTestButtonEdgeInsetsController",
                                "WYTestBannerController",
                                "WYTestRichTextController",
                                "WYMultilevelTableViewController",
                                "WYTableViewPlainController",
                                "WYTableViewGroupedController",
                                "WYTestDownloadController",
                                "WYTestRequestController",
                                "WYTestInterfaceOrientationController",
                                "WYQRCodeController",
                                "WYParseGifController",
                                "WYFlowLayoutAlignmentController",
                                "WYTestLiveStreamingController",
                                "WYTestChatController",
                                "WYSpeechRecognitionController",
                                "WYGenericTypeController",
                                "WYOffLineMethodController",
                                "WYWebViewController"]

    lazy var tableView: UITableView = {

        let tableview = UITableView.wy_shared(style: .plain, separatorStyle: .singleLine, delegate: self, dataSource: self, superView: view)
        tableview.wy_register(UITableViewCell.self, .cell)
        tableview.wy_register(WYLeftControllerHeaderView.self, .headerFooterView)
        tableview.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(wy_navViewHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-wy_tabBarHeight)
        }
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationItem.title = "各种测试样例"
        tableView.backgroundColor = UIColor.wy_dynamic(.white, .black)
        
        WYProtocolManager.shared.add(delegate: self)
        
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

        return cellTitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)

        cell.textLabel?.text = cellTitles[indexPath.row]
        cell.textLabel?.textColor = UIColor.wy_dynamic(.black, .white)
        //cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.font = .systemFont(ofSize: wy_screenWidth(15))

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let className: String = controller[indexPath.row]
        wy_showViewController(className: className)
    }
}

extension WYLeftController: WYProtocoDelegate {
    
    func test() {
        wy_print("按钮开始向下移动")
    }
    
    func test2() {
        wy_print("按钮开始归位")
    }
}
