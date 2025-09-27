//
//  WKWebView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import WebKit

/// WKWebView 进度条扩展
@objc public extension WKWebView {

    /// 进度条颜色（默认 lightGray）
    @objc(progressTintColor)
    var progressTintColorObjC: UIColor {
        get { return progressTintColor }
        set { progressTintColor = newValue }
    }

    /// 进度条背景颜色（默认透明）
    @objc(trackTintColor)
    var trackTintColorObjC: UIColor {
        get { return trackTintColor }
        set { trackTintColor = newValue }
    }

    /// 进度条高度（默认 2）
    @objc(progressHeight)
    var progressHeightObjC: CGFloat {
        get { return progressHeight }
        set { progressHeight = newValue }
    }

    /// 启用进度条监听
    @objc(enableProgressView)
    func enableProgressViewObjC() {
        enableProgressView()
    }
    
    /// 事件监听代理
    @objc(navigationProxy)
    var navigationProxyObjC: WYWebViewNavigationDelegateProxy? {
        get { return navigationProxy }
        set { navigationProxy = newValue }
    }
}
