//
//  WYTestDarkNightModeController.m
//  ObjCVerify
//
//  Created by guanren on 2025/10/15.
//

#import "WYTestDarkNightModeController.h"
#import "WYTabBarController.h"
#import <Masonry/Masonry.h>
#import <WYBasisKitObjC.h>
#import "AppDelegate.h"

@interface WYTestDarkNightModeController ()

@end

@implementation WYTestDarkNightModeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button wy_backgroundColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [button wy_backgroundColor:[UIColor greenColor] forState:UIControlStateSelected];
    button.titleLabel.numberOfLines = 0;
    [button setTitle:@"亮色/中文" forState:UIControlStateNormal];
    [button setTitle:@"Dark night/English" forState:UIControlStateSelected];
    button.selected = (WYLocalizableManager.currentLanguage == WYLanguageEnglish);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(200);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
}

- (void)clickButton:(UIButton *)sender {
    if (WYLocalizableManager.currentLanguage == WYLanguageZh_Hans) {
        [WYLocalizableManager switchLanguageWithLanguage:WYLanguageEnglish reload:YES name:nil identifier:@"rootViewController" handler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                WYTabBarController *tabbarController = (WYTabBarController *)[AppDelegate shared].window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabbarController.selectedViewController;
                [navController.topViewController wy_showViewControllerWithClassName:@"WYTestDarkNightModeController" parameters:nil displaMode:WYDisplaModePush animated:NO];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [UIViewController wy_currentController].navigationItem.title = @"重启后的新Controller";
                });
            });
        }];
        
        [[UIApplication sharedApplication] wy_switchAppDisplayBrightness:UIUserInterfaceStyleDark];
    } else {
        
        [WYLocalizableManager switchLanguageWithLanguage:WYLanguageZh_Hans reload:YES name:nil identifier:@"rootViewController" handler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                WYTabBarController *tabbarController = (WYTabBarController *)[AppDelegate shared].window.rootViewController;
                UINavigationController *navController = (UINavigationController *)tabbarController.selectedViewController;
                [navController.topViewController wy_showViewControllerWithClassName:@"WYTestDarkNightModeController" parameters:nil displaMode:WYDisplaModePush animated:NO];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [UIViewController wy_currentController].navigationItem.title = @"重启后的新Controller";
                });
            });
        }];
        [[UIApplication sharedApplication] wy_switchAppDisplayBrightness:UIUserInterfaceStyleLight];
    }
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
