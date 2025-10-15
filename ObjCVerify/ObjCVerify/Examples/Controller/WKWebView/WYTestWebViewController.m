//
//  WYTestWebViewController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/6.
//

#import "WYTestWebViewController.h"
#import <Masonry/Masonry.h>
#import <WebKit/WKWebView.h>
#import <WYBasisKitObjC.h>

@interface WYTestWebViewController ()<WYWebViewNavigationDelegateProxy>

@end

@implementation WYTestWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    WKWebView *webView = [[WKWebView alloc] init];
    [self.view addSubview:webView];
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).mas_offset(UIDevice.wy_navViewHeight + 2);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view).mas_offset(-UIDevice.wy_tabbarSafetyZone);
    }];
    // 启用加载进度条
    [webView wy_enableProgressView];
    
    // 设置代理派发器
    webView.wy_navigationProxy = self;

    // 加载网页
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com/cn"]]];
}

- (void)wy_webPageNavigationTitleChanged:(NSString *)title isRepeat:(BOOL)isRepeat {
    NSLog(@"webPageNavigationTitleChanged  title = %@, isRepeat = %@",title, isRepeat ? @"yes" : @"no");
}

- (void)wy_webPageWillChanged:(NSString *)urlString {
    NSLog(@"webPageWillChanged  urlString = %@",urlString);
}

- (void)wy_didStartProvisionalNavigation:(NSString *)urlString {
    NSLog(@"didStartProvisionalNavigation  urlString = %@",urlString);
}

- (void)wy_webPageLoadProgress:(CGFloat)progress {
    NSLog(@"webPageLoadProgress  progress = %f",progress);
}

- (void)wy_didFailProvisionalNavigation:(NSString *)urlString withError:(NSError *)error {
    NSLog(@"didFailProvisionalNavigation  urlString = %@, error = %@",urlString, [error localizedDescription]);
}

- (void)wy_didCommitNavigation:(NSString *)urlString {
    NSLog(@"didCommitNavigation  urlString = %@",urlString);
}

- (void)wy_didFinishNavigation:(NSString *)urlString {
    NSLog(@"didFinishNavigation  urlString = %@",urlString);
}

- (void)wy_didFailNavigation:(NSString *)urlString withError:(NSError *)error {
    NSLog(@"didFailNavigation  urlString = %@, error = %@",urlString, [error localizedDescription]);
}

- (void)wy_didReceiveServerRedirectForProvisionalNavigation:(NSString *)urlString {
    NSLog(@"didReceiveServerRedirectForProvisionalNavigation  urlString = %@",urlString);
}

- (void)wy_decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction preferences:(WKWebpagePreferences *)preferences decisionHandler:(void (^)(WKNavigationActionPolicy, WKWebpagePreferences * _Nonnull))decisionHandler {
    NSLog(@"decidePolicyForNavigationAction  navigationAction = %@, preferences = %@",navigationAction, preferences);
    decisionHandler(WKNavigationActionPolicyAllow, preferences);
}

- (void)wy_decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"decidePolicyForNavigationResponse  navigationResponse = %@",navigationResponse);;
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)wy_webViewWebContentProcessDidTerminate {
    NSLog(@"webViewWebContentProcessDidTerminate");
}

- (void)wy_didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(enum NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSLog(@"didReceiveAuthenticationChallenge  challenge = %@", challenge);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)dealloc {
    WYLogManager.output(@"WYWebViewController release");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
