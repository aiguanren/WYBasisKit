//
//  AppDelegate.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "AppDelegate.h"
#import <WYBasisKitObjC-Swift.h>
@import IQKeyboardManagerSwift;
@import IQKeyboardToolbarManager;
#import <SDWebImage/SDImageCodersManager.h>
#import <SDWebImageWebPCoder/SDImageWebPCoder.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 屏蔽控制台约束输出
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    WYBasisKitConfig.defaultScreenPixels = [[WYScreenPixels alloc] initWithWidth:375 height:812];
    
    // 全局设置SDWebImage支持显示webp格式图片
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];

    // 开启键盘管理(输入框自动带上完成工具条，点页面空白处收起键盘)
    [IQKeyboardManager shared].isEnabled = YES;
    [IQKeyboardManager shared].resignOnTouchOutside = YES;
    IQKeyboardToolbarManager.shared.isEnabled = YES;
    // 播放器区域不触发点外收回(键盘管理的窗口点按手势不与播放器单击抢事件)
    {
        NSMutableArray<Class> *ignoreClasses = [[IQKeyboardManager shared].touchResignedGestureIgnoreClasses mutableCopy];
        [ignoreClasses addObject:WYVideoPlayer.class];
        [IQKeyboardManager shared].touchResignedGestureIgnoreClasses = ignoreClasses;
    }

    return YES;
}

/// 屏幕旋转需要支持的方向
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIDevice.wy_currentInterfaceOrientation;
}

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
