//
//  WYTestRequestController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTestRequestController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestRequestController ()

@end

@implementation WYTestRequestController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITextView *textView = [[UITextView alloc] init];
    textView.frame = CGRectMake(0, [UIDevice wy_navViewHeight], [UIDevice wy_screenWidth], [UIDevice wy_screenHeight] - [UIDevice wy_navViewHeight]);
    textView.editable = NO;
    textView.textColor = [UIColor blackColor];
    [self.view addSubview:textView];
    
    NSString *cacheKey = @"testCache";
    WYNetworkConfig *config = [WYNetworkConfig defaultConfig];
    config.requestCache = [[WYNetworkRequestCache alloc] initWithCacheKey:cacheKey];
    config.debugModeLog = NO;
    config.domain = @"https://api.xygeng.cn/";
    //config.originObject = YES;
    config.mapper = @{@(WYMappingKeyMessage): @"updateTime"};
    
    NSString *cachePath = config.requestCache.cachePath.path ?: @"";
    WYStorageData *storageData = [WYStorage takeOutForKey:cacheKey path:cachePath];
    
    NSTimeInterval delay = ((!storageData.isInvalid) && (storageData.userData != nil)) ? 2 : 0;
    
    WYLoadingInfoOptions *option = [[WYLoadingInfoOptions alloc] init];
    option.delay = delay;
    [WYActivity showLoading:@"加载中" in:self.view option:option];
    
    [WYNetworkManager requestWithMethod:WYHTTPMethodGet path:@"one" parameter:nil config:config handler:^(WYHandler * _Nonnull handler) {
        
        if (handler.success) {
            WYSuccess *success = handler.success;
            
            WYLog(@"%@缓存数据\n%@", (success.isCache ? @"是" : @"不是"), (config.originObject ? success.origin : success.parse));
            
            textView.text = (config.originObject ? success.origin : success.parse);
            
            if (!success.isCache) {
                [WYActivity dismissLoadingIn:self.view];
            }
            
            if (success.storage != nil) {
                WYLog(@"缓存路径：%@", success.storage.path.path ?: @"");
            }
            
        } else if (handler.error) {
            
            WYError *error = handler.error;
            WYLog(@"%@", error);
            [WYActivity dismissLoadingIn:self.view];
            [WYActivity showInfo:error.describe];
            
        } else if (handler.progress) {
            NSLog(@"网络请求进度：%f",handler.progress.progress);
        }
    }];
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
