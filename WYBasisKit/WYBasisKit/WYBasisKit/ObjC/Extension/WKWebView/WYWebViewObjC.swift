//
//  WKWebView.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/26.
//

import WebKit
import Foundation
#if canImport(WYBasisKitSwift)
import WYBasisKitSwift
#endif

/// WKWebView 进度条扩展
@objc public extension WKWebView {

    /// 进度条颜色（默认 lightGray）
    @objc(wy_progressTintColor)
    var wy_progressTintColorObjC: UIColor {
        get { return wy_progressTintColor }
        set { wy_progressTintColor = newValue }
    }

    /// 进度条背景颜色（默认透明）
    @objc(wy_trackTintColor)
    var wy_trackTintColorObjC: UIColor {
        get { return wy_trackTintColor }
        set { wy_trackTintColor = newValue }
    }

    /// 进度条高度（默认 2）
    @objc(wy_progressHeight)
    var wy_progressHeightObjC: CGFloat {
        get { return wy_progressHeight }
        set { wy_progressHeight = newValue }
    }

    /// 启用进度条监听
    @objc(wy_enableProgressView)
    func wy_enableProgressViewObjC() {
        wy_enableProgressView()
    }
    
    /// 事件监听代理
    @objc(wy_navigationProxy)
    var wy_navigationProxyObjC: WYWebViewNavigationDelegateProxy? {
        get { return wy_navigationProxy }
        set { wy_navigationProxy = newValue }
    }
}
