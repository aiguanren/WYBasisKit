import WebKit

/// WKWebView 导航代理协议（WKWebViewNavigationDelegateProxy），用于将 WebView 的导航事件分发给业务层或 Objective-C 中间层使用
@objc public protocol WKWebViewNavigationDelegateProxy: AnyObject {
    
    /// 导航栏标题发生变化 isRepeat:当前标题相比上一次是否是重复的
    @objc optional func webPageNavigationTitleChanged(_ title: String, _ isRepeat: Bool)

    /// 页面将要跳转
    @objc optional func webPageWillChanged(_ urlString: String)

    /// 页面开始加载时调用
    @objc optional func didStartProvisionalNavigation(_ urlString: String)
    
    /// 页面加载进度回调
    @objc optional func webPageLoadProgress(_ progress: CGFloat)

    /// 页面加载失败时调用（首次请求）
    @objc optional func didFailProvisionalNavigation(_ urlString: String, withError error: NSError)

    /// 当内容开始返回时调用
    @objc optional func didCommitNavigation(_ urlString: String)

    /// 页面加载完成之后调用
    @objc optional func didFinishNavigation(_ urlString: String)

    /// 提交发生错误时调用（通常指加载后期失败）
    @objc optional func didFailNavigation(_ urlString: String, withError error: NSError)

    /// 接收到服务器跳转请求（服务重定向时之后调用）
    @objc optional func didReceiveServerRedirectForProvisionalNavigation(_ urlString: String)

    /// 根据 WebView 对于即将跳转的 HTTP 请求信息决定是否跳转（iOS 13+ 支持 WebpagePreferences）
    @available(iOS 13.0, *)
    @objc optional func decidePolicyForNavigationAction(_ navigationAction: WKNavigationAction,
                                         preferences: WKWebpagePreferences,
                                         decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void)

    /// 根据客户端收到的服务器响应头决定是否跳转
    @objc optional func decidePolicyForNavigationResponse(_ navigationResponse: WKNavigationResponse,
                                           decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)

    /// Web 内容进程被系统终止时调用
    @objc optional func webViewWebContentProcessDidTerminate()

    /// 收到身份认证时调用
    @objc optional func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge,
                                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

/// WKWebView 进度条扩展
public extension WKWebView {
    
    /// 事件监听代理
    @objc var navigationProxy: WKWebViewNavigationDelegateProxy? {
        get {
            objc_getAssociatedObject(self, &navigationProxyKey) as? WKWebViewNavigationDelegateProxy
        }
        set {
            objc_setAssociatedObject(self, &navigationProxyKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            
            // 创建并绑定 delegator（仅创建一次）
            var delegator = objc_getAssociatedObject(self, &navigationDelegatorKey) as? WKWebViewDelegator
            if delegator == nil {
                delegator = WKWebViewDelegator(proxy: newValue)
                delegator?.bindToWebView(self)
                objc_setAssociatedObject(self, &navigationDelegatorKey, delegator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                // 已有 delegator，仅更新 proxy
                delegator?.proxy = newValue
            }
            
            // 设置 WebView 的 navigationDelegate
            self.navigationDelegate = delegator
        }
    }

    /// 进度条颜色（默认 lightGray）
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
}

/// 使用 KVO 监听 WebView estimatedProgress，展示 UIProgressView
private class WebViewProgressObserver: NSObject {

    /// 被监听的 WKWebView
    weak var webView: WKWebView?

    /// 显示的进度条视图
    let progressView = UIProgressView(progressViewStyle: .default)
    
    private var heightConstraint: NSLayoutConstraint?

    /// 进度条高度（读取自 webView）
    var height: CGFloat {
        webView?.progressHeight ?? 2.0
    }

    /// 初始化并添加 KVO 监听
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        // 创建时赋值
        heightConstraint = progressView.heightAnchor.constraint(equalToConstant: height)
        heightConstraint?.isActive = true

        setupProgressView()
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    /// 移除 KVO
    deinit {
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    /// 设置进度条视图并添加约束
    private func setupProgressView() {
        guard let webView = webView, progressView.superview == nil else { return }
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

    /// 更新进度条高度约束
    func updateHeight(_ newHeight: CGFloat) {
        heightConstraint?.constant = newHeight
        progressView.setNeedsLayout()
    }

    /// 响应 estimatedProgress 变化，更新进度条进度
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "estimatedProgress",
              let webView = webView else { return }

        let progress = Float(webView.estimatedProgress)
        progressView.isHidden = progress >= 1.0
        progressView.setProgress(progress, animated: true)
        
        // 触发两种回调方式
        (webView.navigationDelegate as? WKWebViewDelegator)?.proxy?.webPageLoadProgress?(CGFloat(progress))

        if progress >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.progressView.setProgress(0, animated: false)
            }
        }
    }
}

// WKWebView 代理派发器（WKWebViewDelegator），实现 WKNavigationDelegate，并分发事件给自定义代理 WKWebViewNavigationDelegateProxy
public class WKWebViewDelegator: NSObject, WKNavigationDelegate {
    
    /// 实际处理回调的代理对象（可以为 Objective-C 或 Swift 实现）
    public weak var proxy: WKWebViewNavigationDelegateProxy?
    
    /// 用于监听 WebView 的 title 变化
    private var titleObservation: NSKeyValueObservation?
    
