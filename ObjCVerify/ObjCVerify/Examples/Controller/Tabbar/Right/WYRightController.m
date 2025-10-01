//
//  WYRightController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/1.
//

#import "WYRightController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>
#import "AppEventDelegate.h"

@interface WYRightController ()<AppEventDelegate>

@end

@implementation WYRightController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [WYEventHandler registerWithEvent:AppEventButtonDidMove target:self handler:^(id _Nullable data) {
        WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
    }];
    
    [WYEventHandler registerWithEvent:AppEventButtonDidReturn target:self handler:^(id _Nullable data) {
        WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
    }];
    
    __weak typeof(self) weakSelf = self;
    [WYEventHandler registerWithEvent:AppEventDidShowBannerView target:self handler:^(id _Nullable data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didShowBannerViewWithData: data];
    }];
}

- (void)didShowBannerViewWithData:(NSString *)data {
    WYLog(@"data = %@, controller = %@",data, NSStringFromClass([self class]));
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
