//
//  WYTestRequestController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/12.
//

#import "WYTestRequestController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYTestRequestController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation WYTestRequestController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _textView = [[UITextView alloc] init];
    _textView.frame = CGRectMake(0, [UIDevice wy_navViewHeight], [UIDevice wy_screenWidth], [UIDevice wy_screenHeight] - [UIDevice wy_navViewHeight]);
    _textView.editable = NO;
    _textView.textColor = [UIColor blackColor];
    [self.view addSubview:_textView];
    
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
    
    wy_weakify(self);
    [WYNetworkManager requestWithMethod:WYHTTPMethodGet path:@"one" parameter:nil config:config handler:^(WYHandler * _Nonnull handler) {
        
        wy_strongify(self);
        if (!self) return;
        
        if (handler.success) {
            WYSuccess *success = handler.success;
            
            wy_print(@"%@缓存数据\n%@", (success.isCache ? @"是" : @"不是"), (config.originObject ? success.origin : success.parse));
            
            self.textView.text = (config.originObject ? success.origin : success.parse);
            
            if (!success.isCache) {
                [WYActivity dismissLoadingIn:self.view];
            }
            
            if (success.storage != nil) {
                wy_print(@"缓存路径：%@", success.storage.path.path ?: @"");
            }
            
        } else if (handler.error) {
            
            wy_strongify(self);
            if (!self) return;
            
            WYError *error = handler.error;
            wy_print(@"%@", error);
            [WYActivity dismissLoadingIn:self.view];
            [WYActivity showInfo:error.describe];
            
        } else if (handler.progress) {
            NSLog(@"网络请求进度：%f",handler.progress.progress);
        }
    }];
}

- (BOOL)wy_navigationBarWillReturn {
    [self wy_backToLastViewControllerWithReturnValue:_textView.text animated:YES];
    return NO;
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
