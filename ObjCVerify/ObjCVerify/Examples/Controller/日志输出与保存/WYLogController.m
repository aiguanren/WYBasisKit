//
//  WYLogController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/13.
//

#import "WYLogController.h"
#import <WYBasisKitObjC/WYBasisKitObjC.h>

@interface WYLogController ()

@end

@implementation WYLogController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //WYLogManager.clearLogFile()
    
    WYLog(@"不保存日志，仅在 DEBUG 模式下输出到控制台（默认）");
    
    WYLogWithMode(@"不保存日志，DEBUG 和 RELEASE 都输出到控制台", WYLogOutputModeAlwaysConsoleOnly);
    
    WYLogWithMode(@"保存日志，仅在 DEBUG 模式下输出到控制台", WYLogOutputModeDebugConsoleAndFile);
    
    WYLogWithMode(@"保存日志，DEBUG 和 RELEASE 都输出到控制台", WYLogOutputModeAlwaysConsoleAndFile);
    
    WYLogWithMode(@"仅保存日志，DEBUG 和 RELEASE 均不输出到控制台", WYLogOutputModeOnlySaveToFile);
    
    WYLogWithMode(@"状态栏高度 = %f\n导航栏安全区域高度 = %f\n导航栏高度 = %f\n导航视图高度（状态栏+导航栏） = %f\ntabBar安全区域高度 = %f\ntabBar高度(含安全区域高度) = %f\n是否是全屏手机 = %d", WYLogOutputModeAlwaysConsoleAndFile,
                  UIDevice.wy_statusBarHeight,
                  UIDevice.wy_navBarSafetyZone,
                  UIDevice.wy_navBarHeight,
                  UIDevice.wy_navViewHeight,
                  UIDevice.wy_tabbarSafetyZone,
                  UIDevice.wy_tabBarHeight,
                  UIDevice.wy_isFullScreen);
    
    WYLogWithMode([NSString wy_randomWithMinimux:20 maximum:100], WYLogOutputModeDebugConsoleAndFile);
    
    [WYLogManager showPreview];
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
