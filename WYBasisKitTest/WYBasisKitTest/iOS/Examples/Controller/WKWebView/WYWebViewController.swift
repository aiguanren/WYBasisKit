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
        // 启用加载进度条
        webView.enableProgressView()
        
        // 设置代理派发器
        webView.navigationProxy = self

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

extension WYWebViewController: WKWebViewNavigationDelegateProxy {
    
    /// 重置导航栏标题
    func webPageNavigationTitleChanged(_ title: String, _ isRepeat: Bool) {
        wy_print("webPageNavigationTitleChanged：\(title)， isRepeat：\(isRepeat)")
    }

    /// 页面将要跳转
    func webPageWillChanged(_ urlString: String) {
        wy_print("webPageWillChanged：\(urlString)")
    }

    /// 页面开始加载时调用
    func didStartProvisionalNavigation(_ urlString: String) {
        wy_print("didStartProvisionalNavigation：\(urlString)")
    }
    
    /// 页面加载进度回调
    func webPageLoadProgress(_ progress: CGFloat) {
        wy_print("webPageLoadProgress：\(progress)")
    }

    /// 页面加载失败时调用（首次请求）
    func didFailProvisionalNavigation(_ urlString: String, withError error: NSError) {
        wy_print("didFailProvisionalNavigation：\(urlString)， error：\(error)")
    }

    /// 当内容开始返回时调用
    func didCommitNavigation(_ urlString: String) {
        wy_print("didCommitNavigation：\(urlString)")
    }

    /// 页面加载完成之后调用
    func didFinishNavigation(_ urlString: String) {
        wy_print("didFinishNavigation：\(urlString)")
    }

    /// 提交发生错误时调用（通常指加载后期失败）
    func didFailNavigation(_ urlString: String, withError error: NSError) {
        wy_print("didFailNavigation：\(urlString)，error：\(error)")
    }

    /// 接收到服务器跳转请求（服务重定向时之后调用）
    func didReceiveServerRedirectForProvisionalNavigation(_ urlString: String) {
        wy_print("didReceiveServerRedirectForProvisionalNavigation：\(urlString)")
    }

    /// 根据 WebView 对于即将跳转的 HTTP 请求信息决定是否跳转（iOS 13+ 支持 WebpagePreferences）
    @available(iOS 13.0, *)
    func decidePolicyForNavigationAction(_ navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        wy_print("decidePolicyForNavigationAction：\(navigationAction)，preferences：\(preferences)")
        decisionHandler(.allow, preferences)
    }

    /// 根据客户端收到的服务器响应头决定是否跳转
    func decidePolicyForNavigationResponse(_ navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        wy_print("decidePolicyForNavigationResponse：\(navigationResponse)")
        decisionHandler(.allow)
    }

    /// Web 内容进程被系统终止时调用
    func webViewWebContentProcessDidTerminate() {
        wy_print("webViewWebContentProcessDidTerminate")
    }

    /// 收到身份认证时调用
    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        wy_print("didReceiveAuthenticationChallenge：\(challenge)")
        completionHandler(.performDefaultHandling, nil)
    }
}
