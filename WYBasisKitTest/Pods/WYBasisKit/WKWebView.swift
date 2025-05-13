//
//  WKWebView.swift
//  WYBasisKit
//
//  Created by 官人 on 2025/5/13.
//  Copyright © 2020 官人. All rights reserved.
//

import WebKit
import ObjectiveC

private var progressObserverKey: UInt8 = 0

public extension WKWebView {
    
    /// 进度条颜色（默认lightGray）
    var progressTintColor: UIColor {
        get { progressObserver?.progressView.progressTintColor ?? UIColor.lightGray }
        set { progressObserver?.progressView.progressTintColor = newValue }
    }
    
    /// 进度条背景颜色（默认透明）
    var trackTintColor: UIColor {
        get { progressObserver?.progressView.trackTintColor ?? .clear }
        set { progressObserver?.progressView.trackTintColor = newValue }
    }
    
    /// 进度条高度（默认 2）
    var progressHeight: CGFloat {
        get { progressObserver?.height ?? 2 }
        set { progressObserver?.updateHeight(newValue) }
    }
    
    /// 启用进度条监听
    func enableProgressView() {
        guard progressObserver == nil else { return }
        
        let observer = WebViewProgressObserver(webView: self)
        progressObserver = observer
    }
    
    private var progressObserver: WebViewProgressObserver? {
        get { objc_getAssociatedObject(self, &progressObserverKey) as? WebViewProgressObserver }
        set { objc_setAssociatedObject(self, &progressObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private class WebViewProgressObserver: NSObject {
    
    weak var webView: WKWebView?
    let progressView = UIProgressView(progressViewStyle: .default)
    
    /// 初始化时不再硬编码默认高度
    var height: CGFloat {
        webView?.progressHeight ?? 2.0
    }
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        
        setupProgressView()
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    private func setupProgressView() {
        guard let webView = webView else { return }

        webView.layoutIfNeeded()

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        progressView.trackTintColor = webView.trackTintColor
        progressView.progressTintColor = webView.progressTintColor

        webView.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: webView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: height)
        ])
    }
    
    func updateHeight(_ newHeight: CGFloat) {
        for constraint in progressView.constraints where constraint.firstAttribute == .height {
            constraint.constant = newHeight
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "estimatedProgress",
              let webView = webView else { return }
        
        let progress = Float(webView.estimatedProgress)
        progressView.isHidden = progress >= 1.0
        progressView.setProgress(progress, animated: true)
        
        if progress >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.progressView.setProgress(0, animated: false)
            }
        }
    }
}
