//
//  AppDelegate.m
//  ObjCVerify
//
//  Created by guanren on 2025/8/18.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import <WYBasisKitObjC-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    WYBasisKitConfig.defaultScreenPixels = [[WYScreenPixels alloc] initWithWidth:375 height:812];
    
    _window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    _window.backgroundColor = [UIColor whiteColor];
    [_window makeKeyAndVisible];
    _window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[[MainViewController alloc]init]];
    
    // 屏蔽控制台约束输出
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    return YES;
}

@end