    /// 上一次触发的标题，用于去重
    private var lastTitle: String?

    /// 初始化代理派发器
    public init(proxy: WKWebViewNavigationDelegateProxy?) {
        self.proxy = proxy
    }
    
    /// 绑定 WKWebView，监听 title 属性变化
    public func bindToWebView(_ webView: WKWebView) {
        // 避免重复监听
        titleObservation?.invalidate()
        
        // 使用 KVO 监听 WebView 的 title 属性
        titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, change in
            guard let self = self else { return }
            
            let newTitle = change.newValue ?? nil
            
            // 如果和上一次的标题相同，则说明是重复的标题
            let isRepeat: Bool = (self.lastTitle == newTitle)
            
            self.lastTitle = newTitle
            
            // 回调代理，即使 title 为 nil 也回调
            self.proxy?.webPageNavigationTitleChanged?((newTitle ?? ""), isRepeat)
        }
    }

    /// 页面开始加载时调用（即开始请求）
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        proxy?.didStartProvisionalNavigation?(webView.url?.absoluteString ?? "")
    }

    /// 当内容开始返回时调用（已收到响应数据，但还未渲染完成）
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        proxy?.didCommitNavigation?(webView.url?.absoluteString ?? "")
    }

    /// 页面加载完成时调用（已渲染完成）
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        proxy?.didFinishNavigation?(webView.url?.absoluteString ?? "")
    }

    /// 页面加载过程中发生错误（一般指加载过程中出现中断）
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        proxy?.didFailNavigation?(webView.url?.absoluteString ?? "", withError: error as NSError)
    }

    /// 页面加载失败（首次请求失败，例如 DNS 解析失败等）
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        proxy?.didFailProvisionalNavigation?(webView.url?.absoluteString ?? "", withError: error as NSError)
    }

    /// 接收到服务器的重定向（HTTP 3xx 跳转）
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        proxy?.didReceiveServerRedirectForProvisionalNavigation?(webView.url?.absoluteString ?? "")
    }

    /// 决定是否允许加载请求（可用于拦截 URL）
    @available(iOS 13.0, *)
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        preferences: WKWebpagePreferences,
                        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        
        // 取出请求的 URL 字符串（如果有）
        if let urlString = navigationAction.request.url?.absoluteString {
            proxy?.webPageWillChanged?(urlString)
        }
        
        var isCalled = false
        let safeHandler: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void = { policy, prefs in
            guard !isCalled else { return }
            isCalled = true
            decisionHandler(policy, prefs)
        }
        
        if let handler = proxy?.decidePolicyForNavigationAction {
            handler(navigationAction, preferences, safeHandler)
        } else {
            // 若未实现，必须调用 fallback
            safeHandler(.allow, preferences)
        }
        
        // 用户未调用decisionHandler回调，使用默认策略
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !isCalled {
                safeHandler(.allow, preferences)
#if DEBUG
                assertionFailure("⚠️ 用户未调用decisionHandler回调，使用默认策略")
#endif
            }
        }
    }

    /// 决定是否允许响应跳转（服务器响应返回后触发）
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var isCalled = false
        let safeHandler: (WKNavigationResponsePolicy) -> Void = { policy in
            guard !isCalled else { return }
            isCalled = true
            decisionHandler(policy)
        }
        
        if let handler = proxy?.decidePolicyForNavigationResponse {
            handler(navigationResponse, safeHandler)
        } else {
            // 若未实现，默认允许
            safeHandler(.allow)
        }
        
        // 用户未调用decisionHandler回调，使用默认策略
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !isCalled {
                safeHandler(.allow)
#if DEBUG
                assertionFailure("⚠️ 用户未调用decisionHandler回调，使用默认策略")
#endif
            }
        }
    }

    /// Web 内容进程被终止（系统资源紧张时会杀掉 web 内容进程）
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        proxy?.webViewWebContentProcessDidTerminate?()
    }

    /// 收到身份验证请求（如 HTTPS 认证）
    public func webView(_ webView: WKWebView,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        var isCalled = false
        
        // 封装一个仅可调用一次的 completionHandler
        let safeHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void = { disposition, credential in
            guard !isCalled else { return }
            isCalled = true
            completionHandler(disposition, credential)
        }
        
        if let handler = proxy?.didReceiveAuthenticationChallenge {
            handler(challenge, safeHandler)
        } else {
            safeHandler(.performDefaultHandling, nil)
        }
        
        // 用户未调用completionHandler回调，使用默认策略
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !isCalled {
                safeHandler(.performDefaultHandling, nil)
#if DEBUG
                assertionFailure("⚠️ 用户未调用completionHandler回调，使用默认策略")
#endif
            }
        }
    }
    
    deinit {
        titleObservation?.invalidate()
        titleObservation = nil
    }
}

/// WKWebView 导航代理扩展，用于自动关联 WKWebViewDelegator，避免 weak 导致代理被释放
public extension WKWebView {
    
    /// 使用关联对象绑定进度监听器对象
    private var progressObserver: WebViewProgressObserver? {
        get { objc_getAssociatedObject(self, &progressObserverKey) as? WebViewProgressObserver }
        set { objc_setAssociatedObject(self, &progressObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

private var progressObserverKey: UInt8 = 0
private var navigationDelegatorKey: UInt8 = 0
private var navigationProxyKey: UInt8 = 0
