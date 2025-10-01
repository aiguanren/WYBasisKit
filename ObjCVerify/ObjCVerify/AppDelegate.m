//
//  AppDelegate.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "AppDelegate.h"
#import <WYBasisKitObjC-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 屏蔽控制台约束输出
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    WYBasisKitConfig.defaultScreenPixels = [[WYScreenPixels alloc] initWithWidth:375 height:812];
    
    return YES;
}

/// 切换为深色或浅色模式
//- (void)applicationDidBecomeActive:(UIApplication *)application {
//    application.wy_switchAppDisplayBrightness(style: (WYLocalizableManager.currentLanguage() == .english) ? .dark : .light)
//}

/// 屏幕旋转需要支持的方向
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIDevice.wy_currentInterfaceOrientation;
}

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
