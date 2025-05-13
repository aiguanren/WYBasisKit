//
//  WYWebViewController.swift
//  WYBasisKitTest
//
//  Created by guanren on 2025/5/13.
//  Copyright © 2025 官人. All rights reserved.
//

import UIKit
import WebKit.WKWebView

class WYWebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let webView = WKWebView()
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(wy_navViewHeight + 2)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview().offset(-wy_tabbarSafetyZone)
        }
        webView.enableProgressView()

        // 加载网页
        webView.load(URLRequest(url: URL(string: "https://www.apple.com/cn")!))
    }
    
    deinit {
        wy_print("WYWebViewController release")
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
